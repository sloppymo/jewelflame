extends Node

# Turn management state
var current_family_index: int = 0
var families_order: Array[String] = ["blanche", "lyle", "coryll"]
var current_month: int = 1
var current_year: int = 1
var player_family_id: String = "blanche"

# Turn phase tracking
var is_player_turn: bool = true
var turn_active: bool = false

func _ready():
	# Initialize turn state
	print("TurnManager initialized")

# Core turn management functions
func get_current_family() -> String:
	return families_order[current_family_index]

func advance_turn():
	# Reset exhaustion for current family
	reset_family_exhaustion(get_current_family())
	
	# Move to next family
	current_family_index = (current_family_index + 1) % families_order.size()
	
	# Check for month/year advancement
	if current_family_index == 0:
		advance_month()
	
	# Check if it's player turn
	is_player_turn = get_current_family() == player_family_id
	
	# Emit turn change signal
	EventBus.TurnEnded.emit(current_month, current_year)
	
	print("Turn advanced to: ", get_current_family(), " (Month: ", current_month, ", Year: ", current_year, ")")

func advance_month():
	current_month += 1
	if current_month > 12:
		current_month = 1
		current_year += 1
	
	# Process monthly systems
	print("Processing monthly upkeep")
	
	# September harvest
	if current_month == 9 and GameState:
		print("Processing September harvest")
	
	# Random events (10% chance)
	if randf() < 0.1:
		print("Triggering random events")

func reset_family_exhaustion(family_id: String):
	# This would reset province exhaustion for the specified family
	# Implementation depends on which game state system we're using
	if GameState:
		for province in GameState.provinces.values():
			if province.owner_id == family_id:
				province.is_exhausted = false
				if EventBus:
					EventBus.ProvinceExhausted.emit(province.id, false)

# AI personality management
static func get_family_ai_personality(family_id: String) -> AIPersonalities.PersonalityType:
	match family_id:
		"lyle": return AIPersonalities.PersonalityType.AGGRESSIVE
		"coryll": return AIPersonalities.PersonalityType.OPPORTUNISTIC
		"blanche": return AIPersonalities.PersonalityType.DEFENSIVE
		_: return AIPersonalities.PersonalityType.TACTICAL

# Turn state queries
func is_turn_active() -> bool:
	return turn_active

func set_turn_active(active: bool):
	turn_active = active

func get_turn_info() -> Dictionary:
	return {
		"current_family": get_current_family(),
		"is_player_turn": is_player_turn,
		"month": current_month,
		"year": current_year,
		"turn_active": turn_active
	}

# Save/Load support
func get_save_data() -> Dictionary:
	return {
		"current_family_index": current_family_index,
		"families_order": families_order.duplicate(),
		"current_month": current_month,
		"current_year": current_year,
		"player_family_id": player_family_id,
		"is_player_turn": is_player_turn,
		"turn_active": turn_active
	}

func load_save_data(data: Dictionary):
	current_family_index = data.get("current_family_index", 0)
	families_order = data.get("families_order", ["blanche", "lyle", "coryll"])
	current_month = data.get("current_month", 1)
	current_year = data.get("current_year", 1)
	player_family_id = data.get("player_family_id", "blanche")
	is_player_turn = data.get("is_player_turn", true)
	turn_active = data.get("turn_active", false)
