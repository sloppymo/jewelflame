extends CanvasLayer

# Colors matching SNES Gemfire aesthetic
const COLOR_ROYAL_BLUE = Color("#4a4a9e")
const COLOR_GOLD = Color("#c4a000")
const COLOR_GOLD_HIGHLIGHT = Color("#e6d47a")
const COLOR_TEXT_WHITE = Color("#ffffff")
const COLOR_TEXT_BLACK = Color("#000000")

# Layout constants
const PANEL_WIDTH = 112  # 35% of 320
const MAP_WIDTH = 208    # 65% of 320
const COMMAND_BAR_HEIGHT = 28

# Current state
var current_lord_id: String = ""
var current_family_id: String = ""
var command_mode: String = ""  # battle, develop, search, military

# Signals
signal command_selected(command: String)
signal view_mode_selected(mode: String)
signal end_turn_requested

@onready var left_panel = $MarginContainer/MainHBox/LeftPanel
@onready var map_container = $MarginContainer/MainHBox/MapContainer
@onready var year_month_label = $MarginContainer/MainHBox/LeftPanel/VBoxContainer/TopSection/YearMonthLabel
@onready var family_shield = $MarginContainer/MainHBox/LeftPanel/VBoxContainer/TopSection/FamilyShield
@onready var family_name_label = $MarginContainer/MainHBox/LeftPanel/VBoxContainer/TopSection/FamilyNameLabel
@onready var province_label = $MarginContainer/MainHBox/LeftPanel/VBoxContainer/TopSection/ProvinceLabel
@onready var lord_portrait = $MarginContainer/MainHBox/LeftPanel/VBoxContainer/LordSection/LordPortrait
@onready var lord_name_label = $MarginContainer/MainHBox/LeftPanel/VBoxContainer/LordSection/LordNameLabel
@onready var stat_grid = $MarginContainer/MainHBox/LeftPanel/VBoxContainer/StatsSection/StatGrid
@onready var command_bar = $MarginContainer/MainHBox/LeftPanel/VBoxContainer/CommandBar
@onready var prompt_label = $MarginContainer/MainHBox/LeftPanel/VBoxContainer/PromptSection/PromptLabel
@onready var view_menu = $ViewMenu

# Command buttons
@onready var battle_btn = $MarginContainer/MainHBox/LeftPanel/VBoxContainer/CommandBar/BattleBtn
@onready var develop_btn = $MarginContainer/MainHBox/LeftPanel/VBoxContainer/CommandBar/DevelopBtn
@onready var search_btn = $MarginContainer/MainHBox/LeftPanel/VBoxContainer/CommandBar/SearchBtn
@onready var military_btn = $MarginContainer/MainHBox/LeftPanel/VBoxContainer/CommandBar/MilitaryBtn

# View menu buttons
@onready var one_btn = $ViewMenu/MarginContainer/VBoxContainer/OneBtn
@onready var many_btn = $ViewMenu/MarginContainer/VBoxContainer/ManyBtn
@onready var land_btn = $ViewMenu/MarginContainer/VBoxContainer/LandBtn
@onready var fifth_btn = $ViewMenu/MarginContainer/VBoxContainer/FifthBtn
@onready var close_btn = $ViewMenu/MarginContainer/VBoxContainer/CloseBtn

func _ready():
	# Connect to GameState signals
	EventBus.LordTurnStarted.connect(_on_lord_turn_started)
	EventBus.FamilyTurnStarted.connect(_on_family_turn_started)
	EventBus.TurnCompleted.connect(_on_turn_completed)
	
	# Connect command bar buttons
	battle_btn.pressed.connect(_on_command_pressed.bind("battle"))
	develop_btn.pressed.connect(_on_command_pressed.bind("develop"))
	search_btn.pressed.connect(_on_command_pressed.bind("search"))
	military_btn.pressed.connect(_on_command_pressed.bind("military"))
	
	# Style command buttons
	_style_command_button(battle_btn)
	_style_command_button(develop_btn)
	_style_command_button(search_btn)
	_style_command_button(military_btn)
	
	# Connect view menu buttons
	one_btn.pressed.connect(_on_view_mode_pressed.bind("one"))
	many_btn.pressed.connect(_on_view_mode_pressed.bind("many"))
	land_btn.pressed.connect(_on_view_mode_pressed.bind("land"))
	fifth_btn.pressed.connect(_on_view_mode_pressed.bind("fifth"))
	close_btn.pressed.connect(_on_view_menu_close)
	
	# Style view menu buttons
	_style_view_button(one_btn)
	_style_view_button(many_btn)
	_style_view_button(land_btn)
	_style_view_button(fifth_btn)
	_style_view_button(close_btn)
	
	# Set view menu properties
	view_menu.title = "View"
	view_menu.view_close_requested.connect(_on_view_menu_close)
	
	# Initial update
	_update_year_month()
	_update_prompt()

func _style_command_button(btn: Button):
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = COLOR_ROYAL_BLUE
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
	pressed_style.bg_color = Color("#2a2a7e")
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
	
	btn.add_theme_font_size_override("font_size", 16)

func _style_view_button(btn: Button):
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = COLOR_ROYAL_BLUE
	normal_style.border_color = COLOR_GOLD
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	btn.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color("#6a6abe")
	hover_style.border_color = COLOR_GOLD_HIGHLIGHT
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	btn.add_theme_stylebox_override("hover", hover_style)
	
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", COLOR_TEXT_WHITE)

func _on_command_pressed(command: String):
	command_mode = command
	
	match command:
		"battle":
			_set_prompt("Where do you wish to invade?")
		"develop":
			_set_prompt("Select province to develop.")
		"search":
			_set_prompt("Send searcher where?")
		"military":
			_set_prompt("Select military action.")
	
	command_selected.emit(command)

func _on_view_mode_pressed(mode: String):
	view_mode_selected.emit(mode)
	view_menu.hide()
	match mode:
		"one":
			_set_prompt("Viewing individual lord...")
		"many":
			_set_prompt("Viewing family roster...")
		"land":
			_set_prompt("Viewing province data...")
		"fifth":
			_set_prompt("Viewing 5th Unit inventory...")

func _on_view_menu_close():
	view_menu.hide()
	_update_prompt()

func _on_lord_turn_started(lord_id: String):
	current_lord_id = lord_id
	_update_lord_display()
	_update_prompt()

func _on_family_turn_started(family_id: String):
	current_family_id = family_id
	_update_family_display()

func _on_turn_completed(month: int, year: int):
	_update_year_month()

func _update_year_month():
	var month_names = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
					   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var month = GameState.current_month
	var year = GameState.current_year
	var month_name = month_names[month] if month >= 1 and month <= 12 else "???"
	year_month_label.text = "Year %d %s" % [year, month_name]

func _update_family_display():
	var family = GameState.get_family(current_family_id)
	if not family:
		return
	
	family_name_label.text = family.name
	family_shield.color = family.color
	
	# Count owned provinces
	var province_count = 0
	var capital_name = ""
	for province in GameState.provinces.values():
		if province.owner_id == current_family_id:
			province_count += 1
			if capital_name == "" or province.is_capital:
				capital_name = province.name
	
	province_label.text = "%d:%s" % [province_count, capital_name]

func _update_lord_display():
	var lord = GameState.get_character(current_lord_id)
	if not lord:
		return
	
	lord_name_label.text = lord.name
	_update_stats(lord)
	_update_portrait(lord)

func _update_stats(lord):
	# Clear existing stats
	for child in stat_grid.get_children():
		child.queue_free()
	
	# Add stat entries with pixel art icons
	var stats = [
		{"icon_path": "res://assets/ui/icons/icon_gold.png", "value": _get_lord_gold(lord), "color": COLOR_GOLD},
		{"icon_path": "res://assets/ui/icons/icon_troops.png", "value": lord.command_rating if lord.has_method("get") else 50, "color": COLOR_TEXT_WHITE},
		{"icon_path": "res://assets/ui/icons/icon_food.png", "value": _get_lord_food(lord), "color": COLOR_TEXT_WHITE},
		{"icon_path": "res://assets/ui/icons/icon_attack.png", "value": lord.attack_rating if lord.has_method("get") else 50, "color": COLOR_TEXT_WHITE},
		{"icon_path": "res://assets/ui/icons/icon_defense.png", "value": _get_lord_troops(lord), "color": COLOR_TEXT_WHITE},
		{"icon_path": "res://assets/ui/icons/icon_loyalty.png", "value": lord.defense_rating if lord.has_method("get") else 50, "color": COLOR_TEXT_WHITE}
	]
	
	for stat in stats:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 4)
		
		# Create icon TextureRect
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(16, 16)
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Load icon texture
		var texture = load(stat.icon_path)
		if texture:
			icon_rect.texture = texture
		else:
			push_warning("Failed to load icon: " + stat.icon_path)
		
		hbox.add_child(icon_rect)
		
		var value_label = Label.new()
		value_label.text = str(stat.value)
		value_label.add_theme_color_override("font_color", COLOR_TEXT_WHITE)
		value_label.add_theme_font_size_override("font_size", 12)
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(value_label)
		
		stat_grid.add_child(hbox)

func _update_portrait(lord):
	if lord_portrait and lord.portrait_path:
		var texture = load(lord.portrait_path)
		if texture:
			lord_portrait.texture = texture
			lord_portrait.texture_filter = TEXTURE_FILTER_NEAREST
			lord_portrait.expand_mode = EXPAND_MODE_KEEP_SIZE
			lord_portrait.stretch_mode = STRETCH_MODE_KEEP_ASPECT_CENTERED
			print("Loaded portrait for: ", lord.name)
		else:
			push_warning("Failed to load portrait: " + lord.portrait_path)

func _get_lord_gold(lord) -> int:
	var total = 0
	for province in GameState.provinces.values():
		if province.owner_id == lord.family_id:
			total += province.gold
	return total

func _get_lord_food(lord) -> int:
	var total = 0
	for province in GameState.provinces.values():
		if province.owner_id == lord.family_id:
			total += province.food
	return total

func _get_lord_troops(lord) -> int:
	var total = 0
	for province in GameState.provinces.values():
		if province.owner_id == lord.family_id:
			total += province.soldiers
	return total

func _set_prompt(text: String):
	prompt_label.text = text

func _update_prompt():
	if current_lord_id.is_empty():
		_set_prompt("Select a lord...")
	else:
		var lord = GameState.get_character(current_lord_id)
		if lord:
			_set_prompt("Lord %s, what is your command?" % lord.name)

func show_event_banner(event_text: String, event_icon: String = ""):
	var banner = $EventBanner
	if banner:
		var icon_label = banner.get_node("Panel/HBoxContainer/IconLabel")
		var text_label = banner.get_node("Panel/HBoxContainer/TextLabel")
		
		icon_label.text = event_icon if not event_icon.is_empty() else "📢"
		text_label.text = event_text
		
		banner.show()
		await get_tree().create_timer(5.0).timeout
		banner.hide()

func show_ai_notification(notification: String):
	var banner = $AINotification
	if banner:
		var text_label = banner.get_node("Panel/TextLabel")
		text_label.text = notification
		
		banner.show()
		await get_tree().create_timer(4.0).timeout
		banner.hide()
