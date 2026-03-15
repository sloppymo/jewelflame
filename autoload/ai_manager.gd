extends Node

const FactionData = preload("res://resources/data_classes/faction_data.gd")
const ProvinceData = preload("res://resources/data_classes/province_data.gd")

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
	var personality = _get_personality(faction_id)
	
	# Get owned provinces safely
	var owned_provinces: Array[ProvinceData] = []
	for pid in faction.owned_province_ids:
		if GameState.provinces.has(pid):
			owned_provinces.append(GameState.provinces[pid])
	
	if owned_provinces.is_empty():
		push_warning("AI faction %s has no provinces" % faction_id)
		return
	
	# Phase 1: Recruitment (with personality-based threshold)
	await _process_recruitment(faction, owned_provinces, personality)
	
	# Phase 2: Movement (consolidate forces)
	await _process_movement(faction, owned_provinces, personality)
	
	# Phase 3: Attacks (with personality-based threshold)
	await _process_attacks(faction, owned_provinces, personality)

func _get_personality(faction_id: StringName) -> Dictionary:
	return GameConfig.AI_PERSONALITIES.get(faction_id, GameConfig.AI_PERSONALITIES[&"blanche"])

func _process_recruitment(faction: FactionData, provinces: Array[ProvinceData], personality: Dictionary):
	var recruit_threshold: int = personality.get("recruit_threshold", 100)
	var recruit_bias: float = personality.get("recruit_bias", 1.0)
	var defense_focus: bool = personality.get("defense_focus", false)
	
	for province in provinces:
		# Apply recruit bias to threshold (higher bias = recruit more often)
		var effective_threshold = int(recruit_threshold / recruit_bias)
		
		if province.troops < effective_threshold and faction.gold >= RECRUIT_GOLD_COST:
			var max_affordable: int = faction.gold / RECRUIT_GOLD_COST
			var amount := mini(MAX_RECRUIT_AMOUNT, max_affordable)
			
			if amount > 0:
				ai_action_started.emit(faction.id, "recruit")
				
				faction.gold -= amount * RECRUIT_GOLD_COST
				province.troops += amount
				
				await get_tree().create_timer(0.2).timeout
				ai_action_completed.emit(faction.id, true)

func _process_movement(faction: FactionData, provinces: Array[ProvinceData], personality: Dictionary):
	var expansion_focus: bool = personality.get("expansion_focus", false)
	
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

func _process_attacks(faction: FactionData, provinces: Array[ProvinceData], personality: Dictionary):
	var attack_threshold: float = personality.get("attack_threshold", 1.5)
	var expansion_focus: bool = personality.get("expansion_focus", false)
	
	# Sort provinces by troop count if expansion focused (attack with strongest first)
	var sorted_provinces = provinces.duplicate()
	if expansion_focus:
		sorted_provinces.sort_custom(func(a, b): return a.troops > b.troops)
	
	for source in sorted_provinces:
		var attack_made := false
		
		for adj_id in source.adjacent_province_ids:
			if not GameState.provinces.has(adj_id):
				continue
			
			var target: ProvinceData = GameState.provinces[adj_id]
			
			# Skip owned or empty
			if target.owner_faction_id == faction.id or target.owner_faction_id == &"":
				continue
			
			# Check advantage with personality-based threshold
			var my_power := float(source.troops)
			var their_power: float = float(target.troops) * target.get_defense_bonus()
			
			if my_power > their_power * attack_threshold:
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
