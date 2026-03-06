extends Node

func process_september_harvest():
	var province_yields = {}
	var total_yield = 0
	
	print("=== September Harvest ===")
	
	for province_id in GameState.provinces:
		var province = GameState.provinces[province_id]
		
		# Only harvest for player-owned provinces (UI display)
		if province.owner_id == GameState.player_family_id:
			var harvest_yield = calculate_province_yield(province)
			province_yields[province_id] = harvest_yield
			total_yield += harvest_yield
			
			# Add food to province
			province.food += harvest_yield
			EventBus.ProvinceDataChanged.emit(province_id, "food", province.food)
			
			print("Harvest in %s: +%d food (Cultivation: %d, Loyalty: %d)" % [
				province.name, harvest_yield, province.cultivation, province.loyalty
			])
	
	# Emit harvest report for UI
	EventBus.HarvestReportReady.emit(province_yields)
	
	print("Total September Harvest: %d food" % total_yield)
	print("=== End Harvest ===")

func calculate_province_yield(province: ProvinceData) -> int:
	# Formula: yield = cultivation * 2 * (loyalty/100)
	var base_yield = province.cultivation * 2
	var loyalty_modifier = float(province.loyalty) / 100.0
	
	return int(base_yield * loyalty_modifier)
