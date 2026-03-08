extends Node2D

# Main Tactical Battle Controller - Complete Implementation

# Preload dependencies to fix class_name resolution
const CharacterData = preload("res://resources/data_classes/character_data.gd")
const CombatCalculator = preload("res://scripts/tactical/combat_calculator.gd")
const MagicEffects = preload("res://scripts/tactical/magic_effects.gd")
const AITactical = preload("res://scripts/tactical/ai_tactical.gd")

enum BattlePhase {
	SETUP,
	FORMATION_SELECT,
	PLAYER_TURN,
	ENEMY_TURN,
	RANSOM,
	RESOLUTION,
	ENDED
}

# Battle data passed from strategic layer
var attacker_data: Dictionary = {}
var defender_data: Dictionary = {}

var current_phase: BattlePhase = BattlePhase.SETUP
var turn_number: int = 1

# Battle entities
var attacker_lord: CharacterData = null
var defender_lord: CharacterData = null
var attacker_units: Array = []
var defender_units: Array = []

# Formation
var current_formation: String = "normal"
var formation_multiplier: float = 1.0

# AI
var ai_controller = null  # AITactical instance
var enemy_personality: String = "balanced"

# Current selection
var current_unit_index: int = 0
var selected_unit = null
var selected_target = null
var selected_command: String = ""

# Visual components
var parallax_bg: ParallaxBackground
var magic_effects: MagicEffects
var tactical_hud: CanvasLayer
var combat_calculator: CombatCalculator

# Signals
signal battle_ended(result: Dictionary)
signal unit_acted(unit, action: String)
signal lord_captured(lord: CharacterData, captor: CharacterData)

func _ready():
	combat_calculator = CombatCalculator.new()
	
	_setup_camera()
	_setup_background()
	_setup_units_from_data()
	_setup_hud()
	_setup_magic_effects()
	_setup_ai()
	
	# Start with formation selection
	_show_formation_selection()

func _setup_camera():
	var camera = Camera2D.new()
	camera.position = Vector2(640, 360)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	add_child(camera)
	camera.make_current()

func _setup_background():
	var time_of_day = attacker_data.get("time_of_day", "day") if attacker_data else "day"
	
	parallax_bg = ParallaxBackground.new()
	add_child(parallax_bg)
	
	# Sky layer
	var sky_layer = ParallaxLayer.new()
	sky_layer.motion_scale = Vector2(0.1, 0.1)
	var sky = ColorRect.new()
	sky.size = Vector2(1280, 720)
	
	match time_of_day:
		"day": sky.color = Color(0.4, 0.7, 1.0)
		"sunset": sky.color = Color(0.8, 0.4, 0.3)
		"night": sky.color = Color(0.1, 0.1, 0.3)
		_: sky.color = Color(0.4, 0.7, 1.0)
	
	sky_layer.add_child(sky)
	parallax_bg.add_child(sky_layer)
	
	# Ground
	var ground_layer = ParallaxLayer.new()
	ground_layer.motion_scale = Vector2(0.5, 0.5)
	var ground = ColorRect.new()
	ground.size = Vector2(1280, 240)
	ground.position = Vector2(0, 480)
	
	var terrain = defender_data.get("terrain", "grass") if defender_data else "grass"
	match terrain:
		"grass": ground.color = Color(0.2, 0.6, 0.2)
		"desert": ground.color = Color(0.8, 0.7, 0.4)
		"mountain": ground.color = Color(0.4, 0.4, 0.4)
		_: ground.color = Color(0.2, 0.6, 0.2)
	
	ground_layer.add_child(ground)
	parallax_bg.add_child(ground_layer)

func _setup_units_from_data():
	# Clear existing
	for child in get_children():
		if child.is_in_group("units"):
			child.queue_free()
	
	attacker_units.clear()
	defender_units.clear()
	
	# Get lords
	attacker_lord = attacker_data.get("lord") if attacker_data else null
	defender_lord = defender_data.get("lord") if defender_data else null
	
	# Spawn attacker units
	var attacker_unit_data = attacker_data.get("units", []) if attacker_data else []
	if attacker_unit_data.is_empty():
		# Fallback test data
		attacker_unit_data = [
			{"type": "Knights", "count": 30},
			{"type": "Horsemen", "count": 17}
		]
	
	for i in range(attacker_unit_data.size()):
		var unit_info = attacker_unit_data[i]
		var unit = _create_unit(unit_info, true, i)
		add_child(unit)
		attacker_units.append(unit)
	
	# Spawn defender units
	var defender_unit_data = defender_data.get("units", []) if defender_data else []
	if defender_unit_data.is_empty():
		defender_unit_data = [
			{"type": "Horsemen", "count": 20},
			{"type": "Mages", "count": 12}
		]
	
	for i in range(defender_unit_data.size()):
		var unit_info = defender_unit_data[i]
		var unit = _create_unit(unit_info, false, i)
		add_child(unit)
		defender_units.append(unit)

func _create_unit(unit_info: Dictionary, is_attacker: bool, slot: int):
	var unit = preload("res://scenes/tactical/battle_unit.tscn").instantiate()
	unit.unit_type = unit_info.get("type", "Knights")
	unit.count = unit_info.get("count", 10)
	unit.max_count = unit.count
	unit.is_player_unit = is_attacker
	unit.lord = attacker_lord if is_attacker else defender_lord
	
	# Position based on slot
	if is_attacker:
		unit.position = Vector2(200 + slot * 100, 500)
	else:
		unit.position = Vector2(900 - slot * 100, 500)
	
	unit.add_to_group("units")
	unit.unit_selected.connect(_on_unit_selected)
	unit.unit_defeated.connect(_on_unit_defeated)
	
	return unit

func _setup_hud():
	var hud_scene = load("res://scenes/tactical/tactical_hud.tscn")
	if hud_scene:
		tactical_hud = hud_scene.instantiate()
		add_child(tactical_hud)
		
		tactical_hud.command_selected.connect(_on_command_selected)
		tactical_hud.target_selected.connect(_on_target_selected)
		tactical_hud.retreat_requested.connect(_on_retreat)
		tactical_hud.formation_selected.connect(_on_formation_selected)
		
		# Set battle title with portraits
		var attacker_name = attacker_lord.name if attacker_lord else "Attacker"
		var defender_name = defender_lord.name if defender_lord else "Defender"
		var attacker_portrait = attacker_lord.portrait_path if attacker_lord else ""
		var defender_portrait = defender_lord.portrait_path if defender_lord else ""
		
		tactical_hud.set_battle_info(attacker_name, defender_name, attacker_portrait, defender_portrait)
		_update_hud_counts()

func _setup_magic_effects():
	magic_effects = MagicEffects.new()
	add_child(magic_effects)

func _setup_ai():
	enemy_personality = defender_data.get("personality", "balanced") if defender_data else "balanced"
	ai_controller = AITactical.new(enemy_personality, combat_calculator)

func _show_formation_selection():
	current_phase = BattlePhase.FORMATION_SELECT
	if tactical_hud:
		tactical_hud.show_formation_selection()

func _on_formation_selected(formation_type: String):
	current_formation = formation_type
	match formation_type:
		"rear":
			formation_multiplier = 1.3
			print("Formation: Rear Assault (+30% damage)")
		"flank":
			formation_multiplier = 1.2
			print("Formation: Flanking (+20% damage)")
		_:
			formation_multiplier = 1.0
			print("Formation: Normal")
	
	start_battle()

func start_battle():
	current_phase = BattlePhase.PLAYER_TURN
	turn_number = 1
	current_unit_index = 0
	_select_next_unit()

func _select_next_unit():
	var units = _get_current_phase_units()
	
	while current_unit_index < units.size():
		selected_unit = units[current_unit_index]
		if selected_unit.is_alive():
			if tactical_hud:
				tactical_hud.show_message("Select action for %s" % selected_unit.unit_type)
				tactical_hud.enable_commands(true)
			return
		current_unit_index += 1
	
	_end_phase()

func _get_current_phase_units():
	match current_phase:
		BattlePhase.PLAYER_TURN:
			return attacker_units
		BattlePhase.ENEMY_TURN:
			return defender_units
		_:
			return []

func _end_phase():
	match current_phase:
		BattlePhase.PLAYER_TURN:
			current_phase = BattlePhase.ENEMY_TURN
			current_unit_index = 0
			if tactical_hud:
				tactical_hud.show_message("Enemy Turn")
			_process_ai_turn()
		
		BattlePhase.ENEMY_TURN:
			current_phase = BattlePhase.PLAYER_TURN
			current_unit_index = 0
			turn_number += 1
			if tactical_hud:
				tactical_hud.show_message("Player Turn - Turn %d" % turn_number)
			_select_next_unit()

func _on_command_selected(command: String):
	selected_command = command
	match command:
		"attack":
			if tactical_hud:
				tactical_hud.show_message("Click enemy unit to attack")
				tactical_hud.current_state = tactical_hud.CommandState.SELECTING_TARGET
		"wait":
			_skip_unit_turn()
		"fence":
			_activate_fence()
		"break":
			if tactical_hud:
				tactical_hud.show_message("Click enemy unit to break")
				tactical_hud.current_state = tactical_hud.CommandState.SELECTING_TARGET
		"retreat":
			_on_retreat()

func _on_target_selected(target):
	selected_target = target
	
	if selected_command == "attack":
		await _execute_attack(selected_unit, target)
	elif selected_command == "break":
		await _execute_break(selected_unit, target)
	
	current_unit_index += 1
	await get_tree().create_timer(0.5).timeout
	_select_next_unit()

func _execute_attack(attacker, defender):
	if tactical_hud:
		tactical_hud.enable_commands(false)
	
	var use_magic = combat_calculator.can_use_magic(attacker.unit_type)
	
	if use_magic:
		var start_pos = attacker.global_position
		var end_pos = defender.global_position
		magic_effects.cast_lightning(start_pos, end_pos)
		await get_tree().create_timer(0.3).timeout
		
		var damage = await attacker.attack_with_magic(defender)
		_update_hud_counts()
		
		if not defender.is_alive():
			tactical_hud.show_wipeout_message(defender.unit_type)
	else:
		# Apply formation multiplier to damage
		var base_damage = combat_calculator.calculate_damage(attacker, defender, current_formation)
		var final_damage = int(base_damage * formation_multiplier)
		
		await attacker.attack_with_damage(defender, final_damage)
		_update_hud_counts()
		
		if not defender.is_alive():
			tactical_hud.show_wipeout_message(defender.unit_type)
	
	_check_battle_end()

func _execute_break(attacker, defender):
	if tactical_hud:
		tactical_hud.show_message("Break attempt!")
	
	var damage = combat_calculator.calculate_damage(attacker, defender, "normal")
	damage = int(damage * 1.3 * formation_multiplier)
	await defender.take_damage(int(damage * 0.3))
	
	_update_hud_counts()
	_check_battle_end()

func _activate_fence():
	selected_unit.activate_barrier()
	if tactical_hud:
		tactical_hud.show_message("%s barrier activated!" % selected_unit.unit_type)
	
	current_unit_index += 1
	await get_tree().create_timer(0.5).timeout
	_select_next_unit()

func _skip_unit_turn():
	if tactical_hud:
		tactical_hud.show_message("%s waits..." % selected_unit.unit_type)
	
	current_unit_index += 1
	await get_tree().create_timer(0.5).timeout
	_select_next_unit()

func _on_retreat():
	if tactical_hud:
		tactical_hud.show_message("Retreating from battle!")
	
	var retreating_lord = attacker_lord if current_phase == BattlePhase.PLAYER_TURN else defender_lord
	var result = {
		"winner": "defender" if current_phase == BattlePhase.PLAYER_TURN else "attacker",
		"retreat": true,
		"retreating_lord": retreating_lord,
		"lord_captured": false
	}
	
	_end_battle(result)

func _process_ai_turn():
	if tactical_hud:
		tactical_hud.enable_commands(false)
	
	var actions = ai_controller.calculate_turn(defender_units, attacker_units)
	
	for action in actions:
		if current_phase == BattlePhase.ENDED:
			break
		
		match action.type:
			"attack":
				await get_tree().create_timer(0.5).timeout
				await _execute_ai_attack(action.unit, action.target, action.get("use_magic", false))
			"fence":
				action.unit.activate_barrier()
				if tactical_hud:
					tactical_hud.show_message("Enemy %s used Fence!" % action.unit.unit_type)
				await get_tree().create_timer(0.5).timeout
			"wait", _:
				await get_tree().create_timer(0.3).timeout
		
		await get_tree().create_timer(0.3).timeout
	
	_end_phase()

func _execute_ai_attack(attacker, defender, use_magic: bool):
	if use_magic:
		var start_pos = attacker.global_position
		var end_pos = defender.global_position
		magic_effects.cast_lightning(start_pos, end_pos)
		await get_tree().create_timer(0.3).timeout
		await attacker.attack_with_magic(defender)
	else:
		var damage = combat_calculator.calculate_damage(attacker, defender, "normal")
		damage = int(damage * ai_controller.get_formation_bonus())
		await attacker.attack_with_damage(defender, damage)
	
	_update_hud_counts()
	
	if not defender.is_alive():
		tactical_hud.show_wipeout_message(defender.unit_type)
	
	_check_battle_end()

func _on_unit_selected(unit):
	if current_phase == BattlePhase.PLAYER_TURN and tactical_hud and tactical_hud.current_state == tactical_hud.CommandState.SELECTING_TARGET:
		if not unit.is_player_unit:
			tactical_hud.on_target_clicked(unit)

func _on_unit_defeated(unit):
	_check_battle_end()

func _check_battle_end():
	var attacker_alive = _has_alive_units(attacker_units)
	var defender_alive = _has_alive_units(defender_units)
	
	# Get province_id from meta if available
	var province_id = get_meta("province_id", 0)
	
	if not attacker_alive:
		# Check for lord capture
		if attacker_lord and not attacker_lord.is_captured:
			_show_ransom_dialog(attacker_lord, defender_lord)
			return
		
		var result = {
			"winner": "defender",
			"retreat": false,
			"attacker_lost": true,
			"lord_captured": false,
			"province_id": province_id,
			"province_captured": false
		}
		if tactical_hud:
			tactical_hud.show_victory_message("defenders")
		await get_tree().create_timer(2.0).timeout
		_end_battle(result)
		
	elif not defender_alive:
		if defender_lord and not defender_lord.is_captured:
			_show_ransom_dialog(defender_lord, attacker_lord)
			return
		
		var result = {
			"winner": "attacker",
			"retreat": false,
			"attacker_won": true,
			"lord_captured": false,
			"province_id": province_id,
			"province_captured": true
		}
		if tactical_hud:
			tactical_hud.show_victory_message("attackers")
		await get_tree().create_timer(2.0).timeout
		_end_battle(result)

func _show_ransom_dialog(captured_lord: CharacterData, captor_lord: CharacterData):
	current_phase = BattlePhase.RANSOM
	get_tree().paused = true
	
	var ransom_scene = load("res://scenes/tactical/ransom_dialog.tscn")
	if ransom_scene:
		var ransom_ui = ransom_scene.instantiate()
		ransom_ui.captured_lord = captured_lord
		ransom_ui.captor_lord = captor_lord
		ransom_ui.ransom_paid.connect(_on_ransom_paid.bind(captured_lord))
		ransom_ui.ransom_refused.connect(_on_ransom_refused.bind(captured_lord))
		add_child(ransom_ui)
		lord_captured.emit(captured_lord, captor_lord)

func _on_ransom_paid(captured_lord: CharacterData):
	get_tree().paused = false
	captured_lord.is_captured = false
	
	var result = {
		"winner": "ransom_resolved",
		"retreat": false,
		"lord_captured": false,
		"ransom_paid": true,
		"released_lord": captured_lord
	}
	_end_battle(result)

func _on_ransom_refused(captured_lord: CharacterData):
	get_tree().paused = false
	captured_lord.is_captured = true
	
	var result = {
		"winner": "ransom_resolved",
		"retreat": false,
		"lord_captured": true,
		"captured_lord": captured_lord
	}
	_end_battle(result)

func _has_alive_units(units: Array) -> bool:
	for unit in units:
		if unit.is_alive():
			return true
	return false

func _update_hud_counts():
	var attacker_count = 0
	for unit in attacker_units:
		if unit.is_alive():
			attacker_count += unit.count
	
	var defender_count = 0
	for unit in defender_units:
		if unit.is_alive():
			defender_count += unit.count
	
	if tactical_hud:
		tactical_hud.update_counts(attacker_count, defender_count)

func _end_battle(result: Dictionary):
	current_phase = BattlePhase.ENDED
	
	print("DEBUG: _end_battle called with result: ", result)
	
	# Emit signal - strategic_layer will handle the rest
	battle_ended.emit(result)
	
	# Note: Strategic layer handles cleanup via _on_tactical_battle_ended signal handler
	# No direct call to return_from_battle to avoid double-processing
