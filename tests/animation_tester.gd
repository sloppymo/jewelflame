extends Node2D

# Universal Animation Tester
# Tests all units with both non-combat and combat sprites
# Supports multiple animation sources for comparison

enum UnitType {
	SWORDSHIELD, ARCHER, KNIGHT, HEAVY_KNIGHT, PALADIN, MAGE, ROGUE, ROGUE_HOODED
}

enum SourceType {
	NC,      # Non-Combat Base
	NC_ALT,  # Non-Combat Alt (if available)
	CO,      # Combat Base
	CO_FX,   # Combat + Effects (if available)
	THRUST_ND, # Thrust Non-Directional
	THRUST_D   # Thrust Directional
}

const UNIT_SCALE = 4.0
const GRID_COLS = 4
const SPACING = 180

var unit_configs := {
	UnitType.SWORDSHIELD: {
		"name": "SwordShield",
		"nc_path": "res://assets/animations/swordshield_non_combat.tres",
		"co_path": "res://assets/animations/swordshield_combat.tres",
		"sources": [SourceType.NC, SourceType.CO]
	},
	UnitType.ARCHER: {
		"name": "Archer",
		"nc_path": "res://assets/animations/archer_non_combat.tres",
		"co_path": "res://assets/animations/archer_combat.tres",
		"sources": [SourceType.NC, SourceType.CO]
	},
	UnitType.KNIGHT: {
		"name": "Knight",
		"nc_path": "res://assets/animations/knight_non_combat.tres",
		"co_path": "res://assets/animations/knight_combat.tres",
		"sources": [SourceType.NC, SourceType.CO]
	},
	UnitType.HEAVY_KNIGHT: {
		"name": "HeavyKnight",
		"nc_path": "res://assets/animations/heavy_knight_non_combat.tres",
		"co_path": "res://assets/animations/heavy_knight_combat.tres",
		"sources": [SourceType.NC, SourceType.CO]
	},
	UnitType.PALADIN: {
		"name": "Paladin",
		"nc_path": "res://assets/animations/paladin_non_combat.tres",
		"co_path": "res://assets/animations/paladin_combat.tres",
		"sources": [SourceType.NC, SourceType.CO]
	},
	UnitType.MAGE: {
		"name": "Mage",
		"nc_path": "res://assets/animations/mage_red_non_combat.tres",
		"co_path": "res://assets/animations/mage_red_combat.tres",
		"sources": [SourceType.NC, SourceType.CO]
	},
	UnitType.ROGUE: {
		"name": "Rogue",
		"nc_path": "res://assets/animations/rogue_nc_daggers.tres",
		"co_path": "res://assets/animations/rogue_combat_fx.tres",
		"sources": [SourceType.NC, SourceType.CO_FX]
	},
	UnitType.ROGUE_HOODED: {
		"name": "RogueHooded",
		"nc_path": "res://assets/animations/rogue_hooded_nc_daggers.tres",
		"co_path": "res://assets/animations/rogue_hooded_combat_fx.tres",
		"sources": [SourceType.NC, SourceType.CO_FX]
	}
}

# Current settings
var current_source: SourceType = SourceType.CO
var current_direction: String = "s"
var current_action: String = "idle"
var show_grid: bool = true
var show_bounds: bool = true

# Display units
var display_units: Array[Dictionary] = []

# UI references
@onready var title_label: Label = $UI/TitleLabel
@onready var controls_label: Label = $UI/ControlsLabel
@onready var info_label: Label = $UI/InfoLabel
@onready var camera: Camera2D = $Camera2D

func _ready():
	_setup_display()
	_update_display()
	_update_ui()

func _setup_display():
	# Create a display unit for each unit type
	for unit_type in unit_configs.keys():
		var config = unit_configs[unit_type]
		_display_unit(unit_type, config)

func _display_unit(unit_type: int, config: Dictionary):
	var idx = display_units.size()
	var col = idx % GRID_COLS
	var row = idx / GRID_COLS
	var pos = Vector2(150 + col * SPACING, 150 + row * SPACING)
	
	# Create unit container
	var unit_node = Node2D.new()
	unit_node.position = pos
	unit_node.name = config.name
	add_child(unit_node)
	
	# Create background
	var bg = ColorRect.new()
	bg.size = Vector2(128, 128)
	bg.position = Vector2(-64, -64)
	bg.color = Color(0.15, 0.15, 0.15, 0.8)
	unit_node.add_child(bg)
	
	# Create grid
	if show_grid:
		var grid = _create_grid()
		unit_node.add_child(grid)
	
	# Create animated sprite
	var sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.scale = Vector2(UNIT_SCALE, UNIT_SCALE)
	unit_node.add_child(sprite)
	
	# Create bounds indicator
	if show_bounds:
		var bounds = _create_bounds_indicator()
		unit_node.add_child(bounds)
	
	# Create label
	var label = Label.new()
	label.name = "Label"
	label.text = config.name
	label.position = Vector2(-60, 70)
	label.add_theme_font_size_override("font_size", 14)
	unit_node.add_child(label)
	
	# Store reference
	display_units.append({
		"type": unit_type,
		"config": config,
		"node": unit_node,
		"sprite": sprite,
		"bg": bg
	})

func _create_grid() -> Node2D:
	var grid = Node2D.new()
	grid.name = "Grid"
	
	# Horizontal lines
	for i in range(9):
		var line = Line2D.new()
		line.width = 1
		line.default_color = Color(0.3, 0.3, 0.3, 0.5)
		var y = -64 + i * 16
		line.add_point(Vector2(-64, y))
		line.add_point(Vector2(64, y))
		grid.add_child(line)
	
	# Vertical lines
	for i in range(9):
		var line = Line2D.new()
		line.width = 1
		line.default_color = Color(0.3, 0.3, 0.3, 0.5)
		var x = -64 + i * 16
		line.add_point(Vector2(x, -64))
		line.add_point(Vector2(x, 64))
		grid.add_child(line)
	
	# Center crosshair
	var cross_v = Line2D.new()
	cross_v.width = 2
	cross_v.default_color = Color(0.5, 0.5, 0.5, 0.8)
	cross_v.add_point(Vector2(0, -64))
	cross_v.add_point(Vector2(0, 64))
	grid.add_child(cross_v)
	
	var cross_h = Line2D.new()
	cross_h.width = 2
	cross_h.default_color = Color(0.5, 0.5, 0.5, 0.8)
	cross_h.add_point(Vector2(-64, 0))
	cross_h.add_point(Vector2(64, 0))
	grid.add_child(cross_h)
	
	return grid

func _create_bounds_indicator() -> Node2D:
	var bounds = Node2D.new()
	bounds.name = "Bounds"
	
	# Frame around 16x16 sprite bounds
	var frame = Line2D.new()
	frame.width = 2
	frame.default_color = Color(0, 1, 0, 0.7)
	var s = 8 * UNIT_SCALE  # Half of 16 * scale
	frame.add_point(Vector2(-s, -s))
	frame.add_point(Vector2(s, -s))
	frame.add_point(Vector2(s, s))
	frame.add_point(Vector2(-s, s))
	frame.add_point(Vector2(-s, -s))
	bounds.add_child(frame)
	
	return bounds

func _update_display():
	for unit in display_units:
		var config = unit.config
		var sprite: AnimatedSprite2D = unit.sprite
		
		# Load appropriate sprite frames based on current source
		var path = ""
		match current_source:
			SourceType.NC, SourceType.NC_ALT:
				path = config.nc_path
			_:
				path = config.co_path
		
		if not FileAccess.file_exists(path):
			unit.bg.color = Color(0.3, 0.1, 0.1, 0.8)
			continue
		
		var frames = load(path)
		sprite.sprite_frames = frames
		
		# Build animation name
		var anim_name = _build_animation_name()
		
		# Play animation using the same logic as battle_arena
		_play_anim(sprite, anim_name, true)
		
		# Update background color based on source
		match current_source:
			SourceType.NC, SourceType.NC_ALT:
				unit.bg.color = Color(0.1, 0.15, 0.2, 0.8)
			_:
				unit.bg.color = Color(0.2, 0.1, 0.1, 0.8)

func _build_animation_name() -> String:
	# Build animation name from current action and direction
	match current_action:
		"idle":
			return "idle_" + current_direction
		"walk":
			return "walk_" + current_direction
		"attack":
			# Return base attack name - _play_anim will find the right variant
			return "attack_" + current_direction
		"hurt":
			return "hurt_" + current_direction
		"death":
			return "death_" + current_direction
		"special":
			return "special_" + current_direction
		_:
			return current_action + "_" + current_direction

func _play_anim(sprite: AnimatedSprite2D, anim_name: String, loop: bool = true):
	if not sprite or not sprite.sprite_frames:
		return
	
	# Try exact match first
	var actual_anim = anim_name
	var is_fallback = false
	var dir = current_direction
	
	if not sprite.sprite_frames.has_animation(actual_anim):
		# Parse animation name
		var parts = anim_name.rsplit("_", true, 1)
		if parts.size() < 2:
			return
		
		var base_name = parts[0]
		dir = parts[1]
		
		# Try various naming patterns
		var candidates = _build_animation_candidates(base_name, dir)
		
		for candidate in candidates:
			if sprite.sprite_frames.has_animation(candidate):
				actual_anim = candidate
				is_fallback = true
				break
		
		if not sprite.sprite_frames.has_animation(actual_anim):
			return  # No suitable animation found
	
	# Apply horizontal flip based on direction
	# Sprites default to facing left, so:
	# Moving right (e, ne, se): flip to face right
	# Moving left (w, nw, sw): already facing left, don't flip
	if dir in ["e", "ne", "se"]:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	
	# If using attack as fallback for walk/idle, pause on first frame
	var using_attack_for_movement = is_fallback and (anim_name.begins_with("walk_") or anim_name.begins_with("idle_")) and actual_anim.begins_with("attack")
	
	if using_attack_for_movement:
		# Play but pause on first frame for static pose
		if sprite.animation != actual_anim:
			sprite.play(actual_anim)
			sprite.pause()
			sprite.frame = 0
		elif sprite.is_playing():
			sprite.pause()
			sprite.frame = 0
	else:
		_play_actual_anim(sprite, actual_anim)

func _build_animation_candidates(base_name: String, dir: String) -> Array[String]:
	var candidates: Array[String] = []
	
	# Map 8-way to cardinal directions
	var card_dir = dir
	if dir in ["ne", "nw"]:
		card_dir = "n"
	elif dir in ["se", "sw"]:
		card_dir = "s"
	
	# Pattern 1: Standard 8-dir (attack1_n, hurt_s, etc.)
	if base_name == "attack":
		for num in ["1", "2", "3"]:
			candidates.append("attack" + num + "_" + dir)
			candidates.append("attack" + num + "_" + card_dir)
		candidates.append("attack_" + dir)
		candidates.append("attack_" + card_dir)
	else:
		candidates.append(base_name + "_" + dir)
		candidates.append(base_name + "_" + card_dir)
	
	# Pattern 2: Knight's light/heavy attacks
	if base_name == "attack":
		for attack_type in ["light", "heavy"]:
			candidates.append("attack_" + attack_type + "_" + dir)
			candidates.append("attack_" + attack_type + "_" + card_dir)
	
	# Pattern 3: 4-dir with descriptive names
	var left_right_map = {
		"n": "up", "ne": "up", "nw": "up",
		"s": "down", "se": "down", "sw": "down",
		"e": "right",
		"w": "left"
	}
	var desc_dir = left_right_map.get(dir, "down")
	var desc_card = left_right_map.get(card_dir, "down")
	
	if base_name == "attack":
		candidates.append("attack_" + desc_dir + "_left")
		candidates.append("attack_" + desc_dir + "_right")
		candidates.append("attack_" + desc_card + "_left")
		candidates.append("attack_" + desc_card + "_right")
		candidates.append("attack_horizontal_left")
		candidates.append("attack_horizontal_right")
		candidates.append("attack_stab_left")
		candidates.append("attack_stab_right")
	else:
		candidates.append(base_name + "_" + desc_dir + "_left")
		candidates.append(base_name + "_" + desc_dir + "_right")
		candidates.append(base_name + "_" + desc_card + "_left")
		candidates.append(base_name + "_" + desc_card + "_right")
		candidates.append(base_name + "_left")
		candidates.append(base_name + "_right")
	
	# Pattern 4: Fallback
	candidates.append(base_name + "_s")
	candidates.append(base_name + "_down")
	candidates.append(base_name + "_down_right")
	candidates.append(base_name)
	
	# Pattern 5: For walk/idle without those animations, use attack as fallback (combat sprites)
	if base_name in ["walk", "idle"]:
		# Try attack animations as fallback for movement
		for num in ["1", "2", "3"]:
			candidates.append("attack" + num + "_" + dir)
			candidates.append("attack" + num + "_" + card_dir)
		candidates.append("attack_" + dir)
		candidates.append("attack_" + card_dir)
		candidates.append("attack_" + desc_dir + "_left")
		candidates.append("attack_" + desc_dir + "_right")
		candidates.append("attack_" + desc_card + "_left")
		candidates.append("attack_" + desc_card + "_right")
		for attack_type in ["light", "heavy"]:
			candidates.append("attack_" + attack_type + "_" + dir)
			candidates.append("attack_" + attack_type + "_" + card_dir)
		candidates.append("attack_horizontal_left")
		candidates.append("attack_horizontal_right")
		candidates.append("attack_stab_left")
		candidates.append("attack_stab_right")
	
	return candidates

func _play_actual_anim(sprite: AnimatedSprite2D, actual_anim: String):
	if sprite.animation != actual_anim:
		sprite.play(actual_anim)
	elif not sprite.is_playing():
		sprite.play(actual_anim)

func _update_ui():
	var source_name = SourceType.keys()[current_source]
	var action_display = current_action.to_upper()
	var dir_display = current_direction.to_upper()
	
	title_label.text = "Animation Tester - %s | %s | %s" % [source_name, action_display, dir_display]
	
	controls_label.text = """Controls:
[Q/E] Source: %s
[1-8] Unit Type | [0] All
[ARROWS] Direction | [SPACE] Play
[I] Idle [W] Walk [A] Attack [H] Hurt [D] Death [S] Special
[G] Grid [%s] | [B] Bounds [%s] | [R] Reset Camera
[Z/X] Zoom | [ESC] Exit""" % [
		source_name, 
		"ON" if show_grid else "OFF",
		"ON" if show_bounds else "OFF"
	]
	
	# Count available animations
	var info = "Available: "
	for unit in display_units:
		if not unit.sprite.sprite_frames:
			continue
		var frames = unit.sprite.sprite_frames
		var anim_name = _build_animation_name()
		
		# Check using same logic as _play_anim
		var found = false
		if frames.has_animation(anim_name):
			found = true
		else:
			var parts = anim_name.rsplit("_", true, 1)
			if parts.size() >= 2:
				var candidates = _build_animation_candidates(parts[0], parts[1])
				for candidate in candidates:
					if frames.has_animation(candidate):
						found = true
						break
		
		if found:
			info += unit.config.name + "✓ "
		else:
			info += unit.config.name + "✗ "
	info_label.text = info

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				get_tree().quit()
			
			# Source selection
			KEY_Q:
				current_source = (current_source - 1) as SourceType
				if current_source < 0:
					current_source = SourceType.THRUST_D
				_update_display()
			KEY_E:
				current_source = (current_source + 1) as SourceType
				if current_source > SourceType.THRUST_D:
					current_source = SourceType.NC
				_update_display()
			
			# Direction
			KEY_UP:
				current_direction = "n"
				_update_display()
			KEY_DOWN:
				current_direction = "s"
				_update_display()
			KEY_LEFT:
				current_direction = "w"
				_update_display()
			KEY_RIGHT:
				current_direction = "e"
				_update_display()
			
			# Diagonals
			KEY_KP_7, KEY_HOME:
				current_direction = "nw"
				_update_display()
			KEY_KP_9, KEY_PAGEUP:
				current_direction = "ne"
				_update_display()
			KEY_KP_1, KEY_END:
				current_direction = "sw"
				_update_display()
			KEY_KP_3, KEY_PAGEDOWN:
				current_direction = "se"
				_update_display()
			
			# Actions
			KEY_I:
				current_action = "idle"
				_update_display()
			KEY_W:
				current_action = "walk"
				_update_display()
			KEY_A:
				current_action = "attack"
				_update_display()
			KEY_H:
				current_action = "hurt"
				_update_display()
			KEY_D:
				current_action = "death"
				_update_display()
			KEY_S:
				current_action = "special"
				_update_display()
			
			# Replay
			KEY_SPACE:
				_update_display()
			
			# Toggles
			KEY_G:
				show_grid = not show_grid
				for unit in display_units:
					var grid = unit.node.get_node_or_null("Grid")
					if grid:
						grid.visible = show_grid
			KEY_B:
				show_bounds = not show_bounds
				for unit in display_units:
					var bounds = unit.node.get_node_or_null("Bounds")
					if bounds:
						bounds.visible = show_bounds
			
			# Camera
			KEY_R:
				camera.position = Vector2(640, 360)
				camera.zoom = Vector2(1, 1)
			KEY_Z:
				camera.zoom *= 1.1
			KEY_X:
				camera.zoom *= 0.9
	
	_update_ui()

func _process(delta):
	# Camera pan with mouse drag
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mouse_delta = Input.get_last_mouse_velocity()
		camera.position -= mouse_delta * delta / camera.zoom.x
