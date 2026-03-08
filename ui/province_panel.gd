extends Panel

# Complete ProvincePanel Implementation - Gemfire SNES Style
# Left 40% panel with stats grid, portrait, and action buttons

# Export vars for designer tweaking
@export var panel_width_percent: float = 0.4
@export var portrait_size: Vector2 = Vector2(128, 160)
@export var stat_icon_size: Vector2 = Vector2(32, 32)
@export var button_size: Vector2 = Vector2(64, 64)

# Node references (will be created in code for full control)
var header_section: VBoxContainer
var crest_row: HBoxContainer
var title_label: Label
var owner_label: Label
var close_button: Button
var divider_top: TextureRect

var portrait_section: VBoxContainer
var portrait_container: CenterContainer
var portrait_texture: TextureRect
var lord_name_label: Label

var stats_grid: GridContainer

var divider_bottom: TextureRect

var action_buttons: HBoxContainer
var move_button: Button

var command_prompt: Label

# Stat icon textures
var icon_gold: Texture2D
var icon_food: Texture2D
var icon_troops: Texture2D
var icon_flags: Texture2D
var icon_swords: Texture2D
var icon_castle: Texture2D

# Button textures
var button_frame_normal: Texture2D
var button_frame_hover: Texture2D
var button_frame_pressed: Texture2D

# Portrait textures
var portrait_textures: Dictionary

var current_province_id: int = -1
var animation_controller: Node2D

# Fonts (will be loaded if available)
var font_header: Font
var font_numbers: Font

func _ready():
	EventBus.ProvinceSelected.connect(_on_province_selected)
	EventBus.BattleResolved.connect(_on_battle_resolved)
	EventBus.ProvinceDataChanged.connect(_on_province_data_changed)
	
	animation_controller = get_tree().get_first_node_in_group("animation_controller")
	
	_load_assets()
	_setup_panel_structure()
	_setup_panel_style()
	
	hide()

func _load_assets():
	"""Load all textures and fonts."""
	# Stat icons
	icon_gold = load("res://assets/icons/icon_gold.png")
	icon_food = load("res://assets/icons/icon_food.png")
	icon_troops = load("res://assets/icons/icon_troops.png")
	icon_flags = load("res://assets/icons/icon_flags.png")
	icon_swords = load("res://assets/icons/icon_swords.png")
	icon_castle = load("res://assets/icons/icon_castle.png")
	
	# Button frames
	button_frame_normal = load("res://assets/ui/button_frame.png")
	button_frame_hover = load("res://assets/ui/button_frame_hover.png")
	button_frame_pressed = load("res://assets/ui/button_frame_pressed.png")
	
	# Portrait textures
	portrait_textures = {
		"erin": load("res://assets/portraits/house_blanche/sister.png"),
		"ander": load("res://assets/portraits/house_blanche/son.png"),
		"lars": load("res://assets/portraits/house_blanche/son.png"),
		"char_erin": load("res://assets/portraits/house_blanche/sister.png"),
		"char_ander": load("res://assets/portraits/house_blanche/son.png"),
		"char_lars": load("res://assets/portraits/house_blanche/son.png"),
		"char_lord_2": load("res://assets/portraits/house_blanche/sister.png"),
		"char_lord_4": load("res://assets/portraits/house_blanche/son.png")
	}
	
	# Try to load fonts
	if ResourceLoader.exists("res://assets/fonts/PressStart2P.ttf"):
		font_header = load("res://assets/fonts/PressStart2P.ttf")
	if ResourceLoader.exists("res://assets/fonts/VT323.ttf"):
		font_numbers = load("res://assets/fonts/VT323.ttf")

func _setup_panel_structure():
	"""Build the complete panel hierarchy."""
	# Clear existing
	for child in get_children():
		child.queue_free()
	
	# Set panel anchors (left 40%)
	anchors_preset = Control.PRESET_LEFT_WIDE
	anchor_right = panel_width_percent
	offset_left = 20
	offset_top = 20
	offset_right = -20
	offset_bottom = -20
	
	# Main container with margin
	var margin = MarginContainer.new()
	margin.name = "Margin"
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	
	# Vertical stack - tighter spacing for Gemfire layout
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.add_theme_constant_override("separation", 4)  # Tighter spacing
	margin.add_child(vbox)
	
	# 1. Header Section
	header_section = VBoxContainer.new()
	header_section.name = "Header"
	vbox.add_child(header_section)
	
	# Crest row
	crest_row = HBoxContainer.new()
	crest_row.name = "CrestRow"
	crest_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header_section.add_child(crest_row)
	
	# Title label
	title_label = Label.new()
	title_label.name = "Title"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_header:
		title_label.add_theme_font_override("font", font_header)
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color("#f4e4c1"))
	crest_row.add_child(title_label)
	
	# Close button - small, gold X on blue
	close_button = Button.new()
	close_button.name = "Close"
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(16, 16)
	close_button.add_theme_font_size_override("font_size", 10)
	close_button.add_theme_color_override("font_color", Color("#d4af37"))
	close_button.pressed.connect(_on_close_pressed)
	crest_row.add_child(close_button)
	
	# Owner label
	owner_label = Label.new()
	owner_label.name = "Owner"
	owner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_header:
		owner_label.add_theme_font_override("font", font_header)
	owner_label.add_theme_font_size_override("font_size", 14)
	owner_label.add_theme_color_override("font_color", Color("#d4af37"))
	header_section.add_child(owner_label)
	
	# Top divider
	divider_top = _create_divider()
	vbox.add_child(divider_top)
	
	# 2. Portrait Section - FIXED SIZE, not expanding
	portrait_section = VBoxContainer.new()
	portrait_section.name = "PortraitSection"
	portrait_section.custom_minimum_size = Vector2(0, 180)  # Fixed height ~180px
	portrait_section.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Don't expand
	vbox.add_child(portrait_section)
	
	# Portrait container - CenterContainer but with fixed size
	portrait_container = CenterContainer.new()
	portrait_container.name = "PortraitContainer"
	portrait_container.custom_minimum_size = portrait_size  # 128x160
	portrait_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_section.add_child(portrait_container)
	
	# Portrait texture - STRICT SIZE
	portrait_texture = TextureRect.new()
	portrait_texture.name = "Portrait"
	portrait_texture.custom_minimum_size = portrait_size  # 128x160 ONLY
	portrait_texture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_texture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_container.add_child(portrait_texture)
	
	# Lord name - below portrait
	lord_name_label = Label.new()
	lord_name_label.name = "LordName"
	lord_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lord_name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if font_header:
		lord_name_label.add_theme_font_override("font", font_header)
	lord_name_label.add_theme_font_size_override("font_size", 12)
	lord_name_label.add_theme_color_override("font_color", Color("#f4e4c1"))
	portrait_section.add_child(lord_name_label)
	
	# Middle divider
	var divider_mid = _create_divider()
	vbox.add_child(divider_mid)
	
	# 3. Stats Grid - FIXED SIZE
	stats_grid = _create_stats_grid()
	stats_grid.custom_minimum_size = Vector2(0, 120)  # Fixed height for 6 stats
	stats_grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.add_child(stats_grid)
	
	# Bottom divider
	divider_bottom = _create_divider()
	vbox.add_child(divider_bottom)
	
	# 4. Action Buttons - FIXED SIZE
	action_buttons = _create_action_buttons()
	action_buttons.custom_minimum_size = Vector2(0, 64)  # Fixed height for buttons
	action_buttons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.add_child(action_buttons)
	
	# 5. Command Prompt - FIXED SIZE
	command_prompt = Label.new()
	command_prompt.name = "CommandPrompt"
	command_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	command_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	command_prompt.custom_minimum_size = Vector2(0, 30)
	command_prompt.size_flags_vertical = Control.SIZE_SHRINK_END  # Push to bottom
	if font_header:
		command_prompt.add_theme_font_override("font", font_header)
	command_prompt.add_theme_font_size_override("font_size", 11)
	command_prompt.add_theme_color_override("font_color", Color("#f4e4c1"))
	vbox.add_child(command_prompt)

func _create_divider() -> TextureRect:
	var divider = TextureRect.new()
	divider.texture = load("res://assets/ui/divider_gold.png")
	divider.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	divider.stretch_mode = TextureRect.STRETCH_TILE
	divider.custom_minimum_size = Vector2(256, 24)
	return divider

func _create_stats_grid() -> GridContainer:
	"""Create 2-column, 3-row stats grid."""
	var grid = GridContainer.new()
	grid.name = "StatsGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	
	# Left column stats (Gold, Food, Troops)
	var gold_row = _create_stat_row(icon_gold, "gold", "Gold")
	var food_row = _create_stat_row(icon_food, "food", "Food")
	var troops_row = _create_stat_row(icon_troops, "soldiers", "Troops")
	
	# Right column stats (Flags, Swords, Castle)
	var flags_row = _create_stat_row(icon_flags, "loyalty", "Loyalty")
	var swords_row = _create_stat_row(icon_swords, "cultivation", "Cultivation")
	var castle_row = _create_stat_row(icon_castle, "protection", "Defense")
	
	# Add in grid order (row by row, left to right)
	grid.add_child(gold_row)
	grid.add_child(flags_row)
	grid.add_child(food_row)
	grid.add_child(swords_row)
	grid.add_child(troops_row)
	grid.add_child(castle_row)
	
	return grid

func _create_stat_row(icon_texture: Texture2D, stat_name: String, label_text: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.name = stat_name.capitalize() + "Row"
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	
	# Icon
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.texture = icon_texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = stat_icon_size
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(8, 0)
	row.add_child(spacer)
	
	# Value label
	var value_label = Label.new()
	value_label.name = "Value"
	if font_numbers:
		value_label.add_theme_font_override("font", font_numbers)
	value_label.add_theme_font_size_override("font_size", 24)
	value_label.add_theme_color_override("font_color", Color("#f4e4c1"))
	row.add_child(value_label)
	
	return row

func _create_action_buttons() -> HBoxContainer:
	var container = HBoxContainer.new()
	container.name = "ActionButtons"
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 12)
	
	var buttons = [
		{"name": "Attack", "callback": _on_attack_button_pressed},
		{"name": "Develop", "callback": _on_develop_button_pressed},
		{"name": "Move", "callback": _on_move_button_pressed},
		{"name": "Recruit", "callback": _on_recruit_button_pressed}
	]
	
	for btn_data in buttons:
		var button = Button.new()
		button.name = btn_data.name + "Button"
		button.text = btn_data.name
		button.custom_minimum_size = button_size
		button.pressed.connect(btn_data.callback)
		
		# Apply button styles
		_apply_button_style(button)
		
		if btn_data.name == "Move":
			move_button = button
		
		container.add_child(button)
	
	return container

func _apply_button_style(button: Button):
	"""Apply SNES-style button frame with states."""
	if button_frame_normal:
		var style_normal = StyleBoxTexture.new()
		style_normal.texture = button_frame_normal
		style_normal.texture_margin_left = 4
		style_normal.texture_margin_right = 4
		style_normal.texture_margin_top = 4
		style_normal.texture_margin_bottom = 4
		button.add_theme_stylebox_override("normal", style_normal)
	
	if button_frame_hover:
		var style_hover = StyleBoxTexture.new()
		style_hover.texture = button_frame_hover
		style_hover.texture_margin_left = 4
		style_hover.texture_margin_right = 4
		style_hover.texture_margin_top = 4
		style_hover.texture_margin_bottom = 4
		button.add_theme_stylebox_override("hover", style_hover)
	
	if button_frame_pressed:
		var style_pressed = StyleBoxTexture.new()
		style_pressed.texture = button_frame_pressed
		style_pressed.texture_margin_left = 4
		style_pressed.texture_margin_right = 4
		style_pressed.texture_margin_top = 4
		style_pressed.texture_margin_bottom = 4
		button.add_theme_stylebox_override("pressed", style_pressed)
	
	# Font
	if font_header:
		button.add_theme_font_override("font", font_header)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color("#f4e4c1"))

func _setup_panel_style():
	"""Apply panel background and styling."""
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#1a3a7a")  # Deep blue
	style.border_color = Color("#d4af37")  # Gold
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	add_theme_stylebox_override("panel", style)

func _on_province_selected(province_id: int):
	update_panel(province_id)

func update_panel(province_id: int):
	current_province_id = province_id
	var province = GameState.provinces.get(province_id)
	if not province:
		hide()
		return
	
	var player_family = GameState.get_player_family()
	var is_owned = (province.owner_id == player_family.id)
	
	# Update header
	title_label.text = "%d: %s" % [province_id, province.name]
	owner_label.text = province.owner_id.capitalize()
	if province.is_capital:
		owner_label.text += " ♚"
	if province.is_exhausted:
		owner_label.text += " [Exhausted]"
		owner_label.add_theme_color_override("font_color", Color.GRAY)
	else:
		owner_label.remove_theme_color_override("font_color")
	
	# Update portrait
	_update_portrait(province)
	
	# Update stats
	_update_stats(province)
	
	# Update buttons
	_update_buttons(is_owned, province)
	
	# Update command prompt
	var lord = _get_province_lord(province)
	if lord:
		command_prompt.text = "Lord %s, what is your command?" % lord.name
	else:
		command_prompt.text = "What is your command?"
	
	show()

func _update_portrait(province):
	var lord = _get_province_lord(province)
	
	if lord:
		lord_name_label.text = lord.name
		var tex = portrait_textures.get(lord.id)
		if tex:
			portrait_texture.texture = tex
			portrait_texture.custom_minimum_size = portrait_size
		else:
			portrait_texture.texture = null
	else:
		lord_name_label.text = "No Governor"
		portrait_texture.texture = null

func _update_stats(province):
	# Update all stat labels
	var stats = {
		"gold": province.gold,
		"food": province.food,
		"soldiers": province.soldiers,
		"loyalty": province.loyalty,
		"cultivation": province.cultivation,
		"protection": province.protection
	}
	
	for stat_name in stats:
		var row = stats_grid.get_node_or_null(stat_name.capitalize() + "Row")
		if row:
			var value_label = row.get_node_or_null("Value")
			if value_label:
				value_label.text = str(stats[stat_name])

func _update_buttons(is_owned: bool, province):
	for button in action_buttons.get_children():
		if button is Button:
			button.disabled = !is_owned or province.is_exhausted
			
			if button.disabled:
				if not is_owned:
					button.tooltip_text = "Not your province"
				elif province.is_exhausted:
					button.tooltip_text = "Province already acted"
			else:
				button.tooltip_text = ""

func _get_province_lord(province) -> CharacterData:
	if province.get("governor_id") and not province.governor_id.is_empty():
		return GameState.characters.get(province.governor_id)
	
	for char_id in GameState.characters:
		var character = GameState.characters[char_id]
		if character.family_id == province.owner_id:
			return character
	
	return null

func _on_close_pressed():
	hide()
	current_province_id = -1

func _on_province_data_changed(province_id: int, field: String, value: Variant):
	if province_id == current_province_id and visible:
		update_panel(province_id)

func _on_recruit_button_pressed():
	if current_province_id != -1:
		if MilitaryCommands.execute_recruit(current_province_id, 50):
			update_panel(current_province_id)

func _on_develop_button_pressed():
	if current_province_id != -1:
		var province = GameState.provinces[current_province_id]
		var type = "cultivation" if province.cultivation <= province.protection else "protection"
		if DomesticCommands.execute_develop(current_province_id, type):
			update_panel(current_province_id)

func _on_attack_button_pressed():
	if current_province_id != -1:
		var province = GameState.provinces[current_province_id]
		var player_family = GameState.get_player_family()
		
		var enemy_targets = []
		for neighbor_id in province.neighbors:
			var neighbor = GameState.provinces[neighbor_id]
			if neighbor.owner_id != player_family.id:
				enemy_targets.append(neighbor_id)
		
		if enemy_targets.is_empty():
			print("No attack targets")
			return
		
		var target_id = enemy_targets[0]
		
		if animation_controller:
			animation_controller.show_attack_arrow(current_province_id, target_id)
		
		BattleLauncher.launch_battle(current_province_id, target_id, 0.7, _on_battle_returned)

func _on_move_button_pressed():
	"""Move troops between owned provinces."""
	if current_province_id == -1:
		return
	
	var province = GameState.provinces[current_province_id]
	var player_family = GameState.get_player_family()
	
	# Get friendly neighbors
	var friendly_targets = []
	for neighbor_id in province.neighbors:
		var neighbor = GameState.provinces[neighbor_id]
		if neighbor.owner_id == player_family.id and neighbor_id != current_province_id:
			friendly_targets.append(neighbor_id)
	
	if friendly_targets.is_empty():
		print("No friendly provinces to move to")
		return
	
	# For now, move to first friendly province
	# TODO: Add province selection dialog
	var target_id = friendly_targets[0]
	var move_amount = int(province.soldiers * 0.5)  # Move 50% of troops
	
	if move_amount > 0:
		province.soldiers -= move_amount
		GameState.provinces[target_id].soldiers += move_amount
		province.is_exhausted = true
		EventBus.ProvinceExhausted.emit(current_province_id, true)
		update_panel(current_province_id)
		print("Moved %d troops to %s" % [move_amount, GameState.provinces[target_id].name])

func _on_battle_resolved(result: Dictionary):
	var battle_report = preload("res://ui/battle_report.gd").new()
	get_tree().current_scene.add_child(battle_report)
	
	var attacker_name = "Unknown"
	var defender_name = "Unknown"
	
	for pid in GameState.provinces:
		var p = GameState.provinces[pid]
		if pid in result.get("attacker_provinces", []):
			attacker_name = p.name
		if pid in result.get("defender_provinces", []):
			defender_name = p.name
	
	battle_report.show_battle_report(result, attacker_name, defender_name)

func _on_battle_returned(result: Dictionary):
	print("Battle complete! Winner: ", result.get("winner", "unknown"))
	if current_province_id != -1:
		update_panel(current_province_id)
