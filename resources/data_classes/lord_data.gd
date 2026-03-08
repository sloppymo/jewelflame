extends "res://resources/data_classes/character_data.gd"
class_name LordData
@export var age: int = 25
# is_captured, capture_family_id, loyalty inherited from CharacterData
@export var desertion_chance: float = 0.1
@export var monthly_loyalty_drift: int = 0

# Gemfire-specific stats (command_rating inherited from CharacterData)
@export var attack_rating: int = 50
@export var defense_rating: int = 50

# Battle formation preferences
@export var preferred_formation: String = "balanced"  # aggressive, defensive, balanced
@export var special_ability: String = ""  # rally, tactics, inspire

func calculate_loyalty_modifier() -> float:
	var base_mod = 1.0
	if loyalty < 30:
		base_mod = 0.5
	elif loyalty < 60:
		base_mod = 0.8
	elif loyalty > 90:
		base_mod = 1.2
	return base_mod

func check_desertion() -> bool:
	var chance = desertion_chance
	if loyalty < 30:
		chance *= 3.0
	elif loyalty < 60:
		chance *= 1.5
	return randf() < chance

func to_dict() -> Dictionary:
	var base_dict = super.to_dict()
	base_dict.merge({
		"age": age,
		"loyalty": loyalty,
		"is_captured": is_captured,
		"capture_family_id": capture_family_id,
		"desertion_chance": desertion_chance,
		"monthly_loyalty_drift": monthly_loyalty_drift,
		"attack_rating": attack_rating,
		"defense_rating": defense_rating,
		"command_rating": command_rating,
		"preferred_formation": preferred_formation,
		"special_ability": special_ability
	})
	return base_dict

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	age = data.get("age", 25)
	loyalty = data.get("loyalty", 100)
	is_captured = data.get("is_captured", false)
	capture_family_id = data.get("capture_family_id", "")
	desertion_chance = data.get("desertion_chance", 0.1)
	monthly_loyalty_drift = data.get("monthly_loyalty_drift", 0)
	attack_rating = data.get("attack_rating", 50)
	defense_rating = data.get("defense_rating", 50)
	command_rating = data.get("command_rating", 50)
	preferred_formation = data.get("preferred_formation", "balanced")
	special_ability = data.get("special_ability", "")
