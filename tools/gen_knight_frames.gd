@tool
extends EditorScript

func _run():
	var combat_img = load("res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Combat.png")
	var noncombat_img = load("res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Non-Combat.png")
	
	if not combat_img or not noncombat_img:
		print("ERROR: Could not load sprite sheets!")
		return
		
	var sf = SpriteFrames.new()
	var fw = 16
	var fh = 16
	
	var dirs = [
		["s", 0], ["n", 1], ["se", 2], ["ne", 3],
		["e", 4], ["w", 5], ["sw", 6], ["nw", 7]
	]
	
	# Remove default animation
	if sf.has_animation("default"):
		sf.remove_animation("default")
	
	# NON-COMBAT: Idle (rows 0-7)
	for suffix_row in dirs:
		var suffix = suffix_row[0]
		var row = suffix_row[1]
		var anim_name = "idle_" + suffix
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, 6.0)
		sf.set_animation_loop(anim_name, true)
		for col in range(4):
			var atlas = AtlasTexture.new()
			atlas.atlas = noncombat_img
			atlas.region = Rect2i(col * fw, row * fh, fw, fh)
			sf.add_frame(anim_name, atlas)
		print("Created ", anim_name)
	
	# NON-COMBAT: Walk (rows 8-15)
	for suffix_row in dirs:
		var suffix = suffix_row[0]
		var row = suffix_row[1]
		var anim_name = "walk_" + suffix
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, 10.0)
		sf.set_animation_loop(anim_name, true)
		for col in range(4):
			var atlas = AtlasTexture.new()
			atlas.atlas = noncombat_img
			atlas.region = Rect2i(col * fw, (row + 8) * fh, fw, fh)
			sf.add_frame(anim_name, atlas)
		print("Created ", anim_name)
	
	# NON-COMBAT: Run (rows 16-23)
	for suffix_row in dirs:
		var suffix = suffix_row[0]
		var row = suffix_row[1]
		var anim_name = "run_" + suffix
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, 12.0)
		sf.set_animation_loop(anim_name, true)
		for col in range(4):
			var atlas = AtlasTexture.new()
			atlas.atlas = noncombat_img
			atlas.region = Rect2i(col * fw, (row + 16) * fh, fw, fh)
			sf.add_frame(anim_name, atlas)
		print("Created ", anim_name)
	
	# NON-COMBAT: Death (rows 24-30, missing NW)
	var death_rows = [["s", 24], ["n", 25], ["se", 26], ["ne", 27], ["e", 28], ["w", 29], ["sw", 30]]
	for death_data in death_rows:
		var suffix = death_data[0]
		var row = death_data[1]
		var anim_name = "death_" + suffix
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, 8.0)
		sf.set_animation_loop(anim_name, false)
		for col in range(4):
			var atlas = AtlasTexture.new()
			atlas.atlas = noncombat_img
			atlas.region = Rect2i(col * fw, row * fh, fw, fh)
			sf.add_frame(anim_name, atlas)
		print("Created ", anim_name)
	
	# COMBAT: Attack Light (rows 0-7, 8 frames)
	for suffix_row in dirs:
		var suffix = suffix_row[0]
		var row = suffix_row[1]
		var anim_name = "attack_light_" + suffix
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, 12.0)
		sf.set_animation_loop(anim_name, false)
		for col in range(8):
			var atlas = AtlasTexture.new()
			atlas.atlas = combat_img
			atlas.region = Rect2i(col * fw, row * fh, fw, fh)
			sf.add_frame(anim_name, atlas)
		print("Created ", anim_name)
	
	# COMBAT: Attack Heavy (rows 8-15, 8 frames)
	for suffix_row in dirs:
		var suffix = suffix_row[0]
		var row = suffix_row[1]
		var anim_name = "attack_heavy_" + suffix
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, 10.0)
		sf.set_animation_loop(anim_name, false)
		for col in range(8):
			var atlas = AtlasTexture.new()
			atlas.atlas = combat_img
			atlas.region = Rect2i(col * fw, (row + 8) * fh, fw, fh)
			sf.add_frame(anim_name, atlas)
		print("Created ", anim_name)
	
	# COMBAT: Hurt (rows 16-23, 8 frames)
	for suffix_row in dirs:
		var suffix = suffix_row[0]
		var row = suffix_row[1]
		var anim_name = "hurt_" + suffix
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, 8.0)
		sf.set_animation_loop(anim_name, false)
		for col in range(8):
			var atlas = AtlasTexture.new()
			atlas.atlas = combat_img
			atlas.region = Rect2i(col * fw, (row + 16) * fh, fw, fh)
			sf.add_frame(anim_name, atlas)
		print("Created ", anim_name)
	
	# Ensure animations folder exists
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("animations"):
		dir.make_dir("animations")
	
	var err = ResourceSaver.save(sf, "res://animations/knight_sprite_frames.tres")
	if err == OK:
		print("SUCCESS: Generated knight_sprite_frames.tres with ", sf.get_animation_names().size(), " animations")
	else:
		print("ERROR: Failed to save resource: ", err)
