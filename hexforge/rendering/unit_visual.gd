## HexForge/Rendering/UnitVisual
## Visual representation of a unit on the battlefield
## Handles sprite display, movement animations, and combat effects
## Part of HexForge battle system

class_name UnitVisual
extends Node2D

# ============================================================================
# CONFIGURATION
# ============================================================================

## Unit appearance
@export var unit_color: Color = Color.WHITE
@export var unit_radius: float = 12.0
@export var selection_ring_width: float = 2.0

## Animation settings
@export var move_duration: float = 0.3
@export var move_ease: Tween.EaseType = Tween.EASE_IN_OUT
@export var move_trans: Tween.TransitionType = Tween.TRANS_QUAD

@export var attack_duration: float = 0.2
@export var attack_shake_intensity: float = 4.0
@export var hit_flash_duration: float = 0.15

@export var defeat_duration: float = 0.5
@export var defeat_scale: float = 0.1

## Elevation settings
@export var elevation_height_per_level: float = 8.0

# ============================================================================
# STATE
# ============================================================================

var unit_id: String = ""
var unit_type: String = "infantry"
var side: String = "attacker"
var current_cube: Vector3i = Vector3i.ZERO
var is_selected: bool = false
var is_animating: bool = false

## Visual components
var _sprite: Sprite2D = null
var _selection_ring: Node2D = null

## Active tween references (for cleanup)
var _active_tweens: Array[Tween] = []

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(p_unit_id: String = "", p_unit_type: String = "infantry", p_side: String = "attacker") -> void:
	unit_id = p_unit_id
	unit_type = p_unit_type
	side = p_side

func _ready() -> void:
	_setup_visual()
	_setup_selection_ring()

func _setup_visual() -> void:
	# Create sprite (placeholder - can be replaced with actual unit sprites)
	_sprite = Sprite2D.new()
	
	# Generate a simple placeholder texture based on unit type and side
	_sprite.texture = _create_unit_texture()
	_sprite.modulate = _get_side_color()
	
	add_child(_sprite)

func _create_unit_texture() -> Texture2D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	var center := Vector2i(16, 16)
	var radius := 12
	
	# Draw filled circle
	for x in range(32):
		for y in range(32):
			var dist := Vector2i(x, y).distance_to(center)
			if dist <= radius:
				# Base circle
				var alpha := 1.0
				if dist > radius - 2:
					alpha = 0.8  # Slight edge transparency
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
			elif dist <= radius + 2:
				# Border
				image.set_pixel(x, y, Color(0.2, 0.2, 0.2, 0.8))
	
	# Add unit type indicator in center
	_draw_unit_type_indicator(image)
	
	return ImageTexture.create_from_image(image)

func _draw_unit_type_indicator(image: Image) -> void:
	var color := Color.BLACK
	
	match unit_type:
		"infantry":
			# Draw a simple "I"
			for y in range(10, 22):
				image.set_pixel(15, y, color)
				image.set_pixel(16, y, color)
		"cavalry":
			# Draw a "C"
			for x in range(12, 20):
				image.set_pixel(x, 10, color)
				image.set_pixel(x, 21, color)
			for y in range(11, 21):
				image.set_pixel(12, y, color)
		"archer":
			# Draw an "A" (bow shape)
			for y in range(10, 22):
				image.set_pixel(11 + (y - 10) / 3, y, color)
				image.set_pixel(20 - (y - 10) / 3, y, color)
			image.set_pixel(15, 16, color)
			image.set_pixel(16, 16, color)
		_:
			# Default dot
			for x in range(14, 18):
				for y in range(14, 18):
					image.set_pixel(x, y, color)

func _get_side_color() -> Color:
	match side:
		"attacker":
			return Color(0.8, 0.3, 0.3)  # Reddish
		"defender":
			return Color(0.3, 0.5, 0.8)  # Bluish
		_:
			return Color.WHITE

func _setup_selection_ring() -> void:
	_selection_ring = Node2D.new()
	_selection_ring.visible = false
	add_child(_selection_ring)

func _draw_selection_ring() -> void:
	if _selection_ring == null:
		return
	
	# Clear previous drawing
	_selection_ring.queue_redraw()

func _draw() -> void:
	# Draw selection ring if selected
	if is_selected and _selection_ring == self:
		var radius := unit_radius + 4
		var points := PackedVector2Array()
		
		for i in range(32):
			var angle := TAU * i / 32.0
			points.append(Vector2(cos(angle), sin(angle)) * radius)
		
		draw_polyline(points, Color(1, 0.8, 0), selection_ring_width, true)

# ============================================================================
# POSITION MANAGEMENT
# ============================================================================

## Sets the unit's world position immediately (no animation)
func set_world_position(world_pos: Vector2, elevation: int = 0) -> void:
	position = world_pos - Vector2(0, elevation * elevation_height_per_level)

## Gets the current world position
func get_world_position() -> Vector2:
	return position

## Sets the cube coordinate (updates position immediately)
func set_cube(cube: Vector3i, hex_size: float, elevation: int = 0) -> void:
	current_cube = cube
	var world_pos := HexMath.cube_to_world(cube, hex_size)
	set_world_position(world_pos, elevation)

# ============================================================================
# ANIMATIONS
# ============================================================================

## Animates unit movement from current position to target
func animate_move(target_world_pos: Vector2, target_elevation: int = 0, 
				  on_complete: Callable = Callable()) -> void:
	if is_animating:
		_kill_active_tweens()
	
	is_animating = true
	
	# Calculate target position with elevation
	var target_pos := target_world_pos - Vector2(0, target_elevation * elevation_height_per_level)
	
	# Create movement tween
	var tween := create_tween()
	tween.set_ease(move_ease)
	tween.set_trans(move_trans)
	
	# Add a slight arc for visual appeal
	var mid_pos := (position + target_pos) / 2.0
	mid_pos.y -= 10  # Arc height
	
	# Two-part movement: up then down (arc)
tween.tween_property(self, "position", mid_pos, move_duration * 0.5)
	tween.tween_property(self, "position", target_pos, move_duration * 0.5)
	
	_active_tweens.append(tween)
	
	tween.finished.connect(func():
		is_animating = false
		_active_tweens.erase(tween)
		if on_complete.is_valid():
			on_complete.call()
	)

## Animates unit movement along a path (multiple hexes)
func animate_path(path: Array[Vector3i], hex_size: float, 
				 on_complete: Callable = Callable()) -> void:
	if path.is_empty():
		if on_complete.is_valid():
			on_complete.call()
		return
	
	_animate_path_segment(path, 0, hex_size, on_complete)

func _animate_path_segment(path: Array[Vector3i], index: int, hex_size: float,
						   on_complete: Callable) -> void:
	if index >= path.size():
		# Path complete
		current_cube = path[path.size() - 1]
		if on_complete.is_valid():
			on_complete.call()
		return
	
	var cube := path[index]
	var world_pos := HexMath.cube_to_world(cube, hex_size)
	
	# Get elevation at this cell (would need grid reference in real usage)
	var elevation := 0
	
	# Animate to this position, then continue to next
	animate_move(world_pos, elevation, func():
		current_cube = cube
		_animate_path_segment(path, index + 1, hex_size, on_complete)
	)

## Animates an attack (shake toward target)
func animate_attack(target_world_pos: Vector2, on_complete: Callable = Callable()) -> void:
	if is_animating:
		_kill_active_tweens()
	
	is_animating = true
	
	var original_pos := position
	var direction := (target_world_pos - position).normalized()
	var attack_pos := position + direction * attack_shake_intensity
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	
	# Lunge toward target and back
	tween.tween_property(self, "position", attack_pos, attack_duration * 0.3)
	tween.tween_property(self, "position", original_pos, attack_duration * 0.7)
	
	_active_tweens.append(tween)
	
	tween.finished.connect(func():
		is_animating = false
		_active_tweens.erase(tween)
		if on_complete.is_valid():
			on_complete.call()
	)

## Animates taking damage (flash red and shake)
func animate_hit(on_complete: Callable = Callable()) -> void:
	var original_modulate := _sprite.modulate if _sprite else Color.WHITE
	
	# Flash red
	if _sprite:
		_sprite.modulate = Color(1, 0.3, 0.3)
	
	# Shake
	var tween := create_tween()
	var original_pos := position
	
	for i in range(5):
		var offset := Vector2(randf_range(-3, 3), randf_range(-3, 3))
		tween.tween_property(self, "position", original_pos + offset, 0.03)
	
	tween.tween_property(self, "position", original_pos, 0.03)
	
	tween.finished.connect(func():
		if _sprite:
			_sprite.modulate = original_modulate
		if on_complete.is_valid():
			on_complete.call()
	)

## Animates unit defeat (shrink and fade)
func animate_defeat(on_complete: Callable = Callable()) -> void:
	if is_animating:
		_kill_active_tweens()
	
	is_animating = true
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Scale down and fade
	tween.parallel().tween_property(self, "scale", Vector2(defeat_scale, defeat_scale), defeat_duration)
	
	if _sprite:
		tween.parallel().tween_property(_sprite, "modulate:a", 0.0, defeat_duration)
	
	_active_tweens.append(tween)
	
	tween.finished.connect(func():
		is_animating = false
		_active_tweens.erase(tween)
		visible = false
		if on_complete.is_valid():
			on_complete.call()
	)

## Animates unit spawn (grow from small)
func animate_spawn(on_complete: Callable = Callable()) -> void:
	visible = true
	scale = Vector2(0.1, 0.1)
	
	if _sprite:
		_sprite.modulate.a = 0.0
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	tween.parallel().tween_property(self, "scale", Vector2(1, 1), 0.3)
	
	if _sprite:
		_sprite.modulate.a = 0.0
		tween.parallel().tween_property(_sprite, "modulate:a", 1.0, 0.3)
	
	tween.finished.connect(func():
		if on_complete.is_valid():
			on_complete.call()
	)

## Skips all active animations and jumps to final state
func skip_animations() -> void:
	_kill_active_tweens()
	is_animating = false

func _kill_active_tweens() -> void:
	for tween in _active_tweens:
		if tween.is_valid():
			tween.kill()
	_active_tweens.clear()

# ============================================================================
# SELECTION
# ============================================================================

func set_selected(selected: bool) -> void:
	is_selected = selected
	
	# Update selection ring visibility
	if _selection_ring:
		_selection_ring.visible = selected
	
	queue_redraw()

func get_selected() -> bool:
	return is_selected

# ============================================================================
# UTILITY
# ============================================================================

func randf_range(min_val: float, max_val: float) -> float:
	return randf() * (max_val - min_val) + min_val
