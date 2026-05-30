class_name CombatLabUIManager
extends Node
## Manages all UI updates for the Combat Lab.

const ArenaUnit := preload("res://tests/arena_unit.gd")

#region References (set by owner)
var ui: CanvasLayer = null
var spawn_panel: Panel = null
var anim_debugger: Panel = null
var debug_panel: Panel = null
#endregion

#region Private State
var _label_pool: Array[Label] = []
var _label_pool_size: int = 100
var _active_labels: Dictionary[int, Label] = {}
var _last_dropdown_unit: ArenaUnit = null
var _dropdown_populated: bool = false
var _spell_cast_timer: Timer = null
var _on_spell_cast_fade: Callable
#endregion

#region Initialization
func initialize(p_ui: CanvasLayer) -> void:
	ui = p_ui
	spawn_panel = %SpawnPanel
	anim_debugger = %AnimationDebugger
	debug_panel = %DebugPanel
	
	_init_label_pool()
	_populate_unit_dropdown()
	_populate_formation_dropdown()
	
	# Initialize spell cast timer (reused, not recreated)
	_spell_cast_timer = Timer.new()
	_spell_cast_timer.one_shot = true
	_spell_cast_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	ui.add_child(_spell_cast_timer)

func _init_label_pool() -> void:
	## Pre-create labels to avoid runtime allocation
	for i in range(_label_pool_size):
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.hide()
		_label_pool.append(label)

func _populate_unit_dropdown() -> void:
	%UnitDropdown.clear()
	for unit_name in ConfigLoader.get_all_names():
		%UnitDropdown.add_item(unit_name)
	if %UnitDropdown.item_count > 0:
		%UnitDropdown.selected = 0

func _populate_formation_dropdown() -> void:
	%FormationDropdown.clear()
	%FormationDropdown.add_item("random")
	%FormationDropdown.add_item("line")
	%FormationDropdown.add_item("circle")
	%FormationDropdown.add_item("grid")
	%FormationDropdown.selected = 0
#endregion

#region Top Bar Updates
func update_unit_count(count: int) -> void:
	if not ui:
		return
	%UnitCountLabel.text = "Units: %d" % count

func update_speed_label(time_scale: float) -> void:
	if not ui:
		return
	%SpeedLabel.text = "Speed: %.1fx" % time_scale

func show_spell_cast(caster_name: String, spell_name: String, team: int) -> void:
	## Shows a spell cast notification at the top of the screen
	if not ui:
		return
	
	var label := %SpellCastLabel
	
	# Color based on team
	var team_color := "#FF6B6B" if team == 1 else "#6B9EFF"  # Red vs Blue
	
	# Format: "Caster casts Spell!"
	var text := "[color=%s][b]%s[/b][/color] casts [color=#FFD93D][b]%s[/b][/color]!" % [team_color, caster_name, spell_name]
	label.text = text
	label.modulate.a = 1.0
	
	# Stop existing timer and start fresh
	_spell_cast_timer.stop()
	_spell_cast_timer.start(2.5)
	
	# Disconnect any existing fade callback
	if _on_spell_cast_fade.is_valid():
		_spell_cast_timer.timeout.disconnect(_on_spell_cast_fade)
	
	# Setup new fade callback
	_on_spell_cast_fade = func():
		var tween := label.create_tween()
		tween.tween_property(label, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func():
			label.text = ""
			label.modulate.a = 1.0
		)
	
	_spell_cast_timer.timeout.connect(_on_spell_cast_fade, CONNECT_ONE_SHOT)

func update_debug_status(show_state: bool, show_targets: bool, show_ranges: bool, one_hp: bool) -> void:
	if not debug_panel:
		return
	
	var active: Array[String] = []
	if show_state:
		active.append("F1")
	if show_targets:
		active.append("F2")
	if show_ranges:
		active.append("F3")
	if one_hp:
		active.append("F4")
	
	var status_text := ", ".join(active) if active.size() > 0 else "All OFF"
	%StatusLabel.text = status_text
#endregion

#region State Label Management (Event-Driven)
## Creates a state label for a unit when state labels are enabled
func _create_state_label(unit: ArenaUnit) -> void:
	if not is_instance_valid(unit) or unit.is_dead:
		return
	
	var label := _get_or_create_label_for_unit(unit)
	_update_label_text(label, unit)
	label.show()
	
	if not label.get_parent():
		unit.add_child(label)
	label.position = Vector2(-20, -35)

## Removes a unit's state label
func _remove_state_label(unit: ArenaUnit) -> void:
	var id := unit.get_instance_id()
	if _active_labels.has(id):
		var label := _active_labels[id]
		if is_instance_valid(label):
			label.hide()
			if label.get_parent():
				label.get_parent().remove_child(label)
			_label_pool.append(label)
		_active_labels.erase(id)

## Signal handler: Called when a unit's state changes
func _on_unit_state_changed(new_state: ArenaUnit.State, unit: ArenaUnit) -> void:
	if not is_instance_valid(unit):
		return
	
	var id := unit.get_instance_id()
	if not _active_labels.has(id):
		return
	
	var label := _active_labels[id]
	if is_instance_valid(label):
		_update_label_text(label, unit)
		# Hide label if unit is dead
		if unit.is_dead:
			label.hide()
		else:
			label.show()

## Signal handler: Called when a unit's HP changes
func _on_unit_hp_changed(new_hp: int, max_hp: int, unit: ArenaUnit) -> void:
	if not is_instance_valid(unit):
		return
	
	var id := unit.get_instance_id()
	if not _active_labels.has(id):
		return
	
	var label := _active_labels[id]
	if is_instance_valid(label):
		_update_label_text(label, unit)

## Updates label text based on unit state
func _update_label_text(label: Label, unit: ArenaUnit) -> void:
	var state_text := _get_state_text(unit)
	label.text = "%s\nHP:%d/%d" % [state_text, unit.hp, unit.max_hp]

## Gets or creates a label for a unit
func _get_or_create_label_for_unit(unit: ArenaUnit) -> Label:
	var id := unit.get_instance_id()
	if _active_labels.has(id):
		return _active_labels[id]
	
	var label: Label
	if _label_pool.size() > 0:
		label = _label_pool.pop_back()
	else:
		label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_active_labels[id] = label
	return label

## Hides all state labels and returns them to pool
func _hide_all_state_labels() -> void:
	for id in _active_labels.keys():
		var label := _active_labels[id]
		if is_instance_valid(label):
			label.hide()
			if label.get_parent():
				label.get_parent().remove_child(label)
			_label_pool.append(label)
	_active_labels.clear()

## Gets display text for a unit state
func _get_state_text(unit: ArenaUnit) -> String:
	if unit.is_dead:
		return "DEAD"
	match unit.state:
		ArenaUnit.State.IDLE:
			return "IDLE"
		ArenaUnit.State.CHARGE:
			return "CHARGE"
		ArenaUnit.State.ATTACK:
			return "ATTACK"
		ArenaUnit.State.HURT:
			return "HURT"
		_:
			return "UNKNOWN"
#endregion

#region Animation Debugger
func update_animation_debugger(selected_unit: ArenaUnit) -> void:
	if not anim_debugger:
		return
	
	var no_selection := %NoSelectionLabel
	var controls := %Controls
	
	# Extra safety check - sometimes is_instance_valid returns true for freed objects
	var unit_is_valid := false
	if selected_unit != null:
		if is_instance_valid(selected_unit):
			# Try to access a property to confirm it's really valid
			if not selected_unit.is_queued_for_deletion():
				# Final test: access the instance_id (this will crash if truly freed)
				var _test := selected_unit.get_instance_id()
				unit_is_valid = true
	
	if not unit_is_valid:
		no_selection.show()
		controls.hide()
		_last_dropdown_unit = null
		_dropdown_populated = false
		return
	
	no_selection.hide()
	controls.show()
	
	_update_debugger_info(selected_unit)
	_update_animation_dropdown(selected_unit)

func _update_debugger_info(unit: ArenaUnit) -> void:
	var info_label := %InfoLabel
	var anim_label := %AnimLabel
	var frame_data_label := %FrameDataLabel
	
	var frame := unit.get_current_frame()
	var frame_count := unit.get_frame_count()
	
	info_label.text = "%s | Frame: %d/%d | Team: %d" % [unit.config.unit_name, frame + 1, frame_count, unit.team]
	
	if unit.active_sprite:
		anim_label.text = "Anim: %s" % unit.active_sprite.animation
		
		# Update detailed frame data
		if frame_data_label:
			_update_frame_data_label(unit, frame_data_label)

func _update_animation_dropdown(unit: ArenaUnit) -> void:
	if _last_dropdown_unit == unit and _dropdown_populated:
		return
	
	var dropdown := %AnimDropdown
	
	dropdown.clear()
	var anims := unit.get_animation_names()
	for anim in anims:
		dropdown.add_item(anim)
	
	_last_dropdown_unit = unit
	_dropdown_populated = true

func get_selected_animation_index() -> int:
	return %AnimDropdown.selected

func _update_frame_data_label(unit: ArenaUnit, label: Label) -> void:
	## Displays cached frame information
	var data := unit.get_current_frame_data()
	if data.is_empty():
		return
	
	# Build display text using a single format string for efficiency
	var lines: Array[String] = ["Frame Data:"]
	
	var size := data["texture_size"] as Vector2
	lines.append("  Size: %dx%d" % [size.x, size.y])
	lines.append("  FPS: %.1f | Dur: %.3fs" % [data["fps"], data["duration"]])
	
	if data["has_atlas"]:
		var region := data["atlas_region"] as Rect2
		lines.append("  Atlas: (%d, %d)" % [region.position.x, region.position.y])
	
	lines.append("  FlipH: %s | Loop: %s" % [data["flip_h"], data["loop"]])
	
	label.text = "\n".join(lines)

func get_selected_animation_name() -> String:
	var index: int = %AnimDropdown.selected
	if index >= 0 and index < %AnimDropdown.item_count:
		return %AnimDropdown.get_item_text(index)
	return ""
#endregion

#region Spawn Panel Getters
func get_selected_unit_name() -> String:
	if %UnitDropdown.selected >= 0:
		return %UnitDropdown.get_item_text(%UnitDropdown.selected)
	return "Knight"

func get_spawn_count() -> int:
	return int(%CountSpinBox.value)

func get_selected_formation() -> String:
	if %FormationDropdown.selected >= 0:
		return %FormationDropdown.get_item_text(%FormationDropdown.selected)
	return "random"
#endregion

#region Cleanup
func cleanup() -> void:
	_hide_all_state_labels()
	for label in _label_pool:
		if label:
			label.queue_free()
	_label_pool.clear()
#endregion
