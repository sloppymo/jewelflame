class_name FamilyData extends Resource

@export var id: String = ""
@export var name: String = ""
@export var color: Color = Color.WHITE
@export var ruler_id: String = ""
@export var owned_provinces: Array[int] = []
@export var is_player: bool = false
@export var ai_personality: String = "aggressive"
@export var is_defeated: bool = false

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"color": color.to_html(),
		"ruler_id": ruler_id,
		"owned_provinces": owned_provinces.duplicate(),
		"is_player": is_player,
		"ai_personality": ai_personality,
		"is_defeated": is_defeated
	}

func from_dict(data: Dictionary) -> void:
	id = data.get("id", "")
	name = data.get("name", "")
	color = Color.from_string(data.get("color", "ffffff"), Color.WHITE)
	ruler_id = data.get("ruler_id", "")
	owned_provinces = data.get("owned_provinces", []).duplicate()
	is_player = data.get("is_player", false)
	ai_personality = data.get("ai_personality", "aggressive")
	is_defeated = data.get("is_defeated", false)
