extends Node

var last_visited_level: String = "res://levels/level0/level0.tscn"

signal score_updated(new_score)

var total_score: int = 0

func add_score(amount: int):
	total_score += amount
	score_updated.emit(total_score)
