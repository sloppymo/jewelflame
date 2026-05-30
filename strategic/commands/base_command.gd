# Base Command Class for Undo/Redo Support
class_name BaseCommand extends Resource

var command_id: String = ""
var command_name: String = ""
var timestamp: int = 0
var is_executed: bool = false
var execution_data: Dictionary = {}

# Virtual methods to be overridden by concrete commands
func can_execute() -> Dictionary:
	return ErrorHandler.create_error(ErrorHandler.ErrorType.INVALID_COMMAND, "can_execute() must be implemented by subclass")

func execute() -> Dictionary:
	return ErrorHandler.create_error(ErrorHandler.ErrorType.INVALID_COMMAND, "execute() must be implemented by subclass")

func undo() -> Dictionary:
	return ErrorHandler.create_error(ErrorHandler.ErrorType.INVALID_COMMAND, "undo() must be implemented by subclass")

func get_description() -> String:
	return command_name

func save_state() -> Dictionary:
	# Save current state for undo
	try:
		execution_data = EnhancedGameState.get_save_data()
		return ErrorHandler.create_success()
	except:
		return ErrorHandler.handle_save_load_error("save_state", "execution_data", "Failed to save game state")

func restore_state() -> Dictionary:
	# Restore saved state for undo
	try:
		EnhancedGameState.load_save_data(execution_data)
		return ErrorHandler.create_success()
	except:
		return ErrorHandler.handle_save_load_error("restore_state", "execution_data", "Failed to restore game state")

func redo() -> Dictionary:
	return execute()

func validate_resources() -> Dictionary:
	return ErrorHandler.create_success()

func validate_inputs() -> Dictionary:
	# Base validation - override in subclasses for specific validation
	if command_id.is_empty():
		return ErrorHandler.handle_command_execution(command_name, "Command ID cannot be empty")
	if command_name.is_empty():
		return ErrorHandler.handle_command_execution(command_name, "Command name cannot be empty")
	return ErrorHandler.create_success()

func safe_execute() -> Dictionary:
	# Wrapper that handles validation and error reporting
	var validation_result = validate_inputs()
	if not ErrorHandler.is_success(validation_result):
		return validation_result
	
	var can_execute_result = can_execute()
	if not ErrorHandler.is_success(can_execute_result):
		return can_execute_result
	
	var save_result = save_state()
	if not ErrorHandler.is_success(save_result):
		return save_result
	
	var execute_result = execute()
	if ErrorHandler.is_success(execute_result):
		is_executed = true
	
	return execute_result
