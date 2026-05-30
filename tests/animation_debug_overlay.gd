class_name AnimationDebugOverlay
extends Node2D
## Draws debug visualization on top of an AnimatedSprite2D for animation debugging.

#region Exports
@export var show_grid: bool = true:
	set(value):
		show_grid = value
		queue_redraw()

@export var show_origin: bool = true:
	set(value):
		show_origin = value
		queue_redraw()

@export var show_frame_border: bool = true:
	set(value):
		show_frame_border = value
		queue_redraw()

@export var grid_color: Color = Color(0, 1, 0, 0.3)
@export var origin_color: Color = Color(1, 0, 0, 0.8)
@export var border_color: Color = Color(1, 1, 0, 0.6)
@export var crosshair_color: Color = Color(0, 0.8, 1, 0.7)
#endregion

#region Private Variables
var _target_sprite: AnimatedSprite2D = null
var _grid_size: Vector2i = Vector2i(16, 16)
var _frame_label: Label = null
#endregion

#region Initialization
func _ready() -> void:
	z_index = 100  # Draw on top of everything
	_setup_frame_label()

func _setup_frame_label() -> void:
	_frame_label = Label.new()
	_frame_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frame_label.add_theme_font_size_override("font_size", 10)
	_frame_label.position = Vector2(-50, -40)
	_frame_label.size = Vector2(100, 20)
	_frame_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame_label)

func attach_to_sprite(sprite: AnimatedSprite2D) -> void:
	## Attaches this overlay to follow a specific sprite
	detach()  # Clean up any existing connection
	
	_target_sprite = sprite
	
	if _target_sprite:
		_target_sprite.frame_changed.connect(_on_frame_changed)
		_update_grid_size_from_sprite()
		queue_redraw()
		_update_frame_label()
		show()

func detach() -> void:
	## Detaches from current sprite
	if _target_sprite:
		if _target_sprite.frame_changed.is_connected(_on_frame_changed):
			_target_sprite.frame_changed.disconnect(_on_frame_changed)
		_target_sprite = null
	
	hide()

func _on_frame_changed() -> void:
	queue_redraw()
	_update_frame_label()

func _process(_delta: float) -> void:
	## Follow the target sprite's position
	if _target_sprite:
		global_position = _target_sprite.global_position

func _update_frame_label() -> void:
	if not _target_sprite or not _frame_label:
		return
	
	var frame := _target_sprite.frame
	var anim := _target_sprite.animation
	var frame_count := _target_sprite.sprite_frames.get_frame_count(anim) if _target_sprite.sprite_frames.has_animation(anim) else 0
	
	_frame_label.text = "%s\nFrame: %d/%d" % [anim, frame + 1, frame_count]
#endregion

#region Grid Size Detection
func _update_grid_size_from_sprite() -> void:
	## Auto-detect grid size based on sprite name or texture size
	if not _target_sprite:
		return
	
	# Try to infer from animation name
	var anim_name := _target_sprite.animation.to_lower()
	
	if "24x24" in anim_name or "heavy" in anim_name or "dragon" in anim_name:
		_grid_size = Vector2i(24, 24)
	elif "16x16" in anim_name or "knight" in anim_name or "archer" in anim_name:
		_grid_size = Vector2i(16, 16)
	else:
		# Try to get from actual texture
		var texture := _target_sprite.sprite_frames.get_frame_texture(_target_sprite.animation, _target_sprite.frame)
		if texture:
			var size := texture.get_size()
			# Common sprite sizes
			if size.x <= 16 and size.y <= 16:
				_grid_size = Vector2i(16, 16)
			elif size.x <= 24 and size.y <= 24:
				_grid_size = Vector2i(24, 24)
			elif size.x <= 32 and size.y <= 32:
				_grid_size = Vector2i(32, 32)
#endregion

#region Drawing
func _draw() -> void:
	if not _target_sprite or not _target_sprite.visible:
		return
	
	var texture := _target_sprite.sprite_frames.get_frame_texture(_target_sprite.animation, _target_sprite.frame)
	if not texture:
		return
	
	var texture_size := texture.get_size()
	var half_size := texture_size / 2
	
	# Draw frame border
	if show_frame_border:
		_draw_frame_border(texture_size)
	
	# Draw grid
	if show_grid:
		_draw_grid(texture_size)
	
	# Draw origin point (pivot)
	if show_origin:
		_draw_origin()
	
	# Draw crosshair
	_draw_crosshair(texture_size)

func _draw_frame_border(size: Vector2) -> void:
	## Draws a border around the entire frame
	var half := size / 2
	var rect := Rect2(-half, size)
	draw_rect(rect, border_color, false, 1.5)

func _draw_grid(size: Vector2) -> void:
	## Draws a grid overlay on the sprite
	var half := size / 2
	
	# Vertical lines
	var x := 0.0
	while x < half.x:
		draw_line(Vector2(x, -half.y), Vector2(x, half.y), grid_color, 0.5)
		draw_line(Vector2(-x, -half.y), Vector2(-x, half.y), grid_color, 0.5)
		x += _grid_size.x
	
	# Horizontal lines  
	var y := 0.0
	while y < half.y:
		draw_line(Vector2(-half.x, y), Vector2(half.x, y), grid_color, 0.5)
		draw_line(Vector2(-half.x, -y), Vector2(half.x, -y), grid_color, 0.5)
		y += _grid_size.y

func _draw_origin() -> void:
	## Draws the pivot/origin point with crosshairs
	# Center dot
	draw_circle(Vector2.ZERO, 3, origin_color)
	
	# Crosshair
	var cross_size := 8.0
	draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), origin_color, 1.5)
	draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), origin_color, 1.5)

func _draw_crosshair(size: Vector2) -> void:
	## Draws a subtle crosshair aligned to the frame edges
	var half := size / 2
	var color := crosshair_color
	
	# Draw small marks at cardinal directions
	var mark_len := 5.0
	
	# Top
	draw_line(Vector2(0, -half.y), Vector2(0, -half.y + mark_len), color, 1)
	# Bottom
	draw_line(Vector2(0, half.y), Vector2(0, half.y - mark_len), color, 1)
	# Left
	draw_line(Vector2(-half.x, 0), Vector2(-half.x + mark_len, 0), color, 1)
	# Right
	draw_line(Vector2(half.x, 0), Vector2(half.x - mark_len, 0), color, 1)
#endregion

#region Public API
func set_grid_size(size: Vector2i) -> void:
	_grid_size = size
	queue_redraw()

func get_grid_size() -> Vector2i:
	return _grid_size

func toggle_grid() -> void:
	show_grid = !show_grid

func toggle_origin() -> void:
	show_origin = !show_origin

func toggle_frame_border() -> void:
	show_frame_border = !show_frame_border

func get_target_sprite() -> AnimatedSprite2D:
	return _target_sprite
#endregion
