extends Label

var points: int = 0

func _ready():
	text = str(points)

func add_points(amount: int) -> void:
	points += amount
	print("here")
	text = str(points)
	print("Текущие очки:", points)  # проверка
