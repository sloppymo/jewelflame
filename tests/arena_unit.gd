class_name ArenaUnit
extends CharacterBody2D
## A single combat unit in the arena. Handles AI, animations, and combat state.

const ArrowProjectile := preload("res://tests/arrow_projectile.gd")
const MageProjectile := preload("res://tests/mage_projectile.gd")
const HealthBarScene := preload("res://tests/health_bar.tscn")

#region Signals
signal unit_spawned(unit: ArenaUnit)
signal unit_died(unit: ArenaUnit)
signal damage_dealt(amount: int, target: ArenaUnit)
signal state_changed(new_state: State)
signal hp_changed(new_hp: int, max_hp: int)
signal animation_changed(anim_name: String)
signal spell_cast(caster_name: String, spell_name: String, team: int)
#endregion

#region Enums
enum State { IDLE, CHARGE, ATTACK, HURT, DEAD }
#endregion

#region Constants
const KNOCKBACK_FORCE := 150.0
const KNOCKBACK_DECAY := 400.0
const ALLY_AVOIDANCE_DISTANCE := 25.0
const ALLY_AVOIDANCE_WEIGHT := 0.5
const ATTACK_HIT_WINDOW_START := 0.2
const ATTACK_HIT_WINDOW_END := 0.5
const HURT_DURATION := 0.3
const ATTACK_RANGE_MULTIPLIER := 1.5
#endregion

#region Exported Variables
@export var team: int = 1
@export var unit_type: UnitType.Enum = UnitType.Enum.KNIGHT
#endregion

#region Public Variables
var config: UnitConfig = null
var max_hp: int = 100
var hp: int = 100
var attack_damage: int = 10
var move_speed: float = 60.0
var attack_cooldown: float = 1.0
var attack_range: float = 35.0
var state: State = State.IDLE
var is_dead: bool = false
var direction: String = "e"
var target: ArenaUnit = null
var nc_sprite: AnimatedSprite2D = null
var co_sprite: AnimatedSprite2D = null
var active_sprite: AnimatedSprite2D = null

## Cached references passed from CombatLab (avoids group queries)
var _cached_allies: Array[ArenaUnit] = []
var _cached_enemies: Array[ArenaUnit] = []
#endregion

#region Private Variables
var _state_timer: float = 0.0
var _attack_timer: float = 0.0
var _has_hit: bool = false
var _knockback_velocity: Vector2 = Vector2.ZERO
var _health_bar: HealthBar = null
var _attack_variant: int = 0  # Cycles through different attacks for mages
#endregion

#region Initialization
func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	_add_health_bar()
	unit_spawned.emit(self)

func _add_health_bar() -> void:
	## Creates a health bar above the unit using the HealthBar scene
	_health_bar = HealthBarScene.instantiate()
	_health_bar.setup(team)
	add_child(_health_bar)

func setup(p_config: UnitConfig, p_team: int, p_pos: Vector2) -> void:
	config = p_config
	team = p_team
	position = p_pos
	max_hp = config.max_hp
	hp = max_hp
	attack_damage = config.damage
	move_speed = config.speed
	attack_cooldown = config.attack_cooldown
	attack_range = config.attack_range
	scale = Vector2(config.scale, config.scale)
	
	_create_sprites()
	_update_health_bar()

func _create_sprites() -> void:
	# Non-combat sprite (idle, walk)
	nc_sprite = AnimatedSprite2D.new()
	nc_sprite.sprite_frames = config.nc_frames
	nc_sprite.animation_finished.connect(_on_animation_finished)
	nc_sprite.name = "NCSprite"
	add_child(nc_sprite)
	
	# Combat sprite (attack, hurt, death)
	co_sprite = AnimatedSprite2D.new()
	co_sprite.sprite_frames = config.co_frames
	co_sprite.animation_finished.connect(_on_animation_finished)
	co_sprite.name = "COSprite"
	co_sprite.visible = false
	add_child(co_sprite)

func _update_health_bar() -> void:
	## Updates the health bar display
	if not _health_bar:
		return
	_health_bar.update(hp, max_hp, state)

func _update_health_bar_opacity() -> void:
	## Updates health bar opacity based on combat state
	if not _health_bar:
		return
	_health_bar.update(hp, max_hp, state)
#endregion

#region Main Loop
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	_state_timer += delta
	
	# Apply knockback
	if _knockback_velocity.length() > 1.0:
		position += _knockback_velocity * delta
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		return
	
	match state:
		State.IDLE:
			_update_idle()
		State.CHARGE:
			_update_charge(delta)
		State.ATTACK:
			_update_attack(delta)
		State.HURT:
			_update_hurt()
#endregion

#region State Updates
func _update_idle() -> void:
	_play_anim("idle_" + direction, true)
	# Check if aggro is enabled
	var parent := get_parent()
	if parent and parent.has_method("is_in_bounds") and not parent.aggro_enabled:
		return  # Don't look for targets when aggro is disabled
	_find_target(_cached_enemies)
	if target and is_instance_valid(target) and not target.is_dead:
		_change_state(State.CHARGE)

func _update_charge(delta: float) -> void:
	# Check if aggro is disabled - return to idle
	var parent := get_parent()
	if parent and parent.has_method("is_in_bounds") and not parent.aggro_enabled:
		_change_state(State.IDLE)
		return
		
	if not target or not is_instance_valid(target) or target.is_dead:
		target = null
		_change_state(State.IDLE)
		return
	
	var dist := position.distance_to(target.position)
	if dist <= attack_range:
		_change_state(State.ATTACK)
		_attack_timer = 0.0
		_has_hit = false
		return
	
	var move_dir := (target.position - position).normalized()
	_update_direction(move_dir)
	
	# Avoid clumping with allies
	move_dir = _apply_ally_avoidance(move_dir, _cached_allies)
	
	var next_pos := position + move_dir * move_speed * delta
	if get_parent().has_method("is_in_bounds"):
		if get_parent().is_in_bounds(next_pos):
			position = next_pos
	else:
		position = next_pos
	
	_play_anim("walk_" + direction, true)

func _apply_ally_avoidance(move_dir: Vector2, allies: Array[ArenaUnit]) -> Vector2:
	var adjusted_dir := move_dir
	for unit in allies:
		if unit == self or not is_instance_valid(unit):
			continue
		if unit.is_dead:
			continue
		var dist_to_ally := position.distance_to(unit.position)
		if dist_to_ally < ALLY_AVOIDANCE_DISTANCE:
			adjusted_dir += (position - unit.position).normalized() * ALLY_AVOIDANCE_WEIGHT
	return adjusted_dir.normalized()

func _update_attack(delta: float) -> void:
	# Check if aggro is disabled - stop attacking
	var parent := get_parent()
	if parent and parent.has_method("is_in_bounds") and not parent.aggro_enabled:
		_change_state(State.IDLE)
		return
		
	# Face target (but don't constantly update for simple_facing units to avoid spinning)
	if target and is_instance_valid(target):
		var attack_dir := (target.position - position).normalized()
		# Only update direction on first attack frame or for non-simple_facing units
		if not config.simple_facing or _state_timer < 0.05:
			_update_direction(attack_dir)
	
	_attack_timer += delta
	
	# Deal damage during attack animation window
	if _state_timer > ATTACK_HIT_WINDOW_START and _state_timer < ATTACK_HIT_WINDOW_END and not _has_hit:
		_has_hit = true
		
		# For units with AoE (like Dragon), hit all enemies in radius
		if config.aoe_radius > 0:
			_apply_aoe_damage(_cached_enemies)
		# For archers, spawn a visible arrow projectile
		elif config.unit_name == "Archer" and not config.arrow_path.is_empty():
			_spawn_arrow_projectile()
		elif config.is_mage:
			_spawn_mage_projectile()
		else:
			# Single target damage (melee)
			if target and is_instance_valid(target) and not target.is_dead:
				var dist := position.distance_to(target.position)
				if dist <= attack_range * ATTACK_RANGE_MULTIPLIER:
					target.take_hit((target.position - position).normalized())
					damage_dealt.emit(attack_damage, target)
	
	# Play appropriate animation
	if config.is_mage:
		if config.unit_name == "DragonGreen":
			_play_anim("firebreath_" + direction, true)
		else:
			_play_anim("cast_" + direction, true)
	else:
		_play_anim("attack_" + direction, true)
	
	# Return to charge after cooldown
	if _attack_timer >= attack_cooldown:
		_change_state(State.CHARGE)

func _apply_aoe_damage(enemies: Array[ArenaUnit]) -> void:
	## Applies damage to all enemies within aoe_radius
	if config.aoe_radius <= 0:
		return
	
	for unit in enemies:
		if not is_instance_valid(unit):
			continue
		if unit.is_dead:
			continue
		
		var dist := position.distance_to(unit.position)
		if dist <= config.aoe_radius:
			unit.take_hit((unit.position - position).normalized())
			damage_dealt.emit(attack_damage, unit)

func _spawn_arrow_projectile() -> void:
	## Spawns a visible arrow projectile toward the target
	if not target or not is_instance_valid(target):
		return
	
	# Emit signal for UI notification (Archer shots are less dramatic, show occasionally)
	if _attack_variant % 3 == 0:  # Only show every 3rd shot to avoid spam
		spell_cast.emit(config.unit_name, "Arrow Shot", team)
	_attack_variant += 1
	
	var arrow := ArrowProjectile.new()
	var spawn_pos := position + (target.position - position).normalized() * 20
	var dir := (target.position - position).normalized()
	
	arrow.setup(spawn_pos, dir, attack_damage, team, 500.0)
	
	# Add to the same parent as this unit (the CombatLab)
	if get_parent():
		get_parent().add_child(arrow)

func _spawn_mage_projectile() -> void:
	## Spawns a visible magical projectile toward the target
	if not target or not is_instance_valid(target):
		return
	
	var projectile := MageProjectile.new()
	var spawn_pos := position + (target.position - position).normalized() * 20
	var dir := (target.position - position).normalized()
	
	# Determine spell type - mages can have primary and secondary spells
	var spell := config.spell_type if not config.spell_type.is_empty() else "fireball"
	
	# If mage has secondary spell, alternate between them
	if not config.secondary_spell_type.is_empty():
		# Every other attack uses secondary spell
		if (_attack_variant / 3) % 2 == 1:
			spell = config.secondary_spell_type
	
	# Calculate variant within the current spell type
	var variant := _attack_variant % config.num_spell_variants
	
	# Get the spell name before creating projectile
	var spell_name := _get_spell_name(spell, variant)
	
	# Emit signal for UI notification
	spell_cast.emit(config.unit_name, spell_name, team)
	
	# Pass the current attack variant and increment for next attack
	projectile.setup(spawn_pos, dir, attack_damage, team, config.projectile_speed, spell, variant)
	_attack_variant = (_attack_variant + 1) % 12  # Cycle through many variants
	
	if get_parent():
		get_parent().add_child(projectile)

func _get_spell_name(spell_type: String, variant: int) -> String:
	## Returns the display name for a spell based on type and variant
	match spell_type:
		"fireball", "fire":
			match variant % 6:
				0: return "Fireball"
				1: return "Flame Wave"
				2: return "Inferno Burst"
				3: return "Meteor Strike"
				4: return "Hellfire"
				5: return "Arcane Fire"
		"lightning", "electric":
			match variant % 6:
				0: return "Lightning Bolt"
				1: return "Static Orb"
				2: return "Thunder Strike"
				3: return "Blood Lightning"
				4: return "Crimson Spark"
				5: return "Storm Orb"
		"ice", "frost":
			match variant % 6:
				0: return "Frost Shard"
				1: return "Glacial Spike"
				2: return "Deep Freeze"
				3: return "Hoarfrost"
				4: return "Cryo Blast"
				5: return "Pure Ice"
		"arcane", "magic":
			match variant % 6:
				0: return "Mana Dart"
				1: return "Mystic Bolt"
				2: return "Eldritch Blast"
				3: return "Void Sphere"
				4: return "Blood Magic"
				5: return "Staff Blast"
		"heal", "holy", "priest":
			match variant % 3:
				0: return "Smite"
				1: return "Holy Light"
				2: return "Blessed Bolt"
		_:
			return "Magic Missile"
	return "Unknown Spell"

func _update_hurt() -> void:
	if _state_timer > HURT_DURATION:
		_change_state(State.CHARGE)
		_find_target(_cached_enemies)

func _change_state(new_state: State) -> void:
	if state != new_state:
		state = new_state
		_state_timer = 0.0
		state_changed.emit(new_state)
		_update_health_bar_opacity()  # Update visibility when combat starts/ends
#endregion

#region Direction & Targeting
func _update_direction(dir: Vector2) -> void:
	var angle := dir.angle()
	var deg := rad_to_deg(angle)
	
	# 8-way direction mapping
	if deg >= -22.5 and deg < 22.5:
		direction = "e"
	elif deg >= 22.5 and deg < 67.5:
		direction = "se"
	elif deg >= 67.5 and deg < 112.5:
		direction = "s"
	elif deg >= 112.5 and deg < 157.5:
		direction = "sw"
	elif deg >= 157.5 or deg < -157.5:
		direction = "w"
	elif deg >= -157.5 and deg < -112.5:
		direction = "nw"
	elif deg >= -112.5 and deg < -67.5:
		direction = "n"
	elif deg >= -67.5 and deg < -22.5:
		direction = "ne"

func _find_target(enemies: Array[ArenaUnit]) -> void:
	var nearest: ArenaUnit = null
	var nearest_dist := 999999.0
	
	for unit in enemies:
		if not is_instance_valid(unit):
			continue
		if unit.is_dead:
			continue
		var dist := position.distance_to(unit.position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = unit
	
	target = nearest
#endregion

#region Combat
func take_hit(from_dir: Vector2) -> void:
	if is_dead:
		return
	
	set_hp(hp - attack_damage)
	_knockback_velocity = from_dir * KNOCKBACK_FORCE
	
	if hp <= 0:
		_die(from_dir)
	elif state != State.ATTACK:
		_change_state(State.HURT)
		_update_direction(-from_dir)
		_play_anim("hurt_" + direction, false)

func _die(from_dir: Vector2) -> void:
	is_dead = true
	_change_state(State.DEAD)
	_update_direction(-from_dir)
	_play_anim("death_" + direction, false)
	
	# Hide health bar when dead
	if _health_bar:
		_health_bar.hide_bar()
	
	unit_died.emit(self)
#endregion

#region Animation
func _play_anim(anim_name: String, loop: bool = true) -> void:
	var use_combat := false
	var base_name := anim_name.rsplit("_", true, 1)[0]
	
	if base_name in ["attack", "hurt", "death", "special", "cast", "firebreath"]:
		use_combat = true
	
	# Switch active sprite
	if use_combat and co_sprite and co_sprite.sprite_frames:
		active_sprite = co_sprite
		nc_sprite.visible = false
		co_sprite.visible = true
	elif nc_sprite and nc_sprite.sprite_frames:
		active_sprite = nc_sprite
		co_sprite.visible = false
		nc_sprite.visible = true
	else:
		return
	
	# Handle simple_facing units (like Dragon) - only use _right animations with flip_h
	if config.simple_facing:
		var simple_anim := base_name + "_right"
		if active_sprite.sprite_frames.has_animation(simple_anim):
			# Determine if we need to flip based on target direction
			if target and is_instance_valid(target):
				var facing_right := target.position.x > position.x
				active_sprite.flip_h = not facing_right
			
			if active_sprite.animation != simple_anim:
				active_sprite.play(simple_anim)
				animation_changed.emit(simple_anim)
			elif not active_sprite.is_playing():
				active_sprite.play(simple_anim)
			return
	
	# Try exact animation name first
	var actual_anim := anim_name
	if not active_sprite.sprite_frames.has_animation(anim_name):
		var candidates := _get_animation_candidates(base_name, direction)
		for candidate in candidates:
			if active_sprite.sprite_frames.has_animation(candidate):
				actual_anim = candidate
				break
	
	if active_sprite.sprite_frames.has_animation(actual_anim):
		if active_sprite.animation != actual_anim:
			active_sprite.play(actual_anim)
			animation_changed.emit(actual_anim)
		elif not active_sprite.is_playing():
			active_sprite.play(actual_anim)

func _get_animation_candidates(base_name: String, dir: String) -> Array[String]:
	var candidates: Array[String] = []
	
	# 4-dir mapping from 8-dir
	var four_dir_map := {
		"n": "up", "ne": "up", "nw": "up",
		"s": "down", "se": "down", "sw": "down",
		"e": "right", "w": "left"
	}
	var four_dir: String = four_dir_map.get(dir, "down")
	
	# Try various patterns
	candidates.append(base_name + "_" + dir)
	candidates.append(base_name + "_" + four_dir)
	candidates.append(base_name + "_right")
	candidates.append(base_name + "_left")
	candidates.append(base_name + "_down")
	
	if base_name == "attack":
		candidates.append("attack1_" + dir)
		candidates.append("attack_light_" + dir)
		candidates.append("attack_heavy_" + dir)
		candidates.append("attack_" + four_dir + "_right")
		candidates.append("attack_" + four_dir + "_left")
	
	# Fallbacks
	candidates.append(base_name + "_s")
	candidates.append(base_name)
	
	return candidates

func _on_animation_finished() -> void:
	if is_dead:
		return
	
	match state:
		State.ATTACK:
			_change_state(State.CHARGE)
			_has_hit = false
			_find_target(_cached_enemies)
#endregion

#region Public API
func set_facing(facing_dir: String) -> void:
	direction = facing_dir

func force_play_animation(anim_name: String) -> void:
	_play_anim(anim_name, true)

func get_current_frame() -> int:
	if active_sprite:
		return active_sprite.frame
	return 0

func get_frame_count() -> int:
	if active_sprite and active_sprite.sprite_frames:
		return active_sprite.sprite_frames.get_frame_count(active_sprite.animation)
	return 0

func set_animation_speed(speed: float) -> void:
	if active_sprite:
		active_sprite.speed_scale = speed

func pause_animation() -> void:
	if active_sprite:
		active_sprite.pause()

func resume_animation() -> void:
	if active_sprite:
		active_sprite.play()

func step_frame_forward() -> void:
	if not active_sprite:
		return
	active_sprite.pause()
	var current := active_sprite.frame
	var max_frames := active_sprite.sprite_frames.get_frame_count(active_sprite.animation)
	active_sprite.frame = (current + 1) % max_frames

func step_frame_back() -> void:
	if not active_sprite:
		return
	active_sprite.pause()
	var current := active_sprite.frame
	var max_frames := active_sprite.sprite_frames.get_frame_count(active_sprite.animation)
	active_sprite.frame = (current - 1 + max_frames) % max_frames

func get_animation_names() -> Array[String]:
	if active_sprite and active_sprite.sprite_frames:
		var names := active_sprite.sprite_frames.get_animation_names()
		var result: Array[String] = []
		for name in names:
			result.append(name)
		return result
	return []

var _cached_frame_data: Dictionary = {}
var _cached_frame_index: int = -1
var _cached_anim_name: String = ""

func get_current_frame_data() -> Dictionary:
	## Returns detailed data about the current animation frame (cached)
	if not active_sprite or not active_sprite.sprite_frames:
		return {}
	
	var frame := active_sprite.frame
	var anim_name := active_sprite.animation
	
	# Return cached data if frame hasn't changed
	if frame == _cached_frame_index and anim_name == _cached_anim_name and not _cached_frame_data.is_empty():
		return _cached_frame_data
	
	# Build new data
	var frames := active_sprite.sprite_frames
	_cached_frame_data = {
		"animation": anim_name,
		"frame": frame,
		"frame_count": frames.get_frame_count(anim_name),
		"texture_size": Vector2.ZERO,
		"atlas_region": Rect2(),
		"has_atlas": false,
		"fps": frames.get_animation_speed(anim_name),
		"duration": frames.get_frame_duration(anim_name, frame),
		"flip_h": active_sprite.flip_h,
		"loop": frames.get_animation_loop(anim_name)
	}
	
	var texture := frames.get_frame_texture(anim_name, frame)
	if texture:
		_cached_frame_data["texture_size"] = texture.get_size()
		if texture is AtlasTexture:
			_cached_frame_data["atlas_region"] = texture.region
			_cached_frame_data["has_atlas"] = true
	
	_cached_frame_index = frame
	_cached_anim_name = anim_name
	return _cached_frame_data

func clear_frame_cache() -> void:
	_cached_frame_data.clear()
	_cached_frame_index = -1

func set_hp(new_hp: int) -> void:
	## Sets HP and updates health bar display
	var old_hp := hp
	hp = clamp(new_hp, 0, max_hp)
	if hp != old_hp:
		_update_health_bar()
		hp_changed.emit(hp, max_hp)

func get_idle_frame_offset() -> Vector2:
	## Note: This method was comparing atlas positions which doesn't indicate
	## sprite misalignment. Real alignment checking would need to analyze
	## the actual pixel content of each frame to find the character's center.
	## For now, return zero to avoid misleading "MISALIGNED" warnings.
	return Vector2.ZERO
#endregion
