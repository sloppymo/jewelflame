extends TinyRPGCharacter

# Werewolf - Fast, aggressive melee fighter

var _frenzy_stacks: int = 0
var _max_frenzy: int = 3

func _ready():
	super._ready()
	attack_damage = 20
	move_speed = 110.0
	attack_cooldown_time = 0.5

func _update_ai_charge(delta: float):
	# Werewolves move faster when chasing
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
	
	# Sprint toward target (faster than normal)
	var move_dir = (_ai_target.position - position).normalized()
	
	# Less concerned about allies - werewolves are reckless
	for unit in get_tree().get_nodes_in_group("arena_units"):
		if unit != self and unit.team == team and not unit.is_dead:
			var dist_to_ally = position.distance_to(unit.position)
			if dist_to_ally < 50:
				move_dir += (position - unit.position).normalized() * 0.2
				move_dir = move_dir.normalized()
	
	# Frenzy increases speed
	var speed_mult = 1.0 + (_frenzy_stacks * 0.15)
	position += move_dir * move_speed * speed_mult * delta
	
	if move_dir.x > 0.1:
		facing = "right"
	elif move_dir.x < -0.1:
		facing = "left"
	_update_facing()
	_play_anim("walk")

func _update_ai_attack(delta: float):
	# Face target
	if _ai_target and is_instance_valid(_ai_target):
		var attack_dir = (_ai_target.position - position).normalized()
		if attack_dir.x > 0:
			facing = "right"
		else:
			facing = "left"
		_update_facing()
	
	# Fast attack
	if _ai_state_timer > 0.15 and _ai_state_timer < 0.3 and not _has_hit:
		_has_hit = true
		if _ai_target and is_instance_valid(_ai_target) and not _ai_target.is_dead:
			var dist = position.distance_to(_ai_target.position)
			if dist <= attack_range * 1.5:
				# Build frenzy on successful hit
				_frenzy_stacks = min(_frenzy_stacks + 1, _max_frenzy)
				var dmg = attack_damage + (_frenzy_stacks * 3)
				_ai_target.take_hit_ai(dmg, (_ai_target.position - position).normalized())
	
	_play_anim("attack01")
	
	if _ai_attack_timer >= attack_cooldown_time:
		_change_state(State.WALK)

func take_hit_ai(damage: int, from_dir: Vector2):
	# Lose frenzy when hit
	_frenzy_stacks = max(_frenzy_stacks - 1, 0)
	super.take_hit_ai(damage, from_dir)
