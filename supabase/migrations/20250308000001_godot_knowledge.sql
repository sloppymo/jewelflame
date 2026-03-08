-- Godot Knowledge Base Schema for Jewelflame
-- Stores development patterns, HexForge constraints, and code examples

-- Enable pgvector extension for similarity search
CREATE EXTENSION IF NOT EXISTS vector;

-- Knowledge categories lookup
CREATE TABLE IF NOT EXISTS knowledge_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Main knowledge table
CREATE TABLE IF NOT EXISTS godot_knowledge (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES knowledge_categories(id),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    embedding VECTOR(1536),  -- For similarity search
    similarity_score FLOAT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_knowledge_category ON godot_knowledge(category_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_tags ON godot_knowledge USING GIN(tags);

-- Vector similarity search index (using ivfflat for approximate nearest neighbor)
CREATE INDEX IF NOT EXISTS idx_knowledge_embedding ON godot_knowledge 
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- Function to find similar knowledge
CREATE OR REPLACE FUNCTION find_similar_knowledge(
    query_embedding VECTOR(1536),
    match_threshold FLOAT DEFAULT 0.7,
    match_count INT DEFAULT 5
)
RETURNS TABLE (
    id INT,
    title VARCHAR,
    content TEXT,
    category_name VARCHAR,
    tags TEXT[],
    similarity FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        k.id,
        k.title,
        k.content,
        c.name AS category_name,
        k.tags,
        1 - (k.embedding <=> query_embedding) AS similarity
    FROM godot_knowledge k
    JOIN knowledge_categories c ON k.category_id = c.id
    WHERE 1 - (k.embedding <=> query_embedding) > match_threshold
    ORDER BY k.embedding <=> query_embedding
    LIMIT match_count;
END;
$$ LANGUAGE plpgsql;

-- Insert knowledge categories
INSERT INTO knowledge_categories (name, description) VALUES
    ('hex_grid_patterns', 'Hex coordinate systems, cube coords, neighbors, distance, line drawing'),
    ('combat_systems', 'Turn management, action economy, combat resolution, state machines'),
    ('resource_management', 'Save/load, serialization, JSON, Resource classes'),
    ('ui_patterns', 'Control nodes, layout, signals, Godot UI best practices'),
    ('architecture', 'Singletons, ProtoTree, RuntimeServices, scene structure'),
    ('performance', 'Spatial hashing, viewport culling, caching strategies'),
    ('jewelflame_specific', 'Micro-Gemfire integration, GameState, Province systems')
ON CONFLICT (name) DO NOTHING;

-- Insert sample HexForge constraints (critical rules)
INSERT INTO godot_knowledge (category_id, title, content, tags) VALUES
    (1, 'HexForge Core Constraint: No Rendering in Services', 
     'NEVER couple rendering in Core/Services. Only HexRenderer2D touches visuals. Core and Services should be pure logic.

Example - WRONG:
```gdscript
# In a Service - DON''T DO THIS
func move_unit(unit, pos):
    unit.position = pos  # Rendering in service!
    unit.sprite.update() # Direct visual manipulation
```

Example - CORRECT:
```gdscript
# In a Service
func move_unit(unit, pos):
    unit.grid_position = pos  # Only update data
    # Emit signal for renderer to pick up
    position_changed.emit(unit, pos)
```', 
     ARRAY['hexforge', 'constraints', 'architecture', 'rendering']),
    
    (1, 'HexForge Core Constraint: Custom AStar Only',
     'Never use Godot''s built-in AStar. Use custom BinaryHeap pathfinder for hex grids.

BinaryHeap implementation:
```gdscript
class BinaryHeap:
    var heap: Array = []
    
    func insert(item, priority: float):
        heap.append({"item": item, "priority": priority})
        _heapify_up(heap.size() - 1)
    
    func extract_min():
        if heap.is_empty():
            return null
        var min = heap[0]
        heap[0] = heap[heap.size() - 1]
        heap.pop_back()
        _heapify_down(0)
        return min.item
    
    func _heapify_up(index: int):
        while index > 0:
            var parent = (index - 1) / 2
            if heap[parent].priority <= heap[index].priority:
                break
            _swap(parent, index)
            index = parent
    
    func _heapify_down(index: int):
        var size = heap.size()
        while true:
            var left = 2 * index + 1
            var right = 2 * index + 2
            var smallest = index
            
            if left < size and heap[left].priority < heap[smallest].priority:
                smallest = left
            if right < size and heap[right].priority < heap[smallest].priority:
                smallest = right
            
            if smallest == index:
                break
            _swap(index, smallest)
            index = smallest
    
    func _swap(i: int, j: int):
        var temp = heap[i]
        heap[i] = heap[j]
        heap[j] = temp
```',
     ARRAY['hexforge', 'pathfinding', 'astar', 'binary_heap', 'constraints']),
    
    (1, 'HexForge Core Constraint: Unit Type Parameterization',
     'Never assume unit types in Core. Pass unit_type as parameter. Core should be agnostic to specific unit types.

Example - WRONG:
```gdscript
# Hardcoded unit types - DON''T DO THIS
func calculate_damage(attacker, defender):
    if attacker.type == "Knight":
        return 10
    elif attacker.type == "Archer":
        return 5
```

Example - CORRECT:
```gdscript
# Pass stats as parameters
func calculate_damage(attack_power: int, defense: int, modifiers: Dictionary) -> int:
    var base = attack_power - defense
    for mod in modifiers.values():
        base *= mod
    return max(1, base)
```',
     ARRAY['hexforge', 'constraints', 'unit_types', 'parameterization']),
    
    (1, 'HexForge: Cube Coordinate Validation',
     'Always validate cube coordinates using HexMath.validate_cube().

```gdscript
static func validate_cube(coord: Vector3i) -> bool:
    # Cube coordinates must satisfy: x + y + z = 0
    return coord.x + coord.y + coord.z == 0

static func to_cube(offset: Vector2i) -> Vector3i:
    var x = offset.x
    var z = offset.y - (offset.x - (offset.x & 1)) / 2
    var y = -x - z
    return Vector3i(x, y, z)

static func to_offset(cube: Vector3i) -> Vector2i:
    var col = cube.x
    var row = cube.z + (cube.x - (cube.x & 1)) / 2
    return Vector2i(col, row)
```',
     ARRAY['hexforge', 'hex_grid', 'coordinates', 'cube', 'offset']),
    
    (2, 'Turn-Based Combat State Machine',
     'Use enum-based state machine for combat phases.

```gdscript
enum CombatState {
    SETUP,
    FORMATION_SELECT,
    PLAYER_TURN,
    ENEMY_TURN,
    RESOLUTION,
    ENDED
}

var current_state: CombatState = CombatState.SETUP

func transition_to(new_state: CombatState) -> void:
    _exit_state(current_state)
    current_state = new_state
    _enter_state(new_state)

func _enter_state(state: CombatState) -> void:
    match state:
        CombatState.PLAYER_TURN:
            _start_player_turn()
        CombatState.ENEMY_TURN:
            _start_enemy_turn()
        # ... etc

func _exit_state(state: CombatState) -> void:
    match state:
        CombatState.PLAYER_TURN:
            _cleanup_player_turn()
        # ... etc
```',
     ARRAY['combat', 'state_machine', 'turn_based', 'enum']),
    
    (3, 'Godot Resource Serialization',
     'Use Godot''s Resource system for save/load with proper type hints.

```gdscript
# Data class extending Resource
class_name ProvinceData
extends Resource

@export var id: int
@export var name: String
@export var owner_id: String
@export var soldiers: int
@export var gold: int
@export var food: int

func to_dict() -> Dictionary:
    return {
        "id": id,
        "name": name,
        "owner_id": owner_id,
        "soldiers": soldiers,
        "gold": gold,
        "food": food
    }

static func from_dict(data: Dictionary) -> ProvinceData:
    var pd = ProvinceData.new()
    pd.id = data.get("id", 0)
    pd.name = data.get("name", "")
    pd.owner_id = data.get("owner_id", "")
    pd.soldiers = data.get("soldiers", 0)
    pd.gold = data.get("gold", 0)
    pd.food = data.get("food", 0)
    return pd
```',
     ARRAY['resource', 'serialization', 'save_load', 'data_class']),
    
    (4, 'EventBus Pattern for Godot',
     'Use a global EventBus singleton for cross-system communication.

```gdscript
# autoload/event_bus.gd
extends Node

@warning_ignore("unused_signal")
signal ProvinceSelected(id: int)

@warning_ignore("unused_signal")
signal ProvinceDataChanged(id: int, field: String, value: Variant)

@warning_ignore("unused_signal")
signal TurnEnded(month: int, year: int)

@warning_ignore("unused_signal")
signal BattleResolved(result: Dictionary)

# Usage in any script:
# EventBus.ProvinceSelected.emit(province_id)
# EventBus.ProvinceSelected.connect(_on_province_selected)
```',
     ARRAY['eventbus', 'signals', 'singleton', 'architecture']),
    
    (7, 'Jewelflame: GameState Singleton Pattern',
     'GameState is the central data store for strategic layer.

```gdscript
# autoload/game_state.gd
extends Node

var provinces: Dictionary = {}  # int -> ProvinceData
var families: Dictionary = {}   # String -> FamilyData
var characters: Dictionary = {} # String -> CharacterData

# Turn management
var current_family_index: int = 0
var families_order: Array[String] = ["blanche", "lyle", "coryll"]
var current_month: int = 1
var current_year: int = 1

func _ready():
    load_initial_data()

func get_current_family() -> String:
    return families_order[current_family_index]

func advance_turn():
    reset_family_exhaustion(get_current_family())
    current_family_index = (current_family_index + 1) % families_order.size()
    if current_family_index == 0:
        advance_month()
    EventBus.TurnEnded.emit(current_month, current_year)
```',
     ARRAY['jewelflame', 'gamestate', 'singleton', 'turn_management']),
    
    (7, 'Jewelflame: Province Garrison Management',
     'Store and manage units in provinces with Resource-based data.

```gdscript
# resources/data_classes/province_data.gd
class_name ProvinceData
extends Resource

@export var id: int
@export var name: String
@export var owner_id: String
@export var governor_id: String
@export var soldiers: int
@export var gold: int
@export var food: int
@export var loyalty: int
@export var cultivation: int
@export var protection: int
@export var is_capital: bool
@export var is_exhausted: bool
@export var neighbors: Array[int] = []
@export var terrain_type: String = "plains"
@export var polygon_points: PackedVector2Array

# Garrison composition (for tactical battles)
@export var garrison_units: Array[Dictionary] = []
```',
     ARRAY['jewelflame', 'province', 'garrison', 'resource']),
    
    (7, 'Jewelflame: Strategic to Tactical Bridge',
     'Use BattleLauncher to connect strategic map to tactical battle.

```gdscript
# autoload/battle_launcher.gd
extends Node

const TacticalBattleScene = preload("res://scenes/tactical/tactical_battle.tscn")

func launch_battle(attacker_province_id: int, defender_province_id: int,
                   attacker_force_percent: float = 0.7) -> void:
    var attacker_province = GameState.provinces.get(attacker_province_id)
    var defender_province = GameState.provinces.get(defender_province_id)
    
    var attacker_data = {
        "province_id": attacker_province_id,
        "province_name": attacker_province.name,
        "family_id": attacker_province.owner_id,
        "lord": _get_province_lord(attacker_province),
        "units": _build_unit_stacks(attacker_province, attacker_force_percent),
        "total_soldiers": attacker_province.soldiers
    }
    
    var battle = TacticalBattleScene.instantiate()
    battle.attacker_data = attacker_data
    battle.defender_data = defender_data
    battle.battle_ended.connect(_on_battle_ended)
    
    get_tree().change_scene_to_packed(TacticalBattleScene)
```',
     ARRAY['jewelflame', 'tactical', 'strategic', 'bridge', 'battle']),
    
    (5, 'Godot 4.6 Syntax Updates',
     'Use modern Godot 4.6 syntax patterns.

Old (Godot 3.x):
```gdscript
yield(timer, "timeout")
get_tree().change_scene("res://scene.tscn")
```

New (Godot 4.6):
```gdscript
await timer.timeout
await get_tree().create_timer(1.0).timeout
get_tree().change_scene_to_file("res://scene.tscn")
get_tree().change_scene_to_packed(scene_resource)
```

Type hints:
```gdscript
func calculate_damage(attack: int, defense: int) -> int:
    return max(1, attack - defense)

var provinces: Dictionary[int, ProvinceData] = {}
var units: Array[BattleUnit] = []
```',
     ARRAY['godot4', 'syntax', 'gdscript', 'migration']);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to godot_knowledge
DROP TRIGGER IF EXISTS update_godot_knowledge_updated_at ON godot_knowledge;
CREATE TRIGGER update_godot_knowledge_updated_at
    BEFORE UPDATE ON godot_knowledge
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Verify setup
SELECT 'Knowledge base setup complete' AS status;
