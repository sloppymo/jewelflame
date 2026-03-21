@tool
extends EditorScript

func _run() -> void:
	print("=" .repeat(60))
	print("JEWELFLAME SPRITE SHEET VALIDATION")
	print("=".repeat(60))

	var all_checks := {
		"Sword & Shield PNGs": [
			"res://assets/Citizens - Guards - Warriors/Warriors/Sword_and_Shield_Fighter_Non-Combat.png",
			"res://assets/Citizens - Guards - Warriors/Warriors/Sword_and_Shield_Fighter_Combat.png",
		],
		"Sword & Shield SpriteFrames": [
			"res://assets/animations/swordshield_non_combat.tres",
			"res://assets/animations/swordshield_combat.tres",
		],
		"Sword & Shield Scenes": [
			"res://units/sword_shield_unit.gd",
			"res://units/sword_shield_unit.tscn",
			"res://tests/sword_shield_test.tscn",
		],
		"Archer PNGs": [
			"res://assets/Citizens - Guards - Warriors/Warriors/Archer_Non-Combat.png",
			"res://assets/Citizens - Guards - Warriors/Warriors/Archer_Combat.png",
		],
		"Archer SpriteFrames": [
			"res://assets/animations/archer_non_combat.tres",
			"res://assets/animations/archer_combat.tres",
		],
		"Archer Scenes": [
			"res://units/archer_unit.gd",
			"res://units/archer_unit.tscn",
			"res://tests/archer_test.tscn",
		],
	}

	var total_ok := 0
	var total_missing := 0

	for group_name in all_checks:
		print("\n[%s]" % group_name)
		for path in all_checks[group_name]:
			if ResourceLoader.exists(path):
				print("  [OK]      ", path)
				total_ok += 1
			else:
				print("  [MISSING] ", path)
				total_missing += 1

	print("\n" + "=".repeat(60))
	print("SPRITEFRAMES CONTENTS")
	print("=".repeat(60))

	var resources := {
		"swordshield_non_combat": ["res://assets/animations/swordshield_non_combat.tres", 31],
		"swordshield_combat":     ["res://assets/animations/swordshield_combat.tres",     20],
		"archer_non_combat":      ["res://assets/animations/archer_non_combat.tres",       31],
		"archer_combat":          ["res://assets/animations/archer_combat.tres",            8],
	}

	for res_name in resources:
		var path   : String = resources[res_name][0]
		var expected: int   = resources[res_name][1]
		var sf = load(path)
		if sf:
			var count : int = sf.get_animation_names().size()
			var status := "[OK]" if count == expected else "[WARN: expected %d]" % expected
			print("\n%s %s (%d animations):" % [status, res_name, count])
			for a in sf.get_animation_names():
				var fc : int = sf.get_frame_count(a)
				print("  %s — %d frames" % [a, fc])
		else:
			print("\n[NOT LOADED] %s — run EditorScript first" % res_name)

	print("\n" + "=".repeat(60))
	if total_missing == 0:
		print("✓  ALL %d FILES PRESENT. Run test scenes." % total_ok)
	else:
		print("✗  %d files OK, %d files MISSING." % [total_ok, total_missing])
	print("=".repeat(60))
