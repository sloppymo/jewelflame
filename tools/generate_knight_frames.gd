extends Node2D

func _ready():
	generate_sprite_frames()

func generate_sprite_frames():
	var combat_img = load("res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Combat.png")
	var noncombat_img = load("res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Non-Combat.png")
	
	if not combat_img or not noncombat_img:
		print("ERROR: Could not load images")
		return
	
	print("Combat: ", combat_img.get_size())
	print("Non-combat: ", noncombat_img.get_size())
	
	var sf = SpriteFrames.new()
	var fw = 16
	var fh = 16
	
	var dirs = [
		["s", 0], ["n", 1], ["se", 2], ["ne", 3],
		["e", 4], ["w", 5], ["sw", 6], ["nw", 7]
	]
	
	# NON-COMBAT (4 frames each)
	# Idle, Walk, Run
	for suffix_row in dirs:
		var suffix = suffix_row[0]
		var row = suffix_row[1]
		_add_anim(sf, noncombat_img, "idle_" + suffix, row, 4, 6.0, true, fw, fh)
		_add_anim(sf, noncombat_img, "walk_" + suffix, row + 8, 4, 10.0, true, fw, fh)
		_add_anim(sf, noncombat_img, "run_" + suffix, row + 16, 4, 12.0, true, fw, fh)
	
	# Death (only 7 directions)
	var death_rows = [["s", 24], ["n", 25], ["se", 26], ["ne", 27], ["e", 28], ["w", 29], ["sw", 30]]
	for death_data in death_rows:
		var suffix = death_data[0]
		var row = death_data[1]
		_add_anim(sf, noncombat_img, "death_" + suffix, row, 4, 8.0, false, fw, fh)
	
	# COMBAT (8 frames each)
	# Attack Light, Attack Heavy, Hurt
	for suffix_row in dirs:
		var suffix = suffix_row[0]
		var row = suffix_row[1]
		_add_anim(sf, combat_img, "attack_light_" + suffix, row, 8, 12.0, false, fw, fh)
		_add_anim(sf, combat_img, "attack_heavy_" + suffix, row + 8, 8, 10.0, false, fw, fh)
		_add_anim(sf, combat_img, "hurt_" + suffix, row + 16, 8, 8.0, false, fw, fh)
	
	var err = ResourceSaver.save(sf, "res://animations/knight_sprite_frames.tres")
	if err == OK:
		print("SUCCESS: Generated knight_sprite_frames.tres with ", sf.get_animation_names().size(), " animations")
	else:
		print("ERROR: ", err)

func _add_anim(sf, img, name, row, frames, speed, loop, fw, fh):
	sf.add_animation(name)
	sf.set_animation_speed(name, speed)
	sf.set_animation_loop(name, loop)
	for col in range(frames):
		var atlas = AtlasTexture.new()
		atlas.atlas = img
		atlas.region = Rect2i(col * fw, row * fh, fw, fh)
		sf.add_frame(name, atlas)
	print("Created ", name)
