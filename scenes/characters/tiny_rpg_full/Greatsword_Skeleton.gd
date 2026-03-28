extends TinyRPGCharacter

# Greatsword Skeleton - NON-STANDARD sprite sheet layout
# Layout: Attack01(0), Attack02(1), Attack03(2), Death(3), Hurt(4), Idle(5), Walk(6)

func _ready():
	# Override the standard sprite frame building
	if source_texture:
		build_greatsword_skeleton_frames()
	else:
		push_warning(name + ": No source_texture assigned!")
		_create_placeholder_sprite()
	
	# Apply scale (100x100 -> target size)
	scale = Vector2(target_scale, target_scale)
	
	# Set texture filter for pixel art
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Flip based on facing
	_update_facing()
	
	# Initialize health
	current_health = max_health
	
	# Add to character group for AI
	add_to_group("tiny_rpg_chars")
	add_to_group("arena_units")
	
	# Start idle
	_change_state(State.IDLE)


func build_greatsword_skeleton_frames():
	"""Build SpriteFrames for Greatsword Skeleton's layout.
	
	Greatsword Skeleton layout (7 rows) - ACTUAL ORDER:
	Row 0: Idle (6 frames)
	Row 1: Walk (9 frames)
	Row 2: Attack01 (9 frames)
	Row 3: Attack02 (12 frames)
	Row 4: Attack03 (8 frames)
	Row 5: Hurt (4 frames)
	Row 6: Death (4 frames)
	"""
	var sf = SpriteFrames.new()
	
	var tex_width = source_texture.get_width()
	var tex_height = source_texture.get_height()
	
	# Define animations with CORRECT row mappings
	var anims = [
		{"name": "idle", "row": 0, "frames": 6, "speed": 6.0, "loop": true},
		{"name": "walk", "row": 1, "frames": 8, "speed": 10.0, "loop": true},
		{"name": "attack01", "row": 2, "frames": 6, "speed": 12.0, "loop": false},
		{"name": "attack02", "row": 3, "frames": 6, "speed": 12.0, "loop": false},
		{"name": "attack03", "row": 4, "frames": 6, "speed": 14.0, "loop": false},
		{"name": "hurt", "row": 5, "frames": 4, "speed": 8.0, "loop": false},
		{"name": "death", "row": 6, "frames": 4, "speed": 6.0, "loop": false},
	]
	
	for anim in anims:
		var max_frame = mini(anim["frames"], tex_width / 100)
		
		sf.add_animation(anim["name"])
		sf.set_animation_speed(anim["name"], anim["speed"] * anim_speed_mult)
		sf.set_animation_loop(anim["name"], anim["loop"])
		
		for i in range(max_frame):
			var atlas = AtlasTexture.new()
			atlas.atlas = source_texture
			atlas.region = Rect2(
				i * 100,
				anim["row"] * 100,
				100,
				100
			)
			sf.add_frame(anim["name"], atlas)
	
	sprite.sprite_frames = sf


func _create_placeholder_sprite() -> void:
	var placeholder = PlaceholderTexture2D.new()
	placeholder.size = Vector2(100, 100)
	
	var sf = SpriteFrames.new()
	sf.add_animation("idle")
	sf.add_frame("idle", placeholder)
	sprite.sprite_frames = sf


func _die():
	"""Override to ensure death animation plays."""
	is_dead = true
	current_health = 0
	velocity = Vector2.ZERO
	_knockback_velocity = Vector2.ZERO
	_change_state(State.DEAD)
	collision_layer = 0
	collision_mask = 0
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)
