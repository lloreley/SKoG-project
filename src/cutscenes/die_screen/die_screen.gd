extends CanvasLayer

@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound

func _ready() -> void:
	var all_buttons = find_children("", "TextureButton", true)
	
	for button in all_buttons:
		button.mouse_entered.connect(_on_button_hover)
		button.pressed.connect(_on_button_pressed)

func _on_button_hover() -> void:
	if hover_sound:
		hover_sound.play()

func _on_button_pressed() -> void:
	if click_sound:
		click_sound.play()
