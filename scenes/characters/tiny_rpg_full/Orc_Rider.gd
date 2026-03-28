extends TinyRPGCharacter

# Orc Rider - Fast mounted unit with charge momentum

var _is_charging: bool = false
var _charge_direction: Vector2 = Vector2.ZERO
var _charge_speed: float = 280.0
var _charge_momentum: float = 0.0
var _max_momentum: float = 100.0

func _ready():
	super._ready()
	max_health = 200
	current_health = 200
	attack_damage = 26
	attack_range = 60.0
	move_speed = 160.0  # Very fast base speed
	attack_cooldown_time = 0.75

func _update_ai_charge(delta: float):
	if not _ai_target or not is_instance_valid(_ai_target) or _ai_target.is_dead:
		_is_charging = false
		_charge_momentum = 0.0
		_ai_target = null
		_change_state(State.IDLE)
		return
	
	var dist = position.distance_to(_ai_target.position)
	
	# Start charge from distance
	if dist > 200 and not _is_charging and _charge_momentum <= 0 and randf() < 0.04:
		_start_charge()
		return
	
	if dist <= attack_range and not _is_charging:
		_change_state(State.ATTACK)
		_ai_state_timer = 0.0
		_has_hit = false
		_ai_attack_timer = 0.0
		return
	
	var move_dir: Vector2
	var current_speed: float
	
	if _is_charging:
		# Charging - hard to turn
		current_speed = _charge_speed * (0.6 + _charge_momentum / _max_momentum * 0.4)
		
		var target_dir = (_ai_target.position - position).normalized()
		_charge_direction = _charge_direction.lerp(target_dir, 0.06).normalized()
		move_dir = _charge_direction
		
		_charge_momentum = min(_charge_momentum + 40 * delta, _max_momentum)
		
		# End charge if close or timeout
		if dist < 50 or _ai_state_timer > 2.5:
			_is_charging = false
	else:
		move_dir = (_ai_target.position - position).normalized()
		current_speed = move_speed
		_charge_momentum = max(_charge_momentum - 15 * delta, 0)
	
	# Mounted units trample through allies
	for unit in get_tree().get_nodes_in_group("arena_units"):
		if unit != self and unit.team == team and not unit.is_dead:
			var dist_to_ally = position.distance_to(unit.position)
			if dist_to_ally < 60:
				if _is_charging:
					var push_dir = (unit.position - position).normalized()
					unit._knockback_velocity = push_dir * 80
				else:
					move_dir += (position - unit.position).normalized() * 0.2
					move_dir = move_dir.normalized()
	
	position += move_dir * current_speed * delta
	
	if move_dir.x > 0.1:
		facing = "right"
	elif move_dir.x < -0.1:
		facing = "left"
	_update_facing()
	_play_anim("walk")

func _start_charge():
	_is_charging = true
	_charge_direction = (_ai_target.position - position).normalized()
	_charge_momentum = 15.0
	_ai_state_timer = 0.0

func _update_ai_attack(delta: float):
	if _ai_target and is_instance_valid(_ai_target):
		var attack_dir = (_ai_target.position - position).normalized()
		if attack_dir.x > 0:
			facing = "right"
		else:
			facing = "left"
		_update_facing()
	
	if _ai_state_timer > 0.2 and _ai_state_timer < 0.4 and not _has_hit:
		_has_hit = true
		if _ai_target and is_instance_valid(_ai_target) and not _ai_target.is_dead:
			var dist = position.distance_to(_ai_target.position)
			if dist <= attack_range * 1.5:
				var momentum_bonus = 1.0 + (_charge_momentum / _max_momentum) * 1.5
				var total_damage = int(attack_damage * momentum_bonus)
				
				_ai_target.take_hit_ai(total_damage, (_ai_target.position - position).normalized())
				
				if _charge_momentum > 40:
					_ai_target._knockback_velocity = (_ai_target.position - position).normalized() * 300
				
				_charge_momentum = 0
	
	_play_anim("attack01")
	
	if _ai_attack_timer >= attack_cooldown_time:
		_is_charging = false
		_change_state(State.WALK)

func take_hit_ai(damage: int, from_dir: Vector2):
	_charge_momentum = max(_charge_momentum - 25, 0)
	if _is_charging and _charge_momentum < 15:
		_is_charging = false
	super.take_hit_ai(damage, from_dir)
