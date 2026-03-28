# TinyRPGFullTest.gd
# Test scene for all 10 Tiny RPG Full Pack characters

extends Node2D

@onready var characters_node: Node2D = $Characters
@onready var info_label: Label = $UI/Info

var _characters: Array[TinyRPGCharacter] = []
var _selected_char: TinyRPGCharacter = null

func _ready():
	# Hide debug overlay
	var debug = get_node_or_null("/root/DebugOverlay")
	if debug:
		debug.hide()
	
	# Collect all characters
	for child in characters_node.get_children():
		if child is TinyRPGCharacter:
			_characters.append(child)
	
	_update_info()
	print("Loaded " + str(_characters.size()) + " characters")

func _input(event):
	if event is InputEventKey and event.pressed:
		# Number keys 1-0 to select characters
		match event.keycode:
			KEY_1: _select_by_index(0)
			KEY_2: _select_by_index(1)
			KEY_3: _select_by_index(2)
			KEY_4: _select_by_index(3)
			KEY_5: _select_by_index(4)
			KEY_6: _select_by_index(5)
			KEY_7: _select_by_index(6)
			KEY_8: _select_by_index(7)
			KEY_9: _select_by_index(8)
			KEY_0: _select_by_index(9)
			KEY_W: _move(Vector2.UP)
			KEY_S: _move(Vector2.DOWN)
			KEY_A: _move(Vector2.LEFT)
			KEY_D: _move(Vector2.RIGHT)
			KEY_SPACE: _attack("attack01")
			KEY_Q: _attack("attack02")
			KEY_E: _attack("attack03")
			KEY_H: _damage()
			KEY_K: _kill()
			KEY_R: _respawn()

func _select_by_index(index: int):
	if index < _characters.size():
		_selected_char = _characters[index]
		_update_info()
		print("Selected: " + _selected_char.name)

func _move(dir: Vector2):
	if _selected_char and not _selected_char.is_dead:
		_selected_char.move(dir)
		await get_tree().create_timer(0.2).timeout
		if _selected_char:
			_selected_char.stop()

func _attack(anim: String):
	if _selected_char and not _selected_char.is_dead:
		_selected_char.attack(anim)

func _damage():
	if _selected_char and not _selected_char.is_dead:
		_selected_char.take_damage(25)
		_update_info()

func _kill():
	if _selected_char and not _selected_char.is_dead:
		_selected_char.die()
		_update_info()

func _respawn():
	if _selected_char and _selected_char.is_dead:
		_selected_char.respawn()
		_update_info()

func _update_info():
	var text = "Characters:\n"
	for i in range(_characters.size()):
		var char = _characters[i]
		var marker = "> " if char == _selected_char else "  "
		var num = i + 1 if i < 9 else 0
		var status = "DEAD" if char.is_dead else str(char.current_health) + "/" + str(char.max_health)
		text += marker + str(num) + ". " + char.name + " (" + status + ")\n"
	info_label.text = text
