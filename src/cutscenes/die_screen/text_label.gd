extends RichTextLabel

@onready var type_sound = $TypeSound
@onready var fade_overlay = $"../FadeOverlay" 

@export var typing_speed: float = 0.05
@export var sound_every_n_chars: int = 2 

var dialog_lines: Array = [
	"В этот раз не удалось.",
	"[shake rate=30 level=12]Ты погиб.[/shake]"
]

var current_line_index: int = 0
var is_typing: bool = false
var is_fading: bool = false

func _ready():
	bbcode_enabled = true
	fit_content = true
	visible_ratio = 0.0
	
	if fade_overlay:
		fade_overlay.modulate.a = 0
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	show_next_line()

func show_next_line():
	if current_line_index >= dialog_lines.size():
		start_screen_fade()
		return

	# Добавляем новую строку к уже существующему тексту
	if text != "":
		text += "\n"
	text += dialog_lines[current_line_index]
	
	start_typing()

func start_typing():
	is_typing = true
	# Анимируем visible_ratio от текущего значения до 1.0
	var tween = create_tween()
	# Длительность зависит от количества новых символов
	var duration = dialog_lines[current_line_index].length() * typing_speed
	
	tween.tween_property(self, "visible_ratio", 1.0, duration)
	tween.finished.connect(func(): is_typing = false)

func _input(event):
	if is_fading: return
	
	if event.is_action_pressed("ui_accept"):
		if is_typing:
			# Пропускаем анимацию печати
			is_typing = false
			var tween = create_tween() # Убиваем старый твин через создание нового на том же объекте (или храни ссылку)
			visible_ratio = 1.0
		else:
			current_line_index += 1
			show_next_line()

func _process(_delta):
	# Звук печати: ориентируемся на количество видимых символов
	if is_typing:
		var current_chars = get_total_character_count() * visible_ratio
		if int(current_chars) % sound_every_n_chars == 0:
			play_type_sound()

func play_type_sound():
	if type_sound and not type_sound.playing:
		type_sound.pitch_scale = randf_range(0.9, 1.1)
		type_sound.play()

func start_screen_fade():
	if is_fading: return
	is_fading = true
	
	if fade_overlay:
		var fade_tween = create_tween()
		# Затемняем экран, но ТЕКСТ НЕ ТРОГАЕМ (он остается)
		fade_tween.tween_property(fade_overlay, "modulate:a", 1.0, 2.0)
		fade_tween.finished.connect(_on_fade_finished)

func _on_fade_finished():
	# Тут можно сменить сцену: get_tree().change_scene_to_file(...)
	pass
