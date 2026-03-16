extends Camera2D

@export var fade_speed: float = 30.0 # Как быстро затухает тряска
var shake_strength: float = 0.0

func _process(delta: float):
	if shake_strength > 0:
		# Постепенно уменьшаем силу до нуля
		shake_strength = lerp(shake_strength, 0.0, fade_speed * delta)
		
		# Если сила стала совсем маленькой, обнуляем
		if shake_strength < 0.1:
			shake_strength = 0.0
			offset = Vector2.ZERO
		else:
			# Генерируем случайное смещение
			offset = Vector2(
				randf_range(-shake_strength, shake_strength),
				randf_range(-shake_strength, shake_strength)
			)

# Функция, которую вызывает игрок
func apply_shake(strength: float):
	shake_strength = strength
