extends TextureButton

# Используй @onready или прямой путь. 
# Если звук лежит в корне сцены меню, а не в кнопке, путь будет типа $"../ClickSound"
@onready var click_sound = $"../../ClickSound"

func _ready():
	texture_normal = load("res://res/buttons/start/start1.png")
	texture_hover = load("res://res/buttons/start/start2.png")
	texture_pressed = load("res://res/buttons/start/start3.png")
	size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
	stretch_mode = TextureButton.STRETCH_SCALE
	
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

func _on_pressed():
	disabled = true 
	
	if click_sound:
		click_sound.play()
	
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://world_map/world_map.tscn")
