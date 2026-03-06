extends Node

const TERRAIN_BONUSES = {
	"plains": 1.0,
	"woods": 1.2,
	"river": 1.1,
	"mountain": 1.3
}

static func calculate_power(soldiers: int, commander_skill: int, terrain_bonus: float, is_defender: bool) -> float:
	var base_power = float(soldiers) * (float(commander_skill) / 50.0)
	
	# Use balanced terrain bonuses
	terrain_bonus = GameBalanceConfig.get_terrain_bonus("plains") if terrain_bonus == 1.0 else terrain_bonus
	
	var defender_bonus = GameBalanceConfig.COMBAT_BALANCE.casualties.defender_bonus if is_defender else 1.0
	var commander_bonus = GameBalanceConfig.get_commander_bonus(commander_skill)
	var random_factor = 1.0 + (randf() - 0.5) * GameBalanceConfig.COMBAT_BALANCE.random_factor_range
	
	return base_power * terrain_bonus * defender_bonus * commander_bonus * random_factor

static func resolve_province_attack(attacker_id: int, defender_id: int, attacking_soldiers: int) -> Dictionary:
	# Validate inputs
	if not SafeAccess.validate_province_id(attacker_id):
		return ErrorHandler.handle_invalid_province(attacker_id, "resolve_province_attack")
	if not SafeAccess.validate_province_id(defender_id):
		return ErrorHandler.handle_invalid_province(defender_id, "resolve_province_attack")
	if attacking_soldiers <= 0:
		return ErrorHandler.handle_command_execution("resolve_province_attack", "Invalid attacking soldiers count")
	
	var attacker_province = SafeAccess.get_enhanced_province_safe(attacker_id)
	var defender_province = SafeAccess.get_enhanced_province_safe(defender_id)
	
	if not attacker_province:
		return ErrorHandler.handle_invalid_province(attacker_id, "resolve_province_attack")
	
	if not defender_province:
		return ErrorHandler.handle_invalid_province(defender_id, "resolve_province_attack")
	
	# Get commanders safely
	var attacker_commander_id = SafeAccess.safe_get_governor_id(attacker_province)
	var defender_commander_id = SafeAccess.safe_get_governor_id(defender_province)
	
	var attacker_commander = SafeAccess.get_enhanced_character_safe(attacker_commander_id) if not attacker_commander_id.is_empty() else null
	var defender_commander = SafeAccess.get_enhanced_character_safe(defender_commander_id) if not defender_commander_id.is_empty() else null
	
	var attacker_command = SafeAccess.safe_get_character_command_rating(attacker_commander)
	var defender_command = SafeAccess.safe_get_character_command_rating(defender_commander)
	
	# Calculate terrain bonuses safely
	var attacker_terrain_bonus = TERRAIN_BONUSES.get(SafeAccess.safe_get_province_terrain(attacker_province), 1.0)
	var defender_terrain_bonus = TERRAIN_BONUSES.get(SafeAccess.safe_get_province_terrain(defender_province), 1.0)
	
	# Calculate battle power
	var attacker_power = calculate_power(
		attacking_soldiers, attacker_command, attacker_terrain_bonus, false
	)
	var defender_power = calculate_power(
		SafeAccess.safe_get_province_soldiers(defender_province), defender_command, defender_terrain_bonus, true
	)
	
	# Determine winner
	var attacker_won = attacker_power > defender_power
	var power_ratio = min(attacker_power, defender_power) / max(attacker_power, defender_power)
	
	# Calculate casualties using balanced values
	var dominance = attacker_power / (attacker_power + defender_power)
	
	# Use balanced casualty calculations
	var attacker_casualty_rate = GameBalanceConfig.calculate_casualties(attacker_won, dominance)
	var defender_casualty_rate = GameBalanceConfig.calculate_casualties(!attacker_won, 1.0 - dominance)
	
	var attacker_casualties = int(attacking_soldiers * attacker_casualty_rate)
	var defender_casualties = int(SafeAccess.safe_get_province_soldiers(defender_province) * defender_casualty_rate)
	
	# Apply casualties
	var remaining_attackers = max(0, attacking_soldiers - attacker_casualties)
	var remaining_defenders = max(0, SafeAccess.safe_get_province_soldiers(defender_province) - defender_casualties)
	
	# Calculate loot if attacker wins
	var loot_gold = 0
	var loot_food = 0
	var province_conquered = false
	var prisoner_taken = false
	
	if attacker_won and remaining_defenders == 0:
		province_conquered = true
		loot_gold = int(SafeAccess.safe_get_province_gold(defender_province) * 0.3)
		loot_food = int(SafeAccess.safe_get_province_food(defender_province) * 0.3)
		
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
	var attacker_province = SafeAccess.get_enhanced_province_safe(attacker_id)
	var defender_province = SafeAccess.get_enhanced_province_safe(defender_id)
	
	if not attacker_province or not defender_province:
		ErrorHandler.handle_null_reference("province data", "_apply_battle_results")
		return
	
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
			
			# Add captured lord to battle result
			var governor_id = SafeAccess.safe_get_governor_id(defender_province)
			if not governor_id.is_empty():
				result.captured_lords = [governor_id]
				
				# Mark lord as captured
				var captured_lord = SafeAccess.get_enhanced_character_safe(governor_id)
				if captured_lord and captured_lord.has_method("set") and captured_lord.get("is_captured") != null:
					captured_lord.is_captured = true
					captured_lord.capture_family_id = SafeAccess.safe_get_owner_id(attacker_province)
					captured_lord.loyalty = 20  # Reduced loyalty when captured
		
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

static func resolve_auto_battle(battle: BattleData) -> Dictionary:
	# Use existing resolve_province_attack logic adapted for BattleData
	var total_attacking_units = 0
	for unit in battle.attacking_units:
		total_attacking_units += unit.stack_size
	
	var result = resolve_province_attack(
		battle.attacking_province_id,
		battle.defending_province_id,
		total_attacking_units
	)
	
	# Add BattleData specific results
	if result.has("province_conquered") and result.province_conquered:
		battle.battle_state = "completed"
		battle.winner = "attacker"
		battle.loot_gold = result.get("loot_gold", 0)
		battle.loot_food = result.get("loot_food", 0)
		battle.captured_lords = result.get("captured_lords", [])
	else:
		battle.battle_state = "completed"
		battle.winner = "defender" if not result.get("attacker_won", false) else "attacker"
	
	return result
