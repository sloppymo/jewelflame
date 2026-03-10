## HexForge/Rendering/FogOfWarRenderer
## Dynamic fog of war system for tactical battles
## Shows/hides cells based on line of sight from units
## Part of HexForge rendering system

class_name FogOfWarRenderer
extends Node2D

# ============================================================================
# SIGNALS
# ============================================================================

signal visibility_changed(changed_cells: Array[Vector3i])
signal cell_revealed(cube: Vector3i)
signal cell_hidden(cube: Vector3i)

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var grid: HexGrid = null:
	set(value):
		grid = value
		_reset_visibility()
		queue_redraw()

@export var hex_size: float = 32.0:
	set(value):
		hex_size = value
		queue_redraw()

## Fog colors
@export var unexplored_color: Color = Color(0.1, 0.1, 0.15, 1.0)  # Dark blue-black
@export var hidden_color: Color = Color(0.2, 0.2, 0.25, 0.85)      # Semi-transparent
@export var visible_color: Color = Color(1.0, 1.0, 1.0, 0.0)        # Fully transparent

## Fog transition
@export var enable_transitions: bool = true
@export var transition_duration: float = 0.3

## Visibility settings
@export var base_vision_range: int = 5
@export var elevation_bonus_per_level: int = 1

# ============================================================================
# STATE
# ============================================================================

## Cell states: 0 = unexplored, 1 = explored but hidden, 2 = visible
var _cell_states: Dictionary = {}  # Vector3i -> int

## Cached hex polygon
var _hex_polygon: PackedVector2Array = []

## Visibility sources: unit_id -> {cube, range, elevation}
var _visibility_sources: Dictionary = {}

## Smooth opacity values for transitions
var _cell_opacity: Dictionary = {}  # Vector3i -> float (0.0 to 1.0)

## Active tweens for transitions
var _active_tweens: Dictionary = {}  # Vector3i -> Tween

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_generate_hex_polygon()

func _generate_hex_polygon() -> void:
	_hex_polygon.clear()
	for i in range(6):
		var angle: float = PI / 3.0 * i - PI / 6.0
		var x: float = hex_size * cos(angle)
		var y: float = hex_size * sin(angle)
		_hex_polygon.append(Vector2(x, y))

func _reset_visibility() -> void:
	_cell_states.clear()
	_cell_opacity.clear()
	_kill_all_tweens()
	
	if grid == null:
		return
	
	# Initialize all cells as unexplored
	for cell in grid.get_all_cells():
		_cell_states[cell.cube_coord] = 0
		_cell_opacity[cell.cube_coord] = 1.0  # Fully fogged

# ============================================================================
# VISIBILITY SOURCES
# ============================================================================

## Adds a visibility source (typically a unit)
## @param source_id: Unique identifier for this source
## @param cube: Position of the source
## @param vision_range: How far the source can see
## @param elevation: Elevation of the source (adds to vision range)
func add_visibility_source(source_id: String, cube: Vector3i, 
						   vision_range: int = -1, elevation: int = 0) -> void:
	
	if vision_range < 0:
		vision_range = base_vision_range + (elevation * elevation_bonus_per_level)
	
	_visibility_sources[source_id] = {
		"cube": cube,
		"range": vision_range,
		"elevation": elevation
	}
	
	_update_visibility()

## Updates a visibility source's position
func update_visibility_source(source_id: String, cube: Vector3i, elevation: int = -1) -> void:
	if not _visibility_sources.has(source_id):
		return
	
	var source: Dictionary = _visibility_sources[source_id]
	source["cube"] = cube
	
	if elevation >= 0:
		source["elevation"] = elevation
		source["range"] = base_vision_range + (elevation * elevation_bonus_per_level)
	
	_update_visibility()

## Removes a visibility source
func remove_visibility_source(source_id: String) -> void:
	if _visibility_sources.has(source_id):
		_visibility_sources.erase(source_id)
		_update_visibility()

## Clears all visibility sources
func clear_visibility_sources() -> void:
	_visibility_sources.clear()
	_update_visibility()

# ============================================================================
# VISIBILITY CALCULATION
# ============================================================================

func _update_visibility() -> void:
	if grid == null:
		return
	
	var changed_cells: Array[Vector3i] = []
	var newly_visible: Array[Vector3i] = []
	var newly_hidden: Array[Vector3i] = []
	
	# Calculate which cells should be visible
	var target_visibility: Dictionary = {}  # Vector3i -> bool
	
	for cell in grid.get_all_cells():
		var cube: Vector3i = cell.cube_coord
		var should_be_visible := _should_cell_be_visible(cube)
		target_visibility[cube] = should_be_visible
		
		var current_state: int = _cell_states.get(cube, 0)
		
		if should_be_visible:
			if current_state != 2:
				_cell_states[cube] = 2  # Visible
				newly_visible.append(cube)
				changed_cells.append(cube)
		else:
			if current_state == 0:
				# Still unexplored
				pass
			elif current_state == 2:
				_cell_states[cube] = 1  # Explored but hidden
				newly_hidden.append(cube)
				changed_cells.append(cube)
			# If already 1, no change
	
	# Apply transitions
	if enable_transitions:
		_apply_transitions(target_visibility)
	else:
		for cube in changed_cells:
			_cell_opacity[cube] = 0.0 if target_visibility.get(cube, false) else 1.0
	
	queue_redraw()
	
	# Emit signals
	if not changed_cells.is_empty():
		visibility_changed.emit(changed_cells)
		
		for cube in newly_visible:
			cell_revealed.emit(cube)
		
		for cube in newly_hidden:
			cell_hidden.emit(cube)

func _should_cell_be_visible(cube: Vector3i) -> bool:
	for source in _visibility_sources.values():
		var source_cube: Vector3i = source["cube"]
		var source_range: int = source["range"]
		var source_elevation: int = source["elevation"]
		
		# Check distance
		if HexMath.distance(source_cube, cube) > source_range:
			continue
		
		# Check line of sight (if elevation system is used)
		if source_elevation > 0:
			if not LineOfSight.has_los(grid, source_cube, cube, source_elevation):
				continue
		
		return true
	
	return false

func _apply_transitions(target_visibility: Dictionary) -> void:
	for cube in target_visibility.keys():
		var target_visible: bool = target_visibility[cube]
		var target_opacity: float = 0.0 if target_visible else 1.0
		var current_opacity: float = _cell_opacity.get(cube, 1.0)
		
		if abs(current_opacity - target_opacity) < 0.01:
			continue
		
		# Kill existing tween
		if _active_tweens.has(cube):
			var old_tween: Tween = _active_tweens[cube]
			if old_tween.is_valid():
				old_tween.kill()
			_active_tweens.erase(cube)
		
		# Create new tween
		var tween := create_tween()
		tween.tween_method(
			func(value: float): _cell_opacity[cube] = value,
			current_opacity,
			target_opacity,
			transition_duration
		)
		
		_active_tweens[cube] = tween
		
		tween.finished.connect(func():
			if _active_tweens.has(cube) and _active_tweens[cube] == tween:
				_active_tweens.erase(cube)
		)

func _kill_all_tweens() -> void:
	for tween in _active_tweens.values():
		if tween.is_valid():
			tween.kill()
	_active_tweens.clear()

# ============================================================================
# RENDERING
# ============================================================================

func _draw() -> void:
	if grid == null:
		return
	
	for cell in grid.get_all_cells():
		var cube: Vector3i = cell.cube_coord
		var state: int = _cell_states.get(cube, 0)
		
		if state == 2:
			continue  # Fully visible, don't draw fog
		
		var world_pos := HexMath.cube_to_world(cube, hex_size)
		var color := _get_fog_color(cube, state)
		
		if color.a > 0.01:
			_draw_fog_hex(world_pos, color)

func _get_fog_color(cube: Vector3i, state: int) -> Color:
	var base_color: Color
	
	match state:
		0: base_color = unexplored_color
		1: base_color = hidden_color
		2: return visible_color  # Fully visible
		_: base_color = unexplored_color
	
	# Apply opacity for transitions
	var opacity: float = _cell_opacity.get(cube, 1.0)
	return Color(base_color.r, base_color.g, base_color.b, base_color.a * opacity)

func _draw_fog_hex(world_pos: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for point in _hex_polygon:
		points.append(point + world_pos)
	
	draw_polygon(points, [color])

# ============================================================================
# PUBLIC API
# ============================================================================

## Reveals all cells (for debug or map reveal effects)
func reveal_all() -> void:
	if grid == null:
		return
	
	var changed: Array[Vector3i] = []
	
	for cell in grid.get_all_cells():
		var cube: Vector3i = cell.cube_coord
		if _cell_states.get(cube, 0) != 2:
			_cell_states[cube] = 2
			_cell_opacity[cube] = 0.0
			changed.append(cube)
	
	queue_redraw()
	
	if not changed.is_empty():
		visibility_changed.emit(changed)

## Hides all cells
func hide_all() -> void:
	if grid == null:
		return
	
	var changed: Array[Vector3i] = []
	
	for cell in grid.get_all_cells():
		var cube: Vector3i = cell.cube_coord
		if _cell_states.get(cube, 0) != 1:
			_cell_states[cube] = 1
			_cell_opacity[cube] = 1.0
			changed.append(cube)
	
	queue_redraw()
	
	if not changed.is_empty():
		visibility_changed.emit(changed)

## Resets to unexplored state
func reset_fog() -> void:
	_reset_visibility()
	queue_redraw()

## Checks if a cell is visible
func is_visible(cube: Vector3i) -> bool:
	return _cell_states.get(cube, 0) == 2

## Checks if a cell has been explored
func is_explored(cube: Vector3i) -> bool:
	return _cell_states.get(cube, 0) >= 1

## Gets the visibility state of a cell (0=unexplored, 1=explored, 2=visible)
func get_visibility_state(cube: Vector3i) -> int:
	return _cell_states.get(cube, 0)

## Gets all visible cells
func get_visible_cells() -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for cube in _cell_states.keys():
		if _cell_states[cube] == 2:
			result.append(cube)
	return result

## Gets all explored cells
func get_explored_cells() -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for cube in _cell_states.keys():
		if _cell_states[cube] >= 1:
			result.append(cube)
	return result

# ============================================================================
# UTILITY
# ============================================================================

func get_stats() -> Dictionary:
	var total := grid.get_cell_count() if grid else 0
	var visible := 0
	var explored := 0
	
	for state in _cell_states.values():
		if state == 2:
			visible += 1
			explored += 1
		elif state == 1:
			explored += 1
	
	return {
		"total_cells": total,
		"visible_cells": visible,
		"explored_cells": explored,
		"unexplored_cells": total - explored,
		"sources_count": _visibility_sources.size()
	}
