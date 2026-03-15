extends Node

const FactionData = preload("res://resources/data_classes/faction_data.gd")
const ProvinceData = preload("res://resources/data_classes/province_data.gd")

signal event_triggered(event_id: StringName, faction_id: StringName, message: String)
signal trade_event(faction_id: StringName, gold_bonus: int, income_bonus: int)
signal disaster_event(faction_id: StringName, province_id: StringName, troop_losses: int)
signal recruitment_event(faction_id: StringName, province_id: StringName, troops_gained: int)

const EVENT_TRADE_FLOURISHING := &"trade_flourishing"
const EVENT_PLAGUE_OUTBREAK := &"plague_outbreak"
const EVENT_BOUNTIFUL_HARVEST := &"bountiful_harvest"
const EVENT_BANDIT_RAID := &"bandit_raid"
const EVENT_MERCENARY_ARRIVAL := &"mercenary_arrival"

var event_templates: Dictionary[StringName, Dictionary] = {
	EVENT_TRADE_FLOURISHING: {
		"message": "Trade is flourishing in {province}. You receive {gold} gold and income increases by +{income} per turn.",
		"weight": 25
	},
	EVENT_PLAGUE_OUTBREAK: {
		"message": "Plague has struck {province}! {losses} troops have fallen ill and perished.",
		"weight": 20
	},
	EVENT_BOUNTIFUL_HARVEST: {
		"message": "A bountiful harvest in {province} brings prosperity. Gold +{gold}.",
		"weight": 25
	},
	EVENT_BANDIT_RAID: {
		"message": "Bandits have raided {province}! {losses} troops were killed defending the province.",
		"weight": 20
	},
	EVENT_MERCENARY_ARRIVAL: {
		"message": "Mercenaries have arrived in {province} seeking employment. {troops} troops added to your garrison.",
		"weight": 10
	}
}

func trigger_random_event(faction_id: StringName) -> void:
	if GameState == null:
		push_error("EventManager: GameState not available")
		return
	
	if not GameState.factions.has(faction_id):
		push_error("EventManager: Invalid faction ID: %s" % faction_id)
		return
	
	var faction = GameState.factions[faction_id]
	
	# Pick a random owned province
	if faction.owned_province_ids.is_empty():
		return
	
	var province_id: StringName = faction.owned_province_ids[randi() % faction.owned_province_ids.size()]
	if not GameState.provinces.has(province_id):
		return
	
	var province: ProvinceData = GameState.provinces[province_id]
	
	# Select random event based on weights
	var event_id := _select_weighted_event()
	_execute_event(event_id, faction_id, province_id, province)

func _select_weighted_event() -> StringName:
	var total_weight := 0
	for template in event_templates.values():
		total_weight += template.weight
	
	var roll := randi() % total_weight
	var current_weight := 0
	
	for event_id in event_templates:
		current_weight += event_templates[event_id].weight
		if roll < current_weight:
			return event_id
	
	return EVENT_TRADE_FLOURISHING

func _execute_event(event_id: StringName, faction_id: StringName, province_id: StringName, province: ProvinceData) -> void:
	var faction = GameState.factions[faction_id]
	var template: Dictionary = event_templates[event_id]
	var message: String
	
	match event_id:
		EVENT_TRADE_FLOURISHING:
			var gold_bonus := 50
			var income_bonus := 10
			faction.gold += gold_bonus
			province.base_income += income_bonus
			message = template.message.format({
				"province": province.province_name,
				"gold": gold_bonus,
				"income": income_bonus
			})
			trade_event.emit(faction_id, gold_bonus, income_bonus)
		
		EVENT_PLAGUE_OUTBREAK:
			var losses: int = max(10, province.troops / 4)
			province.troops -= losses
			if province.troops < GameConfig.MIN_GARRISON_SIZE:
				province.troops = GameConfig.MIN_GARRISON_SIZE
			message = template.message.format({
				"province": province.province_name,
				"losses": losses
			})
			disaster_event.emit(faction_id, province_id, losses)
		
		EVENT_BOUNTIFUL_HARVEST:
			var gold_bonus := 100
			faction.gold += gold_bonus
			message = template.message.format({
				"province": province.province_name,
				"gold": gold_bonus
			})
			trade_event.emit(faction_id, gold_bonus, 0)
		
		EVENT_BANDIT_RAID:
			var losses: int = max(5, province.troops / 5)
			province.troops -= losses
			if province.troops < GameConfig.MIN_GARRISON_SIZE:
				province.troops = GameConfig.MIN_GARRISON_SIZE
			message = template.message.format({
				"province": province.province_name,
				"losses": losses
			})
			disaster_event.emit(faction_id, province_id, losses)
		
		EVENT_MERCENARY_ARRIVAL:
			var troops_gained := 30
			province.troops += troops_gained
			message = template.message.format({
				"province": province.province_name,
				"troops": troops_gained
			})
			recruitment_event.emit(faction_id, province_id, troops_gained)
	
	event_triggered.emit(event_id, faction_id, message)
	
	# Display in sidebar if it's the player
	if faction.is_player:
		_display_event_message(message)

func _display_event_message(message: String) -> void:
	# Find sidebar and show message
	var sidebar = get_tree().get_first_node_in_group("sidebar")
	if sidebar and sidebar.has_method("show_event_message"):
		sidebar.show_event_message(message)

func trigger_specific_event(event_id: StringName, faction_id: StringName) -> void:
	if not event_templates.has(event_id):
		push_error("EventManager: Unknown event ID: %s" % event_id)
		return
	
	if GameState == null or not GameState.factions.has(faction_id):
		return
	
	var faction2 = GameState.factions[faction_id]
	if faction2.owned_province_ids.is_empty():
		return
	
	var province_id2: StringName = faction2.owned_province_ids[randi() % faction2.owned_province_ids.size()]
	if GameState.provinces.has(province_id2):
		_execute_event(event_id, faction_id, province_id2, GameState.provinces[province_id2])
