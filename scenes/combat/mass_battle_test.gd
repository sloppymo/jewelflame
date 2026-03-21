extends Node2D

## Simple test scene for the Mass Battle system
## Run this scene directly to test RTwP combat

const MassBattleScene = preload("res://scenes/combat/mass_battle.tscn")

func _ready():
	print("Mass Battle Test: Starting...")
	
	# Create battle with test data
	var battle = MassBattleScene.instantiate()
	
	# Set up test battle data
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
	
	# Connect to battle end
	battle.battle_ended.connect(_on_battle_ended)
	
	# Add to scene
	add_child(battle)
	
	print("Mass Battle Test: Battle scene loaded")
	print("Controls:")
	print("  SPACE - Pause/Unpause")
	print("  ESC - Cancel order")
	print("  Click groups to select")
	print("  Move/Attack/Hold buttons for orders")
	print("  Drag box to multi-select")
	
	# Auto-unpause after 3 seconds for testing
	await get_tree().create_timer(3.0).timeout
	print("Auto-unpausing battle...")
	battle.toggle_pause()
	
	# Auto-enable auto-command for all attacker groups after 5 seconds
	await get_tree().create_timer(5.0).timeout
	print("Enabling auto-command for all groups...")
	for group in battle.attacker_groups:
		group.issue_auto_command(true)
	for group in battle.defender_groups:
		group.issue_auto_command(true)

func _on_battle_ended(result: Dictionary):
	print("\n=== BATTLE ENDED ===")
	print("Attacker won: ", result.get("attacker_won", false))
	print("Attacker casualties: ", result.get("attacker_casualties", 0))
	print("Defender casualties: ", result.get("defender_casualties", 0))
	print("Attacker survivors: ", result.get("attacker_survivors", 0))
	print("Defender survivors: ", result.get("defender_survivors", 0))
	print("====================\n")
	
	# Return to main menu after delay
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://main_strategic.tscn")
