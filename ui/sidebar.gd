extends Control

enum ActionMode {
	NORMAL,
	SELECT_SOURCE,
	SELECT_TARGET
}

signal action_started(action_name: String)
signal action_completed(action_name: String, success: bool)
signal end_turn_requested()

const FactionData = preload("res://resources/data_classes/faction_data.gd")
const ProvinceData = preload("res://resources/data_classes/province_data.gd")

# ============================================================================
# NODES
# ============================================================================
@onready var province_name: Label = %ProvinceName
@onready var ruler_name: Label = %RulerName

@onready var defense_value: Label = %DefenseValue
@onready var income_value: Label = %IncomeValue
@onready var garrison_value: Label = %GarrisonValue
@onready var loyalty_value: Label = %LoyaltyValue

@onready var attack_btn: Button = %AttackBtn
@onready var defend_btn: Button = %DefendBtn
@onready var recruit_btn: Button = %RecruitBtn
@onready var scout_btn: Button = %ScoutBtn
@onready var end_turn_btn: Button = %EndTurnBtn

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
	
	# Connect signals deferred (button connections are in .tscn file)
	call_deferred("_connect_signals")
	
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
	
	if tm:
		tm.player_turn_started.connect(_on_player_turn_started)
		tm.state_changed.connect(_on_state_changed)
	
	if gs:
		gs.province_selected.connect(_on_province_selected)

# ============================================================================
# STATE HANDLERS
# ============================================================================
func _on_state_changed(new_state, _old_state):
	# Compare using integer values of enum
	var player_turn_value = 1
	var ai_turn_value = 2
	var game_over_value = 5
	
	if new_state == player_turn_value:
		_set_buttons_enabled(true)
	elif new_state == ai_turn_value:
		_set_buttons_enabled(false)
		reset_mode()
	elif new_state == game_over_value:
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

func _on_player_turn_started():
	reset_mode()
	_update_ui()

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
	
	# Update ruler name with faction color
	if ruler_name:
		if data.has_owner():
			var gs = get_node_or_null("/root/GameState")
			if gs and gs.factions.has(data.owner_faction_id):
				var faction: FactionData = gs.factions[data.owner_faction_id]
				ruler_name.text = faction.faction_name
				# Color code by faction
				ruler_name.add_theme_color_override("font_color", faction.color)
			else:
				ruler_name.text = "Unclaimed"
				ruler_name.add_theme_color_override("font_color", Color.GRAY)
		else:
			ruler_name.text = "Unclaimed"
			ruler_name.add_theme_color_override("font_color", Color.GRAY)
	
	# Update stats
	_update_stats_display(data)

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
	
	# Defend/Develop - upgrade defense level
	if gs.selected_province_id != &"":
		var province: ProvinceData = gs.get_province(gs.selected_province_id)
		if province and _can_be_source(province):
			var cost: int = province.get_development_cost()
			var faction: FactionData = gs.get_current_faction()
			if faction.gold >= cost:
				var current_bonus = province.get_defense_bonus()
				var current_percent = int((current_bonus - 1.0) * 100)
				
				faction.gold -= cost
				province.upgrade_defense()
				_update_stats_display(province)
				
				var new_bonus = province.get_defense_bonus()
				var new_percent = int((new_bonus - 1.0) * 100)
				
				show_event_message(
					"Upgraded %s defense!\n" % province.province_name +
					"Cost: %d gold\n" % cost +
					"Bonus: +%d%% → +%d%%" % [current_percent, new_percent]
				)
			else:
				_show_error("Not enough gold (need %d)" % cost)
		else:
			_show_error("Select one of your provinces first")

func _on_recruit_pressed():
	var tm = get_node_or_null("/root/TurnManager")
	if tm == null or not tm.is_action_allowed():
		_show_error("Not your turn")
		return
	
	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		return
	
	# Recruit troops in selected province
	if gs.selected_province_id != &"":
		var province: ProvinceData = gs.get_province(gs.selected_province_id)
		if province and _can_be_source(province):
			var cost: int = 10 * 10  # RECRUIT_COST * 10
			var faction: FactionData = gs.get_current_faction()
			if faction.gold >= cost:
				faction.gold -= cost
				province.troops += 10
				_update_stats_display(province)
				show_event_message("Recruited 10 troops in %s!" % province.province_name)
			else:
				_show_error("Not enough gold (need %d)" % cost)
		else:
			_show_error("Select one of your provinces first")

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
	if gs == null:
		return
	
	var attacker_id: StringName = gs.get_current_faction().id
	
	if not target.has_owner():
		_show_error("Target has no owner")
		return
	
	var defender_id := target.owner_faction_id
	
	var cr = get_node_or_null("/root/CombatResolver")
	if cr == null:
		_show_error("CombatResolver not available")
		return
	
	var result = cr.resolve_battle(attacker_id, defender_id, source.id, target.id)
	
	if result != null:
		_show_battle_result(result)
		_update_stats_display(source)

func _execute_move(source: ProvinceData, target: ProvinceData):
	# Calculate move amount (simplified: move half, keep minimum)
	var amount: int = mini(maxi(source.troops - 1, 0), 100)
	if amount <= 0:
		_show_error("Not enough troops to move")
		return
	
	source.troops -= amount
	target.troops += amount
	
	var gs = get_node_or_null("/root/GameState")
	if gs:
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
# EVENT MESSAGE (Typewriter)
# ============================================================================
func show_event_message(message: String, typing_speed: float = 0.02) -> void:
	if not event_message_label:
		return
	
	# Stop any existing animation
	if _typing_tween:
		_typing_tween.kill()
	
	event_message_label.text = ""
	
	# Create typewriter animation
	_typing_tween = create_tween()
	
	for i in range(message.length()):
		_typing_tween.tween_callback(func():
			if event_message_label:
				event_message_label.text = message.substr(0, i + 1)
		)
		_typing_tween.tween_interval(typing_speed)

func clear_event_message() -> void:
	if event_message_label:
		event_message_label.text = ""
	if _typing_tween:
		_typing_tween.kill()
		_typing_tween = null
