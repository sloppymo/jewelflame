class_name IntelSystem

func get_visible_soldiers(province_id: int, observer_family_id: String) -> int:
	var province = GameState.provinces.get(province_id)
	if not province:
		return -1
	
	if province.owner_id == observer_family_id:
		return province.soldiers
	
	for neighbor_id in province.neighbors:
		var neighbor = GameState.provinces.get(neighbor_id)
		if neighbor and neighbor.owner_id == observer_family_id:
			return province.soldiers
	
	return -1

func can_see_details(province_id: int, observer_family_id: String) -> bool:
	return get_visible_soldiers(province_id, observer_family_id) != -1

func get_intel_description(province_id: int, observer_family_id: String) -> String:
	var soldiers = get_visible_soldiers(province_id, observer_family_id)
	if soldiers == -1:
		return "Unknown Force"
	elif soldiers < 50:
		return "Small Garrison (" + str(soldiers) + ")"
	elif soldiers < 150:
		return "Medium Force (" + str(soldiers) + ")"
	else:
		return "Large Army (" + str(soldiers) + ")"
