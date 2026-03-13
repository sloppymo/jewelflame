extends MarginContainer

func _ready():
	# Ensure this node is on top
	z_index = 10
	visible = true
	modulate = Color(1, 1, 1, 1)
	
	# Apply proper margins to keep content inside the frame
	add_theme_constant_override("margin_left", 56)
	add_theme_constant_override("margin_right", 56)
	add_theme_constant_override("margin_top", 56)
	add_theme_constant_override("margin_bottom", 56)
	
	# Constrain the banner size
	var banner = get_node_or_null("MainContainer/Banner")
	if banner:
		banner.custom_minimum_size = Vector2(180, 60)
		banner.max_size = Vector2(200, 80)  # Hard max size
		banner.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		banner.expand_mode = TextureRect.EXPAND_KEEP_SIZE  # Don't expand to texture size
	
	# Constrain the portrait frame
	var portrait_frame = get_node_or_null("MainContainer/PortraitFrame")
	if portrait_frame:
		portrait_frame.custom_minimum_size = Vector2(120, 120)
		portrait_frame.max_size = Vector2(140, 140)  # Hard max size
		portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Constrain the portrait image inside
	var portrait = get_node_or_null("MainContainer/PortraitFrame/Portrait")
	if portrait:
		portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH  # Keep aspect but fit within bounds
	
	print("ContentMargin ready, size: ", size, " pos: ", position)
