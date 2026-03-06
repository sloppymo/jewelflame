extends Node

const DISASTER_CHANCE = 0.05  # 5% per month
const POSITIVE_CHANCE = 0.10  # 10% on develop

func trigger_monthly_events():
	for province_id in GameState.provinces:
		var province = GameState.provinces[province_id]
		
		# Random disasters
		if randf() < DISASTER_CHANCE:
			trigger_disaster(province_id)
		
		# Positive events (only on developed provinces)
		if province.cultivation > 20 or province.protection > 20:
			if randf() < POSITIVE_CHANCE:
				trigger_positive_event(province_id)

func trigger_disaster(province_id: int):
	var province = GameState.provinces[province_id]
	var disaster_type = randi() % 4
	
	match disaster_type:
		0:  # Flood
			print("DISASTER: Flood strikes %s!" % province.name)
			province.cultivation = max(0, province.cultivation - randi_range(5, 15))
			province.loyalty = max(0, province.loyalty - 5)
			EventBus.ProvinceDataChanged.emit(province_id, "cultivation", province.cultivation)
			EventBus.ProvinceDataChanged.emit(province_id, "loyalty", province.loyalty)
			
		1:  # Plague
			print("DISASTER: Plague outbreak in %s!" % province.name)
			var plague_deaths = int(province.soldiers * randf_range(0.1, 0.3))
			province.soldiers = max(10, province.soldiers - plague_deaths)
			EventBus.ProvinceDataChanged.emit(province_id, "soldiers", province.soldiers)
			
		2:  # Fire
			print("DISASTER: Fire ravages %s!" % province.name)
			province.protection = max(0, province.protection - randi_range(10, 25))
			province.gold = max(0, province.gold - randi_range(20, 50))
			EventBus.ProvinceDataChanged.emit(province_id, "protection", province.protection)
			EventBus.ProvinceDataChanged.emit(province_id, "gold", province.gold)
			
		3:  # Snow
			print("DISASTER: Heavy snowfall in %s!" % province.name)
			province.food = max(0, province.food - randi_range(15, 40))
			province.loyalty = max(0, province.loyalty - 8)
			EventBus.ProvinceDataChanged.emit(province_id, "food", province.food)
			EventBus.ProvinceDataChanged.emit(province_id, "loyalty", province.loyalty)

func trigger_positive_event(province_id: int):
	var province = GameState.provinces[province_id]
	var event_type = randi() % 3
	
	match event_type:
		0:  # Unicorn sighting
			print("POSITIVE: Unicorn sighted near %s! Leadership improves." % province.name)
			var governor = GameState.get_character(province.governor_id)
			if governor:
				governor.leadership = min(100, governor.leadership + randi_range(3, 8))
				print("Governor %s leadership increased to %d" % [governor.name, governor.leadership])
			
		1:  # Leprechaun's gold
			print("POSITIVE: Leprechaun's treasure found in %s!" % province.name)
			var gold_found = randi_range(30, 80)
			province.gold += gold_found
			EventBus.ProvinceDataChanged.emit(province_id, "gold", province.gold)
			print("%s gained %d gold!" % [province.name, gold_found])
			
		2:  # Gwraig's blessing
			print("POSITIVE: Gwraig blesses %s! Charm improves." % province.name)
			var governor = GameState.get_character(province.governor_id)
			if governor:
				governor.charm = min(100, governor.charm + randi_range(5, 12))
				print("Governor %s charm increased to %d" % [governor.name, governor.charm])
