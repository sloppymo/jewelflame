@tool
extends EditorScript

# Complete Magical Effects Generator
# Imports ALL effects from assets/Magical Effects/

func _run() -> void:
	print("=== Complete Magical Effects Generator ===\n")
	
	var base_path := "res://assets/Magical Effects"
	
	# 8x8 Elemental Effects v1 (Anti-Alias glow)
	print("--- 8x8 Elemental Effects v1 (Glow) ---")
	_generate_8x8_effects(
		base_path + "/Elemental_Spellcasting_Effects_v1_Anti_Alias_glow_8x8.png",
		"res://assets/animations/effects/elemental_v1_glow.tres",
		["fire_glow", "ice_glow", "lightning_glow", "earth_glow", 
		 "wind_glow", "water_glow", "holy_glow", "dark_glow"]
	)
	
	# 8x8 Elemental Effects v2 (no glow)
	print("\n--- 8x8 Elemental Effects v2 ---")
	_generate_8x8_effects(
		base_path + "/Elemental_Spellcasting_Effects_v2_8x8.png",
		"res://assets/animations/effects/elemental_v2.tres",
		["fire_v2", "ice_v2", "lightning_v2", "earth_v2",
		 "wind_v2", "water_v2", "holy_v2", "dark_v2"]
	)
	
	# 14x14 Extra Elemental Effects
	print("\n--- 14x14 Extra Elemental Effects ---")
	_generate_14x14_effects(
		base_path + "/Extra_Elemental_Spellcasting_Effects_14x14.png",
		"res://assets/animations/effects/extra_elemental_plain.tres",
		["burst", "nova", "shield", "heal", "poison", "sleep", "confuse", "barrier"]
	)
	
	# 14x14 Extra Elemental Effects (Glow)
	print("\n--- 14x14 Extra Elemental Effects (Glow) ---")
	_generate_14x14_effects(
		base_path + "/Extra_Elemental_Spellcasting_Effects_Anti-Alias_glow_14x14.png",
		"res://assets/animations/effects/extra_elemental_glow.tres",
		["burst_glow", "nova_glow", "shield_glow", "heal_glow", 
		 "poison_glow", "sleep_glow", "confuse_glow", "barrier_glow"]
	)
	
	# Fire Explosions (28x28)
	print("\n--- Fire Explosions ---")
	_generate_explosion(
		base_path + "/Fire_Explosion_28x28.png",
		"res://assets/animations/effects/fire_explosion_plain.tres",
		28, 28, 12, "explosion"
	)
	_generate_explosion(
		base_path + "/Fire_Explosion_Anti-Alias_glow.png",
		"res://assets/animations/effects/fire_explosion_glow.tres",
		28, 28, 12, "explosion_glow"
	)
	_generate_explosion(
		base_path + "/Fire_Explosion_ISOMETRIC_28x28.png",
		"res://assets/animations/effects/fire_explosion_iso_plain.tres",
		28, 28, 12, "explosion_iso"
	)
	_generate_explosion(
		base_path + "/Fire_Explosion_ISOMETRIC_Anti-Alias_glow_28x28.png",
		"res://assets/animations/effects/fire_explosion_iso_glow.tres",
		28, 28, 12, "explosion_iso_glow"
	)
	
	# Large Fire (28x28)
	print("\n--- Large Fire ---")
	_generate_explosion(
		base_path + "/Large_Fire_28x28.png",
		"res://assets/animations/effects/large_fire_plain.tres",
		28, 28, 12, "large_fire"
	)
	_generate_explosion(
		base_path + "/Large_Fire_Anti-Alias_glow_28x28.png",
		"res://assets/animations/effects/large_fire_glow.tres",
		28, 28, 12, "large_fire_glow"
	)
	
	# Ice Burst Variants (48x48)
	print("\n--- Ice Burst Variants ---")
	_generate_explosion(
		base_path + "/Ice-Burst_crystal_48x48_Anti-Alias_glow.png",
		"res://assets/animations/effects/ice_burst_crystal_glow.tres",
		48, 48, 8, "ice_crystal"
	)
	_generate_explosion(
		base_path + "/Ice-Burst_crystal_48x48.png",
		"res://assets/animations/effects/ice_burst_crystal.tres",
		48, 48, 8, "ice_crystal_plain"
	)
	_generate_explosion(
		base_path + "/Ice-Burst_dark-blue_outline_48x48.png",
		"res://assets/animations/effects/ice_burst_dark_blue.tres",
		48, 48, 8, "ice_dark_blue"
	)
	_generate_explosion(
		base_path + "/Ice-Burst_light-grey_outline_48x48.png",
		"res://assets/animations/effects/ice_burst_light_grey.tres",
		48, 48, 8, "ice_light_grey"
	)
	_generate_explosion(
		base_path + "/Ice-Burst_no_outline_48x48.png",
		"res://assets/animations/effects/ice_burst_no_outline.tres",
		48, 48, 8, "ice_no_outline"
	)
	_generate_explosion(
		base_path + "/Ice-Burst_transparent-blue_outline_48x48.png",
		"res://assets/animations/effects/ice_burst_transparent.tres",
		48, 48, 8, "ice_transparent"
	)
	
	# Lightning Energy (48x48)
	print("\n--- Lightning Energy ---")
	_generate_explosion(
		base_path + "/Lightning_Energy_48x48.png",
		"res://assets/animations/effects/lightning_energy_plain.tres",
		48, 48, 6, "lightning_energy"
	)
	_generate_explosion(
		base_path + "/Lightning_Energy_Anti-Alias_glow_48x48.png",
		"res://assets/animations/effects/lightning_energy_glow.tres",
		48, 48, 6, "lightning_energy_glow"
	)
	
	# Red Energy (48x48)
	print("\n--- Red Energy ---")
	_generate_explosion(
		base_path + "/Red_Energy_48x48.png",
		"res://assets/animations/effects/red_energy_plain.tres",
		48, 48, 6, "red_energy"
	)
	_generate_explosion(
		base_path + "/Red_Energy_Anti-Alias_glow_48x48.png",
		"res://assets/animations/effects/red_energy_glow.tres",
		48, 48, 6, "red_energy_glow"
	)
	
	# Lightning Blast (54x18)
	print("\n--- Lightning Blast ---")
	_generate_horizontal_beam(
		base_path + "/Lightning_Blast_54x18.png",
		"res://assets/animations/effects/lightning_blast_plain.tres",
		54, 18, 3, "lightning_blast"
	)
	_generate_horizontal_beam(
		base_path + "/Lightning_Blast_Anti-Alias_glow_54x18.png",
		"res://assets/animations/effects/lightning_blast_glow.tres",
		54, 18, 3, "lightning_blast_glow"
	)
	
	# Red Lightning Blast (54x18)
	print("\n--- Red Lightning Blast ---")
	_generate_horizontal_beam(
		base_path + "/Red_Lightning_Blast_54x18.png",
		"res://assets/animations/effects/red_lightning_blast_plain.tres",
		54, 18, 3, "red_blast"
	)
	_generate_horizontal_beam(
		base_path + "/Red_Lightning_Blast_Anti-Alias_glow_54x18.png",
		"res://assets/animations/effects/red_lightning_blast_glow.tres",
		54, 18, 3, "red_blast_glow"
	)
	
	print("\n=== All Magical Effects Imported! ===")

func _generate_8x8_effects(texture_path: String, output_path: String, effect_names: Array) -> void:
	var sprite_frames := SpriteFrames.new()
	var texture: Texture2D = load(texture_path)
	
	if not texture:
		print("ERROR: Could not load %s" % texture_path)
		return
	
	var frame_size := Vector2(8, 8)
	var cols := 4
	
	for i in range(effect_names.size()):
		var effect_name: String = effect_names[i]
		var start_row := i * 2  # Each effect takes 2 rows (4 frames each)
		
		sprite_frames.add_animation(effect_name)
		sprite_frames.set_animation_loop(effect_name, false)
		sprite_frames.set_animation_speed(effect_name, 12.0)
		
		for f in range(4):
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
		print("  ERROR: %d" % err)

func _generate_14x14_effects(texture_path: String, output_path: String, effect_names: Array) -> void:
	var sprite_frames := SpriteFrames.new()
	var texture: Texture2D = load(texture_path)
	
	if not texture:
		print("ERROR: Could not load %s" % texture_path)
		return
	
	var frame_size := Vector2(14, 14)
	
	for i in range(effect_names.size()):
		var effect_name: String = effect_names[i]
		var start_row := i * 2
		
		sprite_frames.add_animation(effect_name)
		sprite_frames.set_animation_loop(effect_name, false)
		sprite_frames.set_animation_speed(effect_name, 12.0)
		
		for f in range(4):
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
		print("  ERROR: %d" % err)

func _generate_explosion(texture_path: String, output_path: String, frame_w: int, frame_h: int, frame_count: int, anim_name: String) -> void:
	var sprite_frames := SpriteFrames.new()
	var texture: Texture2D = load(texture_path)
	
	if not texture:
		print("ERROR: Could not load %s" % texture_path)
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
	
	print("  Created: %s (%d frames, %dx%d)" % [anim_name, frame_count, frame_w, frame_h])
	
	var err := ResourceSaver.save(sprite_frames, output_path)
	if err == OK:
		print("  Saved: %s" % output_path)
	else:
		print("  ERROR: %d" % err)

func _generate_horizontal_beam(texture_path: String, output_path: String, frame_w: int, frame_h: int, frame_count: int, anim_name: String) -> void:
	var sprite_frames := SpriteFrames.new()
	var texture: Texture2D = load(texture_path)
	
	if not texture:
		print("ERROR: Could not load %s" % texture_path)
		return
	
	var frame_size := Vector2(frame_w, frame_h)
	
	sprite_frames.add_animation(anim_name)
	sprite_frames.set_animation_loop(anim_name, true)
	sprite_frames.set_animation_speed(anim_name, 15.0)
	
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
	
	print("  Created: %s (%d frames, %dx%d)" % [anim_name, frame_count, frame_w, frame_h])
	
	var err := ResourceSaver.save(sprite_frames, output_path)
	if err == OK:
		print("  Saved: %s" % output_path)
	else:
		print("  ERROR: %d" % err)
