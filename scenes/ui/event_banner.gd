extends Control

const COLOR_PLAGUE = Color("#8b0000")  # Dark red
const COLOR_EARTHQUAKE = Color("#8b4513")  # Brown
const COLOR_DEFAULT = Color("#4a4a9e")  # Royal blue

@onready var panel = $Panel
@onready var icon_label = $Panel/HBoxContainer/IconLabel
@onready var text_label = $Panel/HBoxContainer/TextLabel
@onready var animation_player = $AnimationPlayer

func _ready():
	hide()

func show_event(event_text: String, event_type: String = ""):
	text_label.text = event_text
	
	# Set icon and color based on event type
	match event_type:
		"plague":
			icon_label.text = "☠️"
			_set_panel_color(COLOR_PLAGUE)
		"earthquake":
			icon_label.text = "🌋"
			_set_panel_color(COLOR_EARTHQUAKE)
		_:
			icon_label.text = "📢"
			_set_panel_color(COLOR_DEFAULT)
	
	show()
	animation_player.play("slide_in")
	
	# Auto-hide after 5 seconds
	await get_tree().create_timer(5.0).timeout
	hide_event()

func hide_event():
	animation_player.play("slide_out")
	await animation_player.animation_finished
	hide()

func _set_panel_color(color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#c4a000")
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	panel.add_theme_stylebox_override("panel", style)
