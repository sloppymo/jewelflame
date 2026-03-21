## knight_unit.gd
## 2-Handed Swordsman — heavy infantry unit with 5-troop formation.
## Uses 16×16 non-combat frames and 32×32 combat frames.

class_name KnightUnit
extends CharacterBody2D

# ── Exports ────────────────────────────────────────────────────────────────────

@export var max_troops     : int   = 5
@export var base_damage    : int   = 20
@export var move_speed     : float = 90.0
@export var attack_range   : float = 30.0
@export var attack_cooldown: float = 1.2

# ── State ──────────────────────────────────────────────────────────────────────

enum State { IDLE, WALKING, ATTACKING, HURT, DEAD }

var current_state  : State  = State.IDLE
var current_troops : int    = 5
var facing_dir     : String = "s"   # 8-dir: n ne e se s sw w nw
var attack_timer   : float  = 0.0
var _move_target   : Vector2 = Vector2.ZERO
var _has_target    : bool   = false

# ── Node refs ──────────────────────────────────────────────────────────────────

@onready var troop_sprites: Array[AnimatedSprite2D] = [
	$Troop_0, $Troop_1, $Troop_2, $Troop_3, $Troop_4,
]

const FORMATION_POSITIONS: Array[Vector2] = [
	Vector2(0,    0),     # Leader
	Vector2(-80,  64),    # Left flank
	Vector2(80,   64),    # Right flank
	Vector2(-64,  128),   # Back left
	Vector2(64,   128),   # Back right
]

# ── Resources ──────────────────────────────────────────────────────────────────

var _nc_frames : SpriteFrames
var _co_frames : SpriteFrames

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_nc_frames = load("res://assets/animations/knight_non_combat.tres")
	_co_frames = load("res://assets/animations/knight_combat.tres")

	if _nc_frames == null or _co_frames == null:
		push_error("KnightUnit: missing SpriteFrames. Run EditorScripts first.")
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
			_set_all_frames(_co_frames)
			_play_combat("attack_light")
			for s in _visible_troops():
				if not s.animation_finished.is_connected(_on_attack_finished):
					s.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)

		State.HURT:
			_set_all_frames(_co_frames)
			_play_combat("hurt")
			for s in _visible_troops():
				if not s.animation_finished.is_connected(_on_hurt_finished):
					s.animation_finished.connect(_on_hurt_finished, CONNECT_ONE_SHOT)

		State.DEAD:
			_set_all_frames(_nc_frames)
			_play_non_combat("death")
			for s in _visible_troops():
				if not s.animation_finished.is_connected(_on_death_finished):
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


# ── Animation helpers ──────────────────────────────────────────────────────────

func _play_non_combat(base: String) -> void:
	var anim := base + "_" + facing_dir
	if not _nc_frames.has_animation(anim):
		var fallback_map := {"nw":"ne", "ne":"nw", "sw":"se", "se":"sw"}
		anim = base + "_" + fallback_map.get(facing_dir, "s")
	_play_on_all(anim)


func _play_combat(base: String) -> void:
	var anim := base + "_" + facing_dir
	if not _co_frames.has_animation(anim):
		anim = base + "_s"
	_play_on_all(anim)


func _play_on_all(anim_name: String) -> void:
	for s in _visible_troops():
		if s.animation != anim_name:
			s.play(anim_name)


func _set_all_frames(frames: SpriteFrames) -> void:
	for s in troop_sprites:
		if s.sprite_frames != frames:
			s.sprite_frames = frames
		if frames == _co_frames:
			s.offset = Vector2(-8.0, -4.0)
		else:
			s.offset = Vector2.ZERO


func _sync_troop_visibility() -> void:
	for i in range(max_troops):
		troop_sprites[i].visible = (i < current_troops)


func _visible_troops() -> Array:
	return troop_sprites.filter(func(s): return s.visible)


# ── Direction helpers ──────────────────────────────────────────────────────────

func _update_facing(vel: Vector2) -> void:
	if vel.length_squared() < 4.0:
		return

	var angle   := vel.angle()
	var degrees := fmod(rad_to_deg(angle) + 360.0, 360.0)

	var dirs8 := ["e", "se", "s", "sw", "w", "nw", "n", "ne"]
	var idx8   := int(fmod((degrees + 22.5) / 45.0, 8.0))
	facing_dir = dirs8[idx8]


# ── Animation callbacks ────────────────────────────────────────────────────────

func _on_attack_finished() -> void:
	set_state(State.IDLE)


func _on_hurt_finished() -> void:
	if current_state != State.DEAD:
		set_state(State.IDLE)


func _on_death_finished() -> void:
	for s in _visible_troops():
		s.stop()
