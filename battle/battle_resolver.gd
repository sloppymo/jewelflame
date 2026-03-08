extends Node

const TERRAIN_BONUSES = {
	"plains": 1.0,
	"woods": 1.2,
	"river": 1.1,
	"mountain": 1.3
}

static func calculate_power(soldiers: int, commander_skill: int, terrain_bonus: float, is_defender: bool) -> float:
	var base_power = float(soldiers) * (float(commander_skill) / 50.0)
	var terrain_modifier = terrain_bonus
	var defense_modifier = 1.1 if is_defender else 1.0
	var random_factor = randf_range(0.8, 1.2)
	
	return base_power * terrain_modifier * defense_modifier * random_factor

static func resolve_province_attack(attacker_id: int, defender_id: int, attacking_soldiers: int) -> Dictionary:
	var attacker_province = GameState.provinces[attacker_id]
	var defender_province = GameState.provinces[defender_id]
	
	# Get commanders
	var attacker_commander = GameState.get_character(attacker_province.governor_id)
	var defender_commander = GameState.get_character(defender_province.governor_id)
	
	var attacker_command = attacker_commander.command if attacker_commander else 50
	var defender_command = defender_commander.command if defender_commander else 50
	
	# Calculate terrain bonuses
	var attacker_terrain_bonus = TERRAIN_BONUSES.get(attacker_province.terrain_type, 1.0)
	var defender_terrain_bonus = TERRAIN_BONUSES.get(defender_province.terrain_type, 1.0)
	
	# Calculate battle power
	var attacker_power = calculate_power(
		attacking_soldiers, attacker_command, attacker_terrain_bonus, false
	)
	var defender_power = calculate_power(
		defender_province.soldiers, defender_command, defender_terrain_bonus, true
	)
	
	# Determine winner
	var attacker_won = attacker_power > defender_power
	var power_ratio = min(attacker_power, defender_power) / max(attacker_power, defender_power)
	
	# Calculate casualties
	var attacker_casualties: int
	var defender_casualties: int
	
	if attacker_won:
		# Attacker wins - fewer casualties
		attacker_casualties = int(attacking_soldiers * (0.4 * (1.0 - power_ratio)))
		defender_casualties = int(defender_province.soldiers * (0.6 + (0.2 * power_ratio)))
	else:
		# Defender wins - attacker takes heavier losses
		attacker_casualties = int(attacking_soldiers * (0.7 + (0.1 * (1.0 - power_ratio))))
		defender_casualties = int(defender_province.soldiers * (0.3 * power_ratio))
	
	# Apply casualties
	var remaining_attackers = max(0, attacking_soldiers - attacker_casualties)
	var remaining_defenders = max(0, defender_province.soldiers - defender_casualties)
	
	# Calculate loot if attacker wins
	var loot_gold = 0
	var loot_food = 0
	var province_conquered = false
	var prisoner_taken = false
	
	if attacker_won and remaining_defenders == 0:
		province_conquered = true
		loot_gold = int(defender_province.gold * 0.3)
		loot_food = int(defender_province.food * 0.3)
		
		# Chance to capture governor
		if randf() < 0.2:  # 20% chance
			prisoner_taken = true
	
	# Prepare result
	var result = {
		"attacker_won": attacker_won,
		"attacker_casualties": attacker_casualties,
		"defender_casualties": defender_casualties,
		"remaining_attackers": remaining_attackers,
		"remaining_defenders": remaining_defenders,
		"loot_gold": loot_gold,
		"loot_food": loot_food,
		"province_conquered": province_conquered,
		"prisoner_taken": prisoner_taken,
		"attacker_power": attacker_power,
		"defender_power": defender_power
	}
	
	# Apply battle results to game state
	_apply_battle_results(attacker_id, defender_id, result)
	
	# Emit battle resolved signal
	EventBus.BattleResolved.emit(result)
	
	return result

static func _apply_battle_results(attacker_id: int, defender_id: int, result: Dictionary):
	var attacker_province = GameState.provinces[attacker_id]
	var defender_province = GameState.provinces[defender_id]
	
	# Apply casualties
	attacker_province.soldiers = result.remaining_attackers
	defender_province.soldiers = result.remaining_defenders
	
	# Handle province conquest
	if result.province_conquered:
		# Transfer ownership
		defender_province.owner_id = attacker_province.owner_id
		
		# Transfer loot
		attacker_province.gold += result.loot_gold
		attacker_province.food += result.loot_food
		defender_province.gold -= result.loot_gold
		defender_province.food -= result.loot_food
		
		# Handle prisoner
		if result.prisoner_taken:
			print("Governor captured in ", defender_province.name)
		
		# Mark attacker exhausted
		attacker_province.is_exhausted = true
		EventBus.ProvinceExhausted.emit(attacker_id, true)
		
		# Emit data change signals
		EventBus.ProvinceDataChanged.emit(defender_id, "owner_id", defender_province.owner_id)
		EventBus.ProvinceDataChanged.emit(attacker_id, "gold", attacker_province.gold)
		EventBus.ProvinceDataChanged.emit(defender_id, "gold", defender_province.gold)
	
	# Emit soldier count changes
	EventBus.ProvinceDataChanged.emit(attacker_id, "soldiers", attacker_province.soldiers)
	EventBus.ProvinceDataChanged.emit(defender_id, "soldiers", defender_province.soldiers)
