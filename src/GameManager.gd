extends Node

var last_checkpoint_pos: Vector2 = Vector2.ZERO

func respawn_player(player):
	if last_checkpoint_pos != Vector2.ZERO:
		player.global_position = last_checkpoint_pos
	else:
		get_tree().reload_current_scene()
