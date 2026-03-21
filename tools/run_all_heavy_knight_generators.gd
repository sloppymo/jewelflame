## Standalone script to generate all Heavy Knight SpriteFrames
## Run with: godot --headless --script tools/run_all_heavy_knight_generators.gd

extends SceneTree

func _initialize():
	print("=== Heavy Knight SpriteFrames Generator ===\n")
	
	# Create output directory if needed
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("assets/animations"):
		dir.make_dir_recursive("assets/animations")
		print("Created assets/animations/")
	
	# Run all three generators
	_generate_non_combat()
	_generate_combat()
	_generate_thrust()
	
	print("\n=== Done ===")
	quit()

func _generate_non_combat() -> void:
	print("\n--- Non-Combat Animations ---")
	var tex_path := "res://assets/Citizens - Guards - Warriors/Warriors/Heavy_Knight_Non-Combat_Animations.png"
	var out_path := "res://assets/animations/heavy_knight_non_combat.tres"
	
	var texture := load(tex_path)
	if texture == null:
		push_error("Cannot load: " + tex_path)
		return
	
	var sf := SpriteFrames.new()
	var fw := 24
	var fh := 24
	
	var animations: Array = [
		["idle_down", 0, 4, 6.0, true], ["idle_up", 1, 4, 6.0, true],
		["idle_right", 2, 4, 6.0, true], ["idle_left", 3, 4, 6.0, true],
		["walk_down", 4, 4, 8.0, true], ["walk_up", 5, 4, 8.0, true],
		["walk_right", 6, 4, 8.0, true], ["walk_left", 7, 4, 8.0, true],
		["run_down", 8, 4, 10.0, true], ["run_up", 9, 4, 10.0, true],
		["run_right", 10, 4, 10.0, true], ["run_left", 11, 4, 10.0, true],
		["jump_down", 12, 4, 8.0, false], ["jump_up", 13, 4, 8.0, false],
		["jump_right", 14, 4, 8.0, false], ["jump_left", 15, 4, 8.0, false],
		["fall_down", 16, 4, 8.0, false], ["fall_up", 17, 4, 8.0, false],
		["fall_right", 18, 4, 8.0, false], ["fall_left", 19, 4, 8.0, false],
		["roll_down", 20, 4, 12.0, false], ["roll_up", 21, 4, 12.0, false],
		["roll_right", 22, 4, 12.0, false], ["roll_left", 23, 4, 12.0, false],
		["death_down", 24, 4, 6.0, false], ["death_up", 25, 4, 6.0, false],
		["death_right", 26, 4, 6.0, false], ["death_left", 27, 4, 6.0, false],
		["death_corpse", 28, 4, 2.0, false],
		["interact_down", 29, 4, 8.0, false], ["interact_up", 30, 4, 8.0, false],
	]
	
	for anim_data in animations:
		var anim_name: String = anim_data[0]
		var start_row: int = anim_data[1]
		var num_frames: int = anim_data[2]
		var fps: float = anim_data[3]
		var should_loop: bool = anim_data[4]
		
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
		print("[OK] Saved: ", out_path, " (", sf.get_animation_names().size(), " animations)")
	else:
		print("[FAIL] Error: ", err)

func _generate_combat() -> void:
	print("\n--- Combat Animations ---")
	var tex_path := "res://assets/Citizens - Guards - Warriors/Warriors/Heavy_Knight_Combat_Animations.png"
	var out_path := "res://assets/animations/heavy_knight_combat.tres"
	
	var texture := load(tex_path)
	if texture == null:
		push_error("Cannot load: " + tex_path)
		return
	
	var sf := SpriteFrames.new()
	var fw := 32
	var fh := 32
	
	var animations: Array = [
		["attack_up_right", 0, 4, 12.0, false], ["attack_down_right", 1, 4, 12.0, false],
		["attack_horizontal_right", 2, 4, 12.0, false], ["attack_stab_right", 3, 4, 12.0, false],
		["attack_up_left", 4, 4, 12.0, false], ["attack_down_left", 5, 4, 12.0, false],
		["attack_horizontal_left", 6, 4, 12.0, false], ["attack_stab_left", 7, 4, 12.0, false],
		["block_right", 8, 4, 8.0, true], ["block_left", 9, 4, 8.0, true],
		["hurt_right", 10, 4, 8.0, false], ["hurt_left", 11, 4, 8.0, false],
	]
	
	for anim_data in animations:
		var anim_name: String = anim_data[0]
		var start_row: int = anim_data[1]
		var num_frames: int = anim_data[2]
		var fps: float = anim_data[3]
		var should_loop: bool = anim_data[4]
		
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
		print("[OK] Saved: ", out_path, " (", sf.get_animation_names().size(), " animations)")
	else:
		print("[FAIL] Error: ", err)

func _generate_thrust() -> void:
	print("\n--- Thrust Animations ---")
	var fw := 32
	var fh := 32
	
	var animations: Array = [
		["thrust_right", 0, 8, 12.0, false], ["thrust_left", 1, 8, 12.0, false],
		["thrust_down", 2, 8, 12.0, false], ["thrust_up", 3, 8, 12.0, false],
	]
	
	# No-dash version
	var nodash_path := "res://assets/Citizens - Guards - Warriors/Warriors/Heavy_Knight_Thrust_Attack_Non-Dash-Version.png"
	var nodash_out := "res://assets/animations/heavy_knight_thrust_nodash.tres"
	
	var tex_nd := load(nodash_path)
	if tex_nd:
		var sf_nd := SpriteFrames.new()
		for anim_data in animations:
			var anim_name: String = anim_data[0]
			var start_row: int = anim_data[1]
			var num_frames: int = anim_data[2]
			var fps: float = anim_data[3]
			var should_loop: bool = anim_data[4]
			
			sf_nd.add_animation(anim_name)
			sf_nd.set_animation_speed(anim_name, fps)
			sf_nd.set_animation_loop(anim_name, should_loop)
			
			for col in range(num_frames):
				var atlas := AtlasTexture.new()
				atlas.atlas = tex_nd
				atlas.region = Rect2(col * fw, start_row * fh, fw, fh)
				atlas.filter_clip = true
				sf_nd.add_frame(anim_name, atlas)
		
		var err := ResourceSaver.save(sf_nd, nodash_out)
		if err == OK:
			print("[OK] Saved: ", nodash_out)
		else:
			print("[FAIL] No-dash error: ", err)
	else:
		print("[FAIL] Cannot load: ", nodash_path)
	
	# Dash version
	var dash_path := "res://assets/Citizens - Guards - Warriors/Warriors/Heavy_Knight_Thrust_Dash_Attack.png"
	var dash_out := "res://assets/animations/heavy_knight_thrust_dash.tres"
	
	var tex_d := load(dash_path)
	if tex_d:
		var sf_d := SpriteFrames.new()
		for anim_data in animations:
			var anim_name: String = anim_data[0]
			var start_row: int = anim_data[1]
			var num_frames: int = anim_data[2]
			var fps: float = anim_data[3]
			var should_loop: bool = anim_data[4]
			
			sf_d.add_animation(anim_name)
			sf_d.set_animation_speed(anim_name, fps)
			sf_d.set_animation_loop(anim_name, should_loop)
			
			for col in range(num_frames):
				var atlas := AtlasTexture.new()
				atlas.atlas = tex_d
				atlas.region = Rect2(col * fw, start_row * fh, fw, fh)
				atlas.filter_clip = true
				sf_d.add_frame(anim_name, atlas)
		
		var err := ResourceSaver.save(sf_d, dash_out)
		if err == OK:
			print("[OK] Saved: ", dash_out)
		else:
			print("[FAIL] Dash error: ", err)
	else:
		print("[FAIL] Cannot load: ", dash_path)
