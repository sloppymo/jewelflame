@tool
extends EditorScript

## Generates: res://assets/animations/paladin_thrust_nodash.tres (6 frames)
##            res://assets/animations/paladin_thrust_dash.tres (8 frames)

func _run() -> void:
	var fw := 32
	var fh := 32

	# Direction order: right, left, down, up
	var animations: Array = [
		["thrust_right",  0,  12.0, false],
		["thrust_left",   1,  12.0, false],
		["thrust_down",   2,  12.0, false],
		["thrust_up",     3,  12.0, false],
	]

	# ── NO-DASH version (6 frames) ────────────────────────────────────────────
	var nodash_path := "res://assets/Citizens - Guards - Warriors/Warriors/Paladin_Combat_Thrust_bcb7b1.png"
	var nodash_out  := "res://assets/animations/paladin_thrust_nodash.tres"

	var tex_nd := load(nodash_path)
	if tex_nd == null:
		push_error("Cannot load: " + nodash_path)
	else:
		var sf_nd := SpriteFrames.new()
		sf_nd.remove_animation("default")
		
		for anim_data in animations:
			var anim_name: String = anim_data[0]
			var start_row: int = anim_data[1]
			var fps: float = anim_data[2]
			var should_loop: bool = anim_data[3]
			
			sf_nd.add_animation(anim_name)
			sf_nd.set_animation_speed(anim_name, fps)
			sf_nd.set_animation_loop(anim_name, should_loop)
			
			for col in range(6):  # 6 frames for no-dash
				var atlas := AtlasTexture.new()
				atlas.atlas = tex_nd
				atlas.region = Rect2(col * fw, start_row * fh, fw, fh)
				atlas.filter_clip = true
				sf_nd.add_frame(anim_name, atlas)
		
		var err := ResourceSaver.save(sf_nd, nodash_out)
		if err == OK:
			print("[OK] Saved nodash: ", nodash_out)
		else:
			push_error("ResourceSaver failed for nodash: " + str(err))

	# ── DASH version (8 frames) ───────────────────────────────────────────────
	var dash_path := "res://assets/Citizens - Guards - Warriors/Warriors/Paladin_Combat_ThrustDash_24489d.png"
	var dash_out  := "res://assets/animations/paladin_thrust_dash.tres"

	var tex_d := load(dash_path)
	if tex_d == null:
		push_error("Cannot load: " + dash_path)
	else:
		var sf_d := SpriteFrames.new()
		sf_d.remove_animation("default")
		
		for anim_data in animations:
			var anim_name: String = anim_data[0]
			var start_row: int = anim_data[1]
			var fps: float = anim_data[2]
			var should_loop: bool = anim_data[3]
			
			sf_d.add_animation(anim_name)
			sf_d.set_animation_speed(anim_name, fps)
			sf_d.set_animation_loop(anim_name, should_loop)
			
			for col in range(8):  # 8 frames for dash
				var atlas := AtlasTexture.new()
				atlas.atlas = tex_d
				atlas.region = Rect2(col * fw, start_row * fh, fw, fh)
				atlas.filter_clip = true
				sf_d.add_frame(anim_name, atlas)
		
		var err := ResourceSaver.save(sf_d, dash_out)
		if err == OK:
			print("[OK] Saved dash: ", dash_out)
		else:
			push_error("ResourceSaver failed for dash: " + str(err))
