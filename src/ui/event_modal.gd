extends PanelContainer
class_name EventModal

enum ModalType {
	VICTORY,
	DEFEAT,
	DEATH,
	ALLIANCE,
	CAPTURE,
	SEASON,
	STORY
}

# Signals
signal dismissed
signal choice_made(choice: String)

# Configuration
@export var fade_in_duration: float = 0.3
@export var scale_in_duration: float = 0.2

# State
var _current_type: ModalType
var _pause_id: String = "event_modal"

# Node references
@onready var overlay: ColorRect = %Overlay
@onready var modal_panel: PanelContainer = %ModalPanel
@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var icon_texture: TextureRect = %IconTexture
@onready var continue_button: Button = %ContinueButton
@onready var choices_container: VBoxContainer = %ChoicesContainer
@onready var animation_player: AnimationPlayer = %AnimationPlayer

func _ready():
	visible = false
	_setup_animations()

func _setup_animations() -> void:
	# Create fade in animation
	var anim := Animation.new()
	anim.length = fade_in_duration + scale_in_duration
	
	# Fade in overlay
	var track_idx := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "%Overlay:color:a")
	anim.track_insert_key(track_idx, 0.0, 0.0)
	anim.track_insert_key(track_idx, fade_in_duration, 0.7)
	
	# Scale in modal
	track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "%ModalPanel:scale")
	anim.track_insert_key(track_idx, 0.0, Vector2(0.9, 0.9))
	anim.track_insert_key(track_idx, fade_in_duration + scale_in_duration, Vector2(1.0, 1.0))
	
	# Fade in modal opacity
	track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "%ModalPanel:modulate:a")
	anim.track_insert_key(track_idx, 0.0, 0.0)
	anim.track_insert_key(track_idx, fade_in_duration + scale_in_duration, 1.0)
	
	animation_player.add_animation("appear", anim)
	
	# Create fade out animation
	anim = Animation.new()
	anim.length = 0.2
	
	track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "%ModalPanel:modulate:a")
	anim.track_insert_key(track_idx, 0.0, 1.0)
	anim.track_insert_key(track_idx, 0.2, 0.0)
	
	track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "%Overlay:color:a")
	anim.track_insert_key(track_idx, 0.0, 0.7)
	anim.track_insert_key(track_idx, 0.2, 0.0)
	
	animation_player.add_animation("disappear", anim)

# Public API

func show_event(event_type: ModalType, data: Dictionary) -> void:
	_current_type = event_type
	
	# Set content based on type
	match event_type:
		ModalType.VICTORY:
			_setup_victory(data)
		ModalType.DEFEAT:
			_setup_defeat(data)
		ModalType.DEATH:
			_setup_death(data)
		ModalType.ALLIANCE:
			_setup_alliance(data)
		ModalType.CAPTURE:
			_setup_capture(data)
		ModalType.SEASON:
			_setup_season(data)
		ModalType.STORY:
			_setup_story(data)
	
	# Reset state
	continue_button.visible = true
	_clear_choices()
	
	# Show and animate
	visible = true
	animation_player.play("appear")
	
	# Use PauseManager instead of direct pause
	if PauseManager:
		PauseManager.push_pause(_pause_id)

func show_event_with_choices(event_type: ModalType, data: Dictionary, choices: Array[String]) -> void:
	show_event(event_type, data)
	
	# Hide continue button, show choices
	continue_button.visible = false
	_populate_choices(choices)

# Setup methods

func _setup_victory(data: Dictionary) -> void:
	title_label.text = "🛡️ VICTORY! 🛡️"
	body_label.text = "The Battle of %s\nhas been won!\n\nEnemy troops defeated: %d\nYour losses: %d\n\nProvince loyalty +%d%%" % [
		data.get("battle_name", "Unknown"),
		data.get("enemy_losses", 0),
		data.get("player_losses", 0),
		data.get("loyalty_boost", 0)
	]
	continue_button.text = "Accept Spoils"
	_play_sound("fanfare_victory")

func _setup_defeat(data: Dictionary) -> void:
	title_label.text = "⚔️ DEFEAT... ⚔️"
	body_label.text = "The Battle of %s\nhas been lost.\n\nYour forces were overwhelmed.\nTroops lost: %d\n\nRetreat to %s?" % [
		data.get("battle_name", "Unknown"),
		data.get("player_losses", 0),
		data.get("retreat_province", "nearest castle")
	]
	continue_button.text = "Retreat"
	_play_sound("fanfare_defeat")

func _setup_death(data: Dictionary) -> void:
	title_label.text = "✝️ FALLEN ✝️"
	
	var portrait = data.get("portrait") as Texture2D
	if portrait:
		icon_texture.texture = portrait
		icon_texture.modulate = Color(0.5, 0.5, 0.5)
	
	body_label.text = "%s\n%s\n\nHas fallen in battle.\n\nYears of service: %d\nAge: %d\n\n\"%s\"" % [
		data.get("name", "Unknown"),
		data.get("title", ""),
		data.get("years_of_service", 0),
		data.get("age", 0),
		data.get("last_words", "For the realm...")
	]
	continue_button.text = "Honor Their Memory"
	_play_sound("bell_toll")

func _setup_alliance(data: Dictionary) -> void:
	title_label.text = "🤝 ALLIANCE FORMED 🤝"
	body_label.text = "You have formed an alliance\nwith %s!\n\nTerms: %s\nDuration: %s turns\n\nTrade bonus: +%d%%\nMilitary support: Available" % [
		data.get("faction_name", "Unknown"),
		data.get("terms", "Mutual defense"),
		data.get("duration", 10),
		data.get("trade_bonus", 15)
	]
	continue_button.text = "Seal the Agreement"
	_play_sound("fanfare_alliance")

func _setup_capture(data: Dictionary) -> void:
	title_label.text = "🏰 PROVINCE CAPTURED 🏰"
	body_label.text = "%s has been conquered!\n\nPrevious owner: %s\nNew monthly income: %d gold\nGarrison capacity: %d troops\n\nThe people await your rule." % [
		data.get("province_name", "Unknown"),
		data.get("previous_owner", "Unknown"),
		data.get("income", 0),
		data.get("garrison_capacity", 0)
	]
	continue_button.text = "Claim Victory"
	_play_sound("fanfare_capture")

func _setup_season(data: Dictionary) -> void:
	var season_icons: Dictionary = {
		"spring": "🌸", "summer": "☀️", "autumn": "🍂", "winter": "❄️"
	}
	var season: String = data.get("season", "spring")
	title_label.text = "%s Year %d, %s" % [season_icons.get(season, ""), data.get("year", 1), season.capitalize()]
	
	var season_texts: Dictionary = {
		"spring": "The snow melts and the fields awaken. A time for planting and renewed vigor.",
		"summer": "The sun beats down upon the land. Armies march and crops ripen in the fields.",
		"autumn": "The harvest is gathered and the air grows crisp. A time of plenty... or preparation.",
		"winter": "Snow blankets the realm. Armies huddle in their castles, waiting for spring."
	}
	
	body_label.text = "%s\n\n%s" % [data.get("flavor_text", season_texts.get(season, "")), data.get("upcoming_events", "")]
	continue_button.text = "Begin %s" % season.capitalize()
	_play_sound("ambient_%s" % season)

func _setup_story(data: Dictionary) -> void:
	title_label.text = data.get("title", "📜 Story 📜")
	body_label.text = data.get("text", "")
	continue_button.text = data.get("button_text", "Continue")
	_play_sound(data.get("sound", "story_reveal"))

# Event handlers

func _on_continue_pressed() -> void:
	_dismiss()

func _on_choice_made(choice: String) -> void:
	choice_made.emit(choice)
	_dismiss()

func _dismiss() -> void:
	animation_player.play("disappear")
	await animation_player.animation_finished
	
	if not is_instance_valid(self):
		return
	
	visible = false
	
	# Use PauseManager to unpause
	if PauseManager:
		PauseManager.pop_pause(_pause_id)
	
	# Clean up
	_clear_choices()
	icon_texture.modulate = Color.WHITE
	continue_button.visible = true
	
	dismissed.emit()

# Helper methods

func _populate_choices(choices: Array[String]) -> void:
	_clear_choices()
	
	for choice in choices:
		var btn := Button.new()
		btn.text = choice
		btn.custom_minimum_size = Vector2(300, 40)
		btn.pressed.connect(_on_choice_made.bind(choice))
		
		# Style
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color("#1a2f3a")
		normal_style.border_width_left = 2
		normal_style.border_width_top = 2
		normal_style.border_width_right = 2
		normal_style.border_width_bottom = 2
		normal_style.border_color = Color("#d4af37")
		btn.add_theme_stylebox_override("normal", normal_style)
		
		choices_container.add_child(btn)
	
	choices_container.visible = true

func _clear_choices() -> void:
	# Fix memory leak
	for child in choices_container.get_children():
		choices_container.remove_child(child)
		child.queue_free()
	choices_container.visible = false

func _play_sound(sound_name: String) -> void:
	# Placeholder
	pass
