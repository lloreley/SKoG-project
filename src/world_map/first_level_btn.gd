extends TextureButton

func _ready():
	texture_normal = load("res://res/buttons/1/1_1.png")
	texture_hover = load("res://res/buttons/1/1_2.png")
	texture_pressed = load("res://res/buttons/1/1_3.png")
	size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
	stretch_mode = TextureButton.STRETCH_SCALE

func _on_pressed():
	disabled = true 
