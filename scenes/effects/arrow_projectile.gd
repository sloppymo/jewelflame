extends Area2D

# Arrow Projectile - travels in a straight line and damages enemies

@export var speed: float = 400.0
@export var damage: int = 10
@export var max_range: float = 300.0
@export var team: int = 0

var _velocity: Vector2 = Vector2.ZERO
var _traveled_distance: float = 0.0
var _shooter: Node2D = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# Set texture filter for pixel art
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Connect collision
	body_entered.connect(_on_body_entered)
	
	# Start animation
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("default"):
		sprite.play("default")

func _physics_process(delta: float):
	# Move the arrow
	position += _velocity * delta
	
	# Track distance traveled
	_traveled_distance += speed * delta
	
	# Destroy if max range reached
	if _traveled_distance >= max_range:
		queue_free()

func fire(direction: Vector2, shooter: Node2D, proj_damage: int, proj_team: int):
	"""Initialize the projectile."""
	_velocity = direction.normalized() * speed
	_shooter = shooter
	damage = proj_damage
	team = proj_team
	
	# Rotate sprite to match direction
	rotation = direction.angle()
	
	# Flip if moving left
	if direction.x < 0:
		sprite.flip_v = true

func _on_body_entered(body: Node2D):
	"""Handle collision with a body."""
	# Don't hit the shooter
	if body == _shooter:
		return
	
	# Check if it's a valid target (has team property and take_hit_ai method)
	if "team" in body and body.has_method("take_hit_ai"):
		# Don't hit allies
		if body.team != team:
			body.take_hit_ai(damage, _velocity.normalized())
			queue_free()
			return
	
	# Hit a wall or obstacle
	queue_free()
