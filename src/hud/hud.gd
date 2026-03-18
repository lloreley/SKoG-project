extends Label

func _ready():
	ScoreManager.score_updated.connect(_on_score_updated)
	text = str(ScoreManager.total_score)

func _on_score_updated(new_score: int):
	text = str(new_score)
