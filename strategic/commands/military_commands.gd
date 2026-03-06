extends Node

func execute_recruit(province_id: int, amount: int) -> bool:
	if not CommandProcessor.can_recruit(province_id, amount):
		print("Cannot recruit: validation failed")
		return false
	
	var province = GameState.provinces[province_id]
	var cost = amount * 2
	
	province.gold -= cost
	province.soldiers += amount
	CommandProcessor.mark_exhausted(province_id)
	
	print("Recruited ", amount, " soldiers in ", province.name, " for ", cost, " gold")
	EventBus.ProvinceDataChanged.emit(province_id, "soldiers", province.soldiers)
	return true
