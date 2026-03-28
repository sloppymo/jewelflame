extends Area2D

# Magic Projectile - travels with particle effects and damages enemies

@export var speed: float = 350.0
@export var damage: int = 15
@export var max_range: float = 250.0
@export var team: int = 0
@export var is_healing: bool = false

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
	# Move the projectile
	position += _velocity * delta
	
	# Track distance traveled
	_traveled_distance += speed * delta
	
	# Destroy if max range reached
	if _traveled_distance >= max_range:
		queue_free()

func fire(direction: Vector2, shooter: Node2D, proj_damage: int, proj_team: int, healing: bool = false):
	"""Initialize the projectile."""
	_velocity = direction.normalized() * speed
	_shooter = shooter
	damage = proj_damage
	team = proj_team
	is_healing = healing
	
	# Rotate sprite to match direction
	rotation = direction.angle()

func _on_body_entered(body: Node2D):
	"""Handle collision with a body."""
	# Don't hit the shooter
	if body == _shooter:
		return
	
	# Check if it's a valid target (has team property)
	if "team" in body:
		if is_healing:
			# Heal allies
			if body.team == team and body.has_method("heal"):
				body.heal(damage)
				queue_free()
				return
		else:
			# Damage enemies
			if body.team != team and body.has_method("take_hit_ai"):
				body.take_hit_ai(damage, _velocity.normalized())
				queue_free()
				return
	
	# Hit a wall or obstacle
	queue_free()
