class_name ArrowProjectile
extends Node2D
## A visible arrow projectile shot by archers

#region Constants
const DEFAULT_SPEED: float = 400.0
const DEFAULT_LIFETIME: float = 3.0
const HIT_RADIUS: float = 15.0
#endregion

#region Variables
var direction: Vector2 = Vector2.RIGHT
var speed: float = DEFAULT_SPEED
var damage: int = 10
var lifetime: float = 0.0
var max_lifetime: float = DEFAULT_LIFETIME
var source_team: int = 0
var has_hit: bool = false

var sprite: Sprite2D = null
var trail_timer: float = 0.0
#endregion

func _ready() -> void:
	z_index = 10
	_create_sprite()

func _create_sprite() -> void:
	sprite = Sprite2D.new()
	sprite.scale = Vector2(1.5, 1.5)  # Make arrow more visible
	
	# Try to load the arrow texture
	var arrow_texture := load("res://assets/Characters(100x100)/Archer/Arrow(projectile)/Arrow02(100x100).png") as Texture2D
	if arrow_texture:
		sprite.texture = arrow_texture
	else:
		# Fallback: create a simple arrow shape
		_create_fallback_arrow()
	
	# Rotate sprite to match direction
	rotation = direction.angle()
	
	add_child(sprite)

func _create_fallback_arrow() -> void:
	## Creates a simple colored arrow if texture not found
	var img := Image.create(32, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.6, 0.4, 0.2, 0))  # Transparent background
	
	# Draw arrow shaft (brown)
	var shaft_color := Color(0.5, 0.3, 0.1)
	for x in range(8, 24):
		for y in range(2, 6):
			img.set_pixel(x, y, shaft_color)
	
	# Draw arrow head (gray/silver)
	var head_color := Color(0.7, 0.7, 0.75)
	for x in range(24, 32):
		for y in range(0, 8):
			if abs(y - 4) < (32 - x) / 2:
				img.set_pixel(x, y, head_color)
	
	# Draw fletching (red feathers)
	var feather_color := Color(0.8, 0.2, 0.1)
	for x in range(0, 8):
		img.set_pixel(x, 0, feather_color)
		img.set_pixel(x, 7, feather_color)
	
	var tex := ImageTexture.create_from_image(img)
	sprite.texture = tex

func _physics_process(delta: float) -> void:
	if has_hit:
		return
	
	lifetime += delta
	
	if lifetime > max_lifetime:
		queue_free()
		return
	
	# Move the arrow
	position += direction * speed * delta
	
	# Rotate to match direction
	rotation = direction.angle()
	
	# Check for collisions with units
	_check_collisions()

func _check_collisions() -> void:
	for unit in get_tree().get_nodes_in_group("arena_units"):
		if not is_instance_valid(unit):
			continue
		
		# Skip if same team or dead
		if unit.team == source_team or unit.is_dead:
			continue
		
		# Check distance
		var dist := position.distance_to(unit.position)
		if dist < HIT_RADIUS:
			_hit_unit(unit)
			return

func _hit_unit(unit) -> void:
	has_hit = true
	unit.take_hit(direction)
	
	# Create hit effect
	_spawn_hit_effect()
	
	queue_free()

func _spawn_hit_effect() -> void:
	## Spawn a small spark/blood effect at hit location
	var effect := ColorRect.new()
	effect.size = Vector2(8, 8)
	effect.position = position - Vector2(4, 4)
	effect.color = Color(1, 0.8, 0.5, 0.8)  # Spark color
	
	get_parent().add_child(effect)
	
	# Auto-remove after short delay
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(effect):
		effect.queue_free()

func setup(spawn_pos: Vector2, dir: Vector2, dmg: int, team: int, arrow_speed: float = DEFAULT_SPEED) -> void:
	position = spawn_pos
	direction = dir.normalized()
	damage = dmg
	source_team = team
	speed = arrow_speed
