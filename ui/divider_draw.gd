extends Control

@export var divider_texture: Texture2D
@export var divider_height: float = 16.0

func _ready():
	queue_redraw()

func _draw():
	if divider_texture:
		# Calculate size to fit width while preserving aspect ratio
		var tex_size = divider_texture.get_size()
		var target_width = size.x
		var target_height = divider_height
		
		# Scale to fit the width, maintaining aspect ratio
		var scale = target_width / tex_size.x
		var scaled_height = tex_size.y * scale
		
		# If scaled height exceeds target, scale down
		if scaled_height > target_height:
			scale = target_height / tex_size.y
			target_width = tex_size.x * scale
			scaled_height = target_height
		
		var scaled_size = Vector2(target_width, scaled_height)
		
		# Center vertically in the control
		var pos = Vector2(0, (size.y - scaled_height) / 2)
		
		# Draw the texture
		draw_texture_rect(divider_texture, Rect2(pos, scaled_size), false)
