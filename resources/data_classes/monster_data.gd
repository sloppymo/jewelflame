class_name MonsterData extends Resource

@export var id: String = ""
@export var name: String = ""
@export var attack: int = 20
@export var defense: int = 20
@export var type: String = "normal"  # flying, earth, fire, water
@export var icon: Texture2D = null

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"attack": attack,
		"defense": defense,
		"type": type
	}

func from_dict(data: Dictionary) -> void:
	id = data.get("id", "")
	name = data.get("name", "")
	attack = data.get("attack", 20)
	defense = data.get("defense", 20)
	type = data.get("type", "normal")
