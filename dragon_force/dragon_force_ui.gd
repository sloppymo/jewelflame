class_name DragonForceUI
extends CanvasLayer

## UI Controller for Dragon Force Battle
## Handles formation buttons, spell casting, and battle info display

@onready var formation_buttons = {
	"melee": $UI/FormationPanel/VBoxContainer/MeleeBtn,
	"standby": $UI/FormationPanel/VBoxContainer/StandbyBtn,
	"advance": $UI/FormationPanel/VBoxContainer/AdvanceBtn,
	"retreat": $UI/FormationPanel/VBoxContainer/RetreatBtn
}

@onready var spell_button: Button = $UI/SpellPanel/VBoxContainer/SpellBtn
@onready var mp_bar: ProgressBar = $UI/SpellPanel/VBoxContainer/MPBar
@onready var spell_status: Label = $UI/SpellPanel/VBoxContainer/StatusLabel

@onready var selected_label: Label = $UI/InfoPanel/VBoxContainer/SelectedLabel
@onready var troops_label: Label = $UI/InfoPanel/VBoxContainer/TroopsLabel
@onready var hp_label: Label = $UI/InfoPanel/VBoxContainer/HPLabel
@onready var mode_label: Label = $UI/InfoPanel/VBoxContainer/ModeLabel

@onready var result_panel: Panel = $UI/BattleResultPanel
@onready var result_label: Label = $UI/BattleResultPanel/VBoxContainer/ResultLabel
@onready var stats_label: Label = $UI/BattleResultPanel/VBoxContainer/StatsLabel
@onready var return_button: Button = $UI/BattleResultPanel/VBoxContainer/ReturnBtn

var battle_controller: DragonForceBattle = null

func _ready():
	print("DragonForceUI ready")
	
	# Connect formation buttons
	formation_buttons["melee"].pressed.connect(_on_formation_pressed.bind("melee"))
	formation_buttons["standby"].pressed.connect(_on_formation_pressed.bind("standby"))
	formation_buttons["advance"].pressed.connect(_on_formation_pressed.bind("advance"))
	formation_buttons["retreat"].pressed.connect(_on_formation_pressed.bind("retreat"))
	
	# Connect spell button
	spell_button.pressed.connect(_on_spell_pressed)
	
	# Connect return button
	return_button.pressed.connect(_on_return_pressed)
	
	# Hide result panel initially
	result_panel.visible = false

func setup(controller: DragonForceBattle):
	battle_controller = controller
	
	# Connect to battle signals
	battle_controller.general_selected.connect(_on_general_selected)
	battle_controller.battle_ended.connect(_on_battle_ended)

func _process(_delta):
	_update_ui()

func _update_ui():
	if not battle_controller:
		return
	
	# Get player general
	var player_general = battle_controller.player_general
	if not player_general:
		return
	
	# Update MP bar
	mp_bar.value = player_general.current_mp
	mp_bar.max_value = player_general.max_mp
	
	# Update spell button
	if player_general.spell_ready:
		spell_button.disabled = false
		spell_status.text = "READY!"
		spell_status.modulate = Color(0, 1, 0)
	else:
		spell_button.disabled = true
		spell_status.text = "Charging... (%d%%)" % int((player_general.current_mp / player_general.max_mp) * 100)
		spell_status.modulate = Color(1, 1, 0)
	
	# Update selected general info
	var selected = battle_controller.selected_general
	if selected:
		selected_label.text = "Selected: %s" % selected.general_name
		troops_label.text = "Troops: %d/%d" % [selected.current_troops, selected.max_troops]
		hp_label.text = "HP: %d/%d" % [selected.current_hp, selected.max_hp]
	else:
		selected_label.text = "Selected: None"
		troops_label.text = "Troops: --"
		hp_label.text = "HP: --"

func _on_formation_pressed(formation_name: String):
	if not battle_controller or not battle_controller.selected_general:
		return
	
	var formation: General.Formation
	match formation_name:
		"melee": formation = General.Formation.MELEE
		"standby": formation = General.Formation.STANDBY
		"advance": formation = General.Formation.ADVANCE
		"retreat": formation = General.Formation.RETREAT
		_: return
	
	battle_controller.selected_general.set_formation(formation)
	print("Formation changed to: ", formation_name)

func _on_spell_pressed():
	if not battle_controller:
		return
	
	battle_controller.start_spell_targeting("fireball")

func _on_return_pressed():
	# Return to strategic map
	print("Returning to strategic map...")
	
	# Use CombatResolver to handle scene transition
	var result = {
		"attacker_won": battle_controller.player_general.is_alive() if battle_controller.player_general else false,
		"defender_won": not (battle_controller.player_general.is_alive() if battle_controller.player_general else true),
		"attacker_survivors": battle_controller.player_general.current_troops / 20 if battle_controller.player_general else 0,
		"defender_survivors": battle_controller.enemy_general.current_troops / 20 if battle_controller.enemy_general else 0
	}
	
	# Call CombatResolver's battle end handler
	var combat_resolver = get_node_or_null("/root/CombatResolver")
	if combat_resolver:
		# Trigger scene return
		var strategic = load("res://main_strategic.tscn").instantiate()
		var current = get_tree().current_scene
		get_tree().root.add_child(strategic)
		get_tree().current_scene = strategic
		if current:
			current.queue_free()

func _on_general_selected(general: General):
	_update_ui()

func _on_battle_ended(result: Dictionary):
	result_panel.visible = true
	
	if result.get("player_won", false):
		result_label.text = "VICTORY!"
		result_label.modulate = Color(0, 1, 0)
	else:
		result_label.text = "DEFEAT!"
		result_label.modulate = Color(1, 0, 0)
	
	var player_troops = result.get("player_troops_remaining", 0)
	var enemy_troops = result.get("enemy_troops_remaining", 0)
	stats_label.text = "Your troops: %d\nEnemy troops: %d" % [player_troops, enemy_troops]

func update_input_mode(mode_name: String):
	mode_label.text = "Mode: %s" % mode_name.to_upper()
	
	match mode_name:
		"select":
			mode_label.modulate = Color(1, 1, 1)
		"move":
			mode_label.modulate = Color(0, 1, 0)
		"spell":
			mode_label.modulate = Color(1, 0.5, 0)

func show_battle_result(result: Dictionary):
	_on_battle_ended(result)
