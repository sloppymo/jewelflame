@tool
extends EditorScript

## Run via: Tools → Execute Script
## Generates: res://assets/animations/heavy_knight_combat.tres
##
## SOURCE SHEET SPECS (pixel-measured):
##   File:  Heavy_Knight_Combat_Animations.png
##   Size:  128 x 384 px  |  RGBA
##   Frame: 32 x 32 px
##   Grid:  4 cols x 12 rows = 48 total frames
##
## IMPACT FRAMES (confirmed by white sword-flash pixel count):
##   All attack rows: impact at frame index 2 (white px jumps from 0 to 140-159)
##   Frames 0-1 = wind-up, frame 2 = peak impact, frame 3 = follow-through
##
## MIRROR ROWS (mathematically confirmed):
##   R08 vs R09: flipped_diff = 0.0 → block_left is block_right mirrored
##
## ROW MAP:
##   R00-R07: attacks (4 right-facing, then 4 left-facing)
##   R08-R09: block (right, left=mirror)
##   R10-R11: hurt (right, left)
##
## ANIMATION NAMING: uses right/left suffix, not 8-directional compass

func _run() -> void:
	var tex_path := "res://assets/Citizens - Guards - Warriors/Warriors/Heavy_Knight_Combat_Animations.png"
	var out_path := "res://assets/animations/heavy_knight_combat.tres"

	var texture := load(tex_path)
	if texture == null:
		push_error("Cannot load: " + tex_path)
		return

	var sf := SpriteFrames.new()
	sf.remove_animation("default")

	var fw := 32
	var fh := 32

	# [anim_name, start_row, num_frames, fps, loop]
	var animations: Array = [
		# ── ATTACKS RIGHT ─────────────────────────────────────────────
		# Impact frame = index 2 on all rows (white flash: ~140-159 px at frame 2)
		["attack_up_right",         0,  4, 12.0, false],
		["attack_down_right",       1,  4, 12.0, false],
		["attack_horizontal_right", 2,  4, 12.0, false],
		["attack_stab_right",       3,  4, 12.0, false],
		# ── ATTACKS LEFT ──────────────────────────────────────────────
		# Impact frame = index 2 on all rows (white flash: ~70-159 px at frame 2)
		["attack_up_left",          4,  4, 12.0, false],
		["attack_down_left",        5,  4, 12.0, false],
		["attack_horizontal_left",  6,  4, 12.0, false],
		["attack_stab_left",        7,  4, 12.0, false],
		# ── BLOCK ─────────────────────────────────────────────────────
		# R08 vs R09: confirmed mirror (flipped_diff = 0.0)
		# No impact frames — no white flash pixels detected
		["block_right",  8,  4,  8.0, true],   # loop = hold block pose
		["block_left",   9,  4,  8.0, true],
		# ── HURT ──────────────────────────────────────────────────────
		# No white flash — purely reactive animation
		["hurt_right",  10,  4,  8.0, false],
		["hurt_left",   11,  4,  8.0, false],
	]

	for anim_data in animations:
		var anim_name   : String = anim_data[0]
		var start_row   : int    = anim_data[1]
		var num_frames  : int    = anim_data[2]
		var fps         : float  = anim_data[3]
		var should_loop : bool   = anim_data[4]

		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, fps)
		sf.set_animation_loop(anim_name, should_loop)

		for col in range(num_frames):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(col * fw, start_row * fh, fw, fh)
			atlas.filter_clip = true
			sf.add_frame(anim_name, atlas)

	var err := ResourceSaver.save(sf, out_path)
	if err == OK:
		print("[OK] Saved: ", out_path)
		print("     Animations: ", sf.get_animation_names().size())
	else:
		push_error("ResourceSaver failed — check that res://assets/animations/ exists")
