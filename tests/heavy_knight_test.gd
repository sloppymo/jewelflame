extends Node2D

@onready var knight: HeavyKnight = $HeavyKnight

func _ready() -> void:
	print("Heavy Knight test ready")

func _process(delta: float) -> void:
	# Movement input
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right"): dir.x += 1
	if Input.is_action_pressed("ui_left"):  dir.x -= 1
	if Input.is_action_pressed("ui_down"):  dir.y += 1
	if Input.is_action_pressed("ui_up"):    dir.y -= 1

	if dir != Vector2.ZERO:
		var spd := knight.run_speed if Input.is_key_pressed(KEY_SHIFT) else knight.move_speed
		knight.velocity = dir.normalized() * spd
		knight.set_state(HeavyKnight.State.RUNNING if Input.is_key_pressed(KEY_SHIFT) else HeavyKnight.State.WALKING)
	else:
		knight.velocity = Vector2.ZERO
		if knight.current_state in [HeavyKnight.State.WALKING, HeavyKnight.State.RUNNING]:
			knight.set_state(HeavyKnight.State.IDLE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_Z:
				knight.set_state(HeavyKnight.State.ATTACKING)
				print("Attack!")
			KEY_X:
				knight.thrust_attack()
				print("Thrust!")
			KEY_C:
				if knight.is_blocking:
					knight.stop_blocking()
				else:
					knight.set_state(HeavyKnight.State.BLOCKING)
				print("Block toggle")
			KEY_V:
				knight.set_state(HeavyKnight.State.ROLLING)
				print("Roll!")
			KEY_H:
				knight.take_damage(10)
				print("Hurt!")
			KEY_K:
				knight.set_state(HeavyKnight.State.DEAD)
				print("Death!")
			KEY_T:
				knight.use_dash_thrust = not knight.use_dash_thrust
				print("Thrust mode: ", "DASH" if knight.use_dash_thrust else "NO-DASH")
			KEY_R:
				get_tree().reload_current_scene()
