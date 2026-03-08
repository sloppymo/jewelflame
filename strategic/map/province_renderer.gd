extends Node2D

@onready var areas: Node2D = $ProvinceAreas
@onready var labels: Node2D = $ProvinceLabels

# Terrain sprites (loaded at runtime to avoid import issues)
var terrain_sprites: Dictionary = {}

# Selection highlight (loaded at runtime)
var selection_highlight: Texture2D
var selected_province_id: int = -1

func _ready():
	# Load terrain sprites
	terrain_sprites = {
		"plains": load("res://assets/terrain/plains.png"),
		"forest": load("res://assets/terrain/forest.png"),
		"mountain": load("res://assets/terrain/mountain.png"),
		"water": load("res://assets/terrain/water.png"),
		"coast": load("res://assets/terrain/coast.png"),
	}
	
	# Load selection highlight
	selection_highlight = load("res://assets/effects/selection.png")
	
	EventBus.ProvinceSelected.connect(_on_province_selected)
	EventBus.GameLoaded.connect(_on_game_loaded)
	EventBus.ProvinceExhausted.connect(_on_province_exhausted)
	render_all_provinces()

func render_all_provinces():
	for child in areas.get_children():
		child.queue_free()
	for child in labels.get_children():
		child.queue_free()
	
	for province_id in GameState.provinces:
		create_province_area(province_id)

func create_province_area(province_id: int):
	var province = GameState.provinces[province_id]
	var family = GameState.families.get(province.owner_id)
	
	var area = Area2D.new()
	area.name = "Province_%d" % province_id
	area.position = get_province_position(province_id)
	area.input_pickable = true
	
	# Collision
	var collision = CollisionPolygon2D.new()
	collision.polygon = get_province_shape(province_id)
	collision.build_mode = CollisionPolygon2D.BUILD_SOLIDS
	area.add_child(collision)
	
	# Terrain texture (under faction color)
	var terrain_type = province.terrain_type if province.get("terrain_type") else "plains"
	var terrain_tex = terrain_sprites.get(terrain_type, terrain_sprites.get("plains"))
	
	var terrain_sprite = Sprite2D.new()
	terrain_sprite.name = "Terrain"
	terrain_sprite.texture = terrain_tex
	terrain_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	terrain_sprite.scale = Vector2(1.5, 1.5)  # Scale up 64x64 to fit hex
	area.add_child(terrain_sprite)
	
	# Faction color overlay
	var polygon = Polygon2D.new()
	polygon.name = "Visual"
	polygon.polygon = get_province_shape(province_id)
	polygon.color = family.color if family else Color.GRAY
	polygon.color.a = 0.4  # Slightly more transparent to show terrain
	area.add_child(polygon)
	
	# Border
	var border = Line2D.new()
	border.name = "Border"
	border.points = get_province_shape(province_id)
	border.closed = true
	border.width = 3
	border.default_color = Color.WHITE
	area.add_child(border)
	
	# Selection highlight (hidden by default)
	var highlight = Sprite2D.new()
	highlight.name = "SelectionHighlight"
	highlight.texture = selection_highlight
	highlight.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	highlight.visible = false
	highlight.scale = Vector2(0.8, 0.8)
	area.add_child(highlight)
	
	if province.is_exhausted:
		var dark = Polygon2D.new()
		dark.name = "ExhaustionOverlay"
		dark.polygon = get_province_shape(province_id)
		dark.color = Color(0, 0, 0, 0.5)
		area.add_child(dark)
	
	area.input_event.connect(_on_province_input.bind(province_id))
	areas.add_child(area)
	
	var label = Label.new()
	label.text = province.name
	label.position = area.position - Vector2(40, 10)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 16)
	labels.add_child(label)

func get_province_position(id: int) -> Vector2:
	var positions = {
		1: Vector2(400, 300),
		2: Vector2(600, 200),
		3: Vector2(600, 400),
		4: Vector2(800, 300),
		5: Vector2(800, 500)
	}
	return positions.get(id, Vector2(500, 500))

func get_province_shape(id: int) -> PackedVector2Array:
	var province = GameState.provinces[id]
	if province.polygon_points.size() > 0:
		return province.polygon_points
	
	var center = Vector2.ZERO
	var size = 80.0
	var points = PackedVector2Array()
	for i in range(6):
		var angle = deg_to_rad(60 * i - 30)
		points.append(center + Vector2(cos(angle), sin(angle)) * size)
	return points

func _on_province_input(viewport, event, shape_idx, province_id: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Province clicked: ", province_id)
		EventBus.ProvinceSelected.emit(province_id)

func _on_province_selected(province_id: int):
	selected_province_id = province_id
	for child in areas.get_children():
		var visual = child.get_node_or_null("Visual")
		var highlight = child.get_node_or_null("SelectionHighlight")
		
		if child.name == "Province_%d" % province_id:
			if visual:
				visual.modulate = Color(1.5, 1.5, 1.5)
			if highlight:
				highlight.visible = true
		else:
			if visual:
				visual.modulate = Color.WHITE
			if highlight:
				highlight.visible = false

func _on_province_exhausted(id: int, exhausted: bool):
	var area = areas.get_node_or_null("Province_%d" % id)
	if area:
		var existing_dark = area.get_node_or_null("ExhaustionOverlay")
		if exhausted:
			if not existing_dark:
				var dark = Polygon2D.new()
				dark.name = "ExhaustionOverlay"
				dark.polygon = get_province_shape(id)
				dark.color = Color(0, 0, 0, 0.5)
				area.add_child(dark)
		else:
			if existing_dark:
				existing_dark.queue_free()

func _on_game_loaded(slot: int):
	render_all_provinces()

func update_province_color(id: int):
	var area = areas.get_node_or_null("Province_%d" % id)
	if area:
		var visual = area.get_node_or_null("Visual")
		var province = GameState.provinces.get(id)
		var family = GameState.families.get(province.owner_id) if province else null
		if visual and family:
			visual.color = family.color
			visual.color.a = 0.6
