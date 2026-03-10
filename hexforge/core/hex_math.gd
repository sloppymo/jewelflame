# hex_math.gd
# HexForge Core Library - Static mathematical utilities for hexagonal grid operations
# All functions use cube coordinates (x, y, z where x+y+z=0)
# Reference: https://www.redblobgames.com/grids/hexagons/
class_name HexMath

# ============================================================================
# DIRECTION VECTORS
# ============================================================================

const DIRECTIONS: Array[Vector3i] = [
	Vector3i(1, -1, 0),   # East
	Vector3i(1, 0, -1),   # Northeast
	Vector3i(0, 1, -1),   # Northwest
	Vector3i(-1, 1, 0),   # West
	Vector3i(-1, 0, 1),   # Southwest
	Vector3i(0, -1, 1),   # Southeast
]

const DIAGONALS: Array[Vector3i] = [
	Vector3i(2, -1, -1),  # East-Northeast
	Vector3i(1, 1, -2),   # North
	Vector3i(-1, 2, -1),  # West-Northwest
	Vector3i(-2, 1, 1),   # West-Southwest
	Vector3i(-1, -1, 2),  # South
	Vector3i(1, -2, 1),   # East-Southeast
]

# ============================================================================
# COORDINATE CONVERSION
# ============================================================================

## Validates that cube coordinates satisfy x + y + z = 0
static func is_valid_cube(cube: Vector3i) -> bool:
	return cube.x + cube.y + cube.z == 0

## Validates cube coordinates with optional assertion in debug builds
static func validate_cube(cube: Vector3i, context: String = "") -> bool:
	var valid: bool = is_valid_cube(cube)
	if not valid:
		push_error("Invalid cube coordinates %s in context: %s" % [cube, context])
	return valid

## Converts axial coordinates (q, r) to cube coordinates (x, y, z)
## q maps to x, r maps to z, y is derived as -x-z
static func axial_to_cube(axial: Vector2i) -> Vector3i:
	var x: int = axial.x
	var z: int = axial.y
	var y: int = -x - z
	return Vector3i(x, y, z)

## Converts cube coordinates (x, y, z) to axial coordinates (q, r)
## Returns Vector2i where x=q, y=r (z is discarded)
static func cube_to_axial(cube: Vector3i) -> Vector2i:
	return Vector2i(cube.x, cube.z)

## Converts cube coordinates to world pixel position (pointy-top layout)
## Size is the distance from center to corner (radius)
static func cube_to_world(cube: Vector3i, size: float) -> Vector2:
	var x: float = size * (sqrt(3) * cube.x + sqrt(3) / 2 * cube.z)
	var y: float = size * (3.0 / 2.0 * cube.z)
	return Vector2(x, y)

## Converts world pixel position to cube coordinates (pointy-top layout)
static func world_to_cube(world: Vector2, size: float) -> Vector3i:
	var q: float = (sqrt(3) / 3 * world.x - 1.0 / 3 * world.y) / size
	var r: float = (2.0 / 3 * world.y) / size
	return cube_round(Vector3(q, -q - r, r))

## Rounds floating-point cube coordinates to nearest integer cube
static func cube_round(frac: Vector3) -> Vector3i:
	var rx: int = round(frac.x)
	var ry: int = round(frac.y)
	var rz: int = round(frac.z)
	
	var x_diff: float = abs(rx - frac.x)
	var y_diff: float = abs(ry - frac.y)
	var z_diff: float = abs(rz - frac.z)
	
	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry
	
	return Vector3i(rx, ry, rz)

# ============================================================================
# DISTANCE AND LENGTH
# ============================================================================

## Calculates Manhattan distance between two cube coordinates
static func distance(a: Vector3i, b: Vector3i) -> int:
	return (abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)) / 2

## Returns the length of a cube vector (distance from origin)
static func length(cube: Vector3i) -> int:
	return (abs(cube.x) + abs(cube.y) + abs(cube.z)) / 2

# ============================================================================
# NEIGHBOR OPERATIONS
# ============================================================================

## Returns the neighbor in the specified direction (0-5)
## 0: East, 1: Northeast, 2: Northwest, 3: West, 4: Southwest, 5: Southeast
static func neighbor(cube: Vector3i, direction: int) -> Vector3i:
	direction = ((direction % 6) + 6) % 6  # Normalize to 0-5
	return cube + DIRECTIONS[direction]

## Returns all 6 neighbors of a cube coordinate
static func neighbors(cube: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	result.resize(6)
	for i in range(6):
		result[i] = cube + DIRECTIONS[i]
	return result

## Returns the diagonal neighbor in the specified direction (0-5)
static func diagonal_neighbor(cube: Vector3i, direction: int) -> Vector3i:
	direction = ((direction % 6) + 6) % 6
	return cube + DIAGONALS[direction]

# ============================================================================
# LINE DRAWING
# ============================================================================

## Linear interpolation between two cube coordinates (0.0 to 1.0)
static func cube_lerp(a: Vector3i, b: Vector3i, t: float) -> Vector3:
	return Vector3(
		lerpf(a.x, b.x, t),
		lerpf(a.y, b.y, t),
		lerpf(a.z, b.z, t)
	)

## Returns all cube coordinates forming a line between a and b (inclusive)
## Uses Bresenham-style algorithm adapted for cube coordinates
static func line(a: Vector3i, b: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var distance_val: int = distance(a, b)
	
	if distance_val == 0:
		result.append(a)
		return result
	
	for i in range(distance_val + 1):
		var t: float = float(i) / distance_val
		result.append(cube_round(cube_lerp(a, b, t)))
	
	return result

# ============================================================================
# RANGE AND AREA OPERATIONS
# ============================================================================

## Returns all cube coordinates within a given radius (inclusive)
static func range_cells(center: Vector3i, radius: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	
	for x in range(-radius, radius + 1):
		for y in range(max(-radius, -x - radius), min(radius, -x + radius) + 1):
			var z: int = -x - y
			result.append(center + Vector3i(x, y, z))
	
	return result

## Returns all cube coordinates forming a ring at exactly the given radius
static func ring(center: Vector3i, radius: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	
	if radius == 0:
		result.append(center)
		return result
	
	# Start at radius distance in the "East" direction
	var cube: Vector3i = center + DIRECTIONS[4] * radius  # Southwest direction * radius
	
	for i in range(6):
		for j in range(radius):
			result.append(cube)
			cube = neighbor(cube, i)
	
	return result

## Returns all cube coordinates forming a spiral from radius 0 to max_radius
static func spiral(center: Vector3i, max_radius: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	result.append(center)  # Radius 0
	
	for radius in range(1, max_radius + 1):
		result.append_array(ring(center, radius))
	
	return result

## Returns cells in a rectangular region (bounding box in cube space)
static func rect_region(min_cube: Vector3i, max_cube: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	
	for x in range(min_cube.x, max_cube.x + 1):
		for y in range(min_cube.y, max_cube.y + 1):
			var z: int = -x - y
			if z >= min_cube.z and z <= max_cube.z:
				result.append(Vector3i(x, y, z))
	
	return result

# ============================================================================
# ROTATION AND REFLECTION
# ============================================================================

## Rotates cube coordinates 60 degrees clockwise around the origin
static func rotate_clockwise(cube: Vector3i) -> Vector3i:
	return Vector3i(-cube.z, -cube.x, -cube.y)

## Rotates cube coordinates 60 degrees counter-clockwise around the origin
static func rotate_counter_clockwise(cube: Vector3i) -> Vector3i:
	return Vector3i(-cube.y, -cube.z, -cube.x)

## Rotates cube coordinates by N * 60 degrees (positive = clockwise)
static func rotate(cube: Vector3i, rotations: int) -> Vector3i:
	rotations = ((rotations % 6) + 6) % 6  # Normalize to 0-5
	var result: Vector3i = cube
	for i in range(rotations):
		result = rotate_clockwise(result)
	return result

## Reflects cube coordinates across the q axis (x axis)
static func reflect_q(cube: Vector3i) -> Vector3i:
	return Vector3i(cube.x, cube.z, cube.y)

## Reflects cube coordinates across the r axis (z axis)
static func reflect_r(cube: Vector3i) -> Vector3i:
	return Vector3i(cube.z, cube.y, cube.x)

## Reflects cube coordinates across the s axis (y axis)
static func reflect_s(cube: Vector3i) -> Vector3i:
	return Vector3i(cube.y, cube.x, cube.z)

# ============================================================================
# ARITHMETIC OPERATIONS
# ============================================================================

## Adds two cube coordinates
static func add(a: Vector3i, b: Vector3i) -> Vector3i:
	return a + b

## Subtracts cube coordinate b from a
static func subtract(a: Vector3i, b: Vector3i) -> Vector3i:
	return a - b

## Multiplies a cube coordinate by a scalar
static func multiply(cube: Vector3i, scalar: int) -> Vector3i:
	return cube * scalar

## Scales a cube coordinate by a floating-point factor (rounds result)
static func scale(cube: Vector3i, factor: float) -> Vector3i:
	return cube_round(Vector3(cube) * factor)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

## Returns true if two cube coordinates are equal
static func equals(a: Vector3i, b: Vector3i) -> bool:
	return a == b

## Returns a string representation of cube coordinates
static func cube_to_string(cube: Vector3i) -> String:
	return "(%d, %d, %d)" % [cube.x, cube.y, cube.z]

## Returns the axial representation as a string
static func axial_to_string(cube: Vector3i) -> String:
	return "(%d, %d)" % [cube.x, cube.z]

## Calculates bounds for a set of cube coordinates
## Returns Dictionary with min_cube, max_cube, width, height
static func calculate_bounds(cells: Array[Vector3i]) -> Dictionary:
	if cells.is_empty():
		return {"min_cube": Vector3i.ZERO, "max_cube": Vector3i.ZERO, "width": 0, "height": 0}
	
	var min_x: int = cells[0].x
	var max_x: int = cells[0].x
	var min_y: int = cells[0].y
	var max_y: int = cells[0].y
	var min_z: int = cells[0].z
	var max_z: int = cells[0].z
	
	for cell in cells:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)
		min_z = min(min_z, cell.z)
		max_z = max(max_z, cell.z)
	
	return {
		"min_cube": Vector3i(min_x, min_y, min_z),
		"max_cube": Vector3i(max_x, max_y, max_z),
		"width": max_x - min_x + 1,
		"height": max_z - min_z + 1
	}
