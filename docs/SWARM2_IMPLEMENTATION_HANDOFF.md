# PROMPT: Iteration Swarm — Core Implementation Phase

You are the Conductor for **Jewelflame Implementation Swarm Alpha**. You are NOT designing from scratch—you are IMPLEMENTING the architecture from the previous swarm.

## CONTEXT FROM PREVIOUS SWARM (Agent 1 - Architecture)

### Data Classes Created:
```gdscript
# /home/sloppymo/jewelflame/resources/data_classes/lord_data.gd
class_name LordData extends CharacterData
@export var age: int = 25
@export var loyalty: int = 100
@export var is_captured: bool = false
@export var capture_family_id: String = ""
@export var desertion_chance: float = 0.1
@export var monthly_loyalty_drift: int = 0

# Gemfire-specific stats
@export var attack_rating: int = 50
@export var defense_rating: int = 50
@export var command_rating: int = 50

# Battle formation preferences
@export var preferred_formation: String = "balanced"
@export var special_ability: String = ""

func calculate_loyalty_modifier() -> float:
	var base_mod = 1.0
	if loyalty < 30:
		base_mod = 0.5
	elif loyalty < 60:
		base_mod = 0.8
	elif loyalty > 90:
		base_mod = 1.2
	return base_mod

func check_desertion() -> bool:
	var chance = desertion_chance
	if loyalty < 30:
		chance *= 3.0
	elif loyalty < 60:
		chance *= 1.5
	return randf() < chance

func to_dict() -> Dictionary:
	var base_dict = super.to_dict()
	base_dict.merge({
		"age": age,
		"loyalty": loyalty,
		"is_captured": is_captured,
		"capture_family_id": capture_family_id,
		"desertion_chance": desertion_chance,
		"monthly_loyalty_drift": monthly_loyalty_drift,
		"attack_rating": attack_rating,
		"defense_rating": defense_rating,
		"command_rating": command_rating,
		"preferred_formation": preferred_formation,
		"special_ability": special_ability
	})
	return base_dict

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	age = data.get("age", 25)
	loyalty = data.get("loyalty", 100)
	is_captured = data.get("is_captured", false)
	capture_family_id = data.get("capture_family_id", "")
	desertion_chance = data.get("desertion_chance", 0.1)
	monthly_loyalty_drift = data.get("monthly_loyalty_drift", 0)
	attack_rating = data.get("attack_rating", 50)
	defense_rating = data.get("defense_rating", 50)
	command_rating = data.get("command_rating", 50)
	preferred_formation = data.get("preferred_formation", "balanced")
	special_ability = data.get("special_ability", "")
```

```gdscript
# /home/sloppymo/jewelflame/resources/data_classes/unit_data.gd
class_name UnitData extends Resource
@export var unit_type: String = "knight"
@export var stack_size: int = 10
@export var experience: int = 0
@export var is_special_unit: bool = false
@export var special_creature_type: String = ""

# Combat stats
@export var attack_power: int = 10
@export var defense_power: int = 10
@export var movement: int = 3
@export var range: int = 1

# Formation bonuses
@export var flanking_bonus: float = 1.2
@export var rear_assault_bonus: float = 1.3

func get_unit_type_stats() -> Dictionary:
	match unit_type:
		"knight":
			return {"attack": 15, "defense": 12, "movement": 2, "range": 1}
		"horseman":
			return {"attack": 12, "defense": 8, "movement": 4, "range": 1}
		"archer":
			return {"attack": 8, "defense": 6, "movement": 3, "range": 3}
		"mage":
			return {"attack": 10, "defense": 4, "movement": 2, "range": 2}
		_:
			return {"attack": 10, "defense": 10, "movement": 3, "range": 1}

func calculate_effective_power() -> int:
	var stats = get_unit_type_stats()
	var base_power = (attack_power + stats.attack) * stack_size
	var experience_bonus = 1.0 + (experience / 100.0)
	return int(base_power * experience_bonus)

func to_dict() -> Dictionary:
	return {
		"unit_type": unit_type,
		"stack_size": stack_size,
		"experience": experience,
		"is_special_unit": is_special_unit,
		"special_creature_type": special_creature_type,
		"attack_power": attack_power,
		"defense_power": defense_power,
		"movement": movement,
		"range": range,
		"flanking_bonus": flanking_bonus,
		"rear_assault_bonus": rear_assault_bonus
	}

func from_dict(data: Dictionary) -> void:
	unit_type = data.get("unit_type", "knight")
	stack_size = data.get("stack_size", 10)
	experience = data.get("experience", 0)
	is_special_unit = data.get("is_special_unit", false)
	special_creature_type = data.get("special_creature_type", "")
	attack_power = data.get("attack_power", 10)
	defense_power = data.get("defense_power", 10)
	movement = data.get("movement", 3)
	range = data.get("range", 1)
	flanking_bonus = data.get("flanking_bonus", 1.2)
	rear_assault_bonus = data.get("rear_assault_bonus", 1.3)
```

```gdscript
# /home/sloppymo/jewelflame/resources/data_classes/battle_data.gd
class_name BattleData extends Resource
@export var battle_id: String = ""
@export var attacking_province_id: int = -1
@export var defending_province_id: int = -1
@export var attacking_family_id: String = ""
@export var defending_family_id: String = ""

# Army compositions
@export var attacking_units: Array[UnitData] = []
@export var defending_units: Array[UnitData] = []

# Battle conditions
@export var terrain_type: String = "plains"
@export var weather_condition: String = "clear"
@export var time_of_day: String = "day"

# Commanders
@export var attacking_commander_id: String = ""
@export var defending_commander_id: String = ""

# Formation settings
@export var attacker_formation: String = "balanced"
@export var defender_formation: String = "balanced"

# Battle results (filled after resolution)
@export var battle_state: String = "pending"
@export var winner: String = ""
@export var attacker_casualties: Array[int] = []
@export var defender_casualties: Array[int] = []
@export var battle_duration: int = 0
@export var loot_gold: int = 0
@export var loot_food: int = 0
@export var captured_lords: Array[String] = []

func calculate_army_power(units: Array[UnitData], commander: LordData, terrain_bonus: float) -> float:
	var total_power = 0.0
	for unit in units:
		total_power += unit.calculate_effective_power()
	
	var commander_bonus = 1.0
	if commander:
		commander_bonus = 1.0 + (commander.command_rating / 100.0)
	
	return total_power * commander_bonus * terrain_bonus

func get_formation_bonus(formation: String, is_attacker: bool) -> float:
	match formation:
		"aggressive":
			return 1.3 if is_attacker else 0.9
		"defensive":
			return 0.9 if is_attacker else 1.3
		"balanced":
			return 1.1
		_:
			return 1.0

func get_weather_modifier() -> float:
	match weather_condition:
		"clear": return 1.0
		"rain": return 0.9
		"fog": return 0.8
		"storm": return 0.7
		_: return 1.0

func to_dict() -> Dictionary:
	return {
		"battle_id": battle_id,
		"attacking_province_id": attacking_province_id,
		"defending_province_id": defending_province_id,
		"attacking_family_id": attacking_family_id,
		"defending_family_id": defending_family_id,
		"attacking_units": attacking_units.map(func(u): return u.to_dict()),
		"defending_units": defending_units.map(func(u): return u.to_dict()),
		"terrain_type": terrain_type,
		"weather_condition": weather_condition,
		"time_of_day": time_of_day,
		"attacking_commander_id": attacking_commander_id,
		"defending_commander_id": defending_commander_id,
		"attacker_formation": attacker_formation,
		"defender_formation": defender_formation,
		"battle_state": battle_state,
		"winner": winner,
		"attacker_casualties": attacker_casualties,
		"defender_casualties": defender_casualties,
		"battle_duration": battle_duration,
		"loot_gold": loot_gold,
		"loot_food": loot_food,
		"captured_lords": captured_lords
	}

func from_dict(data: Dictionary) -> void:
	battle_id = data.get("battle_id", "")
	attacking_province_id = data.get("attacking_province_id", -1)
	defending_province_id = data.get("defending_province_id", -1)
	attacking_family_id = data.get("attacking_family_id", "")
	defending_family_id = data.get("defending_family_id", "")
	
	# Reconstruct unit arrays
	attacking_units.clear()
	for unit_data in data.get("attacking_units", []):
		var unit = UnitData.new()
		unit.from_dict(unit_data)
		attacking_units.append(unit)
	
	defending_units.clear()
	for unit_data in data.get("defending_units", []):
		var unit = UnitData.new()
		unit.from_dict(unit_data)
		defending_units.append(unit)
	
	terrain_type = data.get("terrain_type", "plains")
	weather_condition = data.get("weather_condition", "clear")
	time_of_day = data.get("time_of_day", "day")
	attacking_commander_id = data.get("attacking_commander_id", "")
	defending_commander_id = data.get("defending_commander_id", "")
	attacker_formation = data.get("attacker_formation", "balanced")
	defender_formation = data.get("defender_formation", "balanced")
	battle_state = data.get("battle_state", "pending")
	winner = data.get("winner", "")
	attacker_casualties = data.get("attacker_casualties", [])
	defender_casualties = data.get("defender_casualties", [])
	battle_duration = data.get("battle_duration", 0)
	loot_gold = data.get("loot_gold", 0)
	loot_food = data.get("loot_food", 0)
	captured_lords = data.get("captured_lords", [])
```

### Enhanced ProvinceData (Modified existing):
```gdscript
# Enhanced sections added to existing ProvinceData
# Gemfire-specific resources
@export var mana: int = 50
@export var transport_capacity: int = 100
@export var garrison_limit: int = 200

# Unit composition (replaces simple soldiers)
@export var stationed_units: Array[UnitData] = []

# Lord management
@export var stationed_lord_id: String = ""
@export var prisoner_lords: Array[String] = []

# Terrain and weather
@export var current_weather: String = "clear"
@export var weather_duration: int = 1

# Helper methods added
func get_total_military_power() -> int:
	var total = soldiers
	for unit in stationed_units:
		total += unit.stack_size
	return total

func can_support_more_units() -> bool:
	return get_total_military_power() < garrison_limit

func get_terrain_defense_bonus() -> float:
	match terrain_type:
		"plains": return 1.0
		"woods": return 1.2
		"river": return 1.1
		"mountain": return 1.3
		_: return 1.0

func process_weather_change():
	weather_duration -= 1
	if weather_duration <= 0:
		var weather_options = ["clear", "rain", "fog", "storm"]
		current_weather = weather_options[randi() % weather_options.size()]
		weather_duration = randi_range(1, 3)
```

### Scene Architecture (From Documentation):
```
StrategicMap (Node2D)
├── Camera2D
├── UI_Layer (CanvasLayer)
│   ├── TopBar (HBoxContainer)
│   │   ├── TurnIndicator (Label)
│   │   ├── DateDisplay (Label)
│   │   └── EndTurnButton (Button)
│   ├── LeftPanel (VBoxContainer)
│   │   ├── LordRoster (ScrollContainer)
│   │   ├── CommandCategories (TabContainer)
│   │   └── PlottingStrategyButton (Button)
│   └── RightPanel (VBoxContainer)
│       └── ProvinceInfo (Panel)
├── Map_Layer (Node2D)
│   ├── ProvinceAreas (Node2D)
│   └── ProvinceLabels (Node2D)
└── Animation_Layer (Node2D)
```

## VERIFICATION STATUS (Check these before starting):
- [ ] Data classes compile without errors in Godot 4.4
- [ ] Scene files (.tscn) exist in correct paths  
- [ ] No placeholder "pass" functions in critical paths
- [ ] All @export annotations are present
- [ ] JSON save/load methods work correctly

## YOUR SWARM (4 Agents, Parallel where possible):

### **Agent A: Data Validation & Fixes**
- Task: Take the Resource classes provided above. Fix any syntax errors. Add missing `@export` annotations. Ensure all `save()`/`load()` methods work with JSON.
- Constraint: Do NOT change the public API (function names/signatures). Only fix implementations.
- Deliverable: Working `/resources/data_classes/*.gd` files that pass static analysis.

### **Agent B: Scene Construction**  
- Task: Build the actual `.tscn` files for StrategicMap, TacticalBattle, and Main. Use placeholder ColorRects for visuals.
- Constraint: Must use the data classes from Agent A. Scene tree structure must match architecture exactly.
- Deliverable: Runnable scenes (even if visuals are ugly).

### **Agent C: Turn System Wiring**
- Task: Implement TurnManager state machine. Connect the "Plotting Strategy" button to actually advance phases.
- Constraint: Use signals only—no direct node references between systems.
- Deliverable: Player can click through a full turn cycle (Player → AI Lyle → AI Coryll → Next Month).

### **Agent D: Integration Testing**
- Task: Write test scenarios (GDScript in `/tests/`). Verify: Lord selection works, province ownership changes save/load correctly, turn cycle completes without crash.
- Constraint: Tests must run with `godot --script test.gd`.
- Deliverable: Test report showing 3+ passing integration tests.

## CONDUCTOR (You):

After Agents A-D report:
1. Attempt to run `main.tscn` 
2. If it crashes, diagnose which agent owns the fix
3. Return revised assignments until `main.tscn` loads to strategic map

## SUCCESS CRITERIA:
- `godot --path . --scene scenes/main.tscn` launches without errors
- Player can select a lord, select a province, click "Plotting Strategy"  
- Game advances through all turn phases and loops back to player
- Save/Load creates and reads JSON files in `user://saves/`

## KNOWN ISSUES TO ADDRESS:
- UnitData arrays in BattleData may need proper type hints
- LordData extends CharacterData - ensure inheritance works
- ProvinceData modifications must be compatible with existing save system
- Scene node paths must match autoload singleton names

## CONSTRAINTS:
- DO NOT modify existing working code (battle_resolver.gd, economy_manager.gd, etc.)
- DO NOT create new autoload singletons - use existing ones
- MUST maintain compatibility with existing save format
- ALL new features must be optional/behind feature flags initially

---

**IMPLEMENTATION PRIORITY:**
1. Fix data class compilation errors (Agent A)
2. Create basic scenes (Agent B) 
3. Wire turn system (Agent C)
4. Verify integration (Agent D)
5. Conductor validation and integration

**HANDOFF TO NEXT SWARM:** When all success criteria are met, provide working build + test results for Swarm 3 (Systems Integration & AI).
