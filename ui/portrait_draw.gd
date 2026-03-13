extends Control

@export var portrait_texture: Texture2D

func _ready():
	queue_redraw()

func _draw():
	if portrait_texture:
		# Draw the portrait texture scaled to fit the control size
		draw_texture_rect(portrait_texture, Rect2(Vector2.ZERO, size), false)
