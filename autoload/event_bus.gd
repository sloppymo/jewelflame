extends Node

# Wave 1 Signals
signal ProvinceSelected(id: int)
signal GameSaved(slot: int)
signal GameLoaded(slot: int)
signal ProvinceDataChanged(id: int, field: String, value: Variant)
signal ProvinceExhausted(id: int, exhausted: bool)

# Reserved for Part 2 (define now to prevent signature conflicts)
signal TurnEnded(month: int, year: int)
signal BattleInitiated(battle_data: Dictionary)
signal BattleResolved(result: Dictionary)
signal TroopsMoved(from_id: int, to_id: int, count: int)
signal HarvestReportReady(province_yields: Dictionary)

# Additional signals for complete game
signal CommandExecuted(command: Dictionary)
signal SelectionCleared()
signal LordSelected(lord_id: String)
signal SceneTransitionStarted()
signal SceneTransitionCompleted()
signal VictoryAchieved(winner_family: String)
signal GameOver(loser_family: String)
signal VassalRecruited(lord_id: String, new_family: String)
signal TurnAdvanced(family_id: String)
signal PhaseChanged(phase_name: String)
signal BattleCancelled(command_id: String)
signal BattleCompleted(result: Dictionary)
signal LordCommandCompleted(lord_id: String, command_type: String)

# Missing signals for command system
signal CommandUndone(command: Dictionary)
signal CommandRedone(command: Dictionary)

# Missing signals for turn management
signal FamilyTurnStarted(family_id: String)
signal LordTurnStarted(lord_id: String)
signal LordCommandPhase(lord_id: String, commands_remaining: int)

# Additional missing signals for complete system
signal TurnCompleted(month: int, year: int)
