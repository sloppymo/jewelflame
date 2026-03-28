extends TinyRPGCharacter

# Knight - Charges in, strikes multiple times, then retreats to charge again

enum KnightState { IDLE, CHARGING, STRIKING, RETREATING }
var _knight_state: KnightState = KnightState.IDLE

var _charge_direction: Vector2 = Vector2.ZERO
var _charge_speed: float = 220.0
var _retreat_target: Vector2 = Vector2.ZERO
var _strikes_remaining: int = 0
var _max_strikes: int = 3

# Momentum during charge
var _charge_momentum: float = 0.0
var _max_momentum: float = 100.0
var _momentum_build_rate: float = 60.0

@export var preferred_charge_distance: float = 300.0
@export var retreat_distance: float = 250.0

func _ready():
	super._ready()
	max_health = 150
	current_health = 150
	attack_damage = 25
	attack_range = 65.0
	move_speed = 75.0
	attack_cooldown_time = 0.65

func _update_ai_charge(delta: float):
	match _knight_state:
		KnightState.IDLE:
			_update_idle_state(delta)
		KnightState.CHARGING:
			_update_charging_state(delta)
		KnightState.STRIKING:
			_update_striking_state(delta)
		KnightState.RETREATING:
			_update_retreating_state(delta)

func _update_idle_state(delta: float):
	"""Find target and decide whether to charge or move closer."""
	if not _ai_target or not is_instance_valid(_ai_target) or _ai_target.is_dead:
		_ai_find_target()
		if not _ai_target:
			_play_anim("idle")
			return
	
	var dist = position.distance_to(_ai_target.position)
	
	# If far enough, start a charge
	if dist >= preferred_charge_distance * 0.7:
		_start_charge()
	else:
		# Too close, just fight normally
		if dist <= attack_range:
			_change_state(State.ATTACK)
			_ai_state_timer = 0.0
			_has_hit = false
			_ai_attack_timer = 0.0
		else:
			# Move closer normally
			var move_dir = (_ai_target.position - position).normalized()
			_update_movement(move_dir, delta)

func _start_charge():
	"""Begin a charge attack."""
	_knight_state = KnightState.CHARGING
	_charge_direction = (_ai_target.position - position).normalized()
	_charge_momentum = 0.0
	_strikes_remaining = _max_strikes

func _update_charging_state(delta: float):
	"""Charge toward target building momentum."""
	if not _ai_target or not is_instance_valid(_ai_target) or _ai_target.is_dead:
		_knight_state = KnightState.IDLE
		_ai_target = null
		return
	
	var dist = position.distance_to(_ai_target.position)
	
	# Adjust charge direction slightly to track target
	var target_dir = (_ai_target.position - position).normalized()
	_charge_direction = _charge_direction.lerp(target_dir, 0.1).normalized()
	
	# Build momentum
	_charge_momentum = min(_charge_momentum + _momentum_build_rate * delta, _max_momentum)
	
	# Charge at target
	var current_speed = _charge_speed * (0.6 + _charge_momentum / _max_momentum * 0.4)
	position += _charge_direction * current_speed * delta
	
	# Face direction of charge
	if _charge_direction.x > 0.1:
		facing = "right"
	elif _charge_direction.x < -0.1:
		facing = "left"
	_update_facing()
	_play_anim("walk")
	
	# Transition to striking when close
	if dist <= attack_range:
		_knight_state = KnightState.STRIKING
		_ai_state_timer = 0.0
		_has_hit = false
		_ai_attack_timer = 0.0

func _update_striking_state(delta: float):
	"""Deliver multiple strikes."""
	if not _ai_target or not is_instance_valid(_ai_target) or _ai_target.is_dead:
		_knight_state = KnightState.RETREATING
		_set_retreat_point()
		return
	
	var dist = position.distance_to(_ai_target.position)
	
	# If target moved away, decide whether to pursue or retreat
	if dist > attack_range * 1.5:
		if _strikes_remaining > 0:
			# Still have strikes, pursue
			var move_dir = (_ai_target.position - position).normalized()
			_update_movement(move_dir, delta)
		else:
			# Out of strikes, retreat
			_knight_state = KnightState.RETREATING
			_set_retreat_point()
		return
	
	# Face and attack target
	var attack_dir = (_ai_target.position - position).normalized()
	if attack_dir.x > 0:
		facing = "right"
	else:
		facing = "left"
	_update_facing()
	
	# Deal damage during attack window
	if _ai_state_timer > 0.15 and _ai_state_timer < 0.35 and not _has_hit:
		_has_hit = true
		
		# HUGE damage on first strike with high momentum
		var damage_mult = 1.0
		if _strikes_remaining == _max_strikes and _charge_momentum > 50:
			# Charge impact bonus - up to 3x damage
			damage_mult = 1.0 + (_charge_momentum / _max_momentum) * 2.0
		elif _strikes_remaining < _max_strikes:
			# Follow-up strikes do less
			damage_mult = 0.8
		
		var total_damage = int(attack_damage * damage_mult)
		_ai_target.take_hit_ai(total_damage, attack_dir)
		
		# Big knockback on charge hit
		if _strikes_remaining == _max_strikes and _charge_momentum > 50:
			_ai_target._knockback_velocity = attack_dir * 350
		
		_strikes_remaining -= 1
		_charge_momentum = max(_charge_momentum - 30, 0)
	
	_play_anim("attack01")
	
	# After cooldown, either strike again or retreat
	if _ai_attack_timer >= attack_cooldown_time:
		if _strikes_remaining > 0 and dist <= attack_range * 1.5:
			# Strike again
			_ai_state_timer = 0.0
			_has_hit = false
			_ai_attack_timer = 0.0
		else:
			# Retreat to charge again
			_knight_state = KnightState.RETREATING
			_set_retreat_point()

func _set_retreat_point():
	"""Set a point to retreat to for next charge."""
	if _ai_target and is_instance_valid(_ai_target):
		# Retreat away from target
		var away_dir = (position - _ai_target.position).normalized()
		_retreat_target = position + away_dir * retreat_distance
	else:
		_retreat_target = position

func _update_retreating_state(delta: float):
	"""Retreat to set distance to prepare for next charge."""
	var dist_to_retreat_point = position.distance_to(_retreat_target)
	
	if dist_to_retreat_point < 30:
		# Reached retreat point, go idle and prepare for next charge
		_knight_state = KnightState.IDLE
		_charge_momentum = 0.0
		return
	
	# Sprint to retreat point
	var move_dir = (_retreat_target - position).normalized()
	
	# Avoid running into allies while retreating
	for unit in get_tree().get_nodes_in_group("arena_units"):
		if unit != self and unit.team == team and not unit.is_dead:
			var dist_to_ally = position.distance_to(unit.position)
			if dist_to_ally < 50:
				move_dir += (position - unit.position).normalized() * 0.5
				move_dir = move_dir.normalized()
	
	position += move_dir * move_speed * 1.3 * delta
	
	if move_dir.x > 0.1:
		facing = "right"
	elif move_dir.x < -0.1:
		facing = "left"
	_update_facing()
	_play_anim("walk")
	
	# Check if target is far enough - can start new charge early
	if _ai_target and is_instance_valid(_ai_target) and not _ai_target.is_dead:
		var dist_to_target = position.distance_to(_ai_target.position)
		if dist_to_target >= preferred_charge_distance and dist_to_retreat_point < 50:
			_start_charge()

func _update_movement(move_dir: Vector2, delta: float):
	"""Standard movement with ally avoidance."""
	for unit in get_tree().get_nodes_in_group("arena_units"):
		if unit != self and unit.team == team and not unit.is_dead:
			var dist_to_ally = position.distance_to(unit.position)
			if dist_to_ally < 50:
				move_dir += (position - unit.position).normalized() * 0.5
				move_dir = move_dir.normalized()
	
	position += move_dir * move_speed * delta
	
	if move_dir.x > 0.1:
		facing = "right"
	elif move_dir.x < -0.1:
		facing = "left"
	_update_facing()
	_play_anim("walk")

func take_hit_ai(damage: int, from_dir: Vector2):
	# Knights lose momentum when hit during charge
	if _knight_state == KnightState.CHARGING:
		_charge_momentum = max(_charge_momentum - 40, 0)
		if _charge_momentum < 30:
			# Abort charge, go to striking
			_knight_state = KnightState.STRIKING
			_strikes_remaining = _max_strikes
	
	super.take_hit_ai(damage, from_dir)

func _update_ai_attack(delta: float):
	# Override to use our state machine instead
	pass

func _update_ai_idle(delta: float):
	# Use our knight state machine
	if _knight_state == KnightState.IDLE:
		_update_idle_state(delta)
	else:
		_super_update_ai_idle(delta)

func _super_update_ai_idle(delta: float):
	"""Original idle behavior."""
	_play_anim("idle")
	_ai_find_target()
	if _ai_target and is_instance_valid(_ai_target) and not _ai_target.is_dead:
		_change_state(State.WALK)
