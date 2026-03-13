extends Node

# StrategicUIController - Connects the sidebar UI to the strategic map
# Handles province selection, action routing, and UI updates

@onready var game_sidebar = get_node_or_null("../CanvasLayer/GameSidebar")
@onready var message_panel = get_node_or_null("../CanvasLayer/MessagePanel")
@onready var strategic_map = get_node_or_null("../CanvasLayer/MapContainer/StrategicMap")

var selected_province_id: int = -1

func _ready():
	print("StrategicUIController ready")
	
	# Wait a frame for nodes to be ready
	await get_tree().process_frame
	
	# Get node references
	game_sidebar = get_node_or_null("../CanvasLayer/GameSidebar")
	message_panel = get_node_or_null("../CanvasLayer/MessagePanel")
	strategic_map = get_node_or_null("../CanvasLayer/MapContainer/StrategicMap")
	
	# Connect sidebar signals
	if game_sidebar:
		game_sidebar.action_pressed.connect(_on_action_pressed)
		game_sidebar.end_turn_requested.connect(_on_end_turn_requested)
		game_sidebar.save_requested.connect(_on_save_requested)
		game_sidebar.tab_changed.connect(_on_tab_changed)
	else:
		push_warning("GameSidebar not found!")
	
	# Connect to EventBus
	if has_node("/root/EventBus"):
		EventBus.ProvinceSelected.connect(_on_province_selected)
	
	# Initial message
	if message_panel:
		message_panel.show_message("Welcome to Jewelflame. Select a province to begin.")
	
	# Set initial province
	_on_province_selected(1)

func _on_province_selected(province_id: int):
	selected_province_id = province_id
	
	if not GameState.provinces.has(province_id):
		return
	
	var province = GameState.provinces[province_id]
	
	# Update sidebar through the sidebar's own update method
	if game_sidebar:
		game_sidebar._update_for_province(province_id)
	
	# Show message
	if message_panel:
		message_panel.show_message("Selected province %d: %s" % [province_id, province.name])
	
	print("Province selected: ", province_id, " - ", province.name)

func _on_action_pressed(action: String):
	match action:
		"attack":
			_handle_attack()
		"defend":
			_handle_defend()
		"recruit":
			_handle_recruit()
		"scout":
			_handle_scout()
		"develop":
			_handle_develop()
		"trade":
			_handle_trade()
		"tax":
			_handle_tax()
		"build":
			_handle_build()
		_:
			print("Unknown action: ", action)
			if message_panel:
				message_panel.show_message("Action '%s' not yet implemented." % action)

func _handle_attack():
	if selected_province_id == -1:
		if message_panel:
			message_panel.show_message("No province selected!")
		return
	
	var province = GameState.provinces[selected_province_id]
	
	# Find adjacent enemy provinces
	var targets = []
	if province.get("neighbors"):
		for neighbor_id in province.neighbors:
			if GameState.provinces.has(neighbor_id):
				var neighbor = GameState.provinces[neighbor_id]
				if neighbor.owner_id != province.owner_id:
					targets.append(neighbor)
	
	if targets.is_empty():
		if message_panel:
			message_panel.show_message("No adjacent enemy provinces to attack!")
		return
	
	var target = targets[0]  # Simplified: attack first target
	
	if message_panel:
		message_panel.show_message("Attacking %s from %s..." % [target.name, province.name])
	
	# Start battle
	_start_battle(selected_province_id, target.id)

func _handle_defend():
	if message_panel:
		message_panel.show_message("Defensive stance prepared.")

func _handle_recruit():
	if selected_province_id == -1:
		return
	
	var province = GameState.provinces[selected_province_id]
	
	# Simple recruitment logic
	var cost_per_soldier = 10
	var max_recruit = min(50, province.gold / cost_per_soldier)
	
	if max_recruit > 0:
		province.soldiers += max_recruit
		province.gold -= max_recruit * cost_per_soldier
		
		if message_panel:
			message_panel.show_message("Recruited %d soldiers in %s." % [max_recruit, province.name])
		
		# Update sidebar
		if game_sidebar:
			game_sidebar.update_resources({
				"gold": province.gold,
				"troops": province.soldiers
			})
	else:
		if message_panel:
			message_panel.show_message("Not enough gold to recruit soldiers!")

func _handle_scout():
	if message_panel:
		message_panel.show_message("Scouting reports will appear here.")

func _handle_develop():
	if selected_province_id == -1:
		return
	
	var province = GameState.provinces[selected_province_id]
	
	if province.gold >= 100:
		province.gold -= 100
		if not province.get("development"):
			province.development = 0
		province.development += 1
		
		if message_panel:
			message_panel.show_message("Development increased in %s!" % province.name)
		
		if game_sidebar:
			game_sidebar.update_resources({"gold": province.gold})
	else:
		if message_panel:
			message_panel.show_message("Need 100 gold to develop!")

func _handle_trade():
	if message_panel:
		message_panel.show_message("Trade routes are being established...")

func _handle_tax():
	if selected_province_id == -1:
		return
	
	var province = GameState.provinces[selected_province_id]
	var tax_income = province.soldiers * 2  # Simplified
	province.gold += tax_income
	
	if message_panel:
		message_panel.show_message("Collected %d gold in taxes from %s." % [tax_income, province.name])
	
	if game_sidebar:
		game_sidebar.update_resources({"gold": province.gold})

func _handle_build():
	if message_panel:
		message_panel.show_message("Construction menu not yet available.")

func _start_battle(attacker_id: int, defender_id: int):
	"""Initiate battle between two provinces."""
	print("Starting battle: ", attacker_id, " vs ", defender_id)
	
	# Set up battle data in GameState
	var battle_data = GameState.start_battle(attacker_id, defender_id)
	
	if battle_data.is_empty():
		push_error("Failed to start battle")
		return
	
	# Request tactical battle
	EventBus.RequestTacticalBattle.emit(battle_data)

func _on_end_turn_requested():
	print("End turn requested")
	
	if message_panel:
		message_panel.show_message("Ending turn...")
	
	# Advance turn in GameState
	GameState.advance_turn()
	
	# Emit turn ended signal
	var current_family = GameState.get_current_family()
	EventBus.TurnEnded.emit(GameState.current_month, GameState.current_year)
	EventBus.FamilyTurnStarted.emit(current_family)
	
	if message_panel:
		message_panel.show_message("Turn ended. Now %s's turn." % current_family.capitalize())

func _on_save_requested():
	print("Save requested")
	
	if SaveManager:
		SaveManager.save_game(1)
		if message_panel:
			message_panel.show_message("Game saved to slot 1.")

func _on_tab_changed(tab_name: String):
	print("Tab changed to: ", tab_name)
	
	if message_panel:
		match tab_name:
			"military":
				message_panel.show_message("Military commands available: Attack, Defend, Recruit, Scout")
			"economy":
				message_panel.show_message("Economy commands: Develop, Trade, Tax, Build")
			"diplomacy":
				message_panel.show_message("Diplomacy commands: Alliance, Bribe, Threaten, Gift")
			"system":
				message_panel.show_message("System menu: Stats, Options, Help, Quit")

func _on_tactical_battle_completed(result: Dictionary):
	"""Handle battle completion."""
	print("Battle completed: ", result)
	
	var victor = result.get("victor", "")
	var attacker_province_id = GameState.current_battle.get("attacker", {}).get("province_id", -1)
	var defender_province_id = GameState.current_battle.get("defender", {}).get("province_id", -1)
	
	# Process battle results
	GameState.end_battle(result)
	
	# Show result message
	if message_panel:
		if victor == "attacker":
			var attacker_province = GameState.provinces.get(attacker_province_id)
			var defender_province = GameState.provinces.get(defender_province_id)
			if attacker_province and defender_province:
				message_panel.show_message("Victory! %s has conquered %s!" % [attacker_province.name, defender_province.name])
		else:
			message_panel.show_message("Defeat! The attack was repelled.")
	
	# Refresh the map
	if strategic_map and strategic_map.has_method("render_all_provinces"):
		strategic_map.render_all_provinces()
	
	# Update sidebar
	if game_sidebar and selected_province_id != -1:
		game_sidebar._update_for_province(selected_province_id)
