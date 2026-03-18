class_name SpellSystem
extends Node2D

## Dragon Force Spell System
## Handles AOE spell effects like Fireball, Ice Storm, Heal

signal spell_effect_completed(spell_name: String)

enum SpellType { FIREBALL, ICE_STORM, LIGHTNING, HEAL }

const SPELL_EFFECTS = {
	"fireball": {
		"damage": 30,
		"radius": 60.0,
		"duration": 0.5,
		"color": Color(1.0, 0.3, 0.0),
		"particle_count": 20
	},
	"ice_storm": {
		"damage": 20,
		"radius": 80.0,
		"duration": 1.0,
		"color": Color(0.3, 0.7, 1.0),
		"particle_count": 30
	},
	"lightning": {
		"damage": 40,
		"radius": 40.0,
		"duration": 0.3,
		"color": Color(1.0, 1.0, 0.3),
		"particle_count": 15
	},
	"heal": {
		"heal": 25,
		"radius": 50.0,
		"duration": 0.8,
		"color": Color(0.3, 1.0, 0.3),
		"particle_count": 15
	}
}

var effects_container: Node2D = null

func _ready():
	print("SpellSystem ready")
	# Create effects container if not found
	effects_container = get_node_or_null("EffectsContainer")
	if not effects_container:
		effects_container = Node2D.new()
		effects_container.name = "EffectsContainer"
		add_child(effects_container)

func cast_spell(spell_name: String, target_pos: Vector2, caster_team: int) -> bool:
	"""Cast a spell at the target position."""
	var spell_data = SPELL_EFFECTS.get(spell_name.to_lower())
	if not spell_data:
		push_warning("Unknown spell: ", spell_name)
		return false
	
	print("Casting ", spell_name, " at ", target_pos)
	
	# Create visual effect
	_create_spell_visual(spell_name, target_pos, spell_data)
	
	# Apply effect
	_apply_spell_effect(spell_name, target_pos, spell_data, caster_team)
	
	# Schedule completion
	var duration = spell_data.get("duration", 0.5)
	get_tree().create_timer(duration).timeout.connect(
		func(): spell_effect_completed.emit(spell_name)
	)
	
	return true

func _create_spell_visual(spell_name: String, pos: Vector2, spell_data: Dictionary):
	"""Create visual effect for spell."""
	var color = spell_data.get("color", Color.WHITE)
	var radius = spell_data.get("radius", 50.0)
	var duration = spell_data.get("duration", 0.5)
	
	# Create expanding circle effect
	var effect = Node2D.new()
	effect.position = pos
	effects_container.add_child(effect)
	
	# Main explosion circle
	var circle = ColorRect.new()
	circle.color = Color(color.r, color.g, color.b, 0.5)
	circle.size = Vector2(radius * 2, radius * 2)
	circle.position = Vector2(-radius, -radius)
	
	# Make it circular using corner radius
	circle.set_meta("radius", radius)
	circle.set_meta("color", color)
	
	effect.add_child(circle)
	
	# Animate the effect
	var tween = create_tween()
	
	# Expand
	tween.tween_property(circle, "size", Vector2(radius * 2.5, radius * 2.5), duration * 0.3)
	tween.parallel().tween_property(circle, "position", Vector2(-radius * 1.25, -radius * 1.25), duration * 0.3)
	
	# Fade out
	tween.tween_property(circle, "modulate:a", 0.0, duration * 0.7)
	
	# Cleanup
	tween.tween_callback(effect.queue_free)
	
	# Add particle bursts
	_create_particle_burst(pos, color, spell_data.get("particle_count", 10))

func _create_particle_burst(pos: Vector2, color: Color, count: int):
	"""Create particle burst effect."""
	for i in range(count):
		var particle = ColorRect.new()
		particle.color = color
		particle.size = Vector2(3, 3)
		particle.position = pos
		effects_container.add_child(particle)
		
		# Random direction
		var angle = randf() * PI * 2
		var speed = randf_range(50, 150)
		var direction = Vector2(cos(angle), sin(angle))
		
		# Animate particle
		var tween = create_tween()
		var end_pos = pos + direction * randf_range(30, 80)
		
		tween.tween_property(particle, "position", end_pos, randf_range(0.3, 0.6))
		tween.parallel().tween_property(particle, "modulate:a", 0.0, randf_range(0.3, 0.6))
		tween.tween_callback(particle.queue_free)

func _apply_spell_effect(spell_name: String, pos: Vector2, spell_data: Dictionary, caster_team: int):
	"""Apply the spell's gameplay effect to targets in radius."""
	var radius = spell_data.get("radius", 50.0)
	var damage = spell_data.get("damage", 0)
	var heal = spell_data.get("heal", 0)
	
	# Find all generals in radius
	for general in get_tree().get_nodes_in_group("generals"):
		if not general.is_alive():
			continue
		
		var dist = pos.distance_to(general.global_position)
		if dist <= radius:
			# Apply damage or heal
			if spell_name == "heal":
				# Only heal allies
				if general.team == caster_team:
					general.current_hp = min(general.max_hp, general.current_hp + heal)
					print("Healed ", general.general_name, " for ", heal, " HP")
			else:
				# Damage enemies
				if general.team != caster_team:
					# Falloff based on distance from center
					var falloff = 1.0 - (dist / radius) * 0.5
					var actual_damage = int(damage * falloff)
					
					# Damage troops primarily, then HP
					var troop_damage = int(actual_damage * 0.7)
					var hp_damage = int(actual_damage * 0.3)
					
					general._lose_troops(troop_damage / 2)  # Divide by 2 since troops are in pairs
					general.take_damage(hp_damage)
					
					print(spell_name, " hit ", general.general_name, " for ", actual_damage, " damage")

func get_spell_radius(spell_name: String) -> float:
	var spell_data = SPELL_EFFECTS.get(spell_name.to_lower())
	if spell_data:
		return spell_data.get("radius", 50.0)
	return 50.0

func get_spell_cost(spell_name: String) -> int:
	var spell_data = SPELL_EFFECTS.get(spell_name.to_lower())
	if spell_data:
		return spell_data.get("mp_cost", 20)
	return 20
