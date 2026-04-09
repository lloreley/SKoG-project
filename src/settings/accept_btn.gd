extends TextureButton

func _ready():
	texture_normal = load("res://res/buttons/accept/accept1.png")
	texture_pressed = load("res://res/buttons/accept/accept2.png")
	size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
	stretch_mode = TextureButton.STRETCH_SCALE
