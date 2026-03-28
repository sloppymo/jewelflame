extends Node2D

# Battle Arena - 20v20 aggressive combat showcase
# Each unit has aggressive AI and will actively attack enemies

const UNIT_SCALE = 2.0

var units: Array[ArenaUnit] = []
var blood_effects: Array[Node2D] = []
var attack_effects: Array[Node2D] = []
var bounds: Rect2

# Blood particles
var blood_texture: Texture2D
var attack_spritesheet: Texture2D

enum UnitType { 
	SWORDSHIELD, ARCHER, KNIGHT, HEAVY_KNIGHT, PALADIN, MAGE, ROGUE, ROGUE_HOODED, 
	MAGE_HOODED_BROWN, MAGE_MASC_DKGREY,
	# Creature Extended Pack
	GOBLIN, GOBLIN_SLINGER, MUMMY, ORC, ORC_ARCHER, ORC_CHAMPION, ORC_SOLDIER,
	SKELLY, SKELLY_ARCHER, SKELLY_WARRIOR, WRAITH, ZOMBIE, ZOMBIE_BURSTER, SLIME, FIRE_SKULL,
	# Boss
	DRAGON_GREEN,
	# Custom
	HAMMER_WARRIOR
}

var unit_configs := {
	UnitType.SWORDSHIELD: {
		"name": "SwordShield",
		"nc_path": "res://assets/animations/swordshield_non_combat.tres",
		"co_path": "res://assets/animations/swordshield_combat.tres",
		"hp": 120, "damage": 15, "speed": 60, "attack_cooldown": 0.8,
		"scale": 2.0, "attack_range": 35, "is_mage": false
	},
	UnitType.ARCHER: {
		"name": "Archer",
		"nc_path": "res://assets/animations/archer_non_combat.tres",
		"co_path": "res://assets/animations/archer_combat.tres",
		"hp": 80, "damage": 12, "speed": 70, "attack_cooldown": 1.0,
		"scale": 2.0, "attack_range": 120, "is_mage": false
	},
	UnitType.KNIGHT: {
		"name": "Knight",
		"nc_path": "res://assets/animations/knight_non_combat.tres",
		"co_path": "res://assets/animations/knight_combat.tres",
		"hp": 150, "damage": 18, "speed": 55, "attack_cooldown": 0.9,
		"scale": 2.0, "attack_range": 40, "is_mage": false
	},
	UnitType.HEAVY_KNIGHT: {
		"name": "HeavyKnight",
		"nc_path": "res://assets/animations/heavy_knight_non_combat.tres",
		"co_path": "res://assets/animations/heavy_knight_combat.tres",
		"hp": 200, "damage": 22, "speed": 40, "attack_cooldown": 1.2,
		"scale": 1.8, "attack_range": 45, "is_mage": false
	},
	UnitType.PALADIN: {
		"name": "Paladin",
		"nc_path": "res://assets/animations/paladin_non_combat.tres",
		"co_path": "res://assets/animations/paladin_combat.tres",
		"hp": 180, "damage": 20, "speed": 45, "attack_cooldown": 1.0,
		"scale": 1.8, "attack_range": 40, "is_mage": false
	},
	UnitType.MAGE: {
		"name": "Mage",
		"nc_path": "res://assets/animations/mage_red_non_combat.tres",
		"co_path": "res://assets/animations/mage_red_combat.tres",
		"hp": 70, "damage": 30, "speed": 50, "attack_cooldown": 1.5,
		"scale": 2.0, "attack_range": 150, "is_mage": true,
		"spell_type": "fireball", "projectile_speed": 200
	},
	UnitType.ROGUE: {
		"name": "Rogue",
		"nc_path": "res://assets/animations/rogue_nc_daggers.tres",
		"co_path": "res://assets/animations/rogue_combat_fx.tres",
		"hp": 90, "damage": 16, "speed": 85, "attack_cooldown": 0.6,
		"scale": 2.0, "attack_range": 30, "is_mage": false
	},
	UnitType.ROGUE_HOODED: {
		"name": "RogueHooded",
		"nc_path": "res://assets/animations/rogue_hooded_nc_daggers.tres",
		"co_path": "res://assets/animations/rogue_hooded_combat_fx.tres",
		"hp": 95, "damage": 17, "speed": 80, "attack_cooldown": 0.65,
		"scale": 2.0, "attack_range": 30, "is_mage": false
	},
	UnitType.MAGE_HOODED_BROWN: {
		"name": "MageHoodedBrown",
		"nc_path": "res://assets/animations/mage_hooded_brown_non_combat.tres",
		"co_path": "res://assets/animations/mage_hooded_brown_combat.tres",
		"hp": 75, "damage": 28, "speed": 48, "attack_cooldown": 1.4,
		"scale": 2.0, "attack_range": 140, "is_mage": true,
		"spell_type": "lightning", "projectile_speed": 250
	},
	UnitType.MAGE_MASC_DKGREY: {
		"name": "MageMascDKGrey",
		"nc_path": "res://assets/animations/mage_masc_dkgrey_non_combat.tres",
		"co_path": "res://assets/animations/mage_masc_dkgrey_combat.tres",
		"hp": 80, "damage": 26, "speed": 48, "attack_cooldown": 1.3,
		"scale": 2.0, "attack_range": 145, "is_mage": true,
		"spell_type": "ice", "projectile_speed": 180
	},
	# Creature Extended Pack
	UnitType.GOBLIN: {
		"name": "Goblin",
		"nc_path": "res://assets/animations/creatures/goblin.tres",
		"co_path": "res://assets/animations/creatures/goblin.tres",
		"hp": 60, "damage": 12, "speed": 75, "attack_cooldown": 0.7,
		"scale": 2.0, "attack_range": 30, "is_mage": false
	},
	UnitType.GOBLIN_SLINGER: {
		"name": "GoblinSlinger",
		"nc_path": "res://assets/animations/creatures/goblin_slinger.tres",
		"co_path": "res://assets/animations/creatures/goblin_slinger.tres",
		"hp": 55, "damage": 10, "speed": 70, "attack_cooldown": 1.2,
		"scale": 2.0, "attack_range": 100, "is_mage": false
	},
	UnitType.MUMMY: {
		"name": "Mummy",
		"nc_path": "res://assets/animations/creatures/mummy.tres",
		"co_path": "res://assets/animations/creatures/mummy.tres",
		"hp": 110, "damage": 18, "speed": 35, "attack_cooldown": 1.1,
		"scale": 2.0, "attack_range": 35, "is_mage": false
	},
	UnitType.ORC: {
		"name": "Orc",
		"nc_path": "res://assets/animations/creatures/orc.tres",
		"co_path": "res://assets/animations/creatures/orc.tres",
		"hp": 100, "damage": 18, "speed": 55, "attack_cooldown": 1.0,
		"scale": 2.0, "attack_range": 35, "is_mage": false
	},
	UnitType.ORC_ARCHER: {
		"name": "OrcArcher",
		"nc_path": "res://assets/animations/creatures/orc_archer.tres",
		"co_path": "res://assets/animations/creatures/orc_archer.tres",
		"hp": 85, "damage": 14, "speed": 60, "attack_cooldown": 1.1,
		"scale": 2.0, "attack_range": 110, "is_mage": false
	},
	UnitType.ORC_CHAMPION: {
		"name": "OrcChampion",
		"nc_path": "res://assets/animations/creatures/orc_champion.tres",
		"co_path": "res://assets/animations/creatures/orc_champion.tres",
		"hp": 150, "damage": 24, "speed": 50, "attack_cooldown": 1.2,
		"scale": 2.0, "attack_range": 40, "is_mage": false
	},
	UnitType.ORC_SOLDIER: {
		"name": "OrcSoldier",
		"nc_path": "res://assets/animations/creatures/orc_soldier.tres",
		"co_path": "res://assets/animations/creatures/orc_soldier.tres",
		"hp": 110, "damage": 19, "speed": 52, "attack_cooldown": 1.0,
		"scale": 2.0, "attack_range": 35, "is_mage": false
	},
	UnitType.SKELLY: {
		"name": "Skelly",
		"nc_path": "res://assets/animations/creatures/skelly.tres",
		"co_path": "res://assets/animations/creatures/skelly.tres",
		"hp": 50, "damage": 14, "speed": 45, "attack_cooldown": 0.9,
		"scale": 2.0, "attack_range": 32, "is_mage": false
	},
	UnitType.SKELLY_ARCHER: {
		"name": "SkellyArcher",
		"nc_path": "res://assets/animations/creatures/skelly_archer.tres",
		"co_path": "res://assets/animations/creatures/skelly_archer.tres",
		"hp": 45, "damage": 12, "speed": 48, "attack_cooldown": 1.0,
		"scale": 2.0, "attack_range": 105, "is_mage": false
	},
	UnitType.SKELLY_WARRIOR: {
		"name": "SkellyWarrior",
		"nc_path": "res://assets/animations/creatures/skelly_warrior.tres",
		"co_path": "res://assets/animations/creatures/skelly_warrior.tres",
		"hp": 70, "damage": 17, "speed": 42, "attack_cooldown": 1.0,
		"scale": 2.0, "attack_range": 35, "is_mage": false
	},
	UnitType.WRAITH: {
		"name": "Wraith",
		"nc_path": "res://assets/animations/creatures/wraith.tres",
		"co_path": "res://assets/animations/creatures/wraith.tres",
		"hp": 90, "damage": 22, "speed": 65, "attack_cooldown": 1.1,
		"scale": 2.0, "attack_range": 38, "is_mage": true,
		"spell_type": "dark", "projectile_speed": 180
	},
	UnitType.ZOMBIE: {
		"name": "Zombie",
		"nc_path": "res://assets/animations/creatures/zombie.tres",
		"co_path": "res://assets/animations/creatures/zombie.tres",
		"hp": 130, "damage": 16, "speed": 25, "attack_cooldown": 1.3,
		"scale": 2.0, "attack_range": 30, "is_mage": false
	},
	UnitType.ZOMBIE_BURSTER: {
		"name": "ZombieBurster",
		"nc_path": "res://assets/animations/creatures/zombie_burster.tres",
		"co_path": "res://assets/animations/creatures/zombie_burster.tres",
		"hp": 80, "damage": 35, "speed": 30, "attack_cooldown": 2.0,
		"scale": 2.0, "attack_range": 25, "is_mage": false, "aoe_radius": 60
	},
	UnitType.SLIME: {
		"name": "Slime",
		"nc_path": "res://assets/animations/creatures/slime.tres",
		"co_path": "res://assets/animations/creatures/slime.tres",
		"hp": 40, "damage": 8, "speed": 30, "attack_cooldown": 1.0,
		"scale": 2.0, "attack_range": 25, "is_mage": false
	},
	UnitType.FIRE_SKULL: {
		"name": "FireSkull",
		"nc_path": "res://assets/animations/creatures/fire_skull.tres",
		"co_path": "res://assets/animations/creatures/fire_skull.tres",
		"hp": 50, "damage": 28, "speed": 60, "attack_cooldown": 1.5,
		"scale": 2.0, "attack_range": 120, "is_mage": true,
		"spell_type": "fireball", "projectile_speed": 220
	},
	# Boss
	UnitType.DRAGON_GREEN: {
		"name": "DragonGreen",
		"nc_path": "res://assets/animations/dragon_green.tres",
		"co_path": "res://assets/animations/dragon_green.tres",
		"hp": 800, "damage": 80, "speed": 70, "attack_cooldown": 2.5,
		"scale": 1.5, "attack_range": 100, "is_mage": true,
		"spell_type": "fireball", "projectile_speed": 350,
		"aoe_radius": 80,  # Dragon breath hits multiple units
		"simple_facing": true  # Dragon only uses _right animations with flip
	},
	# Custom
	UnitType.HAMMER_WARRIOR: {
		"name": "HammerWarrior",
		"nc_path": "res://assets/animations/hammer_warrior.tres",
		"co_path": "res://assets/animations/hammer_warrior.tres",
		"hp": 140, "damage": 24, "speed": 50, "attack_cooldown": 1.1,
		"scale": 2.0, "attack_range": 38, "is_mage": false,
		"aoe_radius": 45  # Hammer swings hit nearby enemies
	}
}

func _ready():
	# Hide debug overlay
	var debug = get_node_or_null("/root/DebugOverlay")
	if debug:
		debug.hide()
	
	bounds = Rect2(Vector2(50, 50), Vector2(1180, 620))
	blood_texture = _get_or_create_blood_texture()
	
	# Spawn two armies
	_spawn_army(1, Vector2(150, 200), Vector2(400, 400))  # Left side
	_spawn_army(2, Vector2(900, 200), Vector2(400, 400))  # Right side
	
	# Setup camera
	$Camera2D.position = Vector2(640, 360)
	
	# Setup TinyRPG character controls
	_setup_tiny_rpg_controls()

func _get_or_create_blood_texture() -> Texture2D:
	# Try to load existing blood texture (only if file exists)
	var blood_path := "res://assets/effects/blood.png"
	if FileAccess.file_exists(blood_path):
		var tex = load(blood_path)
		if tex:
			return tex
	
	# Create a simple blood splatter texture
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Clear transparent
	
	# Draw random blood splatter
	var blood_color := Color(0.7, 0.1, 0.1, 0.9)
	for i in range(8):
		var x := randi() % 12 + 2
		var y := randi() % 12 + 2
		var size := randi() % 3 + 1
		for dx in range(-size, size + 1):
			for dy in range(-size, size + 1):
				if x + dx >= 0 and x + dx < 16 and y + dy >= 0 and y + dy < 16:
					if Vector2(dx, dy).length() <= size:
						img.set_pixel(x + dx, y + dy, blood_color)
	
	return ImageTexture.create_from_image(img)

func _spawn_army(team: int, start_pos: Vector2, spread: Vector2):
	var unit_types = unit_configs.keys()
	
	for i in range(20):
		var unit_type = unit_types[randi() % unit_types.size()]
		var offset = Vector2(randf() * spread.x, randf() * spread.y)
		var pos = start_pos + offset
		_spawn_unit(unit_type, team, pos)

func _spawn_mage_army(team: int, start_pos: Vector2, spread: Vector2):
	# Spawn only mage types
	var mage_types = [UnitType.MAGE, UnitType.MAGE_HOODED_BROWN, UnitType.MAGE_MASC_DKGREY]
	
	for i in range(20):
		var unit_type = mage_types[randi() % mage_types.size()]
		var offset = Vector2(randf() * spread.x, randf() * spread.y)
		var pos = start_pos + offset
		_spawn_unit(unit_type, team, pos)

func _spawn_undead_army(team: int, start_pos: Vector2, spread: Vector2):
	# Spawn undead creatures
	var undead_types = [UnitType.SKELLY, UnitType.SKELLY_ARCHER, UnitType.SKELLY_WARRIOR, 
					UnitType.ZOMBIE, UnitType.ZOMBIE_BURSTER, UnitType.WRAITH, UnitType.MUMMY]
	
	for i in range(20):
		var unit_type = undead_types[randi() % undead_types.size()]
		var offset = Vector2(randf() * spread.x, randf() * spread.y)
		var pos = start_pos + offset
		_spawn_unit(unit_type, team, pos)

func _spawn_orc_army(team: int, start_pos: Vector2, spread: Vector2):
	# Spawn orc types
	var orc_types = [UnitType.ORC, UnitType.ORC_ARCHER, UnitType.ORC_CHAMPION, UnitType.ORC_SOLDIER]
	
	for i in range(20):
		var unit_type = orc_types[randi() % orc_types.size()]
		var offset = Vector2(randf() * spread.x, randf() * spread.y)
		var pos = start_pos + offset
		_spawn_unit(unit_type, team, pos)

func _spawn_goblin_army(team: int, start_pos: Vector2, spread: Vector2):
	# Spawn goblin types
	var goblin_types = [UnitType.GOBLIN, UnitType.GOBLIN_SLINGER]
	
	for i in range(20):
		var unit_type = goblin_types[randi() % goblin_types.size()]
		var offset = Vector2(randf() * spread.x, randf() * spread.y)
		var pos = start_pos + offset
		_spawn_unit(unit_type, team, pos)

func _spawn_dragon_battle():
	# 1 Dragon vs 20 mixed units
	_clear_all_units()
	
	# Spawn dragon on left side
	_spawn_unit(UnitType.DRAGON_GREEN, 1, Vector2(200, 360))
	
	# Spawn army on right side
	var army_types = [UnitType.SWORDSHIELD, UnitType.ARCHER, UnitType.KNIGHT, 
					UnitType.HEAVY_KNIGHT, UnitType.PALADIN, UnitType.MAGE]
	for i in range(20):
		var unit_type = army_types[randi() % army_types.size()]
		var pos = Vector2(900 + randf() * 200, 200 + randf() * 320)
		_spawn_unit(unit_type, 2, pos)

func _spawn_unit(unit_type: UnitType, team: int, pos: Vector2):
	var config = unit_configs[unit_type]
	var unit = ArenaUnit.new(self)
	unit.position = pos
	unit.team = team
	unit.unit_type = unit_type
	unit.config = config
	unit.max_hp = config.hp
	unit.hp = config.hp
	unit.attack_damage = config.damage
	unit.move_speed = config.speed
	unit.attack_cooldown = config.attack_cooldown
	unit.attack_range = config.attack_range
	unit.scale = Vector2(config.scale, config.scale)
	
	# Load non-combat sprite (for walk/idle)
	var nc_sprite = AnimatedSprite2D.new()
	nc_sprite.sprite_frames = load(config.nc_path)
	nc_sprite.animation_finished.connect(unit._on_animation_finished)
	nc_sprite.name = "NCSprite"
	unit.add_child(nc_sprite)
	unit.nc_sprite = nc_sprite
	
	# Load combat sprite (for attack/hurt/death)
	var co_sprite = AnimatedSprite2D.new()
	co_sprite.sprite_frames = load(config.co_path)
	co_sprite.animation_finished.connect(unit._on_animation_finished)
	co_sprite.name = "COSprite"
	co_sprite.visible = false
	unit.add_child(co_sprite)
	unit.co_sprite = co_sprite
	
	# Add to scene
	add_child(unit)
	units.append(unit)
	
	# Set initial direction toward enemy
	unit._find_target()

func _spawn_blood(pos: Vector2, dir: Vector2):
	if not blood_texture:
		return
	
	var blood = Sprite2D.new()
	blood.texture = blood_texture
	blood.position = pos
	blood.rotation = dir.angle()
	blood.modulate = Color(0.8, 0, 0, 0.9)
	blood.scale = Vector2(0.5 + randf() * 0.5, 0.5 + randf() * 0.5)
	blood.z_index = -1
	add_child(blood)
	blood_effects.append(blood)
	
	# Auto-cleanup blood after delay
	_cleanup_blood_delayed(blood, 5.0)

func _cleanup_blood_delayed(blood: Node2D, delay: float):
	await get_tree().create_timer(delay).timeout
	if blood and is_instance_valid(blood):
		blood.queue_free()
		blood_effects.erase(blood)

func _spawn_attack_effect(pos: Vector2, effect_type: String = "slash"):
	# Load the appropriate effect sprite
	var effect_path = "res://assets/effects/"
	if effect_type == "staff":
		effect_path += "staff_effect.png"
	else:
		effect_path += "slash_effect.png"
	
	var texture = load(effect_path)
	if not texture:
		return
	
	var effect = AttackEffect.new()
	effect.position = pos
	effect.rotation = randf() * PI * 2
	effect.scale = Vector2(1.5, 1.5)
	effect.z_index = 10
	add_child(effect)
	attack_effects.append(effect)
	
	# Create animated sprite for the effect
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 16, 16)
	effect.add_child(sprite)
	effect.sprite = sprite

func _process(delta):
	# Clean up dead units after some time
	for i in range(units.size() - 1, -1, -1):
		var unit = units[i]
		if unit.is_dead and unit.death_timer > 3.0:
			units.remove_at(i)
			unit.queue_free()

func _input(event):
	if event is InputEventKey and event.pressed:
		# Arena battle controls
		match event.keycode:
			KEY_R:
				_restart_battle()
				return
			KEY_M:
				_restart_mage_battle()
				return
			KEY_U:
				_restart_undead_battle()
				return
			KEY_O:
				_restart_orc_battle()
				return
			KEY_G:
				_restart_goblin_battle()
				return
			KEY_C:
				_clear_all_units()
				return
			KEY_B:
				_spawn_dragon_battle()
				return
		
		# TinyRPG character controls (keys 1-0)
		var char_index = -1
		match event.keycode:
			KEY_1: char_index = 0
			KEY_2: char_index = 1
			KEY_3: char_index = 2
			KEY_4: char_index = 3
			KEY_5: char_index = 4
			KEY_6: char_index = 5
			KEY_7: char_index = 6
			KEY_8: char_index = 7
			KEY_9: char_index = 8
			KEY_0: char_index = 9
			KEY_W: _move_char(Vector2.UP); return
			KEY_S: _move_char(Vector2.DOWN); return
			KEY_A: _move_char(Vector2.LEFT); return
			KEY_D: _move_char(Vector2.RIGHT); return
			KEY_SPACE: _attack_char("attack01"); return
			KEY_Q: _attack_char("attack02"); return
			KEY_E: _attack_char("attack03"); return
			KEY_H: _damage_char(); return
			KEY_K: _kill_char(); return
			KEY_ESCAPE: get_tree().quit(); return
		
		if char_index >= 0 and char_index < _tiny_rpg_chars.size():
			_selected_char = _tiny_rpg_chars[char_index]
			print("Selected: " + _selected_char.name)

func _restart_battle():
	# Clear existing units
	_clear_all_units()
	
	# Spawn new armies
	_spawn_army(1, Vector2(150, 200), Vector2(400, 400))
	_spawn_army(2, Vector2(900, 200), Vector2(400, 400))

func _restart_mage_battle():
	_clear_all_units()
	_spawn_mage_army(1, Vector2(150, 200), Vector2(400, 400))
	_spawn_mage_army(2, Vector2(900, 200), Vector2(400, 400))

func _restart_undead_battle():
	_clear_all_units()
	_spawn_undead_army(1, Vector2(150, 200), Vector2(400, 400))
	_spawn_undead_army(2, Vector2(900, 200), Vector2(400, 400))

func _restart_orc_battle():
	_clear_all_units()
	_spawn_orc_army(1, Vector2(150, 200), Vector2(400, 400))
	_spawn_orc_army(2, Vector2(900, 200), Vector2(400, 400))

func _restart_goblin_battle():
	_clear_all_units()
	_spawn_goblin_army(1, Vector2(150, 200), Vector2(400, 400))
	_spawn_goblin_army(2, Vector2(900, 200), Vector2(400, 400))

func _clear_all_units():
	for unit in units:
		unit.queue_free()
	units.clear()

# TinyRPG Character Controls
var _selected_char: TinyRPGCharacter = null
var _tiny_rpg_chars: Array[TinyRPGCharacter] = []

func _setup_tiny_rpg_controls():
	var chars_node = get_node_or_null("TinyRPGCharacters")
	if not chars_node:
		return
	
	# First pass: collect all characters
	for child in chars_node.get_children():
		if child is TinyRPGCharacter:
			_tiny_rpg_chars.append(child)
	
	print("TinyRPG: Found " + str(_tiny_rpg_chars.size()) + " characters")
	
	# Second pass: assign teams and enable AI
	var half = _tiny_rpg_chars.size() / 2
	for i in range(_tiny_rpg_chars.size()):
		var char = _tiny_rpg_chars[i]
		# Assign teams: first half team 1, second half team 2
		if i < half:
			char.team = 1
		else:
			char.team = 2
		# Enable AI - they join arena_units group automatically
		char.ai_enabled = true
		# Set collision to match ArenaUnits
		char.collision_layer = 0
		char.collision_mask = 0
		print("TinyRPG: " + char.name + " Team " + str(char.team))
	
	if _tiny_rpg_chars.size() > 0:
		_selected_char = _tiny_rpg_chars[0]
		print("TinyRPG: All " + str(_tiny_rpg_chars.size()) + " AI characters ready")

func _move_char(dir: Vector2):
	if _selected_char and not _selected_char.is_dead:
		_selected_char.move(dir)
		await get_tree().create_timer(0.2).timeout
		if _selected_char:
			_selected_char.stop()

func _attack_char(anim: String):
	if _selected_char and not _selected_char.is_dead:
		_selected_char.attack(anim)

func _damage_char():
	if _selected_char and not _selected_char.is_dead:
		_selected_char.take_damage(25)

func _kill_char():
	if _selected_char and not _selected_char.is_dead:
		_selected_char.die()

func _respawn_char():
	if _selected_char and _selected_char.is_dead:
		_selected_char.respawn()

# Inner class for arena units
class ArenaUnit extends CharacterBody2D:
	enum State { IDLE, CHARGE, ATTACK, HURT, DEAD }
	
	var arena: Node2D
	var nc_sprite: AnimatedSprite2D  # Non-combat sprite (walk/idle)
	var co_sprite: AnimatedSprite2D  # Combat sprite (attack/hurt/death)
	var active_sprite: AnimatedSprite2D  # Currently visible sprite
	var team: int = 0
	var unit_type: int = 0
	var config: Dictionary
	
	# Combat stats
	var max_hp: int = 100
	var hp: int = 100
	var attack_damage: int = 10
	var move_speed: float = 60.0
	var attack_cooldown: float = 1.0
	var attack_range: float = 35.0
	var attack_timer: float = 0.0
	var death_timer: float = 0.0
	
	# State
	var state = State.IDLE
	var state_timer: float = 0.0
	var target: ArenaUnit = null
	var direction: String = "s"
	var is_dead: bool = false
	var has_hit: bool = false  # Track if attack has dealt damage this animation
	
	# Knockback
	var knockback_velocity: Vector2 = Vector2.ZERO
	
	func _init(parent_arena: Node2D):
		arena = parent_arena
		add_to_group("arena_units")
	
	func _ready():
		collision_layer = 0
		collision_mask = 0
	
	func _physics_process(delta):
		if is_dead:
			death_timer += delta
			return
		
		state_timer += delta
		
		# Apply knockback
		if knockback_velocity.length() > 1:
			position += knockback_velocity * delta
			knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 400 * delta)
			return  # Skip normal movement while being knocked back
		
		match state:
			State.IDLE:
				_update_idle(delta)
			State.CHARGE:
				_update_charge(delta)
			State.ATTACK:
				_update_attack(delta)
			State.HURT:
				_update_hurt(delta)
	
	func _update_idle(delta):
		_play_anim("idle_" + direction, true)
		_find_target()
		if target and is_instance_valid(target) and not target.is_dead:
			state = State.CHARGE
	
	func _update_charge(delta):
		if not target or not is_instance_valid(target) or target.is_dead:
			target = null
			state = State.IDLE
			return
		
		var dist = position.distance_to(target.position)
		if dist <= attack_range:
			state = State.ATTACK
			state_timer = 0.0
			has_hit = false
			attack_timer = 0.0
			return
		
		# Move toward target with some aggression
		var move_dir = (target.position - position).normalized()
		_update_direction(move_dir)
		
		# Avoid clumping - steer away from nearby allies
		for unit in arena.units:
			if not is_instance_valid(unit):
				continue
			if unit != self and unit.team == team and not unit.is_dead:
				var dist_to_ally = position.distance_to(unit.position)
				if dist_to_ally < 25:
					move_dir += (position - unit.position).normalized() * 0.5
					move_dir = move_dir.normalized()
		
		# Check bounds
		var next_pos = position + move_dir * move_speed * delta
		if arena.bounds.has_point(next_pos):
			position = next_pos
		
		_play_anim("walk_" + direction, true)
	
	func _update_attack(delta):
		# Always face target while attacking
		if target and is_instance_valid(target):
			var attack_dir = (target.position - position).normalized()
			_update_direction(attack_dir)
		
		attack_timer += delta
		
		# Check if this is a mage with projectile spells
		var is_mage = config.get("is_mage", false)
		
		# Deal damage during attack animation (at mid-point)
		if state_timer > 0.2 and state_timer < 0.5 and not has_hit:
			has_hit = true
			
			if is_mage:
				# Mages cast projectiles
				_cast_spell()
			elif target and is_instance_valid(target) and not target.is_dead:
				var dist = position.distance_to(target.position)
				if dist <= attack_range * 1.5:  # Slightly extended range for gameplay feel
					target.take_hit((target.position - position).normalized())
					# Spawn attack effect
					var effect_type = "staff" if unit_type == UnitType.MAGE else "slash"
					arena._spawn_attack_effect(target.position, effect_type)
					
					# Heavy units have AoE
					if config.name in ["HeavyKnight", "Paladin"]:
						_hit_nearby_enemies()
		
		# Play attack animation (mages use "cast" for casting, dragon uses "firebreath")
		if is_mage:
			# Dragon has special firebreath animation
			if config.name == "DragonGreen":
				_play_anim("firebreath_" + direction, true)
			else:
				_play_anim("cast_" + direction, true)
		else:
			_play_anim("attack_" + direction, true)
		
		# Return to charge state after attack
		if attack_timer >= attack_cooldown:
			state = State.CHARGE
			attack_timer = 0.0
	
	func _cast_spell():
		# Spawn a spell projectile
		var spell_type = config.get("spell_type", "fireball")
		var proj_speed = config.get("projectile_speed", 200.0)
		var target_pos = target.position if target and is_instance_valid(target) else position + Vector2.RIGHT * 100
		
		var projectile := SpellProjectile.new(arena, self, target_pos, spell_type, proj_speed, attack_damage)
		arena.add_child(projectile)
		arena.attack_effects.append(projectile)
	
	func _hit_nearby_enemies():
		# AoE damage for heavy units
		var aoe_radius = config.get("aoe_radius", 50)
		for unit in arena.units:
			if not is_instance_valid(unit):
				continue
			if unit.team != team and not unit.is_dead:
				var dist = position.distance_to(unit.position)
				if dist < aoe_radius:
					unit.take_hit((unit.position - position).normalized())
	
	func _update_hurt(delta):
		# Brief hurt animation, then back to charge
		if state_timer > 0.3:
			state = State.CHARGE
			state_timer = 0.0
			_find_target()
	
	func _update_direction(dir: Vector2):
		# Convert vector to 8-way direction string
		var angle = dir.angle()
		var deg = rad_to_deg(angle)
		
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
	
	func _find_target():
		# Find nearest enemy
		var nearest: ArenaUnit = null
		var nearest_dist = 999999.0
		
		for unit in arena.units:
			if not is_instance_valid(unit):
				continue
			if unit.team != team and not unit.is_dead:
				var dist = position.distance_to(unit.position)
				if dist < nearest_dist:
					nearest_dist = dist
					nearest = unit
		
		target = nearest
	
	func take_hit(from_dir: Vector2):
		if is_dead:
			return
		
		# Apply damage
		var damage = 10
		if target and target.config:
			damage = target.attack_damage
		hp -= damage
		
		# Knockback
		knockback_velocity = from_dir * 150
		
		# Blood effect
		arena._spawn_blood(position + Vector2(randf() * 10 - 5, randf() * 10 - 5), from_dir)
		
		if hp <= 0:
			_die(from_dir)
		elif state != State.ATTACK:  # Don't interrupt attack animation
			state = State.HURT
			state_timer = 0.0
			_update_direction(-from_dir)
			_play_anim("hurt_" + direction, false)  # Hurt should not loop
	
	func _die(from_dir: Vector2):
		is_dead = true
		state = State.DEAD
		_update_direction(-from_dir)
		_play_anim("death_" + direction, false)
		
		# Lots of blood on death
		for i in range(3):
			var offset = Vector2(randf() * 20 - 10, randf() * 20 - 10)
			arena._spawn_blood(position + offset, from_dir.rotated(randf() * 0.5 - 0.25))
	
	func _play_anim(anim_name: String, loop: bool = true):
		# Determine which sprite to use based on animation type
		# Non-combat: walk, idle | Combat: attack, hurt, death, special, cast
		var use_combat = false
		var base_name = anim_name.rsplit("_", true, 1)[0]
		
		if base_name in ["attack", "hurt", "death", "special", "cast"]:
			use_combat = true
		
		# Switch active sprite
		if use_combat:
			active_sprite = co_sprite
			nc_sprite.visible = false
			co_sprite.visible = true
		else:
			active_sprite = nc_sprite
			co_sprite.visible = false
			nc_sprite.visible = true
		
		if not active_sprite or not active_sprite.sprite_frames:
			return
		
		# Try exact match first
		var actual_anim = anim_name
		var dir = direction  # Default to current direction
		
		# Check if this unit uses simple facing (like dragon - only _right anim with flip)
		var simple_facing = config.get("simple_facing", false)
		
		if simple_facing:
			# For dragon and similar: only use _right animations, flip for left
			var simple_anim = base_name + "_right"
			if active_sprite.sprite_frames.has_animation(simple_anim):
				actual_anim = simple_anim
				dir = direction  # Use current direction for flip calc
				# Flip if facing left (w, nw, sw)
				active_sprite.flip_h = dir in ["w", "nw", "sw"]
				_play_actual_anim(actual_anim)
				return
		
		if not active_sprite.sprite_frames.has_animation(actual_anim):
			# Parse animation name
			var parts = anim_name.rsplit("_", true, 1)
			if parts.size() < 2:
				return
			
			dir = parts[1]        # "n", "ne", "e", "se", "s", "sw", "w", "nw"
			
			# Try various naming patterns
			var candidates = _build_animation_candidates(base_name, dir)
			
			for candidate in candidates:
				if active_sprite.sprite_frames.has_animation(candidate):
					actual_anim = candidate
					break
			
			if not active_sprite.sprite_frames.has_animation(actual_anim):
				return  # No suitable animation found
		
		# Apply horizontal flip based on direction and animation type
		# Check what animation name was actually found
		if base_name == "cast":
			# Cast animations use right/left directly, no flip needed
			active_sprite.flip_h = false
		elif actual_anim.ends_with("_right") and not actual_anim.ends_with("_up_right") and not actual_anim.ends_with("_down_right"):
			# Sprite has explicit right animation (but not diagonal like down_right)
			# Flip if facing left
			active_sprite.flip_h = dir in ["w", "nw", "sw"]
		elif actual_anim.ends_with("_left") and not actual_anim.ends_with("_up_left") and not actual_anim.ends_with("_down_left"):
			# Sprite has explicit left animation (but not diagonal)
			# Flip if facing right
			active_sprite.flip_h = dir in ["e", "ne", "se"]
		elif actual_anim.ends_with("_up") or actual_anim.ends_with("_down"):
			# Up/down animations should never flip horizontally
			active_sprite.flip_h = false
		elif dir in ["e", "ne", "se"]:
			# Default: flip for right-facing
			active_sprite.flip_h = true
		else:
			active_sprite.flip_h = false
		
		_play_actual_anim(actual_anim)
	
	func _build_animation_candidates(base_name: String, dir: String) -> Array[String]:
		var candidates: Array[String] = []
		
		# Map 8-way to cardinal directions
		var card_dir = dir
		if dir in ["ne", "nw"]:
			card_dir = "n"
		elif dir in ["se", "sw"]:
			card_dir = "s"
		
		# Pattern 1: Standard 8-dir (attack1_n, hurt_s, etc.)
		if base_name == "attack":
			for num in ["1", "2", "3"]:
				candidates.append("attack" + num + "_" + dir)
				candidates.append("attack" + num + "_" + card_dir)
			candidates.append("attack_" + dir)
			candidates.append("attack_" + card_dir)
			# Also try 4-dir cardinal directions (for creatures, hammer warrior, etc.)
			if dir in ["n", "ne", "nw"]:
				candidates.append("attack_n")
			elif dir in ["s", "se", "sw"]:
				candidates.append("attack_s")
			elif dir == "e":
				candidates.append("attack_e")
			elif dir == "w":
				candidates.append("attack_w")
		elif base_name == "cast":
			# Cast uses 4-dir: up, down, left, right
			var cast_dir = "down"
			if dir in ["n"]:
				cast_dir = "up"
			elif dir in ["s"]:
				cast_dir = "down"
			elif dir in ["e", "ne", "se"]:
				cast_dir = "right"
			elif dir in ["w", "nw", "sw"]:
				cast_dir = "left"
			candidates.append("cast_" + cast_dir)
			candidates.append("cast_down")
			candidates.append("cast_right")
		elif base_name == "firebreath":
			# Dragon firebreath - only has _right animation, uses flip_h for left
			candidates.append("firebreath_right")
			candidates.append("firebreath_e")
		else:
			candidates.append(base_name + "_" + dir)
			candidates.append(base_name + "_" + card_dir)
			# Try archer's walk2 naming
			if base_name == "walk":
				candidates.append("walk2_" + dir)
				candidates.append("walk2_" + card_dir)
			# Try idle2 naming if exists
			if base_name == "idle":
				candidates.append("idle2_" + dir)
				candidates.append("idle2_" + card_dir)
		
		# Pattern 2: Knight's light/heavy attacks (attack_light_e, attack_heavy_n)
		if base_name == "attack":
			for attack_type in ["light", "heavy"]:
				candidates.append("attack_" + attack_type + "_" + dir)
				candidates.append("attack_" + attack_type + "_" + card_dir)
		
		# Pattern 0: Simple 4-dir naming FIRST (walk_up, walk_down, walk_left, walk_right)
		# Used by creatures and some combat sprites - check these BEFORE 8-dir
		var four_dir_map = {
			"n": "up", "ne": "up", "nw": "up",
			"s": "down", "se": "down", "sw": "down",
			"e": "right",
			"w": "left"
		}
		var four_dir = four_dir_map.get(dir, "down")
		var four_dir_card = four_dir_map.get(card_dir, "down")
		
		# Try simple 4-dir names FIRST (creatures use these)
		candidates.append(base_name + "_" + four_dir)
		candidates.append(base_name + "_" + four_dir_card)
		
		# Also try _left/_right directly for cardinal directions
		if dir == "w" or card_dir == "w":
			candidates.append(base_name + "_left")
		if dir == "e" or card_dir == "e":
			candidates.append(base_name + "_right")
		candidates.append(base_name + "_left")
		candidates.append(base_name + "_right")
		
		# Pattern 4: Complex 4-dir with left/right variants (attack_down_left, etc.)
		if base_name == "attack":
			candidates.append("attack_" + four_dir + "_left")
			candidates.append("attack_" + four_dir + "_right")
			candidates.append("attack_" + four_dir_card + "_left")
			candidates.append("attack_" + four_dir_card + "_right")
			candidates.append("attack_horizontal_left")
			candidates.append("attack_horizontal_right")
			candidates.append("attack_stab_left")
			candidates.append("attack_stab_right")
		else:
			candidates.append(base_name + "_" + four_dir + "_left")
			candidates.append(base_name + "_" + four_dir + "_right")
			candidates.append(base_name + "_" + four_dir_card + "_left")
			candidates.append(base_name + "_" + four_dir_card + "_right")
			candidates.append(base_name + "_left")
			candidates.append(base_name + "_right")
		
		# Pattern 4: Fallback to any direction
		candidates.append(base_name + "_s")
		candidates.append(base_name + "_down")
		candidates.append(base_name + "_down_right")
		
		# Pattern 5: Directionless fallback
		candidates.append(base_name)
		
		# Pattern 5b: Hurt/Death fallbacks (for creatures without hurt/death anims like dragon)
		if base_name in ["hurt", "death"]:
			candidates.append("idle_" + four_dir)
			candidates.append("idle_" + four_dir_card)
			candidates.append("hover_right")  # Dragon idle
			candidates.append("hover_left")
			candidates.append("fly_right")
			candidates.append("fly_left")
			candidates.append("walk_right")
			candidates.append("walk_left")
			candidates.append("idle_right")
			candidates.append("idle_left")
			candidates.append("idle_n")
			candidates.append("idle_s")
		
		# Pattern 6: For walk/idle without those animations, use attack as fallback (combat sprites)
		if base_name in ["walk", "idle"]:
			# Try attack animations as fallback for movement
			for num in ["1", "2", "3"]:
				candidates.append("attack" + num + "_" + dir)
				candidates.append("attack" + num + "_" + card_dir)
			candidates.append("attack_" + dir)
			candidates.append("attack_" + card_dir)
			candidates.append("attack_" + four_dir + "_left")
			candidates.append("attack_" + four_dir + "_right")
			candidates.append("attack_" + four_dir_card + "_left")
			candidates.append("attack_" + four_dir_card + "_right")
			for attack_type in ["light", "heavy"]:
				candidates.append("attack_" + attack_type + "_" + dir)
				candidates.append("attack_" + attack_type + "_" + card_dir)
			candidates.append("attack_horizontal_left")
			candidates.append("attack_horizontal_right")
			candidates.append("attack_stab_left")
			candidates.append("attack_stab_right")
		
		return candidates
	
	func _play_actual_anim(actual_anim: String):
		if active_sprite.animation != actual_anim:
			active_sprite.play(actual_anim)
		elif not active_sprite.is_playing():
			active_sprite.play(actual_anim)
		
		# Ensure animation is playing
		if not active_sprite.is_playing():
			active_sprite.play(actual_anim)
	
	func _on_animation_finished():
		if is_dead:
			return
		
		match state:
			State.ATTACK:
				# Attack animation done, return to charge
				state = State.CHARGE
				state_timer = 0.0
				has_hit = false
				_find_target()

# Inner class for attack visual effects
class AttackEffect extends Node2D:
	var sprite: Sprite2D
	var lifetime: float = 0.0
	var max_lifetime: float = 0.3
	
	func _process(delta):
		lifetime += delta
		
		if sprite:
			# Animate through frames (assuming 4-frame animation)
			var frame = int((lifetime / max_lifetime) * 4)
			if frame < 4:
				sprite.region_rect = Rect2(frame * 16, 0, 16, 16)
			
			# Fade out
			if lifetime > max_lifetime * 0.5:
				sprite.modulate.a = 1.0 - ((lifetime - max_lifetime * 0.5) / (max_lifetime * 0.5))
		
		if lifetime >= max_lifetime:
			queue_free()

# Inner class for spell projectiles
class SpellProjectile extends Node2D:
	var arena: Node2D
	var caster: ArenaUnit
	var direction: Vector2
	var speed: float = 200.0
	var damage: int = 30
	var spell_type: String = "fireball"
	var lifetime: float = 0.0
	var max_lifetime: float = 3.0
	var has_hit: bool = false
	
	# Visual components
	var sprite: AnimatedSprite2D
	var trail_timer: float = 0.0
	
	func _init(parent_arena: Node2D, caster_unit: ArenaUnit, target_pos: Vector2, spell: String, proj_speed: float, dmg: int):
		arena = parent_arena
		caster = caster_unit
		spell_type = spell
		speed = proj_speed
		damage = dmg
		direction = (target_pos - caster_unit.position).normalized()
		position = caster_unit.position + direction * 20
		z_index = 5
	
	func _ready():
		# Create animated sprite for the projectile
		sprite = AnimatedSprite2D.new()
		sprite.scale = Vector2(2.0, 2.0)
		_add_projectile_sprite()
		add_child(sprite)
		
		# Play the appropriate animation from elemental_spellcasting_v1
		match spell_type:
			"fireball":
				_play_anim("fire")
			"lightning":
				_play_anim("lightning")
			"ice":
				_play_anim("ice")
			_:
				_play_anim("fire")
	
	func _add_projectile_sprite():
		# Load the appropriate effect sprite frames based on spell type
		# All use elemental_spellcasting_v1.tres which has fire/ice/lightning/water/etc.
		var frames_path := "res://assets/animations/effects/elemental_spellcasting_v1.tres"
		
		if FileAccess.file_exists(frames_path):
			sprite.sprite_frames = load(frames_path)
		else:
			# Fallback: create a simple colored circle
			_create_fallback_sprite()
	
	func _create_fallback_sprite():
		# Create a simple sprite if the effect file doesn't exist
		var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
		match spell_type:
			"fireball":
				img.fill(Color.ORANGE_RED)
			"lightning":
				img.fill(Color.YELLOW)
			"ice":
				img.fill(Color.CYAN)
			_:
				img.fill(Color.WHITE)
		
		var tex := ImageTexture.create_from_image(img)
		sprite.sprite_frames = SpriteFrames.new()
		sprite.sprite_frames.add_animation("default")
		sprite.sprite_frames.add_frame("default", tex)
		sprite.play("default")
	
	func _play_anim(anim_name: String):
		if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
			sprite.play(anim_name)
		else:
			# Try to play any available animation
			var anims := sprite.sprite_frames.get_animation_names()
			if anims.size() > 0:
				sprite.play(anims[0])
	
	func _process(delta):
		lifetime += delta
		
		if has_hit or lifetime > max_lifetime:
			_explode()
			return
		
		# Move the projectile
		position += direction * speed * delta
		
		# Rotate sprite to match direction
		rotation = direction.angle()
		
		# Check for collision with units
		_check_collisions()
		
		# Spawn trail effect
		trail_timer += delta
		if trail_timer > 0.05:
			trail_timer = 0.0
			_spawn_trail()
	
	func _check_collisions():
		# Check if caster is still valid
		if not is_instance_valid(caster):
			queue_free()
			return
		
		for unit in arena.units:
			# Check if unit is still valid (not freed)
			if not is_instance_valid(unit):
				continue
			if unit.team != caster.team and not unit.is_dead:
				var dist = position.distance_to(unit.position)
				if dist < 25:  # Hit radius
					_hit_unit(unit)
					return
	
	func _hit_unit(unit: ArenaUnit):
		has_hit = true
		unit.take_hit(direction)
		unit.hp -= damage
		if unit.hp <= 0:
			unit._die(direction)
		_explode()
	
	func _explode():
		# Spawn explosion effect
		var explosion := SpellExplosion.new(spell_type)
		explosion.position = position
		arena.add_child(explosion)
		queue_free()
	
	func _spawn_trail():
		# Optional: spawn small particle trail
		pass

# Inner class for spell explosions
class SpellExplosion extends Node2D:
	var spell_type: String
	var sprite: AnimatedSprite2D
	var lifetime: float = 0.0
	var max_lifetime: float = 0.5
	
	func _init(spell: String):
		spell_type = spell
		z_index = 10
	
	func _ready():
		sprite = AnimatedSprite2D.new()
		sprite.scale = Vector2(2.5, 2.5)
		_add_explosion_sprite()
		add_child(sprite)
	
	func _add_explosion_sprite():
		var frames_path := ""
		match spell_type:
			"fireball":
				frames_path = "res://assets/animations/effects/fire_explosion.tres"
			"lightning":
				frames_path = "res://assets/animations/effects/lightning_energy.tres"
			"ice":
				frames_path = "res://assets/animations/effects/ice_burst.tres"
			_:
				frames_path = "res://assets/animations/effects/fire_explosion.tres"
		
		if FileAccess.file_exists(frames_path):
			sprite.sprite_frames = load(frames_path)
			var anims := sprite.sprite_frames.get_animation_names()
			if anims.size() > 0:
				sprite.play(anims[0])
		else:
			_create_fallback_explosion()
	
	func _create_fallback_explosion():
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		match spell_type:
			"fireball":
				img.fill(Color.ORANGE_RED)
			"lightning":
				img.fill(Color.YELLOW)
			"ice":
				img.fill(Color.CYAN)
			_:
				img.fill(Color.WHITE)
		
		var tex := ImageTexture.create_from_image(img)
		sprite.sprite_frames = SpriteFrames.new()
		sprite.sprite_frames.add_animation("default")
		sprite.sprite_frames.add_frame("default", tex)
		sprite.play("default")
	
	func _process(delta):
		lifetime += delta
		
		if sprite:
			# Fade out
			if lifetime > max_lifetime * 0.5:
				sprite.modulate.a = 1.0 - ((lifetime - max_lifetime * 0.5) / (max_lifetime * 0.5))
		
		if lifetime >= max_lifetime:
			queue_free()
