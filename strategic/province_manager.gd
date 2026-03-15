class_name ProvinceManager
extends Node2D

## Province Selection System using Color ID Map Technique
## This system uses a hidden data map where each province has a unique RGB color
## instead of using hex grid coordinates or Area2D collision shapes

# Signals
signal province_selected(province_id: int, province_data: Dictionary)
signal province_hovered(province_id: int, province_data: Dictionary)
signal province_deselected()

# Configuration
@export var visual_map: Sprite2D  ## The visible pixel art map
@export var data_map_texture: Texture2D  ## The hidden color-coded province map
@export var highlight_shader: ShaderMaterial  ## Optional shader for highlighting

# Data storage
var province_data: Dictionary = {}  ## Key: Color (as String), Value: Province info dict
var color_to_id: Dictionary = {}    ## Key: Color (as String), Value: province_id
var data_image: Image               ## Cached data map image for pixel sampling
var current_hovered_province: int = -1
var selected_province: int = -1

# Province data structure example:
# {
#   "name": "Dunmoor",
#   "owner_id": 1,
#   "garrison": 1200,
#   "defense": "High",
#   "income": 450,
#   "loyalty": 85,
#   "castle_level": 2,
#   "terrain": "plains"
# }

func _ready():
	print("=== PROVINCE MANAGER INITIALIZING ===")
	
	# Validate required nodes
	if not visual_map:
		push_error("ProvinceManager: Visual Map (Sprite2D) not assigned!")
		return
	
	if not data_map_texture:
		push_error("ProvinceManager: Data Map Texture not assigned!")
		return
	
	# Cache the data map image in memory (CRITICAL for performance)
	_cache_data_map()
	
	# Initialize province data
	_initialize_province_data()
	
	print("=== PROVINCE MANAGER READY ===")


## Cache the data map image to avoid disk reads on every mouse move
func _cache_data_map() -> void:
	# Get the Image from the texture
	data_image = data_map_texture.get_image()
	
	if not data_image:
		push_error("ProvinceManager: Failed to load data map image!")
		return
	
	# Ensure the image format supports pixel reading
	if data_image.is_compressed():
		data_image.decompress()
	
	print("Data map cached: ", data_image.get_size(), " pixels")


## Initialize province data - in production, load this from a JSON file or database
func _initialize_province_data() -> void:
	# Example province definitions with unique RGB colors
	# Each province gets a unique color on the data map
	var provinces = [
		{
			"id": 1,
			"color": Color("#FF0001"),  # Bright red
			"name": "Dunmoor",
			"owner_id": 1,
			"garrison": 1200,
			"defense": "High",
			"income": 450,
			"loyalty": 85,
			"castle_level": 2,
			"terrain": "plains"
		},
		{
			"id": 2,
			"color": Color("#00FF02"),  # Bright green
			"name": "Carveti",
			"owner_id": 2,
			"garrison": 800,
			"defense": "Medium",
			"income": 320,
			"loyalty": 70,
			"castle_level": 1,
			"terrain": "forest"
		},
		{
			"id": 3,
			"color": Color("#0003FF"),  # Bright blue
			"name": "Banshea",
			"owner_id": 2,
			"garrison": 1500,
			"defense": "High",
			"income": 500,
			"loyalty": 90,
			"castle_level": 3,
			"terrain": "mountains"
		},
		{
			"id": 4,
			"color": Color("#FFFF04"),  # Yellow
			"name": "Cobrige",
			"owner_id": 3,
			"garrison": 600,
			"defense": "Low",
			"income": 280,
			"loyalty": 60,
			"castle_level": 1,
			"terrain": "coast"
		},
		{
			"id": 5,
			"color": Color("#FF05FF"),  # Magenta
			"name": "Petaria",
			"owner_id": 3,
			"garrison": 1000,
			"defense": "Medium",
			"income": 380,
			"loyalty": 75,
			"castle_level": 2,
			"terrain": "hills"
		}
	]
	
	# Build lookup dictionaries
	for province in provinces:
		var color_key = _color_to_string(province.color)
		province_data[color_key] = province
		color_to_id[color_key] = province.id
	
	print("Initialized ", provinces.size(), " provinces")


## Convert Color to string key for dictionary lookup
func _color_to_string(color: Color) -> String:
	# Round to 8-bit values to avoid floating point precision issues
	var r = int(round(color.r * 255))
	var g = int(round(color.g * 255))
	var b = int(round(color.b * 255))
	return "%02X%02X%02X" % [r, g, b]


## Convert string key back to Color (for debugging/visualization)
func _string_to_color(color_str: String) -> Color:
	if color_str.length() != 6:
		return Color.BLACK
	var r = color_str.substr(0, 2).hex_to_int()
	var g = color_str.substr(2, 2).hex_to_int()
	var b = color_str.substr(4, 2).hex_to_int()
	return Color8(r, g, b)


## Get province ID from pixel color
func _get_province_id_from_color(color: Color) -> int:
	var color_key = _color_to_string(color)
	return color_to_id.get(color_key, -1)


## Get province data from pixel color
func _get_province_data_from_color(color: Color) -> Dictionary:
	var color_key = _color_to_string(color)
	return province_data.get(color_key, {})


## Convert global mouse position to data map local coordinates
func _get_data_map_pixel_at_mouse() -> Color:
	if not data_image or not visual_map:
		return Color.BLACK
	
	# Get mouse position in global coordinates
	var mouse_pos = get_global_mouse_position()
	
	# Convert to local coordinates relative to the visual map
	var local_pos = visual_map.to_local(mouse_pos)
	
	# Account for sprite scaling
	var sprite_size = visual_map.texture.get_size()
	var scale_factor = visual_map.scale
	
	# Convert to pixel coordinates on the data map
	# The data map should be the same dimensions as the visual map
	var pixel_x = int(local_pos.x / scale_factor.x)
	var pixel_y = int(local_pos.y / scale_factor.y)
	
	# Clamp to image bounds
	var img_size = data_image.get_size()
	pixel_x = clamp(pixel_x, 0, img_size.x - 1)
	pixel_y = clamp(pixel_y, 0, img_size.y - 1)
	
	# Sample the pixel color
	var pixel_color = data_image.get_pixel(pixel_x, pixel_y)
	
	return pixel_color


## Check if a pixel color represents a valid province (not background/water)
func _is_valid_province(color: Color) -> bool:
	# Skip transparent or black pixels (background/empty space)
	if color.a < 0.5:
		return false
	if color.r < 0.01 and color.g < 0.01 and color.b < 0.01:
		return false
	
	# Check if this color exists in our province data
	var color_key = _color_to_string(color)
	return province_data.has(color_key)


## Main update function - call this from _process or _input
func update_hover() -> void:
	var pixel_color = _get_data_map_pixel_at_mouse()
	
	if not _is_valid_province(pixel_color):
		# Not hovering over a province
		if current_hovered_province != -1:
			current_hovered_province = -1
			province_deselected.emit()
		return
	
	var province_id = _get_province_id_from_color(pixel_color)
	var data = _get_province_data_from_color(pixel_color)
	
	if province_id != current_hovered_province:
		current_hovered_province = province_id
		province_hovered.emit(province_id, data)


## Handle mouse click to select a province
func handle_click() -> void:
	var pixel_color = _get_data_map_pixel_at_mouse()
	
	if not _is_valid_province(pixel_color):
		# Clicked on empty space - deselect
		selected_province = -1
		province_deselected.emit()
		return
	
	var province_id = _get_province_id_from_color(pixel_color)
	var data = _get_province_data_from_color(pixel_color)
	
	selected_province = province_id
	province_selected.emit(province_id, data)
	
	print("Selected province: ", data.get("name", "Unknown"))


## Get data for currently selected province
func get_selected_province_data() -> Dictionary:
	if selected_province == -1:
		return {}
	for color_key in province_data:
		if province_data[color_key].get("id") == selected_province:
			return province_data[color_key]
	return {}


## Load province data from JSON file (for production use)
func load_province_data_from_json(json_path: String) -> void:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("Failed to open province data: " + json_path)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("JSON parse error: " + json.get_error_message())
		return
	
	var data = json.data
	if not data is Array:
		push_error("Province data must be an array")
		return
	
	# Clear existing data
	province_data.clear()
	color_to_id.clear()
	
	# Load new data
	for province in data:
		var color = Color(province.color_hex)
		var color_key = _color_to_string(color)
		province_data[color_key] = province
		color_to_id[color_key] = province.id
	
	print("Loaded ", data.size(), " provinces from JSON")


## DEBUG: Visualize the data map (shows color ID map in game)
func toggle_data_map_visibility() -> void:
	if not visual_map:
		return
	
	# Swap between visual map and data map
	if visual_map.texture == data_map_texture:
		# Restore visual map
		visual_map.texture = load("res://assets/maps/strategic_map.png")
	else:
		# Show data map
		visual_map.texture = data_map_texture


## Get province count
func get_province_count() -> int:
	return province_data.size()


## Get all provinces owned by a specific family
func get_provinces_by_owner(owner_id: int) -> Array:
	var result = []
	for color_key in province_data:
		var province = province_data[color_key]
		if province.get("owner_id") == owner_id:
			result.append(province)
	return result
