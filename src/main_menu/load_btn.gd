extends TextureButton

func _ready():
	texture_normal = load("res://res/buttons/load/load1.png")
	texture_hover = load("res://res/buttons/load/load2.png")
	texture_pressed = load("res://res/buttons/load/load3.png")
	size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
	stretch_mode = TextureButton.STRETCH_SCALE
	
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

func _on_pressed():
	disabled = true 
	await get_tree().create_timer(0.4).timeout
	SaveManager.is_loading_mode = true
	get_tree().change_scene_to_file("res://save_menu/save_menu.tscn")
