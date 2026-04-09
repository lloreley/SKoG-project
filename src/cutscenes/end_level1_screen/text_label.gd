extends RichTextLabel

@onready var type_sound = $TypeSound
@onready var fade_overlay = $"../FadeOverlay" 

@export var typing_speed: float = 0.05
@export var sound_every_n_chars: int = 2 

var dialog_lines: Array = [
	"Границы сна окончательно стерлись. Ты больше не в безопасности.",
	"Первые шаги дались нелегко, но это была лишь тень того, что ждет впереди.",
	"Лес сгущается, и тени за деревьями начинают двигаться быстрее.",
	"Ты слышишь? Тишина здесь обманчива, она лишь скрывает чей-то голод.",
	"Твой путь только начинается, и старые тропы больше не приведут домой.",
	"Соберись. Каждое решение теперь может стать последним.",
	"Туман впереди скрывает не только дорогу, но и тех, кто в нем живет.",
	"[shake rate=20 level=10]ИДИ ВПЕРЕД. И НЕ ОГЛЯДЫВАЙСЯ.[/shake]"
]

var current_line_index: int = 0
var current_visible: float = 0.0 
var last_visible_chars: int = 0
var is_typing: bool = false
var is_fading: bool = false # Флаг, чтобы заблокировать нажатия в самом конце
var active_tween: Tween
var full_accumulated_text: String = ""

func _ready():
	fit_content = true 
	bbcode_enabled = true
	add_theme_constant_override("line_separation", 2) 
	
	if fade_overlay:
		fade_overlay.modulate.a = 0
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE # Чтобы не блокировал клики
		
	visible_characters = 0
	show_current_line()

func show_current_line():
	if is_fading: return

	if current_line_index < dialog_lines.size():
		var next_phrase = dialog_lines[current_line_index].strip_edges()
		if full_accumulated_text != "":
			full_accumulated_text += " " 
			
		var styled_phrase = "[shake rate=20 level=10]" + next_phrase + "[/shake]"
		if "[" in next_phrase:
			styled_phrase = next_phrase
			
		full_accumulated_text += styled_phrase
		start_typing()
	else:
		is_fading = true
		start_screen_fade()

func start_typing():
	text = full_accumulated_text
	
	# Устанавливаем начальную позицию видимости (пропускаем старый текст)
	var previous_text_length = get_clean_text_length() - get_last_phrase_clean_length()
	last_visible_chars = previous_text_length
	visible_characters = last_visible_chars
	current_visible = float(visible_characters)
	
	is_typing = true
	var total_chars = get_clean_text_length()
	
	if active_tween: active_tween.kill()
	active_tween = create_tween()
	
	# Анимируем только новую часть
	active_tween.tween_property(self, "current_visible", float(total_chars), (total_chars - last_visible_chars) * typing_speed)
	active_tween.finished.connect(func(): is_typing = false)

func _input(event):
	if is_fading: return

	if event.is_action_pressed("ui_accept"):
		if is_typing:
			# 1. Мгновенно допечатываем текущую фразу
			is_typing = false
			if active_tween: active_tween.kill()
			current_visible = float(get_clean_text_length())
			visible_characters = get_clean_text_length()
			
			# 2. Сразу переходим к следующей фразе
			current_line_index += 1
			show_current_line()
		else:
			# Если текст уже был допечатан, просто идем дальше
			current_line_index += 1
			show_current_line()

func start_screen_fade():
	var fade_tween = create_tween()
	fade_tween.parallel().tween_property(self, "modulate:a", 0.0, 1.0)
	if fade_overlay:
		fade_tween.parallel().tween_property(fade_overlay, "modulate:a", 1.0, 2.0)
	
	fade_tween.finished.connect(_on_fade_finished)

func _on_fade_finished():
	get_tree().change_scene_to_file("res://world_map/world_map.tscn")

func _process(_delta):
	if not is_typing: return
	visible_characters = int(current_visible)
	
	if visible_characters > last_visible_chars:
		var total_chars = get_clean_text_length()
		if visible_characters % sound_every_n_chars == 0 and visible_characters < total_chars:
			play_type_sound()
		last_visible_chars = visible_characters

func play_type_sound():
	if type_sound and type_sound.stream:
		if type_sound.playing: type_sound.stop()
		type_sound.pitch_scale = randf_range(0.95, 1.05)
		type_sound.play()

func get_clean_text_length() -> int:
	return get_parsed_text().length()

func get_last_phrase_clean_length() -> int:
	var raw_phrase = dialog_lines[current_line_index].strip_edges()
	# Убираем теги для расчета длины
	var clean = raw_phrase.replace("[shake rate=30 level=12]", "").replace("[/shake]", "").replace("[shake rate=20 level=10]", "")
	return clean.length()
