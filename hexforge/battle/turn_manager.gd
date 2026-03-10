## HexForge/Battle/TurnManager
## Manages turn order, phases, and action reset
## Part of HexForge battle system

class_name TurnManager
extends Node

# ============================================================================
# SIGNALS
# ============================================================================

signal turn_started(turn_number: int, active_side: String)
signal turn_ended(turn_number: int, active_side: String)
signal phase_started(phase: String, side: String)
signal phase_ended(phase: String, side: String)
signal round_completed(round_number: int)

# ============================================================================
# CONFIGURATION
# ============================================================================

## Turn phases in order
const PHASES: Array[String] = ["start", "action", "end"]

## Sides that take turns
@export var sides: Array[String] = ["attacker", "defender"]

# ============================================================================
# STATE
# ============================================================================

var current_turn: int = 1
var current_side_index: int = 0
var current_phase_index: int = 0
var is_processing: bool = false

# ============================================================================
# PROPERTIES
# ============================================================================

var active_side: String:
    get:
        return sides[current_side_index] if sides.size() > 0 else ""

var current_phase: String:
    get:
        return PHASES[current_phase_index] if current_phase_index < PHASES.size() else ""

# ============================================================================
# TURN FLOW
# ============================================================================

func start_battle() -> void:
    current_turn = 1
    current_side_index = 0
    current_phase_index = 0
    is_processing = false
    
    _start_turn()

func end_turn() -> void:
    if is_processing:
        return
    
    is_processing = true
    
    # End current phase
    _end_phase()
    
    # Advance to next side
    var prev_side := active_side
    current_side_index += 1
    
    if current_side_index >= sides.size():
        # Round complete
        current_side_index = 0
        current_turn += 1
        round_completed.emit(current_turn - 1)
    
    turn_ended.emit(current_turn, prev_side)
    
    # Start next turn
    _start_turn()
    
    is_processing = false

func _start_turn() -> void:
    current_phase_index = 0
    turn_started.emit(current_turn, active_side)
    _start_phase()

func _end_turn() -> void:
    turn_ended.emit(current_turn, active_side)

# ============================================================================
# PHASE MANAGEMENT
# ============================================================================

func _start_phase() -> void:
    phase_started.emit(current_phase, active_side)
    
    match current_phase:
        "start":
            _on_start_phase()
        "action":
            _on_action_phase()
        "end":
            _on_end_phase()

func _end_phase() -> void:
    phase_ended.emit(current_phase, active_side)

func advance_phase() -> void:
    _end_phase()
    
    current_phase_index += 1
    
    if current_phase_index >= PHASES.size():
        # All phases complete, end turn
        end_turn()
    else:
        _start_phase()

func _on_start_phase() -> void:
    # Reset unit actions for this side
    # This would connect to UnitManager
    pass

func _on_action_phase() -> void:
    # Main gameplay phase - wait for player input or AI
    pass

func _on_end_phase() -> void:
    # Cleanup, status effects, etc.
    pass

# ============================================================================
# UTILITY
# ============================================================================

func is_side_active(side: String) -> bool:
    return active_side == side

func get_turn_number() -> int:
    return current_turn

func serialize() -> Dictionary:
    return {
        "turn": current_turn,
        "side_index": current_side_index,
        "phase_index": current_phase_index,
        "sides": sides.duplicate()
    }

func deserialize(data: Dictionary) -> void:
    current_turn = data.get("turn", 1)
    current_side_index = data.get("side_index", 0)
    current_phase_index = data.get("phase_index", 0)
    sides = data.get("sides", ["attacker", "defender"]).duplicate()
