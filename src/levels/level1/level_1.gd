extends Node2D

func _ready() -> void:
	ScoreManager.last_visited_level = get_tree().current_scene.scene_file_path

func _process(delta: float) -> void:
	pass

func _on_leave_zone_body_entered(body: Node2D) -> void:
	if body.name == "Character" or body.is_in_group("player"):
		SaveManager.unlock_next_level(1)
		get_tree().change_scene_to_file("res://cutscenes/end_level1_screen/end_level1_screen.tscn")
