@tool
extends EditorScript

## CORRECTED Heavy Knight Non-Combat Generator
## Row order fixed based on testing: right, left, down, up (not down, up, right, left)

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

	# CORRECTED direction order based on visual testing:
	# The sprite sheet rows are ordered: right, left, down, up (not down/up/right/left)
	# [anim_name, start_row, num_frames, fps, loop]
	var animations: Array = [
		# ── IDLE (rows 0-3) ─────────────────────────────────────────
		["idle_right",  0,  4,  6.0, true],  # was idle_down
		["idle_left",   1,  4,  6.0, true],  # was idle_up
		["idle_down",   2,  4,  6.0, true],  # was idle_right
		["idle_up",     3,  4,  6.0, true],  # was idle_left
		# ── WALK (rows 4-7) ─────────────────────────────────────────
		["walk_right",  4,  4,  8.0, true],  # was walk_down
		["walk_left",   5,  4,  8.0, true],  # was walk_up
		["walk_down",   6,  4,  8.0, true],  # was walk_right
		["walk_up",     7,  4,  8.0, true],  # was walk_left
		# ── RUN (rows 8-11) ─────────────────────────────────────────
		["run_right",   8,  4, 10.0, true],  # was run_down
		["run_left",    9,  4, 10.0, true],  # was run_up
		["run_down",   10,  4, 10.0, true],  # was run_right
		["run_up",     11,  4, 10.0, true],  # was run_left
		# ── JUMP (rows 12-15) ───────────────────────────────────────
		["jump_right", 12,  4,  8.0, false], # was jump_down
		["jump_left",  13,  4,  8.0, false], # was jump_up
		["jump_down",  14,  4,  8.0, false], # was jump_right
		["jump_up",    15,  4,  8.0, false], # was jump_left
		# ── FALL (rows 16-19) ───────────────────────────────────────
		["fall_right", 16,  4,  8.0, false], # was fall_down
		["fall_left",  17,  4,  8.0, false], # was fall_up
		["fall_down",  18,  4,  8.0, false], # was fall_right
		["fall_up",    19,  4,  8.0, false], # was fall_left
		# ── ROLL (rows 20-23) ───────────────────────────────────────
		["roll_right", 20,  4, 12.0, false], # was roll_down
		["roll_left",  21,  4, 12.0, false], # was roll_up
		["roll_down",  22,  4, 12.0, false], # was roll_right
		["roll_up",    23,  4, 12.0, false], # was roll_left
		# ── DEATH (rows 24-27) ──────────────────────────────────────
		["death_right", 24,  4,  6.0, false], # was death_down
		["death_left",  25,  4,  6.0, false], # was death_up
		["death_down",  26,  4,  6.0, false], # was death_right
		["death_up",    27,  4,  6.0, false], # was death_left
		# ── CORPSE (row 28) ─────────────────────────────────────────
		["death_corpse", 28, 4,  2.0, false], # near-static hold
		# ── INTERACT (rows 29-30) ───────────────────────────────────
		["interact_right", 29, 4,  8.0, false], # was interact_down
		["interact_left",  30, 4,  8.0, false], # was interact_up
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
		print("[OK] Saved FIXED: ", out_path)
		print("     Animations: ", sf.get_animation_names().size())
		print("     NOTE: Direction order corrected to right/left/down/up")
	else:
		push_error("ResourceSaver failed: " + str(err))
