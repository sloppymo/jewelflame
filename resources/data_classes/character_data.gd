class_name CharacterData extends Resource

@export var id: String = ""
@export var name: String = ""
@export var family_id: String = ""
@export var portrait_path: String = "res://assets/portraits/placeholder.png"
@export var leadership: int = 50
@export var command: int = 50
@export var charm: int = 50
@export var is_ruler: bool = false
@export var is_lord: bool = false

# Fields used by LordData inheritance
@export var loyalty: int = 100
@export var is_captured: bool = false
@export var capture_family_id: String = ""
@export var command_rating: int = 50

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"family_id": family_id,
		"portrait_path": portrait_path,
		"leadership": leadership,
		"command": command,
		"charm": charm,
		"is_ruler": is_ruler,
		"is_lord": is_lord,
		"loyalty": loyalty,
		"is_captured": is_captured,
		"capture_family_id": capture_family_id,
		"command_rating": command_rating
	}

func from_dict(data: Dictionary) -> void:
	id = data.get("id", "")
	name = data.get("name", "")
	family_id = data.get("family_id", "")
	portrait_path = data.get("portrait_path", "res://assets/portraits/placeholder.png")
	leadership = data.get("leadership", 50)
	command = data.get("command", 50)
	charm = data.get("charm", 50)
	is_ruler = data.get("is_ruler", false)
	is_lord = data.get("is_lord", false)
	loyalty = data.get("loyalty", 100)
	is_captured = data.get("is_captured", false)
	capture_family_id = data.get("capture_family_id", "")
	command_rating = data.get("command_rating", 50)
