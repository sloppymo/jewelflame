@tool
extends PanelContainer
class_name GameSidebar

# Signals
signal action_pressed(action_type: String)
signal resource_clicked(resource_type: String)
signal section_changed(section_id: String)

# Enums
enum Section { MILITARY, ECONOMY, DIPLOMACY, SYSTEM }

# Exported Properties - Character
@export var portrait_texture: Texture2D:
	set(value):
		portrait_texture = value
		if is_node_ready() and _portrait:
			_portrait.texture = value

@export var character_name: String = "Unknown":
	set(value):
		character_name = value
		if is_node_ready() and _name_label:
			_name_label.text = value

@export var character_title: String = "":
	set(value):
		character_title = value
		if is_node_ready() and _title_label:
			_title_label.text = value

@export var character_level: int = 1:
	set(value):
		character_level = value
		if is_node_ready() and _level_label:
			_level_label.text = "⚔️ Level %d" % value

# Exported Properties - Resources
@export var gold: int = 0:
	set(value):
		gold = value
		_update_resource_display("gold", value)

@export var food: int = 0:
	set(value):
		food = value
		_update_resource_display("food", value)

@export var troops: int = 0:
	set(value):
		troops = value
		_update_resource_display("troops", value)

@export var wood: int = 0:
	set(value):
		wood = value
		_update_resource_display("wood", value)

@export var holdings: int = 0:
	set(value):
		holdings = value
		_update_resource_display("holdings", value)

@export var influence: int = 0:
	set(value):
		influence = value
		_update_resource_display("influence", value)

# Node References - Cached on ready
@onready var _portrait: TextureRect = %Portrait
@onready var _name_label: Label = %NameLabel
@onready var _title_label: Label = %TitleLabel
@onready var _level_label: Label = %LevelLabel
@onready var _turn_label: Label = %TurnLabel

@onready var _section_tabs: Dictionary = {
	Section.MILITARY: %MilitaryTab,
	Section.ECONOMY: %EconomyTab,
	Section.DIPLOMACY: %DiplomacyTab,
	Section.SYSTEM: %SystemTab
}

@onready var _action_buttons: Array[Button] = [%ActionButton1, %ActionButton2, %ActionButton3, %ActionButton4]
@onready var _resource_labels: Dictionary = {}

# State
var _current_section: Section = Section.MILITARY

# Action configuration
var _available_actions: Dictionary = {
	"military": ["attack", "defend", "recruit", "scout"],
	"economy": ["build", "trade", "tax", "develop"],
	"diplomacy": ["negotiate", "ally", "threaten", "bribe"],
	"system": ["save", "load", "settings", "end_turn"]
}

var _action_names: Dictionary = {
	"attack": "⚔️ Attack", "defend": "🛡️ Defend", "recruit": "👥 Recruit", "scout": "👁️ Scout",
	"build": "🏛️ Build", "trade": "💰 Trade", "tax": "📋 Tax", "develop": "🔨 Develop",
	"negotiate": "📜 Negotiate", "ally": "🤝 Ally", "threaten": "⚠️ Threaten", "bribe": "💎 Bribe",
	"save": "💾 Save", "load": "📂 Load", "settings": "⚙️ Settings", "end_turn": "✓ End Turn"
}

# Track current callables for safe disconnection
var _current_callables: Array[Callable] = []

func _ready() -> void:
	_setup_resource_labels()
	_setup_section_tabs()
	_apply_theme()
	_set_section(Section.MILITARY)

func _setup_resource_labels() -> void:
	_resource_labels = {
		"gold": %GoldValue, "food": %FoodValue, "troops": %TroopsValue,
		"wood": %WoodValue, "holdings": %HoldingsValue, "influence": %InfluenceValue
	}

func _setup_section_tabs() -> void:
	for section in _section_tabs.keys():
		var btn: Button = _section_tabs[section]
		if not btn.pressed.is_connected(_on_section_tab_pressed):
			btn.pressed.connect(_on_section_tab_pressed.bind(section), CONNECT_REFERENCE_COUNTED)

func _apply_theme() -> void:
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color("#1a2f3a")
	add_theme_stylebox_override("panel", bg_style)

func _on_section_tab_pressed(section: Section) -> void:
	_set_section(section)

func _set_section(section: Section) -> void:
	_current_section = section
	if section_changed.get_connections().size() > 0:
		section_changed.emit(_section_to_string(section))
	
	# Update tab highlighting
	for sec in _section_tabs.keys():
		_section_tabs[sec].modulate = Color.WHITE if sec == section else Color.GRAY
	
	_update_action_buttons()

func _update_action_buttons() -> void:
	var section_key: String = _section_to_key(_current_section)
	var actions: Array = _available_actions.get(section_key, [])
	
	# Disconnect old callables safely
	for i in range(_action_buttons.size()):
		var btn: Button = _action_buttons[i]
		
		# Check if we have a tracked callable for this button
		if i < _current_callables.size():
			var old_callable: Callable = _current_callables[i]
			if btn.pressed.is_connected(old_callable):
				btn.pressed.disconnect(old_callable)
	
	_current_callables.clear()
	
	# Set up new buttons
	for i in range(_action_buttons.size()):
		var btn: Button = _action_buttons[i]
		
		if i < actions.size():
			var action: String = actions[i]
			btn.text = _action_names.get(action, action)
			btn.visible = true
			btn.disabled = false
			
			# Create new callable and track it
			var new_callable := _on_action_pressed.bind(action)
			_current_callables.append(new_callable)
			
			if not btn.pressed.is_connected(new_callable):
				btn.pressed.connect(new_callable, CONNECT_REFERENCE_COUNTED)
		else:
			btn.visible = false

func _section_to_key(section: Section) -> String:
	match section:
		Section.MILITARY: return "military"
		Section.ECONOMY: return "economy"
		Section.DIPLOMACY: return "diplomacy"
		Section.SYSTEM: return "system"
		_: return "military"

func _section_to_string(section: Section) -> String:
	match section:
		Section.MILITARY: return "Military"
		Section.ECONOMY: return "Economy"
		Section.DIPLOMACY: return "Diplomacy"
		Section.SYSTEM: return "System"
		_: return "Unknown"

func _on_action_pressed(action_type: String) -> void:
	if action_pressed.get_connections().size() > 0:
		action_pressed.emit(action_type)

func _update_resource_display(resource_type: String, value: int) -> void:
	if _resource_labels.has(resource_type):
		var label: Label = _resource_labels[resource_type]
		if is_instance_valid(label):
			label.text = str(value)

# Public API

func set_character(data: Dictionary) -> void:
	if data.has("portrait"): portrait_texture = data["portrait"]
	if data.has("name"): character_name = data["name"]
	if data.has("title"): character_title = data["title"]
	if data.has("level"): character_level = data["level"]

func update_resource(type: String, value: int, _max_value: int = -1) -> void:
	match type.to_lower():
		"gold": gold = value
		"food": food = value
		"troops": troops = value
		"wood": wood = value
		"holdings": holdings = value
		"influence": influence = value

func set_available_actions(section: String, actions: Array[String]) -> void:
	_available_actions[section] = actions
	if _section_to_key(_current_section) == section:
		_update_action_buttons()

func set_action_enabled(action_type: String, enabled: bool) -> void:
	for btn in _action_buttons:
		if btn.visible and btn.text.find(action_type.capitalize()) != -1:
			btn.disabled = !enabled
			break

func set_turn_info(year: int, month: String) -> void:
	if is_instance_valid(_turn_label):
		_turn_label.text = "Year %d - %s" % [year, month]
