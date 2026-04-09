extends TextureButton

func _ready():
	texture_normal = load("res://res/buttons/restart/restart1.png")
	texture_hover = load("res://res/buttons/restart/restart2.png")
	texture_pressed = load("res://res/buttons/restart/restart3.png")
	# Убедись, что эти настройки не перекрывают настройки в инспекторе, 
	# если ты менял их там вручную
	size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
	stretch_mode = TextureButton.STRETCH_SCALE

func _on_pressed() -> void:
	# Ждем немного для проигрывания звука клика
	await get_tree().create_timer(0.4).timeout
	
	# Сброс очков
	ScoreManager.total_score = 0
	ScoreManager.score_updated.emit(0)
	
	# Загружаем уровень, путь к которому мы сохранили ранее
	var level_to_load = ScoreManager.last_visited_level
	
	if level_to_load != "":
		get_tree().change_scene_to_file(level_to_load)
