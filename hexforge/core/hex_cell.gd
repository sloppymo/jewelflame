## HexForge/Core/HexCell
## Resource representing a single hexagonal cell's data
## Uses AXIAL coordinates for storage, computes cube on-the-fly
## Part of HexForge hex grid system
## Phase: 2

class_name HexCell
extends Resource

const HexMath = preload("res://hexforge/core/hex_math.gd")



# ============================================================================
# EXPORTED PROPERTIES (Visible in Godot Inspector)
# ============================================================================

## Axial coordinates [q, r] - stored compactly for JSON serialization
## q = column (like x), r = row (like z in cube)
@export var axial_coord: Vector2i = Vector2i.ZERO

## Terrain type identifier
## Valid: "plains", "forest", "mountain", "water", "road", "marsh"
@export var terrain_type: String = "plains"

## Elevation level: 0=valley/ground, 1=hill/raised, 2=cliff/impassable height
@export var elevation: int = 0

## If true, completely impassable (walls, deep water, etc.)
## Independent of terrain type
@export var blocking: bool = false

# ============================================================================
# TRANSIENT PROPERTIES (Not serialized)
# ============================================================================

## String ID referencing a unit in external UnitManager
## Empty string = no occupant
## NOT serialized in grid JSON (saved separately in Unit save data)
var occupant_id: String = ""

# ============================================================================
# COMPUTED PROPERTIES
# ============================================================================

## Cube coordinates computed from axial storage (read-only)
## Returns Vector3i(q, r, s) where s = -q-r
var cube_coord: Vector3i:
    get:
        return Vector3i(
            axial_coord.x,
            axial_coord.y,
            -axial_coord.x - axial_coord.y
        )
    set(value):
        push_warning("HexCell: cube_coord is read-only. Set axial_coord instead.")

# ============================================================================
# CONSTANTS
# ============================================================================

const MAX_ELEVATION: int = 2
const MIN_ELEVATION: int = 0

const TERRAIN_PLAINS: String = "plains"
const TERRAIN_FOREST: String = "forest"
const TERRAIN_MOUNTAIN: String = "mountain"
const TERRAIN_WATER: String = "water"
const TERRAIN_ROAD: String = "road"
const TERRAIN_MARSH: String = "marsh"

const VALID_TERRAINS: Array[String] = [
    TERRAIN_PLAINS,
    TERRAIN_FOREST,
    TERRAIN_MOUNTAIN,
    TERRAIN_WATER,
    TERRAIN_ROAD,
    TERRAIN_MARSH
]

# ============================================================================
# CONSTRUCTION
# ============================================================================

## Creates a new HexCell with the specified axial coordinates
func _init(q: int = 0, r: int = 0) -> void:
    axial_coord = Vector2i(q, r)
    _validate_cube()

## Static factory: Creates a HexCell from axial coordinates
static func create_axial(axial: Vector2i, p_terrain: String = "plains", p_elevation: int = 0, p_blocking: bool = false):
    var cell = new(axial.x, axial.y)
    cell.terrain_type = p_terrain
    cell.elevation = p_elevation
    cell.blocking = p_blocking
    return cell

## Static factory: Creates a HexCell from cube coordinates
static func create_cube(cube: Vector3i, p_terrain: String = "plains", p_elevation: int = 0, p_blocking: bool = false):
    var axial := Vector2i(cube.x, cube.z)
    return create_axial(axial, p_terrain, p_elevation, p_blocking)

# ============================================================================
# VALIDATION
# ============================================================================

## Validates that q + r + s == 0 (cube coordinate invariant)
func _validate_cube() -> void:
    var q: int = axial_coord.x
    var r: int = axial_coord.y
    var s: int = -q - r
    
    if q + r + s != 0:
        push_error("HexCell: Invalid cube coordinates at %s (q=%d, r=%d, s=%d, sum=%d)" % [
            axial_coord, q, r, s, q + r + s
        ])
        # In debug builds, we could assert here
        assert(q + r + s == 0, "Cube coordinate invariant violated")

## Returns true if the terrain type is valid
func is_valid_terrain() -> bool:
    return terrain_type in VALID_TERRAINS

# ============================================================================
# MOVEMENT COST API
# ============================================================================

## Returns movement point cost to enter this cell
## 
## Base costs by terrain:
##   - plains: 1.0
##   - forest: 2.0 (3.0 if cavalry)
##   - mountain: 999.0 if blocking, else 3.0
##   - water: 999.0 (impassable unless naval)
##   - road: 0.67 (2/3 cost)
##   - marsh: 3.0
##
## Elevation modifier: +1.0 per level climbing up, -0.5 per level down (min 0.5)
##
## @param unit_type: "infantry", "cavalry", "naval", "flying"
## @param from_elevation: elevation of the cell we're coming from
func get_movement_cost(unit_type: String = "infantry", from_elevation: int = 0) -> float:
    # Blocking check - completely impassable
    if blocking:
        return 9999.0
    
    # Base terrain cost
    var base_cost: float
    match terrain_type:
        TERRAIN_PLAINS:
            base_cost = 1.0
        TERRAIN_FOREST:
            base_cost = 3.0 if unit_type == "cavalry" else 2.0
        TERRAIN_MOUNTAIN:
            base_cost = 999.0  # Impassable unless explicitly non-blocking
        TERRAIN_WATER:
            base_cost = 0.5 if unit_type == "naval" else 999.0
        TERRAIN_ROAD:
            base_cost = 0.67  # 2/3 cost, pathfinder should ceil if needed
        TERRAIN_MARSH:
            base_cost = 3.0
        _:
            base_cost = 1.0
    
    # If base cost is already impassable, return early
    if base_cost >= 999.0:
        return base_cost
    
    # Elevation modifier
    var elevation_diff: int = elevation - from_elevation
    var elevation_cost: float
    if elevation_diff > 0:
        # Climbing up: +1.0 per level
        elevation_cost = float(elevation_diff) * 1.0
    else:
        # Going down: -0.5 per level (but minimum 0.5 total)
        elevation_cost = max(0.5, 1.0 + float(elevation_diff) * 0.5)
    
    return base_cost + elevation_cost

## Returns true if this cell is passable for the given unit type
func is_passable(unit_type: String = "infantry") -> bool:
    return get_movement_cost(unit_type) < 100.0

## Returns true if this cell is passable considering elevation change
func is_passable_from(unit_type: String, from_elevation: int) -> bool:
    return get_movement_cost(unit_type, from_elevation) < 100.0

# ============================================================================
# LINE OF SIGHT API
# ============================================================================

## Returns true if this cell blocks line of sight from the given elevation
## 
## Logic:
##   - Blocks if elevation > from_elevation + 1 (higher than viewer + 1 level)
##   - OR if blocking == true (walls always block)
##
## @param from_elevation: elevation of the viewer
func blocks_los(from_elevation: int) -> bool:
    if blocking:
        return true
    return elevation > from_elevation + 1

## Returns the defense bonus for units occupying this cell
## Used by combat system
func get_defense_bonus() -> int:
    match terrain_type:
        TERRAIN_FOREST:
            return 2
        TERRAIN_MOUNTAIN:
            return 3 if elevation >= 2 else 1
        _:
            if elevation == 1:
                return 1
            return 0

# ============================================================================
# COORDINATE ACCESS
# ============================================================================

## Explicit getter for cube coordinates (alternative to property)
func get_cube() -> Vector3i:
    return cube_coord

## Returns the axial coordinates as Vector2i
func get_axial() -> Vector2i:
    return axial_coord

## Returns the world position for this cell (requires hex size)
func get_world_position(hex_size: float) -> Vector2:
    return HexMath.cube_to_world(cube_coord, hex_size)

# ============================================================================
# SERIALIZATION
# ============================================================================

## Converts this cell to a serializable dictionary
## Uses array format for JSON compactness
## NOTE: occupant_id is EXCLUDED - units saved separately
func to_dict() -> Dictionary:
    return {
        "axial": [axial_coord.x, axial_coord.y],
        "terrain": terrain_type,
        "elevation": elevation,
        "blocking": blocking
        # occupant_id intentionally omitted
    }

## Reconstructs HexCell from a serialized dictionary
static func from_dict(d: Dictionary):
    # Extract axial coordinates with defaults
    var axial_array: Array = d.get("axial", [0, 0])
    if axial_array.size() < 2:
        push_warning("HexCell.from_dict: Invalid axial array, using defaults")
        axial_array = [0, 0]
    
    var q: int = axial_array[0] if axial_array[0] is int else 0
    var r: int = axial_array[1] if axial_array[1] is int else 0
    
    # Create cell with defensive defaults
    var cell = new(q, r)
    cell.terrain_type = d.get("terrain", "plains")
    cell.elevation = d.get("elevation", 0)
    cell.blocking = d.get("blocking", false)
    
    # Validate cube coordinates
    cell._validate_cube()
    
    return cell

## Creates a JSON string representation
func to_json() -> String:
    return JSON.stringify(to_dict())

## Creates a HexCell from a JSON string
static func from_json(json_string: String):
    var result: Variant = JSON.parse_string(json_string)
    if result == null or not result is Dictionary:
        push_error("HexCell.from_json: Failed to parse JSON")
        return null
    return from_dict(result)

# ============================================================================
# UTILITY METHODS
# ============================================================================

## Returns a new HexCell with the same data (deep copy of properties)
## New cell has occupant_id = "" (occupant not copied)
## Used for undo/redo or predictive pathfinding
func duplicate_data() -> HexCell:
    var new_cell = new(axial_coord.x, axial_coord.y)
    new_cell.terrain_type = terrain_type
    new_cell.elevation = elevation
    new_cell.blocking = blocking
    # occupant_id intentionally left empty
    return new_cell

## Returns true if this cell has the same coordinates as another
func same_coordinates(other) -> bool:
    return axial_coord == other.axial_coord

## Returns true if this cell has identical properties (excluding occupant)
func same_properties(other: HexCell) -> bool:
    return (
        terrain_type == other.terrain_type and
        elevation == other.elevation and
        blocking == other.blocking
    )

# ============================================================================
# DEBUG AND UTILITY
# ============================================================================

## Returns a string representation for debugging
func _to_string() -> String:
    return "HexCell[%s] terrain=%s elevation=%d blocking=%s occupant=%s" % [
        axial_coord,
        terrain_type,
        elevation,
        blocking,
        occupant_id if occupant_id != "" else "none"
    ]

## Returns a compact string representation (for logs)
func to_compact_string() -> String:
    return "%s:%s:%d" % [axial_coord, terrain_type, elevation]

# ============================================================================
# TEST USAGE EXAMPLE (commented - run manually to verify)
# ============================================================================
"""
# Test script for HexCell:

func test_hex_cell():
    # Create cell
    var cell = HexCell.new(3, -2)
    cell.terrain_type = "forest"
    cell.elevation = 1
    
    # Verify cube coordinates
    assert(cell.cube_coord == Vector3i(3, -2, -1), "Cube coord mismatch")
    
    # Test movement costs
    assert(cell.get_movement_cost("infantry", 0) == 3.0, "Forest + hill climb should be 3.0")
    assert(cell.get_movement_cost("cavalry", 0) == 4.0, "Forest + cavalry + hill should be 4.0")
    
    # Test serialization
    var dict = cell.to_dict()
    var restored = HexCell.from_dict(dict)
    assert(restored.axial_coord == cell.axial_coord, "Roundtrip failed")
    assert(restored.terrain_type == cell.terrain_type, "Terrain not preserved")
    
    print("All HexCell tests passed!")
"""
