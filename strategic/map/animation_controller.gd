extends Node2D

@onready var areas: Node2D = $"../ProvinceAreas"

func show_attack_arrow(from_id: int, to_id: int):
	var from_province = GameState.provinces[from_id]
	var to_province = GameState.provinces[to_id]
	
	# Get province positions from renderer
	var from_pos = get_province_position(from_id)
	var to_pos = get_province_position(to_id)
	
	# Create arrow line
	var arrow = Line2D.new()
	arrow.name = "AttackArrow"
	arrow.width = 5
	arrow.default_color = Color.RED
	arrow.points = PackedVector2Array([from_pos, to_pos])
	
	# Add arrow to map
	areas.add_child(arrow)
	
	# Animate arrow
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Pulsing effect
	tween.tween_property(arrow, "width", 8, 0.3)
	tween.tween_property(arrow, "width", 5, 0.3)
	tween.set_loops()
	
	# Remove arrow after 1.5 seconds
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(arrow):
		arrow.queue_free()

func show_province_capture(id: int, new_color: Color):
	var area = areas.get_node_or_null("Province_%d" % id)
	if not area:
		return
	
	var visual = area.get_node_or_null("Visual")
	if not visual:
		return
	
	# Create flash effect
	var original_color = visual.color
	var tween = create_tween()
	
	# Flash white
	tween.tween_property(visual, "color", Color.WHITE, 0.2)
	
	# Flash to new color
	tween.tween_property(visual, "color", new_color, 0.3)
	
	# Return to normal (slightly transparent)
	tween.tween_property(visual, "color", Color(new_color.r, new_color.g, new_color.b, 0.6), 0.2)
	
	# Add capture sparkles effect
	_create_capture_sparkles(area.position)

func _create_capture_sparkles(position: Vector2):
	for i in range(8):
		var sparkle = ColorRect.new()
		sparkle.size = Vector2(4, 4)
		sparkle.color = Color.YELLOW
		sparkle.position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		
		areas.add_child(sparkle)
		
		# Animate sparkle
		var tween = create_tween()
		tween.tween_property(sparkle, "position:y", sparkle.position.y - 30, 0.5)
		tween.tween_property(sparkle, "modulate:a", 0.0, 0.5)
		tween.finished.connect(func(): if is_instance_valid(sparkle): sparkle.queue_free())

func get_province_position(id: int) -> Vector2:
	var positions = {
		1: Vector2(400, 300),
		2: Vector2(600, 200),
		3: Vector2(600, 400),
		4: Vector2(800, 300),
		5: Vector2(800, 500)
	}
	return positions.get(id, Vector2(500, 500))
