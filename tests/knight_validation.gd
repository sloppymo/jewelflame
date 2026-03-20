extends Node2D

# Knight Unit Validation Test Scene
# Tests all functionality before cloning to other units

@onready var knight_unit = $KnightUnit
@onready var status_label = $CanvasLayer/VBoxContainer/StatusLabel
@onready var direction_label = $CanvasLayer/VBoxContainer/DirectionLabel

var direction_index = 0
var directions = ["s", "n", "se", "ne", "e", "w", "sw", "nw"]
var direction_names = ["S", "N", "SE", "NE", "E", "W", "SW", "NW"]

func _ready():
	# Connect knight signals
	if knight_unit:
		knight_unit.unit_selected.connect(_on_unit_selected)
		knight_unit.unit_died.connect(_on_unit_died)
		knight_unit.troops_changed.connect(_on_troops_changed)
		update_status()

func update_status():
	if not knight_unit:
		status_label.text = "Unit: DEAD"
		return
	
	var troops = knight_unit.current_troops
	var max_troops = knight_unit.max_troops
	var damage = knight_unit.calculate_damage()
	var facing = knight_unit.facing_direction.to_upper()
	
	status_label.text = "Troops: %d/%d | Damage: %d | Facing: %s" % [troops, max_troops, damage, facing]

func _on_unit_selected(unit):
	print("Unit selected: ", unit.name)
	update_status()

func _on_unit_died(unit):
	print("Unit died: ", unit.name)
	status_label.text = "Unit: DEAD - Click Reset Unit"

func _on_troops_changed(count):
	print("Troops changed: ", count)
	update_status()

func _on_damage_20_pressed():
	if knight_unit and is_instance_valid(knight_unit):
		knight_unit.take_damage(20)
		update_status()

func _on_damage_40_pressed():
	if knight_unit and is_instance_valid(knight_unit):
		knight_unit.take_damage(40)
		update_status()

func _on_kill_unit_pressed():
	if knight_unit and is_instance_valid(knight_unit):
		# Instakill by dealing massive damage
		knight_unit.take_damage(999)
		update_status()

func _on_reset_unit_pressed():
	# Remove old unit if exists
	if knight_unit and is_instance_valid(knight_unit):
		knight_unit.queue_free()
	
	# Spawn new unit
	var knight_scene = load("res://units/knight_unit.tscn")
	knight_unit = knight_scene.instantiate()
	knight_unit.position = Vector2(576, 324)  # Center of 1152x648 screen
	knight_unit.unit_selected.connect(_on_unit_selected)
	knight_unit.unit_died.connect(_on_unit_died)
	knight_unit.troops_changed.connect(_on_troops_changed)
	add_child(knight_unit)
	
	# Reset direction test
	direction_index = 0
	direction_label.text = "Dir: S (auto)"
	
	update_status()
	print("Unit reset")

func _on_test_directions_pressed():
	if not knight_unit or not is_instance_valid(knight_unit):
		return
	
	# Cycle to next direction
	direction_index = (direction_index + 1) % directions.size()
	var dir = directions[direction_index]
	var dir_name = direction_names[direction_index]
	
	knight_unit.facing_direction = dir
	knight_unit.play_animation("idle")
	
	direction_label.text = "Dir: %s (manual)" % dir_name
	update_status()
	print("Direction set to: ", dir_name)

func _on_attack_pressed():
	if knight_unit and is_instance_valid(knight_unit):
		knight_unit.attack()

func _on_move_northeast_pressed():
	if knight_unit and is_instance_valid(knight_unit):
		knight_unit.velocity = Vector2(1, -1).normalized() * knight_unit.move_speed

func _on_stop_pressed():
	if knight_unit and is_instance_valid(knight_unit):
		knight_unit.velocity = Vector2.ZERO

func _process(_delta):
	# Update status continuously for facing direction changes
	if knight_unit and is_instance_valid(knight_unit):
		update_status()
