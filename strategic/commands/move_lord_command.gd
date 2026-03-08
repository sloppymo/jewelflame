class_name MoveLordCommand extends BaseCommand
var lord_id: String = ""
var from_province_id: int = -1
var to_province_id: int = -1
var transport_cost: int = 0

func _init(lord: String, from: int, to: int):
	command_id = "move_lord_" + str(Time.get_unix_time_from_system())
	command_name = "Move Lord"
	lord_id = lord
	from_province_id = from
	to_province_id = to
	transport_cost = calculate_transport_cost()

func can_execute() -> bool:
	var lord = EnhancedGameState.get_character(lord_id)
	if not lord:
		return false
	
	var from_province = EnhancedGameState.get_province(from_province_id)
	var to_province = EnhancedGameState.get_province(to_province_id)
	
	if not from_province or not to_province:
		return false
	
	# Check if provinces are adjacent
	if to_province_id not in from_province.neighbors:
		return false
	
	# Check if lord is in source province
	if from_province.stationed_lord_id != lord_id:
		return false
	
	# Check if destination is friendly or empty
	if to_province.owner_id != lord.family_id and to_province.owner_id != "":
		return false
	
	# Check transport capacity
	if transport_cost > from_province.transport_capacity:
		return false
	
	# Check if destination can accept more units
	if not to_province.can_support_more_units():
		return false
	
	return true

func execute():
	if not can_execute():
		push_error("Cannot execute MoveLordCommand")
		return
	
	save_state()
	
	var from_province = EnhancedGameState.get_province(from_province_id)
	var to_province = EnhancedGameState.get_province(to_province_id)
	
	# Move lord
	from_province.stationed_lord_id = ""
	to_province.stationed_lord_id = lord_id
	
	# Update transport capacity
	from_province.transport_capacity -= transport_cost
	
	# Update command data
	execution_data["moved_lord"] = lord_id
	execution_data["from_province"] = from_province_id
	execution_data["to_province"] = to_province_id
	
	is_executed = true
	
	# Emit signals
	EventBus.LordMoved.emit(lord_id, from_province_id, to_province_id)
	EventBus.ProvinceDataChanged.emit(from_province_id, "stationed_lord_id", "")
	EventBus.ProvinceDataChanged.emit(to_province_id, "stationed_lord_id", lord_id)
	EventBus.ProvinceDataChanged.emit(from_province_id, "transport_capacity", from_province.transport_capacity)

func undo():
	if not is_executed:
		return
	
	restore_state()
	
	# Reverse the move
	var to_province = EnhancedGameState.get_province(to_province_id)
	var from_province = EnhancedGameState.get_province(from_province_id)
	
	to_province.stationed_lord_id = ""
	from_province.stationed_lord_id = lord_id
	from_province.transport_capacity += transport_cost
	
	# Emit signals
	EventBus.LordMoved.emit(lord_id, to_province_id, from_province_id)
	EventBus.ProvinceDataChanged.emit(to_province_id, "stationed_lord_id", "")
	EventBus.ProvinceDataChanged.emit(from_province_id, "stationed_lord_id", lord_id)
	EventBus.ProvinceDataChanged.emit(from_province_id, "transport_capacity", from_province.transport_capacity)

func calculate_transport_cost() -> int:
	var lord = EnhancedGameState.get_character(lord_id)
	var base_cost = 10
	
	# Modify by lord's leadership
	if lord:
		var leadership_bonus = lord.leadership / 100.0
		base_cost = int(base_cost * (2.0 - leadership_bonus))
	
	return base_cost

func get_description() -> String:
	var lord = EnhancedGameState.get_character(lord_id)
	var from_province = EnhancedGameState.get_province(from_province_id)
	var to_province = EnhancedGameState.get_province(to_province_id)
	
	if lord and from_province and to_province:
		return "Move %s from %s to %s" % [lord.name, from_province.name, to_province.name]
	
	return "Move Lord"
