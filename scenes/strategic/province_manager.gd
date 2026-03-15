extends Node2D

const ProvinceData = preload("res://resources/data_classes/province_data.gd")
const FactionData = preload("res://resources/data_classes/faction_data.gd")
const ProvinceNode = preload("res://scenes/strategic/province_node.gd")

@export var province_scene: PackedScene = preload("res://scenes/strategic/province_node.tscn")

@onready var container: Node2D = $ProvinceContainer if has_node("ProvinceContainer") else self
@onready var connections: Node2D = $Connections if has_node("Connections") else null

var province_nodes: Dictionary[StringName, ProvinceNode] = {}

func _ready():
	if GameState == null:
		push_error("ProvinceManager: GameState not available")
		return
	
	initialize_provinces()
	draw_connections()

func initialize_provinces():
	# Clear existing
	for node in container.get_children():
		node.queue_free()
	province_nodes.clear()
	
	# Create province nodes
	for id in GameState.provinces:
		var data: ProvinceData = GameState.provinces[id]
		var node: ProvinceNode = province_scene.instantiate()
		node.data = data
		container.add_child(node)
		
		node.province_selected.connect(_on_province_selected)
		node.province_hovered.connect(_on_province_hovered)
		
		province_nodes[id] = node
	
	print("ProvinceManager: Initialized %d provinces" % province_nodes.size())

func draw_connections():
	if connections == null:
		return
	
	# Clear existing connections
	for child in connections.get_children():
		child.queue_free()
	
	# Draw lines between adjacent provinces
	for id in GameState.provinces:
		var data: ProvinceData = GameState.provinces[id]
		var from_node := get_province_node(id)
		if from_node == null:
			continue
		
		for adj_id in data.adjacent_province_ids:
			# Only draw each connection once (when id < adj_id)
			if id >= adj_id:
				continue
			
			var to_node := get_province_node(adj_id)
			if to_node == null:
				continue
			
			var line := Line2D.new()
			line.points = [from_node.position, to_node.position]
			line.default_color = Color(0.5, 0.5, 0.5, 0.3)
			line.width = 2.0
			connections.add_child(line)

func get_province_node(id: StringName) -> ProvinceNode:
	return province_nodes.get(id)

func highlight_valid_targets(source_id: StringName, action: String):
	clear_highlights()
	
	if not GameState.provinces.has(source_id):
		return
	
	var source: ProvinceData = GameState.provinces[source_id]
	var current_faction := GameState.get_current_faction()
	
	for adj_id in source.adjacent_province_ids:
		if not province_nodes.has(adj_id):
			continue
		
		var target: ProvinceData = GameState.provinces[adj_id]
		var is_valid := false
		
		match action:
			"move":
				is_valid = current_faction.owns_province(adj_id)
			"attack":
				is_valid = not current_faction.owns_province(adj_id) and target.has_owner()
			"scout":
				is_valid = true
		
		if is_valid:
			var node := province_nodes[adj_id]
			node.set_highlight_visible(true)

func clear_highlights():
	for node in province_nodes.values():
		node.set_highlight_visible(false)

func _on_province_selected(node: ProvinceNode):
	print("Province selected: %s" % node.data.id)

func _on_province_hovered(node: ProvinceNode, is_hovered: bool):
	pass  # Could show tooltip

func pulse_province(id: StringName):
	if province_nodes.has(id):
		province_nodes[id].pulse_highlight()

func refresh_all_province_colors():
	"""Refresh colors for all provinces - call after ownership changes"""
	for node in province_nodes.values():
		node._update_owner_color()
		node._update_label()

func get_provinces_by_owner(faction_id: StringName) -> Array[ProvinceNode]:
	"""Get all province nodes owned by a faction"""
	var result: Array[ProvinceNode] = []
	for node in province_nodes.values():
		if node.data and node.data.owner_faction_id == faction_id:
			result.append(node)
	return result

func get_ownership_summary() -> Dictionary[StringName, int]:
	"""Get count of provinces per faction"""
	var summary: Dictionary[StringName, int] = {}
	for node in province_nodes.values():
		if node.data:
			var owner = node.data.owner_faction_id
			if not summary.has(owner):
				summary[owner] = 0
			summary[owner] += 1
	return summary
