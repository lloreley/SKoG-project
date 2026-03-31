extends Node2D

# Позволяет менять спрайты и текст прямо из редактора уровня
@export var button_frames: SpriteFrames
@export var action_text: String = "Действие"
@export var action_name: String = "ui_accept" # Имя клавиши в Input Map

@onready var sprite = $AnimatedSprite2D
@onready var label = $Label

func _ready():
	if button_frames:
		sprite.sprite_frames = button_frames
		sprite.play("default")
	
	if label:
		label.text = action_text
	
	# Скрываем по умолчанию (будем показывать через триггер)
	modulate.a = 0

func show_hint():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_hint():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)

func _input(event):
	# Если игрок нажал нужную кнопку — убираем подсказку
	if event.is_action_pressed(action_name) and modulate.a > 0:
		hide_hint()
