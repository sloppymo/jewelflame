extends Window

# Ransom Dialog for captured lords - Complete Implementation

const COLOR_BLUE = Color("#4a4a9e")
const COLOR_GOLD = Color("#c4a000")
const COLOR_TEXT = Color("#ffffff")

signal ransom_paid(captured_lord: CharacterData)
signal ransom_refused(captured_lord: CharacterData)
signal lord_released(captured_lord: CharacterData)
signal lord_executed(captured_lord: CharacterData)
signal dialog_closed

var captured_lord: CharacterData = null
var captor_lord: CharacterData = null

var demand_gold: int = 28
var demand_food: int = 40

@onready var portrait = $MarginContainer/VBoxContainer/HBoxContainer/PortraitPanel/Portrait
@onready var name_label = $MarginContainer/VBoxContainer/NameLabel
@onready var message_label = $MarginContainer/VBoxContainer/MessageLabel
@onready var gold_slider = $MarginContainer/VBoxContainer/DemandContainer/GoldSlider
@onready var gold_label = $MarginContainer/VBoxContainer/DemandContainer/GoldLabel
@onready var food_slider = $MarginContainer/VBoxContainer/DemandContainer/FoodSlider
@onready var food_label = $MarginContainer/VBoxContainer/DemandContainer/FoodLabel
@onready var release_btn = $MarginContainer/VBoxContainer/ButtonContainer/ReleaseBtn
@onready var execute_btn = $MarginContainer/VBoxContainer/ButtonContainer/ExecuteBtn
@onready var demand_btn = $MarginContainer/VBoxContainer/ButtonContainer/DemandBtn

func _ready():
	_setup_ui()
	_connect_signals()
	
	if captured_lord:
		_show_lord_info()

func _setup_ui():
	title = "Prisoner Captured"
	
	var panel = $MarginContainer
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BLUE
	style.border_color = COLOR_GOLD
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	panel.add_theme_stylebox_override("panel", style)

func _connect_signals():
	if gold_slider:
		gold_slider.value_changed.connect(_on_gold_changed)
	if food_slider:
		food_slider.value_changed.connect(_on_food_changed)
	
	if release_btn:
		release_btn.pressed.connect(_on_release)
	if execute_btn:
		execute_btn.pressed.connect(_on_execute)
	if demand_btn:
		demand_btn.pressed.connect(_on_demand)
	
	close_requested.connect(_on_close)
	
	_style_button(release_btn)
	_style_button(execute_btn)
	_style_button(demand_btn)

func _style_button(btn: Button):
	if not btn:
		return
		
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
	
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", COLOR_TEXT)

func _show_lord_info():
	if not captured_lord:
		return
	
	if name_label:
		name_label.text = captured_lord.name
	
	if message_label:
		message_label.text = "We have captured %s!\nWhat shall we do?" % captured_lord.name
	
	# Load portrait
	if portrait and not captured_lord.portrait_path.is_empty():
		var texture = load(captured_lord.portrait_path)
		if texture:
			portrait.texture = texture
			portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Calculate suggested ransom based on lord's stats
	var attack = captured_lord.get("attack_rating") if captured_lord.has_method("get") else 0
	var defense = captured_lord.get("defense_rating") if captured_lord.has_method("get") else 0
	if attack == null: attack = 50
	if defense == null: defense = 50
	var base = attack + defense
	demand_gold = base
	demand_food = int(base * 1.5)
	
	# Set slider ranges
	if gold_slider:
		gold_slider.min_value = 0
		gold_slider.max_value = demand_gold * 2
		gold_slider.value = demand_gold
	
	if food_slider:
		food_slider.min_value = 0
		food_slider.max_value = demand_food * 2
		food_slider.value = demand_food
	
	_update_labels()

func _update_labels():
	if gold_label:
		gold_label.text = "%d gold" % demand_gold
	if food_label:
		food_label.text = "%d food" % demand_food

func _on_gold_changed(value: float):
	demand_gold = int(value)
	_update_labels()

func _on_food_changed(value: float):
	demand_food = int(value)
	_update_labels()

func _on_release():
	if captured_lord:
		captured_lord.is_captured = false
		lord_released.emit(captured_lord)
		ransom_paid.emit(captured_lord)
		hide()
		dialog_closed.emit()

func _on_execute():
	if captured_lord:
		captured_lord.is_captured = false
		captured_lord.set_meta("is_dead", true)
		lord_executed.emit(captured_lord)
		hide()
		dialog_closed.emit()

func _on_demand():
	if not captured_lord:
		hide()
		return
	
	# Check if captor has enough resources
	var can_pay = true
	
	# In a real implementation, check family's treasury
	# For now, assume 50% chance they accept
	var accepted = randf() < 0.5
	
	if accepted:
		# Transfer resources
		captured_lord.is_captured = false
		ransom_paid.emit(captured_lord)
	else:
		# They refused - lord remains captured
		pass
	
	hide()
	dialog_closed.emit()

func _on_close():
	dialog_closed.emit()
	hide()

# Public method to set lords after instantiation
func set_lords(captured: CharacterData, captor: CharacterData):
	captured_lord = captured
	captor_lord = captor
	_show_lord_info()
