class_name AITactical extends RefCounted

# AI controller for tactical battles - Returns action arrays instead of executing

const CombatCalculator = preload("res://scripts/tactical/combat_calculator.gd")

enum AIPersonality {
	AGGRESSIVE,
	DEFENSIVE,
	BALANCED,
	COWARDLY
}

var personality: AIPersonality = AIPersonality.BALANCED
var retreat_threshold: float = 0.2
var combat_calculator = null  # CombatCalculator instance

func _init(ai_personality: String = "balanced", calculator = null):
	combat_calculator = calculator
	match ai_personality:
		"aggressive":
			personality = AIPersonality.AGGRESSIVE
			retreat_threshold = 0.2
		"defensive":
			personality = AIPersonality.DEFENSIVE
			retreat_threshold = 0.5
		"cowardly":
			personality = AIPersonality.COWARDLY
			retreat_threshold = 0.75
		_:
			personality = AIPersonality.BALANCED
			retreat_threshold = 0.2

# Calculate all AI actions for a turn - returns array of action dictionaries
func calculate_turn(ai_units: Array, enemy_units: Array) -> Array:
	var actions = []
	
	# Check global retreat condition first
	var total_ai_troops = _count_total_troops(ai_units)
	var total_enemy_troops = _count_total_troops(enemy_units)
	
	if total_ai_troops == 0:
		return actions
	
	var troop_ratio = float(total_ai_troops) / float(total_enemy_troops + 1)
	
	# If should retreat, all units retreat
	if troop_ratio < retreat_threshold:
		for unit in ai_units:
			if unit.is_alive():
				actions.append({"type": "retreat", "unit": unit})
		return actions
	
	# Generate actions for each alive unit
	for unit in ai_units:
		if not unit.is_alive():
			continue
		
		var action = _decide_unit_action(unit, ai_units, enemy_units, troop_ratio)
		actions.append(action)
	
	return actions

func _decide_unit_action(unit, ai_units: Array, enemy_units: Array, troop_ratio: float) -> Dictionary:
	match personality:
		AIPersonality.AGGRESSIVE:
			return _aggressive_action(unit, enemy_units)
		AIPersonality.DEFENSIVE:
			return _defensive_action(unit, enemy_units, troop_ratio)
		AIPersonality.COWARDLY:
			return _cowardly_action(unit, enemy_units, troop_ratio)
		_:
			return _balanced_action(unit, enemy_units)

func _aggressive_action(unit, enemy_units: Array) -> Dictionary:
	# Aggressive: Always attack, never use fence, target weakest
	var target = _find_weakest_unit(enemy_units)
	
	if target:
		var use_magic = combat_calculator.can_use_magic(unit.unit_type) if combat_calculator else false
		return {
			"type": "attack",
			"unit": unit,
			"target": target,
			"use_magic": use_magic
		}
	
	return {"type": "wait", "unit": unit}

func _defensive_action(unit, enemy_units: Array, troop_ratio: float) -> Dictionary:
	# Defensive: Use fence/break, target strongest threats, retreat earlier
	
	# 50% chance to use fence if mage and no barrier
	if combat_calculator and combat_calculator.can_use_magic(unit.unit_type):
		if not unit.has_barrier and randf() < 0.5:
			return {"type": "fence", "unit": unit}
	
	# Target strongest enemy (most threatening)
	var target = _find_strongest_unit(enemy_units)
	
	if target:
		return {"type": "attack", "unit": unit, "target": target, "use_magic": false}
	
	return {"type": "wait", "unit": unit}

func _cowardly_action(unit, enemy_units: Array, troop_ratio: float) -> Dictionary:
	# Cowardly: Fence always if mage, only attack if safe, use break to escape
	
	# Always fence if mage without barrier
	if combat_calculator and combat_calculator.can_use_magic(unit.unit_type):
		if not unit.has_barrier:
			return {"type": "fence", "unit": unit}
	
	# Only attack if we significantly outnumber
	if troop_ratio > 1.5:
		var target = _find_weakest_unit(enemy_units)
		if target:
			return {"type": "attack", "unit": unit, "target": target, "use_magic": false}
	
	# Otherwise wait or try to use break
	if randf() < 0.3:
		return {"type": "break", "unit": unit}
	
	return {"type": "wait", "unit": unit}

func _balanced_action(unit, enemy_units: Array) -> Dictionary:
	# Balanced: Smart target selection, occasional fence for mages
	
	# Mages use magic attacks
	if combat_calculator and combat_calculator.can_use_magic(unit.unit_type):
		var target = _find_weakest_unit(enemy_units)
		if target:
			return {"type": "attack", "unit": unit, "target": target, "use_magic": true}
	
	# Regular units attack weakest
	var target = _find_weakest_unit(enemy_units)
	if target:
		return {"type": "attack", "unit": unit, "target": target, "use_magic": false}
	
	return {"type": "wait", "unit": unit}

func _find_weakest_unit(units: Array) :
	var weakest = null
	var min_count = 999999
	
	for unit in units:
		if unit.is_alive() and unit.count < min_count:
			min_count = unit.count
			weakest = unit
	
	return weakest

func _find_strongest_unit(units: Array) :
	var strongest = null
	var max_count = 0
	
	for unit in units:
		if unit.is_alive() and unit.count > max_count:
			max_count = unit.count
			strongest = unit
	
	return strongest

func _count_total_troops(units: Array) -> int:
	var total = 0
	for unit in units:
		if unit.is_alive():
			total += unit.count
	return total

func should_retreat(ai_units: Array, enemy_units: Array) -> bool:
	var total_ai = _count_total_troops(ai_units)
	var total_enemy = _count_total_troops(enemy_units)
	
	if total_ai == 0:
		return true
	
	var ratio = float(total_ai) / float(total_enemy + 1)
	return ratio < retreat_threshold

func get_formation_bonus() -> float:
	# Return formation multiplier based on personality
	match personality:
		AIPersonality.AGGRESSIVE:
			return 1.0  # Normal formation, rely on pure damage
		AIPersonality.DEFENSIVE:
			return 1.0
		AIPersonality.COWARDLY:
			return 0.9  # Slight penalty due to caution
		_:
			return 1.0
