extends Node2D

@export_group("Level Textures")
@export var locked_texture: Texture2D # Сюда в инспекторе кидаешь картинку закрытого уровня

@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound

# Массив кнопок. Убедись, что порядок соответствует индексам уровней (0, 1, 2)
@onready var level_buttons = [$ZeroLevelBtn, $FirstLevelBtn, $SecondLevelBtn]

func _ready() -> void:
	# 1. Загружаем прогресс из текущего слота, который мы выбрали в меню
	var save_data = SaveManager.load_save(SaveManager.current_slot)
	var max_opened = save_data.get("max_level", 0)
	
	# 2. Настраиваем каждую кнопку в цикле
	for i in range(level_buttons.size()):
		var btn = level_buttons[i]
		
		# Подключаем общие звуки
		btn.mouse_entered.connect(_on_button_hover)
		btn.pressed.connect(_on_button_pressed)
		
		# ПРОВЕРКА ПРОГРЕССА:
		if i <= max_opened:
			# Уровень доступен
			btn.disabled = false
		else:
			# Уровень заблокирован
			btn.disabled = true
			if locked_texture:
				btn.texture_disabled = locked_texture

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")

# --- ЗВУКОВАЯ ЛОГИКА ---

func _on_button_hover() -> void:
	if hover_sound:
		hover_sound.stop() # Чтобы звук можно было "спамить" при быстром наведении
		hover_sound.play()

func _on_button_pressed() -> void:
	if click_sound:
		click_sound.play()

# --- ПЕРЕХОДЫ ПО НАЖАТИЮ (привязаны через сигналы в редакторе) ---

func _on_zero_level_btn_pressed() -> void:
	_start_level("res://levels/level0/level0.tscn")

func _on_first_level_btn_pressed() -> void:
	_start_level("res://cutscenes/start_screen/start_screen.tscn")

func _on_second_level_btn_pressed() -> void:
	_start_level("res://levels/level2/level2.tscn")

# --- ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ ---

func _start_level(path: String):
	# Небольшая задержка, чтобы успел проиграться звук клика
	await get_tree().create_timer(0.4).timeout
	# Плавное затухание музыки перед сменой сцены
	if MusicManager:
		MusicManager.fade_out(1.0)
	get_tree().change_scene_to_file(path)
