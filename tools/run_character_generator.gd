# run_character_generator.gd
#
# Purpose: Standalone runner for the character generator
# Usage: Open this scene in Godot and press F5 to run

extends Node2D

@onready var log_label: Label = $LogLabel

func _ready():
	_log("Starting Character Generator...")
	
	# Run the generator
	var generator = preload("res://tools/gen_tiny_rpg_characters.gd").new()
	generator._run()
	
	_log("\nGeneration complete!")
	_log("Check Output panel for details.")
	_log("\nPress any key to close...")

func _log(text: String) -> void:
	print(text)
	if log_label:
		log_label.text += text + "\n"
