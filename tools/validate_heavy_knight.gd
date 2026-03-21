@tool
extends EditorScript

func _run() -> void:
	var checks := [
		"res://assets/Citizens - Guards - Warriors/Warriors/Heavy_Knight_Non-Combat_Animations.png",
		"res://assets/Citizens - Guards - Warriors/Warriors/Heavy_Knight_Combat_Animations.png",
		"res://assets/Citizens - Guards - Warriors/Warriors/Heavy_Knight_Thrust_Attack_Non-Dash-Version.png",
		"res://assets/Citizens - Guards - Warriors/Warriors/Heavy_Knight_Thrust_Dash_Attack.png",
		"res://assets/animations/heavy_knight_non_combat.tres",
		"res://assets/animations/heavy_knight_combat.tres",
		"res://assets/animations/heavy_knight_thrust_nodash.tres",
		"res://assets/animations/heavy_knight_thrust_dash.tres",
		"res://units/heavy_knight.gd",
		"res://units/heavy_knight.tscn",
		"res://tests/heavy_knight_test.tscn",
	]

	var all_ok := true
	for path in checks:
		if ResourceLoader.exists(path):
			print("[OK]      ", path)
		else:
			print("[MISSING] ", path)
			all_ok = false

	if all_ok:
		print("\n✓ All files present.")
	else:
		print("\n✗ Some files missing.")

	for res_name in ["heavy_knight_non_combat", "heavy_knight_combat",
	                  "heavy_knight_thrust_nodash", "heavy_knight_thrust_dash"]:
		var sf = load("res://assets/animations/" + res_name + ".tres")
		if sf:
			print("\n[%s] — %d animations:" % [res_name, sf.get_animation_names().size()])
			for a in sf.get_animation_names():
				print("  %s — %d frames" % [a, sf.get_frame_count(a)])
