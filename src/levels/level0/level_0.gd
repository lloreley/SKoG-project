extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ScoreManager.last_visited_level = get_tree().current_scene.scene_file_path


func _on_leave_zone_body_entered(body: Node2D) -> void:
	if body.name == "Character" or body.is_in_group("player"):
		SaveManager.unlock_next_level(0)
		get_tree().change_scene_to_file("res://world_map/world_map.tscn")
