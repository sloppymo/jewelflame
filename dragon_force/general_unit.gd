class_name GeneralUnit
extends CharacterBody2D

## Dragon Force General Unit - Battle Scene
## Has HP, troops, moves and fights

signal unit_selected(unit: Node2D)
signal unit_died(unit: Node2D)
signal troops_changed(count: int)

enum State { IDLE, WALKING, ATTACKING, HURT, DEAD }

# Stats
@export var unit_name: String = "General"
@export var team: int = 0  # 0 = player, 1 = enemy
@export var max_hp: int = 100
@export var max_troops: int = 10
@export var move_speed: float = 120.0
@export var attack_damage: int = 5
@export var attack_range: float = 30.0

# Current state
var current_hp: int
var current_troops: int
var current_state: State = State.IDLE
var is_selected: bool = false

# Movement - Waypoint system
var waypoints: Array[Vector2] = []  # Queue of movement targets
var current_waypoint: Vector2 = Vector2.ZERO
var move_target: Vector2 = Vector2.ZERO  # For backward compatibility
var facing_direction: Vector2 = Vector2.DOWN

# Combat
var attack_target: Node2D = null
var attack_cooldown: float = 0.0

# Visual
@onready var sprite: Sprite2D = $Sprite2D
@onready var selection_ring: ColorRect = $SelectionRing
@onready var health_bar: ProgressBar = $HealthBar
@onready var troop_label: Label = $TroopLabel
@onready var troop_manager: Node2D = $TroopManager

func _ready():
	add_to_group("general_units")
	
	# Initialize stats
	current_hp = max_hp
	current_troops = max_troops
	
	# Setup visuals
	_setup_visuals()
	_setup_troops()
	
	print("GeneralUnit: %s ready with %d troops" % [unit_name, current_troops])

func _setup_visuals():
	# Selection ring
	if selection_ring:
		selection_ring.visible = false
		selection_ring.color = Color(1, 1, 0, 0.5) if team == 0 else Color(1, 0, 0, 0.5)
	
	# Health bar
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
		health_bar.visible = false
	
	# Troop label
	_update_troop_label()
	
	# Set team color
	if sprite:
		sprite.modulate = Color(0.3, 0.5, 1.0) if team == 0 else Color(1.0, 0.3, 0.3)

func _setup_troops():
	"""Create visual troop representation."""
	if not troop_manager:
		return
	
	# Clear existing troops only (keep waypoints)
	for child in troop_manager.get_children():
		if not child.name.begins_with("Waypoint"):
			child.queue_free()
	
	# Create 10 troop dots in V formation
	for i in range(current_troops):
		var troop = ColorRect.new()
		troop.size = Vector2(4, 4)
		troop.color = Color(0.3, 0.5, 1.0) if team == 0 else Color(1.0, 0.3, 0.3)
		
		# V formation positions
		var offset = Vector2.ZERO
		match i:
			0: offset = Vector2(0, -15)
			1, 2: offset = Vector2(-10 + (i-1)*20, -5)
			3, 4: offset = Vector2(-15 + (i-3)*30, 5)
			5, 6: offset = Vector2(-20 + (i-5)*40, 15)
			7, 8, 9: offset = Vector2(-15 + (i-7)*15, 25)
		
		troop.position = offset - Vector2(2, 2)
		troop_manager.add_child(troop)

func update_waypoint_visuals():
	"""Update visual waypoint markers."""
	if not troop_manager:
		return
	
	# Clear old waypoint visuals
	for child in troop_manager.get_children():
		if child.name.begins_with("Waypoint"):
			child.queue_free()
	
	# Show current waypoint
	if current_waypoint != Vector2.ZERO:
		_add_waypoint_marker(current_waypoint, 0)
	
	# Show queued waypoints
	for i in range(waypoints.size()):
		_add_waypoint_marker(waypoints[i], i + 1)

func _add_waypoint_marker(pos: Vector2, index: int):
	"""Add a visual waypoint marker."""
	var marker = ColorRect.new()
	marker.name = "Waypoint_%d" % index
	marker.size = Vector2(6, 6)
	marker.color = Color(1, 1, 0, 0.7)  # Yellow
	
	# Position relative to general
	var relative_pos = pos - global_position
	marker.position = relative_pos - Vector2(3, 3)
	
	troop_manager.add_child(marker)

func _update_troop_label():
	if troop_label:
		troop_label.text = "%d" % current_troops

# ============================================================================
# PROCESS
# ============================================================================

func _physics_process(delta):
	if current_state == State.DEAD:
		return
	
	# Update attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# Process state
	match current_state:
		State.IDLE:
			_process_idle()
		State.WALKING:
			_process_walking(delta)
		State.ATTACKING:
			_process_attacking()
		State.HURT:
			_process_hurt()

func _process_idle():
	# Check for enemies to attack
	var nearest = _find_nearest_enemy()
	if nearest:
		var dist = global_position.distance_to(nearest.global_position)
		if dist <= attack_range:
			_start_attack(nearest)
		elif move_target != Vector2.ZERO:
			_start_moving(move_target)

func _process_walking(delta):
	# Get current target (waypoint or move_target)
	var target = current_waypoint if current_waypoint != Vector2.ZERO else move_target
	
	if target == Vector2.ZERO:
		# Check for next waypoint
		if waypoints.size() > 0:
			current_waypoint = waypoints.pop_front()
			print("GeneralUnit: Moving to next waypoint: %s" % current_waypoint)
		else:
			_stop_moving()
		return
	
	var direction = global_position.direction_to(target)
	var distance = global_position.distance_to(target)
	
	if distance < 5.0:
		# Reached waypoint
		print("GeneralUnit: Reached waypoint!")
		if waypoints.size() > 0:
			current_waypoint = waypoints.pop_front()
			print("GeneralUnit: Next waypoint: %s" % current_waypoint)
		else:
			_stop_moving()
		update_waypoint_visuals()
		return
	
	# Move
	velocity = direction * move_speed
	move_and_slide()
	
	# Update facing
	_update_facing(direction)
	
	# Check for enemies while moving (only auto-engage if not already attacking)
	if current_state == State.WALKING:
		var nearest = _find_nearest_enemy()
		if nearest and global_position.distance_to(nearest.global_position) <= attack_range:
			_start_attack(nearest)

func _process_attacking():
	# Check if target is invalid or dead
	if not attack_target or not is_instance_valid(attack_target):
		current_state = State.IDLE
		attack_target = null
		return
	
	# Safe check for dead state
	if attack_target is GeneralUnit and attack_target.current_state == State.DEAD:
		current_state = State.IDLE
		attack_target = null
		return
	
	# Check if target moved out of range - chase it
	var dist_to_target = global_position.distance_to(attack_target.global_position)
	if dist_to_target > attack_range * 1.5:  # Give some leeway
		current_state = State.WALKING
		move_target = attack_target.global_position
		return
	
	# Face target
	_update_facing(global_position.direction_to(attack_target.global_position))
	
	# Deal damage on cooldown
	if attack_cooldown <= 0:
		_deal_damage()

func _process_hurt():
	# Return to idle after brief delay
	if not sprite or sprite.modulate == Color(1, 1, 1):
		current_state = State.IDLE

# ============================================================================
# COMBAT
# ============================================================================

func _find_nearest_enemy() -> GeneralUnit:
	var nearest: Node2D = null
	var nearest_dist = 1000.0
	
	for unit in get_tree().get_nodes_in_group("general_units"):
		if unit.team != team and unit.current_state != State.DEAD:
			var dist = global_position.distance_to(unit.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = unit
	
	return nearest

func _start_attack(target: Node2D):
	attack_target = target
	current_state = State.ATTACKING

func _deal_damage():
	attack_cooldown = 0.5  # 0.5 seconds between attacks (faster combat)
	
	if attack_target:
		# Calculate damage based on troop count
		var damage = attack_damage + (current_troops / 2)
		attack_target.take_damage(damage)
		
		# Lose some troops in exchange
		_lose_troops(randi() % 2 + 1)

func take_damage(damage: int):
	if current_state == State.DEAD:
		return
	
	current_hp -= damage
	
	# Update health bar
	if health_bar:
		health_bar.value = current_hp
		health_bar.visible = true
	
	# Flash red (clamped to valid color range)
	if sprite:
		sprite.modulate = Color(1.5, 0.5, 0.5)
		create_tween().tween_property(sprite, "modulate", Color(1, 1, 1), 0.2)
	
	if current_hp <= 0:
		_die()
	else:
		current_state = State.HURT

func _lose_troops(amount: int):
	var old_troops = current_troops
	current_troops = max(0, current_troops - amount)
	_update_troop_label()
	troops_changed.emit(current_troops)
	
	# Only update visual troops if count changed significantly (optimization)
	if current_troops != old_troops:
		_setup_troops()

func _die():
	current_state = State.DEAD
	current_troops = 0
	
	# Visual death
	if sprite:
		sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
	if selection_ring:
		selection_ring.visible = false
	if health_bar:
		health_bar.visible = false
	
	# Clear troops
	if troop_manager:
		for child in troop_manager.get_children():
			child.visible = false
	
	unit_died.emit(self)
	print("GeneralUnit: %s has died!" % unit_name)

# ============================================================================
# MOVEMENT
# ============================================================================

func move_to(position: Vector2, shift_held: bool = false):
	"""Order the general to move to a position.
	If shift_held, add as waypoint. Otherwise, clear waypoints and move."""
	if current_state == State.DEAD:
		return
	
	if shift_held:
		# Add waypoint
		waypoints.append(position)
		print("GeneralUnit: Added waypoint %s (total: %d)" % [position, waypoints.size()])
		update_waypoint_visuals()
		
		# If idle, start moving
		if current_state == State.IDLE:
			current_waypoint = waypoints.pop_front()
			_start_moving(current_waypoint)
	else:
		# Clear waypoints and move to new target
		waypoints.clear()
		current_waypoint = Vector2.ZERO
		move_target = position
		_start_moving(position)
	
	update_waypoint_visuals()

func clear_waypoints():
	"""Clear all waypoints and stop."""
	waypoints.clear()
	current_waypoint = Vector2.ZERO
	move_target = Vector2.ZERO
	update_waypoint_visuals()
	_stop_moving()

func _start_moving(target: Vector2):
	move_target = target
	current_state = State.WALKING

func _stop_moving():
	move_target = Vector2.ZERO
	current_waypoint = Vector2.ZERO
	velocity = Vector2.ZERO
	current_state = State.IDLE

func _update_facing(direction: Vector2):
	facing_direction = direction

# ============================================================================
# SELECTION
# ============================================================================

func select():
	if is_selected:
		return  # Prevent infinite loop
	is_selected = true
	if selection_ring:
		selection_ring.visible = true
	if health_bar:
		health_bar.visible = true
	unit_selected.emit(self)

func deselect():
	is_selected = false
	if selection_ring:
		selection_ring.visible = false

func is_alive() -> bool:
	return current_state != State.DEAD

# ============================================================================
# INPUT
# ============================================================================

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if team == 0 and is_alive():  # Player can only select living own units
				select()
