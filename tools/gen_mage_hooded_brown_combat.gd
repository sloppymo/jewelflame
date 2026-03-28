@tool
extends EditorScript

# Mage Hooded (Brown) Combat SpriteFrames Generator
# Frame size: 32x32 (combat sprites are larger)
# Directions: n, ne, e, se, s, sw, w, nw (8 directions)
# Source: assets/Citizens-Guards-Warriors/Mages/Mage_Hooded_BROWN-Combat.png

func _run() -> void:
	print("Generating Mage Hooded (Brown) Combat SpriteFrames...")
	
	var sprite_frames := SpriteFrames.new()
	
	var texture: Texture2D = load("res://assets/Citizens-Guards-Warriors/Mages/Mage_Hooded_BROWN-Combat.png")
	if not texture:
		print("ERROR: Could not load mage hooded brown combat texture!")
		return
	
	var frame_size := Vector2(32, 32)
	var cols := 4
	
	# 8 directions
	var dirs: Array[String] = ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
	
	# [anim_name, start_row, frame_count, fps, loop]
	# Based on standard combat layout
	var animations: Array = [
		["attack1", 0, 4, 10.0, false],
		["attack2", 8, 4, 10.0, false],
		["attack3", 16, 4, 10.0, false],
		["hurt", 24, 4, 8.0, false],
		["special", 32, 4, 10.0, false],
		["death", 40, 4, 6.0, false],
	]
	
	for anim in animations:
		var anim_name: String = anim[0]
		var start_row: int = anim[1]
		var frame_count: int = anim[2]
		var fps: float = anim[3]
		var loop: bool = anim[4]
		
		for dir_idx in range(8):
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
		
		print("Created animation: %s (%d directions, %d frames each)" % [anim_name, 8, frame_count])
	
	var output_path := "res://assets/animations/mage_hooded_brown_combat.tres"
	var err := ResourceSaver.save(sprite_frames, output_path)
	
	if err == OK:
		print("SUCCESS: Saved to %s" % output_path)
	else:
		print("ERROR: Failed to save (code %d)" % err)
