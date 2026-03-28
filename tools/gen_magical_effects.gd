@tool
extends EditorScript

# Magical Effects SpriteFrames Generator
# Generates animated effects for spells and elemental attacks

func _run() -> void:
	print("Generating Magical Effects SpriteFrames...")
	
	# Elemental Spellcasting Effects v1 (8x8 frames)
	_generate_8x8_effects(
		"res://assets/Citizens-Guards-Warriors/Magical Effects/Elemental_Spellcasting_Effects_v1_Anti_Alias_glow_8x8.png",
		"res://assets/animations/effects/elemental_spellcasting_v1.tres",
		["fire", "ice", "lightning", "earth", "wind", "water", "holy", "dark"]
	)
	
	# Elemental Spellcasting Effects v2 (8x8 frames)
	_generate_8x8_effects(
		"res://assets/Citizens-Guards-Warriors/Magical Effects/Elemental_Spellcasting_Effects_v2_8x8.png",
		"res://assets/animations/effects/elemental_spellcasting_v2.tres",
		["fire2", "ice2", "lightning2", "earth2", "wind2", "water2", "holy2", "dark2"]
	)
	
	# Extra Elemental Effects (14x14 frames)
	_generate_14x14_effects(
		"res://assets/Citizens-Guards-Warriors/Magical Effects/Extra_Elemental_Spellcasting_Effects_Anti-Alias_glow_14x14.png",
		"res://assets/animations/effects/extra_elemental.tres",
		["burst", "nova", "shield", "heal", "poison", "sleep", "confuse", "shield2"]
	)
	
	# Fire Explosion (28x28 frames)
	_generate_explosion(
		"res://assets/Citizens-Guards-Warriors/Magical Effects/Fire_Explosion_Anti-Alias_glow.png",
		"res://assets/animations/effects/fire_explosion.tres",
		28, 28, 12, "fire_explosion"
	)
	
	# Fire Explosion Isometric (28x28 frames)
	_generate_explosion(
		"res://assets/Citizens-Guards-Warriors/Magical Effects/Fire_Explosion_ISOMETRIC_Anti-Alias_glow_28x28.png",
		"res://assets/animations/effects/fire_explosion_iso.tres",
		28, 28, 12, "fire_explosion_iso"
	)
	
	# Large Fire (28x28 frames)
	_generate_explosion(
		"res://assets/Citizens-Guards-Warriors/Magical Effects/Large_Fire_Anti-Alias_glow_28x28.png",
		"res://assets/animations/effects/large_fire.tres",
		28, 28, 12, "large_fire"
	)
	
	# Ice Burst (48x48 frames)
	_generate_explosion(
		"res://assets/Citizens-Guards-Warriors/Magical Effects/Ice-Burst_crystal_48x48_Anti-Alias_glow.png",
		"res://assets/animations/effects/ice_burst.tres",
		48, 48, 8, "ice_burst"
	)
	
	# Lightning Blast (54x18 frames)
	_generate_lightning_blast(
		"res://assets/Citizens-Guards-Warriors/Magical Effects/Lightning_Blast_Anti-Alias_glow_54x18.png",
		"res://assets/animations/effects/lightning_blast.tres"
	)
	
	# Red Lightning Blast
	_generate_lightning_blast(
		"res://assets/Citizens-Guards-Warriors/Magical Effects/Red_Lightning_Blast_Anti-Alias_glow_54x18.png",
		"res://assets/animations/effects/red_lightning_blast.tres",
		"red_"
	)
	
	# Lightning Energy (48x48 frames)
	_generate_explosion(
		"res://assets/Citizens-Guards-Warriors/Magical Effects/Lightning_Energy_Anti-Alias_glow_48x48.png",
		"res://assets/animations/effects/lightning_energy.tres",
		48, 48, 8, "lightning_energy"
	)
	
	# Red Energy (48x48 frames)
	_generate_explosion(
		"res://assets/Citizens-Guards-Warriors/Magical Effects/Red_Energy_Anti-Alias_glow_48x48.png",
		"res://assets/animations/effects/red_energy.tres",
		48, 48, 8, "red_energy"
	)
	
	print("\nAll magical effects generated successfully!")

func _generate_8x8_effects(texture_path: String, output_path: String, effect_names: Array) -> void:
	print("\nGenerating 8x8 effects: %s" % texture_path.get_file())
	
	var sprite_frames := SpriteFrames.new()
	var texture: Texture2D = load(texture_path)
	
	if not texture:
		print("ERROR: Could not load texture: %s" % texture_path)
		return
	
	var frame_size := Vector2(8, 8)
	var frames_per_effect := 4
	
	for i in range(effect_names.size()):
		var effect_name: String = effect_names[i]
		var start_row := i * 2  # Each effect takes 2 rows (4 frames each)
		
		sprite_frames.add_animation(effect_name)
		sprite_frames.set_animation_loop(effect_name, false)
		sprite_frames.set_animation_speed(effect_name, 12.0)
		
		for f in range(frames_per_effect):
			var col := f % 2
			var row := start_row + (f / 2)
			
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(
				col * frame_size.x,
				row * frame_size.y,
				frame_size.x,
				frame_size.y
			)
			sprite_frames.add_frame(effect_name, atlas)
		
		print("  Created: %s" % effect_name)
	
	var err := ResourceSaver.save(sprite_frames, output_path)
	if err == OK:
		print("  Saved: %s" % output_path)
	else:
		print("  ERROR saving: %s (code %d)" % [output_path, err])

func _generate_14x14_effects(texture_path: String, output_path: String, effect_names: Array) -> void:
	print("\nGenerating 14x14 effects: %s" % texture_path.get_file())
	
	var sprite_frames := SpriteFrames.new()
	var texture: Texture2D = load(texture_path)
	
	if not texture:
		print("ERROR: Could not load texture: %s" % texture_path)
		return
	
	var frame_size := Vector2(14, 14)
	var frames_per_effect := 4
	
	for i in range(effect_names.size()):
		var effect_name: String = effect_names[i]
		var start_row := i * 2
		
		sprite_frames.add_animation(effect_name)
		sprite_frames.set_animation_loop(effect_name, false)
		sprite_frames.set_animation_speed(effect_name, 12.0)
		
		for f in range(frames_per_effect):
			var col := f % 2
			var row := start_row + (f / 2)
			
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(
				col * frame_size.x,
				row * frame_size.y,
				frame_size.x,
				frame_size.y
			)
			sprite_frames.add_frame(effect_name, atlas)
		
		print("  Created: %s" % effect_name)
	
	var err := ResourceSaver.save(sprite_frames, output_path)
	if err == OK:
		print("  Saved: %s" % output_path)
	else:
		print("  ERROR saving: %s (code %d)" % [output_path, err])

func _generate_explosion(texture_path: String, output_path: String, frame_w: int, frame_h: int, frame_count: int, anim_name: String) -> void:
	print("\nGenerating explosion: %s" % texture_path.get_file())
	
	var sprite_frames := SpriteFrames.new()
	var texture: Texture2D = load(texture_path)
	
	if not texture:
		print("ERROR: Could not load texture: %s" % texture_path)
		return
	
	var frame_size := Vector2(frame_w, frame_h)
	
	sprite_frames.add_animation(anim_name)
	sprite_frames.set_animation_loop(anim_name, false)
	sprite_frames.set_animation_speed(anim_name, 12.0)
	
	for f in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(
			f * frame_size.x,
			0,
			frame_size.x,
			frame_size.y
		)
		sprite_frames.add_frame(anim_name, atlas)
	
	print("  Created: %s (%d frames)" % [anim_name, frame_count])
	
	var err := ResourceSaver.save(sprite_frames, output_path)
	if err == OK:
		print("  Saved: %s" % output_path)
	else:
		print("  ERROR saving: %s (code %d)" % [output_path, err])

func _generate_lightning_blast(texture_path: String, output_path: String, prefix: String = "") -> void:
	print("\nGenerating lightning blast: %s" % texture_path.get_file())
	
	var sprite_frames := SpriteFrames.new()
	var texture: Texture2D = load(texture_path)
	
	if not texture:
		print("ERROR: Could not load texture: %s" % texture_path)
		return
	
	var frame_size := Vector2(54, 18)
	var frame_count := 6
	
	sprite_frames.add_animation(prefix + "lightning_blast")
	sprite_frames.set_animation_loop(prefix + "lightning_blast", false)
	sprite_frames.set_animation_speed(prefix + "lightning_blast", 15.0)
	
	for f in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(
			f * frame_size.x,
			0,
			frame_size.x,
			frame_size.y
		)
		sprite_frames.add_frame(prefix + "lightning_blast", atlas)
	
	print("  Created: %slightning_blast (%d frames)" % [prefix, frame_count])
	
	var err := ResourceSaver.save(sprite_frames, output_path)
	if err == OK:
		print("  Saved: %s" % output_path)
	else:
		print("  ERROR saving: %s (code %d)" % [output_path, err])
