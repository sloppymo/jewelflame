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

# Node references - using @onready with unique names
@onready var _message_label: Label = %MessageLabel
@onready var _choices_container: HBoxContainer = %ChoicesContainer

# Preload font (non-blocking in @onready)
var _koei_font: Font = null

func _ready() -> void:
	# Load font safely
	if ResourceLoader.exists("res://fonts/Cinzel-Regular.ttf"):
		_koei_font = load("res://fonts/Cinzel-Regular.ttf")
		if _koei_font and is_instance_valid(_message_label):
			_message_label.add_theme_font_override("font", _koei_font)
	
	_apply_theme()
	_clear_choices()

func _apply_theme() -> void:
	if not is_instance_valid(_message_label):
		return
	_message_label.add_theme_color_override("font_color", Color("#f5f5dc"))

func _notification(what: int) -> void:
	# Clean up tween when node is freed
	if what == NOTIFICATION_PREDELETE:
		if _typing_tween and _typing_tween.is_valid():
			_typing_tween.kill()

# Public API

func show_message(text: String, play_sound: bool = true) -> void:
	if not is_instance_valid(self):
		return
		
	_clear_choices()
	_full_text = text
	_current_message = ""
	_message_label.text = ""
	
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
	_choices_container.visible = true

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
	_message_label.text = prompt_text
	_is_typing = false

func clear() -> void:
	_full_text = ""
	_current_message = ""
	if is_instance_valid(_message_label):
		_message_label.text = ""
	_clear_choices()
	_is_typing = false
	
	if _typing_tween and _typing_tween.is_valid():
		_typing_tween.kill()
		_typing_tween = null

func skip_typing() -> void:
	if _is_typing:
		if _typing_tween and _typing_tween.is_valid():
			_typing_tween.kill()
		_current_message = _full_text
		_message_label.text = _full_text
		_is_typing = false
		
		# Only emit if we have listeners
		if message_completed.get_connections().size() > 0:
			message_completed.emit()

# Internal methods

func _start_typewriter() -> void:
	# Kill existing tween safely
	if _typing_tween and _typing_tween.is_valid():
		_typing_tween.kill()
	
	_typing_tween = create_tween()
	_typing_tween.set_trans(Tween.TRANS_LINEAR)
	
	var char_count: int = _full_text.length()
	for i in range(char_count):
		_typing_tween.tween_callback(_add_character.bind(i))
		_typing_tween.tween_interval(display_speed)
	
	_typing_tween.tween_callback(_finish_typing)

func _add_character(index: int) -> void:
	if not is_instance_valid(self) or not is_instance_valid(_message_label):
		return
	if index >= _full_text.length():
		return
	_current_message += _full_text[index]
	_message_label.text = _current_message

func _finish_typing() -> void:
	_is_typing = false
	if message_completed.get_connections().size() > 0:
		message_completed.emit()

func _populate_choices(choices: Array[String]) -> void:
	_clear_choices()
	
	for choice in choices:
		var btn := Button.new()
		btn.text = choice
		btn.add_theme_font_size_override("font_size", 20)
		
		# Safe connection with reference counting
		if not btn.pressed.is_connected(_on_choice_pressed):
			btn.pressed.connect(_on_choice_pressed.bind(choice), CONNECT_REFERENCE_COUNTED)
		
		# Style the button
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color("#1a2f3a")
		normal_style.border_width_left = 2
		normal_style.border_width_top = 2
		normal_style.border_width_right = 2
		normal_style.border_width_bottom = 2
		normal_style.border_color = Color("#d4af37")
		btn.add_theme_stylebox_override("normal", normal_style)
		
		_choices_container.add_child(btn)

func _clear_choices() -> void:
	# Fix memory leak: remove children before queue_free
	if not is_instance_valid(_choices_container):
		return
		
	for child in _choices_container.get_children():
		_choices_container.remove_child(child)
		child.queue_free()
	_choices_container.visible = false

func _on_choice_pressed(choice: String) -> void:
	if choice_selected.get_connections().size() > 0:
		choice_selected.emit(choice)

func _play_message_sound() -> void:
	# Placeholder for sound effect integration
	pass

# Input handling - only when focused

func _gui_input(event: InputEvent) -> void:
	if not _is_typing:
		return
		
	if event is InputEventMouseButton:
		if event.pressed:
			skip_typing()
			accept_event()
	elif event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			skip_typing()
			accept_event()
