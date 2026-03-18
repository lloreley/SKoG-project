extends Area2D

@export var damage: float = 1

func _on_body_entered(body: Node2D) -> void:
	print("Кто-то наступил на ловушку: ", body.name)
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
