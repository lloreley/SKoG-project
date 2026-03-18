extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
	elif body.is_in_group("enemies"):
		body.queue_free()
	elif body.name == "Character":
		get_tree().change_scene_to_file("res://scenes/die_screen.tscn")
