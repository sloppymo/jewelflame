extends Node

# AI Personality System for Gemfire
# Note: class_name AIPersonalities is defined in ai_personalities.gd
# This file provides additional AI functionality without conflicting class names

enum PersonalityType {
	AGGRESSIVE,      # Lyle - High attack threshold, low risk tolerance
	DEFENSIVE,       # Blanche (Player) - High defense, cautious
	OPPORTUNISTIC,   # Coryll - Balanced, seeks weak targets
	TACTICAL         # Advanced tactical AI
}

# Personality weights and thresholds
const PERSONALITY_CONFIGS = {
	PersonalityType.AGGRESSIVE: {
		"attack_threshold": 0.7,      # Attack with 70% of enemy strength
		"risk_tolerance": 0.8,         # Willing to take risks
		"recruit_preference": 0.9,    # Heavy recruitment focus
		"develop_preference": 0.3,     # Low development focus
		"defensive_bonus": 0.8,       # Poor defensive positioning
		"formation_preference": "aggressive",
		"target_priority": "weakest",  # Attacks weakest targets
		"retreat_threshold": 0.3      # Retreats when badly outmatched
	},
	PersonalityType.DEFENSIVE: {
		"attack_threshold": 1.2,      # Attack with 120% of enemy strength
		"risk_tolerance": 2.0,         # Very risk-averse
		"recruit_preference": 0.6,     # Moderate recruitment
		"develop_preference": 0.8,     # High development focus
		"defensive_bonus": 1.3,       # Strong defensive positioning
		"formation_preference": "defensive",
		"target_priority": "nearest",  # Defends nearby threats
		"retreat_threshold": 0.6      # Retreats early
	},
	PersonalityType.OPPORTUNISTIC: {
		"attack_threshold": 1.0,      # Attack with equal strength
		"risk_tolerance": 1.2,         # Moderate risk tolerance
		"recruit_preference": 0.7,     # Balanced recruitment
		"develop_preference": 0.6,     # Balanced development
		"defensive_bonus": 1.0,       # Average positioning
		"formation_preference": "balanced",
		"target_priority": "isolated", # Attacks isolated targets
		"retreat_threshold": 0.4      # Moderate retreat
	},
	PersonalityType.TACTICAL: {
		"attack_threshold": 0.9,      # Slight advantage preferred
		"risk_tolerance": 1.0,         # Calculated risks
		"recruit_preference": 0.8,     # Smart recruitment
		"develop_preference": 0.7,     # Smart development
		"defensive_bonus": 1.1,       # Good positioning
		"formation_preference": "adaptive", # Changes based on situation
		"target_priority": "strategic", # Attacks high-value targets
		"retreat_threshold": 0.5      # Calculated retreats
	}
}

# Strategic AI Decision Making
class StrategicAI extends Node:
	var family_id: String = ""
	var personality_type: PersonalityType = PersonalityType.AGGRESSIVE
	var config: Dictionary = {}
	
	func _init(family: String, personality: PersonalityType):
		family_id = family
		personality_type = personality
		config = GameBalanceConfig.get_ai_config(family)
		
	# Main strategic decision function
	func make_strategic_decision() -> Dictionary:
		var decisions = {
			"attacks": [],
			"recruitments": [],
			"developments": [],
			"movements": []
		}
		
		var family_provinces = get_family_provinces()
		
		for province in family_provinces:
			if province.is_exhausted:
				continue
			
			var province_decisions = evaluate_province_actions(province)
			
			# Execute best action for this province
			if not province_decisions.is_empty():
				var prioritized_actions = prioritize_actions(province_decisions, province)
				var best_action = prioritized_actions[0]
				execute_province_action(best_action, province, decisions)
		
		return decisions
	
	func evaluate_province_actions(province) -> Array[Dictionary]:
		var actions = []
		
		# Evaluate attack opportunities
		var attack_actions = evaluate_attack_opportunities(province)
		actions.append_array(attack_actions)
		
		# Evaluate recruitment needs
		var recruit_actions = evaluate_recruitment_needs(province)
		actions.append_array(recruit_actions)
		
		# Evaluate development opportunities
		var develop_actions = evaluate_development_opportunities(province)
		actions.append_array(develop_actions)
		
		# Evaluate lord movements
		var movement_actions = evaluate_lord_movements(province)
		actions.append_array(movement_actions)
		
		return actions
	
	func evaluate_attack_opportunities(province) -> Array[Dictionary]:
		var attacks = []
		
		for neighbor_id in province.neighbors:
			var neighbor = EnhancedGameState.get_province(neighbor_id)
			if not neighbor or neighbor.owner_id == family_id:
				continue
			
			var attack_strength = calculate_province_strength(province)
			var defense_strength = calculate_province_strength(neighbor)
			var strength_ratio = float(attack_strength) / float(defense_strength)
			
			# Apply personality modifiers
			var terrain_bonus = neighbor.get_terrain_defense_bonus()
			var modified_ratio = strength_ratio / terrain_bonus
			
			if modified_ratio >= config.attack_threshold:
				var utility = calculate_attack_utility(province, neighbor, modified_ratio)
				attacks.append({
					"type": "attack",
					"target_province": neighbor_id,
					"utility": utility,
					"strength_ratio": modified_ratio,
					"risk_level": calculate_attack_risk(province, neighbor)
				})
		
		return attacks
	
	func evaluate_recruitment_needs(province) -> Array[Dictionary]:
		var recruitments = []
		
		var current_strength = calculate_province_strength(province)
		var max_strength = province.garrison_limit
		var strength_ratio = float(current_strength) / float(max_strength)
		
		# Need recruitment if below threshold
		if strength_ratio < config.recruit_preference:
			var urgency = 1.0 - strength_ratio
			var cost = calculate_recruitment_cost(province)
			var can_afford = province.gold >= cost
			
			if can_afford:
				recruitments.append({
					"type": "recruit",
					"utility": urgency * config.recruit_preference,
					"cost": cost,
					"can_afford": can_afford
				})
		
		return recruitments
	
	func evaluate_development_opportunities(province) -> Array[Dictionary]:
		var developments = []
		
		# Evaluate cultivation vs protection based on personality
		var cultivation_need = 1.0 - (province.cultivation / 100.0)
		var protection_need = 1.0 - (province.protection / 100.0)
		
		var develop_type = "cultivation"
		if config.develop_preference > 0.7:
			develop_type = "protection"
		elif cultivation_need < protection_need:
			develop_type = "protection"
		
		var utility = max(cultivation_need, protection_need) * config.develop_preference
		var cost = 10  # Base development cost
		
		if province.gold >= cost:
			developments.append({
				"type": "develop",
				"development_type": develop_type,
				"utility": utility,
				"cost": cost
			})
		
		return developments
	
	func prioritize_actions(actions: Array[Dictionary], province) -> Array[Dictionary]:
		# Sort by utility (descending)
		var sort_func = func(a, b): return a.get("utility", 0) > b.get("utility", 0)
		actions.sort_custom(sort_func)
		return actions
	
	func execute_province_action(action: Dictionary, province, decisions: Dictionary):
		match action.type:
			"attack":
				decisions.attacks.append({
					"province_id": province.id,
					"target_province": action.target_province,
					"forces": calculate_attack_forces(province, action.target_province)
				})
			"recruit":
				decisions.recruitments.append({
					"province_id": province.id,
					"amount": 50
				})
			"develop":
				decisions.developments.append({
					"province_id": province.id,
					"type": action.development_type
				})

# Tactical AI Decision Making
class TacticalAI extends Node:
	var battle_data = null
	var personality_type = PersonalityType.AGGRESSIVE
	var config: Dictionary = {}
	
	func _init(battle, personality: PersonalityType):
		battle_data = battle
		personality_type = personality
		config = PERSONALITY_CONFIGS[personality_type]
	
	# Main tactical decision function
	func make_tactical_decisions() -> Dictionary:
		var decisions = {
			"formation": choose_formation(),
			"target_priorities": determine_target_priorities(),
			"special_abilities": determine_special_ability_usage(),
			"retreat_decision": should_retreat()
		}
		
		return decisions
	
	func choose_formation() -> String:
		if config.formation_preference == "adaptive":
			return choose_adaptive_formation()
		return config.formation_preference
	
	func choose_adaptive_formation() -> String:
		var enemy_strength = calculate_enemy_strength()
		var our_strength = calculate_our_strength()
		var strength_ratio = float(our_strength) / float(enemy_strength)
		
		if strength_ratio > 1.3:
			return "aggressive"
		elif strength_ratio < 0.7:
			return "defensive"
		else:
			return "balanced"
	
	func determine_target_priorities() -> Array[String]:
		var priorities = []
		
		match config.target_priority:
			"weakest":
				priorities = ["enemy_archers", "enemy_mages", "enemy_horsemen", "enemy_knights"]
			"strongest":
				priorities = ["enemy_knights", "enemy_horsemen", "enemy_mages", "enemy_archers"]
			"strategic":
				priorities = ["enemy_commanders", "enemy_special_units", "enemy_ranged", "enemy_melee"]
			_:
				priorities = ["enemy_knights", "enemy_archers", "enemy_horsemen", "enemy_mages"]
		
		return priorities
	
	func determine_special_ability_usage() -> Dictionary:
		var abilities = {}
		
		# Check if commander has special abilities
		var commander = EnhancedGameState.get_character(battle_data.attacking_commander_id)
		if commander and commander.is_lord:
			match commander.special_ability:
				"rally":
					abilities["rally"] = should_use_rally()
				"tactics":
					abilities["tactics"] = should_use_tactics()
				"inspire":
					abilities["inspire"] = should_use_inspire()
		
		return abilities
	
	func should_retreat() -> bool:
		var our_strength = calculate_our_strength()
		var enemy_strength = calculate_enemy_strength()
		var strength_ratio = float(our_strength) / float(enemy_strength)
		
		return strength_ratio < config.retreat_threshold

# Helper Functions - these need to be in the main AIPersonalities class
# But the original code had them at wrong indentation level
# Moving them to be instance methods of AIPersonalities

var family_id: String = ""
var personality_type: PersonalityType = PersonalityType.AGGRESSIVE
var config: Dictionary = {}

func setup(family: String, personality: PersonalityType):
	family_id = family
	personality_type = personality
	config = PERSONALITY_CONFIGS[personality_type]

func get_family_provinces() -> Array:
	var provinces = []
	for province in EnhancedGameState.provinces.values():
		if province.owner_id == family_id:
			provinces.append(province)
	return provinces

func calculate_province_strength(province) -> int:
	var strength = province.soldiers
	
	# Add unit strength
	for unit in province.stationed_units:
		strength += unit.stack_size
	
	# Add commander bonus
	if province.stationed_lord_id != "":
		var lord = EnhancedGameState.get_character(province.stationed_lord_id)
		if lord and lord.is_lord:
			strength = int(strength * (1.0 + lord.command_rating / 100.0))
	
	return strength

func calculate_attack_utility(attacker, defender, strength_ratio: float) -> float:
	var base_utility = strength_ratio
	
	# Strategic value modifiers
	if defender.is_capital:
		base_utility *= 1.5
	
	# Resource value modifiers
	var resource_value = (defender.gold + defender.food) / 200.0
	base_utility += resource_value * 0.1
	
	# Personality risk adjustment
	base_utility *= (2.0 - config.risk_tolerance)
	
	return base_utility

func calculate_attack_risk(attacker, defender) -> float:
	var risk = 0.0
	
	# Terrain risk
	var terrain_bonus = defender.get_terrain_defense_bonus()
	risk += (terrain_bonus - 1.0) * 0.5
	
	# Force size risk
	var attacker_strength = calculate_province_strength(attacker)
	var defender_strength = calculate_province_strength(defender)
	var strength_ratio = float(attacker_strength) / float(defender_strength)
	
	if strength_ratio < 1.0:
		risk += (1.0 - strength_ratio) * 0.8
	
	return min(risk, 1.0)

func calculate_attack_forces(province, target_province_id: int) -> Dictionary:
	var attacker_strength = min(province.soldiers, 100)
	var target_province = EnhancedGameState.get_province(target_province_id)
	var defender_strength = target_province.soldiers if target_province else 50
	return {
		"attacker_strength": attacker_strength,
		"defender_strength": defender_strength,
		"units": []  # Empty units array for now
	}

func calculate_recruitment_cost(province) -> int:
	return GameBalanceConfig.ECONOMY_BALANCE.recruit_cost_per_troop * 50

func execute_ai_lord_command(lord, family):
	# Process AI lord commands through command system
	print("Executing AI command for lord: ", lord.name)
	
	# Get lord's province
	var province = get_lord_province(lord.id)
	if not province:
		return
	
	# Make strategic decision for this lord's province
	var decisions = make_strategic_decision()
	
	# Execute the best decision
	if not decisions.get("attacks", []).is_empty():
		var attack = decisions.attacks[0]
		BattleResolver.resolve_province_attack(
			attack.province_id,
			attack.target_province,
			attack.forces
		)
	elif not decisions.get("recruitments", []).is_empty():
		var recruitment = decisions.recruitments[0]
		MilitaryCommands.execute_recruit(recruitment.province_id, recruitment.amount)
	elif not decisions.get("developments", []).is_empty():
		var development = decisions.developments[0]
		DomesticCommands.execute_develop(development.province_id, development.type)

func get_lord_province(lord_id: String):
	for province in EnhancedGameState.provinces.values():
		if province.governor_id == lord_id:
			return province
	return null

func evaluate_lord_movements(province) -> Array[Dictionary]:
	var movements = []
	
	# Simple movement evaluation - move lords to strengthen borders
	var lord = EnhancedGameState.get_character(province.governor_id)
	if not lord or not lord.is_lord:
		return movements
	
	# Check if province is underdefended
	if province.soldiers < 30:
		# Look for nearby friendly provinces with excess troops
		for neighbor_id in province.neighbors:
			var neighbor = EnhancedGameState.get_province(neighbor_id)
			if neighbor and neighbor.owner_id == family_id and neighbor.soldiers > 80:
				movements.append({
					"type": "movement",
					"target_province": neighbor_id,
					"utility": 0.5,
					"reason": "reinforce_weak_province"
				})
	
	return movements

# Stub functions for tactical AI
func calculate_enemy_strength() -> int:
	return 100

func calculate_our_strength() -> int:
	return 100

func should_use_rally() -> bool:
	return false

func should_use_tactics() -> bool:
	return false

func should_use_inspire() -> bool:
	return false

# Main strategic decision function - needs to be here for the class
func make_strategic_decision() -> Dictionary:
	var decisions = {
		"attacks": [],
		"recruitments": [],
		"developments": [],
		"movements": []
	}
	return decisions
