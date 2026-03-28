@tool
extends EditorScript

# Creature Extended Pack - All Creatures Generator
# Frame size: 16x16
# Layout: 4 columns × N rows (varies by creature)
# Directions: down, up, right, left (4 rows per animation)

func _run() -> void:
	print("=== Creature Extended Pack - Generating All SpriteFrames ===\n")
	
	# Standard 14-row creatures (4 directions × 3-4 animations)
	_generate_standard_creature(
		"goblin",
		"res://assets/Creature Extended- Supporter Pack/goblin.png",
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["attack", 8, 4, 10.0, false],
			["hurt", 12, 2, 8.0, false],
		]
	)
	
	_generate_standard_creature(
		"goblin_slinger",
		"res://assets/Creature Extended- Supporter Pack/goblin_slinger.png",
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["attack", 8, 4, 10.0, false],
			["hurt", 12, 2, 8.0, false],
		]
	)
	
	_generate_standard_creature(
		"mummy",
		"res://assets/Creature Extended- Supporter Pack/mummy.png",
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["attack", 8, 4, 10.0, false],
			["hurt", 12, 2, 8.0, false],
		]
	)
	
	_generate_standard_creature(
		"orc",
		"res://assets/Creature Extended- Supporter Pack/orc.png",
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["attack", 8, 4, 10.0, false],
			["hurt", 12, 2, 8.0, false],
		]
	)
	
	_generate_standard_creature(
		"orc_archer",
		"res://assets/Creature Extended- Supporter Pack/orc_archer.png",
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["attack", 8, 4, 10.0, false],
			["hurt", 12, 2, 8.0, false],
		]
	)
	
	_generate_standard_creature(
		"orc_champion",
		"res://assets/Creature Extended- Supporter Pack/orc_champion.png",
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["attack", 8, 4, 10.0, false],
			["hurt", 12, 2, 8.0, false],
		]
	)
	
	_generate_standard_creature(
		"orc_soldier",
		"res://assets/Creature Extended- Supporter Pack/orc_soldier.png",
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["attack", 8, 4, 10.0, false],
			["hurt", 12, 2, 8.0, false],
		]
	)
	
	_generate_standard_creature(
		"orc_soldier_unarmoured",
		"res://assets/Creature Extended- Supporter Pack/orc_soldier_unarmoured.png",
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["attack", 8, 4, 10.0, false],
			["hurt", 12, 2, 8.0, false],
		]
	)
	
	_generate_standard_creature(
		"skelly",
		"res://assets/Creature Extended- Supporter Pack/skelly.png",
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["attack", 8, 4, 10.0, false],
			["hurt", 12, 2, 8.0, false],
		]
	)
	
	_generate_standard_creature(
		"skelly_archer",
		"res://assets/Creature Extended- Supporter Pack/skelly_archer.png",
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["attack", 8, 4, 10.0, false],
			["hurt", 12, 2, 8.0, false],
		]
	)
	
	_generate_standard_creature(
		"skelly_warrior",
		"res://assets/Creature Extended- Supporter Pack/skelly_warrior.png",
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["attack", 8, 4, 10.0, false],
			["hurt", 12, 2, 8.0, false],
		]
	)
	
	_generate_standard_creature(
		"wraith",
		"res://assets/Creature Extended- Supporter Pack/wraith.png",
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["attack", 8, 4, 10.0, false],
			["hurt", 12, 2, 8.0, false],
		]
	)
	
	_generate_standard_creature(
		"zombie",
		"res://assets/Creature Extended- Supporter Pack/zombie.png",
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["attack", 8, 4, 10.0, false],
			["hurt", 12, 2, 8.0, false],
		]
	)
	
	_generate_standard_creature(
		"zombie_burster",
		"res://assets/Creature Extended- Supporter Pack/zombie_burster.png",
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["attack", 8, 4, 10.0, false],
			["hurt", 12, 2, 8.0, false],
		]
	)
	
	# Special creatures with different row counts
	_generate_custom_creature(
		"slime",
		"res://assets/Creature Extended- Supporter Pack/slime.png",
		8,  # 8 rows total
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
		]
	)
	
	_generate_custom_creature(
		"fire_skull",
		"res://assets/Creature Extended- Supporter Pack/fire_skull.png",
		10,  # 10 rows total
		[
			["idle", 0, 4, 6.0, true],
			["walk", 4, 4, 8.0, true],
			["attack", 8, 2, 10.0, false],
		]
	)
	
	# Projectiles and effects
	_generate_projectile(
		"fire_skull_fireball",
		"res://assets/Creature Extended- Supporter Pack/fire_skull_fireball.png",
		12, 16, 16  # 12 frames, 16x16 each
	)
	
	_generate_explosion(
		"zombie_burster_death_explosion",
		"res://assets/Creature Extended- Supporter Pack/zombie_burster_Death_Explosion.png",
		18, 16, 4  # 18 columns, 16x16, 4 rows
	)
	
	_generate_explosion(
		"zombie_burster_attack_explosion",
		"res://assets/Creature Extended- Supporter Pack/zombie_burster_Explosion_Attack.png",
		18, 16, 4  # 18 columns, 16x16, 4 rows
	)
	
	print("\n=== All Creature Extended sprites generated! ===")

func _generate_standard_creature(name: String, texture_path: String, animations: Array) -> void:
	_generate_custom_creature(name, texture_path, 14, animations)

func _generate_custom_creature(name: String, texture_path: String, total_rows: int, animations: Array) -> void:
	print("Generating: %s" % name)
	
	var sprite_frames := SpriteFrames.new()
	var texture: Texture2D = load(texture_path)
	
	if not texture:
		print("  ERROR: Could not load texture: %s" % texture_path)
		return
	
	var frame_size := Vector2(16, 16)
	var dirs: Array[String] = ["down", "up", "right", "left"]
	
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
		
		print("  - %s (%d directions, %d frames)" % [anim_name, 4, frame_count])
	
	var output_path := "res://assets/animations/creatures/%s.tres" % name
	var err := ResourceSaver.save(sprite_frames, output_path)
	
	if err == OK:
		print("  Saved: %s" % output_path)
	else:
		print("  ERROR saving: %d" % err)

func _generate_projectile(name: String, texture_path: String, frame_count: int, frame_w: int, frame_h: int) -> void:
	print("Generating: %s (projectile)" % name)
	
	var sprite_frames := SpriteFrames.new()
	var texture: Texture2D = load(texture_path)
	
	if not texture:
		print("  ERROR: Could not load texture: %s" % texture_path)
		return
	
	var frame_size := Vector2(frame_w, frame_h)
	var anim_name := "default"
	
	sprite_frames.add_animation(anim_name)
	sprite_frames.set_animation_loop(anim_name, true)
	sprite_frames.set_animation_speed(anim_name, 12.0)
	
	for f in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(
			f * frame_size.x,
			0,
			frame_size.x,
			frame_size.y
		)
		sprite_frames.add_frame(anim_name, atlas)
	
	var output_path := "res://assets/animations/creatures/%s.tres" % name
	var err := ResourceSaver.save(sprite_frames, output_path)
	
	if err == OK:
		print("  Saved: %s" % output_path)
	else:
		print("  ERROR saving: %d" % err)

func _generate_explosion(name: String, texture_path: String, cols: int, frame_size: int, rows: int) -> void:
	print("Generating: %s (explosion)" % name)
	
	var sprite_frames := SpriteFrames.new()
	var texture: Texture2D = load(texture_path)
	
	if not texture:
		print("  ERROR: Could not load texture: %s" % texture_path)
		return
	
	var frame_size_vec := Vector2(frame_size, frame_size)
	var anim_name := "default"
	var frame_count := cols * rows
	
	sprite_frames.add_animation(anim_name)
	sprite_frames.set_animation_loop(anim_name, false)
	sprite_frames.set_animation_speed(anim_name, 12.0)
	
	for r in range(rows):
		for c in range(cols):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(
				c * frame_size_vec.x,
				r * frame_size_vec.y,
				frame_size_vec.x,
				frame_size_vec.y
			)
			sprite_frames.add_frame(anim_name, atlas)
	
	var output_path := "res://assets/animations/creatures/%s.tres" % name
	var err := ResourceSaver.save(sprite_frames, output_path)
	
	if err == OK:
		print("  Saved: %s (%d frames)" % [output_path, frame_count])
	else:
		print("  ERROR saving: %d" % err)
