class_name FactionData extends Resource

@export var id: StringName
@export var faction_name: String
@export var color: Color = Color.WHITE
@export var gold: int = 800
@export var owned_province_ids: Array[StringName] = []
@export var is_player: bool = false

func get_total_troops(provinces: Dictionary[StringName, ProvinceData]) -> int:
	var total := 0
	for pid in owned_province_ids:
		if provinces.has(pid):
			total += provinces[pid].troops
	return total

func get_income(provinces: Dictionary[StringName, ProvinceData]) -> int:
	var income := 0
	for pid in owned_province_ids:
		if provinces.has(pid):
			income += provinces[pid].get_income()
	return income

func owns_province(province_id: StringName) -> bool:
	return province_id in owned_province_ids

func add_province(province_id: StringName) -> void:
	if not province_id in owned_province_ids:
		owned_province_ids.append(province_id)

func remove_province(province_id: StringName) -> void:
	owned_province_ids.erase(province_id)

# ============================================================================
# SERIALIZATION (for Save System)
# ============================================================================

func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"faction_name": faction_name,
		"color": {"r": color.r, "g": color.g, "b": color.b, "a": color.a},
		"gold": gold,
		"owned_province_ids": owned_province_ids.map(func(x): return String(x)),
		"is_player": is_player
	}

func from_dict(data: Dictionary) -> void:
	id = StringName(data.get("id", ""))
	faction_name = data.get("faction_name", "")
	
	var col = data.get("color", {})
	color = Color(col.get("r", 1.0), col.get("g", 1.0), col.get("b", 1.0), col.get("a", 1.0))
	
	gold = data.get("gold", 800)
	
	var province_ids = data.get("owned_province_ids", [])
	owned_province_ids.clear()
	for pid in province_ids:
		owned_province_ids.append(StringName(pid))
	
	is_player = data.get("is_player", false)
