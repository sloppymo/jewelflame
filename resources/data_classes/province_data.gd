class_name ProvinceData extends Resource

# Type reference for UnitData
const UnitData = preload("res://resources/data_classes/unit_data.gd")

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
@export var morale: int = 70
@export var cultivation: int = 0
@export var protection: int = 0
@export var is_exhausted: bool = false

# Gemfire-specific resources
@export var mana: int = 50
@export var transport_capacity: int = 100
@export var garrison_limit: int = 200

# Unit composition (replaces simple soldiers)
@export var stationed_units: Array[UnitData] = []

# Lord management
@export var stationed_lord_id: String = ""
@export var prisoner_lords: Array[String] = []

# Terrain and weather
@export var terrain_type: String = "plains"
@export var current_weather: String = "clear"
@export var weather_duration: int = 1
@export var is_capital: bool = false
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
		"mana": mana,
		"transport_capacity": transport_capacity,
		"garrison_limit": garrison_limit,
		"stationed_units": stationed_units.map(func(u): return u.to_dict()),
		"stationed_lord_id": stationed_lord_id,
		"prisoner_lords": prisoner_lords.duplicate(),
		"terrain_type": terrain_type,
		"current_weather": current_weather,
		"weather_duration": weather_duration,
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
	mana = data.get("mana", 50)
	transport_capacity = data.get("transport_capacity", 100)
	garrison_limit = data.get("garrison_limit", 200)
	
	# Reconstruct unit arrays
	stationed_units.clear()
	for unit_data in data.get("stationed_units", []):
		var unit = UnitData.new()
		unit.from_dict(unit_data)
		stationed_units.append(unit)
	
	stationed_lord_id = data.get("stationed_lord_id", "")
	prisoner_lords = data.get("prisoner_lords", []).duplicate()
	terrain_type = data.get("terrain_type", "plains")
	current_weather = data.get("current_weather", "clear")
	weather_duration = data.get("weather_duration", 1)
	is_capital = data.get("is_capital", false)
	is_exhausted = data.get("is_exhausted", false)

# Helper methods for Gemfire mechanics
func get_total_military_power() -> int:
	var total = soldiers
	for unit in stationed_units:
		total += unit.stack_size
	return total

func can_support_more_units() -> bool:
	return get_total_military_power() < garrison_limit

func get_terrain_defense_bonus() -> float:
	match terrain_type:
		"plains": return 1.0
		"woods": return 1.2
		"river": return 1.1
		"mountain": return 1.3
		_: return 1.0

func process_weather_change():
	weather_duration -= 1
	if weather_duration <= 0:
		# Random weather change
		var weather_options = ["clear", "rain", "fog", "storm"]
		current_weather = weather_options[randi() % weather_options.size()]
		weather_duration = randi_range(1, 3)
