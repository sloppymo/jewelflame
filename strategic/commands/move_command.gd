class_name MoveCommand
extends Command

# Command to move troops between adjacent owned provinces

var source_province_id: StringName
var target_province_id: StringName
var troop_amount: int = 0

# Stored state for undo
var _old_source_troops: int = 0
var _old_target_troops: int = 0

func _init(source_id: StringName, target_id: StringName, amount: int) -> void:
	super._init()
	command_name = "Move Troops"
	source_province_id = source_id
	target_province_id = target_id
	troop_amount = amount

func execute() -> bool:
	var gs = GameState
	if gs == null:
		push_error("MoveCommand: GameState not available")
		return false
	
	var source = gs.provinces.get(source_province_id)
	var target = gs.provinces.get(target_province_id)
	
	if source == null or target == null:
		push_error("MoveCommand: Invalid province IDs")
		return false
	
	# Validate ownership
	var current_faction = gs.get_current_faction()
	if current_faction == null:
		push_error("MoveCommand: No current faction")
		return false
	
	if not current_faction.owns_province(source_province_id):
		push_error("MoveCommand: Do not own source province")
		return false
	
	if not current_faction.owns_province(target_province_id):
		push_error("MoveCommand: Do not own target province")
		return false
	
	# Check adjacency
	if not source.is_adjacent_to(target_province_id):
		push_error("MoveCommand: Provinces not adjacent")
		return false
	
	# Validate troop amount
	if troop_amount <= 0:
		push_error("MoveCommand: Invalid troop amount")
		return false
	
	if troop_amount >= source.troops:
		push_error("MoveCommand: Not enough troops (must leave at least 1)")
		return false
	
	# Store state for undo
	_old_source_troops = source.troops
	_old_target_troops = target.troops
	
	# Execute move
	source.troops -= troop_amount
	target.troops += troop_amount
	
	# Mark source as exhausted
	source.is_exhausted = true
	EventBus.ProvinceExhausted.emit(source_province_id, true)
	
	# Emit signal
	gs.troops_moved.emit(source_province_id, target_province_id, troop_amount)
	EventBus.TroopsMoved.emit(source_province_id, target_province_id, troop_amount)
	
	status = Status.EXECUTED
	return true

func undo() -> bool:
	if status != Status.EXECUTED:
		push_warning("MoveCommand: Cannot undo - not executed")
		return false
	
	var gs = GameState
	if gs == null:
		return false
	
	var source = gs.provinces.get(source_province_id)
	var target = gs.provinces.get(target_province_id)
	
	if source == null or target == null:
		return false
	
	# Restore troop counts
	source.troops = _old_source_troops
	target.troops = _old_target_troops
	
	# Un-exhaust source
	source.is_exhausted = false
	EventBus.ProvinceExhausted.emit(source_province_id, false)
	
	status = Status.UNDONE
	return true

func get_description() -> String:
	var gs = GameState
	if gs == null:
		return "Move %d troops" % troop_amount
	
	var source = gs.provinces.get(source_province_id)
	var target = gs.provinces.get(target_province_id)
	
	if source == null or target == null:
		return "Move %d troops" % troop_amount
	
	return "Move %d troops from %s to %s" % [troop_amount, source.province_name, target.province_name]
