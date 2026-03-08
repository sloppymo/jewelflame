extends Node

# Battle Launcher - Connects Strategic Map to Tactical Battle
# Call launch_battle() from province_panel.gd when Attack is clicked

const TacticalBattleScene = preload("res://scenes/tactical/tactical_battle.tscn")

# Store pre-battle state for return
var previous_scene_path: String = ""
var battle_result: Dictionary = {}
var callback_callable: Callable = Callable()

func launch_battle(attacker_province_id: int, defender_province_id: int, 
				   attacker_force_percent: float = 0.7,
				   return_callback: Callable = Callable()) -> void:
	"""
	Launch tactical battle between two provinces.
	
	Parameters:
		attacker_province_id: ID of attacking province
		defender_province_id: ID of defending province  
		attacker_force_percent: Percentage of troops to commit (0.0-1.0)
		return_callback: Optional callback when battle ends (receives result dict)
	"""
	
	callback_callable = return_callback
	
	var attacker_province = GameState.provinces.get(attacker_province_id)
	var defender_province = GameState.provinces.get(defender_province_id)
	
	if not attacker_province or not defender_province:
		push_error("BattleLauncher: Invalid province IDs")
		return
	
	# Build attacker data
	var attacker_lord = _get_province_lord(attacker_province)
	var attacker_units = _build_unit_stacks(attacker_province, attacker_force_percent)
	
	var attacker_data = {
		"province_id": attacker_province_id,
		"province_name": attacker_province.name,
		"family_id": attacker_province.owner_id,
		"lord": attacker_lord,
		"units": attacker_units,
		"total_soldiers": attacker_province.soldiers,
		"time_of_day": _get_time_of_day()
	}
	
	# Build defender data
	var defender_lord = _get_province_lord(defender_province)
	var defender_units = _build_unit_stacks(defender_province, 1.0)  # Defenders use all troops
	
	var defender_data = {
		"province_id": defender_province_id,
		"province_name": defender_province.name,
		"family_id": defender_province.owner_id,
		"lord": defender_lord,
		"units": defender_units,
		"total_soldiers": defender_province.soldiers,
		"terrain": defender_province.terrain_type if defender_province.get("terrain_type") else "grass",
		"personality": _get_ai_personality(defender_province.owner_id)
	}
	
	# Store return info
	previous_scene_path = get_tree().current_scene.scene_file_path
	
	# Create battle instance
	var battle = TacticalBattleScene.instantiate()
	battle.attacker_data = attacker_data
	battle.defender_data = defender_data
	battle.battle_ended.connect(_on_battle_ended)
	
	# Change to battle scene
	get_tree().root.add_child(battle)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = battle
	
	print("BattleLauncher: Started battle - %s vs %s" % [attacker_province.name, defender_province.name])

func _on_battle_ended(result: Dictionary) -> void:
	"""Handle battle completion and return to strategic map."""
	
	battle_result = result
	
	print("BattleLauncher: Battle ended - Winner: ", result.get("winner", "unknown"))
	
	# Apply battle results to game state
	_apply_battle_results(result)
	
	# Emit signal for other systems
	EventBus.BattleResolved.emit(result)
	
	# Return to strategic map
	_return_to_strategic_map()
	
	# Call callback if provided
	if callback_callable.is_valid():
		callback_callable.call(result)

func _return_to_strategic_map() -> void:
	"""Return to the strategic map scene."""
	
	var strategic_scene = load("res://main_with_ui.tscn").instantiate()
	
	get_tree().root.add_child(strategic_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = strategic_scene
	
	print("BattleLauncher: Returned to strategic map")

func _apply_battle_results(result: Dictionary) -> void:
	"""Apply battle outcome to GameState."""
	
	var attacker_id = result.get("attacker_province_id", -1)
	var defender_id = result.get("defender_province_id", -1)
	var winner = result.get("winner", "")
	
	if attacker_id == -1 or defender_id == -1:
		return
	
	var attacker_province = GameState.provinces.get(attacker_id)
	var defender_province = GameState.provinces.get(defender_id)
	
	if not attacker_province or not defender_province:
		return
	
	# Update soldier counts
	attacker_province.soldiers = result.get("attacker_remaining", 0)
	defender_province.soldiers = result.get("defender_remaining", 0)
	
	# Handle province conquest
	if winner == "attacker":
		# Transfer ownership
		var old_owner = defender_province.owner_id
		defender_province.owner_id = attacker_province.owner_id
		
		# Transfer some resources as loot
		var loot_gold = int(defender_province.gold * 0.3)
		var loot_food = int(defender_province.food * 0.3)
		attacker_province.gold += loot_gold
		attacker_province.food += loot_food
		defender_province.gold -= loot_gold
		defender_province.food -= loot_food
		
		print("BattleLauncher: %s conquered %s! Loot: %d gold, %d food" % [
			attacker_province.name, defender_province.name, loot_gold, loot_food
		])
		
		# Handle lord capture
		if result.get("lord_captured", false):
			var captured_lord = result.get("captured_lord")
			if captured_lord:
				captured_lord.is_captured = true
				captured_lord.captured_by = attacker_province.owner_id
				print("BattleLauncher: Lord captured - ", captured_lord.name)
	
	# Mark attacker as exhausted
	attacker_province.is_exhausted = true
	EventBus.ProvinceExhausted.emit(attacker_id, true)
	
	# Notify province data changed
	EventBus.ProvinceDataChanged.emit(attacker_id, "soldiers", attacker_province.soldiers)
	EventBus.ProvinceDataChanged.emit(defender_id, "soldiers", defender_province.soldiers)

func _get_province_lord(province) -> CharacterData:
	"""Get the lord governing a province."""
	# Find lord by governor_id or look up in characters
	if province.get("governor_id") and not province.governor_id.is_empty():
		return GameState.characters.get(province.governor_id)
	
	# Fallback: find any character from this family
	for char_id in GameState.characters:
		var character = GameState.characters[char_id]
		if character.family_id == province.owner_id:
			return character
	
	return null

func _build_unit_stacks(province, commit_percent: float) -> Array:
	"""Build unit stacks for battle from province soldiers."""
	
	var total_soldiers = int(province.soldiers * commit_percent)
	if total_soldiers <= 0:
		total_soldiers = province.soldiers  # Use all if calculation fails
	
	var units = []
	
	# Determine unit composition based on province development
	var cultivation = province.cultivation if province.get("cultivation") else 50
	var protection = province.protection if province.get("protection") else 50
	
	# Knights (heavy infantry) - based on protection
	var knights = int(total_soldiers * 0.4)
	if knights > 0:
		units.append({"type": "Knights", "count": knights})
	
	# Horsemen (cavalry) - based on food/gold wealth
	var horsemen = int(total_soldiers * 0.3)
	if horsemen > 0:
		units.append({"type": "Horsemen", "count": horsemen})
	
	# Archers - based on cultivation (forests)
	var archers = int(total_soldiers * 0.2)
	if archers > 0:
		units.append({"type": "Archers", "count": archers})
	
	# Mages - small elite force
	var mages = int(total_soldiers * 0.1)
	if mages < 5 and total_soldiers > 20:
		mages = 5
	if mages > 0:
		units.append({"type": "Mages", "count": mages})
	
	# Ensure we have at least one unit
	if units.is_empty() and total_soldiers > 0:
		units.append({"type": "Knights", "count": total_soldiers})
	
	return units

func _get_time_of_day() -> String:
	"""Determine time of day based on game month."""
	var month = GameState.current_month
	match month:
		1, 2, 12: return "night"  # Winter - short days
		6, 7, 8: return "day"     # Summer - bright
		17, 18, 19: return "sunset" # Evening hours
		_: return "day"

func _get_ai_personality(family_id: String) -> String:
	"""Get AI personality for enemy family."""
	match family_id:
		"lyle": return "aggressive"
		"coryll": return "opportunistic"
		_: return "balanced"
