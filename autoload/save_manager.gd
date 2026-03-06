extends Node

const SAVE_DIR = "user://saves/"

func _ready():
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_game(slot: int) -> bool:
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"provinces": [],
		"families": [],
		"characters": []
	}
	
	for province in GameState.provinces.values():
		save_data.provinces.append(province.to_dict())
	
	for family in GameState.families.values():
		save_data.families.append(family.to_dict())
	
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
	GameState.families.clear()
	GameState.characters.clear()
	
	for p_dict in data.provinces:
		var p = ProvinceData.new()
		p.from_dict(p_dict)
		GameState.provinces[p.id] = p
	
	for f_dict in data.families:
		var f = FamilyData.new()
		f.from_dict(f_dict)
		GameState.families[f.id] = f
	
	for c_dict in data.characters:
		var c = CharacterData.new()
		c.from_dict(c_dict)
		GameState.characters[c.id] = c
	
	EventBus.GameLoaded.emit(slot)
	print("Game loaded from ", path)
	return true
