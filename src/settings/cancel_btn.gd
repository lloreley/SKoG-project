extends TextureButton

func _ready():
	texture_normal = load("res://res/buttons/cancel/cancel1.png")
	texture_pressed = load("res://res/buttons/cancel/cancel2.png")
	size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
	stretch_mode = TextureButton.STRETCH_SCALE


func _on_pressed() -> void:
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")
