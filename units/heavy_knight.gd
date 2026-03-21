## heavy_knight.gd
## Heavy Knight — solo hero/player character.
##
## IMPORTANT: This is NOT a 5-troop formation unit.
## It uses a single AnimatedSprite2D and a single collision shape.
##
## Two sprite sizes must be managed:
##   Non-combat (movement/state): 24×24 frames
##   Combat (attacks/block/hurt): 32×32 frames
##   Thrust (special attacks):    32×32 frames, 8-frame animations
##
## When switching from non-combat to combat frames, apply offset (-4, -4)
## to keep the character body centered. Tune this value after visual check.
##
## Facing: right/left only (no 8-direction). Vertical animations (down/up/up)
## exist for isometric-style movement but combat is horizontal only.

class_name HeavyKnight
extends CharacterBody2D

# ── Exports ────────────────────────────────────────────────────────────────────

@export var move_speed       : float = 100.0
@export var run_speed        : float = 180.0
@export var attack_cooldown  : float = 0.8
@export var thrust_cooldown  : float = 1.2
@export var base_damage      : int   = 25
@export var thrust_damage    : int   = 40   # thrust hits harder
@export var use_dash_thrust  : bool  = false  # set true to use dash version

# ── State ──────────────────────────────────────────────────────────────────────

enum State { IDLE, WALKING, RUNNING, JUMPING, FALLING, ROLLING, ATTACKING, BLOCKING, HURT, DEAD }

var current_state   : State  = State.IDLE
var facing          : String = "right"   # "right" or "left"
var vert_facing     : String = "down"    # "down" or "up" — for non-combat vertical dirs
var attack_timer    : float  = 0.0
var thrust_timer    : float  = 0.0
var is_blocking     : bool   = false
var _impact_dealt   : bool   = false
var _thrust_dealt   : bool   = false

# ── Node refs ──────────────────────────────────────────────────────────────────

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

# ── Resources ──────────────────────────────────────────────────────────────────

var _nc_frames      : SpriteFrames   # non-combat  (24×24)
var _co_frames      : SpriteFrames   # combat      (32×32)
var _thrust_nd      : SpriteFrames   # thrust no-dash (32×32, 8 frames)
var _thrust_d       : SpriteFrames   # thrust dash    (32×32, 8 frames)

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_nc_frames = load("res://assets/animations/heavy_knight_non_combat.tres")
	_co_frames = load("res://assets/animations/heavy_knight_combat.tres")
	_thrust_nd = load("res://assets/animations/heavy_knight_thrust_nodash.tres")
	_thrust_d  = load("res://assets/animations/heavy_knight_thrust_dash.tres")

	if _nc_frames == null or _co_frames == null or _thrust_nd == null or _thrust_d == null:
		push_error("HeavyKnight: missing SpriteFrames resources. Run EditorScripts first.")
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
		State.JUMPING:
			_check_impact_frame()
		State.ATTACKING:
			_check_impact_frame()
		State.ROLLING:
			pass  # animation_finished callback handles return to idle
		State.DEAD:
			pass  # hold corpse frame

	move_and_slide()


# ── Public API ─────────────────────────────────────────────────────────────────

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
			sprite.animation_finished.connect(
				func(): set_state(State.IDLE), CONNECT_ONE_SHOT)

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
			sprite.animation_finished.connect(
				func(): set_state(State.IDLE), CONNECT_ONE_SHOT)

		State.DEAD:
			_set_frames(_nc_frames)
			_play_nc("death")
			sprite.animation_finished.connect(_on_death_finished, CONNECT_ONE_SHOT)


func stop_blocking() -> void:
	is_blocking = false
	set_state(State.IDLE)


func thrust_attack() -> void:
	## Trigger the 8-frame thrust attack (stationary or dash version).
	if thrust_timer > 0.0 or current_state == State.DEAD:
		return
	thrust_timer = thrust_cooldown
	_thrust_dealt = false
	current_state = State.ATTACKING

	var frames := _thrust_d if use_dash_thrust else _thrust_nd
	_set_frames(frames)
	sprite.play("thrust_" + facing)
	sprite.animation_finished.connect(_on_thrust_finished, CONNECT_ONE_SHOT)


func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return
	if is_blocking:
		## Blocking reduces damage — tune reduction amount as needed
		amount = int(amount * 0.25)
		if amount == 0:
			return

	set_state(State.HURT)


# ── Impact frame detection ──────────────────────────────────────────────────────

func _check_impact_frame() -> void:
	## Combat attacks: impact at frame index 2
	## Thrust attacks: impact at frame index 4 (peak white flash)
	if _impact_dealt:
		return
	if sprite.frame >= 2:
		_impact_dealt = true
		_on_attack_impact()


func _on_attack_impact() -> void:
	## Override or connect a signal here to deal damage.
	## Called at the first impact frame during any attack animation.
	print("HeavyKnight attack impact! Damage: ", base_damage)
	## emit_signal("attack_landed", global_position, facing, base_damage)


func _on_thrust_finished() -> void:
	## Thrust impact: peak is around frame 4.
	## _check_impact_frame() handles mid-animation detection while in ATTACKING state.
	print("HeavyKnight thrust complete!")
	set_state(State.IDLE)


# ── Animation helpers ──────────────────────────────────────────────────────────

func _play_nc(base: String) -> void:
	## Non-combat: uses down/up/right/left directions.
	## For movement, map horizontal velocity to right/left; vertical to down/up.
	var dir := _get_nc_direction(base)
	var anim := base + "_" + dir
	if not _nc_frames.has_animation(anim):
		anim = base + "_down"
	if sprite.animation != anim:
		sprite.play(anim)


func _play_co_attack() -> void:
	## Pick attack type — cycle through all 4 or pick based on context.
	## Default: horizontal slash (most readable as a standard attack)
	sprite.play("attack_horizontal_" + facing)


func _get_nc_direction(base: String) -> String:
	## Map current velocity to a direction label for non-combat animations.
	## Horizontal movement → right/left
	## Vertical movement (or stationary) → down/up based on vert_facing
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
	## Combat frames are 32×32, non-combat are 24×24.
	## Offset keeps the character body in the same screen position.
	if frames == _nc_frames:
		sprite.offset = Vector2.ZERO
	else:
		sprite.offset = Vector2(-4.0, -4.0)  # tune after visual verification


func _update_facing() -> void:
	if velocity.x > 5.0:
		facing = "right"
	elif velocity.x < -5.0:
		facing = "left"
	if velocity.y > 5.0:
		vert_facing = "down"
	elif velocity.y < -5.0:
		vert_facing = "up"


# ── Animation callbacks ────────────────────────────────────────────────────────

func _on_attack_finished() -> void:
	set_state(State.IDLE)


func _on_jump_finished() -> void:
	set_state(State.FALLING)


func _on_death_finished() -> void:
	## Transition to corpse hold frame
	if _nc_frames.has_animation("death_corpse"):
		_set_frames(_nc_frames)
		sprite.play("death_corpse")
	else:
		sprite.stop()
