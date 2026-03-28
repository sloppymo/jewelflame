extends TinyRPGCharacter

# Skeleton Archer - Undead ranged with NON-STANDARD sprite sheet layout
# Layout: Attack(0), Death(1), Hurt(2), Idle(3), Walk(4)

@export var danger_range: float = 100.0

func _ready():
	# Override the standard sprite frame building
	if source_texture:
		build_skeleton_archer_frames()
	else:
		push_warning(name + ": No source_texture assigned!")
		_create_placeholder_sprite()
	
	# Apply scale (100x100 -> target size)
	scale = Vector2(target_scale, target_scale)
	
	# Set texture filter for pixel art
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Flip based on facing
	_update_facing()
	
	# Initialize health
	current_health = max_health
	
	# Add to character group for AI
	add_to_group("tiny_rpg_chars")
	add_to_group("arena_units")
	
	# Setup custom stats
	max_health = 60
	current_health = 60
	attack_damage = 12
	attack_range = 160.0
	move_speed = 70.0
	
	# Start idle
	_change_state(State.IDLE)


func build_skeleton_archer_frames():
	"""Build SpriteFrames for Skeleton Archer's layout.
	
	Skeleton Archer layout (5 rows) - ACTUAL ORDER:
	Row 0: Idle (6 frames)
	Row 1: Walk (8 frames)
	Row 2: Attack (9 frames)
	Row 3: Death (4 frames)
	Row 4: Hurt (4 frames)
	"""
	var sf = SpriteFrames.new()
	
	var tex_width = source_texture.get_width()
	var tex_height = source_texture.get_height()
	
	# Define animations with CORRECT row mappings
	var anims = [
		{"name": "idle", "row": 0, "frames": 6, "speed": 6.0, "loop": true},
		{"name": "walk", "row": 1, "frames": 8, "speed": 10.0, "loop": true},
		{"name": "attack01", "row": 2, "frames": 6, "speed": 12.0, "loop": false},
		{"name": "death", "row": 3, "frames": 4, "speed": 6.0, "loop": false},
		{"name": "hurt", "row": 4, "frames": 4, "speed": 8.0, "loop": false},
	]
	
	for anim in anims:
		var max_frame = mini(anim["frames"], tex_width / 100)
		
		sf.add_animation(anim["name"])
		sf.set_animation_speed(anim["name"], anim["speed"] * anim_speed_mult)
		sf.set_animation_loop(anim["name"], anim["loop"])
		
		for i in range(max_frame):
			var atlas = AtlasTexture.new()
			atlas.atlas = source_texture
			atlas.region = Rect2(
				i * 100,
				anim["row"] * 100,
				100,
				100
			)
			sf.add_frame(anim["name"], atlas)
	
	sprite.sprite_frames = sf


func _create_placeholder_sprite() -> void:
	var placeholder = PlaceholderTexture2D.new()
	placeholder.size = Vector2(100, 100)
	
	var sf = SpriteFrames.new()
	sf.add_animation("idle")
	sf.add_frame("idle", placeholder)
	sprite.sprite_frames = sf


func _find_nearest_threat() -> Dictionary:
	var nearest_dist = danger_range
	var threat_dir = Vector2.ZERO
	var found = false
	
	for unit in get_tree().get_nodes_in_group("arena_units"):
		if unit is TinyRPGCharacter and unit.team != team and not unit.is_dead:
			var dist = position.distance_to(unit.position)
			if dist < nearest_dist:
				nearest_dist = dist
				threat_dir = (position - unit.position).normalized()
				found = true
	
	return {"found": found, "distance": nearest_dist, "direction": threat_dir}


func _update_ai_charge(delta: float):
	# Check for threats - skeleton archers will retreat but less effectively
	var threat = _find_nearest_threat()
	if threat.found:
		# Retreat but not as fast as living archers
		var retreat_dir = threat.direction + Vector2(randf() - 0.5, randf() - 0.5) * 0.5
		retreat_dir = retreat_dir.normalized()
		position += retreat_dir * move_speed * 1.2 * delta
		
		if retreat_dir.x > 0.1:
			facing = "right"
		elif retreat_dir.x < -0.1:
			facing = "left"
		_update_facing()
		_play_anim("walk")
		return
	
	if not _ai_target or not is_instance_valid(_ai_target) or _ai_target.is_dead:
		_ai_target = null
		_change_state(State.IDLE)
		return
	
	var dist = position.distance_to(_ai_target.position)
	
	if dist <= attack_range:
		_change_state(State.ATTACK)
		_ai_state_timer = 0.0
		_has_hit = false
		_ai_attack_timer = 0.0
		return
	
	# Move toward target (mindless, doesn't avoid allies well)
	var move_dir = (_ai_target.position - position).normalized()
	position += move_dir * move_speed * delta
	
	if move_dir.x > 0.1:
		facing = "right"
	elif move_dir.x < -0.1:
		facing = "left"
	_update_facing()
	_play_anim("walk")


func _update_ai_attack(delta: float):
	# Can be interrupted
	var threat = _find_nearest_threat()
	if threat.found and threat.distance < danger_range * 0.7:
		_change_state(State.WALK)
		return
	
	if _ai_target and is_instance_valid(_ai_target):
		var attack_dir = (_ai_target.position - position).normalized()
		if attack_dir.x > 0:
			facing = "right"
		else:
			facing = "left"
		_update_facing()
	
	# Fire arrow at specific timing
	if _ai_state_timer > 0.25 and _ai_state_timer < 0.45 and not _has_hit:
		_has_hit = true
		_fire_arrow()
	
	_play_anim("attack01")
	
	if _ai_attack_timer >= attack_cooldown_time:
		_change_state(State.WALK)


func _fire_arrow():
	"""Fire an arrow projectile."""
	if not _ai_target or not is_instance_valid(_ai_target):
		return
	
	var arrow = preload("res://scenes/effects/arrow_projectile_skeleton.tscn").instantiate()
	get_parent().add_child(arrow)
	
	# Position arrow in front of skeleton
	var dir = (_ai_target.global_position - global_position).normalized()
	var offset = dir * 40
	arrow.global_position = global_position + offset + Vector2(0, -30)
	arrow.z_index = 50
	
	arrow.fire(dir, self, attack_damage, team)

func _die():
	super._die()
