extends Node

const StrategicProvince = preload("res://resources/data_classes/strategic_province.gd")

## Dragon Force Strategic Map - Node Graph System
## Manages provinces as connected nodes with army positions

signal army_arrived(army: Node2D, province: StrategicProvince)
signal battle_triggered(army1: Node2D, army2: Node2D, location: Vector2)
signal province_clicked(province: StrategicProvince)

# The 5 provinces for MVP
var provinces: Dictionary[StringName, StrategicProvince] = {}
var connections: Array[Dictionary] = []  # [{from: id, to: id}]

# Active armies on the map
var armies: Array[Node2D] = []
var selected_army: Node2D = null

func _ready():
	print("StrategicGraph: Initializing...")
	_setup_provinces()
	_setup_connections()
	print("StrategicGraph: %d provinces, %d connections" % [provinces.size(), connections.size()])

func _setup_provinces():
	"""Create the 5 core provinces."""
	
	# Dunmoor - Player starting province (west)
	var dunmoor = StrategicProvince.new()
	dunmoor.id = &"dunmoor"
	dunmoor.province_name = "Dunmoor"
	dunmoor.map_position = Vector2(200, 300)
	dunmoor.owner_faction = &"blanche"
	provinces[&"dunmoor"] = dunmoor
	
	# Carveti - Central
	var carveti = StrategicProvince.new()
	carveti.id = &"carveti"
	carveti.province_name = "Carveti"
	carveti.map_position = Vector2(400, 250)
	carveti.owner_faction = &"coryll"
	provinces[&"carveti"] = carveti
	
	# Cobrige - South
	var cobrige = StrategicProvince.new()
	cobrige.id = &"cobrige"
	cobrige.province_name = "Cobrige"
	cobrige.map_position = Vector2(350, 450)
	cobrige.owner_faction = &"lyle"
	provinces[&"cobrige"] = cobrige
	
	# Banshea - East
	var banshea = StrategicProvince.new()
	banshea.id = &"banshea"
	banshea.province_name = "Banshea"
	banshea.map_position = Vector2(550, 350)
	banshea.owner_faction = &"coryll"
	provinces[&"banshea"] = banshea
	
	# Petaria - Far East
	var petaria = StrategicProvince.new()
	petaria.id = &"petaria"
	petaria.province_name = "Petaria"
	petaria.map_position = Vector2(700, 280)
	petaria.owner_faction = &"lyle"
	provinces[&"petaria"] = petaria

func _setup_connections():
	"""Define road connections between provinces."""
	# Dunmoor connections
	connections.append({"from": &"dunmoor", "to": &"carveti"})
	connections.append({"from": &"dunmoor", "to": &"cobrige"})
	
	# Carveti connections
	connections.append({"from": &"carveti", "to": &"banshea"})
	connections.append({"from": &"carveti", "to": &"petaria"})
	
	# Cobrige connections
	connections.append({"from": &"cobrige", "to": &"banshea"})
	
	# Banshea to Petaria
	connections.append({"from": &"banshea", "to": &"petaria"})

# ============================================================================
# ARMY MANAGEMENT
# ============================================================================

func spawn_army(province_id: StringName, faction: StringName, is_player: bool) -> Node2D:
	"""Spawn an army at a province."""
	if not provinces.has(province_id):
		push_error("Invalid province: %s" % province_id)
		return null
	
	var army = preload("res://strategic/army_marker.tscn").instantiate()
	army.faction = faction
	army.is_player_controlled = is_player
	army.current_province = province_id
	army.global_position = provinces[province_id].map_position
	
	add_child(army)
	armies.append(army)
	
	print("StrategicGraph: Spawned %s army at %s" % [faction, province_id])
	return army

func move_army(army: Node2D, target_province_id: StringName) -> bool:
	"""Order an army to move to a connected province."""
	if not provinces.has(target_province_id):
		return false
	
	if not _are_connected(army.current_province, target_province_id):
		print("StrategicGraph: Cannot move - provinces not connected")
		return false
	
	army.start_movement(provinces[target_province_id])
	return true

func _are_connected(id1: StringName, id2: StringName) -> bool:
	"""Check if two provinces are directly connected."""
	for conn in connections:
		if (conn.from == id1 and conn.to == id2) or (conn.from == id2 and conn.to == id1):
			return true
	return false

# ============================================================================
# COLLISION DETECTION
# ============================================================================

func _process(delta):
	_check_army_collisions()

var active_battle: bool = false

func _check_army_collisions():
	"""Check for army collisions mid-path or at nodes."""
	if active_battle:
		return  # Don't trigger multiple battles
		
	for i in range(armies.size()):
		for j in range(i + 1, armies.size()):
			var army1 = armies[i]
			var army2 = armies[j]
			
			if army1.faction == army2.faction:
				continue  # Same faction doesn't battle
			
			if not army1.is_alive or not army2.is_alive:
				continue  # Dead armies don't battle
			
			var dist = army1.global_position.distance_to(army2.global_position)
			if dist < 20:  # Collision threshold
				_trigger_battle(army1, army2)
				return  # Only trigger one battle at a time

func _trigger_battle(army1: Node2D, army2: Node2D):
	"""Trigger battle between two armies."""
	var midpoint = (army1.global_position + army2.global_position) / 2
	print("StrategicGraph: BATTLE TRIGGERED between %s and %s at %s" % [army1.faction, army2.faction, midpoint])
	battle_triggered.emit(army1, army2, midpoint)

# ============================================================================
# UTILITY
# ============================================================================

func get_province(id: StringName) -> StrategicProvince:
	return provinces.get(id)

func get_connected_provinces(id: StringName) -> Array[StrategicProvince]:
	"""Get all provinces directly connected to the given one."""
	var result: Array[StrategicProvince] = []
	for conn in connections:
		if conn.from == id:
			result.append(provinces[conn.to])
		elif conn.to == id:
			result.append(provinces[conn.from])
	return result

func select_army(army: Node2D):
	"""Select an army (player only)."""
	if selected_army:
		selected_army.deselect()
	selected_army = army
	if army:
		army.select()

func get_armies_in_province(province_id: StringName) -> Array[Node2D]:
	"""Get all armies currently at a province."""
	var result: Array[Node2D] = []
	for army in armies:
		if army.current_province == province_id and not army.is_moving:
			result.append(army)
	return result
