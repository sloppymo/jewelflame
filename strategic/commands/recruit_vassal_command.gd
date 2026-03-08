class_name RecruitVassalCommand extends BaseCommand
var province_id: int = -1
var defeated_lord_id: String = ""
var recruitment_action: String = "recruit"  # recruit, banish, release

func _init(province: int, lord: String, action: String = "recruit"):
	command_id = "recruit_vassal_" + str(Time.get_unix_time_from_system())
	command_name = "Recruit Vassal"
	province_id = province
	defeated_lord_id = lord
	recruitment_action = action

func can_execute() -> bool:
	var province = EnhancedGameState.get_province(province_id)
	var lord = EnhancedGameState.get_character(defeated_lord_id)
	
	if not province or not lord:
		return false
	
	# Check if lord is captured in this province
	if defeated_lord_id not in province.prisoner_lords:
		return false
	
	# Check if province belongs to player's family
	if province.owner_id != EnhancedGameState.player_family_id:
		return false
	
	# Check recruitment requirements based on action
	match recruitment_action:
		"recruit":
			# Need gold and sufficient loyalty
			if province.gold < 100:
				return false
			if lord.loyalty > 70:  # Too loyal to recruit
				return false
		"banish":
			# No requirements, can always banish
			pass
		"release":
			# No requirements, can always release
			pass
		_:
			return false
	
	return true

func execute():
	if not can_execute():
		push_error("Cannot execute RecruitVassalCommand")
		return
	
	save_state()
	
	var province = EnhancedGameState.get_province(province_id)
	var lord = EnhancedGameState.get_character(defeated_lord_id)
	
	match recruitment_action:
		"recruit":
			# Pay recruitment cost
			province.gold -= 100
			
			# Convert lord to player's service
			lord.family_id = EnhancedGameState.player_family_id
			lord.loyalty = 50  # Reset loyalty to neutral
			lord.is_captured = false
			lord.capture_family_id = ""
			
			# Remove from prisoners
			province.prisoner_lords.erase(defeated_lord_id)
			
			# Place in province if no lord present
			if province.stationed_lord_id == "":
				province.stationed_lord_id = defeated_lord_id
			
			print("Recruited %s to service of %s" % [lord.name, EnhancedGameState.player_family_id])
		
		"banish":
			# Remove lord from game
			province.prisoner_lords.erase(defeated_lord_id)
			lord.is_captured = false
			lord.capture_family_id = ""
			
			print("Banished %s from the realm" % lord.name)
		
		"release":
			# Release lord to their original family
			province.prisoner_lords.erase(defeated_lord_id)
			lord.is_captured = false
			lord.capture_family_id = ""
			lord.loyalty += 20  # Increase loyalty for mercy
			
			print("Released %s" % lord.name)
	
	# Update execution data
	execution_data["province_id"] = province_id
	execution_data["lord_id"] = defeated_lord_id
	execution_data["action"] = recruitment_action
	execution_data["previous_family"] = lord.family_id if recruitment_action == "recruit" else ""
	
	is_executed = true
	
	# Emit signals
	EventBus.VassalRecruited.emit(defeated_lord_id, recruitment_action, province_id)
	EventBus.ProvinceDataChanged.emit(province_id, "gold", province.gold)
	EventBus.CharacterDataChanged.emit(defeated_lord_id, "family_id", lord.family_id)
	EventBus.CharacterDataChanged.emit(defeated_lord_id, "loyalty", lord.loyalty)

func undo():
	if not is_executed:
		return
	
	restore_state()
	
	var province = EnhancedGameState.get_province(province_id)
	var lord = EnhancedGameState.get_character(defeated_lord_id)
	
	match recruitment_action:
		"recruit":
			# Restore original family
			lord.family_id = execution_data["previous_family"]
			lord.is_captured = true
			lord.capture_family_id = EnhancedGameState.player_family_id
			
			# Return to prisoners
			province.prisoner_lords.append(defeated_lord_id)
			
			# Remove from province if stationed there
			if province.stationed_lord_id == defeated_lord_id:
				province.stationed_lord_id = ""
			
			# Refund gold
			province.gold += 100
		
		"banish":
			# Restore as prisoner
			province.prisoner_lords.append(defeated_lord_id)
			lord.is_captured = true
			lord.capture_family_id = EnhancedGameState.player_family_id
		
		"release":
			# Return to prisoner status
			province.prisoner_lords.append(defeated_lord_id)
			lord.is_captured = true
			lord.capture_family_id = EnhancedGameState.player_family_id
			lord.loyalty -= 20  # Remove loyalty bonus
	
	# Emit signals
	EventBus.VassalRecruited.emit(defeated_lord_id, "undo", province_id)
	EventBus.ProvinceDataChanged.emit(province_id, "gold", province.gold)
	EventBus.CharacterDataChanged.emit(defeated_lord_id, "family_id", lord.family_id)
	EventBus.CharacterDataChanged.emit(defeated_lord_id, "loyalty", lord.loyalty)

func get_description() -> String:
	var province = EnhancedGameState.get_province(province_id)
	var lord = EnhancedGameState.get_character(defeated_lord_id)
	
	if province and lord:
		match recruitment_action:
			"recruit":
				return "Recruit %s in %s" % [lord.name, province.name]
			"banish":
				return "Banish %s from %s" % [lord.name, province.name]
			"release":
				return "Release %s from %s" % [lord.name, province.name]
	
	return "Recruit Vassal"
