class_name CombatGroup
extends Node2D

## A group of 5 fighters that acts as a single tactical unit
## Can be given orders and will execute them when unpaused

signal group_selected(group: CombatGroup)
signal group_deselected(group: CombatGroup)
signal order_completed(group: CombatGroup, order_type: String)
signal group_defeated(group: CombatGroup)

enum OrderType { NONE, MOVE, ATTACK, HOLD, AUTO }
enum GroupState { IDLE, MOVING, ENGAGED, FLEEING, DEFEATED }

@export var team: int = 0  # 0 = attacker/player, 1 = defender/enemy
@export var group_id: int = 0
@export var formation_spacing: float = 30.0
@export var move_speed: float = 80.0
@export var auto_command: bool = false

# Group composition
var fighters: Array[Node2D] = []
var fighter_scenes: Array = []

# Current state
var current_state: GroupState = GroupState.IDLE
var current_order: OrderType = OrderType.NONE
var order_target_position: Vector2 = Vector2.ZERO
var order_target_group: CombatGroup = null

# Visual
var selection_highlight: ColorRect
var group_marker: Label
var status_indicator: ColorRect

# Metadata
var total_health: int = 0
var max_health: int = 0
var is_selected: bool = false

func _ready():
	add_to_group("combat_groups")
	_setup_visuals()
	_spawn_fighters()
	_update_health()

func _setup_visuals():
	# Selection highlight (invisible by default)
	selection_highlight = ColorRect.new()
	selection_highlight.size = Vector2(80, 80)
	selection_highlight.position = Vector2(-40, -40)
	selection_highlight.color = Color(1, 1, 0, 0.3)
	selection_highlight.visible = false
	add_child(selection_highlight)
	
	# Group marker with ID
	group_marker = Label.new()
	group_marker.text = "G%d" % (group_id + 1)
	group_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	group_marker.position = Vector2(-15, -60)
	group_marker.size = Vector2(30, 20)
	group_marker.add_theme_font_size_override("font_size", 12)
	group_marker.add_theme_color_override("font_color", Color.WHITE if team == 0 else Color.ORANGE)
	add_child(group_marker)
	
	# Status indicator (small colored square)
	status_indicator = ColorRect.new()
	status_indicator.size = Vector2(10, 10)
	status_indicator.position = Vector2(-5, -75)
	status_indicator.color = Color.GREEN
	add_child(status_indicator)

func _spawn_fighters():
	# Determine which fighter scenes to use based on team
	var available_scenes = _get_fighter_scenes()
	
	# Spawn 5 fighters in a loose formation
	for i in range(5):
		var scene = available_scenes[randi() % available_scenes.size()]
		var fighter = scene.instantiate()
		
		# Position in formation (V shape)
		var offset = _get_formation_offset(i)
		fighter.position = offset
		
		# Set team - Artun_Combat uses 'team' property
		fighter.team = team
		
		# Connect signals - Artun_Combat doesn't have unit_defeated signal
		# But we can check for death in _process
		
		add_child(fighter)
		fighters.append(fighter)
	
	# Give fighters time to find targets
	call_deferred("_refresh_fighter_targets")
	_update_health()

func _refresh_fighter_targets():
	# Tell all fighters to refresh their target lists
	# This ensures they see fighters from other groups as enemies
	for fighter in fighters:
		if is_instance_valid(fighter) and fighter.has_method("find_targets"):
			fighter.find_targets()

func _get_fighter_scenes() -> Array:
	# Mostly sword/shield fighters with occasional variety
	# 80% SwordShield, 20% other (Knight, Archer)
	var roll = randi() % 100
	if roll < 80:
		# Sword & Shield — mainline troops
		return [preload("res://scenes/characters/SwordShield_Fighter.tscn")]
	elif roll < 90:
		# 2-Handed Swordsman — heavy infantry  
		return [preload("res://scenes/characters/Knight_Fighter.tscn")]
	else:
		# Archers — ranged support (rare)
		return [preload("res://scenes/characters/Archer_Fighter.tscn")]

func _get_formation_offset(index: int) -> Vector2:
	# V formation: leader front, 2 behind, 2 at back
	match index:
		0: return Vector2(0, -20)  # Leader front
		1: return Vector2(-25, 0)  # Left
		2: return Vector2(25, 0)   # Right
		3: return Vector2(-15, 25) # Back left
		4: return Vector2(15, 25)  # Back right
	return Vector2.ZERO

func _process(delta):
	if current_state == GroupState.DEFEATED:
		return
	
	_update_health()
	_update_status_indicator()
	
	# Only process orders when not paused (checked by parent controller)
	if get_tree().paused:
		return
	
	match current_state:
		GroupState.IDLE:
			_process_idle(delta)
		GroupState.MOVING:
			_process_moving(delta)
		GroupState.ENGAGED:
			_process_engaged(delta)
		GroupState.FLEEING:
			_process_fleeing(delta)

func _process_idle(_delta):
	# Check for auto-command
	if auto_command and current_order == OrderType.NONE:
		_auto_acquire_target()
	
	# Execute current order
	match current_order:
		OrderType.MOVE:
			current_state = GroupState.MOVING
		OrderType.ATTACK:
			if is_instance_valid(order_target_group) and order_target_group.current_state != GroupState.DEFEATED:
				current_state = GroupState.ENGAGED
			else:
				current_order = OrderType.NONE
		OrderType.HOLD:
			pass  # Stay put
		OrderType.AUTO:
			_auto_acquire_target()

func _process_moving(delta):
	var direction = global_position.direction_to(order_target_position)
	var distance = global_position.distance_to(order_target_position)
	
	if distance < 10.0:
		# Reached destination
		current_state = GroupState.IDLE
		order_completed.emit(self, "move")
		if current_order == OrderType.MOVE:
			current_order = OrderType.NONE
		return
	
	# Move group
	global_position += direction * move_speed * delta
	
	# Face direction
	_update_facing(direction)

func _process_engaged(delta):
	if not is_instance_valid(order_target_group) or order_target_group.current_state == GroupState.DEFEATED:
		# Target defeated, go idle
		current_state = GroupState.IDLE
		order_target_group = null
		if current_order == OrderType.ATTACK:
			current_order = OrderType.NONE
		return
	
	var target_pos = order_target_group.global_position
	var distance = global_position.distance_to(target_pos)
	var attack_range = 80.0
	
	if distance > attack_range:
		# Move toward target
		var direction = global_position.direction_to(target_pos)
		global_position += direction * move_speed * delta
		_update_facing(direction)
	else:
		# In range - fighters will auto-attack via their own AI
		# Just face the target
		_update_facing(global_position.direction_to(target_pos))

func _process_fleeing(delta):
	if not is_instance_valid(order_target_group):
		current_state = GroupState.IDLE
		return
	
	# Run away from target
	var direction = global_position.direction_to(order_target_group.global_position) * -1
	global_position += direction * move_speed * 1.3 * delta
	_update_facing(direction * -1)

func _auto_acquire_target():
	# Find closest enemy group
	var closest = null
	var closest_dist = 1000.0
	
	for group in get_tree().get_nodes_in_group("combat_groups"):
		if group.team != team and group.current_state != GroupState.DEFEATED:
			var dist = global_position.distance_to(group.global_position)
			if dist < closest_dist:
				closest = group
				closest_dist = dist
	
	if closest:
		order_target_group = closest
		current_order = OrderType.ATTACK
		current_state = GroupState.ENGAGED

func _update_facing(direction: Vector2):
	# Update fighter facing based on movement direction
	for fighter in fighters:
		if is_instance_valid(fighter) and fighter.has_method("set_facing_direction"):
			fighter.set_facing_direction(direction)

func _update_health():
	total_health = 0
	max_health = 0
	var alive_count = 0
	
	for fighter in fighters:
		if is_instance_valid(fighter) and "health" in fighter:
			total_health += fighter.health
			max_health += 200  # Artun_Combat has 200 health
			if fighter.health > 0:
				alive_count += 1
	
	# Check for defeat
	if alive_count == 0 and current_state != GroupState.DEFEATED:
		_defeat_group()

func _update_status_indicator():
	var health_percent = float(total_health) / float(max_health) if max_health > 0 else 0
	
	if health_percent > 0.6:
		status_indicator.color = Color.GREEN
	elif health_percent > 0.3:
		status_indicator.color = Color.YELLOW
	else:
		status_indicator.color = Color.RED
	
	# Show health bar or count
	var alive = 0
	for fighter in fighters:
		if is_instance_valid(fighter) and "health" in fighter and fighter.health > 0:
			alive += 1
	group_marker.text = "G%d(%d)" % [group_id + 1, alive]

func _defeat_group():
	current_state = GroupState.DEFEATED
	selection_highlight.visible = false
	group_defeated.emit(self)

func _on_fighter_defeated(_fighter = null):
	_update_health()

# ============================================================================
# PUBLIC API - Orders
# ============================================================================

func select():
	is_selected = true
	selection_highlight.visible = true
	group_selected.emit(self)

func deselect():
	is_selected = false
	selection_highlight.visible = false
	group_deselected.emit(self)

func issue_move_order(target_position: Vector2):
	current_order = OrderType.MOVE
	order_target_position = target_position
	order_target_group = null
	current_state = GroupState.IDLE

func issue_attack_order(target_group: CombatGroup):
	current_order = OrderType.ATTACK
	order_target_group = target_group
	current_state = GroupState.IDLE

func issue_hold_order():
	current_order = OrderType.HOLD
	order_target_group = null
	current_state = GroupState.IDLE

func issue_auto_command(enabled: bool):
	auto_command = enabled
	if enabled:
		current_order = OrderType.AUTO
	else:
		current_order = OrderType.NONE

func get_center_position() -> Vector2:
	return global_position

func is_alive() -> bool:
	return current_state != GroupState.DEFEATED

func get_alive_count() -> int:
	var count = 0
	for fighter in fighters:
		if is_instance_valid(fighter) and "health" in fighter and fighter.health > 0:
			count += 1
	return count

# ============================================================================
# INPUT HANDLING
# ============================================================================

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			group_selected.emit(self)
