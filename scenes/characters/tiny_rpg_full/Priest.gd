extends TinyRPGCharacter

# Priest - Support unit that heals allies

@export var heal_range: float = 120.0
@export var heal_amount: int = 25
@export var heal_cooldown: float = 3.0

var _heal_timer: float = 0.0
var _heal_target: TinyRPGCharacter = null

func _ready():
	super._ready()
	max_health = 100
	attack_damage = 12
	attack_range = 100.0
	attack_cooldown_time = 1.0

func _physics_process(delta):
	if is_dead:
		return
	
	_heal_timer += delta
	_ai_state_timer += delta
	_ai_attack_timer += delta
	
	if _knockback_velocity.length() > 1:
		position += _knockback_velocity * delta
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 400 * delta)
		return
	
	if ai_enabled:
		# Priests prioritize healing over attacking
		if _heal_timer >= heal_cooldown:
			_find_heal_target()
			if _heal_target and is_instance_valid(_heal_target):
				_update_ai_heal(delta)
				return
		
		match current_state:
			State.IDLE:
				_update_ai_idle(delta)
			State.WALK:
				_update_ai_charge(delta)
			State.ATTACK:
				_update_ai_attack(delta)
			State.HURT:
				_update_ai_hurt(delta)

func _find_heal_target():
	"""Find the ally with lowest health percentage."""
	var lowest_health_pct: float = 1.0
	_heal_target = null
	
	for unit in get_tree().get_nodes_in_group("arena_units"):
		if unit is TinyRPGCharacter and unit != self and unit.team == team and not unit.is_dead:
			var health_pct = float(unit.current_health) / unit.max_health
			if health_pct < lowest_health_pct and health_pct < 0.7:  # Only heal if below 70%
				lowest_health_pct = health_pct
				_heal_target = unit

func _update_ai_heal(delta: float):
	"""Move to heal target and cast heal."""
	if not _heal_target or not is_instance_valid(_heal_target) or _heal_target.is_dead:
		_heal_target = null
		return
	
	var dist = position.distance_to(_heal_target.position)
	
	if dist <= heal_range:
		# Cast heal projectile
		_play_anim("attack02")
		_fire_heal_projectile()
		_heal_timer = 0.0
		_heal_target = null
	else:
		# Move toward heal target
		var move_dir = (_heal_target.position - position).normalized()
		position += move_dir * move_speed * delta
		
		if move_dir.x > 0.1:
			facing = "right"
		elif move_dir.x < -0.1:
			facing = "left"
		_update_facing()
		_play_anim("walk")

func _fire_heal_projectile():
	"""Fire a healing projectile."""
	if not _heal_target or not is_instance_valid(_heal_target):
		return
	
	var heal = preload("res://scenes/effects/magic_heal_projectile.tscn").instantiate()
	get_parent().add_child(heal)
	heal.global_position = global_position + Vector2(0, -20)
	var dir = (_heal_target.global_position - global_position).normalized()
	heal.fire(dir, self, heal_amount, team, true)

func _update_ai_idle(delta: float):
	"""Override to also look for heal targets."""
	if _heal_timer >= heal_cooldown:
		_find_heal_target()
		if _heal_target:
			return
		super._update_ai_idle(delta)
