class_name StrategicMapController
extends Node2D

const StrategicProvince = preload("res://resources/data_classes/strategic_province.gd")

## Dragon Force Strategic Map Controller
## Phase 0: Foundation - Army movement and battle detection

@onready var roads_layer: Node2D = $Roads
@onready var province_markers: Node2D = $ProvinceMarkers
@onready var armies_layer: Node2D = $Armies
@onready var camera: Camera2D = $Camera2D

@onready var province_label: Label = $UI/InfoPanel/VBoxContainer/ProvinceLabel
@onready var owner_label: Label = $UI/InfoPanel/VBoxContainer/OwnerLabel
@onready var selected_army_label: Label = $UI/InfoPanel/VBoxContainer/SelectedArmyLabel

var strategic_graph: StrategicGraph = null
var selected_province: StrategicProvince = null
var province_buttons: Dictionary[StringName, Button] = {}

func _ready():
	print("StrategicMapController: Initializing Phase 0...")
	
	# Get StrategicGraph autoload
	strategic_graph = get_node_or_null("/root/StrategicGraph")
	if not strategic_graph:
		push_error("StrategicGraph autoload not found!")
		return
	
	# Connect signals
	strategic_graph.battle_triggered.connect(_on_battle_triggered)
	strategic_graph.province_clicked.connect(_on_province_clicked)
	
	# Setup visuals
	_draw_roads()
	_create_province_buttons()
	_spawn_initial_armies()
	
	print("StrategicMapController: Phase 0 ready! Click a province, then click destination to move.")

func _draw_roads():
	"""Draw visible lines between connected provinces."""
	for conn in strategic_graph.connections:
		var from_pos = strategic_graph.provinces[conn.from].map_position
		var to_pos = strategic_graph.provinces[conn.to].map_position
		
		var line = Line2D.new()
		line.points = [from_pos, to_pos]
		line.width = 4
		line.default_color = Color(0.4, 0.3, 0.2)  # Brown dirt road
		line.z_index = -1
		roads_layer.add_child(line)

func _create_province_buttons():
	"""Create clickable province markers."""
	for id in strategic_graph.provinces:
		var province = strategic_graph.provinces[id]
		
		var button = Button.new()
		button.name = "ProvinceButton_%s" % id
		button.position = province.map_position - Vector2(40, 25)
		button.size = Vector2(80, 50)
		button.text = province.province_name
		
		# Style based on owner
		var style = StyleBoxFlat.new()
		style.bg_color = _get_faction_color(province.owner_faction)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		button.add_theme_stylebox_override("normal", style)
		
		button.pressed.connect(_on_province_button_pressed.bind(province))
		province_markers.add_child(button)
		province_buttons[id] = button

func _get_faction_color(faction: StringName) -> Color:
	match faction:
		&"blanche": return Color(0.3, 0.5, 1.0, 0.7)
		&"lyle": return Color(1.0, 0.3, 0.3, 0.7)
		&"coryll": return Color(1.0, 0.8, 0.2, 0.7)
		_: return Color(0.5, 0.5, 0.5, 0.7)

func _spawn_initial_armies():
	"""Spawn initial armies for testing."""
	# Player army at Dunmoor
	var player_army = strategic_graph.spawn_army(&"dunmoor", &"blanche", true)
	player_army.general_name = "Erin Blanche"
	
	# Enemy army at Carveti (will move toward Dunmoor)
	var enemy_army = strategic_graph.spawn_army(&"carveti", &"coryll", false)
	enemy_army.general_name = "Marcus Coryll"
	
	# Start enemy moving toward player after delay
	get_tree().create_timer(2.0).timeout.connect(
		func():
			if enemy_army:
				enemy_army.start_movement(strategic_graph.provinces[&"dunmoor"])
	)

# ============================================================================
# INPUT HANDLING
# ============================================================================

func _on_province_button_pressed(province: StrategicProvince):
	"""Handle province click."""
	print("StrategicMap: Clicked province %s" % province.province_name)
	
	# Update UI
	province_label.text = "Province: %s" % province.province_name
	owner_label.text = "Owner: %s" % province.owner_faction
	
	# Handle army movement
	if strategic_graph.selected_army and strategic_graph.selected_army.is_player_controlled:
		# Try to move selected army to this province
		var success = strategic_graph.move_army(strategic_graph.selected_army, province.id)
		if success:
			selected_province = null
			_update_selected_army_label()
		return
	
	# Just select the province
	selected_province = province
	strategic_graph.province_clicked.emit(province)

func _on_province_clicked(province: StrategicProvince):
	"""Handle province selection signal."""
	print("StrategicMap: Province %s selected" % province.province_name)

func _input(event):
	# Number key 1 to select player army
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			_select_player_army()

func _select_player_army():
	"""Select the first player-controlled army."""
	for army in strategic_graph.armies:
		if army.is_player_controlled and army.is_alive:
			strategic_graph.select_army(army)
			_update_selected_army_label()
			return

func _update_selected_army_label():
	if strategic_graph.selected_army:
		selected_army_label.text = "Selected: %s (%s)" % [
			strategic_graph.selected_army.general_name,
			strategic_graph.selected_army.faction
		]
	else:
		selected_army_label.text = "Selected: None"

# ============================================================================
# BATTLE HANDLING
# ============================================================================

func _on_battle_triggered(army1: Node2D, army2: Node2D, location: Vector2):
	"""Handle battle detection between armies."""
	print("StrategicMap: BATTLE between %s and %s!" % [army1.general_name, army2.general_name])
	
	# Set active battle flag
	strategic_graph.active_battle = true
	
	# Pause strategic movement
	for army in strategic_graph.armies:
		army.set_physics_process(false)
	
	# Transition to battle scene
	_transition_to_battle(army1, army2)

func _transition_to_battle(army1: Node2D, army2: Node2D):
	"""Transition to battle scene."""
	print("StrategicMap: Transitioning to battle scene...")
	
	# Fade out (simple delay for now)
	get_tree().create_timer(0.5).timeout.connect(
		func():
			# Load battle scene
			var battle = load("res://dragon_force/battle_scene.tscn").instantiate()
			
			# Connect battle ended signal
			battle.battle_ended.connect(_on_battle_ended.bind(army1, army2))
			
			# Change scene
			var current = get_tree().current_scene
			get_tree().root.add_child(battle)
			get_tree().current_scene = battle
			if current:
				current.queue_free()
	)

func _on_battle_ended(result: Dictionary, army1: Node2D, army2: Node2D):
	"""Handle battle completion and return to strategic map."""
	print("StrategicMap: Battle ended! Player won: %s" % result.get("player_won", false))
	
	var player_won = result.get("player_won", false)
	
	# Mark defeated army
	if player_won:
		if not army1.is_player_controlled:
			army1.mark_defeated()
		else:
			army2.mark_defeated()
	else:
		if army1.is_player_controlled:
			army1.mark_defeated()
		else:
			army2.mark_defeated()
	
	# Clear battle flag
	strategic_graph.active_battle = false

func _show_battle_dialog(army1: Node2D, army2: Node2D):
	"""Show battle announcement UI."""
	var dialog = AcceptDialog.new()
	dialog.title = "BATTLE!"
	dialog.dialog_text = "%s vs %s\n\nClash at %s!" % [
		army1.general_name,
		army2.general_name,
		army1.current_province if army1.is_moving else army2.current_province
	]
	add_child(dialog)
	dialog.popup_centered()
	
	# Auto-close after 2 seconds
	get_tree().create_timer(2.0).timeout.connect(dialog.queue_free)
