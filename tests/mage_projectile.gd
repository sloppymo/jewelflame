class_name MageProjectile
extends Node2D
## A magical projectile for mage units using actual sprite assets

#region Constants
const DEFAULT_SPEED: float = 300.0
const DEFAULT_LIFETIME: float = 3.0
const HIT_RADIUS: float = 25.0

# Spell data structure
class SpellData extends RefCounted:
	var name: String
	var texture_paths: Array[String]
	var trail_color: Color
	var hit_color: Color
	var speed_mult: float
	var damage_mult: float
	
	func _init(
		p_name: String,
		p_paths: Array[String],
		p_trail: Color,
		p_hit: Color,
		p_speed: float = 1.0,
		p_dmg: float = 1.0
	):
		name = p_name
		texture_paths = p_paths
		trail_color = p_trail
		hit_color = p_hit
		speed_mult = p_speed
		damage_mult = p_dmg
#endregion

#region Variables
var direction: Vector2 = Vector2.RIGHT
var speed: float = DEFAULT_SPEED
var damage: int = 10
var lifetime: float = 0.0
var max_lifetime: float = DEFAULT_LIFETIME
var source_team: int = 0
var has_hit: bool = false
var spell_type: String = "fireball"
var attack_variant: int = 0
var current_spell: SpellData = null

var sprite: Node2D = null
var particles: CPUParticles2D = null
#endregion

func _ready() -> void:
	z_index = 10
	
	# Get spell data based on type and variant
	current_spell = _get_spell_data()
	if current_spell:
		speed *= current_spell.speed_mult
	
	_create_visuals()

func _get_spell_data() -> SpellData:
	## Returns spell data based on spell type and variant
	match spell_type:
		"fireball", "fire":
			return _get_fire_spell()
		"lightning", "electric":
			return _get_lightning_spell()
		"ice", "frost":
			return _get_ice_spell()
		"heal", "holy", "priest":
			return _get_holy_spell()
		"arcane", "magic":
			return _get_arcane_spell()
		_:
			return _get_fire_spell()  # Default

func _get_fire_spell() -> SpellData:
	match attack_variant % 6:
		0: # Fireball
			return SpellData.new(
				"Fireball",
				["res://assets/Magical Effects/Fire_Explosion_28x28.png"],
				Color(1, 0.4, 0.1, 0.6),
				Color(1, 0.3, 0.1, 0.8),
				1.0, 1.0
			)
		1: # Flame Wave
			return SpellData.new(
				"Flame Wave",
				["res://assets/Magical Effects/Large_Fire_28x28.png"],
				Color(1, 0.5, 0.2, 0.6),
				Color(1, 0.4, 0.2, 0.8),
				0.9, 0.8
			)
		2: # Inferno Burst
			return SpellData.new(
				"Inferno Burst",
				["res://assets/Magical Effects/Fire_Explosion_ISOMETRIC_28x28.png"],
				Color(1, 0.3, 0.0, 0.7),
				Color(1, 0.2, 0.0, 0.9),
				0.95, 1.1
			)
		3: # Meteor Strike (using anti-alias glow)
			return SpellData.new(
				"Meteor Strike",
				["res://assets/Magical Effects/Fire_Explosion_Anti-Alias_glow.png"],
				Color(1, 0.6, 0.2, 0.7),
				Color(1, 0.5, 0.1, 0.9),
				0.85, 1.3
			)
		4: # Hellfire
			return SpellData.new(
				"Hellfire",
				["res://assets/Magical Effects/Large_Fire_Anti-Alias_glow_28x28.png"],
				Color(1, 0.2, 0.0, 0.8),
				Color(1, 0.1, 0.0, 1.0),
				0.8, 1.2
			)
		5: # Arcane Fire
			return SpellData.new(
				"Arcane Fire",
				[
					"res://assets/Characters(100x100)/Wizard/Magic(projectile)/Wizard-Attack01_Effect.png",
					"res://assets/Characters(100x100)/Wizard/Magic(projectile)/Wizard-Attack02_Effect.png"
				],
				Color(1, 0.5, 0.3, 0.6),
				Color(0.9, 0.4, 0.9, 0.8),
				1.1, 1.0
			)
	return null

func _get_lightning_spell() -> SpellData:
	match attack_variant % 6:
		0: # Lightning Bolt
			return SpellData.new(
				"Lightning Bolt",
				["res://assets/Magical Effects/Lightning_Blast_54x18.png"],
				Color(0.5, 0.9, 1.0, 0.6),
				Color(0.6, 0.9, 1.0, 0.9),
				1.3, 1.1
			)
		1: # Static Orb
			return SpellData.new(
				"Static Orb",
				["res://assets/Magical Effects/Lightning_Energy_48x48.png"],
				Color(0.6, 0.8, 1.0, 0.7),
				Color(0.7, 0.9, 1.0, 0.8),
				0.9, 0.9
			)
		2: # Thunder Strike
			return SpellData.new(
				"Thunder Strike",
				["res://assets/Magical Effects/Lightning_Blast_Anti-Alias_glow_54x18.png"],
				Color(0.8, 0.9, 1.0, 0.7),
				Color(0.9, 0.95, 1.0, 0.95),
				1.2, 1.25
			)
		3: # Blood Lightning
			return SpellData.new(
				"Blood Lightning",
				["res://assets/Magical Effects/Red_Lightning_Blast_54x18.png"],
				Color(1.0, 0.3, 0.3, 0.6),
				Color(1.0, 0.2, 0.2, 0.9),
				1.1, 1.15
			)
		4: # Crimson Spark
			return SpellData.new(
				"Crimson Spark",
				["res://assets/Magical Effects/Red_Energy_48x48.png"],
				Color(1.0, 0.4, 0.4, 0.6),
				Color(1.0, 0.3, 0.3, 0.8),
				1.4, 0.95
			)
		5: # Storm Orb
			return SpellData.new(
				"Storm Orb",
				["res://assets/Magical Effects/Lightning_Energy_Anti-Alias_glow_48x48.png"],
				Color(0.7, 0.85, 1.0, 0.7),
				Color(0.8, 0.9, 1.0, 0.9),
				1.0, 1.0
			)
	return null

func _get_ice_spell() -> SpellData:
	match attack_variant % 6:
		0: # Frost Shard
			return SpellData.new(
				"Frost Shard",
				["res://assets/Magical Effects/Ice-Burst_crystal_48x48.png"],
				Color(0.7, 0.9, 1.0, 0.6),
				Color(0.8, 0.95, 1.0, 0.8),
				1.0, 1.0
			)
		1: # Glacial Spike
			return SpellData.new(
				"Glacial Spike",
				["res://assets/Magical Effects/Ice-Burst_crystal_48x48_Anti-Alias_glow.png"],
				Color(0.8, 0.95, 1.0, 0.7),
				Color(0.9, 0.98, 1.0, 0.9),
				1.1, 1.15
			)
		2: # Deep Freeze
			return SpellData.new(
				"Deep Freeze",
				["res://assets/Magical Effects/Ice-Burst_dark-blue_outline_48x48.png"],
				Color(0.3, 0.6, 0.9, 0.6),
				Color(0.4, 0.7, 1.0, 0.8),
				0.9, 0.95
			)
		3: # Hoarfrost
			return SpellData.new(
				"Hoarfrost",
				["res://assets/Magical Effects/Ice-Burst_light-grey_outline_48x48.png"],
				Color(0.9, 0.95, 1.0, 0.6),
				Color(0.95, 0.98, 1.0, 0.8),
				1.2, 0.85
			)
		4: # Cryo Blast
			return SpellData.new(
				"Cryo Blast",
				["res://assets/Magical Effects/Ice-Burst_transparent-blue_outline_48x48.png"],
				Color(0.5, 0.8, 1.0, 0.6),
				Color(0.6, 0.9, 1.0, 0.8),
				0.85, 1.1
			)
		5: # Pure Ice
			return SpellData.new(
				"Pure Ice",
				["res://assets/Magical Effects/Ice-Burst_no_outline_48x48.png"],
				Color(0.8, 0.9, 1.0, 0.6),
				Color(0.9, 0.95, 1.0, 0.8),
				1.15, 1.05
			)
	return null

func _get_holy_spell() -> SpellData:
	match attack_variant % 3:
		0: # Smite
			return SpellData.new(
				"Smite",
				["res://assets/Characters(100x100)/Priest/Magic(projectile)/Priest-Attack_Effect.png"],
				Color(1.0, 1.0, 0.8, 0.7),
				Color(1.0, 1.0, 0.6, 0.9),
				1.0, 1.0
			)
		1: # Holy Light
			return SpellData.new(
				"Holy Light",
				["res://assets/Characters(100x100)/Priest/Magic(projectile)/Priest-Heal_Effect.png"],
				Color(1.0, 1.0, 0.9, 0.7),
				Color(1.0, 1.0, 0.8, 0.9),
				0.9, 0.9
			)
		2: # Blessed Bolt
			return SpellData.new(
				"Blessed Bolt",
				["res://assets/Characters(100x100)/Wizard/Magic(projectile)/Wizard-Attack02_Effect.png"],
				Color(1.0, 0.95, 0.7, 0.7),
				Color(1.0, 0.9, 0.6, 0.9),
				1.1, 1.05
			)
	return null

func _get_arcane_spell() -> SpellData:
	match attack_variant % 6:
		0: # Mana Dart
			return SpellData.new(
				"Mana Dart",
				["res://assets/Magical Effects/Elemental_Spellcasting_Effects_v1_Anti_Alias_glow_8x8.png"],
				Color(0.8, 0.3, 0.9, 0.6),
				Color(0.9, 0.4, 1.0, 0.8),
				1.2, 0.9
			)
		1: # Mystic Bolt
			return SpellData.new(
				"Mystic Bolt",
				["res://assets/Magical Effects/Elemental_Spellcasting_Effects_v2_8x8.png"],
				Color(0.7, 0.4, 0.9, 0.6),
				Color(0.8, 0.5, 1.0, 0.8),
				1.0, 1.0
			)
		2: # Eldritch Blast
			return SpellData.new(
				"Eldritch Blast",
				["res://assets/Magical Effects/Extra_Elemental_Spellcasting_Effects_14x14.png"],
				Color(0.6, 0.2, 0.8, 0.7),
				Color(0.7, 0.3, 0.9, 0.9),
				0.9, 1.2
			)
		3: # Void Sphere
			return SpellData.new(
				"Void Sphere",
				["res://assets/Magical Effects/Extra_Elemental_Spellcasting_Effects_Anti-Alias_glow_14x14.png"],
				Color(0.4, 0.1, 0.6, 0.7),
				Color(0.5, 0.2, 0.8, 0.9),
				0.85, 1.3
			)
		4: # Blood Magic
			return SpellData.new(
				"Blood Magic",
				["res://assets/Magical Effects/Red_Energy_48x48.png"],
				Color(0.9, 0.2, 0.3, 0.7),
				Color(1.0, 0.1, 0.2, 0.9),
				1.0, 1.15
			)
		5: # Staff Blast
			return SpellData.new(
				"Staff Blast",
				["res://assets/Generic Weapon Attack Effects/Staff_Attack_Effect_1.png"],
				Color(0.7, 0.5, 0.9, 0.6),
				Color(0.8, 0.6, 1.0, 0.8),
				1.1, 1.0
			)
	return null

func _create_visuals() -> void:
	# Create animated sprite for the projectile
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(2.5, 2.5)
	
	# Build sprite frames
	var frames := SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_loop("default", true)
	
	if current_spell:
		for path in current_spell.texture_paths:
			var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
			if texture:
				frames.add_frame("default", texture)
	
	if frames.get_frame_count("default") > 0:
		var anim_sprite := sprite as AnimatedSprite2D
		anim_sprite.sprite_frames = frames
		anim_sprite.play("default")
		var fps: float = max(8.0, frames.get_frame_count("default") * 3.0) as float
		frames.set_animation_speed("default", fps)
	else:
		_create_fallback_sprite()
		return
	
	sprite.rotation = direction.angle()
	add_child(sprite)
	
	# Add trailing particles
	_create_trail_particles()

func _create_fallback_sprite() -> void:
	var color: Color = Color(1, 0.5, 0.1)
	if current_spell:
		color = current_spell.trail_color
	
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var center := Vector2i(8, 8)
	for x in range(16):
		for y in range(16):
			var dist := Vector2i(x, y).distance_to(center)
			if dist < 6:
				var alpha: float = 1.0 - (dist / 6.0)
				img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	var tex := ImageTexture.create_from_image(img)
	
	var fallback := Sprite2D.new()
	fallback.texture = tex
	fallback.scale = Vector2(2.0, 2.0)
	add_child(fallback)
	
	if sprite:
		sprite.queue_free()
	sprite = fallback as Node2D

func _create_trail_particles() -> void:
	particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 15
	particles.lifetime = 0.35
	particles.explosiveness = 0.0
	particles.direction = Vector2(-1, 0)
	particles.spread = 20.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 70.0
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 5.0
	
	if current_spell:
		particles.color = current_spell.trail_color
	else:
		particles.color = Color(1, 0.5, 0.1, 0.6)
	
	add_child(particles)

func _physics_process(delta: float) -> void:
	if has_hit:
		return
	
	lifetime += delta
	
	if lifetime > max_lifetime:
		queue_free()
		return
	
	position += direction * speed * delta
	
	if sprite:
		sprite.rotation = direction.angle()
	
	_check_collisions()

func _check_collisions() -> void:
	for unit in get_tree().get_nodes_in_group("arena_units"):
		if not is_instance_valid(unit):
			continue
		
		if unit.team == source_team or unit.is_dead:
			continue
		
		var dist := position.distance_to(unit.position)
		if dist < HIT_RADIUS:
			_hit_unit(unit)
			return

func _hit_unit(unit) -> void:
	has_hit = true
	unit.take_hit(direction)
	_spawn_hit_effect()
	queue_free()

func _spawn_hit_effect() -> void:
	var effect := Node2D.new()
	effect.position = position
	
	var hit_sprite := AnimatedSprite2D.new()
	hit_sprite.scale = Vector2(3.0, 3.0)
	
	var frames := SpriteFrames.new()
	frames.add_animation("default")
	
	# Use current spell's textures or find alternatives
	var hit_paths: Array[String] = []
	if current_spell:
		hit_paths = current_spell.texture_paths.duplicate()
		hit_paths.reverse()  # Reverse for hit effect variation
	
	for path in hit_paths:
		var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
		if texture:
			frames.add_frame("default", texture)
	
	if frames.get_frame_count("default") > 0:
		hit_sprite.sprite_frames = frames
		hit_sprite.play("default")
		effect.add_child(hit_sprite)
	else:
		var rect := ColorRect.new()
		rect.size = Vector2(24, 24)
		rect.position = Vector2(-12, -12)
		if current_spell:
			rect.color = current_spell.hit_color
		else:
			rect.color = Color(1, 0.5, 0.1, 0.8)
		effect.add_child(rect)
	
	get_parent().add_child(effect)
	
	var tween := create_tween()
	tween.tween_property(effect, "scale", Vector2(1.5, 1.5), 0.15)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.25)
	tween.tween_callback(effect.queue_free)

func setup(
	spawn_pos: Vector2,
	dir: Vector2,
	dmg: int,
	team: int,
	proj_speed: float = DEFAULT_SPEED,
	spell: String = "fireball",
	variant: int = 0
) -> void:
	position = spawn_pos
	direction = dir.normalized()
	damage = dmg
	source_team = team
	speed = proj_speed
	spell_type = spell
	attack_variant = variant
