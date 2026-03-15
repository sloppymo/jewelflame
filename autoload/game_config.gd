extends Node

# Balance
const STARTING_GOLD := 800
const STARTING_TROOPS := 200
const RECRUIT_COST := 10
const BASE_INCOME := 100
const MAX_DEFENSE_LEVEL := 5

# Combat
const ATTACKER_WIN_SURVIVOR_RATIO := 0.7  # 70% occupy target
const ATTACKER_WIN_LOSS_RATIO := 0.3  # 30% losses
const ATTACKER_LOSS_RATIO := 0.5  # 50% losses when retreating
const DEFENDER_LOSS_RATIO := 0.2  # 20% losses when defending

# AI
const AI_ATTACK_THRESHOLD := 1.5
const AI_RECRUIT_THRESHOLD := 100
const AI_RECRUIT_AMOUNT := 50
const AI_MIN_GARRISON := 50
const AI_MAX_MOVE_AMOUNT := 50

# Map
const PROVINCE_COUNT := 10

# Movement
const MAX_TROOPS_PER_MOVE := 100
const MIN_GARRISON_SIZE := 1

# Events
const EVENT_CHANCE := 0.3  # 30% chance per turn

# Faction IDs
const FACTION_BLANCHE := &"blanche"
const FACTION_CORYLL := &"coryll"
const FACTION_LYLE := &"lyle"

# Province IDs
const PROVINCE_DUNMOOR := &"dunmoor"
const PROVINCE_CARVETI := &"carveti"
const PROVINCE_COBRIGE := &"cobrige"
const PROVINCE_BANSHEA := &"banshea"
const PROVINCE_PETARIA := &"petaria"
const PROVINCE_WESTFALL := &"westfall"
const PROVINCE_THORNWOOD := &"thornwood"
const PROVINCE_NORTHREACH := &"northreach"
const PROVINCE_EASTMARK := &"eastmark"
const PROVINCE_HIGHMOORS := &"highmoors"
const PROVINCE_SOUTHWYN := &"southwyn"

# AI Personalities - Higher attack_threshold = less aggressive
const AI_PERSONALITIES := {
	&"blanche": {
		"name": "Defensive",
		"attack_threshold": 2.0,  # Very cautious - needs 2:1 advantage
		"recruit_threshold": 80,
		"defense_focus": true,
		"expansion_focus": false,
		"recruit_bias": 1.2,
		"description": "Prioritizes strong defenses and maintains large garrisons"
	},
	&"coryll": {
		"name": "Aggressive",
		"attack_threshold": 1.5,  # Was 0.9 - now needs clear advantage
		"recruit_threshold": 120,
		"defense_focus": false,
		"expansion_focus": true,
		"recruit_bias": 0.8,
		"description": "Attacks frequently, focuses on rapid expansion"
	},
	&"lyle": {
		"name": "Opportunistic",
		"attack_threshold": 1.8,  # Was 1.2 - more cautious opportunism
		"recruit_threshold": 100,
		"defense_focus": false,
		"expansion_focus": true,
		"recruit_bias": 1.1,
		"description": "Balances economy and military, exploits weaknesses"
	}
}
