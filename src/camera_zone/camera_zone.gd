extends Area2D

@export var camera_node: Camera2D 
@export var transition_time: float = 0.4
@export var base_zoom: float = 1.2

func _ready() -> void:
	var col_shape = get_node_or_null("CollisionShape2D")
	if col_shape and col_shape.shape:
		col_shape.shape = col_shape.shape.duplicate()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if is_inside_tree():
		await get_tree().process_frame
		if not is_inside_tree(): return 
		
		for body in get_overlapping_bodies():
			_on_body_entered(body)

func _on_body_entered(body: Node2D) -> void:
	if is_instance_valid(body) and (body.is_in_group("player") or body.name == "Player"):
		var camera = _get_camera(body)
		if is_instance_valid(camera):
			update_camera_limits(camera)

func _on_body_exited(body: Node2D) -> void:
	if is_instance_valid(body) and (body.is_in_group("player") or body.name == "Player"):
		if is_inside_tree():
			await get_tree().process_frame

func _get_camera(player: Node2D) -> Camera2D:
	if is_instance_valid(camera_node): return camera_node
	return player.find_child("Camera2D", true, false) as Camera2D

func update_camera_limits(camera: Camera2D) -> void:
	var col_shape = get_node_or_null("CollisionShape2D")
	if not is_instance_valid(col_shape) or not col_shape.shape: return
	
	var shape = col_shape.shape as RectangleShape2D
	var zone_size = shape.size * col_shape.global_scale
	var zone_pos = col_shape.global_position
	
	var target_l = int(zone_pos.x - zone_size.x / 2)
	var target_r = int(zone_pos.x + zone_size.x / 2)
	var target_t = int(zone_pos.y - zone_size.y / 2)
	var target_b = int(zone_pos.y + zone_size.y / 2)
	
	var viewport_size = get_viewport_rect().size
	var min_zoom = max(viewport_size.x / zone_size.x, viewport_size.y / zone_size.y)
	var final_zoom = Vector2(max(base_zoom, min_zoom), max(base_zoom, min_zoom))

	if camera.is_inside_tree():
		var tween = create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		tween.tween_property(camera, "limit_left", target_l, transition_time)
		tween.tween_property(camera, "limit_right", target_r, transition_time)
		tween.tween_property(camera, "limit_top", target_t, transition_time)
		tween.tween_property(camera, "limit_bottom", target_b, transition_time)
		tween.tween_property(camera, "zoom", final_zoom, transition_time)
		
		var t = 0.0
		while t < transition_time:
			# Главная проверка внутри цикла, чтобы не вылетело при смене сцены
			if not is_inside_tree() or not is_instance_valid(camera): 
				break
				
			camera.reset_smoothing() 
			await get_tree().process_frame
			t += get_process_delta_time()
