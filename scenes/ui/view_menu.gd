extends Window

signal view_mode_selected(mode)
signal view_close_requested

const COLOR_BLUE = Color("#4a4a9e")
const COLOR_GOLD = Color("#c4a000")
const COLOR_TEXT = Color("#ffffff")

@onready var one_btn = $MarginContainer/VBoxContainer/OneBtn
@onready var many_btn = $MarginContainer/VBoxContainer/ManyBtn
@onready var land_btn = $MarginContainer/VBoxContainer/LandBtn
@onready var fifth_btn = $MarginContainer/VBoxContainer/FifthBtn
@onready var close_btn = $MarginContainer/VBoxContainer/CloseBtn

func _ready():
	_setup_button(one_btn, "one", "One - Individual Lord")
	_setup_button(many_btn, "many", "Many - Family Roster")
	_setup_button(land_btn, "land", "Land - Province Data")
	_setup_button(fifth_btn, "fifth", "5th Unit - Monster Inventory")
	_setup_button(close_btn, "", "Close")
	
	close_btn.pressed.connect(_on_close)
	
	# Set window properties
	title = "View"
	view_close_requested.connect(_on_close)

func _setup_button(btn: Button, mode: String, text: String):
	btn.text = text
	if not mode.is_empty():
		btn.pressed.connect(_on_mode_selected.bind(mode))
	
	# Style the button
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = COLOR_BLUE
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
	hover_style.bg_color = Color("#6a6abe")
	hover_style.border_color = Color("#e6d47a")
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	btn.add_theme_stylebox_override("hover", hover_style)
	
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", COLOR_TEXT)

func _on_mode_selected(mode: String):
	view_mode_selected.emit(mode)
	hide()

func _on_close():
	view_close_requested.emit()
	hide()
