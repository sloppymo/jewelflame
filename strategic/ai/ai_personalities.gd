class_name AIPersonalities

enum PersonalityType {
	AGGRESSIVE,
	DEFENSIVE,
	OPPORTUNISTIC,
	TACTICAL
}

const WEIGHTS = {
	"aggressive": {
		"attack_threshold": 0.8,
		"defend_threshold": 1.5,
		"develop_threshold": 0.6,
		"risk_tolerance": 1.0,
		"recruit_priority": 0.7,
		"attack_priority": 0.9
	},
	"defensive": {
		"attack_threshold": 1.2,
		"defend_threshold": 1.0,
		"develop_threshold": 0.8,
		"risk_tolerance": 2.0,
		"recruit_priority": 0.8,
		"attack_priority": 0.4
	},
	"opportunistic": {
		"attack_threshold": 1.0,
		"defend_threshold": 1.3,
		"develop_threshold": 0.7,
		"risk_tolerance": 1.5,
		"recruit_priority": 0.6,
		"attack_priority": 0.7
	}
}

static func evaluate_attack_utility(our_strength: int, enemy_strength: int, personality: String) -> float:
	var weights = WEIGHTS.get(personality, WEIGHTS["aggressive"])
	var strength_ratio = float(our_strength) / float(enemy_strength) if enemy_strength > 0 else 2.0
	
	# Base utility from strength ratio
	var utility = strength_ratio
	
	# Apply personality-based risk tolerance
	if strength_ratio < weights.attack_threshold:
		utility *= 0.2  # Heavily penalize weak attacks
	elif strength_ratio > weights.defend_threshold:
		utility *= 1.5  # Bonus for strong positions
	
	# Apply risk tolerance modifier
	utility *= weights.risk_tolerance
	
	return clamp(utility, 0.0, 2.0)

static func evaluate_defense_priority(province_soldiers: int, neighboring_enemies: int, personality: String) -> float:
	var weights = WEIGHTS.get(personality, WEIGHTS["aggressive"])
	
	# Threat assessment
	var threat_level = float(neighboring_enemies) / float(province_soldiers) if province_soldiers > 0 else 2.0
	
	# Defensive priority based on personality
	if personality == "defensive":
		return threat_level * 1.5
	elif personality == "aggressive":
		return threat_level * 0.7
	else:  # opportunistic
		return threat_level * 1.0

static func should_recruit(province_soldiers: int, gold_available: int, personality: String) -> bool:
	var weights = WEIGHTS.get(personality, WEIGHTS["aggressive"])
	
	# Basic recruitment check
	if gold_available < 100:  # Cost for 50 soldiers
		return false
	
	# Personality-based recruitment decisions
	if personality == "defensive":
		return province_soldiers < 80  # Maintain strong garrisons
	elif personality == "aggressive":
		return province_soldiers < 120  # Build large armies
	else:  # opportunistic
		return province_soldiers < 60 and gold_available > 200  # Balanced approach

static func should_develop(province: ProvinceData, personality: String) -> bool:
	var weights = WEIGHTS.get(personality, WEIGHTS["aggressive"])
	
	# Basic development check
	if province.gold < 10:
		return false
	
	# Personality-based development priorities
	if personality == "defensive":
		return province.protection < 50  # Focus on fortifications
	elif personality == "aggressive":
		return province.cultivation < 30  # Basic economy only
	else:  # opportunistic
		return province.cultivation < 70 or province.protection < 40  # Balanced development

static func choose_target_province(attacker_id: int, potential_targets: Array, personality: String) -> int:
	var best_target = -1
	var best_utility = -1.0
	
	for target_id in potential_targets:
		var attacker_province = GameState.provinces[attacker_id]
		var target_province = GameState.provinces[target_id]
		
		var utility = evaluate_attack_utility(
			attacker_province.soldiers,
			target_province.soldiers,
			personality
		)
		
		# Prefer weaker targets for opportunistic
		if personality == "opportunistic":
			utility += (100.0 - target_province.soldiers) / 100.0
		
		# Prefer capitals for aggressive
		if personality == "aggressive" and target_province.is_capital:
			utility += 0.5
		
		if utility > best_utility:
			best_utility = utility
			best_target = target_id
	
	return best_target
