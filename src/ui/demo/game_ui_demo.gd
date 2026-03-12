extends Node2D
class_name GameUIDemo

# Demo script for testing the Jewelflame UI system
# Attach this to the root of game_ui.tscn or run this scene directly

@onready var ui: GameUI = $GameUI

func _ready():
	print("=== Jewelflame UI Demo ===")
	print("Click buttons to test functionality!")
	
	# Set up initial character
	ui.update_character({
		"name": "Lord Karl",
		"title": "Knight of Cobrige",
		"level": 5,
		"portrait": null  # Add a Texture2D here if you have one
	})
	
	# Set up resources
	ui.update_resources({
		"gold": 497,
		"food": 391,
		"troops": 0,
		"wood": 0,
		"holdings": 45,
		"influence": 12
	})
	
	# Show welcome message
	ui.message_panel.show_message("Lord Karl, what is your command?")
	
	# Connect to action signals for demo feedback
	ui.sidebar.action_pressed.connect(_on_demo_action)
	ui.message_panel.choice_selected.connect(_on_demo_choice)
	ui.event_modal.dismissed.connect(_on_demo_modal_closed)

func _on_demo_action(action_type: String) -> void:
	print("Action pressed: " + action_type)
	
	match action_type:
		"attack":
			ui.message_panel.show_message_with_choices(
				"Attack which province?",
				["12 - Dunmoor", "15 - Carveti", "22 - Banshea", "Cancel"]
			)
		"defend":
			ui.message_panel.show_message("Fortifying current position...")
		"recruit":
			ui.update_resources({"troops": ui.sidebar.troops + 50})
			ui.message_panel.show_feedback("troop_gain", 50)
		"scout":
			ui.message_panel.show_message("Scouting reports: Enemy spotted at Dunmoor!")
		"build":
			ui.message_panel.show_message_with_choices(
				"What would you like to build?",
				["Castle", "Farm", "Market", "Barracks"]
			)
		"trade":
			ui.update_resources({"gold": ui.sidebar.gold + 100})
			ui.message_panel.show_feedback("gold_earned", 100)
		"tax":
			ui.update_resources({"gold": ui.sidebar.gold + 200})
			ui.message_panel.show_feedback("gold_earned", 200)
		"develop":
			ui.message_panel.show_message("Select a province to develop.")
		"negotiate":
			_show_negotiate_demo()
		"ally":
			_show_alliance_demo()
		"threaten":
			ui.message_panel.show_message("Threaten which faction?")
		"bribe":
			ui.update_resources({"gold": ui.sidebar.gold - 50})
			ui.message_panel.show_message("Bribe sent. Gold -50")
		"save":
			ui.message_panel.show_message("Game saved successfully!")
		"load":
			ui.message_panel.show_message("Load game feature coming soon.")
		"settings":
			ui.message_panel.show_message("Settings: Sound, Graphics, Controls")
		"end_turn":
			_show_season_change_demo()

func _on_demo_choice(choice: String) -> void:
	print("Choice selected: " + choice)
	
	if choice == "Cancel":
		ui.message_panel.show_message("Action cancelled.")
	elif "Dunmoor" in choice or "Carveti" in choice or "Banshea" in choice:
		_show_victory_demo()
	elif "Castle" in choice:
		ui.update_resources({"holdings": ui.sidebar.holdings + 1})
		ui.message_panel.show_message("Castle construction started!")
	elif "Farm" in choice or "Market" in choice or "Barracks" in choice:
		ui.message_panel.show_message(choice + " construction started!")
	elif "House" in choice:
		_show_alliance_demo()

func _show_victory_demo() -> void:
	ui.show_combat_result(true, {
		"battle_name": "Battle of Dunmoor",
		"enemy_losses": 200,
		"player_losses": 50,
		"loyalty_boost": 15
	})

func _show_alliance_demo() -> void:
	ui.show_alliance_formed({
		"faction_name": "House Blanche",
		"terms": "Mutual defense and trade",
		"duration": 10,
		"trade_bonus": 15
	})

func _show_negotiate_demo() -> void:
	ui.message_panel.show_message_with_choices(
		"Negotiate with whom?",
		["House Blanche", "House Garth", "Independents", "Cancel"]
	)

func _show_season_change_demo() -> void:
	ui.message_panel.show_message("Ending turn...")
	
	# Simulate turn end
	await get_tree().create_timer(1.5).timeout
	
	ui.show_season_change(1, "winter", "Snow blankets the realm. Armies huddle in their castles.")

func _on_demo_modal_closed() -> void:
	print("Modal closed, game resumed")
	ui.message_panel.show_message("Lord Karl, what is your command?")

func _input(event: InputEvent) -> void:
	# Demo shortcuts
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_show_victory_demo()
			KEY_2:
				_show_alliance_demo()
			KEY_3:
				_show_season_change_demo()
			KEY_0:
				ui.message_panel.show_message("Lord Karl, what is your command?")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("Demo closed")
