class_name UnitConfig
extends Resource
## Configuration data for a unit type.

@export var unit_name: String = "Unknown"
@export var max_hp: int = 100
@export var damage: int = 10
@export var speed: float = 60.0
@export var attack_cooldown: float = 1.0
@export var attack_range: float = 35.0
@export var scale: float = 2.0
@export var is_mage: bool = false

## Path to non-combat sprite frames (idle, walk)
@export var nc_path: String = ""

## Path to combat sprite frames (attack, hurt, death)
@export var co_path: String = ""

## Spell type for mages (fireball, lightning, ice)
@export var spell_type: String = ""

## Secondary spell type for mages (allows hybrid mages)
@export var secondary_spell_type: String = ""

## Number of spell variants this mage can use (1-6)
@export var num_spell_variants: int = 6

## Projectile speed for mages
@export var projectile_speed: float = 200.0

## Area of effect radius for heavy units
@export var aoe_radius: float = 0.0

## If true, unit only uses _right animations with flip_h
@export var simple_facing: bool = false

## For archers - path to arrow projectile sprite frames
@export var arrow_path: String = ""

## Preloaded resources (cached at runtime)
var nc_frames: SpriteFrames = null
var co_frames: SpriteFrames = null

## Loads and caches the sprite frame resources.
func load_resources() -> void:
	if not nc_path.is_empty() and FileAccess.file_exists(nc_path):
		nc_frames = load(nc_path) as SpriteFrames
	if not co_path.is_empty() and FileAccess.file_exists(co_path):
		co_frames = load(co_path) as SpriteFrames

## Returns true if resources are loaded.
func is_loaded() -> bool:
	return nc_frames != null or co_frames != null

## Static factory method for creating configs with optional parameters.
static func create(
	p_name: String,
	p_hp: int,
	p_damage: int,
	p_speed: float,
	p_cooldown: float,
	p_range: float,
	p_scale: float,
	p_mage: bool,
	p_nc_path: String,
	p_co_path: String,
	p_spell: String = "",
	p_proj_speed: float = 200.0,
	p_aoe: float = 0.0
) -> UnitConfig:
	var config := UnitConfig.new()
	config.unit_name = p_name
	config.max_hp = p_hp
	config.damage = p_damage
	config.speed = p_speed
	config.attack_cooldown = p_cooldown
	config.attack_range = p_range
	config.scale = p_scale
	config.is_mage = p_mage
	config.nc_path = p_nc_path
	config.co_path = p_co_path
	config.spell_type = p_spell
	config.projectile_speed = p_proj_speed
	config.aoe_radius = p_aoe
	return config
