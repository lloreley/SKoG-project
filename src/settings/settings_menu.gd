extends CanvasLayer

@onready var volume_slider = $MasterVolumeSlider
@onready var fullscreen_check = $CheckBox
@onready var res_option = $OptionButton

# Узлы звуков (убедитесь, что они добавлены в сцену с такими именами)
@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound

var resolutions: Dictionary = {
	"640x480 (4:3)": Vector2i(640, 480),
	"1024x768 (4:3)": Vector2i(1024, 768),
	"1280x720 (HD)": Vector2i(1280, 720),
	"1366x768": Vector2i(1366, 768),
	"1600x900": Vector2i(1600, 900),
	"1920x1080 (FHD)": Vector2i(1920, 1080),
	"2560x1080 (UW)": Vector2i(2560, 1080),
	"2560x1440 (2K)": Vector2i(2560, 1440),
	"3840x2160 (4K)": Vector2i(3840, 2160)
}

const SAVE_PATH = "user://settings.cfg"

func _ready():
	res_option.clear()
	for res_text in resolutions:
		res_option.add_item(res_text)
	
	volume_slider.min_value = 0.001
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	
	# Подключаем звуки ко всем кнопкам, чекбоксам и спискам в этой сцене
	var all_buttons = find_children("", "BaseButton", true)
	for button in all_buttons:
		button.mouse_entered.connect(_on_button_hover)
		button.pressed.connect(_on_button_pressed)
	
	# Звук для выпадающего списка
	res_option.item_selected.connect(func(_index): _on_button_pressed())
	
	load_settings()

# --- Функции звука ---

func _on_button_hover():
	if hover_sound:
		hover_sound.play()

func _on_button_pressed():
	if click_sound:
		click_sound.play()

# --- Логика настроек ---

func apply_settings():
	var bus_index = AudioServer.get_bus_index("Master")
	# Использование linear_to_db исключает ошибки с логарифмами
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume_slider.value))
	AudioServer.set_bus_mute(bus_index, volume_slider.value <= 0.01)

	var selected_res = resolutions.values()[res_option.selected]

	if fullscreen_check.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		DisplayServer.window_set_size(selected_res)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(selected_res)
		var screen_rect = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
		DisplayServer.window_set_position(screen_rect.position + (screen_rect.size / 2) - (selected_res / 2))
	
	# Синхронизация масштаба для точности кликов мыши
	get_tree().root.content_scale_size = selected_res

func save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", volume_slider.value)
	config.set_value("video", "fullscreen", fullscreen_check.button_pressed)
	config.set_value("video", "res_index", res_option.selected)
	config.save(SAVE_PATH)

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	
	if err == OK:
		volume_slider.value = config.get_value("audio", "master_volume", 0.5)
		fullscreen_check.button_pressed = config.get_value("video", "fullscreen", false)
		res_option.select(config.get_value("video", "res_index", 5))
	else:
		volume_slider.value = 0.5
		fullscreen_check.button_pressed = false
		res_option.select(5)
	
	apply_settings()

func _on_accept_btn_pressed():
	apply_settings()
	save_settings()
	# Небольшая задержка, чтобы звук клика успел прозвучать до смены сцены
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")

func _on_cancel_btn_pressed():
	load_settings()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")
