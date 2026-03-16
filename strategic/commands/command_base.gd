class_name Command
extends RefCounted

# Base class for all game commands
# Implements the Command pattern for undo/redo functionality

enum Status {
	PENDING,
	EXECUTED,
	UNDONE,
	FAILED
}

var status: Status = Status.PENDING
var command_name: String = "Unknown"
var timestamp: int = 0

func _init() -> void:
	timestamp = Time.get_ticks_msec()

# Execute the command. Returns true on success.
func execute() -> bool:
	push_error("Command.execute() must be overridden")
	return false

# Undo the command. Returns true on success.
func undo() -> bool:
	push_error("Command.undo() must be overridden")
	return false

# Get a description of what this command does
func get_description() -> String:
	return command_name

# Get the cost of this command (gold, etc.)
func get_cost() -> int:
	return 0
