extends Node

# Jewel Manager - Handles the Fifth Unit (wizard/jewel) system

enum JewelType {
	RUBY,      # Fire
	EMERALD,   # Nature/Healing
	TOPAZ,     # Lightning
	SAPPHIRE,  # Water/Ice
	AQUAMARINE,# Ice
	AMETHYST,  # Wind
	PEARL      # Poison/Toxic
}

const JEWEL_ICONS = {
	"ruby": preload("res://assets/jewels/ruby.png"),
	"emerald": preload("res://assets/jewels/emerald.png"),
	"topaz": preload("res://assets/jewels/topaz.png"),
	"sapphire": preload("res://assets/jewels/sapphire.png"),
	"aquamarine": preload("res://assets/jewels/aquamarine.png"),
	"amethyst": preload("res://assets/jewels/amethyst.png"),
	"pearl": preload("res://assets/jewels/pearl.png"),
}

const JEWEL_SPELLS = {
	"ruby": {
		"name": "Fireball",
		"damage": 25,
		"aoe": true,
		"mana_cost": 30
	},
	"emerald": {
		"name": "Heal",
		"healing": 20,
		"mana_cost": 25
	},
	"topaz": {
		"name": "Lightning",
		"damage": 30,
		"mana_cost": 35
	},
	"sapphire": {
		"name": "Meteor",
		"damage": 40,
		"aoe": true,
		"mana_cost": 50
	},
	"aquamarine": {
		"name": "Blizzard",
		"damage": 15,
		"slow": true,
		"mana_cost": 30
	},
	"amethyst": {
		"name": "Wind Strike",
		"damage": 20,
		"pushback": true,
		"mana_cost": 25
	},
	"pearl": {
		"name": "Poison Cloud",
		"damage": 10,
		"dot": true,
		"mana_cost": 20
	}
}

func get_jewel_icon(jewel_type: String) -> Texture2D:
	return JEWEL_ICONS.get(jewel_type, null)

func get_jewel_spell(jewel_type: String) -> Dictionary:
	return JEWEL_SPELLS.get(jewel_type, JEWEL_SPELLS["ruby"])

func get_all_jewels() -> Array:
	return JEWEL_ICONS.keys()
