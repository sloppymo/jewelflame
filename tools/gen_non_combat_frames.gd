@tool
extends EditorScript

## Run via: Tools → Execute Script
## Generates: res://assets/animations/swordshield_non_combat.tres
##
## SOURCE SHEET SPECS (measured, not guessed):
##   File: Sword_and_Shield_Fighter_Non-Combat.png
##   Size: 64 x 496 px  |  RGBA
##   Frame: 16 x 16 px
##   Grid: 4 cols x 31 rows = 124 total frames
##   Each row = 4 animation frames for one direction
##
## ANIMATION GROUPS:
##   Rows 00-07  → IDLE   (8 directions x 4 frames)
##   Rows 08-15  → WALK   (8 directions x 4 frames)
##   Rows 16-23  → WALK2  (8 directions x 4 frames) — verify if run or alt walk
##   Rows 24-30  → DEATH  (7 rows — 4 dirs + corpse + 2 prone)
##
## DIRECTION ORDER WITHIN EACH 8-ROW GROUP (confirmed by pixel mass analysis):
##   offset +0 = S   offset +1 = N   offset +2 = SE  offset +3 = NE
##   offset +4 = E   offset +5 = W   offset +6 = SW  offset +7 = NW

func _run():
	var tex_path = "res://assets/Citizens - Guards - Warriors/Warriors/Sword_and_Shield_Fighter_Non-Combat.png"
	var out_path = "res://assets/animations/swordshield_non_combat.tres"

	var texture = load(tex_path)
	if texture == null:
		push_error("Cannot load: " + tex_path + " — check file path")
		return

	var sf = SpriteFrames.new()
	sf.remove_animation("default")

	var fw := 16
	var fh := 16

	# [anim_name, start_row, num_frames, fps, loop]
	# CORRECTED DIRECTION ORDER: E/W are rows 2,3 (side profiles)
	# NE/NW are rows 4,5 (diagonals with "hands up" look)
	var animations := [
		# ── IDLE ──────────────────────────────────────────────
		["idle_s",        0,  4, 6.0, true],
		["idle_n",        1,  4, 6.0, true],
		["idle_e",        2,  4, 6.0, true],   # was se - side profile
		["idle_w",        3,  4, 6.0, true],   # was ne - side profile
		["idle_se",       4,  4, 6.0, true],   # was e
		["idle_sw",       5,  4, 6.0, true],   # was w
		["idle_ne",       6,  4, 6.0, true],   # was sw
		["idle_nw",       7,  4, 6.0, true],   # was nw
		# ── WALK ──────────────────────────────────────────────
		["walk_s",        8,  4, 8.0, true],
		["walk_n",        9,  4, 8.0, true],
		["walk_e",       10,  4, 8.0, true],   # was se
		["walk_w",       11,  4, 8.0, true],   # was ne
		["walk_se",      12,  4, 8.0, true],   # was e
		["walk_sw",      13,  4, 8.0, true],   # was w
		["walk_ne",      14,  4, 8.0, true],   # was sw
		["walk_nw",      15,  4, 8.0, true],   # was nw
		# ── WALK2 (verify: may be run or alternate gait) ──────
		["walk2_s",      16,  4, 8.0, true],
		["walk2_n",      17,  4, 8.0, true],
		["walk2_e",      18,  4, 8.0, true],   # was se
		["walk2_w",      19,  4, 8.0, true],   # was ne
		["walk2_se",     20,  4, 8.0, true],   # was e
		["walk2_sw",     21,  4, 8.0, true],   # was w
		["walk2_ne",     22,  4, 8.0, true],   # was sw
		["walk2_nw",     23,  4, 8.0, true],   # was nw
		# ── DEATH (7 rows — one direction missing, see notes) ──
		["death_s",      24,  4, 6.0, false],
		["death_n",      25,  4, 6.0, false],
		["death_se",     26,  4, 6.0, false],
		["death_sw",     27,  4, 6.0, false],
		["death_corpse", 28,  4, 2.0, false],  # nearly static — pixel diff 4.2
		["death_prone_s",29,  4, 6.0, false],  # lying flat — Y center ~10.6
		["death_prone_n",30,  4, 6.0, false],  # lying flat — Y center ~10.6
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
			sf.add_frame(anim_name, atlas)

	var err := ResourceSaver.save(sf, out_path)
	if err == OK:
		print("[OK] Saved: ", out_path)
		print("     Animations: ", sf.get_animation_names())
	else:
		push_error("ResourceSaver failed with code: " + str(err))
