extends Node2D

var blood_colors = [
	Color(0.8, 0.1, 0.1),
	Color(0.6, 0.05, 0.05),
	Color(0.9, 0.2, 0.2)
]

var particles = []
var gravity = 200.0

func _ready():
	print("Blood spawned at: ", global_position)
	
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(randi() % 3 + 2, randi() % 3 + 2)
		particle.color = blood_colors[randi() % blood_colors.size()]
		particle.position = Vector2(randi() % 20 - 10, randi() % 20 - 10)
		add_child(particle)
		
		particles.append({
			"node": particle,
			"velocity": Vector2(randf() * 100 - 50, randf() * -80 - 20),
			"life": randf() * 0.5 + 0.5
		})
	
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _process(delta):
	for p in particles:
		p["life"] -= delta
		p["velocity"].y += gravity * delta
		p["node"].position += p["velocity"] * delta
		if p["life"] < 0.3:
			p["node"].modulate.a = p["life"] / 0.3
