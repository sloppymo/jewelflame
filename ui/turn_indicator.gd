extends Panel

@onready var month_label: Label = $MonthLabel
@onready var year_label: Label = $YearLabel
@onready var family_label: Label = $FamilyLabel

func _ready():
    EventBus.TurnEnded.connect(_on_turn_ended)
    _update_display()

func _on_turn_ended(month: int, year: int):
    _update_display()

func _update_display():
    month_label.text = _get_month_name(EnhancedGameState.current_month)
    year_label.text = "Year %d" % EnhancedGameState.current_year
    var current_family = EnhancedGameState.get_current_family()
    family_label.text = "Current: %s" % current_family.capitalize()
    family_label.modulate = EnhancedGameState.families[current_family].color

func _get_month_name(month: int) -> String:
    var names = ["", "January", "February", "March", "April", "May", "June", 
                 "July", "August", "September", "October", "November", "December"]
    return names[month]
