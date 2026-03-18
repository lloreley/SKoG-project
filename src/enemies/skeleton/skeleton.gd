extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK, DEAD }
var current_state = State.PATROL

@export_group("Movement")
@export var walk_speed     : float = 150.0
@export var chase_speed    : float = 300.0
@export var gravity        : float = 1800.0
@export var jump_velocity  : float = -750.0
@export var air_control    : float = 500.0

@export_group("Combat")
@export var max_health     : int = 25
@export var attack_range   : float = 90.0
@export var attack_cooldown: float = 0.6 # Уменьшено для агрессии
@export var lunge_force    : float = 300.0 # Сильнее рывок
@export var attack_speed_mult : float = 1.6 # МНОЖИТЕЛЬ СКОРОСТИ АНИМАЦИИ

@onready var sprite      : AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_check : RayCast2D = $FloorChecker
@onready var wall_check  : RayCast2D = $WallChecker
@onready var sword_area  : Area2D = $SwordShape 
@onready var hitbox      : CollisionShape2D = $SwordShape/CollisionShape2D

var player : Node2D = null
var health : int
var facing : int = 1
var can_attack : bool = true
var in_rage : bool = false
var turn_cooldown : float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	hitbox.disabled = true
	if not sword_area.body_entered.is_connected(_on_sword_shape_body_entered):
		sword_area.body_entered.connect(_on_sword_shape_body_entered)

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD: return
	
	if turn_cooldown > 0:
		turn_cooldown -= delta
	
	if not is_on_floor():
		velocity.y += gravity * delta

	match current_state:
		State.PATROL:
			logic_patrol(delta)
		State.CHASE:
			logic_chase(delta)
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0, 800 * delta)

	move_and_slide()
	update_facing()
	update_animation()

func logic_patrol(_delta: float) -> void:
	if player:
		current_state = State.CHASE
		return
	velocity.x = facing * walk_speed
	if is_on_floor() and turn_cooldown <= 0:
		if not floor_check.is_colliding() or wall_check.is_colliding():
			facing *= -1
			turn_cooldown = 0.5

func logic_chase(delta: float) -> void:
	if not player:
		current_state = State.PATROL
		return
	if "is_dashing" in player and player.is_dashing:
		velocity.x = move_toward(velocity.x, 0, 400 * delta)
		return
	
	var dist_x = player.global_position.x - global_position.x
	var dist_y = player.global_position.y - global_position.y
	var direction = sign(dist_x)
	
	if abs(dist_x) < attack_range and can_attack and is_on_floor():
		if dist_y > -60: 
			start_attack()
			return
		
	var target_speed = chase_speed * (1.3 if in_rage else 1.0)
	if is_on_floor():
		velocity.x = direction * target_speed
		if direction != 0 and turn_cooldown <= 0: 
			facing = direction
		
		var should_jump = wall_check.is_colliding() or \
						 (not floor_check.is_colliding() and abs(dist_x) > 30) or \
						 (player.global_position.y < global_position.y - 80 and abs(dist_x) < 100)
		if should_jump:
			velocity.y = jump_velocity
	else:
		velocity.x = move_toward(velocity.x, direction * target_speed, air_control * delta)

func start_attack() -> void:
	if current_state == State.DEAD: return
	current_state = State.ATTACK
	can_attack = false
	
	# Рывок
	velocity.x = facing * lunge_force
	
	# Ускоряем саму анимацию через код
	sprite.speed_scale = attack_speed_mult
	sprite.play("attack")
	
	# ВАЖНО: Мы убрали длинный таймер на 1.2 секунды. 
	# Теперь функция end_attack() вызовется СРАЗУ по сигналу завершения анимации.

func end_attack() -> void:
	if current_state == State.DEAD: return
	current_state = State.CHASE
	hitbox.disabled = true
	sprite.speed_scale = 1.0 # Возвращаем скорость в норму
	
	# Кулдаун между сериями атак
	var cd = attack_cooldown * (0.5 if in_rage else 1.0)
	get_tree().create_timer(cd).timeout.connect(func(): can_attack = true)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= max_health / 2: in_rage = true
	var t = create_tween()
	t.tween_property(sprite, "modulate", Color(5, 0.5, 0.5, 1), 0.1)
	t.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)
	if health <= 0: die()

func die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	remove_from_group("enemies")
	sprite.speed_scale = 1.0
	var frames = sprite.sprite_frames
	if frames.has_animation("die"):
		frames.set_animation_loop("die", false)
	sprite.play("die")

func update_facing() -> void:
	var floor_offset = 30.0 
	var wall_offset = 35.0
	var sword_offset = 25.0
	sprite.scale.x = abs(sprite.scale.x) * facing
	sword_area.position.x = sword_offset * facing
	floor_check.position.x = floor_offset * facing
	wall_check.target_position.x = wall_offset * facing

func update_animation() -> void:
	if current_state == State.DEAD: return
	
	if current_state == State.ATTACK:
		# Теперь удар засчитывается на 3-5 кадрах (адаптировано под скорость)
		hitbox.disabled = not (sprite.frame >= 3 and sprite.frame <= 5)
		return
		
	if is_on_floor():
		if abs(velocity.x) > 10:
			sprite.play("walk")
			sprite.speed_scale = 1.4 if in_rage else 1.0
		else:
			sprite.play("idle")
			sprite.speed_scale = 1.0
	else:
		if sprite.sprite_frames.has_animation("jump"):
			sprite.play("jump")

func _on_sword_shape_body_entered(body: Node2D) -> void:
	if current_state == State.ATTACK and not hitbox.disabled:
		if body.has_method("take_damage"):
			body.take_damage(1.0)
			hitbox.set_deferred("disabled", true)

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		end_attack()
	elif sprite.animation == "die":
		queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"): player = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player: player = null
