extends Node

enum State {
	EVENT_PHASE,
	PLAYER_TURN,
	AI_TURN,
	COMBAT_RESOLUTION,
	TURN_END,
	GAME_OVER
}

signal state_changed(new_state: State, old_state: State)
signal player_turn_started
signal ai_turn_started(faction_id: StringName)
signal ai_turn_ended(faction_id: StringName)
signal turn_ended(turn_number: int)
signal income_collected(faction_id: StringName, amount: int)
signal victory_achieved(faction_id: StringName)

var current_state: State = State.PLAYER_TURN
var current_faction_index: int = 0
var turn_number: int = 1
var faction_order: Array[StringName] = [&"blanche", &"coryll", &"lyle"]
var is_processing_ai: bool = false

func _ready():
	# Validate state on ready
	if GameState == null:
		push_error("TurnManager: GameState autoload missing")

func is_player_turn() -> bool:
	return current_state == State.PLAYER_TURN

func is_action_allowed() -> bool:
	# Strict validation: only player can act during PLAYER_TURN
	return current_state == State.PLAYER_TURN and not is_processing_ai

func change_state(new_state: State):
	if new_state == current_state:
		return
	
	var old_state := current_state
	current_state = new_state
	state_changed.emit(new_state, old_state)
	
	match new_state:
		State.EVENT_PHASE:
			_process_event_phase()
		State.PLAYER_TURN:
			_start_player_turn()
		State.AI_TURN:
			_start_ai_turn()
		State.TURN_END:
			_process_turn_end()

func _process_event_phase():
	# 30% chance of random event for player
	if randf() < 0.3:
		var em = get_node_or_null("/root/EventManager")
		if em:
			em.trigger_random_event(&"blanche")
	
	change_state(State.PLAYER_TURN)

func _start_player_turn():
	player_turn_started.emit()
	# Enable UI input
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.set_input_enabled(true)

func end_player_turn():
	if not is_player_turn():
		push_warning("Attempted to end turn when not player turn")
		return
	
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.set_input_enabled(false)
	change_state(State.AI_TURN)

func _start_ai_turn():
	is_processing_ai = true
	
	# Process each AI faction
	for i in range(faction_order.size()):
		var faction_id := faction_order[i]
		if faction_id == &"blanche":
			continue  # Skip player
		
		ai_turn_started.emit(faction_id)
		
		# AI processing with safety timeout
		await _process_ai_turn(faction_id)
		
		ai_turn_ended.emit(faction_id)
		await get_tree().create_timer(0.3).timeout  # Visual pacing
	
	is_processing_ai = false
	change_state(State.TURN_END)

func _process_ai_turn(faction_id: StringName):
	var ai = get_node_or_null("/root/AIManager")
	if ai == null:
		push_error("AIManager not found")
		return
	
	await ai.take_turn(faction_id)

func _process_turn_end():
	# Collect income
	var gs = get_node_or_null("/root/GameState")
	if gs:
		for faction_id in gs.factions:
			var faction = gs.factions[faction_id]
			var income: int = faction.get_income(gs.provinces)
			faction.gold += income
			income_collected.emit(faction_id, income)
	
	turn_number += 1
	turn_ended.emit(turn_number)
	
	# Check win condition
	if _check_victory():
		change_state(State.GAME_OVER)
		return
	
	change_state(State.EVENT_PHASE)

func _check_victory() -> bool:
	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		return false
		
	for faction_id in gs.factions:
		var faction = gs.factions[faction_id]
		if faction.owned_province_ids.size() >= gs.provinces.size():
			victory_achieved.emit(faction_id)
			return true
	return false

func get_current_faction_id() -> StringName:
	if faction_order.is_empty():
		return &""
	return faction_order[current_faction_index]

func start_game():
	turn_number = 1
	current_faction_index = 0
	# Skip event phase on first turn for better UX
	change_state(State.PLAYER_TURN)
