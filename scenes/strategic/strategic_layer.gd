extends Node2D

# Main Strategic Layer - combines HexForge grid with Strategic HUD

const COLOR_ROYAL_BLUE = Color("#4a4a9e")
const COLOR_GOLD = Color("#c4a000")

const LordData = preload("res://resources/data_classes/lord_data.gd")

var current_command: String = ""
var selected_province_id: int = -1

# View sub-windows
var view_many_window = null
var view_land_window = null
var view_fifth_window = null
var view_one_window = null

# Tactical battle
var tactical_battle_scene = null
var current_battle_result = null
var pending_battle_data: Dictionary = {}

@onready var strategic_hud = $StrategicHUD

func _ready():
	_setup_strategic_hud()
	_setup_view_windows()
	_connect_signals()
	
	# Connect to battle request signal from EnhancedGameState
	EventBus.RequestTacticalBattle.connect(_on_request_tactical_battle)
	
	print("Strategic Layer initialized")

func _on_request_tactical_battle(battle_data: Dictionary):
	"""Handle battle launch request from EnhancedGameState"""
	print("DEBUG: StrategicLayer received battle request")
	
	# Build the battle data structures
	var attacker_lord = battle_data.get("attacker")
	var defender_lord = battle_data.get("defender")
	
	if not attacker_lord or not defender_lord:
		push_error("Missing lord data in battle request")
		return
	
	# Store for result processing
	pending_battle_data = {
		"attacker": attacker_lord,
		"defender": defender_lord,
		"province_id": battle_data.get("province_id", 0)
	}
	
	# Launch tactical scene
	_launch_tactical_scene(attacker_lord, defender_lord)

func _launch_tactical_scene(attacker, defender):
	"""Instantiate and configure tactical battle"""
	print("DEBUG: Launching tactical scene for ", attacker.name, " vs ", defender.name)
	
	# Hide strategic UI
	if strategic_hud:
		strategic_hud.hide()
	
	# Load tactical scene
	var tactical_scene = load("res://scenes/tactical/tactical_battle.tscn")
	if not tactical_scene:
		push_error("Failed to load tactical_battle.tscn")
		strategic_hud.show()
		return
	
	var instance = tactical_scene.instantiate()
	tactical_battle_scene = instance
	
	# Configure data with province_id for result processing
	instance.attacker_data = _build_battle_data(attacker)
	instance.defender_data = _build_battle_data(defender)
	instance.set_meta("province_id", pending_battle_data.get("province_id", 0))
	
	# Connect completion signal before adding to tree
	if not instance.battle_ended.is_connected(_on_tactical_battle_ended):
		instance.battle_ended.connect(_on_tactical_battle_ended)
	
	add_child(instance)
	print("DEBUG: Tactical battle scene added to tree")

func _build_battle_data(lord) -> Dictionary:
	"""Convert lord to battle data format"""
	if not lord:
		return {}
	
	return {
		"lord": lord,
		"units": _build_units_from_lord(lord),
		"personality": _get_personality(lord),
		"time_of_day": "day"
	}

func _setup_strategic_hud():
	# Get references to HUD elements
	var battle_btn = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/CommandBar/BattleBtn")
	var develop_btn = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/CommandBar/DevelopBtn")
	var search_btn = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/CommandBar/SearchBtn")
	var military_btn = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/CommandBar/MilitaryBtn")
	var view_btn = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/CommandBar/ViewBtn")
	var end_turn_btn = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/CommandBar/EndTurnBtn")
	
	# Connect command buttons
	battle_btn.pressed.connect(_on_command_selected.bind("battle"))
	develop_btn.pressed.connect(_on_command_selected.bind("develop"))
	search_btn.pressed.connect(_on_command_selected.bind("search"))
	military_btn.pressed.connect(_on_command_selected.bind("military"))
	view_btn.pressed.connect(_on_view_button_pressed)
	end_turn_btn.pressed.connect(_on_end_turn_requested)
	
	# Style buttons
	_style_command_button(battle_btn)
	_style_command_button(develop_btn)
	_style_command_button(search_btn)
	_style_command_button(military_btn)
	_style_command_button(view_btn)
	_style_command_button(end_turn_btn)
	
	# Setup view menu
	var view_menu = strategic_hud.get_node("ViewMenu")
	var one_btn = view_menu.get_node("MarginContainer/VBoxContainer/OneBtn")
	var many_btn = view_menu.get_node("MarginContainer/VBoxContainer/ManyBtn")
	var land_btn = view_menu.get_node("MarginContainer/VBoxContainer/LandBtn")
	var fifth_btn = view_menu.get_node("MarginContainer/VBoxContainer/FifthBtn")
	var close_btn = view_menu.get_node("MarginContainer/VBoxContainer/CloseBtn")
	
	one_btn.pressed.connect(_on_view_mode_selected.bind("one"))
	many_btn.pressed.connect(_on_view_mode_selected.bind("many"))
	land_btn.pressed.connect(_on_view_mode_selected.bind("land"))
	fifth_btn.pressed.connect(_on_view_mode_selected.bind("fifth"))
	close_btn.pressed.connect(_on_view_menu_closed)
	
	# Style view menu buttons
	_style_view_button(one_btn)
	_style_view_button(many_btn)
	_style_view_button(land_btn)
	_style_view_button(fifth_btn)
	_style_view_button(close_btn)
	
	# Set view menu title
	view_menu.title = "View"

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
	hover_style.border_color = Color("#e6d47a")
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
	
	btn.add_theme_font_size_override("font_size", 14)

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
	hover_style.border_color = Color("#e6d47a")
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	btn.add_theme_stylebox_override("hover", hover_style)
	
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color.WHITE)

func _setup_view_windows():
	# Preload view scenes (they will be instantiated when needed)
	pass

func _connect_signals():
	# Connect to GameState events
	EventBus.TurnCompleted.connect(_on_turn_completed)
	EventBus.FamilyTurnStarted.connect(_on_family_turn_started)
	EventBus.LordTurnStarted.connect(_on_lord_turn_started)

func _on_command_selected(command: String):
	current_command = command
	print("DEBUG: Command selected: ", command)
	
	var prompt_label = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/PromptSection/PromptLabel")
	
	match command:
		"battle":
			print("DEBUG: Battle command matched, starting test battle...")
			prompt_label.text = "Where do you wish to invade? (Click TEST BATTLE to test)"
			# For testing, immediately show a battle
			_start_test_battle()
		"develop":
			prompt_label.text = "Select province to develop."
		"search":
			prompt_label.text = "Send searcher where? (Cost: 5 gold)"
		"military":
			prompt_label.text = "Select military action."
	
	print("Command selected: ", command)

func _start_test_battle():
	# Start a test battle with real data from current lords
	print("DEBUG: _start_test_battle() called")
	var prompt_label = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/PromptSection/PromptLabel")
	prompt_label.text = "Loading tactical battle..."
	
	# Get current lords
	var current_family = EnhancedGameState.get_current_family()
	var attacker_lord = _get_first_lord(current_family)
	
	# Get enemy lord (first non-player family)
	var enemy_family = ""
	for family_id in EnhancedGameState.families:
		if family_id != current_family:
			enemy_family = family_id
			break
	var defender_lord = _get_first_lord(enemy_family)
	
	# Build battle data
	var attacker_units = _build_units_from_lord(attacker_lord)
	var defender_units = _build_units_from_lord(defender_lord)
	
	var battle_data = {
		"attacker": {
			"lord": attacker_lord,
			"units": attacker_units,
			"personality": _get_personality(attacker_lord),
			"time_of_day": "day"
		},
		"defender": {
			"lord": defender_lord,
			"units": defender_units,
			"terrain": "grass"
		}
	}
	
	# Load tactical battle scene
	var battle_scene = load("res://scenes/tactical/tactical_battle.tscn")
	if battle_scene:
		tactical_battle_scene = battle_scene.instantiate()
		tactical_battle_scene.attacker_data = battle_data.attacker
		tactical_battle_scene.defender_data = battle_data.defender
		add_child(tactical_battle_scene)
		
		# Connect to battle end signal
		tactical_battle_scene.battle_ended.connect(_on_tactical_battle_ended)
		tactical_battle_scene.lord_captured.connect(_on_lord_captured)
		
		# Hide strategic HUD during battle
		strategic_hud.hide()

func _get_first_lord(family_id: String):
	for char_id in EnhancedGameState.characters:
		var character = EnhancedGameState.characters[char_id]
		if character.family_id == family_id and character.is_lord:
			return character
	return null

func _build_units_from_lord(lord) -> Array:
	if not lord:
		return [{"type": "Knights", "count": 20}]
	
	# Build units based on lord's stats
	var units = []
	var base_troops = 20
	
	base_troops = lord.command_rating / 2
	
	units.append({"type": "Knights", "count": base_troops})
	
	# Add second unit type based on family
	if lord.family_id == "blanche":
		units.append({"type": "Mages", "count": base_troops / 2})
	elif lord.family_id == "lyle":
		units.append({"type": "Horsemen", "count": base_troops / 2})
	else:
		units.append({"type": "Archers", "count": base_troops / 2})
	
	return units

func _get_personality(lord) -> String:
	# Return personality based on lord's attack/defense stats
	if not lord:
		return "balanced"
	
	# Check if lord has attack/defense ratings (LordData has them, CharacterData doesn't)
	if lord is LordData:
		var lord_data = lord as LordData
		if lord_data.attack_rating > lord_data.defense_rating + 10:
			return "aggressive"
		elif lord_data.defense_rating > lord_data.attack_rating + 10:
			return "defensive"
	
	return "balanced"

func _on_lord_captured(captured_lord, captor):
	print("Lord captured: ", captured_lord.name, " by ", captor.name if captor else "unknown")
	# Update game state to reflect capture
	captured_lord.is_captured = true

func _on_tactical_battle_ended(result: Dictionary):
	"""Handle tactical battle completion and notify EnhancedGameState"""
	print("DEBUG: Tactical battle ended with result: ", result)
	current_battle_result = result
	
	# Remove battle scene
	if tactical_battle_scene:
		tactical_battle_scene.queue_free()
		tactical_battle_scene = null
	
	# Show strategic HUD again
	strategic_hud.show()
	
	# Apply battle results to game state
	_apply_battle_results(result)
	
	# Signal completion back to EnhancedGameState
	EventBus.TacticalBattleCompleted.emit(result)
	
	var prompt_label = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/PromptSection/PromptLabel")
	
	# Check for captured lord
	if result.get("attacker_lost"):
		prompt_label.text = "Battle lost! Your forces were defeated."
	elif result.get("attacker_won"):
		prompt_label.text = "Victory! Enemy defeated."
	elif result.get("retreat"):
		prompt_label.text = "Retreated from battle."
	
	# Show ransom dialog if lord captured
	if result.get("lord_captured"):
		_show_ransom_dialog(result.get("captured_lord"))

func _show_ransom_dialog(lord):
	var ransom_scene = load("res://scenes/tactical/ransom_dialog.tscn")
	if ransom_scene:
		var ransom_dialog = ransom_scene.instantiate()
		add_child(ransom_dialog)
		ransom_dialog.show_ransom_dialog(lord, EnhancedGameState.get_current_family())
		ransom_dialog.dialog_closed.connect(func(): ransom_dialog.queue_free())

func return_from_battle(result: Dictionary):
	_on_tactical_battle_ended(result)

func _apply_battle_results(result: Dictionary):
	"""Update game state based on battle outcome"""
	var winner = result.get("winner", "")
	var province_id = result.get("province_id", pending_battle_data.get("province_id", -1))
	var province_captured = result.get("province_captured", false)
	
	print("DEBUG: Applying battle results - winner: ", winner, ", province_id: ", province_id, ", captured: ", province_captured)
	
	# Handle province capture
	if province_id >= 0 and province_captured and winner == "attacker":
		var province = EnhancedGameState.get_province(province_id)
		var winner_lord = pending_battle_data.get("attacker")
		
		if province and winner_lord:
			# Transfer ownership
			var old_owner = province.owner_id
			province.owner_id = winner_lord.family_id
			province.governor_id = winner_lord.id
			print("DEBUG: Province ", province_id, " captured by ", winner_lord.name, 
				" (family: ", winner_lord.family_id, ", was: ", old_owner, ")")
			
			# Emit province changed signal
			EventBus.ProvinceDataChanged.emit(province_id, "owner_id", province.owner_id)
	else:
		print("DEBUG: No province capture - province_id: ", province_id, ", captured: ", province_captured, ", winner: ", winner)
	
	# Handle lord capture
	if result.get("lord_captured", false):
		var captured_lord = result.get("captured_lord")
		if captured_lord:
			captured_lord.is_captured = true
			print("DEBUG: Lord captured: ", captured_lord.name)

func _on_view_button_pressed():
	var view_menu = strategic_hud.get_node("ViewMenu")
	view_menu.popup_centered()

func _on_view_mode_selected(mode: String):
	var view_menu = strategic_hud.get_node("ViewMenu")
	view_menu.hide()
	
	var current_family = EnhancedGameState.get_current_family()
	var prompt_label = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/PromptSection/PromptLabel")
	
	match mode:
		"one":
			prompt_label.text = "Viewing individual lord..."
			_show_view_one()
		"many":
			prompt_label.text = "Viewing family roster..."
			_show_view_many(current_family)
		"land":
			prompt_label.text = "Viewing province data..."
			_show_view_land(current_family)
		"fifth":
			prompt_label.text = "Viewing 5th Unit inventory..."
			_show_view_fifth(current_family)

func _show_view_many(family_id: String):
	var scene = load("res://scenes/ui/view_many.tscn")
	if scene:
		view_many_window = scene.instantiate()
		add_child(view_many_window)
		view_many_window.view_close_requested.connect(_on_view_closed)
		view_many_window.show_family_roster(family_id)

func _show_view_land(family_id: String):
	var scene = load("res://scenes/ui/view_land.tscn")
	if scene:
		view_land_window = scene.instantiate()
		add_child(view_land_window)
		view_land_window.view_close_requested.connect(_on_view_closed)
		view_land_window.show_province_data(family_id)

func _show_view_fifth(family_id: String):
	var scene = load("res://scenes/ui/view_fifth.tscn")
	if scene:
		view_fifth_window = scene.instantiate()
		add_child(view_fifth_window)
		view_fifth_window.view_close_requested.connect(_on_view_closed)
		view_fifth_window.show_monster_inventory(family_id)

func _show_view_one():
	var scene = load("res://scenes/ui/view_one.tscn")
	if scene:
		view_one_window = scene.instantiate()
		add_child(view_one_window)
		view_one_window.view_close_requested.connect(_on_view_closed)
		
		var current_lord = EnhancedGameState.selected_lord_id
		if current_lord.is_empty():
			var family_lords = EnhancedGameState.get_family_lords(EnhancedGameState.get_current_family())
			if not family_lords.is_empty():
				current_lord = family_lords[0].id
			
		if not current_lord.is_empty():
			view_one_window.show_lord_info(current_lord)

func _on_view_closed():
	var prompt_label = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/PromptSection/PromptLabel")
	var current_lord = EnhancedGameState.selected_lord_id
	if not current_lord.is_empty():
		var lord = EnhancedGameState.get_character(current_lord)
		if lord:
			prompt_label.text = "Lord %s, what is your command?" % lord.name
	else:
		prompt_label.text = "Select a lord..."

func _on_view_menu_closed():
	var view_menu = strategic_hud.get_node("ViewMenu")
	view_menu.hide()

func _on_end_turn_requested():
	var prompt_label = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/PromptSection/PromptLabel")
	prompt_label.text = "Plotting strategy..."
	_end_turn()

func _end_turn():
	# Trigger random events (20% chance)
	var event = RandomEventsEnhanced.try_trigger_random_event()
	if not event.is_empty():
		_show_event_notification(event)
	
	# Advance game turn
	EnhancedGameState.advance_turn_phase()

func _show_event_notification(event: Dictionary):
	var event_banner = strategic_hud.get_node("EventBanner")
	var icon_label = event_banner.get_node("Panel/HBoxContainer/IconLabel")
	var text_label = event_banner.get_node("Panel/HBoxContainer/TextLabel")
	
	icon_label.text = event.get("icon", "📢")
	text_label.text = event.get("message", "An event has occurred")
	
	event_banner.show()
	await get_tree().create_timer(5.0).timeout
	event_banner.hide()

func _on_turn_completed(month: int, year: int):
	print("Turn completed: Year ", year, " Month ", month)
	_update_year_month_display()

func _on_family_turn_started(family_id: String):
	print("Family turn started: ", family_id)
	_update_family_display()

func _on_lord_turn_started(lord_id: String):
	print("Lord turn started: ", lord_id)
	_update_lord_display(lord_id)

func _update_year_month_display():
	var month_names = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
					   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	var month = EnhancedGameState.current_month
	var year = EnhancedGameState.current_year
	var month_name = month_names[month] if month >= 1 and month <= 12 else "???"
	
	var year_month_label = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/TopSection/YearMonthLabel")
	year_month_label.text = "Year %d %s" % [year, month_name]

func _update_family_display():
	var current_family = EnhancedGameState.get_current_family()
	var family = EnhancedGameState.get_family(current_family)
	if not family:
		return
	
	var family_name_label = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/TopSection/FamilyNameLabel")
	var family_shield = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/TopSection/FamilyShield")
	var province_label = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/TopSection/ProvinceLabel")
	
	family_name_label.text = family.name
	family_shield.color = family.color
	
	# Count owned provinces
	var province_count = 0
	var capital_name = ""
	for province in EnhancedGameState.provinces.values():
		if province.owner_id == current_family:
			province_count += 1
			if capital_name == "" or province.is_capital:
				capital_name = province.name
	
	province_label.text = "%d:%s" % [province_count, capital_name]

func _update_lord_display(lord_id: String):
	var lord = EnhancedGameState.get_character(lord_id)
	if not lord:
		return
	
	var lord_name_label = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/LordSection/LordNameLabel")
	lord_name_label.text = lord.name
	
	_update_stats(lord)

func _update_stats(lord):
	var stat_grid = strategic_hud.get_node("MarginContainer/MainHBox/LeftPanel/VBoxContainer/StatsSection/StatGrid")
	
	# Clear existing stats
	for child in stat_grid.get_children():
		child.queue_free()
	
	# Add stat labels with icons
	var stats = [
		{"icon": "💰", "value": _get_lord_gold(lord)},
		{"icon": "🚩", "value": lord.command_rating if lord.get("command_rating") else 50},
		{"icon": "🍞", "value": _get_lord_food(lord)},
		{"icon": "⚔️", "value": lord.attack_rating if lord.get("attack_rating") else 50},
		{"icon": "🪖", "value": _get_lord_troops(lord)},
		{"icon": "🏰", "value": lord.defense_rating if lord.get("defense_rating") else 50}
	]
	
	for stat in stats:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 2)
		
		var icon_label = Label.new()
		icon_label.text = stat.icon
		icon_label.add_theme_font_size_override("font_size", 10)
		hbox.add_child(icon_label)
		
		var value_label = Label.new()
		value_label.text = str(stat.value)
		value_label.add_theme_color_override("font_color", Color.WHITE)
		value_label.add_theme_font_size_override("font_size", 12)
		hbox.add_child(value_label)
		
		stat_grid.add_child(hbox)

func _get_lord_gold(lord) -> int:
	var total = 0
	for province in EnhancedGameState.provinces.values():
		if province.owner_id == lord.family_id:
			total += province.gold
	return total

func _get_lord_food(lord) -> int:
	var total = 0
	for province in EnhancedGameState.provinces.values():
		if province.owner_id == lord.family_id:
			total += province.food
	return total

func _get_lord_troops(lord) -> int:
	var total = 0
	for province in EnhancedGameState.provinces.values():
		if province.owner_id == lord.family_id:
			total += province.soldiers
	return total
