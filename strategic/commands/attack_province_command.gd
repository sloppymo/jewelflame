class_name AttackProvinceCommand extends BaseCommand
var attacking_province_id: int = -1
var defending_province_id: int = -1
var attacking_units: Array[UnitData] = []
var attacking_lord_id: String = ""

func _init(attacker: int, defender: int, units: Array, lord: String = ""):
	command_id = "attack_" + str(Time.get_unix_time_from_system())
	command_name = "Attack Province"
	attacking_province_id = attacker
	defending_province_id = defender
	attacking_units = units.duplicate()
	attacking_lord_id = lord

func can_execute() -> Dictionary:
	# Validate province IDs
	if not SafeAccess.validate_province_id(attacking_province_id):
		return ErrorHandler.handle_invalid_province(attacking_province_id, "can_execute")
	if not SafeAccess.validate_province_id(defending_province_id):
		return ErrorHandler.handle_invalid_province(defending_province_id, "can_execute")
	
	var attacker_province = SafeAccess.get_enhanced_province_safe(attacking_province_id)
	var defender_province = SafeAccess.get_enhanced_province_safe(defending_province_id)
	
	if not attacker_province:
		return ErrorHandler.handle_invalid_province(attacking_province_id, "can_execute")
	if not defender_province:
		return ErrorHandler.handle_invalid_province(defending_province_id, "can_execute")
	
	# Check if provinces are adjacent
	if defender_province_id not in attacker_province.neighbors:
		return ErrorHandler.handle_command_execution(command_name, "Provinces are not adjacent")
	
	# Check if attacker has units
	if attacking_units.is_empty():
		return ErrorHandler.handle_command_execution(command_name, "No attacking units specified")
	
	# Check if attacker is not exhausted
	if attacker_province.is_exhausted:
		return ErrorHandler.handle_command_execution(command_name, "Attacker province is exhausted")
	
	# Check if defender is enemy
	var attacker_owner = SafeAccess.safe_get_owner_id(attacker_province)
	var defender_owner = SafeAccess.safe_get_owner_id(defender_province)
	if defender_owner == attacker_owner:
		return ErrorHandler.handle_command_execution(command_name, "Cannot attack own province")
	
	return ErrorHandler.create_success()

func execute() -> Dictionary:
	var can_execute_result = can_execute()
	if not ErrorHandler.is_success(can_execute_result):
		return can_execute_result
	
	var save_result = save_state()
	if not ErrorHandler.is_success(save_result):
		return save_result
	
	var attacker_province = SafeAccess.get_enhanced_province_safe(attacking_province_id)
	var defender_province = SafeAccess.get_enhanced_province_safe(defending_province_id)
	
	if not attacker_province or not defender_province:
		return ErrorHandler.handle_null_reference("province data", "execute")
	
	# Create battle data
	var battle = BattleData.new()
	battle.battle_id = command_id
	battle.attacking_province_id = attacking_province_id
	battle.defending_province_id = defending_province_id
	battle.attacking_family_id = SafeAccess.safe_get_owner_id(attacker_province)
	battle.defending_family_id = SafeAccess.safe_get_owner_id(defender_province)
	battle.attacking_units = attacking_units.duplicate()
	
	# Set up defending units
	if defender_province.has_method("get") and defender_province.get("stationed_units") != null:
		for unit in defender_province.stationed_units:
			battle.defending_units.append(unit)
	
	# Add basic soldiers if no units
	if battle.defending_units.is_empty():
		var soldier_unit = UnitData.new()
		soldier_unit.unit_type = "knight"
		soldier_unit.stack_size = SafeAccess.safe_get_province_soldiers(defender_province)
		battle.defending_units.append(soldier_unit)
	
	# Set commanders
	battle.attacking_commander_id = attacking_lord_id
	battle.defending_commander_id = defender_province.stationed_lord_id if defender_province.has_method("get") else ""
	
	# Set terrain and weather
	battle.terrain_type = SafeAccess.safe_get_province_terrain(defender_province)
	battle.weather_condition = defender_province.current_weather if defender_province.has_method("get") else "clear"
	
	# Set formations based on commanders
	var attacker_commander = SafeAccess.get_enhanced_character_safe(attacking_lord_id) if not attacking_lord_id.is_empty() else null
	var defender_commander_id = defender_province.stationed_lord_id if defender_province.has_method("get") else ""
	var defender_commander = SafeAccess.get_enhanced_character_safe(defender_commander_id) if not defender_commander_id.is_empty() else null
	
	if attacker_commander and attacker_commander.has_method("get") and attacker_commander.get("preferred_formation") != null:
		battle.attacker_formation = attacker_commander.preferred_formation
	
	if defender_commander and defender_commander.has_method("get") and defender_commander.get("preferred_formation") != null:
		battle.defender_formation = defender_commander.preferred_formation
	
	# Mark attacker as exhausted
	attacker_province.is_exhausted = true
	
	# Remove attacking units from province (they're now in battle)
	if attacker_province.has_method("get") and attacker_province.get("stationed_units") != null:
		for unit in attacking_units:
			var index = attacker_province.stationed_units.find(unit)
			if index >= 0:
				attacker_province.stationed_units.remove_at(index)
	
	# Update execution data
	execution_data["battle_data"] = battle
	execution_data["attacker_province"] = attacking_province_id
	execution_data["defender_province"] = defending_province_id
	
	is_executed = true
	
	# Emit battle initiated signal
	EventBus.BattleInitiated.emit(battle)
	EventBus.ProvinceExhausted.emit(attacking_province_id, true)
	
	# Emit province data changes
	EventBus.ProvinceDataChanged.emit(attacking_province_id, "is_exhausted", true)
	
	return ErrorHandler.create_success({"battle": battle})

func undo() -> Dictionary:
	if not is_executed:
		return ErrorHandler.handle_command_execution(command_name, "Command not executed, cannot undo")
	
	var restore_result = restore_state()
	if not ErrorHandler.is_success(restore_result):
		return restore_result
	
	# Return units to attacking province
	var attacker_province = SafeAccess.get_enhanced_province_safe(attacking_province_id)
	if attacker_province and attacker_province.has_method("get") and attacker_province.get("stationed_units") != null:
		for unit in attacking_units:
			attacker_province.stationed_units.append(unit)
	
	# Remove exhaustion
	if attacker_province:
		attacker_province.is_exhausted = false
	
	# Cancel battle
	EventBus.BattleCancelled.emit(command_id)
	EventBus.ProvinceExhausted.emit(attacking_province_id, false)
	EventBus.ProvinceDataChanged.emit(attacking_province_id, "is_exhausted", false)
	
	is_executed = false
	return ErrorHandler.create_success()

func get_description() -> String:
	var attacker_province = EnhancedGameState.get_province(attacking_province_id)
	var defender_province = EnhancedGameState.get_province(defending_province_id)
	
	if attacker_province and defender_province:
		return "Attack %s from %s" % [defender_province.name, attacker_province.name]
	
	return "Attack Province"

func calculate_attack_power() -> int:
	var total_power = 0
	for unit in attacking_units:
		if unit and unit.has_method("calculate_effective_power"):
			total_power += unit.calculate_effective_power()
	
	# Add commander bonus
	if not attacking_lord_id.is_empty():
		var commander = SafeAccess.get_enhanced_character_safe(attacking_lord_id)
		if commander and commander.has_method("get") and commander.get("command_rating") != null:
			total_power = int(total_power * (1.0 + float(commander.command_rating) / 100.0))
	
	return total_power
