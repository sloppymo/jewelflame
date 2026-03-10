extends Node2D

# Strategic Map Controller
signal province_selected(province_id: int)
signal lord_selected(lord_id: String)
signal plotting_strategy_requested

var selected_province_id: int = -1
var selected_lord_id: String = ""

func _ready():
	# Add to strategic map group for TurnManager to find
	add_to_group("strategic_map")
	
	# Connect UI signals
	var end_turn_button = $UI_Layer/TopBar/EndTurnButton
	if end_turn_button:
		end_turn_button.pressed.connect(_on_plotting_strategy_pressed)
	
	# Connect to TurnManager signals
	TurnManager.turn_advanced.connect(_on_turn_advanced)
	TurnManager.phase_changed.connect(_on_phase_changed)
	
	# Connect to command system
	CommandHistory.CommandExecuted.connect(_on_command_executed)
	
	# Initialize UI
	update_turn_display()
	populate_lord_roster()
	setup_command_buttons()

func _on_plotting_strategy_pressed():
	print("Plotting Strategy button clicked")
	plotting_strategy_requested.emit()

func _on_turn_advanced(family_id: String):
	print("Turn advanced to: ", family_id)
	update_turn_display()
	populate_lord_roster()

func _on_phase_changed(phase_name: String):
	print("Phase changed to: ", phase_name)
	# Update UI to reflect current phase

func _on_command_executed(command: BaseCommand):
	print("Command executed: ", command.get_description())
	# Update UI to reflect command execution

func setup_command_buttons():
	# Add command buttons to the command panels
	var military_panel = $UI_Layer/LeftPanel/CommandCategories/MilitaryCommands
	var domestic_panel = $UI_Layer/LeftPanel/CommandCategories/DomesticCommands
	
	if military_panel:
		# Add attack button
		var attack_button = Button.new()
		attack_button.text = "Attack Province"
		attack_button.pressed.connect(_on_attack_pressed)
		military_panel.add_child(attack_button)
		
		# Add recruit button
		var recruit_button = Button.new()
		recruit_button.text = "Recruit Troops"
		recruit_button.pressed.connect(_on_recruit_pressed)
		military_panel.add_child(recruit_button)
	
	if domestic_panel:
		# Add develop button
		var develop_button = Button.new()
		develop_button.text = "Develop Land"
		develop_button.pressed.connect(_on_develop_pressed)
		domestic_panel.add_child(develop_button)

func _on_attack_pressed():
	if selected_province_id == -1:
		print("No province selected for attack")
		return
	
	var province = GameState.get_province(selected_province_id)
	if not province or province.owner_id != TurnManager.get_current_family():
		print("Cannot attack from this province")
		return
	
	# Find adjacent enemy provinces
	var targets = []
	for neighbor_id in province.neighbors:
		var neighbor = GameState.get_province(neighbor_id)
		if neighbor and neighbor.owner_id != province.owner_id:
			targets.append(neighbor)
	
	if targets.is_empty():
		print("No adjacent enemy provinces to attack")
		return
	
	# Attack the weakest target
	var target = targets[0]  # Simplified - just attack first target
	
	print("Attacking %s from %s" % [target.name, province.name])
	
	# Create attack command
	var attack_command = AttackProvinceCommand.new(
		province.id, 
		target.id, 
		province.stationed_units.duplicate(),
		province.stationed_lord_id
	)
	
	# Execute command
	CommandHistory.execute_command(attack_command)

func _on_recruit_pressed():
	if selected_province_id == -1:
		print("No province selected for recruitment")
		return
	
	var province = GameState.get_province(selected_province_id)
	if not province or province.owner_id != TurnManager.get_current_family():
		print("Cannot recruit in this province")
		return
	
	print("Recruiting troops in %s" % province.name)
	
	# Create recruit command
	var recruit_command = CommandFactory.create_recruit_command(selected_province_id, 50)
	
	# Execute command
	CommandHistory.execute_command(recruit_command)

func _on_develop_pressed():
	if selected_province_id == -1:
		print("No province selected for development")
		return
	
	var province = GameState.get_province(selected_province_id)
	if not province or province.owner_id != TurnManager.get_current_family():
		print("Cannot develop this province")
		return
	
	print("Developing land in %s" % province.name)
	
	# Create develop command (cultivation by default)
	var develop_command = CommandFactory.create_develop_command(selected_province_id, "cultivation")
	
	# Execute command
	CommandHistory.execute_command(develop_command)

func update_turn_display():
	var turn_label = $UI_Layer/TopBar/TurnIndicator
	var date_label = $UI_Layer/TopBar/DateDisplay
	
	if turn_label:
		var current_family = TurnManager.get_current_family()
		var current_phase = TurnManager.get_current_phase()
		turn_label.text = "%s Turn - %s - Month %d, Year %d" % [
			current_family.capitalize(),
			current_phase,
			GameState.current_month,
			GameState.current_year
		]
	
	if date_label:
		var season = get_season_name(GameState.current_month)
		date_label.text = "%s, Year %d" % [season, GameState.current_year]

func get_season_name(month: int) -> String:
	match month:
		1, 2, 3: return "Spring"
		4, 5, 6: return "Summer"
		7, 8, 9: return "Autumn"
		10, 11, 12: return "Winter"
		_: return "Unknown"

func populate_lord_roster():
	var lord_list = $UI_Layer/LeftPanel/LordRoster/LordList
	if not lord_list:
		return
	
	# Clear existing lords
	for child in lord_list.get_children():
		child.queue_free()
	
	# Add current family's lords
	var current_family = TurnManager.get_current_family()
	for character in GameState.characters.values():
		if character.family_id == current_family and character.is_lord:
			var lord_button = Button.new()
			lord_button.text = "%s (Age: %d, Loyalty: %d)" % [
				character.name,
				character.age if character.has_method("get") else 25,
				character.loyalty if character.has_method("get") else 100
			]
			lord_button.pressed.connect(_on_lord_clicked.bind(character.id))
			lord_list.add_child(lord_button)

func _on_lord_clicked(lord_id: String):
	print("Lord selected: ", lord_id)
	selected_lord_id = lord_id
	lord_selected.emit(lord_id)

func show_province_info(province_id: int):
	selected_province_id = province_id
	var province = GameState.get_province(province_id)
	if not province:
		return
	
	var info_panel = $UI_Layer/RightPanel/ProvinceInfo
	# Update province info display
	print("Showing info for province: ", province.name)
	
	# Update UI with province details
	# This would update the actual UI panel with province information
