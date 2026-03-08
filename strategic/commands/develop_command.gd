class_name DevelopCommand extends BaseCommand
var province_id: int = -1
var development_type: String = ""
var cost: int = 10

func _init(p_id: int, dev_type: String):
	command_id = "develop_" + str(Time.get_unix_time_from_system())
	command_name = "Develop " + dev_type + " in province " + str(p_id)
	province_id = p_id
	development_type = dev_type

func can_execute() -> bool:
	var province = EnhancedGameState.get_province(province_id)
	if not province:
		return false
	if province.is_exhausted:
		return false
	if province.owner_id != EnhancedGameState.player_family_id:
		return false
	if province.gold < cost:
		return false
	return true

func execute():
	if not can_execute():
		push_error("Cannot execute DevelopCommand")
		return
	
	save_state()
	
	var province = EnhancedGameState.get_province(province_id)
	
	# Store previous values for undo
	execution_data["previous_value"] = province.get(development_type, 0)
	execution_data["previous_gold"] = province.gold
	
	# Apply development
	province.gold -= cost
	match development_type:
		"cultivation":
			province.cultivation = min(100, province.cultivation + 5)
		"protection":
			province.protection = min(100, province.protection + 5)
		_:
			push_error("Unknown development type: " + development_type)
			return
	
	# Mark province exhausted
	province.is_exhausted = true
	
	is_executed = true
	
	# Emit signals
	EventBus.ProvinceDataChanged.emit(province_id, development_type, province.get(development_type))
	EventBus.ProvinceDataChanged.emit(province_id, "gold", province.gold)
	EventBus.ProvinceExhausted.emit(province_id, true)
	
	print("Development completed: ", development_type, " in ", province.name)

func undo():
	if not is_executed:
		return
	
	restore_state()
	
	var province = EnhancedGameState.get_province(province_id)
	if province:
		# Restore previous values
		province.set(development_type, execution_data.get("previous_value", 0))
		province.gold = execution_data.get("previous_gold", 0)
		province.is_exhausted = false
		
		# Emit signals
		EventBus.ProvinceDataChanged.emit(province_id, development_type, province.get(development_type))
		EventBus.ProvinceDataChanged.emit(province_id, "gold", province.gold)
		EventBus.ProvinceExhausted.emit(province_id, false)
		
		print("Development undone: ", development_type, " in ", province.name)

func get_description() -> String:
	var province = EnhancedGameState.get_province(province_id)
	if province:
		return "Develop " + development_type + " in " + province.name
	return "Develop " + development_type + " in province " + str(province_id)
