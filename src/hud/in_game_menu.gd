extends CanvasLayer

func _on_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")

func _ready():
	for coin in get_tree().get_nodes_in_group("coins"):
		coin.connect("collected", Callable($HUD, "add_points"))
