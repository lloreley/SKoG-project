extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_leave_zone_2_body_entered(body: Node2D) -> void:
	if body.name == "Character" or body.is_in_group("player"):
		SaveManager.unlock_next_level(2)
		get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")
