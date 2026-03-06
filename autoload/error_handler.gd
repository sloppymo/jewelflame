extends Node

enum ErrorType {
	INVALID_PROVINCE,
	INVALID_CHARACTER,
	INSUFFICIENT_RESOURCES,
	INVALID_COMMAND,
	SAVE_LOAD_ERROR,
	NULL_REFERENCE,
	INVALID_FAMILY,
	BATTLE_ERROR,
	SCENE_TRANSITION_ERROR,
	AI_PROCESSING_ERROR
}

static func create_error(type: ErrorType, details: String = "") -> Dictionary:
	var messages = {
		ErrorType.INVALID_PROVINCE: "Invalid province specified",
		ErrorType.INVALID_CHARACTER: "Invalid character specified", 
		ErrorType.INSUFFICIENT_RESOURCES: "Insufficient resources",
		ErrorType.INVALID_COMMAND: "Invalid command",
		ErrorType.SAVE_LOAD_ERROR: "Save/load operation failed",
		ErrorType.NULL_REFERENCE: "Null reference encountered",
		ErrorType.INVALID_FAMILY: "Invalid family specified",
		ErrorType.BATTLE_ERROR: "Battle resolution failed",
		ErrorType.SCENE_TRANSITION_ERROR: "Scene transition failed",
		ErrorType.AI_PROCESSING_ERROR: "AI processing failed"
	}
	
	var base_message = messages.get(type, "Unknown error")
	if not details.is_empty():
		base_message += ": " + details
	
	return {
		"success": false,
		"error_type": type,
		"message": base_message,
		"timestamp": Time.get_unix_time_from_system()
	}

static func create_success(data: Dictionary = {}) -> Dictionary:
	return {
		"success": true,
		"data": data,
		"timestamp": Time.get_unix_time_from_system()
	}

static func log_error(type: ErrorType, details: String = "", context: Dictionary = {}):
	var error_dict = create_error(type, details)
	print("ERROR [%d]: %s" % [error_dict.timestamp, error_dict.message])
	
	if not context.is_empty():
		print("Context: ", context)
	
	push_error(error_dict.message)

static func handle_null_reference(object_name: String, operation: String) -> Dictionary:
	var details = "Null reference in '%s' during '%s'" % [object_name, operation]
	log_error(ErrorType.NULL_REFERENCE, details)
	return create_error(ErrorType.NULL_REFERENCE, details)

static func handle_invalid_province(id: int, operation: String) -> Dictionary:
	var details = "Province ID %d not found in %s" % [id, operation]
	log_error(ErrorType.INVALID_PROVINCE, details)
	return create_error(ErrorType.INVALID_PROVINCE, details)

static func handle_invalid_character(id: String, operation: String) -> Dictionary:
	var details = "Character ID '%s' not found in %s" % [id, operation]
	log_error(ErrorType.INVALID_CHARACTER, details)
	return create_error(ErrorType.INVALID_CHARACTER, details)

static func handle_insufficient_resources(resource_type: String, required: int, available: int) -> Dictionary:
	var details = "Need %d %s, only %d available" % [required, resource_type, available]
	log_error(ErrorType.INSUFFICIENT_RESOURCES, details)
	return create_error(ErrorType.INSUFFICIENT_RESOURCES, details)

static func handle_command_execution(command_name: String, reason: String) -> Dictionary:
	var details = "Command '%s' failed: %s" % [command_name, reason]
	log_error(ErrorType.INVALID_COMMAND, details)
	return create_error(ErrorType.INVALID_COMMAND, details)

static func handle_save_load_error(operation: String, file_path: String, reason: String) -> Dictionary:
	var details = "%s failed for file '%s': %s" % [operation, file_path, reason]
	log_error(ErrorType.SAVE_LOAD_ERROR, details)
	return create_error(ErrorType.SAVE_LOAD_ERROR, details)

static func handle_battle_error(battle_id: String, reason: String) -> Dictionary:
	var details = "Battle '%s' failed: %s" % [battle_id, reason]
	log_error(ErrorType.BATTLE_ERROR, details)
	return create_error(ErrorType.BATTLE_ERROR, details)

static func handle_scene_transition_error(from_scene: String, to_scene: String, reason: String) -> Dictionary:
	var details = "Transition from '%s' to '%s' failed: %s" % [from_scene, to_scene, reason]
	log_error(ErrorType.SCENE_TRANSITION_ERROR, details)
	return create_error(ErrorType.SCENE_TRANSITION_ERROR, details)

static func handle_ai_processing_error(family_id: String, operation: String, reason: String) -> Dictionary:
	var details = "AI processing for family '%s' in '%s' failed: %s" % [family_id, operation, reason]
	log_error(ErrorType.AI_PROCESSING_ERROR, details)
	return create_error(ErrorType.AI_PROCESSING_ERROR, details)

static func is_success(result: Dictionary) -> bool:
	return result.get("success", false)

static func get_error_message(result: Dictionary) -> String:
	if is_success(result):
		return ""
	return result.get("message", "Unknown error")

static func get_error_type(result: Dictionary) -> Variant:
	if is_success(result):
		return null
	return result.get("error_type", null)

static func safe_execute(callable: Callable, error_context: String = "") -> Dictionary:
	var result = callable.call()
	if result is Dictionary and result.has("success"):
		return result
	
	if result == null:
		return handle_null_reference(error_context, "safe_execute")
	
	return create_success({"data": result})
