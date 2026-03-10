## HexForge/Battle/UnitManager
## Manages unit spawning, tracking, and lifecycle
## Part of HexForge battle system

class_name UnitManager
extends Node

const HexCell = preload("res://hexforge/core/hex_cell.gd")

# ============================================================================
# SIGNALS
# ============================================================================

signal unit_spawned(unit_id: String, unit, cube: Vector3i)
signal unit_moved(unit_id: String, from_cube: Vector3i, to_cube: Vector3i)
signal unit_defeated(unit_id: String, side: String)
signal all_units_defeated(side: String)

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var battle_grid = null

# ============================================================================
# STATE
# ============================================================================

var units: Dictionary = {}  # unit_id -> UnitData
var unit_positions: Dictionary = {}  # cube -> unit_id
var _id_counter: int = 0

# ============================================================================
# UNIT DATA CLASS
# ============================================================================

class UnitDataInner:
    var id: String
    var side: String
    var unit_type: String
    var max_hp: int = 10
    var current_hp: int = 10
    var attack: int = 3
    var defense: int = 2
    var movement: float = 5.0
    var attack_range: int = 1
    var has_moved: bool = false
    var has_attacked: bool = false
    var cube: Vector3i = Vector3i.ZERO
    
    # Extension point for custom unit data
    var custom_data: Dictionary = {}
    
    func _init(p_id: String, p_side: String, p_type: String) -> void:
        id = p_id
        side = p_side
        unit_type = p_type
    
    func is_alive() -> bool:
        return current_hp > 0
    
    func reset_actions() -> void:
        has_moved = false
        has_attacked = false
    
    func serialize() -> Dictionary:
        return {
            "id": id,
            "side": side,
            "type": unit_type,
            "hp": current_hp,
            "max_hp": max_hp,
            "attack": attack,
            "defense": defense,
            "movement": movement,
            "range": attack_range,
            "cube": [cube.x, cube.y, cube.z],
            "custom": custom_data.duplicate()
        }
    
    static func deserialize(data: Dictionary) -> UnitDataInner:
        var unit = UnitDataInner.new(
            data.get("id", "unknown"),
            data.get("side", "neutral"),
            data.get("type", "infantry")
        )
        unit.current_hp = data.get("hp", 10)
        unit.max_hp = data.get("max_hp", 10)
        unit.attack = data.get("attack", 3)
        unit.defense = data.get("defense", 2)
        unit.movement = data.get("movement", 5.0)
        unit.attack_range = data.get("range", 1)
        
        var cube_array: Array = data.get("cube", [0, 0, 0])
        unit.cube = Vector3i(cube_array[0], cube_array[1], cube_array[2])
        
        unit.custom_data = data.get("custom", {}).duplicate()
        return unit

# ============================================================================
# SPAWNING
# ============================================================================

func spawn_units(unit_defs: Array, side: String, spawn_area: Array[Vector3i]) -> Array[String]:
    var spawned_ids: Array[String] = []
    
    for i in range(min(unit_defs.size(), spawn_area.size())):
        var def: Dictionary = unit_defs[i]
        var cube = spawn_area[i]
        
        if _is_valid_spawn(cube):
            var unit_id = _generate_unit_id(side)
            var unit = _create_unit(unit_id, side, def)
            _place_unit(unit, cube)
            spawned_ids.append(unit_id)
            unit_spawned.emit(unit_id, unit, cube)
    
    return spawned_ids

func spawn_unit_at(def: Dictionary, side: String, cube: Vector3i) -> String:
    if not _is_valid_spawn(cube):
        return ""
    
    var unit_id = _generate_unit_id(side)
    var unit = _create_unit(unit_id, side, def)
    _place_unit(unit, cube)
    unit_spawned.emit(unit_id, unit, cube)
    return unit_id

func _create_unit(unit_id: String, side: String, def: Dictionary) -> UnitDataInner:
    var unit = UnitDataInner.new(unit_id, side, def.get("type", "infantry"))
    unit.max_hp = def.get("max_hp", def.get("hp", 10))
    unit.current_hp = def.get("hp", unit.max_hp)
    unit.attack = def.get("attack", 3)
    unit.defense = def.get("defense", 2)
    unit.movement = def.get("movement", 5.0)
    unit.attack_range = def.get("range", 1)
    unit.custom_data = def.get("custom", {}).duplicate()
    return unit

func _place_unit(unit: UnitData, cube: Vector3i) -> void:
    unit.cube = cube
    units[unit.id] = unit
    unit_positions[cube] = unit.id
    
    # Mark cell as occupied
    if battle_grid:
        var cell = battle_grid.get_cell(cube)
        if cell:
            cell.occupant_id = unit.id

func _is_valid_spawn(cube: Vector3i) -> bool:
    if not battle_grid or not battle_grid.has_cell(cube):
        return false
    
    var cell = battle_grid.get_cell(cube)
    if cell.blocking or unit_positions.has(cube):
        return false
    
    return true

func _generate_unit_id(side: String) -> String:
    _id_counter += 1
    return "%s_%d" % [side, _id_counter]

# ============================================================================
# MOVEMENT
# ============================================================================

func move_unit(unit_id: String, target_cube: Vector3i) -> bool:
    var unit: UnitDataInner = units.get(unit_id)
    if not unit or not unit.is_alive():
        return false
    
    if unit_positions.has(target_cube):
        return false
    
    var from_cube = unit.cube
    
    # Clear old position
    unit_positions.erase(from_cube)
    if battle_grid:
        var old_cell = battle_grid.get_cell(from_cube)
        if old_cell:
            old_cell.occupant_id = ""
    
    # Set new position
    unit.cube = target_cube
    unit_positions[target_cube] = unit_id
    if battle_grid:
        var new_cell = battle_grid.get_cell(target_cube)
        if new_cell:
            new_cell.occupant_id = unit_id
    
    unit_moved.emit(unit_id, from_cube, target_cube)
    return true

func can_move_to(cube: Vector3i) -> bool:
    if not battle_grid or not battle_grid.has_cell(cube):
        return false
    
    var cell = battle_grid.get_cell(cube)
    return not cell.blocking and not unit_positions.has(cube)

# ============================================================================
# COMBAT
# ============================================================================

func defeat_unit(unit_id: String) -> void:
    var unit: UnitDataInner = units.get(unit_id)
    if not unit:
        return
    
    # Remove from grid
    unit_positions.erase(unit.cube)
    if battle_grid:
        var cell = battle_grid.get_cell(unit.cube)
        if cell:
            cell.occupant_id = ""
    
    unit_defeated.emit(unit_id, unit.side)
    
    # Check if all units on side defeated
    if get_unit_count_by_side(unit.side, true) == 0:
        all_units_defeated.emit(unit.side)

func get_unit_at(cube: Vector3i):
    var unit_id: String = unit_positions.get(cube, "")
    return units.get(unit_id)

func has_unit_at(cube: Vector3i) -> bool:
    return unit_positions.has(cube)

# ============================================================================
# QUERIES
# ============================================================================

func get_unit(unit_id: String):
    return units.get(unit_id)

func get_units_by_side(side: String, alive_only: bool = true) -> Array:
    var result: Array = []
    
    for unit in units.values():
        if unit.side == side:
            if not alive_only or unit.is_alive():
                result.append(unit)
    
    return result

func get_unit_count_by_side(side: String, alive_only: bool = true) -> int:
    return get_units_by_side(side, alive_only).size()

func get_all_units(alive_only: bool = true) -> Array:
    var result: Array = []
    
    for unit in units.values():
        if not alive_only or unit.is_alive():
            result.append(unit)
    
    return result

# ============================================================================
# SERIALIZATION
# ============================================================================

func serialize() -> Array:
    var result: Array = []
    
    for unit in units.values():
        result.append(unit.serialize())
    
    return result

func deserialize(data: Array) -> void:
    clear()
    
    for unit_data in data:
        if unit_data is Dictionary:
            var unit := UnitDataInner.deserialize(unit_data)
            units[unit.id] = unit
            unit_positions[unit.cube] = unit.id

func clear() -> void:
    units.clear()
    unit_positions.clear()
    _id_counter = 0
