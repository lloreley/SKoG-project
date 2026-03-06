extends TextureButton

func _ready():
	texture_normal = load("res://res/buttons/start/start1.png")
	texture_hover = load("res://res/buttons/start/start2.png")
	texture_pressed = load("res://res/buttons/start/start3.png")
	size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
	stretch_mode = TextureButton.STRETCH_SCALE
	pressed.connect(_on_pressed)

func _on_pressed():
	# get_tree().change_scene_to_file("res://world/world.tscn")
	get_tree().change_scene_to_file("res://cutscenes/start_screen/start_screen.tscn")
