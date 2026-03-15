extends CanvasLayer

const ProvinceData = preload("res://resources/data_classes/province_data.gd")

@onready var label: Label

func _ready():
	# Create the label dynamically
	label = Label.new()
	label.name = "DebugLabel"
	add_child(label)
	
	# Style the label
	label.position = Vector2(10, 10)
	label.add_theme_font_size_override("font_size", 14)
	
	if not OS.is_debug_build():
		hide()
		return
	
	label.text = "DEBUG MODE"
	# z_index is set on the label, not CanvasLayer
	label.z_index = 100

func _process(_delta):
	if not OS.is_debug_build():
		return
	
	var tm = get_node_or_null("/root/TurnManager")
	var gs = get_node_or_null("/root/GameState")
	
	if tm == null or gs == null:
		return
	
	var turn_number: int = tm.turn_number
	var current_state: int = int(tm.current_state)
	var is_processing_ai: bool = tm.is_processing_ai
	
	var state_name: String = "Unknown"
	match current_state:
		0: state_name = "EVENT_PHASE"
		1: state_name = "PLAYER_TURN"
		2: state_name = "AI_TURN"
		3: state_name = "COMBAT_RESOLUTION"
		4: state_name = "TURN_END"
		5: state_name = "GAME_OVER"
	
	var text := "Turn: %d | State: %s\n" % [turn_number, state_name]
	
	for fid in gs.factions:
		var f = gs.factions[fid]
		var personality = GameConfig.AI_PERSONALITIES.get(fid, {})
		var p_name = personality.get("name", "Unknown")
		var attack_thresh = personality.get("attack_threshold", 1.5)
		text += "%s (%s, %.1fx): Gold %d, Provinces %d, Troops %d\n" % [
			f.faction_name, 
			p_name,
			attack_thresh,
			f.gold, 
			f.owned_province_ids.size(),
			f.get_total_troops(gs.provinces)
		]
	
	# Add AI processing status
	if is_processing_ai:
		text += "\n[AI PROCESSING...]"
	
	label.text = text

func draw_line_between_provinces(id1: StringName, id2: StringName, color: Color = Color.YELLOW):
	# Visualize adjacency connections
	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if not gs.provinces.has(id1) or not gs.provinces.has(id2):
		return
	
	var p1: ProvinceData = gs.provinces[id1]
	var p2: ProvinceData = gs.provinces[id2]
	
	# This would need a Line2D node added to the overlay
	# For now, just log it
	print("Debug: Connection %s -> %s" % [p1.province_name, p2.province_name])

func toggle_visibility() -> void:
	visible = not visible

func _input(event):
	if not OS.is_debug_build():
		return
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F12:
			toggle_visibility()
