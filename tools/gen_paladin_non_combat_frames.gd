@tool
extends EditorScript

## Generates: res://assets/animations/paladin_non_combat.tres
## Source: Paladin_Non-Combat_Animations_666eae.png
## Specs: 96×744 px, 24×24 frames, 4 cols × 31 rows

func _run() -> void:
	var tex_path := "res://assets/Citizens - Guards - Warriors/Warriors/Paladin_Non-Combat_Animations_666eae.png"
	var out_path := "res://assets/animations/paladin_non_combat.tres"

	var texture := load(tex_path)
	if texture == null:
		push_error("Cannot load: " + tex_path)
		return

	var sf := SpriteFrames.new()
	sf.remove_animation("default")

	var fw := 24
	var fh := 24

	# Direction order: right, left, down, up (based on Heavy Knight correction)
	var animations: Array = [
		# ── IDLE (rows 0-3) ─────────────────────────────────────────
		["idle_right",  0,  4,  6.0, true],
		["idle_left",   1,  4,  6.0, true],
		["idle_down",   2,  4,  6.0, true],
		["idle_up",     3,  4,  6.0, true],
		# ── WALK (rows 4-7) ─────────────────────────────────────────
		["walk_right",  4,  4,  8.0, true],
		["walk_left",   5,  4,  8.0, true],
		["walk_down",   6,  4,  8.0, true],
		["walk_up",     7,  4,  8.0, true],
		# ── RUN (rows 8-11) ─────────────────────────────────────────
		["run_right",   8,  4, 10.0, true],
		["run_left",    9,  4, 10.0, true],
		["run_down",   10,  4, 10.0, true],
		["run_up",     11,  4, 10.0, true],
		# ── JUMP (rows 12-15) ───────────────────────────────────────
		["jump_right", 12,  4,  8.0, false],
		["jump_left",  13,  4,  8.0, false],
		["jump_down",  14,  4,  8.0, false],
		["jump_up",    15,  4,  8.0, false],
		# ── FALL (rows 16-19) ───────────────────────────────────────
		["fall_right", 16,  4,  8.0, false],
		["fall_left",  17,  4,  8.0, false],
		["fall_down",  18,  4,  8.0, false],
		["fall_up",    19,  4,  8.0, false],
		# ── ROLL (rows 20-23) ───────────────────────────────────────
		["roll_right", 20,  4, 12.0, false],
		["roll_left",  21,  4, 12.0, false],
		["roll_down",  22,  4, 12.0, false],
		["roll_up",    23,  4, 12.0, false],
		# ── DEATH (rows 24-27) ──────────────────────────────────────
		["death_right", 24,  4,  6.0, false],
		["death_left",  25,  4,  6.0, false],
		["death_down",  26,  4,  6.0, false],
		["death_up",    27,  4,  6.0, false],
		# ── CORPSE (row 28) ─────────────────────────────────────────
		["death_corpse", 28, 4,  2.0, false],
		# ── INTERACT (rows 29-30) ───────────────────────────────────
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
		push_error("ResourceSaver failed: " + str(err))
