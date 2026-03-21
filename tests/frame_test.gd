extends Node2D

var textures = []
var current_frame = 0
var frame_labels = []

func _ready():
	# Load the combat texture
	var c_tex = load("res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Combat.png")
	
	# Create sprites for all 8 frames in row 0 (attack_light_s)
	for col in range(8):
		var sprite = Sprite2D.new()
		sprite.position = Vector2(200 + col * 80, 300)
		sprite.scale = Vector2(4, 4)
		
		var atlas = AtlasTexture.new()
		atlas.atlas = c_tex
		atlas.region = Rect2(col * 16, 0, 16, 16)  # Row 0, each column
		sprite.texture = atlas
		
		add_child(sprite)
		textures.append(sprite)
		
		# Add label
		var label = Label.new()
		label.text = "Col %d" % col
		label.position = Vector2(200 + col * 80 - 20, 380)
		add_child(label)
		frame_labels.append(label)
	
	# Add row labels for all rows
	for row in range(8):
		var row_label = Label.new()
		row_label.text = "Row %d" % row
		row_label.position = Vector2(50, 300 + row * 100)
		add_child(row_label)
	
	print("Frame test ready - showing all 8 columns from row 0")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space
		# Switch to next row
		current_frame = (current_frame + 1) % 8
		_update_display()

func _update_display():
	var c_tex = load("res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Combat.png")
	
	for col in range(8):
		var atlas = AtlasTexture.new()
		atlas.atlas = c_tex
		atlas.region = Rect2(col * 16, current_frame * 16, 16, 16)
		textures[col].texture = atlas
	
	print("Now showing row %d" % current_frame)
