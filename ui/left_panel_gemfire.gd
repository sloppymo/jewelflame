class_name LeftPanelGemfire
extends Control

# Current selection state
var current_province_id: int = -1
var current_governor_id: String = ""
var current_command: String = ""

# Cached node references
@onready var family_label: Label = $PanelFrame/MarginContainer/MainVBox/HeaderRow/TitleVBox/FamilyLabel
@onready var province_label: Label = $PanelFrame/MarginContainer/MainVBox/HeaderRow/TitleVBox/ProvinceLabel
@onready var crest_icon: TextureRect = $PanelFrame/MarginContainer/MainVBox/HeaderRow/CrestIcon
@onready var portrait: TextureRect = $PanelFrame/MarginContainer/MainVBox/LordRow/PortraitFrame/Portrait
@onready var lord_name: Label = $PanelFrame/MarginContainer/MainVBox/LordRow/LordInfoVBox/LordName
@onready var swords_icon: TextureRect = $PanelFrame/MarginContainer/MainVBox/LordRow/LordInfoVBox/SwordsIcon
@onready var prompt_label: Label = $PanelFrame/MarginContainer/MainVBox/PromptLabel

# Stats grid
@onready var stats_grid: GridContainer = $PanelFrame/MarginContainer/MainVBox/StatsGrid

# Command buttons
@onready var cmd_buttons: Array[TextureButton] = [
	$PanelFrame/MarginContainer/MainVBox/CommandsRow/CommandBtn0,
	$PanelFrame/MarginContainer/MainVBox/CommandsRow/CommandBtn1,
	$PanelFrame/MarginContainer/MainVBox/CommandsRow/CommandBtn2,
	$PanelFrame/MarginContainer/MainVBox/CommandsRow/CommandBtn3
]

# Command names mapping
const COMMAND_NAMES: Array[String] = ["battle", "develop", "march", "troops"]
const COMMAND_LABELS: Array[String] = ["Battle", "Develop", "March", "Troops"]

# Crest textures by family
var crest_textures: Dictionary = {}
var portrait_paths: Dictionary = {}

func _ready():
	_load_crest_textures()
	_discover_portraits()
	_setup_command_buttons()
	_setup_panel_style()
	
	# Connect to EventBus signals
	if has_node("/root/EventBus"):
		EventBus.ProvinceSelected.connect(_on_province_selected)
		EventBus.CommandSelected.connect(_on_command_selected)
		if EventBus.has_signal("FamilyTurnStarted"):
			EventBus.FamilyTurnStarted.connect(_on_family_turn_started)
	
	# Initial update with test data if no province selected
	if current_province_id == -1:
		_show_test_data()

func _load_crest_textures():
	"""Load all family crest textures."""
	var family_ids = ["blanche", "lyle", "coryll"]
	for family_id in family_ids:
		var path = "res://assets/crests/crest_%s.png" % family_id
		if ResourceLoader.exists(path):
			crest_textures[family_id] = load(path)

func _discover_portraits():
	"""Discover all available portraits in house folders."""
	var dir = DirAccess.open("res://assets/portraits/")
	if not dir:
		return
	
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	while folder_name != "":
		if dir.current_is_dir() and folder_name.begins_with("house_"):
			var family_id = folder_name.replace("house_", "")
			var house_dir = DirAccess.open("res://assets/portraits/" + folder_name)
			if house_dir:
				house_dir.list_dir_begin()
				var file_name = house_dir.get_next()
				var portraits = []
				while file_name != "":
					if not house_dir.current_is_dir() and (file_name.ends_with(".png") or file_name.ends_with(".jpeg") or file_name.ends_with(".jpg")):
						portraits.append("res://assets/portraits/%s/%s" % [folder_name, file_name])
					file_name = house_dir.get_next()
				if portraits.size() > 0:
					portrait_paths[family_id] = portraits
				house_dir.list_dir_end()
		
		folder_name = dir.get_next()
	
	dir.list_dir_end()

func _get_portrait_for_lord(lord_id: String, family_id: String) -> String:
	"""Get portrait path for a lord, falling back to generic portraits."""
	if portrait_paths.has(family_id):
		var portraits = portrait_paths[family_id]
		# Try to match by lord name
		for path in portraits:
			var file_name = path.get_file().to_lower()
			if lord_id.to_lower() in file_name or file_name.begins_with("lord_"):
				return path
		# Return first available
		if portraits.size() > 0:
			return portraits[0]
	return ""

func _setup_command_buttons():
	"""Setup command button toggle behavior."""
	for i in range(cmd_buttons.size()):
		var btn = cmd_buttons[i]
		btn.toggled.connect(_on_command_toggled.bind(i))

func _setup_panel_style():
	"""Setup panel background and styling."""
	# Panel background is handled by NinePatchRect texture
	pass

func _on_province_selected(province_id: int):
	"""Update panel when a province is selected."""
	if not GameState.provinces.has(province_id):
		return
	
	current_province_id = province_id
	var province = GameState.provinces[province_id]
	var family_id = province.owner_id
	var family = GameState.families.get(family_id)
	
	# Update header
	if family:
		family_label.text = family.name
		if crest_textures.has(family_id):
			crest_icon.texture = crest_textures[family_id]
	else:
		family_label.text = "Unknown"
	
	province_label.text = "%d: %s" % [province_id, province.name]
	
	# Update governor info
	current_governor_id = province.governor_id
	var lord = GameState.characters.get(current_governor_id)
	
	if lord:
		lord_name.text = lord.name
		
		# CRITICAL FIX: Remove ALL children from portrait (fixes "Coryll.png" debug text)
		for child in portrait.get_children():
			child.queue_free()
		
		# Load portrait
		var portrait_path = _get_portrait_for_lord(current_governor_id, family_id)
		if portrait_path != "" and ResourceLoader.exists(portrait_path):
			var tex = load(portrait_path)
			if tex:
				portrait.texture = tex
		else:
			# Use silhouette placeholder
			portrait.texture = _create_silhouette_texture()
		
		# Update prompt
		prompt_label.text = "%s, what is your command?" % lord.name
	else:
		lord_name.text = "No Governor"
		portrait.texture = _create_silhouette_texture()
		prompt_label.text = "Select a province..."
	
	# Update stats - mapping based on Gemfire reference:
	# Gold (497) | Loyalty/Flags (56)
	# Food (391) | Swords/Power (38)
	# Soldiers (0) | Castles/Protection (45)
	_update_stat(0, province.gold if "gold" in province else 497, "gold")
	_update_stat(1, province.loyalty if "loyalty" in province else 56, "flags")
	_update_stat(2, province.food if "food" in province else 391, "food")
	_update_stat(3, province.power if "power" in province else 38, "swords")
	_update_stat(4, province.soldiers if "soldiers" in province else 0, "troops")
	_update_stat(5, province.castles if "castles" in province else 45, "castle")

func _update_stat(slot: int, value: int, icon_type: String):
	"""Update a stat row with value and icon."""
	if slot >= stats_grid.get_child_count():
		return
	
	var row = stats_grid.get_child(slot)
	var icon_rect = row.get_node("Icon")
	var value_label = row.get_node("Value")
	
	value_label.text = str(value)
	
	# Update icon based on type
	var icon_path = "res://assets/icons/icon_%s.png" % icon_type
	if ResourceLoader.exists(icon_path):
		icon_rect.texture = load(icon_path)

func _on_command_toggled(pressed: bool, button_index: int):
	"""Handle command button toggle."""
	if pressed:
		# Untoggle other buttons
		for i in range(cmd_buttons.size()):
			if i != button_index:
				cmd_buttons[i].button_pressed = false
		
		current_command = COMMAND_NAMES[button_index]
		EventBus.CommandSelected.emit(current_command)
		
		# Update prompt
		if current_governor_id != "":
			var lord = GameState.characters.get(current_governor_id)
			if lord:
				prompt_label.text = "%s will %s. Confirm?" % [lord.name, COMMAND_LABELS[button_index]]
	else:
		if current_command == COMMAND_NAMES[button_index]:
			current_command = ""
			prompt_label.text = "Select a command..."

func _on_command_selected(command: String):
	"""Handle command selection from external source."""
	pass

func _on_family_turn_started(family_id: String):
	"""Handle turn start."""
	# Reset command selection
	current_command = ""
	for btn in cmd_buttons:
		btn.button_pressed = false

func _create_silhouette_texture() -> Texture2D:
	"""Create a silhouette placeholder texture."""
	var img = Image.create(64, 96, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.15, 0.12, 0.25, 1))
	
	# Draw simple silhouette shape
	var center = Vector2(32, 40)
	var head_radius = 12
	
	# Head
	for x in range(64):
		for y in range(96):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist < head_radius:
				img.set_pixel(x, y, Color(0.3, 0.25, 0.4, 1))
			# Body
			elif y > 45 and y < 85 and abs(x - 32) < 20:
				img.set_pixel(x, y, Color(0.25, 0.2, 0.35, 1))
	
	return ImageTexture.create_from_image(img)

func _show_test_data():
	"""Show test data matching the Gemfire reference."""
	family_label.text = "Blanche"
	province_label.text = "5: Petaria"
	lord_name.text = "Lord Karl"
	prompt_label.text = "Lord Karl, what is your command?"
	
	if crest_textures.has("blanche"):
		crest_icon.texture = crest_textures["blanche"]
	
	# Use first available portrait for blanche
	if portrait_paths.has("blanche") and portrait_paths["blanche"].size() > 0:
		var tex = load(portrait_paths["blanche"][0])
		if tex:
			portrait.texture = tex
	
	# Gemfire reference values
	_update_stat(0, 497, "gold")
	_update_stat(1, 56, "flags")
	_update_stat(2, 391, "food")
	_update_stat(3, 38, "swords")
	_update_stat(4, 0, "troops")
	_update_stat(5, 45, "castle")
