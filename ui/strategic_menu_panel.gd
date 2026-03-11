extends PanelContainer

## Gemfire SNES-style Strategic Menu Panel
## Visual overhaul with authentic medieval aesthetic
##
## AI MODIFICATION NOTES:
## - This file has been refactored to use @export node references
## - All function signatures now have complete type hints
## - Debug mode provides verbose logging for troubleshooting
## - AI MODIFICATION ZONE comments mark safe areas for visual changes

# ============================================================================
# EXPORTS: Node References (Set these in the Inspector)
# ============================================================================

@export_group("Header Section")
@export var family_name_label: Label
@export var province_label: Label
@export var shield_icon: TextureRect

@export_group("Portrait Section")
@export var portrait_frame: Control
@export var portrait_texture: TextureRect
@export var portrait_mask: ColorRect
@export var title_label: Label
@export var name_label: Label
@export var frame_border: NinePatchRect

@export_group("Stats Section")
@export var stats_grid: GridContainer
## Stat rows must have Icon (TextureRect) and Value (Label) children
@export var stat_row_0: HBoxContainer
@export var stat_row_1: HBoxContainer
@export var stat_row_2: HBoxContainer
@export var stat_row_3: HBoxContainer
@export var stat_row_4: HBoxContainer
@export var stat_row_5: HBoxContainer

@export_group("Command Section")
@export var command_palette: HBoxContainer
@export var cmd_battle: TextureButton
@export var cmd_develop: TextureButton
@export var cmd_march: TextureButton
@export var cmd_troops: TextureButton

@export_group("Decorative Elements")
@export var border_frame: NinePatchRect
@export var divider_1: NinePatchRect
@export var divider_2: NinePatchRect
@export var divider_3: NinePatchRect

@export_group("Footer")
@export var prompt_text: Label

@export_group("Debug")
@export var debug_mode: bool = false

# ============================================================================
# CONSTANTS
# ============================================================================

const PANEL_WIDTH: int = 280
const PORTRAIT_SIZE: int = 88
const STAT_ICON_SIZE: int = 24
const BUTTON_SIZE: int = 56

## Color palette (AI MODIFICATION ZONE: Adjust for different themes)
const COLOR_BACKGROUND: Color = Color("#4a3f6a")  # Lighter purple
const COLOR_GOLD: Color = Color("#f4d77a")  # Bright gold
const COLOR_DARK_GOLD: Color = Color("#b89627")
const COLOR_LIGHT_GOLD: Color = Color("#fff7aa")

# ============================================================================
# STATE
# ============================================================================

var current_province_id: int = -1
var current_governor_id: String = ""
var current_command: String = ""
var portrait_paths: Dictionary = {}

## Cached LabelSettings for consistent styling
var header_settings: LabelSettings
var subheader_settings: LabelSettings
var stats_settings: LabelSettings
var prompt_settings: LabelSettings

## Button group for command palette
var command_button_group: ButtonGroup

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	_validate_exports()
	_discover_portraits()
	_setup_fonts()
	_setup_panel_style()
	_setup_decorations()
	_setup_stat_icons()
	_setup_command_buttons()
	_setup_shield_icons()
	_fix_portrait_settings()
	_connect_signals()
	
	if debug_mode:
		print("=== StrategicMenuPanel Initialized ===")
		_validate_scene_tree()

func _exit_tree() -> void:
	_cleanup_signals()

# ============================================================================
# VALIDATION
# ============================================================================

## Validates that all required exports are assigned
func _validate_exports() -> void:
	var required_nodes: Array[Dictionary] = [
		{"node": family_name_label, "name": "family_name_label"},
		{"node": province_label, "name": "province_label"},
		{"node": portrait_texture, "name": "portrait_texture"},
		{"node": stats_grid, "name": "stats_grid"},
		{"node": command_palette, "name": "command_palette"},
		{"node": prompt_text, "name": "prompt_text"},
	]
	
	for item in required_nodes:
		if item["node"] == null:
			push_error("StrategicMenuPanel: Missing required export - %s" % item["name"])
			push_error("  -> Assign this node in the Inspector (Scene -> Click StrategicMenuPanel)")

## Validates scene tree structure in debug mode
func _validate_scene_tree() -> void:
	print("=== Scene Tree Validation ===")
	
	# Check stats grid children
	if stats_grid:
		print("Stats grid children: ", stats_grid.get_child_count())
		for i in range(stats_grid.get_child_count()):
			var child = stats_grid.get_child(i)
			if child is HBoxContainer:
				var has_icon = child.has_node("Icon")
				var has_value = child.has_node("Value")
				print("  Row %d: Icon=%s, Value=%s" % [i, has_icon, has_value])
	
	# Check command palette
	if command_palette:
		print("Command palette children: ", command_palette.get_child_count())

# ============================================================================
# SIGNAL CONNECTIONS
# ============================================================================

func _connect_signals() -> void:
	EventBus.ProvinceSelected.connect(_on_province_selected)
	EventBus.FamilyTurnStarted.connect(_on_turn_started)

func _cleanup_signals() -> void:
	if EventBus.ProvinceSelected.is_connected(_on_province_selected):
		EventBus.ProvinceSelected.disconnect(_on_province_selected)
	if EventBus.FamilyTurnStarted.is_connected(_on_turn_started):
		EventBus.FamilyTurnStarted.disconnect(_on_turn_started)

# ============================================================================
# SETUP FUNCTIONS
# ============================================================================

## Configures the main panel background and border
func _setup_panel_style() -> void:
	# === AI MODIFICATION ZONE: Panel Styling ===
	# STATUS: Placeholder textures, can be replaced with pixel art
	# SAFE TO CHANGE: Colors, border widths, corner detail
	# CONSTRAINTS: Must maintain PANEL_WIDTH (280px)
	
	var panel_bg := StyleBoxFlat.new()
	panel_bg.bg_color = COLOR_BACKGROUND
	panel_bg.border_color = COLOR_GOLD
	panel_bg.border_width_left = 4
	panel_bg.border_width_right = 4
	panel_bg.border_width_top = 4
	panel_bg.border_width_bottom = 4
	panel_bg.corner_detail = 1
	add_theme_stylebox_override("panel", panel_bg)

## Creates and applies font settings
func _setup_fonts() -> void:
	# === AI MODIFICATION ZONE: Typography ===
	# SAFE TO CHANGE: Font sizes, colors, shadow settings
	# CONSTRAINTS: Keep pixel_font for retro aesthetic
	
	var pixel_font := _load_pixel_font()
	
	# Header settings (family name) - bright white with black shadow
	header_settings = LabelSettings.new()
	header_settings.font = pixel_font
	header_settings.font_size = 16
	header_settings.font_color = Color.WHITE
	header_settings.shadow_color = Color.BLACK
	header_settings.shadow_size = 2
	header_settings.shadow_offset = Vector2(2, 2)
	
	# Subheader settings (province, titles) - bright gold
	subheader_settings = LabelSettings.new()
	subheader_settings.font = pixel_font
	subheader_settings.font_size = 14
	subheader_settings.font_color = Color("#FFD700")
	subheader_settings.shadow_color = Color.BLACK
	subheader_settings.shadow_size = 2
	subheader_settings.shadow_offset = Vector2(2, 2)
	
	# Stats settings (numbers) - bright white with shadow
	stats_settings = LabelSettings.new()
	stats_settings.font = pixel_font
	stats_settings.font_size = 18
	stats_settings.font_color = Color.WHITE
	stats_settings.shadow_color = Color.BLACK
	stats_settings.shadow_size = 2
	stats_settings.shadow_offset = Vector2(2, 2)
	
	# Prompt settings - bright gold with shadow
	prompt_settings = LabelSettings.new()
	prompt_settings.font = pixel_font
	prompt_settings.font_size = 12
	prompt_settings.font_color = Color("#FFD700")
	prompt_settings.shadow_color = Color.BLACK
	prompt_settings.shadow_size = 2
	prompt_settings.shadow_offset = Vector2(2, 2)
	
	# Apply to existing labels
	if family_name_label:
		family_name_label.label_settings = header_settings
	if province_label:
		province_label.label_settings = subheader_settings
	if prompt_text:
		prompt_text.label_settings = prompt_settings
	if title_label:
		title_label.label_settings = subheader_settings
	if name_label:
		name_label.label_settings = header_settings

## Loads the pixel font or falls back to system monospace
func _load_pixel_font() -> Font:
	var font_path := "res://assets/fonts/PressStart2P-Regular.ttf"
	if ResourceLoader.exists(font_path):
		return load(font_path) as Font
	
	var system_font := SystemFont.new()
	system_font.font_names = ["Courier New", "Monospace", "DejaVu Sans Mono"]
	return system_font

## Creates and applies decorative NinePatch textures
func _setup_decorations() -> void:
	# === AI MODIFICATION ZONE: Decorative Elements ===
	# STATUS: Procedurally generated, replace with pixel art
	# SAFE TO CHANGE: All visual properties
	
	if border_frame:
		var border_tex := _create_ornate_border_texture(32, 32, Color("#3a2f5a"), Color("#d4af37"))
		border_frame.texture = border_tex
		border_frame.patch_margin_left = 8
		border_frame.patch_margin_right = 8
		border_frame.patch_margin_top = 8
		border_frame.patch_margin_bottom = 8
	
	var divider_tex := _create_divider_texture()
	
	for divider in [divider_1, divider_2, divider_3]:
		if divider:
			divider.texture = divider_tex
			divider.patch_margin_left = 8
			divider.patch_margin_right = 8
	
	if frame_border:
		var frame_tex := _create_portrait_frame_texture()
		frame_border.texture = frame_tex
		frame_border.patch_margin_left = 8
		frame_border.patch_margin_right = 8
		frame_border.patch_margin_top = 8
		frame_border.patch_margin_bottom = 8

## Creates and assigns stat icons to the stats grid
func _setup_stat_icons() -> void:
	# === AI MODIFICATION ZONE: Stat Icons ===
	# STATUS: Procedurally generated icons
	# SAFE TO CHANGE: Icon designs, colors
	# TODO: Replace with res://assets/ui/icon_*.png files
	
	var icons: Array[ImageTexture] = [
		_create_coin_icon(),      # Gold
		_create_flag_icon(),      # Loyalty
		_create_wheat_icon(),     # Food
		_create_swords_icon(),    # Soldiers
		_create_helmet_icon(),    # Army
		_create_castle_icon()     # Protection
	]
	
	var rows: Array = [stat_row_0, stat_row_1, stat_row_2, stat_row_3, stat_row_4, stat_row_5]
	
	for i in range(min(icons.size(), rows.size())):
		var row: HBoxContainer = rows[i]
		if row == null:
			continue
			
		var icon_rect := row.get_node("Icon") as TextureRect
		var value_label := row.get_node("Value") as Label
		
		if icon_rect:
			icon_rect.texture = icons[i]
			icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		if value_label:
			value_label.label_settings = stats_settings
			value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

## Configures command palette buttons
func _setup_command_buttons() -> void:
	if command_palette == null:
		return
	
	command_button_group = ButtonGroup.new()
	
	var buttons: Array = [cmd_battle, cmd_develop, cmd_march, cmd_troops]
	var icon_creators: Array[Callable] = [
		_create_battle_icon,
		_create_develop_icon,
		_create_march_icon,
		_create_troops_icon
	]
	var button_names := ["CmdBattle", "CmdDevelop", "CmdMarch", "CmdTroops"]
	
	for i in range(buttons.size()):
		var btn: TextureButton = buttons[i]
		if btn == null:
			continue
			
		btn.button_group = command_button_group
		btn.toggle_mode = true
		
		# Disconnect any existing connections to avoid duplicates
		if btn.toggled.is_connected(_on_command_toggled):
			btn.toggled.disconnect(_on_command_toggled)
		
		btn.toggled.connect(_on_command_toggled.bind(button_names[i]))
		
		# Create button textures
		var normal_tex := _create_button_texture(icon_creators[i], false)
		var pressed_tex := _create_button_texture(icon_creators[i], true)
		
		btn.texture_normal = normal_tex
		btn.texture_pressed = pressed_tex

func _setup_shield_icons() -> void:
	if shield_icon:
		shield_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

## Fixes portrait TextureRect settings to prevent checkered transparency and text bleeding
func _fix_portrait_settings() -> void:
	if portrait_texture == null:
		return
	
	# CRITICAL FIXES for portrait display:
	# 1. NEAREST filter prevents blur on pixel art
	# 2. KEEP_ASPECT_CENTERED prevents stretching
	# 3. EXPAND_FIT_WIDTH_PROPORTIONAL ensures proper sizing
	portrait_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait_texture.modulate = Color.WHITE
	
	# CRITICAL FIX: Remove ALL children from portrait (fixes "Coryll.png" debug text)
	for child in portrait_texture.get_children():
		if debug_mode:
			print("Removing child from portrait: ", child.name)
		child.queue_free()
	
	# Set fallback silhouette if no texture assigned yet
	if portrait_texture.texture == null:
		portrait_texture.texture = _create_silhouette_texture()

# ============================================================================
# EVENT HANDLERS
# ============================================================================

## Updates UI when player selects a province
## @param province_id: 1-5 corresponding to Dunmoor/Petaria
func _on_province_selected(province_id: int) -> void:
	if not GameState.provinces.has(province_id):
		push_warning("Invalid province selection: %d" % province_id)
		return
	
	current_province_id = province_id
	var province: ProvinceData = GameState.provinces[province_id]
	var family: FamilyData = GameState.families.get(province.owner_id)
	var governor: CharacterData = GameState.characters.get(province.governor_id)
	
	if debug_mode:
		print("=== Province Selected ===")
		print("ID: ", province_id)
		print("Name: ", province.name)
		print("Owner: ", province.owner_id)
		print("Governor: ", province.governor_id)
	
	_update_header(family, province)
	_update_portrait(governor, province.owner_id)
	_update_stats(province)
	_update_prompt(governor)
	_reset_command_buttons()

## Called when a new family's turn begins
func _on_turn_started(family_id: String) -> void:
	if debug_mode:
		print("Turn started for family: ", family_id)

## Handles command button toggles
func _on_command_toggled(pressed: bool, command_name: String) -> void:
	if pressed:
		var command := command_name.to_lower().replace("cmd", "")
		current_command = command
		EventBus.CommandSelected.emit(command)
		
		if debug_mode:
			print("Command selected: ", command)

# ============================================================================
# UI UPDATE FUNCTIONS
# ============================================================================

func _update_header(family: FamilyData, province: ProvinceData) -> void:
	var family_id := province.owner_id if province else ""
	
	# Family name
	if family_name_label:
		if family:
			family_name_label.text = family.name.to_upper()
		else:
			family_name_label.text = "UNKNOWN"
	
	# Province label
	if province_label:
		if province:
			province_label.text = "%d: %s" % [province.id, province.name]
		else:
			province_label.text = "--"
	
	# Shield icon
	if shield_icon:
		shield_icon.texture = _get_shield_for_family(family_id)

func _update_portrait(governor: CharacterData, family_id: String) -> void:
	if portrait_frame == null:
		return
	
	# Set mask color based on family
	var mask_color := Color(0.15, 0.12, 0.25)
	match family_id:
		"blanche": mask_color = Color(0.12, 0.12, 0.3)
		"lyle": mask_color = Color(0.3, 0.12, 0.12)
		"coryll": mask_color = Color(0.12, 0.25, 0.12)
	
	if portrait_mask:
		portrait_mask.color = mask_color
	
	# Configure portrait texture settings (fixes checkered transparency + sizing)
	if portrait_texture:
		portrait_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait_texture.modulate = Color.WHITE
	
	# Load portrait texture
	var governor_id := governor.id if governor else ""
	var portrait_path := _get_portrait_for_lord(governor_id, family_id)
	
	if debug_mode:
		print("Portrait path: ", portrait_path)
		print("Texture exists: ", ResourceLoader.exists(portrait_path))
	
	if portrait_texture:
		if portrait_path != "" and ResourceLoader.exists(portrait_path):
			var tex := load(portrait_path) as Texture2D
			if tex:
				var final_tex := _composite_portrait_with_bg(tex, mask_color)
				portrait_texture.texture = final_tex
				
				if debug_mode:
					print("Portrait loaded: ", tex.get_size())
			else:
				push_error("Failed to load texture: " + portrait_path)
				portrait_texture.texture = _create_silhouette_texture()
		else:
			portrait_texture.texture = _create_silhouette_texture()
	
	# Update title and name
	if governor:
		var title := _get_lord_title(governor)
		var display_name := _format_lord_name(governor.name)
		
		if title_label:
			title_label.text = title
		if name_label:
			name_label.text = display_name
	else:
		if title_label:
			title_label.text = "No"
		if name_label:
			name_label.text = "Governor"

func _update_stats(province: ProvinceData) -> void:
	if province == null:
		return
	
	_update_stat(0, province.gold)
	_update_stat(1, province.loyalty)
	_update_stat(2, province.food)
	_update_stat(3, province.soldiers)
	_update_stat(4, province.soldiers)
	_update_stat(5, province.protection)

func _update_stat(slot: int, value: int) -> void:
	var rows: Array = [stat_row_0, stat_row_1, stat_row_2, stat_row_3, stat_row_4, stat_row_5]
	
	if slot < 0 or slot >= rows.size():
		return
	
	var row: HBoxContainer = rows[slot]
	if row == null:
		return
	
	var value_label := row.get_node("Value") as Label
	if value_label:
		value_label.text = str(value)

func _update_prompt(governor: CharacterData) -> void:
	if prompt_text == null:
		return
	
	if governor:
		var title := _get_lord_title(governor)
		var display_name := _format_lord_name(governor.name)
		prompt_text.text = "%s %s, what is your command?" % [title, display_name]
	else:
		prompt_text.text = "Select a province to give commands."

func _reset_command_buttons() -> void:
	if command_palette == null:
		return
	
	for child in command_palette.get_children():
		if child is TextureButton:
			child.button_pressed = false
	
	current_command = ""

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

## Returns the appropriate title for a character
func _get_lord_title(character: CharacterData) -> String:
	if character == null:
		return "Lord"
	
	if character.is_ruler:
		return "King"
	elif character.is_lord:
		return "Lord"
	else:
		return "Knight"

## Strips title prefix from lord name to prevent "Lord Lord Banshea"
func _format_lord_name(full_name: String) -> String:
	if full_name.begins_with("Lord "):
		return full_name.substr(5)
	elif full_name.begins_with("Lady "):
		return full_name.substr(5)
	elif full_name.begins_with("King "):
		return full_name.substr(5)
	elif full_name.begins_with("Knight "):
		return full_name.substr(8)
	else:
		return full_name

## Returns a dictionary with title and name separated
func _parse_lord_name(full_name: String) -> Dictionary:
	if full_name.begins_with("Lord "):
		return {"title": "Lord", "name": full_name.substr(5)}
	elif full_name.begins_with("Lady "):
		return {"title": "Lady", "name": full_name.substr(5)}
	elif full_name.begins_with("King "):
		return {"title": "King", "name": full_name.substr(5)}
	else:
		return {"title": "Lord", "name": full_name}

# ============================================================================
# PORTRAIT SYSTEM
# ============================================================================

## Discovers available portraits in the assets/portraits directory
func _discover_portraits() -> void:
	var base_path := "res://assets/portraits/"
	var dir := DirAccess.open(base_path)
	
	if not dir:
		if debug_mode:
			push_error("Failed to open portraits directory: " + base_path)
		return
	
	dir.list_dir_begin()
	var house_name := dir.get_next()
	
	while house_name != "":
		if dir.current_is_dir() and not house_name.begins_with("."):
			var house_dir_path := base_path + house_name + "/"
			var house_dir := DirAccess.open(house_dir_path)
			
			if house_dir:
				portrait_paths[house_name] = []
				house_dir.list_dir_begin()
				var file := house_dir.get_next()
				
				while file != "":
					if not file.begins_with(".") and not file.ends_with(".import"):
						if file.ends_with(".png") or file.ends_with(".jpg") or file.ends_with(".jpeg"):
							var full_path := house_dir_path + file
							portrait_paths[house_name].append(full_path)
					file = house_dir.get_next()
		
		house_name = dir.get_next()
	
	if debug_mode:
		print("Discovered portraits: ", portrait_paths)

## Finds the appropriate portrait path for a lord
## @param lord_id: Character ID
## @param family_id: Family ID (e.g., "blanche")
## @return: Path to portrait image or empty string
func _get_portrait_for_lord(lord_id: String, family_id: String) -> String:
	# First check if lord has a valid portrait_path field
	var lord: CharacterData = GameState.characters.get(lord_id)
	if lord and lord.portrait_path and lord.portrait_path != "res://assets/portraits/placeholder.png":
		if ResourceLoader.exists(lord.portrait_path):
			return lord.portrait_path
	
	var house_folder := "house_" + family_id
	
	if portrait_paths.has(house_folder) and portrait_paths[house_folder].size() > 0:
		var house_portraits: Array = portrait_paths[house_folder]
		
		# Try to match by lord_id in filename
		for path: String in house_portraits:
			var filename: String = path.to_lower()
			if lord_id.to_lower() in filename:
				return path
		
		# Try to match by lord name (without title)
		if lord:
			var lord_name_lower := _format_lord_name(lord.name).to_lower()
			for path: String in house_portraits:
				var filename: String = path.to_lower()
				if lord_name_lower in filename or lord.name.to_lower() in filename:
					return path
		
		# Fallback: find any portrait with "lord" and family name
		for path: String in house_portraits:
			var filename: String = path.to_lower()
			if filename.contains("lord_") and filename.contains(family_id.to_lower()):
				return path
		
		# Final fallback: use first available portrait
		return house_portraits[0]
	
	return ""

## Composites portrait with a colored background
func _composite_portrait_with_bg(portrait_tex: Texture2D, bg_color: Color) -> ImageTexture:
	if portrait_tex == null:
		return _create_silhouette_texture()
	
	var img := portrait_tex.get_image()
	if not img:
		return _create_silhouette_texture()
	
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	
	var size := img.get_size()
	var new_img := Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	new_img.fill(bg_color)
	
	for x in range(int(size.x)):
		for y in range(int(size.y)):
			var pixel := img.get_pixel(x, y)
			if pixel.a > 0.1:
				new_img.set_pixel(x, y, pixel)
	
	return ImageTexture.create_from_image(new_img)

## Creates a fallback silhouette texture
func _create_silhouette_texture() -> ImageTexture:
	var size := 76
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var silhouette := Color(0.6, 0.6, 0.65, 0.8)
	var highlight := Color(0.75, 0.75, 0.8, 0.9)
	
	for x in range(size):
		for y in range(size):
			var dx := x - size / 2
			
			# Head
			var dy_head := y - 20
			var dist_head := dx * dx + dy_head * dy_head
			if dist_head < 100:
				img.set_pixel(x, y, highlight if dx < -2 else silhouette)
			
			# Body/Shoulders
			var dy_body := y - 50
			if abs(dx) < 25 and y > 28 and y < 58:
				img.set_pixel(x, y, silhouette)
	
	return ImageTexture.create_from_image(img)

# ============================================================================
# SHIELD ICONS
# ============================================================================

## Returns a shield texture for a family
func _get_shield_for_family(family_id: String) -> Texture2D:
	var color := Color.BLUE
	match family_id:
		"blanche": color = Color("#4169E1")  # Royal blue
		"lyle": color = Color("#DC143C")     # Crimson
		"coryll": color = Color("#228B22")   # Forest green
	
	return _create_shield_icon(color)

## Creates a shield-shaped icon texture
func _create_shield_icon(color: Color) -> ImageTexture:
	var size := 48
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var dark := color.darkened(0.5)
	var mid := color.darkened(0.2)
	var highlight := color.lightened(0.3)
	var gold := Color("#d4af37")
	
	# Shield shape defined by rows (width at each y)
	var shield_shape := [
		0,0,0,18,18,20,20,20,20,20,
		20,20,20,20,20,20,20,20,20,20,
		20,20,20,20,19,19,18,18,17,16,
		15,14,13,12,11,10,9,8,6,4,0,0,0
	]
	
	var start_y := 2
	
	for y in range(shield_shape.size()):
		var row_y: int = start_y + y
		if row_y >= size:
			break
		
		var half_width: int = shield_shape[y]
		if half_width == 0:
			continue
		
		var cx: float = size / 2.0
		
		for x in range(size):
			var dx: float = abs(x - cx)
			if dx > half_width:
				continue
			
			var is_border: bool = dx >= half_width - 2 or y < 2 or (y > 35 and dx > half_width * 0.6)
			
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

# ============================================================================
# TEXTURE GENERATION (AI MODIFICATION ZONES)
# ============================================================================

## Creates an ornate border texture
func _create_ornate_border_texture(width: int, height: int, fill: Color, border: Color) -> ImageTexture:
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(fill)
	
	var border_w := 4
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
	var width := 256
	var height := 12
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var gold := Color("#f4d77a")
	var dark_gold := Color("#b89627")
	var light_gold := Color("#fff7aa")
	var ruby := Color("#FF4444")
	
	# Draw ornate horizontal line
	for x in range(width):
		img.set_pixel(x, 3, dark_gold)
		img.set_pixel(x, 4, gold)
		img.set_pixel(x, 5, gold)
		img.set_pixel(x, 6, light_gold)
		img.set_pixel(x, 7, dark_gold)
		
		if x % 20 == 0:
			for dy in range(2, 10):
				for dx in range(-1, 2):
					var d: int = abs(dx) + abs(dy - 5)
					if d < 2:
						img.set_pixel(x + dx, dy, light_gold)
	
	# Center jewel (ruby)
	var center := width / 2
	for x in range(int(center) - 6, int(center) + 6):
		for y in range(0, 12):
			var dx := x - center
			var dy := y - 5.5
			var dist := sqrt(dx * dx + dy * dy)
			if dist < 5:
				if dist < 2:
					img.set_pixel(x, y, ruby.lightened(0.4))
				elif dist < 3.5:
					img.set_pixel(x, y, ruby)
				else:
					img.set_pixel(x, y, gold)
	
	return ImageTexture.create_from_image(img)

func _create_portrait_frame_texture() -> ImageTexture:
	var size := 88
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var gold := Color("#d4af37")
	var dark_gold := Color("#8a7027")
	var light_gold := Color("#f4d77a")
	var shadow := Color("#4a3f1a")
	
	for x in range(size):
		for y in range(size):
			var cx := x - size / 2.0
			var cy := y - size / 2.0
			var dist := sqrt(cx * cx + cy * cy)
			
			# Outer thick border (6px)
			if x < 6 or x >= size - 6 or y < 6 or y >= size - 6:
				if x < 3 or y < 3:
					img.set_pixel(x, y, light_gold)
				elif x >= size - 3 or y >= size - 3:
					img.set_pixel(x, y, shadow)
				else:
					img.set_pixel(x, y, gold)
			
			# Inner decorative border
			elif x < 11 or x >= size - 11 or y < 11 or y >= size - 11:
				if x == 11 or x == size - 12 or y == 11 or y == size - 12:
					img.set_pixel(x, y, dark_gold)
	
	# Corner embellishments
	for corner in range(4):
		var cx := 4 if corner % 2 == 0 else size - 5
		var cy := 4 if corner < 2 else size - 5
		
		for i in range(-3, 4):
			for j in range(-3, 4):
				var px := cx + i
				var py := cy + j
				if px >= 0 and px < size and py >= 0 and py < size:
					var d := sqrt(i * i + j * j)
					if d < 3:
						img.set_pixel(px, py, light_gold)
					elif d < 4:
						img.set_pixel(px, py, gold)
	
	return ImageTexture.create_from_image(img)

# ============================================================================
# STAT ICONS
# ============================================================================

func _create_coin_icon() -> ImageTexture:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var gold := Color("#FFED4A")
	var dark_gold := Color("#D4A000")
	var light_gold := Color("#FFFF7A")
	
	for x in range(24):
		for y in range(24):
			var dist := Vector2(x - 12, y - 12).length()
			if dist < 8:
				if x < 10:
					img.set_pixel(x, y, light_gold)
				elif x > 14:
					img.set_pixel(x, y, dark_gold)
				else:
					img.set_pixel(x, y, gold)
			elif dist < 10:
				img.set_pixel(x, y, dark_gold)
	
	# $ symbol
	for y in range(7, 17):
		img.set_pixel(12, y, dark_gold)
	for x in range(10, 15):
		img.set_pixel(x, 8, dark_gold)
		img.set_pixel(x, 16, dark_gold)
	img.set_pixel(10, 9, dark_gold)
	img.set_pixel(14, 9, dark_gold)
	img.set_pixel(10, 15, dark_gold)
	img.set_pixel(14, 15, dark_gold)
	
	return ImageTexture.create_from_image(img)

func _create_flag_icon() -> ImageTexture:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var red := Color("#DC143C")
	var dark_red := Color("#8B0000")
	var pole := Color("#8B4513")
	var gold := Color("#d4af37")
	
	# Flag pole
	for y in range(2, 20):
		img.set_pixel(6, y, pole)
		img.set_pixel(7, y, pole.darkened(0.3))
	
	img.set_pixel(6, 1, gold)
	img.set_pixel(7, 1, gold)
	
	# Waving banner
	for x in range(8, 20):
		var wave := int(sin((x - 8) / 12.0 * PI) * 2)
		for y in range(4, 12):
			var wy := y + wave
			if wy >= 0 and wy < 24:
				var edge := (x == 8 or x == 19 or y == 4 or y == 11)
				img.set_pixel(x, wy, gold if edge else red)
				if not edge and x % 3 == 0:
					img.set_pixel(x, wy, dark_red)
	
	return ImageTexture.create_from_image(img)

func _create_wheat_icon() -> ImageTexture:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var wheat := Color("#DAA520")
	var dark_wheat := Color("#B8860B")
	var stem := Color("#8B4513")
	
	# Stem
	for y in range(10, 22):
		img.set_pixel(12, y, stem)
		img.set_pixel(13, y, stem.darkened(0.2))
	
	# Wheat head
	for i in range(5):
		var ox := 8 + i * 2
		var oy := 6 + i
		for x in range(ox, ox + 4):
			for y in range(oy, oy + 5):
				var dx := x - ox - 2
				var dy := y - oy - 2
				if dx * dx + dy * dy < 5:
					img.set_pixel(x, y, wheat)
					if dy > 0:
						img.set_pixel(x, y, dark_wheat)
	
	return ImageTexture.create_from_image(img)

func _create_swords_icon() -> ImageTexture:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var silver := Color("#C0C0C0")
	var dark := Color("#696969")
	var highlight := Color("#E8E8E8")
	
	for i in range(-8, 9):
		var x1 := 12 + i
		var y1 := 12 + i
		if x1 >= 2 and x1 < 22 and y1 >= 2 and y1 < 22:
			img.set_pixel(x1, y1, silver)
			if i > 0:
				img.set_pixel(x1 + 1, y1, dark)
			if i < 0:
				img.set_pixel(x1 - 1, y1, highlight)
		
		var x2 := 12 - i
		var y2 := 12 + i
		if x2 >= 2 and x2 < 22 and y2 >= 2 and y2 < 22:
			img.set_pixel(x2, y2, silver)
			if i < 0:
				img.set_pixel(x2, y2 + 1, dark)
			if i > 0:
				img.set_pixel(x2, y2 - 1, highlight)
	
	# Hilts
	for i in range(-3, 4):
		img.set_pixel(4 + i, 4, dark)
		img.set_pixel(20, 4 + i, dark)
	
	return ImageTexture.create_from_image(img)

func _create_helmet_icon() -> ImageTexture:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var steel := Color("#708090")
	var dark := Color("#2F4F4F")
	var highlight := Color("#A0A0A0")
	
	for x in range(24):
		for y in range(24):
			var dx := x - 12
			var dy := y - 10
			if dx * dx + dy * dy < 30 and y < 14:
				if x < 9:
					img.set_pixel(x, y, highlight)
				elif x > 15:
					img.set_pixel(x, y, dark)
				else:
					img.set_pixel(x, y, steel)
	
	# Visor
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
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var stone := Color("#808080")
	var dark := Color("#505050")
	var roof := Color("#8B4513")
	
	# Left tower
	for y in range(6, 20):
		for x in range(4, 9):
			img.set_pixel(x, y, stone)
			if x == 4:
				img.set_pixel(x, y, dark)
	for y in range(4, 6):
		for x in range(4, 9):
			img.set_pixel(x, y, roof)
	
	# Right tower
	for y in range(6, 20):
		for x in range(15, 20):
			img.set_pixel(x, y, stone)
			if x == 19:
				img.set_pixel(x, y, dark)
	for y in range(4, 6):
		for x in range(15, 20):
			img.set_pixel(x, y, roof)
	
	# Center keep
	for y in range(10, 20):
		for x in range(9, 15):
			img.set_pixel(x, y, stone)
	for y in range(8, 10):
		for x in range(9, 15):
			img.set_pixel(x, y, roof)
	
	# Gate
	for y in range(14, 20):
		for x in range(11, 13):
			img.set_pixel(x, y, dark)
	
	return ImageTexture.create_from_image(img)

# ============================================================================
# COMMAND BUTTON ICONS
# ============================================================================

func _create_button_texture(icon_drawer: Callable, pressed: bool) -> ImageTexture:
	var size := 56
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var base := Color("#5a4f8a") if not pressed else Color("#3a2f6a")
	var highlight := Color("#7a6faa") if not pressed else Color("#5a4f8a")
	var shadow := Color("#3a2f5a") if not pressed else Color("#1a0f3a")
	var gold := Color("#f4d77a")
	var dark_gold := Color("#b89627")
	
	img.fill(base)
	
	# Inner recessed area
	for x in range(4, size - 4):
		for y in range(4, size - 4):
			img.set_pixel(x, y, highlight if not pressed else shadow)
	
	# 3D beveled border
	if not pressed:
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
		var cx := 2 if i % 2 == 0 else size - 3
		var cy := 2 if i < 2 else size - 3
		img.set_pixel(cx, cy, gold.lightened(0.5))
	
	# Draw icon
	icon_drawer.call(img)
	
	return ImageTexture.create_from_image(img)

func _create_battle_icon(img: Image) -> void:
	var silver := Color("#C0C0C0")
	var dark := Color("#606060")
	var highlight := Color("#E8E8E8")
	var center := 28
	
	for i in range(-12, 13):
		var x1 := center + i
		var y1 := center + i
		if x1 >= 8 and x1 < 48 and y1 >= 8 and y1 < 48:
			img.set_pixel(x1, y1, silver)
			img.set_pixel(x1 - 1, y1, dark)
			img.set_pixel(x1 + 1, y1, highlight)
		
		var x2 := center - i
		var y2 := center + i
		if x2 >= 8 and x2 < 48 and y2 >= 8 and y2 < 48:
			img.set_pixel(x2, y2, silver)
			img.set_pixel(x2, y2 - 1, dark)
			img.set_pixel(x2, y2 + 1, highlight)
	
	for i in range(-4, 5):
		img.set_pixel(center + 14 + i, center + 14, dark)
		img.set_pixel(center - 14, center + 14 + i, dark)

func _create_develop_icon(img: Image) -> void:
	var stone := Color("#808080")
	var dark_stone := Color("#505050")
	var roof := Color("#8B4513")
	var gold := Color("#d4af37")
	
	# Tower base
	for x in range(18, 38):
		for y in range(30, 46):
			img.set_pixel(x, y, stone)
			if x == 18 or x == 37:
				img.set_pixel(x, y, dark_stone)
	
	# Tower roof
	for y in range(18, 30):
		var width := (y - 18) / 12.0 * 12
		for x in range(int(28 - width), int(28 + width)):
			img.set_pixel(x, y, roof)
	
	# Door
	for x in range(24, 32):
		for y in range(38, 46):
			img.set_pixel(x, y, dark_stone)
	
	# Windows
	img.set_pixel(22, 34, gold)
	img.set_pixel(34, 34, gold)

func _create_march_icon(img: Image) -> void:
	var red := Color("#DC143C")
	var dark_red := Color("#8B0000")
	var pole := Color("#8B4513")
	var gold := Color("#d4af37")
	
	for y in range(12, 44):
		img.set_pixel(16, y, pole)
		img.set_pixel(17, y, pole.darkened(0.3))
	
	img.set_pixel(16, 11, gold)
	img.set_pixel(17, 11, gold)
	
	for x in range(18, 42):
		var wave := sin((x - 18) / 24.0 * PI) * 4
		for y in range(14, 28):
			var wy := y + int(wave)
			if wy >= 0 and wy < 56:
				var is_edge := (y == 14 or y == 27 or x == 18 or x == 41)
				img.set_pixel(x, wy, gold if is_edge else red)
				if not is_edge and x % 4 == 0:
					img.set_pixel(x, wy, dark_red)

func _create_troops_icon(img: Image) -> void:
	var steel := Color("#708090")
	var dark := Color("#2F4F4F")
	var highlight := Color("#A0A0A0")
	
	for x in range(56):
		for y in range(56):
			var cx := x - 28
			var cy := y - 20
			var dist := sqrt(cx * cx + cy * cy)
			
			if dist < 16 and y < 28:
				if cx < -5:
					img.set_pixel(x, y, highlight)
				elif cx > 5:
					img.set_pixel(x, y, dark)
				else:
					img.set_pixel(x, y, steel)
	
	# Visor
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
