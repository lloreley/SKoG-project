extends TextureButton

const ON_NORMAL = preload("res://res/buttons/sound/sound_on1.png")
const ON_PRESSED = preload("res://res/buttons/sound/sound_on2.png")
const OFF_NORMAL = preload("res://res/buttons/sound/sound_off1.png")
const OFF_PRESSED = preload("res://res/buttons/sound/sound_off2.png")

var is_sound_on: bool = true

func _ready():
	size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
	stretch_mode = TextureButton.STRETCH_SCALE
	
	_update_textures()
	self.pressed.connect(_on_pressed)

func _on_pressed():
	is_sound_on = !is_sound_on
	_update_textures()
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), !is_sound_on)

func _update_textures():
	if is_sound_on:
		texture_normal = ON_NORMAL
		texture_pressed = ON_PRESSED
	else:
		texture_normal = OFF_NORMAL
		texture_pressed = OFF_PRESSED
