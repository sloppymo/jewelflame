extends Node

# AI Personality Balance Adjustments
const AI_BALANCE = {
	"lyle": {  # Aggressive - Slightly toned down for balance
		"attack_threshold": 0.75,      # Reduced from 0.7 for better balance
		"risk_tolerance": 0.9,         # Reduced from 0.8 (slightly more cautious)
		"recruit_preference": 0.85,    # Reduced from 0.9 (more balanced)
		"develop_preference": 0.35,     # Increased from 0.3 (slight development)
		"attack_frequency": 0.8,       # New: How often to prioritize attacks
		"defensive_bonus": 0.85,       # Improved from 0.8 (slightly better defense)
		"target_priority": "weakest",
		"retreat_threshold": 0.35      # Increased from 0.3 (less likely to retreat)
	},
	"coryll": {  # Opportunistic - Enhanced for better challenge
		"attack_threshold": 0.95,      # Reduced from 1.0 (more aggressive)
		"risk_tolerance": 1.1,         # Reduced from 1.2 (slightly more cautious)
		"recruit_preference": 0.75,     # Increased from 0.7 (more recruitment)
		"develop_preference": 0.65,     # Increased from 0.6 (more development)
		"attack_frequency": 0.6,       # New: Moderate attack frequency
		"defensive_bonus": 1.05,       # Improved from 1.0 (better defense)
		"target_priority": "isolated",
		"retreat_threshold": 0.45      # Increased from 0.4 (less retreat)
	},
	"blanche": {  # Player/Defensive - Enhanced for better experience
		"attack_threshold": 1.15,      # Reduced from 1.2 (slightly more aggressive)
		"risk_tolerance": 1.8,         # Reduced from 2.0 (more willing to take risks)
		"recruit_preference": 0.65,     # Increased from 0.6 (more recruitment)
		"develop_preference": 0.85,     # Increased from 0.8 (strong development)
		"attack_frequency": 0.4,       # New: Low attack frequency
		"defensive_bonus": 1.35,       # Improved from 1.3 (strong defense)
		"target_priority": "nearest",
		"retreat_threshold": 0.65      # Increased from 0.6 (earlier retreat)
	}
}

# Economic Balance
const ECONOMY_BALANCE = {
	"recruit_cost_per_troop": 1.8,     # Reduced from 2.0 (more affordable)
	"recruit_batch_size": 50,           # Standard recruitment size
	"develop_cost": 8,                 # Reduced from 10 (more accessible)
	"monthly_food_per_troop": 0.8,     # Reduced from 1.0 (less harsh)
	"desertion_food_multiplier": 1.5,   # Reduced from 2.0 (less punishing)
	"harvest_base_yield": 25,           # Base harvest per cultivation point
	"harvest_loyalty_multiplier": 1.2,  # Loyalty bonus to harvest
	"transport_cost_per_distance": 5,   # New: Transport logistics cost
	"max_garrison_percentage": 0.8      # New: Can't garrison more than 80% of limit
}

# Combat Balance
const COMBAT_BALANCE = {
	"terrain_bonuses": {
		"plains": 1.0,
		"woods": 1.15,      # Reduced from 1.2
		"river": 1.08,      # Reduced from 1.1
		"mountain": 1.25    # Reduced from 1.3
	},
	"unit_type_stats": {
		"knight": {"attack": 14, "defense": 13, "movement": 2, "range": 1, "cost": 2.0},
		"horseman": {"attack": 13, "defense": 9, "movement": 4, "range": 1, "cost": 2.2},
		"archer": {"attack": 9, "defense": 7, "movement": 3, "range": 3, "cost": 1.5},
		"mage": {"attack": 11, "defense": 5, "movement": 2, "range": 2, "cost": 2.5}
	},
	"casualties": {
		"winner_min": 0.15,      # Reduced from 0.2
		"winner_max": 0.35,      # Reduced from 0.4
		"loser_min": 0.55,       # Reduced from 0.6
		"loser_max": 0.75,       # Reduced from 0.8
		"defender_bonus": 1.05   # Reduced from 1.1
	},
	"commander_bonus": {
		"low_command": 1.05,     # Reduced from flat 1.0 + command/50
		"medium_command": 1.15,
		"high_command": 1.25,
		"max_bonus": 1.3
	},
	"random_factor_range": 0.3,      # Reduced from 0.4 (less randomness)
	"formation_bonuses": {
		"aggressive_attacker": 1.25,
		"aggressive_defender": 0.95,
		"defensive_attacker": 0.95,
		"defensive_defender": 1.25,
		"balanced": 1.1
	}
}

# Vassal System Balance
const VASSAL_BALANCE = {
	"capture_chance_base": 0.18,        # Reduced from 0.2
	"capture_chance_commander": 0.05,   # New: Commander bonus to capture
	"recruitment_cost": 80,             # Reduced from 100
	"recruitment_loyalty_requirement": 65, # Reduced from 70
	"loyalty_drift_per_month": 2,       # New: Natural loyalty changes
	"desertion_threshold": 25,           # Reduced from 30
	"desertion_chance_base": 0.15,      # New: Base desertion chance
	"loyalty_bonuses": {
		"victory": 5,                      # New: Victory increases loyalty
		"defeat": -8,                      # New: Defeat decreases loyalty
		"good_economy": 3,                 # New: Strong economy increases loyalty
		"poor_economy": -5,                # New: Weak economy decreases loyalty
		"captured": -15                    # Captured lords lose loyalty
	}
}

# Victory and Game Pace Balance
const GAME_PACE_BALANCE = {
	"starting_provinces_per_family": 1,  # Current setup
	"total_provinces": 5,
	"victory_provinces_needed": 4,       # Reduced from 5 (faster games)
	"victory_turn_limit": 100,           # New: Maximum turns before draw
	"ai_turn_delay": 1.0,                # Seconds between AI actions
	"battle_animation_speed": 1.5,        # Battle pacing
	"initial_resources": {
		"gold": 120,                        # Increased from 100
		"food": 120,                        # Increased from 100
		"soldiers": 60,                     # Increased from 50
		"mana": 75                          # Increased from 50
	},
	"monthly_events": {
		"disaster_chance": 0.04,           # Reduced from 0.05
		"positive_chance": 0.12,          # Increased from 0.1
		"harvest_bonus_chance": 0.15       # New: Bonus harvest events
	}
}

# Difficulty Scaling
const DIFFICULTY_SCALING = {
	"easy": {
		"player_bonus": 1.2,
		"ai_penalty": 0.8,
		"resource_bonus": 1.3
	},
	"normal": {
		"player_bonus": 1.0,
		"ai_penalty": 1.0,
		"resource_bonus": 1.0
	},
	"hard": {
		"player_bonus": 0.8,
		"ai_penalty": 1.2,
		"resource_bonus": 0.8
	}
}

# Helper Functions for Balance Calculations
static func get_ai_config(family_id: String) -> Dictionary:
	return AI_BALANCE.get(family_id.to_lower(), AI_BALANCE.coryll)

static func calculate_unit_cost(unit_type: String) -> float:
	return COMBAT_BALANCE.unit_type_stats.get(unit_type, {}).get("cost", 2.0)

static func get_terrain_bonus(terrain: String) -> float:
	return COMBAT_BALANCE.terrain_bonuses.get(terrain, 1.0)

static func calculate_casualties(is_winner: bool, dominance: float) -> float:
	var casualties = COMBAT_BALANCE.casualties
	
	if is_winner:
		return casualties.winner_min + (casualties.winner_max - casualties.winner_min) * (1.0 - dominance)
	else:
		return casualties.loser_min + (casualties.loser_max - casualties.loser_min) * dominance

static func get_commander_bonus(command_rating: int) -> float:
	var bonuses = COMBAT_BALANCE.commander_bonus
	
	if command_rating < 40:
		return bonuses.low_command
	elif command_rating < 60:
		return bonuses.medium_command
	else:
		return min(bonuses.high_command, bonuses.max_bonus)

static func calculate_desertion_chance(loyalty: int, economic_factor: float) -> float:
	var base_chance = VASSAL_BALANCE.desertion_chance_base
	
	if loyalty < VASSAL_BALANCE.desertion_threshold:
		base_chance *= 3.0
	elif loyalty < 50:
		base_chance *= 1.5
	
	base_chance *= economic_factor  # Economic factor: 0.5-2.0
	return min(base_chance, 0.8)  # Cap at 80%

static func get_victory_conditions() -> Dictionary:
	return {
		"province_victory": GAME_PACE_BALANCE.victory_provinces_needed,
		"turn_limit": GAME_PACE_BALANCE.victory_turn_limit,
		"elimination_victory": true
	}

# Balance Validation Functions
static func validate_balance() -> Dictionary:
	var report = {
		"ai_balance": validate_ai_balance(),
		"economy_balance": validate_economy_balance(),
		"combat_balance": validate_combat_balance(),
		"overall_balance": "BALANCED"
	}
	
	# Check overall balance
	var issues = []
	for category in report:
		if category != "overall_balance" and report[category] != "BALANCED":
			issues.append(category)
	
	if issues.size() > 0:
		report.overall_balance = "NEEDS_ADJUSTMENT: " + ", ".join(issues)
	
	return report

static func validate_ai_balance() -> String:
	var lyle = AI_BALANCE.lyle
	var coryll = AI_BALANCE.coryll
	
	# Check if AI personalities are distinct enough
	if abs(lyle.attack_threshold - coryll.attack_threshold) < 0.1:
		return "AI_PERSONALITIES_TOO_SIMILAR"
	
	# Check if thresholds are reasonable
	if lyle.attack_threshold < 0.5 or coryll.attack_threshold > 1.5:
		return "AI_THRESHOLDS_UNREASONABLE"
	
	return "BALANCED"

static func validate_economy_balance() -> String:
	var recruit_cost = ECONOMY_BALANCE.recruit_cost_per_troop * ECONOMY_BALANCE.recruit_batch_size
	var develop_cost = ECONOMY_BALANCE.develop_cost
	
	# Check if costs are reasonable
	if recruit_cost > 150:
		return "RECRUITMENT_TOO_EXPENSIVE"
	
	if develop_cost > 20:
		return "DEVELOPMENT_TOO_EXPENSIVE"
	
	return "BALANCED"

static func validate_combat_balance() -> String:
	var terrain_max = 0.0
	var terrain_min = 2.0
	
	for bonus in COMBAT_BALANCE.terrain_bonuses.values():
		terrain_max = max(terrain_max, bonus)
		terrain_min = min(terrain_min, bonus)
	
	# Check terrain bonus range
	if terrain_max - terrain_min > 0.3:
		return "TERRAIN_BONUSES_TOO_EXTREME"
	
	return "BALANCED"
