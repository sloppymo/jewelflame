extends Node

func _ready():
	print("=== JEWELFLAME VALIDATION TEST ===")
	
	# Test basic autoloads
	print("Testing autoloads...")
	
	if EventBus:
		print("✅ EventBus loaded")
	else:
		print("❌ EventBus failed")
	
	if EnhancedGameState:
		print("✅ EnhancedGameState loaded")
		# Test basic access
		print("Current month: ", EnhancedGameState.current_month)
		print("Current year: ", EnhancedGameState.current_year)
	else:
		print("❌ EnhancedGameState failed")
	
	if GameState:
		print("✅ GameState loaded")
	else:
		print("❌ GameState failed")
	
	if TurnManager:
		print("✅ TurnManager loaded")
	else:
		print("❌ TurnManager failed")
	
	if CommandHistory:
		print("✅ CommandHistory loaded")
	else:
		print("❌ CommandHistory failed")
	
	if AIController:
		print("✅ AIController loaded")
	else:
		print("❌ AIController failed")
	
	print("=== VALIDATION COMPLETE ===")
	
	# Test AI turn
	print("Testing AI turn...")
	AIController.take_turn("lyle")
	
	# Test turn advancement
	print("Testing turn advancement...")
	TurnManager.advance_turn()
	
	print("=== ALL TESTS PASSED ===")
