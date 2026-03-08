class_name BattleUnit extends Node2D

# Preload dependencies
const CombatCalculator = preload("res://scripts/tactical/combat_calculator.gd")

# Unit properties
@export var unit_type: String = "Knights"
@export var count: int = 30
@export var max_count: int = 30
@export var is_player_unit: bool = true
@export var formation: String = "normal"
@export var has_barrier: bool = false

# References
var lord = null  # CharacterData or LordData - using generic type for flexibility
var combat_calculator: CombatCalculator = null

# Visual nodes (to be set up in scene)
var sprite: Sprite2D
var count_label: Label
var barrier_sprite: Sprite2D
var animation_player: AnimationPlayer

# Signals
signal unit_selected(unit: BattleUnit)
signal unit_defeated(unit: BattleUnit)
signal damage_taken(amount: int, remaining: int)

func _ready():
	combat_calculator = CombatCalculator.new()
	_setup_visuals()
	_update_count_display()

func _setup_visuals():
	# Create main sprite
	sprite = Sprite2D.new()
	_add_placeholder_sprite()
	add_child(sprite)
	
	# Create count label
	count_label = Label.new()
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.position = Vector2(-20, -40)
	count_label.size = Vector2(40, 20)
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(count_label)
	
	# Create barrier sprite (hidden by default)
	barrier_sprite = Sprite2D.new()
	barrier_sprite.visible = false
	barrier_sprite.modulate = Color(1.0, 0.6, 0.0, 0.7)  # Orange
	_add_barrier_visual()
	add_child(barrier_sprite)
	
	# Create animation player
	animation_player = AnimationPlayer.new()
	_setup_animations()
	add_child(animation_player)

func _add_placeholder_sprite():
	# Create a simple colored rectangle as placeholder
	# In production, this would be replaced with actual unit sprites
	var viewport = SubViewport.new()
	viewport.size = Vector2(32, 48)
	
	var rect = ColorRect.new()
	rect.size = Vector2(32, 48)
	
	# Different colors for different unit types
	match unit_type:
		"Knights":
			rect.color = Color(0.8, 0.8, 0.9)  # Silver
		"Horsemen":
			rect.color = Color(0.6, 0.4, 0.2)  # Brown
		"Archers":
			rect.color = Color(0.2, 0.6, 0.2)  # Green
		"Mages":
			rect.color = Color(0.4, 0.2, 0.8)  # Purple
		"5th_Unit":
			rect.color = Color(0.8, 0.2, 0.2)  # Red
		_:
			rect.color = Color(0.5, 0.5, 0.5)
	
	viewport.add_child(rect)
	
	var texture = viewport.get_texture()
	sprite.texture = texture
	
	# Flip sprite if enemy unit (facing left)
	if not is_player_unit:
		sprite.flip_h = true

func _add_barrier_visual():
	# Create a circular shield visual
	var viewport = SubViewport.new()
	viewport.size = Vector2(50, 50)
	viewport.transparent_bg = true
	
	var circle = ColorRect.new()
	circle.size = Vector2(50, 50)
	circle.color = Color(1.0, 0.6, 0.0, 0.5)
	
	# Make it circular using a shader or just use transparency
	viewport.add_child(circle)
	
	var texture = viewport.get_texture()
	barrier_sprite.texture = texture
	barrier_sprite.scale = Vector2(1.5, 1.5)

func _setup_animations():
	# Add animation library
	var anim_lib = AnimationLibrary.new()
	animation_player.add_animation_library("", anim_lib)
	
	# Create attack animation
	var attack_anim = Animation.new()
	var track_idx = attack_anim.add_track(Animation.TYPE_VALUE)
	attack_anim.track_set_path(track_idx, "Sprite2D:position")
	attack_anim.track_insert_key(track_idx, 0.0, Vector2.ZERO)
	attack_anim.track_insert_key(track_idx, 0.15, Vector2(20 if is_player_unit else -20, 0))
	attack_anim.track_insert_key(track_idx, 0.3, Vector2.ZERO)
	attack_anim.length = 0.3
	anim_lib.add_animation("attack", attack_anim)
	
	# Create hit animation
	var hit_anim = Animation.new()
	track_idx = hit_anim.add_track(Animation.TYPE_VALUE)
	hit_anim.track_set_path(track_idx, "Sprite2D:modulate")
	hit_anim.track_insert_key(track_idx, 0.0, Color.WHITE)
	hit_anim.track_insert_key(track_idx, 0.1, Color.RED)
	hit_anim.track_insert_key(track_idx, 0.2, Color.WHITE)
	hit_anim.length = 0.2
	anim_lib.add_animation("hit", hit_anim)
	
	# Create death animation
	var die_anim = Animation.new()
	track_idx = die_anim.add_track(Animation.TYPE_VALUE)
	die_anim.track_set_path(track_idx, ":scale")
	die_anim.track_insert_key(track_idx, 0.0, Vector2.ONE)
	die_anim.track_insert_key(track_idx, 0.5, Vector2(0.1, 0.1))
	
	track_idx = die_anim.add_track(Animation.TYPE_VALUE)
	die_anim.track_set_path(track_idx, ":modulate")
	die_anim.track_insert_key(track_idx, 0.0, Color.WHITE)
	die_anim.track_insert_key(track_idx, 0.5, Color(1, 1, 1, 0))
	die_anim.length = 0.5
	
	anim_lib.add_animation("die", die_anim)

func _update_count_display():
	count_label.text = str(count)

func attack(target: BattleUnit, formation: String = "normal") -> int:
	# Play attack animation
	animation_player.play("attack")
	
	# Calculate and apply damage
	var damage = combat_calculator.calculate_damage(self, target, formation)
	
	# Wait for attack animation
	await animation_player.animation_finished
	
	# Apply damage to target
	await target.take_damage(damage)
	
	return damage

func attack_with_damage(target: BattleUnit, damage: int) -> void:
	# Play attack animation
	animation_player.play("attack")
	await animation_player.animation_finished
	
	# Apply pre-calculated damage
	await target.take_damage(damage)

func attack_with_magic(target: BattleUnit) -> int:
	# Calculate magic damage
	var damage = combat_calculator.calculate_magic_damage(self, target)
	
	# Target takes damage
	await target.take_damage(damage)
	
	return damage

func take_damage(amount: int) -> void:
	# Check if barrier absorbs damage
	if has_barrier:
		has_barrier = false
		barrier_sprite.visible = false
		# Show barrier break effect
		_show_barrier_break()
		return
	
	# Play hit animation
	animation_player.play("hit")
	
	# Reduce count
	count -= amount
	count = max(0, count)
	
	# Show damage number
	_show_damage_number(amount)
	
	# Update display
	_update_count_display()
	
	# Emit signal
	damage_taken.emit(amount, count)
	
	# Check for defeat
	if count <= 0:
		await animation_player.animation_finished
		_die()

func _show_damage_number(amount: int):
	var damage_label = Label.new()
	damage_label.text = "-" + str(amount)
	damage_label.add_theme_font_size_override("font_size", 16)
	damage_label.add_theme_color_override("font_color", Color.RED)
	damage_label.position = Vector2(0, -60)
	add_child(damage_label)
	
	# Animate floating up
	var tween = create_tween()
	tween.tween_property(damage_label, "position", Vector2(0, -80), 1.0)
	tween.parallel().tween_property(damage_label, "modulate", Color(1, 0, 0, 0), 1.0)
	tween.finished.connect(func(): damage_label.queue_free())

func _show_barrier_break():
	var label = Label.new()
	label.text = "Barrier Broken!"
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.ORANGE)
	label.position = Vector2(-30, -70)
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position", Vector2(-30, -90), 1.0)
	tween.parallel().tween_property(label, "modulate", Color(1, 0.6, 0, 0), 1.0)
	tween.finished.connect(func(): label.queue_free())

func _die():
	animation_player.play("die")
	await animation_player.animation_finished
	unit_defeated.emit(self)
	hide()

func activate_barrier():
	has_barrier = true
	barrier_sprite.visible = true

func is_alive() -> bool:
	return count > 0

func get_percentage_remaining() -> float:
	if max_count <= 0:
		return 0.0
	return float(count) / float(max_count)

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Check if clicked on this unit
			var mouse_pos = get_global_mouse_position()
			var rect = Rect2(global_position - Vector2(16, 24), Vector2(32, 48))
			if rect.has_point(mouse_pos):
				unit_selected.emit(self)
