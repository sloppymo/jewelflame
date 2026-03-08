class_name MagicEffects extends Node2D

# Lightning bolt effect
var lightning_segments: int = 8
var lightning_color_start: Color = Color.WHITE
var lightning_color_mid: Color = Color.CORNFLOWER_BLUE
var lightning_color_end: Color = Color.PURPLE

# Barrier effect colors
var barrier_color: Color = Color(1.0, 0.6, 0.0, 0.6)  # Orange
var barrier_pulse_color: Color = Color(1.0, 0.8, 0.4, 0.8)

func _ready():
	pass

func cast_lightning(start_pos: Vector2, end_pos: Vector2, duration: float = 0.5) -> void:
	var lightning_line = Line2D.new()
	lightning_line.width = 3.0
	lightning_line.default_color = lightning_color_start
	add_child(lightning_line)
	
	# Generate zigzag points
	var points = _generate_lightning_points(start_pos, end_pos)
	lightning_line.points = points
	
	# Create gradient
	var gradient = Gradient.new()
	gradient.add_point(0.0, lightning_color_start)
	gradient.add_point(0.5, lightning_color_mid)
	gradient.add_point(1.0, lightning_color_end)
	lightning_line.gradient = gradient
	
	# Animate flicker
	var tween = create_tween()
	
	# Flash on
	tween.tween_property(lightning_line, "width", 5.0, 0.05)
	tween.tween_property(lightning_line, "width", 2.0, 0.05)
	tween.tween_property(lightning_line, "width", 4.0, 0.05)
	tween.tween_property(lightning_line, "width", 3.0, 0.05)
	
	# Fade out
	tween.tween_property(lightning_line, "modulate", Color(1, 1, 1, 0), duration - 0.2)
	
	tween.finished.connect(func(): lightning_line.queue_free())

func _generate_lightning_points(start: Vector2, end: Vector2) -> PackedVector2Array:
	var points = PackedVector2Array()
	points.append(start)
	
	var direction = (end - start).normalized()
	var total_distance = start.distance_to(end)
	var segment_length = total_distance / lightning_segments
	
	var perpendicular = Vector2(-direction.y, direction.x)
	
	for i in range(1, lightning_segments):
		var base_pos = start + direction * (segment_length * i)
		
		# Add random offset perpendicular to direction
		var offset_amount = randf_range(-15, 15)
		if i == lightning_segments - 1:
			offset_amount = 0  # Keep last point closer to target
		
		var offset = perpendicular * offset_amount
		points.append(base_pos + offset)
	
	points.append(end)
	return points

func create_barrier(unit_position: Vector2, size: float = 50.0) -> Node2D:
	var barrier_container = Node2D.new()
	barrier_container.position = unit_position
	add_child(barrier_container)
	
	# Create outer ring
	var outer_ring = _create_ring_sprite(size, barrier_color)
	barrier_container.add_child(outer_ring)
	
	# Create inner ring
	var inner_ring = _create_ring_sprite(size * 0.7, Color(barrier_color.r, barrier_color.g, barrier_color.b, 0.4))
	barrier_container.add_child(inner_ring)
	
	# Animate pulse
	var tween = create_tween().set_loops()
	tween.tween_property(outer_ring, "scale", Vector2(1.1, 1.1), 0.5)
	tween.tween_property(outer_ring, "scale", Vector2(1.0, 1.0), 0.5)
	
	return barrier_container

func _create_ring_sprite(size: float, color: Color) -> Sprite2D:
	var sprite = Sprite2D.new()
	
	# Create circle texture
	var image = Image.create(int(size), int(size), false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2, size / 2)
	var radius = size / 2 - 2
	
	for x in range(int(size)):
		for y in range(int(size)):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			if dist < radius and dist > radius - 4:
				image.set_pixel(x, y, color)
			elif dist <= radius:
				var inner_color = Color(color.r, color.g, color.b, color.a * 0.3)
				image.set_pixel(x, y, inner_color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	
	return sprite

func remove_barrier(barrier_node: Node2D) -> void:
	if barrier_node:
		# Shrink and fade animation
		var tween = create_tween()
		tween.tween_property(barrier_node, "scale", Vector2(0.1, 0.1), 0.3)
		tween.parallel().tween_property(barrier_node, "modulate", Color(1, 1, 1, 0), 0.3)
		tween.finished.connect(func(): barrier_node.queue_free())

func cast_fireball(start_pos: Vector2, end_pos: Vector2, duration: float = 0.6) -> void:
	var fireball = _create_projectile_sprite(Color.ORANGE_RED, 8)
	fireball.position = start_pos
	add_child(fireball)
	
	# Move to target
	var tween = create_tween()
	tween.tween_property(fireball, "position", end_pos, duration)
	
	# Trail effect
	var trail_timer = Timer.new()
	trail_timer.wait_time = 0.05
	trail_timer.one_shot = false
	add_child(trail_timer)
	
	trail_timer.timeout.connect(func():
		if is_instance_valid(fireball):
			_create_trail_particle(fireball.position, Color.ORANGE)
	)
	trail_timer.start()
	
	# Impact at end
	tween.finished.connect(func():
		trail_timer.stop()
		trail_timer.queue_free()
		_create_impact_explosion(end_pos, Color.ORANGE_RED)
		fireball.queue_free()
	)

func _create_projectile_sprite(color: Color, size: int) -> Sprite2D:
	var sprite = Sprite2D.new()
	
	var image = Image.create(size * 2, size * 2, false, Image.FORMAT_RGBA8)
	var center = Vector2(size, size)
	
	for x in range(size * 2):
		for y in range(size * 2):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			if dist <= size:
				var alpha = 1.0 - (dist / size)
				var pixel_color = Color(color.r, color.g, color.b, alpha)
				image.set_pixel(x, y, pixel_color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	
	return sprite

func _create_trail_particle(pos: Vector2, color: Color) -> void:
	var particle = Sprite2D.new()
	particle.position = pos
	
	var size = randi_range(3, 6)
	var image = Image.create(size * 2, size * 2, false, Image.FORMAT_RGBA8)
	var center = Vector2(size, size)
	
	for x in range(size * 2):
		for y in range(size * 2):
			var pixel_pos = Vector2(x, y)
			var dist = pixel_pos.distance_to(center)
			
			if dist <= size:
				var alpha = (1.0 - (dist / size)) * 0.5
				var pixel_color = Color(color.r, color.g, color.b, alpha)
				image.set_pixel(x, y, pixel_color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	particle.texture = texture
	add_child(particle)
	
	var tween = create_tween()
	tween.tween_property(particle, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.finished.connect(func(): particle.queue_free())

func _create_impact_explosion(pos: Vector2, color: Color) -> void:
	# Create expanding ring
	var ring = _create_ring_sprite(20, color)
	ring.position = pos
	add_child(ring)
	
	var tween = create_tween()
	tween.tween_property(ring, "scale", Vector2(3, 3), 0.4)
	tween.parallel().tween_property(ring, "modulate", Color(1, 1, 1, 0), 0.4)
	tween.finished.connect(func(): ring.queue_free())
	
	# Create particles
	for i in range(8):
		var angle = (PI * 2 / 8) * i
		var dir = Vector2(cos(angle), sin(angle))
		var particle = _create_projectile_sprite(color, 4)
		particle.position = pos
		add_child(particle)
		
		var ptween = create_tween()
		ptween.tween_property(particle, "position", pos + dir * 30, 0.3)
		ptween.parallel().tween_property(particle, "modulate", Color(1, 1, 1, 0), 0.3)
		ptween.finished.connect(func(): particle.queue_free())
