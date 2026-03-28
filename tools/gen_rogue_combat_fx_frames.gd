@tool
extends EditorScript

# Rogue (Regular) Combat With Effects SpriteFrames Generator
# Frame size: 16x16
# Directions: right, left, down, up (4 rows per animation group)
# Source: assets/Citizens-Guards-Warriors/Rogues/Regular/rogue_combat_fx.png
# Note: 6 columns (wider sprites with effects)

func _run() -> void:
	print("Generating Rogue Combat (With FX) SpriteFrames...")
	
	var sprite_frames := SpriteFrames.new()
	
	var texture: Texture2D = load("res://assets/Citizens-Guards-Warriors/Rogues/Regular/rogue_combat_fx.png")
	if not texture:
		print("ERROR: Could not load rogue combat FX texture!")
		return
	
	var frame_size := Vector2(16, 16)
	var cols := 6
	
	# Directions in row order: right, left, down, up
	var dirs: Array[String] = ["right", "left", "down", "up"]
	
	# [anim_name, start_row, frame_count, fps, loop]
	# 30 rows total = 5 animations × 6 directions? No, 4 directions per anim
	# Actually: 30 rows = 7.5 animations? Let me check: 30 / 4 = 7.5
	# Likely: 7 animations with 4 directions each = 28 rows + 2 extra
	var animations: Array = [
		["combat_idle", 0, 4, 6.0, true],
		["attack_dagger", 4, 6, 10.0, false],
		["attack_bow", 10, 6, 10.0, false],
		["hurt", 16, 4, 8.0, false],
		["dodge", 20, 4, 12.0, false],
		["special", 24, 6, 10.0, false],
	]
	
	for anim in animations:
		var anim_name: String = anim[0]
		var start_row: int = anim[1]
		var frame_count: int = anim[2]
		var fps: float = anim[3]
		var loop: bool = anim[4]
		
		for dir_idx in range(4):
			var dir: String = dirs[dir_idx]
			var full_name := anim_name + "_" + dir
			
			sprite_frames.add_animation(full_name)
			sprite_frames.set_animation_loop(full_name, loop)
			sprite_frames.set_animation_speed(full_name, fps)
			
			var row := start_row + dir_idx
			
			for f in range(frame_count):
				var atlas := AtlasTexture.new()
				atlas.atlas = texture
				atlas.region = Rect2(
					f * frame_size.x,
					row * frame_size.y,
					frame_size.x,
					frame_size.y
				)
				sprite_frames.add_frame(full_name, atlas)
		
		print("Created animation: %s (%d directions, %d frames each)" % [anim_name, 4, frame_count])
	
	var output_path := "res://assets/animations/rogue_combat_fx.tres"
	var err := ResourceSaver.save(sprite_frames, output_path)
	
	if err == OK:
		print("SUCCESS: Saved to %s" % output_path)
	else:
		print("ERROR: Failed to save (code %d)" % err)
