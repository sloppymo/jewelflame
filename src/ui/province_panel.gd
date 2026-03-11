## Jewelflame/UI/ProvincePanel
## Main interaction panel for province management
## Left 40% of screen, ornate styling, SNES-era pixel aesthetic

class_name ProvincePanel
extends Control

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var province_id: String = ""

## Texture references (set in inspector or fallback to defaults)
@export var panel_border_texture: Texture2D
@export var portrait_frame_texture: Texture2D
@export var portrait_texture: Texture2D
@export var icon_gold: Texture2D
@export var icon_food: Texture2D
@export var icon_mana: Texture2D
@export var icon_troops: Texture2D

## Faction colors
const COLOR_BLANCHE: Color = Color("#1a3a7a")  # Royal blue
const COLOR_LYLE: Color = Color("#8b2a2a")     # Crimson
const COLOR_CORYLL: Color = Color("#2a6b3a")   # Forest green

const COLOR_GOLD: Color = Color("#d4af37")
const COLOR_CREAM: Color = Color("#f4e4c1")
const COLOR_GREEN: Color = Color("#4a8b4a")

# ============================================================================
# UI REFERENCES - Created dynamically in _ready()
# ============================================================================

var panel_background: NinePatchRect
var portrait_frame: NinePatchRect
var portrait_rect: TextureRect
var province_name_label: Label
var lord_name_label: Label

var gold_label: Label
var food_label: Label
var mana_label: Label
var troops_label: Label

var recruit_button: Button
var develop_button: Button
var attack_button: Button
var info_button: Button

var resource_grid: GridContainer

# ============================================================================
# STATE
# ============================================================================

var current_province: Province = null
var is_player_turn: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_create_ui_structure()
	_setup_panel_style()
	_connect_signals()
	_hide_panel()

func _create_ui_structure() -> void:
	"""Create the complete UI hierarchy dynamically."""
	
	# Main panel background (NinePatchRect for scalable frame)
	panel_background = NinePatchRect.new()
	panel_background.name = "PanelBackground"
	panel_background.texture = panel_border_texture if panel_border_texture else _get_default_panel_texture()
	panel_background.patch_margin_left = 24
	panel_background.patch_margin_right = 24
	panel_background.patch_margin_top = 24
	panel_background.patch_margin_bottom = 24
	panel_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel_background)
	
	# Content container - margins inside the frame
	var content = MarginContainer.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("margin_left", 32)
	content.add_theme_constant_override("margin_right", 32)
	content.add_theme_constant_override("margin_top", 32)
	content.add_theme_constant_override("margin_bottom", 32)
	panel_background.add_child(content)
	
	# Main vertical layout
	var vbox = VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.add_theme_constant_override("separation", 16)
	content.add_child(vbox)
	
	# --- HEADER SECTION ---
	var header = HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 16)
	vbox.add_child(header)
	
	# Portrait frame (NinePatchRect for decorative border)
	portrait_frame = NinePatchRect.new()
	portrait_frame.name = "PortraitFrame"
	portrait_frame.texture = portrait_frame_texture if portrait_frame_texture else _get_default_frame_texture()
	portrait_frame.patch_margin_left = 8
	portrait_frame.patch_margin_right = 8
	portrait_frame.patch_margin_top = 8
	portrait_frame.patch_margin_bottom = 8
	portrait_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_frame.custom_minimum_size = Vector2(120, 160)
	header.add_child(portrait_frame)
	
	# Portrait texture inside frame
	portrait_rect = TextureRect.new()
	portrait_rect.name = "Portrait"
	portrait_rect.texture = portrait_texture if portrait_texture else _get_default_portrait_texture()
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait_rect.set_anchor_and_offset(MARGIN_LEFT, 0, 8)
	portrait_rect.set_anchor_and_offset(MARGIN_RIGHT, 1, -8)
	portrait_rect.set_anchor_and_offset(MARGIN_TOP, 0, 8)
	portrait_rect.set_anchor_and_offset(MARGIN_BOTTOM, 1, -8)
	portrait_frame.add_child(portrait_rect)
	
	# Info column (faction banner + names)
	var info_column = VBoxContainer.new()
	info_column.name = "InfoColumn"
	info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(info_column)
	
	# Faction banner placeholder (could be TextureRect with banner)
	var banner = ColorRect.new()
	banner.name = "FactionBanner"
	banner.custom_minimum_size = Vector2(0, 32)
	banner.color = COLOR_BLANCHE
	info_column.add_child(banner)
	
	# Province name label
	province_name_label = Label.new()
	province_name_label.name = "ProvinceName"
	province_name_label.text = "3: Petaria"
	province_name_label.add_theme_font_size_override("font_size", 24)
	province_name_label.add_theme_color_override("font_color", COLOR_GOLD)
	info_column.add_child(province_name_label)
	
	# Lord name label
	lord_name_label = Label.new()
	lord_name_label.name = "LordName"
	lord_name_label.text = "Lars"
	lord_name_label.add_theme_font_size_override("font_size", 20)
	lord_name_label.add_theme_color_override("font_color", COLOR_CREAM)
	info_column.add_child(lord_name_label)
	
	# --- RESOURCE GRID ---
	resource_grid = GridContainer.new()
	resource_grid.name = "ResourceGrid"
	resource_grid.columns = 2
	resource_grid.add_theme_constant_override("h_separation", 32)
	resource_grid.add_theme_constant_override("v_separation", 12)
	vbox.add_child(resource_grid)
	
	# Create resource slots
	_create_resource_slot("gold", icon_gold if icon_gold else _get_default_icon("gold"), "100")
	_create_resource_slot("food", icon_food if icon_food else _get_default_icon("food"), "100")
	_create_resource_slot("mana", icon_mana if icon_mana else _get_default_icon("mana"), "50")
	_create_resource_slot("troops", icon_troops if icon_troops else _get_default_icon("troops"), "0")
	_create_resource_slot("population", _get_default_icon("population"), "0")
	_create_resource_slot("castles", _get_default_icon("castle"), "0")
	
	# Store label references
	gold_label = resource_grid.get_node("GoldSlot/Value")
	food_label = resource_grid.get_node("FoodSlot/Value")
	mana_label = resource_grid.get_node("ManaSlot/Value")
	troops_label = resource_grid.get_node("TroopsSlot/Value")
	
	# --- UNIT TYPE ROW ---
	var unit_row = HBoxContainer.new()
	unit_row.name = "UnitRow"
	unit_row.alignment = BoxContainer.ALIGNMENT_CENTER
	unit_row.add_theme_constant_override("separation", 16)
	vbox.add_child(unit_row)
	
	# Unit type icons (placeholder)
	for i in range(4):
		var unit_icon = TextureRect.new()
		unit_icon.name = "UnitIcon%d" % i
		unit_icon.custom_minimum_size = Vector2(32, 32)
		unit_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		unit_row.add_child(unit_icon)
	
	# --- DIALOGUE SECTION ---
	var dialogue_label = Label.new()
	dialogue_label.name = "Dialogue"
	dialogue_label.text = "Lars, what is your command?"
	dialogue_label.add_theme_font_size_override("font_size", 16)
	dialogue_label.add_theme_color_override("font_color", COLOR_CREAM)
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(dialogue_label)
	
	# --- BUTTON ROW ---
	var button_row = HBoxContainer.new()
	button_row.name = "ButtonRow"
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 8)
	vbox.add_child(button_row)
	
	recruit_button = Button.new()
	recruit_button.name = "RecruitButton"
	recruit_button.text = "Recruit"
	button_row.add_child(recruit_button)
	
	develop_button = Button.new()
	develop_button.name = "DevelopButton"
	develop_button.text = "Develop"
	button_row.add_child(develop_button)
	
	attack_button = Button.new()
	attack_button.name = "AttackButton"
	attack_button.text = "Attack"
	button_row.add_child(attack_button)
	
	info_button = Button.new()
	info_button.name = "InfoButton"
	info_button.text = "Info"
	button_row.add_child(info_button)

func _create_resource_slot(id: String, icon: Texture2D, initial_value: String) -> void:
	"""Create a resource slot with icon and value label."""
	var slot = HBoxContainer.new()
	slot.name = id.capitalize() + "Slot"
	slot.add_theme_constant_override("separation", 8)
	
	var icon_rect = TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.texture = icon
	icon_rect.custom_minimum_size = Vector2(32, 32)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slot.add_child(icon_rect)
	
	var value_label = Label.new()
	value_label.name = "Value"
	value_label.text = initial_value
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", COLOR_CREAM)
	slot.add_child(value_label)
	
	resource_grid.add_child(slot)

func _setup_panel_style() -> void:
	"""Apply additional styling after node creation."""
	# Panel is already styled in _create_ui_structure
	pass

func _connect_signals() -> void:
	# Connect to EventBus
	EventBus.province_selected.connect(_on_province_selected)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.province_exhausted.connect(_on_province_exhausted)
	
	# Connect buttons
	if recruit_button:
		recruit_button.pressed.connect(_on_recruit_pressed)
	if develop_button:
		develop_button.pressed.connect(_on_develop_pressed)
	if attack_button:
		attack_button.pressed.connect(_on_attack_pressed)
	if info_button:
		info_button.pressed.connect(_on_info_pressed)

# ============================================================================
# FALLBACK TEXTURES
# ============================================================================

func _get_default_panel_texture() -> Texture2D:
	"""Create a simple fallback panel texture if none provided."""
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	# Fill with purple background
	img.fill(Color("#4a3a6a"))
	# Draw border
	for x in range(64):
		img.set_pixel(x, 0, Color("#d4af37"))
		img.set_pixel(x, 63, Color("#d4af37"))
	for y in range(64):
		img.set_pixel(0, y, Color("#d4af37"))
		img.set_pixel(63, y, Color("#d4af37"))
	return ImageTexture.create_from_image(img)

func _get_default_frame_texture() -> Texture2D:
	"""Create a simple fallback frame texture."""
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color("#3a2a5a"))
	# Gold border
	for x in range(32):
		img.set_pixel(x, 0, Color("#d4af37"))
		img.set_pixel(x, 31, Color("#d4af37"))
	for y in range(32):
		img.set_pixel(0, y, Color("#d4af37"))
		img.set_pixel(31, y, Color("#d4af37"))
	return ImageTexture.create_from_image(img)

func _get_default_portrait_texture() -> Texture2D:
	"""Create a placeholder portrait texture."""
	var img = Image.create(96, 144, false, Image.FORMAT_RGBA8)
	img.fill(Color("#6a5a8a"))
	return ImageTexture.create_from_image(img)

func _get_default_icon(type: String) -> Texture2D:
	"""Create a simple placeholder icon."""
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color("#d4af37"))
	return ImageTexture.create_from_image(img)

# ============================================================================
# PANEL DISPLAY
# ============================================================================

func show_province(province: Province) -> void:
	current_province = province
	province_id = province.id
	
	_update_display()
	_show_panel()
	
	EventBus.panel_opened.emit(province_id)

func _update_display() -> void:
	if not current_province:
		return
	
	# Province name (e.g., "3: Cobrige")
	if province_name_label:
		province_name_label.text = "%s: %s" % [current_province.id, current_province.name]
		province_name_label.add_theme_color_override("font_color", COLOR_GOLD)
	
	# Lord name and portrait
	var family_id := current_province.owner_faction
	var family_data := GameState.factions.get(family_id, {})
	
	if lord_name_label:
		lord_name_label.text = family_data.get("leader_name", "Unknown")
		lord_name_label.add_theme_color_override("font_color", COLOR_CREAM)
	
	# Set portrait based on family
	if portrait_rect:
		portrait_rect.texture = _get_portrait_for_family(family_id)
		# Tint background based on family
		portrait_rect.modulate = _get_tint_for_family(family_id)
	
	# Stats
	_update_stats()
	
	# Button states
	_update_button_states()

func _update_stats() -> void:
	if not current_province:
		return
	
	if gold_label:
		gold_label.text = str(current_province.calculate_gold_output())
	if food_label:
		food_label.text = str(current_province.calculate_food_output())
	if mana_label:
		mana_label.text = "0"  # TODO: Implement mana system
	if troops_label:
		troops_label.text = str(current_province.get_unit_count())

func _update_button_states() -> void:
	var can_act := current_province and current_province.can_act() and is_player_turn
	
	if recruit_button:
		recruit_button.disabled = not can_act
	if develop_button:
		develop_button.disabled = not can_act
	if attack_button:
		# Attack requires adjacent enemy province
		attack_button.disabled = not (can_act and _has_adjacent_enemy())

func _has_adjacent_enemy() -> bool:
	if not current_province:
		return false
	
	var player_faction := GameState.player_faction
	
	for connected_id in current_province.connected_to:
		var neighbor := GameState.get_province(connected_id)
		if neighbor and neighbor.owner_faction != player_faction:
			return true
	
	return false

func _get_portrait_for_family(family_id: String) -> Texture2D:
	# Return appropriate portrait texture
	# For now, use placeholders - in real game, load from assets/portraits/
	match family_id:
		"blanche":
			return portrait_texture if portrait_texture else _get_default_portrait_texture()
		"lyle":
			return portrait_texture if portrait_texture else _get_default_portrait_texture()
		_:
			return portrait_texture if portrait_texture else _get_default_portrait_texture()

func _get_tint_for_family(family_id: String) -> Color:
	match family_id:
		"blanche":
			return Color(1.0, 1.0, 1.0)  # No tint (blue background in image)
		"lyle":
			return Color(1.0, 0.9, 0.9)  # Warm tint
		"coryll":
			return Color(0.9, 1.0, 0.9)  # Green tint
		_:
			return Color(1.0, 1.0, 1.0)

# ============================================================================
# VISIBILITY
# ============================================================================

func _show_panel() -> void:
	visible = true
	# Animation: slide in from left
	var tween := create_tween()
	tween.tween_property(self, "position:x", 0, 0.2).from(-size.x)

func _hide_panel() -> void:
	visible = false
	current_province = null

func close_panel() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:x", -size.x, 0.2)
	tween.finished.connect(func(): _hide_panel())
	
	EventBus.panel_closed.emit()

# ============================================================================
# BUTTON HANDLERS
# ============================================================================

func _on_recruit_pressed() -> void:
	if not current_province:
		return
	
	EventBus.recruit_requested.emit(current_province.id)
	
	# Cost: 50 soldiers for 100 gold
	var cost := 100
	var current_gold := GameState.get_faction_gold(current_province.owner_faction)
	
	if current_gold < cost:
		EventBus.error_occurred.emit("Not enough gold! Need 100.")
		return
	
	# Deduct gold
	GameState.spend_gold(current_province.owner_faction, cost)
	
	# Add unit
	var unit_data := {
		"id": "unit_%d_%d" % [Time.get_ticks_msec(), randi()],
		"type": "infantry",
		"hp": 10,
		"attack": 3,
		"defense": 2
	}
	current_province.add_unit(unit_data)
	current_province.exhaust()
	
	_update_stats()
	_update_button_states()
	
	EventBus.action_completed.emit("recruit", true)
	EventBus.notification_shown.emit("Recruited 50 soldiers", "info")

func _on_develop_pressed() -> void:
	if not current_province:
		return
	
	EventBus.develop_requested.emit(current_province.id, "cultivation")
	
	# Cost: 10 gold
	var cost := 10
	var current_gold := GameState.get_faction_gold(current_province.owner_faction)
	
	if current_gold < cost:
		EventBus.error_occurred.emit("Not enough gold! Need 10.")
		return
	
	if current_province.agriculture_level >= Province.MAX_AGRICULTURE_LEVEL:
		EventBus.error_occurred.emit("Already at maximum development!")
		return
	
	# Deduct gold and upgrade
	GameState.spend_gold(current_province.owner_faction, cost)
	current_province.upgrade_agriculture()
	current_province.exhaust()
	
	_update_stats()
	_update_button_states()
	
	EventBus.action_completed.emit("develop", true)
	EventBus.notification_shown.emit("Development improved!", "info")

func _on_attack_pressed() -> void:
	if not current_province:
		return
	
	# Find adjacent enemy province
	var player_faction := GameState.player_faction
	var target_id := ""
	
	for connected_id in current_province.connected_to:
		var neighbor := GameState.get_province(connected_id)
		if neighbor and neighbor.owner_faction != player_faction:
			target_id = connected_id
			break
	
	if target_id == "":
		EventBus.error_occurred.emit("No adjacent enemy province!")
		return
	
	EventBus.attack_requested.emit(current_province.id, target_id)
	
	# Launch battle
	var battle_data := GameState.start_battle(current_province.id, target_id)
	
	if battle_data.is_empty():
		EventBus.error_occurred.emit("Cannot start battle!")
		return
	
	# Transition to tactical scene
	get_tree().change_scene_to_file("res://scenes/tactical_battle.tscn")

func _on_info_pressed() -> void:
	# Show detailed province info (loyalty, terrain details, etc.)
	EventBus.notification_shown.emit("Province info: " + current_province.name, "info")

# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_province_selected(id: String) -> void:
	var province := GameState.get_province(id)
	if province:
		show_province(province)

func _on_turn_started(family_id: String) -> void:
	is_player_turn = (family_id == GameState.player_faction)
	_update_button_states()

func _on_province_exhausted(id: String, exhausted: bool) -> void:
	if current_province and current_province.id == id:
		_update_button_states()
