class_name StrategicProvince
extends Resource

## Dragon Force Strategic Province Data
## Represents a node on the strategic map

@export var id: StringName = &""
@export var province_name: String = ""
@export var map_position: Vector2 = Vector2.ZERO
@export var owner_faction: StringName = &""

# Visual
@export var color_code: Color = Color.WHITE
@export var is_castle: bool = true  # Most provinces are castles

# Gameplay (for future phases)
var stationed_general: StringName = &""
var troop_count: int = 100
var defense_level: int = 1

func _to_string() -> String:
	return "StrategicProvince(%s, owner=%s)" % [province_name, owner_faction]
