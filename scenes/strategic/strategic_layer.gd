extends Node2D

const ProvinceData = preload("res://resources/data_classes/province_data.gd")
const FactionData = preload("res://resources/data_classes/faction_data.gd")

@onready var province_manager
@onready var turn_indicator: Label
@onready var sidebar: Control

func _ready():
	print("=== STRATEGIC LAYER INITIALIZING ===")
	
	# Get references
	province_manager = get_node_or_null("CanvasLayer/MapContainer/ProvinceManager")
	turn_indicator = get_node_or_null("CanvasLayer/TurnIndicator")
	sidebar = get_node_or_null("CanvasLayer/GameSidebar")
	
	# Connect signals deferred
	call_deferred("_connect_signals")
	
	# Set initial turn indicator
	_update_turn_indicator("Turn 1 - Your Turn")
	
	print("=== STRATEGIC LAYER READY ===")

func _connect_signals():
	var tm = get_node_or_null("/root/TurnManager")
	var cr = get_node_or_null("/root/CombatResolver")
	var em = get_node_or_null("/root/EventManager")
	
	# Connect to TurnManager signals
	if tm:
		tm.turn_ended.connect(_on_turn_ended)
		tm.player_turn_started.connect(_on_player_turn_started)
		tm.ai_turn_started.connect(_on_ai_turn_started)
		tm.ai_turn_ended.connect(_on_ai_turn_ended)
		tm.state_changed.connect(_on_state_changed)
		
		# Start the game
		tm.start_game()
	
	# Connect to CombatResolver
	if cr:
		cr.battle_resolved.connect(_on_battle_resolved)
		cr.battle_started.connect(_on_battle_started)
	
	# Connect to EventManager
	if em:
		em.event_triggered.connect(_on_event_triggered)

func _on_turn_ended(turn_number: int):
	_update_turn_indicator("Turn %d - Processing..." % turn_number)

func _on_player_turn_started():
	var tm = get_node_or_null("/root/TurnManager")
	if tm:
		_update_turn_indicator("Turn %d - Your Turn" % tm.turn_number)
		
		# Show welcome message on first turn
		if sidebar and tm.turn_number == 1:
			sidebar.show_event_message("Welcome to Jewelflame! Select a province to begin.")
	
	# Show welcome message on first turn
	if sidebar:
		var tm2 = get_node_or_null("/root/TurnManager")
		if tm2 and tm2.turn_number == 1:
			sidebar.show_event_message("Welcome to Jewelflame! Select a province to begin.")

func _on_ai_turn_started(faction_id: StringName):
	var gs = get_node_or_null("/root/GameState")
	var tm = get_node_or_null("/root/TurnManager")
	
	if gs and gs.factions.has(faction_id) and tm:
		var faction: FactionData = gs.factions[faction_id]
		_update_turn_indicator("Turn %d - %s thinking..." % [tm.turn_number, faction.faction_name])

func _on_ai_turn_ended(faction_id: StringName):
	pass

func _on_state_changed(new_state, _old_state):
	# GAME_OVER = 5
	if new_state == 5:
		_show_game_over()

func _on_battle_started(attacker: StringName, defender: StringName, location: StringName):
	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		return
	
	var attacker_name: String = gs.factions[attacker].faction_name if gs.factions.has(attacker) else "Unknown"
	var location_name: String = gs.provinces[location].province_name if gs.provinces.has(location) else "Unknown"
	print("Battle started: %s attacking %s" % [attacker_name, location_name])

func _on_battle_resolved(result):
	# Refresh province display
	if province_manager:
		province_manager.draw_connections()
	
	var gs = get_node_or_null("/root/GameState")
	if gs == null or sidebar == null:
		return
	
	# Show result in sidebar
	var target_name: String = gs.provinces[result.target_province_id].province_name if gs.provinces.has(result.target_province_id) else "Unknown"
	if result.attacker_won:
		sidebar.show_event_message("Victory! %s conquered!" % target_name)
	else:
		sidebar.show_event_message("Defeat at %s!" % target_name)

func _on_event_triggered(event_id: StringName, faction_id: StringName, message: String):
	print("Event triggered: %s for %s" % [event_id, faction_id])
	
	var gs = get_node_or_null("/root/GameState")
	if sidebar and gs and faction_id == gs.player_faction_id:
		sidebar.show_event_message(message)

func _update_turn_indicator(text: String):
	if turn_indicator:
		turn_indicator.text = text

func _show_game_over():
	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		return
	
	# Check who won
	var winner_id := &""
	for fid in gs.factions:
		var faction: FactionData = gs.factions[fid]
		if faction.owned_province_ids.size() >= gs.provinces.size():
			winner_id = fid
			break
	
	if winner_id == gs.player_faction_id:
		_update_turn_indicator("VICTORY! You have conquered all provinces!")
		if sidebar:
			sidebar.show_event_message("VICTORY! You have conquered all provinces and unified the realm!")
	else:
		_update_turn_indicator("DEFEAT! Your house has fallen!")
		if sidebar:
			sidebar.show_event_message("DEFEAT! Your house has been eradicated from history.")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			var tm = get_node_or_null("/root/TurnManager")
			if tm and tm.is_player_turn():
				tm.end_player_turn()
