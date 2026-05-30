class_name ArenaMap
extends Node2D
## A full-screen arena map with proper walls and tactical layout.

@onready var tile_map: TileMap = $TileMap

# Arena dimensions (in tiles)
const ARENA_WIDTH := 50
const ARENA_HEIGHT := 30
const TILE_SIZE := 32

func _ready() -> void:
	_generate_arena()

func _generate_arena() -> void:
	## Generates a tactical arena with proper walls
	tile_map.clear()
	
	# Center the arena
	var offset_x := -(ARENA_WIDTH * TILE_SIZE) / 2
	var offset_y := -(ARENA_HEIGHT * TILE_SIZE) / 2
	position = Vector2(offset_x + 640, offset_y + 360)
	
	# Generate floor
	_generate_floor()
	
	# Generate outer walls
	_generate_outer_walls()
	
	# Generate inner cover/walls
	_generate_inner_cover()

func _generate_floor() -> void:
	## Creates the base stone floor
	for x in range(ARENA_WIDTH):
		for y in range(ARENA_HEIGHT):
			var pos := Vector2i(x, y)
			var rand := randf()
			
			# Random floor variation (only use valid atlas coords from stone_floor.png)
			# stone_floor.png is 112x224 = 3.5 x 7 tiles: (0,0), (1,0), (0,1), (1,1)
			if rand < 0.5:
				tile_map.set_cell(0, pos, 0, Vector2i(0, 0))  # Clean stone
			elif rand < 0.7:
				tile_map.set_cell(0, pos, 0, Vector2i(1, 0))  # Variation
			elif rand < 0.85:
				tile_map.set_cell(0, pos, 0, Vector2i(0, 1))  # Cracked
			else:
				tile_map.set_cell(0, pos, 0, Vector2i(1, 1))  # Darker

func _generate_outer_walls() -> void:
	## Creates a solid wall border around the arena
	
	# Top wall
	for x in range(ARENA_WIDTH):
		tile_map.set_cell(1, Vector2i(x, 0), 1, Vector2i(0, 0))
		tile_map.set_cell(1, Vector2i(x, 1), 1, Vector2i(0, 1))
	
	# Bottom wall
	for x in range(ARENA_WIDTH):
		tile_map.set_cell(1, Vector2i(x, ARENA_HEIGHT - 1), 1, Vector2i(0, 0))
		tile_map.set_cell(1, Vector2i(x, ARENA_HEIGHT - 2), 1, Vector2i(0, 1))
	
	# Left wall
	for y in range(2, ARENA_HEIGHT - 2):
		tile_map.set_cell(1, Vector2i(0, y), 1, Vector2i(1, 0))
		tile_map.set_cell(1, Vector2i(1, y), 1, Vector2i(1, 1))
	
	# Right wall
	for y in range(2, ARENA_HEIGHT - 2):
		tile_map.set_cell(1, Vector2i(ARENA_WIDTH - 1, y), 1, Vector2i(1, 0))
		tile_map.set_cell(1, Vector2i(ARENA_WIDTH - 2, y), 1, Vector2i(1, 1))
	
	# Corner pillars (use same tiles as walls, different positions)
	tile_map.set_cell(1, Vector2i(0, 0), 1, Vector2i(0, 0))
	tile_map.set_cell(1, Vector2i(ARENA_WIDTH - 1, 0), 1, Vector2i(0, 0))
	tile_map.set_cell(1, Vector2i(0, ARENA_HEIGHT - 1), 1, Vector2i(0, 0))
	tile_map.set_cell(1, Vector2i(ARENA_WIDTH - 1, ARENA_HEIGHT - 1), 1, Vector2i(0, 0))
	
	# Entry gaps (no walls at spawn points)
	# Left entry
	for y in range(12, 18):
		tile_map.erase_cell(1, Vector2i(0, y))
		tile_map.erase_cell(1, Vector2i(1, y))
	# Right entry
	for y in range(12, 18):
		tile_map.erase_cell(1, Vector2i(ARENA_WIDTH - 1, y))
		tile_map.erase_cell(1, Vector2i(ARENA_WIDTH - 2, y))

func _generate_inner_cover() -> void:
	## Adds cover walls and pillars inside the arena
	
	# Central pillars (4 corners)
	var center_x := ARENA_WIDTH / 2
	var center_y := ARENA_HEIGHT / 2
	
	# Four corner pillars around center
	var pillars := [
		Vector2i(center_x - 5, center_y - 3),
		Vector2i(center_x + 5, center_y - 3),
		Vector2i(center_x - 5, center_y + 3),
		Vector2i(center_x + 5, center_y + 3),
	]
	
	for pos in pillars:
		tile_map.set_cell(1, pos, 1, Vector2i(1, 0))
		tile_map.set_cell(1, pos + Vector2i(0, 1), 1, Vector2i(1, 1))
	
	# Side cover walls
	var left_cover := [
		Vector2i(8, 8), Vector2i(8, 9),
		Vector2i(8, 20), Vector2i(8, 21),
	]
	var right_cover := [
		Vector2i(ARENA_WIDTH - 9, 8), Vector2i(ARENA_WIDTH - 9, 9),
		Vector2i(ARENA_WIDTH - 9, 20), Vector2i(ARENA_WIDTH - 9, 21),
	]
	
	for pos in left_cover:
		tile_map.set_cell(1, pos, 1, Vector2i(1, 0))
	for pos in right_cover:
		tile_map.set_cell(1, pos, 1, Vector2i(1, 0))
	
	# Mid-field barriers (top and bottom)
	for x in range(center_x - 4, center_x + 4):
		tile_map.set_cell(1, Vector2i(x, 6), 1, Vector2i(0, 0))
		tile_map.set_cell(1, Vector2i(x, ARENA_HEIGHT - 7), 1, Vector2i(0, 0))
	
	# Add some decorative rubble/cracks on floor
	for i in range(15):
		var rx := randi() % (ARENA_WIDTH - 4) + 2
		var ry := randi() % (ARENA_HEIGHT - 4) + 2
		var pos := Vector2i(rx, ry)
		# Don't place on walls
		if tile_map.get_cell_source_id(1, pos) == -1:
			if randf() < 0.5:
				tile_map.set_cell(0, pos, 0, Vector2i(0, 0))  # Just use regular floor for now
			else:
				tile_map.set_cell(0, pos, 0, Vector2i(1, 1))  # Slight variation

func get_spawn_position(team: int) -> Vector2:
	## Returns a spawn position for a team
	if team == 1:
		# Left side spawn (inside the wall gap)
		return Vector2(3 * TILE_SIZE + 16, (ARENA_HEIGHT / 2) * TILE_SIZE + 16)
	else:
		# Right side spawn
		return Vector2((ARENA_WIDTH - 3) * TILE_SIZE + 16, (ARENA_HEIGHT / 2) * TILE_SIZE + 16)

func get_center() -> Vector2:
	## Returns the center of the arena
	return Vector2((ARENA_WIDTH * TILE_SIZE) / 2, (ARENA_HEIGHT * TILE_SIZE) / 2)

func is_valid_position(pos: Vector2) -> bool:
	## Checks if a position is inside the arena and not on a wall
	var local_pos := pos - position
	var tile_x := int(local_pos.x / TILE_SIZE)
	var tile_y := int(local_pos.y / TILE_SIZE)
	
	# Check bounds
	if tile_x < 0 or tile_x >= ARENA_WIDTH or tile_y < 0 or tile_y >= ARENA_HEIGHT:
		return false
	
	# Check if tile is a wall (layer 1)
	if tile_map.get_cell_source_id(1, Vector2i(tile_x, tile_y)) != -1:
		return false
	
	return true

func is_wall(pos: Vector2) -> bool:
	## Checks if a position has a wall
	var local_pos := pos - position
	var tile_x := int(local_pos.x / TILE_SIZE)
	var tile_y := int(local_pos.y / TILE_SIZE)
	return tile_map.get_cell_source_id(1, Vector2i(tile_x, tile_y)) != -1
