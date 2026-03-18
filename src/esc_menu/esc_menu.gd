extends CanvasLayer

@onready var continue_btn = $VBoxContainer/ContinueBtn

func _ready():
	# Скрываем меню при старте игры
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	# Если нажата кнопка паузы (Esc)
	if event.is_action_pressed("ui_pause"):
		toggle_pause()

func toggle_pause():
	var new_pause_state = !get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state
	
	if new_pause_state:
		# Показываем мышь и даем фокус кнопке
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		continue_btn.grab_focus()
	else:
		# Скрываем мышь (если это нужно для геймплея)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Сигналы кнопок теперь просто вызывают общую функцию
func _on_continue_btn_pressed():
	toggle_pause()

func _on_restart_btn_pressed():
	get_tree().paused = false
	ScoreManager.total_score = 0
	ScoreManager.score_updated.emit(0)
	get_tree().reload_current_scene()

func _on_to_main_menu_btn_pressed():
	get_tree().paused = false
	ScoreManager.total_score = 0
	ScoreManager.score_updated.emit(0)
	get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")
