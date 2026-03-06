extends Node

func take_turn(family_id: String):
	print("AI turn starting for: ", family_id)
	var family = GameState.families[family_id]
	
	# Get all provinces owned by this family
	var family_provinces = []
	for province in GameState.provinces.values():
		if province.owner_id == family_id and not province.is_exhausted:
			family_provinces.append(province)
	
	# Process each province with delays for pacing
	for i in range(family_provinces.size()):
		var province = family_provinces[i]
		
		# Add delay between actions for better UX
		await get_tree().create_timer(1.5).timeout
		
		# Skip if province was conquered during this turn
		if province.owner_id != family_id:
			continue
			
		process_province_ai(province, family)
	
	# Signal turn completion
	print("AI turn completed for: ", family_id)

func process_province_ai(province: ProvinceData, family: FamilyData):
	var personality = family.ai_personality
	var action_taken = false
	
	# Step 1: Check for attack opportunities
	if not action_taken:
		action_taken = try_attack_action(province, personality)
	
	# Step 2: Recruit if needed
	if not action_taken:
		action_taken = try_recruit_action(province, personality)
	
	# Step 3: Develop if no other action taken
	if not action_taken:
		action_taken = try_develop_action(province, personality)
	
	if action_taken:
		print("AI ", family.name, " took action in ", province.name)

func try_attack_action(province: ProvinceData, personality: String) -> bool:
	# Find adjacent enemy provinces
	var potential_targets = []
	for neighbor_id in province.neighbors:
		var neighbor = GameState.provinces[neighbor_id]
		if neighbor.owner_id != province.owner_id:
			potential_targets.append(neighbor_id)
	
	if potential_targets.is_empty():
		return false
	
	# Use AI personality to choose target
	var target_id = AIPersonalities.choose_target_province(
		province.id, potential_targets, personality
	)
	
	if target_id == -1:
		return false
	
	# Evaluate if attack is wise
	var utility = AIPersonalities.evaluate_attack_utility(
		province.soldiers,
		GameState.provinces[target_id].soldiers,
		personality
	)
	
	# Only attack if utility meets threshold
	var weights = AIPersonalities.WEIGHTS[personality]
	if utility >= weights.attack_threshold:
		# Execute attack with partial forces (leave garrison)
		var attack_force = int(province.soldiers * 0.7)  # Attack with 70% of troops
		execute_action("attack", province, target_id, attack_force)
		return true
	
	return false

func try_recruit_action(province: ProvinceData, personality: String) -> bool:
	if not AIPersonalities.should_recruit(province.soldiers, province.gold, personality):
		return false
	
	execute_action("recruit", province, -1, 50)
	return true

func try_develop_action(province: ProvinceData, personality: String) -> bool:
	if not AIPersonalities.should_develop(province, personality):
		return false
	
	# Choose development type based on personality
	var develop_type = "protection" if personality == "defensive" else "cultivation"
	execute_action("develop", province, -1, develop_type)
	return true

func execute_action(action: String, province: ProvinceData, target_id: int, param):
	match action:
		"attack":
			# Execute attack through battle system
			# var result = BattleResolver.resolve_province_attack(
			# 	province.id, target_id, param
			# )
			pass
			
			# Handle battle results
			# if result.attacker_won:
			# 	# Transfer ownership
			# 	var target_province = GameState.provinces[target_id]
			# 	target_province.owner_id = province.owner_id
			# 	EventBus.ProvinceDataChanged.emit(target_id, "owner_id", target_province.owner_id)
			# 	
			# 	# Transfer some resources as loot
			# 	var loot_gold = int(target_province.gold * 0.3)
			# 	var loot_food = int(target_province.food * 0.3)
			# 	province.gold += loot_gold
			# 	province.food += loot_food
			# 	target_province.gold -= loot_gold
			# 	target_province.food -= loot_food
			# 	
			# 	print("AI ", province.owner_id, " conquered ", target_province.name)
		
		"recruit":
			MilitaryCommands.execute_recruit(province.id, param)
		
		"develop":
			DomesticCommands.execute_develop(province.id, param)
