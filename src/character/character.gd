extends CharacterBody2D

# --- Настройки движения ---
@export_group("Movement")
@export var WALK_SPEED : float = 250.0
@export var RUN_SPEED : float = 420.0
@export var ACCELERATION : float = 1200.0
@export var FRICTION : float = 1500.0

# --- Настройки прыжка ---
@export_group("Jump")
@export var JUMP_VELOCITY : float = -675.0
@export var GRAVITY : float = 1800.0
@export var JUMP_CUT : float = 0.4
@export var COYOTE_TIME : float = 0.12
@export var MAX_JUMPS : int = 2

# --- Настройки Дэша ---
@export_group("Dash")
@export var DASH_SPEED : float = 1800.0
@export var DASH_DURATION : float = 0.075
@export var DASH_COOLDOWN : float = 0.4

# --- Узлы ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var camera = get_node_or_null("Camera2D")

# Партиклы
@onready var run_dust = get_node_or_null("RunDust")
@onready var jump_dust = get_node_or_null("JumpDust")

# --- ЗВУКОВЫЕ УЗЛЫ ---
@onready var sfx_footsteps  : AudioStreamPlayer2D = $Footsteps
@onready var sfx_jump       : AudioStreamPlayer2D = $JumpSound
@onready var sfx_dash       : AudioStreamPlayer2D = $DashSound
@onready var sfx_hurt       : AudioStreamPlayer2D = $HurtSound
@onready var footstep_timer : Timer = $FootstepTimer

# --- ЭФФЕКТЫ ---
@export var ghost_node : PackedScene # Не забудь перетащить сюда DashGhost.tscn в инспекторе!
var ghost_timer : float = 0.0

# --- Состояния ---
var is_dashing : bool = false
var can_dash : bool = true
var current_health : float = 4.0
var max_health : float = 4.0
var can_take_damage : bool = true
var coyote_timer : float = 0.0
var current_jumps : int = 0
var dash_dir : Vector2 = Vector2.ZERO
var was_in_air : bool = false

func _ready() -> void:
	current_health = max_health
	update_ui()

func _physics_process(delta: float) -> void:
	if is_dashing:
		process_dash(delta)
		return

	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)
	handle_sounds() 
	
	if Input.is_action_just_pressed("dash_key") and can_dash:
		start_dash()

	if is_on_floor() and was_in_air:
		if camera and camera.has_method("apply_shake"): camera.apply_shake(12.0)
		trigger_jump_dust(1.5)
		was_in_air = false
	
	if not is_on_floor():
		was_in_air = true

	move_and_slide()
	update_timers(delta)
	update_animation()

# --- ЛОГИКА ЗВУКОВ ---

func handle_sounds() -> void:
	if not sfx_footsteps or not footstep_timer: return
	
	var is_moving_on_floor = is_on_floor() and abs(velocity.x) > 10
	
	if is_moving_on_floor:
		if footstep_timer.is_stopped():
			sfx_footsteps.pitch_scale = randf_range(0.8, 1.2)
			sfx_footsteps.play()
			var step_delay = 0.35 
			if abs(velocity.x) > WALK_SPEED + 10:
				step_delay = 0.22
			footstep_timer.start(step_delay)
	else:
		if sfx_footsteps.playing:
			sfx_footsteps.stop()
		footstep_timer.stop()

# --- МЕХАНИКА ДЭША ---

func start_dash() -> void:
	is_dashing = true
	can_dash = false
	ghost_timer = 0 # Чтобы первый призрак появился сразу
	
	sfx_dash.play()
	
	var input = Input.get_axis("ui_left", "ui_right")
	var dir = input if input != 0 else (-1.0 if anim.flip_h else 1.0)
	dash_dir = Vector2(dir, 0)

	set_collision_mask_value(3, false)
	set_collision_layer_value(2, false)
	
	global_position.x += dash_dir.x * 10 
	
	anim.modulate = Color(8, 8, 8, 1) 
	if camera and camera.has_method("apply_shake"): camera.apply_shake(10.0)

	get_tree().create_timer(DASH_DURATION).timeout.connect(stop_dash)
	get_tree().create_timer(DASH_COOLDOWN).timeout.connect(func(): can_dash = true)

func process_dash(delta: float) -> void:
	# Движение
	var motion = dash_dir * DASH_SPEED * delta
	var collision = move_and_collide(motion)
	
	# Логика призрачного шлейфа
	ghost_timer -= delta
	if ghost_timer <= 0:
		add_ghost()
		ghost_timer = 0.03 # Частота появления призраков
	
	if collision:
		var collider = collision.get_collider()
		if collider.has_method("get_collision_layer_value"):
			if collider.get_collision_layer_value(1):
				stop_dash()

func add_ghost() -> void:
	if not ghost_node: return
	var ghost = ghost_node.instantiate()
	# Копируем параметры спрайта
	ghost.texture = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	ghost.global_position = global_position
	ghost.flip_h = anim.flip_h
	ghost.scale = anim.scale
	ghost.modulate = Color(2.0, 2.0, 2.0, 0.659) # Светло-голубой неоновый цвет
	get_parent().add_child(ghost)

func stop_dash() -> void:
	if not is_dashing: return
	is_dashing = false
	set_collision_mask_value(3, true)
	set_collision_layer_value(2, true)
	velocity.x = dash_dir.x * WALK_SPEED
	velocity.y = 0
	anim.modulate = Color(1, 1, 1, 1)

# --- ФИЗИКА И ПРЫЖКИ ---

func apply_gravity(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		current_jumps = 0
	else:
		velocity.y += GRAVITY * delta
		coyote_timer -= delta

func handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor() or coyote_timer > 0:
			execute_jump()
		elif current_jumps < MAX_JUMPS:
			execute_jump()
			if camera and camera.has_method("apply_shake"): camera.apply_shake(5.0)
	
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= JUMP_CUT

func execute_jump() -> void:
	velocity.y = JUMP_VELOCITY
	current_jumps += 1
	coyote_timer = 0
	sfx_jump.pitch_scale = randf_range(0.95, 1.05)
	sfx_jump.play()
	trigger_jump_dust(1.0)

func handle_movement(delta: float) -> void:
	var move_input = Input.get_axis("ui_left", "ui_right")
	var target_speed = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	
	if move_input != 0:
		velocity.x = move_toward(velocity.x, move_input * target_speed, ACCELERATION * delta)
		anim.flip_h = move_input < 0
		
		if is_on_floor() and run_dust:
			run_dust.emitting = true
			run_dust.direction.x = -move_input
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		if run_dust: run_dust.emitting = false

func trigger_jump_dust(scale_mult: float) -> void:
	if jump_dust:
		jump_dust.scale_amount_max = 4.0 * scale_mult
		jump_dust.restart()
		jump_dust.emitting = true

func update_animation() -> void:
	if is_dashing: return
	if not is_on_floor():
		anim.play("jump" if velocity.y < 0 else "fall")
	elif abs(velocity.x) > 10:
		anim.play("run" if abs(velocity.x) > WALK_SPEED + 10 else "walk")
	else:
		anim.play("Idle")

# --- УРОН И СМЕРТЬ ---

func take_damage(amount: float) -> void:
	if not can_take_damage or is_dashing: return
	
	current_health -= amount
	can_take_damage = false
	
	sfx_hurt.play()
	update_ui()
	
	# Эффект Hit-Stop (Заморозка)
	Engine.time_scale = 0.05
	if camera and camera.has_method("apply_shake"): camera.apply_shake(50.0)
	
	# Ждем 0.1 сек реального времени (независимо от замедления)
	await get_tree().create_timer(0.1, true, false, true).timeout
	Engine.time_scale = 1.0
	
	if current_health <= 0:
		die()
	else:
		var tween = create_tween()
		tween.tween_property(anim, "modulate", Color(3.993, 0.0, 0.0, 1.0), 0.1)
		tween.tween_property(anim, "modulate", Color(1,1,1,1), 0.1)
		tween.set_loops(3)
		await get_tree().create_timer(1.0).timeout
		can_take_damage = true

func update_ui() -> void:
	var ui = get_tree().root.find_child("in_game_menu", true, false)
	if ui and ui.has_method("update_health_ui"):
		ui.update_health_ui(current_health)

# --- УРОН И СМЕРТЬ (ОБНОВЛЕНО) ---

func die() -> void:
	# Останавливаем всё управление
	set_physics_process(false)
	set_process_input(false)
	
	# Проигрываем анимацию смерти
	if anim.sprite_frames.has_animation("die"):
		anim.play("die")
		await anim.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout

	# Теперь вместо экрана смерти пробуем респаун
	respawn()

func respawn() -> void:
	# Проверяем, есть ли сохраненная точка в GameManager
	if GameManager.last_checkpoint_pos != Vector2.ZERO:
		# Телепортируем игрока на позицию чекпоинта
		global_position = GameManager.last_checkpoint_pos
		
		# --- ЛОГИКА СЖИГАНИЯ КОСТРА ---
		# Ищем все объекты в группе "checkpoints"
		var checkpoints = get_tree().get_nodes_in_group("checkpoints")
		for cp in checkpoints:
			# Увеличиваем дистанцию до 50, так как 10 пикселей — это слишком мало
			if cp.global_position.distance_to(global_position) < 50:
				# Вызываем метод деактивации, который пометит костер как is_burned_out
				if cp.has_method("deactivate"):
					cp.deactivate()
		
		# --- ВОССТАНОВЛЕНИЕ ИГРОКА ---
		current_health = max_health
		update_ui()
		
		# Включаем управление и физику
		set_physics_process(true)
		set_process_input(true)
		can_take_damage = true
		
		# Сбрасываем скорость и запускаем анимацию покоя
		velocity = Vector2.ZERO
		if anim:
			anim.play("Idle")
			
			# Эффект плавного появления игрока (из прозрачности)
			var tween = create_tween()
			tween.tween_property(anim, "modulate:a", 1.0, 0.5).from(0.0)
			
		print("Игрок возродился, костер израсходован.")
	else:
		# Если чекпоинтов нет или они все сгорели — на экран смерти
		get_tree().change_scene_to_file("res://cutscenes/die_screen/die_screen.tscn")

func update_timers(delta: float) -> void:
	if coyote_timer > 0:
		coyote_timer -= delta
