extends Window

# 5th Unit / Monster inventory view

const COLOR_BLUE = Color("#4a4a9e")
const COLOR_GOLD = Color("#c4a000")
const COLOR_TEXT = Color("#ffffff")

signal monster_selected(monster_idx: int)
signal view_close_requested

var family_id: String = ""
var monsters: Array = []
var max_monsters: int = 5

@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var capacity_label = $MarginContainer/VBoxContainer/CapacityLabel
@onready var monster_grid = $MarginContainer/VBoxContainer/MonsterGrid
@onready var close_btn = $MarginContainer/VBoxContainer/CloseBtn

func _ready():
	_setup_button(close_btn, _on_close)
	close_btn.text = "Close"
	
	title = "5th Unit Inventory"
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

func show_monster_inventory(family_id_param: String):
	family_id = family_id_param
	
	monsters = SearchSystem.get_family_monsters(family_id)
	max_monsters = SearchSystem.get_max_monsters(family_id)
	
	capacity_label.text = "Monsters: %d/%d" % [monsters.size(), max_monsters]
	_update_display()
	popup_centered()

func _update_display():
	# Clear grid
	for child in monster_grid.get_children():
		child.queue_free()
	
	# Create grid layout
	var columns = 3
	var current_row: HBoxContainer = null
	
	for i in range(max_monsters):
		if i % columns == 0:
			current_row = HBoxContainer.new()
			current_row.add_theme_constant_override("separation", 10)
			monster_grid.add_child(current_row)
		
		var slot = _create_monster_slot(i)
		current_row.add_child(slot)

func _create_monster_slot(index: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(90, 80)
	
	var style = StyleBoxFlat.new()
	
	if index < monsters.size():
		# Occupied slot
		var monster = monsters[index]
		style.bg_color = COLOR_BLUE
		style.border_color = COLOR_GOLD
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Monster icon/name
		var name_label = Label.new()
		name_label.text = monster.get("name", "Unknown")
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", COLOR_TEXT)
		vbox.add_child(name_label)
		
		# Stats
		var stats_label = Label.new()
		stats_label.text = "Atk:%d Def:%d" % [monster.get("attack", 0), monster.get("defense", 0)]
		stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_label.add_theme_font_size_override("font_size", 10)
		stats_label.add_theme_color_override("font_color", COLOR_GOLD)
		vbox.add_child(stats_label)
		
		# Type
		var type_label = Label.new()
		type_label.text = monster.get("type", "normal")
		type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_label.add_theme_font_size_override("font_size", 9)
		type_label.add_theme_color_override("font_color", COLOR_TEXT)
		vbox.add_child(type_label)
		
		# Select button
		var select_btn = Button.new()
		select_btn.text = "Assign"
		select_btn.add_theme_font_size_override("font_size", 9)
		select_btn.pressed.connect(_on_monster_selected.bind(index))
		vbox.add_child(select_btn)
		
		panel.add_child(vbox)
	else:
		# Empty slot
		style.bg_color = Color("#2a2a5e")
		style.border_color = Color("#6a6a8e")
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		
		var empty_label = Label.new()
		empty_label.text = "Empty"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 10)
		empty_label.add_theme_color_override("font_color", Color("#6a6a8e"))
		panel.add_child(empty_label)
	
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _on_monster_selected(index: int):
	monster_selected.emit(index)
	hide()

func _on_close():
	view_close_requested.emit()
	hide()
