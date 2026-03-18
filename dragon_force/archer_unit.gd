extends "res://dragon_force/general_unit.gd"

## Archer Unit - Ranged unit that keeps distance
## High damage from afar, vulnerable in melee

@export var projectile_range: float = 150.0
@export var min_ideal_range: float = 60.0  # Try to stay at least this far
@export var kite_chance: float = 0.3  # Chance to retreat when enemy gets close

var is_kiting: bool = false

func _ready():
	super._ready()
	# Archer stats
	max_hp = 70  # Fragile
	move_speed = 100.0  # Average
	attack_damage = 8
	attack_range = 140.0  # Long range!
	
	# Visual - greenish tint
	if sprite:
		sprite.modulate = Color(0.4, 1.0, 0.4) if team == 0 else Color(0.8, 0.3, 0.3)

func _process_attacking():
	if not attack_target or not is_instance_valid(attack_target):
		current_state = State.IDLE
		attack_target = null
		return
	
	if attack_target.current_state == State.DEAD:
		current_state = State.IDLE
		attack_target = null
		return
	
	var dist = global_position.distance_to(attack_target.global_position)
	
	# Too close? Try to kite back
	if dist < min_ideal_range and randf() < kite_chance:
		_kite_away()
		return
	
	# Face target
	_update_facing(global_position.direction_to(attack_target.global_position))
	
	# Shoot on cooldown
	if attack_cooldown <= 0:
		_fire_arrow()

func _kite_away():
	"""Retreat to maintain optimal range."""
	if attack_target:
		var away_dir = (global_position - attack_target.global_position).normalized()
		var kite_pos = global_position + away_dir * 80
		move_to(kite_pos)
		is_kiting = true

func _fire_arrow():
	"""Fire a projectile at the target."""
	attack_cooldown = 1.0  # Slower fire rate
	
	if attack_target and is_instance_valid(attack_target):
		var damage = attack_damage + (current_troops / 3)
		attack_target.take_damage(damage)
		_spawn_arrow_effect(attack_target.global_position)
		
		_lose_troops(1)  # Archers lose troops slower

func _spawn_arrow_effect(target_pos: Vector2):
	"""Visual arrow flying to target."""
	var arrow = ColorRect.new()
	arrow.size = Vector2(12, 3)
	arrow.color = Color(0.9, 0.9, 0.3, 0.9)
	arrow.position = global_position - arrow.size / 2
	arrow.rotation = global_position.angle_to_point(target_pos)
	get_parent().add_child(arrow)
	
	# Animate arrow flying
	var tween = create_tween()
	tween.tween_property(arrow, "position", target_pos - arrow.size / 2, 0.15)
	tween.tween_callback(func():
		arrow.color = Color(1, 0.8, 0.2, 0.7)
		var fade = create_tween()
		fade.tween_property(arrow, "modulate:a", 0.0, 0.1)
		fade.tween_callback(arrow.queue_free)
	)

func _find_nearest_enemy() -> Node2D:
	"""Override to prefer enemies within range."""
	var nearest: Node2D = null
	var nearest_dist = 10000.0
	var nearest_in_range: Node2D = null
	var nearest_in_range_dist = 10000.0
	
	for unit in get_tree().get_nodes_in_group("general_units"):
		if unit.team != team and unit.current_state != State.DEAD:
			var dist = global_position.distance_to(unit.global_position)
			
			# Track absolute nearest
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = unit
			
			# Track nearest within attack range
			if dist < projectile_range and dist < nearest_in_range_dist:
				nearest_in_range_dist = dist
				nearest_in_range = unit
	
	# Prefer target in range, fallback to nearest
	return nearest_in_range if nearest_in_range else nearest
