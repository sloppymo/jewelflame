class_name ProvinceNode extends Area2D

const ProvinceData = preload("res://resources/data_classes/province_data.gd")
const FactionData = preload("res://resources/data_classes/faction_data.gd")

@export var data: ProvinceData
@export var base_color: Color = Color(0.7, 0.7, 0.8)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var highlight: Sprite2D = $HighlightSprite
@onready var label: Label = $Label
@onready var owner_indicator: ColorRect = $OwnerIndicator

signal province_selected(node: ProvinceNode)
signal province_hovered(node: ProvinceNode, is_hovered: bool)

func _ready():
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Update visual based on data
	_update_visual()
	
	# Debug: Show ID and owner
	_update_label()
	
	# Connect to GameState for ownership updates
	if GameState:
		GameState.province_ownership_changed.connect(_on_ownership_changed)

func _update_visual():
	if not data:
		return
	
	# Update position
	position = data.map_position
	
	# Update colors based on owner
	_update_owner_color()

func _update_owner_color():
	if not data or not sprite:
		return
	
	if data.has_owner() and GameState and GameState.factions.has(data.owner_faction_id):
		var faction: FactionData = GameState.factions[data.owner_faction_id]
		# Set main sprite to faction color (darker for base)
		sprite.modulate = faction.color.darkened(0.3)
		# Set highlight to faction color (brighter)
		if highlight:
			highlight.modulate = faction.color.lightened(0.2)
		# Update owner indicator
		if owner_indicator:
			owner_indicator.color = faction.color
			owner_indicator.visible = true
	else:
		# No owner - gray/neutral
		sprite.modulate = Color(0.5, 0.5, 0.55)
		if highlight:
			highlight.modulate = Color.GRAY
		if owner_indicator:
			owner_indicator.visible = false

func _update_label():
	if not label or not data:
		return
	
	var display_text = data.id
	
	# Show owner abbreviation in label
	if data.has_owner():
		var owner_short = data.owner_faction_id.substr(0, 1).to_upper()
		display_text += " [" + owner_short + "]"
	
	label.text = display_text
	label.visible = true  # Always show, not just debug

func _on_ownership_changed(province_id: StringName, old_owner: StringName, new_owner: StringName):
	if data and data.id == province_id:
		_update_owner_color()
		_update_label()
		
		# Flash effect on ownership change
		_flash_ownership_change(old_owner, new_owner)

func _flash_ownership_change(old_owner: StringName, new_owner: StringName):
	# Brief flash to show ownership changed
	if not sprite:
		return
	
	var tween = create_tween()
	var original_modulate = sprite.modulate
	
	# Flash white
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	# Then to new color
	tween.tween_callback(func(): 
		_update_owner_color()
		pulse_highlight()
	)

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
	tween.tween_property(highlight, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(highlight, "scale", Vector2(1.0, 1.0), 0.15)
	tween.finished.connect(func(): highlight.visible = false)
