extends AnimatedSprite2D

@export var team: int = 0
@export var walk_speed: float = 100.0
@export var health: int = 200
@export var attack_damage: int = 15
@export var attack_range: float = 60.0
@export var detection_range: float = 500.0

enum State { IDLE, WALKING, ATTACKING, HURT, DEAD, FLEEING, DISENGAGING }
var current_state: State = State.IDLE
var current_direction: String = "down"
var target: Node2D = null
var all_artuns: Array = []
var state_timer: float = 0.0
var disengage_timer: float = 0.0
var disengage_duration: float = 3.0

# Bark system
var bark_label: Label = null
var bark_timer: float = 0.0
var bark_messages: Array = [
	"Oof!",
	"Take this!",
	"Yikes!",
	"Gotcha!",
	"Ow!",
	"Hiyah!",
	"Run!",
	"Not today!",
	"Aha!",
	"Ugh!",
	"Hey!",
	"Stop!"
]

func _ready():
	add_to_group("artun_combat")
	call_deferred("find_targets")
	call_deferred("setup_bark_label")
	change_state(State.IDLE)

func setup_bark_label():
	bark_label = Label.new()
	bark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bark_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bark_label.add_theme_font_size_override("font_size", 10)
	bark_label.modulate = Color(1, 1, 1)
	bark_label.visible = false
	
	# Remove background
	var empty_style = StyleBoxEmpty.new()
	bark_label.add_theme_stylebox_override("normal", empty_style)
	
	add_child(bark_label)

func show_bark(message: String = ""):
	if message == "":
		message = bark_messages[randi() % bark_messages.size()]
	
	if bark_label:
		bark_label.text = message
		bark_label.visible = true
		bark_label.modulate.a = 1.0
		bark_timer = 1.5
		
		# Force size update then position above head
		bark_label.reset_size()
		bark_label.position = Vector2(-bark_label.size.x / 2, -50)

func find_targets():
	all_artuns = get_tree().get_nodes_in_group("artun_combat")
	all_artuns.erase(self)

func change_state(new_state: State):
	current_state = new_state
	state_timer = 0.0
	
	match current_state:
		State.IDLE:
			play("idle_" + current_direction)
		State.WALKING:
			play("walk_" + current_direction)
		State.ATTACKING:
			play("attack_" + current_direction)
		State.HURT:
			play("hurt_" + current_direction)
		State.DEAD:
			play("dead")
			modulate = Color(0.5, 0.5, 0.5, 0.7)
		State.FLEEING:
			play("walk_" + current_direction)
		State.DISENGAGING:
			play("walk_" + current_direction)

func _process(delta):
	# Handle bark timer
	if bark_timer > 0:
		bark_timer -= delta
		if bark_label:
			if bark_timer <= 0.3:
				bark_label.modulate.a = bark_timer / 0.3
			else:
				bark_label.modulate.a = 1.0
			
			# Keep bark positioned above head
			bark_label.position = Vector2(-bark_label.size.x / 2, -50)
		
		if bark_timer <= 0:
			bark_label.visible = false
			bark_label.modulate.a = 1.0
	
	if current_state == State.DEAD:
		return
	
	state_timer += delta
	disengage_timer += delta
	
	# Check if should disengage
	if disengage_timer >= 5.0 and current_state != State.DISENGAGING and current_state != State.IDLE:
		disengage_timer = 0.0
		change_state(State.DISENGAGING)
		show_bark("Break!")
		return
	
	match current_state:
		State.IDLE:
			_update_idle(delta)
		State.WALKING:
			_update_walking(delta)
		State.ATTACKING:
			_update_attacking(delta)
		State.HURT:
			_update_hurt(delta)
		State.FLEEING:
			_update_fleeing(delta)
		State.DISENGAGING:
			_update_disengaging(delta)

func _update_idle(delta):
	target = find_closest_enemy()
	
	if target and global_position.distance_to(target.global_position) < detection_range:
		if health < 50 and randf() < 0.3:
			change_state(State.FLEEING)
			show_bark("Run!")
		else:
			change_state(State.WALKING)
	else:
		if randf() < 0.015:
			pick_random_direction()
			change_state(State.WALKING)

func _update_walking(delta):
	if not is_instance_valid(target) or target.current_state == State.DEAD:
		target = find_closest_enemy()
		if not target:
			change_state(State.IDLE)
			return
	
	var dist = global_position.distance_to(target.global_position)
	
	if dist < attack_range:
		change_state(State.ATTACKING)
		show_bark()
		return
	
	var dir = global_position.direction_to(target.global_position)
	_update_direction(dir)
	global_position += dir * walk_speed * delta
	play("walk_" + current_direction)

func _update_attacking(delta):
	if state_timer >= 0.2 and state_timer < 0.3:
		if is_instance_valid(target) and global_position.distance_to(target.global_position) < attack_range + 30:
			target.take_damage(attack_damage)
	
	if not is_playing() or state_timer >= 0.5:
		if health < 40 and randf() < 0.3:
			change_state(State.FLEEING)
			show_bark("Retreat!")
		else:
			change_state(State.IDLE)

func _update_hurt(delta):
	if not is_playing() or state_timer >= 0.4:
		if health <= 0:
			spawn_death_blood()
			show_bark("Argh...")
			change_state(State.DEAD)
		elif health < 50 and randf() < 0.4:
			change_state(State.FLEEING)
			show_bark("Flee!")
		else:
			change_state(State.IDLE)

func _update_fleeing(delta):
	var enemy = find_closest_enemy()
	if enemy:
		var dir = global_position.direction_to(enemy.global_position) * -1
		_update_direction(dir)
		global_position += dir * walk_speed * 1.3 * delta
		play("walk_" + current_direction)
		
		if global_position.distance_to(enemy.global_position) > detection_range * 0.6 or state_timer > 2.0:
			change_state(State.IDLE)
	else:
		change_state(State.IDLE)

func _update_disengaging(delta):
	# Walk away from current target for 3 seconds
	if state_timer >= disengage_duration:
		change_state(State.IDLE)
		return
	
	if is_instance_valid(target):
		var dir = global_position.direction_to(target.global_position) * -1
		_update_direction(dir)
		global_position += dir * walk_speed * 1.2 * delta
		play("walk_" + current_direction)
	else:
		# No target, just walk in current direction
		var move_dir = Vector2.ZERO
		match current_direction:
			"up": move_dir = Vector2(0, -1)
			"down": move_dir = Vector2(0, 1)
			"left": move_dir = Vector2(-1, 0)
			"right": move_dir = Vector2(1, 0)
		
		global_position += move_dir * walk_speed * delta
		play("walk_" + current_direction)

func pick_random_direction():
	var dirs = ["up", "down", "left", "right"]
	current_direction = dirs[randi() % dirs.size()]

func find_closest_enemy() -> Node2D:
	var closest = null
	var closest_dist = detection_range
	
	for artun in all_artuns:
		if is_instance_valid(artun) and artun.team != team and artun.current_state != State.DEAD:
			var dist = global_position.distance_to(artun.global_position)
			if dist < closest_dist:
				closest = artun
				closest_dist = dist
	
	return closest

func _update_direction(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		current_direction = "right" if dir.x > 0 else "left"
	else:
		current_direction = "down" if dir.y > 0 else "up"

func spawn_blood():
	var blood = preload("res://scenes/effects/pixel_blood.tscn").instantiate()
	blood.position = position + Vector2(randi() % 20 - 10, randi() % 10)
	get_parent().add_child(blood)

func spawn_death_blood():
	for i in range(4):
		var blood = preload("res://scenes/effects/pixel_blood.tscn").instantiate()
		blood.position = position + Vector2(randi() % 60 - 30, randi() % 30 - 15)
		get_parent().add_child(blood)

func take_damage(damage: int):
	if current_state == State.DEAD:
		return
	
	health -= damage
	spawn_blood()
	
	# Flash white on hit
	modulate = Color(1.5, 1.5, 1.5)
	await get_tree().create_timer(0.08).timeout
	modulate = Color(1, 1, 1)
	
	# Random hurt bark
	if randf() < 0.5:
		var hurt_barks = ["Ow!", "Ouch!", "Hey!", "Ugh!"]
		show_bark(hurt_barks[randi() % hurt_barks.size()])
	
	change_state(State.HURT)
