class_name UnitData extends Resource
@export var unit_type: String = "knight"  # knight, horseman, archer, mage, special
@export var stack_size: int = 10
@export var experience: int = 0
@export var is_special_unit: bool = false
@export var special_creature_type: String = ""  # dragon, undead, elemental

# Combat stats
@export var attack_power: int = 10
@export var defense_power: int = 10
@export var movement: int = 3
@export var range: int = 1

# Formation bonuses
@export var flanking_bonus: float = 1.2
@export var rear_assault_bonus: float = 1.3

func get_unit_type_stats() -> Dictionary:
	match unit_type:
		"knight":
			return {"attack": 15, "defense": 12, "movement": 2, "range": 1}
		"horseman":
			return {"attack": 12, "defense": 8, "movement": 4, "range": 1}
		"archer":
			return {"attack": 8, "defense": 6, "movement": 3, "range": 3}
		"mage":
			return {"attack": 10, "defense": 4, "movement": 2, "range": 2}
		_:
			return {"attack": 10, "defense": 10, "movement": 3, "range": 1}

func calculate_effective_power() -> int:
	var stats = get_unit_type_stats()
	var base_power = (attack_power + stats.attack) * stack_size
	var experience_bonus = 1.0 + (experience / 100.0)
	return int(base_power * experience_bonus)

func to_dict() -> Dictionary:
	return {
		"unit_type": unit_type,
		"stack_size": stack_size,
		"experience": experience,
		"is_special_unit": is_special_unit,
		"special_creature_type": special_creature_type,
		"attack_power": attack_power,
		"defense_power": defense_power,
		"movement": movement,
		"range": range,
		"flanking_bonus": flanking_bonus,
		"rear_assault_bonus": rear_assault_bonus
	}

func from_dict(data: Dictionary) -> void:
	unit_type = data.get("unit_type", "knight")
	stack_size = data.get("stack_size", 10)
	experience = data.get("experience", 0)
	is_special_unit = data.get("is_special_unit", false)
	special_creature_type = data.get("special_creature_type", "")
	attack_power = data.get("attack_power", 10)
	defense_power = data.get("defense_power", 10)
	movement = data.get("movement", 3)
	range = data.get("range", 1)
	flanking_bonus = data.get("flanking_bonus", 1.2)
	rear_assault_bonus = data.get("rear_assault_bonus", 1.3)
