extends Node

# Unit Manager - Handles tactical unit sprites and types

const UNIT_SPRITES = {
	"knight_blue": preload("res://assets/units/knight_blue.png"),
	"knight_red": preload("res://assets/units/knight_red.png"),
	"archer_blue": preload("res://assets/units/archer_blue.png"),
	"archer_red": preload("res://assets/units/archer_red.png"),
	"cavalry_blue": preload("res://assets/units/cavalry_blue.png"),
	"cavalry_red": preload("res://assets/units/cavalry_red.png"),
}

const UNIT_STATS = {
	"knight": {
		"attack": 8,
		"defense": 6,
		"speed": 4,
		"ranged": false
	},
	"archer": {
		"attack": 5,
		"defense": 3,
		"speed": 5,
		"ranged": true,
		"range": 3
	},
	"cavalry": {
		"attack": 7,
		"defense": 4,
		"speed": 7,
		"ranged": false
	}
}

func get_unit_sprite(unit_type: String, faction: String) -> Texture2D:
	var key = "%s_%s" % [unit_type, faction]
	return UNIT_SPRITES.get(key, UNIT_SPRITES["knight_blue"])

func get_unit_stats(unit_type: String) -> Dictionary:
	return UNIT_STATS.get(unit_type, UNIT_STATS["knight"])

func create_unit_stack(unit_type: String, faction: String, count: int) -> Dictionary:
	return {
		"type": unit_type,
		"faction": faction,
		"count": count,
		"sprite": get_unit_sprite(unit_type, faction),
		"stats": get_unit_stats(unit_type)
	}
