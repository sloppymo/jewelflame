extends CanvasLayer

# Tactical Battle HUD - Complete Implementation

const COLOR_BLUE = Color("#4a4a9e")
const COLOR_GOLD = Color("#c4a000")
const COLOR_TEXT = Color("#ffffff")

enum CommandState {
	IDLE,
	SELECTING_TARGET,
	EXECUTING_ACTION,
	BATTLE_ENDED
}

var current_state: CommandState = CommandState.IDLE
var selected_unit = null
var selected_command: String = ""

# Battle info
var attacker_name: String = ""
var defender_name: String = ""
var attacker_count: int = 0
var defender_count: int = 0

# Signals
signal command_selected(command: String)
signal target_selected(target)
signal turn_ended
signal retreat_requested
signal formation_selected(formation: String)

@onready var top_banner = get_node_or_null("TopBanner")
@onready var banner_label = get_node_or_null("TopBanner/BannerLabel")
@onready var attacker_portrait = get_node_or_null("TopBanner/AttackerPortrait")
@onready var defender_portrait = get_node_or_null("TopBanner/DefenderPortrait")
@onready var command_menu = get_node_or_null("CommandMenu")
@onready var attack_btn = get_node_or_null("CommandMenu/HBoxContainer/AttackBtn")
@onready var wait_btn = get_node_or_null("CommandMenu/HBoxContainer/WaitBtn")
@onready var fence_btn = get_node_or_null("CommandMenu/HBoxContainer/FenceBtn")
@onready var break_btn = get_node_or_null("CommandMenu/HBoxContainer/BreakBtn")
@onready var retreat_btn = get_node_or_null("CommandMenu/HBoxContainer/RetreatBtn")
@onready var message_label = get_node_or_null("MessageLabel")
@onready var formation_popup = get_node_or_null("FormationPopup")

func _ready():
	_setup_buttons()
	_setup_banner()
	_setup_formation_popup()
	hide_message()

func _setup_buttons():
	if attack_btn:
		attack_btn.pressed.connect(_on_attack_pressed)
		_style_button(attack_btn)
	if wait_btn:
		wait_btn.pressed.connect(_on_wait_pressed)
		_style_button(wait_btn)
	if fence_btn:
		fence_btn.pressed.connect(_on_fence_pressed)
		_style_button(fence_btn)
	if break_btn:
		break_btn.pressed.connect(_on_break_pressed)
		_style_button(break_btn)
	if retreat_btn:
		retreat_btn.pressed.connect(_on_retreat_pressed)
		_style_button(retreat_btn)

func _style_button(btn: Button):
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = COLOR_BLUE
	normal_style.border_color = COLOR_GOLD
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 4
	normal_style.corner_radius_bottom_left = 4
	normal_style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color("#6a6abe")
	hover_style.border_color = Color("#e6d47a")
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	btn.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color("#2a2a7e")
	pressed_style.border_color = COLOR_GOLD
	pressed_style.border_width_left = 3
	pressed_style.border_width_top = 3
	pressed_style.border_width_right = 1
	pressed_style.border_width_bottom = 1
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", COLOR_TEXT)

func _setup_banner():
	if top_banner == null:
		push_warning("TopBanner missing from tactical_hud scene")
		return
		
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BLUE
	style.border_color = COLOR_GOLD
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	top_banner.add_theme_stylebox_override("panel", style)
	
	# Setup portraits
	if attacker_portrait:
		attacker_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		attacker_portrait.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	if defender_portrait:
		defender_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		defender_portrait.expand_mode = TextureRect.EXPAND_KEEP_SIZE

func _setup_formation_popup():
	if formation_popup:
		formation_popup.hide()
		
		# Connect formation buttons if they exist
		var normal_btn = formation_popup.get_node_or_null("NormalBtn")
		var flank_btn = formation_popup.get_node_or_null("FlankBtn")
		var rear_btn = formation_popup.get_node_or_null("RearBtn")
		
		if normal_btn:
			normal_btn.pressed.connect(_on_formation_chosen.bind("normal"))
		if flank_btn:
			flank_btn.pressed.connect(_on_formation_chosen.bind("flank"))
		if rear_btn:
			rear_btn.pressed.connect(_on_formation_chosen.bind("rear"))

func set_battle_info(attacker: String, defender: String, attacker_portrait_path: String = "", defender_portrait_path: String = ""):
	attacker_name = attacker
	defender_name = defender
	
	# Load portraits
	if attacker_portrait and not attacker_portrait_path.is_empty():
		var texture = load(attacker_portrait_path)
		if texture:
			attacker_portrait.texture = texture
	
	if defender_portrait and not defender_portrait_path.is_empty():
		var texture = load(defender_portrait_path)
		if texture:
			defender_portrait.texture = texture
	
	_update_banner()

func update_counts(attacker_cnt: int, defender_cnt: int):
	attacker_count = attacker_cnt
	defender_count = defender_cnt
	_update_banner()

func _update_banner():
	var text = "%s ⚔️ vs 🛡️ %s" % [attacker_name, defender_name]
	if banner_label:
		banner_label.text = text

func show_formation_selection():
	if formation_popup:
		formation_popup.show()
		enable_commands(false)

func _on_formation_chosen(formation: String):
	if formation_popup:
		formation_popup.hide()
	formation_selected.emit(formation)

func _on_attack_pressed():
	if current_state == CommandState.IDLE:
		current_state = CommandState.SELECTING_TARGET
		selected_command = "attack"
		show_message("Select target to attack")
		command_selected.emit("attack")

func _on_wait_pressed():
	if current_state == CommandState.IDLE:
		command_selected.emit("wait")
		show_message("Unit waits...")
		end_turn()

func _on_fence_pressed():
	if current_state == CommandState.IDLE:
		command_selected.emit("fence")
		show_message("Defensive barrier activated!")
		end_turn()

func _on_break_pressed():
	if current_state == CommandState.IDLE:
		current_state = CommandState.SELECTING_TARGET
		selected_command = "break"
		show_message("Select target to break")
		command_selected.emit("break")

func _on_retreat_pressed():
	if current_state == CommandState.IDLE:
		command_selected.emit("retreat")
		retreat_requested.emit()

func on_target_clicked(target):
	if current_state == CommandState.SELECTING_TARGET:
		selected_unit = target
		target_selected.emit(target)
		current_state = CommandState.EXECUTING_ACTION
		hide_message()

func end_turn():
	current_state = CommandState.IDLE
	selected_command = ""
	selected_unit = null
	turn_ended.emit()

func show_message(text: String):
	if message_label:
		message_label.text = text
		message_label.show()
		await get_tree().create_timer(3.0).timeout
		hide_message()

func hide_message():
	if message_label:
		message_label.hide()

func show_victory_message(winner: String):
	var panel = $VictoryPanel
	var label = $VictoryPanel/Label
	if label:
		label.text = "The %s won!" % winner
	if panel:
		panel.show()
		await get_tree().create_timer(3.0).timeout
		panel.hide()

func show_wipeout_message(unit_type: String):
	show_message("The %s unit was wiped out!" % unit_type)

func enable_commands(enabled: bool):
	if attack_btn: attack_btn.disabled = not enabled
	if wait_btn: wait_btn.disabled = not enabled
	if fence_btn: fence_btn.disabled = not enabled
	if break_btn: break_btn.disabled = not enabled
	if retreat_btn: retreat_btn.disabled = not enabled
