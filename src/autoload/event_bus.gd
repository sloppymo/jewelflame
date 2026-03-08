## Jewelflame/Autoload/EventBus
## Global signal bus for cross-system communication
## All signals routed through here - no direct node references across scenes

extends Node

# ============================================================================
# STRATEGIC LAYER SIGNALS
# ============================================================================

## Province selection
signal province_selected(province_id: String)
signal province_hovered(province_id: String)
signal province_exhausted(province_id: String, exhausted: bool)

## Province data changes
signal province_data_changed(province_id: String, field: String, value: Variant)
signal province_owner_changed(province_id: String, new_owner: String, old_owner: String)

## Turn system
signal turn_ended(month: int, year: int)
signal turn_started(family_id: String)
signal season_changed(season: String)

## Commands
signal recruit_requested(province_id: String)
signal develop_requested(province_id: String, type: String)  # "cultivation" or "protection"
signal attack_requested(from_province_id: String, to_province_id: String)
signal move_requested(from_province_id: String, to_province_id: String, unit_count: int)

## Economy
signal gold_changed(family_id: String, amount: int, total: int)
signal food_changed(family_id: String, amount: int, total: int)
signal mana_changed(family_id: String, amount: int, total: int)
signal upkeep_processed(family_id: String, food_consumed: int)

# ============================================================================
# TACTICAL BATTLE SIGNALS
# ============================================================================

## Battle lifecycle
signal tactical_battle_started(battle_data: Dictionary)
signal tactical_battle_ended(result: Dictionary)
signal battle_state_saved(slot: String)
signal battle_state_loaded(slot: String)

## Combat events
signal unit_spawned(unit_id: String, side: String, position: Vector3i)
signal unit_moved(unit_id: String, from_pos: Vector3i, to_pos: Vector3i)
signal unit_attacked(attacker_id: String, defender_id: String, damage: int)
signal unit_defeated(unit_id: String, side: String)
signal turn_started_battle(side: String)
signal turn_ended_battle(side: String)

# ============================================================================
# UI SIGNALS
# ============================================================================

signal panel_opened(province_id: String)
signal panel_closed()
signal action_completed(action: String, success: bool)
signal error_occurred(message: String)
signal notification_shown(message: String, type: String)  # type: "info", "warning", "error"

# ============================================================================
# SYSTEM SIGNALS
# ============================================================================

signal game_saved(slot: String)
signal game_loaded(slot: String)
signal game_started(new_game: bool)
signal victory_achieved(faction_id: String, condition: String)

# ============================================================================
# DEBUG SIGNALS
# ============================================================================

signal debug_command(command: String, params: Dictionary)
