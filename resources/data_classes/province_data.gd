class_name ProvinceData extends Resource

@export var id: StringName
@export var province_name: String
@export var defense_level: int = 1
@export var base_income: int = 100
@export var owner_faction_id: StringName = &""
@export var troops: int = 0
@export var adjacent_province_ids: Array[StringName] = []

# Visual/Position data
@export var map_position: Vector2 = Vector2.ZERO
@export var color_code: Color = Color.WHITE  # For color ID map technique

func get_income() -> int:
	return base_income + (defense_level - 1) * 50

func get_defense_bonus() -> float:
	return 1.0 + (defense_level - 1) * 0.2

func get_development_cost() -> int:
	return int(200 * pow(1.5, defense_level - 1))

func is_adjacent_to(other_id: StringName) -> bool:
	return other_id in adjacent_province_ids

func has_owner() -> bool:
	return owner_faction_id != &""

func upgrade_defense() -> bool:
	if defense_level < 5:
		defense_level += 1
		return true
	return false
