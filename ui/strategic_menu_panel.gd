extends PanelContainer

# Gemfire SNES-style Strategic Menu Panel
# Visual overhaul with authentic medieval aesthetic

@onready var GameState = get_node("/root/GameState")

# State tracking
var current_province_id: int = -1
var current_governor_id: String = ""
var current_command: String = ""

# Portrait discovery cache
var portrait_paths: Dictionary = {}

# Font resources
var pixel_font: Font
var header_settings: LabelSettings
var stats_settings: LabelSettings
var prompt_settings: LabelSettings

func _ready():
	_setup_panel_style()
	_setup_fonts()
	_setup_ninepatch_decorations()
	_setup_stat_icons()
	_setup_command_buttons()
	_setup_shield_icons()
	_discover_portraits()
	
	# Connect to EventBus
	EventBus.ProvinceSelected.connect(_on_province_selected)
	EventBus.FamilyTurnStarted.connect(_on_turn_started)

func _setup_panel_style():
	# Deep SNES purple background with gold border - much lighter for visibility
	var panel_bg = StyleBoxFlat.new()
	panel_bg.bg_color = Color("#4a3f6a")  # Much lighter purple
	panel_bg.border_color = Color("#f4d77a")  # Bright gold
	panel_bg.border_width_left = 4
	panel_bg.border_width_right = 4
	panel_bg.border_width_top = 4
	panel_bg.border_width_bottom = 4
	panel_bg.corner_detail = 1
	add_theme_stylebox_override("panel", panel_bg)

func _setup_fonts():
	# Load Press Start 2P or fallback to monospace
	var font_path = "res://assets/fonts/PressStart2P-Regular.ttf"
	if ResourceLoader.exists(font_path):
		pixel_font = load(font_path)
	else:
		pixel_font = SystemFont.new()
		pixel_font.font_names = ["Courier New", "Monospace", "DejaVu Sans Mono"]
	
	# Header settings (family name, province) - bright white with black shadow
	header_settings = LabelSettings.new()
	header_settings.font = pixel_font
	header_settings.font_size = 16
	header_settings.font_color = Color("#FFFFFF")
	header_settings.shadow_color = Color("#000000")
	header_settings.shadow_size = 2
	header_settings.shadow_offset = Vector2(2, 2)
	
	# Smaller header for province label - bright gold
	var subheader_settings = LabelSettings.new()
	subheader_settings.font = pixel_font
	subheader_settings.font_size = 14
	subheader_settings.font_color = Color("#FFD700")  # Bright gold
	subheader_settings.shadow_color = Color("#000000")
	subheader_settings.shadow_size = 2
	subheader_settings.shadow_offset = Vector2(2, 2)
	
	# Stats settings (numbers) - bright white with shadow
	stats_settings = LabelSettings.new()
	stats_settings.font = pixel_font
	stats_settings.font_size = 18
	stats_settings.font_color = Color("#FFFFFF")
	stats_settings.shadow_color = Color("#000000")
	stats_settings.shadow_size = 2
	stats_settings.shadow_offset = Vector2(2, 2)
	
	# Prompt settings - bright gold with shadow
	prompt_settings = LabelSettings.new()
	prompt_settings.font = pixel_font
	prompt_settings.font_size = 12
	prompt_settings.font_color = Color("#FFD700")
	prompt_settings.shadow_color = Color("#000000")
	prompt_settings.shadow_size = 2
	prompt_settings.shadow_offset = Vector2(2, 2)
	
	# Apply settings to existing labels
	var header_row = $MarginContainer/ContentStack/HeaderRow
	header_row.get_node("HeaderText/FamilyName").label_settings = header_settings
	header_row.get_node("HeaderText/ProvinceLabel").label_settings = subheader_settings
	
	$MarginContainer/ContentStack/PromptText.label_settings = prompt_settings
	
	# Apply to LordInfo labels
	var lord_info = $MarginContainer/ContentStack/PortraitSection/LordInfo
	lord_info.get_node("TitleLabel").label_settings = subheader_settings
	lord_info.get_node("NameLabel").label_settings = header_settings

func _setup_ninepatch_decorations():
	# Create ornate gold border for the panel background - lighter fill
	var border_tex = _create_ornate_border_texture(32, 32, Color("#3a2f5a"), Color("#d4af37"))
	var border_rect = $MarginContainer/BorderFrame
	border_rect.texture = border_tex
	border_rect.patch_margin_left = 8
	border_rect.patch_margin_right = 8
	border_rect.patch_margin_top = 8
	border_rect.patch_margin_bottom = 8
	
	# Create decorative dividers with jewel center
	var divider_tex = _create_divider_texture()
	
	var d1 = $MarginContainer/ContentStack/Divider1
	d1.texture = divider_tex
	d1.patch_margin_left = 8
	d1.patch_margin_right = 8
	
	var d2 = $MarginContainer/ContentStack/Divider2
	d2.texture = divider_tex
	d2.patch_margin_left = 8
	d2.patch_margin_right = 8
	
	var d3 = $MarginContainer/ContentStack/Divider3
	d3.texture = divider_tex
	d2.patch_margin_left = 8
	d2.patch_margin_right = 8
	
	# Portrait frame - ornate gold decorative border
	var frame_tex = _create_portrait_frame_texture()
	var portrait_frame = $MarginContainer/ContentStack/PortraitSection/PortraitFrame/FrameBorder
	portrait_frame.texture = frame_tex
	portrait_frame.patch_margin_left = 8
	portrait_frame.patch_margin_right = 8
	portrait_frame.patch_margin_top = 8
	portrait_frame.patch_margin_bottom = 8

func _setup_stat_icons():
	# Create actual stat icons (not colored rectangles)
	var icons = [
		_create_coin_icon(),      # Gold
		_create_flag_icon(),      # Loyalty
		_create_wheat_icon(),     # Food
		_create_swords_icon(),    # Military
		_create_helmet_icon(),    # Army
		_create_castle_icon()     # Defense
	]
	
	var stats_grid = $MarginContainer/ContentStack/StatsGrid
	for i in range(6):
		var row = stats_grid.get_child(i)
		var icon_rect = row.get_node("Icon")
		icon_rect.texture = icons[i]
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		var value_label = row.get_node("Value")
		value_label.label_settings = stats_settings
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _setup_command_buttons():
	var btn_group = ButtonGroup.new()
	var palette = $MarginContainer/ContentStack/CommandPalette
	var btn_names = ["CmdBattle", "CmdDevelop", "CmdMarch", "CmdTroops"]
	var icon_creators = [_create_battle_icon, _create_develop_icon, _create_march_icon, _create_troops_icon]
	
	for i in range(4):
		var btn = palette.get_child(i)
		btn.button_group = btn_group
		btn.toggled.connect(_on_command_toggled.bind(btn.name))
		
		# Create 3D raised button textures
		var normal_tex = _create_button_texture(icon_creators[i], false)
		var pressed_tex = _create_button_texture(icon_creators[i], true)
		
		btn.texture_normal = normal_tex
		btn.texture_pressed = pressed_tex

func _setup_shield_icons():
	# Create shield icons for each family
	var shield_rect = $MarginContainer/ContentStack/HeaderRow/ShieldIcon
	shield_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Will be set dynamically in _on_province_selected

# ============ TEXTURE GENERATION HELPERS ============

func _create_ornate_border_texture(width: int, height: int, fill: Color, border: Color) -> ImageTexture:
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(fill)
	
	# Draw ornamental border (thicker at corners)
	var border_w = 4
	for x in range(width):
		for y in range(border_w):
			img.set_pixel(x, y, border)
			img.set_pixel(x, height - 1 - y, border)
	
	for y in range(height):
		for x in range(border_w):
			img.set_pixel(x, y, border)
			img.set_pixel(width - 1 - x, y, border)
	
	# Corner embellishments
	for i in range(6):
		for j in range(6):
			if i < 3 or j < 3:
				img.set_pixel(i, j, border.lightened(0.2))
				img.set_pixel(width - 1 - i, j, border.lightened(0.2))
				img.set_pixel(i, height - 1 - j, border.lightened(0.2))
				img.set_pixel(width - 1 - i, height - 1 - j, border.lightened(0.2))
	
	return ImageTexture.create_from_image(img)

func _create_divider_texture() -> ImageTexture:
	var width = 256  # Wider for better stretching
	var height = 12
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Transparent
	
	var gold = Color("#f4d77a")  # Bright gold
	var dark_gold = Color("#b89627")
	var light_gold = Color("#fff7aa")
	var ruby = Color("#FF4444")  # Bright red
	
	# Draw ornate horizontal line
	for x in range(width):
		# Base line with bevel
		img.set_pixel(x, 3, dark_gold)
		img.set_pixel(x, 4, gold)
		img.set_pixel(x, 5, gold)
		img.set_pixel(x, 6, light_gold)
		img.set_pixel(x, 7, dark_gold)
		
		# Decorative dots pattern
		if x % 20 == 0:
			for dy in range(2, 10):
				for dx in range(-1, 2):
					var d = abs(dx) + abs(dy - 5)
					if d < 2:
						img.set_pixel(x + dx, dy, light_gold)
	
	# Center jewel (ruby)
	var center = width / 2
	for x in range(int(center) - 6, int(center) + 6):
		for y in range(0, 12):
			var dx = x - center
			var dy = y - 5.5
			var dist = sqrt(dx * dx + dy * dy)
			if dist < 5:
				# Gem gradient
				if dist < 2:
					img.set_pixel(x, y, ruby.lightened(0.4))
				elif dist < 3.5:
					img.set_pixel(x, y, ruby)
				else:
					img.set_pixel(x, y, gold)
	
	return ImageTexture.create_from_image(img)

func _create_portrait_frame_texture() -> ImageTexture:
	var size = 88
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Transparent center for portrait
	
	var gold = Color("#d4af37")
	var dark_gold = Color("#8a7027")
	var light_gold = Color("#f4d77a")
	var shadow = Color("#4a3f1a")
	
	# Create ornate medieval frame
	for x in range(size):
		for y in range(size):
			var cx = x - size / 2.0
			var cy = y - size / 2.0
			var dist = sqrt(cx * cx + cy * cy)
			
			# Outer thick border (6px)
			if x < 6 or x >= size - 6 or y < 6 or y >= size - 6:
				# Bevel effect
				if x < 3 or y < 3:
					img.set_pixel(x, y, light_gold)  # Top-left highlight
				elif x >= size - 3 or y >= size - 3:
					img.set_pixel(x, y, shadow)  # Bottom-right shadow
				else:
					img.set_pixel(x, y, gold)
			
			# Inner decorative border (2px gap, then 3px line)
			elif x < 11 or x >= size - 11 or y < 11 or y >= size - 11:
				if x == 11 or x == size - 12 or y == 11 or y == size - 12:
					img.set_pixel(x, y, dark_gold)
	
	# Corner embellishments (ornate scrollwork corners)
	for corner in range(4):
		var cx = 4 if corner % 2 == 0 else size - 5
		var cy = 4 if corner < 2 else size - 5
		
		for i in range(-3, 4):
			for j in range(-3, 4):
				var px = cx + i
				var py = cy + j
				if px >= 0 and px < size and py >= 0 and py < size:
					var d = sqrt(i * i + j * j)
					if d < 3:
						img.set_pixel(px, py, light_gold)
					elif d < 4:
						img.set_pixel(px, py, gold)
	
	return ImageTexture.create_from_image(img)

# ============ STAT ICONS ============

func _create_coin_icon() -> ImageTexture:
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var gold = Color("#FFED4A")  # Bright yellow
	var dark_gold = Color("#D4A000")
	var light_gold = Color("#FFFF7A")
	
	# Main coin circle with 3D effect
	for x in range(24):
		for y in range(24):
			var dist = Vector2(x - 12, y - 12).length()
			if dist < 8:
				# Gradient for roundness
				if x < 10:
					img.set_pixel(x, y, light_gold)
				elif x > 14:
					img.set_pixel(x, y, dark_gold)
				else:
					img.set_pixel(x, y, gold)
			elif dist < 10:
				img.set_pixel(x, y, dark_gold)
	
	# $ symbol with better proportions
	for y in range(7, 17):
		img.set_pixel(12, y, dark_gold)
	# Top and bottom hooks
	for x in range(10, 15):
		img.set_pixel(x, 8, dark_gold)
		img.set_pixel(x, 16, dark_gold)
	img.set_pixel(10, 9, dark_gold)
	img.set_pixel(14, 9, dark_gold)
	img.set_pixel(10, 15, dark_gold)
	img.set_pixel(14, 15, dark_gold)
	
	return ImageTexture.create_from_image(img)

func _create_flag_icon() -> ImageTexture:
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var red = Color("#DC143C")
	var dark_red = Color("#8B0000")
	var pole = Color("#8B4513")
	var gold = Color("#d4af37")
	
	# Flag pole with 3D effect
	for y in range(2, 20):
		img.set_pixel(6, y, pole)
		img.set_pixel(7, y, pole.darkened(0.3))
	
	# Pole top
	img.set_pixel(6, 1, gold)
	img.set_pixel(7, 1, gold)
	
	# Waving banner
	for x in range(8, 20):
		var wave = int(sin((x - 8) / 12.0 * PI) * 2)
		for y in range(4, 12):
			var wy = y + wave
			if wy >= 0 and wy < 24:
				var edge = (x == 8 or x == 19 or y == 4 or y == 11)
				img.set_pixel(x, wy, gold if edge else red)
				if not edge and x % 3 == 0:
					img.set_pixel(x, wy, dark_red)
	
	return ImageTexture.create_from_image(img)

func _create_wheat_icon() -> ImageTexture:
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var wheat = Color("#DAA520")
	var dark_wheat = Color("#B8860B")
	var stem = Color("#8B4513")
	
	# Stem
	for y in range(10, 22):
		img.set_pixel(12, y, stem)
		img.set_pixel(13, y, stem.darkened(0.2))
	
	# Wheat head - multiple grains in a cluster
	for i in range(5):
		var ox = 8 + i * 2
		var oy = 6 + i
		for x in range(ox, ox + 4):
			for y in range(oy, oy + 5):
				var dx = x - ox - 2
				var dy = y - oy - 2
				if dx * dx + dy * dy < 5:
					img.set_pixel(x, y, wheat)
					if dy > 0:
						img.set_pixel(x, y, dark_wheat)
	
	return ImageTexture.create_from_image(img)

func _create_swords_icon() -> ImageTexture:
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var silver = Color("#C0C0C0")
	var dark = Color("#696969")
	var highlight = Color("#E8E8E8")
	
	# Crossed swords with hilts
	for i in range(-8, 9):
		# Sword 1
		var x1 = 12 + i
		var y1 = 12 + i
		if x1 >= 2 and x1 < 22 and y1 >= 2 and y1 < 22:
			img.set_pixel(x1, y1, silver)
			if i > 0:
				img.set_pixel(x1 + 1, y1, dark)
			if i < 0:
				img.set_pixel(x1 - 1, y1, highlight)
		
		# Sword 2
		var x2 = 12 - i
		var y2 = 12 + i
		if x2 >= 2 and x2 < 22 and y2 >= 2 and y2 < 22:
			img.set_pixel(x2, y2, silver)
			if i < 0:
				img.set_pixel(x2, y2 + 1, dark)
			if i > 0:
				img.set_pixel(x2, y2 - 1, highlight)
	
	# Hilts (crossguards)
	for i in range(-3, 4):
		img.set_pixel(4 + i, 4, dark)
		img.set_pixel(20, 4 + i, dark)
	
	return ImageTexture.create_from_image(img)

func _create_helmet_icon() -> ImageTexture:
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var steel = Color("#708090")
	var dark = Color("#2F4F4F")
	var highlight = Color("#A0A0A0")
	
	# Helmet dome with gradient
	for x in range(24):
		for y in range(24):
			var dx = x - 12
			var dy = y - 10
			if dx * dx + dy * dy < 30 and y < 14:
				if x < 9:
					img.set_pixel(x, y, highlight)
				elif x > 15:
					img.set_pixel(x, y, dark)
				else:
					img.set_pixel(x, y, steel)
	
	# Visor with slit
	for x in range(8, 16):
		img.set_pixel(x, 11, dark)
		img.set_pixel(x, 12, Color.BLACK)
		img.set_pixel(x, 13, dark)
	
	# Cheek guards
	for y in range(14, 20):
		img.set_pixel(6, y, steel)
		img.set_pixel(7, y, dark)
		img.set_pixel(16, y, steel)
		img.set_pixel(17, y, dark)
	
	return ImageTexture.create_from_image(img)

func _create_castle_icon() -> ImageTexture:
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var stone = Color("#808080")
	var dark = Color("#505050")
	var roof = Color("#8B4513")
	
	# Left tower
	for y in range(6, 20):
		for x in range(4, 9):
			img.set_pixel(x, y, stone)
			if x == 4:
				img.set_pixel(x, y, dark)
	# Tower roof
	for y in range(4, 6):
		for x in range(4, 9):
			img.set_pixel(x, y, roof)
	
	# Right tower
	for y in range(6, 20):
		for x in range(15, 20):
			img.set_pixel(x, y, stone)
			if x == 19:
				img.set_pixel(x, y, dark)
	# Tower roof
	for y in range(4, 6):
		for x in range(15, 20):
			img.set_pixel(x, y, roof)
	
	# Center keep (shorter)
	for y in range(10, 20):
		for x in range(9, 15):
			img.set_pixel(x, y, stone)
	# Keep roof
	for y in range(8, 10):
		for x in range(9, 15):
			img.set_pixel(x, y, roof)
	
	# Gate
	for y in range(14, 20):
		for x in range(11, 13):
			img.set_pixel(x, y, dark)
	
	return ImageTexture.create_from_image(img)

# ============ COMMAND BUTTON ICONS ============

func _create_battle_icon(img: Image):
	# Crossed swords with detail - centered in 56x56 button
	var silver = Color("#C0C0C0")
	var dark = Color("#606060")
	var highlight = Color("#E8E8E8")
	var center = 28
	
	# Sword 1 (top-left to bottom-right)
	for i in range(-12, 13):
		var x = center + i
		var y = center + i
		if x >= 8 and x < 48 and y >= 8 and y < 48:
			img.set_pixel(x, y, silver)
			img.set_pixel(x-1, y, dark)
			img.set_pixel(x+1, y, highlight)
	
	# Sword 2 (top-right to bottom-left)
	for i in range(-12, 13):
		var x = center - i
		var y = center + i
		if x >= 8 and x < 48 and y >= 8 and y < 48:
			img.set_pixel(x, y, silver)
			img.set_pixel(x, y-1, dark)
			img.set_pixel(x, y+1, highlight)
	
	# Sword hilts
	for i in range(-4, 5):
		img.set_pixel(center + 14 + i, center + 14, dark)
		img.set_pixel(center - 14, center + 14 + i, dark)

func _create_develop_icon(img: Image):
	# Medieval castle/tower with more detail
	var stone = Color("#808080")
	var dark_stone = Color("#505050")
	var roof = Color("#8B4513")
	var gold = Color("#d4af37")
	
	# Tower base
	for x in range(18, 38):
		for y in range(30, 46):
			img.set_pixel(x, y, stone)
			if x == 18 or x == 37:
				img.set_pixel(x, y, dark_stone)
	
	# Tower roof (triangular)
	for y in range(18, 30):
		var width = (y - 18) / 12.0 * 12
		for x in range(int(28 - width), int(28 + width)):
			img.set_pixel(x, y, roof)
	
	# Door
	for x in range(24, 32):
		for y in range(38, 46):
			img.set_pixel(x, y, dark_stone)
	
	# Windows
	img.set_pixel(22, 34, gold)
	img.set_pixel(34, 34, gold)

func _create_march_icon(img: Image):
	# Banner/flag with waving effect
	var red = Color("#DC143C")
	var dark_red = Color("#8B0000")
	var pole = Color("#8B4513")
	var gold = Color("#d4af37")
	
	# Flag pole
	for y in range(12, 44):
		img.set_pixel(16, y, pole)
		img.set_pixel(17, y, pole.darkened(0.3))
	
	# Pole top ornament
	img.set_pixel(16, 11, gold)
	img.set_pixel(17, 11, gold)
	
	# Waving banner
	for x in range(18, 42):
		var wave = sin((x - 18) / 24.0 * PI) * 4
		for y in range(14, 28):
			var wy = y + int(wave)
			if wy >= 0 and wy < 56:
				var is_edge = (y == 14 or y == 27 or x == 18 or x == 41)
				img.set_pixel(x, wy, gold if is_edge else red)
				if not is_edge and x % 4 == 0:
					img.set_pixel(x, wy, dark_red)

func _create_troops_icon(img: Image):
	# Detailed helmet with visor
	var steel = Color("#708090")
	var dark = Color("#2F4F4F")
	var highlight = Color("#A0A0A0")
	
	# Helmet dome
	for x in range(56):
		for y in range(56):
			var cx = x - 28
			var cy = y - 20
			var dist = sqrt(cx * cx + cy * cy)
			
			if dist < 16 and y < 28:
				# Gradient for roundness
				if cx < -5:
					img.set_pixel(x, y, highlight)
				elif cx > 5:
					img.set_pixel(x, y, dark)
				else:
					img.set_pixel(x, y, steel)
	
	# Visor slit
	for x in range(20, 36):
		img.set_pixel(x, 22, dark)
		img.set_pixel(x, 23, Color.BLACK)
		img.set_pixel(x, 24, dark)
	
	# Cheek guards
	for y in range(24, 36):
		img.set_pixel(14, y, steel)
		img.set_pixel(15, y, dark)
		img.set_pixel(40, y, steel)
		img.set_pixel(41, y, dark)
	
	# Nose guard
	for y in range(22, 32):
		img.set_pixel(28, y, steel)
		img.set_pixel(27, y, dark)
		img.set_pixel(29, y, highlight)

func _create_button_texture(icon_drawer: Callable, pressed: bool) -> ImageTexture:
	var size = 56
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Rich medieval color palette - brighter for visibility
	var base = Color("#5a4f8a") if not pressed else Color("#3a2f6a")  # Brighter purple
	var highlight = Color("#7a6faa") if not pressed else Color("#5a4f8a")
	var shadow = Color("#3a2f5a") if not pressed else Color("#1a0f3a")
	var gold = Color("#f4d77a")  # Bright gold
	var dark_gold = Color("#b89627")
	
	img.fill(base)
	
	# Inner recessed area (beveled)
	for x in range(4, size - 4):
		for y in range(4, size - 4):
			img.set_pixel(x, y, highlight if not pressed else shadow)
	
	# 3D beveled border
	if not pressed:
		# Raised effect
		for x in range(size):
			img.set_pixel(x, 0, gold.lightened(0.3))
			img.set_pixel(x, 1, gold)
			img.set_pixel(x, size - 2, dark_gold)
			img.set_pixel(x, size - 1, shadow)
		for y in range(size):
			img.set_pixel(0, y, gold.lightened(0.3))
			img.set_pixel(1, y, gold)
			img.set_pixel(size - 2, y, dark_gold)
			img.set_pixel(size - 1, y, shadow)
	else:
		# Pressed/inset effect
		for x in range(size):
			img.set_pixel(x, 0, shadow)
			img.set_pixel(x, 1, dark_gold)
			img.set_pixel(x, size - 2, gold)
			img.set_pixel(x, size - 1, gold.lightened(0.3))
		for y in range(size):
			img.set_pixel(0, y, shadow)
			img.set_pixel(1, y, dark_gold)
			img.set_pixel(size - 2, y, gold)
			img.set_pixel(size - 1, y, gold.lightened(0.3))
	
	# Corner accents
	for i in range(4):
		var cx = 2 if i % 2 == 0 else size - 3
		var cy = 2 if i < 2 else size - 3
		img.set_pixel(cx, cy, gold.lightened(0.5))
	
	# Draw icon in center
	icon_drawer.call(img)
	
	return ImageTexture.create_from_image(img)

# ============ SHIELD ICONS ============

func _create_shield_icon(color: Color) -> ImageTexture:
	var size = 48
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var dark = color.darkened(0.5)
	var mid = color.darkened(0.2)
	var highlight = color.lightened(0.3)
	var gold = Color("#d4af37")
	
	# Shield shape defined by rows (width at each y)
	var shield_shape = [
		0,0,0,18,18,20,20,20,20,20,
		20,20,20,20,20,20,20,20,20,20,
		20,20,20,20,19,19,18,18,17,16,
		15,14,13,12,11,10,9,8,6,4,0,0,0
	]
	
	var start_y = 2
	
	for y in range(shield_shape.size()):
		var row_y = start_y + y
		if row_y >= size:
			break
		
		var half_width = shield_shape[y]
		if half_width == 0:
			continue
		
		var cx = size / 2
		
		for x in range(size):
			var dx = abs(x - cx)
			if dx > half_width:
				continue
			
			var is_border = dx >= half_width - 2 or y < 2 or (y > 35 and dx > half_width * 0.6)
			
			if is_border:
				img.set_pixel(x, row_y, gold)
			else:
				if x < cx - 6:
					img.set_pixel(x, row_y, highlight)
				elif x > cx + 6:
					img.set_pixel(x, row_y, mid)
				else:
					img.set_pixel(x, row_y, color)
				
				if abs(x - cx) < 3:
					img.set_pixel(x, row_y, highlight.lightened(0.1))
	
	return ImageTexture.create_from_image(img)

func lightened(c: Color, amount: float) -> Color:
	return c.lightened(amount)


func _get_shield_for_family(family_id: String) -> Texture2D:
	var color = Color.BLUE
	match family_id:
		"blanche": color = Color("#4169E1")  # Royal blue
		"lyle": color = Color("#DC143C")     # Crimson
		"coryll": color = Color("#228B22")   # Forest green
	
	return _create_shield_icon(color)

# ============ PORTRAIT DISCOVERY ============

func _discover_portraits():
	var base_path = "res://assets/portraits/"
	var dir = DirAccess.open(base_path)
	if not dir:
		push_error("Failed to open portraits directory: " + base_path)
		return
	
	dir.list_dir_begin()
	var house_name = dir.get_next()
	
	while house_name != "":
		if dir.current_is_dir() and not house_name.begins_with("."):
			var house_dir_path = base_path + house_name + "/"
			var house_dir = DirAccess.open(house_dir_path)
			
			if house_dir:
				portrait_paths[house_name] = []
				house_dir.list_dir_begin()
				var file = house_dir.get_next()
				
				while file != "":
					if not file.begins_with(".") and not file.ends_with(".import"):
						if file.ends_with(".png") or file.ends_with(".jpg") or file.ends_with(".jpeg"):
							var full_path = house_dir_path + file
							portrait_paths[house_name].append(full_path)
					file = house_dir.get_next()
		
		house_name = dir.get_next()

func _get_portrait_for_lord(lord_id: String, family_id: String) -> String:
	var lord = GameState.characters.get(lord_id)
	if lord and lord.portrait_path and lord.portrait_path != "res://assets/portraits/placeholder.png":
		if ResourceLoader.exists(lord.portrait_path):
			return lord.portrait_path
	
	var house_folder = "house_" + family_id
	
	if portrait_paths.has(house_folder) and portrait_paths[house_folder].size() > 0:
		var house_portraits = portrait_paths[house_folder]
		
		for path in house_portraits:
			var filename = path.to_lower()
			if lord_id.to_lower() in filename:
				return path
		
		if lord:
			var lord_name_lower = lord.name.to_lower().replace("lord ", "").strip_edges()
			for path in house_portraits:
				var filename = path.to_lower()
				if lord_name_lower in filename or lord.name.to_lower() in filename:
					return path
		
		for path in house_portraits:
			var filename = path.to_lower()
			if filename.contains("lord_") and filename.contains(family_id.to_lower()):
				return path
		
		return house_portraits[0]
	
	return ""

func _on_province_selected(province_id: int):
	if not GameState.provinces.has(province_id):
		return
	
	current_province_id = province_id
	var province = GameState.provinces[province_id]
	
	var family_id = province.owner_id
	var family = GameState.families.get(family_id)
	
	current_governor_id = province.governor_id
	var lord = GameState.characters.get(current_governor_id)
	
	# Update Header
	var header_row = $MarginContainer/ContentStack/HeaderRow
	
	var family_name_label = header_row.get_node("HeaderText/FamilyName")
	if family:
		family_name_label.text = family.name.to_upper()
	else:
		family_name_label.text = "UNKNOWN"
	
	var province_label = header_row.get_node("HeaderText/ProvinceLabel")
	province_label.text = "%d: %s" % [province_id, province.name]
	
	# Shield icon
	var shield_icon = header_row.get_node("ShieldIcon")
	shield_icon.texture = _get_shield_for_family(family_id)
	
	# Update Portrait Section
	var portrait_section = $MarginContainer/ContentStack/PortraitSection
	var portrait_frame = portrait_section.get_node("PortraitFrame")
	
	var portrait_tex = portrait_frame.get_node("PortraitTex")
	var portrait_mask = portrait_frame.get_node("PortraitMask")
	var portrait_path = _get_portrait_for_lord(current_governor_id, family_id)
	
	# Set mask color based on family
	var mask_color = Color(0.15, 0.12, 0.25)
	match family_id:
		"blanche": mask_color = Color(0.12, 0.12, 0.3)
		"lyle": mask_color = Color(0.3, 0.12, 0.12)
		"coryll": mask_color = Color(0.12, 0.25, 0.12)
	portrait_mask.color = mask_color
	
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var tex = load(portrait_path)
		if tex:
			var final_tex = _composite_portrait_with_bg(tex, mask_color)
			portrait_tex.texture = final_tex
			portrait_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		else:
			portrait_tex.texture = _create_silhouette_texture()
	else:
		portrait_tex.texture = _create_silhouette_texture()
	
	# Title and Name
	var lord_info = portrait_section.get_node("LordInfo")
	var title_label = lord_info.get_node("TitleLabel")
	var name_label = lord_info.get_node("NameLabel")
	
	if lord:
		var title = "Lord"
		if lord.is_ruler:
			title = "King"
		elif not lord.is_lord:
			title = "Knight"
		
		var display_name = lord.name
		if display_name.begins_with("Lord "):
			display_name = display_name.substr(5)
		elif display_name.begins_with("Lady "):
			display_name = display_name.substr(5)
		
		title_label.text = title
		name_label.text = display_name
	else:
		title_label.text = "No"
		name_label.text = "Governor"
	
	# Update Stats Grid
	_update_stat(0, province.gold)
	_update_stat(1, province.loyalty)
	_update_stat(2, province.food)
	_update_stat(3, province.soldiers)
	_update_stat(4, province.soldiers)
	_update_stat(5, province.protection)
	
	# Update Prompt
	var prompt_text = $MarginContainer/ContentStack/PromptText
	if lord:
		var title = "Lord"
		if lord.is_ruler:
			title = "King"
		elif not lord.is_lord:
			title = "Knight"
		
		var display_name = lord.name
		if display_name.begins_with("Lord "):
			display_name = display_name.substr(5)
		elif display_name.begins_with("Lady "):
			display_name = display_name.substr(5)
		
		prompt_text.text = "%s %s, what is your command?" % [title, display_name]
	else:
		prompt_text.text = "Select a province to give commands."
	
	# Reset command buttons
	var palette = $MarginContainer/ContentStack/CommandPalette
	for btn in palette.get_children():
		btn.button_pressed = false
	current_command = ""

func _composite_portrait_with_bg(portrait_tex: Texture2D, bg_color: Color) -> ImageTexture:
	var img = portrait_tex.get_image()
	if not img:
		return portrait_tex as ImageTexture
	
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	
	var size = img.get_size()
	var new_img = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	new_img.fill(bg_color)
	
	for x in range(int(size.x)):
		for y in range(int(size.y)):
			var pixel = img.get_pixel(x, y)
			if pixel.a > 0.1:
				new_img.set_pixel(x, y, pixel)
	
	return ImageTexture.create_from_image(new_img)

func _create_silhouette_texture() -> ImageTexture:
	var size = 76
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	# Fill with transparent so background shows through
	img.fill(Color(0, 0, 0, 0))
	
	# Simple knight silhouette
	var silhouette = Color(0.6, 0.6, 0.65, 0.8)
	var highlight = Color(0.75, 0.75, 0.8, 0.9)
	
	for x in range(size):
		for y in range(size):
			var dx = x - size / 2
			
			# Head
			var dy_head = y - 20
			var dist_head = dx * dx + dy_head * dy_head
			if dist_head < 100:
				img.set_pixel(x, y, highlight if dx < -2 else silhouette)
			
			# Body/Shoulders
			var dy_body = y - 50
			if abs(dx) < 25 and y > 28 and y < 58:
				img.set_pixel(x, y, silhouette)
	
	return ImageTexture.create_from_image(img)

func _update_stat(slot: int, value: int):
	var stats_grid = $MarginContainer/ContentStack/StatsGrid
	if slot >= stats_grid.get_child_count():
		return
	
	var row = stats_grid.get_child(slot)
	var value_label = row.get_node("Value")
	value_label.text = str(value)

func _on_command_toggled(pressed: bool, command_name: String):
	if pressed:
		var command = command_name.to_lower().replace("cmd", "")
		current_command = command
		EventBus.CommandSelected.emit(command)

func _on_turn_started(family_id: String):
	pass
