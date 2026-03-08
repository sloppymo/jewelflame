extends Window

# Province data view - shows resource table for all owned territories

const COLOR_BLUE = Color("#4a4a9e")
const COLOR_GOLD = Color("#c4a000")
const COLOR_TEXT = Color("#ffffff")

signal province_selected(province_id: int)
signal view_close_requested

var family_id: String = ""
var owned_provinces: Array = []

@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var province_list = $MarginContainer/VBoxContainer/ProvinceList
@onready var close_btn = $MarginContainer/VBoxContainer/CloseBtn

func _ready():
	_setup_button(close_btn, _on_close)
	close_btn.text = "Close"
	
	title = "Province Data"
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

func show_province_data(family_id_param: String):
	family_id = family_id_param
	
	var family = EnhancedGameState.get_family(family_id)
	if family:
		var province_count = _count_owned_provinces()
		title_label.text = "%s: %d provinces" % [family.name, province_count]
	
	_load_owned_provinces()
	_update_display()
	popup_centered()

func _count_owned_provinces() -> int:
	var count = 0
	for province in EnhancedGameState.provinces.values():
		if province.owner_id == family_id:
			count += 1
	return count

func _load_owned_provinces():
	owned_provinces.clear()
	for province in EnhancedGameState.provinces.values():
		if province.owner_id == family_id:
			owned_provinces.append(province)
	
	# Sort by province ID
	owned_provinces.sort_custom(func(a, b): return a.id < b.id)

func _update_display():
	# Clear list
	for child in province_list.get_children():
		child.queue_free()
	
	# Add header row
	var header = _create_province_row("#", "Name", "Gold", "Food", "Mana", "Troops", "Lord", true)
	province_list.add_child(header)
	
	# Add separator
	var separator = HSeparator.new()
	province_list.add_child(separator)
	
	# Add province rows
	for province in owned_provinces:
		var lord_name = _get_lord_name(province.stationed_lord_id)
		var row = _create_province_row(
			str(province.id),
			province.name,
			str(province.gold),
			str(province.food),
			str(province.mana),
			str(province.soldiers),
			lord_name,
			false,
			province.id
		)
		province_list.add_child(row)

func _create_province_row(id: String, name: String, gold: String, food: String, mana: String, troops: String, lord: String, is_header: bool = false, province_id: int = -1) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	
	var labels = [id, name, gold, food, mana, troops, lord]
	var widths = [25, 70, 40, 40, 40, 45, 70]
	
	for i in range(labels.size()):
		var label = Label.new()
		label.text = labels[i]
		label.custom_minimum_size.x = widths[i]
		label.add_theme_font_size_override("font_size", 11)
		
		if is_header:
			label.add_theme_color_override("font_color", COLOR_GOLD)
		else:
			label.add_theme_color_override("font_color", COLOR_TEXT)
		
		row.add_child(label)
	
	if not is_header and province_id >= 0:
		var select_btn = Button.new()
		select_btn.text = "Select"
		select_btn.add_theme_font_size_override("font_size", 9)
		select_btn.pressed.connect(_on_province_selected.bind(province_id))
		row.add_child(select_btn)
	
	return row

func _get_lord_name(lord_id: String) -> String:
	if lord_id.is_empty():
		return "None"
	var lord = EnhancedGameState.get_character(lord_id)
	if lord:
		return lord.name
	return "Unknown"

func _on_province_selected(province_id: int):
	province_selected.emit(province_id)
	hide()

func _on_close():
	view_close_requested.emit()
	hide()
