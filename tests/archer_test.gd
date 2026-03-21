extends Node2D

@onready var unit: ArcherUnit = $ArcherUnit

func _ready() -> void:
	print("Archer test ready. Troops: ", unit.current_troops)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				unit.take_damage(20)
				print("Troops remaining: ", unit.current_troops)
			KEY_2:
				unit.take_damage(40)
				print("Troops remaining: ", unit.current_troops)
			KEY_3:
				unit.set_state(ArcherUnit.State.ATTACKING)
				print("Shoot triggered — watch for arrow at frame 2")
			KEY_4:
				unit.set_state(ArcherUnit.State.HURT)
				print("Hurt triggered")
			KEY_R:
				get_tree().reload_current_scene()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			unit.move_toward_target(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			unit.fire_at(get_global_mouse_position())
			print("Firing at: ", get_global_mouse_position())
