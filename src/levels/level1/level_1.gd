extends Node2D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_leave_zone_body_entered(body: Node2D) -> void:
	if body.name == "Character" or body.is_in_group("player"):
		get_tree().change_scene_to_file("res://world_map/world_map.tscn")
