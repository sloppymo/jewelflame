class_name BattleScene
extends Node2D

## Dragon Force Battle Scene - Phase 1 MVP
## 2v2 General battle with standard RTS controls

signal battle_ended(result: Dictionary)

enum BattlePhase { SETUP, COMBAT, ENDED }

var phase: BattlePhase = BattlePhase.SETUP
var player_units: Array[Node2D] = []
var enemy_units: Array[Node2D] = []
var selected_units: Array[Node2D] = []

# Input
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var selection_box: ColorRect = null

# UI
@onready var ui_layer: CanvasLayer = $CanvasLayer
@onready var result_panel: Panel = $CanvasLayer/ResultPanel

func _ready():
	print("BattleScene: Initializing Phase 1...")
	
	# Create selection box
	selection_box = ColorRect.new()
	selection_box.color = Color(0, 1, 0, 0.2)
	selection_box.visible = false
	add_child(selection_box)
	
	# Hide result panel
	if result_panel:
		result_panel.visible = false
		var return_btn = result_panel.get_node_or_null("VBoxContainer/ReturnButton")
		if return_btn:
			return_btn.pressed.connect(return_to_strategic_map)
	
	# Spawn units
	_spawn_units()
	
	# Start combat
	phase = BattlePhase.COMBAT
	print("BattleScene: Battle started! 2v2 Combat")
	print("BattleScene: LEFT CLICK = Select | DRAG = Box Select | RIGHT CLICK = Move")

func _spawn_units():
	"""Spawn 3v3 mixed unit types for variety testing."""
	
	# Helper function to spawn a unit with script
	var _spawn_unit = func(scene_path: String, script_path: String, name: String, 
						  team_id: int, pos: Vector2, is_player: bool) -> Node2D:
		var unit = load(scene_path).instantiate()
		if script_path != "":
			unit.set_script(load(script_path))
		unit.unit_name = name
		unit.team = team_id
		unit.global_position = pos
		add_child(unit)
		
		if is_player:
			player_units.append(unit)
			unit.unit_selected.connect(_on_unit_selected)
		else:
			enemy_units.append(unit)
		unit.unit_died.connect(_on_unit_died)
		return unit
	
	# PLAYER TEAM (3 units)
	# 1. Special Unit - Erin (cleave attacks)
	_spawn_unit.call("res://dragon_force/general_unit.tscn", 
					"res://dragon_force/special_unit.gd",
					"Erin Blanche", 0, Vector2(150, 200), true)
	
	# 2. Cavalry - Sarah (fast, charge attacks)
	_spawn_unit.call("res://dragon_force/general_unit.tscn",
					"res://dragon_force/cavalry_unit.gd",
					"Sarah Blanche", 0, Vector2(150, 300), true)
	
	# 3. Archer - Generic Archer (ranged)
	_spawn_unit.call("res://dragon_force/general_unit.tscn",
					"res://dragon_force/archer_unit.gd",
					"Blanche Archer", 0, Vector2(100, 400), true)
	
	# ENEMY TEAM (3 units)
	# 1. Monster - Marcus (tank, fear, splash)
	_spawn_unit.call("res://dragon_force/general_unit.tscn",
					"res://dragon_force/monster_unit.gd",
					"Marcus Coryll", 1, Vector2(650, 200), false)
	
	# 2. Regular - Elena
	_spawn_unit.call("res://dragon_force/general_unit.tscn", "",
					"Elena Coryll", 1, Vector2(650, 300), false)
	
	# 3. Cavalry - Enemy Rider
	_spawn_unit.call("res://dragon_force/general_unit.tscn",
					"res://dragon_force/cavalry_unit.gd",
					"Coryll Rider", 1, Vector2(700, 400), false)
	
	# Start enemy AI
	_start_enemy_ai()

func _input(event):
	if phase != BattlePhase.COMBAT:
		return
	
	# Left mouse button - selection
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start selection drag
				is_dragging = true
				drag_start = get_global_mouse_position()
				selection_box.position = drag_start
				selection_box.size = Vector2.ZERO
				selection_box.visible = true
				
				# If not holding shift, clear selection
				if not Input.is_key_pressed(KEY_SHIFT):
					_deselect_all()
			else:
				# End selection drag
				is_dragging = false
				selection_box.visible = false
				
				var drag_end = get_global_mouse_position()
				var drag_distance = drag_start.distance_to(drag_end)
				
				if drag_distance < 5:  # Reduced threshold for better click detection
					# Click - select single unit
					_select_at_position(drag_end)
				else:
					# Box select
					_box_select(drag_start, drag_end)
		
		# Right mouse button - move order
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if selected_units.size() > 0:
				var target_pos = get_global_mouse_position()
				var shift_held = Input.is_key_pressed(KEY_SHIFT)
				_issue_move_order(target_pos, shift_held)
	
	# Update selection box while dragging
	if is_dragging and event is InputEventMouseMotion:
		_update_selection_box(get_global_mouse_position())

func _update_selection_box(mouse_pos: Vector2):
	var top_left = Vector2(min(drag_start.x, mouse_pos.x), min(drag_start.y, mouse_pos.y))
	var bottom_right = Vector2(max(drag_start.x, mouse_pos.x), max(drag_start.y, mouse_pos.y))
	selection_box.position = top_left
	selection_box.size = bottom_right - top_left

func _select_at_position(pos: Vector2):
	"""Select unit at position."""
	# Click-through in reverse order to select top-most unit first
	for i in range(player_units.size() - 1, -1, -1):
		var unit = player_units[i]
		if unit.is_alive() and unit.global_position.distance_to(pos) < 35:
			_select_unit(unit)
			return

func _box_select(start: Vector2, end: Vector2):
	"""Select units in box."""
	var box = Rect2(
		Vector2(min(start.x, end.x), min(start.y, end.y)),
		Vector2(abs(end.x - start.x), abs(end.y - start.y))
	)
	
	for unit in player_units:
		if unit.is_alive() and box.has_point(unit.global_position):
			_select_unit(unit, false)

func _select_unit(unit: Node2D, clear_others: bool = true):
	"""Select a unit."""
	if clear_others:
		_deselect_all()
	
	if not selected_units.has(unit):
		selected_units.append(unit)
		unit.select()
		print("BattleScene: Selected %s (%d units total)" % [unit.unit_name, selected_units.size()])

func _deselect_all():
	"""Deselect all units."""
	for unit in selected_units:
		unit.deselect()
	selected_units.clear()

func _issue_move_order(target_pos: Vector2, shift_held: bool = false):
	"""Issue move order to all selected units."""
	print("BattleScene: Move order to %s for %d units (shift: %s)" % [target_pos, selected_units.size(), shift_held])
	
	# Calculate formation offset
	var offset_spacing = 40
	var count = selected_units.size()
	var start_offset = -(count - 1) * offset_spacing / 2
	
	for i in range(count):
		var unit = selected_units[i]
		var offset = Vector2(0, start_offset + i * offset_spacing)
		unit.move_to(target_pos + offset, shift_held)  # Pass shift_held for waypoint queueing

func _on_unit_selected(unit: Node2D):
	"""Handle unit selection from unit itself."""
	# Don't re-select if already selected (prevents infinite recursion)
	if unit in selected_units:
		return
	if not Input.is_key_pressed(KEY_SHIFT):
		_deselect_all()
	_select_unit(unit, false)

func _process(_delta):
	if phase == BattlePhase.COMBAT:
		_check_battle_end()

func _check_battle_end():
	var player_alive_count = 0
	for unit in player_units:
		if unit.is_alive():
			player_alive_count += 1
	
	var enemy_alive_count = 0
	for unit in enemy_units:
		if unit.is_alive():
			enemy_alive_count += 1
	
	if player_alive_count == 0 or enemy_alive_count == 0:
		_end_battle(player_alive_count > 0)

func _on_unit_died(unit: Node2D):
	print("BattleScene: %s died" % unit.unit_name)
	if selected_units.has(unit):
		selected_units.erase(unit)
	
	# "Weight of Battle" - nearby units lose 1 troop from the horror of death
	_apply_death_weight(unit)
	
	_check_battle_end()

func _apply_death_weight(died_unit: Node2D):
	"""When a unit dies, nearby units lose 1 troop from the trauma."""
	var weight_range = 300.0  # Units within this range feel the death
	
	# Affects both teams - war is traumatic for everyone
	var all_units = player_units + enemy_units
	
	for unit in all_units:
		if unit == died_unit:
			continue
		if not unit.is_alive():
			continue
		
		var dist = unit.global_position.distance_to(died_unit.global_position)
		
		if dist <= weight_range and unit.current_troops > 1:
			# Lose 1 troop from witnessing death
			unit.current_troops -= 1
			print("BattleScene: %s lost a troop from witnessing %s's death" % [unit.unit_name, died_unit.unit_name])
			
			# Update visuals
			if unit.has_method("_update_troop_label"):
				unit._update_troop_label()
			if unit.has_method("_setup_troops"):
				unit._setup_troops()
			unit.troops_changed.emit(unit.current_troops)

func _end_battle(player_won: bool):
	if phase == BattlePhase.ENDED:
		return
	phase = BattlePhase.ENDED
	
	var result = {
		"player_won": player_won,
		"player_units_alive": 0,
		"enemy_units_alive": 0
	}
	
	for unit in player_units:
		if unit.is_alive():
			result["player_units_alive"] += 1
	
	for unit in enemy_units:
		if unit.is_alive():
			result["enemy_units_alive"] += 1
	
	print("BattleScene: Battle ended! Player won: %s" % player_won)
	_show_result_ui(player_won, result)
	battle_ended.emit(result)

func _show_result_ui(player_won: bool, result: Dictionary):
	if not result_panel:
		return
	
	result_panel.visible = true
	
	var title = result_panel.get_node_or_null("VBoxContainer/TitleLabel")
	var stats = result_panel.get_node_or_null("VBoxContainer/StatsLabel")
	
	if title:
		title.text = "VICTORY!" if player_won else "DEFEAT!"
		title.modulate = Color(0, 1, 0) if player_won else Color(1, 0, 0)
	
	if stats:
		stats.text = "Your units: %d/%d\nEnemy units: %d/%d" % [
			result.player_units_alive, player_units.size(),
			result.enemy_units_alive, enemy_units.size()
		]

func _start_enemy_ai():
	"""Simple enemy AI - continuously chase nearest player."""
	# Repeating timer to update enemy targets
	var ai_timer = Timer.new()
	ai_timer.wait_time = 1.5  # Update every 1.5 seconds
	ai_timer.timeout.connect(_update_enemy_ai)
	add_child(ai_timer)
	ai_timer.start()
	# Initial call
	_update_enemy_ai()

func _update_enemy_ai():
	if phase != BattlePhase.COMBAT:
		return
	
	# Each enemy moves toward nearest player
	for enemy in enemy_units:
		if not enemy.is_alive():
			continue
		
		# Skip if enemy is already in combat (attacking)
		if enemy.current_state == enemy.State.ATTACKING:
			continue
		
		# Find nearest player
		var nearest = null
		var nearest_dist = 10000.0
		
		for player in player_units:
			if player.is_alive():
				var dist = enemy.global_position.distance_to(player.global_position)
				if dist < nearest_dist:
					nearest_dist = dist
					nearest = player
		
		if nearest:
			enemy.move_to(nearest.global_position)

func return_to_strategic_map():
	print("BattleScene: Returning to strategic map...")
	var strategic_map = load("res://strategic/strategic_map.tscn").instantiate()
	var current = get_tree().current_scene
	get_tree().root.add_child(strategic_map)
	get_tree().current_scene = strategic_map
	if current:
		current.queue_free()
