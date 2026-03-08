## Jewelflame/Tactical/TacticalBattle
## Main tactical battle scene - uses HexForge for combat resolution
## Returns results to strategic layer via GameState

class_name TacticalBattle
extends Node2D

# ============================================================================
# CONFIGURATION
# ============================================================================

## Scene transition settings
const RETURN_SCENE: String = "res://scenes/strategic_map.tscn"

# ============================================================================
# HEXFORGE INTEGRATION
# ============================================================================

@onready var battle_controller: BattleController
@onready var hex_renderer: HexRenderer2D

# ============================================================================
# UI REFERENCES
# ============================================================================

@onready var battle_ui: Control
@onready var turn_label: Label
@onready var end_turn_button: Button
@onready var retreat_button: Button
@onready var battle_log: RichTextLabel

# ============================================================================
# STATE
# ============================================================================

var battle_data: Dictionary = {}
var attacker_faction: String = ""
var defender_faction: String = ""
var is_player_attacker: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	# Retrieve battle data from GameState
	battle_data = GameState.current_battle
	
	if battle_data.is_empty():
		push_error("TacticalBattle: No battle data in GameState!")
		_return_to_strategic()
		return
	
	_extract_battle_info()
	_setup_hexforge()
	_setup_ui()
	_setup_camera()
	
	# Connect to battle events
	_connect_battle_signals()
	
	# Start the battle
	_start_battle()

func _extract_battle_info() -> void:
	var attacker_data: Dictionary = battle_data.get("attacker", {})
	var defender_data: Dictionary = battle_data.get("defender", {})
	
	attacker_faction = attacker_data.get("faction", "")
	defender_faction = defender_data.get("faction", "")
	
	is_player_attacker = (attacker_faction == GameState.player_faction)

func _setup_hexforge() -> void:
	# Create HexForge battle controller
	battle_controller = BattleController.new()
	add_child(battle_controller)
	
	# Configure based on defender terrain
	var defender_data: Dictionary = battle_data.get("defender", {})
	var terrain: String = defender_data.get("terrain", "plains")
	var has_castle: bool = defender_data.get("has_castle", false)
	
	# Generate map based on terrain
	var map_data := _generate_map_data(terrain, has_castle)
	
	# Prepare unit data
	var attacker_units: Array = _convert_units_for_hexforge(
		battle_data.get("attacker", {}).get("units", [])
	)
	var defender_units: Array = _convert_units_for_hexforge(
		battle_data.get("defender", {}).get("units", [])
	)
	
	# Start HexForge battle
	battle_controller.start_battle(map_data, attacker_units, defender_units)

func _generate_map_data(terrain: String, has_castle: bool) -> Dictionary:
	# Generate a hex grid based on terrain type
	var width := 11
	var height := 11
	var cells: Array = []
	
	for q in range(-width/2, width/2 + 1):
		for r in range(-height/2, height/2 + 1):
			var cube := HexMath.axial_to_cube(Vector2i(q, r))
			var cell_data := {
				"axial": [q, r],
				"terrain": _get_terrain_for_position(q, r, terrain, has_castle),
				"elevation": _get_elevation_for_position(q, r, has_castle),
				"blocking": false
			}
			cells.append(cell_data)
	
	return {
		"version": "1.0.0",
		"bounds": {
			"min_q": -width/2,
			"min_r": -height/2,
			"max_q": width/2,
			"max_r": height/2
		},
		"cells": cells
	}

func _get_terrain_for_position(q: int, r: int, province_terrain: String, has_castle: bool) -> String:
	# Generate terrain variety based on province type
	var center_dist := abs(q) + abs(r) + abs(-q-r)
	
	match province_terrain:
		"forest":
			if randf() > 0.4:
				return "forest"
			return "plains"
		"mountain":
			if center_dist > 3:
				return "mountain"
			return "plains"
		"coastal":
			if center_dist > 4:
				return "water"
			return "plains"
		_:
			# Plains with occasional forests
			if randf() > 0.8:
				return "forest"
			return "plains"

func _get_elevation_for_position(q: int, r: int, has_castle: bool) -> int:
	# Castle provides elevated positions for defender
	if has_castle and q > 2:  # Defender side (east)
		return 1
	return 0

func _convert_units_for_hexforge(units_data: Array) -> Array:
	# Convert Jewelflame unit format to HexForge format
	var hexforge_units: Array = []
	
	for unit_data in units_data:
		var unit_type: String = unit_data.get("type", "infantry")
		
		# Map unit types
		var hexforge_type := "infantry"
		match unit_type:
			"cavalry", "horsemen":
				hexforge_type = "cavalry"
			"archer":
				hexforge_type = "archer"
			"mage", "wizard":
				hexforge_type = "mage"
			_:
				hexforge_type = "infantry"
		
		hexforge_units.append({
			"type": hexforge_type,
			"hp": unit_data.get("hp", 10),
			"max_hp": unit_data.get("hp", 10),
			"attack": unit_data.get("attack", 3),
			"defense": unit_data.get("defense", 2),
			"movement": 5.0 if unit_type == "cavalry" else 3.0,
			"range": 1
		})
	
	return hexforge_units

func _setup_ui() -> void:
	# Create battle UI (simplified - full UI would be in .tscn file)
	battle_ui = Control.new()
	battle_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(battle_ui)
	
	# Turn label
	turn_label = Label.new()
	turn_label.position = Vector2(20, 20)
	turn_label.add_theme_font_size_override("font_size", 24)
	battle_ui.add_child(turn_label)
	
	# End turn button
	end_turn_button = Button.new()
	end_turn_button.text = "End Turn"
	end_turn_button.position = Vector2(20, 60)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	battle_ui.add_child(end_turn_button)
	
	# Retreat button
	retreat_button = Button.new()
	retreat_button.text = "Retreat"
	retreat_button.position = Vector2(20, 100)
	retreat_button.pressed.connect(_on_retreat_pressed)
	battle_ui.add_child(retreat_button)
	
	# Battle log
	battle_log = RichTextLabel.new()
	battle_log.position = Vector2(20, 500)
	battle_log.size = Vector2(400, 200)
	battle_log.bbcode_enabled = true
	battle_ui.add_child(battle_log)

func _setup_camera() -> void:
	var camera := Camera2D.new()
	camera.name = "BattleCamera"
	camera.zoom = Vector2(1.2, 1.2)
	add_child(camera)

func _connect_battle_signals() -> void:
	if not battle_controller:
		return
	
	battle_controller.battle_started.connect(_on_battle_started)
	battle_controller.battle_ended.connect(_on_battle_ended)
	battle_controller.turn_manager.turn_started.connect(_on_turn_started)
	battle_controller.combat_engine.attack_resolved.connect(_on_attack_resolved)
	battle_controller.unit_manager.unit_defeated.connect(_on_unit_defeated)

# ============================================================================
# BATTLE FLOW
# ============================================================================

func _start_battle() -> void:
	_log_battle("Battle started! %s vs %s" % [attacker_faction, defender_faction])
	_update_turn_display()

func _on_battle_started(attacker_count: int, defender_count: int) -> void:
	_log_battle("Forces engaged: %d attackers, %d defenders" % [attacker_count, defender_count])

func _on_battle_ended(victor: String, result: Dictionary) -> void:
	_log_battle("Battle ended! Victor: %s" % victor)
	
	# Prepare result for strategic layer
	var battle_result := _prepare_battle_result(victor, result)
	
	# End battle in GameState
	GameState.end_battle(battle_result)
	
	# Return to strategic map
	_return_to_strategic()

func _prepare_battle_result(victor: String, hexforge_result: Dictionary) -> Dictionary:
	var attacker_casualties: Array = []
	var defender_casualties: Array = []
	var attacker_survivors: Array = []
	var defender_survivors: Array = []
	
	# Extract casualty information from HexForge result
	# This would need proper integration with HexForge's serialization
	
	return {
		"victor": victor,
		"attacker_faction": attacker_faction,
		"defender_faction": defender_faction,
		"attacker_casualties": attacker_casualties,
		"attacker_survivors": attacker_survivors,
		"defender_casualties": defender_casualties,
		"defender_survivors": defender_survivors,
		"capture_province": victor == attacker_faction,
		"turns": hexforge_result.get("turns", 1)
	}

# ============================================================================
# TURN MANAGEMENT
# ============================================================================

func _on_turn_started(turn_number: int, active_side: String) -> void:
	_update_turn_display()
	
	var is_player_turn := (active_side == "attacker" and is_player_attacker) or \
					  (active_side == "defender" and not is_player_attacker)
	
	if is_player_turn:
		_log_battle("Your turn!")
	else:
		_log_battle("Enemy turn...")
		# Trigger AI if enabled
		if active_side == "defender" and not is_player_attacker:
			_process_ai_turn()

func _update_turn_display() -> void:
	if turn_label and battle_controller:
		var side := battle_controller.turn_manager.active_side
		var turn := battle_controller.turn_manager.get_turn_number()
		turn_label.text = "Turn %d - %s" % [turn, side.capitalize()]

func _process_ai_turn() -> void:
	# Simple AI - end turn after delay
	await get_tree().create_timer(1.0).timeout
	battle_controller.end_turn()

# ============================================================================
# COMBAT EVENTS
# ============================================================================

func _on_attack_resolved(attacker_id: String, defender_id: String, damage: int, hit: bool) -> void:
	if hit:
		_log_battle("%s hits %s for %d damage!" % [attacker_id, defender_id, damage])
	else:
		_log_battle("%s attacks %s but misses!" % [attacker_id, defender_id])

func _on_unit_defeated(unit_id: String, side: String) -> void:
	_log_battle("%s unit %s has been defeated!" % [side.capitalize(), unit_id])

# ============================================================================
# UI HANDLERS
# ============================================================================

func _on_end_turn_pressed() -> void:
	if battle_controller:
		battle_controller.end_turn()

func _on_retreat_pressed() -> void:
	# Retreat counts as defeat for attacker
	var victor := defender_faction if is_player_attacker else attacker_faction
	
	_log_battle("Retreating from battle!")
	
	var result := {
		"victor": victor,
		"attacker_faction": attacker_faction,
		"defender_faction": defender_faction,
		"attacker_casualties": [],
		"attacker_survivors": [],
		"defender_casualties": [],
		"defender_survivors": [],
		"capture_province": false,
		"turns": battle_controller.turn_manager.get_turn_number()
	}
	
	GameState.end_battle(result)
	_return_to_strategic()

func _log_battle(message: String) -> void:
	if battle_log:
		battle_log.append_text("[color=#f4e4c1]%s[/color]\n" % message)

# ============================================================================
# SCENE TRANSITION
# ============================================================================

func _return_to_strategic() -> void:
	get_tree().change_scene_to_file(RETURN_SCENE)
