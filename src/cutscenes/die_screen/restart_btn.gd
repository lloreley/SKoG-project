extends TextureButton

func _ready():
	texture_normal = load("res://res/buttons/restart/restart1.png")
	texture_hover = load("res://res/buttons/restart/restart2.png")
	texture_pressed = load("res://res/buttons/restart/restart3.png")
	size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_FILL
	stretch_mode = TextureButton.STRETCH_SCALE


func _on_pressed() -> void:
	await get_tree().create_timer(0.4).timeout
	ScoreManager.total_score = 0
	ScoreManager.score_updated.emit(0)
	get_tree().change_scene_to_file("res://levels/level1/level1.tscn")
