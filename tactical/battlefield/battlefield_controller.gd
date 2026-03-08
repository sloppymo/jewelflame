extends Node2D

# Tactical Battlefield Controller
signal battle_completed(battle_result: Dictionary)
signal battle_aborted()

var current_battle: BattleData = null
var battle_active: bool = false

func _ready():
	# Add to tactical battle group for SceneManager to find
	add_to_group("tactical_battle")
	
	# Connect UI signals
	var auto_resolve_button = $UI_Layer/TopBar/AutoResolveButton
	if auto_resolve_button:
		auto_resolve_button.pressed.connect(_on_auto_resolve_pressed)
	
	# Hide modal dialogs initially
	hide_modals()

func initialize_battle(battle_data: BattleData):
	current_battle = battle_data
	battle_active = true
	
	# Update UI
	update_battle_display()
	setup_units()
	
	print("Tactical battle initialized: ", battle_data.battle_id)

func update_battle_display():
	var status_label = $UI_Layer/TopBar/BattleStatus
	var round_label = $UI_Layer/TopBar/RoundCounter
	
	if status_label and current_battle:
		status_label.text = "Battle: %s vs %s" % [
			current_battle.attacking_family_id.capitalize(),
			current_battle.defending_family_id.capitalize()
		]
	
	if round_label:
		round_label.text = "Round 1 of 10"

func setup_units():
	# Clear existing units
	clear_units()
	
	if not current_battle:
		return
	
	# Place attacker units
	var attacker_container = $Unit_Layer/AttackerUnits
	for i in range(current_battle.attacking_units.size()):
		var unit = current_battle.attacking_units[i]
		var unit_sprite = create_unit_sprite(unit, "attacker")
		unit_sprite.position = Vector2(200 + (i * 150), 400)
		attacker_container.add_child(unit_sprite)
	
	# Place defender units
	var defender_container = $Unit_Layer/DefenderUnits
	for i in range(current_battle.defending_units.size()):
		var unit = current_battle.defending_units[i]
		var unit_sprite = create_unit_sprite(unit, "defender")
		unit_sprite.position = Vector2(1200 + (i * 150), 400)
		defender_container.add_child(unit_sprite)

func create_unit_sprite(unit_data: UnitData, side: String) -> Sprite2D:
	var sprite = Sprite2D.new()
	
	# Create a simple colored rectangle as placeholder
	var texture = ImageTexture.new()
	var image = Image.create(60, 80, false, Image.FORMAT_RGB8)
	
	# Different colors for different unit types and sides
	var color = Color.BLUE if side == "attacker" else Color.RED
	match unit_data.unit_type:
		"knight": color = color.lightened(0.2)
		"horseman": color = color.darkened(0.2)
		"archer": color = color.lightened(0.4)
		"mage": color = Color.PURPLE if side == "attacker" else Color.ORANGE
	
	image.fill(color)
	texture.set_image(image)
	sprite.texture = texture
	
	# Store unit data
	sprite.set_meta("unit_data", unit_data)
	sprite.set_meta("side", side)
	
	return sprite

func clear_units():
	var attacker_container = $Unit_Layer/AttackerUnits
	var defender_container = $Unit_Layer/DefenderUnits
	
	for child in attacker_container.get_children():
		child.queue_free()
	
	for child in defender_container.get_children():
		child.queue_free()

func _on_auto_resolve_pressed():
	if not current_battle or not battle_active:
		return
	
	print("Auto-resolving battle...")
	
	# Simple auto-resolve stub (BattleResolver not available as autoload)
	var result = {
		"winner": "attacker" if randf() > 0.5 else "defender",
		"attacker_casualties": randi() % 10,
		"defender_casualties": randi() % 10,
		"vassals_captured": []
	}
	
	# Show results
	show_battle_results(result)
	
	# Emit completion signal
	battle_completed.emit(result)
	
	# Signal battle completion to SceneManager
	EventBus.BattleResolved.emit(result)

func show_battle_results(result: Dictionary):
	var results_panel = $UI_Layer/ModalLayer/BattleResults
	if results_panel:
		results_panel.visible = true
	
	# Update battle log
	var battle_log = $UI_Layer/BottomPanel/BattleLog/BattleLogText
	if battle_log:
		var log_text = "[b]Battle Results[/b]\n"
		log_text += "Winner: %s\n" % result.get("winner", "Unknown")
		log_text += "Attacker casualties: %d\n" % result.get("attacker_casualties", 0)
		log_text += "Defender casualties: %d\n" % result.get("defender_casualties", 0)
		log_text += "Loot: %d gold, %d food\n" % [
			result.get("loot_gold", 0),
			result.get("loot_food", 0)
		]
		
		# Add captured lords if any
		if result.has("captured_lords") and not result.captured_lords.is_empty():
			log_text += "Captured lords: %s\n" % str(result.captured_lords)
		
		battle_log.text = log_text

func hide_modals():
	var results_panel = $UI_Layer/ModalLayer/BattleResults
	var capture_dialog = $UI_Layer/ModalLayer/VassalCaptureDialog
	
	if results_panel:
		results_panel.visible = false
	if capture_dialog:
		capture_dialog.visible = false

func abort_battle():
	battle_active = false
	current_battle = null
	battle_aborted.emit()
	print("Battle aborted")
