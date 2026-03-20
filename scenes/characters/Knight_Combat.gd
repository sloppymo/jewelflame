extends AnimatedSprite2D

@export var team: int = 0
@export var walk_speed: float = 80.0
@export var health: int = 250
@export var attack_damage: int = 20
@export var attack_range: float = 50.0
@export var detection_range: float = 400.0

enum State { IDLE, WALKING, ATTACKING, HURT, DEAD, FLEEING, DISENGAGING }
var current_state: State = State.IDLE
var current_direction: String = "s"  # s, n, e, w, se, sw, ne, nw
var target: Node2D = null
var all_fighters: Array = []
var state_timer: float = 0.0

# Bark system
var bark_label: Label = null
var bark_timer: float = 0.0
var bark_messages: Array = [
	"For honor!",
	"Charge!",
	"Yield!",
	"Have at thee!",
	"To arms!",
	"En garde!",
	"For the kingdom!",
	"Stand down!"
]

func _ready():
	add_to_group("knight_combat")
	add_to_group("artun_combat")
	call_deferred("find_targets")
	call_deferred("setup_bark_label")
	
	# Build SpriteFrames programmatically
	build_sprite_frames()
	
	change_state(State.IDLE)

func build_sprite_frames():
	# Load textures
	var nc_tex = load("res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Non-Combat.png")
	var c_tex = load("res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Combat.png")
	
	if not nc_tex or not c_tex:
		push_error("Failed to load knight textures")
		return
	
	var sf = SpriteFrames.new()
	
	# CORRECTED direction mapping based on sprite sheet analysis
	# Row order in sprite sheet: s, n, e, w, se, nw, sw, ne
	var dirs = ["s", "n", "e", "w", "se", "nw", "sw", "ne"]
	
	# Non-combat animations (4 frames each)
	# Idle: rows 0-7, Walk: rows 8-15, Run: rows 16-23
	for i in range(8):
		var dir = dirs[i]
		_add_anim(sf, nc_tex, "idle_" + dir, i, 4, 6.0, true)
		_add_anim(sf, nc_tex, "walk_" + dir, i + 8, 4, 10.0, true)
		_add_anim(sf, nc_tex, "run_" + dir, i + 16, 4, 12.0, true)
	
	# Death: rows 24-30 (7 directions, no nw)
	# Using same direction order as other animations
	var death_dirs = ["s", "n", "e", "w", "se", "sw"]  # 6 directions fit in rows 24-29
	# Row 30 might be unused or duplicate - verify visually
	for i in range(6):
		_add_anim(sf, nc_tex, "death_" + death_dirs[i], i + 24, 4, 8.0, false)
	
	# FIXED: Combat animations - use frames with substantial content only
	# Frame analysis shows cols 0, 2, 5, 7 have main content (60+ pixels)
	# Cols 1, 3, 4, 6 are thin transition frames (17-31 pixels) that cause artifacts
	var combat_frames = [0, 2, 5, 7]
	
	# Attack Light: rows 0-7
	for i in range(8):
		var dir = dirs[i]
		_add_anim_filtered(sf, c_tex, "attack_light_" + dir, i, combat_frames, 12.0, false)
	
	# Attack Heavy: rows 8-15
	for i in range(8):
		var dir = dirs[i]
		_add_anim_filtered(sf, c_tex, "attack_heavy_" + dir, i + 8, combat_frames, 10.0, false)
	
	# Hurt: rows 16-23
	for i in range(8):
		var dir = dirs[i]
		_add_anim_filtered(sf, c_tex, "hurt_" + dir, i + 16, combat_frames, 8.0, false)
	
	sprite_frames = sf
	print("Built SpriteFrames with ", sf.get_animation_names().size(), " animations")

func _add_anim(sf, atlas, name, row, frames, speed, loop):
	sf.add_animation(name)
	sf.set_animation_speed(name, speed)
	sf.set_animation_loop(name, loop)
	for col in range(frames):
		var tex = AtlasTexture.new()
		tex.atlas = atlas
		tex.region = Rect2(col * 16, row * 16, 16, 16)
		sf.add_frame(name, tex)

func _add_anim_filtered(sf, atlas, name, row, frame_indices, speed, loop):
	"""Add animation using only specific frame indices (skips empty/transition frames)."""
	sf.add_animation(name)
	sf.set_animation_speed(name, speed)
	sf.set_animation_loop(name, loop)
	for col in frame_indices:
		var tex = AtlasTexture.new()
		tex.atlas = atlas
		tex.region = Rect2(col * 16, row * 16, 16, 16)
		sf.add_frame(name, tex)

func setup_bark_label():
	bark_label = Label.new()
	bark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bark_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bark_label.add_theme_font_size_override("font_size", 10)
	bark_label.modulate = Color(1, 1, 1)
	bark_label.visible = false
	
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
		bark_label.reset_size()
		bark_label.position = Vector2(-bark_label.size.x / 2, -50)

func find_targets():
	all_fighters = get_tree().get_nodes_in_group("artun_combat")
	all_fighters.erase(self)

func _get_animation_name(base_name: String, direction: String) -> String:
	"""Get animation name with fallback for missing directions."""
	var full_name = base_name + "_" + direction
	if sprite_frames and sprite_frames.has_animation(full_name):
		return full_name
	
	# Fallbacks for missing animations
	if base_name == "death" and direction == "nw":
		return "death_n"  # NW death missing, use N
	
	# Default fallback
	return base_name + "_s"


func change_state(new_state: State):
	current_state = new_state
	state_timer = 0.0
	
	match current_state:
		State.IDLE:
			play(_get_animation_name("idle", current_direction))
		State.WALKING:
			play(_get_animation_name("walk", current_direction))
		State.ATTACKING:
			var attack_anim = _get_animation_name("attack_light", current_direction)
			play(attack_anim)
			print("Knight playing attack: ", attack_anim)
		State.HURT:
			play(_get_animation_name("hurt", current_direction))
		State.DEAD:
			play(_get_animation_name("death", current_direction))
			modulate = Color(0.5, 0.5, 0.5, 0.7)
		State.FLEEING:
			play(_get_animation_name("walk", current_direction))
		State.DISENGAGING:
			play(_get_animation_name("walk", current_direction))

func _process(delta):
	if bark_timer > 0:
		bark_timer -= delta
		if bark_label:
			if bark_timer <= 0.3:
				bark_label.modulate.a = bark_timer / 0.3
			else:
				bark_label.modulate.a = 1.0
			bark_label.position = Vector2(-bark_label.size.x / 2, -50)
			
			if bark_timer <= 0:
				bark_label.visible = false
				bark_label.modulate.a = 1.0
	
	if current_state == State.DEAD:
		return
	
	state_timer += delta
	
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

func _update_idle(_delta):
	target = find_closest_enemy()
	
	if target and global_position.distance_to(target.global_position) < detection_range:
		if health < 60 and randf() < 0.3:
			change_state(State.FLEEING)
			show_bark("Fall back!")
		else:
			change_state(State.WALKING)
	else:
		if randf() < 0.01:
			pick_random_direction()
			change_state(State.WALKING)

func _update_walking(delta):
	if not is_instance_valid(target) or is_target_dead():
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
	
	# Make sure animation plays
	var anim_name = _get_animation_name("walk", current_direction)
	if animation != anim_name:
		play(anim_name)

func _update_attacking(delta):
	# Deal damage mid-animation
	if state_timer >= 0.3 and state_timer < 0.4:
		if is_instance_valid(target) and global_position.distance_to(target.global_position) < attack_range + 30:
			if target.has_method("take_damage"):
				target.take_damage(attack_damage)
	
	# Wait for animation to finish (8 frames at 12 fps = 0.67s) - give it extra time
	if state_timer >= 0.8 and not is_playing():
		if health < 50 and randf() < 0.3:
			change_state(State.FLEEING)
			show_bark("Withdraw!")
		else:
			change_state(State.IDLE)
	elif state_timer >= 1.5:
		if health < 50 and randf() < 0.3:
			change_state(State.FLEEING)
			show_bark("Withdraw!")
		else:
			change_state(State.IDLE)

func _update_hurt(_delta):
	if not is_playing() or state_timer >= 0.4:
		if health <= 0:
			spawn_death_blood()
			show_bark("Nooo...")
			change_state(State.DEAD)
		elif health < 60 and randf() < 0.4:
			change_state(State.FLEEING)
			show_bark("Flee!")
		else:
			change_state(State.IDLE)

func _update_fleeing(delta):
	var enemy = find_closest_enemy()
	if enemy:
		var dir = global_position.direction_to(enemy.global_position) * -1
		_update_direction(dir)
		global_position += dir * walk_speed * 1.2 * delta
		
		var anim_name = _get_animation_name("walk", current_direction)
		if animation != anim_name:
			play(anim_name)
		
		if global_position.distance_to(enemy.global_position) > detection_range * 0.6 or state_timer > 2.0:
			change_state(State.IDLE)
	else:
		change_state(State.IDLE)

func _update_disengaging(delta):
	if state_timer >= 3.0:
		change_state(State.IDLE)
		return
	
	if is_instance_valid(target):
		var dir = global_position.direction_to(target.global_position) * -1
		_update_direction(dir)
		global_position += dir * walk_speed * delta
		
		var anim_name = _get_animation_name("walk", current_direction)
		if animation != anim_name:
			play(anim_name)
	else:
		change_state(State.IDLE)

func is_target_dead() -> bool:
	if target.has_method("is_dead"):
		return target.is_dead()
	# Check if target has current_state property (Artun compatibility)
	var state = target.get("current_state")
	if state != null:
		return state == State.DEAD
	return false

func pick_random_direction():
	var dirs = ["e", "se", "s", "sw", "w", "nw", "n", "ne"]
	current_direction = dirs[randi() % dirs.size()]

func find_closest_enemy() -> Node2D:
	var closest = null
	var closest_dist = detection_range
	
	for fighter in all_fighters:
		if is_instance_valid(fighter) and fighter.team != team:
			var is_dead = false
			if fighter.has_method("is_dead"):
				is_dead = fighter.is_dead()
			else:
				# Check for current_state property (Artun compatibility)
				var state = fighter.get("current_state")
				if state != null:
					is_dead = state == State.DEAD
			
			if not is_dead:
				var dist = global_position.distance_to(fighter.global_position)
				if dist < closest_dist:
					closest = fighter
					closest_dist = dist
	
	return closest

func _update_direction(dir: Vector2):
	var angle = atan2(dir.y, dir.x)
	var degrees = rad_to_deg(angle)
	degrees = fmod(degrees + 360.0, 360.0)
	
	var dirs = ["e", "se", "s", "sw", "w", "nw", "n", "ne"]
	var index = int(fmod((degrees + 22.5) / 45.0, 8.0))
	current_direction = dirs[index]

func is_dead() -> bool:
	return current_state == State.DEAD

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
	
	modulate = Color(1.5, 1.5, 1.5)
	await get_tree().create_timer(0.08).timeout
	modulate = Color(1, 1, 1)
	
	if randf() < 0.5:
		var hurt_barks = ["Oof!", "Argh!", "Ugh!", "Gah!"]
		show_bark(hurt_barks[randi() % hurt_barks.size()])
	
	change_state(State.HURT)
