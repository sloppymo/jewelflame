class_name DragonForceAI
extends Node

## Real-time AI for enemy generals in Dragon Force battles
## Handles formation switching, spell timing, and tactical decisions

enum Personality { AGGRESSIVE, DEFENSIVE, BALANCED, OPPORTUNISTIC }
enum Tactic { ATTACK, DEFEND, FLANK, RETREAT, CAST_SPELL }

@export var personality: Personality = Personality.BALANCED
@export var reaction_time: float = 1.0  # Seconds between AI decisions

var controlled_general: General = null
var current_tactic: Tactic = Tactic.ATTACK
var decision_timer: float = 0.0
var target_general: General = null

# AI state tracking
var last_hp_percent: float = 1.0
var last_troop_percent: float = 1.0
var spell_cast_recently: bool = false
var spell_cast_timer: float = 0.0

func _ready():
	print("DragonForceAI ready - Personality: ", _get_personality_name())

func setup(general: General):
	"""Set up AI to control a specific general."""
	controlled_general = general
	
	# Determine personality based on class
	if controlled_general:
		match controlled_general.general_class:
			General.GeneralClass.WARRIOR:
				personality = Personality.AGGRESSIVE
			General.GeneralClass.MAGE:
				personality = Personality.DEFENSIVE
			General.GeneralClass.ROGUE:
				personality = Personality.OPPORTUNISTIC
		
		# Connect to signals
		controlled_general.troops_changed.connect(_on_troops_changed)
		controlled_general.spell_cast.connect(_on_spell_cast)

func _process(delta):
	if not controlled_general or controlled_general.current_state == General.State.DEAD:
		return
	
	# Update timers
	decision_timer += delta
	if spell_cast_recently:
		spell_cast_timer += delta
		if spell_cast_timer > 5.0:
			spell_cast_recently = false
	
	# Make decisions periodically
	if decision_timer >= reaction_time:
		decision_timer = 0.0
		_make_decision()
	
	# Execute current tactic
	_execute_tactic(delta)

func _make_decision():
	"""Main AI decision making."""
	if not controlled_general:
		return
	
	# Find best target
	_find_target()
	
	# Calculate current situation
	var hp_percent = float(controlled_general.current_hp) / controlled_general.max_hp
	var troop_percent = float(controlled_general.current_troops) / controlled_general.max_troops
	var mp_percent = float(controlled_general.current_mp) / controlled_general.max_mp
	
	# Personality-based decision
	match personality:
		Personality.AGGRESSIVE:
			_decision_aggressive(hp_percent, troop_percent, mp_percent)
		Personality.DEFENSIVE:
			_decision_defensive(hp_percent, troop_percent, mp_percent)
		Personality.BALANCED:
			_decision_balanced(hp_percent, troop_percent, mp_percent)
		Personality.OPPORTUNISTIC:
			_decision_opportunistic(hp_percent, troop_percent, mp_percent)
	
	# Store state for next decision
	last_hp_percent = hp_percent
	last_troop_percent = troop_percent

func _decision_aggressive(hp_percent: float, troop_percent: float, mp_percent: float):
	"""Aggressive AI: Attack constantly, use spells offensively."""
	# Always attack unless about to die
	if hp_percent < 0.2 or troop_percent < 0.1:
		current_tactic = Tactic.RETREAT
		controlled_general.set_formation(General.Formation.RETREAT)
	elif mp_percent >= 0.8 and not spell_cast_recently:
		current_tactic = Tactic.CAST_SPELL
	else:
		current_tactic = Tactic.ATTACK
		controlled_general.set_formation(General.Formation.MELEE)

func _decision_defensive(hp_percent: float, troop_percent: float, mp_percent: float):
	"""Defensive AI: Hold position, use spells to weaken enemies."""
	if hp_percent < 0.3 or troop_percent < 0.2:
		current_tactic = Tactic.RETREAT
		controlled_general.set_formation(General.Formation.RETREAT)
	elif mp_percent >= 0.5 and not spell_cast_recently and target_general:
		# Cast spell when we have good MP and a target
		current_tactic = Tactic.CAST_SPELL
	elif target_general and controlled_general.global_position.distance_to(target_general.global_position) < 100:
		# Enemy is close, go to standby
		current_tactic = Tactic.DEFEND
		controlled_general.set_formation(General.Formation.STANDBY)
	else:
		current_tactic = Tactic.DEFEND
		controlled_general.set_formation(General.Formation.STANDBY)

func _decision_balanced(hp_percent: float, troop_percent: float, mp_percent: float):
	"""Balanced AI: Mix of offense and defense based on situation."""
	if hp_percent < 0.25 or troop_percent < 0.15:
		current_tactic = Tactic.RETREAT
		controlled_general.set_formation(General.Formation.RETREAT)
	elif mp_percent >= 0.7 and not spell_cast_recently and target_general:
		var dist = controlled_general.global_position.distance_to(target_general.global_position)
		if dist < 150:  # Cast when enemy is in range
			current_tactic = Tactic.CAST_SPELL
	elif troop_percent > 0.5 and hp_percent > 0.5:
		current_tactic = Tactic.ATTACK
		controlled_general.set_formation(General.Formation.MELEE)
	else:
		current_tactic = Tactic.DEFEND
		controlled_general.set_formation(General.Formation.STANDBY)

func _decision_opportunistic(hp_percent: float, troop_percent: float, mp_percent: float):
	"""Opportunistic AI: Flank weak enemies, run from strong ones."""
	if not target_general:
		current_tactic = Tactic.ATTACK
		return
	
	var target_strength = _estimate_enemy_strength(target_general)
	var my_strength = _estimate_my_strength()
	
	if my_strength < target_strength * 0.7:
		# We're weaker, try to flank or retreat
		if hp_percent < 0.4:
			current_tactic = Tactic.RETREAT
			controlled_general.set_formation(General.Formation.RETREAT)
		else:
			current_tactic = Tactic.FLANK
			controlled_general.set_formation(General.Formation.ADVANCE)
	elif mp_percent >= 0.6 and not spell_cast_recently:
		current_tactic = Tactic.CAST_SPELL
	else:
		current_tactic = Tactic.ATTACK
		controlled_general.set_formation(General.Formation.MELEE)

func _find_target():
	"""Find the best target general."""
	var nearest: General = null
	var nearest_dist = 1000.0
	var weakest: General = null
	var weakest_troops = 9999
	
	for general in get_tree().get_nodes_in_group("generals"):
		if general.team != controlled_general.team and general.is_alive():
			var dist = controlled_general.global_position.distance_to(general.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = general
			
			if general.current_troops < weakest_troops:
				weakest_troops = general.current_troops
				weakest = general
	
	# Choose target based on personality
	match personality:
		Personality.AGGRESSIVE:
			target_general = nearest  # Attack closest
		Personality.OPPORTUNISTIC:
			target_general = weakest  # Attack weakest
		_:
			# Balanced/defensive: nearest unless very weak enemy exists
			if weakest and weakest_troops < 20:
				target_general = weakest
			else:
				target_general = nearest

func _execute_tactic(delta):
	"""Execute the current tactical decision."""
	if not controlled_general or not target_general:
		return
	
	match current_tactic:
		Tactic.ATTACK:
			_execute_attack()
		Tactic.DEFEND:
			_execute_defend()
		Tactic.FLANK:
			_execute_flank()
		Tactic.RETREAT:
			_execute_retreat()
		Tactic.CAST_SPELL:
			_execute_cast_spell()

func _execute_attack():
	"""Move toward target and attack."""
	if target_general:
		controlled_general.move_to(target_general.global_position)

func _execute_defend():
	"""Hold position unless enemy is very close."""
	if target_general:
		var dist = controlled_general.global_position.distance_to(target_general.global_position)
		if dist > 80:
			# Move closer but not too close
			var dir = controlled_general.global_position.direction_to(target_general.global_position)
			var hold_pos = target_general.global_position - dir * 60
			controlled_general.move_to(hold_pos)

func _execute_flank():
	"""Try to get behind the target."""
	if target_general:
		# Calculate flanking position
		var to_target = controlled_general.global_position.direction_to(target_general.global_position)
		var flank_dir = Vector2(-to_target.y, to_target.x)  # Perpendicular
		var flank_pos = target_general.global_position + flank_dir * 80
		controlled_general.move_to(flank_pos)

func _execute_retreat():
	"""Move toward map edge."""
	# Move away from target
	if target_general:
		var away_dir = controlled_general.global_position.direction_to(target_general.global_position) * -1
		var retreat_pos = controlled_general.global_position + away_dir * 200
		controlled_general.move_to(retreat_pos)

func _execute_cast_spell():
	"""Cast spell at target position."""
	if target_general and controlled_general.spell_ready:
		var success = controlled_general.cast_spell(target_general.global_position)
		if success:
			spell_cast_recently = true
			spell_cast_timer = 0.0
			current_tactic = Tactic.ATTACK  # Return to attack after casting

func _estimate_enemy_strength(enemy: General) -> float:
	"""Estimate enemy strength based on troops and HP."""
	var troop_factor = float(enemy.current_troops) / enemy.max_troops
	var hp_factor = float(enemy.current_hp) / enemy.max_hp
	var class_multiplier = 1.0
	
	match enemy.general_class:
		General.GeneralClass.WARRIOR: class_multiplier = 1.3
		General.GeneralClass.MAGE: class_multiplier = 1.1
		General.GeneralClass.ROGUE: class_multiplier = 1.0
	
	return (troop_factor * 0.7 + hp_factor * 0.3) * class_multiplier * 100

func _estimate_my_strength() -> float:
	"""Estimate our own strength."""
	if not controlled_general:
		return 0.0
	
	var troop_factor = float(controlled_general.current_troops) / controlled_general.max_troops
	var hp_factor = float(controlled_general.current_hp) / controlled_general.max_hp
	
	return (troop_factor * 0.7 + hp_factor * 0.3) * 100

func _on_troops_changed(new_count: int):
	"""React to troop losses."""
	if not controlled_general:
		return
	
	var troop_percent = float(new_count) / controlled_general.max_troops
	
	# Consider retreat if troops are very low
	if troop_percent < 0.1 and personality != Personality.AGGRESSIVE:
		current_tactic = Tactic.RETREAT
		controlled_general.set_formation(General.Formation.RETREAT)

func _on_spell_cast(spell_name: String, position: Vector2):
	"""React to spell being cast."""
	spell_cast_recently = true
	spell_cast_timer = 0.0

func _get_personality_name() -> String:
	match personality:
		Personality.AGGRESSIVE: return "Aggressive"
		Personality.DEFENSIVE: return "Defensive"
		Personality.BALANCED: return "Balanced"
		Personality.OPPORTUNISTIC: return "Opportunistic"
		_: return "Unknown"

func set_personality(new_personality: Personality):
	personality = new_personality
	print("AI personality changed to: ", _get_personality_name())
