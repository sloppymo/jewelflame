@tool
extends EditorScript

## Heavy Knight Non-Combat Generator - CORRECTED
## Actual sprite sheet row order: down, up, right, left (verified by user)

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

	# CORRECT direction order based on verified sprite sheet structure:
	# Row 0 = down, Row 1 = up, Row 2 = right, Row 3 = left
	# [anim_name, start_row, num_frames, fps, loop]
	var animations: Array = [
		# ── IDLE (rows 0-3) ─────────────────────────────────────────
		["idle_down",   0,  4,  6.0, true],  # was incorrectly idle_right
		["idle_up",     1,  4,  6.0, true],  # was incorrectly idle_left
		["idle_right",  2,  4,  6.0, true],  # was incorrectly idle_down
		["idle_left",   3,  4,  6.0, true],  # was incorrectly idle_up
		# ── WALK (rows 4-7) ─────────────────────────────────────────
		["walk_down",   4,  4,  8.0, true],
		["walk_up",     5,  4,  8.0, true],
		["walk_right",  6,  4,  8.0, true],
		["walk_left",   7,  4,  8.0, true],
		# ── RUN (rows 8-11) ─────────────────────────────────────────
		["run_down",    8,  4, 10.0, true],
		["run_up",      9,  4, 10.0, true],
		["run_right",  10,  4, 10.0, true],
		["run_left",   11,  4, 10.0, true],
		# ── JUMP (rows 12-15) ───────────────────────────────────────
		["jump_down",  12,  4,  8.0, false],
		["jump_up",    13,  4,  8.0, false],
		["jump_right", 14,  4,  8.0, false],
		["jump_left",  15,  4,  8.0, false],
		# ── FALL (rows 16-19) ───────────────────────────────────────
		["fall_down",  16,  4,  8.0, false],
		["fall_up",    17,  4,  8.0, false],
		["fall_right", 18,  4,  8.0, false],
		["fall_left",  19,  4,  8.0, false],
		# ── ROLL (rows 20-23) ───────────────────────────────────────
		["roll_down",  20,  4, 12.0, false],
		["roll_up",    21,  4, 12.0, false],
		["roll_right", 22,  4, 12.0, false],
		["roll_left",  23,  4, 12.0, false],
		# ── DEATH (rows 24-27) ──────────────────────────────────────
		["death_down", 24,  4,  6.0, false],
		["death_up",   25,  4,  6.0, false],
		["death_right",26,  4,  6.0, false],
		["death_left", 27,  4,  6.0, false],
		# ── CORPSE (row 28) ─────────────────────────────────────────
		["death_corpse", 28, 4,  2.0, false],
		# ── INTERACT (rows 29-30) ───────────────────────────────────
		["interact_down",  29, 4,  8.0, false],
		["interact_up",    30, 4,  8.0, false],
		["interact_right", 31, 4,  8.0, false],
		["interact_left",  32, 4,  8.0, false],
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
		print("[OK] Saved CORRECTED: ", out_path)
		print("     Direction order: down/up/right/left (verified)")
	else:
		push_error("ResourceSaver failed: " + str(err))
