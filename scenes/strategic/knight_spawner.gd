extends Node2D

# Knight spawner for animation testing
# Spawns a new fighter every 3 seconds at random positions

@export var spawn_interval: float = 3.0
@export var map_bounds: Rect2 = Rect2(650, 350, 1100, 700)  # x, y, width, height - lower on screen

var fighter_scenes = []
var team_colors = [0, 1, 2, 3]
var fighter_names = ["Knight", "Grym", "Hark", "Janik", "Nyro", "Serek"]

var timer: float = 0.0
var spawn_count: int = 0

func _ready():
	# Load all fighter scenes
	fighter_scenes = [
		preload("res://scenes/characters/Knight_Fighter.tscn"),
		preload("res://scenes/characters/Grym_Fighter.tscn"),
		preload("res://scenes/characters/Hark_Fighter.tscn"),
		preload("res://scenes/characters/Janik_Fighter.tscn"),
		preload("res://scenes/characters/Nyro_Fighter.tscn"),
		preload("res://scenes/characters/Serek_Fighter.tscn"),
	]
	
	print("Knight Spawner ready - spawning every ", spawn_interval, " seconds")

func _process(delta):
	timer += delta
	
	if timer >= spawn_interval:
		timer = 0.0
		spawn_fighter()

func spawn_fighter():
	# Pick random fighter type
	var scene_idx = randi() % fighter_scenes.size()
	var fighter_scene = fighter_scenes[scene_idx]
	
	# Create fighter
	var fighter = fighter_scene.instantiate()
	
	# Random position within map bounds
	var x = map_bounds.position.x + randf() * map_bounds.size.x
	var y = map_bounds.position.y + randf() * map_bounds.size.y
	fighter.position = Vector2(x, y)
	
	# Random team
	fighter.team = team_colors[randi() % team_colors.size()]
	
	# Set scale
	fighter.scale = Vector2(2.5, 2.5)
	
	# Add to scene
	add_child(fighter)
	
	spawn_count += 1
	var type_name = fighter_names[scene_idx]
	print("Spawned #", spawn_count, ": ", type_name, " at (", int(x), ",", int(y), ") - Team ", fighter.team)
