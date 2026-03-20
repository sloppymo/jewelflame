extends AnimatedSprite2D

var current_direction: String = "s"
var directions = ["s", "n", "e", "w", "se", "nw", "sw", "ne"]
var dir_index: int = 0

func _ready():
	# CRITICAL: Set nearest filter for pixel art
	texture_filter = TEXTURE_FILTER_NEAREST
	
	build_sprite_frames()
	play("idle_s")

func build_sprite_frames():
	var nc_tex = load("res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Non-Combat.png")
	var c_tex = load("res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Combat.png")
	
	if not nc_tex or not c_tex:
		push_error("Failed to load textures")
		return
	
	var sf = SpriteFrames.new()
	
	# Direction mapping based on sprite sheet analysis
	# Row order: s, n, e, w, se, nw, sw, ne
	var dirs = ["s", "n", "e", "w", "se", "nw", "sw", "ne"]
	
	# Non-combat animations
	for i in range(8):
		var dir = dirs[i]
		_add_anim(sf, nc_tex, "idle_" + dir, i, 4, 6.0, true)
		_add_anim(sf, nc_tex, "walk_" + dir, i + 8, 4, 10.0, true)
		_add_anim(sf, nc_tex, "run_" + dir, i + 16, 4, 12.0, true)
	
	# Death (6 directions, rows 24-29)
	var death_dirs = ["s", "n", "e", "w", "se", "sw"]
	for i in range(6):
		_add_anim(sf, nc_tex, "death_" + death_dirs[i], i + 24, 4, 8.0, false)
	
	# FIXED: Combat animations - use frames with substantial content only
	# Frame analysis shows cols 0, 2, 5, 7 have main content
	# Cols 1, 3, 4, 6 are thin transition frames that cause artifacts
	var combat_frames = [0, 2, 5, 7]
	
	for i in range(8):
		var dir = dirs[i]
		_add_anim_filtered(sf, c_tex, "attack_light_" + dir, i, combat_frames, 12.0, false)
		_add_anim_filtered(sf, c_tex, "attack_heavy_" + dir, i + 8, combat_frames, 10.0, false)
		_add_anim_filtered(sf, c_tex, "hurt_" + dir, i + 16, combat_frames, 8.0, false)
	
	sprite_frames = sf
	print("Built ", sf.get_animation_names().size(), " animations")

func _add_anim(sf, atlas, name, row, frames, speed, loop):
	sf.add_animation(name)
	sf.set_animation_speed(name, speed)
	sf.set_animation_loop(name, loop)
	for col in range(frames):
		var tex = AtlasTexture.new()
		tex.atlas = atlas
		tex.region = Rect2(col * 16, row * 16, 16, 16)
		sf.add_frame(name, tex)

func _add_anim_filtered(sf, atlas, name, row, frame_indices, speed, loop):
	sf.add_animation(name)
	sf.set_animation_speed(name, speed)
	sf.set_animation_loop(name, loop)
	for col in frame_indices:
		var tex = AtlasTexture.new()
		tex.atlas = atlas
		tex.region = Rect2(col * 16, row * 16, 16, 16)
		# CRITICAL: Set filter to nearest for pixel art
		tex.set_texture_filter(CanvasItem.TEXTURE_FILTER_NEAREST)
		sf.add_frame(name, tex)

func cycle_direction():
	dir_index = (dir_index + 1) % directions.size()
	current_direction = directions[dir_index]
	play("idle_" + current_direction)
	return current_direction

func play_animation(anim_name: String):
	play(anim_name + "_" + current_direction)
