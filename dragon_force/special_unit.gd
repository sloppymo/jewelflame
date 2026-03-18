extends "res://dragon_force/general_unit.gd"

## Special Unit - Heavy melee unit with wave/cleave attack
## Attacks in a wide arc in front, hitting multiple enemies

@export var wave_attack_range: float = 60.0
@export var wave_attack_angle: float = 90.0  # Degrees, centered on facing direction
@export var wave_damage_multiplier: float = 0.7  # 70% damage to secondary targets

func _ready():
	super._ready()
	# Special units have more HP but move slower
	max_hp = 150
	move_speed = 90.0
	attack_damage = 8
	attack_range = 40.0  # Slightly longer reach
	
	# Visual distinction - larger sprite tint
	if sprite:
		sprite.modulate = Color(0.2, 0.4, 1.2) if team == 0 else Color(1.2, 0.2, 0.2)

func _deal_damage():
	"""Override to perform wave attack hitting multiple enemies in arc."""
	attack_cooldown = 0.8  # Slower attack speed for balance
	
	# Primary target takes full damage
	if attack_target and is_instance_valid(attack_target):
		if attack_target.current_state != State.DEAD:
			var damage = attack_damage + (current_troops / 2)
			attack_target.take_damage(damage)
			
			# Visual effect for primary hit
			_spawn_attack_effect(attack_target.global_position)
	
	# Wave attack - hit all enemies in arc
	_perform_wave_attack()
	
	# Lose troops from exertion
	_lose_troops(randi() % 2 + 1)

func _perform_wave_attack():
	"""Attack all enemies in a wide arc in front of the unit."""
	var hit_count = 0
	
	for unit in get_tree().get_nodes_in_group("general_units"):
		if unit == self:
			continue
		if unit.team == team:
			continue
		if not is_instance_valid(unit):
			continue
		if unit.current_state == State.DEAD:
			continue
		
		var to_unit = unit.global_position - global_position
		var dist = to_unit.length()
		
		# Check range
		if dist > wave_attack_range:
			continue
		
		# Check angle (unit must be in front arc)
		var angle_to_unit = rad_to_deg(facing_direction.angle_to(to_unit.normalized()))
		if abs(angle_to_unit) > wave_attack_angle / 2:
			continue
		
		# Hit this unit with reduced damage
		var wave_damage = int((attack_damage + (current_troops / 2)) * wave_damage_multiplier)
		unit.take_damage(wave_damage)
		hit_count += 1
		
		# Visual effect for each hit
		_spawn_attack_effect(unit.global_position, true)
	
	if hit_count > 0:
		print("SpecialUnit: %s wave attack hit %d enemies!" % [unit_name, hit_count])

func _spawn_attack_effect(pos: Vector2, is_secondary: bool = false):
	"""Spawn a visual effect for the attack."""
	var effect = ColorRect.new()
	effect.size = Vector2(12, 12) if not is_secondary else Vector2(8, 8)
	effect.color = Color(1, 0.8, 0.2, 0.8) if not is_secondary else Color(1, 0.6, 0.2, 0.6)
	effect.position = pos - effect.size / 2
	get_parent().add_child(effect)
	
	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)
