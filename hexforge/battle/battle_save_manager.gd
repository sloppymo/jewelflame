## HexForge/Battle/BattleSaveManager
## High-level API for battle save/load operations
## Auto-saves, quick saves, and save slot management
## Part of HexForge battle system

class_name BattleSaveManager
extends Node

# ============================================================================
# SIGNALS
# ============================================================================

signal battle_saved(save_info: Dictionary)
signal battle_loaded(save_info: Dictionary)
signal auto_save_triggered()
signal quick_save_created(path: String)

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var auto_save_enabled: bool = true
@export var auto_save_interval_seconds: float = 300.0  # 5 minutes
@export var max_auto_saves: int = 5
@export var max_quick_saves: int = 10

@export var save_directory: String = "user://battles/"
@export var auto_save_prefix: String = "autosave_"
@export var quick_save_prefix: String = "quicksave_"

# ============================================================================
# STATE
# ============================================================================

var _battle_controller: Node = null
var _auto_save_timer: Timer = null
var _current_battle_id: String = ""

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_ensure_save_directory()
	_setup_auto_save_timer()

func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(save_directory):
		var err := DirAccess.make_dir_recursive_absolute(save_directory)
		if err != OK:
			push_error("BattleSaveManager: Failed to create save directory: %s" % save_directory)

func _setup_auto_save_timer() -> void:
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = auto_save_interval_seconds
	_auto_save_timer.autostart = auto_save_enabled
	_auto_save_timer.timeout.connect(_on_auto_save_timer)
	add_child(_auto_save_timer)

func setup(battle_controller: Node) -> void:
	_battle_controller = battle_controller

# ============================================================================
# SAVE OPERATIONS
# ============================================================================

## Saves the current battle state
func save_battle(save_name: String = "", slot_name: String = "") -> String:
	if _battle_controller == null:
		push_error("BattleSaveManager: No battle controller set")
		return ""
	
	var state := BattleState.new()
	state.capture_from_battle(_battle_controller)
	
	# Set save metadata
	if not save_name.is_empty():
		state.battle_name = save_name
	
	if not _current_battle_id.is_empty():
		state.battle_id = _current_battle_id
	elif state.battle_id.is_empty():
		state.battle_id = _generate_battle_id()
		_current_battle_id = state.battle_id
	
	# Generate filename
	var filename: String
	if not slot_name.is_empty():
		filename = slot_name + ".battle"
	else:
		filename = _generate_save_filename(state.battle_name)
	
	var path := save_directory + filename
	
	# Save to file
	if state.save_to_file(path):
		battle_saved.emit(state.get_save_info())
		return path
	
	return ""

## Quick save (overwrites previous quicksave or creates new)
func quick_save() -> String:
	_cleanup_old_saves(quick_save_prefix, max_quick_saves)
	
	var slot_name := quick_save_prefix + Time.get_datetime_string_from_system().replace(":", "-")
	var path := save_battle("Quick Save", slot_name)
	
	if not path.is_empty():
		quick_save_created.emit(path)
	
	return path

## Auto save (creates rotating auto-saves)
func auto_save() -> String:
	_cleanup_old_saves(auto_save_prefix, max_auto_saves)
	
	var timestamp := Time.get_unix_time_from_system()
	var slot_name := auto_save_prefix + str(timestamp)
	var path := save_battle("Auto Save", slot_name)
	
	if not path.is_empty():
		auto_save_triggered.emit()
	
	return path

# ============================================================================
# LOAD OPERATIONS
# ============================================================================

## Loads a battle from a file path
func load_battle(path: String) -> bool:
	if _battle_controller == null:
		push_error("BattleSaveManager: No battle controller set")
		return false
	
	var state := BattleState.load_from_file(path)
	if state == null:
		return false
	
	_current_battle_id = state.battle_id
	
	var success := state.restore_to_battle(_battle_controller)
	if success:
		battle_loaded.emit(state.get_save_info())
	
	return success

## Loads the most recent auto-save
func load_latest_auto_save() -> bool:
	var saves := list_auto_saves()
	if saves.is_empty():
		return false
	
	return load_battle(saves[0]["path"])

## Loads the most recent quick save
func load_latest_quick_save() -> bool:
	var saves := list_quick_saves()
	if saves.is_empty():
		return false
	
	return load_battle(saves[0]["path"])

## Loads a battle by ID
func load_battle_by_id(battle_id: String) -> bool:
	var all_saves := list_all_saves()
	
	for save in all_saves:
		if save["battle_id"] == battle_id:
			return load_battle(save["path"])
	
	return false

# ============================================================================
# SAVE LISTING
# ============================================================================

## Lists all saved battles
func list_all_saves() -> Array[Dictionary]:
	return BattleState.list_saved_battles(save_directory)

## Lists auto-saves only
func list_auto_saves() -> Array[Dictionary]:
	return list_all_saves().filter(func(s): return s["filename"].begins_with(auto_save_prefix))

## Lists quick saves only
func list_quick_saves() -> Array[Dictionary]:
	return list_all_saves().filter(func(s): return s["filename"].begins_with(quick_save_prefix))

## Lists manual saves only
func list_manual_saves() -> Array[Dictionary]:
	return list_all_saves().filter(func(s): 
		return not s["filename"].begins_with(auto_save_prefix) and not s["filename"].begins_with(quick_save_prefix)
	)

## Gets the most recent save info
func get_most_recent_save() -> Dictionary:
	var saves := list_all_saves()
	if saves.is_empty():
		return {}
	return saves[0]

# ============================================================================
# SAVE MANAGEMENT
# ============================================================================

## Deletes a save file
func delete_save(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	
	var err := DirAccess.remove_absolute(path)
	return err == OK

## Deletes saves by battle ID (all versions)
func delete_battle_saves(battle_id: String) -> int:
	var all_saves := list_all_saves()
	var deleted := 0
	
	for save in all_saves:
		if save["battle_id"] == battle_id:
			if delete_save(save["path"]):
				deleted += 1
	
	return deleted

## Cleans up old saves beyond the limit
func _cleanup_old_saves(prefix: String, max_count: int) -> void:
	var saves := list_all_saves().filter(func(s): return s["filename"].begins_with(prefix))
	
	# Sort by timestamp (oldest last)
	saves.sort_custom(func(a, b): return a["timestamp"] < b["timestamp"])
	
	# Delete oldest if over limit
	while saves.size() >= max_count:
		var oldest := saves.pop_back()
		delete_save(oldest["path"])

# ============================================================================
# AUTO SAVE
# ============================================================================

func _on_auto_save_timer() -> void:
	if auto_save_enabled and _battle_controller != null:
		var is_active: bool = _battle_controller.get("is_active") if _battle_controller.has("is_active") else false
		if is_active:
			auto_save()

func set_auto_save_enabled(enabled: bool) -> void:
	auto_save_enabled = enabled
	if _auto_save_timer:
		_auto_save_timer.paused = not enabled

func trigger_manual_auto_save() -> String:
	return auto_save()

# ============================================================================
# UTILITY
# ============================================================================

func _generate_save_filename(battle_name: String) -> String:
	var base_name := battle_name if not battle_name.is_empty() else "battle"
	base_name = base_name.replace(" ", "_").to_lower()
	
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	return "%s_%s.battle" % [base_name, timestamp]

func _generate_battle_id() -> String:
	var timestamp := Time.get_unix_time_from_system()
	var random := randi() % 10000
	return "battle_%d_%d" % [timestamp, random]

## Gets save directory size info
func get_storage_info() -> Dictionary:
	var saves := list_all_saves()
	var total_size := 0
	
	for save in saves:
		var path: String = save["path"]
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				total_size += file.get_length()
				file.close()
	
	return {
		"save_count": saves.size(),
		"total_size_bytes": total_size,
		"total_size_kb": total_size / 1024.0,
		"auto_saves": list_auto_saves().size(),
		"quick_saves": list_quick_saves().size()
	}

# ============================================================================
# EXPORT/IMPORT
# ============================================================================

## Exports a save to a different location (for sharing)
func export_save(source_path: String, target_path: String) -> bool:
	if not FileAccess.file_exists(source_path):
		return false
	
	var state := BattleState.load_from_file(source_path)
	if state == null:
		return false
	
	return state.save_to_file(target_path)

## Imports a save from an external location
func import_save(source_path: String, custom_name: String = "") -> String:
	if not FileAccess.file_exists(source_path):
		return ""
	
	var state := BattleState.load_from_file(source_path)
	if state == null:
		return ""
	
	if not custom_name.is_empty():
		state.battle_name = custom_name
	
	var filename := _generate_save_filename(state.battle_name)
	var target_path := save_directory + filename
	
	if state.save_to_file(target_path):
		return target_path
	
	return ""
