extends Node

# Command History Management

var command_stack: Array = []
var undo_stack: Array = []
var max_history_size: int = 50

func execute_command(command) -> bool:
	if not command.can_execute():
		print("Command cannot be executed: ", command.get_description())
		return false
	
	command.execute()
	command_stack.append(command)
	undo_stack.clear()  # Clear redo stack when new command is executed
	
	# Limit history size
	if command_stack.size() > max_history_size:
		command_stack.pop_front()
	
	print("Executed: ", command.get_description())
	EventBus.CommandExecuted.emit(command)
	return true

func undo_last_command() -> bool:
	if command_stack.is_empty():
		print("No commands to undo")
		return false
	
	var command = command_stack.pop_back()
	command.undo()
	undo_stack.append(command)
	
	print("Undone: ", command.get_description())
	EventBus.CommandUndone.emit(command)
	return true

func redo_last_command() -> bool:
	if undo_stack.is_empty():
		print("No commands to redo")
		return false
	
	var command = undo_stack.pop_back()
	command.redo()
	command_stack.append(command)
	
	print("Redone: ", command.get_description())
	EventBus.CommandRedone.emit(command)
	return true

func get_command_history() -> Array[String]:
	var descriptions = []
	for command in command_stack:
		descriptions.append(command.get_description())
	return descriptions

func clear_history():
	command_stack.clear()
	undo_stack.clear()
