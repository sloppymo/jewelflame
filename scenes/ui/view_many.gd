extends Window

# Family roster view - shows 8 family members per page

const COLOR_BLUE = Color("#4a4a9e")
const COLOR_GOLD = Color("#c4a000")
const COLOR_TEXT = Color("#ffffff")
const COLOR_HEADER = Color("#6a6abe")

signal lord_selected(lord_id: String)
signal view_close_requested

var current_page: int = 0
var lords_per_page: int = 8
var family_lords: Array = []
var family_id: String = ""

@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var page_label = $MarginContainer/VBoxContainer/PageLabel
@onready var lord_list = $MarginContainer/VBoxContainer/LordList
@onready var prev_btn = $MarginContainer/VBoxContainer/HBoxContainer/PrevBtn
@onready var next_btn = $MarginContainer/VBoxContainer/HBoxContainer/NextBtn
@onready var close_btn = $MarginContainer/VBoxContainer/HBoxContainer/CloseBtn

func _ready():
	_setup_button(prev_btn, _on_prev_page)
	_setup_button(next_btn, _on_next_page)
	_setup_button(close_btn, _on_close)
	
	close_btn.text = "Close"
	prev_btn.text = "<"
	next_btn.text = ">"
	
	title = "Family Roster"
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

func show_family_roster(family_id_param: String):
	family_id = family_id_param
	current_page = 0
	
	var family = GameState.get_family(family_id)
	if family:
		title_label.text = "%s Family Roster" % family.name
	
	_load_family_lords()
	_update_display()
	popup_centered()

func _load_family_lords():
	family_lords.clear()
	for character in GameState.characters.values():
		if character.family_id == family_id and character is LordData:
			family_lords.append(character)
	
	# Sort by lord status and name
	family_lords.sort_custom(func(a, b): return a.name < b.name)

func _update_display():
	# Clear list
	for child in lord_list.get_children():
		child.queue_free()
	
	var total_pages = ceili(float(family_lords.size()) / lords_per_page)
	page_label.text = "Page %d/%d" % [current_page + 1, max(1, total_pages)]
	
	# Calculate range for current page
	var start_idx = current_page * lords_per_page
	var end_idx = min(start_idx + lords_per_page, family_lords.size())
	
	# Add header row
	var header = _create_lord_row("Name", "Age", "Atk", "Def", "Cmd", "Troops", true)
	lord_list.add_child(header)
	
	# Add lord rows
	for i in range(start_idx, end_idx):
		var lord = family_lords[i]
		var row = _create_lord_row(
			lord.name,
			str(lord.age),
			str(lord.attack_rating),
			str(lord.defense_rating),
			str(lord.command_rating),
			_get_lord_troops(lord),
			false,
			lord.id
		)
		lord_list.add_child(row)
	
	# Update button states
	prev_btn.disabled = current_page <= 0
	next_btn.disabled = current_page >= total_pages - 1

func _create_lord_row(name: String, age: String, atk: String, def: String, cmd: String, troops: String, is_header: bool = false, lord_id: String = "") -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	
	var labels = [name, age, atk, def, cmd, troops]
	var widths = [80, 30, 30, 30, 30, 50]
	
	for i in range(labels.size()):
		var label = Label.new()
		label.text = labels[i]
		label.custom_minimum_size.x = widths[i]
		label.add_theme_font_size_override("font_size", 12)
		
		if is_header:
			label.add_theme_color_override("font_color", COLOR_GOLD)
		else:
			label.add_theme_color_override("font_color", COLOR_TEXT)
		
		row.add_child(label)
	
	if not is_header and not lord_id.is_empty():
		var select_btn = Button.new()
		select_btn.text = "View"
		select_btn.add_theme_font_size_override("font_size", 10)
		select_btn.pressed.connect(_on_lord_selected.bind(lord_id))
		row.add_child(select_btn)
	
	return row

func _get_lord_troops(lord) -> String:
	var total = 0
	for province in GameState.provinces.values():
		if province.owner_id == lord.family_id:
			total += province.soldiers
	return str(total)

func _on_prev_page():
	if current_page > 0:
		current_page -= 1
		_update_display()

func _on_next_page():
	var total_pages = ceili(float(family_lords.size()) / lords_per_page)
	if current_page < total_pages - 1:
		current_page += 1
		_update_display()

func _on_lord_selected(lord_id: String):
	lord_selected.emit(lord_id)
	hide()

func _on_close():
	view_close_requested.emit()
	hide()
