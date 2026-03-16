extends Node

# LordManager - Manages all noble characters in the game
# Handles creation, capture, assignment, and recruitment of lords

const CharacterData = preload("res://resources/data_classes/character_data.gd")

# ============================================================================
# SIGNALS
# ============================================================================

signal lord_captured(lord_id: StringName, captor_faction_id: StringName, province_id: StringName)
signal lord_recruited(lord_id: StringName, new_faction_id: StringName)
signal lord_assigned(lord_id: StringName, province_id: StringName)
signal lord_removed(lord_id: StringName, province_id: StringName)
signal lord_died(lord_id: StringName)

# ============================================================================
# DATA
# ============================================================================

# All characters in the game indexed by ID
var characters: Dictionary[StringName, CharacterData] = {}

# Quick lookup: faction -> array of their lords
var faction_lords: Dictionary[StringName, Array] = {}

# Quick lookup: faction -> array of captured enemy lords
var captured_lords: Dictionary[StringName, Array] = {}

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	print("=== LORD MANAGER INITIALIZING ===")
	# Defer initialization to ensure GameState is ready
	call_deferred("_initialize_characters")
	print("=== LORD MANAGER READY ===")

func _initialize_characters():
	characters.clear()
	faction_lords.clear()
	captured_lords.clear()
	
	# Wait for GameState to be ready
	if GameState == null:
		push_error("LordManager: GameState not available!")
		return
	
	# Create House Blanche (Player) nobles
	_create_blanche_nobles()
	
	# Create House Coryll nobles
	_create_coryll_nobles()
	
	# Create House Lyle nobles
	_create_lyle_nobles()
	
	# Assign initial governors to provinces
	_assign_initial_governors()
	
	print("Created %d characters" % characters.size())

func _create_blanche_nobles():
	# Lord Erin Blanche - Ruler
	var erin = CharacterData.new()
	erin.id = &"erin_blanche"
	erin.name = "Lord Erin Blanche"
	erin.family_id = &"blanche"
	erin.portrait_path = "res://assets/portraits/house_blanche/lord_blanche.png"
	erin.leadership = 75
	erin.command = 70
	erin.charm = 65
	erin.is_ruler = true
	erin.is_lord = true
	erin.loyalty = 100
	_add_character(erin)
	
	# Lady Sarah Blanche
	var sarah = CharacterData.new()
	sarah.id = &"sarah_blanche"
	sarah.name = "Lady Sarah Blanche"
	sarah.family_id = &"blanche"
	sarah.portrait_path = "res://assets/portraits/house_blanche/sister.png"
	sarah.leadership = 60
	sarah.command = 55
	sarah.charm = 80
	sarah.is_lord = true
	sarah.loyalty = 95
	_add_character(sarah)
	
	# Sir Thomas Blanche
	var thomas = CharacterData.new()
	thomas.id = &"thomas_blanche"
	thomas.name = "Sir Thomas Blanche"
	thomas.family_id = &"blanche"
	thomas.portrait_path = "res://assets/portraits/house_blanche/son.png"
	thomas.leadership = 65
	thomas.command = 75
	thomas.charm = 50
	thomas.is_lord = true
	thomas.loyalty = 90
	_add_character(thomas)

func _create_coryll_nobles():
	# Lord Marcus Coryll - Ruler
	var marcus = CharacterData.new()
	marcus.id = &"marcus_coryll"
	marcus.name = "Lord Marcus Coryll"
	marcus.family_id = &"coryll"
	marcus.portrait_path = "res://assets/portraits/house_blanche/portrait_blanche_80.png"
	marcus.leadership = 70
	marcus.command = 80
	marcus.charm = 60
	marcus.is_ruler = true
	marcus.is_lord = true
	marcus.loyalty = 100
	_add_character(marcus)
	
	# Lady Elena Coryll
	var elena = CharacterData.new()
	elena.id = &"elena_coryll"
	elena.name = "Lady Elena Coryll"
	elena.family_id = &"coryll"
	elena.portrait_path = "res://assets/portraits/house_blanche/sister.png"
	elena.leadership = 55
	elena.command = 65
	elena.charm = 75
	elena.is_lord = true
	elena.loyalty = 85
	_add_character(elena)
	
	# Sir Victor Coryll
	var victor = CharacterData.new()
	victor.id = &"victor_coryll"
	victor.name = "Sir Victor Coryll"
	victor.family_id = &"coryll"
	victor.portrait_path = "res://assets/portraits/house_blanche/son.png"
	victor.leadership = 60
	victor.command = 70
	victor.charm = 55
	victor.is_lord = true
	victor.loyalty = 88
	_add_character(victor)
	
	# Dame Isolde Coryll
	var isolde = CharacterData.new()
	isolde.id = &"isolde_coryll"
	isolde.name = "Dame Isolde Coryll"
	isolde.family_id = &"coryll"
	isolde.portrait_path = "res://assets/portraits/house_blanche/sister.png"
	isolde.leadership = 65
	isolde.command = 60
	isolde.charm = 70
	isolde.is_lord = true
	isolde.loyalty = 90
	_add_character(isolde)

func _create_lyle_nobles():
	# Lord Duncan Lyle - Ruler
	var duncan = CharacterData.new()
	duncan.id = &"duncan_lyle"
	duncan.name = "Lord Duncan Lyle"
	duncan.family_id = &"lyle"
	duncan.portrait_path = "res://assets/portraits/house_lyle/lord_lyle.png"
	duncan.leadership = 80
	duncan.command = 75
	duncan.charm = 65
	duncan.is_ruler = true
	duncan.is_lord = true
	duncan.loyalty = 100
	_add_character(duncan)
	
	# Sir Alistair Lyle
	var alistair = CharacterData.new()
	alistair.id = &"alistair_lyle"
	alistair.name = "Sir Alistair Lyle"
	alistair.family_id = &"lyle"
	alistair.portrait_path = "res://assets/portraits/house_blanche/son.png"
	alistair.leadership = 60
	alistair.command = 70
	alistair.charm = 55
	alistair.is_lord = true
	alistair.loyalty = 85
	_add_character(alistair)
	
	# Lady Fiona Lyle
	var fiona = CharacterData.new()
	fiona.id = &"fiona_lyle"
	fiona.name = "Lady Fiona Lyle"
	fiona.family_id = &"lyle"
	fiona.portrait_path = "res://assets/portraits/house_blanche/sister.png"
	fiona.leadership = 55
	fiona.command = 60
	fiona.charm = 80
	fiona.is_lord = true
	fiona.loyalty = 90
	_add_character(fiona)
	
	# Sir Rowan Lyle
	var rowan = CharacterData.new()
	rowan.id = &"rowan_lyle"
	rowan.name = "Sir Rowan Lyle"
	rowan.family_id = &"lyle"
	rowan.portrait_path = "res://assets/portraits/house_blanche/son.png"
	rowan.leadership = 50
	rowan.command = 75
	rowan.charm = 60
	rowan.is_lord = true
	rowan.loyalty = 88
	_add_character(rowan)

func _add_character(char_data: CharacterData) -> void:
	characters[char_data.id] = char_data
	
	# Add to faction lookup
	if not faction_lords.has(char_data.family_id):
		faction_lords[char_data.family_id] = []
	faction_lords[char_data.family_id].append(char_data.id)

func _assign_initial_governors():
	# Blanche provinces
	assign_governor(&"dunmoor", &"erin_blanche")  # Lord Erin rules Dunmoor
	assign_governor(&"westfall", &"sarah_blanche")  # Lady Sarah rules Westfall
	
	# Coryll provinces
	assign_governor(&"carveti", &"marcus_coryll")  # Lord Marcus rules Carveti
	assign_governor(&"banshea", &"elena_coryll")  # Lady Elena rules Banshea
	assign_governor(&"northreach", &"victor_coryll")  # Sir Victor rules Northreach
	
	# Lyle provinces
	assign_governor(&"cobrige", &"duncan_lyle")  # Lord Duncan rules Cobrige
	assign_governor(&"petaria", &"alistair_lyle")  # Sir Alistair rules Petaria
	assign_governor(&"eastmark", &"fiona_lyle")  # Lady Fiona rules Eastmark

# ============================================================================
# PUBLIC API - Character Access
# ============================================================================

func get_character(char_id: StringName) -> CharacterData:
	return characters.get(char_id)

func get_faction_lords(faction_id: StringName) -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	var lord_ids = faction_lords.get(faction_id, [])
	for id in lord_ids:
		var lord = characters.get(id)
		if lord and not lord.is_captured:
			result.append(lord)
	return result

func get_available_lords(faction_id: StringName) -> Array[CharacterData]:
	# Returns lords who are not governing any province and not captured
	var result: Array[CharacterData] = []
	var lord_ids = faction_lords.get(faction_id, [])
	for id in lord_ids:
		var lord = characters.get(id)
		if lord and not lord.is_captured and lord.governor_of == &"":
			result.append(lord)
	return result

func get_captured_lords(faction_id: StringName) -> Array[CharacterData]:
	# Returns enemy lords captured by this faction
	var result: Array[CharacterData] = []
	var captured_ids = captured_lords.get(faction_id, [])
	for id in captured_ids:
		var lord = characters.get(id)
		if lord and lord.is_captured and lord.captured_by == faction_id:
			result.append(lord)
	return result

func get_province_governor(province_id: StringName) -> CharacterData:
	var gs = GameState
	if gs == null:
		return null
	
	var province = gs.provinces.get(province_id)
	if province == null or province.governor_id == &"":
		return null
	
	return characters.get(province.governor_id)

# ============================================================================
# PUBLIC API - Governor Assignment
# ============================================================================

func assign_governor(province_id: StringName, lord_id: StringName) -> bool:
	var gs = GameState
	if gs == null:
		return false
	
	var province = gs.provinces.get(province_id)
	var lord = characters.get(lord_id)
	
	if province == null or lord == null:
		return false
	
	# Remove current governor if any
	if province.governor_id != &"":
		var current_gov = characters.get(province.governor_id)
		if current_gov:
			current_gov.governor_of = &""
	
	# Assign new governor
	province.governor_id = lord_id
	lord.governor_of = province_id
	
	lord_assigned.emit(lord_id, province_id)
	print("LordManager: %s assigned to govern %s" % [lord.name, province.province_name])
	return true

func remove_governor(province_id: StringName) -> bool:
	var gs = GameState
	if gs == null:
		return false
	
	var province = gs.provinces.get(province_id)
	if province == null or province.governor_id == &"":
		return false
	
	var lord = characters.get(province.governor_id)
	if lord:
		lord.governor_of = &""
		lord_removed.emit(lord.id, province_id)
	
	province.governor_id = &""
	return true

# ============================================================================
# PUBLIC API - Capture and Recruitment
# ============================================================================

func capture_lord(lord_id: StringName, captor_faction_id: StringName, province_id: StringName) -> bool:
	var lord = characters.get(lord_id)
	if lord == null:
		return false
	
	if lord.is_captured:
		push_warning("Lord %s is already captured" % lord.name)
		return false
	
	# Remove from current province if governing
	if lord.governor_of != &"":
		remove_governor(lord.governor_of)
	
	# Set captured status
	lord.is_captured = true
	lord.captured_by = captor_faction_id
	
	# Add to captor's prisoner list
	if not captured_lords.has(captor_faction_id):
		captured_lords[captor_faction_id] = []
	captured_lords[captor_faction_id].append(lord_id)
	
	lord_captured.emit(lord_id, captor_faction_id, province_id)
	print("LordManager: %s captured by %s at %s" % [lord.name, captor_faction_id, province_id])
	return true

func recruit_lord(lord_id: StringName, new_faction_id: StringName, cost: int = GameConfig.LORD_RECRUIT_COST) -> bool:
	var lord = characters.get(lord_id)
	if lord == null:
		return false
	
	if not lord.is_captured:
		push_warning("Lord %s is not captured" % lord.name)
		return false
	
	if lord.captured_by != new_faction_id:
		push_warning("Lord %s is not captured by %s" % [lord.name, new_faction_id])
		return false
	
	var gs = GameState
	if gs == null:
		return false
	
	var faction = gs.factions.get(new_faction_id)
	if faction == null:
		return false
	
	if faction.gold < cost:
		push_warning("Not enough gold to recruit %s (need %d)" % [lord.name, cost])
		return false
	
	# Pay recruitment cost
	faction.gold -= cost
	
	# Remove from old faction
	var old_faction = lord.family_id
	if faction_lords.has(old_faction):
		faction_lords[old_faction].erase(lord_id)
	
	# Remove from captured list
	if captured_lords.has(new_faction_id):
		captured_lords[new_faction_id].erase(lord_id)
	
	# Change faction
	lord.family_id = new_faction_id
	lord.is_captured = false
	lord.captured_by = &""
	lord.loyalty = GameConfig.LORD_BASE_LOYALTY  # Start with moderate loyalty
	
	# Add to new faction
	if not faction_lords.has(new_faction_id):
		faction_lords[new_faction_id] = []
	faction_lords[new_faction_id].append(lord_id)
	
	lord_recruited.emit(lord_id, new_faction_id)
	print("LordManager: %s recruited by %s for %d gold" % [lord.name, new_faction_id, cost])
	return true

func release_lord(lord_id: StringName) -> bool:
	var lord = characters.get(lord_id)
	if lord == null:
		return false
	
	if not lord.is_captured:
		return false
	
	var captor = lord.captured_by
	
	# Remove from captured list
	if captured_lords.has(captor):
		captured_lords[captor].erase(lord_id)
	
	# Release (returns to original faction but with reduced loyalty)
	lord.is_captured = false
	lord.captured_by = &""
	lord.loyalty = max(0, lord.loyalty - GameConfig.LORD_RELEASE_LOYALTY_PENALTY)  # Lose loyalty
	
	print("LordManager: %s released, loyalty reduced to %d" % [lord.name, lord.loyalty])
	return true

func execute_lord(lord_id: StringName) -> bool:
	var lord = characters.get(lord_id)
	if lord == null:
		return false
	
	if not lord.is_captured:
		return false
	
	var captor = lord.captured_by
	
	# Remove from captured list
	if captured_lords.has(captor):
		captured_lords[captor].erase(lord_id)
	
	# Remove from faction
	if faction_lords.has(lord.family_id):
		faction_lords[lord.family_id].erase(lord_id)
	
	# Mark as dead/remove from characters
	characters.erase(lord_id)
	
	lord_died.emit(lord_id)
	print("LordManager: %s executed" % lord.name)
	return true

# ============================================================================
# PUBLIC API - Combat Effects
# ============================================================================

func get_battle_bonus(province_id: StringName) -> float:
	# Returns a multiplier based on the governor's command stat
	var governor = get_province_governor(province_id)
	if governor == null:
		return 1.0  # No bonus
	
	# Command stat 50 = 1.0, 100 = 1.5, 0 = 0.5
	return 0.5 + (governor.command / 100.0)

func get_province_loyalty_bonus(province_id: StringName) -> int:
	# Returns a loyalty bonus based on governor's leadership
	var governor = get_province_governor(province_id)
	if governor == null:
		return 0
	
	# Leadership / 5 = bonus (max 20)
	return governor.leadership / 5

# ============================================================================
# SERIALIZATION
# ============================================================================

func to_dict() -> Dictionary:
	var char_list = []
	for char_data in characters.values():
		char_list.append(char_data.to_dict())
	
	return {
		"characters": char_list,
		"captured_lords": _serialize_captured()
	}

func from_dict(data: Dictionary) -> void:
	characters.clear()
	faction_lords.clear()
	captured_lords.clear()
	
	# Load characters
	for char_dict in data.get("characters", []):
		var char_data = CharacterData.new()
		char_data.from_dict(char_dict)
		_add_character(char_data)
	
	# Restore captured status
	_load_captured(data.get("captured_lords", {}))

func _serialize_captured() -> Dictionary:
	var result = {}
	for faction_id in captured_lords:
		result[String(faction_id)] = captured_lords[faction_id].map(func(id): return String(id))
	return result

func _load_captured(data: Dictionary) -> void:
	for faction_id_str in data:
		var faction_id = StringName(faction_id_str)
		captured_lords[faction_id] = []
		for lord_id_str in data[faction_id_str]:
			var lord_id = StringName(lord_id_str)
			captured_lords[faction_id].append(lord_id)
			
			# Update character captured status
			var lord = characters.get(faction_id)
			if lord:
				lord.is_captured = true
				lord.captured_by = faction_id
