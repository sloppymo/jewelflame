## Jewelflame/Autoload/GameState
## Global game state manager - bridges strategic and tactical layers
## Autoload singleton - persists across scene changes

extends Node

# ============================================================================
# SIGNALS
# ============================================================================

## Strategic layer signals
signal province_selected(province_id: String)
signal province_owner_changed(province_id: String, new_owner: String, old_owner: String)
signal turn_ended(month: int, year: int)
signal season_changed(season: String)

## Tactical layer signals
signal battle_started(battle_data: Dictionary)
signal battle_ended(result: Dictionary)
signal battle_saved(slot: String)
signal battle_loaded(slot: String)

## Economy signals
signal gold_changed(faction: String, amount: int, total: int)
signal food_changed(faction: String, amount: int, total: int)

## System signals
signal game_loaded()
signal game_saved()
signal error_occurred(message: String)

# ============================================================================
# CONFIGURATION
# ============================================================================

## Starting year
const START_YEAR: int = 1100

## Seasons in order
const SEASONS: Array[String] = ["spring", "summer", "autumn", "winter"]

## Months per season
const MONTHS_PER_SEASON: int = 3

## Auto-save battle in progress
const AUTO_SAVE_BATTLE: bool = true
const BATTLE_SAVE_SLOT: String = "battle_in_progress"

# ============================================================================
# GAME STATE
# ============================================================================

## Current game time
var current_year: int = START_YEAR
var current_month: int = 1  # 1-12
var current_season: String = "spring"

## Turn tracking
var current_faction_index: int = 0
var turn_number: int = 1

## All provinces (id -> Province)
var provinces: Dictionary = {}

## All factions (id -> FactionData)
var factions: Dictionary = {}

## Player faction ID
var player_faction: String = ""

## Active factions in play (for turn order)
var active_factions: Array[String] = []

## Battle state (null when not in battle)
var current_battle: Dictionary = {}
var battle_in_progress: bool = false

# ============================================================================
# ECONOMY STATE
# ============================================================================

## Faction resources (faction_id -> {gold, food})
var faction_resources: Dictionary = {}

## Unit templates for recruitment
var unit_templates: Dictionary = {}

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	print("GameState: Initialized")

## Initializes a new game with starting data
func initialize_new_game(starting_data: Dictionary) -> void:
	# Clear existing state
	provinces.clear()
	factions.clear()
	faction_resources.clear()
	
	# Set up time
	current_year = starting_data.get("year", START_YEAR)
	current_month = starting_data.get("month", 1)
	_update_season()
	
	# Load provinces
	var province_data: Array = starting_data.get("provinces", [])
	for p_dict in province_data:
		var province := Province.from_dict(p_dict)
		provinces[province.id] = province
	
	# Load factions
	var faction_data: Array = starting_data.get("factions", [])
	for f_dict in faction_data:
		var faction_id: String = f_dict.get("id", "")
		factions[faction_id] = f_dict
		faction_resources[faction_id] = {
			"gold": f_dict.get("starting_gold", 100),
			"food": f_dict.get("starting_food", 100)
		}
	
	# Set turn order
	active_factions = starting_data.get("turn_order", factions.keys())
	current_faction_index = 0
	player_faction = starting_data.get("player_faction", "")
	
	print("GameState: New game initialized with %d provinces, %d factions" % [
		provinces.size(), factions.size()
	])

# ============================================================================
# TURN MANAGEMENT
# ============================================================================

## Gets the faction whose turn it is
func get_current_faction() -> String:
	if active_factions.is_empty():
		return ""
	return active_factions[current_faction_index]

## Returns true if it's the player's turn
func is_player_turn() -> bool:
	return get_current_faction() == player_faction

## Ends the current faction's turn and advances
func end_turn() -> void:
	var ending_faction := get_current_faction()
	
	# Process end-of-turn for this faction
	_process_end_of_turn(ending_faction)
	
	# Advance to next faction
	current_faction_index += 1
	if current_faction_index >= active_factions.size():
		# All factions have gone - advance month
		current_faction_index = 0
		_advance_month()
	
	var new_faction := get_current_faction()
	
	# Process start-of-turn for new faction
	_process_start_of_turn(new_faction)
	
	turn_ended.emit(current_month, current_year)
	print("GameState: Turn ended for %s, now %s's turn (Month %d)" % [
		ending_faction, new_faction, current_month
	])

func _advance_month() -> void:
	current_month += 1
	turn_number += 1
	
	if current_month > 12:
		current_month = 1
		current_year += 1
	
	var old_season := current_season
	_update_season()
	
	if current_season != old_season:
		season_changed.emit(current_season)
		_process_season_change(current_season)

func _update_season() -> void:
	var season_index := (current_month - 1) / MONTHS_PER_SEASON
	current_season = SEASONS[season_index]

func _process_start_of_turn(faction_id: String) -> void:
	# Refresh all owned provinces
	for province in provinces.values():
		if province.owner_faction == faction_id:
			province.refresh()

func _process_end_of_turn(faction_id: String) -> void:
	# Apply upkeep costs
	_upkeep_phase(faction_id)

func _process_season_change(season: String) -> void:
	match season:
		"spring":
			_process_spring()
		"summer":
			_process_summer()
		"autumn":
			_process_autumn()
		"winter":
			_process_winter()

func _process_spring() -> void:
	pass  # Planting season - nothing special yet

func _process_summer() -> void:
	pass  # Campaign season - nothing special yet

func _process_autumn() -> void:
	# Harvest season - collect food
	_for_all_factions(_harvest_food)

func _process_winter() -> void:
	# Winter attrition - extra food consumption
	_for_all_factions(_winter_attrition)

# ============================================================================
# ECONOMY
# ============================================================================

func _upkeep_phase(faction_id: String) -> void:
	var total_food_consumption := 0
	
	# Calculate food consumption from all owned provinces
	for province in provinces.values():
		if province.owner_faction == faction_id:
			total_food_consumption += province.calculate_food_consumption()
	
	# Consume food
	var resources := faction_resources.get(faction_id, {"gold": 0, "food": 0})
	resources["food"] = max(0, resources["food"] - total_food_consumption)
	
	food_changed.emit(faction_id, -total_food_consumption, resources["food"])

func _harvest_food(faction_id: String) -> void:
	var total_food := 0
	
	for province in provinces.values():
		if province.owner_faction == faction_id:
			total_food += province.calculate_food_output()
	
	var resources := faction_resources.get(faction_id, {"gold": 0, "food": 0})
	resources["food"] += total_food
	
	food_changed.emit(faction_id, total_food, resources["food"])

func _winter_attrition(faction_id: String) -> void:
	# Winter doubles food consumption
	var total_consumption := 0
	
	for province in provinces.values():
		if province.owner_faction == faction_id:
			total_consumption += province.calculate_food_consumption()
	
	# Additional winter consumption (already consumed once in upkeep)
	var resources := faction_resources.get(faction_id, {"gold": 0, "food": 0})
	var actual_consumption := min(total_consumption, resources["food"])
	resources["food"] -= actual_consumption
	
	# TODO: Apply attrition penalties if food runs out
	
	food_changed.emit(faction_id, -actual_consumption, resources["food"])

func collect_gold(faction_id: String) -> int:
	var total_gold := 0
	
	for province in provinces.values():
		if province.owner_faction == faction_id:
			total_gold += province.calculate_gold_output()
	
	var resources := faction_resources.get(faction_id, {"gold": 0, "food": 0})
	resources["gold"] += total_gold
	
	gold_changed.emit(faction_id, total_gold, resources["gold"])
	return total_gold

func get_faction_gold(faction_id: String) -> int:
	return faction_resources.get(faction_id, {}).get("gold", 0)

func get_faction_food(faction_id: String) -> int:
	return faction_resources.get(faction_id, {}).get("food", 0)

func spend_gold(faction_id: String, amount: int) -> bool:
	var resources := faction_resources.get(faction_id, {"gold": 0, "food": 0})
	if resources["gold"] < amount:
		return false
	
	resources["gold"] -= amount
	gold_changed.emit(faction_id, -amount, resources["gold"])
	return true

# ============================================================================
# BATTLE BRIDGE
# ============================================================================

## Initiates a battle between attacker and defender provinces
func start_battle(attacker_province_id: String, defender_province_id: String) -> Dictionary:
	var attacker_province: Province = provinces.get(attacker_province_id)
	var defender_province: Province = provinces.get(defender_province_id)
	
	if not attacker_province or not defender_province:
		error_occurred.emit("Invalid province IDs for battle")
		return {}
	
	if defender_province.owner_faction == attacker_province.owner_faction:
		error_occurred.emit("Cannot attack own province")
		return {}
	
	# Mark defender as under siege
	defender_province.is_under_siege = true
	
	# Build battle data
	var battle_data := {
		"attacker": {
			"faction": attacker_province.owner_faction,
			"province_id": attacker_province_id,
			"units": attacker_province.garrison.duplicate(true)
		},
		"defender": {
			"faction": defender_province.owner_faction,
			"province_id": defender_province_id,
			"units": defender_province.garrison.duplicate(true),
			"has_castle": defender_province.has_castle,
			"castle_level": defender_province.castle_level,
			"terrain": defender_province.terrain
		},
		"province_name": defender_province.name,
		"turn": turn_number,
		"month": current_month,
		"year": current_year
	}
	
	current_battle = battle_data
	battle_in_progress = true
	
	# Auto-save if enabled
	if AUTO_SAVE_BATTLE:
		_save_battle_state()
	
	battle_started.emit(battle_data)
	print("GameState: Battle started - %s (%s) vs %s (%s)" % [
		attacker_province.owner_faction, attacker_province_id,
		defender_province.owner_faction, defender_province_id
	])
	
	return battle_data

## Ends current battle and applies results to strategic layer
func end_battle(result: Dictionary) -> void:
	if not battle_in_progress:
		return
	
	var victor: String = result.get("victor", "")
	var attacker_id: String = current_battle.get("attacker", {}).get("province_id", "")
	var defender_id: String = current_battle.get("defender", {}).get("province_id", "")
	
	var attacker_province: Province = provinces.get(attacker_id)
	var defender_province: Province = provinces.get(defender_id)
	
	if attacker_province:
		# Update attacker garrison with survivors
		var attacker_casualties: Array = result.get("attacker_casualties", [])
		var attacker_survivors: Array = result.get("attacker_survivors", [])
		
		for unit_id in attacker_casualties:
			attacker_province.remove_unit(unit_id)
		
		# Update survivor HP from battle results
		for unit_data in attacker_survivors:
			var unit_id: String = unit_data.get("id", "")
			var existing := attacker_province.get_unit(unit_id)
			if not existing.is_empty():
				existing["current_hp"] = unit_data.get("current_hp", existing.get("hp", 10))
	
	if defender_province:
		# Update defender garrison
		var defender_casualties: Array = result.get("defender_casualties", [])
		var defender_survivors: Array = result.get("defender_survivors", [])
		
		for unit_id in defender_casualties:
			defender_province.remove_unit(unit_id)
		
		for unit_data in defender_survivors:
			var unit_id: String = unit_data.get("id", "")
			var existing := defender_province.get_unit(unit_id)
			if not existing.is_empty():
				existing["current_hp"] = unit_data.get("current_hp", existing.get("hp", 10))
		
		# Handle capture
		if victor == attacker_province.owner_faction:
			defender_province.change_owner(victor)
			province_owner_changed.emit(defender_id, victor, defender_province.owner_faction)
	
	battle_ended.emit(result)
	
	# Clear battle state
	current_battle = {}
	battle_in_progress = false
	
	print("GameState: Battle ended - Victor: %s" % victor)

# ============================================================================
# SAVE / LOAD
# ============================================================================

func save_game(slot: String) -> bool:
	var save_data := {
		"version": "1.0.0",
		"timestamp": Time.get_unix_time_from_system(),
		"game": {
			"year": current_year,
			"month": current_month,
			"season": current_season,
			"turn": turn_number,
			"current_faction_index": current_faction_index,
			"player_faction": player_faction,
			"active_factions": active_factions.duplicate()
		},
		"provinces": _serialize_provinces(),
		"factions": factions.duplicate(true),
		"resources": faction_resources.duplicate(true),
		"battle_in_progress": battle_in_progress,
		"current_battle": current_battle.duplicate(true) if battle_in_progress else {}
	}
	
	var json := JSON.stringify(save_data, "  ")
	var file := FileAccess.open("user://saves/%s.json" % slot, FileAccess.WRITE)
	if file:
		file.store_string(json)
		file.close()
		game_saved.emit()
		print("GameState: Game saved to slot '%s'" % slot)
		return true
	else:
		error_occurred.emit("Failed to save game")
		return false

func load_game(slot: String) -> bool:
	var path := "user://saves/%s.json" % slot
	if not FileAccess.file_exists(path):
		error_occurred.emit("Save file not found: %s" % slot)
		return false
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		error_occurred.emit("Failed to open save file")
		return false
	
	var json := file.get_as_text()
	file.close()
	
	var result: Variant = JSON.parse_string(json)
	if result == null or not result is Dictionary:
		error_occurred.emit("Corrupted save file")
		return false
	
	var save_data: Dictionary = result
	var game_data: Dictionary = save_data.get("game", {})
	
	# Restore game state
	current_year = game_data.get("year", START_YEAR)
	current_month = game_data.get("month", 1)
	current_season = game_data.get("season", "spring")
	turn_number = game_data.get("turn", 1)
	current_faction_index = game_data.get("current_faction_index", 0)
	player_faction = game_data.get("player_faction", "")
	active_factions = game_data.get("active_factions", []).duplicate()
	
	# Restore provinces
	provinces.clear()
	for p_dict in save_data.get("provinces", []):
		var province := Province.from_dict(p_dict)
		provinces[province.id] = province
	
	# Restore factions and resources
	factions = save_data.get("factions", {}).duplicate(true)
	faction_resources = save_data.get("resources", {}).duplicate(true)
	
	# Restore battle state
	battle_in_progress = save_data.get("battle_in_progress", false)
	if battle_in_progress:
		current_battle = save_data.get("current_battle", {}).duplicate(true)
	
	game_loaded.emit()
	print("GameState: Game loaded from slot '%s'" % slot)
	return true

func _serialize_provinces() -> Array:
	var result: Array = []
	for province in provinces.values():
		result.append(province.to_dict())
	return result

func _save_battle_state() -> void:
	# Save current battle for resumption
	var battle_save := {
		"timestamp": Time.get_unix_time_from_system(),
		"battle": current_battle.duplicate(true),
		"strategic_state": {
			"year": current_year,
			"month": current_month,
			"turn": turn_number
		}
	}
	
	var json := JSON.stringify(battle_save)
	var file := FileAccess.open("user://saves/%s.json" % BATTLE_SAVE_SLOT, FileAccess.WRITE)
	if file:
		file.store_string(json)
		file.close()
		battle_saved.emit(BATTLE_SAVE_SLOT)

# ============================================================================
# UTILITY
# ============================================================================

func _for_all_factions(callback: Callable) -> void:
	for faction_id in active_factions:
		callback.call(faction_id)

func get_province(province_id: String) -> Province:
	return provinces.get(province_id)

func get_owned_provinces(faction_id: String) -> Array[Province]:
	var result: Array[Province] = []
	for province in provinces.values():
		if province.owner_faction == faction_id:
			result.append(province)
	return result

func get_province_count(faction_id: String) -> int:
	var count := 0
	for province in provinces.values():
		if province.owner_faction == faction_id:
			count += 1
	return count
