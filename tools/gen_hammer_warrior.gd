@tool
extends EditorScript

# Hammer Warrior SpriteFrames Generator
# AI-generated sprite sheet based on existing warrior format
# Frame size: 16x16
# 8 directions: n, ne, e, se, s, sw, w, nw
# Layout: idle (8 rows) + walk (4 rows - might be 8?) + attack (8 rows)

func _run() -> void:
	print("=== Hammer Warrior SpriteFrames Generator ===\n")
	
	var sprite_frames := SpriteFrames.new()
	
	var texture: Texture2D = load("res://assets/Warriors/Hammer_Warrior.png")
	if not texture:
		print("ERROR: Could not load Hammer_Warrior.png!")
		print("Make sure to save the sprite sheet to: assets/Warriors/Hammer_Warrior.png")
		return
	
	var frame_size := Vector2(16, 16)
	var dirs: Array[String] = ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
	
	# Based on the image (12 rows total):
	# Rows 0-7: idle (8 directions, 4 frames each)
	# Rows 8-11: attack (4 directions? or fewer frames?)
	# 
	# Actually looking at the image more carefully:
	# - Rows 0-7 appear to be idle/walk (8 directions)
	# - Rows 8-11 appear to be attack (4 directions x 4 frames)
	
	# Let's try a flexible approach - detect based on what exists
	
	# [anim_name, start_row, frame_count, fps, loop]
	var animations: Array = [
		["idle", 0, 4, 6.0, true],
		["walk", 4, 4, 8.0, true],  # If walk is separate from idle
		["attack", 8, 4, 10.0, false],
	]
	
	# Alternative: Maybe it's just idle (8 rows) + attack (4 rows)
	# Let's generate both patterns and see what works
	
	# Pattern A: idle rows 0-7 (all 8 directions), attack rows 8-11 (4 directions)
	print("Trying Pattern A: 8-dir idle + 4-dir attack...")
	_generate_pattern_a(sprite_frames, texture, frame_size, dirs)
	
	var output_path := "res://assets/animations/hammer_warrior.tres"
	var err := ResourceSaver.save(sprite_frames, output_path)
	
	if err == OK:
		print("\nSUCCESS: Saved to %s" % output_path)
		print("\nAnimations created:")
		for anim_name in sprite_frames.get_animation_names():
			print("  - %s" % anim_name)
	else:
		print("\nERROR: Failed to save (code %d)" % err)

func _generate_pattern_a(sprite_frames: SpriteFrames, texture: Texture2D, frame_size: Vector2, dirs: Array) -> void:
	# Idle - 8 directions, 4 frames each (rows 0-7)
	for dir_idx in range(8):
		var dir: String = dirs[dir_idx]
		var full_name := "idle_" + dir
		
		sprite_frames.add_animation(full_name)
		sprite_frames.set_animation_loop(full_name, true)
		sprite_frames.set_animation_speed(full_name, 6.0)
		
		for f in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(
				f * frame_size.x,
				dir_idx * frame_size.y,
				frame_size.x,
				frame_size.y
			)
			sprite_frames.add_frame(full_name, atlas)
	
	print("  Created: idle_* (8 directions, 4 frames)")
	
	# Attack - might be rows 8-11, possibly fewer directions
	# Let's try 4 directions for attack (cardinal directions)
	var attack_dirs: Array[String] = ["s", "n", "e", "w"]  # Row order might vary
	for dir_idx in range(4):
		var dir: String = attack_dirs[dir_idx]
		var full_name := "attack_" + dir
		
		sprite_frames.add_animation(full_name)
		sprite_frames.set_animation_loop(full_name, false)
		sprite_frames.set_animation_speed(full_name, 10.0)
		
		for f in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(
				f * frame_size.x,
				(8 + dir_idx) * frame_size.y,
				frame_size.x,
				frame_size.y
			)
			sprite_frames.add_frame(full_name, atlas)
	
	print("  Created: attack_* (4 directions, 4 frames)")
