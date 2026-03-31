extends Node2D

@onready var fire = $Fire
@onready var e_button = $EBtn
@onready var audio = $AudioStreamPlayer2D
@onready var light = $PointLight2D
@onready var campfire_sprite = $Campfire 

var is_active: bool = false
var can_interact: bool = false
var is_burned_out: bool = false 

func _ready():
	# Добавляем в группу программно, если забыли в инспекторе
	add_to_group("checkpoints")
	e_button.visible = false
	fire.visible = false
	if light:
		light.enabled = false
		light.energy = 0.0

func _process(_delta):
	# Эффект мерцания работает ТОЛЬКО если костер активен
	if is_active and light and light.enabled:
		light.energy = lerp(light.energy, randf_range(1.1, 1.5), 0.1)
	
	# Проверка нажатия кнопки взаимодействия
	if can_interact and not is_active and not is_burned_out:
		if Input.is_action_just_pressed("interact"):
			activate_checkpoint()

# --- ЛОГИКА АКТИВАЦИИ ---
func activate_checkpoint():
	# Тушим все остальные костры в группе
	var all_checkpoints = get_tree().get_nodes_in_group("checkpoints")
	for cp in all_checkpoints:
		if cp != self and cp.has_method("extinguish"):
			cp.extinguish()

	is_active = true
	is_burned_out = false
	
	# Визуал активации
	e_button.visible = false
	fire.visible = true
	if fire is AnimatedSprite2D: 
		fire.play()
	
	if light:
		light.enabled = true
		var tw = create_tween()
		tw.tween_property(light, "energy", 1.3, 0.5)
	
	if audio: 
		audio.play()
	
	# Сохраняем позицию
	GameManager.last_checkpoint_pos = global_position
	print("Чекпоинт зажжен:", name)

# --- МЕТОД: ПОТУШИТЬ (Визуальное выключение) ---
func extinguish():
	is_active = false
	# Скрываем огонь немедленно
	if fire:
		fire.visible = false
		if fire is AnimatedSprite2D: 
			fire.stop()
	
	if audio and audio.playing: 
		audio.stop()
		
	if light:
		# Плавное затухание света
		var tw = create_tween()
		tw.tween_property(light, "energy", 0.0, 0.3)
		tw.finished.connect(func(): light.enabled = false)
	
	print("Костер визуально потушен:", name)

func deactivate():
	# Сначала тушим визуал
	extinguish()
	
	is_active = false
	is_burned_out = true
	fire.visible = false # ГАСИМ ОГОНЬ ВИЗУАЛЬНО
	if light: light.enabled = false
	if campfire_sprite: campfire_sprite.modulate = Color(0.3, 0.3, 0.3) # Затемняем дрова
	
	if campfire_sprite:
		var tw = create_tween()
		tw.tween_property(campfire_sprite, "modulate", Color(0.2, 0.2, 0.2, 1.0), 1.0)
		
	print("Костер полностью израсходован:", name)

# --- СИГНАЛЫ (Проверь, что они подключены в редакторе!) ---

func _on_appear_button_e_body_entered(body):
	if body.is_in_group("player") and not is_active and not is_burned_out:
		e_button.visible = true
		e_button.modulate.a = 0
		create_tween().tween_property(e_button, "modulate:a", 1.0, 0.2)

func _on_appear_button_e_body_exited(body):
	if body.is_in_group("player"):
		var tween = create_tween()
		tween.tween_property(e_button, "modulate:a", 0.0, 0.1)
		await tween.finished
		if not is_active: e_button.visible = false

func _on_interact_body_entered(body):
	if body.is_in_group("player"):
		can_interact = true

func _on_interact_body_exited(body):
	if body.is_in_group("player"):
		can_interact = false
