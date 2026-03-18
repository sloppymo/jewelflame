class_name General
extends CharacterBody2D

## Dragon Force General - Commands troops in real-time battle
## Has HP, MP, Troop Count, and Spell casting ability

enum GeneralClass { WARRIOR, ROGUE, MAGE }
enum State { IDLE, WALKING, ATTACKING, CASTING, HURT, DEAD, DUEL }
enum Formation { MELEE, STANDBY, ADVANCE, RETREAT }

signal general_selected(general: General)
signal general_died(general: General)
signal troops_changed(new_count: int)
signal spell_cast(spell_name: String, position: Vector2)
signal formation_changed(new_formation: Formation)

# General Stats
@export var general_name: String = "General"
@export var team: int = 0  # 0 = player, 1 = enemy
@export var general_class: GeneralClass = GeneralClass.WARRIOR
@export var max_hp: int = 200  # Increased for longer battles
@export var max_mp: int = 50
@export var max_troops: int = 100
@export var walk_speed: float = 100.0

# Current stats (will be modified during battle)
var current_hp: int
var current_mp: int
var current_troops: int
var current_state: State = State.IDLE
var current_formation: Formation = Formation.ADVANCE

# Spell system
var spell_charge: float = 0.0
var spell_charge_rate: float = 5.0  # MP per second
var spell_cost: int = 20
var spell_ready: bool = false
var equipped_spell: String = "fireball"

# Combat
var is_in_duel: bool = false
var duel_target: General = null
var attack_cooldown: float = 0.0
var attack_range: float = 50.0
var attack_damage: int = 8
var combat_start_delay: float = 2.0  # Delay before combat starts

# Movement
var move_target: Vector2 = Vector2.ZERO
var is_moving: bool = false
var facing_direction: Vector2 = Vector2.DOWN

# Visual components
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var troop_manager: TroopManager = $TroopManager
@onready var selection_ring: ColorRect = $SelectionRing
@onready var health_bar: ProgressBar = $HealthBar
@onready var troop_label: Label = $TroopLabel

func _ready():
	add_to_group("generals")
	
	# Initialize stats
	current_hp = max_hp
	current_mp = 0  # Start with 0 MP, charge up during battle
	current_troops = max_troops
	
	# Setup visuals
	_setup_visuals()
	
	# Connect to troop manager
	if troop_manager:
		troop_manager.setup_troops(current_troops, team)
	
	print("General '%s' ready - Class: %s, Troops: %d" % [general_name, _class_name(), current_troops])

func _setup_visuals():
	# Selection ring (hidden by default)
	if selection_ring:
		selection_ring.visible = false
		selection_ring.color = Color(1, 1, 0, 0.5) if team == 0 else Color(1, 0, 0, 0.5)
	
	# Health bar
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
		health_bar.visible = false  # Only show when selected or damaged
	
	# Troop count label
	if troop_label:
		_update_troop_label()
	
	# Setup sprite frames from existing fighter assets
	_setup_sprite_frames()
		
	# Set initial animation
	_play_animation("idle_down")

func _setup_sprite_frames():
	"""Load sprite frames from existing fighter scenes based on class."""
	if not sprite:
		return
	
	# Choose fighter scene based on class
	var fighter_scene_path: String
	match general_class:
		GeneralClass.WARRIOR:
			fighter_scene_path = "res://scenes/characters/Artun_Fighter.tscn"
		GeneralClass.ROGUE:
			fighter_scene_path = "res://scenes/characters/Janik_Fighter.tscn"
		GeneralClass.MAGE:
			fighter_scene_path = "res://scenes/characters/Nyro_Fighter.tscn"
		_:
			fighter_scene_path = "res://scenes/characters/Artun_Fighter.tscn"
	
	# Load the fighter scene and copy its sprite frames
	var fighter_scene = load(fighter_scene_path)
	if fighter_scene:
		var temp_instance = fighter_scene.instantiate()
		var source_sprite = temp_instance.get_node_or_null("AnimatedSprite2D")
		if source_sprite and source_sprite.sprite_frames:
			sprite.sprite_frames = source_sprite.sprite_frames
			sprite.scale = Vector2(1.5, 1.5)  # Make generals slightly larger
		temp_instance.queue_free()

func _update_troop_label():
	if troop_label:
		troop_label.text = "%d" % current_troops
		# Color based on troop percentage
		var ratio = float(current_troops) / max_troops
		if ratio > 0.6:
			troop_label.modulate = Color.WHITE
		elif ratio > 0.3:
			troop_label.modulate = Color.YELLOW
		else:
			troop_label.modulate = Color.RED

func _class_name() -> String:
	match general_class:
		GeneralClass.WARRIOR: return "Warrior"
		GeneralClass.ROGUE: return "Rogue"
		GeneralClass.MAGE: return "Mage"
		_: return "Unknown"

func _physics_process(delta):
	if current_state == State.DEAD:
		return
	
	# Decrement combat start delay
	if combat_start_delay > 0:
		combat_start_delay -= delta
	
	# Update spell charge
	_update_spell_charge(delta)
	
	# Update attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# Process movement and combat based on state
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.WALKING:
			_process_walking(delta)
		State.ATTACKING:
			_process_attacking(delta)
		State.CASTING:
			_process_casting(delta)
		State.HURT:
			_process_hurt(delta)
		State.DUEL:
			_process_duel(delta)
	
	# Apply movement
	if is_moving:
		move_and_slide()

func _update_spell_charge(delta):
	if current_mp < max_mp and not is_in_duel:
		current_mp += spell_charge_rate * delta
		current_mp = min(current_mp, max_mp)
		
		# Check if spell is ready
		spell_ready = current_mp >= spell_cost

func _process_idle(delta):
	# Check for nearby enemies to attack
	var nearest_enemy = _find_nearest_enemy()
	
	if nearest_enemy:
		var dist = global_position.distance_to(nearest_enemy.global_position)
		
		match current_formation:
			Formation.MELEE:
				# Aggressive - attack if in range, move toward if not
				if dist <= attack_range:
					_start_attack(nearest_enemy)
				else:
					_start_moving_to(nearest_enemy.global_position)
			
			Formation.STANDBY:
				# Defensive - only attack if enemy is very close
				if dist <= attack_range * 0.8:
					_start_attack(nearest_enemy)
			
			Formation.ADVANCE:
				# Move forward looking for enemies
				if dist <= attack_range:
					_start_attack(nearest_enemy)
			
			Formation.RETREAT:
				# Run away
				var away_dir = global_position.direction_to(nearest_enemy.global_position) * -1
				_start_moving_to(global_position + away_dir * 100)
	
	# If we have a move target and not in combat, go there
	elif move_target != Vector2.ZERO and global_position.distance_to(move_target) > 10:
		_start_moving_to(move_target)

func _process_walking(delta):
	if move_target == Vector2.ZERO:
		_stop_moving()
		return
	
	var direction = global_position.direction_to(move_target)
	var distance = global_position.distance_to(move_target)
	
	if distance < 5.0:
		_stop_moving()
		return
	
	# Update facing
	_update_facing(direction)
	
	# Move
	velocity = direction * walk_speed
	
	# Check for enemies while walking (auto-engage if not in retreat)
	if current_formation != Formation.RETREAT:
		var nearest_enemy = _find_nearest_enemy()
		if nearest_enemy and global_position.distance_to(nearest_enemy.global_position) <= attack_range:
			_start_attack(nearest_enemy)

func _process_attacking(delta):
	# Attack animation is playing, damage is dealt during animation
	if not sprite.is_playing():
		# Return to idle or continue attacking
		if current_troops > 0:
			current_state = State.IDLE
		else:
			# Enter duel mode when troops are depleted
			_enter_duel_mode()

func _process_casting(delta):
	# Spell casting animation
	if not sprite.is_playing():
		current_state = State.IDLE

func _process_hurt(delta):
	if not sprite.is_playing():
		if current_hp <= 0:
			_die()
		else:
			current_state = State.IDLE

func _process_duel(delta):
	# 1v1 combat when troops are depleted
	if not is_instance_valid(duel_target) or duel_target.current_state == State.DEAD:
		is_in_duel = false
		duel_target = null
		current_state = State.IDLE
		return
	
	if attack_cooldown <= 0:
		_attack_duel_target()

func _enter_duel_mode():
	# Find nearest enemy general with no troops
	var enemy = _find_nearest_enemy()
	if enemy and enemy.current_troops <= 0:
		is_in_duel = true
		duel_target = enemy
		current_state = State.DUEL
		print("%s entered duel with %s!" % [general_name, enemy.general_name])

func _attack_duel_target():
	if not is_instance_valid(duel_target):
		return
	
	attack_cooldown = 1.0  # Slower attacks in duel
	
	# Face target
	var dir = global_position.direction_to(duel_target.global_position)
	_update_facing(dir)
	
	# Deal damage
	duel_target.take_damage(attack_damage * 2, self)  # Double damage in duel
	
	# Visual feedback
	_play_animation("attack_" + _get_direction_string())

func _start_attack(target: General):
	if attack_cooldown > 0:
		return
	
	# Don't attack during startup delay
	if combat_start_delay > 0:
		return
	
	attack_cooldown = 1.0  # Attack every 1 second (slower combat)
	
	# Face target
	var dir = global_position.direction_to(target.global_position)
	_update_facing(dir)
	
	current_state = State.ATTACKING
	_play_animation("attack_" + _get_direction_string())
	
	# Deal damage based on troop count
	var damage = _calculate_damage()
	target.take_damage(damage, self)
	
	# Lose some troops in the exchange
	_lose_troops(randi() % 3 + 1)

func _calculate_damage() -> int:
	# Damage based on class (small base damage)
	var base_damage = attack_damage  # 8 base
	
	match general_class:
		GeneralClass.WARRIOR: base_damage *= 1.3
		GeneralClass.ROGUE: base_damage *= 1.1
		GeneralClass.MAGE: base_damage *= 0.9
	
	# Small random variation
	var variation = randi_range(-2, 2)
	
	return max(1, int(base_damage + variation))

func _find_nearest_enemy() -> General:
	var nearest: General = null
	var nearest_dist = 1000.0
	
	for general in get_tree().get_nodes_in_group("generals"):
		if general.team != team and general.current_state != State.DEAD:
			var dist = global_position.distance_to(general.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = general
	
	return nearest

func _start_moving_to(target_pos: Vector2):
	move_target = target_pos
	is_moving = true
	current_state = State.WALKING
	
	var dir = global_position.direction_to(target_pos)
	_update_facing(dir)
	_play_animation("walk_" + _get_direction_string())

func _stop_moving():
	is_moving = false
	move_target = Vector2.ZERO
	velocity = Vector2.ZERO
	current_state = State.IDLE
	_play_animation("idle_" + _get_direction_string())

func _update_facing(direction: Vector2):
	facing_direction = direction

func _get_direction_string() -> String:
	if abs(facing_direction.x) > abs(facing_direction.y):
		return "right" if facing_direction.x > 0 else "left"
	else:
		return "down" if facing_direction.y > 0 else "up"

func _play_animation(anim_name: String):
	if not sprite or not sprite.sprite_frames:
		return
	
	# Handle missing cast animations by using attack as fallback
	if anim_name.begins_with("cast_") and not sprite.sprite_frames.has_animation(anim_name):
		anim_name = anim_name.replace("cast_", "attack_")
	
	# Handle missing hurt animations by using idle as fallback
	if anim_name.begins_with("hurt_") and not sprite.sprite_frames.has_animation(anim_name):
		anim_name = anim_name.replace("hurt_", "idle_")
	
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

# ============================================================================
# PUBLIC API
# ============================================================================

func move_to(position: Vector2):
	"""Order the general to move to a position."""
	if current_state != State.DEAD:
		move_target = position
		_start_moving_to(position)

func set_formation(formation: Formation):
	"""Change the general's formation."""
	current_formation = formation
	formation_changed.emit(formation)
	
	# Update troop manager formation
	if troop_manager:
		troop_manager.set_formation(formation)

func cast_spell(target_pos: Vector2) -> bool:
	"""Cast the equipped spell if MP is sufficient."""
	if current_mp < spell_cost or current_state == State.DEAD:
		return false
	
	current_mp -= spell_cost
	spell_ready = false
	current_state = State.CASTING
	
	# Face target
	var dir = global_position.direction_to(target_pos)
	_update_facing(dir)
	
	_play_animation("cast_" + _get_direction_string())
	
	# Emit signal for spell effect
	spell_cast.emit(equipped_spell, target_pos)
	
	return true

func take_damage(damage: int, attacker: General = null):
	"""Take damage to HP."""
	if current_state == State.DEAD:
		return
	
	current_hp -= damage
	
	if health_bar:
		health_bar.value = current_hp
		health_bar.visible = true
	
	# Flash red
	if sprite:
		sprite.modulate = Color(1.5, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color(1, 1, 1)
	
	if current_hp <= 0:
		_die()
	else:
		current_state = State.HURT
		_play_animation("hurt_" + _get_direction_string())

func _lose_troops(amount: int):
	"""Lose troops in combat."""
	current_troops = max(0, current_troops - amount)
	_update_troop_label()
	troops_changed.emit(current_troops)
	
	# Update troop visual
	if troop_manager:
		troop_manager.set_troop_count(current_troops)
	
	# Check for morale break (enter duel mode)
	if current_troops == 0 and not is_in_duel:
		_enter_duel_mode()

func _die():
	current_state = State.DEAD
	is_in_duel = false
	current_troops = 0
	
	if troop_manager:
		troop_manager.set_troop_count(0)
	
	if sprite and sprite.sprite_frames:
		# Check for dead animation, fallback to idle if not found
		if sprite.sprite_frames.has_animation("dead"):
			sprite.play("dead")
		elif sprite.sprite_frames.has_animation("idle_down"):
			sprite.play("idle_down")
		# Hide sprite to show defeated state
		sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
	
	general_died.emit(self)
	print("General %s has died!" % general_name)

func select():
	"""Select this general (player only)."""
	if selection_ring:
		selection_ring.visible = true
	if health_bar:
		health_bar.visible = true

func deselect():
	"""Deselect this general."""
	if selection_ring:
		selection_ring.visible = false
	if health_bar:
		health_bar.visible = false

func is_alive() -> bool:
	return current_state != State.DEAD

func get_troop_ratio() -> float:
	return float(current_troops) / max_troops

# ============================================================================
# INPUT HANDLING
# ============================================================================

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			general_selected.emit(self)
