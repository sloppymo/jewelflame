## Jewelflame/Strategic/ProvinceRenderer
## Visual representation of a single province on the strategic map
## Handles rendering, input detection, and visual states

class_name ProvinceRenderer
extends Area2D

# ============================================================================
# SIGNALS
# ============================================================================

signal province_clicked(province_id: String)
signal province_hovered(province_id: String)

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var province_id: String = ""
@export var province: Province
@export var hex_size: float = 40.0

## Colors
@export var base_color: Color = Color("#8b7355")
@export var faction_color: Color = Color("#555555"):
	set(value):
		faction_color = value
		queue_redraw()

## Selection/hover states
var is_selected: bool = false:
	set(value):
		is_selected = value
		queue_redraw()

var is_hovered: bool = false:
	set(value):
		is_hovered = value
		queue_redraw()

var is_exhausted: bool = false:
	set(value):
		is_exhausted = value
		queue_redraw()

# ============================================================================
# INTERNAL
# ============================================================================

var _hex_polygon: PackedVector2Array = []
var _collision_polygon: CollisionPolygon2D

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_generate_hex_polygon()
	_setup_collision()
	_setup_input()
	_update_faction_color()
	
	# Connect to province signals
	if province:
		province.owner_changed.connect(_on_owner_changed)

func _generate_hex_polygon() -> void:
	# Generate pointy-top hexagon points
	_hex_polygon.clear()
	for i in range(6):
		var angle: float = PI / 3.0 * i - PI / 6.0
		var x: float = hex_size * cos(angle)
		var y: float = hex_size * sin(angle)
		_hex_polygon.append(Vector2(x, y))

func _setup_collision() -> void:
	# Create collision polygon for mouse detection
	_collision_polygon = CollisionPolygon2D.new()
	_collision_polygon.polygon = _hex_polygon
	add_child(_collision_polygon)

func _setup_input() -> void:
	# Enable input detection
	input_pickable = true
	
	# Connect input events
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _update_faction_color() -> void:
	if not province:
		return
	
	match province.owner_faction:
		"blanche":
			faction_color = Color("#1a3a7a")
		"lyle":
			faction_color = Color("#8b2a2a")
		"coryll":
			faction_color = Color("#2a6b3a")
		_:
			faction_color = Color("#555555")

# ============================================================================
# INPUT HANDLING
# ============================================================================

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			province_clicked.emit(province_id)

func _on_mouse_entered() -> void:
	is_hovered = true
	province_hovered.emit(province_id)

func _on_mouse_exited() -> void:
	is_hovered = false

# ============================================================================
# DRAWING
# ============================================================================

func _draw() -> void:
	if not province:
		return
	
	_draw_hex_fill()
	_draw_hex_border()
	_draw_exhaustion_overlay()
	_draw_castle_indicator()
	_draw_troop_indicator()

func _draw_hex_fill() -> void:
	# Blend base terrain color with faction color
	var fill_color: Color = base_color.blend(faction_color * 0.6)
	
	# Adjust for hover/selection
	if is_selected:
		fill_color = fill_color.lightened(0.2)
	elif is_hovered:
		fill_color = fill_color.lightened(0.1)
	
	# Exhaustion makes it darker
	if is_exhausted:
		fill_color = fill_color.darkened(0.3)
	
	draw_polygon(_hex_polygon, [fill_color])

func _draw_hex_border() -> void:
	var border_color: Color
	var border_width: float = 2.0
	
	if is_selected:
		border_color = Color("#d4af37")  # Gold for selected
		border_width = 4.0
	elif is_hovered:
		border_color = Color("#f4e4c1")  # Cream for hover
	else:
		border_color = Color("#2b2b5c")  # Dark blue default
	
	# Draw border by connecting hex points
	for i in range(6):
		var start := _hex_polygon[i]
		var end := _hex_polygon[(i + 1) % 6]
		draw_line(start, end, border_color, border_width, true)

func _draw_exhaustion_overlay() -> void:
	if not is_exhausted:
		return
	
	# Draw subtle diagonal stripes
	var stripe_color := Color("#000000", 0.3)
	var spacing := 10.0
	
	for i in range(-5, 6):
		var offset := i * spacing
		draw_line(
			Vector2(offset - 30, -30),
			Vector2(offset + 30, 30),
			stripe_color,
			2.0
		)

func _draw_castle_indicator() -> void:
	if not province or not province.has_castle:
		return
	
	# Draw small castle icon in center
	var castle_color := Color("#d4af37")  # Gold
	var size := hex_size * 0.3
	
	# Simple castle shape (rectangle with battlements)
	var rect := Rect2(Vector2(-size/2, -size/2), Vector2(size, size))
	draw_rect(rect, castle_color)
	
	# Battlements (small squares on top)
	var battlement_size := size / 4
	for i in range(3):
		var x := -size/2 + i * battlement_size * 1.5
		draw_rect(
			Rect2(Vector2(x, -size/2 - battlement_size), Vector2(battlement_size, battlement_size)),
			castle_color
		)

func _draw_troop_indicator() -> void:
	if not province:
		return
	
	var troop_count := province.get_unit_count()
	if troop_count == 0:
		return
	
	# Draw small number below castle (or in center if no castle)
	var text_color := Color("#f4e4c1")
	var font_size := 12
	
	# Use draw_string with default font
	var text := str(troop_count)
	# Note: In Godot 4, we need a Font resource to use draw_string properly
	# For now, draw a simple representation
	
	# Draw small circles representing unit stacks
	var circle_color := Color("#f4e4c1")
	var radius := 3.0
	var y_offset := hex_size * 0.5
	
	# Max 5 dots
	var dots := mini(troop_count / 10 + 1, 5)
	var spacing := 8.0
	var start_x := -(dots - 1) * spacing / 2
	
	for i in range(dots):
		draw_circle(Vector2(start_x + i * spacing, y_offset), radius, circle_color)

# ============================================================================
# PUBLIC METHODS
# ============================================================================

func set_selected(selected: bool) -> void:
	is_selected = selected

func refresh() -> void:
	_update_faction_color()
	queue_redraw()

# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_owner_changed(new_owner: String, old_owner: String) -> void:
	_update_faction_color()
	queue_redraw()
