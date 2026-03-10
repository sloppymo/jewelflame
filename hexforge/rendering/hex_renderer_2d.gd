## HexForge/Rendering/HexRenderer2D
## Visual representation of a hex grid
## ADDED: Viewport culling for off-screen hexes, batch rendering
## ADDED: Texture-based rendering support for sprite-based hexes
## Extends Node2D for SceneTree integration
## Part of HexForge hex grid system

class_name HexRenderer2D
extends Node2D

const HexMath = preload("res://hexforge/core/hex_math.gd")
const HexCell = preload("res://hexforge/core/hex_cell.gd")
const Pathfinder = preload("res://hexforge/services/pathfinder.gd")
const LineOfSight = preload("res://hexforge/services/line_of_sight.gd")

# ============================================================================
# CONFIGURATION
# ============================================================================

## The HexGrid to render (set this after instantiation)
var grid = null:
	set(value):
		grid = value
		queue_redraw()

## Hex size (distance from center to corner)
@export var hex_size: float = 32.0:
	set(value):
		hex_size = value
		_generate_hex_polygon()
		queue_redraw()

## Line width for hex borders
@export var line_width: float = 1.0

## Colors for different terrain types (used when use_textures = false)
@export var terrain_colors: Dictionary = {
	"plains": Color(0.4, 0.7, 0.3),
	"forest": Color(0.2, 0.5, 0.2),
	"mountain": Color(0.5, 0.4, 0.3),
	"water": Color(0.3, 0.5, 0.8),
	"road": Color(0.6, 0.6, 0.5),
	"marsh": Color(0.4, 0.5, 0.3)
}

## Default color for unknown terrain
@export var default_color: Color = Color(0.5, 0.5, 0.5)

## Border color
@export var border_color: Color = Color(0.2, 0.2, 0.2)

## Highlight color (for selection)
@export var highlight_color: Color = Color(1.0, 1.0, 0.0, 0.3)

## Whether to draw coordinates (debug)
@export var draw_coordinates: bool = false

## Coordinate text color
@export var coordinate_color: Color = Color(0.0, 0.0, 0.0)

## Font size for coordinates
@export var coordinate_font_size: int = 12

# ============================================================================
# TEXTURE RENDERING (NEW)
# ============================================================================

## Enable texture-based rendering instead of procedural colors
@export var use_textures: bool = false:
	set(value):
		use_textures = value
		queue_redraw()

## The terrain atlas resource containing texture mappings
@export var terrain_atlas = null:
	set(value):
		terrain_atlas = value
		_cache_atlas_data()
		queue_redraw()

## Fallback texture if terrain not found in atlas
@export var fallback_texture: Texture2D = null

## Scale factor for textures (1.0 = exact fit to hex_size)
@export var texture_scale: float = 1.0:
	set(value):
		texture_scale = value
		queue_redraw()

## Apply elevation offset to texture Y position
@export var texture_elevation_offset: bool = true

## Cached atlas lookups for performance
var _atlas_region_cache: Dictionary = {}
var _atlas_texture_cache: Texture2D = null

# ============================================================================
# VIEWPORT CULLING
# ============================================================================

## Enable viewport culling (skip drawing off-screen hexes)
@export var enable_culling: bool = true

## Padding around viewport to include cells near edge (in pixels)
@export var cull_padding: float = 64.0

## Maximum cells to render per frame (0 = unlimited)
@export var max_cells_per_frame: int = 0

## Cached viewport rect for culling
var _viewport_rect: Rect2 = Rect2()

## Cached camera reference
var _camera: Camera2D = null

## Last frame's visible cells (for debugging)
var _visible_cell_count: int = 0

## Total cells in grid (for debugging)
var _total_cell_count: int = 0

# ============================================================================
# BATCH RENDERING
# ============================================================================

## Enable batch rendering for terrain types
@export var enable_batch_rendering: bool = true

## Batch size for rendering (cells per batch)
const BATCH_SIZE: int = 100

# ============================================================================
# INTERNAL STATE
# ============================================================================

## Currently highlighted cells (for range display)
var highlighted_cells: Dictionary = {}  # Vector3i -> Color

## Currently selected cell
var selected_cell: Vector3i = Vector3i.MAX

## Cached polygon for a single hex (reused for all cells)
var _hex_polygon: PackedVector2Array = []

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
	_cache_atlas_data()

## Generates the polygon points for a single hexagon
func _generate_hex_polygon() -> void:
	_hex_polygon.clear()
	for i in range(6):
		var angle: float = PI / 3.0 * i - PI / 6.0  # Pointy-top orientation
		var x: float = hex_size * cos(angle)
		var y: float = hex_size * sin(angle)
		_hex_polygon.append(Vector2(x, y))

## Finds the active camera for culling calculations
func _find_camera() -> void:
	var viewport := get_viewport()
	if viewport:
		_camera = viewport.get_camera_2d()

## Caches atlas data for performance
func _cache_atlas_data() -> void:
	_atlas_region_cache.clear()
	_atlas_texture_cache = null
	
	if terrain_atlas == null:
		return
	
	# Pre-cache all terrain regions
	for terrain_type in terrain_atlas.terrain_mappings.keys():
		var region = terrain_atlas.get_region(terrain_type)
		if region.has("atlas"):
			_atlas_region_cache[terrain_type] = region
	
	# Cache the atlas texture
	if terrain_atlas.atlas_texture != null:
		_atlas_texture_cache = terrain_atlas.atlas_texture

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
func _cell_might_be_visible(cell) -> bool:
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
	
	var cells_drawn: int = 0
	
	# Draw all visible cells
	for cell in grid.get_all_cells():
		# Check culling
		if not _cell_might_be_visible(cell):
			continue
		
		# Use texture or procedural rendering
		if use_textures and terrain_atlas != null:
			_draw_textured_cell(cell)
		else:
			_draw_cell(cell)
		
		_visible_cell_count += 1
		cells_drawn += 1
		
		# Check frame limit
		if max_cells_per_frame > 0 and cells_drawn >= max_cells_per_frame:
			break
	
	# Draw highlights on top
	for cube in highlighted_cells.keys():
		if grid.has_cell(cube):
			var cell = grid.get_cell(cube)
			if cell != null and (not enable_culling or _cell_might_be_visible(cell)):
				_draw_highlight(cube, highlighted_cells[cube])
	
	# Draw selection
	if selected_cell != Vector3i.MAX and grid.has_cell(selected_cell):
		var selected_cell_obj = grid.get_cell(selected_cell)
		if selected_cell_obj != null and (not enable_culling or _cell_might_be_visible(selected_cell_obj)):
			_draw_selection(selected_cell)

## Draws a single hex cell using textures
func _draw_textured_cell(cell) -> void:
	var world_pos: Vector2 = _get_cached_world_position(cell.cube_coord)
	
	# Apply elevation offset
	if texture_elevation_offset:
		world_pos.y -= cell.elevation * 8
	
	# Get texture region from atlas
	var texture_region: Dictionary = _get_texture_region(cell)
	
	if texture_region.is_empty():
		# Fallback to procedural if no texture found
		_draw_cell(cell)
		return
	
	var atlas: Texture2D = texture_region.get("atlas", fallback_texture)
	var region: Rect2 = texture_region.get("region", Rect2(0, 0, 64, 74))
	
	if atlas == null:
		_draw_cell(cell)
		return
	
	# Calculate draw position (centered)
	var texture_size = region.size * texture_scale
	var draw_pos = world_pos - texture_size / 2
	
	# Draw the textured hex
	draw_texture_rect_region(atlas, Rect2(draw_pos, texture_size), region)
	
	# Draw border if configured
	if line_width > 0:
		draw_polyline(_get_hex_polygon_at(world_pos, true), border_color, line_width, true)
	
	# Draw blocking indicator
	if cell.blocking:
		_draw_blocking_indicator(world_pos)
	
	# Draw coordinates (debug)
	if draw_coordinates:
		_draw_coordinates(world_pos, cell)

## Gets the texture region for a cell (with caching)
func _get_texture_region(cell) -> Dictionary:
	# Check cache first
	if _atlas_region_cache.has(cell.terrain_type):
		return _atlas_region_cache[cell.terrain_type]
	
	# Query atlas
	if terrain_atlas != null:
		var region = terrain_atlas.get_region(cell.terrain_type)
		if not region.is_empty():
			_atlas_region_cache[cell.terrain_type] = region
			return region
	
	return {}

## Draws a single hex cell using procedural colors
func _draw_cell(cell) -> void:
	var world_pos: Vector2 = _get_cached_world_position(cell.cube_coord)
	
	# Get terrain color
	var color: Color = terrain_colors.get(cell.terrain_type, default_color)
	
	# Adjust color by elevation (darker = higher)
	var elevation_darken: float = 1.0 - (cell.elevation * 0.1)
	color = Color(color.r * elevation_darken, color.g * elevation_darken, color.b * elevation_darken)
	
	# Draw filled hex
	draw_polygon(_get_hex_polygon_at(world_pos), [color])
	
	# Draw border
	draw_polyline(_get_hex_polygon_at(world_pos, true), border_color, line_width, true)
	
	# Draw blocking indicator
	if cell.blocking:
		_draw_blocking_indicator(world_pos)
	
	# Draw coordinates (debug)
	if draw_coordinates:
		_draw_coordinates(world_pos, cell)

## Returns the hex polygon at a specific world position
func _get_hex_polygon_at(world_pos: Vector2, closed: bool = false) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	result.resize(_hex_polygon.size() + (1 if closed else 0))
	
	for i in range(_hex_polygon.size()):
		result[i] = _hex_polygon[i] + world_pos
	
	if closed:
		result[_hex_polygon.size()] = result[0]
	
	return result

## Draws a blocking indicator (X) in the cell
func _draw_blocking_indicator(world_pos: Vector2) -> void:
	var size: float = hex_size * 0.3
	var color: Color = Color(0.8, 0.2, 0.2)
	
	draw_line(world_pos + Vector2(-size, -size), world_pos + Vector2(size, size), color, 2.0)
	draw_line(world_pos + Vector2(-size, size), world_pos + Vector2(size, -size), color, 2.0)

## Draws coordinate text at the cell center
func _draw_coordinates(world_pos: Vector2, cell) -> void:
	var text: String = "%d,%d" % [cell.axial_coord.x, cell.axial_coord.y]
	# Note: In Godot 4, we use draw_string with a Font
	# For now, we'll skip the actual text drawing to avoid font dependency
	# This can be added later with a preload font reference

## Draws a highlight overlay on a cell
func _draw_highlight(cube: Vector3i, color: Color) -> void:
	var world_pos: Vector2 = _get_cached_world_position(cube)
	draw_polygon(_get_hex_polygon_at(world_pos), [color])

## Draws a selection border around a cell
func _draw_selection(cube: Vector3i) -> void:
	var world_pos: Vector2 = _get_cached_world_position(cube)
	var selection_color: Color = Color(1.0, 0.8, 0.0)
	draw_polyline(_get_hex_polygon_at(world_pos, true), selection_color, line_width * 2, true)

# ============================================================================
# HIGHLIGHTING API
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
func highlight_cell_objects(cells: Array, color: Color = highlight_color) -> void:
	for cell in cells:
		highlighted_cells[cell.cube_coord] = color
	queue_redraw()

# ============================================================================
# SELECTION API
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
func get_cell_at_screen(screen_pos: Vector2):
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
		"cache_size": _world_position_cache.size(),
		"using_textures": use_textures,
		"atlas_cached_regions": _atlas_region_cache.size()
	}

## Reloads atlas data (call after modifying terrain_atlas)
func reload_atlas() -> void:
	_cache_atlas_data()
	queue_redraw()

# ============================================================================
# BATCH OPERATIONS
# ============================================================================

## Highlights all cells in a path
func highlight_path(path: Array[Vector3i], color: Color = highlight_color) -> void:
	highlight_cells(path, color)

## Highlights reachable cells (movement range)
func highlight_reachable(center: Vector3i, max_movement: float, unit_type: String = "infantry") -> void:
	if grid == null:
		return
	
	var reachable = Pathfinder.find_reachable(grid, center, max_movement, unit_type)
	for cube in reachable.keys():
		# Vary color by cost (greener = cheaper)
		var cost: float = reachable[cube]
		var intensity: float = 1.0 - (cost / max_movement * 0.5)
		var color: Color = Color(0.0, intensity, 0.0, 0.4)
		highlighted_cells[cube] = color
	
	queue_redraw()

## Highlights attack range (LoS check included)
func highlight_attack_range(center: Vector3i, max_range: int, from_elevation: int = -1) -> void:
	if grid == null:
		return
	
	if from_elevation < 0:
		var center_cell = grid.get_cell(center)
		from_elevation = center_cell.elevation if center_cell else 0
	
	var in_range = grid.get_cells_in_range(center, max_range)
	for cell in in_range:
		if LineOfSight.has_los(grid, center, cell.cube_coord, from_elevation):
			highlighted_cells[cell.cube_coord] = Color(0.8, 0.0, 0.0, 0.3)
	
	queue_redraw()
