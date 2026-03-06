extends Node

# Performance constants
const MAX_AI_PROCESS_TIME_MS = 100  # 100ms max per AI turn
const AI_DECISION_BATCH_SIZE = 5

# Performance tracking
var ai_performance_data: Dictionary = {}

func take_turn(family_id: String):
	var start_time = Time.get_ticks_msec()
	print("AI turn starting for: ", family_id)
	
	var family = SafeAccess.get_enhanced_family_safe(family_id)
	if not family:
		ErrorHandler.handle_invalid_family(family_id, "take_turn")
		return
	
	# Get all provinces owned by this family
	var family_provinces = []
	for province in EnhancedGameState.provinces.values():
		if SafeAccess.safe_get_owner_id(province) == family_id and not province.is_exhausted:
			family_provinces.append(province)
	
	# Process provinces in batches with time limits
	var processed_count = 0
	for i in range(0, family_provinces.size(), AI_DECISION_BATCH_SIZE):
		# Check time limit
		if Time.get_ticks_msec() - start_time > MAX_AI_PROCESS_TIME_MS:
			print("AI processing timeout - deferring remaining decisions")
			call_deferred("continue_ai_processing", family_id, family_provinces.slice(i))
			return
		
		# Process batch
		var batch = family_provinces.slice(i, min(i + AI_DECISION_BATCH_SIZE, family_provinces.size()))
		for province in batch:
			# Skip if province was conquered during this turn
			if SafeAccess.safe_get_owner_id(province) != family_id:
				continue
			
			process_province_ai_optimized(province, family)
			processed_count += 1
		
		# Small delay between batches for UX
		await get_tree().create_timer(0.2).timeout
	
	# Record performance data
	var total_time = Time.get_ticks_msec() - start_time
	record_ai_performance(family_id, processed_count, total_time)
	
	# Signal turn completion
	print("AI turn completed for: ", family_id, " (", total_time, "ms)")

func process_province_ai_optimized(province: ProvinceData, family: FamilyData):
	var personality = family.ai_personality
	var action_taken = false
	
	# Pre-calculate common values to avoid repeated access
	var province_id = province.id
	var province_soldiers = SafeAccess.safe_get_province_soldiers(province)
	var province_gold = SafeAccess.safe_get_province_gold(province)
	var owner_id = SafeAccess.safe_get_owner_id(province)
	
	# Batch evaluate all decisions
	var all_decisions = []
	
	# Evaluate attack options
	var attack_decisions = evaluate_attack_options_batch(province, personality, province_id, owner_id, province_soldiers)
	all_decisions.append_array(attack_decisions)
	
	# Evaluate recruitment options
	var recruit_decisions = evaluate_recruitment_options_batch(province, personality, province_soldiers, province_gold)
	all_decisions.append_array(recruit_decisions)
	
	# Evaluate development options
	var develop_decisions = evaluate_development_options_batch(province, personality)
	all_decisions.append_array(develop_decisions)
	
	# Execute highest priority decision
	if not all_decisions.is_empty():
		var best_decision = prioritize_decisions(all_decisions, personality)
		execute_ai_decision(best_decision, province)
		action_taken = true
	
	if action_taken:
		print("AI ", family.name, " took action in ", province.name)

func evaluate_attack_options_batch(province: ProvinceData, personality: String, province_id: int, owner_id: String, province_soldiers: int) -> Array[Dictionary]:
	var decisions = []
	
	# Find adjacent enemy provinces
	var potential_targets = []
	for neighbor_id in province.neighbors:
		var neighbor = SafeAccess.get_enhanced_province_safe(neighbor_id)
		if neighbor and SafeAccess.safe_get_owner_id(neighbor) != owner_id:
			potential_targets.append(neighbor_id)
	
	if potential_targets.is_empty():
		return decisions
	
	# Batch evaluate all targets
	for target_id in potential_targets:
		var target = SafeAccess.get_enhanced_province_safe(target_id)
		if not target:
			continue
		
		var target_soldiers = SafeAccess.safe_get_province_soldiers(target)
		var utility = AIPersonalities.evaluate_attack_utility(
			province_soldiers,
			target_soldiers,
			personality
		)
		
		var weights = AIPersonalities.WEIGHTS[personality]
		if utility >= weights.attack_threshold:
			var attack_force = int(province_soldiers * 0.7)  # Attack with 70% of troops
			decisions.append({
				"type": "attack",
				"target_id": target_id,
				"force": attack_force,
				"utility": utility,
				"priority": utility * weights.attack_priority
			})
	
	return decisions

func evaluate_recruitment_options_batch(province: ProvinceData, personality: String, province_soldiers: int, province_gold: int) -> Array[Dictionary]:
	var decisions = []
	
	if AIPersonalities.should_recruit(province_soldiers, province_gold, personality):
		var recruit_cost = 50
		var utility = min(province_gold / recruit_cost, 5.0)  # Max utility of 5
		
		decisions.append({
			"type": "recruit",
			"amount": 50,
			"utility": utility,
			"priority": utility * 0.8  # Lower priority than attacks
		})
	
	return decisions

func evaluate_development_options_batch(province: ProvinceData, personality: String) -> Array[Dictionary]:
	var decisions = []
	
	if AIPersonalities.should_develop(province, personality):
		var develop_type = "protection" if personality == "defensive" else "cultivation"
		var utility = 1.0  # Base utility for development
		
		decisions.append({
			"type": "develop",
			"develop_type": develop_type,
			"utility": utility,
			"priority": utility * 0.6  # Lower priority than recruitment
		})
	
	return decisions

func prioritize_decisions(decisions: Array[Dictionary], personality: String) -> Dictionary:
	if decisions.is_empty():
		return {}
	
	# Sort by priority (highest first)
	decisions.sort_custom(func(a, b): return a.priority > b.priority)
	return decisions[0]

func execute_ai_decision(decision: Dictionary, province: ProvinceData):
	match decision.type:
		"attack":
			execute_action("attack", province, decision.target_id, decision.force)
		"recruit":
			execute_action("recruit", province, -1, decision.amount)
		"develop":
			execute_action("develop", province, -1, decision.develop_type)

func continue_ai_processing(family_id: String, remaining_provinces: Array):
	print("Continuing AI processing for: ", family_id)
	var family = SafeAccess.get_enhanced_family_safe(family_id)
	if not family:
		return
	
	for province in remaining_provinces:
		if SafeAccess.safe_get_owner_id(province) != family_id:
			continue
		
		process_province_ai_optimized(province, family)
		await get_tree().create_timer(0.1).timeout

func record_ai_performance(family_id: String, provinces_processed: int, total_time_ms: int):
	ai_performance_data[family_id] = {
		"provinces_processed": provinces_processed,
		"total_time_ms": total_time_ms,
		"avg_time_per_province": float(total_time_ms) / provinces_processed,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# Log performance warnings
	if total_time_ms > MAX_AI_PROCESS_TIME_MS:
		print("Warning: AI processing for ", family_id, " took ", total_time_ms, "ms (limit: ", MAX_AI_PROCESS_TIME_MS, "ms)")

func get_ai_performance_data() -> Dictionary:
	return ai_performance_data.duplicate()

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
