@tool
extends Node2D

func _ready():
	queue_redraw()

func _draw():
	var size = Vector2(1280, 720)
	var grid_size = 16
	
	# Draw grid lines
	for x in range(0, int(size.x), grid_size):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(1, 1, 1, 0.1), 1.0)
	
	for y in range(0, int(size.y), grid_size):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.1), 1.0)
	
	# Draw center crosshair
	var center = Vector2(640, 360)
	draw_line(Vector2(center.x - 20, center.y), Vector2(center.x + 20, center.y), Color(1, 0, 0, 0.5), 2.0)
	draw_line(Vector2(center.x, center.y - 20), Vector2(center.x, center.y + 20), Color(1, 0, 0, 0.5), 2.0)
