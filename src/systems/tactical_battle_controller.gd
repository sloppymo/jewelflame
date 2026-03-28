extends Node
## TacticalBattleController - Wrapper/Extension for MassBattleController
## Provides battle transition integration and auto-resolve functionality

signal battle_ended(result: Dictionary)

## Reference to the actual battle controller (MassBattleController or similar)
var mass_battle_controller = null

var battle_data: Dictionary = {}
var attacker_faction: StringName
var defender_faction: StringName
var is_battle_active: bool = false
var battle_timer: float = 0.0

func _ready() -> void:
	## Find the actual battle controller in the scene
	mass_battle_controller = _find_mass_battle_controller()
	
	if mass_battle_controller:
		# Connect to existing battle controller's signals
		if mass_battle_controller.has_signal("battle_ended"):
			mass_battle_controller.battle_ended.connect(_on_mass_battle_ended)
		if mass_battle_controller.has_signal("battle_started"):
			mass_battle_controller.battle_started.connect(_on_battle_started)
	
	# Check if we came from strategic map via BattleTransition
	if not BattleTransition.pending_battle.is_empty():
		_setup_from_strategic_transition()
	else:
		_setup_direct_test()
	
	is_battle_active = true

func _find_mass_battle_controller():
	## Try to find the existing battle controller in the scene
	# Look for MassBattleController
	var controller = get_tree().get_first_node_in_group("mass_battle_controller")
	if controller:
		return controller
	
	# Search in siblings or parent
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child.has_method("set_pause"):  # MassBattleController has this method
				return child
			if child.get_script() and "MassBattleController" in str(child.get_script().get_path()):
				return child
	
	return null

func _setup_from_strategic_transition() -> void:
	## Configure battle based on strategic transition data
	battle_data = BattleTransition.pending_battle.duplicate()
	attacker_faction = battle_data.get("attacker_faction", &"blanche")
	defender_faction = battle_data.get("defender_faction", &"coryll")
	
	print("TacticalBattleController: Setup from strategic - %s vs %s" % [attacker_faction, defender_faction])
	
	# If we have the mass battle controller, configure it
	if mass_battle_controller:
		if mass_battle_controller.has_method("set_attacker_data"):
			mass_battle_controller.set_attacker_data({
				"faction_id": attacker_faction,
				"troops": battle_data.get("attacker_troops", 100),
				"province_id": battle_data.get("attacker_province", &""),
				"general_name": _get_general_name(attacker_faction)
			})
		if mass_battle_controller.has_method("set_defender_data"):
			mass_battle_controller.set_defender_data({
				"faction_id": defender_faction,
				"troops": battle_data.get("defender_troops", 100),
				"province_id": battle_data.get("defender_province", &""),
				"general_name": _get_general_name(defender_faction)
			})

func _setup_direct_test() -> void:
	## Fallback for direct scene testing
	attacker_faction = GameState.player_faction_id
	defender_faction = &"coryll"
	
	# Default to first enemy faction if player is blanche
	if attacker_faction == &"blanche":
		defender_faction = &"coryll"
	elif attacker_faction == &"coryll":
		defender_faction = &"lyle"
	else:
		defender_faction = &"blanche"
	
	battle_data = {
		"attacker_troops": 100,
		"defender_troops": 100,
		"attacker_faction": attacker_faction,
		"defender_faction": defender_faction
	}
	
	print("TacticalBattleController: Direct test mode - %s vs %s" % [attacker_faction, defender_faction])

func _get_general_name(faction_id: StringName) -> String:
	## Get a general name for the faction
	match faction_id:
		&"blanche": return "Erin Blanche"
		&"coryll": return "Marcus Coryll"
		&"lyle": return "Victor Lyle"
		_: return "Unknown General"

func _process(delta: float) -> void:
	if not is_battle_active:
		return
	
	battle_timer += delta
	
	# Check for timeout (optional)
	if battle_timer > 300.0:  # 5 minute timeout
		_auto_resolve()

func _on_battle_started() -> void:
	print("TacticalBattleController: Battle started!")
	is_battle_active = true

func _on_mass_battle_ended(result: Dictionary) -> void:
	## Handle battle completion from MassBattleController
	print("TacticalBattleController: Mass battle ended!")
	
	is_battle_active = false
	
	# Build standard result format
	var final_result: Dictionary = {
		"winner": "attacker" if result.get("attacker_won", false) else "defender",
		"attacker_won": result.get("attacker_won", false),
		"defender_won": result.get("defender_won", false),
		"attacker_remaining": result.get("attacker_survivors", 0) * 20,  # Convert groups to troops
		"defender_remaining": result.get("defender_survivors", 0) * 20,
		"attacker_losses": result.get("attacker_casualties", 0) * 20,
		"defender_losses": result.get("defender_casualties", 0) * 20,
		"battle_duration": battle_timer,
		"retreat": result.get("retreat", false)
	}
	
	# Merge with original battle data
	final_result.merge(battle_data, true)
	
	print("Battle ended! Winner: %s" % final_result.winner)
	
	battle_ended.emit(final_result)
	
	# Return to strategic map if we came from there
	if not BattleTransition.pending_battle.is_empty():
		await get_tree().create_timer(2.0).timeout  # Brief victory display
		BattleTransition.return_to_strategic_map(final_result)

## Input handling for battle controls
func _input(event: InputEvent) -> void:
	if not is_battle_active:
		return
	
	# ESC to auto-resolve (for testing/quick play)
	if event.is_action_pressed("ui_cancel"):
		_auto_resolve()
	
	# Space to speed up time
	if event.is_action_pressed("ui_accept"):
		Engine.time_scale = 2.0 if Engine.time_scale == 1.0 else 1.0

func _auto_resolve() -> void:
	## Instantly resolve battle using BattleResolver
	if not is_battle_active:
		return
	
	is_battle_active = false
	
	var attacker_troops: int = battle_data.get("attacker_troops", 100)
	var defender_troops: int = battle_data.get("defender_troops", 100)
	
	var resolve_result: Dictionary = BattleResolver.resolve_auto_battle(
		attacker_troops,
		defender_troops
	)
	
	var winner: String = "draw"
	match resolve_result.outcome:
		BattleResolver.BattleOutcome.ATTACKER_WIN:
			winner = "attacker"
		BattleResolver.BattleOutcome.DEFENDER_WIN:
			winner = "defender"
	
	var result: Dictionary = {
		"winner": winner,
		"attacker_won": winner == "attacker",
		"defender_won": winner == "defender",
		"attacker_remaining": resolve_result.attacker_remaining,
		"defender_remaining": resolve_result.defender_remaining,
		"attacker_losses": resolve_result.attacker_losses,
		"defender_losses": resolve_result.defender_losses,
		"battle_duration": battle_timer,
		"auto_resolved": true,
		"retreat": false
	}
	
	# Merge with original battle data
	result.merge(battle_data, true)
	
	battle_ended.emit(result)
	
	if not BattleTransition.pending_battle.is_empty():
		BattleTransition.return_to_strategic_map(result)
