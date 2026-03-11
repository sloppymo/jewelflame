class_name StrategicPanel
extends Control

# Node references
@onready var faction_name: Label = $PanelBackground/MarginContainer/MainVBox/FactionHeader/FactionLabels/FactionName
@onready var province_name: Label = $PanelBackground/MarginContainer/MainVBox/FactionHeader/FactionLabels/ProvinceName
@onready var banner_icon: TextureRect = $PanelBackground/MarginContainer/MainVBox/FactionHeader/BannerIcon
@onready var portrait_frame: NinePatchRect = $PanelBackground/MarginContainer/MainVBox/CharacterSection/PortraitFrame
@onready var portrait: TextureRect = $PanelBackground/MarginContainer/MainVBox/CharacterSection/PortraitFrame/Portrait
@onready var name_label: Label = $PanelBackground/MarginContainer/MainVBox/CharacterSection/NameSection/NameLabel
@onready var class_icon: TextureRect = $PanelBackground/MarginContainer/MainVBox/CharacterSection/NameSection/ClassIcon
@onready var dialogue_label: Label = $PanelBackground/MarginContainer/MainVBox/DialogueLabel

# Fallback portrait texture
var fallback_portrait: Texture2D = null

# Resource labels
@onready var resource_values: Array[Label] = [
	$PanelBackground/MarginContainer/MainVBox/ResourceGrid/Resource0/Value,
	$PanelBackground/MarginContainer/MainVBox/ResourceGrid/Resource1/Value,
	$PanelBackground/MarginContainer/MainVBox/ResourceGrid/Resource2/Value,
	$PanelBackground/MarginContainer/MainVBox/ResourceGrid/Resource3/Value,
	$PanelBackground/MarginContainer/MainVBox/ResourceGrid/Resource4/Value,
	$PanelBackground/MarginContainer/MainVBox/ResourceGrid/Resource5/Value
]

@onready var resource_icons: Array[TextureRect] = [
	$PanelBackground/MarginContainer/MainVBox/ResourceGrid/Resource0/Icon,
	$PanelBackground/MarginContainer/MainVBox/ResourceGrid/Resource1/Icon,
	$PanelBackground/MarginContainer/MainVBox/ResourceGrid/Resource2/Icon,
	$PanelBackground/MarginContainer/MainVBox/ResourceGrid/Resource3/Icon,
	$PanelBackground/MarginContainer/MainVBox/ResourceGrid/Resource4/Icon,
	$PanelBackground/MarginContainer/MainVBox/ResourceGrid/Resource5/Icon
]

# Unit buttons
@onready var unit_buttons: Array[TextureButton] = [
	$PanelBackground/MarginContainer/MainVBox/UnitRow/UnitBtn0,
	$PanelBackground/MarginContainer/MainVBox/UnitRow/UnitBtn1,
	$PanelBackground/MarginContainer/MainVBox/UnitRow/UnitBtn2,
	$PanelBackground/MarginContainer/MainVBox/UnitRow/UnitBtn3
]

@onready var unit_icons: Array[TextureRect] = [
	$PanelBackground/MarginContainer/MainVBox/UnitRow/UnitBtn0/UnitIcon,
	$PanelBackground/MarginContainer/MainVBox/UnitRow/UnitBtn1/UnitIcon,
	$PanelBackground/MarginContainer/MainVBox/UnitRow/UnitBtn2/UnitIcon,
	$PanelBackground/MarginContainer/MainVBox/UnitRow/UnitBtn3/UnitIcon
]

# Resource icon paths
const RESOURCE_ICONS: Dictionary = {
	"gold": "res://assets/icons/icon_gold.png",
	"food": "res://assets/icons/icon_food.png",
	"troops": "res://assets/icons/icon_troops.png",
	"flags": "res://assets/icons/icon_flags.png",
	"swords": "res://assets/icons/icon_swords.png",
	"castle": "res://assets/icons/icon_castle.png"
}

# Crest paths
const CRESTS: Dictionary = {
	"blanche": "res://assets/crests/crest_blanche.png",
	"lyle": "res://assets/crests/crest_lyle.png",
	"coryll": "res://assets/crests/crest_coryll.png"
}

func _ready():
	_setup_unit_buttons()
	_setup_portrait_frame()
	_setup_portrait_display()
	_load_fallback_portrait()
	
	# Hide class icon (swords) by default - it was showing as an X
	if class_icon:
		class_icon.visible = false
	
	# Debug output
	print("StrategicPanel ready")
	print("Portrait node: ", portrait)
	print("Portrait frame: ", portrait_frame)
	print("Portrait current texture: ", portrait.texture if portrait else "null")

func _setup_portrait_display():
	"""Configure the portrait TextureRect for proper display."""
	if portrait:
		portrait.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture_filter = TEXTURE_FILTER_NEAREST  # Crisp pixel art

func _setup_portrait_frame():
	"""Ensure portrait frame is properly configured."""
	if portrait_frame:
		portrait_frame.patch_margin_left = 12
		portrait_frame.patch_margin_top = 12
		portrait_frame.patch_margin_right = 12
		portrait_frame.patch_margin_bottom = 12
		portrait_frame.axis_stretch_horizontal = 0  # TILE mode
		portrait_frame.axis_stretch_vertical = 0    # TILE mode

func _load_fallback_portrait():
	"""Load fallback portrait if main portrait fails."""
	# Try to load a fallback portrait
	var fallback_paths = [
		"res://assets/portraits/house_blanche/lord_blanche.png",
		"res://assets/portraits/house_blanche/portrait_blanche_80.png",
		"res://assets/crests/crest_blanche.png"
	]
	
	for path in fallback_paths:
		if ResourceLoader.exists(path):
			fallback_portrait = load(path)
			if fallback_portrait:
				print("Loaded fallback portrait from: ", path)
				return
			
	print("WARNING: Could not load any fallback portrait")

func _setup_unit_buttons():
	for i in range(unit_buttons.size()):
		unit_buttons[i].toggled.connect(_on_unit_button_toggled.bind(i))

func _on_unit_button_toggled(pressed: bool, index: int):
	if pressed:
		for i in range(unit_buttons.size()):
			if i != index:
				unit_buttons[i].button_pressed = false

# Required public methods
func set_character(name: String, portrait_texture: Texture2D, faction: String):
	"""Set the character name, portrait, and faction."""
	print("StrategicPanel.set_character called: ", name, ", faction: ", faction)
	name_label.text = name
	
	# Set portrait with fallback
	if portrait_texture:
		print("Setting portrait texture: ", portrait_texture)
		portrait.texture = portrait_texture
		portrait.modulate = Color.WHITE
	elif fallback_portrait:
		print("Using fallback portrait for: ", name)
		portrait.texture = fallback_portrait
		portrait.modulate = Color.WHITE
	else:
		push_warning("No portrait texture available for: " + name)
		# Create a colored placeholder
		portrait.texture = null
		portrait.modulate = _get_faction_color(faction)
	
	# Set faction crest
	if CRESTS.has(faction):
		var crest_path = CRESTS[faction]
		if ResourceLoader.exists(crest_path):
			banner_icon.texture = load(crest_path)
			print("Loaded crest: ", crest_path)
	
	set_dialogue_text("%s, what is your command?" % name)

func _get_faction_color(faction: String) -> Color:
	"""Get a color representing the faction for placeholder portraits."""
	match faction.to_lower():
		"blanche": return Color(0.2, 0.4, 0.8)  # Blue
		"lyle": return Color(0.8, 0.2, 0.2)    # Red
		"coryll": return Color(0.2, 0.8, 0.2)  # Green
		_: return Color(0.5, 0.5, 0.5)          # Gray

func set_resources(gold: int, food: int, troops: int, mana: int, grain: int, authority: int):
	"""Set the 6 resource values."""
	var values = [gold, food, troops, mana, grain, authority]
	for i in range(min(values.size(), resource_values.size())):
		resource_values[i].text = str(values[i])

func set_resource_icons(icon_types: Array[String]):
	"""Set the 6 resource icon types."""
	for i in range(min(icon_types.size(), resource_icons.size())):
		var icon_type = icon_types[i]
		if RESOURCE_ICONS.has(icon_type):
			var icon_path = RESOURCE_ICONS[icon_type]
			if ResourceLoader.exists(icon_path):
				resource_icons[i].texture = load(icon_path)

func set_unit_types(unit_textures: Array[Texture2D]):
	"""Set the 4 unit type icons."""
	for i in range(min(unit_textures.size(), unit_icons.size())):
		if unit_textures[i]:
			unit_icons[i].texture = unit_textures[i]

func set_dialogue_text(text: String):
	"""Set the dialogue text at the bottom."""
	dialogue_label.text = text

func highlight_unit_type(index: int):
	"""Highlight a specific unit type button."""
	if index >= 0 and index < unit_buttons.size():
		unit_buttons[index].button_pressed = true
		for i in range(unit_buttons.size()):
			if i != index:
				unit_buttons[i].button_pressed = false

func set_faction(faction_id: String, faction_name_text: String, province_text: String):
	"""Set faction info with crest and text."""
	faction_name.text = faction_name_text
	province_name.text = province_text
	if CRESTS.has(faction_id):
		var crest_path = CRESTS[faction_id]
		if ResourceLoader.exists(crest_path):
			banner_icon.texture = load(crest_path)
