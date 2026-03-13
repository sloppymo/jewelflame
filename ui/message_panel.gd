class_name MessagePanel
extends NinePatchRect

# MessagePanel - Bottom panel for typewriter-style game messages
# Inspired by Gemfire's message display

signal message_completed()
signal message_skipped()

@export var typewriter_speed: float = 0.03  # Seconds per character
@export var panel_height: float = 120.0

@onready var message_label: RichTextLabel = %MessageLabel
@onready var continue_indicator: Control = %ContinueIndicator

var _full_text: String = ""
var _current_char: int = 0
var _is_typing: bool = false
var _typewriter_timer: Timer = null

func _ready():
	# Force nearest texture filter for pixel-perfect rendering
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	_setup_typewriter_timer()
	_hide_continue_indicator()
	clear_message()

func _setup_typewriter_timer():
	_typewriter_timer = Timer.new()
	_typewriter_timer.one_shot = false
	_typewriter_timer.timeout.connect(_on_typewriter_tick)
	add_child(_typewriter_timer)

func _input(event):
	# Skip typewriter effect on any input during typing
	if _is_typing and event is InputEventMouseButton:
		if event.pressed:
			_skip_to_end()

func show_message(text: String, use_typewriter: bool = true) -> void:
	"""Display a message with optional typewriter effect."""
	_full_text = text
	_current_char = 0
	
	if use_typewriter:
		_start_typewriter()
	else:
		message_label.text = _full_text
		_show_continue_indicator()
		message_completed.emit()

func show_message_with_choices(text: String, choices: Array[String]) -> void:
	"""Display a message with choice buttons."""
	show_message(text, false)
	# TODO: Add choice buttons dynamically
	# For now, just show the text

func clear_message() -> void:
	"""Clear the message panel."""
	_full_text = ""
	_current_char = 0
	_is_typing = false
	message_label.text = ""
	_hide_continue_indicator()

func _start_typewriter() -> void:
	"""Start the typewriter effect."""
	_is_typing = true
	message_label.text = ""
	_hide_continue_indicator()
	_typewriter_timer.start(typewriter_speed)

func _on_typewriter_tick() -> void:
	"""Add next character during typewriter effect."""
	if _current_char < _full_text.length():
		_current_char += 1
		message_label.text = _full_text.substr(0, _current_char)
	else:
		_finish_typing()

func _skip_to_end() -> void:
	"""Skip typewriter effect and show full message."""
	if _is_typing:
		_typewriter_timer.stop()
		message_label.text = _full_text
		_finish_typing()
		message_skipped.emit()

func _finish_typing() -> void:
	"""Complete the typewriter effect."""
	_is_typing = false
	_typewriter_timer.stop()
	_show_continue_indicator()
	message_completed.emit()

func _show_continue_indicator() -> void:
	if continue_indicator:
		continue_indicator.visible = true

func _hide_continue_indicator() -> void:
	if continue_indicator:
		continue_indicator.visible = false

func is_typing() -> bool:
	return _is_typing
