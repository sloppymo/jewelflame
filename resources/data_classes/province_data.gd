class_name ProvinceData extends Resource

@export var id: int = -1
@export var name: String = ""
@export var color_id: Color = Color.WHITE
@export var owner_id: String = ""
@export var governor_id: String = ""
@export var neighbors: Array[int] = []

@export var gold: int = 100
@export var food: int = 100
@export var soldiers: int = 50
@export var loyalty: int = 50
@export var cultivation: int = 0
@export var protection: int = 0

@export var terrain_type: String = "plains"
@export var is_capital: bool = false
@export var is_exhausted: bool = false
@export var polygon_points: PackedVector2Array = []

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"color_id": color_id.to_html(),
		"owner_id": owner_id,
		"governor_id": governor_id,
		"neighbors": neighbors.duplicate(),
		"gold": gold,
		"food": food,
		"soldiers": soldiers,
		"loyalty": loyalty,
		"cultivation": cultivation,
		"protection": protection,
		"terrain_type": terrain_type,
		"is_capital": is_capital,
		"is_exhausted": is_exhausted
	}

func from_dict(data: Dictionary) -> void:
	id = data.get("id", -1)
	name = data.get("name", "")
	color_id = Color.from_string(data.get("color_id", "ffffff"), Color.WHITE)
	owner_id = data.get("owner_id", "")
	governor_id = data.get("governor_id", "")
	neighbors = data.get("neighbors", []).duplicate()
	gold = data.get("gold", 100)
	food = data.get("food", 100)
	soldiers = data.get("soldiers", 50)
	loyalty = data.get("loyalty", 50)
	cultivation = data.get("cultivation", 0)
	protection = data.get("protection", 0)
	terrain_type = data.get("terrain_type", "plains")
	is_capital = data.get("is_capital", false)
	is_exhausted = data.get("is_exhausted", false)
