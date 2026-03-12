extends CanvasLayer
class_name GameUI

# References to UI components
@onready var sidebar: GameSidebar = %GameSidebar
@onready var message_panel: MessagePanel = %MessagePanel
@onready var event_modal: EventModal = %EventModal

func _ready():
	if not is_instance_valid(self):
		return
	
	# Connect sidebar signals
	if sidebar:
		sidebar.action_pressed.connect(_on_action_pressed)
		sidebar.section_changed.connect(_on_section_changed)
	
	# Connect message panel signals
	if message_panel:
		message_panel.message_completed.connect(_on_message_completed)
		message_panel.choice_selected.connect(_on_message_choice_selected)
	
	# Connect event modal signals
	if event_modal:
		event_modal.dismissed.connect(_on_event_dismissed)
		event_modal.choice_made.connect(_on_event_choice_made)
	
	# Initialize with test data (remove in production)
	_call_deferred("_initialize_test_data")

func _initialize_test_data() -> void:
	if not is_instance_valid(self):
		return
	
	# Set up test character
	if sidebar:
		sidebar.character_name = "Lord Karl"
		sidebar.character_title = "Knight of Cobrige"
		sidebar.character_level = 5
	
	# Set up test resources
	if sidebar:
		sidebar.gold = 497
		sidebar.food = 391
		sidebar.troops = 0
		sidebar.wood = 0
		sidebar.holdings = 45
		sidebar.influence = 12
	
	# Show initial message
	if message_panel:
		message_panel.show_message("Lord Karl, what is your command?")

# Signal handlers

func _on_action_pressed(action_type: String) -> void:
	if not is_instance_valid(self) or not message_panel:
		return
		
	match action_type:
		"attack": _show_attack_options()
		"defend": message_panel.show_message("Fortifying current position...")
		"recruit": message_panel.show_feedback("troop_gain", 50)
		"scout": message_panel.show_message("Scouting reports will appear here.")
		"build": _show_build_options()
		"trade": _show_trade_options()
		"tax": message_panel.show_feedback("gold_earned", 200)
		"develop": message_panel.show_message("Select a province to develop.")
		"negotiate": _show_negotiate_options()
		"ally": _show_alliance_options()
		"threaten": message_panel.show_message("Threaten which faction?")
		"bribe": message_panel.show_message("How much gold to offer?")
		"save": _save_game()
		"load": _load_game()
		"settings": _show_settings()
		"end_turn": _end_turn()

func _on_section_changed(section_id: String) -> void:
	if message_panel and is_instance_valid(message_panel):
		message_panel.show_message("Switched to %s section" % section_id)

func _on_message_completed() -> void:
	pass

func _on_message_choice_selected(choice: String) -> void:
	if message_panel and is_instance_valid(message_panel):
		message_panel.show_message("Selected: %s" % choice)

func _on_event_dismissed() -> void:
	pass

func _on_event_choice_made(choice: String) -> void:
	if message_panel and is_instance_valid(message_panel):
		message_panel.show_message("Event choice: %s" % choice)

# Action implementations

func _show_attack_options() -> void:
	if not message_panel or not is_instance_valid(message_panel):
		return
	message_panel.show_message_with_choices(
		"Attack which province?",
		["12 - Dunmoor", "15 - Carveti", "22 - Banshea", "28 - Petaria"]
	)

func _show_build_options() -> void:
	if not message_panel or not is_instance_valid(message_panel):
		return
	message_panel.show_message_with_choices(
		"What would you like to build?",
		["Castle", "Farm", "Market", "Barracks"]
	)

func _show_trade_options() -> void:
	if not message_panel or not is_instance_valid(message_panel):
		return
	message_panel.show_message_with_choices(
		"Trade what resource?",
		["Sell 100 food", "Buy 50 wood", "Sell gold", "Cancel"]
	)

func _show_negotiate_options() -> void:
	if not message_panel or not is_instance_valid(message_panel):
		return
	message_panel.show_message_with_choices(
		"Negotiate with whom?",
		["House Blanche", "House Garth", "House Petaria", "Cancel"]
	)

func _show_alliance_options() -> void:
	if not message_panel or not is_instance_valid(message_panel):
		return
	message_panel.show_message_with_choices(
		"Propose alliance with?",
		["House Blanche", "House Petaria", "Independents", "Cancel"]
	)

func _save_game() -> void:
	if message_panel and is_instance_valid(message_panel):
		message_panel.show_message("Game saved successfully!")

func _load_game() -> void:
	if message_panel and is_instance_valid(message_panel):
		message_panel.show_message("Load game feature coming soon.")

func _show_settings() -> void:
	if message_panel and is_instance_valid(message_panel):
		message_panel.show_message("Settings menu would open here.")

func _end_turn() -> void:
	if not message_panel or not is_instance_valid(message_panel):
		return
		
	message_panel.show_message("Ending turn...")
	
	# Use create_timer safely
	var timer := get_tree().create_timer(1.0)
	await timer.timeout
	
	if not is_instance_valid(self) or not event_modal:
		return
	
	# Show season change modal
	show_season_change(1, "winter", "Snow blankets the realm. Armies huddle in their castles.")

# Public API for external systems

func show_combat_result(victory: bool, data: Dictionary) -> void:
	if not event_modal or not is_instance_valid(event_modal):
		return
	if victory:
		event_modal.show_event(EventModal.ModalType.VICTORY, data)
	else:
		event_modal.show_event(EventModal.ModalType.DEFEAT, data)

func show_character_death(character_data: Dictionary) -> void:
	if event_modal and is_instance_valid(event_modal):
		event_modal.show_event(EventModal.ModalType.DEATH, character_data)

func show_alliance_formed(faction_data: Dictionary) -> void:
	if event_modal and is_instance_valid(event_modal):
		event_modal.show_event(EventModal.ModalType.ALLIANCE, faction_data)

func show_province_captured(province_data: Dictionary) -> void:
	if event_modal and is_instance_valid(event_modal):
		event_modal.show_event(EventModal.ModalType.CAPTURE, province_data)

func show_season_change(year: int, season: String, flavor_text: String = "") -> void:
	if event_modal and is_instance_valid(event_modal):
		event_modal.show_event(EventModal.ModalType.SEASON, {
			"year": year, "season": season, "flavor_text": flavor_text
		})

func show_story_event(title: String, text: String, button_text: String = "Continue") -> void:
	if event_modal and is_instance_valid(event_modal):
		event_modal.show_event(EventModal.ModalType.STORY, {
			"title": title, "text": text, "button_text": button_text
		})

func update_resources(resources: Dictionary) -> void:
	if not sidebar or not is_instance_valid(sidebar):
		return
	if resources.has("gold"): sidebar.gold = resources["gold"]
	if resources.has("food"): sidebar.food = resources["food"]
	if resources.has("troops"): sidebar.troops = resources["troops"]
	if resources.has("wood"): sidebar.wood = resources["wood"]
	if resources.has("holdings"): sidebar.holdings = resources["holdings"]
	if resources.has("influence"): sidebar.influence = resources["influence"]

func update_character(character_data: Dictionary) -> void:
	if sidebar and is_instance_valid(sidebar):
		sidebar.set_character(character_data)
