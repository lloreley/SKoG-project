extends CanvasLayer

@onready var health_sprite: Sprite2D = $Health 

# Массив с предзагруженными текстурами (от полного до пустого)
var health_stages = [
	preload("res://res/healthbar/HealthBar1.png"), # 100% (4 HP)
	preload("res://res/healthbar/HealthBar2.png"),
	preload("res://res/healthbar/HealthBar3.png"),
	preload("res://res/healthbar/HealthBar4.png"),
	preload("res://res/healthbar/HealthBar5.png"),
	preload("res://res/healthbar/HealthBar6.png"),
	preload("res://res/healthbar/HealthBar7.png"),
	preload("res://res/healthbar/HealthBar8.png"),
	preload("res://res/healthbar/HealthBar9.png")  # 0% (Смерть)
]

func update_health_ui(current_health: float):
	var index = int((4.0 - current_health) * 2.0)
	index = clamp(index, 0, 8)
	
	health_sprite.texture = health_stages[index]
