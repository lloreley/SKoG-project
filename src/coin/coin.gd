extends Area2D

@export var points: int = 10
@onready var audio = $AudioStreamPlayer2D
@onready var sprite = $AnimatedSprite2D
@onready var collision = $CollisionShape2D

func _ready():
	add_to_group("coins")

func _on_body_entered(body):
	if body.name == "Character" or body.is_in_group("player"):
		collect()

func collect():
	collision.set_deferred("disabled", true)
	ScoreManager.add_score(points)
	sprite.visible = false
	
	if audio:
		audio.play()
		audio.finished.connect(queue_free)
	else:
		queue_free()
