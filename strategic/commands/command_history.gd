extends Node

# Command History Management
class_name CommandHistory

var command_stack: Array[BaseCommand] = []
var undo_stack: Array[BaseCommand] = []
var max_history_size: int = 50

func execute_command(command: BaseCommand) -> bool:
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

# Command Factory
class CommandFactory:
	
	static func create_move_command(lord_id: String, from_province: int, to_province: int) -> MoveLordCommand:
		return MoveLordCommand.new(lord_id, from_province, to_province)

	static func create_attack_command(attacker_province: int, defender_province: int, units: Array, lord_id: String = "") -> AttackProvinceCommand:
		return AttackProvinceCommand.new(attacker_province, defender_province, units, lord_id)

	static func create_recruit_command(province_id: int, lord_id: String, action: String = "recruit") -> RecruitVassalCommand:
		return RecruitVassalCommand.new(province_id, lord_id, action)

	static func create_develop_command(province_id: int, development_type: String) -> DevelopCommand:
		return DevelopCommand.new(province_id, development_type)

	static func create_transport_command(from_province: int, to_province: int, resource_type: String, amount: int) -> TransportCommand:
		return TransportCommand.new(from_province, to_province, resource_type, amount)
