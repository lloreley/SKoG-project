extends CharacterBody2D

@export_group("Movement")
@export var WALK_SPEED : float = 250.0
@export var RUN_SPEED : float = 420.0
@export var ACCELERATION : float = 1200.0
@export var FRICTION : float = 1500.0

@export_group("Jump")
@export var JUMP_VELOCITY : float = -675.0
@export var GRAVITY : float = 1800.0
@export var JUMP_CUT : float = 0.4
@export var COYOTE_TIME : float = 0.12
@export var MAX_JUMPS : int = 2

@export_group("Dash")
@export var DASH_SPEED : float = 1800.0
@export var DASH_DURATION : float = 0.075
@export var DASH_COOLDOWN : float = 0.4

@export_group("Attack")
@export var ATTACK_OFFSET : float = 35.0

# ССЫЛКИ НА УЗЛЫ
@onready var visuals : Node2D = $Visuals
@onready var anim_full : AnimatedSprite2D = $Visuals/FullBody
@onready var anim_body : AnimatedSprite2D = $Visuals/Body
@onready var anim_legs : AnimatedSprite2D = $Visuals/Legs

@onready var camera = get_node_or_null("Camera2D")
@onready var run_dust = get_node_or_null("RunDust")
@onready var jump_dust = get_node_or_null("JumpDust")
@onready var sfx_footsteps : AudioStreamPlayer2D = $Footsteps
@onready var sfx_jump : AudioStreamPlayer2D = $JumpSound
@onready var sfx_dash : AudioStreamPlayer2D = $DashSound
@onready var sfx_hurt : AudioStreamPlayer2D = $HurtSound
@onready var sfx_attack : AudioStreamPlayer2D = $AttackSound
@onready var footstep_timer : Timer = $FootstepTimer

@onready var attack_area : Area2D = $Visuals/AttackArea
@onready var attack_shape : CollisionShape2D = $Visuals/AttackArea/CollisionShape2D

@export var ghost_node : PackedScene
var ghost_timer : float = 0.0
var is_dashing : bool = false
var can_dash : bool = true
var is_attacking : bool = false
var current_health : float = 4.0
var max_health : float = 4.0
var can_take_damage : bool = true
var coyote_timer : float = 0.0
var current_jumps : int = 0
var was_in_air : bool = false
var dash_dir : Vector2 = Vector2.ZERO

func _ready() -> void:
	current_health = max_health
	if attack_shape:
		attack_shape.disabled = true
	update_ui()
	switch_to_layer("full")
	anim_body.frame_changed.connect(_on_attack_frame_changed)

func _physics_process(delta: float) -> void:
	if is_dashing:
		process_dash(delta)
		return

	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()

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

# --- СИСТЕМА СПРАЙТОВ ---
func switch_to_layer(mode: String):
	if not anim_full or not anim_body or not anim_legs: return
	anim_full.visible = (mode == "full")
	anim_body.visible = (mode == "split")
	anim_legs.visible = (mode == "split")

# --- ДВИЖЕНИЕ И УПРАВЛЕНИЕ ---
func handle_movement(delta: float) -> void:
	var move_input = Input.get_axis("ui_left", "ui_right")
	var target_speed = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	
	if move_input != 0:
		velocity.x = move_toward(velocity.x, move_input * target_speed, ACCELERATION * delta)
		visuals.scale.x = abs(visuals.scale.x) * move_input
		if is_on_floor() and run_dust:
			run_dust.emitting = true
			run_dust.direction.x = -move_input
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		if run_dust: run_dust.emitting = false

func start_dash() -> void:
	is_dashing = true
	can_dash = false
	ghost_timer = 0
	if sfx_dash: sfx_dash.play()
	
	var input = Input.get_axis("ui_left", "ui_right")
	# Определяем направление: либо ввод, либо куда смотрит персонаж (через масштаб visuals)
	var dir = input if input != 0 else sign(visuals.scale.x)
	dash_dir = Vector2(dir, 0)
	
	# Отключаем слои врагов и игрока
	set_collision_mask_value(3, false)
	set_collision_layer_value(2, false)
	
	# Мгновенное смещение помогает "пройти" сквозь коллизию врага в первый же кадр
	global_position.x += dash_dir.x * 10 
	
	visuals.modulate = Color(8, 8, 8, 1) 
	if camera and camera.has_method("apply_shake"): camera.apply_shake(10.0)
	
	get_tree().create_timer(DASH_DURATION).timeout.connect(stop_dash)
	get_tree().create_timer(DASH_COOLDOWN).timeout.connect(func(): can_dash = true)

func process_dash(delta: float) -> void:
	var motion = dash_dir * DASH_SPEED * delta
	var collision = move_and_collide(motion)
	
	ghost_timer -= delta
	if ghost_timer <= 0:
		add_ghost()
		ghost_timer = 0.03 
		
	if collision:
		var collider = collision.get_collider()
		# Останавливаемся только об TileMap или объекты на 1-м слое (стены)
		if collider is TileMapLayer or ("collision_layer" in collider and collider.collision_layer & 1):
			stop_dash()

func stop_dash() -> void:
	if not is_dashing: return
	is_dashing = false
	set_collision_mask_value(3, true)
	set_collision_layer_value(2, true)
	velocity.x = dash_dir.x * WALK_SPEED
	velocity.y = 0
	visuals.modulate = Color(1, 1, 1, 1)

# --- АТАКА ---
func start_attack() -> void:
	is_attacking = true
	switch_to_layer("split")
	anim_body.play("attack_body")
	
	if anim_legs.sprite_frames.has_animation("attack_legs"):
		anim_legs.play("attack_legs")
	
	# Мы БОЛЬШЕ НЕ включаем коллизию здесь принудительно
	# Она включится сама в _on_attack_frame_changed
	
	await anim_body.animation_finished
	
	if attack_shape: 
		attack_shape.disabled = true
	is_attacking = false

func take_damage(amount: float) -> void:
	if not can_take_damage or is_dashing: return
	current_health -= amount
	can_take_damage = false
	if sfx_hurt: sfx_hurt.play()
	update_ui()
	
	Engine.time_scale = 0.05
	if camera and camera.has_method("apply_shake"): camera.apply_shake(50.0)
	await get_tree().create_timer(0.1, true, false, true).timeout
	Engine.time_scale = 1.0
	
	if current_health <= 0:
		die()
	else:
		var tween = create_tween()
		tween.tween_property(visuals, "modulate", Color.RED, 0.1)
		tween.tween_property(visuals, "modulate", Color.WHITE, 0.1)
		tween.set_loops(3)
		await get_tree().create_timer(1.0).timeout
		can_take_damage = true

func die() -> void:
	set_physics_process(false)
	set_process_input(false)
	switch_to_layer("full")
	if anim_full.sprite_frames.has_animation("die"):
		anim_full.play("die")
		await anim_full.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
	respawn()

func respawn() -> void:
	if GameManager.last_checkpoint_pos != Vector2.ZERO:
		# 1. Перемещаем игрока в точку сохранения
		global_position = GameManager.last_checkpoint_pos
		
		# 2. Ждем один кадр для синхронизации позиций в движке
		await get_tree().process_frame
		
		# 3. Находим костер, на котором стоим, и деактивируем его навсегда
		var checkpoints = get_tree().get_nodes_in_group("checkpoints")
		for cp in checkpoints:
			if cp.global_position.distance_to(global_position) < 50:
				if cp.has_method("deactivate"):
					cp.deactivate()
		
		# 4. СТИРАЕМ точку сохранения в менеджере. 
		# Теперь этот костер "израсходован". Если игрок умрет снова, 
		# не дойдя до нового костра, он попадет на die_screen.
		GameManager.last_checkpoint_pos = Vector2.ZERO

		# 5. Восстановление состояния персонажа
		current_health = max_health
		update_ui()
		set_physics_process(true)
		set_process_input(true)
		can_take_damage = true
		velocity = Vector2.ZERO
		
		# Визуальное обновление (переключение на целого персонажа и анимация Idle)
		switch_to_layer("full")
		if anim_full.sprite_frames.has_animation("idle"):
			anim_full.play("idle")
		
		# Эффект появления
		var tween = create_tween()
		tween.tween_property(visuals, "modulate:a", 1.0, 0.5).from(0.0)
	else:
		# Если GameManager.last_checkpoint_pos пуст (костер уже был использован),
		# переходим на сцену экрана смерти или главного меню.
		get_tree().change_scene_to_file("res://cutscenes/die_screen/die_screen.tscn")

# --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ---
func update_ui() -> void:
	var ui = get_tree().root.find_child("in_game_menu", true, false)
	if ui and ui.has_method("update_health_ui"):
		ui.update_health_ui(current_health)

func update_animation() -> void:
	if is_dashing or current_health <= 0: return
	if is_on_floor() and abs(velocity.x) < 10 and not is_attacking:
		switch_to_layer("full")
		anim_full.play("idle")
		return
	
	switch_to_layer("split")
	if not is_on_floor():
		anim_legs.play("jump_legs")
	elif abs(velocity.x) > 10:
		anim_legs.play("run_legs" if abs(velocity.x) > WALK_SPEED + 10 else "walk_legs")
	else:
		anim_legs.play("walk_legs")

	if not is_attacking:
		if not is_on_floor(): anim_body.play("jump_body")
		elif abs(velocity.x) > 10: anim_body.play("run_body" if abs(velocity.x) > WALK_SPEED + 10 else "walk_body")
		else: anim_body.play("walk_body")

func apply_gravity(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		current_jumps = 0
	else:
		velocity.y += GRAVITY * delta
		coyote_timer -= delta

func handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor() or coyote_timer > 0 or current_jumps < MAX_JUMPS:
			velocity.y = JUMP_VELOCITY
			current_jumps += 1
			coyote_timer = 0
			if sfx_jump: sfx_jump.play()
			trigger_jump_dust(1.0)
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= JUMP_CUT

func add_ghost() -> void:
	if not ghost_node: return
	var ghost = ghost_node.instantiate()
	var active_anim = anim_full if anim_full.visible else anim_body
	ghost.texture = active_anim.sprite_frames.get_frame_texture(active_anim.animation, active_anim.frame)
	ghost.global_position = global_position
	ghost.scale = visuals.scale
	ghost.modulate = Color(2.0, 2.0, 2.0, 0.6)
	get_parent().add_child(ghost)

func handle_sounds() -> void:
	if not sfx_footsteps or not footstep_timer: return
	if is_on_floor() and abs(velocity.x) > 10:
		if footstep_timer.is_stopped():
			sfx_footsteps.play()
			footstep_timer.start(0.35 if abs(velocity.x) <= WALK_SPEED + 10 else 0.22)
	else:
		footstep_timer.stop()

func trigger_jump_dust(scale_mult: float) -> void:
	if jump_dust:
		jump_dust.restart()
		jump_dust.emitting = true

func update_timers(delta: float) -> void:
	if coyote_timer > 0: coyote_timer -= delta

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body != self and body.has_method("take_damage"):
		body.take_damage(2)
		
func _on_attack_frame_changed() -> void:
	if is_attacking and anim_body.animation == "attack_body":
		
		# КАДРЫ УДАРА (2 и 4)
		if anim_body.frame == 2 or anim_body.frame == 4:
			# 1. Звук
			if sfx_attack:
				sfx_attack.pitch_scale = randf_range(0.9, 1.1)
				sfx_attack.play()
			
			# 2. Включаем коллизию
			if attack_shape:
				attack_shape.disabled = false
				
			# 3. Мгновенная проверка попадания (чтобы урон прошел сразу)
			var targets = attack_area.get_overlapping_bodies()
			for target in targets:
				if target != self and target.has_method("take_damage"):
					target.take_damage(2)
		
		# КАДРЫ "ОТДЫХА" (все остальные)
		else:
			# Выключаем коллизию на кадрах между ударами, чтобы не задеть лишнего
			if attack_shape:
				attack_shape.disabled = true
