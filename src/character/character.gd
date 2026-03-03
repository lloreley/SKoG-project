extends CharacterBody2D

# --- ДВИЖЕНИЕ ---
const WALK_SPEED = 250.0
const RUN_SPEED = 420.0
const ACCELERATION = 1200.0
const RUN_ACCELERATION = 1800.0
const FRICTION = 1500.0

# --- ПРЫЖОК ---
const JUMP_VELOCITY = -550.0
const GRAVITY_UP = 1200.0
const GRAVITY_DOWN = 2000.0
const JUMP_CUT_MULTIPLIER = 0.4

# --- COYOTE TIME ---
const COYOTE_TIME = 0.12
var coyote_timer = 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	anim.play("Idle")


func _physics_process(delta: float) -> void:

	# --- ПРОВЕРКА БЕГА ---
	var is_running = Input.is_action_pressed("run")
	var current_speed = RUN_SPEED if is_running else WALK_SPEED
	var current_acceleration = RUN_ACCELERATION if is_running else ACCELERATION

	# --- ГРАВИТАЦИЯ ---
	if not is_on_floor():
		if velocity.y < 0:
			velocity.y += GRAVITY_UP * delta
		else:
			velocity.y += GRAVITY_DOWN * delta
	else:
		coyote_timer = COYOTE_TIME

	if not is_on_floor():
		coyote_timer -= delta

	# --- ПРЫЖОК ---
	if Input.is_action_just_pressed("ui_accept") and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0

	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	# --- ДВИЖЕНИЕ ПО X ---
	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * current_speed, current_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	move_and_slide()

	# --- ОГРАНИЧЕНИЕ МИРА ---
	var world_width = 1650
	var world_height = 480
	position.x = clamp(position.x, 0, world_width)
	position.y = clamp(position.y, 0, world_height)

	update_animation(is_running)


func update_animation(is_running: bool):

	# Поворот
	if velocity.x < 0:
		anim.flip_h = true
	elif velocity.x > 0:
		anim.flip_h = false

	# Анимации
	if not is_on_floor():
		if velocity.y < 0:
			anim.play("jump")
		else:
			anim.play("fall")
	else:
		if abs(velocity.x) > 10:
			if is_running:
				anim.play("run")
			else:
				anim.play("walk")
		else:
			anim.play("Idle")
