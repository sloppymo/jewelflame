# TinyRPGCharacterTest.gd
#
# Purpose: Test scene for Tiny RPG characters
# Usage: Press keys to test different animations

extends Node2D

@onready var soldier: TinyRPGCharacter = $Soldier
@onready var orc: TinyRPGCharacter = $Orc
@onready var log_label: Label = $UI/LogLabel

var _selected_char: TinyRPGCharacter = null

func _ready():
	# Hide debug overlay and other interfering UI
	var debug = get_node_or_null("/root/DebugOverlay")
	if debug:
		debug.hide()
	
	await get_tree().create_timer(0.5).timeout
	
	_log("Tiny RPG Character Test")
	_log("=======================")
	_log("Characters loaded!")
	_log("1: Select Soldier (left)")
	_log("2: Select Orc (right)")
	_log("WASD: Move selected")
	_log("Space: Attack 01")
	_log("H: Take damage")
	
	# Auto-select soldier
	_select_character(soldier)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_select_character(soldier)
			KEY_2:
				_select_character(orc)
			KEY_W, KEY_UP:
				_move(Vector2.UP)
			KEY_S, KEY_DOWN:
				_move(Vector2.DOWN)
			KEY_A, KEY_LEFT:
				_move(Vector2.LEFT)
			KEY_D, KEY_RIGHT:
				_move(Vector2.RIGHT)
			KEY_SPACE:
				_attack("attack01")
			KEY_Q:
				_attack("attack02")
			KEY_E:
				_attack("attack03")
			KEY_H:
				_damage()
			KEY_K:
				_kill()
			KEY_R:
				_respawn()

func _select_character(char: TinyRPGCharacter) -> void:
	_selected_char = char
	var name = "Soldier" if char == soldier else "Orc"
	_log("Selected: " + name)
	
	# Visual indicator
	if char == soldier:
		soldier.modulate = Color(1.2, 1.2, 1.2)
		orc.modulate = Color(1, 1, 1)
	else:
		orc.modulate = Color(1.2, 1.2, 1.2)
		soldier.modulate = Color(1, 1, 1)

func _move(dir: Vector2) -> void:
	if _selected_char:
		_selected_char.move(dir)
		_log("Move: " + str(dir))

func _stop() -> void:
	if _selected_char:
		_selected_char.stop()

func _attack(type: String) -> void:
	if _selected_char:
		_selected_char.attack(type)
		_log("Attack: " + type)

func _damage() -> void:
	if _selected_char:
		_selected_char.take_damage(25, Vector2.RIGHT)
		_log("Took 25 damage")

func _kill() -> void:
	if _selected_char:
		_selected_char.die()
		_log("Died")

func _respawn() -> void:
	if _selected_char and _selected_char.is_dead:
		_selected_char.respawn()
		_log("Respawned")

func _log(text: String) -> void:
	print(text)
	if log_label:
		log_label.text += text + "\n"
