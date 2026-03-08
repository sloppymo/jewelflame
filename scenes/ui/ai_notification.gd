extends Control

const COLOR_NOTIFICATION = Color("#2a2a5e")

@onready var panel = $Panel
@onready var text_label = $Panel/TextLabel
@onready var animation_player = $AnimationPlayer

var notification_queue: Array[String] = []
var is_showing: bool = false

func _ready():
	hide()

func show_notification(text: String):
	notification_queue.append(text)
	if not is_showing:
		_process_queue()

func _process_queue():
	if notification_queue.is_empty():
		is_showing = false
		return
	
	is_showing = true
	var text = notification_queue.pop_front()
	text_label.text = text
	
	# Set panel style
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_NOTIFICATION
	style.border_color = Color("#c4a000")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	
	show()
	animation_player.play("fade_in")
	
	# Show for 4 seconds then next
	await get_tree().create_timer(4.0).timeout
	animation_player.play("fade_out")
	await animation_player.animation_finished
	
	_process_queue()

func clear_queue():
	notification_queue.clear()
	is_showing = false
	hide()
