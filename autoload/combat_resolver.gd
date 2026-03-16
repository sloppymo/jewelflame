extends Node

const FactionData = preload("res://resources/data_classes/faction_data.gd")
const ProvinceData = preload("res://resources/data_classes/province_data.gd")

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
