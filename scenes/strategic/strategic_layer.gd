extends Node2D

# Main Strategic Layer - combines HexForge grid with Strategic HUD

const COLOR_ROYAL_BLUE = Color("#4a4a9e")
const COLOR_GOLD = Color("#c4a000")

const LordData = preload("res://resources/data_classes/lord_data.gd")

# Note: GameState and RandomEvents are autoloads - access directly or via get_tree().root
# Do NOT use @onready with get_node("/root/...") - causes tree access errors

var current_command: String = ""
var selected_province_id: int = -1

# View sub-windows
var view_many_window = null
var view_land_window = null
var view_fifth_window = null
var view_one_window = null

# Tactical battle
var tactical_battle_scene = null
var current_battle_result = null
var pending_battle_data: Dictionary = {}

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var view_menu: Window = $CanvasLayer/ViewMenu
@onready var hex_grid_container: Node2D = $CanvasLayer/MapContainer/StrategicMap
@onready var strategic_panel = $CanvasLayer/GameSidebar

func _ready():
	
	_connect_signals()
	_render_province_map()
	
	# Connect to battle request signal from GameState
	EventBus.RequestTacticalBattle.connect(_on_request_tactical_battle)
	
	# Connect to province selection
	EventBus.ProvinceSelected.connect(_on_province_selected)
	
	# Connect to command selection from menu panel
	EventBus.CommandSelected.connect(_on_command_selected)
	
	print("Strategic Layer initialized")

func _input(event):
	# Fallback province click detection
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		if hex_grid_container:
			for child in hex_grid_container.get_children():
				if child is Area2D:
					# Check if mouse is within hex bounds (simple distance check)
					var distance = mouse_pos.distance_to(child.position)
					if distance < 50:  # Hex radius
						var province_id = int(child.name.split("_")[1])
						print("Province clicked (fallback): ", province_id)
						EventBus.ProvinceSelected.emit(province_id)
						break

func _render_province_map():
	"""Render the hex-based province map"""
	if not hex_grid_container:
		push_error("HexGridContainer not found!")
		return
	var hex_container = hex_grid_container
	
	# Clear existing
	for child in hex_container.get_children():
		child.queue_free()
	
	# Render each province as a hex
	for province_id in GameState.provinces.keys():
		_create_province_hex(province_id, hex_container)

func _create_province_hex(province_id: int, container: Node2D):
	var province = GameState.provinces[province_id]
	var family = GameState.families.get(province.owner_id)
	
	var area = Area2D.new()
	area.name = "Province_%d" % province_id
	area.position = _get_province_position(province_id)
	area.input_pickable = true
	area.monitoring = true
	area.monitorable = true
	
	# Collision for clicking
	var collision = CollisionPolygon2D.new()
	collision.polygon = _get_hex_shape()
	collision.build_mode = CollisionPolygon2D.BUILD_SOLIDS
	area.add_child(collision)
	
	# Visual hex
	var polygon = Polygon2D.new()
	polygon.name = "Visual"
	polygon.polygon = _get_hex_shape()
	polygon.color = family.color if family else Color.GRAY
	polygon.color.a = 0.6
	area.add_child(polygon)
	
	# Border
	var border = Line2D.new()
	border.points = _get_hex_shape()
	border.closed = true
	border.width = 2
	border.default_color = Color.WHITE
	area.add_child(border)
	
	# Province name label
	var label = Label.new()
	label.text = province.name
	label.position = Vector2(-40, -10)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 14)
	area.add_child(label)
	
	# Click handler
	area.input_event.connect(_on_province_clicked.bind(province_id))
	
	container.add_child(area)
	
func _get_hex_shape() -> PackedVector2Array:
	var size = 60.0
	var points = PackedVector2Array()
	for i in range(6):
		var angle = deg_to_rad(60 * i - 30)
		points.append(Vector2(cos(angle), sin(angle)) * size)
	return points

func _get_province_position(id: int) -> Vector2:
	# Grid layout for 5 provinces
	var positions = {
		1: Vector2(400, 300),   # Dunmoor - left
		2: Vector2(550, 200),   # Carveti - top
		3: Vector2(550, 400),   # Cobrige - bottom
		4: Vector2(700, 250),   # Banshea - right-top
		5: Vector2(700, 450)    # Petaria - right-bottom
	}
	return positions.get(id, Vector2(500, 350))

func _on_province_clicked(viewport, event, shape_idx, province_id: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Province clicked: ", province_id)
		EventBus.ProvinceSelected.emit(province_id)

func _on_province_selected(province_id: int):
	selected_province_id = province_id
	var province = GameState.provinces.get(province_id)
	if not province:
		return
	
	print("Selected province: ", province.name)
	
	# Update StrategicPanel with province info
	_update_strategic_panel(province)
	
	# Visual feedback - highlight selected province
	_highlight_province(province_id)
	
	# Handle command if one is active
	if current_command == "develop":
		_execute_develop_command(province)
	elif current_command == "search":
		_execute_search_command(province)
	elif current_command == "battle":
		_execute_battle_command(province)

func _update_strategic_panel(province):
	"""Update the GameSidebar with province and lord information."""
	if not strategic_panel:
		push_warning("GameSidebar not found!")
		return
	
	# The GameSidebar automatically updates via EventBus.ProvinceSelected signal
	# But we can also call the update method directly if needed
	if strategic_panel.has_method("_update_for_province"):
		strategic_panel._update_for_province(province.id)
	
	print("Updated GameSidebar for province: ", province.name)

func _highlight_province(province_id: int):
	"""Highlight the selected province hex"""
	if not hex_grid_container:
		return
	
	for child in hex_grid_container.get_children():
		var visual = child.get_node_or_null("Visual")
		if visual:
			if child.name == "Province_%d" % province_id:
				visual.modulate = Color(1.5, 1.5, 1.5)  # Brighten
			else:
				visual.modulate = Color.WHITE  # Reset

func _execute_develop_command(province):
	"""Execute develop command on selected province"""
	if province.owner_id != GameState.get_current_family():
		print("Cannot develop enemy province!")
		return
	
	province.cultivation += 10
	print("Developed province: ", province.name)

func _execute_search_command(province):
	"""Execute search command on selected province"""
	print("Searched province: ", province.name)

func _execute_battle_command(province):
	"""Execute battle command - attack selected province"""
	var current_family = GameState.get_current_family()
	
	# If enemy province, launch battle
	print("Attacking enemy province: ", province.name)
	_start_test_battle()

func _connect_signals():
	# Connect view menu buttons (if view_menu exists)
	if not view_menu:
		return
	
	var one_btn = view_menu.get_node_or_null("MarginContainer/VBoxContainer/OneBtn")
	var many_btn = view_menu.get_node_or_null("MarginContainer/VBoxContainer/ManyBtn")
	var land_btn = view_menu.get_node_or_null("MarginContainer/VBoxContainer/LandBtn")
	var fifth_btn = view_menu.get_node_or_null("MarginContainer/VBoxContainer/FifthBtn")
	var close_btn = view_menu.get_node_or_null("MarginContainer/VBoxContainer/CloseBtn")
	
	if one_btn:
		one_btn.pressed.connect(_on_view_mode_selected.bind("one"))
	if many_btn:
		many_btn.pressed.connect(_on_view_mode_selected.bind("many"))
	if land_btn:
		land_btn.pressed.connect(_on_view_mode_selected.bind("land"))
	if fifth_btn:
		fifth_btn.pressed.connect(_on_view_mode_selected.bind("fifth"))
	if close_btn:
		close_btn.pressed.connect(_on_view_menu_closed)

func _on_command_selected(command: String):
	current_command = command
	print("DEBUG: Command selected: ", command)
	
	match command:
		"battle":
			print("DEBUG: Battle command selected")
		"develop":
			print("DEBUG: Develop command selected")
		"search":
			print("DEBUG: Search command selected")
		"military":
			print("DEBUG: Military command selected")
		"view":
			if view_menu:
				view_menu.popup_centered()

func _start_test_battle():
	# Start a test battle with real data from current lords
	print("DEBUG: _start_test_battle() called")
	
	# Get current lords
	var current_family = GameState.get_current_family()
	var attacker_lord = _get_first_lord(current_family)
	
	# Get enemy lord (first non-player family)
	var enemy_family = ""
	for family_id in GameState.families.keys():
		if family_id != current_family:
			enemy_family = family_id
			break
	var defender_lord = _get_first_lord(enemy_family)
	
	# Build battle data
	var attacker_units = _build_units_from_lord(attacker_lord)
	var defender_units = _build_units_from_lord(defender_lord)
	
	var battle_data = {
		"attacker": {
			"lord": attacker_lord,
			"units": attacker_units,
			"personality": _get_personality(attacker_lord),
			"time_of_day": "day"
		},
		"defender": {
			"lord": defender_lord,
			"units": defender_units,
			"terrain": "grass"
		}
	}
	
	# Load tactical battle scene
	var battle_scene = load("res://scenes/tactical/tactical_battle.tscn")
	if battle_scene:
		tactical_battle_scene = battle_scene.instantiate()
		tactical_battle_scene.attacker_data = battle_data.attacker
		tactical_battle_scene.defender_data = battle_data.defender
		add_child(tactical_battle_scene)
		
		# Connect to battle end signal
		tactical_battle_scene.battle_ended.connect(_on_tactical_battle_ended)
		tactical_battle_scene.lord_captured.connect(_on_lord_captured)

func _get_first_lord(family_id: String):
	for char_id in GameState.characters.keys():
		var character = GameState.characters[char_id]
		if character.family_id == family_id and character.is_lord:
			return character
	return null

func _build_units_from_lord(lord) -> Array:
	if not lord:
		return [{"type": "Knights", "count": 20}]
	
	# Build units based on lord's stats
	var units = []
	var base_troops = 20
	
	if lord.get("command_rating"):
		base_troops = lord.command_rating / 2
	
	units.append({"type": "Knights", "count": base_troops})
	
	# Add second unit type based on family
	if lord.family_id == "blanche":
		units.append({"type": "Mages", "count": base_troops / 2})
	elif lord.family_id == "lyle":
		units.append({"type": "Horsemen", "count": base_troops / 2})
	else:
		units.append({"type": "Archers", "count": base_troops / 2})
	
	return units

func _get_personality(lord) -> String:
	# Return personality based on lord's attack/defense stats
	if not lord:
		return "balanced"
	
	# Check if lord has attack/defense ratings
	if lord is LordData:
		var lord_data = lord as LordData
		if lord_data.attack_rating > lord_data.defense_rating + 10:
			return "aggressive"
		elif lord_data.defense_rating > lord_data.attack_rating + 10:
			return "defensive"
	
	return "balanced"

func _on_lord_captured(captured_lord, captor):
	print("Lord captured: ", captured_lord.name, " by ", captor.name if captor else "unknown")
	# Update game state to reflect capture
	captured_lord.is_captured = true

func _on_tactical_battle_ended(result: Dictionary):
	"""Handle tactical battle completion and notify GameState"""
	print("DEBUG: Tactical battle ended with result: ", result)
	current_battle_result = result
	
	# Remove battle scene
	if tactical_battle_scene:
		tactical_battle_scene.queue_free()
		tactical_battle_scene = null
	
	# Apply battle results to game state
	_apply_battle_results(result)
	
	# Signal completion back to GameState
	EventBus.TacticalBattleCompleted.emit(result)

func _apply_battle_results(result: Dictionary):
	"""Update game state based on battle outcome"""
	var winner = result.get("winner", "")
	var province_id = result.get("province_id", pending_battle_data.get("province_id", -1))
	var province_captured = result.get("province_captured", false)
	
	print("DEBUG: Applying battle results - winner: ", winner, ", province_id: ", province_id, ", captured: ", province_captured)
	
	# Handle province capture
	if province_id >= 0 and province_captured and winner == "attacker":
		var province = GameState.get_province(province_id)
		var winner_lord = pending_battle_data.get("attacker")
		
		if province and winner_lord:
			# Transfer ownership
			var old_owner = province.owner_id
			province.owner_id = winner_lord.family_id
			province.governor_id = winner_lord.id
			print("DEBUG: Province ", province_id, " captured by ", winner_lord.name, 
				" (family: ", winner_lord.family_id, ", was: ", old_owner, ")")
			
			# Emit province changed signal
			EventBus.ProvinceDataChanged.emit(province_id, "owner_id", province.owner_id)
	else:
		print("DEBUG: No province capture - province_id: ", province_id, ", captured: ", province_captured, ", winner: ", winner)
	
	# Handle lord capture
	if result.get("lord_captured", false):
		var captured_lord = result.get("captured_lord")
		if captured_lord:
			captured_lord.is_captured = true
			print("DEBUG: Lord captured: ", captured_lord.name)

func _on_view_mode_selected(mode: String):
	view_menu.hide()
	
	match mode:
		"one":
			_show_view_one()
		"many":
			_show_view_many(GameState.get_current_family())
		"land":
			_show_view_land(GameState.get_current_family())
		"fifth":
			_show_view_fifth(GameState.get_current_family())

func _show_view_many(family_id: String):
	var scene = load("res://scenes/ui/view_many.tscn")
	if scene:
		view_many_window = scene.instantiate()
		add_child(view_many_window)
		view_many_window.view_close_requested.connect(_on_view_closed)
		view_many_window.show_family_roster(family_id)

func _show_view_land(family_id: String):
	var scene = load("res://scenes/ui/view_land.tscn")
	if scene:
		view_land_window = scene.instantiate()
		add_child(view_land_window)
		view_land_window.view_close_requested.connect(_on_view_closed)
		view_land_window.show_province_data(family_id)

func _show_view_fifth(family_id: String):
	var scene = load("res://scenes/ui/view_fifth.tscn")
	if scene:
		view_fifth_window = scene.instantiate()
		add_child(view_fifth_window)
		view_fifth_window.view_close_requested.connect(_on_view_closed)
		view_fifth_window.show_monster_inventory(family_id)

func _show_view_one():
	var scene = load("res://scenes/ui/view_one.tscn")
	if scene:
		view_one_window = scene.instantiate()
		add_child(view_one_window)
		view_one_window.view_close_requested.connect(_on_view_closed)
		
		var current_lord = GameState.selected_lord_id
		if current_lord.is_empty():
			var family_lords = GameState.get_family_lords(GameState.get_current_family())
			if not family_lords.is_empty():
				current_lord = family_lords[0].id
			
		if not current_lord.is_empty():
			view_one_window.show_lord_info(current_lord)

func _on_view_closed():
	pass

func _on_view_menu_closed():
	if view_menu:
		view_menu.hide()

func _on_request_tactical_battle(battle_data: Dictionary):
	"""Handle battle launch request from GameState"""
	print("DEBUG: StrategicLayer received battle request")
	
	# Build the battle data structures
	var attacker_lord = battle_data.get("attacker")
	var defender_lord = battle_data.get("defender")
	
	if not attacker_lord or not defender_lord:
		push_error("Missing lord data in battle request")
		return
	
	# Store for result processing
	pending_battle_data = {
		"attacker": attacker_lord,
		"defender": defender_lord,
		"province_id": battle_data.get("province_id", 0)
	}
	
	# Launch tactical scene
	_launch_tactical_scene(attacker_lord, defender_lord)

func _launch_tactical_scene(attacker, defender):
	"""Instantiate and configure tactical battle"""
	print("DEBUG: Launching tactical scene for ", attacker.name, " vs ", defender.name)
	
	# Load tactical scene
	var tactical_scene = load("res://scenes/tactical/tactical_battle.tscn")
	if not tactical_scene:
		push_error("Failed to load tactical_battle.tscn")
		return
	
	var instance = tactical_scene.instantiate()
	tactical_battle_scene = instance
	
	# Configure data with province_id for result processing
	instance.attacker_data = _build_battle_data(attacker)
	instance.defender_data = _build_battle_data(defender)
	instance.set_meta("province_id", pending_battle_data.get("province_id", 0))
	
	# Connect completion signal before adding to tree
	if not instance.battle_ended.is_connected(_on_tactical_battle_ended):
		instance.battle_ended.connect(_on_tactical_battle_ended)
	
	add_child(instance)
	print("DEBUG: Tactical battle scene added to tree")

func _build_battle_data(lord) -> Dictionary:
	"""Convert lord to battle data format"""
	if not lord:
		return {}
	
	return {
		"lord": lord,
		"units": _build_units_from_lord(lord),
		"personality": _get_personality(lord),
		"time_of_day": "day"
	}
