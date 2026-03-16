class_name DevelopCommand
extends Command

# Command to upgrade province defense level

var province_id: StringName
var _cost: int = 0

# Stored state for undo
var _old_defense_level: int = 0

func _init(target_id: StringName) -> void:
	super._init()
	command_name = "Develop Province"
	province_id = target_id

func execute() -> bool:
	var gs = GameState
	if gs == null:
		push_error("DevelopCommand: GameState not available")
		return false
	
	var province = gs.provinces.get(province_id)
	if province == null:
		push_error("DevelopCommand: Invalid province ID")
		return false
	
	# Validate ownership
	var current_faction = gs.get_current_faction()
	if current_faction == null:
		push_error("DevelopCommand: No current faction")
		return false
	
	if not current_faction.owns_province(province_id):
		push_error("DevelopCommand: Do not own province")
		return false
	
	# Check max level
	if province.defense_level >= 5:
		push_error("DevelopCommand: Province at max defense level")
		return false
	
	# Calculate cost
	_cost = province.get_development_cost()
	
	# Check funds
	if current_faction.gold < _cost:
		push_error("DevelopCommand: Not enough gold (need %d)" % _cost)
		return false
	
	# Store state for undo
	_old_defense_level = province.defense_level
	
	# Execute development
	current_faction.gold -= _cost
	province.upgrade_defense()
	
	# Emit signal
	EventBus.ProvinceDataChanged.emit(province_id, "defense_level", province.defense_level)
	
	status = Status.EXECUTED
	return true

func undo() -> bool:
	if status != Status.EXECUTED:
		push_warning("DevelopCommand: Cannot undo - not executed")
		return false
	
	var gs = GameState
	if gs == null:
		return false
	
	var province = gs.provinces.get(province_id)
	if province == null:
		return false
	
	var current_faction = gs.get_current_faction()
	if current_faction == null:
		return false
	
	# Restore state
	province.defense_level = _old_defense_level
	current_faction.gold += _cost
	
	status = Status.UNDONE
	return true

func get_cost() -> int:
	if _cost > 0:
		return _cost
	
	# Calculate cost without executing
	var gs = GameState
	if gs == null:
		return 0
	
	var province = gs.provinces.get(province_id)
	if province == null:
		return 0
	
	return province.get_development_cost()

func get_description() -> String:
	var gs = GameState
	if gs == null:
		return "Develop Province"
	
	var province = gs.provinces.get(province_id)
	if province == null:
		return "Develop Province"
	
	return "Develop %s (Level %d -> %d)" % [province.province_name, _old_defense_level, _old_defense_level + 1]
