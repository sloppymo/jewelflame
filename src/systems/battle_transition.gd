extends Node
## Handles transition from Strategic Map to Tactical Combat
## Passes army data, initializes battle, returns results

signal battle_complete(result: Dictionary)

const TACTICAL_SCENE_PATH: String = "res://scenes/combat/mass_battle.tscn"

var pending_battle: Dictionary = {}
var return_to_strategic: bool = true

func initiate_battle(
	attacker_province: StringName,
	defender_province: StringName,
	attacker_faction: StringName,
	defender_faction: StringName
) -> void:
	## Store battle context and load tactical scene
	
	var attacker_province_data = GameState.provinces.get(attacker_province)
	var defender_province_data = GameState.provinces.get(defender_province)
	
	if not attacker_province_data or not defender_province_data:
		push_error("BattleTransition: Invalid province IDs")
		return
	
	pending_battle = {
		"attacker_province": attacker_province,
		"defender_province": defender_province,
		"attacker_faction": attacker_faction,
		"defender_faction": defender_faction,
		"attacker_troops": attacker_province_data.troops,
		"defender_troops": defender_province_data.troops,
		"attacker_hero": _get_hero_for_province(attacker_province),
		"defender_hero": _get_hero_for_province(defender_province)
	}
	
	print("BattleTransition: Loading tactical battle...")
	print("  %s (%d troops) vs %s (%d troops)" % [
		attacker_province_data.province_name, pending_battle.attacker_troops,
		defender_province_data.province_name, pending_battle.defender_troops
	])
	
	# Store in GameState for the battle scene to access
	GameState.current_battle = pending_battle.duplicate()
	
	# Change to tactical scene
	get_tree().change_scene_to_file(TACTICAL_SCENE_PATH)

func _get_hero_for_province(province_id: StringName) -> HeroData:
	## Get hero assigned to province (if any)
	# Check if province has a governor
	var province = GameState.provinces.get(province_id)
	if province and province.get("governor_id") and not province.governor_id.is_empty():
		var char_data = GameState.characters.get(province.governor_id)
		if char_data:
			return HeroData.from_character(char_data)
	return null

func return_to_strategic_map(battle_result: Dictionary) -> void:
	## Process battle result and return to strategic layer
	var result: Dictionary = battle_result.duplicate()
	result.merge(pending_battle, true)
	
	# Apply casualties to armies
	_apply_battle_casualties(result)
	
	# Transfer province if attacker won
	if result.get("winner") == "attacker" or result.get("attacker_won", false):
		GameState.transfer_province_ownership(
			pending_battle.defender_province,
			pending_battle.defender_faction,
			pending_battle.attacker_faction
		)
		# Move surviving attackers to captured province
		_transfer_survivors(result)
	
	# Award hero experience
	_award_hero_experience(result)
	
	# Clear pending battle
	pending_battle.clear()
	GameState.current_battle.clear()
	
	# Return to strategic map
	var strategic = load("res://main_strategic.tscn").instantiate()
	var current = get_tree().current_scene
	get_tree().root.add_child(strategic)
	get_tree().current_scene = strategic
	if current:
		current.queue_free()
	
	# Emit completion signal
	battle_complete.emit(result)

func _apply_battle_casualties(result: Dictionary) -> void:
	## Reduce army sizes based on battle casualties
	var attacker_province_data = GameState.provinces.get(pending_battle.attacker_province)
	var defender_province_data = GameState.provinces.get(pending_battle.defender_province)
	
	if attacker_province_data:
		var attacker_losses: int = result.get("attacker_losses", 0)
		attacker_province_data.troops = max(10, attacker_province_data.troops - attacker_losses)
	
	if defender_province_data:
		var defender_losses: int = result.get("defender_losses", 0)
		defender_province_data.troops = max(10, defender_province_data.troops - defender_losses)

func _transfer_survivors(result: Dictionary) -> void:
	## Move surviving attackers to captured province
	var attacker_remaining: int = result.get("attacker_remaining", 0)
	if attacker_remaining <= 0:
		return
	
	var target_province_data = GameState.provinces.get(pending_battle.defender_province)
	if target_province_data:
		# Surviving troops occupy the province
		target_province_data.troops = max(10, attacker_remaining / 2)

func _award_hero_experience(result: Dictionary) -> void:
	## Award XP to heroes based on battle outcome
	var winner: String = result.get("winner", "")
	if result.get("attacker_won", false):
		winner = "attacker"
	elif result.get("defender_won", false):
		winner = "defender"
	
	var attacker_hero: HeroData = pending_battle.attacker_hero
	var defender_hero: HeroData = pending_battle.defender_hero
	
	if attacker_hero and winner == "attacker":
		attacker_hero.add_experience(50)
		print("Hero %s gained 50 XP" % attacker_hero.name)
	elif attacker_hero:
		attacker_hero.add_experience(10)  # Participation XP
	
	if defender_hero and winner == "defender":
		defender_hero.add_experience(50)
		print("Hero %s gained 50 XP" % defender_hero.name)
	elif defender_hero:
		defender_hero.add_experience(10)

## Data class for hero information
class HeroData:
	var hero_id: String
	var name: String
	var faction: StringName
	var location: String  # Province name
	var level: int = 1
	var experience: int = 0
	var max_hp: int = 200
	var current_hp: int = 200
	var strength: int = 10
	var intelligence: int = 10
	var agility: int = 10
	
	const XP_PER_LEVEL: int = 100
	
	func _init(id: String, hero_name: String, f: StringName, loc: String) -> void:
		hero_id = id
		name = hero_name
		faction = f
		location = loc
	
	## Create HeroData from existing CharacterData
	static func from_character(char_data) -> HeroData:
		var hero = HeroData.new(
			char_data.get("id", "unknown"),
			char_data.get("name", "Unknown"),
			char_data.get("family_id", &"neutral"),
			char_data.get("location", "")
		)
		hero.level = char_data.get("level", 1)
		# Map other stats if available
		if char_data.get("stats"):
			hero.strength = char_data.stats.get("str", 10)
			hero.intelligence = char_data.stats.get("int", 10)
			hero.agility = char_data.stats.get("agi", 10)
		return hero
	
	func add_experience(amount: int) -> void:
		experience += amount
		_check_level_up()
	
	func _check_level_up() -> void:
		while experience >= XP_PER_LEVEL * level:
			experience -= XP_PER_LEVEL * level
			level += 1
			_level_up_stats()
			print("Hero %s leveled up to %d!" % [name, level])
	
	func _level_up_stats() -> void:
		max_hp += 20
		current_hp = max_hp
		strength += 2
		intelligence += 1
		agility += 1
	
	func get_battle_bonus() -> float:
		## Returns bonus multiplier for army power (0.0 - 0.5)
		var base_bonus: float = 0.1
		var level_bonus: float = level * 0.02
		return base_bonus + level_bonus
