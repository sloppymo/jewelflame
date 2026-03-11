## UI Button Integration for ProvincePanel
## Use these TextureButtons in your Godot UI

extends Control

# Button texture references
@export var btn_crops: Texture2D
@export var btn_banner: Texture2D
@export var btn_helmet: Texture2D
@export var btn_crown: Texture2D
@export var btn_bread: Texture2D
@export var btn_gold: Texture2D
@export var btn_catapult: Texture2D
@export var btn_worker: Texture2D
@export var btn_diplomacy: Texture2D
@export var btn_scout: Texture2D

func _create_action_buttons() -> void:
	"""Create TextureButton nodes with the chopped assets."""
	
	var button_configs = [
		{"name": "RecruitBtn", "texture": btn_crops, "tooltip": "Recruit Troops"},
		{"name": "DevelopBtn", "texture": btn_worker, "tooltip": "Develop Province"},
		{"name": "AttackBtn", "texture": btn_catapult, "tooltip": "Attack"},
		{"name": "DiplomacyBtn", "texture": btn_diplomacy, "tooltip": "Diplomacy"},
		{"name": "ScoutBtn", "texture": btn_scout, "tooltip": "Scout"},
	]
	
	var container = HBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 8)
	
	for config in button_configs:
		var btn = TextureButton.new()
		btn.name = config.name
		btn.texture_normal = config.texture
		btn.texture_pressed = config.texture  # Could use darker variant
		btn.texture_hover = config.texture    # Could use lighter variant
		btn.tooltip_text = config.tooltip
		btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		# Set fixed size for consistency
		btn.custom_minimum_size = Vector2(64, 64)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		
		# Connect signal
		btn.pressed.connect(_on_action_button_pressed.bind(config.name))
		
		container.add_child(btn)
	
	add_child(container)

func _on_action_button_pressed(button_name: String) -> void:
	match button_name:
		"RecruitBtn":
			print("Recruit action")
		"DevelopBtn":
			print("Develop action")
		"AttackBtn":
			print("Attack action")
		"DiplomacyBtn":
			print("Diplomacy action")
		"ScoutBtn":
			print("Scout action")

## Alternative: Use in ProvincePanel resource grid
func _create_resource_icons() -> void:
	"""Use icons as TextureRect nodes in resource display."""
	
	var resources = [
		{"icon": btn_gold, "label": "Gold", "value": "100"},
		{"icon": btn_bread, "label": "Food", "value": "50"},
		{"icon": btn_crown, "label": "Influence", "value": "10"},
		{"icon": btn_banner, "label": "Banners", "value": "5"},
	]
	
	var grid = GridContainer.new()
	grid.columns = 2
	
	for res in resources:
		var row = HBoxContainer.new()
		
		var icon = TextureRect.new()
		icon.texture = res.icon
		icon.custom_minimum_size = Vector2(32, 32)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var label = Label.new()
		label.text = "%s: %s" % [res.label, res.value]
		
		row.add_child(icon)
		row.add_child(label)
		grid.add_child(row)
	
	add_child(grid)
