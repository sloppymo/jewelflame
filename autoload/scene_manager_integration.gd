extends Node

# Scene Manager - Handles switching between Strategic and Tactical scenes

@onready var strategic_map = $StrategicMap
@onready var tactical_battle = $TacticalBattle

func _ready():
	print("Scene Manager initialized")
	
	# Connect to battle request signal
	EventBus.RequestTacticalBattle.connect(_on_request_tactical_battle)
	EventBus.TacticalBattleCompleted.connect(_on_tactical_battle_completed)
	
	# Start with strategic map visible
	_show_strategic()

func _on_request_tactical_battle(battle_data: Dictionary):
	print("Scene Manager: Switching to tactical battle")
	_show_tactical(battle_data)

func _on_tactical_battle_completed(result: Dictionary):
	print("Scene Manager: Battle completed, returning to strategic")
	_show_strategic()

func _show_strategic():
	strategic_map.visible = true
	strategic_map.process_mode = Node.PROCESS_MODE_INHERIT
	
	if tactical_battle:
		tactical_battle.visible = false
		tactical_battle.process_mode = Node.PROCESS_MODE_DISABLED

func _show_tactical(battle_data: Dictionary = {}):
	strategic_map.visible = false
	strategic_map.process_mode = Node.PROCESS_MODE_DISABLED
	
	if tactical_battle:
		tactical_battle.visible = true
		tactical_battle.process_mode = Node.PROCESS_MODE_INHERIT
		
		# Pass battle data if the scene supports it
		if tactical_battle.has_method("setup_battle"):
			tactical_battle.setup_battle(battle_data)
