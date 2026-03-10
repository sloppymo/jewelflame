## Tactical Battle Main Controller
## Integrates HexForge battle systems with Jewelflame GameState
## Connection ID: ec74b0f4-ca88-40ad-9532-084ce680ef07

extends Node2D

# ============================================================================
# SIGNALS
# ============================================================================

signal battle_ended(result: Dictionary)
signal battle_aborted()

# ============================================================================
# CONSTANTS
# ============================================================================

const HEX_SIZE: float = 32.0

# ============================================================================
# HEXFORGE SUBSYSTEMS (Auto-initialized)
# ============================================================================

var battle_controller = null
var battle_grid = null
var unit_manager = null
var turn_manager = null
var combat_engine = null
var ai_manager = null
var hex_renderer = null
var cursor = null
var highlighter = null
var hexforge_loader = null

# ============================================================================
# STATE
# ============================================================================

var battle_data: Dictionary = {}
var selected_unit_id: String = ""
var is_battle_active: bool = false

# ============================================================================
# UI REFERENCES
# ============================================================================

@onready var turn_label: Label = $CanvasLayer/BattleUI/TopBar/TurnLabel
@onready var end_turn_button: Button = $CanvasLayer/BattleUI/TopBar/EndTurnButton
@onready var retreat_button: Button = $CanvasLayer/BattleUI/TopBar/RetreatButton
@onready var unit_info_panel: Control = $CanvasLayer/BattleUI/UnitInfoPanel
@onready var battle_log: RichTextLabel = $CanvasLayer/BattleUI/BattleLog
@onready var victory_panel: Panel = $CanvasLayer/BattleUI/VictoryPanel
@onready var victory_label: Label = $CanvasLayer/BattleUI/VictoryPanel/VictoryLabel

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	print("TacticalBattle: Initializing...")
	
	# Load HexForge classes
	_load_hexforge()
	
	# Get battle data from GameState
	battle_data = GameState.current_battle
	if battle_data.is_empty():
		push_error("TacticalBattle: No battle data found in GameState!")
		_log_message("ERROR: No battle data found!")
		await get_tree().create_timer(2.0).timeout
		_return_to_strategic()
		return
	
	# Initialize HexForge subsystems
	_initialize_hexforge()
	
	# Setup UI
	_setup_ui()
	
	# Spawn units and start battle
	_setup_battlefield()
	
	print("TacticalBattle: Initialization complete")

func _load_hexforge() -> void:
	"""Load HexForge classes using the loader."""
	var loader_script = load("res://tactical/hexforge_loader.gd")
	if loader_script:
		hexforge_loader = loader_script.get_instance()
	else:
		push_error("TacticalBattle: Failed to load HexForge loader!")

func _initialize_hexforge() -> void:
	"""Initialize all HexForge battle subsystems."""
	
	if hexforge_loader == null or not hexforge_loader.is_available():
		push_error("TacticalBattle: HexForge not available!")
		_log_message("ERROR: HexForge battle system not available")
		return
	
	# Create battle controller (main orchestrator)
	battle_controller = hexforge_loader.create_battle_controller()
	if battle_controller == null:
		push_error("TacticalBattle: Failed to create BattleController!")
		return
		
	battle_controller.hex_size = HEX_SIZE
	add_child(battle_controller)
	
	# Get references to subsystems from battle_controller
	battle_grid = battle_controller.battle_grid
	unit_manager = battle_controller.unit_manager
	turn_manager = battle_controller.turn_manager
	combat_engine = battle_controller.combat_engine
	hex_renderer = battle_controller.renderer
	cursor = battle_controller.cursor
	highlighter = battle_controller.highlighter
	
	# Create AI manager
	ai_manager = hexforge_loader.create_ai_manager()
	if ai_manager:
		ai_manager.battle_controller = battle_controller
		add_child(ai_manager)
	
	# Connect to battle controller signals
	battle_controller.battle_started.connect(_on_battle_started)
	battle_controller.battle_ended.connect(_on_battle_ended)
	battle_controller.unit_selected.connect(_on_unit_selected)
	battle_controller.action_completed.connect(_on_action_completed)
	
	# Connect turn manager signals
	if turn_manager:
		turn_manager.turn_started.connect(_on_turn_started)
		turn_manager.turn_ended.connect(_on_turn_ended)

func _setup_ui() -> void:
	"""Setup UI connections."""
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)
	if retreat_button:
		retreat_button.pressed.connect(_on_retreat_pressed)

func _setup_battlefield() -> void:
	"""Setup the battlefield with terrain and units."""
	
	if battle_controller == null:
		_log_message("ERROR: Battle controller not initialized!")
		return
	
	var terrain = battle_data.defender.get("terrain", "plains")
	var province_name = battle_data.get("province_name", "Unknown Province")
	
	_log_message("Battle starting in %s" % province_name)
	_log_message("Terrain: %s" % terrain.capitalize())
	
	# Update province name label
	var province_label = $CanvasLayer/BattleUI/TopBar/ProvinceName
	if province_label:
		province_label.text = "Battle of %s" % province_name
	
	# Convert battle data to HexForge format
	var attacker_units = _convert_units(battle_data.attacker.get("units", []))
	var defender_units = _convert_units(battle_data.defender.get("units", []))
	
	# Start the battle
	battle_controller.start_battle(null, attacker_units, defender_units)
	is_battle_active = true

func _convert_units(unit_array: Array) -> Array:
	"""Convert Jewelflame unit data to HexForge format."""
	var result = []
	for unit_data in unit_array:
		if unit_data is Dictionary:
			result.append({
				"type": unit_data.get("type", "infantry"),
				"hp": unit_data.get("hp", 10),
				"max_hp": unit_data.get("hp", 10),
				"attack": unit_data.get("attack", 3),
				"defense": unit_data.get("defense", 2),
				"movement": unit_data.get("movement", 5.0),
				"range": unit_data.get("attack_range", 1)
			})
	return result

# ============================================================================
# INPUT HANDLING
# ============================================================================

func _input(event: InputEvent) -> void:
	if not is_battle_active:
		return
	
	# Handle Escape key for deselect
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if battle_controller:
			battle_controller._deselect_unit()
		selected_unit_id = ""
		_clear_unit_info()

# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_battle_started(attacker_count: int, defender_count: int) -> void:
	_log_message("Battle started! Attackers: %d, Defenders: %d" % [attacker_count, defender_count])

func _on_battle_ended(victor: String, result: Dictionary) -> void:
	is_battle_active = false
	_log_message("Battle ended! Victor: %s" % victor)
	
	# Show victory panel
	if victory_panel and victory_label:
		victory_label.text = "%s Victory!" % victor.capitalize()
		victory_panel.visible = true
	
	# Build result for GameState
	var battle_result = {
		"victor": victor,
		"attacker_province_id": battle_data.attacker.get("province_id", -1),
		"defender_province_id": battle_data.defender.get("province_id", -1),
		"attacker_survivors": _get_survivors("attacker"),
		"defender_survivors": _get_survivors("defender"),
		"attacker_casualties": result.get("attacker_casualties", 0),
		"defender_casualties": result.get("defender_casualties", 0)
	}
	
	# Notify GameState
	GameState.end_battle(battle_result)
	
	# Emit signal for scene transition
	battle_ended.emit(battle_result)
	
	# Return to strategic map after delay
	await get_tree().create_timer(3.0).timeout
	_return_to_strategic()

func _on_unit_selected(unit_id: String) -> void:
	selected_unit_id = unit_id
	if unit_manager:
		var unit = unit_manager.get_unit(unit_id)
		if unit:
			_show_unit_info(unit)

func _on_action_completed() -> void:
	# Action completed (move or attack)
	pass

func _on_turn_started(turn_number: int, active_side: String) -> void:
	_update_turn_label(turn_number, active_side)
	_log_message("Turn %d - %s's phase" % [turn_number, active_side.capitalize()])
	
	# Enable/disable end turn button based on whose turn it is
	if end_turn_button:
		end_turn_button.disabled = (active_side != "attacker")
	
	# Trigger AI if it's defender's turn
	if active_side == "defender" and ai_manager:
		ai_manager.process_ai_turn("defender")

func _on_turn_ended(turn_number: int, active_side: String) -> void:
	pass

# ============================================================================
# UI CALLBACKS
# ============================================================================

func _on_end_turn_pressed() -> void:
	if is_battle_active and battle_controller:
		battle_controller.end_turn()

func _on_retreat_pressed() -> void:
	_log_message("Attacker retreats!")
	if battle_controller:
		battle_controller.end_battle("defender")

# ============================================================================
# UI UPDATES
# ============================================================================

func _update_turn_label(turn: int, side: String) -> void:
	if turn_label:
		var side_text = "Player" if side == "attacker" else "Enemy"
		turn_label.text = "Turn %d - %s Phase" % [turn, side_text]

func _show_unit_info(unit) -> void:
	if not unit_info_panel:
		return
	
	# Find or create labels
	var name_label = unit_info_panel.get_node_or_null("NameLabel")
	var stats_label = unit_info_panel.get_node_or_null("StatsLabel")
	
	if not name_label:
		name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.position = Vector2(10, 10)
		name_label.size = Vector2(180, 30)
		unit_info_panel.add_child(name_label)
	
	if not stats_label:
		stats_label = Label.new()
		stats_label.name = "StatsLabel"
		stats_label.position = Vector2(10, 50)
		stats_label.size = Vector2(180, 100)
		unit_info_panel.add_child(stats_label)
	
	name_label.text = unit.unit_type.capitalize()
	stats_label.text = "HP: %d/%d\nATK: %d | DEF: %d\nMOV: %d | RNG: %d" % [
		unit.current_hp, unit.max_hp,
		unit.attack, unit.defense,
		int(unit.movement), unit.attack_range
	]

func _clear_unit_info() -> void:
	if unit_info_panel:
		var name_label = unit_info_panel.get_node_or_null("NameLabel")
		var stats_label = unit_info_panel.get_node_or_null("StatsLabel")
		if name_label:
			name_label.text = ""
		if stats_label:
			stats_label.text = ""

func _log_message(message: String) -> void:
	if battle_log:
		battle_log.append_text("[color=yellow]%s[/color]\n" % message)
		battle_log.scroll_to_line(battle_log.get_line_count())
	print("TacticalBattle: %s" % message)

# ============================================================================
# UTILITY
# ============================================================================

func _get_survivors(side: String) -> Array:
	"""Get surviving units for a side."""
	var survivors = []
	if unit_manager == null:
		return survivors
		
	var units = unit_manager.get_units_by_side(side, true)
	for unit in units:
		survivors.append({
			"type": unit.unit_type,
			"count": unit.current_hp,
			"hp": unit.current_hp
		})
	return survivors

func _return_to_strategic() -> void:
	"""Return to the strategic map scene."""
	print("TacticalBattle: Returning to strategic map...")
	get_tree().change_scene_to_file("res://main_strategic.tscn")

# ============================================================================
# PUBLIC API
# ============================================================================

func get_battle_result() -> Dictionary:
	"""Get the current battle result (for external systems)."""
	if not is_battle_active or unit_manager == null:
		return {}
	
	return {
		"attacker_remaining": unit_manager.get_unit_count_by_side("attacker", true),
		"defender_remaining": unit_manager.get_unit_count_by_side("defender", true),
		"current_turn": turn_manager.get_turn_number() if turn_manager else 0
	}
