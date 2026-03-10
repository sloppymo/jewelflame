## HexForge/Battle/BattleController
## Main battle coordinator - wires together all battle systems
## Refactored from monolithic BattleScene
## Part of HexForge battle system

class_name BattleController
extends Node2D

const BattleGrid = preload("res://hexforge/battle/battle_grid.gd")
const UnitManager = preload("res://hexforge/battle/unit_manager.gd")
const TurnManager = preload("res://hexforge/battle/turn_manager.gd")
const CombatEngine = preload("res://hexforge/battle/combat_engine.gd")
const HexRenderer2D = preload("res://hexforge/rendering/hex_renderer_2d.gd")
const HexCursor = preload("res://hexforge/rendering/hex_cursor.gd")
const RangeHighlighter = preload("res://hexforge/rendering/range_highlighter.gd")
const HexCell = preload("res://hexforge/core/hex_cell.gd")
const HexGrid = preload("res://hexforge/core/hex_grid.gd")
const HexMath = preload("res://hexforge/core/hex_math.gd")
const Pathfinder = preload("res://hexforge/services/pathfinder.gd")

# ============================================================================
# SIGNALS
# ============================================================================

signal battle_started(attacker_count: int, defender_count: int)
signal battle_ended(victor: String, result: Dictionary)
signal unit_selected(unit_id: String)
signal action_completed()

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var hex_size: float = 32.0

# ============================================================================
# SUBSYSTEMS
# ============================================================================

var battle_grid = null
var unit_manager = null
var turn_manager = null
var combat_engine = null

# ============================================================================
# RENDERING
# ============================================================================

var renderer = null
var cursor = null
var highlighter = null

# ============================================================================
# STATE
# ============================================================================

var is_active: bool = false
var selected_unit_id: String = ""
var _pending_action: Dictionary = {}

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
    _initialize_subsystems()
    _initialize_rendering()
    _connect_signals()

func _initialize_subsystems() -> void:
    battle_grid = BattleGrid.new()
    add_child(battle_grid)
    
    unit_manager = UnitManager.new()
    unit_manager.battle_grid = battle_grid
    add_child(unit_manager)
    
    turn_manager = TurnManager.new()
    add_child(turn_manager)
    
    combat_engine = CombatEngine.new()
    combat_engine.battle_grid = battle_grid
    combat_engine.unit_manager = unit_manager
    add_child(combat_engine)

func _initialize_rendering() -> void:
    renderer = HexRenderer2D.new()
    renderer.hex_size = hex_size
    add_child(renderer)
    
    cursor = HexCursor.new()
    cursor.enabled = false  # Disabled until battle starts
    add_child(cursor)
    
    highlighter = RangeHighlighter.new()
    highlighter.renderer = renderer
    add_child(highlighter)

func _connect_signals() -> void:
    # Grid signals
    battle_grid.grid_loaded.connect(_on_grid_loaded)
    
    # Unit signals
    unit_manager.unit_spawned.connect(_on_unit_spawned)
    unit_manager.unit_moved.connect(_on_unit_moved)
    unit_manager.unit_defeated.connect(_on_unit_defeated)
    unit_manager.all_units_defeated.connect(_on_all_units_defeated)
    
    # Turn signals
    turn_manager.turn_started.connect(_on_turn_started)
    turn_manager.turn_ended.connect(_on_turn_ended)
    
    # Combat signals
    combat_engine.attack_resolved.connect(_on_attack_resolved)
    combat_engine.unit_defeated.connect(_on_combat_unit_defeated)
    
    # Input signals
    cursor.cell_clicked.connect(_on_cell_clicked)
    cursor.cell_hovered.connect(_on_cell_hovered)

# ============================================================================
# BATTLE LIFECYCLE
# ============================================================================

func start_battle(map_data: Variant = null, attacker_units: Array = [], defender_units: Array = []) -> void:
    is_active = true
    selected_unit_id = ""
    
    # Load grid
    battle_grid.load_grid(map_data)
    
    # Spawn units
    var attacker_spawns = _calculate_spawn_positions("attacker", attacker_units.size())
    var defender_spawns = _calculate_spawn_positions("defender", defender_units.size())
    
    unit_manager.spawn_units(attacker_units, "attacker", attacker_spawns)
    unit_manager.spawn_units(defender_units, "defender", defender_spawns)
    
    # Enable input
    cursor.grid = battle_grid.grid
    cursor.renderer = renderer
    cursor.enabled = true
    
    # Start turn system
    turn_manager.start_battle()
    
    battle_started.emit(attacker_units.size(), defender_units.size())

func end_battle(victor: String) -> void:
    is_active = false
    cursor.enabled = false
    
    var result = {
        "victor": victor,
        "turns": turn_manager.get_turn_number(),
        "attacker_casualties": _count_casualties("attacker"),
        "defender_casualties": _count_casualties("defender"),
        "survivors": unit_manager.serialize()
    }
    
    battle_ended.emit(victor, result)

func _count_casualties(side: String) -> int:
    var total = unit_manager.get_unit_count_by_side(side, false)
    var alive = unit_manager.get_unit_count_by_side(side, true)
    return total - alive

# ============================================================================
# SPAWN POSITIONS
# ============================================================================

func _calculate_spawn_positions(side: String, count: int) -> Array[Vector3i]:
    var positions: Array[Vector3i] = []
    var grid_width: int = battle_grid.grid_width
    var grid_height: int = battle_grid.grid_height
    
    var start_q: int = -grid_width / 2 + 1 if side == "attacker" else grid_width / 2 - 1
    var r_offset: int = -grid_height / 2 + 1
    
    for i in range(count):
        var r: int = r_offset + (i * 2)
        var cube = HexMath.axial_to_cube(Vector2i(start_q, r))
        positions.append(cube)
    
    return positions

# ============================================================================
# INPUT HANDLING
# ============================================================================

func _on_cell_clicked(cube: Vector3i, cell, button: int) -> void:
    if not is_active:
        return
    
    if button == MOUSE_BUTTON_LEFT:
        _handle_left_click(cube)
    elif button == MOUSE_BUTTON_RIGHT:
        _handle_right_click(cube)

func _handle_left_click(cube: Vector3i) -> void:
    # Check if clicking on a unit
    var clicked_unit = unit_manager.get_unit_at(cube)
    
    if clicked_unit:
        if clicked_unit.side == turn_manager.active_side:
            # Select friendly unit
            _select_unit(clicked_unit.id)
            return
        elif selected_unit_id != "":
            # Attack enemy unit
            _attempt_attack(selected_unit_id, clicked_unit.id)
            return
    
    # Move selected unit
    if selected_unit_id != "" and not unit_manager.has_unit_at(cube):
        _attempt_move(selected_unit_id, cube)

func _handle_right_click(cube: Vector3i) -> void:
    _deselect_unit()

func _on_cell_hovered(cube: Vector3i, cell) -> void:
    if not is_active or selected_unit_id == "":
        return
    
    var unit = unit_manager.get_unit(selected_unit_id)
    if not unit or unit.side != turn_manager.active_side:
        return
    
    # Preview path
    if not unit_manager.has_unit_at(cube):
        highlighter.show_movement_with_path(
            unit.cube,
            unit.movement,
            cube,
            unit.unit_type
        )

# ============================================================================
# UNIT SELECTION
# ============================================================================

func _select_unit(unit_id: String) -> void:
    selected_unit_id = unit_id
    cursor.select_cell(unit_manager.get_unit(unit_id).cube)
    unit_selected.emit(unit_id)
    _show_unit_ranges(unit_id)

func _deselect_unit() -> void:
    selected_unit_id = ""
    cursor.clear_selection()
    highlighter.clear_all()

func _show_unit_ranges(unit_id: String) -> void:
    var unit = unit_manager.get_unit(unit_id)
    if not unit:
        return
    
    highlighter.clear_all()
    
    # Movement range
    highlighter.show_movement_range(unit.cube, unit.movement, unit.unit_type)
    
    # Attack range
    var cell = battle_grid.get_cell(unit.cube)
    var elevation: int = cell.elevation if cell else 0
    highlighter.show_attack_range(unit.cube, unit.attack_range, elevation)

# ============================================================================
# ACTIONS
# ============================================================================

func _attempt_move(unit_id: String, target_cube: Vector3i) -> void:
    var unit = unit_manager.get_unit(unit_id)
    if not unit or unit.has_moved:
        return
    
    # Validate path
    var path = Pathfinder.find_path(
        battle_grid.grid,
        unit.cube,
        target_cube,
        unit.unit_type,
        int(unit.movement)
    )
    
    if path.is_empty():
        return
    
    var cost = Pathfinder.calculate_path_cost(battle_grid.grid, path, unit.unit_type)
    if cost > unit.movement:
        return
    
    # Execute move
    if unit_manager.move_unit(unit_id, target_cube):
        unit.has_moved = true
        _select_unit(unit_id)  # Re-select to update highlights

func _attempt_attack(attacker_id: String, defender_id: String) -> void:
    var attacker = unit_manager.get_unit(attacker_id)
    if not attacker or attacker.has_attacked:
        return
    
    if combat_engine.resolve_attack(attacker_id, defender_id):
        attacker.has_attacked = true
        highlighter.clear_all()

func end_turn() -> void:
    if not is_active:
        return
    
    _deselect_unit()
    turn_manager.end_turn()

# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_grid_loaded(grid) -> void:
    renderer.grid = grid
    renderer.queue_redraw()

func _on_unit_spawned(unit_id: String, unit, cube: Vector3i) -> void:
    renderer.queue_redraw()

func _on_unit_moved(unit_id: String, from_cube: Vector3i, to_cube: Vector3i) -> void:
    renderer.queue_redraw()

func _on_unit_defeated(unit_id: String, side: String) -> void:
    if selected_unit_id == unit_id:
        _deselect_unit()
    renderer.queue_redraw()

func _on_all_units_defeated(side: String) -> void:
    var victor = "defender" if side == "attacker" else "attacker"
    end_battle(victor)

func _on_turn_started(turn_number: int, active_side: String) -> void:
    # Reset actions for new side
    for unit in unit_manager.get_units_by_side(active_side):
        unit.reset_actions()

func _on_turn_ended(turn_number: int, active_side: String) -> void:
    _deselect_unit()

func _on_attack_resolved(attacker_id: String, defender_id: String, damage: int, hit: bool) -> void:
    action_completed.emit()

func _on_combat_unit_defeated(unit_id: String, side: String) -> void:
    pass  # Handled by unit_manager signal

# ============================================================================
# SERIALIZATION
# ============================================================================

func serialize_battle() -> Dictionary:
    return {
        "grid": battle_grid.serialize(),
        "units": unit_manager.serialize(),
        "turn": turn_manager.serialize(),
        "active": is_active
    }

func deserialize_battle(data: Dictionary) -> void:
    battle_grid.deserialize(data.get("grid", {}))
    unit_manager.deserialize(data.get("units", []))
    turn_manager.deserialize(data.get("turn", {}))
    is_active = data.get("active", false)
