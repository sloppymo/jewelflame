## HexForge/Battle/BattleGrid
## Manages the hex grid and terrain serialization
## Separated from gameplay logic for cleaner architecture
## Part of HexForge battle system

class_name BattleGrid
extends Node

const HexGrid = preload("res://hexforge/core/hex_grid.gd")
const HexCell = preload("res://hexforge/core/hex_cell.gd")
const HexMath = preload("res://hexforge/core/hex_math.gd")

# ============================================================================
# SIGNALS
# ============================================================================

signal grid_loaded(grid)
signal grid_changed()

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var grid_width: int = 11
@export var grid_height: int = 11

# ============================================================================
# STATE
# ============================================================================

var grid = null
var _map_generator: MapGenerator = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
    grid = HexGrid.new()
    _map_generator = MapGenerator.new()

# ============================================================================
# GRID LOADING
# ============================================================================

func load_grid(map_data: Variant = null) -> void:
    match typeof(map_data):
        TYPE_OBJECT when map_data is Object and map_data.has_method("get_cell"):
            grid = map_data
        TYPE_DICTIONARY:
            _load_from_dictionary(map_data)
        _:
            _generate_default_grid()
    
    grid_loaded.emit(grid)

func _load_from_dictionary(data: Dictionary) -> void:
    grid.clear()
    
    if data.has("cells"):
        for cell_data in data["cells"]:
            var cell = HexCell.from_dict(cell_data)
            if cell:
                grid.set_cell(cell)
    
    grid_changed.emit()

func _generate_default_grid() -> void:
    grid.clear()
    
    for q in range(-grid_width / 2, grid_width / 2 + 1):
        for r in range(-grid_height / 2, grid_height / 2 + 1):
            var cube := HexMath.axial_to_cube(Vector2i(q, r))
            var terrain := _map_generator.get_terrain_for(cube)
            grid.create_cell_cube(cube, terrain.type, terrain.elevation, terrain.blocking)
    
    grid_changed.emit()

# ============================================================================
# SERIALIZATION
# ============================================================================

func serialize() -> Dictionary:
    return grid.to_dict()

func deserialize(data: Dictionary) -> void:
    var new_grid = HexGrid.from_dict(data)
    if new_grid:
        grid = new_grid
        grid_loaded.emit(grid)

func save_to_file(path: String) -> bool:
    return grid.save_to_file(path)

func load_from_file(path: String) -> bool:
    var new_grid := HexGrid.load_from_file(path)
    if new_grid:
        grid = new_grid
        grid_loaded.emit(grid)
        return true
    return false

# ============================================================================
# UTILITY
# ============================================================================

func get_cell(cube: Vector3i):
    return grid.get_cell(cube) if grid else null

func has_cell(cube: Vector3i) -> bool:
    return grid.has_cell(cube) if grid else false

func get_cells_in_range(center: Vector3i, radius: int) -> Array:
    return grid.get_cells_in_range(center, radius) if grid else []

# ============================================================================
# MAP GENERATOR INNER CLASS
# ============================================================================

class MapGenerator:
    func get_terrain_for(cube: Vector3i) -> Dictionary:
        var noise := randf()
        
        if noise > 0.85:
            return { "type": "forest", "elevation": 0, "blocking": false }
        elif noise > 0.75:
            return { "type": "mountain", "elevation": 2, "blocking": true }
        elif noise > 0.70:
            return { "type": "water", "elevation": 0, "blocking": true }
        else:
            return { "type": "plains", "elevation": 0, "blocking": false }
