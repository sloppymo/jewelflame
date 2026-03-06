extends Node

func can_recruit(province_id: int, amount: int) -> bool:
	var province = GameState.provinces.get(province_id)
	if not province:
		return false
	if province.is_exhausted:
		return false
	if province.owner_id != GameState.player_family_id:
		return false
	var cost = amount * 2
	return province.gold >= cost

func can_develop(province_id: int, type: String) -> bool:
	var province = GameState.provinces.get(province_id)
	if not province or province.is_exhausted:
		return false
	if province.owner_id != GameState.player_family_id:
		return false
	return province.gold >= 10

func mark_exhausted(province_id: int):
	var province = GameState.provinces.get(province_id)
	if province:
		province.is_exhausted = true
		EventBus.ProvinceExhausted.emit(province_id, true)
