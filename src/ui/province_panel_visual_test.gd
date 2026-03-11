## Jewelflame/Tests/ProvincePanelVisualTest
## Visual test scene for ProvincePanel
## Run this scene to see the panel rendered with test data

extends Control

func _ready() -> void:
	print("\n=== ProvincePanel Visual Test ===")
	print("Setting up test environment...")
	
	# Initialize minimal GameState if not already done
	if not GameState.is_initialized:
		_initialize_test_game_state()
	
	# Create and add the ProvincePanel
	var panel = preload("res://src/ui/province_panel.gd").new()
	panel.name = "ProvincePanel"
	panel.custom_minimum_size = Vector2(400, 600)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Find the test panel container
	var container = $TestPanel
	container.add_child(panel)
	
	# Wait for panel to initialize
	await get_tree().process_frame
	
	# Get test province and show it
	var test_province = GameState.get_province("3")
	if test_province:
		panel.show_province(test_province)
		print("✅ Panel shown with test province: " + test_province.name)
	else:
		print("❌ Test province not found")
	
	print("\n=== Visual Test Ready ===")
	print("Check the left side of the window for the panel.")
	print("Verify:")
	print("  - Purple background with gold border")
	print("  - Portrait frame (no checkered transparency)")
	print("  - No debug filename text")
	print("  - Resource icons and values")
	print("  - Unit type row")
	print("  - Dialogue text")
	print("  - Action buttons (Recruit, Develop, Attack, Info)")

func _initialize_test_game_state() -> void:
	print("Initializing test GameState...")
	
	# Create test factions
	GameState.factions = {
		"coryll": {
			"id": "coryll",
			"name": "House Coryll",
			"leader_name": "Lars",
			"color": Color("#2a6b3a"),
			"gold": 500
		},
		"blanche": {
			"id": "blanche", 
			"name": "House Blanche",
			"leader_name": "Elara",
			"color": Color("#1a3a7a"),
			"gold": 600
		}
	}
	
	# Create test provinces
	var province_script = preload("res://src/strategic/province.gd")
	
	var province3 = province_script.new()
	province3.id = "3"
	province3.name = "Petaria"
	province3.owner_faction = "coryll"
	province3.terrain = "plains"
	province3.agriculture_level = 2
	province3.connected_to = ["2", "4"]
	
	GameState.provinces = {
		"3": province3
	}
	
	GameState.player_faction = "coryll"
	GameState.is_initialized = true
	
	print("✅ Test GameState initialized")
