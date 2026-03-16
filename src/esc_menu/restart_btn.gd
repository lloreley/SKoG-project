extends TextureButton

func _ready():
	texture_normal = load("res://res/buttons/restart/restart1.png")
	texture_hover = load("res://res/buttons/restart/restart2.png")
	texture_pressed = load("res://res/buttons/restart/restart3.png")
	size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
	stretch_mode = TextureButton.STRETCH_SCALE
