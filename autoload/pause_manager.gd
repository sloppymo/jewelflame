extends Node

# PauseManager - Centralized pause system for the game
# Handles modal dialogs, pause states, and game speed control

signal pause_state_changed(is_paused: bool)

var _pause_stack: Array[String] = []
var _is_paused: bool = false

func _ready():
	print("PauseManager initialized")

func pause_game(reason: String = "default") -> void:
	"""Pause the game with a given reason."""
	if not _pause_stack.has(reason):
		_pause_stack.append(reason)
		_update_pause_state()

func unpause_game(reason: String = "default") -> void:
	"""Unpause the game for a specific reason."""
	if _pause_stack.has(reason):
		_pause_stack.erase(reason)
		_update_pause_state()

func force_unpause() -> void:
	"""Force unpause regardless of stack."""
	_pause_stack.clear()
	_update_pause_state()

func is_paused() -> bool:
	"""Check if game is currently paused."""
	return _is_paused

func _update_pause_state() -> void:
	var should_pause = _pause_stack.size() > 0
	if should_pause != _is_paused:
		_is_paused = should_pause
		get_tree().paused = _is_paused
		pause_state_changed.emit(_is_paused)
		print("Game ", "paused" if _is_paused else "unpaused", 
			" (reasons: " + ", ".join(_pause_stack) + ")" if _is_paused else "")

# Convenience methods for common pause reasons
func pause_for_modal() -> void:
	pause_game("modal")

func unpause_from_modal() -> void:
	unpause_game("modal")

func pause_for_event() -> void:
	pause_game("event")

func unpause_from_event() -> void:
	unpause_game("event")
