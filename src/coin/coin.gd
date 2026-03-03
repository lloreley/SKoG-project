extends Area2D


signal collected(points)
@export var points: int = 10

func _ready():
	add_to_group("coins")

func _on_body_entered(body):
	if body.name == "Character":
		emit_signal("collected", points)
		print("Монетка собрана")
		queue_free()
