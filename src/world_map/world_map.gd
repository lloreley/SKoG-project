extends Node2D

@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound

func _ready() -> void:
	var all_buttons = find_children("", "TextureButton", true)
	
	for button in all_buttons:
		button.mouse_entered.connect(_on_button_hover)
		button.pressed.connect(_on_button_pressed)

# Используем _unhandled_input, чтобы ESC срабатывал, даже если фокус не на кнопке
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"): # По умолчанию "ui_cancel" привязан к ESC
		get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")

func _on_button_hover() -> void:
	if hover_sound:
		# Если звук уже играет, останавливаем, чтобы он начался заново (для быстрых движений)
		hover_sound.stop()
		hover_sound.play()

func _on_button_pressed() -> void:
	if click_sound:
		click_sound.play()

func _on_zero_level_btn_pressed() -> void:
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://levels/level0/level0.tscn")


func _on_first_level_btn_pressed() -> void:
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://cutscenes/start_screen/start_screen.tscn")
