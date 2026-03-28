# Projectile.gd
#
# Purpose: Physics-correct projectile with piercing and proper collision timing
# Usage: Instantiate, call setup(), add to scene
# Depends: None (self-contained)
#
# Usage:
#   var proj = preload("res://scenes/combat/projectile.tscn").instantiate()
#   proj.setup(direction, damage, speed)
#   proj.impact_fx = preload("res://scenes/effects/blood_splash.tscn")
#   proj.target_groups = ["enemies", "destructible"]
#   get_tree().current_scene.add_child(proj)
#
# Implementation based on Kimberlyclaw's professional review
# Date: 2026-03-25

class_name Projectile
extends Area2D

#region Signals
## Emitted when projectile hits a valid target
signal hit(target: Node2D, pos: Vector2)

## Emitted when projectile expires without hitting anything
signal missed(pos: Vector2)
#endregion

#region Exported Configuration - Movement
@export_group("Movement")

## Projectile speed in pixels per second
@export var speed: float = 400.0

## Maximum lifetime in seconds before auto-destruction
@export var lifetime: float = 5.0

## Whether to rotate the visual node to face movement direction
@export var rotate_visual: bool = true
#endregion

#region Exported Configuration - Combat
@export_group("Combat")

## Damage dealt on hit
@export var damage: float = 50.0

## Number of enemies to pierce through (0 = destroy on first hit)
@export var pierce: int = 0

## Target groups to collide with (uses OR logic)
@export var target_groups: Array[StringName] = [&"enemies"]
#endregion

#region Exported Configuration - FX
@export_group("FX")

## Scene to spawn on impact (should be ImpactFX or similar)
@export var impact_fx: PackedScene

## Whether to spawn trail particles (child node)
@export var trail_particles: bool = false
#endregion

#region Private State
var velocity: Vector2 = Vector2.RIGHT
var _hit_targets: Array[Node2D] = []
var _spawn_frames: int = 2  # Wait for Area2D init
var _initialized: bool = false
#endregion

#region Node References
@onready var visual: Node2D = $Visual if has_node("Visual") else null
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
#endregion


func _ready():
	"""Initialize projectile with safety delay for Area2D."""
	# Connect collision signals
	body_entered.connect(_on_hit_body)
	area_entered.connect(_on_hit_area)
	
	# SAFETY: Disable briefly to prevent immediate collision with spawner
	monitoring = false
	monitorable = false
	set_physics_process(false)
	
	# Re-enable after 2 physics frames
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	if not is_instance_valid(self):
		return
	
	monitoring = true
	monitorable = true
	set_physics_process(true)
	_initialized = true


func _physics_process(delta: float):
	"""Move projectile and check lifetime."""
	if not _initialized:
		return
	
	# Move projectile
	position += velocity * speed * delta
	
	# Rotate visual to face movement direction
	if rotate_visual and visual:
		visual.rotation = velocity.angle()
	
	# Decay lifetime
	lifetime -= delta
	if lifetime <= 0.0:
		_expire()


#region Public API

func setup(dir: Vector2, dmg: float, spd: float = -1.0) -> void:
	"""Configure projectile after instantiation.
	
	Args:
		dir: Movement direction (will be normalized)
		dmg: Damage to deal on hit
		spd: Speed override (-1 uses exported speed value)
	"""
	velocity = dir.normalized()
	damage = dmg
	if spd > 0.0:
		speed = spd


func setup_from_to(from_pos: Vector2, to_pos: Vector2, dmg: float, spd: float = -1.0) -> void:
	"""Setup projectile direction from source to target position.
	
	Args:
		from_pos: Starting position (usually global_position before adding to tree)
		to_pos: Target position to aim at
		dmg: Damage to deal on hit
		spd: Speed override (-1 uses exported speed value)
	"""
	global_position = from_pos
	var dir = to_pos - from_pos
	setup(dir, dmg, spd)


func set_visual_rotation_offset(offset_degrees: float) -> void:
	"""Add rotation offset to visual (useful for asymmetric sprites).
	
	Args:
		offset_degrees: Rotation offset in degrees
	"""
	if visual:
		visual.rotation_degrees += offset_degrees


func ignore_body(body: Node2D) -> void:
	"""Add a body to ignore list (e.g., the shooter).
	
	Args:
		body: Node to ignore collisions with
	"""
	if body not in _hit_targets:
		_hit_targets.append(body)

#endregion


#region Private Methods - Collision

func _on_hit_body(body: Node2D) -> void:
	"""Handle collision with physics bodies."""
	if not _can_hit(body):
		return
	
	_process_hit(body)


func _on_hit_area(area: Area2D) -> void:
	"""Handle collision with other areas (shields, weak points)."""
	if not _can_hit(area):
		return
	
	_process_hit(area)


func _can_hit(body: Node) -> bool:
	"""Check if body is a valid target.
	
	Returns:
		true if body can be hit, false otherwise
	"""
	# Already hit this target?
	if body in _hit_targets:
		return false
	
	# Check target groups (any match is valid)
	for group in target_groups:
		if body.is_in_group(group):
			return true
	
	return false


func _process_hit(target: Node2D) -> void:
	"""Process a valid hit.
	
	Order: 1) Apply damage, 2) Emit signal, 3) Spawn FX
	This order ensures damage happens before FX in case target dies.
	"""
	_hit_targets.append(target)
	
	# 1. Apply damage FIRST
	if target.has_method(&"take_damage"):
		target.take_damage(damage)
	elif target.has_method(&"damage"):
		target.damage(damage)
	
	# 2. Signal for gameplay hooks
	hit.emit(target, global_position)
	
	# 3. Spawn FX AFTER damage (target might die and free itself)
	_spawn_impact_fx()
	
	# 4. Handle piercing - destroy when pierce EXHAUSTED
	if pierce <= 0:
		queue_free()
	else:
		pierce -= 1


func _spawn_impact_fx() -> void:
	"""Spawn impact effect scene if configured."""
	if impact_fx == null:
		print("Projectile: No impact_fx configured")
		return
	
	var fx = impact_fx.instantiate()
	if not fx is Node2D:
		push_warning("Projectile: impact_fx must be a Node2D scene")
		return
	
	fx.global_position = global_position
	fx.rotation = velocity.angle()
	
	print("Projectile: Spawning impact FX at ", global_position)
	
	# Add to current scene (deferred to avoid physics issues)
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.call_deferred(&"add_child", fx)
	else:
		get_tree().root.call_deferred(&"add_child", fx)


func _expire() -> void:
	"""Handle projectile expiration (lifetime ended without hit)."""
	missed.emit(global_position)
	queue_free()

#endregion
