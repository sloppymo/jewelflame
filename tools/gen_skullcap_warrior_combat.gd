@tool
extends EditorScript

# Skullcap Warrior Combat SpriteFrames Generator
# Frame size: 32x32, 4-directional (down/up/right/left)
# 20 rows = 5 animations

func _run() -> void:
	print("Generating Skullcap Warrior Combat SpriteFrames...")
	
	var sprite_frames := SpriteFrames.new()
	
	var texture: Texture2D = load("res://assets/Citizens-Guards-Warriors/SkullcapWarrior/skullcap_warrior_combat_fx.png")
	if not texture:
		print("ERROR: Could not load skullcap warrior combat texture!")
		return
	
	var frame_size := Vector2(32, 32)
	var dirs: Array[String] = ["down", "up", "right", "left"]
	
	# [anim_name, start_row, frame_count, fps, loop]
	var animations: Array = [
		["combat_idle", 0, 4, 6.0, true],
		["attack_up", 4, 4, 12.0, false],
		["attack_down", 8, 4, 12.0, false],
		["attack_horizontal", 12, 4, 12.0, false],
		["attack_stab", 16, 4, 12.0, false],
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
				atlas.region = Rect2(f * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)
				atlas.filter_clip = true
				sprite_frames.add_frame(full_name, atlas)
		
		print("Created: %s (%d directions)" % [anim_name, 4])
	
	var output_path := "res://assets/animations/skullcap_warrior_combat.tres"
	var err := ResourceSaver.save(sprite_frames, output_path)
	
	if err == OK:
		print("SUCCESS: Saved to %s" % output_path)
	else:
		print("ERROR: Failed to save (code %d)" % err)
