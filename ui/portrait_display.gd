extends TextureRect

class_name PortraitDisplay

@export var placeholder_texture: Texture2D = null

func _ready():
	# Set texture filter to nearest for crisp pixel art
	texture_filter = TEXTURE_FILTER_NEAREST
	expand_mode = EXPAND_MODE_KEEP_SIZE
	stretch_mode = STRETCH_MODE_KEEP

func set_character(character: CharacterData):
	if character and not character.portrait_path.is_empty():
		var texture = load(character.portrait_path)
		if texture:
			self.texture = texture
			print("Loaded portrait for: ", character.name, " from: ", character.portrait_path)
		else:
			push_warning("Failed to load portrait: " + character.portrait_path)
			self.texture = placeholder_texture
	else:
		self.texture = placeholder_texture
		if character:
			push_warning("No portrait path for character: " + character.name)

func clear():
	self.texture = placeholder_texture
