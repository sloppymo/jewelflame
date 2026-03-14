extends Node

const BattleData = preload("res://resources/data_classes/battle_data.gd")

var provinces: Dictionary = {}  # int -> ProvinceData
var families: Dictionary = {}   # String -> FamilyData
var characters: Dictionary = {} # String -> CharacterData
var player_family_id: String = "blanche"
var selected_lord_id: String = ""

# Battle bridge - current active battle data
var current_battle: Dictionary = {}
var current_battle_data: BattleData = null

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

# ============================================================================
# BATTLE BRIDGE FUNCTIONS
# ============================================================================

func start_battle(attacker_province_id: int, defender_province_id: int) -> Dictionary:
	"""
	Initialize battle data for transition to tactical battle scene.
	Returns battle data dictionary for the battle scene to use.
	"""
	var attacker_province = provinces.get(attacker_province_id)
	var defender_province = provinces.get(defender_province_id)
	
	if not attacker_province or not defender_province:
		push_error("GameState: Invalid province IDs for battle")
		return {}
	
	# Build attacker battle data
	var attacker_units = _build_battle_units(attacker_province)
	var attacker_data = {
		"faction": attacker_province.owner_id,
		"province_id": attacker_province_id,
		"province_name": attacker_province.name,
		"units": attacker_units,
		"lord": _get_province_lord(attacker_province)
	}
	
	# Build defender battle data
	var defender_units = _build_battle_units(defender_province)
	var defender_data = {
		"faction": defender_province.owner_id,
		"province_id": defender_province_id,
		"province_name": defender_province.name,
		"units": defender_units,
		"lord": _get_province_lord(defender_province),
		"has_castle": defender_province.castle_level if "castle_level" in defender_province else false,
		"castle_level": defender_province.castle_level if "castle_level" in defender_province else 0,
		"terrain": defender_province.terrain_type
	}
	
	# Store current battle
	current_battle = {
		"attacker": attacker_data,
		"defender": defender_data,
		"province_name": defender_province.name,
		"battle_id": "battle_%d_%d_%d" % [attacker_province_id, defender_province_id, Time.get_ticks_msec()]
	}
	
	# Also create BattleData resource for compatibility
	current_battle_data = BattleData.new()
	current_battle_data.battle_id = current_battle.battle_id
	current_battle_data.attacking_province_id = attacker_province_id
	current_battle_data.defending_province_id = defender_province_id
	current_battle_data.attacking_family_id = attacker_province.owner_id
	current_battle_data.defending_family_id = defender_province.owner_id
	current_battle_data.terrain_type = defender_data.terrain
	current_battle_data.battle_state = "in_progress"
	
	print("GameState: Battle started - %s vs %s" % [attacker_province.name, defender_province.name])
	
	return current_battle

func end_battle(result: Dictionary) -> void:
	"""
	Process battle results and update game state.
	Called by tactical battle scene when battle ends.
	"""
	var victor = result.get("victor", "")
	var attacker_province_id = current_battle.get("attacker", {}).get("province_id", -1)
	var defender_province_id = current_battle.get("defender", {}).get("province_id", -1)
	
	if attacker_province_id == -1 or defender_province_id == -1:
		push_error("GameState: Invalid battle data in end_battle")
		return
	
	var attacker_province = provinces.get(attacker_province_id)
	var defender_province = provinces.get(defender_province_id)
	
	if not attacker_province or not defender_province:
		push_error("GameState: Could not find provinces for battle resolution")
		return
	
	# Update soldier counts
	var attacker_survivors = result.get("attacker_survivors", [])
	var defender_survivors = result.get("defender_survivors", [])
	
	attacker_province.soldiers = _count_soldiers_from_survivors(attacker_survivors)
	defender_province.soldiers = _count_soldiers_from_survivors(defender_survivors)
	
	# Handle province conquest
	if victor == "attacker":
		# Transfer ownership
		var old_owner = defender_province.owner_id
		defender_province.owner_id = attacker_province.owner_id
		
		# Transfer some resources as loot
		var loot_gold = int(defender_province.gold * 0.3)
		var loot_food = int(defender_province.food * 0.3)
		attacker_province.gold += loot_gold
		attacker_province.food += loot_food
		defender_province.gold -= loot_gold
		defender_province.food -= loot_food
		
		print("GameState: %s conquered %s!" % [attacker_province.name, defender_province.name])
	
	# Mark attacker as exhausted
	attacker_province.is_exhausted = true
	EventBus.ProvinceExhausted.emit(attacker_province_id, true)
	
	# Update battle data
	if current_battle_data:
		current_battle_data.battle_state = "completed"
		current_battle_data.winner = victor
	
	# Clear current battle
	current_battle = {}
	current_battle_data = null
	
	print("GameState: Battle ended - Victor: %s" % victor)
	
	# Emit battle resolved signal
	EventBus.BattleResolved.emit(result)

func _build_battle_units(province) -> Array:
	"""Build unit data for battle from province soldiers."""
	var units = []
	var total_soldiers = province.soldiers
	
	if total_soldiers <= 0:
		return units
	
	# Simple unit distribution
	var knights = max(1, int(total_soldiers * 0.4))
	var horsemen = max(1, int(total_soldiers * 0.3))
	var archers = max(1, int(total_soldiers * 0.2))
	var mages = max(1, int(total_soldiers * 0.1))
	
	# Create unit dictionaries
	if knights > 0:
		units.append({
			"id": "knight_%d" % randi(),
			"name": "Knight",
			"type": "knight",
			"hp": 20,
			"current_hp": 20,
			"attack": 8,
			"defense": 5,
			"movement": 4,
			"attack_range": 1
		})
	
	if horsemen > 0:
		units.append({
			"id": "horseman_%d" % randi(),
			"name": "Horseman",
			"type": "horseman",
			"hp": 15,
			"current_hp": 15,
			"attack": 6,
			"defense": 3,
			"movement": 6,
			"attack_range": 1
		})
	
	if archers > 0:
		units.append({
			"id": "archer_%d" % randi(),
			"name": "Archer",
			"type": "archer",
			"hp": 12,
			"current_hp": 12,
			"attack": 5,
			"defense": 2,
			"movement": 4,
			"attack_range": 3
		})
	
	if mages > 0:
		units.append({
			"id": "mage_%d" % randi(),
			"name": "Mage",
			"type": "mage",
			"hp": 10,
			"current_hp": 10,
			"attack": 10,
			"defense": 1,
			"movement": 3,
			"attack_range": 4
		})
	
	return units

func _get_province_lord(province) -> CharacterData:
	"""Get the lord governing a province."""
	if province.governor_id and not province.governor_id.is_empty():
		return characters.get(province.governor_id)
	
	# Fallback: find any character from this family
	for char_id in characters:
		var character = characters[char_id]
		if character.family_id == province.owner_id:
			return character
	
	return null

func _count_soldiers_from_survivors(survivors: Array) -> int:
	"""Count total soldiers from survivor unit data."""
	var total = 0
	for unit in survivors:
		if unit is Dictionary:
			total += unit.get("count", 10)
		elif unit.has_method("is_alive"):
			# UnitData object
			total += unit.current_hp
	return total
