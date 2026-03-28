extends Node

const SAVE_DIR = "user://saves/"

func _ready():
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

## Check if a save file exists (for main menu compatibility)
func has_save(slot: int = 0) -> bool:
	var path = SAVE_DIR + "save_%d.json" % slot
	return FileAccess.file_exists(path)

func save_game(slot: int) -> bool:
	var save_data = {
		"version": "1.1",
		"timestamp": Time.get_unix_time_from_system(),
		"provinces": [],
		"factions": [],
		"characters": [],
		"player_faction_id": String(GameState.player_faction_id),
		"current_month": GameState.current_month,
		"current_year": GameState.current_year
	}
	
	for province in GameState.provinces.values():
		save_data.provinces.append(province.to_dict())
	
	for faction in GameState.factions.values():
		save_data.factions.append(faction.to_dict())
	
	for character in GameState.characters.values():
		save_data.characters.append(character.to_dict())
	
	var path = SAVE_DIR + "save_%d.json" % slot
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		EventBus.GameSaved.emit(slot)
		print("Game saved to ", path)
		return true
	push_error("Failed to save game to " + path)
	return false

func load_game(slot: int) -> bool:
	var path = SAVE_DIR + "save_%d.json" % slot
	if not FileAccess.file_exists(path):
		push_warning("Save file not found: " + path)
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("JSON parse error: " + json.get_error_message())
		return false
	
	var data = json.data
	
	GameState.provinces.clear()
	GameState.factions.clear()
	GameState.characters.clear()
	
	for p_dict in data.provinces:
		var p = ProvinceData.new()
		p.from_dict(p_dict)
		GameState.provinces[p.id] = p
	
	# Load factions (new system, replaces families)
	var loaded_factions = data.get("factions", data.get("families", []))
	for f_dict in loaded_factions:
		var f = FactionData.new()
		f.from_dict(f_dict)
		GameState.factions[f.id] = f
	
	for c_dict in data.characters:
		var c = CharacterData.new()
		c.from_dict(c_dict)
		GameState.characters[c.id] = c
	
	# Restore additional game state
	GameState.player_faction_id = StringName(data.get("player_faction_id", "blanche"))
	GameState.current_month = data.get("current_month", 1)
	GameState.current_year = data.get("current_year", 1)
	
	EventBus.GameLoaded.emit(slot)
	print("Game loaded from ", path)
	return true
