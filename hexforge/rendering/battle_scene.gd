## HexForge/Rendering/BattleScene
## Tactical battle scene integration for Micro-Gemfire
## Manages hex grid, units, turns, and battle resolution
## Part of HexForge hex grid system

class_name BattleScene
extends Node2D

# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when battle starts
signal battle_started(grid_size: Vector2i, attacker_units: int, defender_units: int)

## Emitted when a unit is selected
signal unit_selected(unit_id: String, cube: Vector3i)

## Emitted when a unit moves
signal unit_moved(unit_id: String, from_cube: Vector3i, to_cube: Vector3i)

## Emitted when a unit attacks
signal unit_attacked(attacker_id: String, defender_id: String, damage: int)

## Emitted when a unit is defeated
signal unit_defeated(unit_id: String, side: String)

## Emitted when turn changes
signal turn_changed(turn_number: int, active_side: String)

## Emitted when battle ends
signal battle_ended(victor: String, attacker_casualties: int, defender_casualties: int)

# ============================================================================
# CONFIGURATION
# ============================================================================

## Grid configuration
@export var grid_width: int = 11
@export var grid_height: int = 11
@export var hex_size: float = 32.0

## Scene references
@export var renderer: HexRenderer2D = null
@export var cursor: HexCursor = null
@export var highlighter: RangeHighlighter = null

# ============================================================================
# BATTLE STATE
# ============================================================================

## The hex grid
var grid: HexGrid = null

## Unit management
var units: Dictionary = {}  # unit_id -> UnitData
var unit_positions: Dictionary = {}  # cube -> unit_id

## Turn management
var current_turn: int = 1
var active_side: String = "attacker"  # "attacker" or "defender"
var turn_order: Array[String] = []

## Battle result
var battle_result: Dictionary = {
    "victor": "",
    "attacker_casualties": 0,
    "defender_casualties": 0,
    "turns": 0
}

## Unit data structure
class UnitData:
    var id: String
    var side: String  # "attacker" or "defender"
    var unit_type: String  # "infantry", "cavalry", "archer", etc.
    var max_hp: int = 10
    var current_hp: int = 10
    var attack: int = 3
    var defense: int = 2
    var movement: float = 5.0
    var attack_range: int = 1
    var has_moved: bool = false
    var has_attacked: bool = false
    var cube: Vector3i = Vector3i.ZERO
    
    func _init(p_id: String, p_side: String, p_type: String) -> void:
        id = p_id
        side = p_side
        unit_type = p_type

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
    _setup_components()
    _connect_signals()

func _setup_components() -> void:
    # Create grid
    grid = HexGrid.new()
    
    # Create renderer if not set
    if renderer == null:
        renderer = HexRenderer2D.new()
        renderer.grid = grid
        renderer.hex_size = hex_size
        add_child(renderer)
    
    # Create cursor if not set
    if cursor == null:
        cursor = HexCursor.new()
        cursor.grid = grid
        cursor.renderer = renderer
        add_child(cursor)
    
    # Create highlighter if not set
    if highlighter == null:
        highlighter = RangeHighlighter.new()
        highlighter.renderer = renderer
        highlighter.grid = grid
        add_child(highlighter)

func _connect_signals() -> void:
    if cursor:
        cursor.cell_clicked.connect(_on_cell_clicked)
        cursor.cell_hovered.connect(_on_cell_hovered)

# ============================================================================
# BATTLE SETUP
# ============================================================================

## Initializes a new battle
## @param map_data: Optional HexGrid or Dictionary with terrain data
## @param attacker_units: Array of unit definitions for attacker
## @param defender_units: Array of unit definitions for defender
func start_battle(map_data: Variant = null, attacker_units: Array = [], defender_units: Array = []) -> void:
    _clear_battle()
    
    # Setup grid
    if map_data is HexGrid:
        grid = map_data
    elif map_data is Dictionary:
        _generate_grid_from_data(map_data)
    else:
        _generate_default_grid()
    
    # Update renderer reference
    renderer.grid = grid
    cursor.grid = grid
    highlighter.grid = grid
    
    # Spawn units
    _spawn_units(attacker_units, "attacker")
    _spawn_units(defender_units, "defender")
    
    # Initialize turn order
    current_turn = 1
    active_side = "attacker"
    
    battle_started.emit(Vector2i(grid_width, grid_height), attacker_units.size(), defender_units.size())
    turn_changed.emit(current_turn, active_side)

## Generates a default grid
func _generate_default_grid() -> void:
    grid.clear()
    
    # Create a rectangular grid in axial coordinates
    for q in range(-grid_width / 2, grid_width / 2 + 1):
        for r in range(-grid_height / 2, grid_height / 2 + 1):
            var cube := HexMath.axial_to_cube(Vector2i(q, r))
            
            # Simple terrain generation (can be replaced with proper map data)
            var terrain: String = "plains"
            var elevation: int = 0
            var blocking: bool = false
            
            # Add some variety
            var noise: float = randf()
            if noise > 0.85:
                terrain = "forest"
                elevation = 0
            elif noise > 0.75:
                terrain = "mountain"
                elevation = 2
                blocking = true
            elif noise > 0.70:
                terrain = "water"
                blocking = true
            
            grid.create_cell_cube(cube, terrain, elevation, blocking)

## Generates grid from data dictionary
func _generate_grid_from_data(data: Dictionary) -> void:
    grid.clear()
    
    if data.has("cells"):
        for cell_data in data["cells"]:
            var cell := HexCell.from_dict(cell_data)
            if cell:
                grid.set_cell(cell)

## Spawns units on the grid
func _spawn_units(unit_defs: Array, side: String) -> void:
    var start_q: int = -grid_width / 2 + 1 if side == "attacker" else grid_width / 2 - 1
    var r_offset: int = -grid_height / 2 + 1
    
    for i in range(unit_defs.size()):
        var def: Dictionary = unit_defs[i]
        var unit_id: String = "%s_%d" % [side, i]
        
        # Calculate spawn position
        var r: int = r_offset + (i * 2)
        var cube := HexMath.axial_to_cube(Vector2i(start_q, r))
        
        # Find valid spawn position
        while not _is_valid_spawn(cube):
            r += 1
            cube = HexMath.axial_to_cube(Vector2i(start_q, r))
        
        # Create unit
        var unit := UnitData.new(unit_id, side, def.get("type", "infantry"))
        unit.max_hp = def.get("hp", 10)
        unit.current_hp = unit.max_hp
        unit.attack = def.get("attack", 3)
        unit.defense = def.get("defense", 2)
        unit.movement = def.get("movement", 5.0)
        unit.attack_range = def.get("range", 1)
        unit.cube = cube
        
        units[unit_id] = unit
        unit_positions[cube] = unit_id
        
        # Mark cell as occupied
        var cell := grid.get_cell(cube)
        if cell:
            cell.occupant_id = unit_id

func _is_valid_spawn(cube: Vector3i) -> bool:
    if not grid.has_cell(cube):
        return false
    
    var cell := grid.get_cell(cube)
    if cell.blocking:
        return false
    
    if unit_positions.has(cube):
        return false
    
    return true

## Clears the current battle state
func _clear_battle() -> void:
    units.clear()
    unit_positions.clear()
    current_turn = 1
    active_side = "attacker"
    battle_result = {
        "victor": "",
        "attacker_casualties": 0,
        "defender_casualties": 0,
        "turns": 0
    }

# ============================================================================
# INPUT HANDLING
# ============================================================================

func _on_cell_clicked(cube: Vector3i, cell: HexCell, button: int) -> void:
    if button == MOUSE_BUTTON_LEFT:
        _handle_left_click(cube)
    elif button == MOUSE_BUTTON_RIGHT:
        _handle_right_click(cube)

func _on_cell_hovered(cube: Vector3i, cell: HexCell) -> void:
    _update_hover_preview(cube)

func _handle_left_click(cube: Vector3i) -> void:
    var selected_unit_id: String = cursor.get_selected_cell()
    
    # Check if clicking on a unit
    if unit_positions.has(cube):
        var clicked_unit_id: String = unit_positions[cube]
        var clicked_unit: UnitData = units[clicked_unit_id]
        
        # Select own unit
        if clicked_unit.side == active_side:
            cursor.select_cell(cube)
            unit_selected.emit(clicked_unit_id, cube)
            _show_unit_ranges(clicked_unit)
            return
        
        # Attack enemy unit
        if selected_unit_id != "":
            var selected_unit: UnitData = units.get(selected_unit_id)
            if selected_unit and selected_unit.side == active_side:
                _attempt_attack(selected_unit, clicked_unit)
                return
    
    # Move selected unit
    if selected_unit_id != "" and not unit_positions.has(cube):
        var selected_unit: UnitData = units.get(selected_unit_id)
        if selected_unit and selected_unit.side == active_side:
            _attempt_move(selected_unit, cube)

func _handle_right_click(cube: Vector3i) -> void:
    # Cancel selection
    cursor.clear_selection()
    highlighter.clear_all()

func _update_hover_preview(cube: Vector3i) -> void:
    var selected_unit_id: String = cursor.get_selected_cell()
    if selected_unit_id == "":
        return
    
    var selected_unit: UnitData = units.get(selected_unit_id)
    if selected_unit == null or selected_unit.side != active_side:
        return
    
    # Show path to hovered cell
    if not unit_positions.has(cube):
        highlighter.show_movement_with_path(
            selected_unit.cube,
            selected_unit.movement,
            cube,
            selected_unit.unit_type
        )

# ============================================================================
# UNIT ACTIONS
# ============================================================================

func _show_unit_ranges(unit: UnitData) -> void:
    highlighter.clear_all()
    
    # Show movement range
    highlighter.show_movement_range(unit.cube, unit.movement, unit.unit_type)
    
    # Show attack range
    var cell := grid.get_cell(unit.cube)
    var elevation: int = cell.elevation if cell else 0
    highlighter.show_attack_range(unit.cube, unit.attack_range, elevation)

func _attempt_move(unit: UnitData, target_cube: Vector3i) -> void:
    if unit.has_moved:
        return
    
    # Check if valid move
    var path := Pathfinder.find_path(grid, unit.cube, target_cube, unit.unit_type, int(unit.movement))
    if path.is_empty():
        return
    
    var cost: float = Pathfinder.calculate_path_cost(grid, path, unit.unit_type)
    if cost > unit.movement:
        return
    
    # Execute move
    var from_cube: Vector3i = unit.cube
    
    # Clear old position
    unit_positions.erase(from_cube)
    var old_cell := grid.get_cell(from_cube)
    if old_cell:
        old_cell.occupant_id = ""
    
    # Set new position
    unit.cube = target_cube
    unit_positions[target_cube] = unit.id
    var new_cell := grid.get_cell(target_cube)
    if new_cell:
        new_cell.occupant_id = unit.id
    
    unit.has_moved = true
    
    unit_moved.emit(unit.id, from_cube, target_cube)
    
    # Update selection and highlights
    cursor.select_cell(target_cube)
    _show_unit_ranges(unit)

func _attempt_attack(attacker: UnitData, defender: UnitData) -> void:
    if attacker.has_attacked:
        return
    
    # Check range
    var distance: int = HexMath.distance(attacker.cube, defender.cube)
    if distance > attacker.attack_range:
        return
    
    # Check LoS
    var attacker_cell := grid.get_cell(attacker.cube)
    var from_elevation: int = attacker_cell.elevation if attacker_cell else 0
    if not LineOfSight.has_los(grid, attacker.cube, defender.cube, from_elevation):
        return
    
    # Calculate damage
    var damage: int = _calculate_damage(attacker, defender)
    defender.current_hp -= damage
    
    attacker.has_attacked = true
    
    unit_attacked.emit(attacker.id, defender.id, damage)
    
    # Check defeat
    if defender.current_hp <= 0:
        _defeat_unit(defender)
    
    # Clear highlights
    highlighter.clear_all()

func _calculate_damage(attacker: UnitData, defender: UnitData) -> int:
    var base_damage: int = attacker.attack
    
    # Defense modifiers
    var defense: int = defender.defense
    var defender_cell := grid.get_cell(defender.cube)
    if defender_cell:
        defense += defender_cell.get_defense_bonus()
    
    # Cover modifier
    var cover := LineOfSight.check_cover(grid, defender.cube, attacker.cube)
    if cover.has_cover:
        if cover.cover_type == "heavy":
            defense += 2
        else:
            defense += 1
    
    var damage: int = max(1, base_damage - defense)
    return damage

func _defeat_unit(unit: UnitData) -> void:
    # Remove from grid
    unit_positions.erase(unit.cube)
    var cell := grid.get_cell(unit.cube)
    if cell:
        cell.occupant_id = ""
    
    # Track casualties
    if unit.side == "attacker":
        battle_result.attacker_casualties += 1
    else:
        battle_result.defender_casualties += 1
    
    unit_defeated.emit(unit.id, unit.side)
    
    # Check battle end
    _check_battle_end()

# ============================================================================
# TURN MANAGEMENT
# ============================================================================

func end_turn() -> void:
    # Reset unit actions for current side
    for unit in units.values():
        if unit.side == active_side:
            unit.has_moved = false
            unit.has_attacked = false
    
    # Switch sides
    if active_side == "attacker":
        active_side = "defender"
    else:
        active_side = "attacker"
        current_turn += 1
    
    turn_changed.emit(current_turn, active_side)
    
    # Clear UI
    cursor.clear_selection()
    highlighter.clear_all()
    
    # Check battle end (retreat condition)
    _check_battle_end()

func _check_battle_end() -> void:
    var attacker_count: int = 0
    var defender_count: int = 0
    
    for unit in units.values():
        if unit.current_hp > 0:
            if unit.side == "attacker":
                attacker_count += 1
            else:
                defender_count += 1
    
    if attacker_count == 0:
        _end_battle("defender")
    elif defender_count == 0:
        _end_battle("attacker")

func _end_battle(victor: String) -> void:
    battle_result.victor = victor
    battle_result.turns = current_turn
    
    battle_ended.emit(victor, battle_result.attacker_casualties, battle_result.defender_casualties)

# ============================================================================
# SERIALIZATION
# ============================================================================

## Returns battle result for strategic layer
func get_battle_result() -> Dictionary:
    return battle_result.duplicate()

## Returns surviving units for strategic layer
func get_surviving_units(side: String = "") -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    
    for unit in units.values():
        if unit.current_hp > 0:
            if side == "" or unit.side == side:
                result.append({
                    "id": unit.id,
                    "side": unit.side,
                    "type": unit.unit_type,
                    "hp": unit.current_hp,
                    "max_hp": unit.max_hp
                })
    
    return result
