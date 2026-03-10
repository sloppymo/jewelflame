## HexForge/Services/LineOfSight
## Line of sight calculation using Bresenham-style hex line algorithm
## Checks elevation differences and blocking terrain
## Part of HexForge hex grid system
## Phase: 4

class_name LineOfSight
extends RefCounted

const HexGrid = preload("res://hexforge/core/hex_grid.gd")
const HexCell = preload("res://hexforge/core/hex_cell.gd")
const HexMath = preload("res://hexforge/core/hex_math.gd")

# ============================================================================
# CONSTANTS
# ============================================================================

## Maximum LoS distance (to prevent infinite checks)
const MAX_LOS_DISTANCE: int = 50

## Elevation difference required to block LoS
## Cell blocks if: elevation > from_elevation + ELEVATION_BLOCK_THRESHOLD
const ELEVATION_BLOCK_THRESHOLD: int = 1

# ============================================================================
# LINE OF SIGHT CHECKS
# ============================================================================

## Checks if there is line of sight between two cells
##
## @param grid: The HexGrid to check
## @param from: Starting cube coordinates
## @param to: Target cube coordinates
## @param from_elevation: Elevation of the viewer (defaults to cell's elevation)
## @return true if LoS is clear
static func has_los(
    grid,
    from: Vector3i,
    to: Vector3i,
    from_elevation: int = -1
) -> bool:
    
    # Validate inputs
    if grid == null:
        push_error("LineOfSight.has_los: Grid is null")
        return false
    
    if not grid.has_cell(from):
        return false
    
    # Trivial case: checking self
    if from == to:
        return true
    
    # Get starting elevation if not provided
    if from_elevation < 0:
        var from_cell = grid.get_cell(from)
        if from_cell == null:
            return false
        from_elevation = from_cell.elevation
    
    # Check max distance
    var distance: int = HexMath.distance(from, to)
    if distance > MAX_LOS_DISTANCE:
        return false
    
    # Get the line of cells between from and to
    var line: Array[Vector3i] = HexMath.line(from, to)
    
    # Check each cell along the line (excluding start, including end)
    # We check the end cell to see if it's visible, but don't check if it blocks
    for i in range(1, line.size()):
        var cube: Vector3i = line[i]
        
        # If cell doesn't exist in grid, it blocks LoS
        if not grid.has_cell(cube):
            return false
        
        var cell = grid.get_cell(cube)
        
        # Check if this cell blocks LoS
        # The target cell (last in line) is visible if we can see it
        var is_target: bool = (i == line.size() - 1)
        
        if _cell_blocks_los(cell, from_elevation, is_target):
            return false
    
    return true

## Checks if a specific cell blocks line of sight
##
## @param cell: The HexCell to check
## @param from_elevation: Elevation of the viewer
## @param is_target: If true, this is the target cell (different rules apply)
## @return true if this cell blocks LoS
static func _cell_blocks_los(cell, from_elevation: int, is_target: bool) -> bool:
    if cell == null:
        return true
    
    # Blocking terrain always blocks (walls, etc.)
    if cell.blocking:
        return true
    
    # Elevation check: blocks if cell is significantly higher than viewer
    # For the target cell, we check if WE can see IT (so it doesn't block itself)
    # For intermediate cells, they block if they obscure the view
    if cell.elevation > from_elevation + ELEVATION_BLOCK_THRESHOLD:
        return true
    
    return false

## Checks if a ranged attack is valid (has LoS and is within range)
##
## @param grid: The HexGrid
## @param from: Attacker position
## @param to: Target position
## @param max_range: Maximum attack range
## @param from_elevation: Attacker elevation (-1 = use cell elevation)
## @return Dictionary with "valid" (bool) and "reason" (String)
static func is_valid_shot(
    grid,
    from: Vector3i,
    to: Vector3i,
    max_range: int,
    from_elevation: int = -1
) -> Dictionary:
    
    # Check range first (cheaper than LoS)
    var distance: int = HexMath.distance(from, to)
    if distance > max_range:
        return {
            "valid": false,
            "reason": "Target out of range (%d > %d)" % [distance, max_range]
        }
    
    # Check LoS
    if not has_los(grid, from, to, from_elevation):
        return {
            "valid": false,
            "reason": "No line of sight"
        }
    
    return {
        "valid": true,
        "reason": "Valid shot"
    }

# ============================================================================
# VISIBLE CELLS QUERIES
# ============================================================================

## Returns all cells visible from a given position within a range
##
## @param grid: The HexGrid
## @param from: Viewer position
## @param max_range: Maximum distance to check
## @param from_elevation: Viewer elevation (-1 = use cell elevation)
## @return Array[HexCell]: All visible cells
static func get_visible_cells(
    grid,
    from: Vector3i,
    max_range: int,
    from_elevation: int = -1
) -> Array[HexCell]:
    
    if not grid.has_cell(from):
        return []
    
    # Get viewer elevation
    if from_elevation < 0:
        var from_cell = grid.get_cell(from)
        from_elevation = from_cell.elevation if from_cell else 0
    
    var visible: Array[HexCell] = []
    var candidates = grid.get_cells_in_range(from, max_range)
    
    for cell in candidates:
        if has_los(grid, from, cell.cube_coord, from_elevation):
            visible.append(cell)
    
    return visible

## Returns all cube coordinates visible from a given position
static func get_visible_cubes(
    grid,
    from: Vector3i,
    max_range: int,
    from_elevation: int = -1
) -> Array[Vector3i]:
    
    var cells = get_visible_cells(grid, from, max_range, from_elevation)
    var result: Array[Vector3i] = []
    
    for cell in cells:
        result.append(cell.cube_coord)
    
    return result

## Returns visible cells as a Dictionary for fast lookup
## Key: cube (Vector3i), Value: true
static func get_visible_cells_set(
    grid,
    from: Vector3i,
    max_range: int,
    from_elevation: int = -1
) -> Dictionary:
    
    var cells = get_visible_cells(grid, from, max_range, from_elevation)
    var result: Dictionary = {}
    
    for cell in cells:
        result[cell.cube_coord] = true
    
    return result

# ============================================================================
# COVER AND CONCEALMENT
# ============================================================================

## Checks if a cell provides cover against an attack from a direction
##
## @param grid: The HexGrid
## @param target: Position of the target
## @param attacker: Position of the attacker
## @return Dictionary with "has_cover" (bool) and "cover_type" (String)
static func check_cover(
    grid,
    target: Vector3i,
    attacker: Vector3i
) -> Dictionary:
    
    if not grid.has_cell(target):
        return {"has_cover": false, "cover_type": "none"}
    
    var target_cell = grid.get_cell(target)
    
    # Check terrain-based cover
    match target_cell.terrain_type:
        "forest":
            return {"has_cover": true, "cover_type": "light"}
        "mountain":
            if target_cell.elevation >= 1:
                return {"has_cover": true, "cover_type": "heavy"}
        "urban", "ruins":
            return {"has_cover": true, "cover_type": "heavy"}
    
    # Check elevation advantage
    if grid.has_cell(attacker):
        var attacker_cell = grid.get_cell(attacker)
        if target_cell.elevation > attacker_cell.elevation:
            return {"has_cover": true, "cover_type": "elevation"}
    
    return {"has_cover": false, "cover_type": "none"}

## Returns true if the target has partial cover from the attacker
static func has_partial_cover(grid, target: Vector3i, attacker: Vector3i) -> bool:
    var cover = check_cover(grid, target, attacker)
    return cover.has_cover and cover.cover_type != "none"

## Returns true if the target has heavy cover from the attacker
static func has_heavy_cover(grid, target: Vector3i, attacker: Vector3i) -> bool:
    var cover = check_cover(grid, target, attacker)
    return cover.cover_type == "heavy"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

## Returns the line of cells between two points (for visualization)
## Includes LoS blocking information for each cell
##
## @return Array of dictionaries: {cube, blocks_los, reason}
static func trace_los(
    grid,
    from: Vector3i,
    to: Vector3i,
    from_elevation: int = -1
) -> Array[Dictionary]:
    
    var result: Array[Dictionary] = []
    
    if from_elevation < 0 and grid.has_cell(from):
        var from_cell = grid.get_cell(from)
        from_elevation = from_cell.elevation if from_cell else 0
    
    var line: Array[Vector3i] = HexMath.line(from, to)
    
    for i in range(line.size()):
        var cube: Vector3i = line[i]
        var entry: Dictionary = {"cube": cube, "in_grid": false, "blocks_los": false, "reason": ""}
        
        if not grid.has_cell(cube):
            entry.reason = "Cell not in grid"
            result.append(entry)
            continue
        
        entry.in_grid = true
        var cell = grid.get_cell(cube)
        
        if i == 0:
            entry.reason = "Start position"
        elif i == line.size() - 1:
            entry.reason = "Target position"
            if _cell_blocks_los(cell, from_elevation, true):
                entry.blocks_los = true
                entry.reason = "Target not visible (elevation/terrain)"
        else:
            if _cell_blocks_los(cell, from_elevation, false):
                entry.blocks_los = true
                if cell.blocking:
                    entry.reason = "Blocking terrain"
                else:
                    entry.reason = "Elevation blocks view"
            else:
                entry.reason = "Clear"
        
        result.append(entry)
    
    return result

## Returns the first blocking cell along a line (or null if clear)
static func find_first_blocker(
    grid,
    from: Vector3i,
    to: Vector3i,
    from_elevation: int = -1
):
    
    if from_elevation < 0 and grid.has_cell(from):
        var from_cell = grid.get_cell(from)
        from_elevation = from_cell.elevation if from_cell else 0
    
    var line: Array[Vector3i] = HexMath.line(from, to)
    
    for i in range(1, line.size() - 1):  # Skip start, don't check target
        var cube: Vector3i = line[i]
        
        if not grid.has_cell(cube):
            return null  # Can't determine blocker
        
        var cell = grid.get_cell(cube)
        if _cell_blocks_los(cell, from_elevation, false):
            return cell
    
    return null

# ============================================================================
# TEST USAGE EXAMPLE
# ============================================================================
"""
# Test script for LineOfSight:

func test_line_of_sight():
    var grid = HexGrid.new()
    
    # Create a flat plain
    for q in range(-2, 3):
        for r in range(-2, 3):
            var cube = HexMath.axial_to_cube(Vector2i(q, r))
            grid.create_cell_cube(cube, "plains")
    
    # Add a wall blocking the center
    grid.create_cell_cube(Vector3i(0, 0, 0), "mountain", 2, true)
    
    # Test basic LoS
    assert(LineOfSight.has_los(grid, Vector3i(-2, 1, 1), Vector3i(-1, 1, 0)), "Adjacent should have LoS")
    assert(not LineOfSight.has_los(grid, Vector3i(-1, 0, 1), Vector3i(1, 0, -1)), "Wall should block LoS")
    
    # Test elevation blocking
    var elevated_grid = HexGrid.new()
    elevated_grid.create_cell_cube(Vector3i(0, 0, 0), "plains", 0)  # Viewer
    elevated_grid.create_cell_cube(Vector3i(1, -1, 0), "plains", 3)  # High wall
    elevated_grid.create_cell_cube(Vector3i(2, -2, 0), "plains", 0)  # Target behind wall
    
    assert(not LineOfSight.has_los(elevated_grid, Vector3i(0, 0, 0), Vector3i(2, -2, 0)), 
           "High elevation should block LoS")
    
    # Test valid shot
    var shot = LineOfSight.is_valid_shot(grid, Vector3i(-2, 1, 1), Vector3i(-1, 1, 0), 5)
    assert(shot.valid, "Valid shot should be valid")
    
    shot = LineOfSight.is_valid_shot(grid, Vector3i(-1, 0, 1), Vector3i(1, 0, -1), 5)
    assert(not shot.valid, "Shot through wall should be invalid")
    
    # Test visible cells
    var visible = LineOfSight.get_visible_cells(grid, Vector3i(-2, 0, 2), 3)
    assert(visible.size() > 0, "Should see some cells")
    assert(visible.size() < grid.get_cell_count(), "Should not see through wall")
    
    # Test cover
    var cover_grid = HexGrid.new()
    cover_grid.create_cell_cube(Vector3i(0, 0, 0), "plains")
    cover_grid.create_cell_cube(Vector3i(1, -1, 0), "forest")
    
    var cover = LineOfSight.check_cover(cover_grid, Vector3i(1, -1, 0), Vector3i(0, 0, 0))
    assert(cover.has_cover, "Forest should provide cover")
    
    print("All LineOfSight tests passed!")
"""
