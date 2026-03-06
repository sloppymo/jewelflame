extends Panel

@onready var month_label: Label = $VBox/MonthLabel
@onready var family_label: Label = $VBox/FamilyLabel
@onready var end_turn_button: Button = $VBox/EndTurnButton

var victory_dialog: AcceptDialog
var defeat_dialog: AcceptDialog

func _ready():
	EventBus.TurnEnded.connect(_on_turn_ended)
	EventBus.GameLoaded.connect(_on_game_loaded)
	EventBus.HarvestReportReady.connect(_on_harvest_report_ready)
	
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	update_display()

func _on_turn_ended(month: int, year: int):
	update_display()
	
	# Check if it's AI turn and handle automatically
	var current_family = GameState.get_current_family()
	if current_family != GameState.player_family_id:
		end_turn_button.disabled = true
		_handle_ai_turn()
	else:
		end_turn_button.disabled = false

func _on_game_loaded(slot: int):
	update_display()

func _on_harvest_report_ready(province_yields: Dictionary):
	# Show harvest report dialog
	var harvest_report = get_tree().get_first_node_in_group("harvest_report")
	if harvest_report:
		harvest_report.show_harvest_report(province_yields)

func update_display():
	var month_names = ["January", "February", "March", "April", "May", "June",
					 "July", "August", "September", "October", "November", "December"]
	
	month_label.text = "%s, Year %d" % [
		month_names[GameState.current_month - 1],
		GameState.current_year
	]
	
	var current_family = GameState.get_current_family()
	var family = GameState.families[current_family]
	family_label.text = "Current Turn: %s" % family.name
	
	# Enable/disable end turn button based on whose turn it is
	end_turn_button.disabled = (current_family != GameState.player_family_id)

func _on_end_turn_pressed():
	if GameState.get_current_family() == GameState.player_family_id:
		# Use call_deferred to avoid stack overflow
		call_deferred("_advance_turn_safe")

func _advance_turn_safe():
	GameState.advance_turn()

func _handle_ai_turn():
	var current_family = GameState.get_current_family()
	var family = GameState.families[current_family]
	
	print("Starting AI turn for: ", family.name)
	
	# Execute AI turn with delay
	AIController.take_turn(current_family)

func show_victory_dialog(winner_name: String):
	if not victory_dialog:
		victory_dialog = AcceptDialog.new()
		victory_dialog.dialog_text = "Victory!\n\n%s has conquered all provinces!" % winner_name
		victory_dialog.title = "Victory Achieved"
		victory_dialog.exclusive = true
		
		add_child(victory_dialog)
		victory_dialog.popup_centered()
		
		# Add restart button
		var restart_button = Button.new()
		restart_button.text = "New Game"
		restart_button.pressed.connect(_on_restart_game)
		victory_dialog.add_button(restart_button)

func show_defeat_dialog():
	if not defeat_dialog:
		defeat_dialog = AcceptDialog.new()
		defeat_dialog.dialog_text = "Defeat!\n\nYour family has been eliminated from the realm."
		defeat_dialog.title = "Defeat"
		defeat_dialog.exclusive = true
		
		add_child(defeat_dialog)
		defeat_dialog.popup_centered()
		
		# Add restart button
		var restart_button = Button.new()
		restart_button.text = "New Game"
		restart_button.pressed.connect(_on_restart_game)
		defeat_dialog.add_button(restart_button)

func _on_restart_game():
	# Reset game state
	GameState.current_family_index = 0
	GameState.current_month = 1
	GameState.current_year = 1
	
	# Reset province ownership to initial state
	GameState.load_initial_data()
	
	# Close dialogs
	if victory_dialog:
		victory_dialog.queue_free()
		victory_dialog = null
	if defeat_dialog:
		defeat_dialog.queue_free()
		defeat_dialog = null
	
	# Update display
	update_display()
