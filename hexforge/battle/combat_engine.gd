## HexForge/Battle/CombatEngine
## Handles damage calculation, attack resolution, and combat rules
## Part of HexForge battle system

class_name CombatEngine
extends Node

const HexMath = preload("res://hexforge/core/hex_math.gd")
const HexCell = preload("res://hexforge/core/hex_cell.gd")
const LineOfSight = preload("res://hexforge/services/line_of_sight.gd")

# ============================================================================
# SIGNALS
# ============================================================================

signal attack_resolved(attacker_id: String, defender_id: String, damage: int, hit: bool)
signal damage_dealt(target_id: String, damage: int, remaining_hp: int)
signal unit_defeated(unit_id: String, side: String)

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var battle_grid = null
@export var unit_manager = null

## Minimum damage (always at least 1 on hit)
const MIN_DAMAGE: int = 1

# ============================================================================
# ATTACK RESOLUTION
# ============================================================================

## Attempts to resolve an attack from attacker to defender
## Returns true if attack was valid and resolved
func resolve_attack(attacker_id: String, defender_id: String) -> bool:
    var attacker = unit_manager.get_unit(attacker_id)
    var defender = unit_manager.get_unit(defender_id)
    
    if not _validate_attack(attacker, defender):
        return false
    
    # Calculate damage
    var damage = _calculate_damage(attacker, defender)
    
    # Apply damage
    var remaining_hp = _apply_damage(defender, damage)
    
    attack_resolved.emit(attacker_id, defender_id, damage, true)
    damage_dealt.emit(defender_id, damage, remaining_hp)
    
    # Check defeat
    if remaining_hp <= 0:
        unit_manager.defeat_unit(defender_id)
        unit_defeated.emit(defender_id, defender.side)
    
    return true

func _validate_attack(attacker, defender) -> bool:
    if not attacker or not defender:
        return false
    
    if not attacker.is_alive() or not defender.is_alive():
        return false
    
    if attacker.side == defender.side:
        return false  # No friendly fire
    
    # Check range
    var distance: int = HexMath.distance(attacker.cube, defender.cube)
    if distance > attacker.attack_range:
        return false
    
    # Check LoS
    if battle_grid:
        var attacker_cell = battle_grid.get_cell(attacker.cube)
        var from_elevation: int = attacker_cell.elevation if attacker_cell else 0
        if not LineOfSight.has_los(battle_grid.grid, attacker.cube, defender.cube, from_elevation):
            return false
    
    return true

# ============================================================================
# DAMAGE CALCULATION
# ============================================================================

func _calculate_damage(attacker, defender) -> int:
    var base_damage: int = attacker.attack
    var defense: int = _calculate_defense(defender, attacker)
    
    var damage: int = max(MIN_DAMAGE, base_damage - defense)
    return damage

func _calculate_defense(defender, attacker) -> int:
    var defense: int = defender.defense
    
    # Terrain bonus
    if battle_grid:
        var cell = battle_grid.get_cell(defender.cube)
        if cell:
            defense += cell.get_defense_bonus()
    
    # Cover bonus
    if battle_grid:
        var cover = LineOfSight.check_cover(battle_grid.grid, defender.cube, attacker.cube)
        if cover.has_cover:
            defense += 2 if cover.cover_type == "heavy" else 1
    
    return defense

func _apply_damage(unit, damage: int) -> int:
    unit.current_hp -= damage
    return unit.current_hp

# ============================================================================
# UTILITY
# ============================================================================

## Checks if attacker can attack defender (without executing)
func can_attack(attacker_id: String, defender_id: String) -> bool:
    var attacker = unit_manager.get_unit(attacker_id)
    var defender = unit_manager.get_unit(defender_id)
    return _validate_attack(attacker, defender)

## Gets attackable units from a position
func get_attackable_units(attacker_id: String) -> Array:
    var attacker = unit_manager.get_unit(attacker_id)
    if not attacker:
        return []
    
    var result: Array = []
    
    if not battle_grid:
        return result
    
    var cells_in_range = battle_grid.get_cells_in_range(attacker.cube, attacker.attack_range)
    
    for cell in cells_in_range:
        var unit = unit_manager.get_unit_at(cell.cube_coord)
        if unit and unit.side != attacker.side and unit.is_alive():
            # Check LoS
            var attacker_cell = battle_grid.get_cell(attacker.cube)
            var from_elevation: int = attacker_cell.elevation if attacker_cell else 0
            if LineOfSight.has_los(battle_grid.grid, attacker.cube, unit.cube, from_elevation):
                result.append(unit)
    
    return result

## Calculates expected damage (for AI decisions)
func calculate_expected_damage(attacker_id: String, defender_id: String) -> int:
    var attacker = unit_manager.get_unit(attacker_id)
    var defender = unit_manager.get_unit(defender_id)
    
    if not attacker or not defender:
        return 0
    
    return _calculate_damage(attacker, defender)
