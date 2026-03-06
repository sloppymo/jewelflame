extends Node

static func get_province_safe(id: int) -> ProvinceData:
	var province = GameState.get_province(id)
	if not province:
		push_error("SafeAccess: Invalid province ID %d" % id)
		return null
	return province

static func get_character_safe(id: String) -> CharacterData:
	var character = GameState.get_character(id)
	if not character:
		push_error("SafeAccess: Invalid character ID %s" % id)
		return null
	return character

static func get_family_safe(id: String) -> FamilyData:
	var family = GameState.get_family(id)
	if not family:
		push_error("SafeAccess: Invalid family ID %s" % id)
		return null
	return family

static func get_enhanced_province_safe(id: int) -> ProvinceData:
	var province = GameState.get_province(id)
	if not province:
		push_error("SafeAccess: Invalid province ID %d" % id)
		return null
	return province

static func get_enhanced_character_safe(id: String) -> CharacterData:
	var character = GameState.get_character(id)
	if not character:
		push_error("SafeAccess: Invalid character ID %s" % id)
		return null
	return character

static func get_enhanced_family_safe(id: String) -> FamilyData:
	var family = GameState.get_family(id)
	if not family:
		push_error("SafeAccess: Invalid family ID %s" % id)
		return null
	return family

static func validate_province_id(id: int) -> bool:
	return id > 0 and id <= 5

static func validate_character_id(id: String) -> bool:
	return not id.is_empty() and id.length() <= 50

static func validate_family_id(id: String) -> bool:
	return not id.is_empty() and ["blanche", "lyle", "coryll"].has(id)

static func safe_get_province_terrain(province: ProvinceData) -> String:
	if not province:
		return "plains"
	return province.terrain_type if province.terrain_type else "plains"

static func safe_get_character_command_rating(character: CharacterData) -> int:
	if not character:
		return 50
	return character.command_rating if character.command_rating else 50

static func safe_get_province_soldiers(province: ProvinceData) -> int:
	if not province:
		return 0
	return province.soldiers if province.soldiers else 0

static func safe_get_province_gold(province: ProvinceData) -> int:
	if not province:
		return 0
	return province.gold if province.gold else 0

static func safe_get_province_food(province: ProvinceData) -> int:
	if not province:
		return 0
	return province.food if province.food else 0

static func safe_get_governor_id(province: ProvinceData) -> String:
	if not province:
		return ""
	return province.governor_id if province.governor_id else ""

static func safe_get_owner_id(province: ProvinceData) -> String:
	if not province:
		return ""
	return province.owner_id if province.owner_id else ""
