extends Control

enum ActionMode {
	NORMAL,
	SELECT_SOURCE,
	SELECT_TARGET
}

signal action_started(action_name: String)
signal action_completed(action_name: String, success: bool)
signal end_turn_requested()

const TurnManager = preload("res://autoload/turn_manager.gd")
const FactionData = preload("res://resources/data_classes/faction_data.gd")
const ProvinceData = preload("res://resources/data_classes/province_data.gd")
const CharacterData = preload("res://resources/data_classes/character_data.gd")
const GameConfig = preload("res://autoload/game_config.gd")

# ============================================================================
# NODES
# ============================================================================
@onready var province_name: Label = %ProvinceName
@onready var ruler_name: Label = %RulerName
@onready var portrait: Control = %Portrait  # Will cast to TextureRect or custom portrait control

@onready var defense_value: Label = %DefenseValue
@onready var income_value: Label = %IncomeValue
@onready var garrison_value: Label = %GarrisonValue
@onready var loyalty_value: Label = %LoyaltyValue

@onready var attack_btn: Button = %AttackBtn
@onready var defend_btn: Button = %DefendBtn
@onready var recruit_btn: Button = %RecruitBtn
@onready var scout_btn: Button = %ScoutBtn
@onready var end_turn_btn: Button = %EndTurnBtn
@onready var undo_btn: Button = %UndoBtn
@onready var redo_btn: Button = %RedoBtn
@onready var captured_btn: Button = %CapturedBtn

@onready var event_message_label: Label = %EventMessageLabel

# ============================================================================
# STATE
# ============================================================================
var current_mode: ActionMode = ActionMode.NORMAL
var selected_source: ProvinceData = null
var selected_target: ProvinceData = null
var current_action: String = ""
var _typing_tween: Tween = null

# ============================================================================
# INITIALIZATION
# ============================================================================
func _ready():
	print("=== SIDEBAR INITIALIZING ===")
	
	# Get autoloads
	var tm = get_node_or_null("/root/TurnManager")
	var gs = get_node_or_null("/root/GameState")
	
	# Safety checks
	if tm == null or gs == null:
		push_error("Sidebar: Required autoloads not found")
		return
	
	# Connect signals (button connections are already in .tscn file)
	_connect_signals()
	
	# Initialize with first province if available
	if gs.provinces.size() > 0:
		var keys: Array = gs.provinces.keys()
		var first_id: StringName = keys[0]
		_update_for_province(gs.provinces[first_id])
	
	_update_ui()
	print("=== SIDEBAR READY ===")

func _connect_signals():
	var tm = get_node_or_null("/root/TurnManager")
	var gs = get_node_or_null("/root/GameState")
	var cp = get_node_or_null("/root/CommandProcessor")
	
	if tm:
		tm.player_turn_started.connect(_on_player_turn_started)
		tm.state_changed.connect(_on_state_changed)
		tm.turn_ended.connect(_on_turn_ended)
	
	if gs:
		gs.province_selected.connect(_on_province_selected)
	
	# Connect to CommandProcessor for command execution feedback
	if cp:
		cp.command_executed.connect(_on_command_executed)
		cp.command_failed.connect(_on_command_failed)
		cp.history_changed.connect(_on_history_changed)
	
	# Connect to EventBus for battle results
	EventBus.BattleResolved.connect(_on_battle_resolved)
	
	# Connect to LordManager for capture events
	var lm = get_node_or_null("/root/LordManager")
	if lm:
		lm.lord_captured.connect(_on_lord_captured)
		lm.lord_recruited.connect(_on_lord_recruited)

# ============================================================================
# STATE HANDLERS
# ============================================================================
func _on_state_changed(new_state, _old_state):
	# Use proper enum comparisons for type safety
	match new_state:
		TurnManager.State.PLAYER_TURN:
			_set_buttons_enabled(true)
		TurnManager.State.AI_TURN:
			_set_buttons_enabled(false)
			reset_mode()
		TurnManager.State.GAME_OVER:
			_set_buttons_enabled(false)
			show_event_message("Game Over!")

func _set_buttons_enabled(enabled: bool):
	if attack_btn:
		attack_btn.disabled = not enabled
	if defend_btn:
		defend_btn.disabled = not enabled
	if recruit_btn:
		recruit_btn.disabled = not enabled
	if scout_btn:
		scout_btn.disabled = not enabled
	if end_turn_btn:
		end_turn_btn.disabled = not enabled
	# Undo/Redo buttons update separately based on command history
	_update_undo_redo_buttons()

func _on_player_turn_started():
	reset_mode()
	_update_ui()

func _on_turn_ended(_turn_number: int):
	# Clear command history at end of turn
	var cp = get_node_or_null("/root/CommandProcessor")
	if cp:
		cp.clear_history()
	_update_undo_redo_buttons()

# ============================================================================
# PROVINCE SELECTION
# ============================================================================
func _on_province_selected(data: ProvinceData):
	if data == null:
		return
	
	_update_for_province(data)
	
	match current_mode:
		ActionMode.NORMAL:
			pass  # Just display info
		
		ActionMode.SELECT_SOURCE:
			if _can_be_source(data):
				selected_source = data
				current_mode = ActionMode.SELECT_TARGET
				_highlight_valid_targets(data)
				show_event_message("Select target province for %s" % current_action)
			else:
				_show_error("Cannot use %s as source (must own this province)" % data.province_name)
				reset_mode()
		
		ActionMode.SELECT_TARGET:
			if _can_be_target(data, selected_source):
				selected_target = data
				_execute_action()
			else:
				_show_error("Invalid target: %s" % data.province_name)
				reset_mode()

func _update_for_province(data: ProvinceData):
	if not data:
		return
	
	# Update province name
	if province_name:
		province_name.text = data.province_name
	
	# Update governor/noble info
	_update_governor_display(data)
	
	# Update stats
	_update_stats_display(data)

func _update_governor_display(province: ProvinceData):
	if ruler_name == null:
		return
	
	var lm = get_node_or_null("/root/LordManager")
	var gs = get_node_or_null("/root/GameState")
	
	if lm == null or gs == null:
		ruler_name.text = "No Governor"
		ruler_name.add_theme_color_override("font_color", Color.GRAY)
		return
	
	# Get the governor
	var governor: CharacterData = null
	if province.has_governor():
		governor = lm.get_character(province.governor_id)
	
	if governor != null:
		# Show governor name
		ruler_name.text = governor.name
		
		# Color by faction
		if gs.factions.has(governor.family_id):
			var faction: FactionData = gs.factions[governor.family_id]
			ruler_name.add_theme_color_override("font_color", faction.color)
		else:
			ruler_name.add_theme_color_override("font_color", Color.WHITE)
		
		# Update portrait if available
		_update_portrait(governor.portrait_path)
	else:
		# No governor - show faction name or "No Governor"
		if province.has_owner():
			if gs.factions.has(province.owner_faction_id):
				var faction: FactionData = gs.factions[province.owner_faction_id]
				ruler_name.text = faction.faction_name
				ruler_name.add_theme_color_override("font_color", faction.color)
			else:
				ruler_name.text = "Unknown"
				ruler_name.add_theme_color_override("font_color", Color.GRAY)
		else:
			ruler_name.text = "Unclaimed"
			ruler_name.add_theme_color_override("font_color", Color.GRAY)
		
		_update_portrait("")  # Clear portrait

func _update_portrait(portrait_path: String):
	# This would update the portrait texture
	# The portrait node is a custom control that handles its own drawing
	# For now, we emit a signal or call a method on it if available
	if portrait != null and portrait.has_method("set_portrait"):
		portrait.set_portrait(portrait_path)

func _update_stats_display(province: ProvinceData):
	if not province:
		return
	
	# Defense - now shows percentage bonus
	if defense_value:
		var defense_bonus = province.get_defense_bonus()
		var bonus_percent = int((defense_bonus - 1.0) * 100)
		defense_value.text = "Level %d (+%d%%)" % [province.defense_level, bonus_percent]
	
	# Income
	if income_value:
		income_value.text = str(province.get_income())
	
	# Garrison (troops)
	if garrison_value:
		garrison_value.text = str(province.troops)
	
	# Loyalty (placeholder - would come from province data)
	if loyalty_value:
		loyalty_value.text = "100%"

# ============================================================================
# ACTION VALIDATION
# ============================================================================
func _can_be_source(data: ProvinceData) -> bool:
	if data == null:
		return false
	
	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	
	var current_faction = gs.get_current_faction()
	if current_faction == null:
		return false
	
	return current_faction.owns_province(data.id)

func _can_be_target(data: ProvinceData, source: ProvinceData) -> bool:
	if data == null or source == null:
		return false
	
	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	
	var current_faction = gs.get_current_faction()
	if current_faction == null:
		return false
	
	# Must be adjacent
	if not source.is_adjacent_to(data.id):
		return false
	
	match current_action:
		"move":
			# Must own target and not be same as source
			return data.id != source.id and current_faction.owns_province(data.id)
		"attack":
			# Must NOT own target
			return data.id != source.id and not current_faction.owns_province(data.id)
		"scout":
			# Can scout any adjacent
			return data.id != source.id
		_:
			return false

func _highlight_valid_targets(source: ProvinceData):
	# TODO: Emit signal or call into ProvinceManager to highlight valid targets
	pass

func _clear_highlights():
	# TODO: Clear all highlights
	pass

# ============================================================================
# BUTTON HANDLERS
# ============================================================================
func _on_attack_pressed():
	var tm = get_node_or_null("/root/TurnManager")
	if tm == null or not tm.is_action_allowed():
		_show_error("Not your turn")
		return
	
	# Use CommandProcessor for validation and execution
	current_action = "attack"
	current_mode = ActionMode.SELECT_SOURCE
	action_started.emit("attack")
	show_event_message("Select province to attack FROM")

func _on_move_pressed():
	var tm = get_node_or_null("/root/TurnManager")
	if tm == null or not tm.is_action_allowed():
		_show_error("Not your turn")
		return
	
	current_action = "move"
	current_mode = ActionMode.SELECT_SOURCE
	action_started.emit("move")
	show_event_message("Select province to move troops FROM")

func _on_defend_pressed():
	var tm = get_node_or_null("/root/TurnManager")
	if tm == null or not tm.is_action_allowed():
		_show_error("Not your turn")
		return
	
	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		return
	
	if gs.selected_province_id == &"":
		_show_error("Select one of your provinces first")
		return
	
	var province: ProvinceData = gs.get_province(gs.selected_province_id)
	if province == null:
		_show_error("Select one of your provinces first")
		return
	
	# Direct implementation (CommandProcessor has issues)
	var current_faction = gs.get_current_faction()
	if current_faction == null or not current_faction.owns_province(province.id):
		_show_error("Do not own this province")
		return
	
	var cost: int = province.get_development_cost()
	if current_faction.gold < cost:
		_show_error("Not enough gold (need %d)" % cost)
		return
	
	if province.defense_level >= 5:
		_show_error("Province at max defense level")
		return
	
	current_faction.gold -= cost
	province.upgrade_defense()
	_update_stats_display(province)
	show_event_message("Upgraded defense of %s!" % province.province_name)

func _on_recruit_pressed():
	var tm = get_node_or_null("/root/TurnManager")
	if tm == null or not tm.is_action_allowed():
		_show_error("Not your turn")
		return
	
	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		return
	
	if gs.selected_province_id == &"":
		_show_error("Select one of your provinces first")
		return
	
	var province: ProvinceData = gs.get_province(gs.selected_province_id)
	if province == null:
		_show_error("Select one of your provinces first")
		return
	
	# Direct implementation
	const RECRUIT_AMOUNT: int = 10
	const RECRUIT_COST: int = 100
	
	var current_faction = gs.get_current_faction()
	if current_faction == null or not current_faction.owns_province(province.id):
		_show_error("Do not own this province")
		return
	
	if current_faction.gold < RECRUIT_COST:
		_show_error("Not enough gold (need %d)" % RECRUIT_COST)
		return
	
	current_faction.gold -= RECRUIT_COST
	province.troops += RECRUIT_AMOUNT
	_update_stats_display(province)
	show_event_message("Recruited %d troops in %s!" % [RECRUIT_AMOUNT, province.province_name])

func _on_scout_pressed():
	var tm = get_node_or_null("/root/TurnManager")
	if tm == null or not tm.is_action_allowed():
		_show_error("Not your turn")
		return
	
	current_action = "scout"
	current_mode = ActionMode.SELECT_SOURCE
	action_started.emit("scout")
	show_event_message("Select province to scout FROM")

func _on_end_turn_pressed():
	var tm = get_node_or_null("/root/TurnManager")
	if tm == null or not tm.is_action_allowed():
		return
	tm.end_player_turn()
	end_turn_requested.emit()

func _on_undo_pressed():
	var cp = get_node_or_null("/root/CommandProcessor")
	if cp:
		if cp.undo():
			show_event_message("Action undone")
		else:
			_show_error("Cannot undo")
	_update_undo_redo_buttons()

func _on_redo_pressed():
	var cp = get_node_or_null("/root/CommandProcessor")
	if cp:
		if cp.redo():
			show_event_message("Action redone")
		else:
			_show_error("Cannot redo")
	_update_undo_redo_buttons()

func _on_save_pressed():
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		if sm.save_game(1):
			show_event_message("Game saved!")
		else:
			_show_error("Failed to save game")
	else:
		_show_error("SaveManager not available")

func _on_captured_pressed():
	var lm = get_node_or_null("/root/LordManager")
	var gs = get_node_or_null("/root/GameState")
	if lm == null or gs == null:
		return
	
	var captured = lm.get_captured_lords(gs.player_faction_id)
	
	if captured.is_empty():
		show_event_message("No captured nobles.\n\nDefeat enemy forces to capture their rulers!")
		return
	
	# Build message with captured nobles
	var msg = "CAPTURED NOBLES:\n\n"
	for lord in captured:
		var original_faction = ""
		if gs.factions.has(lord.family_id):
			original_faction = gs.factions[lord.family_id].faction_name
		
		msg += "• %s\n" % lord.name
		msg += "  Leadership: %d | Command: %d | Charm: %d\n" % [lord.leadership, lord.command, lord.charm]
		if not original_faction.is_empty():
			msg += "  Originally from %s\n" % original_faction
		msg += "  [Recruit for 80 gold]\n\n"
	
	msg += "Click 'Recruit' to add them to your faction!"
	show_event_message(msg)
	
	# TODO: Create a proper dialog for recruiting
	# For now, just show the first available captive as recruitable
	if not captured.is_empty():
		var first_captive = captured[0]
		# Auto-recruit for testing (remove this in production)
		# lm.recruit_lord(first_captive.id, gs.player_faction_id)

func _update_undo_redo_buttons():
	var cp = get_node_or_null("/root/CommandProcessor")
	
	if undo_btn:
		undo_btn.disabled = (cp == null) or not cp.can_undo()
	if redo_btn:
		redo_btn.disabled = (cp == null) or not cp.can_redo()

# ============================================================================
# ACTION EXECUTION
# ============================================================================
func _execute_action():
	if selected_source == null or selected_target == null:
		return
	
	match current_action:
		"attack":
			_execute_attack(selected_source, selected_target)
		"move":
			_execute_move(selected_source, selected_target)
		"scout":
			_execute_scout(selected_source, selected_target)
	
	action_completed.emit(current_action, true)
	reset_mode()
	_update_ui()

func _execute_attack(source: ProvinceData, target: ProvinceData):
	var gs = get_node_or_null("/root/GameState")
	var cp = get_node_or_null("/root/CommandProcessor")
	var cr = get_node_or_null("/root/CombatResolver")
	
	if gs == null or cr == null:
		return
	
	if cp != null and cp.can_attack(source.id, target.id):
		# Use CommandProcessor
		if not cp.execute_attack(source.id, target.id):
			_show_error("Attack failed")
		return
	
	# Direct implementation fallback
	var attacker_id: StringName = gs.get_current_faction().id
	var defender_id := target.owner_faction_id
	
	var result = cr.resolve_battle(attacker_id, defender_id, source.id, target.id)
	
	if result != null:
		_show_battle_result(result)
		_update_stats_display(source)

func _execute_move(source: ProvinceData, target: ProvinceData):
	var gs = get_node_or_null("/root/GameState")
	var cp = get_node_or_null("/root/CommandProcessor")
	
	if gs == null:
		return
	
	# Calculate move amount (simplified: move half, keep minimum)
	var amount: int = mini(maxi(source.troops - 1, 0), 100)
	if amount <= 0:
		_show_error("Not enough troops to move")
		return
	
	if cp != null and cp.can_move(source.id, target.id, amount):
		# Use CommandProcessor
		if cp.execute_move(source.id, target.id, amount):
			show_event_message("Moved %d troops from %s to %s" % [amount, source.province_name, target.province_name])
			_update_stats_display(source)
		return
	
	# Direct implementation fallback
	source.troops -= amount
	target.troops += amount
	gs.troops_moved.emit(source.id, target.id, amount)
	show_event_message("Moved %d troops from %s to %s" % [amount, source.province_name, target.province_name])
	_update_stats_display(source)

func _execute_scout(_source: ProvinceData, target: ProvinceData):
	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		return
	
	# Reveal information about target
	var info := "Scout Report: %s\n" % target.province_name
	info += "Owner: %s\n" % (gs.factions[target.owner_faction_id].faction_name if target.has_owner() else "None")
	info += "Troops: %d (approximate)\n" % target.troops
	info += "Defense: Level %d" % target.defense_level
	show_event_message(info)

func _show_battle_result(result):
	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		return
	
	var target_name: String = gs.provinces[result.target_province_id].province_name if gs.provinces.has(result.target_province_id) else "Unknown"
	var msg: String
	if result.attacker_won:
		msg = "Victory! Conquered %s with %d survivors.\nLosses: %d attackers, %d defenders" % [
			target_name,
			result.troops_moved_to_target,
			result.attacker_losses,
			result.defender_losses
		]
	else:
		msg = "Defeat at %s!\nLosses: %d attackers, %d defenders" % [
			target_name,
			result.attacker_losses,
			result.defender_losses
		]
	show_event_message(msg)

# ============================================================================
# UTILITIES
# ============================================================================
func reset_mode():
	current_mode = ActionMode.NORMAL
	selected_source = null
	selected_target = null
	current_action = ""
	_clear_highlights()

func _update_ui():
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.selected_province_id != &"":
		_update_for_province(gs.get_province(gs.selected_province_id))

func _show_error(msg: String):
	push_warning("Sidebar Error: %s" % msg)
	show_event_message("Error: " + msg)

# ============================================================================
# COMMAND SYSTEM FEEDBACK
# ============================================================================

func _on_history_changed(_history_size: int, _redo_size: int):
	_update_undo_redo_buttons()

func _on_command_executed(command):
	# Refresh UI after command execution
	_update_ui()
	
	# Show success message based on command type (using duck typing)
	var cmd_name = command.get_description()
	if cmd_name.begins_with("Move"):
		show_event_message(cmd_name)

func _on_command_failed(_command, error: String):
	_show_error(error)

func _on_battle_resolved(result: Dictionary):
	_show_battle_result(result)
	_update_ui()

func _on_lord_captured(lord_id: StringName, captor_faction_id: StringName, province_id: StringName):
	var lm = get_node_or_null("/root/LordManager")
	var gs = get_node_or_null("/root/GameState")
	if lm == null or gs == null:
		return
	
	var lord = lm.get_character(lord_id)
	var province = gs.get_province(province_id)
	var captor = gs.get_faction(captor_faction_id)
	
	if lord and province and captor:
		var msg = "%s captured!\n%s has taken %s prisoner." % [lord.name, captor.faction_name, lord.name]
		show_event_message(msg)
		
		# If player captured someone, show additional info
		if captor_faction_id == gs.player_faction_id:
			msg += "\n\nYou can recruit %s for %d gold or release them." % [lord.name, GameConfig.LORD_RECRUIT_COST]
			show_event_message(msg)

func _on_lord_recruited(lord_id: StringName, new_faction_id: StringName):
	var lm = get_node_or_null("/root/LordManager")
	var gs = get_node_or_null("/root/GameState")
	if lm == null or gs == null:
		return
	
	var lord = lm.get_character(lord_id)
	var faction = gs.get_faction(new_faction_id)
	
	if lord and faction:
		show_event_message("%s has joined %s!" % [lord.name, faction.faction_name])

# ============================================================================
# EVENT MESSAGE (Typewriter)
# ============================================================================
func show_event_message(message: String, typing_speed: float = 0.02) -> void:
	if not event_message_label:
		return
	
	# Stop any existing animation
	if _typing_tween != null and _typing_tween.is_valid():
		_typing_tween.kill()
	
	event_message_label.text = ""
	
	# Create typewriter animation
	_typing_tween = create_tween()
	if _typing_tween == null:
		# Fallback if tween creation fails
		event_message_label.text = message
		return
	
	for i in range(message.length()):
		_typing_tween.tween_callback(func():
			if event_message_label:
				event_message_label.text = message.substr(0, i + 1)
		)
		_typing_tween.tween_interval(typing_speed)

func clear_event_message() -> void:
	if event_message_label:
		event_message_label.text = ""
	if _typing_tween != null and _typing_tween.is_valid():
		_typing_tween.kill()
	_typing_tween = null
