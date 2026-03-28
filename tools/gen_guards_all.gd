@tool
extends EditorScript

# Guards Pack - All Guards Generator

func _run() -> void:
	print("=== Guards Pack - Generating All SpriteFrames ===\n")
	
	# Guard Archer
	_generate_guard_combat(
		"guard_archer",
		"res://assets/Citizens - Guards - Warriors/Guards/Guard_Archer_Combat.png",
		32, 32,
		[
			["attack1", 0, 4, 10.0, false],
			["attack2", 8, 4, 10.0, false],
			["hurt", 16, 4, 8.0, false],
			["special", 24, 4, 10.0, false],
		]
	)
	
	_generate_guard_noncombat(
		"guard_archer",
		"res://assets/Citizens - Guards - Warriors/Guards/Guard_Archer_Non-Combat.png",
		16, 16,
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["run", 8, 4, 10.0, true],
			["jump", 12, 4, 8.0, false],
			["fall", 16, 4, 8.0, false],
			["roll", 20, 4, 12.0, false],
			["death", 24, 4, 6.0, false],
		]
	)
	
	# Guard Spearman
	_generate_guard_combat(
		"guard_spearman",
		"res://assets/Citizens - Guards - Warriors/Guards/Guard_Spearman_Combat.png",
		32, 32,
		[
			["attack1", 0, 4, 10.0, false],
			["attack2", 8, 4, 10.0, false],
			["hurt", 16, 4, 8.0, false],
			["special", 24, 4, 10.0, false],
		]
	)
	
	_generate_guard_noncombat(
		"guard_spearman",
		"res://assets/Citizens - Guards - Warriors/Guards/Guard_Spearman.png",
		16, 16,
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["run", 8, 4, 10.0, true],
			["jump", 12, 4, 8.0, false],
			["fall", 16, 4, 8.0, false],
			["roll", 20, 4, 12.0, false],
			["death", 24, 4, 6.0, false],
		]
	)
	
	# Guard Swordsman
	_generate_guard_combat(
		"guard_swordsman",
		"res://assets/Citizens - Guards - Warriors/Guards/Guard_Swordman_Combat.png",
		32, 32,
		[
			["attack1", 0, 4, 10.0, false],
			["attack2", 8, 4, 10.0, false],
			["hurt", 16, 4, 8.0, false],
			["special", 24, 4, 10.0, false],
		]
	)
	
	_generate_guard_noncombat(
		"guard_swordsman",
		"res://assets/Citizens - Guards - Warriors/Guards/Guard_Swordsman.png",
		16, 16,
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["run", 8, 4, 10.0, true],
			["jump", 12, 4, 8.0, false],
			["fall", 16, 4, 8.0, false],
			["roll", 20, 4, 12.0, false],
			["death", 24, 4, 6.0, false],
		]
	)
	
	print("\n=== All Guards sprites generated! ===")

func _generate_guard_combat(name: String, texture_path: String, frame_w: int, frame_h: int, animations: Array) -> void:
	print("Generating: %s combat" % name)
	
	var sprite_frames := SpriteFrames.new()
	var texture: Texture2D = load(texture_path)
	
	if not texture:
		print("  ERROR: Could not load texture: %s" % texture_path)
		return
	
	var frame_size := Vector2(frame_w, frame_h)
	var dirs: Array[String] = ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
	
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
		
		print("  - %s (%d directions, %d frames)" % [anim_name, 8, frame_count])
	
	var output_path := "res://assets/animations/guards/%s_combat.tres" % name
	var err := ResourceSaver.save(sprite_frames, output_path)
	
	if err == OK:
		print("  Saved: %s" % output_path)
	else:
		print("  ERROR saving: %d" % err)

func _generate_guard_noncombat(name: String, texture_path: String, frame_w: int, frame_h: int, animations: Array) -> void:
	print("Generating: %s non-combat" % name)
	
	var sprite_frames := SpriteFrames.new()
	var texture: Texture2D = load(texture_path)
	
	if not texture:
		print("  ERROR: Could not load texture: %s" % texture_path)
		return
	
	var frame_size := Vector2(frame_w, frame_h)
	var dirs: Array[String] = ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
	
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
		
		print("  - %s (%d directions, %d frames)" % [anim_name, 8, frame_count])
	
	var output_path := "res://assets/animations/guards/%s_non_combat.tres" % name
	var err := ResourceSaver.save(sprite_frames, output_path)
	
	if err == OK:
		print("  Saved: %s" % output_path)
	else:
		print("  ERROR saving: %d" % err)
