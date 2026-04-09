extends CanvasLayer

@export_group("New Game Textures")
@export var tex_new_normal: Texture2D
@export var tex_new_hover: Texture2D
@export var tex_new_pressed: Texture2D

@export_group("Load Game Textures")
@export var tex_load_normal: Texture2D
@export var tex_load_hover: Texture2D
@export var tex_load_pressed: Texture2D

@export_group("Delete Textures")
@export var tex_del_normal: Texture2D
@export var tex_del_pressed: Texture2D
@export var tex_del_disabled: Texture2D 

@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound
@onready var confirm_dialog = $RewriteConfirm

@onready var slot_buttons = [$Slot1, $Slot2, $Slot3]
@onready var delete_buttons = [$Delete1, $Delete2, $Delete3]
@onready var info_labels = [$Label1, $Label2, $Label3]

var pending_slot: int = -1 

func _ready() -> void:
	# 1. Сначала настраиваем диалог (важен порядок!)
	confirm_dialog.exclusive = true # Запрещает клики мимо окна
	confirm_dialog.process_mode = Node.PROCESS_MODE_ALWAYS # Чтобы окно работало, даже если пауза
	
	if not confirm_dialog.confirmed.is_connected(_on_rewrite_confirmed):
		confirm_dialog.confirmed.connect(_on_rewrite_confirmed)
	if not confirm_dialog.canceled.is_connected(_on_rewrite_canceled):
		confirm_dialog.canceled.connect(_on_rewrite_canceled)

	# 2. Настройка звуков для кнопок (кроме кнопок внутри диалога!)
	var all_buttons = find_children("", "TextureButton", true)
	for button in all_buttons:
		if not button.mouse_entered.is_connected(_on_button_hover):
			button.mouse_entered.connect(_on_button_hover)
		if not button.pressed.is_connected(_on_button_pressed):
			button.pressed.connect(_on_button_pressed)

	# 3. Настройка слотов
	for i in range(slot_buttons.size()):
		var slot_index = i + 1
		delete_buttons[i].ignore_texture_size = true
		delete_buttons[i].stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		
		_update_slot_visuals(slot_index)
		
		# Очищаем старые связи, если они были (на всякий случай)
		for sig in slot_buttons[i].pressed.get_connections():
			slot_buttons[i].pressed.disconnect(sig.callable)
		
		slot_buttons[i].pressed.connect(_on_slot_pressed.bind(slot_index))
		
		for sig in delete_buttons[i].pressed.get_connections():
			delete_buttons[i].pressed.disconnect(sig.callable)
			
		delete_buttons[i].pressed.connect(_on_delete_pressed.bind(slot_index))

func _update_slot_visuals(slot_index: int) -> void:
	var btn = slot_buttons[slot_index - 1]
	var del_btn = delete_buttons[slot_index - 1]
	var label = info_labels[slot_index - 1]
	
	del_btn.texture_hover = null
	
	if SaveManager.save_exists(slot_index):
		var data = SaveManager.load_save(slot_index)
		label.text = "УРОВЕНЬ " + str(data.get("max_level", 0))
		btn.texture_normal = tex_load_normal
		btn.texture_hover = tex_load_hover
		btn.texture_pressed = tex_load_pressed
		btn.disabled = false
		del_btn.disabled = false
		del_btn.texture_normal = tex_del_normal
		del_btn.texture_hover = tex_del_normal
		del_btn.texture_pressed = tex_del_pressed
	else:
		label.text = "ПУСТО"
		btn.texture_normal = tex_new_normal
		btn.texture_hover = tex_new_hover
		btn.texture_pressed = tex_new_pressed
		btn.disabled = SaveManager.is_loading_mode
		del_btn.disabled = true
		del_btn.texture_disabled = tex_del_disabled

func _on_slot_pressed(slot_index: int) -> void:
	# Если мы уже ждем подтверждения, блокируем новые нажатия
	if pending_slot != -1: return 
	
	SaveManager.current_slot = slot_index
	
	if SaveManager.is_loading_mode:
		if SaveManager.save_exists(slot_index):
			get_tree().change_scene_to_file("res://world_map/world_map.tscn")
	else:
		if SaveManager.save_exists(slot_index):
			pending_slot = slot_index
			_set_buttons_disabled(true) # ВЫКЛЮЧАЕМ кнопки, чтобы не было "даблкликов"
			confirm_dialog.popup_centered()
		else:
			_start_new_game(slot_index)

func _on_rewrite_confirmed() -> void:
	var slot_to_start = pending_slot
	pending_slot = -1
	_start_new_game(slot_to_start)

func _on_rewrite_canceled() -> void:
	pending_slot = -1
	_set_buttons_disabled(false) # ВКЛЮЧАЕМ кнопки обратно

func _set_buttons_disabled(is_disabled: bool) -> void:
	for btn in slot_buttons:
		btn.set_block_signals(is_disabled) # Полная блокировка сигналов
	for del in delete_buttons:
		del.set_block_signals(is_disabled)

func _start_new_game(slot: int) -> void:
	SaveManager.write_save(slot, {"max_level": 0})
	get_tree().change_scene_to_file("res://world_map/world_map.tscn")

func _on_delete_pressed(slot_index: int) -> void:
	if pending_slot != -1: return
	SaveManager.delete_save(slot_index)
	_update_slot_visuals(slot_index)

func _on_button_hover() -> void:
	if hover_sound: hover_sound.play()

func _on_button_pressed() -> void:
	if click_sound: click_sound.play()

func _on_back_button_pressed() -> void:
	if pending_slot != -1: return
	get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")
