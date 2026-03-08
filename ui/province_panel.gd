extends Panel

@onready var title_label: Label = $VBox/Header/TitleLabel
@onready var close_button: Button = $VBox/Header/CloseButton
@onready var owner_label: Label = $VBox/OwnerLabel
@onready var stats_label: Label = $VBox/StatsLabel
@onready var action_buttons: VBoxContainer = $VBox/ActionButtons

var current_province_id: int = -1
# var intel_system: IntelSystem = IntelSystem.new() # Disabled - IntelSystem removed
var animation_controller: Node2D

func _ready():
	EventBus.ProvinceSelected.connect(update_panel)
	EventBus.BattleResolved.connect(_on_battle_resolved)
	EventBus.ProvinceDataChanged.connect(_on_province_data_changed)
	
	# Get animation controller reference
	animation_controller = get_tree().get_first_node_in_group("animation_controller")
	
	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	hide()

func _on_close_pressed():
	hide()
	current_province_id = -1

func _on_province_data_changed(province_id: int, field: String, value: Variant):
	# Refresh panel if current province's data changed
	if province_id == current_province_id and visible:
		update_panel(province_id)

func update_panel(province_id: int):
	current_province_id = province_id
	var province = GameState.provinces.get(province_id)
	if not province:
		hide()
		return
	
	var player_family = GameState.get_player_family()
	var is_owned = (province.owner_id == player_family.id)
	
	title_label.text = province.name
	owner_label.text = "Owner: " + province.owner_id.capitalize()
	if province.is_capital:
		owner_label.text += " ♚"
	
	# var soldier_text = intel_system.get_intel_description(province_id, player_family.id)
	var soldier_text = str(province.soldiers) # Simple fallback without IntelSystem
	var stats = "Gold: %d\nFood: %d\nSoldiers: %s\nLoyalty: %d\nCultivation: %d\nProtection: %d" % [
		province.gold, province.food, soldier_text,
		province.loyalty, province.cultivation, province.protection
	]
	
	if province.is_exhausted:
		stats += "\n[EXHAUSTED]"
	
	stats_label.text = stats
	
	# Show the panel
	show()
	
	for button in action_buttons.get_children():
		button.disabled = !is_owned or province.is_exhausted
		
		if button.disabled:
			if not is_owned:
				button.tooltip_text = "Not your province"
			elif province.is_exhausted:
				button.tooltip_text = "Province already acted this turn"
	
	# Special handling for attack button
	var attack_button = action_buttons.get_node_or_null("AttackButton")
	if attack_button:
		attack_button.disabled = !can_attack(province_id, player_family.id)
		
		if attack_button.disabled:
			if not is_owned:
				attack_button.tooltip_text = "Cannot attack from enemy province"
			elif not has_adjacent_enemies(province_id):
				attack_button.tooltip_text = "No adjacent enemy provinces"
			elif province.is_exhausted:
				attack_button.tooltip_text = "Province already acted this turn"
	
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
		var province = GameState.provinces[current_province_id]
		var player_family = GameState.get_player_family()
		
		# Get adjacent enemy provinces
		var enemy_targets = []
		for neighbor_id in province.neighbors:
			var neighbor = GameState.provinces[neighbor_id]
			if neighbor.owner_id != player_family.id:
				enemy_targets.append(neighbor_id)
		
		if enemy_targets.is_empty():
			print("No attack targets available")
			return
		
		# For now, attack the first available target
		# TODO: Add target selection UI
		var target_id = enemy_targets[0]
		
		# Show attack animation
		if animation_controller:
			animation_controller.show_attack_arrow(current_province_id, target_id)
		
		# Launch tactical battle!
		print("Launching tactical battle: %s vs %s" % [province.name, GameState.provinces[target_id].name])
		BattleLauncher.launch_battle(current_province_id, target_id, 0.7, _on_battle_returned)

func _on_battle_resolved(result: Dictionary):
	# Show battle report dialog
	var battle_report = preload("res://ui/battle_report.gd").new()
	get_tree().current_scene.add_child(battle_report)
	
	# Get attacker and defender names
	var attacker_name = "Unknown"
	var defender_name = "Unknown"
	
	# Find the provinces involved in this battle
	for province_id in GameState.provinces:
		var province = GameState.provinces[province_id]
		if province_id in result.get("attacker_provinces", []):
			attacker_name = province.name
		if province_id in result.get("defender_provinces", []):
			defender_name = province.name
	
	battle_report.show_battle_report(result, attacker_name, defender_name)

func _on_battle_returned(result: Dictionary) -> void:
	"""Called when tactical battle ends and returns to strategic map."""
	print("Battle returned! Winner: ", result.get("winner", "unknown"))
	
	# Refresh the panel to show updated stats
	if current_province_id != -1:
		update_panel(current_province_id)

func can_attack(province_id: int, family_id: String) -> bool:
	var province = GameState.provinces[province_id]
	
	# Must own the province
	if province.owner_id != family_id:
		return false
	
	# Must not be exhausted
	if province.is_exhausted:
		return false
	
	# Must have adjacent enemies
	return has_adjacent_enemies(province_id)

func has_adjacent_enemies(province_id: int) -> bool:
	var province = GameState.provinces[province_id]
	var player_family = GameState.get_player_family()
	
	for neighbor_id in province.neighbors:
		var neighbor = GameState.provinces[neighbor_id]
		if neighbor.owner_id != player_family.id:
			return true
	
	return false
