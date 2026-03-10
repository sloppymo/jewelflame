extends Node

# Signal bus for cross-system communication
# These signals are emitted and connected by other systems, not by EventBus itself

@warning_ignore("unused_signal")
signal ProvinceSelected(id: int)

@warning_ignore("unused_signal")
signal GameSaved(slot: int)

@warning_ignore("unused_signal")
signal GameLoaded(slot: int)

@warning_ignore("unused_signal")
signal ProvinceDataChanged(id: int, field: String, value: Variant)

@warning_ignore("unused_signal")
signal ProvinceExhausted(id: int, exhausted: bool)

@warning_ignore("unused_signal")
signal TurnEnded(month: int, year: int)

@warning_ignore("unused_signal")
signal TurnCompleted(month: int, year: int)

@warning_ignore("unused_signal")
signal FamilyTurnStarted(family_id: String)

@warning_ignore("unused_signal")
signal LordTurnStarted(lord_id: String)

@warning_ignore("unused_signal")
signal BattleResolved(result: Dictionary)

@warning_ignore("unused_signal")
signal TroopsMoved(from_id: int, to_id: int, count: int)

@warning_ignore("unused_signal")
signal HarvestReportReady(province_yields: Dictionary)

# Strategic to Tactical bridge signals
@warning_ignore("unused_signal")
signal RequestTacticalBattle(battle_data: Dictionary)

@warning_ignore("unused_signal")
signal TacticalBattleCompleted(result: Dictionary)

# Command system signals
@warning_ignore("unused_signal")
signal CommandSelected(command: String)
