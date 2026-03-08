## Jewelflame/Jewels/Jewel
## Represents a wizard's elemental jewel - the "Fifth Unit" special ability
## Part of tactical layer - used during battles

class_name Jewel
extends Resource

# ============================================================================
# SIGNALS
# ============================================================================

signal cooldown_changed(remaining: int)
signal used()

# ============================================================================
# EXPORTED PROPERTIES
# ============================================================================

## Jewel type identifier
@export var jewel_type: String = ""  # fire, water, earth, air, light, dark

## Display name
@export var name: String = ""

## Wizard character name
@export var wizard_name: String = ""

## Elemental affinity
@export var element: String = ""  # fire, ice, lightning, meteor, wind, poison

## Cooldown in turns (3 months = 9 turns)
@export var base_cooldown: int = 9

## Current cooldown remaining (0 = ready)
@export var current_cooldown: int = 0

## Uses remaining (-1 = infinite, for single-player campaign balance)
@export var uses_remaining: int = -1

## Movement range on tactical grid
@export var movement_range: int = 3

## Spell/ability data
@export var spell_data: Dictionary = {}

# ============================================================================
# JEWEL DEFINITIONS (CONSTANTS)
# ============================================================================

const TYPE_RUBY: String = "ruby"        # Fire Dragon - Tyrant exclusive
const TYPE_EMERALD: String = "emerald"  # Empyron - Fire Magic
const TYPE_TOPAZ: String = "topaz"      # Zendor - Lightning (best balance)
const TYPE_SAPPHIRE: String = "sapphire" # Pluvius - Meteors (highest damage)
const TYPE_AQUAMARINE: String = "aquamarine" # Chylla - Ice
const TYPE_AMETHYST: String = "amethyst"     # Scylla - Wind
const TYPE_PEARL: String = "pearl"           # Skulryk - Poison

const ALL_TYPES: Array[String] = [
	TYPE_RUBY, TYPE_EMERALD, TYPE_TOPAZ, TYPE_SAPPHIRE,
	TYPE_AQUAMARINE, TYPE_AMETHYST, TYPE_PEARL
]

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(p_type: String = "") -> void:
	if p_type != "":
		_setup_from_type(p_type)

## Sets up jewel properties from type template
func _setup_from_type(p_type: String) -> void:
	jewel_type = p_type
	
	match p_type:
		TYPE_RUBY:
			name = "Ruby"
			wizard_name = "Fire Dragon"
			element = "fire"
			base_cooldown = 12
			movement_range = 3
			spell_data = {
				"damage": 50,
				"aoe_radius": 2,
				"effect": "inferno",
				"description": "Devastating fire storm - game ending power"
			}
		
		TYPE_EMERALD:
			name = "Emerald"
			wizard_name = "Empyron"
			element = "fire_magic"
			base_cooldown = 9
			movement_range = 3
			spell_data = {
				"damage": 25,
				"aoe_radius": 1,
				"effect": "fireball",
				"description": "Crystal fire attacks - medium power"
			}
		
		TYPE_TOPAZ:
			name = "Topaz"
			wizard_name = "Zendor"
			element = "lightning"
			base_cooldown = 9
			movement_range = 3
			spell_data = {
				"damage": 30,
				"aoe_radius": 1,
				"effect": "thunderstrike",
				"chain_targets": 3,
				"description": "Lightning strikes - best balance of speed and power"
			}
		
		TYPE_SAPPHIRE:
			name = "Sapphire"
			wizard_name = "Pluvius"
			element = "meteor"
			base_cooldown = 9
			movement_range = 2  # Slowest
			spell_data = {
				"damage": 40,
				"aoe_radius": 2,
				"effect": "meteor_shower",
				"description": "Highest damage meteors - slowest movement"
			}
		
		TYPE_AQUAMARINE:
			name = "Aquamarine"
			wizard_name = "Chylla"
			element = "ice"
			base_cooldown = 9
			movement_range = 3
			spell_data = {
				"damage": 20,
				"aoe_radius": 1,
				"effect": "blizzard",
				"freeze_duration": 1,
				"description": "Freezing attacks - can immobilize enemies"
			}
		
		TYPE_AMETHYST:
			name = "Amethyst"
			wizard_name = "Scylla"
			element = "wind"
			base_cooldown = 9
			movement_range = 3
			spell_data = {
				"damage": 20,
				"aoe_radius": 1,
				"effect": "wind_blade",
				"knockback": 2,
				"description": "Wind attacks - can push enemies back"
			}
		
		TYPE_PEARL:
			name = "Pearl"
			wizard_name = "Skulryk"
			element = "poison"
			base_cooldown = 9
			movement_range = 3
			spell_data = {
				"damage": 15,
				"aoe_radius": 1,
				"effect": "poison_cloud",
				"dot_damage": 5,
				"dot_duration": 3,
				"description": "Poison clouds - damage over time, weakest direct damage"
			}

# ============================================================================
# COOLDOWN MANAGEMENT
# ============================================================================

## Reduces cooldown by 1 turn (call at start of owner's turn)
func tick_cooldown() -> void:
	if current_cooldown > 0:
		current_cooldown -= 1
		cooldown_changed.emit(current_cooldown)

## Resets cooldown after use
func reset_cooldown() -> void:
	current_cooldown = base_cooldown
	cooldown_changed.emit(current_cooldown)

## Returns true if jewel is ready to use
func is_ready() -> bool:
	return current_cooldown == 0 and (uses_remaining != 0)

## Returns cooldown as percentage (0-100)
func get_cooldown_percent() -> float:
	if base_cooldown == 0:
		return 0.0
	return float(current_cooldown) / float(base_cooldown) * 100.0

## Returns human-readable cooldown status
func get_status_text() -> String:
	if uses_remaining == 0:
		return "Depleted"
	if current_cooldown == 0:
		return "Ready"
	return "%d turns" % current_cooldown

# ============================================================================
# USAGE
# ============================================================================

## Attempts to use the jewel (returns true if successful)
func use() -> bool:
	if not is_ready():
		return false
	
	if uses_remaining > 0:
		uses_remaining -= 1
	
	reset_cooldown()
	used.emit()
	return true

# ============================================================================
# SPELL EFFECTS
# ============================================================================

## Calculates damage for a spell cast
func calculate_spell_damage(distance: int = 0) -> int:
	var base: int = spell_data.get("damage", 20)
	
	# Some jewels have damage falloff at range
	match element:
		"meteor":
			# Meteors do full damage regardless of range
			pass
		_:
			# Others lose 10% per hex after first
			if distance > 1:
				base = int(base * max(0.5, 1.0 - (distance - 1) * 0.1))
	
	# Add some variance
	var variance := randf_range(0.9, 1.1)
	return max(1, int(base * variance))

## Gets area of effect radius
func get_aoe_radius() -> int:
	return spell_data.get("aoe_radius", 1)

## Gets special effect type
func get_effect_type() -> String:
	return spell_data.get("effect", "")

## Gets effect description
func get_description() -> String:
	return spell_data.get("description", "")

# ============================================================================
# SERIALIZATION
# ============================================================================

func to_dict() -> Dictionary:
	return {
		"type": jewel_type,
		"cooldown": current_cooldown,
		"uses": uses_remaining
	}

static func from_dict(d: Dictionary) -> Jewel:
	var jewel := Jewel.new(d.get("type", ""))
	jewel.current_cooldown = d.get("cooldown", 0)
	jewel.uses_remaining = d.get("uses", -1)
	return jewel

# ============================================================================
# UTILITY
# ============================================================================

func _to_string() -> String:
	return "Jewel[%s] %s (%s) - %s" % [
		jewel_type, wizard_name, element, get_status_text()
	]

## Returns true if this is the tyrant's exclusive Fire Dragon
func is_tyrant_exclusive() -> bool:
	return jewel_type == TYPE_RUBY
