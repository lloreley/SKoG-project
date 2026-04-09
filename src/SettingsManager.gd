extends Node

const SAVE_PATH = "user://settings.cfg"

# Те же разрешения, что и в меню
var resolutions: Array = [
	Vector2i(640, 480), Vector2i(1024, 768), Vector2i(1280, 720),
	Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080),
	Vector2i(2560, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)
]

func _ready():
	# Этот код выполнится ОДИН раз при запуске игры
	load_and_apply_settings()

func load_and_apply_settings():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	
	if err == OK:
		var volume = config.get_value("audio", "master_volume", 0.5)
		var is_fullscreen = config.get_value("video", "fullscreen", false)
		var res_index = config.get_value("video", "res_index", 5)
		
		apply_all(volume, is_fullscreen, res_index)
	else:
		# Если файла нет, применяем дефолтные настройки
		apply_all(0.5, false, 5)

func apply_all(volume: float, fullscreen: bool, res_idx: int):
	# 1. Применяем звук
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume))
	AudioServer.set_bus_mute(bus_index, volume <= 0.01)
	
	# 2. Применяем видео
	var selected_res = resolutions[res_idx]
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		DisplayServer.window_set_size(selected_res)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(selected_res)
		
		# Центрируем окно
		var screen_rect = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
		DisplayServer.window_set_position(screen_rect.position + (screen_rect.size / 2) - (selected_res / 2))
