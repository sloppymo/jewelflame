class_name DragonForceBattle
extends Node2D

## Dragon Force Style Real-Time Battle Controller
## 1v1 General battle with troops (Phase 1 prototype)

signal battle_started()
signal battle_ended(result: Dictionary)
signal general_selected(general: General)

enum BattlePhase { SETUP, COMBAT, ENDED }
enum InputMode { SELECT, MOVE, SPELL }

# Battle configuration
@export var battlefield_size: Vector2 = Vector2(800, 600)
@export var player_spawn_pos: Vector2 = Vector2(150, 300)
@export var enemy_spawn_pos: Vector2 = Vector2(650, 300)

# Battle data
var attacker_data: Dictionary = {}
var defender_data: Dictionary = {}

# Battle state
var current_phase: BattlePhase = BattlePhase.SETUP
var input_mode: InputMode = InputMode.SELECT

# Generals
var player_general: General = null
var enemy_general: General = null
var selected_general: General = null

# Subsystems
var spell_system: SpellSystem = null

# Visual
var selection_box: ColorRect = null
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var spell_cursor: Sprite2D = null
var current_spell: String = "fireball"

# UI Reference
@onready var ui_layer: CanvasLayer = $CanvasLayer
@onready var camera: Camera2D = $Camera2D

func _ready():
	print("DragonForceBattle: Initializing...")
	
	# Setup subsystems
	_setup_spell_system()
	_setup_visuals()
	
	# Spawn generals
	call_deferred("_spawn_battle")
	
	print("DragonForceBattle: Ready")

func _setup_spell_system():
	spell_system = SpellSystem.new()
	spell_system.name = "SpellSystem"
	add_child(spell_system)
	spell_system.spell_effect_completed.connect(_on_spell_completed)

func _setup_visuals():
	# Create selection box for drag selection
	selection_box = ColorRect.new()
	selection_box.color = Color(1, 1, 0, 0.3)
	selection_box.visible = false
	add_child(selection_box)
	
	# Create spell cursor (for AOE targeting)
	spell_cursor = Sprite2D.new()
	spell_cursor.visible = false
	spell_cursor.modulate = Color(1, 0.5, 0, 0.5)
	add_child(spell_cursor)

func _spawn_battle():
	"""Spawn the two opposing generals."""
	
	# Create player general (Warrior)
	player_general = _create_general(
		"Erin Blanche",
		General.GeneralClass.WARRIOR,
		0,  # Player team
		player_spawn_pos,
		100,  # Troops
		"fireball"
	)
	add_child(player_general)
	player_general.general_selected.connect(_on_general_selected)
	player_general.general_died.connect(_on_general_died)
	
	# Create enemy general (Rogue)
	enemy_general = _create_general(
		"Rival Lord",
		General.GeneralClass.ROGUE,
		1,  # Enemy team
		enemy_spawn_pos,
		100,  # Troops
		"fireball"
	)
	add_child(enemy_general)
	enemy_general.general_selected.connect(_on_general_selected)
	enemy_general.general_died.connect(_on_general_died)
	
	# Setup enemy AI
	var ai = DragonForceAI.new()
	ai.name = "EnemyAI"
	enemy_general.add_child(ai)
	ai.setup(enemy_general)
	
	# Start combat after brief delay (allows generals to spawn)
	get_tree().create_timer(1.0).timeout.connect(
		func():
			current_phase = BattlePhase.COMBAT
			battle_started.emit()
			print("DragonForceBattle: Battle started! %s vs %s" % [player_general.general_name, enemy_general.general_name])
	)

func _create_general(name: String, gen_class: General.GeneralClass, team: int, 
					 pos: Vector2, troops: int, spell: String) -> General:
	"""Create a general from the base scene."""
	var general = preload("res://dragon_force/general_base.tscn").instantiate()
	general.general_name = name
	general.general_class = gen_class
	general.team = team
	general.position = pos
	general.max_troops = troops
	general.equipped_spell = spell
	
	# Set different colors based on team
	if team == 0:
		general.modulate = Color(0.9, 0.9, 1.0)  # Blue tint for player
	else:
		general.modulate = Color(1.0, 0.8, 0.8)  # Red tint for enemy
	
	return general

func _process(_delta):
	match current_phase:
		BattlePhase.COMBAT:
			_process_combat()
		BattlePhase.ENDED:
			pass

func _process_combat():
	# Update spell cursor position
	if input_mode == InputMode.SPELL and spell_cursor.visible:
		spell_cursor.global_position = get_global_mouse_position()
	
	# Check for battle end conditions
	_check_battle_end()

func _input(event):
	if current_phase != BattlePhase.COMBAT:
		return
	
	# Handle input based on mode
	match input_mode:
		InputMode.SELECT:
			_handle_select_input(event)
		InputMode.MOVE:
			_handle_move_input(event)
		InputMode.SPELL:
			_handle_spell_input(event)
	
	# Global shortcuts
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				_set_input_mode(InputMode.SELECT)
			KEY_1:
				if selected_general:
					selected_general.set_formation(General.Formation.MELEE)
			KEY_2:
				if selected_general:
					selected_general.set_formation(General.Formation.STANDBY)
			KEY_3:
				if selected_general:
					selected_general.set_formation(General.Formation.ADVANCE)
			KEY_4:
				if selected_general:
					selected_general.set_formation(General.Formation.RETREAT)

func _handle_select_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start drag selection
				is_dragging = true
				drag_start = get_global_mouse_position()
				selection_box.position = drag_start
				selection_box.size = Vector2.ZERO
				selection_box.visible = true
			else:
				# End drag selection
				is_dragging = false
				selection_box.visible = false
				_select_in_box()
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Right click = move order if general selected
			if selected_general and event.pressed:
				_set_input_mode(InputMode.MOVE)
	
	# Update selection box during drag
	if is_dragging:
		var mouse_pos = get_global_mouse_position()
		var top_left = Vector2(min(drag_start.x, mouse_pos.x), min(drag_start.y, mouse_pos.y))
		var bottom_right = Vector2(max(drag_start.x, mouse_pos.x), max(drag_start.y, mouse_pos.y))
		selection_box.position = top_left
		selection_box.size = bottom_right - top_left

func _handle_move_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Issue move order
			if selected_general:
				var target_pos = get_global_mouse_position()
				selected_general.move_to(target_pos)
				print("Move order: ", selected_general.general_name, " -> ", target_pos)
			
			_set_input_mode(InputMode.SELECT)
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Cancel move mode
			_set_input_mode(InputMode.SELECT)

func _handle_spell_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Cast spell at location
			if selected_general and selected_general.spell_ready:
				var target_pos = get_global_mouse_position()
				
				if spell_system:
					var success = spell_system.cast_spell(
						selected_general.equipped_spell,
						target_pos,
						selected_general.team
					)
					
					if success:
						selected_general.cast_spell(target_pos)
						print("Spell cast: ", selected_general.equipped_spell, " at ", target_pos)
			
			_set_input_mode(InputMode.SELECT)
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Cancel spell mode
			_set_input_mode(InputMode.SELECT)

func _select_in_box():
	"""Select generals inside the selection box."""
	var box_rect = Rect2(selection_box.position, selection_box.size)
	
	# Only select player generals
	if player_general and box_rect.has_point(player_general.global_position):
		_select_general(player_general)

func _on_general_selected(general: General):
	"""Handle general selection click."""
	if general.team == 0:  # Player team only
		_select_general(general)

func _select_general(general: General):
	"""Select a general."""
	# Deselect previous
	if selected_general:
		selected_general.deselect()
	
	selected_general = general
	selected_general.select()
	general_selected.emit(general)
	
	print("Selected: ", general.general_name)

func _on_general_died(general: General):
	"""Handle general death."""
	print("General died: ", general.general_name)
	
	if general == selected_general:
		selected_general = null
	
	_check_battle_end()

func _check_battle_end():
	"""Check if battle should end."""
	if current_phase == BattlePhase.ENDED:
		return
	
	var player_alive = player_general and player_general.is_alive()
	var enemy_alive = enemy_general and enemy_general.is_alive()
	
	if not player_alive or not enemy_alive:
		_end_battle(player_alive)

func _end_battle(player_won: bool):
	current_phase = BattlePhase.ENDED
	
	var result = {
		"player_won": player_won,
		"attacker_won": player_won,  # For compatibility
		"player_troops_remaining": player_general.current_troops if player_general else 0,
		"enemy_troops_remaining": enemy_general.current_troops if enemy_general else 0,
		"player_hp_remaining": player_general.current_hp if player_general else 0,
		"enemy_hp_remaining": enemy_general.current_hp if enemy_general else 0
	}
	
	print("Battle ended! Player won: ", player_won)
	battle_ended.emit(result)
	
	# Notify UI
	if ui_layer and ui_layer.has_method("show_battle_result"):
		ui_layer.show_battle_result(result)

func _set_input_mode(mode: InputMode):
	input_mode = mode
	
	# Update cursor visibility
	spell_cursor.visible = (mode == InputMode.SPELL)
	
	# Update UI
	if ui_layer and ui_layer.has_method("update_input_mode"):
		match mode:
			InputMode.SELECT: ui_layer.update_input_mode("select")
			InputMode.MOVE: ui_layer.update_input_mode("move")
			InputMode.SPELL: ui_layer.update_input_mode("spell")

func _on_spell_completed(spell_name: String):
	print("Spell effect completed: ", spell_name)

# ============================================================================
# PUBLIC API
# ============================================================================

func start_spell_targeting(spell_name: String = "fireball"):
	"""Start targeting mode for spell casting."""
	if selected_general and selected_general.spell_ready:
		current_spell = spell_name
		_set_input_mode(InputMode.SPELL)
	else:
		print("Spell not ready or no general selected")

func get_battle_summary() -> Dictionary:
	return {
		"phase": current_phase,
		"player_general_alive": player_general.is_alive() if player_general else false,
		"enemy_general_alive": enemy_general.is_alive() if enemy_general else false,
		"player_troops": player_general.current_troops if player_general else 0,
		"enemy_troops": enemy_general.current_troops if enemy_general else 0,
		"player_mp": player_general.current_mp if player_general else 0,
		"enemy_mp": enemy_general.current_mp if enemy_general else 0,
		"selected_general": selected_general.general_name if selected_general else "None"
	}
