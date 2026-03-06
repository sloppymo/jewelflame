extends AcceptDialog

@onready var result_label: RichTextLabel = $VBox/ResultLabel

func _ready():
	exclusive = true
	title = "September Harvest Report"
	add_to_group("harvest_report")

func show_harvest_report(province_yields: Dictionary):
	var report_text = "[b]September Harvest Results[/b]\n\n"
	var total_yield = 0
	
	# List each province's harvest
	for province_id in province_yields:
		var province = GameState.provinces[province_id]
		var yield = province_yields[province_id]
		total_yield += yield
		
		report_text += "%s: [color=green]+%d[/color] food\n" % [province.name, yield]
	
	# Total summary
	report_text += "\n[b]Total Harvest: %d food[/b]" % total_yield
	
	dialog_text = report_text
	
	# Show dialog
	popup_centered()
