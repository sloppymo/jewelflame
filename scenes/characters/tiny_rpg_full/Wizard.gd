extends TinyRPGCharacter

# Wizard - Multiple spells including AoE, EXTREME range, retreats when threatened

enum SpellType { FIREBOLT, FIREBALL, METEOR }
var _current_spell: SpellType = SpellType.FIREBOLT
var _mana: float = 100.0
var _mana_regen: float = 8.0

# Spell costs and cooldowns
const MANA_COSTS = { SpellType.FIREBOLT: 10, SpellType.FIREBALL: 25, SpellType.METEOR: 50 }
const COOLDOWNS = { SpellType.FIREBOLT: 0.8, SpellType.FIREBALL: 1.5, SpellType.METEOR: 3.0 }
const DAMAGES = { SpellType.FIREBOLT: 20, SpellType.FIREBALL: 35, SpellType.METEOR: 60 }
const RANGES = { SpellType.FIREBOLT: 200.0, SpellType.FIREBALL: 180.0, SpellType.METEOR: 220.0 }

@export var danger_range: float = 150.0  # Retreat if enemy gets this close

func _ready():
	super._ready()
	max_health = 80
	current_health = 80
	attack_damage = 20
	attack_range = 220.0
	move_speed = 70.0  # Slower but can retreat
	attack_cooldown_time = 0.8

func _physics_process(delta):
	super._physics_process(delta)
	_mana = min(_mana + _mana_regen * delta, 100.0)

func _select_spell() -> SpellType:
	"""Select best spell based on mana and situation."""
	var nearby_enemies = 0
	
	for unit in get_tree().get_nodes_in_group("arena_units"):
		if unit is TinyRPGCharacter and unit.team != team and not unit.is_dead:
			var dist = position.distance_to(unit.position)
			if dist < 150:
				nearby_enemies += 1
				
	if nearby_enemies >= 3 and _mana >= MANA_COSTS[SpellType.METEOR]:
		return SpellType.METEOR
	
	if nearby_enemies >= 2 and _mana >= MANA_COSTS[SpellType.FIREBALL]:
		return SpellType.FIREBALL
	
	if _mana >= MANA_COSTS[SpellType.FIREBOLT]:
		return SpellType.FIREBOLT
	
	return SpellType.FIREBOLT

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
	retreat_dir += Vector2(randf() - 0.5, randf() - 0.5) * 0.3
	retreat_dir = retreat_dir.normalized()
	position += retreat_dir * move_speed * 1.4 * delta
	
	if retreat_dir.x > 0.1:
		facing = "right"
	elif retreat_dir.x < -0.1:
		facing = "left"
	_update_facing()
	_play_anim("walk")

func _update_ai_charge(delta: float):
	# PRIORITY 1: Check for nearby threats and retreat
	var threat = _find_nearest_threat()
	if threat.found:
		_retreat_from_threat(threat.direction, delta)
		return
	
	# PRIORITY 2: Find and attack target
	if _ai_target and is_instance_valid(_ai_target) and not _ai_target.is_dead:
		var dist = position.distance_to(_ai_target.position)
		
		_current_spell = _select_spell()
		var spell_range = RANGES[_current_spell]
		
		if dist <= spell_range and _mana >= MANA_COSTS[_current_spell]:
			attack_range = spell_range
			attack_cooldown_time = COOLDOWNS[_current_spell]
			attack_damage = DAMAGES[_current_spell]
			_change_state(State.ATTACK)
			_ai_state_timer = 0.0
			_has_hit = false
			_ai_attack_timer = 0.0
			return
		
		# Stay at max range - wizards want distance
		var ideal_dist = spell_range * 0.85
		var move_dir: Vector2
		
		if dist < ideal_dist:
			move_dir = (position - _ai_target.position).normalized()
		else:
			move_dir = (_ai_target.position - position).normalized() * 0.3  # Move very slowly closer
		
		# Strong avoidance
		for unit in get_tree().get_nodes_in_group("arena_units"):
			if unit != self and not unit.is_dead:
				var dist_to_unit = position.distance_to(unit.position)
				if dist_to_unit < 120:
					move_dir += (position - unit.position).normalized() * 1.2
					move_dir = move_dir.normalized()
		
		position += move_dir * move_speed * delta
		
		if move_dir.x > 0.1:
			facing = "right"
		elif move_dir.x < -0.1:
			facing = "left"
		_update_facing()
		_play_anim("walk")
	else:
		_ai_target = null
		_change_state(State.IDLE)

func _update_ai_idle(delta: float):
	"""Even when idle, check for threats."""
	var threat = _find_nearest_threat()
	if threat.found:
		_retreat_from_threat(threat.direction, delta)
		return
		super._update_ai_idle(delta)

func _update_ai_attack(delta: float):
	# Check for threats - abort if needed
	var threat = _find_nearest_threat()
	if threat.found and threat.distance < danger_range * 0.8:
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
	
	if _ai_state_timer > 0.25 and _ai_state_timer < 0.5 and not _has_hit:
		_has_hit = true
		_mana -= MANA_COSTS[_current_spell]
		
		match _current_spell:
			SpellType.FIREBOLT:
				_cast_firebolt()
			SpellType.FIREBALL:
				_cast_fireball()
			SpellType.METEOR:
				_cast_meteor()
	
	match _current_spell:
		SpellType.FIREBOLT:
			_play_anim("attack01")
		SpellType.FIREBALL, SpellType.METEOR:
			_play_anim("attack02")
	
	if _ai_attack_timer >= attack_cooldown_time:
		_change_state(State.WALK)

func _cast_firebolt():
	"""Cast a firebolt projectile."""
	if not _ai_target or not is_instance_valid(_ai_target):
		return
	
	var bolt = preload("res://scenes/effects/magic_projectile.tscn").instantiate()
	get_parent().add_child(bolt)
	
	bolt.global_position = global_position + Vector2(0, -20)
	var dir = (_ai_target.global_position - global_position).normalized()
	
	var is_crit = randf() < 0.25
	var dmg = int(attack_damage * 1.5) if is_crit else attack_damage
	bolt.fire(dir, self, dmg, team)

func _cast_fireball():
	if not _ai_target or not is_instance_valid(_ai_target):
		return
		
	var target_pos = _ai_target.position
	
	var dist = position.distance_to(target_pos)
	if dist <= attack_range * 1.5:
		_ai_target.take_hit_ai(attack_damage, (target_pos - position).normalized())
		_ai_target._show_damage_number(attack_damage, true)
	
	for unit in get_tree().get_nodes_in_group("arena_units"):
		if unit is TinyRPGCharacter and unit.team != team and not unit.is_dead and unit != _ai_target:
			if target_pos.distance_to(unit.position) < 80:
				var aoe_damage = int(attack_damage * 0.6)
				unit.take_hit_ai(aoe_damage, (unit.position - target_pos).normalized())
				unit._show_damage_number(aoe_damage, false)

func _cast_meteor():
	if not _ai_target or not is_instance_valid(_ai_target):
		return
		
	var target_pos = _ai_target.position
	
	for unit in get_tree().get_nodes_in_group("arena_units"):
		if unit is TinyRPGCharacter and unit.team != team and not unit.is_dead:
			var unit_dist = target_pos.distance_to(unit.position)
			if unit_dist < 150:
				var falloff = 1.0 - (unit_dist / 150.0) * 0.5
				var meteor_damage = int(attack_damage * falloff)
				unit.take_hit_ai(meteor_damage, (unit.position - target_pos).normalized())
				unit._show_damage_number(meteor_damage, false)
