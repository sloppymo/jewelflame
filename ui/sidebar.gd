class_name GameSidebar
extends Control

signal action_pressed(action: String)
signal tab_changed(tab_name: String)
signal end_turn_requested()
signal save_requested()

# Header
@onready var family_name: Label = %FamilyName

# Portrait
@onready var portrait: Control = %Portrait

# Stats - Gold/Food/Troops/Wood/Mana/Influence
@onready var gold_value: Label = %GoldValue
@onready var food_value: Label = %FoodValue
@onready var troops_value: Label = %TroopsValue
@onready var wood_value: Label = %WoodValue
@onready var mana_value: Label = %ManaValue
@onready var influence_value: Label = %InfluenceValue

# Buttons
@onready var attack_btn: Button = %AttackBtn
@onready var defend_btn: Button = %DefendBtn
@onready var recruit_btn: Button = %RecruitBtn
@onready var scout_btn: Button = %ScoutBtn
@onready var save_btn: Button = %SaveBtn
@onready var end_turn_btn: Button = %EndTurnBtn

func _ready():
	print("=== SIDEBAR INITIALIZING ===")
	
	# Validate all textures are loaded
	_validate_textures()
	
	# Constrain content sizes to fit within sidebar
	_constrain_content_sizes()
	
	# Connect to game events safely
	var event_bus = get_node_or_null("/root/EventBus")
	var game_state = get_node_or_null("/root/GameState")
	
	if event_bus:
		event_bus.ProvinceSelected.connect(_on_province_selected)
		event_bus.TurnEnded.connect(_on_turn_ended)
	
	# Initialize with first province if available
	if game_state and game_state.provinces.size() > 0:
		_update_for_province(1)
	
	print("=== SIDEBAR READY ===")

func _validate_textures():
	print("--- VALIDATING TEXTURES ---")
	
	# Check Banner
	var banner = get_node_or_null("Banner")
	if banner:
		var banner_tex = banner.get("banner_texture")
		print("Banner texture: ", banner_tex)
		if banner_tex == null:
			push_error("SIDEBAR: Banner texture is null!")
	else:
		push_error("SIDEBAR: Banner node not found!")
	
	# Check Portrait
	var portrait_node = get_node_or_null("Portrait")
	if portrait_node:
		var portrait_tex = portrait_node.get("portrait_texture")
		print("Portrait texture: ", portrait_tex)
		if portrait_tex == null:
			push_error("SIDEBAR: Portrait texture is null!")
	else:
		push_error("SIDEBAR: Portrait node not found!")
	
	print("--- TEXTURE VALIDATION COMPLETE ---")

func _constrain_content_sizes():
	# Layout is now handled in sidebar.tscn
	pass

func _update_for_province(province_id: int):
	var game_state = get_node_or_null("/root/GameState")
	if not game_state:
		return
		
	var province = game_state.provinces.get(province_id)
	if not province:
		return
	
	var family = game_state.families.get(province.owner_id)
	if family:
		family_name.text = family.name.to_upper()
	else:
		family_name.text = "UNCLAIMED"
	
	# Update resources display
	_update_resources_display(province)

func _update_resources_display(province):
	if province:
		if gold_value: gold_value.text = str(province.gold if "gold" in province else 0)
		if food_value: food_value.text = str(province.food if "food" in province else 0)
		if troops_value: troops_value.text = str(province.troops if "troops" in province else 0)
		if wood_value: wood_value.text = str(province.wood if "wood" in province else 0)
		if mana_value: mana_value.text = str(province.mana if "mana" in province else 50)
		if influence_value: influence_value.text = str(province.influence if "influence" in province else 0)

func update_resources(resources: Dictionary):
	"""Update resource values from dictionary."""
	if resources.has("gold") and gold_value:
		gold_value.text = str(resources.gold)
	if resources.has("food") and food_value:
		food_value.text = str(resources.food)
	if resources.has("troops") and troops_value:
		troops_value.text = str(resources.troops)
	if resources.has("wood") and wood_value:
		wood_value.text = str(resources.wood)
	if resources.has("mana") and mana_value:
		mana_value.text = str(resources.mana)
	if resources.has("influence") and influence_value:
		influence_value.text = str(resources.influence)

func update_portrait(character_id: String):
	"""Dynamically swap portrait texture."""
	var portrait_path = "res://assets/portraits/house_" + character_id + "/lord_" + character_id + ".png"
	var texture = load(portrait_path)
	if texture:
		var portrait_node = get_node_or_null("Portrait")
		if portrait_node:
			portrait_node.portrait_texture = texture
			portrait_node.queue_redraw()
			print("Portrait updated to: ", portrait_path)
	else:
		push_error("Failed to load portrait: " + portrait_path)

func update_stats(gold: int, food: int, troops: int, wood: int, mana: int, influence: int):
	"""Update all stat labels."""
	if gold_value: gold_value.text = str(gold)
	if food_value: food_value.text = str(food)
	if troops_value: troops_value.text = str(troops)
	if wood_value: wood_value.text = str(wood)
	if mana_value: mana_value.text = str(mana)
	if influence_value: influence_value.text = str(influence)

func _on_province_selected(province_id: int):
	_update_for_province(province_id)

func _on_turn_ended(_turn_number: int):
	pass

# Button handlers
func _on_attack_pressed():
	action_pressed.emit("attack")

func _on_defend_pressed():
	action_pressed.emit("defend")

func _on_recruit_pressed():
	action_pressed.emit("recruit")

func _on_scout_pressed():
	action_pressed.emit("scout")

func _on_save_pressed():
	save_requested.emit()

func _on_end_turn_pressed():
	end_turn_requested.emit()
