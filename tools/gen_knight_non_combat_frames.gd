@tool
extends EditorScript

## Run via: Tools → Execute Script
## Generates: res://assets/animations/knight_non_combat.tres
##
## SOURCE SHEET SPECS:
##   File:  2-Handed_Swordsman_Non-Combat.png
##   Size:  64 x 496 px
##   Frame: 16 x 16 px
##   Grid:  4 cols x 31 rows
##
## DIRECTION ORDER: s(0), n(1), se(2), ne(3), e(4), w(5), sw(6), nw(7)
##
## ROWS:
##   00-07: idle
##   08-15: walk
##   16-23: run
##   24-30: death (7 directions, no nw)

func _run() -> void:
	var tex_path := "res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Non-Combat.png"
	var out_path := "res://assets/animations/knight_non_combat.tres"

	var texture := load(tex_path)
	if texture == null:
		push_error("Cannot load: " + tex_path)
		return

	var sf := SpriteFrames.new()
	sf.remove_animation("default")

	var fw := 16
	var fh := 16

	# [anim_name, start_row, num_frames, fps, loop]
	var animations: Array = [
		# ── IDLE ─────────────────────────────────────────────────────
		["idle_s",   0,  4,  6.0, true],
		["idle_n",   1,  4,  6.0, true],
		["idle_se",  2,  4,  6.0, true],
		["idle_ne",  3,  4,  6.0, true],
		["idle_e",   4,  4,  6.0, true],
		["idle_w",   5,  4,  6.0, true],
		["idle_sw",  6,  4,  6.0, true],
		["idle_nw",  7,  4,  6.0, true],
		# ── WALK ─────────────────────────────────────────────────────
		["walk_s",   8,  4,  10.0, true],
		["walk_n",   9,  4,  10.0, true],
		["walk_se",  10, 4,  10.0, true],
		["walk_ne",  11, 4,  10.0, true],
		["walk_e",   12, 4,  10.0, true],
		["walk_w",   13, 4,  10.0, true],
		["walk_sw",  14, 4,  10.0, true],
		["walk_nw",  15, 4,  10.0, true],
		# ── RUN ──────────────────────────────────────────────────────
		["run_s",    16, 4,  12.0, true],
		["run_n",    17, 4,  12.0, true],
		["run_se",   18, 4,  12.0, true],
		["run_ne",   19, 4,  12.0, true],
		["run_e",    20, 4,  12.0, true],
		["run_w",    21, 4,  12.0, true],
		["run_sw",   22, 4,  12.0, true],
		["run_nw",   23, 4,  12.0, true],
		# ── DEATH ────────────────────────────────────────────────────
		["death_s",  24, 4,  8.0, false],
		["death_n",  25, 4,  8.0, false],
		["death_se", 26, 4,  8.0, false],
		["death_ne", 27, 4,  8.0, false],
		["death_e",  28, 4,  8.0, false],
		["death_w",  29, 4,  8.0, false],
		["death_sw", 30, 4,  8.0, false],
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
		push_error("ResourceSaver failed: " + str(err))
