extends Control

@export var banner_texture: Texture2D

func _ready():
	queue_redraw()

func _draw():
	if banner_texture:
		# Calculate aspect-ratio-preserving rectangle
		var tex_size = banner_texture.get_size()
		var target_size = size
		
		# Calculate scale to fit while preserving aspect ratio
		var scale_x = target_size.x / tex_size.x
		var scale_y = target_size.y / tex_size.y
		var scale = min(scale_x, scale_y)
		
		# Calculate the scaled size
		var scaled_size = tex_size * scale
		
		# Center the texture
		var pos = (target_size - scaled_size) / 2
		
		# Draw the texture with aspect ratio preserved
		draw_texture_rect(banner_texture, Rect2(pos, scaled_size), false)
