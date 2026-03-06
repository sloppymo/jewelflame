extends Node

func process_monthly_upkeep():
	print("=== Monthly Upkeep ===")
	
	for province_id in GameState.provinces:
		var province = GameState.provinces[province_id]
		
		# Calculate food requirement: 1 food per 10 soldiers
		var food_required = int(province.soldiers / 10)
		var food_deficit = 0
		
		if province.food < food_required:
			food_deficit = food_required - province.food
			
			# Soldiers desert due to starvation
			var deserters = min(province.soldiers, food_deficit * 2)
			province.soldiers -= deserters
			
			# Loyalty drops due to supply issues
			province.loyalty = max(0, province.loyalty - 10)
			
			print("Supply shortage in %s: %d soldiers deserted, loyalty -10" % [
				province.name, deserters
			])
			
			EventBus.ProvinceDataChanged.emit(province_id, "soldiers", province.soldiers)
			EventBus.ProvinceDataChanged.emit(province_id, "loyalty", province.loyalty)
		
		# Consume food
		province.food = max(0, province.food - food_required)
		EventBus.ProvinceDataChanged.emit(province_id, "food", province.food)
		
		if food_deficit > 0:
			print("%s: %d food deficit, %d soldiers lost" % [
				province.name, food_deficit, deserters
			])
		else:
			print("%s: %d food consumed" % [province.name, food_required])
	
	print("=== End Upkeep ===")
