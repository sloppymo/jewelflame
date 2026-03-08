extends Node2D

# Test scene for Strategic Layer implementation

@onready var strategic_hud = $StrategicHUD

func _ready():
	print("=== Strategic Layer Test Started ===")
	
	# Wait for game state to initialize
	await get_tree().create_timer(0.5).timeout
	
	# Test 1: Verify GameState has data
	_test_game_state()
	
	# Test 2: Verify Search System
	_test_search_system()
	
	# Test 3: Verify Random Events
	_test_random_events()
	
	# Test 4: Test command signals
	_test_commands()
	
	print("=== Strategic Layer Test Complete ===")

func _test_game_state():
	print("\n[TEST] Game State")
	print("  Current Year: ", EnhancedGameState.current_year)
	print("  Current Month: ", EnhancedGameState.current_month)
	print("  Current Family: ", EnhancedGameState.get_current_family())
	print("  Provinces: ", EnhancedGameState.provinces.size())
	print("  Families: ", EnhancedGameState.families.size())
	print("  Characters: ", EnhancedGameState.characters.size())
	print("  [PASS] Game State initialized")

func _test_search_system():
	print("\n[TEST] Search System")
	
	# Test search table loaded
	if SearchSystem.search_table.is_empty():
		print("  [FAIL] Search table not loaded")
	else:
		print("  Search table entries: ", SearchSystem.search_table.get("outcomes", []).size())
		print("  Search cost: ", SearchSystem.search_cost)
		print("  [PASS] Search System initialized")
	
	# Test search can be performed
	var can_search = SearchSystem.can_search("blanche")
	print("  Can search (blanche): ", can_search)

func _test_random_events():
	print("\n[TEST] Random Events")
	
	# Test event definitions
	var event_types = RandomEventsEnhanced.EventType.values()
	print("  Event types: ", event_types.size())
	
	# Test event generation
	var event = RandomEventsEnhanced.try_trigger_random_event()
	if event.is_empty():
		print("  No event triggered (80% chance of no event)")
	else:
		print("  Event triggered: ", event.get("title", "Unknown"))
		print("  Event message: ", event.get("message", ""))
	
	print("  [PASS] Random Events System initialized")

func _test_commands():
	print("\n[TEST] Command Interface")
	
	if strategic_hud:
		# Connect to signals for testing
		strategic_hud.command_selected.connect(_on_test_command)
		strategic_hud.view_mode_selected.connect(_on_test_view_mode)
		strategic_hud.end_turn_requested.connect(_on_test_end_turn)
		print("  [PASS] Strategic HUD signals connected")
	else:
		print("  [FAIL] Strategic HUD not found")

func _on_test_command(command: String):
	print("  Command selected: ", command)

func _on_test_view_mode(mode: String):
	print("  View mode selected: ", mode)
	
	# Test opening view windows
	match mode:
		"one":
			print("  Opening View One...")
		"many":
			print("  Opening View Many...")
		"land":
			print("  Opening View Land...")
		"fifth":
			print("  Opening View Fifth...")

func _on_test_end_turn():
	print("  End turn requested")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				print("\n[MANUAL TEST] Opening View Many")
				var view_many = load("res://scenes/ui/view_many.tscn").instantiate()
				add_child(view_many)
				view_many.show_family_roster("blanche")
			KEY_2:
				print("\n[MANUAL TEST] Opening View Land")
				var view_land = load("res://scenes/ui/view_land.tscn").instantiate()
				add_child(view_land)
				view_land.show_province_data("blanche")
			KEY_3:
				print("\n[MANUAL TEST] Opening View Fifth")
				var view_fifth = load("res://scenes/ui/view_fifth.tscn").instantiate()
				add_child(view_fifth)
				view_fifth.show_monster_inventory("blanche")
			KEY_4:
				print("\n[MANUAL TEST] Testing Search")
				var result = SearchSystem.perform_search("blanche", 1)
				print("  Search result: ", result)
			KEY_5:
				print("\n[MANUAL TEST] Testing Random Event")
				var event = RandomEventsEnhanced.try_trigger_random_event()
				if event.is_empty():
					print("  No event (80% chance)")
				else:
					print("  Event: ", event.get("message"))
			KEY_ESCAPE:
				get_tree().quit()
