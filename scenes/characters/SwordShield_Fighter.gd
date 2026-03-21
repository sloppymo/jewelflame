extends AnimatedSprite2D

## Sword & Shield Fighter — uses pre-generated SpriteFrames
## Compatible with combat_group system

@export var team: int = 0
@export var walk_speed: float = 40.0  # 50% slower (was 80)
@export var health: int = 400  # 2x health (was 200)
@export var attack_damage: int = 15
@export var attack_range: float = 50.0
@export var detection_range: float = 400.0

enum State { IDLE, WALKING, ATTACKING, HURT, DEAD, FLEEING, DISENGAGING }
var current_state: State = State.IDLE
var current_direction: String = "s"  # s, n, e, w, se, sw, ne, nw
var target: Node2D = null
var all_fighters: Array = []
var state_timer: float = 0.0

# SpriteFrames resources
var _nc_frames: SpriteFrames  # non-combat
var _co_frames: SpriteFrames  # combat

func _ready():
	# CRITICAL: Set nearest filter for pixel art
	texture_filter = TEXTURE_FILTER_NEAREST
	
	add_to_group("swordshield_combat")
	add_to_group("artun_combat")  # For compatibility with targeting
	
	# Load pre-generated SpriteFrames
	_nc_frames = load("res://assets/animations/swordshield_non_combat.tres")
	_co_frames = load("res://assets/animations/swordshield_combat.tres")
	
	if _nc_frames == null or _co_frames == null:
		push_error("SwordShield_Fighter: missing SpriteFrames resources")
		return
	
	# Set up SpriteFrames
	sprite_frames = _nc_frames
	
	# Scale up for visibility
	scale = Vector2(2, 2)
	
	call_deferred("find_targets")
	change_state(State.IDLE)

func find_targets():
	all_fighters = get_tree().get_nodes_in_group("artun_combat")
	all_fighters.erase(self)

func change_state(new_state: State):
	if current_state == new_state:
		return
		
	current_state = new_state
	state_timer = 0.0
	
	match current_state:
		State.IDLE:
			_set_frames(_nc_frames)
			_play_anim("idle", current_direction)
		State.WALKING:
			_set_frames(_nc_frames)
			_play_anim("walk", current_direction)
		State.ATTACKING:
			_set_frames(_co_frames)
			attack_timer = 0.0
			_play_anim("attack1", _to_4dir(current_direction))
		State.HURT:
			_set_frames(_co_frames)
			_play_anim("hurt", _to_4dir(current_direction))
		State.DEAD:
			_set_frames(_nc_frames)
			_play_anim("death", current_direction)
			modulate = Color(0.5, 0.5, 0.5, 0.7)
		State.FLEEING:
			_set_frames(_nc_frames)
			_play_anim("walk", current_direction)
		State.DISENGAGING:
			_set_frames(_nc_frames)
			_play_anim("walk", current_direction)

var attack_timer: float = 0.0

func _process(delta):
	state_timer += delta
	
	if current_state == State.DEAD:
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

func _update_idle(_delta):
	target = find_closest_enemy()
	
	if target and global_position.distance_to(target.global_position) < detection_range:
		if health < 120 and randf() < 0.3:  # Adjusted threshold for 2x health
			change_state(State.FLEEING)
		else:
			change_state(State.WALKING)
	else:
		# Random wandering
		if randf() < 0.005:
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
		return
	
	var dir = global_position.direction_to(target.global_position)
	_update_direction(dir)
	global_position += dir * walk_speed * delta
	
	var anim_name = _get_anim_name("walk", current_direction)
	if animation != anim_name:
		play(anim_name)

func _update_attacking(delta):
	attack_timer += delta
	
	# Deal damage mid-animation
	if attack_timer >= 0.3 and attack_timer < 0.4:
		if is_instance_valid(target) and global_position.distance_to(target.global_position) < attack_range + 30:
			if target.has_method("take_damage"):
				target.take_damage(attack_damage)
	
	# Wait for animation to finish
	if attack_timer >= 0.8 and not is_playing():
		if health < 100 and randf() < 0.3:  # Adjusted threshold for 2x health
			change_state(State.FLEEING)
		else:
			change_state(State.IDLE)
	elif attack_timer >= 1.5:
		# Timeout fallback
		change_state(State.IDLE)

func _update_hurt(_delta):
	if not is_playing() or state_timer >= 0.5:
		if health <= 0:
			change_state(State.DEAD)
		elif health < 120 and randf() < 0.4:  # Adjusted threshold for 2x health
			change_state(State.FLEEING)
		else:
			change_state(State.IDLE)

func _update_fleeing(delta):
	var enemy = find_closest_enemy()
	if enemy:
		var dir = global_position.direction_to(enemy.global_position) * -1
		_update_direction(dir)
		global_position += dir * walk_speed * 1.2 * delta
		
		var anim_name = _get_anim_name("walk", current_direction)
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
		
		var anim_name = _get_anim_name("walk", current_direction)
		if animation != anim_name:
			play(anim_name)
	else:
		change_state(State.IDLE)

func _set_frames(frames: SpriteFrames):
	if sprite_frames != frames:
		sprite_frames = frames
		# Combat sprites are 32x32 - offset to center
		if frames == _co_frames:
			offset = Vector2(-8, -4)
		else:
			offset = Vector2.ZERO

func _play_anim(base: String, direction: String):
	var anim_name = _get_anim_name(base, direction)
	if sprite_frames.has_animation(anim_name):
		play(anim_name)

func _get_anim_name(base: String, direction: String) -> String:
	var full_name = base + "_" + direction
	if sprite_frames and sprite_frames.has_animation(full_name):
		return full_name
	
	# Fallbacks
	if base == "death":
		if not sprite_frames.has_animation(full_name):
			# Death has limited directions
			var fallbacks = {"nw": "ne", "ne": "nw", "sw": "se", "se": "sw", "e": "w", "w": "e"}
			var fb = fallbacks.get(direction, "s")
			return base + "_" + fb
	
	return base + "_s"

func _to_4dir(dir_8: String) -> String:
	"""Convert 8-direction to 4-direction for combat animations."""
	match dir_8:
		"se", "sw": return "s"
		"ne", "nw": return "n"
		_: return dir_8

func _update_direction(dir: Vector2):
	var angle = atan2(dir.y, dir.x)
	var degrees = rad_to_deg(angle)
	degrees = fmod(degrees + 360.0, 360.0)
	
	var dirs = ["e", "se", "s", "sw", "w", "nw", "n", "ne"]
	var index = int(fmod((degrees + 22.5) / 45.0, 8.0))
	current_direction = dirs[index]

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
				var state = fighter.get("current_state")
				if state != null:
					is_dead = state == State.DEAD
			
			if not is_dead:
				var dist = global_position.distance_to(fighter.global_position)
				if dist < closest_dist:
					closest = fighter
					closest_dist = dist
	
	return closest

func is_target_dead() -> bool:
	if target.has_method("is_dead"):
		return target.is_dead()
	var state = target.get("current_state")
	if state != null:
		return state == State.DEAD
	return false

func is_dead() -> bool:
	return current_state == State.DEAD

func take_damage(damage: int):
	if current_state == State.DEAD:
		return
	
	health -= damage
	
	# Flash white
	modulate = Color(1.5, 1.5, 1.5)
	await get_tree().create_timer(0.08).timeout
	modulate = Color(1, 1, 1)
	
	change_state(State.HURT)

func set_facing_direction(dir: Vector2):
	_update_direction(dir)
