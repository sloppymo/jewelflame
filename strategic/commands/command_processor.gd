extends Node

# Base Command class preload (needed for signal type hints)
const Command = preload("res://strategic/commands/command_base.gd")

# CommandProcessor - Central command validation and execution system
# Implements the Command pattern for undo/redo functionality
# Separates UI logic from game logic

# ============================================================================
# SIGNALS
# ============================================================================

signal command_executed(command: Command)
signal command_undone(command: Command)
signal command_redone(command: Command)
signal command_failed(command: Command, error: String)
signal history_changed(history_size: int, redo_size: int)

# ============================================================================
# CONSTANTS
# ============================================================================

const MAX_HISTORY_SIZE: int = 50

# ============================================================================
# STATE
# ============================================================================

var _command_history: Array[Command] = []
var _redo_stack: Array[Command] = []
var _is_processing: bool = false

# ============================================================================
# PUBLIC API - Command Execution
# ============================================================================

func execute_attack(source_id: StringName, target_id: StringName) -> bool:
	"""Execute an attack command."""
	if not _validate_attack(source_id, target_id):
		return false
	
	var cmd = AttackCommand.new(source_id, target_id)
	return _execute_command(cmd)

func execute_move(source_id: StringName, target_id: StringName, amount: int) -> bool:
	"""Execute a troop move command."""
	if not _validate_move(source_id, target_id, amount):
		return false
	
	var cmd = MoveCommand.new(source_id, target_id, amount)
	return _execute_command(cmd)

func execute_develop(province_id: StringName) -> bool:
	"""Execute a province development command."""
	if not _validate_develop(province_id):
		return false
	
	var cmd = DevelopCommand.new(province_id)
	return _execute_command(cmd)

func execute_recruit(province_id: StringName) -> bool:
	"""Execute a troop recruitment command."""
	if not _validate_recruit(province_id):
		return false
	
	var cmd = RecruitCommand.new(province_id)
	return _execute_command(cmd)

# ============================================================================
# PUBLIC API - Undo/Redo
# ============================================================================

func can_undo() -> bool:
	return not _command_history.is_empty()

func can_redo() -> bool:
	return not _redo_stack.is_empty()

func undo() -> bool:
	if not can_undo():
		push_warning("CommandProcessor: Nothing to undo")
		return false
	
	if _is_processing:
		push_warning("CommandProcessor: Cannot undo while processing")
		return false
	
	var cmd = _command_history.pop_back()
	if cmd.undo():
		_redo_stack.append(cmd)
		history_changed.emit(_command_history.size(), _redo_stack.size())
		command_undone.emit(cmd)
		print("CommandProcessor: Undid - %s" % cmd.get_description())
		return true
	else:
		# Restore to history if undo failed
		_command_history.append(cmd)
		push_error("CommandProcessor: Failed to undo command")
		return false

func redo() -> bool:
	if not can_redo():
		push_warning("CommandProcessor: Nothing to redo")
		return false
	
	if _is_processing:
		push_warning("CommandProcessor: Cannot redo while processing")
		return false
	
	var cmd = _redo_stack.pop_back()
	if cmd.execute():
		_command_history.append(cmd)
		history_changed.emit(_command_history.size(), _redo_stack.size())
		command_redone.emit(cmd)
		print("CommandProcessor: Redid - %s" % cmd.get_description())
		return true
	else:
		# Restore to redo stack if execution failed
		_redo_stack.append(cmd)
		push_error("CommandProcessor: Failed to redo command")
		return false

func clear_history() -> void:
	_command_history.clear()
	_redo_stack.clear()
	history_changed.emit(0, 0)

# ============================================================================
# PUBLIC API - Validation (for UI preview)
# ============================================================================

func can_attack(source_id: StringName, target_id: StringName) -> bool:
	return _validate_attack(source_id, target_id, false)

func can_move(source_id: StringName, target_id: StringName, amount: int) -> bool:
	return _validate_move(source_id, target_id, amount, false)

func can_develop(province_id: StringName) -> bool:
	return _validate_develop(province_id, false)

func can_recruit(province_id: StringName) -> bool:
	return _validate_recruit(province_id, false)

# ============================================================================
# INTERNAL - Command Execution
# ============================================================================

func _execute_command(cmd: Command) -> bool:
	if _is_processing:
		push_warning("CommandProcessor: Already processing a command")
		return false
	
	_is_processing = true
	
	if cmd.execute():
		_command_history.append(cmd)
		_redo_stack.clear()  # Clear redo stack on new command
		
		# Enforce max history size
		if _command_history.size() > MAX_HISTORY_SIZE:
			_command_history.pop_front()
		
		history_changed.emit(_command_history.size(), _redo_stack.size())
		command_executed.emit(cmd)
		print("CommandProcessor: Executed - %s" % cmd.get_description())
		_is_processing = false
		return true
	else:
		command_failed.emit(cmd, "Execution failed")
		_is_processing = false
		return false

# ============================================================================
# INTERNAL - Validation
# ============================================================================

func _validate_attack(source_id: StringName, target_id: StringName, emit_errors: bool = true) -> bool:
	var gs = _get_game_state()
	var tm = _get_turn_manager()
	
	if gs == null or tm == null:
		return _fail_validation("System not ready", emit_errors)
	
	if not tm.is_action_allowed():
		return _fail_validation("Not your turn", emit_errors)
	
	var source = gs.provinces.get(source_id)
	var target = gs.provinces.get(target_id)
	
	if source == null or target == null:
		return _fail_validation("Invalid province selection", emit_errors)
	
	var current_faction = gs.get_current_faction()
	if current_faction == null:
		return _fail_validation("No current faction", emit_errors)
	
	if not current_faction.owns_province(source_id):
		return _fail_validation("Do not own source province", emit_errors)
	
	if current_faction.owns_province(target_id):
		return _fail_validation("Cannot attack your own province", emit_errors)
	
	if not source.is_adjacent_to(target_id):
		return _fail_validation("Provinces not adjacent", emit_errors)
	
	if source.troops <= 1:
		return _fail_validation("Not enough troops to attack", emit_errors)
	
	if source.is_exhausted:
		return _fail_validation("Province already acted this turn", emit_errors)
	
	return true

func _validate_move(source_id: StringName, target_id: StringName, amount: int, emit_errors: bool = true) -> bool:
	var gs = _get_game_state()
	var tm = _get_turn_manager()
	
	if gs == null or tm == null:
		return _fail_validation("System not ready", emit_errors)
	
	if not tm.is_action_allowed():
		return _fail_validation("Not your turn", emit_errors)
	
	var source = gs.provinces.get(source_id)
	var target = gs.provinces.get(target_id)
	
	if source == null or target == null:
		return _fail_validation("Invalid province selection", emit_errors)
	
	var current_faction = gs.get_current_faction()
	if current_faction == null:
		return _fail_validation("No current faction", emit_errors)
	
	if not current_faction.owns_province(source_id):
		return _fail_validation("Do not own source province", emit_errors)
	
	if not current_faction.owns_province(target_id):
		return _fail_validation("Do not own target province", emit_errors)
	
	if not source.is_adjacent_to(target_id):
		return _fail_validation("Provinces not adjacent", emit_errors)
	
	if amount <= 0:
		return _fail_validation("Invalid troop amount", emit_errors)
	
	if amount >= source.troops:
		return _fail_validation("Must leave at least 1 troop", emit_errors)
	
	if source.is_exhausted:
		return _fail_validation("Province already acted this turn", emit_errors)
	
	return true

func _validate_develop(province_id: StringName, emit_errors: bool = true) -> bool:
	var gs = _get_game_state()
	var tm = _get_turn_manager()
	
	if gs == null or tm == null:
		return _fail_validation("System not ready", emit_errors)
	
	if not tm.is_action_allowed():
		return _fail_validation("Not your turn", emit_errors)
	
	var province = gs.provinces.get(province_id)
	if province == null:
		return _fail_validation("Invalid province", emit_errors)
	
	var current_faction = gs.get_current_faction()
	if current_faction == null:
		return _fail_validation("No current faction", emit_errors)
	
	if not current_faction.owns_province(province_id):
		return _fail_validation("Do not own this province", emit_errors)
	
	if province.defense_level >= 5:
		return _fail_validation("Province at max defense level", emit_errors)
	
	var cost = province.get_development_cost()
	if current_faction.gold < cost:
		return _fail_validation("Not enough gold (need %d)" % cost, emit_errors)
	
	return true

func _validate_recruit(province_id: StringName, emit_errors: bool = true) -> bool:
	var gs = _get_game_state()
	var tm = _get_turn_manager()
	
	if gs == null or tm == null:
		return _fail_validation("System not ready", emit_errors)
	
	if not tm.is_action_allowed():
		return _fail_validation("Not your turn", emit_errors)
	
	var province = gs.provinces.get(province_id)
	if province == null:
		return _fail_validation("Invalid province", emit_errors)
	
	var current_faction = gs.get_current_faction()
	if current_faction == null:
		return _fail_validation("No current faction", emit_errors)
	
	if not current_faction.owns_province(province_id):
		return _fail_validation("Do not own this province", emit_errors)
	
	const RECRUIT_COST = 10 * 10  # 10 troops at 10 gold each
	if current_faction.gold < RECRUIT_COST:
		return _fail_validation("Not enough gold (need %d)" % RECRUIT_COST, emit_errors)
	
	return true

func _fail_validation(error_msg: String, emit: bool) -> bool:
	if emit:
		push_warning("CommandProcessor: Validation failed - " + error_msg)
	return false

# ============================================================================
# INTERNAL - Helpers
# ============================================================================

func _get_game_state() -> Node:
	return get_node_or_null("/root/GameState")

func _get_turn_manager() -> Node:
	return get_node_or_null("/root/TurnManager")

# ============================================================================
# DEBUG
# ============================================================================

func get_history_summary() -> String:
	var result := "Command History (%d commands):\n" % _command_history.size()
	for i in range(_command_history.size()):
		var cmd = _command_history[i]
		result += "%d. %s [%s]\n" % [i + 1, cmd.get_description(), Command.Status.keys()[cmd.status]]
	return result
