@tool
extends EditorScript

# Green Dragon SpriteFrames Generator
# Frame size: 96x96 (large dragon sprites)
# Directions: right, left (2 directions, horizontal flip for other sides)

func _run() -> void:
	print("=== Green Dragon SpriteFrames Generator ===\n")
	
	var sprite_frames := SpriteFrames.new()
	
	# Load all dragon textures
	var textures := {
		"firebreath": load("res://assets/Dragon/Green Dragon/dragon_FIREBREATH_green.png"),
		"fly": load("res://assets/Dragon/Green Dragon/dragon_FLY_green.png"),
		"hover": load("res://assets/Dragon/Green Dragon/dragon_HOVER_green.png"),
		"launch": load("res://assets/Dragon/Green Dragon/dragon_LAUNCH_green.png"),
		"melee": load("res://assets/Dragon/Green Dragon/dragon_MELEE_green.png"),
		"walk": load("res://assets/Dragon/Green Dragon/dragon_WALK_green.png"),
	}
	
	var frame_size := Vector2(96, 96)
	
	# Animation definitions: [name, texture_key, frame_count, fps, loop]
	var animations: Array = [
		["firebreath", "firebreath", 64, 12.0, false],
		["fly", "fly", 24, 10.0, true],
		["hover", "hover", 24, 8.0, true],
		["launch", "launch", 32, 12.0, false],
		["melee", "melee", 24, 12.0, false],
		["walk", "walk", 24, 10.0, true],
	]
	
	for anim in animations:
		var anim_name: String = anim[0]
		var tex_key: String = anim[1]
		var frame_count: int = anim[2]
		var fps: float = anim[3]
		var loop: bool = anim[4]
		
		var texture: Texture2D = textures[tex_key]
		if not texture:
			print("  ERROR: Could not load texture for %s" % anim_name)
			continue
		
		# Create right-facing animation
		var right_name := anim_name + "_right"
		sprite_frames.add_animation(right_name)
		sprite_frames.set_animation_loop(right_name, loop)
		sprite_frames.set_animation_speed(right_name, fps)
		
		for f in range(frame_count):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(
				f * frame_size.x,
				0,  # Single row - right facing
				frame_size.x,
				frame_size.y
			)
			sprite_frames.add_frame(right_name, atlas)
		
		print("Created: %s (%d frames)" % [right_name, frame_count])
	
	var output_path := "res://assets/animations/dragon_green.tres"
	var err := ResourceSaver.save(sprite_frames, output_path)
	
	if err == OK:
		print("\nSUCCESS: Saved to %s" % output_path)
	else:
		print("\nERROR: Failed to save (code %d)" % err)
