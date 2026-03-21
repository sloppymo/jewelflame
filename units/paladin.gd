## paladin.gd
## Paladin — solo hero unit, similar to Heavy Knight but with Paladin animations

class_name Paladin
extends CharacterBody2D

@export var move_speed       : float = 100.0
@export var run_speed        : float = 180.0
@export var attack_cooldown  : float = 0.8
@export var thrust_cooldown  : float = 1.2
@export var base_damage      : int   = 25
@export var thrust_damage    : int   = 40
@export var use_dash_thrust  : bool  = false

enum State { IDLE, WALKING, RUNNING, JUMPING, FALLING, ROLLING, ATTACKING, BLOCKING, HURT, DEAD }

var current_state   : State  = State.IDLE
var facing          : String = "right"
var vert_facing     : String = "down"
var attack_timer    : float  = 0.0
var thrust_timer    : float  = 0.0
var is_blocking     : bool   = false
var _impact_dealt   : bool   = false

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

var _nc_frames      : SpriteFrames
var _co_frames      : SpriteFrames
var _thrust_nd      : SpriteFrames
var _thrust_d       : SpriteFrames

func _ready() -> void:
	_nc_frames = load("res://assets/animations/paladin_non_combat.tres")
	_co_frames = load("res://assets/animations/paladin_combat.tres")
	_thrust_nd = load("res://assets/animations/paladin_thrust_nodash.tres")
	_thrust_d  = load("res://assets/animations/paladin_thrust_dash.tres")

	if _nc_frames == null or _co_frames == null:
		push_error("Paladin: missing SpriteFrames. Run EditorScripts first.")
		return

	sprite.sprite_frames = _nc_frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.play("idle_down")

func _physics_process(delta: float) -> void:
	attack_timer = max(0.0, attack_timer - delta)
	thrust_timer = max(0.0, thrust_timer - delta)

	match current_state:
		State.IDLE:
			if velocity.length() < 5.0:
				_play_nc("idle")
		State.WALKING:
			_update_facing()
			_play_nc("walk")
		State.RUNNING:
			_update_facing()
			_play_nc("run")
		State.ATTACKING:
			_check_impact_frame()
		State.ROLLING:
			pass
		State.DEAD:
			pass

	move_and_slide()

func set_state(new_state: State) -> void:
	if current_state == State.DEAD:
		return
	current_state = new_state

	match new_state:
		State.IDLE:
			_set_frames(_nc_frames)
			_play_nc("idle")
		State.WALKING:
			_set_frames(_nc_frames)
			_play_nc("walk")
		State.RUNNING:
			_set_frames(_nc_frames)
			_play_nc("run")
		State.JUMPING:
			_set_frames(_nc_frames)
			_play_nc("jump")
			sprite.animation_finished.connect(_on_jump_finished, CONNECT_ONE_SHOT)
		State.FALLING:
			_set_frames(_nc_frames)
			_play_nc("fall")
		State.ROLLING:
			_set_frames(_nc_frames)
			_play_nc("roll")
			sprite.animation_finished.connect(func(): set_state(State.IDLE), CONNECT_ONE_SHOT)
		State.ATTACKING:
			if attack_timer > 0.0:
				return
			attack_timer = attack_cooldown
			_impact_dealt = false
			_set_frames(_co_frames)
			_play_co_attack()
			sprite.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)
		State.BLOCKING:
			_set_frames(_co_frames)
			is_blocking = true
			sprite.play("block_" + facing)
		State.HURT:
			_set_frames(_co_frames)
			sprite.play("hurt_" + facing)
			sprite.animation_finished.connect(func(): set_state(State.IDLE), CONNECT_ONE_SHOT)
		State.DEAD:
			_set_frames(_nc_frames)
			_play_nc("death")
			sprite.animation_finished.connect(_on_death_finished, CONNECT_ONE_SHOT)

func stop_blocking() -> void:
	is_blocking = false
	set_state(State.IDLE)

func thrust_attack() -> void:
	if thrust_timer > 0.0 or current_state == State.DEAD:
		return
	thrust_timer = thrust_cooldown
	current_state = State.ATTACKING

	var frames := _thrust_d if use_dash_thrust else _thrust_nd
	_set_frames(frames)
	sprite.play("thrust_" + facing)
	sprite.animation_finished.connect(_on_thrust_finished, CONNECT_ONE_SHOT)

func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return
	if is_blocking:
		amount = int(amount * 0.25)
		if amount == 0:
			return
	set_state(State.HURT)

func _check_impact_frame() -> void:
	if _impact_dealt:
		return
	if sprite.frame >= 2:
		_impact_dealt = true
		_on_attack_impact()

func _on_attack_impact() -> void:
	print("Paladin attack impact! Damage: ", base_damage)

func _on_thrust_finished() -> void:
	set_state(State.IDLE)

func _play_nc(base: String) -> void:
	var dir := _get_nc_direction(base)
	var anim := base + "_" + dir
	if not _nc_frames.has_animation(anim):
		anim = base + "_down"
	if sprite.animation != anim:
		sprite.play(anim)

func _play_co_attack() -> void:
	sprite.play("attack_horizontal_" + facing)

func _get_nc_direction(base: String) -> String:
	match base:
		"idle", "death", "death_corpse", "interact":
			return vert_facing
		_:
			if abs(velocity.x) >= abs(velocity.y):
				return "right" if velocity.x >= 0 else "left"
			else:
				return "down" if velocity.y >= 0 else "up"

func _set_frames(frames: SpriteFrames) -> void:
	if sprite.sprite_frames == frames:
		return
	sprite.sprite_frames = frames
	if frames == _nc_frames:
		sprite.offset = Vector2.ZERO
	else:
		sprite.offset = Vector2(-4.0, -4.0)

func _update_facing() -> void:
	if velocity.x > 5.0:
		facing = "right"
	elif velocity.x < -5.0:
		facing = "left"
	if velocity.y > 5.0:
		vert_facing = "down"
	elif velocity.y < -5.0:
		vert_facing = "up"

func _on_attack_finished() -> void:
	set_state(State.IDLE)

func _on_jump_finished() -> void:
	set_state(State.FALLING)

func _on_death_finished() -> void:
	if _nc_frames.has_animation("death_corpse"):
		_set_frames(_nc_frames)
		sprite.play("death_corpse")
	else:
		sprite.stop()
