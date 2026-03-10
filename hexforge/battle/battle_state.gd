## HexForge/Battle/BattleState
## Serializable battle state for save/load functionality
## Captures complete battle state: grid, units, turns, and progress
## Part of HexForge battle system

class_name BattleState
extends Resource

# ============================================================================
# VERSION
# ============================================================================

const VERSION: String = "1.0.0"

# ============================================================================
# STATE DATA
# ============================================================================

## Battle identification
@export var battle_id: String = ""
@export var battle_name: String = ""
@export var save_timestamp: int = 0

## Grid state (serialized HexGrid)
@export var grid_data: Dictionary = {}

## Unit states
@export var unit_data: Array[Dictionary] = []

## Turn state
@export var current_turn: int = 1
@export var active_side: String = "attacker"  # "attacker" or "defender"
@export var turn_order: Array[String] = []

## Battle configuration
@export var hex_size: float = 32.0
@export var grid_width: int = 11
@export var grid_height: int = 11

## Battle progress
@export var is_active: bool = false
@export var is_complete: bool = false
@export var victor: String = ""  # "attacker", "defender", or ""
@export var battle_result: Dictionary = {}

## Fog of war state (if enabled)
@export var fog_of_war_enabled: bool = false
@export var explored_cells: Array[Vector3i] = []
@export var visibility_sources: Array[Dictionary] = []

## Animation state (for resuming mid-animation)
@export var pending_animations: Array[Dictionary] = []
@export var selected_unit_id: String = ""

# ============================================================================
# SERIALIZATION
# ============================================================================

## Converts the battle state to a serializable dictionary
func to_dict() -> Dictionary:
	return {
		"version": VERSION,
		"metadata": {
			"battle_id": battle_id,
			"battle_name": battle_name,
			"save_timestamp": save_timestamp,
			"hexforge_version": VERSION
		},
		"grid": grid_data,
		"units": {
			"unit_data": unit_data,
			"selected_unit_id": selected_unit_id
		},
		"turn_state": {
			"current_turn": current_turn,
			"active_side": active_side,
			"turn_order": turn_order
		},
		"configuration": {
			"hex_size": hex_size,
			"grid_width": grid_width,
			"grid_height": grid_height
		},
		"progress": {
			"is_active": is_active,
			"is_complete": is_complete,
			"victor": victor,
			"battle_result": battle_result
		},
		"fog_of_war": {
			"enabled": fog_of_war_enabled,
			"explored_cells": _pack_vectors(explored_cells),
			"visibility_sources": visibility_sources
		}
	}

## Creates a BattleState from a dictionary
static func from_dict(d: Dictionary) -> BattleState:
	var state := BattleState.new()
	
	# Check version
	var version: String = d.get("version", "1.0.0")
	if version != VERSION:
		push_warning("BattleState: Version mismatch (file=%s, current=%s)" % [version, VERSION])
	
	# Metadata
	var metadata: Dictionary = d.get("metadata", {})
	state.battle_id = metadata.get("battle_id", "")
	state.battle_name = metadata.get("battle_name", "")
	state.save_timestamp = metadata.get("save_timestamp", 0)
	
	# Grid
	state.grid_data = d.get("grid", {})
	
	# Units
	var units: Dictionary = d.get("units", {})
	state.unit_data = _to_typed_array(units.get("unit_data", []))
	state.selected_unit_id = units.get("selected_unit_id", "")
	
	# Turn state
	var turn_state: Dictionary = d.get("turn_state", {})
	state.current_turn = turn_state.get("current_turn", 1)
	state.active_side = turn_state.get("active_side", "attacker")
	state.turn_order = turn_state.get("turn_order", ["attacker", "defender"])
	
	# Configuration
	var config: Dictionary = d.get("configuration", {})
	state.hex_size = config.get("hex_size", 32.0)
	state.grid_width = config.get("grid_width", 11)
	state.grid_height = config.get("grid_height", 11)
	
	# Progress
	var progress: Dictionary = d.get("progress", {})
	state.is_active = progress.get("is_active", false)
	state.is_complete = progress.get("is_complete", false)
	state.victor = progress.get("victor", "")
	state.battle_result = progress.get("battle_result", {})
	
	# Fog of war
	var fog: Dictionary = d.get("fog_of_war", {})
	state.fog_of_war_enabled = fog.get("enabled", false)
	state.explored_cells = _unpack_vectors(fog.get("explored_cells", []))
	state.visibility_sources = _to_typed_array(fog.get("visibility_sources", []))
	
	return state

## Converts to JSON string
func to_json() -> String:
	return JSON.stringify(to_dict(), "  ")

## Creates from JSON string
static func from_json(json_string: String) -> BattleState:
	var result: Variant = JSON.parse_string(json_string)
	if result == null or not result is Dictionary:
		push_error("BattleState.from_json: Failed to parse JSON")
		return null
	return from_dict(result)

# ============================================================================
# FILE OPERATIONS
# ============================================================================

## Saves battle state to a file
func save_to_file(path: String) -> bool:
	save_timestamp = Time.get_unix_time_from_system()
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("BattleState.save_to_file: Failed to open file: %s" % path)
		return false
	
	file.store_string(to_json())
	file.close()
	
	print("BattleState: Saved to %s" % path)
	return true

## Loads battle state from a file
static func load_from_file(path: String) -> BattleState:
	if not FileAccess.file_exists(path):
		push_error("BattleState.load_from_file: File does not exist: %s" % path)
		return null
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("BattleState.load_from_file: Failed to open file: %s" % path)
		return null
	
	var json_string := file.get_as_text()
	file.close()
	
	return from_json(json_string)

## Gets a list of saved battles from a directory
static func list_saved_battles(directory: String = "user://battles/") -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	
	if not DirAccess.dir_exists_absolute(directory):
		return results
	
	var dir := DirAccess.open(directory)
	if dir == null:
		return results
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".battle"):
			var full_path := directory + file_name
			var state := load_from_file(full_path)
			
			if state != null:
				var date_str := ""
				if state.save_timestamp > 0:
					date_str = Time.get_datetime_string_from_unix_time(state.save_timestamp)
				
				results.append({
					"path": full_path,
					"filename": file_name,
					"battle_name": state.battle_name,
					"battle_id": state.battle_id,
					"timestamp": state.save_timestamp,
					"date_string": date_str,
					"turn": state.current_turn,
					"active_side": state.active_side,
					"is_complete": state.is_complete
				})
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Sort by timestamp (newest first)
	results.sort_custom(func(a, b): return a["timestamp"] > b["timestamp"])
	
	return results

# ============================================================================
# CAPTURE FROM RUNTIME
# ============================================================================

## Captures current state from battle components
func capture_from_battle(battle_controller: Node) -> void:
	if battle_controller == null:
		push_error("BattleState.capture_from_battle: Null controller")
		return
	
	# Generate battle ID if not set
	if battle_id.is_empty():
		battle_id = _generate_battle_id()
	
	# Capture grid state
	var battle_grid = battle_controller.get("battle_grid")
	if battle_grid != null and battle_grid.has_method("get_grid"):
		var grid: HexGrid = battle_grid.get_grid()
		if grid != null:
			grid_data = grid.to_dict()
	
	# Capture unit states
	var unit_manager = battle_controller.get("unit_manager")
	if unit_manager != null:
		_capture_units_from_manager(unit_manager)
	
	# Capture turn state
	var turn_manager = battle_controller.get("turn_manager")
	if turn_manager != null:
		current_turn = turn_manager.get("current_turn") as int
		active_side = turn_manager.get("active_side") as String
		turn_order = turn_manager.get("turn_order") as Array[String]
	
	# Capture configuration
	hex_size = battle_controller.get("hex_size") as float
	
	# Capture battle state
	is_active = battle_controller.get("is_active") as bool
	
	if battle_controller.has_method("get_battle_result"):
		battle_result = battle_controller.call("get_battle_result")
		is_complete = battle_result.get("complete", false)
		victor = battle_result.get("victor", "")
	
	# Capture selection
	selected_unit_id = battle_controller.get("selected_unit_id") as String

func _capture_units_from_manager(unit_manager: Node) -> void:
	unit_data.clear()
	
	# Get units from manager
	var units = unit_manager.get("units")
	if units == null:
		return
	
	for unit_id in units.keys():
		var unit = units[unit_id]
		var unit_dict: Dictionary = {
			"id": unit_id,
			"side": unit.get("side") if unit.has("side") else "attacker",
			"unit_type": unit.get("unit_type") if unit.has("unit_type") else "infantry",
			"current_hp": unit.get("current_hp") if unit.has("current_hp") else 10,
			"max_hp": unit.get("max_hp") if unit.has("max_hp") else 10,
			"attack": unit.get("attack") if unit.has("attack") else 3,
			"defense": unit.get("defense") if unit.has("defense") else 2,
			"movement": unit.get("movement") if unit.has("movement") else 5.0,
			"attack_range": unit.get("attack_range") if unit.has("attack_range") else 1,
			"has_moved": unit.get("has_moved") if unit.has("has_moved") else false,
			"has_attacked": unit.get("has_attacked") if unit.has("has_attacked") else false,
			"cube": _pack_vector(unit.get("cube") if unit.has("cube") else Vector3i.ZERO),
			"elevation": unit.get("elevation") if unit.has("elevation") else 0
		}
		unit_data.append(unit_dict)

# ============================================================================
# RESTORE TO RUNTIME
# ============================================================================

## Restores state to battle components
func restore_to_battle(battle_controller: Node) -> bool:
	if battle_controller == null:
		push_error("BattleState.restore_to_battle: Null controller")
		return false
	
	# Validate version
	if grid_data.is_empty():
		push_error("BattleState.restore_to_battle: No grid data")
		return false
	
	# Restore grid
	var battle_grid = battle_controller.get("battle_grid")
	if battle_grid != null and battle_grid.has_method("load_grid"):
		var grid := HexGrid.from_dict(grid_data)
		if grid != null:
			battle_grid.call("load_grid", grid)
			battle_controller.set("grid", grid)
	
	# Restore units
	var unit_manager = battle_controller.get("unit_manager")
	if unit_manager != null:
		_restore_units_to_manager(unit_manager)
	
	# Restore turn state
	var turn_manager = battle_controller.get("turn_manager")
	if turn_manager != null:
		turn_manager.set("current_turn", current_turn)
		turn_manager.set("active_side", active_side)
		turn_manager.set("turn_order", turn_order)
	
	# Restore configuration
	battle_controller.set("hex_size", hex_size)
	
	# Restore state flags
	battle_controller.set("is_active", is_active)
	battle_controller.set("selected_unit_id", selected_unit_id)
	
	print("BattleState: Restored battle '%s' (Turn %d, %s)" % [battle_name, current_turn, active_side])
	return true

func _restore_units_to_manager(unit_manager: Node) -> void:
	# Clear existing units
	if unit_manager.has_method("clear_all_units"):
		unit_manager.call("clear_all_units")
	
	# Spawn saved units
	for unit_dict in unit_data:
		if unit_manager.has_method("spawn_unit_from_data"):
			unit_manager.call("spawn_unit_from_data", unit_dict)

# ============================================================================
# UTILITY
# ============================================================================

func _generate_battle_id() -> String:
	var timestamp := Time.get_unix_time_from_system()
	var random := randi() % 10000
	return "battle_%d_%d" % [timestamp, random]

func _pack_vector(v: Vector3i) -> Array:
	return [v.x, v.y, v.z]

func _unpack_vector(a: Array) -> Vector3i:
	if a.size() < 3:
		return Vector3i.ZERO
	return Vector3i(a[0], a[1], a[2])

func _pack_vectors(vectors: Array[Vector3i]) -> Array:
	var result: Array = []
	for v in vectors:
		result.append(_pack_vector(v))
	return result

static func _unpack_vectors(arrays: Array) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for a in arrays:
		if a is Array and a.size() >= 3:
			result.append(Vector3i(a[0], a[1], a[2]))
	return result

static func _to_typed_array(arr: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in arr:
		if item is Dictionary:
			result.append(item)
	return result

# ============================================================================
# METADATA
# ============================================================================

func get_save_info() -> Dictionary:
	var date_str := ""
	if save_timestamp > 0:
		date_str = Time.get_datetime_string_from_unix_time(save_timestamp)
	
	return {
		"battle_id": battle_id,
		"battle_name": battle_name,
		"date": date_str,
		"turn": current_turn,
		"active_side": active_side,
		"unit_count": unit_data.size(),
		"is_complete": is_complete,
		"victor": victor
	}

func _to_string() -> String:
	return "BattleState[%s] Turn %d (%s), %d units, %s" % [
		battle_name if not battle_name.is_empty() else battle_id,
		current_turn,
		active_side,
		unit_data.size(),
		"Complete" if is_complete else "Active"
	]
