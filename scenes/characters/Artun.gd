extends AnimatedSprite2D

@export var walk_speed: float = 100.0
@export var current_direction: String = "down"
@export var auto_walk: bool = true
@export var walk_area: Vector2 = Vector2(600, 400)

var directions: Dictionary = {
	"up": Vector2(0, -1),
	"down": Vector2(0, 1),
	"left": Vector2(-1, 0),
	"right": Vector2(1, 0)
}

var direction_list: Array = ["up", "down", "left", "right"]
var walk_timer: float = 0.0
var walk_duration: float = 2.0
var start_position: Vector2

func _ready():
	start_position = position
	print("Artun ready at position: ", position)
	print("Available animations: ", sprite_frames.get_animation_names())
	play_walk_animation()

func _process(delta):
	if auto_walk:
		_auto_walk(delta)
	else:
		_player_control(delta)

func _auto_walk(delta):
	walk_timer += delta
	
	if walk_timer >= walk_duration:
		walk_timer = 0.0
		current_direction = direction_list[randi() % direction_list.size()]
		walk_duration = randf_range(1.5, 3.0)
	
	var move_dir = directions[current_direction]
	var new_pos = position + move_dir * walk_speed * delta
	var half_area = walk_area / 2.0
	
	if new_pos.x < start_position.x - half_area.x or new_pos.x > start_position.x + half_area.x:
		if current_direction == "left":
			current_direction = "right"
		elif current_direction == "right":
			current_direction = "left"
		walk_timer = 0.0
		move_dir = directions[current_direction]
		
	if new_pos.y < start_position.y - half_area.y or new_pos.y > start_position.y + half_area.y:
		if current_direction == "up":
			current_direction = "down"
		elif current_direction == "down":
			current_direction = "up"
		walk_timer = 0.0
		move_dir = directions[current_direction]
	
	position += move_dir * walk_speed * delta
	play_walk_animation()

func _player_control(delta):
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("ui_up"):
		input_dir.y -= 1
		current_direction = "up"
	elif Input.is_action_pressed("ui_down"):
		input_dir.y += 1
		current_direction = "down"
	
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
		current_direction = "left"
	elif Input.is_action_pressed("ui_right"):
		input_dir.x += 1
		current_direction = "right"
	
	if input_dir != Vector2.ZERO:
		position += input_dir.normalized() * walk_speed * delta
		play_walk_animation()
	else:
		stop()

func play_walk_animation():
	var anim_name = "walk_" + current_direction
	if sprite_frames.has_animation(anim_name):
		if not is_playing():
			play(anim_name)
	else:
		if sprite_frames.get_animation_names().size() > 0:
			play(sprite_frames.get_animation_names()[0])
