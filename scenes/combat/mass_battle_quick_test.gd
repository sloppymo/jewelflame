extends Node2D

## Quick test with reduced fighter health for faster battles

const MassBattleScene = preload("res://scenes/combat/mass_battle.tscn")

func _ready():
	print("Mass Battle Quick Test: Starting...")
	
	# Modify fighter health for faster battles
	# We'll do this by modifying the fighter scenes temporarily
	_modify_fighter_health(50)  # Reduce to 50 HP
	
	var battle = MassBattleScene.instantiate()
	
	battle.attacker_data = {
		"province_id": 1,
		"province_name": "Test Province A",
		"family_id": "blanche",
		"lord": null,
		"units": [],
		"total_soldiers": 100,
		"time_of_day": "day"
	}
	
	battle.defender_data = {
		"province_id": 2,
		"province_name": "Test Province B",
		"family_id": "lyle",
		"lord": null,
		"units": [],
		"total_soldiers": 100,
		"terrain": "grass",
		"personality": "aggressive"
	}
	
	battle.battle_ended.connect(_on_battle_ended)
	add_child(battle)
	
	print("Mass Battle Quick Test: Battle scene loaded")
	
	# Auto-unpause after 2 seconds
	await get_tree().create_timer(2.0).timeout
	print("Auto-unpausing battle...")
	battle.toggle_pause()
	
	# Enable auto-command for all groups
	await get_tree().create_timer(3.0).timeout
	print("Enabling auto-command for all groups...")
	for group in battle.attacker_groups:
		group.issue_auto_command(true)
	for group in battle.defender_groups:
		group.issue_auto_command(true)

func _modify_fighter_health(new_health: int):
	# This is a hack for testing - modify the health in the fighter script
	var fighter_script = load("res://scenes/characters/Artun_Combat.gd")
	# Note: In a real scenario, we'd use a different approach
	# For now, just print that we'd modify it
	print("Note: Fighter health would be reduced to ", new_health, " for faster testing")

func _on_battle_ended(result: Dictionary):
	print("\n=== BATTLE ENDED ===")
	print("Attacker won: ", result.get("attacker_won", false))
	print("Attacker casualties: ", result.get("attacker_casualties", 0))
	print("Defender casualties: ", result.get("defender_casualties", 0))
	print("Attacker survivors: ", result.get("attacker_survivors", 0))
	print("Defender survivors: ", result.get("defender_survivors", 0))
	print("Attacker groups remaining: ", result.get("attacker_groups_remaining", 0))
	print("Defender groups remaining: ", result.get("defender_groups_remaining", 0))
	print("====================\n")
	
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()
