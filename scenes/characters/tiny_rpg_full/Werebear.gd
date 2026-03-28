extends TinyRPGCharacter

# Werebear - Slow but powerful tank with berserk mode

var _berserk_threshold: float = 0.3  # Go berserk below 30% health
var _is_berserk: bool = false

func _ready():
	super._ready()
	max_health = 300
	current_health = 300
	attack_damage = 35
	move_speed = 45.0
	attack_cooldown_time = 1.2

func take_hit_ai(damage: int, from_dir: Vector2):
	# Werebears have damage reduction
	var reduced_damage = int(damage * 0.8)  # 20% damage reduction
	super.take_hit_ai(reduced_damage, from_dir)
	
	# Check for berserk mode
	if not _is_berserk and float(current_health) / max_health < _berserk_threshold:
		_enter_berserk()

func _enter_berserk():
	_is_berserk = true
	attack_damage = int(attack_damage * 1.5)
	move_speed = move_speed * 1.3
	anim_speed_mult = 1.3
	# Rebuild sprite frames with new speed
	build_sprite_frames()
	
func _update_ai_attack(delta: float):
	# Face target
	if _ai_target and is_instance_valid(_ai_target):
		var attack_dir = (_ai_target.position - position).normalized()
		if attack_dir.x > 0:
			facing = "right"
		else:
			facing = "left"
		_update_facing()
	
	# Heavy attack with knockback
	if _ai_state_timer > 0.25 and _ai_state_timer < 0.5 and not _has_hit:
		_has_hit = true
		if _ai_target and is_instance_valid(_ai_target) and not _ai_target.is_dead:
			var dist = position.distance_to(_ai_target.position)
			if dist <= attack_range * 1.5:
				_ai_target.take_hit_ai(attack_damage, (_ai_target.position - position).normalized())
				# Apply extra knockback
				if _ai_target.has_method("take_hit_ai"):
					_ai_target._knockback_velocity = (_ai_target.position - position).normalized() * 250
	
	_play_anim("attack01")
	
	if _ai_attack_timer >= attack_cooldown_time:
		_change_state(State.WALK)
