@tool
extends EditorScript

## Run via: Tools → Execute Script
## Generates: res://assets/animations/heavy_knight_non_combat.tres
##
## SOURCE SHEET SPECS (pixel-measured):
##   File:  Heavy_Knight_Non-Combat_Animations.png
##   Size:  96 x 744 px  |  RGBA
##   Frame: 24 x 24 px   ← DIFFERENT from combat sheets (those are 32x32)
##   Grid:  4 cols x 31 rows = 124 total frames
##
## DIRECTION ORDER within each 4-row group (confirmed by pixel mass analysis):
##   offset +0 = down   offset +1 = up
##   offset +2 = right  offset +3 = left
##   R20 vs R21 mirror confirmed: flipped_diff = 0.0 (right/left are exact mirrors)
##
## ANIMATION GROUPS:
##   Rows 00-03  → idle   (4 dirs × 4 frames)
##   Rows 04-07  → walk   (4 dirs × 4 frames)
##   Rows 08-11  → run    (4 dirs × 4 frames)
##   Rows 12-15  → jump   (4 dirs × 4 frames)
##   Rows 16-19  → fall   (4 dirs × 4 frames)
##   Rows 20-23  → roll   (4 dirs × 4 frames)  R20/R21=mirror confirmed
##   Rows 24-27  → death  (4 dirs × 4 frames)  diff ~58-67 — highest energy
##   Row  28     → death_corpse  (near-static hold, diff=3.6)
##   Rows 29-30  → interact (2 rows — down + up or down + side)

func _run() -> void:
	var tex_path := "res://assets/Citizens - Guards - Warriors/Warriors/Heavy_Knight_Non-Combat_Animations.png"
	var out_path := "res://assets/animations/heavy_knight_non_combat.tres"

	var texture := load(tex_path)
	if texture == null:
		push_error("Cannot load: " + tex_path)
		return

	var sf := SpriteFrames.new()
	sf.remove_animation("default")

	var fw := 24
	var fh := 24

	# [anim_name, start_row, num_frames, fps, loop]
	var animations: Array = [
		# ── IDLE ─────────────────────────────────────────────────────
		["idle_down",   0,  4,  6.0, true],
		["idle_up",     1,  4,  6.0, true],
		["idle_right",  2,  4,  6.0, true],
		["idle_left",   3,  4,  6.0, true],
		# ── WALK ─────────────────────────────────────────────────────
		["walk_down",   4,  4,  8.0, true],
		["walk_up",     5,  4,  8.0, true],
		["walk_right",  6,  4,  8.0, true],
		["walk_left",   7,  4,  8.0, true],
		# ── RUN ──────────────────────────────────────────────────────
		["run_down",    8,  4, 10.0, true],
		["run_up",      9,  4, 10.0, true],
		["run_right",  10,  4, 10.0, true],
		["run_left",   11,  4, 10.0, true],
		# ── JUMP ─────────────────────────────────────────────────────
		["jump_down",  12,  4,  8.0, false],
		["jump_up",    13,  4,  8.0, false],
		["jump_right", 14,  4,  8.0, false],
		["jump_left",  15,  4,  8.0, false],
		# ── FALL ─────────────────────────────────────────────────────
		["fall_down",  16,  4,  8.0, false],
		["fall_up",    17,  4,  8.0, false],
		["fall_right", 18,  4,  8.0, false],
		["fall_left",  19,  4,  8.0, false],
		# ── ROLL/DODGE ───────────────────────────────────────────────
		# R20 vs R21: horizontal mirror confirmed (flipped_diff = 0.0)
		["roll_down",  20,  4, 12.0, false],
		["roll_up",    21,  4, 12.0, false],
		["roll_right", 22,  4, 12.0, false],
		["roll_left",  23,  4, 12.0, false],
		# ── DEATH ────────────────────────────────────────────────────
		# Highest frame energy in sheet (diff ~58-67). Play once, hold corpse.
		["death_down",  24,  4,  6.0, false],
		["death_up",    25,  4,  6.0, false],
		["death_right", 26,  4,  6.0, false],
		["death_left",  27,  4,  6.0, false],
		# Row 28: near-static corpse hold (diff = 3.6 — same signature as other packs)
		["death_corpse", 28, 4,  2.0, false],
		# ── INTERACT ─────────────────────────────────────────────────
		# Rows 29-30: two remaining rows. Verify in-engine (chest/item interaction).
		["interact_down", 29, 4,  8.0, false],
		["interact_up",   30, 4,  8.0, false],
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
