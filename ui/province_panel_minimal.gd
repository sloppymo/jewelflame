extends Panel

@onready var title_label: Label = $VBox/TitleLabel
@onready var owner_label: Label = $VBox/OwnerLabel
@onready var stats_label: Label = $VBox/StatsLabel
@onready var action_buttons: VBoxContainer = $VBox/ActionButtons

var current_province_id: int = -1
var intel_system: IntelSystem = IntelSystem.new()

func _ready():
	EventBus.ProvinceSelected.connect(update_panel)
	hide()

func update_panel(province_id: int):
	current_province_id = province_id
	var province = GameState.provinces.get(province_id)
	if not province:
		hide()
		return
	
	var player_family = GameState.get_player_family()
	var is_owned = province.owner_id == player_family.id
	
	# Update labels
	title_label.text = province.name
	owner_label.text = "Owner: " + province.owner_id
	
	# Update stats with fog of war
	var soldier_info = str(intel_system.get_visible_soldiers(province_id, player_family.id))
	if province.owner_id != player_family.id:
		# Check if adjacent for fog of war
		var is_adjacent = false
		# Simple adjacency check - you can improve this later
		if is_adjacent:
			soldier_info = str(province.soldiers)
		else:
			soldier_info = "???"
	
	stats_label.text = "Gold: %d\nFood: %d\nSoldiers: %s\nLoyalty: %d\nCultivation: %d\nProtection: %d" % [
		province.gold,
		province.food,
		soldier_info,
		province.loyalty,
		province.cultivation,
		province.protection
	]
	
	# Update buttons
	for button in action_buttons.get_children():
		button.disabled = !is_owned or province.is_exhausted
		
		if button.disabled:
			if not is_owned:
				button.tooltip_text = "Not your province"
			elif province.is_exhausted:
				button.tooltip_text = "Province already acted this turn"
	
	show()

func _on_recruit_button_pressed():
	if current_province_id != -1:
		if MilitaryCommands.execute_recruit(current_province_id, 50):
			update_panel(current_province_id)

func _on_develop_button_pressed():
	if current_province_id != -1:
		var province = GameState.provinces[current_province_id]
		var type = "cultivation" if province.cultivation <= province.protection else "protection"
		if DomesticCommands.execute_develop(current_province_id, type):
			update_panel(current_province_id)

func _on_attack_button_pressed():
	if current_province_id != -1:
		print("Attack functionality disabled - BattleResolver not available")
		# TODO: Implement basic attack when BattleResolver is fixed
