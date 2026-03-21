extends Node2D

## Universal Animation Tester - Test all units and their animations

enum UnitType { SWORDSHIELD, ARCHER, KNIGHT, HEAVY_KNIGHT, PALADIN }

var current_unit: UnitType = UnitType.SWORDSHIELD
var current_anim_index: int = 0
var animation_names: Array[String] = []
var sprite: AnimatedSprite2D = null

# Unit configurations
var unit_configs := {
	UnitType.SWORDSHIELD: {
		"name": "Sword & Shield",
		"nc_path": "res://assets/animations/swordshield_non_combat.tres",
		"co_path": "res://assets/animations/swordshield_combat.tres",
		"frame_size": "16x16 / 32x32",
		"directions": "8-dir (s,n,se,ne,e,w,sw,nw)"
	},
	UnitType.ARCHER: {
		"name": "Archer",
		"nc_path": "res://assets/animations/archer_non_combat.tres",
		"co_path": "res://assets/animations/archer_combat.tres",
		"frame_size": "16x16 / 32x32",
		"directions": "8-dir (s,n,se,ne,e,w,sw,nw)"
	},
	UnitType.KNIGHT: {
		"name": "Knight (2H Sword)",
		"nc_path": "res://assets/animations/knight_non_combat.tres",
		"co_path": "res://assets/animations/knight_combat.tres",
		"frame_size": "16x16 / 32x32",
		"directions": "8-dir (s,n,se,ne,e,w,sw,nw)"
	},
	UnitType.HEAVY_KNIGHT: {
		"name": "Heavy Knight",
		"nc_path": "res://assets/animations/heavy_knight_non_combat.tres",
		"co_path": "res://assets/animations/heavy_knight_combat.tres",
		"thrust_nd": "res://assets/animations/heavy_knight_thrust_nodash.tres",
		"thrust_d": "res://assets/animations/heavy_knight_thrust_dash.tres",
		"frame_size": "24x24 / 32x32",
		"directions": "4-dir (down,up,right,left) + thrust 4-dir"
	},
	UnitType.PALADIN: {
		"name": "Paladin",
		"nc_path": "res://assets/animations/paladin_non_combat.tres",
		"co_path": "res://assets/animations/paladin_combat.tres",
		"thrust_nd": "res://assets/animations/paladin_thrust_nodash.tres",
		"thrust_d": "res://assets/animations/paladin_thrust_dash.tres",
		"frame_size": "24x24 / 32x32",
		"directions": "4-dir (down,up,right,left) + thrust 4-dir"
	}
}

@onready var info_label: Label = $UI/InfoLabel
@onready var anim_list_label: Label = $UI/AnimListLabel
@onready var debug_label: Label = $UI/DebugLabel
@onready var controls_label: Label = $UI/ControlsLabel

func _ready():
	print("Animation Tester Ready")
	_setup_sprite()
	_refresh_animation_list()
	_update_display()

func _setup_sprite():
	if sprite:
		sprite.queue_free()
	
	sprite = AnimatedSprite2D.new()
	sprite.name = "TestSprite"
	sprite.scale = Vector2(4, 4)  # Scale up for visibility
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(640, 360)
	add_child(sprite)
	
	_load_unit_frames()

func _load_unit_frames():
	var config = unit_configs[current_unit]
	var nc_frames = load(config["nc_path"])
	
	if nc_frames == null:
		push_error("Failed to load: " + config["nc_path"])
		return
	
	sprite.sprite_frames = nc_frames
	
	# For Heavy Knight, we have multiple frame resources
	# For now, just show the non-combat one
	
	print("Loaded: " + config["name"])

func _refresh_animation_list():
	if sprite.sprite_frames == null:
		return
	
	animation_names.clear()
	for anim_name in sprite.sprite_frames.get_animation_names():
		animation_names.append(anim_name)
	animation_names.sort()
	
	# Reset index if out of bounds
	if current_anim_index >= animation_names.size():
		current_anim_index = 0

func _update_display():
	if animation_names.is_empty():
		return
	
	var config = unit_configs[current_unit]
	var current_anim = animation_names[current_anim_index]
	
	# Main info
	info_label.text = """UNIT: %s
Frame Size: %s
Directions: %s
Animations: %d""" % [
		config["name"],
		config["frame_size"],
		config["directions"],
		animation_names.size()
	]
	
	# Animation list (show context around current)
	var list_text := "ANIMATIONS (%d/%d):\n\n" % [current_anim_index + 1, animation_names.size()]
	
	var start_idx = max(0, current_anim_index - 5)
	var end_idx = min(animation_names.size(), current_anim_index + 6)
	
	for i in range(start_idx, end_idx):
		var prefix := ">>> " if i == current_anim_index else "    "
		list_text += prefix + animation_names[i] + "\n"
	
	anim_list_label.text = list_text
	
	# Debug info
	var frame_count = sprite.sprite_frames.get_frame_count(current_anim)
	var current_frame = sprite.frame if sprite.is_playing() else 0
	var is_looping = sprite.sprite_frames.get_animation_loop(current_anim)
	var speed = sprite.sprite_frames.get_animation_speed(current_anim)
	
	debug_label.text = """CURRENT: %s
Frame: %d / %d
Speed: %.1f FPS
Loop: %s
Playing: %s""" % [
		current_anim,
		current_frame,
		frame_count,
		speed,
		"Yes" if is_looping else "No",
		"Yes" if sprite.is_playing() else "No"
	]

func _process(_delta):
	_update_display()

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			# Unit switching
			KEY_1:
				_switch_unit(UnitType.SWORDSHIELD)
			KEY_2:
				_switch_unit(UnitType.ARCHER)
			KEY_3:
				_switch_unit(UnitType.KNIGHT)
			KEY_4:
				_switch_unit(UnitType.HEAVY_KNIGHT)
			KEY_5:
				_switch_unit(UnitType.PALADIN)
			
			# Animation navigation
			KEY_UP:
				_prev_anim()
			KEY_DOWN:
				_next_anim()
			KEY_PAGEUP:
				_prev_anim_10()
			KEY_PAGEDOWN:
				_next_anim_10()
			
			# Playback
			KEY_SPACE:
				_play_current()
			KEY_P:
				_toggle_pause()
			KEY_S:
				_stop()
			KEY_L:
				_toggle_loop()
			
			# Speed
			KEY_EQUAL:
				_speed_up()
			KEY_MINUS:
				_speed_down()
			KEY_0:
				_speed_reset()
			
			# Frame stepping
			KEY_RIGHT:
				_frame_forward()
			KEY_LEFT:
				_frame_back()
			
			# Scale
			KEY_BRACKETLEFT:
				_scale_down()
			KEY_BRACKETRIGHT:
				_scale_up()
			
			# Background
			KEY_B:
				_toggle_bg()
			
			# Reset
			KEY_R:
				_reset()
			
			# Quit
			KEY_ESCAPE:
				get_tree().quit()

func _switch_unit(unit_type: UnitType):
	current_unit = unit_type
	current_anim_index = 0
	_setup_sprite()
	_refresh_animation_list()
	print("Switched to: " + unit_configs[current_unit]["name"])

func _prev_anim():
	current_anim_index = wrapi(current_anim_index - 1, 0, animation_names.size())
	_play_current()

func _next_anim():
	current_anim_index = wrapi(current_anim_index + 1, 0, animation_names.size())
	_play_current()

func _prev_anim_10():
	current_anim_index = wrapi(current_anim_index - 10, 0, animation_names.size())
	_play_current()

func _next_anim_10():
	current_anim_index = wrapi(current_anim_index + 10, 0, animation_names.size())
	_play_current()

func _play_current():
	if animation_names.is_empty():
		return
	var anim_name = animation_names[current_anim_index]
	sprite.play(anim_name)
	print("Playing: " + anim_name)

func _toggle_pause():
	if sprite.is_playing():
		sprite.pause()
		print("Paused")
	else:
		sprite.play()
		print("Resumed")

func _stop():
	sprite.stop()
	sprite.frame = 0
	print("Stopped")

func _toggle_loop():
	if animation_names.is_empty():
		return
	var anim_name = animation_names[current_anim_index]
	var current_loop = sprite.sprite_frames.get_animation_loop(anim_name)
	sprite.sprite_frames.set_animation_loop(anim_name, not current_loop)
	print("Loop: " + str(not current_loop))

func _speed_up():
	if animation_names.is_empty():
		return
	var anim_name = animation_names[current_anim_index]
	var current_speed = sprite.sprite_frames.get_animation_speed(anim_name)
	sprite.sprite_frames.set_animation_speed(anim_name, current_speed + 2.0)
	print("Speed: " + str(current_speed + 2.0))

func _speed_down():
	if animation_names.is_empty():
		return
	var anim_name = animation_names[current_anim_index]
	var current_speed = sprite.sprite_frames.get_animation_speed(anim_name)
	sprite.sprite_frames.set_animation_speed(anim_name, max(1.0, current_speed - 2.0))
	print("Speed: " + str(max(1.0, current_speed - 2.0)))

func _speed_reset():
	if animation_names.is_empty():
		return
	var anim_name = animation_names[current_anim_index]
	sprite.sprite_frames.set_animation_speed(anim_name, 10.0)
	print("Speed reset to 10.0")

func _frame_forward():
	sprite.pause()
	var anim_name = animation_names[current_anim_index]
	var frame_count = sprite.sprite_frames.get_frame_count(anim_name)
	sprite.frame = wrapi(sprite.frame + 1, 0, frame_count)

func _frame_back():
	sprite.pause()
	var anim_name = animation_names[current_anim_index]
	var frame_count = sprite.sprite_frames.get_frame_count(anim_name)
	sprite.frame = wrapi(sprite.frame - 1, 0, frame_count)

func _scale_up():
	sprite.scale *= 1.2
	print("Scale: " + str(sprite.scale))

func _scale_down():
	sprite.scale *= 0.8
	print("Scale: " + str(sprite.scale))

func _toggle_bg():
	var bg = $Background
	if bg:
		bg.visible = not bg.visible

func _reset():
	sprite.scale = Vector2(4, 4)
	sprite.position = Vector2(640, 360)
	current_anim_index = 0
	_play_current()
	print("Reset")
