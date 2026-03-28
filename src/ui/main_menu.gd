extends Control
## MainMenu - Entry point for the game
## New Game / Continue / Options / Quit

signal new_game_started
signal continue_game_requested

@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	# Connect button signals
	new_game_button.pressed.connect(_on_new_game)
	continue_button.pressed.connect(_on_continue)
	options_button.pressed.connect(_on_options)
	quit_button.pressed.connect(_on_quit)
	
	# Check for existing save
	_update_continue_button()
	
	# Focus new game by default
	new_game_button.grab_focus()

func _update_continue_button() -> void:
	## Enable/disable continue button based on save existence
	if SaveManager.has_save():
		continue_button.disabled = false
		continue_button.text = "Continue Game"
	else:
		continue_button.disabled = true
		continue_button.text = "No Save Data"

func _on_new_game() -> void:
	## Start new game - reset state and go to strategic map
	print("MainMenu: Starting new game...")
	
	# Reset game state
	_reset_game_state()
	
	# Initialize fresh game
	if GameState.has_method("initialize_provinces"):
		GameState.initialize_provinces()
	else:
		GameState.initialize_new_game()
	
	# Change to strategic map
	get_tree().change_scene_to_file("res://scenes/strategic_map.tscn")
	
	new_game_started.emit()

func _on_continue() -> void:
	## Load existing save
	if not SaveManager.has_save():
		return
	
	print("MainMenu: Loading saved game...")
	
	if SaveManager.load_game():
		# Change to strategic map with loaded state
		get_tree().change_scene_to_file("res://scenes/strategic_map.tscn")
		continue_game_requested.emit()
	else:
		push_error("MainMenu: Failed to load save game")
		_update_continue_button()

func _on_options() -> void:
	## Show options menu (placeholder)
	print("MainMenu: Options not yet implemented")
	# TODO: Implement options screen

func _on_quit() -> void:
	## Quit the game
	print("MainMenu: Quitting...")
	get_tree().quit()

func _reset_game_state() -> void:
	## Clear all game state for new game
	# Use new system if available
	if GameState.has_method("initialize_new_game"):
		GameState.initialize_new_game()
		return
	
	# Legacy fallback
	GameState.provinces.clear()
	GameState.factions.clear()
	GameState.characters.clear()
	GameState.current_phase = 0  # STRATEGIC
	GameState.current_province = "Dunmoor"
	GameState.player_faction_id = &"blanche"
