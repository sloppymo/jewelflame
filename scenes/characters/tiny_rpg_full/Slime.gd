extends TinyRPGCharacter

# Slime - Weak but splits when hit

var _split_count: int = 0
var _max_splits: int = 1

func _ready():
	super._ready()
	max_health = 50
	current_health = 50
	attack_damage = 8
	move_speed = 40.0

func take_hit_ai(damage: int, from_dir: Vector2):
	# Slimes take extra damage from fire/attacks
	var actual_damage = int(damage * 1.2)
	
	var old_health = current_health
	super.take_hit_ai(actual_damage, from_dir)
	
	# Split if health drops below half and hasn't split yet
	if old_health > max_health / 2 and current_health <= max_health / 2 and _split_count < _max_splits:
		_split()

func _split():
	_split_count += 1
	# In a full implementation, this would spawn a smaller slime
	# For now, just heal a bit and get smaller
	heal(15)
	target_scale = target_scale * 0.7
	scale = Vector2(target_scale, target_scale)
	attack_damage = int(attack_damage * 0.6)

func _update_ai_charge(delta: float):
	# Slimes move slowly and erratically
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
	
	# Erratic movement - sometimes pause
	if randf() < 0.1:
		_play_anim("idle")
		return
	
	var move_dir = (_ai_target.position - position).normalized()
	
	# Random jitter
	move_dir += Vector2(randf() - 0.5, randf() - 0.5) * 0.3
	move_dir = move_dir.normalized()
	
	position += move_dir * move_speed * delta
	
	if move_dir.x > 0.1:
		facing = "right"
	elif move_dir.x < -0.1:
		facing = "left"
	_update_facing()
	_play_anim("walk")
