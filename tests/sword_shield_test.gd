extends Node2D

@onready var unit: SwordShieldUnit = $SwordShieldUnit

func _ready() -> void:
	print("Sword & Shield test ready. Troops: ", unit.current_troops)

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
				unit.set_state(SwordShieldUnit.State.ATTACKING)
				print("Attack triggered")
			KEY_4:
				unit.set_state(SwordShieldUnit.State.HURT)
				print("Hurt triggered")
			KEY_R:
				get_tree().reload_current_scene()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			unit.move_toward_target(get_global_mouse_position())
