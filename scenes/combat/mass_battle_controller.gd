class_name MassBattleController
extends Node2D

## Real-Time with Pause (RTwP) Mass Battle Controller
## 4 groups of 5 fighters per team (20 vs 20)
## Pause to give orders, unpause to execute

const CombatGroup = preload("res://scenes/combat/combat_group.gd")

signal battle_started()
signal battle_ended(result: Dictionary)
signal pause_changed(is_paused: bool)
signal group_selection_changed(selected_groups: Array)
signal order_mode_changed(mode: String)

enum OrderMode { SELECT, MOVE, ATTACK, HOLD }
enum BattlePhase { SETUP, COMBAT, ENDED }

# Configuration
@export var attacker_spawn_x: float = 200.0
@export var defender_spawn_x: float = 1000.0
@export var spawn_y_start: float = 150.0
@export var spawn_y_spacing: float = 120.0

# Battle data from strategic layer
var attacker_data: Dictionary = {}
var defender_data: Dictionary = {}

# State
var current_phase: BattlePhase = BattlePhase.SETUP
var is_paused: bool = true  # Start paused
var current_order_mode: OrderMode = OrderMode.SELECT

# Groups
var attacker_groups: Array[CombatGroup] = []
var defender_groups: Array[CombatGroup] = []
var selected_groups: Array[CombatGroup] = []

# References
@onready var camera: Camera2D = $Camera2D
@onready var ui_layer: CanvasLayer = $CanvasLayer
@onready var selection_box: ColorRect = $SelectionBox
@onready var ground: StaticBody2D = $Ground

# Input state
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO

func _ready():
	print("MassBattleController: Initializing...")
	
	# Setup ground for mouse detection
	_setup_ground()
	
	# Connect to UI
	_connect_ui_signals()
	
	# Spawn battle groups
	call_deferred("_spawn_groups")
	
	# Start paused - use call_deferred to ensure it happens after scene load
	call_deferred("_initial_pause")
	
	print("MassBattleController: Ready")

func _initial_pause():
	set_pause(true)

func _setup_ground():
	if ground:
		# Create collision shape for the entire battlefield
		var collision = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(1280, 720)
		collision.shape = rect
		collision.position = Vector2(640, 360)
		ground.add_child(collision)

func _connect_ui_signals():
	if ui_layer:
		ui_layer.pause_toggled.connect(toggle_pause)
		ui_layer.order_mode_selected.connect(set_order_mode_by_string)
		ui_layer.auto_command_toggled.connect(_on_auto_command_toggled)
		ui_layer.retreat_requested.connect(_on_retreat)
		
		# Connect controller signals to UI
		pause_changed.connect(ui_layer.update_pause_state)
		order_mode_changed.connect(ui_layer.update_order_mode)
		group_selection_changed.connect(ui_layer.update_selection_count)
		battle_ended.connect(_on_battle_ended_for_ui)

func _on_auto_command_toggled(enabled: bool):
	for group in selected_groups:
		group.issue_auto_command(enabled)

func _on_retreat():
	# Attacker retreats - defender wins
	_end_battle_with_retreat()

func _on_battle_ended_for_ui(result: Dictionary):
	if ui_layer:
		ui_layer.show_victory(result.get("attacker_won", false), result)

func _end_battle_with_retreat():
	current_phase = BattlePhase.ENDED
	set_pause(true)
	
	var attacker_casualties = _calculate_casualties(attacker_groups)
	var defender_casualties = _calculate_casualties(defender_groups)
	
	var result = {
		"attacker_won": false,
		"defender_won": true,
		"retreat": true,
		"attacker_casualties": attacker_casualties,
		"defender_casualties": defender_casualties,
		"attacker_survivors": _calculate_survivors(attacker_groups),
		"defender_survivors": _calculate_survivors(defender_groups),
		"attacker_groups_remaining": _count_alive_groups(attacker_groups),
		"defender_groups_remaining": _count_alive_groups(defender_groups)
	}
	
	print("Battle ended by retreat!")
	battle_ended.emit(result)

func _spawn_groups():
	# Spawn 4 attacker groups
	for i in range(4):
		var group = _create_group(0, i, Vector2(
			attacker_spawn_x,
			spawn_y_start + i * spawn_y_spacing
		))
		attacker_groups.append(group)
		add_child(group)
		group.group_selected.connect(_on_group_selected)
		group.group_defeated.connect(_on_group_defeated)
	
	# Spawn 4 defender groups
	for i in range(4):
		var group = _create_group(1, i + 4, Vector2(
			defender_spawn_x,
			spawn_y_start + i * spawn_y_spacing
		))
		defender_groups.append(group)
		add_child(group)
		group.group_selected.connect(_on_group_selected)
		group.group_defeated.connect(_on_group_defeated)
	
	# Start combat
	current_phase = BattlePhase.COMBAT
	battle_started.emit()
	
	print("MassBattleController: Battle started with ", 
		attacker_groups.size(), " attacker groups and ",
		defender_groups.size(), " defender groups")

func _create_group(team: int, group_id: int, position: Vector2) -> CombatGroup:
	var group = preload("res://scenes/combat/combat_group.tscn").instantiate()
	group.team = team
	group.group_id = group_id
	group.position = position
	return group

func _process(delta):
	match current_phase:
		BattlePhase.COMBAT:
			_process_combat(delta)
		BattlePhase.ENDED:
			pass

func _process_combat(_delta):
	# Handle selection box dragging
	if is_dragging:
		_update_selection_box()
	
	# Check for battle end
	if _check_battle_end():
		_end_battle()

func _input(event):
	if current_phase != BattlePhase.COMBAT:
		return
	
	# Space to pause/unpause
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		toggle_pause()
		return
	
	# Escape to cancel orders
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_clear_selection()
		set_order_mode(OrderMode.SELECT)
		return
	
	# Mouse input for orders
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_mouse_down()
			else:
				_handle_mouse_up()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_handle_right_click()

func _handle_mouse_down():
	var mouse_pos = get_global_mouse_position()
	
	match current_order_mode:
		OrderMode.SELECT:
			# Start drag selection
			is_dragging = true
			drag_start = mouse_pos
			selection_box.visible = true
			selection_box.position = drag_start
			selection_box.size = Vector2.ZERO
			
		OrderMode.MOVE:
			# Issue move order to selected groups
			_issue_move_order(mouse_pos)
			set_order_mode(OrderMode.SELECT)
			
		OrderMode.ATTACK:
			# Try to attack group under cursor
			var target = _get_group_at_position(mouse_pos)
			if target and target.team != 0:
				_issue_attack_order(target)
			set_order_mode(OrderMode.SELECT)
			
		OrderMode.HOLD:
			_issue_hold_order()
			set_order_mode(OrderMode.SELECT)

func _handle_mouse_up():
	if is_dragging:
		is_dragging = false
		selection_box.visible = false
		_select_groups_in_box()

func _handle_right_click():
	# Right click always cancels current order mode
	set_order_mode(OrderMode.SELECT)

func _update_selection_box():
	var mouse_pos = get_global_mouse_position()
	var top_left = Vector2(min(drag_start.x, mouse_pos.x), min(drag_start.y, mouse_pos.y))
	var bottom_right = Vector2(max(drag_start.x, mouse_pos.x), max(drag_start.y, mouse_pos.y))
	
	selection_box.position = top_left
	selection_box.size = bottom_right - top_left

func _select_groups_in_box():
	var box_rect = Rect2(selection_box.position, selection_box.size)
	
	# Only select player groups (team 0)
	for group in attacker_groups:
		if group.is_alive() and box_rect.has_point(group.global_position):
			_add_to_selection(group)

func _get_group_at_position(pos: Vector2) -> CombatGroup:
	for group in get_tree().get_nodes_in_group("combat_groups"):
		if group.is_alive():
			var dist = group.global_position.distance_to(pos)
			if dist < 50:
				return group
	return null

# ============================================================================
# SELECTION MANAGEMENT
# ============================================================================

func _on_group_selected(group: CombatGroup):
	# Deselect enemy groups
	if group.team != 0:
		return
	
	if not Input.is_key_pressed(KEY_SHIFT):
		_clear_selection()
	
	_add_to_selection(group)

func _add_to_selection(group: CombatGroup):
	if not selected_groups.has(group):
		selected_groups.append(group)
		group.select()
		group_selection_changed.emit(selected_groups)

func _remove_from_selection(group: CombatGroup):
	if selected_groups.has(group):
		selected_groups.erase(group)
		group.deselect()
		group_selection_changed.emit(selected_groups)

func _clear_selection():
	for group in selected_groups:
		group.deselect()
	selected_groups.clear()
	group_selection_changed.emit(selected_groups)

# ============================================================================
# ORDER ISSUING
# ============================================================================

func _issue_move_order(target_pos: Vector2):
	for group in selected_groups:
		# Offset positions for formation
		var offset = _calculate_formation_offset(selected_groups.find(group))
		group.issue_move_order(target_pos + offset)
	
	print("Issued move order to ", selected_groups.size(), " groups")

func _issue_attack_order(target: CombatGroup):
	for group in selected_groups:
		group.issue_attack_order(target)
	
	print("Issued attack order on ", target.name)

func _issue_hold_order():
	for group in selected_groups:
		group.issue_hold_order()
	
	print("Issued hold order to ", selected_groups.size(), " groups")

func _calculate_formation_offset(index: int) -> Vector2:
	# Offset groups so they don't all pile on the same spot
	match index:
		0: return Vector2(0, 0)
		1: return Vector2(60, 0)
		2: return Vector2(-60, 0)
		3: return Vector2(30, 50)
		_: return Vector2(randi() % 60 - 30, randi() % 40 - 20)

# ============================================================================
# ORDER MODES
# ============================================================================

func set_order_mode(mode: OrderMode):
	current_order_mode = mode
	
	var mode_name = ""
	match mode:
		OrderMode.SELECT: mode_name = "select"
		OrderMode.MOVE: mode_name = "move"
		OrderMode.ATTACK: mode_name = "attack"
		OrderMode.HOLD: mode_name = "hold"
	
	order_mode_changed.emit(mode_name)
	print("Order mode: ", mode_name)

func set_order_mode_by_string(mode_name: String):
	match mode_name.to_lower():
		"select": set_order_mode(OrderMode.SELECT)
		"move": set_order_mode(OrderMode.MOVE)
		"attack": set_order_mode(OrderMode.ATTACK)
		"hold": set_order_mode(OrderMode.HOLD)

# ============================================================================
# PAUSE CONTROL
# ============================================================================

func toggle_pause():
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_changed.emit(is_paused)
	print("Battle ", "paused" if is_paused else "resumed")

func set_pause(paused: bool):
	is_paused = paused
	get_tree().paused = is_paused
	pause_changed.emit(is_paused)

# ============================================================================
# BATTLE END
# ============================================================================

func _check_battle_end() -> bool:
	var attackers_alive = _count_alive_groups(attacker_groups)
	var defenders_alive = _count_alive_groups(defender_groups)
	
	return attackers_alive == 0 or defenders_alive == 0

func _count_alive_groups(groups: Array[CombatGroup]) -> int:
	var count = 0
	for group in groups:
		if group.is_alive():
			count += 1
	return count

func _on_group_defeated(group: CombatGroup):
	print("Group ", group.group_id, " (team ", group.team, ") defeated")
	
	# Remove from selection if selected
	if selected_groups.has(group):
		_remove_from_selection(group)
	
	# Check for battle end (even when paused)
	print("Checking battle end... Attackers alive: ", _count_alive_groups(attacker_groups), 
		", Defenders alive: ", _count_alive_groups(defender_groups))
	if current_phase == BattlePhase.COMBAT and _check_battle_end():
		print("Battle end condition met!")
		_end_battle()

func _end_battle():
	current_phase = BattlePhase.ENDED
	set_pause(true)
	
	var attackers_alive = _count_alive_groups(attacker_groups)
	var defenders_alive = _count_alive_groups(defender_groups)
	var attacker_won = defenders_alive == 0
	
	# Calculate casualties
	var attacker_casualties = _calculate_casualties(attacker_groups)
	var defender_casualties = _calculate_casualties(defender_groups)
	
	var result = {
		"attacker_won": attacker_won,
		"defender_won": not attacker_won,
		"attacker_casualties": attacker_casualties,
		"defender_casualties": defender_casualties,
		"attacker_survivors": _calculate_survivors(attacker_groups),
		"defender_survivors": _calculate_survivors(defender_groups),
		"attacker_groups_remaining": attackers_alive,
		"defender_groups_remaining": defenders_alive
	}
	
	print("Battle ended! Winner: ", "Attacker" if attacker_won else "Defender")
	battle_ended.emit(result)

func _calculate_casualties(groups: Array[CombatGroup]) -> int:
	var total = 0
	var dead = 0
	for group in groups:
		total += 5
		dead += 5 - group.get_alive_count()
	return dead

func _calculate_survivors(groups: Array[CombatGroup]) -> int:
	var survivors = 0
	for group in groups:
		survivors += group.get_alive_count()
	return survivors

# ============================================================================
# PUBLIC API
# ============================================================================

func get_attacker_groups() -> Array[CombatGroup]:
	return attacker_groups

func get_defender_groups() -> Array[CombatGroup]:
	return defender_groups

func get_selected_groups() -> Array[CombatGroup]:
	return selected_groups

func is_battle_active() -> bool:
	return current_phase == BattlePhase.COMBAT

func get_battle_summary() -> Dictionary:
	return {
		"attackers_alive": _count_alive_groups(attacker_groups),
		"defenders_alive": _count_alive_groups(defender_groups),
		"attacker_casualties": _calculate_casualties(attacker_groups),
		"defender_casualties": _calculate_casualties(defender_groups),
		"is_paused": is_paused,
		"selected_count": selected_groups.size()
	}
