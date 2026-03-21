@tool
extends EditorScript

func _run() -> void:
	print("=" .repeat(60))
	print("SWORD & SHIELD VALIDATION")
	print("=".repeat(60))

	var checks := {
		"PNGs": [
			"res://assets/Citizens - Guards - Warriors/Warriors/Sword_and_Shield_Fighter_Non-Combat.png",
			"res://assets/Citizens - Guards - Warriors/Warriors/Sword_and_Shield_Fighter_Combat.png",
		],
		"SpriteFrames": [
			"res://assets/animations/swordshield_non_combat.tres",
			"res://assets/animations/swordshield_combat.tres",
		],
		"Scenes": [
			"res://units/sword_shield_unit.gd",
			"res://units/sword_shield_unit.tscn",
			"res://tests/sword_shield_test.tscn",
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
		print("✓ Sword & Shield ready (%d files)" % ok)
	else:
		print("✗ %d missing" % missing)
