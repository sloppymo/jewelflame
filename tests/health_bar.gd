class_name HealthBar
extends Control
## A reusable health bar component for combat units.

@onready var outline: ColorRect = %Outline
@onready var background: ColorRect = %Background
@onready var foreground: ColorRect = %Foreground

var _full_width: float = 24.0
var _bar_height: float = 4.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(team: int) -> void:
	## Initializes the health bar with team colors
	foreground.color = Color.GREEN if team == 1 else Color.CYAN

func update(hp: int, max_hp: int, state: ArenaUnit.State = ArenaUnit.State.IDLE) -> void:
	## Updates the health bar display
	var ratio := float(hp) / float(max(max_hp, 1))
	foreground.size.x = _full_width * ratio
	
	# Update color based on health percentage
	var team := 1 if foreground.color.g > foreground.color.b else 2
	if ratio > 0.6:
		foreground.color = Color.GREEN if team == 1 else Color.CYAN
	elif ratio > 0.3:
		foreground.color = Color.ORANGE if team == 1 else Color.BLUE
	else:
		foreground.color = Color.RED if team == 1 else Color.PURPLE
	
	# Update opacity based on combat state
	match state:
		ArenaUnit.State.CHARGE, ArenaUnit.State.ATTACK, ArenaUnit.State.HURT:
			modulate.a = 0.75
		_:
			modulate.a = 1.0

func hide_bar() -> void:
	## Hides the health bar (called when unit dies)
	hide()
