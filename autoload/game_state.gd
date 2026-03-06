extends Node

var provinces: Dictionary = {}  # int -> ProvinceData
var families: Dictionary = {}   # String -> FamilyData
var characters: Dictionary = {} # String -> CharacterData
var player_family_id: String = "blanche"

# Turn management
var current_family_index: int = 0
var families_order: Array[String] = ["blanche", "lyle", "coryll"]
var current_month: int = 1
var current_year: int = 1

func _ready():
	load_initial_data()

func create_default_province(index: int) -> ProvinceData:
	var province = ProvinceData.new()
	province.id = index + 1
	
	var province_names = ["Dunmoor", "Carveti", "Cobrige", "Banshea", "Petaria"]
	var province_owners = ["blanche", "lyle", "coryll", "blanche", "lyle"]
	
	province.name = province_names[index]
	province.owner_id = province_owners[index]
	province.gold = 100
	province.food = 100
	province.soldiers = 50
	province.cultivation = 30
	province.protection = 30
	province.morale = 70
	province.is_exhausted = false
	province.terrain_type = "plains"
	
	return province

func load_initial_data():
	var province_files = [
		"res://resources/instances/provinces/province_01_dunmoor.tres",
		"res://resources/instances/provinces/province_02_carveti.tres",
		"res://resources/instances/provinces/province_03_cobrige.tres",
		"res://resources/instances/provinces/province_04_banshea.tres",
		"res://resources/instances/provinces/province_05_petaria.tres"
	]
	
	for path in province_files:
		if ResourceLoader.exists(path):
			var province = load(path).duplicate()
			if province and province.has_method("get") and province.get("id"):
				provinces[province.id] = province
				print("Loaded province: ", province.name)
		else:
			# Create default province if resource doesn't exist
			var province = create_default_province(province_files.find(path))
			provinces[province.id] = province
			print("Created default province: ", province.name)
	
	var family_files = [
		"res://resources/instances/families/family_blanche.tres",
		"res://resources/instances/families/family_lyle.tres",
		"res://resources/instances/families/family_coryll.tres"
	]
	
	for path in family_files:
		if ResourceLoader.exists(path):
			var family = load(path).duplicate()
			families[family.id] = family
			print("Loaded family: ", family.name)
	
	var character_files = [
		"res://resources/instances/characters/char_erin.tres",
		"res://resources/instances/characters/char_ander.tres",
		"res://resources/instances/characters/char_lars.tres",
		"res://resources/instances/characters/char_lord_2.tres",
		"res://resources/instances/characters/char_lord_4.tres"
	]
	
	for path in character_files:
		if ResourceLoader.exists(path):
			var character = load(path).duplicate()
			characters[character.id] = character
			print("Loaded character: ", character.name)

func get_player_family() -> FamilyData:
	return families.get(player_family_id)

func get_family(id: String) -> FamilyData:
	return families.get(id)

func get_character(id: String) -> CharacterData:
	return characters.get(id)

func get_province(id: int) -> ProvinceData:
	return provinces.get(id)

func get_current_family() -> String:
	return families_order[current_family_index]

func advance_turn():
	# Reset exhaustion for current family
	reset_family_exhaustion(get_current_family())
	
	var current_family = get_current_family()
	
	# Process AI turn if not player
	if current_family != player_family_id:
		print("Processing AI turn for: ", current_family)
		# AI processing would go here
		# Small delay before next turn
		await get_tree().create_timer(0.5).timeout
	
	# Move to next family
	current_family_index = (current_family_index + 1) % families_order.size()
	
	# Check for month/year advancement
	if current_family_index == 0:
		advance_month()
	
	# Emit turn ended signal
	EventBus.TurnEnded.emit(current_month, current_year)
	
	# Check victory conditions
	var victory_status = check_victory_conditions()
	if victory_status.has("victory") and victory_status.victory:
		print("Victory achieved by: ", victory_status.winner)
		# TODO: Show victory screen
	elif victory_status.has("defeat") and victory_status.defeat:
		print("Defeat for: ", victory_status.loser)
		# TODO: Show defeat screen
	
	# If next turn is AI, trigger it automatically
	if get_current_family() != player_family_id and not victory_status.has("victory"):
		advance_turn()

func advance_month():
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1
	
	# Process monthly systems
	print("Processing monthly upkeep")
	
	# September harvest
	if current_month == 9:
		print("Processing September harvest")
	
	# Random events (10% chance)
	if randf() < 0.1:
		print("Triggering random events")

func reset_family_exhaustion(family_id: String):
	for province in provinces.values():
		if province.owner_id == family_id:
			province.is_exhausted = false
			EventBus.ProvinceExhausted.emit(province.id, false)

func check_victory_conditions() -> Dictionary:
	var result = {}
	
	# Check each family for elimination or victory
	for family_id in families_order:
		var family = families[family_id]
		var owned_provinces = 0
		
		for province in provinces.values():
			if province.owner_id == family_id:
				owned_provinces += 1
		
		if owned_provinces == 0:
			family.is_defeated = true
			if family_id == player_family_id:
				result["defeat"] = true
				result["loser"] = family_id
		elif owned_provinces == 5:  # All provinces
			result["victory"] = true
			result["winner"] = family_id
	
	return result

func get_save_data() -> Dictionary:
	var save_data = {
		"provinces": {},
		"families": {},
		"characters": {},
		"current_family_index": current_family_index,
		"families_order": families_order,
		"current_month": current_month,
		"current_year": current_year,
		"player_family_id": player_family_id
	}
	
	# Save provinces
	for province_id in provinces:
		var province = provinces[province_id]
		save_data.provinces[province_id] = {
			"id": province.id,
			"name": province.name,
			"owner_id": province.owner_id,
			"soldiers": province.soldiers,
			"gold": province.gold,
			"food": province.food,
			"cultivation": province.cultivation,
			"protection": province.protection,
			"morale": province.morale,
			"is_exhausted": province.is_exhausted,
			"governor_id": province.governor_id,
			"terrain_type": province.terrain_type
		}
	
	# Save families
	for family_id in families:
		var family = families[family_id]
		save_data.families[family_id] = {
			"id": family.id,
			"name": family.name,
			"treasury": family.treasury,
			"is_defeated": family.is_defeated
		}
	
	# Save characters
	for character_id in characters:
		var character = characters[character_id]
		var character_data = {
			"id": character.id,
			"name": character.name,
			"family_id": character.family_id,
			"is_lord": character.is_lord,
			"loyalty": character.loyalty
		}
		
		# Add lord-specific data
		if character.is_lord:
			character_data.merge({
				"command_rating": character.command_rating,
				"diplomacy_rating": character.get("diplomacy_rating", 50),
				"special_ability": character.get("special_ability", ""),
				"is_captured": character.get("is_captured", false),
				"capture_family_id": character.get("capture_family_id", ""),
				"monthly_loyalty_drift": character.get("monthly_loyalty_drift", 0)
			})
		
		save_data.characters[character_id] = character_data
	
	return save_data

func load_save_data(data: Dictionary):
	# Load basic state
	current_family_index = data.get("current_family_index", 0)
	families_order = data.get("families_order", ["blanche", "lyle", "coryll"])
	current_month = data.get("current_month", 1)
	current_year = data.get("current_year", 1)
	player_family_id = data.get("player_family_id", "blanche")
	
	# Clear existing data
	provinces.clear()
	families.clear()
	characters.clear()
	
	# Load provinces
	var provinces_data = data.get("provinces", {})
	for province_id in provinces_data:
		var province_data = provinces_data[province_id]
		# Create province instance (simplified - would normally load from resource)
		var province = create_province_from_data(province_data)
		provinces[province_id] = province
	
	# Load families
	var families_data = data.get("families", {})
	for family_id in families_data:
		var family_data = families_data[family_id]
		# Create family instance (simplified)
		var family = create_family_from_data(family_data)
		families[family_id] = family
	
	# Load characters
	var characters_data = data.get("characters", {})
	for character_id in characters_data:
		var character_data = characters_data[character_id]
		# Create character instance
		var character = create_character_from_data(character_data)
		characters[character_id] = character

func create_province_from_data(data: Dictionary) -> ProvinceData:
	# Simplified province creation - in full implementation would load from resource template
	var province = ProvinceData.new()
	province.id = data.id
	province.name = data.name
	province.owner_id = data.owner_id
	province.soldiers = data.soldiers
	province.gold = data.gold
	province.food = data.food
	province.cultivation = data.cultivation
	province.protection = data.protection
	province.morale = data.morale
	province.is_exhausted = data.is_exhausted
	province.governor_id = data.governor_id
	province.terrain_type = data.terrain_type
	return province

func create_family_from_data(data: Dictionary) -> FamilyData:
	# Simplified family creation
	var family = FamilyData.new()
	family.id = data.id
	family.name = data.name
	family.treasury = data.treasury
	family.is_defeated = data.is_defeated
	return family

func create_character_from_data(data: Dictionary) -> CharacterData:
	# Create base character
	var character: CharacterData
	
	if data.get("is_lord", false):
		character = CharacterData.new()  # Use CharacterData instead of LordData
		# Load lord-specific data
		character.command_rating = data.get("command_rating", 50)
		# Note: Additional lord properties would need to be stored as metadata
	else:
		character = CharacterData.new()
	
	# Load base character data
	character.id = data.id
	character.name = data.name
	character.family_id = data.family_id
	character.is_lord = data.get("is_lord", false)
	character.loyalty = data.get("loyalty", 100)
	
	return character
