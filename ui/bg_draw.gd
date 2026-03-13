extends Control

func _ready():
	print("Bg Control ready, size: ", size)
	queue_redraw()

func _draw():
	print("Drawing Bg rect, size: ", size)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.102, 0.102, 0.18, 1))
