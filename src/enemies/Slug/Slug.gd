extends CharacterBody2D

@export_group("Movement")
@export var speed : float = 40.0
@export var gravity : float = 1800.0

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_check : RayCast2D = $FloorChecker
@onready var wall_check : RayCast2D = $WallChecker
@onready var hitbox : Area2D = $Hitbox

var facing : int = 1
var turn_cooldown : float = 0.0

func _ready() -> void:
	# Добавляем в группу для взаимодействия
	add_to_group("enemies")
	
	# Автоматически запускаем анимацию
	if sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")
	
	# Подключаем урон
	if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	# Настройка RayCast (чтобы точно видели пол)
	floor_check.enabled = true
	wall_check.enabled = true

func _physics_process(delta: float) -> void:
	if turn_cooldown > 0:
		turn_cooldown -= delta

	# Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0 # Обнуляем вертикальную скорость на земле

	# Движение
	velocity.x = facing * speed

	# Разворот у края или стены
	if is_on_floor() and turn_cooldown <= 0:
		# Если впереди пусто или стена
		if not floor_check.is_colliding() or wall_check.is_colliding():
			_flip()

	move_and_slide()
	_update_visuals()

func _flip() -> void:
	facing *= -1
	turn_cooldown = 0.2

func _update_visuals() -> void:
	sprite.flip_h = (facing > 0)
	
	# Важно: меняем положение лучей, чтобы они всегда были ПЕРЕД улиткой
	floor_check.position.x = 15 * facing
	wall_check.target_position.x = 20 * facing

func _on_hitbox_body_entered(body: Node2D) -> void:
	# Бьем только игрока
	if body.has_method("take_damage"):
		body.take_damage(1.0)
