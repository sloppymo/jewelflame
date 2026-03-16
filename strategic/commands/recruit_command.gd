class_name RecruitCommand
extends Command

# Command to recruit troops in a province

const RECRUIT_AMOUNT: int = 10
const RECRUIT_COST_PER_UNIT: int = 10

var province_id: StringName
var _total_cost: int = 0

# Stored state for undo
var _old_troops: int = 0

func _init(target_id: StringName) -> void:
	super._init()
	command_name = "Recruit Troops"
	province_id = target_id
	_total_cost = RECRUIT_AMOUNT * RECRUIT_COST_PER_UNIT

func execute() -> bool:
	var gs = GameState
	if gs == null:
		push_error("RecruitCommand: GameState not available")
		return false
	
	var province = gs.provinces.get(province_id)
	if province == null:
		push_error("RecruitCommand: Invalid province ID")
		return false
	
	# Validate ownership
	var current_faction = gs.get_current_faction()
	if current_faction == null:
		push_error("RecruitCommand: No current faction")
		return false
	
	if not current_faction.owns_province(province_id):
		push_error("RecruitCommand: Do not own province")
		return false
	
	# Check funds
	if current_faction.gold < _total_cost:
		push_error("RecruitCommand: Not enough gold (need %d)" % _total_cost)
		return false
	
	# Store state for undo
	_old_troops = province.troops
	
	# Execute recruitment
	current_faction.gold -= _total_cost
	province.troops += RECRUIT_AMOUNT
	
	# Emit signal
	EventBus.ProvinceDataChanged.emit(province_id, "troops", province.troops)
	
	status = Status.EXECUTED
	return true

func undo() -> bool:
	if status != Status.EXECUTED:
		push_warning("RecruitCommand: Cannot undo - not executed")
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
	province.troops = _old_troops
	current_faction.gold += _total_cost
	
	status = Status.UNDONE
	return true

func get_cost() -> int:
	return _total_cost

func get_description() -> String:
	var gs = GameState
	if gs == null:
		return "Recruit %d troops" % RECRUIT_AMOUNT
	
	var province = gs.provinces.get(province_id)
	if province == null:
		return "Recruit %d troops" % RECRUIT_AMOUNT
	
	return "Recruit %d troops in %s" % [RECRUIT_AMOUNT, province.province_name]
