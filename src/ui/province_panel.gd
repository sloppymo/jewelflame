## Jewelflame/UI/ProvincePanel
## Main interaction panel for province management
## Left 40% of screen, ornate styling, SNES-era pixel aesthetic

class_name ProvincePanel
extends Control

# ============================================================================
# CONFIGURATION
# ============================================================================

@export var province_id: String = ""

## Texture references (set in inspector)
@export var panel_border_texture: Texture2D
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
# UI REFERENCES (to be wired in scene)
# ============================================================================

@onready var panel_container: PanelContainer
@onready var nine_patch: NinePatchRect
@onready var portrait_rect: TextureRect
@onready var province_name_label: Label
@onready var lord_name_label: Label

@onready var gold_label: Label
@onready var food_label: Label
@onready var mana_label: Label
@onready var troops_label: Label

@onready var recruit_button: Button
@onready var develop_button: Button
@onready var attack_button: Button
@onready var info_button: Button

# ============================================================================
# STATE
# ============================================================================

var current_province: Province = null
var is_player_turn: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	_setup_panel_style()
	_connect_signals()
	_hide_panel()

func _setup_panel_style() -> void:
	# Ensure pixel-perfect rendering
	if nine_patch:
	nine_patch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		nine_patch.texture = panel_border_texture
		# 24px margins as specified
		nine_patch.patch_margin_left = 24
		nine_patch.patch_margin_right = 24
		nine_patch.patch_margin_top = 24
		nine_patch.patch_margin_bottom = 24
	
	if portrait_rect:
		portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait_rect.custom_minimum_size = Vector2(256, 384)  # 2× native
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

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
			return portrait_texture  # Lady Elara
		"lyle":
			return portrait_texture  # Lord Roland (different texture in real game)
		_:
			return portrait_texture

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
