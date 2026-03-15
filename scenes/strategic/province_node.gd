class_name ProvinceNode extends Area2D

const ProvinceData = preload("res://resources/data_classes/province_data.gd")
const FactionData = preload("res://resources/data_classes/faction_data.gd")

@export var data: ProvinceData
@export var highlight_color: Color = Color(1.0, 0.8, 0.0, 0.5)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var highlight: Sprite2D = $HighlightSprite
@onready var label: Label = $Label

signal province_selected(node: ProvinceNode)
signal province_hovered(node: ProvinceNode, is_hovered: bool)

func _ready():
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Update visual based on data
	_update_visual()
	
	# Debug: Show ID
	if label:
		label.text = data.id if data else ""
		label.visible = OS.is_debug_build()
	
	# Connect to GameState for ownership updates
	if GameState:
		GameState.province_ownership_changed.connect(_on_ownership_changed)

func _update_visual():
	if not data:
		return
	
	# Update position
	position = data.map_position
	
	# Update highlight color based on owner
	_update_highlight_color()

func _update_highlight_color():
	if not data or not highlight:
		return
	
	if data.has_owner() and GameState and GameState.factions.has(data.owner_faction_id):
		var faction: FactionData = GameState.factions[data.owner_faction_id]
		highlight.modulate = faction.color
	else:
		highlight.modulate = Color.GRAY

func _on_ownership_changed(province_id: StringName, _old_owner: StringName, _new_owner: StringName):
	if data and data.id == province_id:
		_update_highlight_color()

func _on_mouse_entered():
	if highlight:
		highlight.visible = true
	province_hovered.emit(self, true)

func _on_mouse_exited():
	if highlight:
		highlight.visible = false
	province_hovered.emit(self, false)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if GameState and GameState.is_input_enabled:
			province_selected.emit(self)
			GameState.select_province(data)

func set_highlight_visible(visible: bool) -> void:
	if highlight:
		highlight.visible = visible

func pulse_highlight() -> void:
	if not highlight:
		return
	
	var tween := create_tween()
	highlight.visible = true
	tween.tween_property(highlight, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(highlight, "scale", Vector2(1.0, 1.0), 0.2)
	tween.finished.connect(func(): highlight.visible = false)
