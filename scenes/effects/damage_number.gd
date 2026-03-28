extends Label

# Floating damage number that rises and fades

@export var rise_speed: float = 40.0
@export var fade_speed: float = 1.5
@export var spread: float = 20.0

var _velocity: Vector2
var _life: float = 1.0

func _ready():
	# Ensure we're on top of everything
	z_index = 100
	top_level = true  # Render in screen space
	
	# Random horizontal spread
	_velocity = Vector2(randf() * spread - spread/2, -rise_speed)
	
	# Random slight rotation
	rotation = randf() * 0.2 - 0.1

func _process(delta):
	position += _velocity * delta
	_life -= fade_speed * delta
	
	modulate.a = _life
	
	# Slow down the rise over time
	_velocity.y *= 0.98
	
	if _life <= 0:
		queue_free()

func set_damage(amount: int, is_critical: bool = false, is_heal: bool = false):
	if is_heal:
		text = "+" + str(amount)
	else:
		text = str(amount)
	
	if is_heal:
		modulate = Color(0.2, 1.0, 0.3, 1.0)  # Green for heals
	elif is_critical:
		modulate = Color(1.0, 0.2, 0.2, 1.0)  # Red for crits
		scale = Vector2(1.3, 1.3)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)  # White for normal
