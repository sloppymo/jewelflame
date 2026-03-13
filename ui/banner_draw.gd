extends Control

@export var banner_texture: Texture2D

func _ready():
	queue_redraw()

func _draw():
	if banner_texture:
		# Draw the banner texture scaled to fit the control size
		draw_texture_rect(banner_texture, Rect2(Vector2.ZERO, size), false)
