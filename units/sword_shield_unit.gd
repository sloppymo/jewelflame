## sword_shield_unit.gd
## Sword & Shield Fighter — handles both non-combat (16x16) and combat (32x32) sprite sheets.
## Extend your base unit class or use standalone.
##
## Sprite sheet facts:
##   Non-combat: 16x16 frames, 8 directions, animations: idle/walk/walk2/death
##   Combat:     32x32 frames, 4 directions (S/N/W/E), animations: attack1-3/hurt/special
##
## Formation: V-shape, 5 troops, tuned for 16x16 base sprites.

class_name SwordShieldUnit
extends CharacterBody2D

# ── Exports ────────────────────────────────────────────────────────────────────

@export var max_troops     : int   = 5
@export var base_damage    : int   = 15
@export var move_speed     : float = 100.0
@export var attack_range   : float = 25.0
@export var attack_cooldown: float = 1.0

# ── State ──────────────────────────────────────────────────────────────────────

enum State { IDLE, WALKING, ATTACKING, HURT, DEAD }

var current_state  : State  = State.IDLE
var current_troops : int    = 5
var facing_dir     : String = "s"   # 8-dir: n ne e se s sw w nw
var facing_4dir    : String = "s"   # 4-dir for combat sheet: n s e w
var attack_timer   : float  = 0.0
var is_hurt_active : bool   = false
var _move_target   : Vector2 = Vector2.ZERO
var _has_target    : bool   = false

# ── Node refs ──────────────────────────────────────────────────────────────────

## V-formation positions — tuned for 16x16 sprites.
## If your scene uses different node names, adjust here.
@onready var troop_sprites: Array[AnimatedSprite2D] = [
	$Troop_0,   # Leader — front center
	$Troop_1,   # Left flank
	$Troop_2,   # Right flank
	$Troop_3,   # Back left
	$Troop_4,   # Back right
]

const FORMATION_POSITIONS: Array[Vector2] = [
	Vector2(0,    0),     # Troop_0 — centered
	Vector2(-80,  64),    # Troop_1 — wider spread for 4x sprites
	Vector2(80,   64),    # Troop_2
	Vector2(-64,  128),   # Troop_3
	Vector2(64,   128),   # Troop_4
]

# ── Resources (set in _ready or via export) ────────────────────────────────────

var _nc_frames : SpriteFrames   # non-combat
var _co_frames : SpriteFrames   # combat

# ── Lifecycle ──────────────────────────────────────────────────────────────────

func _ready() -> void:
	_nc_frames = load("res://assets/animations/swordshield_non_combat.tres")
	_co_frames = load("res://assets/animations/swordshield_combat.tres")

	if _nc_frames == null or _co_frames == null:
		push_error("SwordShieldUnit: missing SpriteFrames resources. Run both EditorScripts first.")
		return

	# Apply formation positions
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
			_play_combat("attack1")
			# Return to idle when animation finishes
			for s in _visible_troops():
				if not s.animation_finished.is_connected(_on_attack_finished):
					s.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)

		State.HURT:
			_set_all_frames(_co_frames)
			_play_combat("hurt")
			is_hurt_active = true
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

	# Each troop represents (max_hp / max_troops) HP
	var troops_lost := ceili(float(amount) / (100.0 / float(max_troops)))
	current_troops = max(0, current_troops - troops_lost)

	_sync_troop_visibility()

	if current_troops <= 0:
		set_state(State.DEAD)
	else:
		set_state(State.HURT)


func calculate_damage() -> int:
	## Damage scales linearly with remaining troop count.
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
	## Play a non-combat animation (8-directional).
	var anim := base + "_" + facing_dir
	# Death group has limited directions — fall back gracefully
	if not _nc_frames.has_animation(anim):
		var fallback_map := {"nw":"ne", "ne":"nw", "sw":"se", "se":"sw"}
		anim = base + "_" + fallback_map.get(facing_dir, "s")
	_play_on_all(anim)


func _play_combat(base: String) -> void:
	## Play a combat animation (4-directional).
	var anim := base + "_" + facing_4dir
	if not _co_frames.has_animation(anim):
		anim = base + "_s"  # safe fallback
	_play_on_all(anim)


func _play_on_all(anim_name: String) -> void:
	for s in _visible_troops():
		if s.animation != anim_name:
			s.play(anim_name)


func _set_all_frames(frames: SpriteFrames) -> void:
	for s in troop_sprites:
		if s.sprite_frames != frames:
			s.sprite_frames = frames
		# Combat sprites are 32x32 — offset to center, but bias toward bottom
		# to prevent sword from clipping at top of viewport during swings
		if frames == _co_frames:
			s.offset = Vector2(-8.0, -4.0)  # Less negative Y to keep sword in frame
		else:
			s.offset = Vector2.ZERO


func _sync_troop_visibility() -> void:
	## Show/hide troops. Dead troops leave STATIC GAPS — no repositioning.
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

	# 8-direction for non-combat sheet
	var dirs8 := ["e", "se", "s", "sw", "w", "nw", "n", "ne"]
	var idx8   := int(fmod((degrees + 22.5) / 45.0, 8.0))
	facing_dir = dirs8[idx8]

	# 4-direction for combat sheet
	# Collapse diagonals to nearest cardinal
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
	is_hurt_active = false
	if current_state != State.DEAD:
		set_state(State.IDLE)


func _on_death_finished() -> void:
	## Hold on the corpse frame if available; otherwise freeze last frame.
	if _nc_frames.has_animation("death_corpse"):
		_play_on_all("death_corpse")
	else:
		for s in _visible_troops():
			s.stop()
