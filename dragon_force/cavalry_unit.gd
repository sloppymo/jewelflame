extends "res://dragon_force/general_unit.gd"

## Cavalry Unit - Fast moving unit with charge attack
## Gains damage bonus when moving at full speed

@export var charge_bonus_damage: int = 5
@export var charge_speed_threshold: float = 0.8
@export var trample_range: float = 20.0

var is_charging: bool = false
var charge_target: Vector2 = Vector2.ZERO

func _ready():
	super._ready()
	# Cavalry stats
	max_hp = 120
	move_speed = 180.0  # Fast!
	attack_damage = 6
	attack_range = 35.0
	
	# Visual - yellowish tint
	if sprite:
		sprite.modulate = Color(1.0, 0.9, 0.4) if team == 0 else Color(1.0, 0.5, 0.2)

func _process_walking(delta):
	# Check if we're charging (moving fast toward target)
	var target = current_waypoint if current_waypoint != Vector2.ZERO else move_target
	
	if target != Vector2.ZERO:
		var dist = global_position.distance_to(target)
		if dist > 50:  # Charging if far from target
			is_charging = true
		else:
			is_charging = false
	
	# Trample - damage units we pass through while charging
	if is_charging:
		_trample_enemies()
	
	# Call parent walking logic
	super._process_walking(delta)

func _trample_enemies():
	"""Damage enemies we run past while charging."""
	for unit in get_tree().get_nodes_in_group("general_units"):
		if unit == self or unit.team == team:
			continue
		if not is_instance_valid(unit) or unit.current_state == State.DEAD:
			continue
		
		var dist = global_position.distance_to(unit.global_position)
		if dist < trample_range:
			# Trample damage (small, but can hit multiple times)
			unit.take_damage(2)
			_spawn_trample_effect(unit.global_position)

func _deal_damage():
	"""Charge attack deals extra damage if charging."""
	attack_cooldown = 0.6
	
	if attack_target and is_instance_valid(attack_target):
		if attack_target.current_state != State.DEAD:
			var damage = attack_damage + (current_troops / 2)
			if is_charging:
				damage += charge_bonus_damage
				print("Cavalry: %s CHARGE attack for %d damage!" % [unit_name, damage])
				is_charging = false  # Charge expended
			attack_target.take_damage(damage)
			_spawn_attack_effect(attack_target.global_position)
	
	_lose_troops(randi() % 2 + 1)

func _spawn_trample_effect(pos: Vector2):
	var effect = ColorRect.new()
	effect.size = Vector2(6, 6)
	effect.color = Color(0.8, 0.6, 0.2, 0.5)
	effect.position = pos - effect.size / 2
	get_parent().add_child(effect)
	
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.2)
	tween.tween_callback(effect.queue_free)
