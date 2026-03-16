class_name CharacterData extends Resource

# Unique identifier for this character
@export var id: StringName = &""

# Basic info
@export var name: String = ""
@export var family_id: StringName = &""  # Which faction they belong to
@export var portrait_path: String = "res://assets/portraits/placeholder.png"

# Stats (0-100 scale)
@export var leadership: int = 50   # Affects troop morale, province loyalty
@export var command: int = 50      # Affects combat effectiveness
@export var charm: int = 50        # Affects diplomacy, recruitment cost

# Role
@export var is_ruler: bool = false     # Is this the faction leader?
@export var is_lord: bool = true       # Is this a noble (can govern provinces)?

# Current status
@export var loyalty: int = 100         # Loyalty to their faction (0-100)
@export var is_captured: bool = false  # Are they currently a prisoner?
@export var captured_by: StringName = &""  # Which faction captured them
@export var governor_of: StringName = &""  # Which province they govern (if any)

# Combat bonus (derived from command stat)
var command_rating: int:
	get:
		return command

func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"name": name,
		"family_id": String(family_id),
		"portrait_path": portrait_path,
		"leadership": leadership,
		"command": command,
		"charm": charm,
		"is_ruler": is_ruler,
		"is_lord": is_lord,
		"loyalty": loyalty,
		"is_captured": is_captured,
		"captured_by": String(captured_by),
		"governor_of": String(governor_of)
	}

func from_dict(data: Dictionary) -> void:
	id = StringName(data.get("id", ""))
	name = data.get("name", "")
	family_id = StringName(data.get("family_id", ""))
	portrait_path = data.get("portrait_path", "res://assets/portraits/placeholder.png")
	leadership = data.get("leadership", 50)
	command = data.get("command", 50)
	charm = data.get("charm", 50)
	is_ruler = data.get("is_ruler", false)
	is_lord = data.get("is_lord", true)
	loyalty = data.get("loyalty", 100)
	is_captured = data.get("is_captured", false)
	captured_by = StringName(data.get("captured_by", ""))
	governor_of = StringName(data.get("governor_of", ""))
