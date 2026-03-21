extends Node2D

@onready var knight: KnightUnit = $KnightUnit

func _ready() -> void:
	print("Knight Test Ready")
	print("Controls:")
	print("  [1] Remove 1 troop")
	print("  [2] Remove 2 troops")
	print("  [3] Attack")
	print("  [4] Hurt (10 damage)")
	print("  [R] Reset scene")
	print("  [LClick] Move to position")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				knight.current_troops = max(0, knight.current_troops - 1)
				knight._sync_troop_visibility()
				print("Troops: ", knight.current_troops)
			KEY_2:
				knight.current_troops = max(0, knight.current_troops - 2)
				knight._sync_troop_visibility()
				print("Troops: ", knight.current_troops)
			KEY_3:
				knight.set_state(KnightUnit.State.ATTACKING)
				print("Attacking!")
			KEY_4:
				knight.take_damage(10)
				print("Hurt! Troops: ", knight.current_troops)
			KEY_R:
				get_tree().reload_current_scene()
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var target_pos = get_global_mouse_position()
		knight.move_toward_target(target_pos)
		print("Moving to: ", target_pos)

func _process(_delta: float) -> void:
	# Update HUD with current state
	$HUD.text = "Troops: %d/%d | State: %s | Pos: %s\n[1] -1  [2] -2  [3] Attack  [4] Hurt  [R] Reset  [Click] Move" % [
		knight.current_troops,
		knight.max_troops,
		str(knight.current_state),
		str(knight.global_position.round())
	]
