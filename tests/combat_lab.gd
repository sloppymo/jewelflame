class_name CombatLab
extends Node2D
## Production-quality combat testing environment.
## Features: Smart spawn, animation debugger, debug overlays, slow motion.

const ArenaUnit := preload("res://tests/arena_unit.gd")
const CombatLabUIManager := preload("res://tests/ui_manager.gd")
const AnimationDebugOverlay := preload("res://tests/animation_debug_overlay.gd")
const ArenaMap := preload("res://tests/arena_map.gd")

#region Constants
const ARENA_BOUNDS := Rect2(Vector2(50, 50), Vector2(1180, 620))
const CAMERA_CENTER := Vector2(640, 360)
const MIN_TIME_SCALE := 0.1
const MAX_TIME_SCALE := 2.0
const TIME_SCALE_STEP := 0.1

#region Unit Stats Override
var enable_stat_overrides := false
var override_level: int = 1
var override_str: int = 10
var override_def: int = 5
var override_spd: int = 5
var override_dex: int = 5
var override_crit_chance: float = 0.05
var override_crit_mult: float = 2.0
var override_equipment: Dictionary = {}  # slot -> item_id
#endregion

#region @onready References
@onready var ui: CanvasLayer = $UI
@onready var camera: Camera2D = $Camera2D
@onready var background: ColorRect = $Background
@onready var arena_map: ArenaMap = $ArenaMap
#endregion

#region Runtime State
var units: Array[ArenaUnit] = []
var selected_unit: ArenaUnit = null
var debug_8way_units: Array[ArenaUnit] = []

var spawn_count: int = 1
var current_team: int = 1
var current_formation: String = "random"
var one_hp_mode: bool = false

var is_paused: bool = false
var time_scale: float = 1.0

var show_state_labels: bool = false
var show_target_lines: bool = false
var show_attack_ranges: bool = false
var aggro_enabled: bool = true

## Team cache - rebuilt only when units spawn/die (not every frame)
var _team_caches_dirty: bool = true
var _allies_by_team: Dictionary = {1: [], 2: []}
var _enemies_by_team: Dictionary = {1: [], 2: []}
#endregion

#region Debug Overlay
var _anim_debug_overlay: AnimationDebugOverlay = null
#endregion

#region Managers
var ui_manager: CombatLabUIManager = null
#endregion

#region Initialization
func _ready() -> void:
	ConfigLoader.initialize()
	
	ui_manager = CombatLabUIManager.new()
	add_child(ui_manager)
	ui_manager.initialize(ui)
	
	_setup_camera()
	_connect_signals()
	
	print("Combat Lab ready! Press H for help.")

func _setup_camera() -> void:
	camera.position = CAMERA_CENTER

func _connect_signals() -> void:
	# Background click for spawning
	$Background.gui_input.connect(_on_background_gui_input)
	
	# Spawn panel signals - using Godot 4 % unique name accessor
	%CountSpinBox.value_changed.connect(_on_spawn_count_changed)
	%Team1Button.pressed.connect(func(): _on_team_toggled(1))
	%Team2Button.pressed.connect(func(): _on_team_toggled(2))
	%FormationDropdown.item_selected.connect(_on_formation_selected)
	%Preset1v1.pressed.connect(func(): _on_preset_spawn("1v1"))
	%Preset5v5.pressed.connect(func(): _on_preset_spawn("5v5"))
	%PresetDragon.pressed.connect(func(): _on_preset_spawn("dragon"))
	%PresetMixed.pressed.connect(func(): _on_preset_spawn("mixed"))
	%ClearButton.pressed.connect(_on_clear_pressed)
	%StopAggroButton.toggled.connect(_on_stop_aggro_toggled)
	
	# Animation debugger signals
	%PlayPauseButton.pressed.connect(_on_play_pause_pressed)
	%StepBackButton.pressed.connect(_on_step_back_pressed)
	%StepForwardButton.pressed.connect(_on_step_forward_pressed)
	%Test8WayButton.pressed.connect(_on_8way_test_pressed)
	%AnimDropdown.item_selected.connect(_on_anim_dropdown_selected)
#endregion

#region Background Input
func _on_background_gui_input(event: InputEvent) -> void:
	## Handle clicks on the background for spawning units
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos := get_global_mouse_position()
		var clicked_unit := _get_unit_at_position(mouse_pos)
		if clicked_unit:
			_select_unit(clicked_unit)
		else:
			_spawn_at_mouse()
#endregion

#region Input Handling
func _unhandled_input(event: InputEvent) -> void:
	## Handles game-world input (UI input is consumed by UI nodes)
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos := get_global_mouse_position()
			var clicked_unit := _get_unit_at_position(mouse_pos)
			if clicked_unit:
				_select_unit(clicked_unit)
			else:
				_spawn_at_mouse()

func _input(event: InputEvent) -> void:
	## Handles global hotkeys
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				_toggle_overlay("state_labels")
			KEY_F2:
				_toggle_overlay("target_lines")
			KEY_F3:
				_toggle_overlay("attack_ranges")
			KEY_F4:
				_toggle_1hp_mode()
			KEY_F5:
				_toggle_grid_overlay()
			KEY_SPACE:
				_toggle_pause()
			KEY_H:
				_print_help()
			KEY_DELETE:
				_delete_selected_unit()
			KEY_R:
				if event.ctrl_pressed:
					_clear_all_units()
				else:
					_respawn_selected_unit()
			KEY_C:
				if event.ctrl_pressed:
					_clone_selected_unit()
			KEY_ESCAPE:
				get_tree().quit()
	
	if event is InputEventMouseButton:
		if event.shift_pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				time_scale = min(time_scale + TIME_SCALE_STEP, MAX_TIME_SCALE)
				_apply_time_scale()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				time_scale = max(time_scale - TIME_SCALE_STEP, MIN_TIME_SCALE)
				_apply_time_scale()

func _toggle_overlay(overlay_name: String) -> void:
	match overlay_name:
		"state_labels":
			show_state_labels = !show_state_labels
			print("State labels: ", "ON" if show_state_labels else "OFF")
			# Create/remove labels for all units
			for unit in units:
				if is_instance_valid(unit):
					if show_state_labels:
						ui_manager._create_state_label(unit)
					else:
						ui_manager._remove_state_label(unit)
		"target_lines":
			show_target_lines = !show_target_lines
			print("Target lines: ", "ON" if show_target_lines else "OFF")
			queue_redraw()
		"attack_ranges":
			show_attack_ranges = !show_attack_ranges
			print("Attack ranges: ", "ON" if show_attack_ranges else "OFF")
			queue_redraw()
	
	ui_manager.update_debug_status(show_state_labels, show_target_lines, show_attack_ranges, one_hp_mode)

func _toggle_1hp_mode() -> void:
	one_hp_mode = !one_hp_mode
	_apply_1hp_mode()
	print("1-HP mode: ", "ON" if one_hp_mode else "OFF")
	ui_manager.update_debug_status(show_state_labels, show_target_lines, show_attack_ranges, one_hp_mode)

func _toggle_grid_overlay() -> void:
	if _anim_debug_overlay:
		_anim_debug_overlay.toggle_grid()
		print("Grid overlay: ", "ON" if _anim_debug_overlay.show_grid else "OFF")
	else:
		print("No unit selected - select a unit first to see grid overlay")

func _toggle_pause() -> void:
	is_paused = !is_paused
	_apply_time_scale()
	print("Paused: ", is_paused)
#endregion

#region Spawning
func _spawn_at_mouse() -> void:
	var unit_name := ui_manager.get_selected_unit_name()
	var unit_type := ConfigLoader.get_type_by_name(unit_name)
	var mouse_pos := get_global_mouse_position()
	
	if spawn_count == 1:
		_spawn_unit(unit_type, current_team, mouse_pos)
	else:
		_spawn_formation(unit_type, current_team, mouse_pos, spawn_count, current_formation)

func _spawn_unit(unit_type: UnitType.Enum, team: int, pos: Vector2) -> ArenaUnit:
	var config := ConfigLoader.get_config(unit_type)
	if not config:
		push_error("No config found for unit type: " + str(unit_type))
		return null
	
	var unit := ArenaUnit.new()
	unit.unit_type = unit_type
	unit.setup(config, team, pos)
	
	if one_hp_mode:
		unit.max_hp = 1
		unit.hp = 1
	
	unit.add_to_group("arena_units")
	unit.unit_died.connect(_on_unit_died.bind(unit))
	unit.spell_cast.connect(_on_spell_cast)
	
	# State labels will be connected via _on_unit_spawned when enabled
	
	add_child(unit)
	units.append(unit)
	
	# Rebuild team caches when unit spawns
	_rebuild_team_caches()
	
	ui_manager.update_unit_count(units.size())
	return unit

func _spawn_formation(unit_type: UnitType.Enum, team: int, center: Vector2, count: int, formation: String) -> void:
	match formation:
		"line":
			for i in range(count):
				var offset := Vector2((i - count / 2.0) * 40, 0)
				_spawn_unit(unit_type, team, center + offset)
		"circle":
			for i in range(count):
				var angle := (i / float(count)) * TAU
				var offset := Vector2(cos(angle), sin(angle)) * 60
				_spawn_unit(unit_type, team, center + offset)
		"grid":
			var cols: int = int(ceil(sqrt(count)))
			for i in range(count):
				var x: int = (i % cols) * 40
				var y: int = (i / cols) * 40
				_spawn_unit(unit_type, team, center + Vector2(x - cols * 20, y - cols * 20))
		_:
			# Random
			for i in range(count):
				var offset := Vector2(randf() * 100 - 50, randf() * 100 - 50)
				_spawn_unit(unit_type, team, center + offset)
#endregion

#region Unit Management
func _get_unit_at_position(pos: Vector2) -> ArenaUnit:
	for unit in units:
		if not is_instance_valid(unit):
			continue
		if unit.position.distance_to(pos) < 30:
			return unit
	return null

func _select_unit(unit: ArenaUnit) -> void:
	# Detach from previous unit
	if _anim_debug_overlay:
		_anim_debug_overlay.detach()
	
	selected_unit = unit
	print("Selected: ", unit.config.unit_name, " (Team ", unit.team, ")")
	
	# Attach overlay to new unit's active sprite
	if unit.active_sprite:
		if not _anim_debug_overlay:
			_anim_debug_overlay = AnimationDebugOverlay.new()
			add_child(_anim_debug_overlay)
		_anim_debug_overlay.attach_to_sprite(unit.active_sprite)

func _delete_selected_unit() -> void:
	if selected_unit and is_instance_valid(selected_unit):
		_remove_unit(selected_unit)
		selected_unit = null

func _clone_selected_unit() -> void:
	if selected_unit and is_instance_valid(selected_unit):
		_spawn_unit(selected_unit.unit_type, selected_unit.team, selected_unit.position + Vector2(20, 0))

func _respawn_selected_unit() -> void:
	if selected_unit and is_instance_valid(selected_unit):
		var pos := selected_unit.position
		var team := selected_unit.team
		var unit_type := selected_unit.unit_type
		_delete_selected_unit()
		_spawn_unit(unit_type, team, pos)

func _clear_all_units() -> void:
	for unit in units:
		if is_instance_valid(unit):
			unit.queue_free()
	units.clear()
	selected_unit = null
	debug_8way_units.clear()
	ui_manager.update_unit_count(0)
	ui_manager._hide_all_state_labels()
	_team_caches_dirty = true

func _remove_unit(unit: ArenaUnit) -> void:
	if unit in units:
		units.erase(unit)
	if is_instance_valid(unit):
		unit.queue_free()
	ui_manager.update_unit_count(units.size())
	_team_caches_dirty = true

func _on_unit_died(unit: ArenaUnit) -> void:
	## Delayed cleanup for dead units
	await get_tree().create_timer(3.0).timeout
	if unit in units and is_instance_valid(unit):
		_remove_unit(unit)
		_team_caches_dirty = true

func _on_spell_cast(caster_name: String, spell_name: String, team: int) -> void:
	## Shows spell cast notification in the UI
	if ui_manager:
		ui_manager.show_spell_cast(caster_name, spell_name, team)

func _apply_1hp_mode() -> void:
	for unit in units:
		if is_instance_valid(unit):
			if one_hp_mode:
				unit.max_hp = 1
				unit.set_hp(1)
			else:
				unit.max_hp = unit.config.max_hp
				unit.set_hp(unit.config.max_hp)

func _apply_time_scale() -> void:
	Engine.time_scale = 0.0 if is_paused else time_scale
	ui_manager.update_speed_label(time_scale)
#endregion

#region UI Callbacks
func _on_spawn_count_changed(value: float) -> void:
	spawn_count = int(value)

func _on_team_toggled(team: int) -> void:
	current_team = team
	%Team1Button.button_pressed = (team == 1)
	%Team2Button.button_pressed = (team == 2)

func _on_formation_selected(index: int) -> void:
	current_formation = %FormationDropdown.get_item_text(index)

func _on_preset_spawn(preset: String) -> void:
	_clear_all_units()
	match preset:
		"1v1":
			_spawn_unit(UnitType.Enum.KNIGHT, 1, Vector2(440, 360))
			_spawn_unit(UnitType.Enum.ORC, 2, Vector2(840, 360))
		"5v5":
			for i in range(5):
				_spawn_unit(UnitType.Enum.KNIGHT, 1, Vector2(300 + i * 40, 300 + randf() * 100))
			for i in range(5):
				_spawn_unit(UnitType.Enum.ORC, 2, Vector2(900 + i * 40, 300 + randf() * 100))
		"dragon":
			_spawn_unit(UnitType.Enum.DRAGON_GREEN, 1, Vector2(300, 360))
			for i in range(10):
				_spawn_unit(UnitType.Enum.KNIGHT, 2, Vector2(900 + randf() * 100, 200 + randf() * 320))
		"mixed":
			var types := [UnitType.Enum.KNIGHT, UnitType.Enum.ARCHER, UnitType.Enum.MAGE, UnitType.Enum.ORC, UnitType.Enum.SKELLY]
			for i in range(10):
				_spawn_unit(types[i % types.size()], 1, Vector2(200 + randf() * 300, 200 + randf() * 320))
			for i in range(10):
				_spawn_unit(types[i % types.size()], 2, Vector2(800 + randf() * 300, 200 + randf() * 320))

func _on_clear_pressed() -> void:
	_clear_all_units()

func _on_stop_aggro_toggled(enabled: bool) -> void:
	aggro_enabled = !enabled
	if aggro_enabled:
		%StopAggroButton.text = "Stop Aggro"
		%StopAggroButton.modulate = Color.WHITE
		print("Aggro: ENABLED - Units will fight")
	else:
		%StopAggroButton.text = "Resume Aggro"
		%StopAggroButton.modulate = Color(1, 0.5, 0.5)
		print("Aggro: DISABLED - Units will idle")
#endregion

#region Animation Debugger
func _on_anim_dropdown_selected(index: int) -> void:
	if not selected_unit or not is_instance_valid(selected_unit):
		return
	
	var anim_name := ui_manager.get_selected_animation_name()
	if not anim_name.is_empty():
		selected_unit.force_play_animation(anim_name)

func _on_play_pause_pressed() -> void:
	if not selected_unit or not is_instance_valid(selected_unit):
		return
	
	if selected_unit.active_sprite:
		if selected_unit.active_sprite.is_playing():
			selected_unit.pause_animation()
		else:
			selected_unit.resume_animation()

func _on_step_forward_pressed() -> void:
	if not selected_unit or not is_instance_valid(selected_unit):
		return
	selected_unit.step_frame_forward()

func _on_step_back_pressed() -> void:
	if not selected_unit or not is_instance_valid(selected_unit):
		return
	selected_unit.step_frame_back()

func _on_8way_test_pressed() -> void:
	if not selected_unit or not is_instance_valid(selected_unit):
		return
	
	# Clear previous 8-way test
	for unit in debug_8way_units:
		if is_instance_valid(unit) and unit in units:
			units.erase(unit)
			unit.queue_free()
	debug_8way_units.clear()
	
	var unit_type := selected_unit.unit_type
	var center := CAMERA_CENTER
	var radius := 120.0
	var directions := ["e", "se", "s", "sw", "w", "nw", "n", "ne"]
	var angles := [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]
	
	for i in range(8):
		var angle := deg_to_rad(angles[i])
		var pos := center + Vector2(cos(angle), sin(angle)) * radius
		var unit := _spawn_unit(unit_type, 1, pos)
		if unit:
			unit.set_facing(directions[i])
			unit.force_play_animation("idle_e")
			debug_8way_units.append(unit)
	
	print("8-way test spawned. All units facing different directions.")
#endregion

func _rebuild_team_caches() -> void:
	## Rebuilds team cache arrays - call when units spawn/die
	_allies_by_team = {1: [], 2: []}
	_enemies_by_team = {1: [], 2: []}
	
	for unit in units:
		if not is_instance_valid(unit) or unit.is_dead:
			continue
		if unit.team == 1:
			_allies_by_team[1].append(unit)
			_enemies_by_team[2].append(unit)
		else:
			_allies_by_team[2].append(unit)
			_enemies_by_team[1].append(unit)
	
	# Update cached references for each unit
	for unit in units:
		if is_instance_valid(unit):
			unit._cached_allies = _allies_by_team[unit.team]
			unit._cached_enemies = _enemies_by_team[unit.team]
	
	_team_caches_dirty = false
#endregion Main Loop

#region Process
func _process(_delta: float) -> void:
	# Rebuild caches if needed (only when units spawn/die, not every frame)
	if _team_caches_dirty:
		_rebuild_team_caches()
	
	# Update animation debugger for selected unit
	var safe_selected: ArenaUnit = null
	if selected_unit != null and is_instance_valid(selected_unit):
		if not selected_unit.is_queued_for_deletion():
			safe_selected = selected_unit
		else:
			selected_unit = null
			if _anim_debug_overlay:
				_anim_debug_overlay.detach()
	
	ui_manager.update_animation_debugger(safe_selected)

func _draw() -> void:
	if show_target_lines:
		_draw_target_lines()
	if show_attack_ranges:
		_draw_attack_ranges()

func _draw_target_lines() -> void:
	for unit in units:
		if not is_instance_valid(unit) or unit.is_dead:
			continue
		if unit.target and is_instance_valid(unit.target):
			draw_line(unit.position, unit.target.position, Color(1, 0, 0, 0.5), 2)

func _draw_attack_ranges() -> void:
	for unit in units:
		if not is_instance_valid(unit) or unit.is_dead:
			continue
		var color := Color(1, 0, 0, 0.2) if unit.team == 1 else Color(0, 0, 1, 0.2)
		draw_circle(unit.position, unit.attack_range, color)
#endregion

#region Helpers
func is_in_bounds(pos: Vector2) -> bool:
	return ARENA_BOUNDS.has_point(pos)

func _print_help() -> void:
	print("""
=== COMBAT LAB CONTROLS ===

SPAWNING:
- Select unit type from dropdown
- Click in arena to spawn
- Adjust count/team/formation in left panel
- Use preset buttons for quick scenarios

SELECTION:
- Left-click unit to select
- Delete: Remove selected unit
- Ctrl+C: Clone selected unit
- R: Respawn selected unit (fresh instance)
- Ctrl+R: Clear all units

DEBUG OVERLAYS:
- F1: Toggle state labels (IDLE/ATTACK/HURT/DEAD + HP)
- F2: Toggle target lines
- F3: Toggle attack range circles
- F4: Toggle 1-HP mode (all units die in one hit)
- F5: Toggle grid overlay on selected unit (for sprite alignment)

	AGGRO CONTROL:
	- "Stop Aggro" button in Spawn Panel stops all combat
	- Units will idle until "Resume Aggro" is clicked

TIME CONTROL:
- Space: Pause/unpause
- Shift + Mouse Wheel: Adjust speed (0.1x - 2.0x)

ANIMATION DEBUGGER:
- Select a unit to see animation controls
- Use dropdown to switch animations
- Play/Pause/Step buttons for frame control
- "8-Way Test" spawns 8 units facing all directions

OTHER:
- H: Show this help
- Esc: Quit
""")
#endregion
