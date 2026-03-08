class_name CombatCalculator

const UNIT_STATS_PATH = "res://resources/tactical/unit_stats.json"

var unit_stats: Dictionary = {}
var formation_modifiers: Dictionary = {}
var terrain_modifiers: Dictionary = {}

func _init():
	_load_unit_stats()

func _load_unit_stats():
	var file = FileAccess.open(UNIT_STATS_PATH, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			var data = json.get_data()
			unit_stats = data.get("unit_types", {})
			formation_modifiers = data.get("formations", {})
			terrain_modifiers = data.get("terrain_modifiers", {})
		else:
			push_error("Failed to parse unit stats JSON")
	else:
		push_error("Failed to load unit stats from: " + UNIT_STATS_PATH)

func calculate_damage(attacker, defender, formation: String = "normal") -> int:
	var attacker_stats = get_unit_stats(attacker.unit_type)
	var defender_stats = get_unit_stats(defender.unit_type)
	
	# Base damage calculation
	var base_atk = attacker_stats.get("attack", 5)
	var base_def = defender_stats.get("defense", 3)
	var unit_bonus = attacker_stats.get("bonus", 0)
	
	# Lord stats contribution (if available)
	var lord_atk_bonus = 0
	var lord_def_bonus = 0
	if attacker.lord:
		lord_atk_bonus = attacker.lord.attack_rating / 10
	if defender.lord:
		lord_def_bonus = defender.lord.defense_rating / 10
	
	# Formation multiplier
	var formation_mult = get_formation_multiplier(formation)
	
	# Calculate raw damage
	var raw_damage = (base_atk + unit_bonus + lord_atk_bonus) - (base_def + lord_def_bonus)
	raw_damage = max(1, raw_damage)  # Minimum 1 damage
	
	# Apply formation bonus
	var damage = int(raw_damage * formation_mult)
	
	# Random variance (0.9 - 1.1)
	var variance = randf_range(0.9, 1.1)
	damage = int(damage * variance)
	
	# Minimum 1 damage
	return max(1, damage)

func calculate_magic_damage(attacker, defender) -> int:
	var attacker_stats = get_unit_stats(attacker.unit_type)
	var defender_stats = get_unit_stats(defender.unit_type)
	
	# Magic attacks ignore some defense
	var base_atk = attacker_stats.get("attack", 10) + 5  # Magic bonus
	var base_def = int(defender_stats.get("defense", 3) * 0.5)  # Defense reduced vs magic
	var unit_bonus = attacker_stats.get("bonus", 0)
	
	var lord_atk_bonus = 0
	if attacker.lord:
		lord_atk_bonus = attacker.lord.attack_rating / 10
	
	var raw_damage = (base_atk + unit_bonus + lord_atk_bonus) - base_def
	raw_damage = max(2, raw_damage)
	
	# Magic has higher variance (0.8 - 1.3)
	var variance = randf_range(0.8, 1.3)
	var damage = int(raw_damage * variance)
	
	return max(2, damage)

func get_unit_stats(unit_type: String) -> Dictionary:
	return unit_stats.get(unit_type, {
		"attack": 5,
		"defense": 3,
		"speed": 5,
		"bonus": 0,
		"can_use_magic": false
	})

func get_formation_multiplier(formation: String) -> float:
	var mod = formation_modifiers.get(formation, {})
	return mod.get("damage_multiplier", 1.0)

func get_formation_description(formation: String) -> String:
	var mod = formation_modifiers.get(formation, {})
	return mod.get("description", "Standard engagement")

func can_use_magic(unit_type: String) -> bool:
	var stats = get_unit_stats(unit_type)
	return stats.get("can_use_magic", false)

func is_large_unit(unit_type: String) -> bool:
	var stats = get_unit_stats(unit_type)
	return stats.get("is_large", false)

func get_terrain_modifier(terrain: String) -> Dictionary:
	return terrain_modifiers.get(terrain, {
		"defense_bonus": 0,
		"speed_bonus": 0
	})

func calculate_initiative(unit, formation: String) -> int:
	var stats = get_unit_stats(unit.unit_type)
	var base_speed = stats.get("speed", 5)
	
	var formation_data = formation_modifiers.get(formation, {})
	var initiative_bonus = formation_data.get("initiative_bonus", 0)
	
	return base_speed + initiative_bonus
