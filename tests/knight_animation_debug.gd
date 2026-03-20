extends Node2D

var knight: AnimatedSprite2D
var status_label: Label
var frame_label: Label
var slow_motion: bool = false

func _ready():
	knight = $Knight
	status_label = $UI/Panel/VBox/Status
	frame_label = $FrameCounter
	
	# Connect buttons
	$UI/Panel/VBox/BtnIdle.pressed.connect(_on_idle)
	$UI/Panel/VBox/BtnWalk.pressed.connect(_on_walk)
	$UI/Panel/VBox/BtnAttackLight.pressed.connect(_on_attack_light)
	$UI/Panel/VBox/BtnAttackHeavy.pressed.connect(_on_attack_heavy)
	$UI/Panel/VBox/BtnHurt.pressed.connect(_on_hurt)
	$UI/Panel/VBox/BtnDeath.pressed.connect(_on_death)
	$UI/Panel/VBox/BtnNextDir.pressed.connect(_on_next_dir)
	$UI/Panel/VBox/BtnSlowMo.pressed.connect(_on_slow_mo)
	
	# Draw grid
	_draw_grid()
	
	print("Knight Debug Scene Ready")
	print("Use buttons to test animations")

func _process(_delta):
	if knight and knight.is_playing():
		frame_label.text = "Frame: %d / %d" % [knight.frame, knight.sprite_frames.get_frame_count(knight.animation) - 1]
		$UI/Panel/VBox/Info.text = "Anim: %s\nFrame: %d" % [knight.animation, knight.frame]

func _draw_grid():
	var grid = $Grid
	# Draw vertical lines
	for x in range(-1000, 3000, 100):
		var line = Line2D.new()
		line.points = [Vector2(x, -1000), Vector2(x, 2000)]
		line.default_color = Color(0.7, 0.7, 0.75, 0.3)
		line.width = 1
		grid.add_child(line)
	
	# Draw horizontal lines
	for y in range(-1000, 2000, 100):
		var line = Line2D.new()
		line.points = [Vector2(-1000, y), Vector2(3000, y)]
		line.default_color = Color(0.7, 0.7, 0.75, 0.3)
		line.width = 1
		grid.add_child(line)
	
	# Draw center crosshair
	var h_line = Line2D.new()
	h_line.points = [Vector2(900, 540), Vector2(1020, 540)]
	h_line.default_color = Color(1, 0, 0, 0.5)
	h_line.width = 2
	grid.add_child(h_line)
	
	var v_line = Line2D.new()
	v_line.points = [Vector2(960, 480), Vector2(960, 600)]
	v_line.default_color = Color(1, 0, 0, 0.5)
	v_line.width = 2
	grid.add_child(v_line)

func _on_idle():
	knight.play_animation("idle")

func _on_walk():
	knight.play_animation("walk")

func _on_attack_light():
	knight.play_animation("attack_light")
	print("Playing attack_light_", knight.current_direction)

func _on_attack_heavy():
	knight.play_animation("attack_heavy")
	print("Playing attack_heavy_", knight.current_direction)

func _on_hurt():
	knight.play_animation("hurt")

func _on_death():
	knight.play_animation("death")

func _on_next_dir():
	var new_dir = knight.cycle_direction()
	status_label.text = "Direction: " + new_dir
	print("Direction: ", new_dir)

func _on_slow_mo():
	slow_motion = !slow_motion
	if slow_motion:
		Engine.time_scale = 0.3
		$UI/Panel/VBox/BtnSlowMo.text = "Normal Speed"
	else:
		Engine.time_scale = 1.0
		$UI/Panel/VBox/BtnSlowMo.text = "Toggle Slow Motion"
