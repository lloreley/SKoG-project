extends TextureButton
class_name CustomButton

@export var normal_texture: Texture2D
@export var hover_texture: Texture2D
@export var pressed_texture: Texture2D

func _ready() -> void:
	if normal_texture:
		texture_normal = normal_texture
	if hover_texture:
		texture_hover = hover_texture
	if pressed_texture:
		texture_pressed = pressed_texture
	
	self.expand = true
	self.stretch_mode = TextureButton.STRETCH_KEEP
