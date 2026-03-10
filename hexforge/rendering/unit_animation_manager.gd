## HexForge/Rendering/UnitAnimationManager
## Manages all unit animations on the battlefield
## Coordinates movement, combat, and spawn animations
## Integrates with BattleController for seamless animation playback

class_name UnitAnimationManager
extends Node2D

# ============================================================================
# SIGNALS
# ============================================================================

signal animation_started(unit_id: String, animation_type: String)
signal animation_completed(unit_id: String, animation_type: String)
signal all_animations_complete()

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var hex_size: float = 32.0
@export var auto_start_animations: bool = true

# ============================================================================
# STATE
# ============================================================================

## Unit visuals: unit_id -> UnitVisual
var _unit_visuals: Dictionary = {}

## Animation queue for sequential playback
var _animation_queue: Array[Dictionary] = []

## Currently playing animation
var _is_playing: bool = false

## Pending callbacks for completed animations
var _pending_callbacks: Array[Callable] = []

# ============================================================================
# UNIT REGISTRATION
# ============================================================================

## Creates and registers a new unit visual
func spawn_unit(unit_id: String, unit_type: String, side: String, 
				cube: Vector3i, elevation: int = 0) -> UnitVisual:
	
	# Remove existing if present
	if _unit_visuals.has(unit_id):
		remove_unit(unit_id)
	
	# Create new unit visual
	var visual := UnitVisual.new(unit_id, unit_type, side)
	visual.name = "Unit_" + unit_id
	visual.set_cube(cube, hex_size, elevation)
	
	add_child(visual)
	_unit_visuals[unit_id] = visual
	
	# Play spawn animation
	visual.animate_spawn()
	
	return visual

## Removes a unit visual
func remove_unit(unit_id: String) -> void:
	if _unit_visuals.has(unit_id):
		var visual: UnitVisual = _unit_visuals[unit_id]
		_unit_visuals.erase(unit_id)
		visual.queue_free()

## Gets a unit visual by ID
func get_unit_visual(unit_id: String) -> UnitVisual:
	return _unit_visuals.get(unit_id)

## Checks if a unit has a visual
func has_unit_visual(unit_id: String) -> bool:
	return _unit_visuals.has(unit_id)

## Clears all unit visuals
func clear_all_units() -> void:
	for visual in _unit_visuals.values():
		visual.queue_free()
	_unit_visuals.clear()
	_animation_queue.clear()

# ============================================================================
# ANIMATION PLAYBACK
# ============================================================================

## Animates a unit moving to a new position
func animate_move(unit_id: String, target_cube: Vector3i, target_elevation: int = 0,
				  on_complete: Callable = Callable()) -> void:
	
	var visual := get_unit_visual(unit_id)
	if visual == null:
		push_warning("UnitAnimationManager: No visual found for unit %s" % unit_id)
		if on_complete.is_valid():
			on_complete.call()
		return
	
	var world_pos := HexMath.cube_to_world(target_cube, hex_size)
	
	_queue_animation({
		"type": "move",
		"unit_id": unit_id,
		"visual": visual,
		"target_pos": world_pos,
		"target_elevation": target_elevation,
		"on_complete": on_complete
	})

## Animates a unit moving along a path (multiple hexes)
func animate_path_move(unit_id: String, path: Array[Vector3i],
					   on_complete: Callable = Callable()) -> void:
	
	var visual := get_unit_visual(unit_id)
	if visual == null or path.is_empty():
		if on_complete.is_valid():
			on_complete.call()
		return
	
	_queue_animation({
		"type": "path",
		"unit_id": unit_id,
		"visual": visual,
		"path": path.duplicate(),
		"on_complete": on_complete
	})

## Animates a unit attacking another unit
func animate_attack(attacker_id: String, defender_id: String,
					on_complete: Callable = Callable()) -> void:
	
	var attacker := get_unit_visual(attacker_id)
	var defender := get_unit_visual(defender_id)
	
	if attacker == null:
		push_warning("UnitAnimationManager: No visual found for attacker %s" % attacker_id)
		if on_complete.is_valid():
			on_complete.call()
		return
	
	var target_pos := defender.position if defender else attacker.position
	
	_queue_animation({
		"type": "attack",
		"unit_id": attacker_id,
		"visual": attacker,
		"target_pos": target_pos,
		"defender_id": defender_id,
		"on_complete": on_complete
	})

## Animates a unit taking damage
func animate_hit(unit_id: String, on_complete: Callable = Callable()) -> void:
	var visual := get_unit_visual(unit_id)
	if visual == null:
		if on_complete.is_valid():
			on_complete.call()
		return
	
	_queue_animation({
		"type": "hit",
		"unit_id": unit_id,
		"visual": visual,
		"on_complete": on_complete
	})

## Animates a unit being defeated
func animate_defeat(unit_id: String, on_complete: Callable = Callable()) -> void:
	var visual := get_unit_visual(unit_id)
	if visual == null:
		if on_complete.is_valid():
			on_complete.call()
		return
	
	_queue_animation({
		"type": "defeat",
		"unit_id": unit_id,
		"visual": visual,
		"on_complete": on_complete
	})

## Immediately sets a unit's position (no animation)
func teleport_unit(unit_id: String, cube: Vector3i, elevation: int = 0) -> void:
	var visual := get_unit_visual(unit_id)
	if visual:
		visual.skip_animations()
		visual.set_cube(cube, hex_size, elevation)

## Skips all pending and current animations
func skip_all_animations() -> void:
	_animation_queue.clear()
	for visual in _unit_visuals.values():
		visual.skip_animations()
	_is_playing = false

# ============================================================================
# ANIMATION QUEUE
# ============================================================================

func _queue_animation(anim_data: Dictionary) -> void:
	_animation_queue.append(anim_data)
	
	if auto_start_animations and not _is_playing:
		_process_queue()

func _process_queue() -> void:
	if _animation_queue.is_empty():
		_is_playing = false
		all_animations_complete.emit()
		return
	
	_is_playing = true
	var anim := _animation_queue.pop_front()
	
	var anim_type: String = anim["type"]
	var unit_id: String = anim["unit_id"]
	var visual: UnitVisual = anim["visual"]
	var on_complete: Callable = anim.get("on_complete", Callable())
	
	animation_started.emit(unit_id, anim_type)
	
	var wrapped_callback := func():
		animation_completed.emit(unit_id, anim_type)
		if on_complete.is_valid():
			on_complete.call()
		_process_queue()
	
	match anim_type:
		"move":
			var target_pos: Vector2 = anim["target_pos"]
			var elevation: int = anim["target_elevation"]
			visual.animate_move(target_pos, elevation, wrapped_callback)
		
		"path":
			var path: Array[Vector3i] = anim["path"]
			visual.animate_path(path, hex_size, wrapped_callback)
		
		"attack":
			var target_pos: Vector2 = anim["target_pos"]
			visual.animate_attack(target_pos, wrapped_callback)
		
		"hit":
			visual.animate_hit(wrapped_callback)
		
		"defeat":
			visual.animate_defeat(func():
				remove_unit(unit_id)
				animation_completed.emit(unit_id, anim_type)
				if on_complete.is_valid():
					on_complete.call()
				_process_queue()
			)
		
		_:
			push_warning("Unknown animation type: %s" % anim_type)
			wrapped_callback.call()

## Starts processing the animation queue if not already playing
func start_animations() -> void:
	if not _is_playing:
		_process_queue()

## Checks if any animations are currently playing or queued
func is_animating() -> bool:
	return _is_playing or not _animation_queue.is_empty()

## Gets the number of pending animations in queue
func get_queue_length() -> int:
	return _animation_queue.size()

# ============================================================================
# SELECTION
# ============================================================================

## Selects a unit (shows selection ring)
func select_unit(unit_id: String) -> void:
	# Deselect all first
	clear_selection()
	
	var visual := get_unit_visual(unit_id)
	if visual:
		visual.set_selected(true)

## Deselects all units
func clear_selection() -> void:
	for visual in _unit_visuals.values():
		visual.set_selected(false)

## Gets the currently selected unit ID (or empty string if none)
func get_selected_unit() -> String:
	for unit_id in _unit_visuals.keys():
		var visual: UnitVisual = _unit_visuals[unit_id]
		if visual.get_selected():
			return unit_id
	return ""

# ============================================================================
# UTILITY
# ============================================================================

## Gets the cube position of a unit visual
func get_unit_cube(unit_id: String) -> Vector3i:
	var visual := get_unit_visual(unit_id)
	return visual.current_cube if visual else Vector3i.MAX

## Gets all unit IDs
func get_all_unit_ids() -> Array[String]:
	var result: Array[String] = []
	result.assign(_unit_visuals.keys())
	return result

## Checks if a cube is occupied by a unit visual
func is_cube_occupied(cube: Vector3i) -> bool:
	for visual in _unit_visuals.values():
		if visual.current_cube == cube:
			return true
	return false

## Gets the unit ID at a cube (or empty string)
func get_unit_at_cube(cube: Vector3i) -> String:
	for unit_id in _unit_visuals.keys():
		var visual: UnitVisual = _unit_visuals[unit_id]
		if visual.current_cube == cube:
			return unit_id
	return ""

## Updates hex size (recalculates all positions)
func set_hex_size(new_size: float) -> void:
	hex_size = new_size
	for visual in _unit_visuals.values():
		visual.set_cube(visual.current_cube, hex_size)
