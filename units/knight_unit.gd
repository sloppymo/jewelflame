class_name KnightUnit
extends CharacterBody2D

signal unit_selected(unit)
signal unit_died(unit)
signal troops_changed(count)

@export var max_troops: int = 5
@export var base_damage: int = 20
@export var move_speed: float = 80.0
@export var attack_range: float = 20.0
@export var max_hp: int = 100
@export var team: int = 0

var current_troops: int = 5
var facing_direction: String = "s"
var is_selected: bool = false
var is_attacking: bool = false
var is_dying: bool = false

@onready var troop_sprites = [$Troop_0, $Troop_1, $Troop_2, $Troop_3, $Troop_4]

func _ready():
	# Ensure all troop sprites are visible and synced on start
	current_troops = max_troops
	update_troop_visuals()
	play_animation("idle")
	
	# Connect input detection
	$Area2D.input_event.connect(_on_input_event)
	
	# Ensure all sprites start with the same frame for synchronization
	for sprite in troop_sprites:
		if sprite.visible:
			sprite.frame = 0

func calculate_damage() -> int:
	var ratio = float(current_troops) / float(max_troops)
	return int(base_damage * ratio)

func update_troop_visuals():
	# Static gaps - hide dead, don't reposition
	# Death order: Troop_4 first, then Troop_3, etc. (back to front)
	for i in range(max_troops):
		var should_be_visible = i < current_troops
		if troop_sprites[i].visible != should_be_visible:
			troop_sprites[i].visible = should_be_visible
			if not should_be_visible:
				troop_sprites[i].stop()
			else:
				# Sync frame with leader when becoming visible
				sprite_sync_with_leader(troop_sprites[i])

func sprite_sync_with_leader(sprite: AnimatedSprite2D):
	"""Sync a sprite's animation and frame with the leader (Troop_0)"""
	var leader = troop_sprites[0]
	if leader.sprite_frames and leader.animation != "":
		if sprite.sprite_frames.has_animation(leader.animation):
			sprite.animation = leader.animation
			sprite.frame = leader.frame
			sprite.play()

func take_damage(amount: int):
	if is_dying:
		return
	
	var hp_per_troop = float(max_hp) / max_troops
	var troops_lost = ceili(amount / hp_per_troop)
	
	current_troops = maxi(0, current_troops - troops_lost)
	troops_changed.emit(current_troops)
	update_troop_visuals()
	
	if current_troops <= 0:
		die()
	else:
		# White flash effect on remaining troops
		_flash_white()

func _flash_white():
	"""Brief white flash effect on all visible troops"""
	for sprite in troop_sprites:
		if sprite.visible:
			sprite.modulate = Color(2, 2, 2, 1)
	
	# Use a timer to restore colors
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(_restore_colors)

func _restore_colors():
	for sprite in troop_sprites:
		if is_instance_valid(sprite):
			sprite.modulate = Color(1, 1, 1, 1)

func die():
	if is_dying:
		return
	is_dying = true
	
	play_animation("death")
	
	# Wait for death animation to complete before freeing
	# Death has 4 frames at 8 fps = 0.5s
	await get_tree().create_timer(0.5).timeout
	
	unit_died.emit(self)
	queue_free()

func play_animation(anim_base: String):
	var full_anim = anim_base + "_" + facing_direction
	
	# Fallback for missing death direction (missing NW on non-combat sheet)
	if anim_base == "death":
		var leader = troop_sprites[0]
		if leader.sprite_frames and not leader.sprite_frames.has_animation(full_anim):
			# Try fallback directions
			if facing_direction == "nw":
				full_anim = "death_n"  # NW missing, use N
			else:
				full_anim = "death_s"  # Ultimate fallback
	
	# Play on all visible sprites
	for sprite in troop_sprites:
		if sprite.visible and sprite.sprite_frames:
			if sprite.sprite_frames.has_animation(full_anim):
				if sprite.animation != full_anim or not sprite.is_playing():
					sprite.play(full_anim)
			else:
				push_warning("Missing animation: " + full_anim)

func update_facing(velocity_vector: Vector2):
	if velocity_vector.length() < 5:
		return
	
	var angle = velocity_vector.angle()
	var degrees = rad_to_deg(angle)
	
	# Convert to 0-360 range
	degrees = fmod(degrees + 360.0, 360.0)
	
	# 8-direction mapping based on standard isometric angles
	# 0° = East, 90° = South, 180° = West, 270° = North
	# Adjusted for game perspective where S faces camera
	var new_direction: String
	
	if degrees >= 337.5 or degrees < 22.5:
		new_direction = "e"
	elif degrees >= 22.5 and degrees < 67.5:
		new_direction = "se"
	elif degrees >= 67.5 and degrees < 112.5:
		new_direction = "s"
	elif degrees >= 112.5 and degrees < 157.5:
		new_direction = "sw"
	elif degrees >= 157.5 and degrees < 202.5:
		new_direction = "w"
	elif degrees >= 202.5 and degrees < 247.5:
		new_direction = "nw"
	elif degrees >= 247.5 and degrees < 292.5:
		new_direction = "n"
	else:  # 292.5 to 337.5
		new_direction = "ne"
	
	if new_direction != facing_direction:
		facing_direction = new_direction

func attack():
	if is_attacking or is_dying:
		return
	is_attacking = true
	play_animation("attack_light")
	
	# Wait for attack animation to finish
	var leader = troop_sprites[0]
	if leader.visible:
		await leader.animation_finished
	else:
		# If leader is dead, wait fixed time (8 frames at 12 fps = 0.67s)
		await get_tree().create_timer(0.67).timeout
	
	is_attacking = false

func _physics_process(_delta):
	if is_dying:
		return
	
	if velocity.length() > 0 and not is_attacking:
		update_facing(velocity)
		play_animation("walk")
		move_and_slide()
	elif not is_attacking:
		play_animation("idle")

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_selected = true
		unit_selected.emit(self)
		queue_redraw()

func _draw():
	# Selection ring (cyan) - only when selected
	if is_selected:
		draw_arc(Vector2.ZERO, 14, 0, TAU, 32, Color(0.2, 0.8, 1.0, 0.8), 2.0)

func move_to(target: Vector2):
	velocity = (target - global_position).normalized() * move_speed

func deselect():
	is_selected = false
	queue_redraw()
