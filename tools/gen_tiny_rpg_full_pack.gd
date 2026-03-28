# gen_tiny_rpg_full_pack.gd
#
# Purpose: Generator for Tiny RPG Character Asset Pack - Full 10 Characters
# Creates SpriteFrames resources from the full character pack
#
# Characters: Armored Axeman, Armored Orc, Armored Skeleton, Elite Orc, Knight,
#             Knights Templar, Orc, Skeleton, Soldier, Swordsman

@tool
extends EditorScript

const SOURCE_DIR = "/home/sloppymo/Pictures/Purchased Assets 2/Tiny RPG Character Asset Pack -Full 10 Characters"
const OUTPUT_DIR = "res://resources/characters/tiny_rpg_full"
const FRAME_SIZE = 100

# Character definitions with their animation rows
const CHARACTERS = {
	"Armored Axeman": {
		"folder": "Armored Axeman",
		"animations": [
			{"name": "idle", "row": 0, "frames": 6},
			{"name": "walk", "row": 1, "frames": 8},
			{"name": "attack01", "row": 2, "frames": 6},
			{"name": "attack02", "row": 3, "frames": 6},
			{"name": "attack03", "row": 4, "frames": 6},
			{"name": "hurt", "row": 5, "frames": 4},
			{"name": "death", "row": 6, "frames": 6},
		]
	},
	"Armored Orc": {
		"folder": "Armored Orc",
		"animations": [
			{"name": "idle", "row": 0, "frames": 6},
			{"name": "walk", "row": 1, "frames": 8},
			{"name": "attack01", "row": 2, "frames": 6},
			{"name": "attack02", "row": 3, "frames": 6},
			{"name": "attack03", "row": 4, "frames": 6},
			{"name": "block", "row": 5, "frames": 6},
			{"name": "hurt", "row": 6, "frames": 4},
			{"name": "death", "row": 7, "frames": 4},
		]
	},
	"Armored Skeleton": {
		"folder": "Armored Skeleton",
		"animations": [
			{"name": "idle", "row": 0, "frames": 6},
			{"name": "walk", "row": 1, "frames": 8},
			{"name": "attack01", "row": 2, "frames": 6},
			{"name": "attack02", "row": 3, "frames": 6},
			{"name": "hurt", "row": 4, "frames": 4},
			{"name": "death", "row": 5, "frames": 4},
		]
	},
	"Elite Orc": {
		"folder": "Elite Orc",
		"animations": [
			{"name": "idle", "row": 0, "frames": 6},
			{"name": "walk", "row": 1, "frames": 8},
			{"name": "attack01", "row": 2, "frames": 6},
			{"name": "attack02", "row": 3, "frames": 6},
			{"name": "attack03", "row": 4, "frames": 9},
			{"name": "hurt", "row": 5, "frames": 4},
			{"name": "death", "row": 6, "frames": 4},
		]
	},
	"Knight": {
		"folder": "Knight",
		"animations": [
			{"name": "idle", "row": 0, "frames": 6},
			{"name": "walk", "row": 1, "frames": 8},
			{"name": "attack01", "row": 2, "frames": 6},
			{"name": "attack02", "row": 3, "frames": 6},
			{"name": "attack03", "row": 4, "frames": 8},
			{"name": "block", "row": 5, "frames": 6},
			{"name": "hurt", "row": 6, "frames": 4},
			{"name": "death", "row": 7, "frames": 4},
		]
	},
	"Knights Templar": {
		"folder": "Knights Templar",
		"animations": [
			{"name": "idle", "row": 0, "frames": 6},
			{"name": "walk01", "row": 1, "frames": 8},
			{"name": "walk02", "row": 2, "frames": 8},
			{"name": "attack01", "row": 3, "frames": 6},
			{"name": "attack02", "row": 4, "frames": 6},
			{"name": "attack03", "row": 5, "frames": 7},
			{"name": "block", "row": 6, "frames": 6},
			{"name": "hurt", "row": 7, "frames": 4},
			{"name": "death", "row": 8, "frames": 4},
		]
	},
	"Orc": {
		"folder": "Orc",
		"animations": [
			{"name": "idle", "row": 0, "frames": 6},
			{"name": "walk", "row": 1, "frames": 8},
			{"name": "attack01", "row": 2, "frames": 6},
			{"name": "attack02", "row": 3, "frames": 6},
			{"name": "hurt", "row": 4, "frames": 4},
			{"name": "death", "row": 5, "frames": 4},
		]
	},
	"Skeleton": {
		"folder": "Skeleton",
		"animations": [
			{"name": "idle", "row": 0, "frames": 6},
			{"name": "walk", "row": 1, "frames": 8},
			{"name": "attack01", "row": 2, "frames": 6},
			{"name": "attack02", "row": 3, "frames": 6},
			{"name": "block", "row": 4, "frames": 6},
			{"name": "hurt", "row": 5, "frames": 4},
			{"name": "death", "row": 6, "frames": 4},
		]
	},
	"Soldier": {
		"folder": "Soldier",
		"animations": [
			{"name": "idle", "row": 0, "frames": 6},
			{"name": "walk", "row": 1, "frames": 8},
			{"name": "attack01", "row": 2, "frames": 6},
			{"name": "attack02", "row": 3, "frames": 6},
			{"name": "attack03", "row": 4, "frames": 9},
			{"name": "hurt", "row": 5, "frames": 4},
			{"name": "death", "row": 6, "frames": 4},
		]
	},
	"Swordsman": {
		"folder": "Swordsman",
		"animations": [
			{"name": "idle", "row": 0, "frames": 6},
			{"name": "walk", "row": 1, "frames": 8},
			{"name": "attack01", "row": 2, "frames": 6},
			{"name": "attack02", "row": 3, "frames": 6},
			{"name": "attack03", "row": 4, "frames": 9},
			{"name": "hurt", "row": 5, "frames": 4},
			{"name": "death", "row": 6, "frames": 4},
		]
	}
}

const ANIM_SPEEDS = {
	"idle": 6.0, "walk": 10.0, "walk01": 10.0, "walk02": 10.0,
	"attack01": 12.0, "attack02": 12.0, "attack03": 14.0,
	"block": 10.0, "hurt": 8.0, "death": 6.0
}

func _run():
	print("=== Tiny RPG Full Pack Generator ===")
	_ensure_dir(OUTPUT_DIR)
	
	for char_name in CHARACTERS.keys():
		_generate_character(char_name, CHARACTERS[char_name])
	
	print("\n=== Generation Complete ===")

func _generate_character(char_name: String, char_data: Dictionary) -> void:
	print("\nGenerating " + char_name + "...")
	
	var folder = char_data["folder"]
	var animations = char_data["animations"]
	
	var texture_path = SOURCE_DIR + "/" + folder + "/" + char_name + ".png"
	var texture = load(texture_path)
	
	if texture == null:
		push_warning("Failed to load: " + texture_path)
		return
	
	var sf = SpriteFrames.new()
	
	for anim in animations:
		var anim_name = anim["name"]
		var row = anim["row"]
		var frame_count = anim["frames"]
		
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, ANIM_SPEEDS.get(anim_name, 10.0))
		sf.set_animation_loop(anim_name, anim_name in ["idle", "walk", "walk01", "walk02"])
		
		# Add frames
		for i in range(frame_count):
			var atlas = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
			sf.add_frame(anim_name, atlas)
		
		print("  + " + anim_name + " (" + str(frame_count) + " frames)")
	
	# Save
	var output_path = OUTPUT_DIR + "/" + char_name.to_lower().replace(" ", "_") + "_frames.tres"
	var err = ResourceSaver.save(sf, output_path)
	
	if err == OK:
		print("  Saved: " + output_path)
	else:
		push_error("Failed to save: " + output_path)

func _ensure_dir(path: String) -> void:
	var dir = DirAccess.open("res://")
	if dir == null:
		return
	var parts = path.replace("res://", "").split("/")
	var current = "res://"
	for part in parts:
		if part.is_empty():
			continue
		current += part + "/"
		if not dir.dir_exists(part):
			dir.make_dir(part)
			dir.change_dir(part)
		else:
			dir.change_dir(part)

# Standalone execution
func _standalone():
	_run()
