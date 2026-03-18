extends AnimatableBody2D

@export var offset: Vector2 = Vector2(0, -100) # Куда едем (относительно старта)
@export var duration: float = 2.0             # Время в одну сторону

func _ready():
	start_tween()

func start_tween():
	# Создаем плавное движение туда-обратно
	var tween = create_tween().set_loops() # Бесконечный цикл
	tween.set_trans(Tween.TRANS_SINE)      # Плавное замедление в концах пути
	
	# Движение к цели
	tween.tween_property(self, "position", position + offset, duration)
	# Возврат назад
	tween.tween_property(self, "position", position, duration)
