extends HBoxContainer

# Command types matching the 4-icon layout from Gemfire
const COMMAND_BATTLE = "battle"
const COMMAND_DEVELOP = "develop"
const COMMAND_SEARCH = "search"
const COMMAND_MILITARY = "military"
const COMMAND_VIEW = "view"
const COMMAND_END_TURN = "end_turn"

# Colors
const COLOR_NORMAL = Color("#4a4a9e")
const COLOR_HOVER = Color("#6a6abe")
const COLOR_ACTIVE = Color("#2a2a7e")
const COLOR_GOLD = Color("#c4a000")
const COLOR_GOLD_HIGHLIGHT = Color("#e6d47a")

signal command_selected(command: String)

var buttons: Dictionary = {}
var active_command: String = ""

@onready var battle_btn = $BattleBtn
@onready var develop_btn = $DevelopBtn
@onready var search_btn = $SearchBtn
@onready var military_btn = $MilitaryBtn

func _ready():
	_setup_button(battle_btn, COMMAND_BATTLE, "⚔️", "Battle")
	_setup_button(develop_btn, COMMAND_DEVELOP, "🏛️", "Develop")
	_setup_button(search_btn, COMMAND_SEARCH, "🚩", "Search")
	_setup_button(military_btn, COMMAND_MILITARY, "🪖", "Military")
	
	# Add View and End Turn buttons in a second row (optional)
	# These could be separate or integrated differently

func _setup_button(btn: Button, command: String, icon: String, tooltip: String):
	btn.text = icon
	btn.tooltip_text = tooltip
	btn.pressed.connect(_on_button_pressed.bind(command))
	btn.mouse_entered.connect(_on_button_hover.bind(command, true))
	btn.mouse_exited.connect(_on_button_hover.bind(command, false))
	buttons[command] = btn
	
	# Style the button
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = COLOR_NORMAL
	normal_style.border_color = COLOR_GOLD
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = COLOR_HOVER
	hover_style.border_color = COLOR_GOLD_HIGHLIGHT
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	hover_style.corner_radius_top_left = 4
	hover_style.corner_radius_top_right = 4
	hover_style.corner_radius_bottom_left = 4
	hover_style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = COLOR_ACTIVE
	pressed_style.border_color = COLOR_GOLD
	pressed_style.border_width_left = 3
	pressed_style.border_width_top = 3
	pressed_style.border_width_right = 1
	pressed_style.border_width_bottom = 1
	pressed_style.corner_radius_top_left = 4
	pressed_style.corner_radius_top_right = 4
	pressed_style.corner_radius_bottom_left = 4
	pressed_style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	# Set font size
	btn.add_theme_font_size_override("font_size", 16)

func _on_button_pressed(command: String):
	active_command = command
	_update_button_states()
	command_selected.emit(command)

func _on_button_hover(command: String, is_hovering: bool):
	# Additional hover effects could go here
	pass

func _update_button_states():
	for cmd in buttons:
		var btn = buttons[cmd]
		if cmd == active_command:
			btn.modulate = Color(0.8, 0.8, 1.0)
		else:
			btn.modulate = Color.WHITE

func set_active_command(command: String):
	active_command = command
	_update_button_states()

func clear_active():
	active_command = ""
	_update_button_states()
