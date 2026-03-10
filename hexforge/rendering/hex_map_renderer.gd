## HexForge/Rendering/HexMapRenderer
## Background map mode renderer - displays pre-rendered map with hex overlay
## Alternative to HexRenderer2D for beautiful pre-made battlefields
## Draws only hex borders (polylines), not filled polygons
## Part of HexForge hex grid system

class_name HexMapRenderer
extends Node2D

# ============================================================================
# CONFIGURATION
# ============================================================================

## The HexGrid to render (set this after instantiation)
var grid: HexGrid = null:
	set(value):
		grid = value
		queue_redraw()

## Hex size (distance from center to corner)
@export var hex_size: float = 32.0:
	set(value):
		hex_size = value
		_generate_hex_polygon()
		queue_redraw()

## Background texture (pre-rendered battlefield map)
@export var background_texture: Texture2D = null:
	set(value):
		background_texture = value
		queue_redraw()

## Background texture scale (to match grid size)
@export var background_scale: float = 1.0:
	set(value):
		background_scale = value
		queue_redraw()

## Background offset (to align with grid)
@export var background_offset: Vector2 = Vector2.ZERO:
	set(value):
		background_offset = value
		queue_redraw()

## Line width for hex borders
@export var line_width: float = 1.5

## Grid line color
@export var grid_line_color: Color = Color(0.2, 0.2, 0.2, 0.6)

## Show grid lines
@export var show_grid_lines: bool = true:
	set(value):
		show_grid_lines = value
		queue_redraw()

## Highlight color (for selection)
@export var highlight_color: Color = Color(1.0, 1.0, 0.0, 0.3)

## Selection border color
@export var selection_color: Color = Color(1.0, 0.8, 0.0, 1.0)

## Selection border width
@export var selection_line_width: float = 3.0

# ============================================================================
# ELEVATION INDICATORS
# ============================================================================

@export var show_elevation_indicators: bool = true
@export var elevation_indicator_color: Color = Color(0.8, 0.8, 0.8, 0.8)
@export var elevation_indicator_size: float = 8.0

# ============================================================================
# VIEWPORT CULLING
# ============================================================================

## Enable viewport culling (skip drawing off-screen hexes)
@export var enable_culling: bool = true

## Padding around viewport to include cells near edge (in pixels)
@export var cull_padding: float = 64.0

## Cached viewport rect for culling
var _viewport_rect: Rect2 = Rect2()

## Cached camera reference
var _camera: Camera2D = null

## Last frame's visible cells (for debugging)
var _visible_cell_count: int = 0

## Total cells in grid (for debugging)
var _total_cell_count: int = 0

# ============================================================================
# INTERNAL STATE
# ============================================================================

## Currently highlighted cells (for range display)
var highlighted_cells: Dictionary = {}  # Vector3i -> Color

## Currently selected cell
var selected_cell: Vector3i = Vector3i.MAX

## Cached polygon for a single hex (reused for all cells)
var _hex_polygon: PackedVector2Array = []

## Cached closed polygon (for polylines)
var _hex_polygon_closed: PackedVector2Array = []

## Pre-calculated world positions cache
var _world_position_cache: Dictionary = {}

## Enable position caching
@export var cache_world_positions: bool = true

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_generate_hex_polygon()
	_find_camera()

## Generates the polygon points for a single hexagon
func _generate_hex_polygon() -> void:
	_hex_polygon.clear()
	_hex_polygon_closed.clear()
	
	for i in range(6):
		var angle: float = PI / 3.0 * i - PI / 6.0  # Pointy-top orientation
		var x: float = hex_size * cos(angle)
		var y: float = hex_size * sin(angle)
		_hex_polygon.append(Vector2(x, y))
		_hex_polygon_closed.append(Vector2(x, y))
	
	# Close the polygon for polyline drawing
	_hex_polygon_closed.append(_hex_polygon_closed[0])

## Finds the active camera for culling calculations
func _find_camera() -> void:
	var viewport := get_viewport()
	if viewport:
		_camera = viewport.get_camera_2d()

## Clears the world position cache
func clear_position_cache() -> void:
	_world_position_cache.clear()

# ============================================================================
# VIEWPORT CULLING
# ============================================================================

## Updates the viewport rect for culling calculations
func _update_viewport_rect() -> void:
	if _camera == null:
		_find_camera()
	
	if _camera != null:
		# Get camera viewport in world coordinates
		var canvas_transform := _camera.get_canvas_transform()
		var viewport_size := get_viewport_rect().size
		
		# Transform viewport corners to world space
		var top_left := canvas_transform.affine_inverse() * Vector2.ZERO
		var bottom_right := canvas_transform.affine_inverse() * viewport_size
		
		# Add padding
		top_left -= Vector2(cull_padding, cull_padding)
		bottom_right += Vector2(cull_padding, cull_padding)
		
		_viewport_rect = Rect2(top_left, bottom_right - top_left)
	else:
		# No camera - render everything
		_viewport_rect = Rect2(-Vector2.INF, Vector2.INF)

## Returns true if a world position is within the viewport (with padding)
func _is_in_viewport(world_pos: Vector2) -> bool:
	if not enable_culling:
		return true
	return _viewport_rect.has_point(world_pos)

## Returns true if a cell might be visible (conservative check)
func _cell_might_be_visible(cell: HexCell) -> bool:
	if not enable_culling:
		return true
	
	var world_pos := _get_cached_world_position(cell.cube_coord)
	
	# Check if cell center is in viewport
	if _is_in_viewport(world_pos):
		return true
	
	# Check if any corner might be in viewport (conservative)
	# A hex extends hex_size from center in all directions
	var extended_rect := Rect2(
		world_pos - Vector2(hex_size, hex_size),
		Vector2(hex_size * 2, hex_size * 2)
	)
	
	return _viewport_rect.intersects(extended_rect)

## Gets a cached world position or calculates it
func _get_cached_world_position(cube: Vector3i) -> Vector2:
	if cache_world_positions:
		if not _world_position_cache.has(cube):
			_world_position_cache[cube] = HexMath.cube_to_world(cube, hex_size)
		return _world_position_cache[cube]
	else:
		return HexMath.cube_to_world(cube, hex_size)

## Invalidates the world position cache for a specific cell
func invalidate_position_cache(cube: Vector3i) -> void:
	_world_position_cache.erase(cube)

# ============================================================================
# RENDERING
# ============================================================================

func _draw() -> void:
	if grid == null:
		return
	
	# Update viewport rect for culling
	_update_viewport_rect()
	
	_total_cell_count = grid.get_cell_count()
	_visible_cell_count = 0
	
	# Draw background texture if available
	_draw_background()
	
	# Draw grid lines (polylines, not filled)
	if show_grid_lines:
		_draw_grid_lines()
	
	# Draw elevation indicators
	if show_elevation_indicators:
		_draw_elevation_indicators()
	
	# Draw highlights on top
	for cube in highlighted_cells.keys():
		if grid.has_cell(cube):
			var cell := grid.get_cell(cube)
			if cell != null and (not enable_culling or _cell_might_be_visible(cell)):
				_draw_highlight(cube, highlighted_cells[cube])
	
	# Draw selection
	if selected_cell != Vector3i.MAX and grid.has_cell(selected_cell):
		var selected_cell_obj := grid.get_cell(selected_cell)
		if selected_cell_obj != null and (not enable_culling or _cell_might_be_visible(selected_cell_obj)):
			_draw_selection(selected_cell)

## Draws the background texture
func _draw_background() -> void:
	if background_texture == null:
		return
	
	var texture_size := background_texture.get_size()
	var scaled_size := texture_size * background_scale
	
	# Calculate position to center the texture at origin, then apply offset
	var draw_position := -scaled_size / 2.0 + background_offset
	
	draw_texture_rect(
		background_texture,
		Rect2(draw_position, scaled_size),
		false
	)

## Draws grid lines as polylines (not filled polygons)
func _draw_grid_lines() -> void:
	for cell in grid.get_all_cells():
		# Check culling
		if not _cell_might_be_visible(cell):
			continue
		
		_draw_cell_border(cell)
		_visible_cell_count += 1

## Draws a single hex cell border (polyline only)
func _draw_cell_border(cell: HexCell) -> void:
	var world_pos: Vector2 = _get_cached_world_position(cell.cube_coord)
	
	# Draw border as polyline (not filled polygon)
	var polygon := _get_hex_polygon_at(world_pos)
	draw_polyline(polygon, grid_line_color, line_width, true)

## Returns the hex polygon at a specific world position
func _get_hex_polygon_at(world_pos: Vector2) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	result.resize(_hex_polygon_closed.size())
	
	for i in range(_hex_polygon_closed.size()):
		result[i] = _hex_polygon_closed[i] + world_pos
	
	return result

## Draws elevation indicators for cells with elevation > 0
func _draw_elevation_indicators() -> void:
	for cell in grid.get_all_cells():
		if cell.elevation <= 0:
			continue
		
		if not _cell_might_be_visible(cell):
			continue
		
		_draw_elevation_indicator(cell)

## Draws a single elevation indicator
func _draw_elevation_indicator(cell: HexCell) -> void:
	var world_pos: Vector2 = _get_cached_world_position(cell.cube_coord)
	
	# Draw stacked bars or number based on elevation
	var bar_width: float = elevation_indicator_size
	var bar_height: float = elevation_indicator_size * 0.4
	var spacing: float = 2.0
	
	# Draw small stacked rectangles in center
	for i in range(cell.elevation):
		var y_offset: float = -i * (bar_height + spacing)
		var rect := Rect2(
			world_pos - Vector2(bar_width / 2, bar_height / 2) + Vector2(0, y_offset),
			Vector2(bar_width, bar_height)
		)
		draw_rect(rect, elevation_indicator_color, true)
		draw_rect(rect, Color(elevation_indicator_color, 1.0), false, 1.0)

## Draws a highlight overlay on a cell
func _draw_highlight(cube: Vector3i, color: Color) -> void:
	var world_pos: Vector2 = _get_cached_world_position(cube)
	
	# Draw filled highlight
	var points := PackedVector2Array()
	for point in _hex_polygon:
		points.append(point + world_pos)
	
	draw_polygon(points, [color])
	
	# Draw highlight border
	draw_polyline(_get_hex_polygon_at(world_pos), Color(color.r, color.g, color.b, 1.0), line_width + 1, true)

## Draws a selection border around a cell
func _draw_selection(cube: Vector3i) -> void:
	var world_pos: Vector2 = _get_cached_world_position(cube)
	draw_polyline(_get_hex_polygon_at(world_pos), selection_color, selection_line_width, true)

# ============================================================================
# HIGHLIGHTING API (Same interface as HexRenderer2D)
# ============================================================================

## Highlights a cell with a specific color
func highlight_cell(cube: Vector3i, color: Color = highlight_color) -> void:
	highlighted_cells[cube] = color
	queue_redraw()

## Removes highlight from a cell
func clear_highlight(cube: Vector3i) -> void:
	highlighted_cells.erase(cube)
	queue_redraw()

## Clears all highlights
func clear_all_highlights() -> void:
	highlighted_cells.clear()
	queue_redraw()

## Highlights multiple cells at once
func highlight_cells(cubes: Array[Vector3i], color: Color = highlight_color) -> void:
	for cube in cubes:
		highlighted_cells[cube] = color
	queue_redraw()

## Highlights cells from HexCell array
func highlight_cell_objects(cells: Array[HexCell], color: Color = highlight_color) -> void:
	for cell in cells:
		highlighted_cells[cell.cube_coord] = color
	queue_redraw()

# ============================================================================
# SELECTION API (Same interface as HexRenderer2D)
# ============================================================================

## Selects a cell (draws selection border)
func select_cell(cube: Vector3i) -> void:
	selected_cell = cube
	queue_redraw()

## Clears the current selection
func clear_selection() -> void:
	selected_cell = Vector3i.MAX
	queue_redraw()

## Returns the currently selected cell (or Vector3i.MAX if none)
func get_selected_cell() -> Vector3i:
	return selected_cell

# ============================================================================
# UTILITY
# ============================================================================

## Converts screen position to cube coordinates
func screen_to_cube(screen_pos: Vector2) -> Vector3i:
	# Convert screen to local
	var local_pos: Vector2 = to_local(screen_pos)
	return HexMath.world_to_cube(local_pos, hex_size)

## Returns the cell at a screen position (or null if none)
func get_cell_at_screen(screen_pos: Vector2) -> HexCell:
	if grid == null:
		return null
	
	var cube: Vector3i = screen_to_cube(screen_pos)
	return grid.get_cell(cube)

## Forces a redraw of the grid
func refresh() -> void:
	queue_redraw()

## Returns rendering statistics
func get_render_stats() -> Dictionary:
	return {
		"total_cells": _total_cell_count,
		"visible_cells": _visible_cell_count,
		"culled_cells": _total_cell_count - _visible_cell_count,
		"culling_enabled": enable_culling,
		"cache_size": _world_position_cache.size()
	}

# ============================================================================
# BATCH OPERATIONS (Same interface as HexRenderer2D)
# ============================================================================

## Highlights all cells in a path
func highlight_path(path: Array[Vector3i], color: Color = highlight_color) -> void:
	highlight_cells(path, color)

## Highlights reachable cells (movement range)
func highlight_reachable(center: Vector3i, max_movement: float, unit_type: String = "infantry") -> void:
	if grid == null:
		return
	
	var reachable := Pathfinder.find_reachable(grid, center, max_movement, unit_type)
	for cube in reachable.keys():
		# Vary color by cost (greener = cheaper)
		var cost: float = reachable[cube]
		var intensity: float = 1.0 - (cost / max_movement * 0.5)
		var cell_color: Color = Color(0.0, intensity, 0.0, 0.4)
		highlighted_cells[cube] = cell_color
	
	queue_redraw()

## Highlights attack range (LoS check included)
func highlight_attack_range(center: Vector3i, max_range: int, from_elevation: int = -1) -> void:
	if grid == null:
		return
	
	if from_elevation < 0:
		var center_cell := grid.get_cell(center)
		from_elevation = center_cell.elevation if center_cell else 0
	
	var in_range := grid.get_cells_in_range(center, max_range)
	for cell in in_range:
		if LineOfSight.has_los(grid, center, cell.cube_coord, from_elevation):
			highlighted_cells[cell.cube_coord] = Color(0.8, 0.0, 0.0, 0.3)
	
	queue_redraw()

# ============================================================================
# BACKGROUND ALIGNMENT HELPERS
# ============================================================================

## Calculates the world bounds of the grid
func get_grid_world_bounds() -> Rect2:
	if grid == null or grid.get_cell_count() == 0:
		return Rect2()
	
	var first := true
	var min_pos := Vector2.ZERO
	var max_pos := Vector2.ZERO
	
	for cell in grid.get_all_cells():
		var world_pos := _get_cached_world_position(cell.cube_coord)
		if first:
			min_pos = world_pos
			max_pos = world_pos
			first = false
		else:
			min_pos.x = min(min_pos.x, world_pos.x)
			min_pos.y = min(min_pos.y, world_pos.y)
			max_pos.x = max(max_pos.x, world_pos.x)
			max_pos.y = max(max_pos.y, world_pos.y)
	
	# Expand by hex size to include edges
	var size := max_pos - min_pos + Vector2(hex_size * 2, hex_size * 2)
	var pos := min_pos - Vector2(hex_size, hex_size)
	
	return Rect2(pos, size)

## Auto-aligns the background to fit the grid
func auto_align_background() -> void:
	if background_texture == null or grid == null:
		return
	
	var grid_bounds := get_grid_world_bounds()
	var texture_size := background_texture.get_size()
	
	# Calculate scale to fit grid
	var scale_x := grid_bounds.size.x / texture_size.x
	var scale_y := grid_bounds.size.y / texture_size.y
	background_scale = max(scale_x, scale_y)
	
	# Center on grid
	background_offset = grid_bounds.position + grid_bounds.size / 2.0
	
	queue_redraw()
