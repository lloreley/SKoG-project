@tool
extends Area2D

# --- ГРУППА НАСТРОЕК ДЛЯ РЕДАКТОРА ---
@export_group("Hint Settings")

# Текст подсказки
@export var action_text: String = "Действие":
	set(value):
		action_text = value
		# Обновляем текст в реальном времени в редакторе
		if is_node_ready() and has_node("Label"):
			$Label.text = value

# Набор кадров для иконки кнопки
@export var button_frames: SpriteFrames:
	set(value):
		button_frames = value
		if is_node_ready() and has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.sprite_frames = value

# Какое действие из Input Map мы показываем
@export var button_animation_name: String = "default":
	set(value):
		button_animation_name = value
		if is_node_ready() and has_node("AnimatedSprite2D") and button_frames:
			if $AnimatedSprite2D.sprite_frames.has_animation(value):
				$AnimatedSprite2D.play(value)

# Какое действие нужно нажать, чтобы скрыть подсказку вручную
@export var close_action_name: String = "ui_accept"

@export_group("Physics")
# С какими телами взаимодействуем? (Обычно Layer 1 - это игрок)
@export_flags_2d_physics var collision_mask_flags: int = 1:
	set(value):
		collision_mask_flags = value
		collision_mask = value

# --- ДОЧЕРНИЕ УЗЛЫ ---
@onready var sprite = $AnimatedSprite2D
@onready var label = $Label

func _ready():
	# Синхронизируем маску коллизии
	collision_mask = collision_mask_flags

	# Первичная настройка визуала
	if label:
		label.text = action_text
	if sprite and button_frames:
		sprite.sprite_frames = button_frames
		if sprite.sprite_frames.has_animation(button_animation_name):
			sprite.play(button_animation_name)
		else:
			sprite.play("default")
	
	if Engine.is_editor_hint():
		# В редакторе ВСЕГДА показываем
		modulate.a = 1.0
		show()
	else:
		# В игре ВСЕГДА прячем при старте
		modulate.a = 0.0
		# Подключаем сигналы кодом, чтобы не делать это вручную в редакторе
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)
		if not body_exited.is_connected(_on_body_exited):
			body_exited.connect(_on_body_exited)

# --- ЛОГИКА ОТОБРАЖЕНИЯ (ТОЛЬКО ИГРА) ---

func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint(): return
	
	# Проверяем, что это игрок (по имени узла или группе)
	if body.name == "Character" or body.name == "Player" or body.is_in_group("player"):
		show_hint()

func _on_body_exited(body: Node2D) -> void:
	if Engine.is_editor_hint(): return
	
	if body.name == "Character" or body.name == "Player" or body.is_in_group("player"):
		hide_hint()

func show_hint():
	# Убиваем запущенные твины, если они есть, чтобы не было конфликтов
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func hide_hint():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _input(event):
	if Engine.is_editor_hint(): return
	
	# Если подсказка видна и нажата кнопка закрытия
	if modulate.a > 0.8 and event.is_action_pressed(close_action_name):
		hide_hint()
