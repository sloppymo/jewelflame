extends Node

# Signal bus for cross-system communication
# These signals are emitted and connected by other systems, not by EventBus itself

@warning_ignore("unused_signal")
signal ProvinceSelected(id: StringName)

@warning_ignore("unused_signal")
signal GameSaved(slot: int)

@warning_ignore("unused_signal")
signal GameLoaded(slot: int)

@warning_ignore("unused_signal")
signal ProvinceDataChanged(id: StringName, field: String, value: Variant)

@warning_ignore("unused_signal")
signal ProvinceExhausted(id: StringName, exhausted: bool)

@warning_ignore("unused_signal")
signal TurnEnded(month: int, year: int)

@warning_ignore("unused_signal")
signal TurnCompleted(month: int, year: int)

@warning_ignore("unused_signal")
signal FamilyTurnStarted(family_id: StringName)

@warning_ignore("unused_signal")
signal LordTurnStarted(lord_id: StringName)

@warning_ignore("unused_signal")
signal BattleResolved(result: Dictionary)

@warning_ignore("unused_signal")
signal TroopsMoved(from_id: StringName, to_id: StringName, count: int)

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

# FX system signals
@warning_ignore("unused_signal")
signal CameraShakeRequested(strength: float, duration: float, priority: int)
