extends Node

const FactionData = preload("res://resources/data_classes/faction_data.gd")
const ProvinceData = preload("res://resources/data_classes/province_data.gd")

# ============================================================================
# TYPED DATA STORAGE (New System)
# ============================================================================
var factions: Dictionary[StringName, FactionData] = {}
var provinces: Dictionary[StringName, ProvinceData] = {}

# ============================================================================
# SIGNALS
# ============================================================================
signal province_selected(province_data: ProvinceData)
signal province_ownership_changed(province_id: StringName, old_owner: StringName, new_owner: StringName)
signal troops_moved(from_id: StringName, to_id: StringName, amount: int)
signal battle_recorded(result)
signal input_enabled_changed(enabled: bool)

# ============================================================================
# STATE
# ============================================================================
var player_faction_id: StringName = &"blanche"
var selected_province_id: StringName = &""
var is_input_enabled: bool = true

# ============================================================================
# LEGACY COMPATIBILITY
# ============================================================================
const BattleData = preload("res://resources/data_classes/battle_data.gd")
var current_battle: Dictionary = {}
var current_battle_data: BattleData = null
var current_family_index: int = 0
var families_order: Array[String] = ["blanche", "lyle", "coryll"]
var current_month: int = 1
var current_year: int = 1

# Legacy dictionaries for backward compatibility
var families: Dictionary = {}  # String -> FamilyData (legacy)
var characters: Dictionary = {}  # String -> CharacterData
var selected_lord_id: String = ""

func _ready():
	print("=== GAME STATE INITIALIZING ===")
	initialize_new_game()
	print("=== GAME STATE READY ===")

# ============================================================================
# INITIALIZATION
# ============================================================================
func initialize_new_game():
	_load_factions()
	_load_provinces()
	_setup_initial_ownership()

func _load_factions():
	factions.clear()
	
	# Create Blanche (Player)
	var blanche := FactionData.new()
	blanche.id = &"blanche"
	blanche.faction_name = "House Blanche"
	blanche.color = Color(0.9, 0.9, 1.0)
	blanche.gold = 800
	blanche.is_player = true
	factions[&"blanche"] = blanche
	
	# Create Coryll
	var coryll := FactionData.new()
	coryll.id = &"coryll"
	coryll.faction_name = "House Coryll"
	coryll.color = Color(1.0, 0.3, 0.3)
	coryll.gold = 800
	coryll.is_player = false
	factions[&"coryll"] = coryll
	
	# Create Lyle
	var lyle := FactionData.new()
	lyle.id = &"lyle"
	lyle.faction_name = "House Lyle"
	lyle.color = Color(0.3, 0.6, 1.0)
	lyle.gold = 800
	lyle.is_player = false
	factions[&"lyle"] = lyle
	
	print("Loaded %d factions" % factions.size())

func _load_provinces():
	provinces.clear()
	
	# Dunmoor - Player starting province
	var dunmoor := ProvinceData.new()
	dunmoor.id = &"dunmoor"
	dunmoor.province_name = "Dunmoor"
	dunmoor.defense_level = 1
	dunmoor.base_income = 100
	dunmoor.troops = 200
	dunmoor.map_position = Vector2(200, 300)
	dunmoor.adjacent_province_ids = [&"carveti", &"cobrige"]
	dunmoor.color_code = Color(1.0, 0.0, 0.0)  # Red
	provinces[&"dunmoor"] = dunmoor
	
	# Carveti
	var carveti := ProvinceData.new()
	carveti.id = &"carveti"
	carveti.province_name = "Carveti"
	carveti.defense_level = 1
	carveti.base_income = 120
	carveti.troops = 150
	carveti.map_position = Vector2(400, 200)
	carveti.adjacent_province_ids = [&"dunmoor", &"banshea", &"petaria"]
	carveti.color_code = Color(0.0, 1.0, 0.0)  # Green
	provinces[&"carveti"] = carveti
	
	# Cobrige
	var cobrige := ProvinceData.new()
	cobrige.id = &"cobrige"
	cobrige.province_name = "Cobrige"
	cobrige.defense_level = 2
	cobrige.base_income = 80
	cobrige.troops = 180
	cobrige.map_position = Vector2(350, 450)
	cobrige.adjacent_province_ids = [&"dunmoor", &"banshea"]
	cobrige.color_code = Color(0.0, 0.0, 1.0)  # Blue
	provinces[&"cobrige"] = cobrige
	
	# Banshea
	var banshea := ProvinceData.new()
	banshea.id = &"banshea"
	banshea.province_name = "Banshea"
	banshea.defense_level = 1
	banshea.base_income = 90
	banshea.troops = 120
	banshea.map_position = Vector2(550, 350)
	banshea.adjacent_province_ids = [&"carveti", &"cobrige", &"petaria"]
	banshea.color_code = Color(1.0, 1.0, 0.0)  # Yellow
	provinces[&"banshea"] = banshea
	
	# Petaria
	var petaria := ProvinceData.new()
	petaria.id = &"petaria"
	petaria.province_name = "Petaria"
	petaria.defense_level = 3
	petaria.base_income = 150
	petaria.troops = 200
	petaria.map_position = Vector2(700, 250)
	petaria.adjacent_province_ids = [&"carveti", &"banshea"]
	petaria.color_code = Color(1.0, 0.0, 1.0)  # Magenta
	provinces[&"petaria"] = petaria
	
	print("Loaded %d provinces" % provinces.size())

func _setup_initial_ownership():
	# Blanche owns Dunmoor
	transfer_province_ownership(&"dunmoor", &"", &"blanche")
	
	# Coryll owns Carveti and Banshea
	transfer_province_ownership(&"carveti", &"", &"coryll")
	transfer_province_ownership(&"banshea", &"", &"coryll")
	
	# Lyle owns Cobrige and Petaria
	transfer_province_ownership(&"cobrige", &"", &"lyle")
	transfer_province_ownership(&"petaria", &"", &"lyle")

# ============================================================================
# PROVINCE OPERATIONS
# ============================================================================
func select_province(province_data: ProvinceData) -> void:
	if province_data:
		selected_province_id = province_data.id
		province_selected.emit(province_data)

func transfer_province_ownership(province_id: StringName, old_owner: StringName, new_owner: StringName) -> void:
	if not provinces.has(province_id):
		push_error("Invalid province ID: %s" % province_id)
		return
	
	var province: ProvinceData = provinces[province_id]
	
	# Remove from old owner
	if old_owner != &"" and factions.has(old_owner):
		factions[old_owner].remove_province(province_id)
	
	# Add to new owner
	if new_owner != &"" and factions.has(new_owner):
		factions[new_owner].add_province(province_id)
	
	province.owner_faction_id = new_owner
	province_ownership_changed.emit(province_id, old_owner, new_owner)
	
	print("Province %s transferred from %s to %s" % [province_id, old_owner, new_owner])

# ============================================================================
# UTILITY
# ============================================================================
func get_player_faction() -> FactionData:
	return factions.get(player_faction_id)

func get_current_faction() -> FactionData:
	var tm = get_node_or_null("/root/TurnManager")
	var current_id: StringName = player_faction_id
	if tm:
		current_id = tm.get_current_faction_id()
	return factions.get(current_id)

func get_faction(id: StringName) -> FactionData:
	return factions.get(id)

func get_province(id: StringName) -> ProvinceData:
	return provinces.get(id)

func set_input_enabled(enabled: bool) -> void:
	is_input_enabled = enabled
	input_enabled_changed.emit(enabled)

func record_battle_result(result) -> void:
	battle_recorded.emit(result)

# ============================================================================
# LEGACY COMPATIBILITY FUNCTIONS
# ============================================================================
func get_family(id: String) -> FamilyData:
	# Legacy compatibility
	return families.get(id)

func get_character(id: String) -> CharacterData:
	return characters.get(id)

func get_family_lords(family_id: String) -> Array:
	var family_lords = []
	for char_id in characters:
		var character = characters[char_id]
		if character.family_id == family_id and character.is_lord:
			family_lords.append(character)
	return family_lords

func check_victory_conditions() -> Dictionary:
	var result = {}
	
	for faction_id in factions:
		var faction: FactionData = factions[faction_id]
		if faction.owned_province_ids.is_empty():
			if faction_id == player_faction_id:
				result["defeat"] = true
				result["loser"] = faction_id
		elif faction.owned_province_ids.size() >= provinces.size():
			result["victory"] = true
			result["winner"] = faction_id
	
	return result

# ============================================================================
# BATTLE BRIDGE (Legacy Compatibility)
# ============================================================================
func start_battle(attacker_province_id: int, defender_province_id: int) -> Dictionary:
	"""Legacy battle start - converts int IDs to StringName."""
	# This is for backward compatibility with old save files
	push_warning("Using legacy start_battle - consider updating to use CombatResolver directly")
	return {}

func end_battle(result: Dictionary) -> void:
	"""Legacy battle end."""
	push_warning("Using legacy end_battle - consider updating to use CombatResolver directly")
