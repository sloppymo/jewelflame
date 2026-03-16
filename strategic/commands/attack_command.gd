class_name AttackCommand
extends Command

# Command to attack a province from an adjacent province
# CombatResolver is an autoload - accessed directly

var attacker_province_id: StringName
var defender_province_id: StringName
var attacker_faction_id: StringName
var defender_faction_id: StringName

# Stored state for undo
var _old_attacker_troops: int = 0
var _old_defender_troops: int = 0
var _old_owner_id: StringName = &""
var _battle_result = null  # BattleResult or null
var _province_captured: bool = false

func _init(source_id: StringName, target_id: StringName) -> void:
	super._init()
	command_name = "Attack"
	attacker_province_id = source_id
	defender_province_id = target_id

func execute() -> bool:
	var gs = GameState
	if gs == null:
		push_error("AttackCommand: GameState not available")
		return false
	
	var attacker = gs.provinces.get(attacker_province_id)
	var defender = gs.provinces.get(defender_province_id)
	
	if attacker == null or defender == null:
		push_error("AttackCommand: Invalid province IDs")
		return false
	
	if not attacker.has_owner():
		push_error("AttackCommand: Attacker province has no owner")
		return false
	
	# Store state for undo
	_old_attacker_troops = attacker.troops
	_old_defender_troops = defender.troops
	_old_owner_id = defender.owner_faction_id
	attacker_faction_id = attacker.owner_faction_id
	defender_faction_id = defender.owner_faction_id
	
	# Check adjacency
	if not attacker.is_adjacent_to(defender_province_id):
		push_error("AttackCommand: Provinces not adjacent")
		return false
	
	# Mark attacker as exhausted
	attacker.is_exhausted = true
	EventBus.ProvinceExhausted.emit(attacker_province_id, true)
	
	# Resolve battle using CombatResolver (autoload)
	if CombatResolver == null:
		push_error("AttackCommand: CombatResolver not available")
		return false
	
	_battle_result = CombatResolver.resolve_battle(
		attacker_faction_id,
		defender_faction_id,
		attacker_province_id,
		defender_province_id
	)
	
	if _battle_result == null:
		push_error("AttackCommand: Battle resolution failed")
		return false
	
	# Handle capture (CombatResolver already updates troop counts)
	if _battle_result.attacker_won:
		_province_captured = true
		gs.transfer_province_ownership(defender_province_id, defender_faction_id, attacker_faction_id)
		
		# Transfer loot
		var loot_gold = int(defender.base_income * 0.3)
		var attacker_faction = gs.factions.get(attacker_faction_id)
		if attacker_faction:
			attacker_faction.gold += loot_gold
	
	status = Status.EXECUTED
	EventBus.BattleResolved.emit({
		"attacker_faction_id": _battle_result.attacker_faction_id,
		"defender_faction_id": _battle_result.defender_faction_id,
		"source_province_id": _battle_result.source_province_id,
		"target_province_id": _battle_result.target_province_id,
		"attacker_won": _battle_result.attacker_won,
		"attacker_losses": _battle_result.attacker_losses,
		"defender_losses": _battle_result.defender_losses,
		"troops_moved_to_target": _battle_result.troops_moved_to_target
	})
	return true

func undo() -> bool:
	if status != Status.EXECUTED:
		push_warning("AttackCommand: Cannot undo - not executed")
		return false
	
	var gs = GameState
	if gs == null:
		return false
	
	var attacker = gs.provinces.get(attacker_province_id)
	var defender = gs.provinces.get(defender_province_id)
	
	if attacker == null or defender == null:
		return false
	
	# Restore troop counts
	attacker.troops = _old_attacker_troops
	defender.troops = _old_defender_troops
	
	# Restore ownership if captured
	if _province_captured:
		gs.transfer_province_ownership(defender_province_id, attacker_faction_id, _old_owner_id)
	
	# Un-exhaust attacker
	attacker.is_exhausted = false
	EventBus.ProvinceExhausted.emit(attacker_province_id, false)
	
	status = Status.UNDONE
	return true

func get_description() -> String:
	var gs = GameState
	if gs == null:
		return "Attack"
	
	var attacker = gs.provinces.get(attacker_province_id)
	var defender = gs.provinces.get(defender_province_id)
	
	if attacker == null or defender == null:
		return "Attack"
	
	var result = "Attack %s from %s" % [defender.province_name, attacker.province_name]
	if status == Status.EXECUTED:
		if _province_captured:
			result += " (Captured)"
		else:
			result += " (Defeated)"
	return result
