extends Area2D

# Настройки сундука
@export_enum("simple", "gold") var chest_type: String = "simple"
@export var bonus_points: int = 50

@onready var sprite = $Chest
@onready var e_button = $EBtn
@onready var open_sound = $OpenSound

var is_opened: bool = false
var player_in_range: bool = false

func _ready():
	# Кнопка скрыта, но её внутренняя анимация уже может работать в фоне
	e_button.visible = false
	sprite.play("idle_" + chest_type)
	
func _process(_delta):
	if player_in_range and not is_opened:
		if Input.is_action_just_pressed("interact"):
			open_chest()

func _on_interact_body_entered(body):
	if (body.name == "Character" or body.is_in_group("player")) and not is_opened:
		player_in_range = true
		
		# Показываем кнопку только через прозрачность (modulate)
		e_button.visible = true
		e_button.modulate.a = 0
		
		# Запускаем анимацию самой кнопки (если не стоит Autoplay)
		e_button.play() 
		
		var tween = create_tween()
		tween.tween_property(e_button, "modulate:a", 1.0, 0.2)
		
		# Анимация покачивания сундука при приближении
		sprite.play("hit_" + chest_type)
		
		# Ждем завершения hit, только если она не зациклена
		if sprite.sprite_frames.get_animation_loop("hit_" + chest_type) == false:
			await sprite.animation_finished
			if not is_opened:
				sprite.play("idle_" + chest_type)

func _on_interact_body_exited(body):
	if body.name == "Character" or body.is_in_group("player"):
		player_in_range = false
		
		# Плавно скрываем прозрачность
		var tween = create_tween()
		tween.tween_property(e_button, "modulate:a", 0.0, 0.1)
		await tween.finished
		
		if not player_in_range: # Проверка, не вернулся ли игрок мгновенно
			e_button.visible = false
			e_button.stop() # Останавливаем анимацию для экономии ресурсов

func open_chest():
	is_opened = true
	player_in_range = false
	e_button.visible = false
	e_button.stop()
	
	sprite.play("open_" + chest_type)
	
	if open_sound:
		open_sound.play()

	if get_tree().root.has_node("ScoreManager"):
		var sm = get_tree().root.get_node("ScoreManager")
		sm.add_score(bonus_points)
	else:
		ScoreManager.add_score(bonus_points)
