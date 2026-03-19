class_name ArmyMarker
extends CharacterBody2D

const StrategicProvince = preload("res://resources/data_classes/strategic_province.gd")

## Army Marker - Represents a general + troops on the strategic map
## Moves between province nodes, triggers battles on collision

signal movement_started(target_province: StrategicProvince)
signal movement_completed(province: StrategicProvince)
signal selected(army: ArmyMarker)

# Identity
@export var faction: StringName = &""
@export var is_player_controlled: bool = false
@export var general_name: String = "General"

# Movement
@export var move_speed: float = 100.0  # Pixels per second
var current_province: StringName = &""
var target_province: StrategicProvince = null
var is_moving: bool = false
var move_progress: float = 0.0
var start_position: Vector2 = Vector2.ZERO

# State
var is_alive: bool = true
var troop_count: int = 100

# Visual
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var selection_ring: ColorRect = $SelectionRing
@onready var troop_label: Label = $TroopLabel

# Animation
var facing_direction: String = "s"

func _ready():
	add_to_group("army_markers")
	print("ArmyMarker: _ready() called for ", general_name)
	print("ArmyMarker: sprite node = ", sprite)
	print("ArmyMarker: sprite_frames = ", sprite.sprite_frames if sprite else "null")
	_setup_visuals()
	_play_animation("idle")

func _setup_visuals():
	# Set color based on faction (tint the sprites)
	if sprite:
		match faction:
			&"blanche":
				sprite.modulate = Color(0.3, 0.5, 1.0)  # Blue
			&"lyle":
				sprite.modulate = Color(1.0, 0.3, 0.3)  # Red
			&"coryll":
				sprite.modulate = Color(1.0, 0.8, 0.2)  # Gold
			_:
				sprite.modulate = Color(0.7, 0.7, 0.7)  # Gray
	
	# Hide selection ring by default
	if selection_ring:
		selection_ring.visible = false
	
	# Setup troop label
	_update_troop_label()

func _update_troop_label():
	if troop_label:
		troop_label.text = str(troop_count)

func _play_animation(anim_name: String):
	"""Play animation with facing direction."""
	var full_anim = anim_name + "_" + facing_direction
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(full_anim):
		sprite.play(full_anim)

func _update_facing(direction: Vector2):
	"""Update facing direction based on movement vector."""
	if direction.length() < 0.1:
		return
	
	var angle = direction.angle()
	var degrees = rad_to_deg(angle)
	degrees = fmod(degrees + 360.0, 360.0)
	
	# 8-direction mapping
	if degrees >= 337.5 or degrees < 22.5:
		facing_direction = "e"
	elif degrees >= 22.5 and degrees < 67.5:
		facing_direction = "se"
	elif degrees >= 67.5 and degrees < 112.5:
		facing_direction = "s"
	elif degrees >= 112.5 and degrees < 157.5:
		facing_direction = "sw"
	elif degrees >= 157.5 and degrees < 202.5:
		facing_direction = "w"
	elif degrees >= 202.5 and degrees < 247.5:
		facing_direction = "nw"
	elif degrees >= 247.5 and degrees < 292.5:
		facing_direction = "n"
	else:
		facing_direction = "ne"

# ============================================================================
# MOVEMENT
# ============================================================================

func start_movement(target: StrategicProvince):
	"""Start moving to a target province."""
	if is_moving or not is_alive:
		return
	
	target_province = target
	start_position = global_position
	move_progress = 0.0
	is_moving = true
	
	# Calculate direction for facing
	var direction = (target.map_position - start_position).normalized()
	_update_facing(direction)
	_play_animation("walk")
	
	var distance = start_position.distance_to(target.map_position)
	var duration = distance / move_speed
	
	print("ArmyMarker: %s moving from %s to %s (%.1f seconds)" % [general_name, current_province, target.id, duration])
	movement_started.emit(target)

func _physics_process(delta):
	if not is_moving or not target_province:
		return
	
	# Calculate total distance and duration
	var total_distance = start_position.distance_to(target_province.map_position)
	var duration = total_distance / move_speed
	
	# Update progress
	move_progress += delta / duration
	
	if move_progress >= 1.0:
		# Arrived
		global_position = target_province.map_position
		current_province = target_province.id
		is_moving = false
		_play_animation("idle")
		print("ArmyMarker: %s arrived at %s" % [general_name, target_province])
		movement_completed.emit(target_province)
		target_province = null
	else:
		# Lerp position
		global_position = start_position.lerp(target_province.map_position, move_progress)

# ============================================================================
# SELECTION
# ============================================================================

func select():
	"""Select this army."""
	if selection_ring:
		selection_ring.visible = true
	selected.emit(self)

func deselect():
	"""Deselect this army."""
	if selection_ring:
		selection_ring.visible = false

# ============================================================================
# INPUT
# ============================================================================

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if is_player_controlled:
				select()

# ============================================================================
# COMBAT
# ============================================================================

func mark_defeated():
	"""Mark this army as defeated (after losing battle)."""
	is_alive = false
	if sprite:
		sprite.modulate = Color(0.2, 0.2, 0.2, 0.5)  # Dark and transparent
		_play_animation("death")
	if selection_ring:
		selection_ring.visible = false

func update_troops(count: int):
	"""Update troop count display."""
	troop_count = count
	_update_troop_label()
