# gen_tiny_rpg_characters.gd
#
# Purpose: Generator script for Tiny RPG Character Asset Pack sprites
# Usage: Run from Godot Editor (Tools menu) or as standalone scene
# 
# Features:
#   - Creates SpriteFrames from separate animation files
#   - Handles 100x100 frame size with configurable scale
#   - Generates both Soldier and Orc characters
#   - Saves .tres files to resources/characters/
#
# Source assets:
#   /home/sloppymo/Pictures/Purchased Assets 2/Tiny RPG Character Asset Pack v1.03 -Free Soldier&Orc

@tool
extends EditorScript  # Can run from Editor's Script panel (File -> Run)

#region Configuration
## Source directory for Tiny RPG assets
const SOURCE_DIR = "/home/sloppymo/Pictures/Purchased Assets 2/Tiny RPG Character Asset Pack v1.03 -Free Soldier&Orc/Characters(100x100)"

## Output directory for generated resources
const OUTPUT_DIR = "res://resources/characters/tiny_rpg"

## Frame dimensions (from source sprites)
const FRAME_WIDTH = 100
const FRAME_HEIGHT = 100

## Animation speeds (frames per second)
const ANIM_SPEEDS = {
	"idle": 6.0,
	"walk": 10.0,
	"attack01": 12.0,
	"attack02": 12.0,
	"attack03": 14.0,
	"hurt": 8.0,
	"death": 6.0,
}

## Loop settings
const LOOP_ANIMATIONS = ["idle", "walk"]
#endregion


func _run():
	"""Main entry point when run from Editor."""
	print("=== Tiny RPG Character Generator ===")
	
	# Ensure output directory exists
	_ensure_dir(OUTPUT_DIR)
	
	# Generate Soldier
	_generate_character("Soldier", "Soldier/Soldier", [
		{"name": "idle", "file": "Soldier-Idle.png", "frames": 6},
		{"name": "walk", "file": "Soldier-Walk.png", "frames": 8},
		{"name": "attack01", "file": "Soldier-Attack01.png", "frames": 6},
		{"name": "attack02", "file": "Soldier-Attack02.png", "frames": 6},
		{"name": "attack03", "file": "Soldier-Attack03.png", "frames": 9},
		{"name": "hurt", "file": "Soldier-Hurt.png", "frames": 4},
		{"name": "death", "file": "Soldier-Death.png", "frames": 4},
	])
	
	# Generate Orc
	_generate_character("Orc", "Orc/Orc", [
		{"name": "idle", "file": "Orc-Idle.png", "frames": 6},
		{"name": "walk", "file": "Orc-Walk.png", "frames": 8},
		{"name": "attack01", "file": "Orc-Attack01.png", "frames": 6},
		{"name": "attack02", "file": "Orc-Attack02.png", "frames": 6},
		{"name": "hurt", "file": "Orc-Hurt.png", "frames": 4},
		{"name": "death", "file": "Orc-Death.png", "frames": 4},
	])
	
	# Generate Arrow projectile
	_generate_projectile()
	
	print("\n=== Generation Complete ===")
	print("Files saved to: " + OUTPUT_DIR)


func _generate_character(char_name: String, char_path: String, animations: Array) -> void:
	"""Generate SpriteFrames resource for a character.
	
	Args:
		char_name: Character name (e.g., "Soldier", "Orc")
		char_path: Subpath to character folder
		animations: Array of animation definitions
	"""
	print("\nGenerating " + char_name + "...")
	
	var sprite_frames = SpriteFrames.new()
	
	for anim in animations:
		var anim_name = anim["name"]
		var file_name = anim["file"]
		var frame_count = anim["frames"]
		
		var full_path = SOURCE_DIR + "/" + char_path + "/" + file_name
		var texture = load(full_path)
		
		if texture == null:
			push_warning("Failed to load: " + full_path)
			continue
		
		# Add animation to SpriteFrames
		sprite_frames.add_animation(anim_name)
		sprite_frames.set_animation_speed(anim_name, ANIM_SPEEDS.get(anim_name, 10.0))
		sprite_frames.set_animation_loop(anim_name, anim_name in LOOP_ANIMATIONS)
		
		# Calculate frame dimensions
		var tex_width = texture.get_width()
		var tex_height = texture.get_height()
		var frames_per_row = tex_width / FRAME_WIDTH
		
		# Add frames
		for i in range(frame_count):
			var row = i / frames_per_row
			var col = i % frames_per_row
			
			var atlas_tex = AtlasTexture.new()
			atlas_tex.atlas = texture
			atlas_tex.region = Rect2(
				col * FRAME_WIDTH,
				row * FRAME_HEIGHT,
				FRAME_WIDTH,
				FRAME_HEIGHT
			)
			
			sprite_frames.add_frame(anim_name, atlas_tex)
		
		print("  + " + anim_name + " (" + str(frame_count) + " frames)")
	
	# Save the resource
	var output_path = OUTPUT_DIR + "/" + char_name.to_lower() + "_frames.tres"
	var err = ResourceSaver.save(sprite_frames, output_path)
	
	if err == OK:
		print("  Saved: " + output_path)
	else:
		push_error("Failed to save: " + output_path + " (error " + str(err) + ")")


func _generate_projectile() -> void:
	"""Generate arrow projectile texture reference."""
	print("\nGenerating Arrow Projectile...")
	
	var arrow_path = SOURCE_DIR + "/../../Arrow(Projectile)/Arrow01(32x32).png"
	var texture = load(arrow_path)
	
	if texture == null:
		push_warning("Failed to load arrow: " + arrow_path)
		return
	
	# Save as standalone texture resource for easy reference
	var output_path = OUTPUT_DIR + "/arrow_projectile.tres"
	var err = ResourceSaver.save(texture, output_path)
	
	if err == OK:
		print("  Saved: " + output_path)
	else:
		push_error("Failed to save arrow: " + output_path)


func _ensure_dir(path: String) -> void:
	"""Ensure output directory exists."""
	var dir = DirAccess.open("res://")
	if dir == null:
		push_error("Cannot open res://")
		return
	
	# Create nested directories
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


# Standalone execution (for testing outside Editor)
func _standalone():
	"""Can be called from a test scene."""
	_run()
