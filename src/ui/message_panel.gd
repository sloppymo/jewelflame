extends PanelContainer
class_name MessagePanel

# Signals
signal message_completed
signal choice_selected(choice: String)

# Configuration
@export var display_speed: float = 0.03
@export var auto_hide_delay: float = 5.0

# State
var _full_text: String = ""
var _current_message: String = ""
var _is_typing: bool = false
var _typing_tween: Tween = null

# Node references
@onready var message_label: Label = %MessageLabel
@onready var choices_container: HBoxContainer = %ChoicesContainer

func _ready():
	_apply_theme()
	_clear_choices()

func _apply_theme() -> void:
	# Apply KOEI-style font if available
	if ResourceLoader.exists("res://fonts/Cinzel-Regular.ttf"):
		var font = load("res://fonts/Cinzel-Regular.ttf")
		message_label.add_theme_font_override("font", font)
	
	message_label.add_theme_color_override("font_color", Color("#f5f5dc"))

# Public API

func show_message(text: String, play_sound: bool = true) -> void:
	_clear_choices()
	_full_text = text
	_current_message = ""
	message_label.text = ""
	
	if play_sound:
		_play_message_sound()
	
	_is_typing = true
	_start_typewriter()

func show_message_with_choices(text: String, choices: Array[String], play_sound: bool = true) -> void:
	show_message(text, play_sound)
	
	# Wait for typing to complete
	if _is_typing:
		await message_completed
		if not is_instance_valid(self):
			return
	
	_populate_choices(choices)
	choices_container.visible = true

func show_feedback(feedback_type: String, amount: int = 0, delay: float = -1) -> void:
	var messages: Dictionary = {
		"troop_loss": "You lost %d troops in the battle!" % amount,
		"troop_gain": "%d new recruits have joined your army!" % amount,
		"gold_earned": "Taxes collected: %d gold" % amount,
		"gold_spent": "You spent %d gold" % amount,
		"victory": "Your army has been victorious!",
		"defeat": "Your forces have been defeated...",
		"construction_complete": "Construction completed!",
		"alliance_formed": "Alliance formed!",
		"province_captured": "Province captured!",
		"province_lost": "Province lost to enemy!",
		"war_declared": "War has been declared!",
		"peace_treaty": "Peace treaty signed!",
		"treasury_low": "Warning: Treasury is running low!",
		"food_shortage": "Warning: Food shortage detected!"
	}
	
	if messages.has(feedback_type):
		show_message(messages[feedback_type])
		
		if delay < 0:
			delay = auto_hide_delay
		if delay > 0:
			await get_tree().create_timer(delay).timeout
			if is_instance_valid(self):
				clear()

func show_prompt(prompt_text: String) -> void:
	_clear_choices()
	_full_text = prompt_text
	_current_message = prompt_text
	message_label.text = prompt_text
	_is_typing = false

func clear() -> void:
	_full_text = ""
	_current_message = ""
	message_label.text = ""
	_clear_choices()
	_is_typing = false
	
	if _typing_tween and _typing_tween.is_valid():
		_typing_tween.kill()

func skip_typing() -> void:
	if _is_typing:
		if _typing_tween and _typing_tween.is_valid():
			_typing_tween.kill()
		_current_message = _full_text
		message_label.text = _full_text
		_is_typing = false
		message_completed.emit()

# Internal methods

func _start_typewriter() -> void:
	if _typing_tween and _typing_tween.is_valid():
		_typing_tween.kill()
	
	_typing_tween = create_tween()
	_typing_tween.set_trans(Tween.TRANS_LINEAR)
	
	var char_count = _full_text.length()
	for i in range(char_count):
		_typing_tween.tween_callback(_add_character.bind(i))
		_typing_tween.tween_interval(display_speed)
	
	_typing_tween.tween_callback(_finish_typing)

func _add_character(index: int) -> void:
	if not is_instance_valid(self) or index >= _full_text.length():
		return
	_current_message += _full_text[index]
	message_label.text = _current_message

func _finish_typing() -> void:
	_is_typing = false
	message_completed.emit()

func _populate_choices(choices: Array[String]) -> void:
	_clear_choices()
	
	for choice in choices:
		var btn := Button.new()
		btn.text = choice
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_on_choice_pressed.bind(choice))
		
		# Style the button
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color("#1a2f3a")
		normal_style.border_width_left = 2
		normal_style.border_width_top = 2
		normal_style.border_width_right = 2
		normal_style.border_width_bottom = 2
		normal_style.border_color = Color("#d4af37")
		btn.add_theme_stylebox_override("normal", normal_style)
		
		choices_container.add_child(btn)

func _clear_choices() -> void:
	# Fix memory leak: remove children before queue_free
	for child in choices_container.get_children():
		choices_container.remove_child(child)
		child.queue_free()
	choices_container.visible = false

func _on_choice_pressed(choice: String) -> void:
	choice_selected.emit(choice)

func _play_message_sound() -> void:
	# Placeholder for sound effect
	pass

# Input handling - only when focused

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and _is_typing:
			skip_typing()
			accept_event()
	elif event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE and _is_typing:
			skip_typing()
			accept_event()
