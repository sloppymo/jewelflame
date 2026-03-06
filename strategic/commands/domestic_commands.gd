extends Node

func execute_develop(province_id: int, type: String) -> bool:
	if not CommandProcessor.can_develop(province_id, type):
		print("Cannot develop: validation failed")
		return false
	
	var province = GameState.provinces[province_id]
	var governor = GameState.get_character(province.governor_id)
	
	province.gold -= 10
	
	var leadership_bonus = int(governor.leadership / 20) if governor else 0
	var increase = randi_range(2, 5) + leadership_bonus
	
	if type == "cultivation":
		province.cultivation = mini(200, province.cultivation + increase)
		EventBus.ProvinceDataChanged.emit(province_id, "cultivation", province.cultivation)
	elif type == "protection":
		province.protection = mini(200, province.protection + increase)
		EventBus.ProvinceDataChanged.emit(province_id, "protection", province.protection)
	
	if randf() < 0.1:
		print("Random event triggered in ", province.name, "!")
	
	CommandProcessor.mark_exhausted(province_id)
	print("Developed ", type, " in ", province.name, " by ", increase, " points")
	return true
