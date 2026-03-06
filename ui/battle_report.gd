extends AcceptDialog

@onready var result_label: RichTextLabel = $VBox/ResultLabel

func _ready():
	exclusive = true
	title = "Battle Report"

func show_battle_report(result: Dictionary, attacker_name: String, defender_name: String):
	var report_text = ""
	
	if result.attacker_won:
		report_text = "[color=green]VICTORY![/color]\n\n"
		report_text += "%s [color=green]defeated[/color] %s!\n\n" % [attacker_name, defender_name]
		
		if result.province_conquered:
			report_text += "[color=yellow]Province Conquered![/color]\n\n"
		
		if result.prisoner_taken:
			report_text += "[color=cyan]Governor Captured![/color]\n\n"
	else:
		report_text = "[color=red]DEFEAT![/color]\n\n"
		report_text += "%s [color=red]was defeated by[/color] %s!\n\n" % [attacker_name, defender_name]
	
	# Battle details
	report_text += "[b]Battle Details:[/b]\n"
	report_text += "Attacker Power: %.1f\n" % result.attacker_power
	report_text += "Defender Power: %.1f\n\n" % result.defender_power
	
	# Casualties
	report_text += "[b]Casualties:[/b]\n"
	report_text += "%s: %d soldiers lost\n" % [attacker_name, result.attacker_casualties]
	report_text += "%s: %d soldiers lost\n\n" % [defender_name, result.defender_casualties]
	
	# Loot and gains
	if result.attacker_won and result.province_conquered:
		report_text += "[b]Loot:[/b]\n"
		report_text += "Gold: +%d\n" % result.loot_gold
		report_text += "Food: +%d\n\n" % result.loot_food
	
	# Remaining forces
	report_text += "[b]Remaining Forces:[/b]\n"
	report_text += "%s: %d soldiers\n" % [attacker_name, result.remaining_attackers]
	report_text += "%s: %d soldiers" % [defender_name, result.remaining_defenders]
	
	dialog_text = report_text
	
	# Show dialog
	popup_centered()
