@tool
extends EditorScript

# Lonesome Forest Tileset Generator
# Imports all Summer and Winter tilesets into Godot

func _run() -> void:
	print("=== Lonesome Forest Tileset Generator ===\n")
	
	var base_path := "res://assets/Lonesome Forest - Summer and Winter Versions"
	
	# Summer Tilesets
	print("--- Summer Tilesets ---")
	_import_tileset(
		"Lonesome_Forest_FLOOR",
		base_path + "/Summer Tileset/Lonesome_Forest_FLOOR.png",
		16, 16
	)
	_import_tileset(
		"Lonesome_Forest_COBBLESTONE_PATH",
		base_path + "/Summer Tileset/Lonesome_Forest_COBBLESTONE_PATH.png",
		16, 16
	)
	_import_tileset(
		"Lonesome_Forest_RIVER_and_WATER_EDGES",
		base_path + "/Summer Tileset/Lonesome_Forest_RIVER_and_WATER_EDGES.png",
		16, 16
	)
	_import_tileset(
		"Lonesome_Forest_WALLS_and_CLIFF_EDGES",
		base_path + "/Summer Tileset/Lonesome_Forest_WALLS_and_CLIFF_EDGES.png",
		16, 16
	)
	_import_tileset(
		"Lonesome_Forest_WALLs_and_CLIIFS_with_FLOOR",
		base_path + "/Summer Tileset/Lonesome_Forest_WALLs_and_CLIIFS_with_FLOOR.png",
		16, 16
	)
	_import_tileset(
		"Lonesome_Forest_DETAIL_OBJECTS",
		base_path + "/Summer Tileset/Lonesome_Forest_DETAIL_OBJECTS.png",
		16, 16
	)
	
	# Winter Tilesets
	print("\n--- Winter Tilesets ---")
	_import_tileset(
		"Lonesome_Forest_WINTER_FLOOR",
		base_path + "/Winter Tileset/Lonesome_Forest_WINTER_FLOOR.png",
		16, 16
	)
	_import_tileset(
		"Lonesome_Forest_WINTER_COBLESTONE_PATH",
		base_path + "/Winter Tileset/Lonesome_Forest_WINTER_COBLESTONE_PATH.png",
		16, 16
	)
	_import_tileset(
		"Lonesome_Forest_WINTER_RIVER_and_WATER_EDGES",
		base_path + "/Winter Tileset/Lonesome_Forest_WINTER_RIVER_and_WATER_EDGES.png",
		16, 16
	)
	_import_tileset(
		"Lonesome_Forest_WINTER_WALLS_and_CLIFF_EDGES",
		base_path + "/Winter Tileset/Lonesome_Forest_WINTER_WALLS_and_CLIFF_EDGES.png",
		16, 16
	)
	_import_tileset(
		"Lonesome_Forest_WINTER_WALLS_and_CLIFFS_with_FLOOR",
		base_path + "/Winter Tileset/Lonesome_Forest_WINTER_WALLS_and_CLIFFS_with_FLOOR.png",
		16, 16
	)
	_import_tileset(
		"Lonesome_Forest_WINTER_DETAIL_OBJECTS",
		base_path + "/Winter Tileset/Lonesome_Forest_WINTER_DETAIL_OBJECTS.png",
		16, 16
	)
	
	# Animated Tiles - Summer
	print("\n--- Summer Animated Tiles ---")
	_generate_animation(
		"Lonesome_Forest_ANIM_water",
		base_path + "/Animations - Summer & Winter/Sprite Sheet Versions/Lonesome_Forest_ANIM_water.png",
		16, 16, 4, 4.0
	)
	_generate_animation(
		"Lonesome_Forest_ANIM_waterfall_top",
		base_path + "/Animations - Summer & Winter/Sprite Sheet Versions/Lonesome_Forest_ANIM_waterfall_top.png",
		16, 16, 4, 6.0
	)
	_generate_animation(
		"Lonesome_Forest_ANIM_waterfall_mid",
		base_path + "/Animations - Summer & Winter/Sprite Sheet Versions/Lonesome_Forest_ANIM_waterfall_mid.png",
		16, 16, 4, 6.0
	)
	_generate_animation(
		"Lonesome_Forest_ANIM_waterfall_bottom",
		base_path + "/Animations - Summer & Winter/Sprite Sheet Versions/Lonesome_Forest_ANIM_waterfall_bottom.png",
		16, 16, 4, 6.0
	)
	_generate_animation(
		"Lonesome_Forest_ANIM_water_shadow_top",
		base_path + "/Animations - Summer & Winter/Sprite Sheet Versions/Lonesome_Forest_ANIM_water_shadow_top.png",
		16, 16, 4, 4.0
	)
	_generate_animation(
		"Lonesome_Forest_ANIM_water_shadow_mid",
		base_path + "/Animations - Summer & Winter/Sprite Sheet Versions/Lonesome_Forest_ANIM_water_shadow_mid.png",
		16, 16, 4, 4.0
	)
	_generate_animation(
		"Lonesome_Forest_ANIM_water_shadow_bottom",
		base_path + "/Animations - Summer & Winter/Sprite Sheet Versions/Lonesome_Forest_ANIM_water_shadow_bottom.png",
		16, 16, 4, 4.0
	)
	_generate_animation(
		"Lonesome_Forest_ANIM_chest",
		base_path + "/Animations - Summer & Winter/Sprite Sheet Versions/Lonesome_Forest_ANIM_chest.png",
		16, 16, 4, 6.0
	)
	_generate_animation(
		"Lonesome_Forest_ANIM_simple_flame",
		base_path + "/Animations - Summer & Winter/Sprite Sheet Versions/Lonesome_Forest_ANIM_simple_flame.png",
		16, 16, 4, 8.0
	)
	
	# Animated Tiles - Winter
	print("\n--- Winter Animated Tiles ---")
	_generate_animation(
		"Lonesome_Forest_WINTER_ANIM_chest",
		base_path + "/Animations - Summer & Winter/Sprite Sheet Versions/LForest_chest_WINTER_spritesheet.png",
		16, 16, 4, 6.0
	)
	
	print("\n=== All Lonesome Forest tilesets imported! ===")

func _import_tileset(name: String, texture_path: String, tile_w: int, tile_h: int) -> void:
	var texture: Texture2D = load(texture_path)
	if not texture:
		print("ERROR: Could not load %s" % texture_path)
		return
	
	var size := texture.get_size()
	var cols := int(size.x / tile_w)
	var rows := int(size.y / tile_h)
	
	print("Imported: %s (%dx%d tiles)" % [name, cols, rows])
	
	# The textures are already imported by Godot automatically
	# Just need to confirm they exist
	print("  -> %s" % texture_path)

func _generate_animation(name: String, texture_path: String, frame_w: int, frame_h: int, frame_count: int, fps: float) -> void:
	var sprite_frames := SpriteFrames.new()
	var texture: Texture2D = load(texture_path)
	
	if not texture:
		print("ERROR: Could not load %s" % texture_path)
		return
	
	var frame_size := Vector2(frame_w, frame_h)
	
	sprite_frames.add_animation("default")
	sprite_frames.set_animation_loop("default", true)
	sprite_frames.set_animation_speed("default", fps)
	
	for f in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(
			f * frame_size.x,
			0,
			frame_size.x,
			frame_size.y
		)
		sprite_frames.add_frame("default", atlas)
	
	var output_path := "res://assets/animations/tilesets/%s.tres" % name
	var err := ResourceSaver.save(sprite_frames, output_path)
	
	if err == OK:
		print("Created: %s (%d frames @ %.1f fps)" % [name, frame_count, fps])
	else:
		print("ERROR saving %s: %d" % [name, err])
