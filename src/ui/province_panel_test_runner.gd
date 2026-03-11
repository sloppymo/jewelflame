## Jewelflame/Tests/ProvincePanelTestRunner
## Automated test runner for ProvincePanel
## Attach this to a Node in any scene to run tests

extends Node

@onready var test_script = preload("res://src/ui/province_panel_test.gd")

func _ready() -> void:
	print("\n========================================")
	print("  PROVINCE PANEL TEST RUNNER")
	print("========================================\n")
	
	var tester = test_script.new()
	add_child(tester)
	await tester.run_tests()
	
	print("\n========================================")
	print("  TEST RUN COMPLETE")
	print("========================================\n")
	
	# Keep the scene open for visual inspection
	print("Scene remains open for visual inspection.")
	print("Check the Output panel for detailed results.")
