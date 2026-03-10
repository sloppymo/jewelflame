## HexForge/Core/HexGrid
## ADDED: Spatial hashing for large grids, optimized range queries
## Uses Dictionary with Vector3i (cube) keys for O(1) lookup
## Part of HexForge hex grid system
## Phase: 3

class_name HexGrid
extends Resource

const HexCell = preload("res://hexforge/core/hex_cell.gd")
const HexMath = preload("res://hexforge/core/hex_math.gd")

# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when a cell is added or modified
signal cell_changed(cube_coord: Vector3i, cell)

## Emitted when a cell is removed
signal cell_removed(cube_coord: Vector3i)

## Emitted when the grid is cleared
signal grid_cleared()

# ============================================================================
# EXPORTED PROPERTIES
# ============================================================================

## Dictionary of cells: Vector3i (cube) -> cell
## Using cube coordinates as keys for consistent hashing
@export var cells: Dictionary = {}

## Grid bounds in axial coordinates (min_q, min_r, max_q, max_r)
## Updated automatically as cells are added/removed
@export var bounds: Rect2i = Rect2i()

## Grid version for save compatibility
const VERSION: String = "1.0.0"

# ============================================================================
# SPATIAL HASHING (NEW)
# ============================================================================

## Spatial hash for efficient range queries on large grids
## Key: "bucket_x,bucket_y" -> Array[Vector3i] (cube coordinates)
var _spatial_hash: Dictionary = {}

## Size of each spatial bucket (in cube coordinates)
const SPATIAL_BUCKET_SIZE: int = 10

## Enable spatial hashing for large grids (>100 cells)
var spatial_hashing_enabled: bool = true

## Threshold for enabling spatial hashing
const SPATIAL_HASH_THRESHOLD: int = 100

# ============================================================================
# CONSTANTS
# ============================================================================

const DEFAULT_HEX_SIZE: float = 32.0

# ============================================================================
# CELL MANAGEMENT
# ============================================================================

## Adds or updates a cell in the grid
## Returns the previous cell at this position (null if none)
func set_cell(cell):
    if cell == null:
        push_error("HexGrid.set_cell: Cannot add null cell")
        return null
    
    var cube: Vector3i = cell.cube_coord
    var previous = cells.get(cube)
    
    # Remove from spatial hash if updating
    if previous != null and spatial_hashing_enabled:
        _remove_from_spatial_hash(cube)
    
    cells[cube] = cell
    _update_bounds_for_cell(cell)
    
    # Add to spatial hash
    if spatial_hashing_enabled:
        _add_to_spatial_hash(cube)
    
    cell_changed.emit(cube, cell)
    return previous

## Creates and adds a cell at the specified axial coordinates
## Convenience method for map generation
func create_cell(axial: Vector2i, terrain: String = "plains", elevation: int = 0, blocking: bool = false):
    var cell = HexCell.create_axial(axial, terrain, elevation, blocking)
    set_cell(cell)
    return cell

## Creates and adds a cell at the specified cube coordinates
func create_cell_cube(cube: Vector3i, terrain: String = "plains", elevation: int = 0, blocking: bool = false):
    var cell = HexCell.create_cube(cube, terrain, elevation, blocking)
    set_cell(cell)
    return cell

## Retrieves a cell at the specified cube coordinates
## Returns null if no cell exists at this position
func get_cell(cube: Vector3i):
    return cells.get(cube)

## Retrieves a cell at the specified axial coordinates
func get_cell_axial(axial: Vector2i):
    var cube := HexMath.axial_to_cube(axial)
    return get_cell(cube)

## Removes a cell from the grid
## Returns the removed cell (null if none existed)
func remove_cell(cube: Vector3i) -> HexCell:
    if not cells.has(cube):
        return null
    
    var cell: HexCell = cells[cube]
    cells.erase(cube)
    
    # Remove from spatial hash
    if spatial_hashing_enabled:
        _remove_from_spatial_hash(cube)
    
    # Recalculate bounds if we removed a boundary cell
    _recalculate_bounds()
    
    cell_removed.emit(cube)
    return cell

## Returns true if a cell exists at the specified coordinates
func has_cell(cube: Vector3i) -> bool:
    return cells.has(cube)

## Returns true if a cell exists at the specified axial coordinates
func has_cell_axial(axial: Vector2i) -> bool:
    return has_cell(HexMath.axial_to_cube(axial))

## Returns the number of cells in the grid
func get_cell_count() -> int:
    return cells.size()

## Clears all cells from the grid
func clear() -> void:
    cells.clear()
    _spatial_hash.clear()
    bounds = Rect2i()
    grid_cleared.emit()

# ============================================================================
# SPATIAL HASHING (NEW)
# ============================================================================

## Returns the bucket key for a cube coordinate
func _get_bucket_key(cube: Vector3i) -> String:
    var bucket_x: int = floor(float(cube.x) / SPATIAL_BUCKET_SIZE)
    var bucket_y: int = floor(float(cube.z) / SPATIAL_BUCKET_SIZE)
    return "%d,%d" % [bucket_x, bucket_y]

## Adds a cube to the spatial hash
func _add_to_spatial_hash(cube: Vector3i) -> void:
    var key: String = _get_bucket_key(cube)
    if not _spatial_hash.has(key):
        _spatial_hash[key] = []
    _spatial_hash[key].append(cube)

## Removes a cube from the spatial hash
func _remove_from_spatial_hash(cube: Vector3i) -> void:
    var key: String = _get_bucket_key(cube)
    if _spatial_hash.has(key):
        var bucket: Array = _spatial_hash[key]
        bucket.erase(cube)
        if bucket.is_empty():
            _spatial_hash.erase(key)

## Rebuilds the entire spatial hash
func _rebuild_spatial_hash() -> void:
    _spatial_hash.clear()
    for cube in cells.keys():
        _add_to_spatial_hash(cube)

## Returns all cells in buckets that intersect the given range
## Much faster than checking all cells for large grids
func _get_cells_in_spatial_range(center: Vector3i, radius: int) -> Array:
    var result: Array = []
    var checked: Dictionary = {}
    
    # Calculate bucket range
    var min_bucket_x: int = floor(float(center.x - radius) / SPATIAL_BUCKET_SIZE)
    var max_bucket_x: int = floor(float(center.x + radius) / SPATIAL_BUCKET_SIZE)
    var min_bucket_y: int = floor(float(center.z - radius) / SPATIAL_BUCKET_SIZE)
    var max_bucket_y: int = floor(float(center.z + radius) / SPATIAL_BUCKET_SIZE)
    
    # Check all buckets in range
    for bx in range(min_bucket_x, max_bucket_x + 1):
        for by in range(min_bucket_y, max_bucket_y + 1):
            var key: String = "%d,%d" % [bx, by]
            if _spatial_hash.has(key):
                for cube in _spatial_hash[key]:
                    if not checked.has(cube):
                        checked[cube] = true
                        if HexMath.distance(center, cube) <= radius:
                            var cell = get_cell(cube)
                            if cell != null:
                                result.append(cell)
    
    return result

## Enables spatial hashing and rebuilds if needed
func enable_spatial_hashing() -> void:
    spatial_hashing_enabled = true
    if cells.size() > 0:
        _rebuild_spatial_hash()

## Disables spatial hashing
func disable_spatial_hashing() -> void:
    spatial_hashing_enabled = false
    _spatial_hash.clear()

# ============================================================================
# NEIGHBOR QUERIES
# ============================================================================

## Returns all 6 neighbors of a cell that exist in the grid
## Returns empty array if center cell doesn't exist
func get_neighbors(cube: Vector3i) -> Array:
    var result: Array = []
    
    if not has_cell(cube):
        return result
    
    var neighbor_cubes := HexMath.neighbors(cube)
    for neighbor_cube in neighbor_cubes:
        var cell = get_cell(neighbor_cube)
        if cell != null:
            result.append(cell)
    
    return result

## Returns neighbor cells as cube coordinates (includes non-existent neighbors)
func get_neighbor_cubes(cube: Vector3i) -> Array[Vector3i]:
    return HexMath.neighbors(cube)

## Returns only the passable neighbors for a given unit type
func get_passable_neighbors(cube: Vector3i, unit_type: String = "infantry") -> Array:
    var result: Array = []
    var center_cell = get_cell(cube)
    var from_elevation: int = center_cell.elevation if center_cell else 0
    
    for neighbor in get_neighbors(cube):
        if neighbor.is_passable_from(unit_type, from_elevation):
            result.append(neighbor)
    
    return result

# ============================================================================
# RANGE QUERIES (OPTIMIZED)
# ============================================================================

## Returns all cells within a given radius (inclusive)
## Uses spatial hashing for large grids
func get_cells_in_range(center: Vector3i, radius: int) -> Array:
    # Use spatial hashing for large grids
    if spatial_hashing_enabled and cells.size() > SPATIAL_HASH_THRESHOLD:
        return _get_cells_in_spatial_range(center, radius)
    
    # Fall back to brute force for small grids
    var result: Array[HexCell] = []
    
    var cubes_in_range := HexMath.range_cells(center, radius)
    for cube in cubes_in_range:
        var cell = get_cell(cube)
        if cell != null:
            result.append(cell)
    
    return result

## Returns all cube coordinates within range (including empty positions)
func get_cubes_in_range(center: Vector3i, radius: int) -> Array[Vector3i]:
    return HexMath.range_cells(center, radius)

## Returns cells forming a ring at exactly the given radius
func get_ring(center: Vector3i, radius: int) -> Array[HexCell]:
    var result: Array[HexCell] = []
    
    var ring_cubes := HexMath.ring(center, radius)
    for cube in ring_cubes:
        var cell = get_cell(cube)
        if cell != null:
            result.append(cell)
    
    return result

## Returns cells in a spiral pattern from center (radius 0 to max)
func get_spiral(center: Vector3i, max_radius: int) -> Array[HexCell]:
    var result: Array[HexCell] = []
    
    var spiral_cubes := HexMath.spiral(center, max_radius)
    for cube in spiral_cubes:
        var cell = get_cell(cube)
        if cell != null:
            result.append(cell)
    
    return result

# ============================================================================
# MOVEMENT COST LOOKUP
# ============================================================================

## Gets the movement cost between two adjacent cells
## Returns INF if either cell doesn't exist or movement is impossible
func get_movement_cost_between(from_cube: Vector3i, to_cube: Vector3i, unit_type: String = "infantry") -> float:
    var from_cell = get_cell(from_cube)
    var to_cell = get_cell(to_cube)
    
    if from_cell == null or to_cell == null:
        return 9999.0
    
    # Check adjacency
    if HexMath.distance(from_cube, to_cube) != 1:
        push_warning("HexGrid.get_movement_cost_between: Cells are not adjacent")
        return 9999.0
    
    return to_cell.get_movement_cost(unit_type, from_cell.elevation)

## Returns true if movement is possible between two adjacent cells
func can_move_between(from_cube: Vector3i, to_cube: Vector3i, unit_type: String = "infantry") -> bool:
    return get_movement_cost_between(from_cube, to_cube, unit_type) < 100.0

# ============================================================================
# BOUNDS MANAGEMENT
# ============================================================================

## Updates bounds to include the given cell
func _update_bounds_for_cell(cell: HexCell) -> void:
    var axial = cell.axial_coord
    
    if cells.size() == 1:
        # First cell - initialize bounds
        bounds = Rect2i(axial.x, axial.y, 0, 0)
    else:
        # Expand bounds to include this cell
        var min_q: int = min(bounds.position.x, axial.x)
        var min_r: int = min(bounds.position.y, axial.y)
        var max_q: int = max(bounds.end.x - 1, axial.x)
        var max_r: int = max(bounds.end.y - 1, axial.y)
        
        bounds = Rect2i(min_q, min_r, max_q - min_q + 1, max_r - min_r + 1)

## Recalculates bounds from all cells (called after removal)
func _recalculate_bounds() -> void:
    if cells.is_empty():
        bounds = Rect2i()
        return
    
    var first: bool = true
    var min_q: int = 0
    var min_r: int = 0
    var max_q: int = 0
    var max_r: int = 0
    
    for cell in cells.values():
        var axial = cell.axial_coord
        if first:
            min_q = axial.x
            max_q = axial.x
            min_r = axial.y
            max_r = axial.y
            first = false
        else:
            min_q = min(min_q, axial.x)
            max_q = max(max_q, axial.x)
            min_r = min(min_r, axial.y)
            max_r = max(max_r, axial.y)
    
    bounds = Rect2i(min_q, min_r, max_q - min_q + 1, max_r - min_r + 1)

## Returns the grid bounds as a Rect2i in axial coordinates
func get_bounds() -> Rect2i:
    return bounds

## Returns true if the given cube is within the grid bounds
func is_within_bounds(cube: Vector3i) -> bool:
    var axial := HexMath.cube_to_axial(cube)
    return bounds.has_point(axial)

## Returns all cells in the grid as an array
func get_all_cells() -> Array[HexCell]:
    var result: Array[HexCell] = []
    result.assign(cells.values())
    return result

## Returns all cube coordinates in the grid
func get_all_cubes() -> Array[Vector3i]:
    var result: Array[Vector3i] = []
    result.assign(cells.keys())
    return result

# ============================================================================
# SERIALIZATION
# ============================================================================

## Converts the grid to a serializable dictionary
func to_dict() -> Dictionary:
    var cell_array: Array = []
    
    for cell in cells.values():
        cell_array.append(cell.to_dict())
    
    return {
        "version": VERSION,
        "bounds": {
            "min_q": bounds.position.x,
            "min_r": bounds.position.y,
            "max_q": bounds.end.x - 1,
            "max_r": bounds.end.y - 1
        },
        "cells": cell_array
    }

## Creates a HexGrid from a serialized dictionary
static func from_dict(d: Dictionary):
    var grid = new()
    
    # Check version (for future compatibility)
    var version: String = d.get("version", "1.0.0")
    if version != VERSION:
        push_warning("HexGrid.from_dict: Version mismatch (file=%s, current=%s)" % [version, VERSION])
    
    # Load cells
    var cell_array: Array = d.get("cells", [])
    for cell_dict in cell_array:
        if cell_dict is Dictionary:
            var cell = HexCell.from_dict(cell_dict)
            if cell != null:
                grid.set_cell(cell)
    
    return grid

## Converts the grid to a JSON string
func to_json() -> String:
    return JSON.stringify(to_dict(), "  ")  # Pretty-print with 2-space indent

## Creates a HexGrid from a JSON string
static func from_json(json_string: String) -> HexGrid:
    var result: Variant = JSON.parse_string(json_string)
    if result == null or not result is Dictionary:
        push_error("HexGrid.from_json: Failed to parse JSON")
        return null
    return from_dict(result)

## Saves the grid to a file
## Returns true on success
func save_to_file(path: String) -> bool:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("HexGrid.save_to_file: Failed to open file: %s" % path)
        return false
    
    file.store_string(to_json())
    file.close()
    return true

## Loads a HexGrid from a file
## Returns null on failure
static func load_from_file(path: String) -> HexGrid:
    if not FileAccess.file_exists(path):
        push_error("HexGrid.load_from_file: File does not exist: %s" % path)
        return null
    
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("HexGrid.load_from_file: Failed to open file: %s" % path)
        return null
    
    var json_string := file.get_as_text()
    file.close()
    
    return from_json(json_string)

# ============================================================================
# UTILITY
# ============================================================================

## Returns a string representation for debugging
func _to_string() -> String:
    return "HexGrid[cells=%d, bounds=%s, spatial_buckets=%d]" % [
        cells.size(), bounds, _spatial_hash.size()
    ]

## Returns statistics about the grid
func get_stats() -> Dictionary:
    var terrain_counts: Dictionary = {}
    var elevation_counts: Dictionary = {}
    var blocking_count: int = 0
    
    for cell in cells.values():
        terrain_counts[cell.terrain_type] = terrain_counts.get(cell.terrain_type, 0) + 1
        elevation_counts[cell.elevation] = elevation_counts.get(cell.elevation, 0) + 1
        if cell.blocking:
            blocking_count += 1
    
    return {
        "total_cells": cells.size(),
        "bounds": bounds,
        "terrain_distribution": terrain_counts,
        "elevation_distribution": elevation_counts,
        "blocking_count": blocking_count,
        "spatial_hashing_enabled": spatial_hashing_enabled,
        "spatial_buckets": _spatial_hash.size()
    }

# ============================================================================
# TEST USAGE EXAMPLE
# ============================================================================
"""
# Test script for HexGrid:

func test_hex_grid():
    var grid = HexGrid.new()
    
    # Create some cells
    grid.create_cell_cube(Vector3i(0, 0, 0), "plains")
    grid.create_cell_cube(Vector3i(1, -1, 0), "forest", 1)
    grid.create_cell_cube(Vector3i(1, 0, -1), "mountain", 2, true)
    
    # Test queries
    assert(grid.get_cell_count() == 3, "Cell count mismatch")
    assert(grid.has_cell(Vector3i(0, 0, 0)), "Should have origin cell")
    
    # Test neighbors
    var neighbors = grid.get_neighbors(Vector3i(0, 0, 0))
    assert(neighbors.size() == 2, "Should have 2 neighbors (1 is missing)")
    
    # Test range query
    var in_range = grid.get_cells_in_range(Vector3i(0, 0, 0), 1)
    assert(in_range.size() == 3, "Range query should return all 3 cells")
    
    # Test serialization
    var json = grid.to_json()
    var restored = HexGrid.from_json(json)
    assert(restored.get_cell_count() == 3, "Roundtrip failed")
    
    # Test spatial hashing with large grid
    var large_grid = HexGrid.new()
    for q in range(-20, 21):
        for r in range(-20, 21):
            large_grid.create_cell(Vector2i(q, r), "plains")
    
    assert(large_grid._spatial_hash.size() > 0, "Spatial hash should be populated")
    
    var spatial_result = large_grid._get_cells_in_spatial_range(Vector3i(0, 0, 0), 5)
    assert(spatial_result.size() > 0, "Spatial query should return cells")
    
    print("All HexGrid tests passed!")
"""
