extends TextureButton

func _ready():
	texture_normal = load("res://res/buttons/quit/quit1.png")
	texture_hover = load("res://res/buttons/quit/quit2.png")
	texture_pressed = load("res://res/buttons/quit/quit3.png")
	size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
	stretch_mode = TextureButton.STRETCH_SCALE
	self.pressed.connect(_on_quit_button_pressed)

func _on_quit_button_pressed():
	get_tree().quit()
