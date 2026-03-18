class_name FormationController
extends Node

## Controls formation state machine for a general
## Dragon Force formations: Melee, Standby, Advance, Retreat

# Formation enum - mirrors General.Formation for compatibility
const Formation = General.Formation

signal formation_changed(new_formation: Formation)
signal formation_icon_requested(icon_type: String)

var current_formation: Formation = Formation.ADVANCE
var formation_descriptions: Dictionary = {
	Formation.MELEE: "Aggressive swarm - chase and attack enemies",
	Formation.STANDBY: "Defensive wall - hold position and counter-attack",
	Formation.ADVANCE: "Move forward - engage enemies on contact",
	Formation.RETREAT: "Flee toward map edge - escape battle"
}

func _ready():
	print("FormationController ready - Initial formation: ADVANCE")

func set_formation(formation: Formation) -> bool:
	"""Change to a new formation."""
	if current_formation == formation:
		return false
	
	current_formation = formation
	formation_changed.emit(formation)
	
	print("Formation changed to: ", _get_formation_name(formation))
	return true

func get_formation() -> Formation:
	return current_formation

func get_formation_name() -> String:
	return _get_formation_name(current_formation)

func get_formation_description() -> String:
	return formation_descriptions.get(current_formation, "Unknown")

func _get_formation_name(formation: Formation) -> String:
	match formation:
		Formation.MELEE: return "MELEE"
		Formation.STANDBY: return "STANDBY"
		Formation.ADVANCE: return "ADVANCE"
		Formation.RETREAT: return "RETREAT"
		_: return "UNKNOWN"

func get_formation_icon() -> String:
	"""Get icon name for current formation."""
	match current_formation:
		Formation.MELEE: return "sword"
		Formation.STANDBY: return "shield"
		Formation.ADVANCE: return "arrow_up"
		Formation.RETREAT: return "arrow_down"
		_: return "unknown"

func get_behavior_description() -> String:
	"""Get a detailed description of current formation behavior."""
	match current_formation:
		Formation.MELEE:
			return "Troops swarm aggressively. General will chase enemies and attack on contact."
		Formation.STANDBY:
			return "Troops form defensive wall. General holds position and only attacks when enemy is very close."
		Formation.ADVANCE:
			return "Troops advance in arrow formation. General moves forward and engages enemies."
		Formation.RETREAT:
			return "Troops scatter behind general. General flees toward the nearest map edge."
		_:
			return "Unknown formation behavior"
