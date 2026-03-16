extends CharacterBody2D

# --- Настройки движения ---
@export_group("Movement")
@export var WALK_SPEED = 250.0
@export var RUN_SPEED = 420.0
@export var ACCELERATION = 1200.0
@export var FRICTION = 1500.0

# --- Настройки прыжка ---
@export_group("Jump")
@export var JUMP_VELOCITY = -550.0
@export var GRAVITY_UP = 1200.0
@export var GRAVITY_DOWN = 2000.0
@export var JUMP_CUT_MULTIPLIER = 0.4
@export var COYOTE_TIME = 0.12
@export var MAX_JUMPS = 2 

# --- Здоровье ---
@export_group("Health")
@export var max_health: float = 4.0 # 4 сердца = 8 половинок
var current_health: float
var can_take_damage: bool = true

# --- Узлы ---
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var run_dust: CPUParticles2D = $RunDust
@onready var jump_dust: CPUParticles2D = $JumpDust

# --- Переменные состояния ---
var coyote_timer = 0.0
var current_jumps = 0
var was_in_air = false
var footstep_timer = 0.0

@export var STEP_DELAY_WALK = 0.35 
@export var STEP_DELAY_RUN = 0.22  

func _ready():
	current_health = max_health
	update_ui()

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)
	
	# Эффект приземления
	if is_on_floor() and was_in_air:
		camera.apply_shake(12.0)
		trigger_jump_dust(1.5) 
		was_in_air = false
	
	if not is_on_floor():
		was_in_air = true
	
	move_and_slide()
	update_timers(delta)
	update_animation()

func apply_gravity(delta: float):
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		current_jumps = 0
	else:
		var current_gravity = GRAVITY_UP if velocity.y < 0 else GRAVITY_DOWN
		velocity.y += current_gravity * delta

func handle_jump():
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor() or coyote_timer > 0:
			execute_jump()
		elif current_jumps < MAX_JUMPS:
			execute_jump()
			camera.apply_shake(8.0)
		
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULTIPLIER

func execute_jump():
	velocity.y = JUMP_VELOCITY
	current_jumps += 1
	coyote_timer = 0.0
	trigger_jump_dust(1.0) 

func trigger_jump_dust(scale_mult: float):
	jump_dust.scale_amount_max = 4.0 * scale_mult
	jump_dust.restart()
	jump_dust.emitting = true

func handle_movement(delta: float):
	var direction := Input.get_axis("ui_left", "ui_right")
	var is_running = Input.is_action_pressed("run")
	var target_speed = RUN_SPEED if is_running else WALK_SPEED
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * target_speed, ACCELERATION * delta)
		
		if is_on_floor():
			run_dust.emitting = true
			run_dust.speed_scale = 1.8 if is_running else 0.4
			run_dust.direction.x = -direction 
		else:
			run_dust.emitting = false
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		run_dust.emitting = false
		footstep_timer = 0.05 # Сброс для мгновенного первого шага

# --- Система здоровья ---
func take_damage(amount: float):
	if not can_take_damage: return
	
	current_health -= amount
	can_take_damage = false
	update_ui()
	camera.apply_shake(15.0)
	
	if current_health <= 0:
		die()
	else:
		# Фреймы неуязвимости (мигание)
		var tween = create_tween()
		tween.tween_property(anim, "modulate", Color(1, 0, 0, 0.8), 0.1)
		tween.tween_property(anim, "modulate", Color(1, 1, 1, 1), 0.1)
		tween.set_loops(3) # Мигнет 3 раза
		
		await get_tree().create_timer(1.0).timeout
		can_take_damage = true

func update_ui():
	# Ищем узел in_game_menu в сцене
	var ui = get_tree().root.find_child("in_game_menu", true, false)
	if ui and ui.has_method("update_health_ui"):
		ui.update_health_ui(current_health)

func die():
	get_tree().reload_current_scene()

func update_timers(delta: float):
	if coyote_timer > 0:
		coyote_timer -= delta

func update_animation():
	var is_running = Input.is_action_pressed("run")
	if velocity.x != 0:
		anim.flip_h = velocity.x < 0
	if not is_on_floor():
		anim.play("jump") if velocity.y < 0 else anim.play("fall")
	else:
		if abs(velocity.x) > 10:
			anim.play("run" if is_running else "walk")
		else:
			anim.play("Idle")
