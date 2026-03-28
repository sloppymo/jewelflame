# TinyRPG_Character.gd
#
# Purpose: Generic character controller for Tiny RPG Asset Pack characters
# Features:
#   - Automatic scaling from 100x100 to target size
#   - Runtime sprite frame building (no .tres needed)
#   - State machine (IDLE, WALK, ATTACK, HURT, DEAD)
#   - AI matching ArenaUnit behavior

class_name TinyRPGCharacter
extends CharacterBody2D

#region Exported Configuration
@export_group("Visual")

## Source texture (combined sprite sheet like Soldier.png or Orc.png)
@export var source_texture: Texture2D

## Target scale (100x100 scaled down, e.g., 0.25 = 25x25 pixels)
@export var target_scale: float = 0.25

## Facing direction: "right" or "left"
@export_enum("right", "left") var facing: String = "right"

@export_group("Combat")

## Maximum health
@export var max_health: int = 100

## Movement speed
@export var move_speed: float = 80.0

## Attack damage
@export var attack_damage: int = 15

## Team number (0 = player, 1+ = enemies)
@export var team: int = 1

## Attack range in pixels
@export var attack_range: float = 50.0

## Attack cooldown in seconds
@export var attack_cooldown_time: float = 1.0

@export_group("Animation")

## Animation speed multiplier
@export var anim_speed_mult: float = 1.0

@export_group("AI")

## Enable AI behavior
@export var ai_enabled: bool = false
#endregion

#region State
enum State { IDLE, WALK, ATTACK, HURT, DEAD }
var current_state: State = State.IDLE
var current_health: int = 100
var is_dead: bool = false

#region AI State (matching ArenaUnit pattern)
var _ai_target: TinyRPGCharacter = null
var _ai_attack_timer: float = 0.0
var _ai_state_timer: float = 0.0
var _has_hit: bool = false
var _knockback_velocity: Vector2 = Vector2.ZERO
#endregion
#endregion

#region Node References
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_cooldown: Timer = $AttackCooldown if has_node("AttackCooldown") else null
#endregion


func _ready():
	"""Initialize the character."""
	# Build sprite frames from texture
	if source_texture:
		build_sprite_frames()
	else:
		push_warning(name + ": No source_texture assigned!")
		_create_placeholder_sprite()
	
	# Apply scale (100x100 -> target size)
	scale = Vector2(target_scale, target_scale)
	
	# Set texture filter for pixel art
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Flip based on facing
	_update_facing()
	
	# Initialize health
	current_health = max_health
	
	# Add to character group for AI
	add_to_group("tiny_rpg_chars")
	add_to_group("arena_units")  # Join the arena unit group for targeting
	
	# Start idle
	_change_state(State.IDLE)


func _create_placeholder_sprite() -> void:
	"""Create a placeholder sprite when texture is missing."""
	var placeholder = PlaceholderTexture2D.new()
	placeholder.size = Vector2(100, 100)
	
	var sf = SpriteFrames.new()
	sf.add_animation("idle")
	sf.add_frame("idle", placeholder)
	sprite.sprite_frames = sf


func build_sprite_frames():
	"""Build SpriteFrames from the source texture at runtime.
	
	Uses CORRECT frame counts per animation to avoid empty frames.
	Frame counts are based on the individual animation files.
	"""
	var sf = SpriteFrames.new()
	
	# Calculate actual dimensions
	var tex_width = source_texture.get_width()
	var tex_height = source_texture.get_height()
	var max_cols = tex_width / 100
	var max_rows = tex_height / 100
	
	# Animation definitions with CORRECT frame counts
	# These match the individual -Idle.png, -Walk.png, -Death.png etc. files
	var anims = [
		{"name": "idle", "row": 0, "frames": 6, "speed": 6.0, "loop": true},
		{"name": "walk", "row": 1, "frames": 8, "speed": 10.0, "loop": true},
		{"name": "attack01", "row": 2, "frames": 6, "speed": 12.0, "loop": false},
		{"name": "attack02", "row": 3, "frames": 6, "speed": 12.0, "loop": false},
		{"name": "hurt", "row": 4, "frames": 4, "speed": 8.0, "loop": false},
		{"name": "death", "row": 5, "frames": 4, "speed": 6.0, "loop": false},
	]
	
	# Add attack03 if there's a 7th row (index 6)
	if max_rows >= 7:
		anims.append({"name": "attack03", "row": 6, "frames": 9, "speed": 14.0, "loop": false})
	
	# Build each animation
	for anim in anims:
		# Skip if this row doesn't exist
		if anim["row"] >= max_rows:
			continue
		
		# Skip if row would be empty (some sheets have fewer animations)
		var expected_max_frame = anim["frames"]
		if expected_max_frame > max_cols:
			expected_max_frame = int(max_cols)
		
		sf.add_animation(anim["name"])
		sf.set_animation_speed(anim["name"], anim["speed"] * anim_speed_mult)
		sf.set_animation_loop(anim["name"], anim["loop"])
		
		# Add frames using CORRECT count (not the full row)
		for i in range(expected_max_frame):
			var atlas = AtlasTexture.new()
			atlas.atlas = source_texture
			atlas.region = Rect2(
				i * 100,
				anim["row"] * 100,
				100,
				100
			)
			sf.add_frame(anim["name"], atlas)
	
	# Ensure we always have at least idle and walk
	if not sf.has_animation("idle"):
		push_error(name + ": No idle animation found!")
	if not sf.has_animation("walk"):
		push_error(name + ": No walk animation found!")
	
	sprite.sprite_frames = sf


func _physics_process(delta: float):
	"""Handle physics movement and AI (matching ArenaUnit pattern)."""
	if is_dead:
		return
	
	_ai_state_timer += delta
	_ai_attack_timer += delta
	
	# Apply knockback
	if _knockback_velocity.length() > 1:
		position += _knockback_velocity * delta
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 400 * delta)
		return
	
	# Process AI if enabled (matching ArenaUnit state machine)
	if ai_enabled:
		match current_state:
			State.IDLE:
				_update_ai_idle(delta)
			State.WALK:
				_update_ai_charge(delta)
			State.ATTACK:
				_update_ai_attack(delta)
			State.HURT:
				_update_ai_hurt(delta)
	else:
		# Manual control movement
		match current_state:
			State.WALK:
				move_and_slide()
				if velocity.x > 0.1:
					facing = "right"
				elif velocity.x < -0.1:
					facing = "left"
				_update_facing()


#region AI Methods (matching ArenaUnit pattern)

func _update_ai_idle(delta: float):
	"""Idle state - find target."""
	_play_anim("idle")
	_ai_find_target()
	if _ai_target and is_instance_valid(_ai_target) and not _ai_target.is_dead:
		_change_state(State.WALK)


func _update_ai_charge(delta: float):
	"""Charge state - move toward target."""
	if not _ai_target or not is_instance_valid(_ai_target) or _ai_target.is_dead:
		_ai_target = null
		_change_state(State.IDLE)
		return
	
	var dist = position.distance_to(_ai_target.position)
	if dist <= attack_range:
		_change_state(State.ATTACK)
		_ai_state_timer = 0.0
		_has_hit = false
		_ai_attack_timer = 0.0
		return
	
	# Move toward target
	var move_dir = (_ai_target.position - position).normalized()
	
	# Avoid clumping with allies (matching ArenaUnit)
	for unit in get_tree().get_nodes_in_group("arena_units"):
		if unit != self and unit.team == team and not unit.is_dead:
			var dist_to_ally = position.distance_to(unit.position)
			if dist_to_ally < 50:
				move_dir += (position - unit.position).normalized() * 0.5
				move_dir = move_dir.normalized()
	
	# Update position directly (matching ArenaUnit)
	position += move_dir * move_speed * delta
	
	# Face target
	if move_dir.x > 0.1:
		facing = "right"
	elif move_dir.x < -0.1:
		facing = "left"
	_update_facing()
	
	_play_anim("walk")


func _update_ai_attack(delta: float):
	"""Attack state - deal damage."""
	# Face target
	if _ai_target and is_instance_valid(_ai_target):
		var attack_dir = (_ai_target.position - position).normalized()
		if attack_dir.x > 0:
			facing = "right"
		else:
			facing = "left"
		_update_facing()
	
	# Deal damage during attack animation (at mid-point)
	if _ai_state_timer > 0.2 and _ai_state_timer < 0.5 and not _has_hit:
		_has_hit = true
		if _ai_target and is_instance_valid(_ai_target) and not _ai_target.is_dead:
			var dist = position.distance_to(_ai_target.position)
			if dist <= attack_range * 1.5:
				_ai_target.take_hit_ai(attack_damage, (_ai_target.position - position).normalized())
	
	_play_anim("attack01")
	
	# Return to charge after cooldown
	if _ai_attack_timer >= attack_cooldown_time:
		_change_state(State.WALK)


func _update_ai_hurt(delta: float):
	"""Hurt state - brief animation then back to charge."""
	if _ai_state_timer > 0.3:
		_change_state(State.WALK)
		_ai_find_target()


func _ai_find_target():
	"""Find nearest enemy from arena_units group."""
	var nearest: TinyRPGCharacter = null
	var nearest_dist = 999999.0
	
	for unit in get_tree().get_nodes_in_group("arena_units"):
		if unit is TinyRPGCharacter and unit != self:
			if unit.team != team and not unit.is_dead:
				var dist = position.distance_to(unit.position)
				if dist < nearest_dist:
					nearest_dist = dist
					nearest = unit
	
	_ai_target = nearest


func take_hit_ai(damage: int, from_dir: Vector2):
	"""Take damage from AI (called by other characters)."""
	if is_dead:
		return
	
	current_health -= damage
	_knockback_velocity = from_dir * 150
	
	# Show damage number
	_show_damage_number(damage)
	
	if current_health <= 0:
		_die()
	elif current_state != State.ATTACK:
		_change_state(State.HURT)
		_ai_state_timer = 0.0

#endregion


#region Public API - Movement

func move(direction: Vector2) -> void:
	"""Start moving in a direction."""
	if is_dead or current_state in [State.ATTACK, State.HURT]:
		return
	
	velocity = direction.normalized() * move_speed
	_change_state(State.WALK)


func stop() -> void:
	"""Stop moving."""
	if is_dead:
		return
	
	velocity = Vector2.ZERO
	_change_state(State.IDLE)


func move_to(target_pos: Vector2) -> void:
	"""Move towards a target position."""
	var dir = target_pos - global_position
	move(dir)

#endregion


#region Public API - Combat

func attack(attack_type: String = "attack01") -> void:
	"""Perform an attack."""
	if is_dead or current_state in [State.ATTACK, State.HURT, State.DEAD]:
		return
	
	# Validate attack type
	if not sprite.sprite_frames.has_animation(attack_type):
		attack_type = "attack01"
	
	_change_state(State.ATTACK, attack_type)


func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	"""Take damage and apply hurt state."""
	if is_dead:
		return
	
	current_health -= amount
	
	# Show damage number
	_show_damage_number(amount)
	
	# Apply knockback
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir.normalized() * 100.0
	
	if current_health <= 0:
		_die()
	else:
		_change_state(State.HURT)


func die() -> void:
	"""Force death."""
	_die()


func heal(amount: int) -> void:
	"""Heal the character."""
	if is_dead:
		return
	
	current_health = mini(current_health + amount, max_health)


func respawn() -> void:
	"""Respawn the character after death."""
	is_dead = false
	current_health = max_health
	velocity = Vector2.ZERO
	_knockback_velocity = Vector2.ZERO
	collision_layer = 2
	collision_mask = 7
	# Reset sprite color
	sprite.modulate = Color(1, 1, 1, 1)
	_change_state(State.IDLE)

#endregion


#region Private Methods

func _change_state(new_state: State, anim_override: String = "") -> void:
	"""Change state and play appropriate animation."""
	current_state = new_state
	_ai_state_timer = 0.0
	
	var anim_name: String
	
	match new_state:
		State.IDLE:
			anim_name = "idle"
		State.WALK:
			anim_name = "walk"
		State.ATTACK:
			anim_name = anim_override if anim_override else "attack01"
		State.HURT:
			anim_name = "hurt"
			# Hurt has a timeout in case animation doesn't fire finished signal
			get_tree().create_timer(0.4).timeout.connect(_on_hurt_timeout)
		State.DEAD:
			anim_name = "death"
		_:
			anim_name = "idle"
	
	_play_anim(anim_name)


func _play_anim(anim_name: String):
	"""Play animation if it exists, fallback to alternatives if not."""
	if not sprite.sprite_frames:
		return
	
	# Try the requested animation first
	var actual_anim = anim_name
	
	# Fallback chain for missing animations
	if not sprite.sprite_frames.has_animation(actual_anim):
		match anim_name:
			"attack03":
				if sprite.sprite_frames.has_animation("attack02"):
					actual_anim = "attack02"
				elif sprite.sprite_frames.has_animation("attack01"):
					actual_anim = "attack01"
				else:
					actual_anim = "idle"
			"attack02":
				actual_anim = "attack01" if sprite.sprite_frames.has_animation("attack01") else "idle"
			"attack01":
				actual_anim = "idle"
			"hurt":
				# Hurt should flash or show idle briefly
				actual_anim = "idle"
			"death":
				# Death MUST play death animation
				actual_anim = "death" if sprite.sprite_frames.has_animation("death") else "idle"
			"walk":
				actual_anim = "idle"
			_:
				actual_anim = "idle"
	
	# Final safety check
	if not sprite.sprite_frames.has_animation(actual_anim):
		actual_anim = "idle"
	
	# Play the animation
	sprite.play(actual_anim)
	
	# Connect finished signal for non-looping animations
	if not sprite.sprite_frames.get_animation_loop(actual_anim):
		if not sprite.animation_finished.is_connected(_on_anim_finished):
			sprite.animation_finished.connect(_on_anim_finished)


func _on_anim_finished() -> void:
	"""Handle animation completion."""
	match current_state:
		State.ATTACK:
			_change_state(State.WALK)
		State.HURT:
			# Check if we already handled hurt timeout
			if current_state == State.HURT:
				velocity = Vector2.ZERO
				_change_state(State.WALK)


func _on_hurt_timeout() -> void:
	"""Fallback for when hurt animation doesn't fire finished signal."""
	if current_state == State.HURT:
		velocity = Vector2.ZERO
		_change_state(State.WALK)


func _update_facing() -> void:
	"""Update sprite flip based on facing direction."""
	sprite.flip_h = (facing == "left")


func _die() -> void:
	"""Handle death."""
	is_dead = true
	current_health = 0
	velocity = Vector2.ZERO
	_knockback_velocity = Vector2.ZERO
	_change_state(State.DEAD)
	
	# Disable collision
	collision_layer = 0
	collision_mask = 0
	
	# Grey out the sprite
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)


func _show_damage_number(amount: int, is_critical: bool = false, is_heal: bool = false) -> void:
	"""Spawn a floating damage number."""
	var damage_label = preload("res://scenes/effects/damage_number.tscn").instantiate()
	
	# Add to the character's parent (world) so it moves independently
	get_parent().add_child(damage_label)
	
	# Position above the character sprite (accounting for scale)
	# The sprite is offset by -62px at scale, so we go above that
	var sprite_offset = Vector2(0, -80) * target_scale
	damage_label.global_position = global_position + sprite_offset
	
	damage_label.set_damage(amount, is_critical, is_heal)

#endregion
