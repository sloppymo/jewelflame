## Jewelflame/Strategic/StrategicMap
## Main strategic layer scene - hex map with province rendering
## Right 60% of screen (or full screen if panel hidden)

class_name StrategicMap
extends Node2D

# ============================================================================
# CONFIGURATION
# ============================================================================

## Hex rendering settings
@export var hex_size: float = 40.0
@export var hex_spacing: float = 1.05  # Slight gap between hexes

## Colors per faction
@export var color_blanche: Color = Color("#1a3a7a")  # Royal blue
@export var color_lyle: Color = Color("#8b2a2a")     # Crimson
@export var color_coryll: Color = Color("#2a6b3a")   # Forest green
@export var color_neutral: Color = Color("#555555")   # Gray

## Terrain colors (under faction tint)
@export var color_plains: Color = Color("#8b7355")
@export var color_forest: Color = Color("#2d4a2d")
@export var color_mountain: Color = Color("#5a5a5a")
@export var color_water: Color = Color("#3a5a7a")

# ============================================================================
# STATE
# ============================================================================

## Province renderers (province_id -> ProvinceRenderer)
var province_renderers: Dictionary = {}

## Currently selected province
var selected_province_id: String = ""

## Camera reference
var camera: Camera2D

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_setup_camera()
	_create_province_renderers()
	_connect_signals()
	_center_map()

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.name = "StrategicCamera"
	camera.zoom = Vector2(1.0, 1.0)
	camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	add_child(camera)

func _create_province_renderers() -> void:
	# Create renderers for all provinces in GameState
	for province_id in GameState.provinces.keys():
		var province: Province = GameState.provinces[province_id]
		var renderer := ProvinceRenderer.new()
		
		renderer.province_id = province_id
		renderer.province = province
		renderer.hex_size = hex_size
		renderer.position = _get_province_position(province_id)
		
		# Set terrain color
		renderer.base_color = _get_terrain_color(province.terrain)
		
		add_child(renderer)
		province_renderers[province_id] = renderer
		
		# Connect interaction
		renderer.province_clicked.connect(_on_province_clicked)
		renderer.province_hovered.connect(_on_province_hovered)

func _connect_signals() -> void:
	EventBus.province_selected.connect(_on_province_selected)
	EventBus.province_owner_changed.connect(_on_province_owner_changed)
	EventBus.turn_ended.connect(_on_turn_ended)

func _center_map() -> void:
	# Calculate center of all provinces
	if province_renderers.is_empty():
		return
	
	var center := Vector2.ZERO
	var count := 0
	
	for renderer in province_renderers.values():
		center += renderer.position
		count += 1
	
	if count > 0:
		center /= count
		camera.position = center

# ============================================================================
# POSITIONING
# ============================================================================

## Hardcoded positions for 5 provinces (hex grid coordinates)
func _get_province_position(province_id: String) -> Vector2:
	# Hex grid axial coordinates (q, r)
	var axial_positions := {
		"1": Vector2i(0, 0),    # Dunmoor (center)
		"2": Vector2i(2, -1),   # Carveti (northeast)
		"3": Vector2i(1, 1),    # Cobrige (southeast)
		"4": Vector2i(-1, 2),   # Banshea (south)
		"5": Vector2i(-2, 1)    # Petaria (southwest)
	}
	
	var axial := axial_positions.get(province_id, Vector2i.ZERO)
	return HexMath.axial_to_world(axial, hex_size * hex_spacing)

func _get_terrain_color(terrain: String) -> Color:
	match terrain:
		"forest":
			return color_forest
		"mountain":
			return color_mountain
		"water", "coastal":
			return color_water
		_:  # plains
			return color_plains

func _get_faction_color(faction_id: String) -> Color:
	match faction_id:
		"blanche":
			return color_blanche
		"lyle":
			return color_lyle
		"coryll":
			return color_coryll
		_:
			return color_neutral

# ============================================================================
# INPUT HANDLING
# ============================================================================

func _unhandled_input(event: InputEvent) -> void:
	# Camera pan with middle mouse or arrow keys
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MIDDLE:
			camera.position -= event.relative / camera.zoom
	
	# Zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom = (camera.zoom * 1.1).clamp(Vector2(0.5, 0.5), Vector2(2.0, 2.0))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom = (camera.zoom / 1.1).clamp(Vector2(0.5, 0.5), Vector2(2.0, 2.0))

# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_province_clicked(province_id: String) -> void:
	selected_province_id = province_id
	EventBus.province_selected.emit(province_id)

func _on_province_hovered(province_id: String) -> void:
	EventBus.province_hovered.emit(province_id)

func _on_province_selected(province_id: String) -> void:
	# Highlight selected province
	for id in province_renderers.keys():
		var renderer: ProvinceRenderer = province_renderers[id]
		renderer.set_selected(id == province_id)

func _on_province_owner_changed(province_id: String, new_owner: String, old_owner: String) -> void:
	# Update renderer color
	var renderer: ProvinceRenderer = province_renderers.get(province_id)
	if renderer:
		renderer.faction_color = _get_faction_color(new_owner)
		renderer.queue_redraw()

func _on_turn_ended(month: int, year: int) -> void:
	# Refresh all province visuals
	for renderer in province_renderers.values():
		renderer.queue_redraw()

# ============================================================================
# DRAWING
# ============================================================================

func _draw() -> void:
	# Draw connections between provinces
	_draw_connections()

func _draw_connections() -> void:
	# Draw lines between connected provinces
	for province_id in GameState.provinces.keys():
		var province: Province = GameState.provinces[province_id]
		var from_pos: Vector2 = _get_province_position(province_id)
		
		for connected_id in province.connected_to:
			# Only draw each connection once (when province_id < connected_id)
			if province_id < connected_id:
				var to_pos: Vector2 = _get_province_position(connected_id)
				_draw_connection_line(from_pos, to_pos)

func _draw_connection_line(from: Vector2, to: Vector2) -> void:
	# Draw a dashed or solid line between provinces
	var color := Color("#3a3a3a", 0.5)
	var width := 3.0
	
	draw_line(from, to, color, width)

# ============================================================================
# UTILITY
# ============================================================================

func get_renderer(province_id: String) -> ProvinceRenderer:
	return province_renderers.get(province_id)

func refresh_all() -> void:
	for renderer in province_renderers.values():
		renderer.queue_redraw()
