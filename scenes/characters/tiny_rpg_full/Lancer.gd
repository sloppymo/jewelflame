extends TinyRPGCharacter

# Lancer - Very fast charge attacks with massive momentum

var _is_charging: bool = false
var _charge_direction: Vector2 = Vector2.ZERO
var _charge_speed: float = 350.0  # Extremely fast charge
var _charge_momentum: float = 0.0
var _max_momentum: float = 100.0
var _momentum_build_rate: float = 50.0

func _ready():
	super._ready()
	max_health = 130
	current_health = 130
	attack_damage = 30
	attack_range = 70.0
	move_speed = 140.0  # Very fast base speed
	attack_cooldown_time = 0.9

func _update_ai_charge(delta: float):
	if not _ai_target or not is_instance_valid(_ai_target) or _ai_target.is_dead:
		_is_charging = false
		_charge_momentum = 0.0
		_ai_target = null
		_change_state(State.IDLE)
		return
	
	var dist = position.distance_to(_ai_target.position)
	
	# Start charge if far enough away and not already charging
	if dist > 250 and not _is_charging and _charge_momentum <= 0 and randf() < 0.03:
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
		# Continue charging - momentum makes it hard to turn
		current_speed = _charge_speed * (0.5 + _charge_momentum / _max_momentum * 0.5)
		
		# Can only adjust direction slightly while charging
		var target_dir = (_ai_target.position - position).normalized()
		_charge_direction = _charge_direction.lerp(target_dir, 0.08).normalized()
		move_dir = _charge_direction
		
		# Build momentum while charging
		_charge_momentum = min(_charge_momentum + _momentum_build_rate * delta, _max_momentum)
		
		# End charge if very close or been charging too long
		if dist < 40 or _ai_state_timer > 2.0:
			_is_charging = false
			# Keep some momentum after charge ends
	else:
		move_dir = (_ai_target.position - position).normalized()
		current_speed = move_speed
		# Decay momentum when not charging
		_charge_momentum = max(_charge_momentum - 20 * delta, 0)
	
	# Lancers push through allies (unstoppable momentum)
	for unit in get_tree().get_nodes_in_group("arena_units"):
		if unit != self and unit.team == team and not unit.is_dead:
			var dist_to_ally = position.distance_to(unit.position)
			if dist_to_ally < 60:
				if _is_charging:
					# Push ally aside when charging
					var push_dir = (unit.position - position).normalized()
					unit._knockback_velocity = push_dir * 100
				else:
					move_dir += (position - unit.position).normalized() * 0.3
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
	_charge_momentum = 20.0  # Start with some momentum
	_ai_state_timer = 0.0

func _update_ai_attack(delta: float):
	# Face target
	if _ai_target and is_instance_valid(_ai_target):
		var attack_dir = (_ai_target.position - position).normalized()
		if attack_dir.x > 0:
			facing = "right"
		else:
			facing = "left"
		_update_facing()
	
	# Devastating charge attack
	if _ai_state_timer > 0.15 and _ai_state_timer < 0.35 and not _has_hit:
		_has_hit = true
		if _ai_target and is_instance_valid(_ai_target) and not _ai_target.is_dead:
			var dist = position.distance_to(_ai_target.position)
			if dist <= attack_range * 1.5:
				# Massive damage from momentum
				var momentum_bonus = 1.0 + (_charge_momentum / _max_momentum) * 2.0
				var total_damage = int(attack_damage * momentum_bonus)
				
				_ai_target.take_hit_ai(total_damage, (_ai_target.position - position).normalized())
				
				# Massive knockback on charge hit
				if _charge_momentum > 50:
					_ai_target._knockback_velocity = (_ai_target.position - position).normalized() * 400
				
				# Reset momentum after hit
				_charge_momentum = 0
	
	# Use attack02 for high-momentum attacks
	if _charge_momentum > 50:
		_play_anim("attack02")
	else:
		_play_anim("attack01")
	
	if _ai_attack_timer >= attack_cooldown_time:
		_is_charging = false
		_change_state(State.WALK)

func take_hit_ai(damage: int, from_dir: Vector2):
	# Lancers lose momentum when hit
	_charge_momentum = max(_charge_momentum - 30, 0)
	if _is_charging and _charge_momentum < 20:
		_is_charging = false
	super.take_hit_ai(damage, from_dir)
