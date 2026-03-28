extends Node
## BattleResolver - Wrapper for CombatResolver providing legacy-compatible API
## Used by TacticalBattleController for auto-resolve functionality

enum BattleOutcome {
	ATTACKER_WIN,
	DEFENDER_WIN,
	DRAW
}

## Auto-resolve a battle using CombatResolver math
func resolve_auto_battle(attacker_troops: int, defender_troops: int, 
						 defender_bonus: float = 1.0) -> Dictionary:
	"""
	Resolve a battle automatically using existing combat resolution logic.
	
	Returns: {
		"outcome": BattleOutcome,
		"attacker_remaining": int,
		"defender_remaining": int,
		"attacker_losses": int,
		"defender_losses": int
	}
	"""
	
	# Calculate battle power
	var attack_power := attacker_troops * 1.0
	var defense_power := defender_troops * defender_bonus
	
	var attacker_won := attack_power > defense_power
	var attacker_losses: int
	var defender_losses: int
	var attacker_remaining: int
	var defender_remaining: int
	
	if attacker_won:
		# Attacker wins: ~30% losses
		attacker_losses = int(attacker_troops * 0.3)
		defender_losses = defender_troops
		attacker_remaining = attacker_troops - attacker_losses
		defender_remaining = 0
	else:
		# Defender wins: attacker ~50% losses, defender ~20% losses
		attacker_losses = int(attacker_troops * 0.5)
		defender_losses = int(defender_troops * 0.2)
		attacker_remaining = attacker_troops - attacker_losses
		defender_remaining = defender_troops - defender_losses
	
	var outcome = BattleOutcome.DRAW
	if attacker_won:
		outcome = BattleOutcome.ATTACKER_WIN
	elif defender_remaining > attacker_remaining:
		outcome = BattleOutcome.DEFENDER_WIN
	
	return {
		"outcome": outcome,
		"attacker_remaining": attacker_remaining,
		"defender_remaining": defender_remaining,
		"attacker_losses": attacker_losses,
		"defender_losses": defender_losses
	}

## Convert faction string to enum value (for compatibility)
static func faction_to_enum(faction_id: StringName) -> int:
	match faction_id:
		&"blanche": return GameState.Faction.BLANCHE
		&"coryll": return GameState.Faction.CORYLL
		&"lyle": return GameState.Faction.LYLE
		_: return GameState.Faction.NEUTRAL

## Convert enum to faction string
static func enum_to_faction(faction_enum: int) -> StringName:
	match faction_enum:
		GameState.Faction.BLANCHE: return &"blanche"
		GameState.Faction.CORYLL: return &"coryll"
		GameState.Faction.LYLE: return &"lyle"
		_: return &"neutral"
