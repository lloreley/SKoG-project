extends Camera2D

@export_group("Drag Settings")
@export var drag_sensitivity : float = 1.0  # Чувствительность перетаскивания

@export_group("Zoom Settings")
@export var min_zoom     : float = 0.5    # Насколько далеко можно отдалить
@export var max_zoom     : float = 2.0    # Насколько сильно можно приблизить
@export var zoom_speed   : float = 0.1    # Шаг приближения
@export var zoom_smooth  : float = 10.0   # Плавность зума

@export_group("Map Limits")
@export var map_limit_left   : float = -5000
@export var map_limit_top    : float = -5000
@export var map_limit_right  : float = 5000
@export var map_limit_bottom : float = 5000

var target_zoom : float = 1.0
var is_dragging : bool = false

func _ready() -> void:
	target_zoom = zoom.x
	# Для перетаскивания лучше выключить сглаживание позиции или сделать его очень быстрым,
	# чтобы карта не "отставала" от руки игрока.
	position_smoothing_enabled = true
	position_smoothing_speed = 15.0

func _input(event: InputEvent) -> void:
	# 1. Обработка зума (колесико)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom += zoom_speed
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom -= zoom_speed
		
		target_zoom = clamp(target_zoom, min_zoom, max_zoom)

		# 2. Обработка нажатия ЛКМ для начала перетаскивания
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed

	# 3. Само перетаскивание через движение мыши
	if event is InputEventMouseMotion and is_dragging:
		# relative — это вектор того, насколько сдвинулась мышь с прошлого кадра.
		# Мы делим на zoom, чтобы скорость движения соответствовала масштабу карты.
		position -= event.relative * (1.0 / zoom.x) * drag_sensitivity
		
		# Ограничиваем камеру сразу при движении
		limit_camera_position()

func _process(delta: float) -> void:
	handle_zooming(delta)

func handle_zooming(delta: float) -> void:
	# Плавный зум к цели
	var new_zoom = lerp(zoom.x, target_zoom, zoom_smooth * delta)
	zoom = Vector2(new_zoom, new_zoom)

func limit_camera_position() -> void:
	position.x = clamp(position.x, map_limit_left, map_limit_right)
	position.y = clamp(position.y, map_limit_top, map_limit_bottom)
