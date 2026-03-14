class_name GameSidebar
extends Control

signal action_pressed(action: String)
signal tab_changed(tab_name: String)
signal end_turn_requested()
signal save_requested()

# Header
@onready var province_name: Label = %ProvinceName
@onready var ruler_name: Label = %RulerName

# Portrait
@onready var portrait: Control = %Portrait

# Stats
@onready var defense_value: Label = %DefenseValue
@onready var income_value: Label = %IncomeValue
@onready var garrison_value: Label = %GarrisonValue
@onready var loyalty_value: Label = %LoyaltyValue

# Buttons
@onready var attack_btn: Button = %AttackBtn
@onready var defend_btn: Button = %DefendBtn
@onready var recruit_btn: Button = %RecruitBtn
@onready var scout_btn: Button = %ScoutBtn
@onready var save_btn: Button = %SaveBtn
@onready var end_turn_btn: Button = %EndTurnBtn

func _ready():
	print("=== SIDEBAR INITIALIZING ===")
	
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

func _update_for_province(province_id: int):
	var game_state = get_node_or_null("/root/GameState")
	if not game_state:
		return
		
	var province = game_state.provinces.get(province_id)
	if not province:
		return
	
	# Update province name
	if province_name:
		province_name.text = province.name
	
	# Update ruler name (placeholder - would lookup actual lord)
	var family = game_state.families.get(province.owner_id)
	if family and ruler_name:
		ruler_name.text = "Lord of " + family.name.capitalize()
	elif ruler_name:
		ruler_name.text = "Unclaimed"
	
	# Update stats display
	_update_stats_display(province)

func _update_stats_display(province):
	if not province:
		return
	
	# Defense (based on terrain/protection)
	if defense_value:
		var defense = "Medium"
		if province.protection > 50:
			defense = "High"
		elif province.protection < 20:
			defense = "Low"
		defense_value.text = defense
	
	# Income (gold per turn)
	if income_value:
		income_value.text = str(province.gold)
	
	# Garrison (soldiers)
	if garrison_value:
		garrison_value.text = str(province.soldiers)
	
	# Loyalty
	if loyalty_value:
		loyalty_value.text = str(province.loyalty) + "%"

func update_province_name(name: String):
	"""Update the province name label."""
	if province_name:
		province_name.text = name

func update_ruler_name(name: String):
	"""Update the ruler name label."""
	if ruler_name:
		ruler_name.text = name

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
