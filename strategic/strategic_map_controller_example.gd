class_name StrategicMapController
extends Node2D

## Example controller showing how to integrate ProvinceManager with your game
## Attach this to your main strategic map scene

@onready var province_manager: ProvinceManager = $ProvinceManager
@onready var sidebar: GameSidebar = $CanvasLayer/GameSidebar
@onready var visual_map: Sprite2D = $VisualMap

# Visual feedback nodes
@onready var selection_indicator: Sprite2D = $SelectionIndicator
@onready var hover_indicator: Sprite2D = $HoverIndicator

var selected_province_id: int = -1

func _ready():
	print("=== STRATEGIC MAP CONTROLLER INITIALIZING ===")
	
	# Connect to province manager signals
	if province_manager:
		province_manager.province_selected.connect(_on_province_selected)
		province_manager.province_hovered.connect(_on_province_hovered)
		province_manager.province_deselected.connect(_on_province_deselected)
	else:
		push_error("ProvinceManager not found!")
	
	# Hide indicators initially
	if selection_indicator:
		selection_indicator.visible = false
	if hover_indicator:
		hover_indicator.visible = false
	
	print("=== STRATEGIC MAP CONTROLLER READY ===")


func _process(_delta):
	# Update hover detection
	if province_manager:
		province_manager.update_hover()


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_left_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_handle_right_click()


func _handle_left_click():
	"""Handle province selection on left click"""
	if not province_manager:
		return
	
	province_manager.handle_click()


func _handle_right_click():
	"""Handle context menu or secondary action on right click"""
	if selected_province_id == -1:
		return
	
	# Show context menu for selected province
	# (Attack, Move, Info, etc.)
	_show_context_menu()


func _on_province_selected(province_id: int, data: Dictionary):
	"""Called when a province is selected"""
	selected_province_id = province_id
	
	print("Selected province: ", data.get("name", "Unknown"))
	
	# Update sidebar
	if sidebar:
		sidebar.update_for_province(province_id, data)
	
	# Show selection indicator
	_update_selection_indicator(province_id)
	
	# Emit to other systems (turn manager, etc.)
	EventBus.emit_signal("province_selected", province_id)


func _on_province_hovered(province_id: int, data: Dictionary):
	"""Called when mouse hovers over a province"""
	# Update hover indicator
	_update_hover_indicator(province_id)
	
	# Optional: Show tooltip
	# _show_tooltip(data)


func _on_province_deselected():
	"""Called when mouse leaves all provinces"""
	if hover_indicator:
		hover_indicator.visible = false


func _update_selection_indicator(province_id: int):
	"""Move the selection indicator to the selected province"""
	if not selection_indicator:
		return
	
	# Get province center position from data
	var province_pos = _get_province_center(province_id)
	
	selection_indicator.position = province_pos
	selection_indicator.visible = true
	
	# Optional: Add animation
	var tween = create_tween()
	tween.tween_property(selection_indicator, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(selection_indicator, "scale", Vector2(1.0, 1.0), 0.1)


func _update_hover_indicator(province_id: int):
	"""Move hover indicator to follow mouse"""
	if not hover_indicator:
		return
	
	hover_indicator.position = get_global_mouse_position()
	hover_indicator.visible = true


func _get_province_center(province_id: int) -> Vector2:
	"""Calculate center position of a province (for indicator placement)"""
	# This is a placeholder - in a real implementation, you'd either:
	# 1. Pre-calculate centers and store in province data
	# 2. Scan the data map to find the bounding box center
	# 3. Use a separate "center points" image
	
	# For now, return mouse position as fallback
	return get_global_mouse_position()


func _show_context_menu():
	"""Show right-click context menu for selected province"""
	print("Showing context menu for province ", selected_province_id)
	# Implement your context menu UI here


func get_selected_province() -> Dictionary:
	"""Get data for currently selected province"""
	if selected_province_id == -1 or not province_manager:
		return {}
	
	return province_manager.get_selected_province_data()


# Public API for other systems

func can_attack_target(target_province_id: int) -> bool:
	"""Check if we can attack the target province from our selection"""
	if selected_province_id == -1:
		return false
	
	var selected_data = get_selected_province()
	if selected_data.is_empty():
		return false
	
	# Check if target is a neighbor
	var neighbors = selected_data.get("neighbors", [])
	if not target_province_id in neighbors:
		return false
	
	# Check ownership (can't attack own provinces)
	var target_data = province_manager._get_province_data_from_id(target_province_id)
	if target_data.get("owner_id") == selected_data.get("owner_id"):
		return false
	
	return true


func get_province_owner(province_id: int) -> int:
	"""Get the family ID that owns a province"""
	if not province_manager:
		return -1
	
	# This would need to be added to ProvinceManager
	# For now, return from stored data
	return -1


# Debug functions

func _unhandled_key_input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				# Toggle data map visibility for debugging
				if province_manager:
					province_manager.toggle_data_map_visibility()
			KEY_F2:
				# Print debug info
				_print_debug_info()


func _print_debug_info():
	"""Print debug information about the province system"""
	print("\n=== PROVINCE SYSTEM DEBUG ===")
	print("Selected province: ", selected_province_id)
	
	if province_manager:
		print("Total provinces: ", province_manager.get_province_count())
		
		var mouse_color = province_manager._get_data_map_pixel_at_mouse()
		print("Color at mouse: ", mouse_color)
	
	print("============================\n")
