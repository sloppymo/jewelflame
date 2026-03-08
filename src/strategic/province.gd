## Jewelflame/Strategic/Province
## Represents a territory on the strategic map
## Contains garrison, resources, and ownership data
## Part of strategic layer

class_name Province
extends Resource

# ============================================================================
# SIGNALS
# ============================================================================

signal owner_changed(new_owner: String, old_owner: String)
signal garrison_changed()
signal development_changed(field: String, value: int)

# ============================================================================
# EXPORTED PROPERTIES
# ============================================================================

## Unique province ID (e.g., "dunmoor", "carveti")
@export var id: String = ""

## Display name
@export var name: String = ""

## Owner faction ID (e.g., "blanche", "lyle", "tyrant")
@export var owner_faction: String = ""

## Province terrain type (affects tactical battles)
@export var terrain: String = "plains"  # plains, forest, mountain, coastal

## Has castle/fortress (defensive bonus in battles)
@export var has_castle: bool = false

## Castle level 0-3 (affects defense and production)
@export var castle_level: int = 0

## Agricultural development 0-3 (affects food production)
@export var agriculture_level: int = 0

## Economic development 0-3 (affects gold production)
@export var economy_level: int = 0

## Base gold production per season
@export var base_gold: int = 10

## Base food production per harvest
@export var base_food: int = 10

## Connected province IDs (valid movement targets)
@export var connected_to: Array[String] = []

## Screen position for map rendering (0-1 normalized)
@export var map_position: Vector2 = Vector2.ZERO

# ============================================================================
# TRANSIENT STATE (Not Serialized)
# ============================================================================

## Units currently stationed here (garrison)
## Array of unit data dictionaries
var garrison: Array[Dictionary] = []

## Current defense bonus from castle
var defense_bonus: int = 0

## Is this province exhausted this turn? (one action per turn)
var is_exhausted: bool = false

## Is currently being invaded? (blocks other actions)
var is_under_siege: bool = false

# ============================================================================
# CONSTANTS
# ============================================================================

const MAX_CASTLE_LEVEL: int = 3
const MAX_AGRICULTURE_LEVEL: int = 3
const MAX_ECONOMY_LEVEL: int = 3

const TERRAIN_PLAINS: String = "plains"
const TERRAIN_FOREST: String = "forest"
const TERRAIN_MOUNTAIN: String = "mountain"
const TERRAIN_COASTAL: String = "coastal"

const VALID_TERRAINS: Array[String] = [
	TERRAIN_PLAINS,
	TERRAIN_FOREST,
	TERRAIN_MOUNTAIN,
	TERRAIN_COASTAL
]

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(p_id: String = "", p_name: String = "") -> void:
	id = p_id
	name = p_name if p_name != "" else p_id.capitalize()

## Static factory for creating provinces
static func create(p_id: String, p_name: String, p_owner: String, p_terrain: String) -> Province:
	var province := Province.new(p_id, p_name)
	province.owner_faction = p_owner
	province.terrain = p_terrain
	return province

# ============================================================================
# OWNERSHIP
# ============================================================================

## Changes province ownership
func change_owner(new_owner: String) -> void:
	if new_owner == owner_faction:
		return
	
	var old_owner := owner_faction
	owner_faction = new_owner
	
	# Reset exhaustion on capture
	is_exhausted = false
	is_under_siege = false
	
	owner_changed.emit(new_owner, old_owner)

# ============================================================================
# GARRISON MANAGEMENT
# ============================================================================

## Adds a unit to the garrison
func add_unit(unit_data: Dictionary) -> void:
	garrison.append(unit_data.duplicate())
	garrison_changed.emit()

## Removes a unit from the garrison by ID
func remove_unit(unit_id: String) -> bool:
	for i in range(garrison.size()):
		if garrison[i].get("id", "") == unit_id:
			garrison.remove_at(i)
			garrison_changed.emit()
			return true
	return false

## Gets a unit by ID
func get_unit(unit_id: String) -> Dictionary:
	for unit in garrison:
		if unit.get("id", "") == unit_id:
			return unit
	return {}

## Returns true if garrison has any units
func has_garrison() -> bool:
	return not garrison.is_empty()

## Gets total unit count
func get_unit_count() -> int:
	return garrison.size()

## Clears all units (defeat/destruction)
func clear_garrison() -> void:
	garrison.clear()
	garrison_changed.emit()

## Moves a unit to another province
func transfer_unit(unit_id: String, target_province: Province) -> bool:
	var unit := get_unit(unit_id)
	if unit.is_empty():
		return false
	
	if not remove_unit(unit_id):
		return false
	
	target_province.add_unit(unit)
	return true

# ============================================================================
# DEVELOPMENT
# ============================================================================

## Upgrades castle level (returns cost or -1 if maxed)
func upgrade_castle() -> int:
	if castle_level >= MAX_CASTLE_LEVEL:
		return -1
	
	var cost := _get_castle_upgrade_cost()
	castle_level += 1
	_update_defense_bonus()
	development_changed.emit("castle", castle_level)
	return cost

## Upgrades agriculture (returns cost or -1 if maxed)
func upgrade_agriculture() -> int:
	if agriculture_level >= MAX_AGRICULTURE_LEVEL:
		return -1
	
	var cost := _get_agriculture_upgrade_cost()
	agriculture_level += 1
	development_changed.emit("agriculture", agriculture_level)
	return cost

## Upgrades economy (returns cost or -1 if maxed)
func upgrade_economy() -> int:
	if economy_level >= MAX_ECONOMY_LEVEL:
		return -1
	
	var cost := _get_economy_upgrade_cost()
	economy_level += 1
	development_changed.emit("economy", economy_level)
	return cost

func _get_castle_upgrade_cost() -> int:
	return 50 * (castle_level + 1)

func _get_agriculture_upgrade_cost() -> int:
	return 30 * (agriculture_level + 1)

func _get_economy_upgrade_cost() -> int:
	return 40 * (economy_level + 1)

func _update_defense_bonus() -> void:
	defense_bonus = castle_level * 2  # +2 defense per castle level

# ============================================================================
# PRODUCTION
# ============================================================================

## Calculates gold production for this season
func calculate_gold_output() -> int:
	var output := base_gold
	
	# Economy bonus: +20% per level
	output = int(output * (1.0 + economy_level * 0.2))
	
	# Castle tax bonus: +10% per level
	output = int(output * (1.0 + castle_level * 0.1))
	
	return output

## Calculates food production for harvest
func calculate_food_output() -> int:
	var output := base_food
	
	# Agriculture bonus: +25% per level
	output = int(output * (1.0 + agriculture_level * 0.25))
	
	return output

## Calculates food consumption for garrison
func calculate_food_consumption() -> int:
	# Each unit consumes 1 food per turn
	return garrison.size()

# ============================================================================
# TURN MANAGEMENT
# ============================================================================

## Marks province as having taken an action this turn
func exhaust() -> void:
	is_exhausted = true

## Resets exhaustion at start of turn
func refresh() -> void:
	is_exhausted = false

## Returns true if province can take an action
func can_act() -> bool:
	return not is_exhausted and not is_under_siege

# ============================================================================
# BATTLE INTEGRATION
# ============================================================================

## Generates battle data for tactical combat
func generate_battle_data(is_defender: bool = true) -> Dictionary:
	return {
		"province_id": id,
		"province_name": name,
		"terrain": terrain,
		"has_castle": has_castle,
		"castle_level": castle_level,
		"defense_bonus": defense_bonus,
		"garrison": garrison.duplicate(true),
		"is_defender": is_defender
	}

## Applies battle results (casualties, capture)
func apply_battle_result(result: Dictionary) -> void:
	var victor: String = result.get("victor", "")
	var casualties: Array = result.get("casualties", [])
	var survivors: Array = result.get("survivors", [])
	
	# Remove casualties
	for unit_id in casualties:
		remove_unit(unit_id)
	
	# Update survivors (HP changes, etc.)
	garrison = survivors.duplicate(true)
	
	# If defender lost, change ownership
	if victor != owner_faction and result.get("capture_province", false):
		change_owner(victor)
	
	is_under_siege = false
	garrison_changed.emit()

# ============================================================================
# SERIALIZATION
# ============================================================================

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"owner": owner_faction,
		"terrain": terrain,
		"has_castle": has_castle,
		"castle_level": castle_level,
		"agriculture_level": agriculture_level,
		"economy_level": economy_level,
		"base_gold": base_gold,
		"base_food": base_food,
		"connected_to": connected_to.duplicate(),
		"map_position": {"x": map_position.x, "y": map_position.y},
		"garrison": garrison.duplicate(true),
		"is_exhausted": is_exhausted
	}

static func from_dict(d: Dictionary) -> Province:
	var province := Province.new(d.get("id", ""), d.get("name", ""))
	
	province.owner_faction = d.get("owner", "")
	province.terrain = d.get("terrain", "plains")
	province.has_castle = d.get("has_castle", false)
	province.castle_level = d.get("castle_level", 0)
	province.agriculture_level = d.get("agriculture_level", 0)
	province.economy_level = d.get("economy_level", 0)
	province.base_gold = d.get("base_gold", 10)
	province.base_food = d.get("base_food", 10)
	province.connected_to = d.get("connected_to", []).duplicate()
	
	var pos := d.get("map_position", {"x": 0.0, "y": 0.0})
	province.map_position = Vector2(pos.get("x", 0.0), pos.get("y", 0.0))
	
	province.garrison = d.get("garrison", []).duplicate(true)
	province.is_exhausted = d.get("is_exhausted", false)
	province._update_defense_bonus()
	
	return province

# ============================================================================
# UTILITY
# ============================================================================

func _to_string() -> String:
	return "Province[%s] owner=%s garrison=%d castle=%d" % [
		id, owner_faction, garrison.size(), castle_level
	]
