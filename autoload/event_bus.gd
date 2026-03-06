extends Node

# Wave 1 Signals
signal ProvinceSelected(id: int)
signal GameSaved(slot: int)
signal GameLoaded(slot: int)
signal ProvinceDataChanged(id: int, field: String, value: Variant)
signal ProvinceExhausted(id: int, exhausted: bool)

# Reserved for Part 2 (define now to prevent signature conflicts)
signal TurnEnded(month: int, year: int)
signal BattleResolved(result: Dictionary)
signal TroopsMoved(from_id: int, to_id: int, count: int)
signal HarvestReportReady(province_yields: Dictionary)
