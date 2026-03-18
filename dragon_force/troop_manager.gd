class_name TroopManager
extends Node2D

## Manages visual representation of troops as dots around the general
## Uses simple Sprite2D instances for performance (up to 100 troops per general)

const TROOP_DOT_SIZE: float = 4.0  # 4x4 pixel dots
const MAX_VISIBLE_TROOPS: int = 50  # Visual cap (represents 100+ troops as clusters)

# Formation enum - mirrors General.Formation for compatibility
const Formation = General.Formation

@export var dot_color_player: Color = Color(0.2, 0.4, 0.9)  # Blue
@export var dot_color_enemy: Color = Color(0.9, 0.2, 0.2)   # Red

var current_formation: Formation = Formation.ADVANCE
var troop_count: int = 0
var team: int = 0

# Visual troop dots
var troop_dots: Array[Sprite2D] = []
var dot_texture: Texture2D

# Formation offsets
var formation_offsets: Dictionary = {}

func _ready():
	# Create simple dot texture
	dot_texture = _create_dot_texture()
	
	# Define formation positions (relative to general)
	_setup_formations()

func _create_dot_texture() -> Texture2D:
	"""Create a simple 4x4 pixel dot texture."""
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)

func _setup_formations():
	"""Setup troop positions for each formation type."""
	# Melee: Loose swarm around general
	formation_offsets[Formation.MELEE] = _generate_swarm_offsets(60.0)
	
	# Standby: Tight defensive formation in front
	formation_offsets[Formation.STANDBY] = _generate_wedge_offsets(50.0)
	
	# Advance: Arrow formation pointing forward
	formation_offsets[Formation.ADVANCE] = _generate_arrow_offsets(60.0)
	
	# Retreat: Scattered behind general
	formation_offsets[Formation.RETREAT] = _generate_scatter_offsets(70.0)

func _generate_swarm_offsets(radius: float) -> Array[Vector2]:
	"""Generate random positions in a circle."""
	var offsets: Array[Vector2] = []
	for i in range(MAX_VISIBLE_TROOPS):
		var angle = randf() * PI * 2
		var dist = randf() * radius
		offsets.append(Vector2(cos(angle) * dist, sin(angle) * dist))
	return offsets

func _generate_wedge_offsets(radius: float) -> Array[Vector2]:
	"""Generate wedge formation (defensive wall)."""
	var offsets: Array[Vector2] = []
	var rows = 5
	var cols = 10
	for i in range(MAX_VISIBLE_TROOPS):
		var row = i / cols
		var col = i % cols
		var x = (col - cols / 2.0) * 8.0
		var y = -20.0 - (row * 6.0)  # In front of general
		offsets.append(Vector2(x, y))
	return offsets

func _generate_arrow_offsets(radius: float) -> Array[Vector2]:
	"""Generate arrow formation (pointing forward)."""
	var offsets: Array[Vector2] = []
	var rows = 7
	for i in range(MAX_VISIBLE_TROOPS):
		var row = i % rows
		var col = i / rows
		var row_width = (rows - row) * 2  # Wider at back
		var x = (col % row_width - row_width / 2.0) * 6.0
		var y = -15.0 - (row * 6.0)  # In front of general
		offsets.append(Vector2(x, y))
	return offsets

func _generate_scatter_offsets(radius: float) -> Array[Vector2]:
	"""Generate scattered positions behind general."""
	var offsets: Array[Vector2] = []
	for i in range(MAX_VISIBLE_TROOPS):
		var angle = randf_range(PI / 4, 3 * PI / 4)  # Back arc
		var dist = randf() * radius + 20.0
		offsets.append(Vector2(cos(angle) * dist, sin(angle) * dist))
	return offsets

# ============================================================================
# PUBLIC API
# ============================================================================

func setup_troops(count: int, general_team: int):
	"""Initialize troop manager with troop count and team."""
	troop_count = count
	team = general_team
	
	# Clear existing dots
	for dot in troop_dots:
		if is_instance_valid(dot):
			dot.queue_free()
	troop_dots.clear()
	
	# Create visual dots
	_update_visual_troops()

func set_troop_count(count: int):
	"""Update troop count and refresh visuals."""
	if troop_count == count:
		return
	
	troop_count = count
	_update_visual_troops()

func set_formation(formation: Formation):
	"""Change formation and reposition troops."""
	if current_formation == formation:
		return
	
	current_formation = formation
	_update_troop_positions()

func _update_visual_troops():
	"""Create or destroy dots to match troop count."""
	var visible_count = min(troop_count / 2, MAX_VISIBLE_TROOPS)  # Each dot represents 2 troops
	
	# Create missing dots
	while troop_dots.size() < visible_count:
		var dot = Sprite2D.new()
		dot.texture = dot_texture
		dot.modulate = dot_color_player if team == 0 else dot_color_enemy
		dot.z_index = -1  # Behind general
		add_child(dot)
		troop_dots.append(dot)
	
	# Hide excess dots (don't destroy, just hide for performance)
	for i in range(troop_dots.size()):
		if is_instance_valid(troop_dots[i]):
			troop_dots[i].visible = i < visible_count
	
	# Update positions
	_update_troop_positions()

func _update_troop_positions():
	"""Update positions based on current formation."""
	var offsets = formation_offsets.get(current_formation, formation_offsets[Formation.ADVANCE])
	
	for i in range(troop_dots.size()):
		if not is_instance_valid(troop_dots[i]):
			continue
		
		if i < offsets.size():
			# Add some subtle noise for organic movement
			var noise = Vector2(randf() - 0.5, randf() - 0.5) * 2.0
			troop_dots[i].position = offsets[i] + noise

func _process(_delta):
	"""Optional: Add subtle animation to troop dots."""
	# Subtle bobbing motion
	var time = Time.get_time_dict_from_system()["second"]
	for i in range(troop_dots.size()):
		if is_instance_valid(troop_dots[i]) and troop_dots[i].visible:
			var offset = sin(time + i * 0.5) * 0.5
			troop_dots[i].position.y += offset * 0.01  # Very subtle
