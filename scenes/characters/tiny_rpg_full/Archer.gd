extends TinyRPGCharacter

# Archer - EXTREME kiting, retreats at all costs

@export var danger_range: float = 120.0  # Retreat if enemy gets this close
@export var optimal_range: float = 200.0

var _retreat_cooldown: float = 0.0

func _ready():
	super._ready()
	max_health = 60
	current_health = 60
	attack_damage = 8
	attack_range = 250.0
	move_speed = 90.0  # Slightly faster to help escape
	attack_cooldown_time = 1.0

func _physics_process(delta):
	super._physics_process(delta)
	_retreat_cooldown = max(_retreat_cooldown - delta, 0)

func _update_ai_charge(delta: float):
	# PRIORITY 1: Check for nearby threats and retreat
	var nearest_threat = _find_nearest_threat()
	if nearest_threat and nearest_threat.distance < danger_range:
		_retreat_from_threat(nearest_threat.direction, delta)
		return
	
	# PRIORITY 2: Attack if in range
	if _ai_target and is_instance_valid(_ai_target) and not _ai_target.is_dead:
		var dist = position.distance_to(_ai_target.position)
		
		if dist <= attack_range:
			print(name + " entering ATTACK state, target=" + _ai_target.name + " dist=" + str(dist))
			_change_state(State.ATTACK)
			_ai_state_timer = 0.0
			_has_hit = false
			_ai_attack_timer = 0.0
			return
		else:
			print(name + " target too far: " + str(dist) + " (range=" + str(attack_range) + ")")
		
		# Move to optimal range (not too close, not too far)
		var target_pos = _ai_target.position + (_ai_target.position - position).normalized() * -optimal_range
		var move_dir = (target_pos - position).normalized()
		
		# Strong avoidance of all units
		for unit in get_tree().get_nodes_in_group("arena_units"):
			if unit != self and not unit.is_dead:
				var dist_to_unit = position.distance_to(unit.position)
				if dist_to_unit < 120:
					move_dir += (position - unit.position).normalized() * 1.5
					move_dir = move_dir.normalized()
		
		position += move_dir * move_speed * delta
		
		if move_dir.x > 0.1:
			facing = "right"
		elif move_dir.x < -0.1:
			facing = "left"
		_update_facing()
		_play_anim("walk")
	else:
		# Find target
		_ai_find_target()
		if not _ai_target:
			print(name + " no target found")
			_change_state(State.IDLE)
		return

func _find_nearest_threat() -> Dictionary:
	"""Find the nearest enemy that poses a threat."""
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

func _retreat_from_threat(retreat_dir: Vector2, delta: float):
	"""Sprint away from danger."""
	# Add some randomness to retreat direction
	retreat_dir += Vector2(randf() - 0.5, randf() - 0.5) * 0.3
	retreat_dir = retreat_dir.normalized()
	
	# Sprint away at 1.5x speed
	position += retreat_dir * move_speed * 1.5 * delta
	
	if retreat_dir.x > 0.1:
		facing = "right"
	elif retreat_dir.x < -0.1:
		facing = "left"
	_update_facing()
	_play_anim("walk")
	
	# Brief retreat cooldown prevents immediate re-engagement
	_retreat_cooldown = 0.5

func _update_ai_idle(delta: float):
	"""Even when idle, check for threats."""
	var threat = _find_nearest_threat()
	if threat.found:
		_retreat_from_threat(threat.direction, delta)
		return
	
	# Otherwise normal idle behavior
	super._update_ai_idle(delta)

func _update_ai_attack(delta: float):
	"""During attack, keep checking for threats to abort."""
	var threat = _find_nearest_threat()
	if threat.found and threat.distance < danger_range * 0.8:
		# Abort attack and retreat!
		_change_state(State.WALK)
		return
	
	# Face target
	if _ai_target and is_instance_valid(_ai_target):
		var attack_dir = (_ai_target.position - position).normalized()
		if attack_dir.x > 0:
			facing = "right"
		else:
			facing = "left"
		_update_facing()
	
	# Fire arrow at specific timing
	if _ai_state_timer > 0.25 and _ai_state_timer < 0.45 and not _has_hit:
		print(name + " firing arrow! timer=" + str(_ai_state_timer))
		_has_hit = true
		_fire_arrow()
	
	_play_anim("attack01")
	
	if _ai_attack_timer >= attack_cooldown_time:
		_change_state(State.WALK)

func _fire_arrow():
	"""Fire an arrow projectile."""
	if not _ai_target or not is_instance_valid(_ai_target):
		return
	
	print(name + " spawning arrow projectile")
	var arrow = preload("res://scenes/effects/arrow_projectile.tscn").instantiate()
	get_parent().add_child(arrow)
	print(name + " arrow added to scene")
	
	# Calculate direction to target first
	var dir = (_ai_target.global_position - global_position).normalized()
	
	# Position arrow in front of archer (at bow level)
	var offset = dir * 40  # 40 pixels in front of archer
	arrow.global_position = global_position + offset + Vector2(0, -30)
	arrow.z_index = 50  # Ensure arrow is visible on top
	
	# Fire the arrow
	arrow.fire(dir, self, attack_damage, team)

func take_hit_ai(damage: int, from_dir: Vector2):
	# Archers take EXTRA damage
	var fragile_damage = int(damage * 1.3)
	super.take_hit_ai(fragile_damage, from_dir)
	# Immediately try to retreat
	_retreat_cooldown = 0
