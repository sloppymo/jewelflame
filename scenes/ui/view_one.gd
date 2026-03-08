extends Window

# Individual lord view - shows detailed stats and equipment

const COLOR_BLUE = Color("#4a4a9e")
const COLOR_GOLD = Color("#c4a000")
const COLOR_TEXT = Color("#ffffff")

signal view_close_requested

var lord_id: String = ""

@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var portrait = $MarginContainer/VBoxContainer/HBoxContainer/PortraitPanel/Portrait
@onready var stats_panel = $MarginContainer/VBoxContainer/HBoxContainer/StatsPanel
@onready var equipment_grid = $MarginContainer/VBoxContainer/EquipmentGrid
@onready var fifth_unit_panel = $MarginContainer/VBoxContainer/FifthUnitPanel
@onready var close_btn = $MarginContainer/VBoxContainer/CloseBtn

func _ready():
	_setup_button(close_btn, _on_close)
	close_btn.text = "Close"
	
	title = "Lord Information"
	view_close_requested.connect(_on_close)

func _setup_button(btn: Button, callback: Callable):
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = COLOR_BLUE
	normal_style.border_color = COLOR_GOLD
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	btn.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color("#6a6abe")
	hover_style.border_color = Color("#e6d47a")
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	btn.add_theme_stylebox_override("hover", hover_style)
	
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.pressed.connect(callback)

func show_lord_info(lord_id_param: String):
	lord_id = lord_id_param
	
	var lord = EnhancedGameState.get_character(lord_id)
	if not lord:
		return
	
	title_label.text = "%s - %s" % [lord.name, _get_family_name(lord.family_id)]
	
	_update_stats(lord)
	_update_equipment(lord)
	_update_fifth_unit(lord)
	
	popup_centered()

func _update_stats(lord):
	# Clear stats panel
	for child in stats_panel.get_children():
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	
	# Add stat rows
	var stats = [
		{"label": "Age", "value": str(lord.age)},
		{"label": "Attack", "value": str(lord.attack_rating)},
		{"label": "Defense", "value": str(lord.defense_rating)},
		{"label": "Command", "value": str(lord.command_rating)},
		{"label": "Loyalty", "value": str(lord.loyalty) + "%"},
		{"label": "Troops", "value": str(_get_lord_troops(lord))},
		{"label": "Gold", "value": str(_get_lord_gold(lord))},
		{"label": "Food", "value": str(_get_lord_food(lord))}
	]
	
	for stat in stats:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		
		var label = Label.new()
		label.text = stat.label + ":"
		label.custom_minimum_size.x = 70
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", COLOR_GOLD)
		row.add_child(label)
		
		var value = Label.new()
		value.text = stat.value
		value.add_theme_font_size_override("font_size", 12)
		value.add_theme_color_override("font_color", COLOR_TEXT)
		row.add_child(value)
		
		vbox.add_child(row)
	
	stats_panel.add_child(vbox)

func _update_equipment(lord):
	# Clear equipment grid
	for child in equipment_grid.get_children():
		child.queue_free()
	
	var label = Label.new()
	label.text = "Equipment"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", COLOR_GOLD)
	equipment_grid.add_child(label)
	
	# Create 2x3 equipment grid
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	
	var slots = ["Weapon", "Armor", "Accessory", "Item 1", "Item 2", "Item 3"]
	for slot_name in slots:
		var slot = _create_equipment_slot(slot_name)
		grid.add_child(slot)
	
	equipment_grid.add_child(grid)

func _create_equipment_slot(slot_name: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(60, 50)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#2a2a5e")
	style.border_color = COLOR_GOLD
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var label = Label.new()
	label.text = slot_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color("#6a6a8e"))
	vbox.add_child(label)
	
	var empty = Label.new()
	empty.text = "Empty"
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.add_theme_font_size_override("font_size", 8)
	empty.add_theme_color_override("font_color", Color("#4a4a6e"))
	vbox.add_child(empty)
	
	panel.add_child(vbox)
	return panel

func _update_fifth_unit(lord):
	# Clear fifth unit panel
	for child in fifth_unit_panel.get_children():
		child.queue_free()
	
	var label = Label.new()
	label.text = "5th Unit"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", COLOR_GOLD)
	fifth_unit_panel.add_child(label)
	
	var monster = _get_lord_monster(lord)
	if monster:
		var info = HBoxContainer.new()
		
		var name_label = Label.new()
		name_label.text = monster.get("name", "Unknown")
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", COLOR_TEXT)
		info.add_child(name_label)
		
		var stats_label = Label.new()
		stats_label.text = "  (Atk:%d Def:%d)" % [monster.get("attack", 0), monster.get("defense", 0)]
		stats_label.add_theme_font_size_override("font_size", 11)
		stats_label.add_theme_color_override("font_color", COLOR_GOLD)
		info.add_child(stats_label)
		
		fifth_unit_panel.add_child(info)
	else:
		var empty = Label.new()
		empty.text = "None assigned"
		empty.add_theme_font_size_override("font_size", 11)
		empty.add_theme_color_override("font_color", Color("#6a6a8e"))
		fifth_unit_panel.add_child(empty)

func _get_family_name(family_id: String) -> String:
	var family = EnhancedGameState.get_family(family_id)
	if family:
		return family.name
	return "Unknown"

func _get_lord_troops(lord) -> int:
	var total = 0
	for province in EnhancedGameState.provinces.values():
		if province.owner_id == lord.family_id:
			total += province.soldiers
	return total

func _get_lord_gold(lord) -> int:
	var total = 0
	for province in EnhancedGameState.provinces.values():
		if province.owner_id == lord.family_id:
			total += province.gold
	return total

func _get_lord_food(lord) -> int:
	var total = 0
	for province in EnhancedGameState.provinces.values():
		if province.owner_id == lord.family_id:
			total += province.food
	return total

func _get_lord_monster(lord) -> Dictionary:
	# Check if lord has a monster assigned (would be stored in lord data)
	if lord.has_meta("assigned_monster"):
		return lord.get_meta("assigned_monster")
	return {}

func _on_close():
	view_close_requested.emit()
	hide()
