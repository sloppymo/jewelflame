@tool
extends EditorScript

func _run() -> void:
	var checks := [
		"res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Non-Combat.png",
		"res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Combat.png",
		"res://assets/animations/knight_non_combat.tres",
		"res://assets/animations/knight_combat.tres",
		"res://units/knight_unit.gd",
		"res://units/knight_unit.tscn",
		"res://tests/knight_test.tscn",
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
		print("\n✗ Some files missing. Run EditorScripts to generate .tres files.")

	for res_name in ["knight_non_combat", "knight_combat"]:
		var sf = load("res://assets/animations/" + res_name + ".tres")
		if sf:
			print("\n[%s] — %d animations:" % [res_name, sf.get_animation_names().size()])
			for a in sf.get_animation_names():
				print("  %s — %d frames" % [a, sf.get_frame_count(a)])
