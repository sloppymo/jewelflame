## Jewelflame/Factions/Faction
## Represents a playable faction/family in Jewelflame
## Manages jewels, leaders, and faction-specific bonuses

class_name Faction
extends Resource

# ============================================================================
# SIGNALS
# ============================================================================

signal jewel_acquired(jewel_type: String)
signal jewel_used(jewel_type: String)
signal jewel_cooldown_changed(jewel_type: String, remaining: int)
signal leader_changed(new_leader: String)

# ============================================================================
# EXPORTED PROPERTIES
# ============================================================================

## Faction ID (e.g., "blanche", "lyle", "tyrant")
@export var id: String = ""

## Display name
@export var name: String = ""

## Leader character ID
@export var leader_id: String = ""

## Leader display name
@export var leader_name: String = ""

## Faction color (for UI/territory highlighting)
@export var faction_color: Color = Color.WHITE

## Faction bonus type
@export var bonus_type: String = ""  # military, economic, diplomatic, magical

## Faction bonus value (percentage)
@export var bonus_value: float = 0.0

## Is AI controlled
@export var is_ai: bool = true

## Is eliminated from game
@export var is_eliminated: bool = false

## Starting position (province IDs)
@export var starting_provinces: Array[String] = []

# ============================================================================
# JEWEL INVENTORY
# ============================================================================

## Owned jewels (jewel_type -> Jewel)
var jewels: Dictionary = {}

## Starting jewel types
var starting_jewels: Array[String] = []

# ============================================================================
# CHARACTER ROSTER
# ============================================================================

## War leaders (generals)
var generals: Array[String] = []

## Political advisors
var advisors: Array[String] = []

# ============================================================================
# CONSTANTS
# ============================================================================

const BONUS_MILITARY: String = "military"
const BONUS_ECONOMIC: String = "economic"
const BONUS_DIPLOMATIC: String = "diplomatic"
const BONUS_MAGICAL: String = "magical"

const VALID_BONUSES: Array[String] = [
	BONUS_MILITARY, BONUS_ECONOMIC, BONUS_DIPLOMATIC, BONUS_MAGICAL
]

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(p_id: String = "", p_name: String = "") -> void:
	id = p_id
	name = p_name if p_name != "" else p_id.capitalize()

## Sets up faction from template data
func setup_from_template(template: Dictionary) -> void:
	name = template.get("name", id.capitalize())
	leader_id = template.get("leader_id", "")
	leader_name = template.get("leader_name", "Unknown")
	
	var color_dict: Dictionary = template.get("color", {"r": 1.0, "g": 1.0, "b": 1.0})
	faction_color = Color(color_dict.get("r", 1.0), color_dict.get("g", 1.0), color_dict.get("b", 1.0))
	
	bonus_type = template.get("bonus_type", "")
	bonus_value = template.get("bonus_value", 0.0)
	is_ai = template.get("is_ai", true)
	starting_provinces = template.get("starting_provinces", []).duplicate()
	starting_jewels = template.get("starting_jewels", []).duplicate()
	
	# Initialize starting jewels
	for jewel_type in starting_jewels:
		acquire_jewel(jewel_type)
	
	generals = template.get("generals", []).duplicate()
	advisors = template.get("advisors", []).duplicate()

# ============================================================================
# JEWEL MANAGEMENT
# ============================================================================

## Adds a jewel to faction inventory
func acquire_jewel(jewel_type: String) -> void:
	if jewel_type == "" or jewels.has(jewel_type):
		return
	
	var jewel := Jewel.new(jewel_type)
	jewels[jewel_type] = jewel
	
	# Connect cooldown signal
	jewel.cooldown_changed.connect(_on_jewel_cooldown_changed.bind(jewel_type))
	
	jewel_acquired.emit(jewel_type)

## Uses a jewel (returns true if successful)
func use_jewel(jewel_type: String) -> bool:
	var jewel: Jewel = jewels.get(jewel_type)
	if not jewel:
		return false
	
	if jewel.use():
		jewel_used.emit(jewel_type)
		return true
	return false

## Gets a jewel by type
func get_jewel(jewel_type: String) -> Jewel:
	return jewels.get(jewel_type)

## Returns all owned jewel types
func get_jewel_types() -> Array[String]:
	var result: Array[String] = []
	result.assign(jewels.keys())
	return result

## Returns all ready jewels
func get_ready_jewels() -> Array[Jewel]:
	var result: Array[Jewel] = []
	for jewel in jewels.values():
		if jewel.is_ready():
			result.append(jewel)
	return result

## Returns true if faction has any ready jewels
func has_ready_jewel() -> bool:
	for jewel in jewels.values():
		if jewel.is_ready():
			return true
	return false

## Ticks all jewel cooldowns (call at start of turn)
func tick_jewel_cooldowns() -> void:
	for jewel in jewels.values():
		jewel.tick_cooldown()

func _on_jewel_cooldown_changed(remaining: int, jewel_type: String) -> void:
	jewel_cooldown_changed.emit(jewel_type, remaining)

# ============================================================================
# BONUS CALCULATIONS
# ============================================================================

## Gets attack bonus (0.0 = none, 0.1 = +10%)
func get_attack_bonus() -> float:
	if bonus_type == BONUS_MILITARY:
		return bonus_value
	return 0.0

## Gets defense bonus
func get_defense_bonus() -> float:
	if bonus_type == BONUS_MILITARY:
		return bonus_value * 0.5  # Half bonus to defense
	return 0.0

## Gets gold production bonus
func get_gold_bonus() -> float:
	if bonus_type == BONUS_ECONOMIC:
		return bonus_value
	return 0.0

## Gets food production bonus
func get_food_bonus() -> float:
	if bonus_type == BONUS_ECONOMIC:
		return bonus_value * 0.5
	return 0.0

## Gets diplomatic bonus (affects defection chance)
func get_diplomatic_bonus() -> float:
	if bonus_type == BONUS_DIPLOMATIC:
		return bonus_value
	return 0.0

## Gets jewel cooldown reduction (as percentage)
func get_cooldown_reduction() -> float:
	if bonus_type == BONUS_MAGICAL:
		return bonus_value
	return 0.0

## Applies cooldown reduction to a base cooldown
func apply_cooldown_reduction(base_cooldown: int) -> int:
	var reduction := get_cooldown_reduction()
	return max(1, int(base_cooldown * (1.0 - reduction)))

# ============================================================================
# ELIMINATION
# ============================================================================

## Marks faction as eliminated
func eliminate() -> void:
	is_eliminated = true
	is_ai = true  # Force AI control (no player input)

## Returns true if faction is still in the game
func is_active() -> bool:
	return not is_eliminated

# ============================================================================
# SERIALIZATION
# ============================================================================

func to_dict() -> Dictionary:
	var jewel_data: Dictionary = {}
	for type_key in jewels.keys():
		var jewel: Jewel = jewels[type_key]
		jewel_data[type_key] = jewel.to_dict()
	
	return {
		"id": id,
		"name": name,
		"leader_id": leader_id,
		"leader_name": leader_name,
		"color": {"r": faction_color.r, "g": faction_color.g, "b": faction_color.b},
		"bonus_type": bonus_type,
		"bonus_value": bonus_value,
		"is_ai": is_ai,
		"is_eliminated": is_eliminated,
		"jewels": jewel_data,
		"generals": generals.duplicate(),
		"advisors": advisors.duplicate()
	}

static func from_dict(d: Dictionary) -> Faction:
	var faction := Faction.new(d.get("id", ""), d.get("name", ""))
	
	faction.leader_id = d.get("leader_id", "")
	faction.leader_name = d.get("leader_name", "")
	
	var color_dict: Dictionary = d.get("color", {"r": 1.0, "g": 1.0, "b": 1.0})
	faction.faction_color = Color(color_dict.get("r", 1.0), color_dict.get("g", 1.0), color_dict.get("b", 1.0))
	
	faction.bonus_type = d.get("bonus_type", "")
	faction.bonus_value = d.get("bonus_value", 0.0)
	faction.is_ai = d.get("is_ai", true)
	faction.is_eliminated = d.get("is_eliminated", false)
	
	# Restore jewels
	var jewel_data: Dictionary = d.get("jewels", {})
	for jewel_type in jewel_data.keys():
		var j_dict: Dictionary = jewel_data[jewel_type]
		var jewel := Jewel.from_dict(j_dict)
		faction.jewels[jewel_type] = jewel
		jewel.cooldown_changed.connect(faction._on_jewel_cooldown_changed.bind(jewel_type))
	
	faction.generals = d.get("generals", []).duplicate()
	faction.advisors = d.get("advisors", []).duplicate()
	
	return faction

# ============================================================================
# UTILITY
# ============================================================================

func _to_string() -> String:
	return "Faction[%s] %s - Leader: %s, Jewels: %d" % [
		id, name, leader_name, jewels.size()
	]
