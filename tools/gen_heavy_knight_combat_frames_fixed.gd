@tool
extends EditorScript

## CORRECTED Heavy Knight Combat Generator
## Attack row order verified: the attacks are organized by type, not by direction

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

	# Combat sheet layout (verified):
	# Rows 0-3: Right-facing attacks (up, down, horizontal, stab)
	# Rows 4-7: Left-facing attacks (up, down, horizontal, stab)
	# Rows 8-9: Block (right, left)
	# Rows 10-11: Hurt (right, left)
	
	var animations: Array = [
		# ── ATTACKS RIGHT ───────────────────────────────────────────
		["attack_up_right",         0,  4, 12.0, false],
		["attack_down_right",       1,  4, 12.0, false],
		["attack_horizontal_right", 2,  4, 12.0, false],
		["attack_stab_right",       3,  4, 12.0, false],
		# ── ATTACKS LEFT ────────────────────────────────────────────
		["attack_up_left",          4,  4, 12.0, false],
		["attack_down_left",        5,  4, 12.0, false],
		["attack_horizontal_left",  6,  4, 12.0, false],
		["attack_stab_left",        7,  4, 12.0, false],
		# ── BLOCK ───────────────────────────────────────────────────
		["block_right",             8,  4,  8.0, true],
		["block_left",              9,  4,  8.0, true],
		# ── HURT ────────────────────────────────────────────────────
		["hurt_right",             10,  4,  8.0, false],
		["hurt_left",              11,  4,  8.0, false],
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
