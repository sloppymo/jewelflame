extends Node

const FactionData = preload("res://resources/data_classes/faction_data.gd")
const ProvinceData = preload("res://resources/data_classes/province_data.gd")
const MassBattleScene = preload("res://scenes/combat/mass_battle.tscn")
const DragonForceBattleScene = preload("res://dragon_force/dragon_force_battle.tscn")

## Enable mass battle system instead of auto-resolve
@export var use_mass_battle: bool = true

## Use Dragon Force RTS battle (Phase 1: 1v1 General battle)
@export var use_dragon_force: bool = true

signal battle_resolved(result: BattleResult)
signal battle_started(attacker: StringName, defender: StringName, location: StringName)

class BattleResult:
	var attacker_faction_id: StringName
	var defender_faction_id: StringName
	var source_province_id: StringName
	var target_province_id: StringName
	var attacker_won: bool
	var attacker_losses: int
	var defender_losses: int
	var troops_moved_to_target: int
	
	func _init(a: StringName, d: StringName, s: StringName, t: StringName, 
			   won: bool, a_loss: int, d_loss: int, moved: int):
		attacker_faction_id = a
		defender_faction_id = d
		source_province_id = s
		target_province_id = t
		attacker_won = won
		attacker_losses = a_loss
		defender_losses = d_loss
		troops_moved_to_target = moved

func resolve_battle(attacker_id: StringName, defender_id: StringName,
				   source_id: StringName, target_id: StringName) -> BattleResult:
	
	# Launch mass battle if enabled
	if use_mass_battle:
		_launch_mass_battle(attacker_id, defender_id, source_id, target_id)
		return null  # Battle will resolve asynchronously
	
	# Null safety
	if GameState == null:
		push_error("CombatResolver: GameState not available")
		return null
	
	if not GameState.provinces.has(source_id) or not GameState.provinces.has(target_id):
		push_error("Invalid province IDs in combat")
		return null
	
	if not GameState.factions.has(attacker_id) or not GameState.factions.has(defender_id):
		push_error("Invalid faction IDs in combat")
		return null
	
	var source: ProvinceData = GameState.provinces[source_id]
	var target: ProvinceData = GameState.provinces[target_id]
	
	# Validate adjacency
	if not source.is_adjacent_to(target_id):
		push_error("Combat failed: provinces not adjacent")
		return null
	
	# Validate ownership
	if source.owner_faction_id != attacker_id:
		push_error("Combat failed: attacker doesn't own source province")
		return null
	
	if target.owner_faction_id != defender_id:
		push_error("Combat failed: target not owned by defender")
		return null
	
	# Combat calculation
	battle_started.emit(attacker_id, defender_id, target_id)
	
	var attack_power := source.troops * 1.0
	var defense_power := target.troops * target.get_defense_bonus()
	
	var attacker_won := attack_power > defense_power
	var attacker_losses: int
	var defender_losses: int
	var troops_moved := 0
	
	if attacker_won:
		# Attacker wins: 30% losses, 70% of survivors occupy target
		attacker_losses = int(source.troops * GameConfig.ATTACKER_WIN_LOSS_RATIO)
		defender_losses = target.troops
		
		var surviving_attackers: int = source.troops - attacker_losses
		troops_moved = int(surviving_attackers * GameConfig.ATTACKER_WIN_SURVIVOR_RATIO)
		var troops_returned := surviving_attackers - troops_moved
		
		# Apply results
		target.troops = troops_moved
		target.owner_faction_id = attacker_id
		source.troops = troops_returned
		
		# Transfer ownership
		GameState.transfer_province_ownership(target_id, defender_id, attacker_id)
		
	else:
		# Attacker loses: 50% losses retreating, defenders lose 20%
		attacker_losses = int(source.troops * GameConfig.ATTACKER_LOSS_RATIO)
		defender_losses = int(target.troops * GameConfig.DEFENDER_LOSS_RATIO)
		
		source.troops -= attacker_losses
		target.troops -= defender_losses
		
		# Ensure minimum garrison
		if source.troops < GameConfig.MIN_GARRISON_SIZE:
			source.troops = GameConfig.MIN_GARRISON_SIZE
		if target.troops < GameConfig.MIN_GARRISON_SIZE:
			target.troops = GameConfig.MIN_GARRISON_SIZE
	
	var result := BattleResult.new(attacker_id, defender_id, source_id, target_id,
								  attacker_won, attacker_losses, defender_losses, troops_moved)
	
	# Handle lord capture if province was taken
	if attacker_won:
		_capture_province_governor(target_id, attacker_id)
	
	# Update GameState
	GameState.record_battle_result(result)
	battle_resolved.emit(result)
	
	return result

func _launch_mass_battle(attacker_id: StringName, defender_id: StringName,
						source_id: StringName, target_id: StringName) -> void:
	"""Launch the tactical battle scene."""
	
	var gs = GameState
	if gs == null:
		return
	
	var source: ProvinceData = gs.provinces[source_id]
	var target: ProvinceData = gs.provinces[target_id]
	
	# Build battle data
	var attacker_data = {
		"province_id": source_id,
		"province_name": source.province_name,
		"family_id": attacker_id,
		"lord": null,
		"units": [],
		"total_soldiers": source.troops,
		"time_of_day": "day"
	}
	
	var defender_data = {
		"province_id": target_id,
		"province_name": target.province_name,
		"family_id": defender_id,
		"lord": null,
		"units": [],
		"total_soldiers": target.troops,
		"terrain": "grass",
		"personality": "balanced"
	}
	
	# Use Dragon Force battle if enabled
	if use_dragon_force:
		_launch_dragon_force_battle(attacker_data, defender_data, attacker_id, defender_id, source_id, target_id)
	else:
		_launch_legacy_mass_battle(attacker_data, defender_data, attacker_id, defender_id, source_id, target_id)

func _launch_dragon_force_battle(attacker_data: Dictionary, defender_data: Dictionary,
								  attacker_id: StringName, defender_id: StringName,
								  source_id: StringName, target_id: StringName) -> void:
	"""Launch the Dragon Force RTS battle scene."""
	
	print("CombatResolver: Launching Dragon Force battle - ", attacker_data.province_name, " vs ", defender_data.province_name)
	
	# Create and setup battle
	var battle = DragonForceBattleScene.instantiate()
	battle.attacker_data = attacker_data
	battle.defender_data = defender_data
	battle.battle_ended.connect(_on_dragon_force_battle_ended.bind(attacker_id, defender_id, source_id, target_id))
	
	# Setup UI
	battle.ui_layer.setup(battle)
	
	# Change scene
	var old_scene = get_tree().current_scene
	get_tree().root.add_child(battle)
	get_tree().current_scene = battle
	if old_scene:
		old_scene.queue_free()

func _launch_legacy_mass_battle(attacker_data: Dictionary, defender_data: Dictionary,
								attacker_id: StringName, defender_id: StringName,
								source_id: StringName, target_id: StringName) -> void:
	"""Launch the legacy mass battle scene."""
	
	# Create and setup battle
	var battle = MassBattleScene.instantiate()
	battle.attacker_data = attacker_data
	battle.defender_data = defender_data
	battle.battle_ended.connect(_on_mass_battle_ended.bind(attacker_id, defender_id, source_id, target_id))
	
	# Change scene
	var old_scene = get_tree().current_scene
	get_tree().root.add_child(battle)
	get_tree().current_scene = battle
	if old_scene:
		old_scene.queue_free()
	
	print("CombatResolver: Launched mass battle - ", attacker_data.province_name, " vs ", defender_data.province_name)

func _on_dragon_force_battle_ended(result: Dictionary, attacker_id: StringName, defender_id: StringName,
								   source_id: StringName, target_id: StringName) -> void:
	"""Handle Dragon Force battle completion and apply results."""
	
	var gs = GameState
	if gs == null:
		return
	
	var source: ProvinceData = gs.provinces[source_id]
	var target: ProvinceData = gs.provinces[target_id]
	
	var attacker_won = result.get("attacker_won", result.get("player_won", false))
	var attacker_troops = result.get("player_troops_remaining", 0)
	var defender_troops = result.get("enemy_troops_remaining", 0)
	
	# Calculate losses
	var attacker_losses = source.troops - attacker_troops
	var defender_losses = target.troops - defender_troops
	
	if attacker_won:
		# Attacker wins - occupy province
		target.troops = max(GameConfig.MIN_GARRISON_SIZE, attacker_troops / 2)
		target.owner_faction_id = attacker_id
		source.troops = max(GameConfig.MIN_GARRISON_SIZE, attacker_troops / 2)
		
		# Transfer ownership
		gs.transfer_province_ownership(target_id, defender_id, attacker_id)
		
		# Handle governor capture
		_capture_province_governor(target_id, attacker_id)
	else:
		# Defender wins
		source.troops = max(GameConfig.MIN_GARRISON_SIZE, attacker_troops)
		target.troops = max(GameConfig.MIN_GARRISON_SIZE, defender_troops)
	
	# Create result object
	var battle_result := BattleResult.new(
		attacker_id, defender_id, source_id, target_id,
		attacker_won, attacker_losses, defender_losses,
		attacker_troops / 2 if attacker_won else 0
	)
	
	gs.record_battle_result(battle_result)
	battle_resolved.emit(battle_result)
	
	# Return to strategic map
	var strategic = load("res://main_strategic.tscn").instantiate()
	var current = get_tree().current_scene
	get_tree().root.add_child(strategic)
	get_tree().current_scene = strategic
	if current:
		current.queue_free()

func _on_mass_battle_ended(result: Dictionary, attacker_id: StringName, defender_id: StringName,
						   source_id: StringName, target_id: StringName) -> void:
	"""Handle mass battle completion and apply results."""
	
	var gs = GameState
	if gs == null:
		return
	
	var source: ProvinceData = gs.provinces[source_id]
	var target: ProvinceData = gs.provinces[target_id]
	
	var attacker_won = result.get("attacker_won", false)
	var attacker_survivors = result.get("attacker_survivors", 0)
	var defender_survivors = result.get("defender_survivors", 0)
	
	# Convert survivors back to troop counts (5 fighters per group, ~20 soldiers per fighter)
	var attacker_remaining = attacker_survivors * 20
	var defender_remaining = defender_survivors * 20
	
	# Calculate losses
	var attacker_losses = source.troops - attacker_remaining
	var defender_losses = target.troops - defender_remaining
	
	if attacker_won:
		# Attacker wins - occupy province
		target.troops = attacker_remaining / 2  # Half occupy, half return
		target.owner_faction_id = attacker_id
		source.troops = attacker_remaining / 2
		
		# Transfer ownership
		gs.transfer_province_ownership(target_id, defender_id, attacker_id)
		
		# Handle governor capture
		_capture_province_governor(target_id, attacker_id)
	else:
		# Defender wins
		source.troops = max(GameConfig.MIN_GARRISON_SIZE, attacker_remaining)
		target.troops = max(GameConfig.MIN_GARRISON_SIZE, defender_remaining)
	
	# Create result object
	var battle_result := BattleResult.new(
		attacker_id, defender_id, source_id, target_id,
		attacker_won, attacker_losses, defender_losses,
		attacker_remaining / 2 if attacker_won else 0
	)
	
	gs.record_battle_result(battle_result)
	battle_resolved.emit(battle_result)
	
	# Return to strategic map
	var strategic = load("res://main_strategic.tscn").instantiate()
	var current = get_tree().current_scene
	get_tree().root.add_child(strategic)
	get_tree().current_scene = strategic
	if current:
		current.queue_free()

func _capture_province_governor(province_id: StringName, captor_faction_id: StringName) -> void:
	var lm = LordManager
	if lm == null:
		return
	
	var governor = lm.get_province_governor(province_id)
	if governor == null:
		return
	
	# Don't capture if already belongs to captor's faction
	if governor.family_id == captor_faction_id:
		return
	
	# Capture the governor
	lm.capture_lord(governor.id, captor_faction_id, province_id)
	
	# Remove governor from province
	var gs = GameState
	if gs and gs.provinces.has(province_id):
		gs.provinces[province_id].governor_id = &""
