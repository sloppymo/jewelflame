## HexForge/Rendering/HexCursor
## Mouse/touch interaction for hex grid
## Handles selection, hover, and input events
## Part of HexForge hex grid system

class_name HexCursor
extends Node2D

const HexMath = preload("res://hexforge/core/hex_math.gd")
const HexCell = preload("res://hexforge/core/hex_cell.gd")
const HexRenderer2D = preload("res://hexforge/rendering/hex_renderer_2d.gd")

# ============================================================================
# SIGNALS
# ============================================================================

## Emitted when a cell is clicked
signal cell_clicked(cube: Vector3i, cell, button: int)

## Emitted when a cell is hovered (mouse moved to new cell)
signal cell_hovered(cube: Vector3i, cell)

## Emitted when mouse leaves a cell
signal cell_exited(cube: Vector3i)

## Emitted when drag selection starts
signal drag_started(start_cube: Vector3i)

## Emitted when drag selection ends
signal drag_ended(end_cube: Vector3i, dragged_cells: Array[Vector3i])

# ============================================================================
# CONFIGURATION
# ============================================================================

## The HexGrid to interact with
var grid = null

## The HexRenderer2D (for coordinate conversion)
var renderer = null

## Enable/disable interaction
@export var enabled: bool = true

## Show hover highlight
@export var show_hover: bool = true

## Hover highlight color
@export var hover_color: Color = Color(1.0, 1.0, 1.0, 0.2)

## Enable drag selection
@export var enable_drag: bool = false

## Minimum drag distance to trigger selection (pixels)
@export var drag_threshold: float = 10.0

# ============================================================================
# INTERNAL STATE
# ============================================================================

## Currently hovered cell
var hovered_cell: Vector3i = Vector3i.MAX

## Currently selected cell(s)
var selected_cells: Array[Vector3i] = []

## Drag state
var is_dragging: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_start_cube: Vector3i = Vector3i.MAX

## Input handling
var _camera: Camera2D = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
    # Find renderer if not set
    if renderer == null:
        renderer = _find_renderer()
    
    # Find camera for proper coordinate conversion
    _camera = _find_camera()

## Finds the HexRenderer2D in the scene
func _find_renderer():
    # Check siblings
    var parent := get_parent()
    if parent:
        for child in parent.get_children():
            if child is HexRenderer2D:
                return child
    
    # Check entire scene
    return get_tree().root.find_child("HexRenderer2D", true, false)

## Finds the active Camera2D
func _find_camera() -> Camera2D:
    var viewport := get_viewport()
    if viewport:
        return viewport.get_camera_2d()
    return null

# ============================================================================
# INPUT HANDLING
# ============================================================================

func _input(event: InputEvent) -> void:
    if not enabled or grid == null:
        return
    
    if event is InputEventMouseMotion:
        _handle_mouse_motion(event)
    elif event is InputEventMouseButton:
        _handle_mouse_button(event)

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
    var screen_pos: Vector2 = event.position
    var cube := _screen_to_cube(screen_pos)
    
    # Handle hover
    if cube != hovered_cell:
        # Clear old hover
        if hovered_cell != Vector3i.MAX and show_hover:
            _clear_hover_highlight()
        
        hovered_cell = cube
        
        # Set new hover
        if hovered_cell != Vector3i.MAX:
            var cell = grid.get_cell(hovered_cell)
            if show_hover and cell != null:
                _set_hover_highlight(hovered_cell)
            cell_hovered.emit(hovered_cell, cell)
        else:
            cell_exited.emit(hovered_cell)
    
    # Handle drag
    if is_dragging and enable_drag:
        _update_drag_selection(screen_pos)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
    if not event.pressed:
        # Button released
        if is_dragging and enable_drag:
            _end_drag(event.position)
        return
    
    var screen_pos: Vector2 = event.position
    var cube := _screen_to_cube(screen_pos)
    var cell = grid.get_cell(cube) if cube != Vector3i.MAX else null
    
    # Left click
    if event.button_index == MOUSE_BUTTON_LEFT:
        if enable_drag:
            _start_drag(screen_pos, cube)
        else:
            # Simple selection
            select_cell(cube)
            cell_clicked.emit(cube, cell, event.button_index)
    
    # Right click
    elif event.button_index == MOUSE_BUTTON_RIGHT:
        cell_clicked.emit(cube, cell, event.button_index)
    
    # Middle click (pan camera - let it pass through)
    elif event.button_index == MOUSE_BUTTON_MIDDLE:
        pass

# ============================================================================
# DRAG SELECTION
# ============================================================================

func _start_drag(screen_pos: Vector2, cube: Vector3i) -> void:
    is_dragging = true
    drag_start_pos = screen_pos
    drag_start_cube = cube
    drag_started.emit(cube)

func _update_drag_selection(screen_pos: Vector2) -> void:
    # Check if we've moved enough to count as a drag
    var distance: float = drag_start_pos.distance_to(screen_pos)
    if distance < drag_threshold:
        return
    
    # TODO: Draw selection rectangle or highlight dragged cells
    # This would require additional visual feedback

func _end_drag(screen_pos: Vector2) -> void:
    is_dragging = false
    var end_cube := _screen_to_cube(screen_pos)
    
    # Get all cells in the drag rectangle (if we implemented that)
    # For now, just emit the start and end
    var dragged_cells: Array[Vector3i] = []
    
    drag_ended.emit(end_cube, dragged_cells)

# ============================================================================
# COORDINATE CONVERSION
# ============================================================================

## Converts screen position to cube coordinates
func _screen_to_cube(screen_pos: Vector2) -> Vector3i:
    if renderer == null:
        return Vector3i.MAX
    
    # Adjust for camera if present
    var world_pos: Vector2 = screen_pos
    if _camera != null:
        world_pos = _camera.get_canvas_transform().affine_inverse() * screen_pos
    
    return renderer.screen_to_cube(world_pos)

## Returns the cell at screen position (or null)
func get_cell_at_screen(screen_pos: Vector2):
    if grid == null:
        return null
    
    var cube := _screen_to_cube(screen_pos)
    if cube == Vector3i.MAX:
        return null
    
    return grid.get_cell(cube)

# ============================================================================
# SELECTION API
# ============================================================================

## Selects a single cell
func select_cell(cube: Vector3i) -> void:
    # Clear previous selection
    clear_selection()
    
    if cube != Vector3i.MAX and grid.has_cell(cube):
        selected_cells.append(cube)
        
        # Update renderer selection
        if renderer != null:
            renderer.select_cell(cube)

## Adds a cell to the current selection (multi-select)
func add_to_selection(cube: Vector3i) -> void:
    if cube != Vector3i.MAX and grid.has_cell(cube) and not cube in selected_cells:
        selected_cells.append(cube)

## Removes a cell from selection
func remove_from_selection(cube: Vector3i) -> void:
    selected_cells.erase(cube)

## Clears all selection
func clear_selection() -> void:
    selected_cells.clear()
    if renderer != null:
        renderer.clear_selection()

## Returns the primary selected cell (or Vector3i.MAX)
func get_selected_cell() -> Vector3i:
    if selected_cells.is_empty():
        return Vector3i.MAX
    return selected_cells[0]

## Returns all selected cells
func get_selected_cells() -> Array[Vector3i]:
    return selected_cells.duplicate()

## Returns true if a cell is selected
func is_selected(cube: Vector3i) -> bool:
    return cube in selected_cells

# ============================================================================
# HOVER HIGHLIGHTING
# ============================================================================

func _set_hover_highlight(cube: Vector3i) -> void:
    if renderer != null:
        renderer.highlight_cell(cube, hover_color)

func _clear_hover_highlight() -> void:
    if renderer != null and hovered_cell != Vector3i.MAX:
        renderer.clear_highlight(hovered_cell)

# ============================================================================
# UTILITY
# ============================================================================

## Returns the currently hovered cell (or Vector3i.MAX)
func get_hovered_cell() -> Vector3i:
    return hovered_cell

## Returns the cell object under the mouse (or null)
func get_hovered_cell_object():
    if hovered_cell == Vector3i.MAX or grid == null:
        return null
    return grid.get_cell(hovered_cell)

## Enables/disables cursor interaction
func set_enabled(value: bool) -> void:
    enabled = value
    if not enabled:
        clear_selection()
        _clear_hover_highlight()
