class_name ConfigLoader
## Loads and manages all unit configurations.

static var configs: Dictionary[UnitType.Enum, UnitConfig] = {}
static var is_initialized: bool = false

## Initializes all unit configurations. Call once at startup.
static func initialize() -> void:
	if is_initialized:
		return
	
	_add_config(UnitType.Enum.SWORDSHIELD, UnitConfig.create(
		"SwordShield", 120, 15, 60.0, 0.8, 35.0, 2.0, false,
		"res://assets/animations/swordshield_non_combat.tres",
		"res://assets/animations/swordshield_combat.tres"
	))
	
	var archer_config := UnitConfig.create(
		"Archer", 80, 12, 70.0, 1.0, 300.0, 2.0, false,
		"res://assets/animations/archer_non_combat.tres",
		"res://assets/animations/archer_combat.tres"
	)
	# Use 100x100 arrow for better visibility
	archer_config.arrow_path = "res://assets/Characters(100x100)/Archer/Arrow(projectile)/Arrow02(100x100).png"
	_add_config(UnitType.Enum.ARCHER, archer_config)
	
	_add_config(UnitType.Enum.KNIGHT, UnitConfig.create(
		"Knight", 150, 18, 55.0, 0.9, 40.0, 2.0, false,
		"res://assets/animations/knight_non_combat.tres",
		"res://assets/animations/knight_combat.tres"
	))
	
	_add_config(UnitType.Enum.HEAVY_KNIGHT, UnitConfig.create(
		"HeavyKnight", 200, 22, 40.0, 1.2, 45.0, 1.8, false,
		"res://assets/animations/heavy_knight_non_combat.tres",
		"res://assets/animations/heavy_knight_combat.tres",
		"", 0.0, 50.0
	))
	
	_add_config(UnitType.Enum.PALADIN, UnitConfig.create(
		"Paladin", 180, 20, 45.0, 1.0, 40.0, 1.8, false,
		"res://assets/animations/paladin_non_combat.tres",
		"res://assets/animations/paladin_combat.tres",
		"", 0.0, 50.0
	))
	
	var mage_config := UnitConfig.create(
		"Mage", 70, 30, 50.0, 1.5, 150.0, 2.0, true,
		"res://assets/animations/mage_red_non_combat.tres",
		"res://assets/animations/mage_red_combat.tres",
		"fireball", 200.0
	)
	mage_config.secondary_spell_type = "arcane"  # Fire + Arcane hybrid
	mage_config.num_spell_variants = 6
	_add_config(UnitType.Enum.MAGE, mage_config)
	
	_add_config(UnitType.Enum.ROGUE, UnitConfig.create(
		"Rogue", 90, 16, 85.0, 0.6, 30.0, 2.0, false,
		"res://assets/animations/rogue_nc_daggers.tres",
		"res://assets/animations/rogue_combat_fx.tres"
	))
	
	_add_config(UnitType.Enum.ROGUE_HOODED, UnitConfig.create(
		"RogueHooded", 95, 17, 80.0, 0.65, 30.0, 2.0, false,
		"res://assets/animations/rogue_hooded_nc_daggers.tres",
		"res://assets/animations/rogue_hooded_combat_fx.tres"
	))
	
	var mage_hooded_config := UnitConfig.create(
		"MageHoodedBrown", 75, 28, 48.0, 1.4, 140.0, 2.0, true,
		"res://assets/animations/mage_hooded_brown_non_combat.tres",
		"res://assets/animations/mage_hooded_brown_combat.tres",
		"lightning", 250.0
	)
	mage_hooded_config.secondary_spell_type = "fireball"  # Storm + Fire hybrid
	mage_hooded_config.num_spell_variants = 6
	_add_config(UnitType.Enum.MAGE_HOODED_BROWN, mage_hooded_config)
	
	var ice_mage_config := UnitConfig.create(
		"MageMascDKGrey", 80, 26, 48.0, 1.3, 145.0, 2.0, true,
		"res://assets/animations/mage_masc_dkgrey_non_combat.tres",
		"res://assets/animations/mage_masc_dkgrey_combat.tres",
		"ice", 180.0
	)
	ice_mage_config.secondary_spell_type = "lightning"  # Ice + Storm hybrid
	ice_mage_config.num_spell_variants = 6
	_add_config(UnitType.Enum.MAGE_MASC_DKGREY, ice_mage_config)
	
	# Creatures
	_add_config(UnitType.Enum.ORC, UnitConfig.create(
		"Orc", 100, 18, 55.0, 1.0, 35.0, 2.0, false,
		"res://assets/animations/creatures/orc.tres",
		"res://assets/animations/creatures/orc.tres"
	))
	
	_add_config(UnitType.Enum.SKELLY, UnitConfig.create(
		"Skelly", 50, 14, 45.0, 0.9, 32.0, 2.0, false,
		"res://assets/animations/creatures/skelly.tres",
		"res://assets/animations/creatures/skelly.tres"
	))
	
	var dragon_config := UnitConfig.create(
		"DragonGreen", 800, 300, 70.0, 2.5, 300.0, 1.5, true,
		"res://assets/animations/dragon_green.tres",
		"res://assets/animations/dragon_green.tres",
		"fireball", 350.0, 150.0
	)
	dragon_config.simple_facing = true
	_add_config(UnitType.Enum.DRAGON_GREEN, dragon_config)
	
	# Additional Mage Types
	var fire_skull_config := UnitConfig.create(
		"FireSkull", 60, 35, 55.0, 1.2, 160.0, 1.8, true,
		"res://assets/animations/skullcap_warrior_non_combat.tres",
		"res://assets/animations/skullcap_warrior_combat.tres",
		"fire", 220.0
	)
	fire_skull_config.secondary_spell_type = "arcane"  # Fire + Void magic
	fire_skull_config.num_spell_variants = 6
	_add_config(UnitType.Enum.FIRE_SKULL, fire_skull_config)
	
	var wraith_config := UnitConfig.create(
		"Wraith", 90, 28, 60.0, 1.3, 140.0, 1.9, true,
		"res://assets/animations/creatures/wraith.tres" if FileAccess.file_exists("res://assets/animations/creatures/wraith.tres") else "res://assets/animations/skullcap_warrior_non_combat.tres",
		"res://assets/animations/creatures/wraith.tres" if FileAccess.file_exists("res://assets/animations/creatures/wraith.tres") else "res://assets/animations/skullcap_warrior_combat.tres",
		"arcane", 240.0
	)
	wraith_config.secondary_spell_type = "ice"  # Void + Ice
	wraith_config.num_spell_variants = 6
	_add_config(UnitType.Enum.WRAITH, wraith_config)
	
	# Preload all resources
	for config in configs.values():
		config.load_resources()
	
	is_initialized = true
	print("ConfigLoader: Loaded ", configs.size(), " unit configurations")

static func _add_config(type: UnitType.Enum, config: UnitConfig) -> void:
	configs[type] = config

## Returns the config for a unit type.
static func get_config(type: UnitType.Enum) -> UnitConfig:
	if not is_initialized:
		initialize()
	return configs.get(type, null)

## Returns an array of all unit names.
static func get_all_names() -> Array[String]:
	if not is_initialized:
		initialize()
	var names: Array[String] = []
	for config in configs.values():
		names.append(config.unit_name)
	names.sort()
	return names

## Returns the unit type enum for a given name.
static func get_type_by_name(name: String) -> UnitType.Enum:
	if not is_initialized:
		initialize()
	for type in configs.keys():
		if configs[type].unit_name == name:
			return type
	return UnitType.Enum.KNIGHT
