# CameraShaker.gd
#
# Purpose: Priority-based camera shake for impact feedback
# Autoload: Yes (registered in project.godot)
# Depends: EventBus (for decoupled triggers)
#
# Usage:
#   Direct: CameraShaker.shake(0.5, 0.3, 1)
#   Event:  EventBus.CameraShakeRequested.emit(0.5, 0.3, 1)
#
# Implementation based on Kimberlyclaw's professional review
# Date: 2026-03-25

extends Node

#region Exported Configuration
## Default decay rate for shake falloff (higher = faster decay)
@export var default_decay: float = 5.0

## Maximum camera offset in pixels
@export var max_offset: float = 20.0
#endregion

#region Private State
var _shake_strength: float = 0.0
var _shake_decay: float = 0.0
var _priority: int = 0
var _current_camera: Camera2D = null
#endregion


func _ready():
	"""Initialize the camera shaker with low process priority."""
	process_priority = -100  # Run after most systems
	
	# Connect to EventBus for decoupled triggering
	if Engine.has_singleton("EventBus"):
		EventBus.CameraShakeRequested.connect(_on_shake_requested)
	else:
		# Fallback: try to get autoload directly
		var event_bus = get_node_or_null("/root/EventBus")
		if event_bus:
			event_bus.CameraShakeRequested.connect(_on_shake_requested)


func _process(delta: float):
	"""Process camera shake decay and apply offset."""
	# Early exit if shake is negligible
	if _shake_strength <= 0.001:
		_reset_shake()
		return
	
	# Get current active camera (cached reference)
	var cam = _get_active_camera()
	if cam == null:
		return
	
	# Decay with non-linear curve for natural feel
	_shake_strength = lerp(_shake_strength, 0.0, _shake_decay * delta)
	
	# Generate random offset
	var offset = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	) * _shake_strength * max_offset
	
	# Apply to camera
	cam.offset = offset


func shake(strength: float, duration: float, priority: int = 0) -> void:
	"""Trigger camera shake.
	
	Args:
		strength: 0.0-1.0 intensity of the shake
		duration: seconds for shake to decay
		priority: higher number overrides lower priority shakes
	"""
	# Don't interrupt higher priority shakes
	if priority < _priority and _shake_strength > 0.1:
		return
	
	_priority = priority
	_shake_strength = clampf(strength, 0.0, 1.0)
	_shake_decay = 1.0 / maxf(duration, 0.01)  # Prevent div by zero
	
	# Cache camera reference on first use
	if _current_camera == null:
		_current_camera = _get_active_camera()


func stop_shake() -> void:
	"""Immediately stop any active shake."""
	_reset_shake()


#region Private Methods

func _on_shake_requested(strength: float, duration: float, priority: int) -> void:
	"""Handler for EventBus signal."""
	shake(strength, duration, priority)


func _get_active_camera() -> Camera2D:
	"""Get the currently active Camera2D from the viewport."""
	var viewport = get_viewport()
	if viewport == null:
		return null
	
	var cam = viewport.get_camera_2d()
	if cam != _current_camera:
		# Camera changed, reset offset on old camera if any
		if _current_camera != null:
			_current_camera.offset = Vector2.ZERO
		_current_camera = cam
	
	return cam


func _reset_shake() -> void:
	"""Reset shake state and clear camera offset."""
	_shake_strength = 0.0
	_priority = 0
	
	# Clear camera offset
	if _current_camera != null:
		_current_camera.offset = Vector2.ZERO
		_current_camera = null

#endregion
