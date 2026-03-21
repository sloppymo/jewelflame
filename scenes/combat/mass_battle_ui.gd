class_name MassBattleUI
extends CanvasLayer

## UI for Mass Battle - Pause controls, order buttons, group status

signal pause_toggled()
signal order_mode_selected(mode: String)
signal auto_command_toggled(enabled: bool)
signal retreat_requested()

# References to UI elements
@onready var pause_button: Button = $Control/TopBar/PauseButton
@onready var pause_label: Label = $Control/TopBar/PauseLabel
@onready var move_button: Button = $Control/BottomPanel/MoveButton
@onready var attack_button: Button = $Control/BottomPanel/AttackButton
@onready var hold_button: Button = $Control/BottomPanel/HoldButton
@onready var select_button: Button = $Control/BottomPanel/SelectButton
@onready var auto_checkbox: CheckBox = $Control/BottomPanel/AutoCheckBox
@onready var retreat_button: Button = $Control/BottomPanel/RetreatButton

@onready var status_label: Label = $Control/TopBar/StatusLabel
@onready var turn_label: Label = $Control/TopBar/TurnLabel
@onready var group_info: Label = $Control/GroupInfoPanel/GroupInfo

@onready var victory_panel: Panel = $Control/VictoryPanel
@onready var victory_label: Label = $Control/VictoryPanel/VictoryLabel
@onready var result_label: Label = $Control/VictoryPanel/ResultLabel
@onready var continue_button: Button = $Control/VictoryPanel/ContinueButton

@onready var instructions: Label = $Control/Instructions

# State
var is_paused: bool = true
var current_mode: String = "select"
var selected_group_count: int = 0

func _ready():
	_setup_connections()
	_update_ui()
	_hide_victory_panel()

func _setup_connections():
	# Pause button
	if pause_button:
		pause_button.pressed.connect(_on_pause_pressed)
	
	# Order buttons
	if move_button:
		move_button.pressed.connect(_on_move_pressed)
	if attack_button:
		attack_button.pressed.connect(_on_attack_pressed)
	if hold_button:
		hold_button.pressed.connect(_on_hold_pressed)
	if select_button:
		select_button.pressed.connect(_on_select_pressed)
	
	# Auto command
	if auto_checkbox:
		auto_checkbox.toggled.connect(_on_auto_toggled)
	
	# Retreat
	if retreat_button:
		retreat_button.pressed.connect(_on_retreat_pressed)
	
	# Victory continue
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)

func _on_pause_pressed():
	pause_toggled.emit()

func _on_move_pressed():
	_set_order_mode("move")

func _on_attack_pressed():
	_set_order_mode("attack")

func _on_hold_pressed():
	_set_order_mode("hold")

func _on_select_pressed():
	_set_order_mode("select")

func _on_auto_toggled(enabled: bool):
	auto_command_toggled.emit(enabled)

func _on_retreat_pressed():
	retreat_requested.emit()

func _on_continue_pressed():
	_hide_victory_panel()

func _set_order_mode(mode: String):
	current_mode = mode
	order_mode_selected.emit(mode)
	_update_button_highlights()

func _update_button_highlights():
	# Reset all buttons
	if move_button:
		move_button.modulate = Color.WHITE
	if attack_button:
		attack_button.modulate = Color.WHITE
	if hold_button:
		hold_button.modulate = Color.WHITE
	if select_button:
		select_button.modulate = Color.WHITE
	
	# Highlight current mode
	match current_mode:
		"move":
			if move_button:
				move_button.modulate = Color.YELLOW
		"attack":
			if attack_button:
				attack_button.modulate = Color.YELLOW
		"hold":
			if hold_button:
				hold_button.modulate = Color.YELLOW
		"select":
			if select_button:
				select_button.modulate = Color.YELLOW

# ============================================================================
# UPDATE METHODS (called by controller)
# ============================================================================

func update_pause_state(paused: bool):
	is_paused = paused
	_update_ui()

func update_order_mode(mode: String):
	current_mode = mode
	_update_button_highlights()

func update_selection_count(count: int):
	selected_group_count = count
	_update_group_info()

func update_battle_status(summary: Dictionary):
	_update_status_label(summary)

func show_victory(attacker_won: bool, result: Dictionary):
	if victory_panel:
		victory_panel.visible = true
	
	if victory_label:
		victory_label.text = "VICTORY!" if attacker_won else "DEFEAT!"
		victory_label.add_theme_color_override("font_color", Color.GREEN if attacker_won else Color.RED)
	
	if result_label:
		var text = "Attacker Casualties: %d\n" % result.get("attacker_casualties", 0)
		text += "Defender Casualties: %d\n" % result.get("defender_casualties", 0)
		text += "Attacker Survivors: %d\n" % result.get("attacker_survivors", 0)
		text += "Defender Survivors: %d" % result.get("defender_survivors", 0)
		result_label.text = text

func _hide_victory_panel():
	if victory_panel:
		victory_panel.visible = false

# ============================================================================
# UI UPDATES
# ============================================================================

func _update_ui():
	# Update pause button text
	if pause_button:
		pause_button.text = "▶ RESUME" if is_paused else "⏸ PAUSE"
	
	# Update pause label
	if pause_label:
		pause_label.text = "PAUSED" if is_paused else "PLAYING"
		pause_label.add_theme_color_override("font_color", Color.YELLOW if is_paused else Color.GREEN)
	
	# Update instructions
	if instructions:
		if is_paused:
			instructions.text = "PAUSED - Click groups to select | Issue orders | SPACE to resume"
		else:
			instructions.text = "PLAYING - Watching battle unfold | SPACE to pause"
	
	_update_button_highlights()
	_update_group_info()

func _update_group_info():
	if group_info:
		if selected_group_count == 0:
			group_info.text = "No groups selected"
		elif selected_group_count == 1:
			group_info.text = "1 group selected"
		else:
			group_info.text = "%d groups selected" % selected_group_count

func _update_status_label(summary: Dictionary):
	if status_label:
		var text = "Attackers: %d groups | Defenders: %d groups" % [
			summary.get("attackers_alive", 0),
			summary.get("defenders_alive", 0)
		]
		status_label.text = text

func update_turn_info(turn_number: int, phase: String):
	if turn_label:
		turn_label.text = "Turn %d - %s" % [turn_number, phase]
