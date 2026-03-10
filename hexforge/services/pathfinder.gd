## HexForge/Services/Pathfinder
## A* pathfinding with binary heap priority queue
## ADDED: Path caching for repeated queries
## Static methods - pass HexGrid as parameter
## Part of HexForge hex grid system
## Phase: 4

class_name Pathfinder
extends RefCounted

const HexGrid = preload("res://hexforge/core/hex_grid.gd")
const HexCell = preload("res://hexforge/core/hex_cell.gd")
const HexMath = preload("res://hexforge/core/hex_math.gd")

# ============================================================================
# PATH CACHE
# ============================================================================

## Cache for storing recent pathfinding results
## Key format: "start_x,start_y,start_z:goal_x,goal_y,goal_z:unit_type:max_range"
## Value: {path: Array[Vector3i], timestamp: int, cost: float}
static var _path_cache: Dictionary = {}

## Maximum number of cached paths
const MAX_CACHE_SIZE: int = 100

## Cache entry TTL in seconds
const CACHE_TTL_SECONDS: int = 30

## Enable/disable caching
static var cache_enabled: bool = true

# ============================================================================
# CACHE MANAGEMENT
# ============================================================================

## Clears the path cache
static func clear_cache() -> void:
	_path_cache.clear()

## Returns the current cache size
static func get_cache_size() -> int:
	return _path_cache.size()

## Disables path caching
static func disable_cache() -> void:
	cache_enabled = false
	clear_cache()

## Enables path caching
static func enable_cache() -> void:
	cache_enabled = true

## Generates a cache key for a path query
static func _make_cache_key(
	start: Vector3i,
	goal: Vector3i,
	unit_type: String,
	max_range: int
) -> String:
	return "%d,%d,%d:%d,%d,%d:%s:%d" % [
		start.x, start.y, start.z,
		goal.x, goal.y, goal.z,
		unit_type, max_range
	]

## Cleans expired cache entries
static func _clean_expired_cache() -> void:
	var now: int = Time.get_ticks_msec()
	var expired_keys: Array[String] = []
	
	for key in _path_cache.keys():
		var entry: Dictionary = _path_cache[key]
		var age_ms: int = now - entry.timestamp
		if age_ms > CACHE_TTL_SECONDS * 1000:
			expired_keys.append(key)
	
	for key in expired_keys:
		_path_cache.erase(key)

## Adds a path to the cache
static func _cache_path(
	key: String,
	path: Array[Vector3i],
	cost: float
) -> void:
	if _path_cache.size() >= MAX_CACHE_SIZE:
		# Remove oldest entry (simple FIFO)
		var oldest_key: String = ""
		var oldest_time: int = Time.get_ticks_msec()
		
		for k in _path_cache.keys():
			var entry: Dictionary = _path_cache[k]
			if entry.timestamp < oldest_time:
				oldest_time = entry.timestamp
				oldest_key = k
		
		if oldest_key != "":
			_path_cache.erase(oldest_key)
	
	_path_cache[key] = {
		"path": path.duplicate(),
		"timestamp": Time.get_ticks_msec(),
		"cost": cost
	}

## Verifies that a cached path is still valid
static func _verify_path(grid, path: Array[Vector3i], unit_type: String) -> bool:
	if path.size() < 2:
		return true
	
	for i in range(path.size() - 1):
		var from_cube: Vector3i = path[i]
		var to_cube: Vector3i = path[i + 1]
		
		# Check cells still exist
		if not grid.has_cell(from_cube) or not grid.has_cell(to_cube):
			return false
		
		# Check movement is still possible
		var cost: float = grid.get_movement_cost_between(from_cube, to_cube, unit_type)
		if cost >= 999.0:
			return false
	
	return true

# ============================================================================
# BINARY HEAP IMPLEMENTATION
# ============================================================================

## Internal binary heap for priority queue operations
class BinaryHeap:
	var _data: Array[HeapNode] = []
	
	## Returns the number of elements in the heap
	func size() -> int:
		return _data.size()
	
	## Returns true if the heap is empty
	func is_empty() -> bool:
		return _data.is_empty()
	
	## Inserts a new node into the heap
	func push(cube: Vector3i, priority: float) -> void:
		var node := HeapNode.new(cube, priority)
		_data.append(node)
		_sift_up(_data.size() - 1)
	
	## Removes and returns the node with lowest priority
	func pop() -> Vector3i:
		if _data.is_empty():
			return Vector3i.ZERO
		
		var result: Vector3i = _data[0].cube
		
		# Move last element to root and sift down
		_data[0] = _data[_data.size() - 1]
		_data.resize(_data.size() - 1)
		
		if _data.size() > 0:
			_sift_down(0)
		
		return result
	
	## Returns the lowest priority without removing it
	func peek_priority() -> float:
		if _data.is_empty():
			return INF
		return _data[0].priority
	
	## Sifts a node up to maintain heap property
	func _sift_up(index: int) -> void:
		var node: HeapNode = _data[index]
		var parent_index: int = (index - 1) / 2
		
		while index > 0 and _data[parent_index].priority > node.priority:
			_data[index] = _data[parent_index]
			index = parent_index
			parent_index = (index - 1) / 2
		
		_data[index] = node
	
	## Sifts a node down to maintain heap property
	func _sift_down(index: int) -> void:
		var size: int = _data.size()
		var node: HeapNode = _data[index]
		
		while true:
			var left_child: int = 2 * index + 1
			var right_child: int = 2 * index + 2
			var smallest: int = index
			
			if left_child < size and _data[left_child].priority < _data[smallest].priority:
				smallest = left_child
			
			if right_child < size and _data[right_child].priority < _data[smallest].priority:
				smallest = right_child
			
			if smallest == index:
				break
			
			_data[index] = _data[smallest]
			index = smallest
		
		_data[index] = node

## Node stored in the binary heap
class HeapNode:
	var cube: Vector3i
	var priority: float
	
	func _init(p_cube: Vector3i, p_priority: float) -> void:
		cube = p_cube
		priority = p_priority

# ============================================================================
# A* PATHFINDING
# ============================================================================

## Finds a path from start to goal using A* algorithm
##

## @param start: Starting cube coordinates
## @param goal: Target cube coordinates
## @param unit_type: Unit type for movement cost calculation
## @param max_range: Maximum path length (0 = unlimited)
## @return Array[Vector3i]: Path from start to goal (inclusive), empty if no path
static func find_path(
	grid,
	start: Vector3i,
	goal: Vector3i,
	unit_type: String = "infantry",
	max_range: int = 0
) -> Array[Vector3i]:
	
	# Validate inputs
	if grid == null:
		push_error("Pathfinder.find_path: Grid is null")
		return []
	
	if not grid.has_cell(start) or not grid.has_cell(goal):
		push_error("Pathfinder.find_path: Start or goal not in grid")
		return []
	
	# Trivial case: start == goal
	if start == goal:
		return [start]
	
	# Check cache first
	if cache_enabled:
		_clean_expired_cache()
		var cache_key: String = _make_cache_key(start, goal, unit_type, max_range)
		if _path_cache.has(cache_key):
			var cached: Dictionary = _path_cache[cache_key]
			# Verify the cached path is still valid (grid may have changed)
			if _verify_path(grid, cached.path, unit_type):
				return cached.path.duplicate()
			else:
				# Path no longer valid, remove from cache
				_path_cache.erase(cache_key)
	
	# Data structures
	var open_set := BinaryHeap.new()
	var came_from: Dictionary = {}  # cube -> previous cube
	var g_score: Dictionary = {}     # cube -> cost from start
	var closed_set: Dictionary = {}  # cube -> true (already processed)
	
	# Initialize with start node
	open_set.push(start, 0.0)
	g_score[start] = 0.0
	
	while not open_set.is_empty():
		var current: Vector3i = open_set.pop()
		
		# Skip if already processed
		if closed_set.has(current):
			continue
		closed_set[current] = true
		
		# Check if we reached the goal
		if current == goal:
			var path := _reconstruct_path(came_from, goal)
			# Cache the result
			if cache_enabled:
				var cache_key: String = _make_cache_key(start, goal, unit_type, max_range)
				_cache_path(cache_key, path, g_score.get(goal, 0.0))
			return path
		
		# Check range limit
		if max_range > 0:
			var current_cost: float = g_score.get(current, INF)
			if current_cost >= max_range:
				continue
		
		# Explore neighbors
		for neighbor_cube in HexMath.neighbors(current):
			# Skip if not in grid
			if not grid.has_cell(neighbor_cube):
				continue
			
			# Skip if already processed
			if closed_set.has(neighbor_cube):
				continue
			
			# Calculate movement cost
			var move_cost: float = grid.get_movement_cost_between(current, neighbor_cube, unit_type)
			if move_cost >= 999.0:  # Impassable
				continue
			
			var tentative_g: float = g_score.get(current, INF) + move_cost
			
			# Check if this path is better
			if tentative_g < g_score.get(neighbor_cube, INF):
				came_from[neighbor_cube] = current
				g_score[neighbor_cube] = tentative_g
				
				# Calculate f_score = g_score + heuristic
				var h: float = _heuristic(neighbor_cube, goal)
				var f_score: float = tentative_g + h
				
				open_set.push(neighbor_cube, f_score)
	
	# No path found
	return []

## Heuristic function: cube distance (admissible for A*)
static func _heuristic(a: Vector3i, b: Vector3i) -> float:
	return float(HexMath.distance(a, b))

## Reconstructs the path from came_from map
static func _reconstruct_path(came_from: Dictionary, goal: Vector3i) -> Array[Vector3i]:
	var path: Array[Vector3i] = []
	var current: Vector3i = goal
	
	while came_from.has(current):
		path.append(current)
		current = came_from[current]
	
	path.append(current)  # Add start
	path.reverse()
	
	return path

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

## Returns true if a path exists between start and goal
static func has_path(
	grid,
	start: Vector3i,
	goal: Vector3i,
	unit_type: String = "infantry",
	max_range: int = 0
) -> bool:
	return not find_path(grid, start, goal, unit_type, max_range).is_empty()

## Calculates the total movement cost of a path
## Returns INF if any segment is invalid
static func calculate_path_cost(
	grid,
	path: Array[Vector3i],
	unit_type: String = "infantry"
) -> float:
	if path.size() < 2:
		return 0.0
	
	var total_cost: float = 0.0
	
	for i in range(path.size() - 1):
		var from_cube: Vector3i = path[i]
		var to_cube: Vector3i = path[i + 1]
		
		var cost: float = grid.get_movement_cost_between(from_cube, to_cube, unit_type)
		if cost >= 999.0:
			return INF
		
		total_cost += cost
	
	return total_cost

## Finds all reachable cells within a given movement range
## Uses Dijkstra's algorithm (A* without heuristic)
##
## @return Dictionary: cube -> total_cost to reach that cube
static func find_reachable(
	grid,
	start: Vector3i,
	max_movement: float,
	unit_type: String = "infantry"
) -> Dictionary:
	
	if not grid.has_cell(start):
		return {}
	
	var open_set := BinaryHeap.new()
	var g_score: Dictionary = {}
	var closed_set: Dictionary = {}
	
	open_set.push(start, 0.0)
	g_score[start] = 0.0
	
	while not open_set.is_empty():
		var current: Vector3i = open_set.pop()
		
		if closed_set.has(current):
			continue
		closed_set[current] = true
		
		var current_cost: float = g_score.get(current, INF)
		
		for neighbor_cube in HexMath.neighbors(current):
			if not grid.has_cell(neighbor_cube):
				continue
			
			if closed_set.has(neighbor_cube):
				continue
			
			var move_cost: float = grid.get_movement_cost_between(current, neighbor_cube, unit_type)
			if move_cost >= 999.0:
				continue
			
			var tentative_g: float = current_cost + move_cost
			
			# Skip if beyond movement range
			if tentative_g > max_movement:
				continue
			
			if tentative_g < g_score.get(neighbor_cube, INF):
				g_score[neighbor_cube] = tentative_g
				open_set.push(neighbor_cube, tentative_g)
	
	return g_score

## Returns all cells reachable within the given movement range
static func get_reachable_cells(
	grid,
	start: Vector3i,
	max_movement: float,
	unit_type: String = "infantry"
):
	var reachable = find_reachable(grid, start, max_movement, unit_type)
	var result: Array = []
	
	for cube in reachable.keys():
		var cell = grid.get_cell(cube)
		if cell != null:
			result.append(cell)
	
	return result

# ============================================================================
# TEST USAGE EXAMPLE
# ============================================================================
"""
# Test script for Pathfinder:

func test_pathfinder():
	var grid = HexGrid.new()
	
	# Create a simple 3x3 grid
	for q in range(-1, 2):
		for r in range(-1, 2):
			var cube = HexMath.axial_to_cube(Vector2i(q, r))
			grid.create_cell_cube(cube, "plains")
	
	# Add a wall
	grid.create_cell_cube(Vector3i(0, -1, 1), "mountain", 2, true)
	
	# Test basic path
	var path = Pathfinder.find_path(grid, Vector3i(-1, 1, 0), Vector3i(1, -1, 0))
	assert(path.size() > 0, "Should find a path around the wall")
	
	# Test path to self
	path = Pathfinder.find_path(grid, Vector3i(0, 0, 0), Vector3i(0, 0, 0))
	assert(path.size() == 1, "Path to self should be just the start")
	
	# Test blocked path
	# Create enclosed cell
	var enclosed_grid = HexGrid.new()
	enclosed_grid.create_cell_cube(Vector3i(0, 0, 0), "plains")
	enclosed_grid.create_cell_cube(Vector3i(1, -1, 0), "mountain", 2, true)
	enclosed_grid.create_cell_cube(Vector3i(1, 0, -1), "mountain", 2, true)
	enclosed_grid.create_cell_cube(Vector3i(0, 1, -1), "mountain", 2, true)
	enclosed_grid.create_cell_cube(Vector3i(-1, 1, 0), "mountain", 2, true)
	enclosed_grid.create_cell_cube(Vector3i(-1, 0, 1), "mountain", 2, true)
	enclosed_grid.create_cell_cube(Vector3i(0, -1, 1), "mountain", 2, true)
	enclosed_grid.create_cell_cube(Vector3i(2, -2, 0), "plains")
	
	path = Pathfinder.find_path(enclosed_grid, Vector3i(0, 0, 0), Vector3i(2, -2, 0))
	assert(path.is_empty(), "Should not find path through walls")
	
	# Test reachable cells
	var reachable = Pathfinder.find_reachable(grid, Vector3i(0, 0, 0), 2.0)
	assert(reachable.size() > 0, "Should find reachable cells")
	
	# Test caching
	var cached_path = Pathfinder.find_path(grid, Vector3i(-1, 1, 0), Vector3i(1, -1, 0))
	assert(Pathfinder.get_cache_size() > 0, "Cache should contain entries")
	
	print("All Pathfinder tests passed!")
"""
