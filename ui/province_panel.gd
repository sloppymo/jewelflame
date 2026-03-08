extends Panel

# New UI Assets Integration - SNES Gemfire Style

@onready var title_label: Label = $VBox/Header/TitleLabel
@onready var close_button: Button = $VBox/Header/CloseButton
@onready var owner_label: Label = $VBox/OwnerLabel
@onready var portrait_frame: TextureRect = $VBox/PortraitContainer/PortraitFrame
@onready var portrait: TextureRect = $VBox/PortraitContainer/Portrait
@onready var divider_top: TextureRect = $VBox/DividerTop
@onready var stats_grid: GridContainer = $VBox/StatsGrid
@onready var divider_bottom: TextureRect = $VBox/DividerBottom
@onready var action_buttons: HBoxContainer = $VBox/ActionButtons

# Stat icon textures (loaded on ready)
var icon_gold: Texture2D
var icon_food: Texture2D
var icon_troops: Texture2D

# Portrait textures by lord
var portrait_textures: Dictionary = {
	"erin": preload("res://assets/portraits/house_blanche/sister.png"),
	"ander": preload("res://assets/portraits/house_blanche/son.png"),
	"lars": null,  # Add when available
	"lord_carveti": null,
	"lord_banshea": null
}

var current_province_id: int = -1
var animation_controller: Node2D

func _ready():
	EventBus.ProvinceSelected.connect(update_panel)
	EventBus.BattleResolved.connect(_on_battle_resolved)
	EventBus.ProvinceDataChanged.connect(_on_province_data_changed)
	
	# Get animation controller reference
	animation_controller = get_tree().get_first_node_in_group("animation_controller")
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# Load icon textures
	_load_icons()
	
	# Setup UI with proper pixel art filtering
	_setup_pixel_art_ui()
	
	hide()

func _load_icons():
	"""Load stat icons with error handling."""
	icon_gold = load("res://assets/icons/icon_gold.png")
	icon_food = load("res://assets/icons/icon_food.png")
	icon_troops = load("res://assets/icons/icon_troops.png")
	
	# Fallback to generated icons if not found
	if not icon_gold:
		icon_gold = load("res://assets/generated/ui/icon_gold.png")
	if not icon_food:
		icon_food = load("res://assets/generated/ui/icon_gold.png")  # Fallback
	if not icon_troops:
		icon_troops = load("res://assets/generated/ui/icon_gold.png")  # Fallback

func _setup_pixel_art_ui():
	"""Configure all textures for pixel-perfect rendering."""
	# Set texture filter to NEAREST for all pixel art
	if portrait_frame:
		portrait_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if portrait:
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if divider_top:
		divider_top.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if divider_bottom:
		divider_bottom.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Setup stat icons with nearest neighbor
	_setup_stat_icons()

func _setup_stat_icons():
	"""Create stat rows with icons and values."""
	# Clear existing children
	for child in stats_grid.get_children():
		child.queue_free()
	
	# Create stat rows: Gold, Food, Troops, Loyalty, Cultivation, Protection
	# Layout: [Icon] [Value] [Icon] [Value] in a 2-column grid
	
	# Row 1: Gold | Food
	_create_stat_row(icon_gold, "gold", Color.GOLD)
	_create_stat_row(icon_food, "food", Color.FOREST_GREEN)
	
	# Row 2: Troops | Loyalty
	_create_stat_row(icon_troops, "soldiers", Color.CRIMSON)
	# Loyalty icon - reuse gold temporarily or create new
	_create_stat_row(icon_gold, "loyalty", Color.CORAL)
	
	# Row 3: Cultivation | Protection
	_create_stat_row(icon_food, "cultivation", Color.YELLOW_GREEN)
	_create_stat_row(icon_troops, "protection", Color.STEEL_BLUE)

func _create_stat_row(icon_texture: Texture2D, stat_name: String, color: Color):
	"""Create a stat display with icon and label."""
	# Icon
	var icon = TextureRect.new()
	icon.texture = icon_texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(32, 32)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.name = "Icon" + stat_name.capitalize()
	stats_grid.add_child(icon)
	
	# Value label
	var label = Label.new()
	label.name = "Label" + stat_name.capitalize()
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("#f4e4c1"))  # Cream color
	stats_grid.add_child(label)

func _on_close_pressed():
	hide()
	current_province_id = -1

func _on_province_data_changed(province_id: int, field: String, value: Variant):
	# Refresh panel if current province's data changed
	if province_id == current_province_id and visible:
		update_panel(province_id)

func update_panel(province_id: int):
	current_province_id = province_id
	var province = GameState.provinces.get(province_id)
	if not province:
		hide()
		return
	
	var player_family = GameState.get_player_family()
	var is_owned = (province.owner_id == player_family.id)
	
	# Update title with province ID
	title_label.text = "%d: %s" % [province_id, province.name]
	
	# Update owner with capital indicator
	owner_label.text = province.owner_id.capitalize()
	if province.is_capital:
		owner_label.text += " ♚"
	
	# Update portrait
	_update_portrait(province)
	
	# Update stat values
	_update_stat_values(province)
	
	# Show exhaustion indicator
	if province.is_exhausted:
		owner_label.text += " [EXHAUSTED]"
		owner_label.add_theme_color_override("font_color", Color.GRAY)
	else:
		owner_label.remove_theme_color_override("font_color")
	
	# Update action buttons
	_update_action_buttons(is_owned, province)
	
	show()

func _update_portrait(province):
	"""Update the lord portrait based on province governor."""
	var lord = _get_province_lord(province)
	
	if lord and portrait:
		# Try to load portrait by lord ID
		var tex = portrait_textures.get(lord.id)
		if tex:
			portrait.texture = tex
			portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		else:
			# Use colored placeholder
			portrait.texture = _create_placeholder_portrait(lord.id)
	else:
		# No lord - show empty frame
		if portrait:
			portrait.texture = null

func _create_placeholder_portrait(lord_id: String) -> ImageTexture:
	"""Create a colored placeholder for missing portraits."""
	var img = Image.create(80, 120, false, Image.FORMAT_RGBA8)
	
	# Color based on lord
	var color = Color.DIM_GRAY
	if "erin" in lord_id:
		color = Color.TEAL
	elif "ander" in lord_id:
		color = Color.BROWN
	elif "lars" in lord_id:
		color = Color.FOREST_GREEN
	
	img.fill(color)
	return ImageTexture.create_from_image(img)

func _get_province_lord(province) -> CharacterData:
	"""Get the lord governing a province."""
	if province.get("governor_id") and not province.governor_id.is_empty():
		return GameState.characters.get(province.governor_id)
	
	# Fallback: find any character from this family
	for char_id in GameState.characters:
		var character = GameState.characters[char_id]
		if character.family_id == province.owner_id:
			return character
	
	return null

func _update_stat_values(province):
	"""Update all stat labels with current values."""
	var stat_values = {
		"gold": province.gold,
		"food": province.food,
		"soldiers": province.soldiers,
		"loyalty": province.loyalty,
		"cultivation": province.cultivation,
		"protection": province.protection
	}
	
	for stat_name in stat_values:
		var label = stats_grid.get_node_or_null("Label" + stat_name.capitalize())
		if label:
			label.text = str(stat_values[stat_name])

func _update_action_buttons(is_owned: bool, province):
	"""Enable/disable action buttons based on ownership and state."""
	for button in action_buttons.get_children():
		if button is Button:
			button.disabled = !is_owned or province.is_exhausted
			
			if button.disabled:
				if not is_owned:
					button.tooltip_text = "Not your province"
				elif province.is_exhausted:
					button.tooltip_text = "Province already acted this turn"
	
	# Special handling for attack button
	var attack_button = action_buttons.get_node_or_null("AttackButton")
	if attack_button:
		attack_button.disabled = !can_attack(province.id, GameState.get_player_family().id)

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
		
		# Get adjacent enemy provinces
		var enemy_targets = []
		for neighbor_id in province.neighbors:
			var neighbor = GameState.provinces[neighbor_id]
			if neighbor.owner_id != player_family.id:
				enemy_targets.append(neighbor_id)
		
		if enemy_targets.is_empty():
			print("No attack targets available")
			return
		
		# For now, attack the first available target
		var target_id = enemy_targets[0]
		
		# Show attack animation
		if animation_controller:
			animation_controller.show_attack_arrow(current_province_id, target_id)
		
		# Launch tactical battle!
		print("Launching tactical battle: %s vs %s" % [province.name, GameState.provinces[target_id].name])
		BattleLauncher.launch_battle(current_province_id, target_id, 0.7, _on_battle_returned)

func _on_battle_resolved(result: Dictionary):
	# Show battle report dialog
	var battle_report = preload("res://ui/battle_report.gd").new()
	get_tree().current_scene.add_child(battle_report)
	
	# Get attacker and defender names
	var attacker_name = "Unknown"
	var defender_name = "Unknown"
	
	# Find the provinces involved in this battle
	for province_id in GameState.provinces:
		var province = GameState.provinces[province_id]
		if province_id in result.get("attacker_provinces", []):
			attacker_name = province.name
		if province_id in result.get("defender_provinces", []):
			defender_name = province.name
	
	battle_report.show_battle_report(result, attacker_name, defender_name)

func _on_battle_returned(result: Dictionary) -> void:
	"""Called when tactical battle ends and returns to strategic map."""
	print("Battle returned! Winner: ", result.get("winner", "unknown"))
	
	# Refresh the panel to show updated stats
	if current_province_id != -1:
		update_panel(current_province_id)

func can_attack(province_id: int, family_id: String) -> bool:
	var province = GameState.provinces[province_id]
	
	# Must own the province
	if province.owner_id != family_id:
		return false
	
	# Must not be exhausted
	if province.is_exhausted:
		return false
	
	# Must have adjacent enemies
	return has_adjacent_enemies(province_id)

func has_adjacent_enemies(province_id: int) -> bool:
	var province = GameState.provinces[province_id]
	var player_family = GameState.get_player_family()
	
	for neighbor_id in province.neighbors:
		var neighbor = GameState.provinces[neighbor_id]
		if neighbor.owner_id != player_family.id:
			return true
	
	return false
