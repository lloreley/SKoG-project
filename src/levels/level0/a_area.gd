@tool
extends Area2D

# Ссылка на дочерний узел (сцену подсказки)
# Убедись, что имя узла в дереве совпадает с "TutorialHint"
@onready var hint_node = $TutorialHint_A

func _ready() -> void:
	# Проверяем, что узел существует, прежде чем обращаться к нему
	if hint_node:
		hint_node.modulate.a = 0
		hint_node.hide()
	
	# Подключаем сигналы области к текущему скрипту
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	# Проверяем, что вошел именно игрок (по имени или группе)
	if body.name == "Player" or body.is_in_group("player"):
		show_hint()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		hide_hint()

func show_hint() -> void:
	hint_node.show()
	var tween = create_tween()
	# Плавное появление за 0.3 секунды
	tween.tween_property(hint_node, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	
	# Если внутри подсказки есть AnimatedSprite2D, запускаем его
	if hint_node.has_node("AnimatedSprite2D"):
		hint_node.get_node("AnimatedSprite2D").play("default")

func hide_hint() -> void:
	var tween = create_tween()
	# Плавное исчезновение
	tween.tween_property(hint_node, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	# Полностью скрываем после завершения анимации, чтобы не тратить ресурсы
	tween.finished.connect(hint_node.hide)
