extends Node2D

## Direction verification test - confirms which row shows which direction

var sprite: AnimatedSprite2D
var current_row: int = 0
var current_type: String = "idle"

@onready var label: Label = $Label

func _ready():
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(6, 6)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(640, 360)
	add_child(sprite)
	
	# Load the non-combat frames
	var frames = load("res://assets/animations/heavy_knight_non_combat.tres")
	if frames:
		sprite.sprite_frames = frames
	else:
		push_error("Failed to load heavy_knight_non_combat.tres")
		return
	
	_update_display()

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				current_type = "idle"
				_update_display()
			KEY_2:
				current_type = "walk"
				_update_display()
			KEY_3:
				current_type = "run"
				_update_display()
			KEY_4:
				current_type = "jump"
				_update_display()
			KEY_5:
				current_type = "fall"
				_update_display()
			KEY_6:
				current_type = "roll"
				_update_display()
			KEY_7:
				current_type = "death"
				_update_display()
			
			# Navigate rows within type
			KEY_UP:
				current_row = (current_row - 1) % 4
				_update_display()
			KEY_DOWN:
				current_row = (current_row + 1) % 4
				_update_display()
			
			KEY_SPACE:
				sprite.play()
			KEY_P:
				sprite.pause()
			
			KEY_R:
				# Regenerate with fixed script
				print("Run gen_heavy_knight_non_combat_frames_fixed.gd to regenerate")

func _update_display():
	var directions := ["right", "left", "down", "up"]
	var dir_name := directions[current_row]
	var anim_name := current_type + "_" + dir_name
	
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
		sprite.pause()
		sprite.frame = 0
		
		label.text = """DIRECTION TEST

Type: %s
Direction: %s (row +%d)
Animation: %s

CONTROLS:
[1-7] Switch type (idle/walk/run/jump/fall/roll/death)
[Up/Down] Change direction
[Space] Play  [P] Pause

Check: Does the sprite face the correct direction?
- right: should face right (side view)
- left: should face left (side view)
- down: should face camera (front view)
- up: should face away (back view)

If wrong, the row mapping needs correction.""" % [
			current_type.to_upper(),
			dir_name.to_upper(),
			current_row,
			anim_name
		]
	else:
		label.text = "Animation not found: " + anim_name
