class_name BattleData extends Resource
# Preload dependencies
const UnitData = preload("res://resources/data_classes/unit_data.gd")
const LordData = preload("res://resources/data_classes/lord_data.gd")

@export var battle_id: String = ""
@export var attacking_province_id: int = -1
@export var defending_province_id: int = -1
@export var attacking_family_id: String = ""
@export var defending_family_id: String = ""

# Army compositions
@export var attacking_units: Array[UnitData] = []
@export var defending_units: Array[UnitData] = []

# Battle conditions
@export var terrain_type: String = "plains"
@export var weather_condition: String = "clear"  # clear, rain, fog, storm
@export var time_of_day: String = "day"  # day, night

# Commanders
@export var attacking_commander_id: String = ""
@export var defending_commander_id: String = ""

# Formation settings
@export var attacker_formation: String = "balanced"
@export var defender_formation: String = "balanced"

# Battle results (filled after resolution)
@export var battle_state: String = "pending"  # pending, in_progress, completed
@export var winner: String = ""  # attacker, defender
@export var attacker_casualties: Array[int] = []  # casualties per unit type
@export var defender_casualties: Array[int] = []
@export var battle_duration: int = 0  # rounds
@export var loot_gold: int = 0
@export var loot_food: int = 0
@export var captured_lords: Array[String] = []

func calculate_army_power(units: Array[UnitData], commander: LordData, terrain_bonus: float) -> float:
	var total_power = 0.0
	for unit in units:
		total_power += unit.calculate_effective_power()
	
	var commander_bonus = 1.0
	if commander:
		commander_bonus = 1.0 + (commander.command_rating / 100.0)
	
	return total_power * commander_bonus * terrain_bonus

func get_formation_bonus(formation: String, is_attacker: bool) -> float:
	match formation:
		"aggressive":
			return 1.3 if is_attacker else 0.9
		"defensive":
			return 0.9 if is_attacker else 1.3
		"balanced":
			return 1.1
		_:
			return 1.0

func get_weather_modifier() -> float:
	match weather_condition:
		"clear":
			return 1.0
		"rain":
			return 0.9  # Reduces ranged effectiveness
		"fog":
			return 0.8  # Reduces all combat
		"storm":
			return 0.7  # Heavy penalties
		_:
			return 1.0

func to_dict() -> Dictionary:
	return {
		"battle_id": battle_id,
		"attacking_province_id": attacking_province_id,
		"defending_province_id": defending_province_id,
		"attacking_family_id": attacking_family_id,
		"defending_family_id": defending_family_id,
		"attacking_units": attacking_units.map(func(u): return u.to_dict()),
		"defending_units": defending_units.map(func(u): return u.to_dict()),
		"terrain_type": terrain_type,
		"weather_condition": weather_condition,
		"time_of_day": time_of_day,
		"attacking_commander_id": attacking_commander_id,
		"defending_commander_id": defending_commander_id,
		"attacker_formation": attacker_formation,
		"defender_formation": defender_formation,
		"battle_state": battle_state,
		"winner": winner,
		"attacker_casualties": attacker_casualties,
		"defender_casualties": defender_casualties,
		"battle_duration": battle_duration,
		"loot_gold": loot_gold,
		"loot_food": loot_food,
		"captured_lords": captured_lords
	}

func from_dict(data: Dictionary) -> void:
	battle_id = data.get("battle_id", "")
	attacking_province_id = data.get("attacking_province_id", -1)
	defending_province_id = data.get("defending_province_id", -1)
	attacking_family_id = data.get("attacking_family_id", "")
	defending_family_id = data.get("defending_family_id", "")
	
	# Reconstruct unit arrays
	attacking_units.clear()
	for unit_data in data.get("attacking_units", []):
		var unit = UnitData.new()
		unit.from_dict(unit_data)
		attacking_units.append(unit)
	
	defending_units.clear()
	for unit_data in data.get("defending_units", []):
		var unit = UnitData.new()
		unit.from_dict(unit_data)
		defending_units.append(unit)
	
	terrain_type = data.get("terrain_type", "plains")
	weather_condition = data.get("weather_condition", "clear")
	time_of_day = data.get("time_of_day", "day")
	attacking_commander_id = data.get("attacking_commander_id", "")
	defending_commander_id = data.get("defending_commander_id", "")
	attacker_formation = data.get("attacker_formation", "balanced")
	defender_formation = data.get("defender_formation", "balanced")
	battle_state = data.get("battle_state", "pending")
	winner = data.get("winner", "")
	attacker_casualties = data.get("attacker_casualties", [])
	defender_casualties = data.get("defender_casualties", [])
	battle_duration = data.get("battle_duration", 0)
	loot_gold = data.get("loot_gold", 0)
	loot_food = data.get("loot_food", 0)
	captured_lords = data.get("captured_lords", [])
