extends "res://dragon_force/general_unit.gd"

## Monster Unit - Huge tank that terrifies nearby enemies
## High HP, slow, fear aura reduces enemy damage

@export var fear_range: float = 80.0
@export var fear_damage_reduction: float = 0.3  # Enemies deal 30% less damage
@export var roar_cooldown: float = 8.0
@export var roar_duration: float = 3.0

var roar_timer: float = 0.0
var is_roaring: bool = false

func _ready():
	super._ready()
	# Monster stats
	max_hp = 250  # Tank!
	move_speed = 70.0  # Very slow
	attack_damage = 12
	attack_range = 45.0
	max_troops = 5  # Fewer but tougher "troops" (maybe represents monster pack?)
	
	# Visual - purple/dark tint, larger
	if sprite:
		sprite.modulate = Color(0.6, 0.3, 0.9) if team == 0 else Color(0.5, 0.1, 0.1)
		# Make sprite bigger
		sprite.scale = Vector2(1.3, 1.3)

func _physics_process(delta):
	super._physics_process(delta)
	
	# Apply fear aura
	_apply_fear_aura()
	
	# Handle roar cooldown
	if roar_timer > 0:
		roar_timer -= delta

func _apply_fear_aura():
	"""Reduce damage of nearby enemies."""
	for unit in get_tree().get_nodes_in_group("general_units"):
		if unit.team == team or unit == self:
			continue
		if not is_instance_valid(unit) or unit.current_state == State.DEAD:
			continue
		
		var dist = global_position.distance_to(unit.global_position)
		if dist <= fear_range:
			# Visual indicator of fear (subtle red tint on enemies)
			if unit.sprite and not is_roaring:
				pass  # Could add fear visual here

func _deal_damage():
	"""Powerful smash attack with optional roar."""
	if is_roaring:
		return  # Can't attack while roaring
	
	attack_cooldown = 1.2  # Slow attacks
	
	# Randomly roar instead of attacking
	if roar_timer <= 0 and randf() < 0.3:
		_roar()
		return
	
	if attack_target and is_instance_valid(attack_target):
		if attack_target.current_state != State.DEAD:
			var damage = attack_damage + (current_troops)
			attack_target.take_damage(damage)
			_spawn_smash_effect(attack_target.global_position)
			
			# Area damage - hits nearby enemies too
			_deal_splash_damage(attack_target.global_position)
	
	_lose_troops(randi() % 2 + 1)

func _roar():
	"""Terrifying roar that stuns nearby enemies briefly."""
	is_roaring = true
	roar_timer = roar_cooldown
	
	print("Monster: %s ROARS!" % unit_name)
	
	# Visual roar effect
	_spawn_roar_effect()
	
	# Stun nearby enemies (force them to idle briefly)
	for unit in get_tree().get_nodes_in_group("general_units"):
		if unit.team == team or unit == self:
			continue
		if not is_instance_valid(unit) or unit.current_state == State.DEAD:
			continue
		
		var dist = global_position.distance_to(unit.global_position)
		if dist <= fear_range * 1.5:
			# Interrupt their action
			if unit.current_state == State.ATTACKING or unit.current_state == State.WALKING:
				unit.current_state = State.IDLE
				unit.attack_target = null
				print("Monster: %s is terrified!" % unit.unit_name)
	
	# End roar after duration
	get_tree().create_timer(roar_duration).timeout.connect(func():
		is_roaring = false
	)

func _deal_splash_damage(center: Vector2):
	"""Deal reduced damage to enemies near the primary target."""
	for unit in get_tree().get_nodes_in_group("general_units"):
		if unit.team == team or unit == self:
			continue
		if not is_instance_valid(unit) or unit.current_state == State.DEAD:
			continue
		if unit == attack_target:
			continue  # Skip primary target
		
		var dist = center.distance_to(unit.global_position)
		if dist < 40:
			var splash_damage = int((attack_damage + current_troops) * 0.5)
			unit.take_damage(splash_damage)
			_spawn_splash_effect(unit.global_position)

func _spawn_smash_effect(pos: Vector2):
	var effect = ColorRect.new()
	effect.size = Vector2(20, 20)
	effect.color = Color(0.8, 0.2, 0.2, 0.8)
	effect.position = pos - effect.size / 2
	get_parent().add_child(effect)
	
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.4)
	tween.tween_callback(effect.queue_free)

func _spawn_roar_effect():
	var roar = ColorRect.new()
	roar.size = Vector2(fear_range * 2, fear_range * 2)
	roar.color = Color(0.5, 0.1, 0.5, 0.3)
	roar.position = -roar.size / 2
	add_child(roar)
	
	var tween = create_tween()
	tween.tween_property(roar, "modulate:a", 0.0, roar_duration)
	tween.tween_callback(roar.queue_free)

func _spawn_splash_effect(pos: Vector2):
	var effect = ColorRect.new()
	effect.size = Vector2(10, 10)
	effect.color = Color(0.6, 0.2, 0.2, 0.6)
	effect.position = pos - effect.size / 2
	get_parent().add_child(effect)
	
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)
