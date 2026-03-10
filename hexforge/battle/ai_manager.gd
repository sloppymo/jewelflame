## HexForge/Battle/AIManager
## Handles AI opponent decision making
## Part of HexForge battle system

class_name AIManager
extends Node

const HexMath = preload("res://hexforge/core/hex_math.gd")
const Pathfinder = preload("res://hexforge/services/pathfinder.gd")

# ============================================================================
# SIGNALS
# ============================================================================

signal ai_turn_started(side: String)
signal ai_turn_completed(side: String)
signal ai_action_started(action: String, unit_id: String)
signal ai_action_completed(action: String, unit_id: String)

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var battle_controller = null
@export var think_delay: float = 0.5  # Delay between actions

## AI difficulty settings
enum Difficulty { EASY, NORMAL, HARD }
@export var difficulty: Difficulty = Difficulty.NORMAL

# ============================================================================
# STATE
# ============================================================================

var _is_processing: bool = false
var _current_side: String = ""

# ============================================================================
# TURN HANDLING
# ============================================================================

func process_ai_turn(side: String) -> void:
    if _is_processing:
        return
    
    _is_processing = true
    _current_side = side
    
    ai_turn_started.emit(side)
    
    # Get all AI units
    var ai_units = battle_controller.unit_manager.get_units_by_side(side, true)
    
    # Process each unit
    for unit in ai_units:
        await _process_unit_turn(unit)
        await get_tree().create_timer(think_delay).timeout
    
    ai_turn_completed.emit(side)
    _is_processing = false

func _process_unit_turn(unit) -> void:
    if not unit.is_alive():
        return
    
    ai_action_started.emit("thinking", unit.id)
    
    # Get possible actions
    var enemies = battle_controller.unit_manager.get_units_by_side(
        _get_enemy_side(unit.side), true
    )
    
    if enemies.is_empty():
        return
    
    # Find best target
    var target = _select_target(unit, enemies)
    if not target:
        return
    
    # Try to attack
    if _can_attack(unit, target):
        if not unit.has_attacked:
            await _execute_attack(unit, target)
            return
    
    # Move toward target
    if not unit.has_moved:
        await _execute_move_toward(unit, target)

# ============================================================================
# DECISION MAKING
# ============================================================================

func _select_target(unit, enemies: Array):
    var best_target = null
    var best_score: float = -INF
    
    for enemy in enemies:
        var score = _evaluate_target(unit, enemy)
        if score > best_score:
            best_score = score
            best_target = enemy
    
    return best_target

func _evaluate_target(unit, target) -> float:
    var score: float = 0.0
    
    # Distance (closer is better)
    var distance = HexMath.distance(unit.cube, target.cube)
    score -= distance * 10.0
    
    # Target HP (weaker targets preferred)
    score += (target.max_hp - target.current_hp) * 2.0
    
    # Can attack?
    if _can_attack(unit, target):
        score += 50.0
    
    # Expected damage
    var expected_damage = battle_controller.combat_engine.calculate_expected_damage(unit.id, target.id)
    score += expected_damage * 5.0
    
    # Difficulty modifiers
    match difficulty:
        Difficulty.EASY:
            score *= 0.8  # Make suboptimal choices
        Difficulty.HARD:
            score *= 1.2  # Better target selection
    
    return score

func _can_attack(unit, target) -> bool:
    var distance = HexMath.distance(unit.cube, target.cube)
    if distance > unit.attack_range:
        return false
    
    return battle_controller.combat_engine.can_attack(unit.id, target.id)

# ============================================================================
# ACTION EXECUTION
# ============================================================================

func _execute_attack(unit, target) -> void:
    ai_action_started.emit("attack", unit.id)
    
    battle_controller.combat_engine.resolve_attack(unit.id, target.id)
    unit.has_attacked = true
    
    await get_tree().create_timer(0.3).timeout
    ai_action_completed.emit("attack", unit.id)

func _execute_move_toward(unit, target) -> void:
    ai_action_started.emit("move", unit.id)
    
    # Find path to target
    var path = Pathfinder.find_path(
        battle_controller.battle_grid.grid,
        unit.cube,
        target.cube,
        unit.unit_type,
        int(unit.movement)
    )
    
    if path.is_empty():
        ai_action_completed.emit("move", unit.id)
        return
    
    # Find furthest reachable position along path
    var best_cube: Vector3i = unit.cube
    var accumulated_cost: float = 0.0
    
    for i in range(1, path.size()):
        var from_cube = path[i - 1]
        var to_cube = path[i]
        
        var cost = battle_controller.battle_grid.grid.get_movement_cost_between(
            from_cube, to_cube, unit.unit_type
        )
        
        if accumulated_cost + cost > unit.movement:
            break
        
        # Check if position is occupied
        if battle_controller.unit_manager.has_unit_at(to_cube):
            break
        
        accumulated_cost += cost
        best_cube = to_cube
    
    # Execute move
    if best_cube != unit.cube:
        battle_controller.unit_manager.move_unit(unit.id, best_cube)
        unit.has_moved = true
    
    await get_tree().create_timer(0.3).timeout
    ai_action_completed.emit("move", unit.id)

# ============================================================================
# UTILITY
# ============================================================================

func _get_enemy_side(side: String) -> String:
    return "defender" if side == "attacker" else "attacker"

func is_ai_processing() -> bool:
    return _is_processing
