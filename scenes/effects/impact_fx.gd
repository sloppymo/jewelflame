# ImpactFX.gd
#
# Purpose: Scene-based visual effects with optional camera shake
# Usage: Instantiate scenes, don't extend this class
# Depends: EventBus (for decoupled camera shake)
#
# Usage:
#   var fx = preload("res://scenes/effects/blood_splash.tscn").instantiate()
#   fx.global_position = hit_pos
#   fx.rotation = hit_dir.angle()
#   get_tree().current_scene.add_child(fx)
#
# Implementation based on Kimberlyclaw's professional review
# Date: 2026-03-25

class_name ImpactFX
extends Node2D

#region Exported Configuration
## Lifetime in seconds before cleanup begins (0 = wait for particles)
@export var lifetime: float = 1.0

## Fade-out duration in seconds
@export var fade_out: float = 0.3

## Camera shake strength (0 = no shake)
@export var shake_strength: float = 0.0

## Camera shake duration in seconds
@export var shake_duration: float = 0.0

## Camera shake priority (higher = more important)
@export var shake_priority: int = 0

## Destroy immediately when particles finish (if true, ignores lifetime)
@export var destroy_on_particles_done: bool = false
#endregion

#region Node References
@onready var particles: GPUParticles2D = $Particles if has_node("Particles") else null
@onready var sprite: Sprite2D = $Sprite if has_node("Sprite") else null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite if has_node("AnimatedSprite") else null
#endregion


func _ready():
	"""Initialize the impact effect."""
	# Trigger particles if present
	if particles:
		particles.emitting = true
		if destroy_on_particles_done:
			particles.finished.connect(_on_particles_done)
	
	# Trigger camera shake via EventBus (decoupled)
	if shake_strength > 0.0 and shake_duration > 0.0:
		_request_camera_shake()
	
	# Start lifetime timer
	if lifetime > 0.0 and not destroy_on_particles_done:
		_start_lifetime_timer()


#region Public API

func trigger_shake(strength: float, duration: float, priority: int = 0) -> void:
	"""Manually trigger camera shake (useful for dynamic effects).
	
	Args:
		strength: Shake intensity 0.0-1.0
		duration: Shake duration in seconds
		priority: Higher priority overrides lower priority shakes
	"""
	shake_strength = strength
	shake_duration = duration
	shake_priority = priority
	_request_camera_shake()


func fade_out_now(duration: float = -1.0) -> void:
	"""Start fade-out immediately.
	
	Args:
		duration: Override fade duration (-1 uses exported fade_out value)
	"""
	if duration < 0:
		duration = fade_out
	_fade_out(duration)


func destroy_immediately() -> void:
	"""Queue free immediately without fade."""
	queue_free()

#endregion


#region Private Methods

func _request_camera_shake() -> void:
	"""Request camera shake via EventBus."""
	# Try EventBus first (preferred, decoupled)
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus and event_bus.has_signal("CameraShakeRequested"):
		event_bus.CameraShakeRequested.emit(shake_strength, shake_duration, shake_priority)
		return
	
	# Fallback: direct call to CameraShaker
	var shaker = get_node_or_null("/root/CameraShaker")
	if shaker and shaker.has_method("shake"):
		shaker.shake(shake_strength, shake_duration, shake_priority)


func _start_lifetime_timer() -> void:
	"""Start the lifetime timer leading to fade-out."""
	var wait_time = lifetime - fade_out
	if wait_time <= 0:
		# Lifetime shorter than fade, just fade immediately
		_fade_out(fade_out)
	else:
		await get_tree().create_timer(wait_time).timeout
		if is_instance_valid(self):
			_fade_out(fade_out)


func _fade_out(duration: float) -> void:
	"""Fade out visual elements and queue free."""
	var tween = create_tween()
	
	# Fade sprite if present
	if sprite:
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, duration)
	
	# Fade animated sprite if present
	if animated_sprite:
		tween.parallel().tween_property(animated_sprite, "modulate:a", 0.0, duration)
	
	# Stop particles gracefully
	if particles:
		particles.emitting = false
	
	# Scale down for additional effect (optional polish)
	if sprite:
		tween.parallel().tween_property(sprite, "scale", Vector2.ZERO, duration)
	elif animated_sprite:
		tween.parallel().tween_property(animated_sprite, "scale", Vector2.ZERO, duration)
	
	# Queue free when done
	tween.tween_callback(queue_free)


func _on_particles_done() -> void:
	"""Called when particles finish emitting."""
	# If no sprite or sprite is already faded, destroy
	if not sprite or sprite.modulate.a <= 0.01:
		if not animated_sprite or animated_sprite.modulate.a <= 0.01:
			queue_free()
	# Otherwise let fade-out handle it

#endregion
