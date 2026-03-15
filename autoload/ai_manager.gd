extends Node

const FactionData = preload("res://resources/data_classes/faction_data.gd")
const ProvinceData = preload("res://resources/data_classes/province_data.gd")

const ATTACK_ADVANTAGE_THRESHOLD := 1.5
const RECRUIT_TROOP_THRESHOLD := 100
const RECRUIT_GOLD_COST := 10
const MAX_RECRUIT_AMOUNT := 50

signal ai_action_started(faction_id: StringName, action: String)
signal ai_action_completed(faction_id: StringName, success: bool)

func take_turn(faction_id: StringName) -> void:
	if GameState == null:
		push_error("AIManager: GameState not available")
		return
	
	if not GameState.factions.has(faction_id):
		push_error("AI taking turn for invalid faction: %s" % faction_id)
		return
	
	var faction = GameState.factions[faction_id]
	
	# Get owned provinces safely
	var owned_provinces: Array[ProvinceData] = []
	for pid in faction.owned_province_ids:
		if GameState.provinces.has(pid):
			owned_provinces.append(GameState.provinces[pid])
	
	if owned_provinces.is_empty():
		push_warning("AI faction %s has no provinces" % faction_id)
		return
	
	# Phase 1: Recruitment
	await _process_recruitment(faction, owned_provinces)
	
	# Phase 2: Movement (consolidate forces)
	await _process_movement(faction, owned_provinces)
	
	# Phase 3: Attacks
	await _process_attacks(faction, owned_provinces)

func _process_recruitment(faction: FactionData, provinces: Array[ProvinceData]):
	for province in provinces:
		if province.troops < RECRUIT_TROOP_THRESHOLD and faction.gold >= RECRUIT_GOLD_COST:
			var max_affordable: int = faction.gold / RECRUIT_GOLD_COST
			var amount := mini(MAX_RECRUIT_AMOUNT, max_affordable)
			
			if amount > 0:
				ai_action_started.emit(faction.id, "recruit")
				
				faction.gold -= amount * RECRUIT_GOLD_COST
				province.troops += amount
				
				await get_tree().create_timer(0.2).timeout
				ai_action_completed.emit(faction.id, true)

func _process_movement(faction: FactionData, provinces: Array[ProvinceData]):
	# Simple consolidation: Move troops from weak provinces to strong ones
	for source in provinces:
		if source.troops <= GameConfig.AI_MIN_GARRISON:
			continue  # Don't strip garrisons
		
		for adj_id in source.adjacent_province_ids:
			if not GameState.provinces.has(adj_id):
				continue
			
			var target: ProvinceData = GameState.provinces[adj_id]
			
			# Only move to owned, understrength provinces
			if target.owner_faction_id == faction.id and target.troops < source.troops:
				var amount: int = mini(source.troops - GameConfig.AI_MIN_GARRISON, GameConfig.AI_MAX_MOVE_AMOUNT)
				if amount > 0:
					ai_action_started.emit(faction.id, "move")
					
					source.troops -= amount
					target.troops += amount
					
					await get_tree().create_timer(0.3).timeout
					ai_action_completed.emit(faction.id, true)
				break  # One move per source province

func _process_attacks(faction: FactionData, provinces: Array[ProvinceData]):
	for source in provinces:
		var attack_made := false
		
		for adj_id in source.adjacent_province_ids:
			if not GameState.provinces.has(adj_id):
				continue
			
			var target: ProvinceData = GameState.provinces[adj_id]
			
			# Skip owned or empty
			if target.owner_faction_id == faction.id or target.owner_faction_id == &"":
				continue
			
			# Check advantage
			var my_power := float(source.troops)
			var their_power: float = float(target.troops) * target.get_defense_bonus()
			
			if my_power > their_power * ATTACK_ADVANTAGE_THRESHOLD:
				ai_action_started.emit(faction.id, "attack")
				
				CombatResolver.resolve_battle(
					faction.id,
					target.owner_faction_id,
					source.id,
					target.id
				)
				
				await get_tree().create_timer(0.5).timeout
				ai_action_completed.emit(faction.id, true)
				attack_made = true
				break  # One attack per source province
		
		if attack_made:
			await get_tree().create_timer(0.2).timeout
