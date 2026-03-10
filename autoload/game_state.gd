extends Node

var provinces: Dictionary = {}  # int -> ProvinceData
var families: Dictionary = {}   # String -> FamilyData
var characters: Dictionary = {} # String -> CharacterData
var player_family_id: String = "blanche"
var selected_lord_id: String = ""

# Turn management
var current_family_index: int = 0
var families_order: Array[String] = ["blanche", "lyle", "coryll"]
var current_month: int = 1
var current_year: int = 1

func _ready():
	load_initial_data()

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
			provinces[province.id] = province
			print("Loaded province: ", province.name)
	
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
	elif victory_status.has("defeat") and victory_status.defeat:
		print("Defeat for: ", victory_status.loser)

func advance_month():
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1
	
	# Process monthly systems
	# EconomyManager.process_monthly_upkeep()
	
	# September harvest
	if current_month == 9:
		# HarvestSystem.process_september_harvest()
		pass
	
	# Random events
	# RandomEvents.trigger_monthly_events()

func reset_family_exhaustion(family_id: String):
	for province in provinces.values():
		if province.owner_id == family_id:
			province.is_exhausted = false
			EventBus.ProvinceExhausted.emit(province.id, false)

func advance_turn_phase():
	advance_turn()

func get_family_lords(family_id: String) -> Array:
	var family_lords = []
	for char_id in characters:
		var character = characters[char_id]
		if character.family_id == family_id and character.is_lord:
			family_lords.append(character)
	return family_lords

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
