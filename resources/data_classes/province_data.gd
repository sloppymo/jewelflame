class_name ProvinceData extends Resource

@export var id: StringName
@export var province_name: String
@export var defense_level: int = 1
@export var base_income: int = 100
@export var owner_faction_id: StringName = &""
@export var governor_id: StringName = &""  # ID of the CharacterData governing this province
@export var troops: int = 0
@export var adjacent_province_ids: Array[StringName] = []

# Visual/Position data
@export var map_position: Vector2 = Vector2.ZERO
@export var color_code: Color = Color.WHITE  # For color ID map technique

# Game state
@export var is_exhausted: bool = false  # Has acted this turn

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

func has_governor() -> bool:
	return governor_id != &""

func get_governor() -> CharacterData:
	var lm = Engine.get_singleton("LordManager")
	if lm:
		return lm.get_character(governor_id)
	return null

# ============================================================================
# SERIALIZATION (for Save System)
# ============================================================================

func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"province_name": province_name,
		"defense_level": defense_level,
		"base_income": base_income,
		"owner_faction_id": String(owner_faction_id),
		"troops": troops,
		"adjacent_province_ids": adjacent_province_ids.map(func(x): return String(x)),
		"map_position": {"x": map_position.x, "y": map_position.y},
		"color_code": {"r": color_code.r, "g": color_code.g, "b": color_code.b, "a": color_code.a}
	}

func from_dict(data: Dictionary) -> void:
	id = StringName(data.get("id", ""))
	province_name = data.get("province_name", "")
	defense_level = data.get("defense_level", 1)
	base_income = data.get("base_income", 100)
	owner_faction_id = StringName(data.get("owner_faction_id", ""))
	troops = data.get("troops", 0)
	
	var adj_ids = data.get("adjacent_province_ids", [])
	adjacent_province_ids.clear()
	for adj_id in adj_ids:
		adjacent_province_ids.append(StringName(adj_id))
	
	var pos = data.get("map_position", {})
	map_position = Vector2(pos.get("x", 0.0), pos.get("y", 0.0))
	
	var col = data.get("color_code", {})
	color_code = Color(col.get("r", 1.0), col.get("g", 1.0), col.get("b", 1.0), col.get("a", 1.0))
