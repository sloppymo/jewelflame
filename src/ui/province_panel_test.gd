## Jewelflame/Tests/ProvincePanelTest
## Unit test for ProvincePanel UI structure
## Run with: Godot Test Runner or manually in game

class_name ProvincePanelTest
extends Node

## Test results
var tests_passed := 0
var tests_failed := 0
var error_messages := []

func run_tests() -> void:
	print("=== ProvincePanel Structure Tests ===")
	
	# Create test instance
	var panel = preload("res://src/ui/province_panel.gd").new()
	add_child(panel)
	
	# Wait one frame for _ready() to execute
	await get_tree().process_frame
	
	# Run all tests
	_test_panel_background_exists(panel)
	_test_portrait_frame_exists(panel)
	_test_portrait_rect_settings(panel)
	_test_texture_filtering(panel)
	_test_resource_grid_structure(panel)
	_test_no_debug_labels(panel)
	
	# Cleanup
	panel.queue_free()
	
	# Report results
	print("\n=== Test Results ===")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)
	
	if tests_failed > 0:
		print("\nErrors:")
		for msg in error_messages:
			print("  - " + msg)
	else:
		print("\n✅ All tests passed!")

func _test_panel_background_exists(panel: ProvincePanel) -> void:
	var bg = panel.get_node_or_null("PanelBackground")
	if bg == null:
		_error("PanelBackground (NinePatchRect) not found")
		return
	
	if not bg is NinePatchRect:
		_error("PanelBackground is not a NinePatchRect")
		return
	
	# Check patch margins are set
	if bg.patch_margin_left == 0 or bg.patch_margin_top == 0:
		_error("PanelBackground patch margins not set")
		return
	
	_pass("PanelBackground exists with proper NinePatchRect settings")

func _test_portrait_frame_exists(panel: ProvincePanel) -> void:
	var frame = panel.get_node_or_null("PanelBackground/Content/MainVBox/Header/PortraitFrame")
	if frame == null:
		_error("PortraitFrame not found in expected path")
		return
	
	if not frame is NinePatchRect:
		_error("PortraitFrame is not a NinePatchRect")
		return
	
	_pass("PortraitFrame exists as NinePatchRect")

func _test_portrait_rect_settings(panel: ProvincePanel) -> void:
	var portrait = panel.get_node_or_null("PanelBackground/Content/MainVBox/Header/PortraitFrame/Portrait")
	if portrait == null:
		_error("Portrait TextureRect not found")
		return
	
	if not portrait is TextureRect:
		_error("Portrait is not a TextureRect")
		return
	
	# Check stretch mode
	if portrait.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
		_error("Portrait stretch_mode should be KEEP_ASPECT_CENTERED")
		return
	
	# Check texture filter
	if portrait.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_error("Portrait texture_filter should be TEXTURE_FILTER_NEAREST (pixel art)")
		return
	
	_pass("Portrait has correct settings (KEEP_ASPECT_CENTERED, TEXTURE_FILTER_NEAREST)")

func _test_texture_filtering(panel: ProvincePanel) -> void:
	# Check panel background
	var bg = panel.get_node_or_null("PanelBackground")
	if bg and bg.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_error("PanelBackground should use TEXTURE_FILTER_NEAREST")
		return
	
	# Check portrait frame
	var frame = panel.get_node_or_null("PanelBackground/Content/MainVBox/Header/PortraitFrame")
	if frame and frame.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_error("PortraitFrame should use TEXTURE_FILTER_NEAREST")
		return
	
	_pass("All textures use TEXTURE_FILTER_NEAREST for pixel art")

func _test_resource_grid_structure(panel: ProvincePanel) -> void:
	var grid = panel.get_node_or_null("PanelBackground/Content/MainVBox/ResourceGrid")
	if grid == null:
		_error("ResourceGrid not found")
		return
	
	if not grid is GridContainer:
		_error("ResourceGrid is not a GridContainer")
		return
	
	if grid.columns != 2:
		_error("ResourceGrid should have 2 columns")
		return
	
	# Check that labels exist
	var gold_label = grid.get_node_or_null("GoldSlot/Value")
	if gold_label == null:
		_error("GoldSlot/Value label not found")
		return
	
	_pass("ResourceGrid has correct structure (2 columns, value labels)")

func _test_no_debug_labels(panel: ProvincePanel) -> void:
	"""Ensure no debug filename labels exist."""
	
	# Check all labels in the panel
	var labels = _find_all_nodes_of_type(panel, "Label")
	
	for label in labels:
		var text = label.text.to_lower()
		# Check for filename patterns
		if ".png" in text or ".jpg" in text or ".gd" in text:
			_error("Found debug filename label: '%s'" % label.text)
			return
		# Check for partial filename fragments
		if text.length() > 0 and (text.ends_with(")") or text.begins_with("c_")):
			if label.name != "ProvinceName" and label.name != "LordName" and label.name != "Value":
				_error("Potential debug label found: '%s' (name: %s)" % [label.text, label.name])
				return
	
	_pass("No debug filename labels found")

func _find_all_nodes_of_type(node: Node, type_name: String) -> Array:
	"""Recursively find all nodes of a given type."""
	var results := []
	
	for child in node.get_children():
		if child.get_class() == type_name or child.is_class(type_name):
			results.append(child)
		results.append_array(_find_all_nodes_of_type(child, type_name))
	
	return results

func _pass(message: String) -> void:
	tests_passed += 1
	print("✅ PASS: " + message)

func _error(message: String) -> void:
	tests_failed += 1
	error_messages.append(message)
	print("❌ FAIL: " + message)
