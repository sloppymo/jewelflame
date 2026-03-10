## HexForge/Rendering/RangeHighlighter
## Visual feedback for movement and attack ranges
## Part of HexForge hex grid system

class_name RangeHighlighter
extends Node

const HexMath = preload("res://hexforge/core/hex_math.gd")
const HexCell = preload("res://hexforge/core/hex_cell.gd")
const HexRenderer2D = preload("res://hexforge/rendering/hex_renderer_2d.gd")
const Pathfinder = preload("res://hexforge/services/pathfinder.gd")
const LineOfSight = preload("res://hexforge/services/line_of_sight.gd")

# ============================================================================
# CONFIGURATION
# ============================================================================

## The HexRenderer2D to control
@export var renderer = null

## The HexGrid reference
@export var grid = null

## Movement range colors
@export var movement_color: Color = Color(0.0, 0.8, 0.0, 0.3)
@export var movement_path_color: Color = Color(0.0, 0.6, 1.0, 0.4)

## Attack range colors
@export var attack_color: Color = Color(0.8, 0.0, 0.0, 0.3)
@export var attack_no_los_color: Color = Color(0.8, 0.4, 0.0, 0.2)

## Danger/AI range colors
@export var danger_color: Color = Color(0.8, 0.0, 0.0, 0.2)
@export var warning_color: Color = Color(0.9, 0.6, 0.0, 0.2)

## Selection colors
@export var selection_color: Color = Color(1.0, 0.9, 0.0, 0.4)
@export var hover_color: Color = Color(1.0, 1.0, 1.0, 0.2)

# ============================================================================
# INTERNAL STATE
# ============================================================================

## Currently displayed highlights by category
var _highlights: Dictionary = {}  # category -> Dictionary[cube, Color]

## Valid categories
const CAT_MOVEMENT: String = "movement"
const CAT_ATTACK: String = "attack"
const CAT_PATH: String = "path"
const CAT_DANGER: String = "danger"
const CAT_SELECTION: String = "selection"
const CAT_HOVER: String = "hover"

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
    if renderer == null:
        renderer = _find_renderer()
    if grid == null and renderer != null:
        grid = renderer.grid

func _find_renderer():
    var parent = get_parent()
    if parent:
        for child in parent.get_children():
            if child is HexRenderer2D:
                return child
    return get_tree().root.find_child("HexRenderer2D", true, false)

# ============================================================================
# HIGHLIGHTING API
# ============================================================================

## Shows movement range for a unit
func show_movement_range(center: Vector3i, max_movement: float, unit_type: String = "infantry") -> void:
    if grid == null:
        return
    
    clear_category(CAT_MOVEMENT)
    
    var reachable = Pathfinder.find_reachable(grid, center, max_movement, unit_type)
    var highlight_dict: Dictionary = {}
    
    for cube in reachable.keys():
        # Vary color intensity by cost
        var cost: float = reachable[cube]
        var intensity: float = 1.0 - (cost / max_movement * 0.3)
        var color: Color = movement_color
        color.a = movement_color.a * intensity
        highlight_dict[cube] = color
    
    _highlights[CAT_MOVEMENT] = highlight_dict
    _apply_highlights()

## Shows attack range (with LoS check)
func show_attack_range(center: Vector3i, max_range: int, from_elevation: int = -1) -> void:
    if grid == null:
        return
    
    clear_category(CAT_ATTACK)
    
    if from_elevation < 0:
        var center_cell = grid.get_cell(center)
        from_elevation = center_cell.elevation if center_cell else 0
    
    var in_range = grid.get_cells_in_range(center, max_range)
    var highlight_dict: Dictionary = {}
    
    for cell in in_range:
        if cell.cube_coord == center:
            continue  # Don't highlight self
        
        var has_los: bool = LineOfSight.has_los(grid, center, cell.cube_coord, from_elevation)
        var color: Color = attack_color if has_los else attack_no_los_color
        highlight_dict[cell.cube_coord] = color
    
    _highlights[CAT_ATTACK] = highlight_dict
    _apply_highlights()

## Shows a path
func show_path(path: Array[Vector3i]) -> void:
    clear_category(CAT_PATH)
    
    var highlight_dict: Dictionary = {}
    for cube in path:
        highlight_dict[cube] = movement_path_color
    
    _highlights[CAT_PATH] = highlight_dict
    _apply_highlights()

## Shows danger zones (enemy attack ranges)
func show_danger_zones(enemy_positions: Array[Vector3i], enemy_range: int) -> void:
    clear_category(CAT_DANGER)
    
    var highlight_dict: Dictionary = {}
    
    for enemy_pos in enemy_positions:
        var in_range = grid.get_cells_in_range(enemy_pos, enemy_range)
        for cell in in_range:
            # Check if already highlighted (overlapping danger)
            if highlight_dict.has(cell.cube_coord):
                # Make it more intense (darker red)
                highlight_dict[cell.cube_coord] = danger_color
            else:
                highlight_dict[cell.cube_coord] = warning_color
    
    _highlights[CAT_DANGER] = highlight_dict
    _apply_highlights()

## Highlights selected unit/cell
func highlight_selection(cube: Vector3i) -> void:
    clear_category(CAT_SELECTION)
    
    _highlights[CAT_SELECTION] = {cube: selection_color}
    _apply_highlights()

## Highlights hovered cell
func highlight_hover(cube: Vector3i) -> void:
    clear_category(CAT_HOVER)
    
    _highlights[CAT_HOVER] = {cube: hover_color}
    _apply_highlights()

# ============================================================================
# CLEARING
# ============================================================================

## Clears a specific category
func clear_category(category: String) -> void:
    _highlights.erase(category)
    _apply_highlights()

## Clears all highlights
func clear_all() -> void:
    _highlights.clear()
    if renderer != null:
        renderer.clear_all_highlights()

## Clears movement highlights
func clear_movement() -> void:
    clear_category(CAT_MOVEMENT)

## Clears attack highlights
func clear_attack() -> void:
    clear_category(CAT_ATTACK)

## Clears path highlights
func clear_path() -> void:
    clear_category(CAT_PATH)

# ============================================================================
# COMBINED OPERATIONS
# ============================================================================

## Shows movement range and path to hovered cell
func show_movement_with_path(center: Vector3i, max_movement: float, hover_cube: Vector3i, unit_type: String = "infantry") -> void:
    show_movement_range(center, max_movement, unit_type)
    
    # Find path to hover
    if hover_cube != center and hover_cube != Vector3i.MAX:
        var path = Pathfinder.find_path(grid, center, hover_cube, unit_type, int(max_movement))
        if not path.is_empty():
            show_path(path)

## Shows combined movement and attack range (for units that can move then attack)
func show_combined_ranges(unit_pos: Vector3i, move_range: float, attack_range: int, unit_type: String = "infantry") -> void:
    show_movement_range(unit_pos, move_range, unit_type)
    
    # For each reachable position, show attack range
    var reachable = Pathfinder.find_reachable(grid, unit_pos, move_range, unit_type)
    var attack_dict: Dictionary = {}
    
    for cube in reachable.keys():
        var cell = grid.get_cell(cube)
        var from_elev: int = cell.elevation if cell else 0
        
        var in_attack_range = grid.get_cells_in_range(cube, attack_range)
        for attack_cell in in_attack_range:
            if attack_cell.cube_coord == unit_pos:
                continue
            
            var has_los: bool = LineOfSight.has_los(grid, cube, attack_cell.cube_coord, from_elev)
            var color: Color = attack_color if has_los else attack_no_los_color
            
            # Blend with existing if already set
            if attack_dict.has(attack_cell.cube_coord):
                color = color.blend(attack_dict[attack_cell.cube_coord])
            
            attack_dict[attack_cell.cube_coord] = color
    
    _highlights[CAT_ATTACK] = attack_dict
    _apply_highlights()

# ============================================================================
# INTERNAL
# ============================================================================

## Applies all current highlights to the renderer
func _apply_highlights() -> void:
    if renderer == null:
        return
    
    # Clear renderer
    renderer.clear_all_highlights()
    
    # Merge all highlights (later categories override earlier ones)
    var merged: Dictionary = {}
    
    # Priority order: danger -> movement -> attack -> path -> selection -> hover
    var priority_order: Array[String] = [
        CAT_DANGER,
        CAT_MOVEMENT,
        CAT_ATTACK,
        CAT_PATH,
        CAT_SELECTION,
        CAT_HOVER
    ]
    
    for category in priority_order:
        if _highlights.has(category):
            var cat_highlights: Dictionary = _highlights[category]
            for cube in cat_highlights.keys():
                merged[cube] = cat_highlights[cube]
    
    # Apply to renderer
    for cube in merged.keys():
        renderer.highlight_cell(cube, merged[cube])

# ============================================================================
# UTILITY
# ============================================================================

## Returns true if a cell is highlighted in any category
func is_highlighted(cube: Vector3i) -> bool:
    for category in _highlights.values():
        if category.has(cube):
            return true
    return false

## Returns the highlight color for a cell (or null)
func get_highlight_color(cube: Vector3i) -> Color:
    for category in _highlights.values():
        if category.has(cube):
            return category[cube]
    return Color.TRANSPARENT

## Returns all highlighted cells
func get_all_highlighted() -> Array[Vector3i]:
    var result: Array[Vector3i] = []
    var seen: Dictionary = {}
    
    for category in _highlights.values():
        for cube in category.keys():
            if not seen.has(cube):
                seen[cube] = true
                result.append(cube)
    
    return result
