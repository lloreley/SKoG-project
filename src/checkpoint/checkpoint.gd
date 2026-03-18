extends Node2D

@onready var fire = $Fire
@onready var e_button = $EBtn
@onready var audio = $AudioStreamPlayer2D
@onready var light = $PointLight2D
@onready var campfire_sprite = $Campfire # Узел самого спрайта дров

var is_active: bool = false
var can_interact: bool = false
var is_burned_out: bool = false # Сгорел ли костер окончательно после смерти

func _ready():
	e_button.visible = false
	fire.visible = false
	if light:
		light.enabled = false
		light.energy = 0.0

func _process(_delta):
	# Эффект мерцания только если костер горит
	if is_active and light:
		light.energy = lerp(light.energy, randf_range(1.1, 1.5), 0.1)

	# Взаимодействие возможно только если костер не горит и не сгорел совсем
	if can_interact and not is_active and not is_burned_out:
		if Input.is_action_just_pressed("interact"):
			activate_checkpoint()

# --- ЛОГИКА АКТИВАЦИИ ---
func activate_checkpoint():
	# При зажигании нового костра — тушим все остальные АКТИВНЫЕ костры
	# Но НЕ помечаем их как сгоревшие (is_burned_out), чтобы их можно было зажечь снова
	var all_checkpoints = get_tree().get_nodes_in_group("checkpoints")
	for cp in all_checkpoints:
		if cp != self and cp.is_active:
			if cp.has_method("extinguish"): # Специальный метод "потушить"
				cp.extinguish()

	is_active = true
	can_interact = false
	
	# Анимация появления огня и исчезновения кнопки
	e_button.visible = false
	fire.visible = true
	if fire is AnimatedSprite2D: fire.play()
	
	if light:
		light.enabled = true
		create_tween().tween_property(light, "energy", 1.3, 0.5)
	
	if audio: audio.play()
	
	# Сохраняем позицию в GameManager
	if get_tree().root.has_node("GameManager"):
		GameManager.last_checkpoint_pos = global_position
	
	print("Чекпоинт зажжен!")

# --- МЕТОД 1: ПРОСТО ПОТУШИТЬ (если игрок взял другой костер) ---
func extinguish():
	is_active = false
	fire.visible = false
	if fire is AnimatedSprite2D: fire.stop()
	if audio: audio.stop()
	if light:
		var tw = create_tween()
		tw.tween_property(light, "energy", 0.0, 0.5)
		tw.finished.connect(func(): light.enabled = false)
	print("Костер потух, но его можно зажечь снова")

# --- МЕТОД 2: СЖЕЧЬ НАВСЕГДА (вызывается только при смерти/респауне) ---
func deactivate():
	is_active = false
	is_burned_out = true # Теперь костер нельзя будет зажечь снова
	can_interact = false
	
	# Сбрасываем позицию, чтобы нельзя было бесконечно спавниться на одном месте
	if get_tree().root.has_node("GameManager"):
		GameManager.last_checkpoint_pos = Vector2.ZERO
	
	extinguish() # Выключаем визуал
	
	# Визуально показываем, что дрова прогорели
	if campfire_sprite:
		campfire_sprite.modulate = Color(0.3, 0.3, 0.3, 1.0) # Затемняем
		
	print("Костер полностью израсходован")

# --- СИГНАЛЫ ЗОН ---
func _on_appear_button_e_body_entered(body):
	if (body.name == "Character" or body.is_in_group("player")) and not is_active and not is_burned_out:
		e_button.visible = true
		e_button.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(e_button, "modulate:a", 1.0, 0.2)

func _on_appear_button_e_body_exited(body):
	if body.name == "Character" or body.is_in_group("player"):
		var tween = create_tween()
		tween.tween_property(e_button, "modulate:a", 0.0, 0.1)
		await tween.finished
		e_button.visible = false

func _on_interact_body_entered(body):
	if (body.name == "Character" or body.is_in_group("player")) and not is_burned_out:
		can_interact = true

func _on_interact_body_exited(body):
	if body.name == "Character" or body.is_in_group("player"):
		can_interact = false
