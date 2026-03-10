class_name TransportCommand extends BaseCommand
var from_province_id: int = -1
var to_province_id: int = -1
var resource_type: String = ""
var amount: int = 0

func _init(from_id: int, to_id: int, res_type: String, amt: int):
	command_id = "transport_" + str(Time.get_unix_time_from_system())
	command_name = "Transport " + str(amt) + " " + res_type + " from " + str(from_id) + " to " + str(to_id)
	from_province_id = from_id
	to_province_id = to_id
	resource_type = res_type
	amount = amt

func can_execute() -> bool:
	var source = GameState.get_province(from_province_id)
	var target = GameState.get_province(to_province_id)
	
	if not source or not target:
		return false
	if source.owner_id != target.owner_id:
		return false
	if source.owner_id != GameState.player_family_id:
		return false
	if source.get(resource_type, 0) < amount:
		return false
	return true

func execute():
	if not can_execute():
		push_error("Cannot execute TransportCommand")
		return
	
	save_state()
	
	var source = GameState.get_province(from_province_id)
	var target = GameState.get_province(to_province_id)
	
	# Store previous values for undo
	execution_data["previous_source_amount"] = source.get(resource_type, 0)
	execution_data["previous_target_amount"] = target.get(resource_type, 0)
	
	# Transfer resources
	var source_amount = source.get(resource_type, 0)
	var target_amount = target.get(resource_type, 0)
	
	source.set(resource_type, source_amount - amount)
	target.set(resource_type, target_amount + amount)
	
	is_executed = true
	
	# Emit signals
	EventBus.ProvinceDataChanged.emit(from_province_id, resource_type, source.get(resource_type))
	EventBus.ProvinceDataChanged.emit(to_province_id, resource_type, target.get(resource_type))
	
	print("Transported ", amount, " ", resource_type, " from ", source.name, " to ", target.name)

func undo():
	if not is_executed:
		return
	
	restore_state()
	
	var source = GameState.get_province(from_province_id)
	var target = GameState.get_province(to_province_id)
	
	if source and target:
		# Restore previous amounts
		source.set(resource_type, execution_data.get("previous_source_amount", 0))
		target.set(resource_type, execution_data.get("previous_target_amount", 0))
		
		# Emit signals
		EventBus.ProvinceDataChanged.emit(from_province_id, resource_type, source.get(resource_type))
		EventBus.ProvinceDataChanged.emit(to_province_id, resource_type, target.get(resource_type))
		
		print("Transport undone: ", amount, " ", resource_type, " from ", source.name, " to ", target.name)

func get_description() -> String:
	var source = GameState.get_province(from_province_id)
	var target = GameState.get_province(to_province_id)
	
	if source and target:
		return "Transport " + str(amount) + " " + resource_type + " from " + source.name + " to " + target.name
	
	return "Transport " + str(amount) + " " + resource_type + " from province " + str(from_province_id) + " to " + str(to_province_id)
