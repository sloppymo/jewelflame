class_name EquipmentData extends Resource

@export var id: String = ""
@export var name: String = ""
@export var slot: String = "weapon"  # weapon, armor, accessory
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var command_bonus: int = 0
@export var icon: Texture2D = null

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"slot": slot,
		"attack_bonus": attack_bonus,
		"defense_bonus": defense_bonus,
		"command_bonus": command_bonus
	}

func from_dict(data: Dictionary) -> void:
	id = data.get("id", "")
	name = data.get("name", "")
	slot = data.get("slot", "weapon")
	attack_bonus = data.get("attack_bonus", 0)
	defense_bonus = data.get("defense_bonus", 0)
	command_bonus = data.get("command_bonus", 0)
