extends AudioStreamPlayer

@export var normal_pitch : float = 1.0
@export var battle_pitch : float = 1.2
@export var change_speed : float = 0.5

var target_pitch : float = 1.0

func _process(delta: float) -> void:
	if is_enemy_on_screen():
		target_pitch = battle_pitch
	else:
		target_pitch = normal_pitch
	
	# Плавный переход
	pitch_scale = move_toward(pitch_scale, target_pitch, change_speed * delta)

func is_enemy_on_screen() -> bool:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return false

	# Получаем текущую активную камеру
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return false # Если камеры нет, считаем что врагов не видно

	# Вычисляем видимую область камеры (Rect2)
	var screen_size = get_viewport().get_visible_rect().size
	var camera_pos = camera.get_screen_center_position()
	var zoom = camera.zoom
	
	# Учитываем зум камеры при расчете границ
	var view_size = screen_size / zoom
	var view_rect = Rect2(camera_pos - view_size / 2, view_size)

	for enemy in enemies:
		if enemy is Node2D:
			# Проверяем, входит ли точка врага в прямоугольник видимости
			if view_rect.has_point(enemy.global_position):
				return true
				
	return false
