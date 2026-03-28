@tool
extends EditorScript

# Rogue (Regular) Combat Without Effects SpriteFrames Generator
# Frame size: 16x16
# Directions: right, left, down, up (4 rows per animation group)
# Source: assets/Citizens-Guards-Warriors/Rogues/Hooded/rogue_hooded_combat_no_fx.png

func _run() -> void:
	print("Generating Hooded Rogue Combat (No FX) SpriteFrames...")
	
	var sprite_frames := SpriteFrames.new()
	
	var texture: Texture2D = load("res://assets/Citizens-Guards-Warriors/Rogues/Hooded/rogue_hooded_combat_no_fx.png")
	if not texture:
		print("ERROR: Could not load rogue combat texture!")
		return
	
	var frame_size := Vector2(16, 16)
	var cols := 4
	
	# Directions in row order: right, left, down, up
	var dirs: Array[String] = ["right", "left", "down", "up"]
	
	# [anim_name, start_row, frame_count, fps, loop]
	# 20 rows total = 5 animations × 4 directions
	var animations: Array = [
		["combat_idle", 0, 4, 6.0, true],
		["attack_dagger", 4, 4, 10.0, false],
		["attack_bow", 8, 4, 10.0, false],
		["hurt", 12, 4, 8.0, false],
		["dodge", 16, 4, 12.0, false],
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
	
	var output_path := "res://assets/animations/rogue_hooded_combat_no_fx.tres"
	var err := ResourceSaver.save(sprite_frames, output_path)
	
	if err == OK:
		print("SUCCESS: Saved to %s" % output_path)
	else:
		print("ERROR: Failed to save (code %d)" % err)
