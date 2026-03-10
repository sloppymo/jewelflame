## HexForge Dynamic Loader
## Loads HexForge classes from local copy
## Connection ID: ec74b0f4-ca88-40ad-9532-084ce680ef07

class_name HexForgeLoader
extends RefCounted

# Singleton pattern
static var _instance = null

# Cached class references
var BattleController: GDScript = null
var BattleGrid: GDScript = null
var UnitManager: GDScript = null
var TurnManager: GDScript = null
var CombatEngine: GDScript = null
var AIManager: GDScript = null
var HexRenderer2D: GDScript = null
var HexCursor: GDScript = null
var RangeHighlighter: GDScript = null
var HexGrid: GDScript = null
var HexCell: GDScript = null
var HexMath: GDScript = null
var Pathfinder: GDScript = null
var LineOfSight: GDScript = null

var _loaded: bool = false

static func get_instance():
	if _instance == null:
		_instance = new()
		_instance._load_classes()
	return _instance

func _load_classes() -> void:
	if _loaded:
		return
	
	print("HexForgeLoader: Loading HexForge classes from res://hexforge/...")
	
	# Load core classes first (no dependencies)
	HexMath = load("res://hexforge/core/hex_math.gd")
	HexCell = load("res://hexforge/core/hex_cell.gd")
	HexGrid = load("res://hexforge/core/hex_grid.gd")
	
	# Load services
	Pathfinder = load("res://hexforge/services/pathfinder.gd")
	LineOfSight = load("res://hexforge/services/line_of_sight.gd")
	
	# Load rendering classes (depend on core)
	HexRenderer2D = load("res://hexforge/rendering/hex_renderer_2d.gd")
	HexCursor = load("res://hexforge/rendering/hex_cursor.gd")
	RangeHighlighter = load("res://hexforge/rendering/range_highlighter.gd")
	
	# Load battle classes (depend on core and rendering)
	BattleGrid = load("res://hexforge/battle/battle_grid.gd")
	UnitManager = load("res://hexforge/battle/unit_manager.gd")
	TurnManager = load("res://hexforge/battle/turn_manager.gd")
	CombatEngine = load("res://hexforge/battle/combat_engine.gd")
	BattleController = load("res://hexforge/battle/battle_controller.gd")
	AIManager = load("res://hexforge/battle/ai_manager.gd")
	
	# Try to load pathfinder and LOS (may be in different locations)
	if ResourceLoader.exists("res://hexforge/core/pathfinder.gd"):
		Pathfinder = load("res://hexforge/core/pathfinder.gd")
	if ResourceLoader.exists("res://hexforge/core/line_of_sight.gd"):
		LineOfSight = load("res://hexforge/core/line_of_sight.gd")
	
	_loaded = true
	print("HexForgeLoader: All classes loaded successfully")

func is_available() -> bool:
	return _loaded and BattleController != null

func create_battle_controller() -> Node:
	if BattleController == null:
		push_error("HexForgeLoader: BattleController not loaded!")
		return null
	return BattleController.new()

func create_ai_manager() -> Node:
	if AIManager == null:
		push_error("HexForgeLoader: AIManager not loaded!")
		return null
	return AIManager.new()
