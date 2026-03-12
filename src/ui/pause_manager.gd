extends Node
class_name PauseManager

# Singleton pattern - autoload this in Project Settings

# Stack of pause sources
var _pause_stack: Array[String] = []
var _is_paused: bool = false

signal pause_changed(is_paused: bool)
signal source_pushed(source: String)
signal source_popped(source: String)

## Pushes a pause source onto the stack and pauses the game
func push_pause(source: String) -> void:
	if source in _pause_stack:
		push_warning("Pause source '%s' already in stack" % source)
		return
	
	_pause_stack.append(source)
	_update_pause_state()
	source_pushed.emit(source)
	print("Pause pushed: %s (stack: %s)" % [source, _pause_stack])

## Pops a pause source from the stack
func pop_pause(source: String) -> void:
	if not source in _pause_stack:
		push_warning("Pause source '%s' not found in stack" % source)
		return
	
	_pause_stack.erase(source)
	_update_pause_state()
	source_popped.emit(source)
	print("Pause popped: %s (stack: %s)" % [source, _pause_stack])

## Checks if a specific source is currently pausing
func is_paused_by(source: String) -> bool:
	return source in _pause_stack

## Gets the current pause stack (for debugging)
func get_pause_stack() -> Array[String]:
	return _pause_stack.duplicate()

## Clears all pause sources (use with caution)
func clear_all() -> void:
	_pause_stack.clear()
	_update_pause_state()

func _update_pause_state() -> void:
	var should_pause = _pause_stack.size() > 0
	if should_pause != _is_paused:
		_is_paused = should_pause
		get_tree().paused = _is_paused
		pause_changed.emit(_is_paused)
		print("Game %s" % ("paused" if _is_paused else "resumed"))

## Ensures game is unpaused even if stack is corrupted
func force_unpause() -> void:
	_pause_stack.clear()
	_is_paused = false
	get_tree().paused = false
	pause_changed.emit(false)
	push_warning("Force unpaused - pause stack was cleared")
