@tool
extends EditorScript

func _run() -> void:
	print("=" .repeat(60))
	print("ARCHER VALIDATION")
	print("=".repeat(60))

	var checks := {
		"PNGs": [
			"res://assets/Citizens - Guards - Warriors/Warriors/Archer_Non-Combat.png",
			"res://assets/Citizens - Guards - Warriors/Warriors/Archer_Combat.png",
		],
		"SpriteFrames": [
			"res://assets/animations/archer_non_combat.tres",
			"res://assets/animations/archer_combat.tres",
		],
		"Scenes": [
			"res://units/archer_unit.gd",
			"res://units/archer_unit.tscn",
			"res://tests/archer_test.tscn",
		],
	}

	var ok := 0
	var missing := 0

	for group in checks:
		print("\n[%s]" % group)
		for path in checks[group]:
			if ResourceLoader.exists(path):
				print("  [OK] ", path)
				ok += 1
			else:
				print("  [MISSING] ", path)
				missing += 1

	print("\n" + "=".repeat(60))
	if missing == 0:
		print("✓ Archer ready (%d files)" % ok)
	else:
		print("✗ %d missing" % missing)
