extends Node2D

var fade_timer: float = 0.0
var fade_duration: float = 8.0

func _ready():
	# Create random blood splatter shape
	var num_blobs = randi() % 4 + 3
	
	for i in range(num_blobs):
		var blob = ColorRect.new()
		var size = randi() % 4 + 3
		blob.size = Vector2(size, size)
		blob.color = Color(0.5 + randf() * 0.2, 0.05, 0.05)  # Dark red variations
		
		# Random position around center
		var angle = randf() * PI * 2
		var dist = randf() * 15
		blob.position = Vector2(cos(angle) * dist, sin(angle) * dist)
		
		add_child(blob)
	
	# Random rotation
	rotation = randf() * PI * 2
	
	# Start fade after some time
	await get_tree().create_timer(3.0).timeout
	fade_timer = fade_duration

func _process(delta):
	if fade_timer > 0:
		fade_timer -= delta
		modulate.a = fade_timer / fade_duration
		if fade_timer <= 0:
			queue_free()
