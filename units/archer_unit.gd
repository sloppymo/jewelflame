## archer_unit.gd
## Archer unit — handles both non-combat (16×16) and combat (32×32) sprite sheets.
##
## Key difference from SwordShieldUnit:
##   - Combat sheet has only 4 shoot directions (E, W, S, N) — not 8
##   - Mirror directions (W = flipped E, hurt_w = flipped hurt_e) are baked into
##     the SpriteFrames resource, so the script just calls "shoot_w" normally
##   - Arrow deals damage at frame index 2 (the release frame with arrow flash)
##   - Ranged attack: default range 150px, no melee contact required
##
## Formation: V-shape, 5 troops, 16×16 base sprites.

class_name ArcherUnit
extends CharacterBody2D

# ── Exports ────────────────────────────────────────────────────────────────────

@export var max_troops      : int   = 5
@export var base_damage     : int   = 12   # ranged — slightly lower than melee
@export var move_speed      : float = 90.0
@export var attack_range    : float = 150.0
@export var attack_cooldown : float = 1.4   # slower fire rate than sword swing

# ── State ──────────────────────────────────────────────────────────────────────

enum State { IDLE, WALKING, ATTACKING, HURT, DEAD }

var current_state  : State  = State.IDLE
var current_troops : int    = 5
var facing_dir     : String = "s"    # 8-dir: n ne e se s sw w nw
var facing_4dir    : String = "s"    # 4-dir for combat sheet: n s e w
var attack_timer   : float  = 0.0
var _arrow_damage_dealt : bool = false
var _move_target   : Vector2 = Vector2.ZERO
var _has_target    : bool   = false

# ── Node refs ──────────────────────────────────────────────────────────────────

@onready var troop_sprites: Array[AnimatedSprite2D] = [
	$Troop_0,
	$Troop_1,
	$Troop_2,
	$Troop_3,
	$Troop_4,
]

const FORMATION_POSITIONS: Array[Vector2] = [
	Vector2(0,    0),     # Leader — centered
	Vector2(-80,  64),    # Left flank — wider spread
	Vector2(80,   64),    # Right flank
	Vector2(-64,  128),   # Back left
	Vector2(64,   128),   # Back right
]

# ── Resources ──────────────────────────────────────────────────────────────────

var _nc_frames : SpriteFrames
var _co_frames : SpriteFrames

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_nc_frames = load("res://assets/animations/archer_non_combat.tres")
	_co_frames = load("res://assets/animations/archer_combat.tres")

	if _nc_frames == null or _co_frames == null:
		push_error("ArcherUnit: missing SpriteFrames. Run both archer EditorScripts first.")
		return

	for i in range(max_troops):
		troop_sprites[i].position = FORMATION_POSITIONS[i]

	_sync_troop_visibility()
	_play_non_combat("idle")


func _physics_process(delta: float) -> void:
	attack_timer = max(0.0, attack_timer - delta)

	match current_state:
		State.WALKING:
			if _has_target and global_position.distance_to(_move_target) < 10.0:
				stop_moving()
			elif velocity.length() > 10.0:
				_update_facing(velocity)
				_play_non_combat("walk")
			else:
				set_state(State.IDLE)
		State.IDLE:
			_play_non_combat("idle")
		State.ATTACKING:
			# Check for arrow release frame to signal damage
			_check_arrow_frame()

	move_and_slide()


# ── Public API ─────────────────────────────────────────────────────────────────

func set_state(new_state: State) -> void:
	if current_state == State.DEAD:
		return
	current_state = new_state

	match new_state:
		State.IDLE:
			_set_all_frames(_nc_frames)
			_play_non_combat("idle")

		State.WALKING:
			_set_all_frames(_nc_frames)
			_play_non_combat("walk")

		State.ATTACKING:
			if attack_timer > 0.0:
				return
			attack_timer = attack_cooldown
			_arrow_damage_dealt = false
			_set_all_frames(_co_frames)
			_play_combat("shoot")
			for s in _visible_troops():
				s.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)

		State.HURT:
			_set_all_frames(_co_frames)
			_play_combat("hurt")
			for s in _visible_troops():
				s.animation_finished.connect(_on_hurt_finished, CONNECT_ONE_SHOT)

		State.DEAD:
			_set_all_frames(_nc_frames)
			_play_non_combat("death")
			for s in _visible_troops():
				s.animation_finished.connect(_on_death_finished, CONNECT_ONE_SHOT)


func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return
	var troops_lost := ceili(float(amount) / (100.0 / float(max_troops)))
	current_troops = max(0, current_troops - troops_lost)
	_sync_troop_visibility()
	if current_troops <= 0:
		set_state(State.DEAD)
	else:
		set_state(State.HURT)


func calculate_damage() -> int:
	## Damage scales with remaining troops. Ranged = lower base than melee.
	return int(float(base_damage) * float(current_troops) / float(max_troops))


func move_toward_target(target_pos: Vector2) -> void:
	_move_target = target_pos
	_has_target = true
	var dir := (target_pos - global_position).normalized()
	velocity = dir * move_speed
	_update_facing(velocity)
	set_state(State.WALKING)


func stop_moving() -> void:
	velocity = Vector2.ZERO
	_has_target = false
	set_state(State.IDLE)


func fire_at(target_pos: Vector2) -> void:
	## Point toward target, then trigger attack state.
	## Call this from your battle system instead of set_state(ATTACKING) directly
	## so facing is correct before the shoot animation plays.
	var dir := target_pos - global_position
	_update_facing(dir)
	set_state(State.ATTACKING)


# ── Arrow damage frame detection ───────────────────────────────────────────────

func _check_arrow_frame() -> void:
	## The arrow release frame is frame index 2 in the shoot animation.
	## Emit a signal or call your damage system here.
	## Checked every physics frame while in ATTACKING state.
	if _arrow_damage_dealt:
		return
	var any_sprite := _visible_troops()
	if any_sprite.is_empty():
		return
	var sprite : AnimatedSprite2D = any_sprite[0]
	if sprite.frame >= 2:
		_arrow_damage_dealt = true
		_on_arrow_released()


func _on_arrow_released() -> void:
	## Override or connect a signal here to deal ranged damage at the right moment.
	## Default: print for testing.
	print("Arrow released! Damage: ", calculate_damage())
	# Example: emit_signal("arrow_fired", global_position, facing_4dir, calculate_damage())


# ── Animation helpers ──────────────────────────────────────────────────────────

func _play_non_combat(base: String) -> void:
	var anim := base + "_" + facing_dir
	if not _nc_frames.has_animation(anim):
		# Death group has limited directions — mirror nearest diagonal
		var fallbacks := {"nw": "ne", "ne": "nw", "sw": "se", "se": "sw"}
		anim = base + "_" + fallbacks.get(facing_dir, "s")
	_play_on_all(anim)


func _play_combat(base: String) -> void:
	## Combat sheet uses 4-directional naming: n, s, e, w
	var anim := base + "_" + facing_4dir
	if not _co_frames.has_animation(anim):
		# hurt and death only have e/w — fall back to e for n/s
		var fallbacks := {"n": "s", "s": "s", "e": "e", "w": "w"}
		anim = base + "_" + fallbacks.get(facing_4dir, "e")
	_play_on_all(anim)


func _play_on_all(anim_name: String) -> void:
	for s in _visible_troops():
		if s.animation != anim_name:
			s.play(anim_name)


func _set_all_frames(frames: SpriteFrames) -> void:
	for s in troop_sprites:
		if s.sprite_frames != frames:
			s.sprite_frames = frames
		# Combat frames are 32×32 — offset to center, bias toward bottom
		# to prevent bow/arrow from clipping at top of viewport
		s.offset = Vector2(-8.0, -4.0) if frames == _co_frames else Vector2.ZERO


func _sync_troop_visibility() -> void:
	## Dead troops leave STATIC GAPS — no repositioning, ever.
	for i in range(max_troops):
		troop_sprites[i].visible = (i < current_troops)


func _visible_troops() -> Array:
	return troop_sprites.filter(func(s): return s.visible)


# ── Direction helpers ──────────────────────────────────────────────────────────

func _update_facing(dir_vec: Vector2) -> void:
	if dir_vec.length_squared() < 4.0:
		return

	var degrees := fmod(rad_to_deg(dir_vec.angle()) + 360.0, 360.0)

	# 8-direction for non-combat sheet
	var dirs8   := ["e", "se", "s", "sw", "w", "nw", "n", "ne"]
	facing_dir  = dirs8[int(fmod((degrees + 22.5) / 45.0, 8.0))]

	# 4-direction for combat sheet — collapse diagonals to nearest cardinal
	if degrees >= 315.0 or degrees < 45.0:
		facing_4dir = "e"
	elif degrees < 135.0:
		facing_4dir = "s"
	elif degrees < 225.0:
		facing_4dir = "w"
	else:
		facing_4dir = "n"


# ── Animation callbacks ────────────────────────────────────────────────────────

func _on_attack_finished() -> void:
	set_state(State.IDLE)


func _on_hurt_finished() -> void:
	if current_state != State.DEAD:
		set_state(State.IDLE)


func _on_death_finished() -> void:
	if _nc_frames.has_animation("death_corpse"):
		_play_on_all("death_corpse")
	else:
		for s in _visible_troops():
			s.stop()
