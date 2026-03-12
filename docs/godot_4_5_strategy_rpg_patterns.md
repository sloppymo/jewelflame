# Godot 4.5 Production Architecture: Strategy RPG Patterns
## Corrected & Enhanced Edition – March 2026

---

## Quick Reference Card (Top 10 Rules)

1. **Use Typed Dictionaries**: Godot 4.4+ supports `Dictionary[KeyType, ValueType]`. Eliminates runtime casting overhead and enables editor autocompletion.

2. **TileMapLayer over TileMap**: Godot 4.5 introduces chunked physics for TileMapLayer. Deprecate the monolithic TileMap node for new projects.

3. **StringName for Hot Paths**: Prefix string literals with `&` (e.g., `&"province_selected"`) for interned strings that enable O(1) dictionary lookups and zero-allocation comparisons.

4. **Pool UI Nodes**: For lists >20 items, never `add_child()`/`queue_free()` dynamically. Pool Control nodes and update data to prevent frame drops.

5. **Enforce @tool Safety**: Use `if Engine.is_editor_hint(): return` to prevent editor tool scripts from executing game logic or emitting signals in the inspector.

6. **Resource vs. RefCounted**: Extend Resource for disk-serializable data (lords, provinces); extend RefCounted for transient runtime state (combat calculations, pathfinding buffers).

7. **Signal Cleanup is Mandatory**: Always `disconnect()` signals before `queue_free()` or when pooling UI items. Use `Callable.is_valid()` guards when holding references to external nodes.

8. **State Machines via process_mode**: Use Node-based FSMs toggling `process_mode = PROCESS_MODE_DISABLED` rather than boolean checks in `_process`. This guarantees zero CPU cost for inactive states.

9. **SubViewports for Retro Scaling**: Enforce integer scaling via SubViewportContainer with `stretch = false` and `canvas_item_default_texture_filter = NEAREST`. Never use camera zoom for pixel-art upscaling.

10. **Safe Serialization**: Never `load()` user-provided `.tres` files. Use `ResourceLoader.FLAG_TRUST_LOAD_VARIABLES` only for trusted assets; for save games, use ConfigFile, JSON, or binary serialization instead.

---

## SECTION 1: Core Language & Performance Patterns

### Pattern: Typed Dictionaries for Database Operations
**Godot Version:** 4.4+ | **Complexity:** Low | **Use Case:** Province lookup tables, lord rosters, item databases

**The Rule:** Replace untyped Dictionaries with strictly typed variants to bypass Variant conversion overhead and enable static analysis.

```gdscript
[CATEGORY:DATA_STRUCTURES] [COMPLEXITY:LOW] [RISK:NONE]

class_name ProvinceManager extends Node

# Static typing eliminates runtime type checks and enables inspector editing
@export var provinces: Dictionary[StringName, ProvinceData] = {}
@export var lord_locations: Dictionary[StringName, StringName] = {}  # lord_id -> province_id

func get_province(id: StringName) -> ProvinceData:
    # Zero casting overhead - direct pointer access
    return provinces.get(id, null)

func move_lord(lord_id: StringName, to_province: StringName) -> void:
    lord_locations[lord_id] = to_province
    EventBus.lord_moved.emit(lord_id, to_province)
```

**Anti-Pattern (Avoid):**
```gdscript
# Untyped - forces Variant boxing/unboxing on every access
var provinces = {}

func get_province(id):  # Return type unknown
    return provinces.get(id)  # Runtime type check required
```

**LLM Context Note:** *When generating lookup tables, cache systems, or registry patterns, default to Typed Dictionaries. They provide compile-time safety and significant CPU optimization for tight loops. Token-efficient summary: [Dictionary[KeyType, ValueType], StringName keys, zero casting].*

---

### Pattern: StringName Interning for Signal Performance
**Godot Version:** 4.x | **Complexity:** Low | **Use Case:** High-frequency signal emissions, dictionary keys in `_process`

**The Rule:** Use `&"string_literal"` syntax for signal names and dictionary keys accessed in performance-critical sections to avoid string duplication and enable fast hashing.

```gdscript
[CATEGORY:PERFORMANCE] [COMPLEXITY:LOW] [RISK:NONE]

class_name BattleAnimator extends Node

# StringName interning - O(1) hash comparison, zero allocation
const ANIM_ATTACK := &"attack"
const ANIM_DEFEND := &"defend"
const ANIM_RETREAT := &"retreat"

# Cache for O(1) lookup instead of string hashing every frame
var _animation_map: Dictionary[StringName, Animation] = {}

func _ready() -> void:
    # Pre-hash at startup, not during gameplay
    _animation_map[ANIM_ATTACK] = load("res://anims/attack.res")
    _animation_map[ANIM_DEFEND] = load("res://anims/defend.res")

func play_animation(anim_name: StringName) -> void:
    # Direct pointer comparison - no string hashing
    if anim_name == ANIM_ATTACK:
        _play_attack()
    elif anim_name == ANIM_DEFEND:
        _play_defend()

# Signal emission with interned names - zero allocation
func _on_damage_taken() -> void:
    EventBus.emit(&"unit_damaged", self)  # &"" = StringName literal
```

**Anti-Pattern (Avoid):**
```gdscript
# String literals create new String objects and hash on every comparison
if anim_name == "attack":  # Allocates String, computes hash
    pass

EventBus.emit("unit_damaged", self)  # Allocates StringName at runtime
```

---

### Pattern: Node Pooling for Dynamic UI Lists
**Godot Version:** 4.x | **Complexity:** Medium | **Use Case:** Unit rosters, battle logs, inventory grids, message histories

**The Rule:** Pre-instantiate a fixed pool of Control nodes and recycle them. Never instantiate during gameplay for lists with >20 items.

```gdscript
[CATEGORY:UI_PERFORMANCE] [COMPLEXITY:MEDIUM] [RISK:MEMORY_LEAKS_IF_MISSED]

class_name UnitRosterPanel extends PanelContainer

const POOL_SIZE := 50
const ENTRY_SCENE := preload("res://ui/unit_entry.tscn")

var _entry_pool: Array[UnitEntry] = []
var _active_entries: Array[UnitEntry] = []
var _available_entries: Array[UnitEntry] = []

func _ready() -> void:
    # Pre-instantiate all entries at load time
    for i in range(POOL_SIZE):
        var entry: UnitEntry = ENTRY_SCENE.instantiate()
        entry.visible = false
        _entry_pool.append(entry)
        _available_entries.append(entry)
        %EntryContainer.add_child(entry)

func display_units(units: Array[UnitData]) -> void:
    # Recycle: hide all current, return to available pool
    for entry in _active_entries:
        entry.visible = false
        # CRITICAL: Disconnect signals before recycling
        if entry.clicked.is_connected(_on_unit_clicked):
            entry.clicked.disconnect(_on_unit_clicked)
    _available_entries.append_array(_active_entries)
    _active_entries.clear()
    
    # Activate only what we need - NO INSTANTIATION
    for unit in units:
        if _available_entries.is_empty():
            push_warning("Pool exhausted! Increase POOL_SIZE.")
            break
        
        var entry: UnitEntry = _available_entries.pop_back()
        entry.setup(unit)
        entry.visible = true
        entry.clicked.connect(_on_unit_clicked.bind(unit.id))
        _active_entries.append(entry)

func _exit_tree() -> void:
    # CRITICAL: Clean up all signal connections before free
    for entry in _entry_pool:
        entry.clicked.disconnect_all()
```

**Memory Safety Checklist:**
- [ ] Disconnect all signals before recycling
- [ ] Clear parent references before reparenting
- [ ] Use `is_instance_valid()` before accessing pooled nodes
- [ ] Pool size > 2x max expected concurrent items

---

### Pattern: @tool Guard for Editor Scripts
**Godot Version:** 4.x | **Complexity:** Low | **Use Case:** Custom editor plugins, inspector enhancements, gizmos

**The Rule:** Always guard game logic in `@tool` scripts with `Engine.is_editor_hint()` checks to prevent scene corruption and unexpected side effects.

```gdscript
[CATEGORY:EDITOR_SAFETY] [COMPLEXITY:LOW] [RISK:SCENE_CORRUPTION]

@tool
class_name ProvinceMapEditor extends Node2D

@export var show_garrison_radius: bool = false:
    set(value):
        show_garrison_radius = value
        # Only update visual gizmo, not game state
        queue_redraw()

func _ready() -> void:
    # MANDATORY GUARD: Prevent game initialization in editor
    if Engine.is_editor_hint():
        return
    
    # Game-only initialization
    EventBus.province_selected.connect(_on_province_selected)
    _initialize_strategic_ai()

func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        # Editor-only: Update gizmo animations
        _update_editor_preview()
        return
    
    # Game-only: Strategic AI processing
    _strategic_ai_tick(delta)
```

**Common @tool Pitfalls:**
- ❌ Emitting signals that trigger resource loading in editor
- ❌ Instantiating gameplay nodes in `_ready()` without guard
- ❌ Modifying shared resources that affect other scenes
- ❌ Using random seeding that changes on every inspector refresh

---

### Pattern: Resource vs RefCounted Decision Tree
**Godot Version:** 4.x | **Complexity:** Low | **Use Case:** Data architecture, save systems, runtime optimization

**The Rule:** Use this decision matrix for every data class:

| Criteria | Resource | RefCounted | Node |
|----------|----------|------------|------|
| Disk Serialization | ✅ Yes | ❌ No | ⚠️ Via PackedScene |
| Inspector Editing | ✅ Full | ❌ None | ✅ Partial |
| Reference Counting | ✅ Yes | ✅ Yes | ✅ Tree-based |
| Scene Tree Required | ❌ No | ❌ No | ✅ Yes |
| _process/_physics | ❌ No | ❌ No | ✅ Yes |

```gdscript
[CATEGORY:ARCHITECTURE] [COMPLEXITY:LOW] [RISK:DESIGN_DEBT]

# RESOURCE: Serialize to disk, edit in inspector
class_name ProvinceData extends Resource
    @export var name: StringName
    @export var gold_income: int
    @export var garrison: Array[UnitData]
    @export var owner_faction: StringName

# REFCOUNTED: Runtime-only, automatic memory management
class_name CombatCalculator extends RefCounted
    var attacker_stats: UnitStats
    var defender_stats: UnitStats
    var terrain_modifiers: float
    
    func calculate_damage() -> int:
        # Heavy math, no disk persistence needed
        return _complex_calculation()

# NODE: Scene tree integration, visual representation
class_name BattleUnit extends Node2D
    var data: UnitData  # Resource reference
    var state_machine: StateMachine
    
    func _process(delta: float) -> void:
        # Visual updates, input handling
        _update_sprite_position()
```

**HexForge-Specific Guidance:**
- `ProvinceData` → **Resource** (saved in province_database.tres)
- `HexCell` → **Resource** (serialized for save games)
- `Pathfinder` → **RefCounted** (temporary calculation buffer)
- `BattleUnit` → **Node** (visual + physics + AI)

---

### Pattern: Signal Cleanup Lifecycle
**Godot Version:** 4.x | **Complexity:** Medium | **Use Case:** All signal connections, especially in pooled objects and dynamic UI

**The Rule:** Implement a formal disconnection phase before any node enters a recyclable or deletable state.

```gdscript
[CATEGORY:MEMORY_SAFETY] [COMPLEXITY:MEDIUM] [RISK:CRASH_ON_ACCESS]

class_name StrategicPanel extends PanelContainer

var _connected_signals: Array[Dictionary] = []  # Track for cleanup

func connect_to_province(province: ProvinceNode) -> void:
    # Track connections for later cleanup
    var callback := _on_province_updated.bind(province.id)
    province.updated.connect(callback)
    
    _connected_signals.append({
        "source": province,
        "signal": &"updated",
        "callback": callback
    })

func disconnect_all() -> void:
    # Formal cleanup phase
    for conn in _connected_signals:
        if is_instance_valid(conn.source):
            if conn.source.is_connected(conn.signal, conn.callback):
                conn.source.disconnect(conn.signal, conn.callback)
    _connected_signals.clear()

func _notification(what: int) -> void:
    match what:
        NOTIFICATION_PREDELETE:
            # Last chance cleanup
            disconnect_all()
        NOTIFICATION_EXIT_TREE:
            # Parent changed or tree exit
            disconnect_all()

# Callable.is_valid() guard for external references
func _on_external_event(data: Dictionary) -> void:
    # If target was freed, is_valid() returns false
    if _current_target and _current_target.is_valid():
        _current_target.call(data)
```

**Signal Connection Checklist:**
- [ ] Track all connections in a collection
- [ ] Disconnect in `_exit_tree()` and `NOTIFICATION_PREDELETE`
- [ ] Use `is_connected()` before disconnecting
- [ ] Nullify references after disconnect
- [ ] Use `Callable.is_valid()` for stored callables

---

### Pattern: State Machine via process_mode
**Godot Version:** 4.x | **Complexity:** Medium | **Use Case:** Turn-based phases, UI states, AI behaviors, menu systems

**The Rule:** Use `process_mode` toggling instead of boolean state checks for guaranteed zero-cost inactive states.

```gdscript
[CATEGORY:STATE_MANAGEMENT] [COMPLEXITY:MEDIUM] [RISK:LOGIC_ERRORS]

class_name TurnStateMachine extends Node

enum State { STRATEGIC, TACTICAL, DIALOGUE, MENU }

@onready var _strategic_state: StrategicState = $StrategicState
@onready var _tactical_state: TacticalState = $TacticalState
@onready var _dialogue_state: DialogueState = $DialogueState

func transition_to(new_state: State) -> void:
    # Disable ALL states first
    _strategic_state.process_mode = PROCESS_MODE_DISABLED
    _tactical_state.process_mode = PROCESS_MODE_DISABLED
    _dialogue_state.process_mode = PROCESS_MODE_DISABLED
    
    # Enable only target state
    match new_state:
        State.STRATEGIC:
            _strategic_state.process_mode = PROCESS_MODE_INHERIT
            _strategic_state.on_enter()
        State.TACTICAL:
            _tactical_state.process_mode = PROCESS_MODE_INHERIT
            _tactical_state.on_enter()
        State.DIALOGUE:
            _dialogue_state.process_mode = PROCESS_MODE_INHERIT
            _dialogue_state.on_enter()
    
    EventBus.state_changed.emit(new_state)

# Each state node only runs when active
class_name StrategicState extends Node
    func _process(delta: float) -> void:
        # Only runs when process_mode = INHERIT and parent is active
        _handle_strategic_input()
        _update_province_highlights()
    
    func on_enter() -> void:
        EventBus.strategic_started.emit()
```

**Why process_mode over boolean checks:**
- ❌ Boolean: `_process` still called, branch misprediction, cache pollution
- ✅ process_mode: Node removed from processing list, zero CPU cost

---

### Pattern: SubViewport Retro Scaling
**Godot Version:** 4.x | **Complexity:** Medium | **Use Case:** Pixel-art games, integer scaling, crisp UI at non-native resolutions

**The Rule:** Use SubViewportContainer with nearest-neighbor filtering for authentic retro scaling. Never use camera zoom for pixel-art.

```gdscript
[CATEGORY:RENDERING] [COMPLEXITY:MEDIUM] [RISK:BLURRY_PIXELS]

class_name RetroScaler extends SubViewportContainer

@export var game_resolution := Vector2i(640, 360)  # 16:9 base
@export var integer_scale := true

func _ready() -> void:
    stretch = false  # CRITICAL: Disable stretch for integer scaling
    
    var subviewport := SubViewport.new()
    subviewport.size = game_resolution
    subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(subviewport)
    
    # Nearest neighbor for crisp pixels
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    
    # Add your game world here
    var game_world = preload("res://scenes/game_world.tscn").instantiate()
    subviewport.add_child(game_world)

func _on_viewport_size_changed() -> void:
    # Calculate integer scale factor
    var window_size := DisplayServer.window_get_size()
    var scale_x := window_size.x / game_resolution.x
    var scale_y := window_size.y / game_resolution.y
    var scale_factor := mini(scale_x, scale_y)
    
    if integer_scale:
        scale_factor = maxi(1, scale_factor)  # Never below 1x
    
    # Apply integer scale
    custom_minimum_size = Vector2(game_resolution) * scale_factor
    size = custom_minimum_size

# In Project Settings:
# rendering/textures/canvas_textures/default_texture_filter = Nearest
```

**Anti-Pattern (Avoid):**
```gdscript
# Camera zoom causes sub-pixel distortion
$Camera2D.zoom = Vector2(2, 2)  # ❌ Blurry on non-integer scales
```

---

### Pattern: Safe Save Game Serialization
**Godot Version:** 4.x | **Complexity:** High | **Use Case:** Save/load systems, user-generated content

**The Rule:** Never use Resource serialization for user data. Use ConfigFile, JSON, or custom binary formats.

```gdscript
[CATEGORY:SECURITY] [COMPLEXITY:HIGH] [RISK:REMOTE_CODE_EXECUTION]

class_name SaveGameManager extends Node

const SAVE_PATH := "user://saves/"

# SECURE: ConfigFile for save data (no script execution)
func save_game(slot: int) -> void:
    var config := ConfigFile.new()
    
    # Serialize only data, not scripts
    config.set_value("player", "gold", GameState.player_gold)
    config.set_value("player", "provinces_owned", GameState.provinces_owned)
    
    # Province data as nested sections
    for province in ProvinceDatabase.get_all():
        var section := "province_" + province.id
        config.set_value(section, "owner", province.owner_faction)
        config.set_value(section, "garrison_size", province.garrison.size())
    
    var err := config.save(SAVE_PATH + "save_%d.cfg" % slot)
    if err != OK:
        push_error("Save failed: " + str(err))

func load_game(slot: int) -> bool:
    var config := ConfigFile.new()
    var err := config.load(SAVE_PATH + "save_%d.cfg" % slot)
    
    if err != OK:
        return false
    
    # Validate all data before applying
    if not _validate_save_data(config):
        push_error("Save file corrupted or tampered")
        return false
    
    # Apply validated data
    GameState.player_gold = config.get_value("player", "gold", 0)
    # ... restore other values
    
    return true

func _validate_save_data(config: ConfigFile) -> bool:
    # Check for required sections
    if not config.has_section("player"):
        return false
    
    # Validate value ranges
    var gold: int = config.get_value("player", "gold", 0)
    if gold < 0 or gold > 999999:
        return false
    
    return true

# DANGEROUS - NEVER DO THIS:
func unsafe_load(path: String) -> void:
    var resource = load(path)  # ❌ Can execute arbitrary GDScript!
    if resource is SaveGame:
        resource.apply_to_game()
```

**Secure Serialization Options:**
1. **ConfigFile**: Built-in, section-based, human-readable
2. **JSON**: Universal, validate with schemas
3. **Binary**: Custom format, smallest size, fastest load
4. **Base64 + Compression**: For network transmission

---

### Pattern: StringName Interning (Technical Detail)
**Godot Version:** 4.x | **Complexity:** Low | **Use Case:** Signal names, dictionary keys, hot path comparisons

**Technical Correction:** StringName uses string interning (hashed canonical storage), not pointer comparison. This eliminates heap allocations for repeated string literals and accelerates dictionary lookups.

```gdscript
[CATEGORY:PERFORMANCE] [COMPLEXITY:LOW] [RISK:NONE]

class_name HexGridController extends Node2D
    # Pre-interned StringName - created once at compile time
    const CELL_CLICKED := &"cell_clicked"
    
    func _input(event: InputEvent) -> void:
        if event is InputEventMouseButton and event.pressed:
            var cell := local_to_map(get_local_mouse_position())
            # Fast O(1) hash comparison instead of string copy
            EventBus.emit_signal(CELL_CLICKED, cell)
    
    func _ready() -> void:
        # Connecting with StringName avoids runtime string allocation
        EventBus.connect(CELL_CLICKED, _on_cell_clicked)
    
    func _on_cell_clicked(cell: Vector2i) -> void:
        pass
```

**Anti-Pattern (Avoid):**
```gdscript
# Creates new String object every frame in _input
emit_signal("cell_clicked", cell)
```

---

### Pattern: Safe Async Boundaries
**Godot Version:** 4.x | **Complexity:** Medium | **Use Case:** Turn transitions, AI thinking delays, modal animations

**The Rule:** Avoid unbounded await in _process or physics loops. Coroutines are safe when scoped to state transitions with explicit cleanup, but dangerous when nested in polling functions.

```gdscript
[CATEGORY:ASYNC] [COMPLEXITY:MEDIUM] [RISK:MEMORY_LEAK]

class_name TurnStateMachine extends Node
    var _transition_guard: bool = false
    
    func transition_to(state_name: StringName) -> void:
        # Prevent reentrant calls during animation
        if _transition_guard:
            return
        _transition_guard = true
        
        # Safe: Await is bounded and followed by state cleanup
        await _play_transition_animation()
        _change_state(state_name)
        _transition_guard = false
    
    func _play_transition_animation() -> void:
        await get_tree().create_timer(0.5).timeout
```

**Anti-Pattern (Avoid):**
```gdscript
# DANGER: Creates new coroutine every frame if condition holds
func _process(delta: float) -> void:
    if waiting_for_input:
        await get_tree().create_timer(0.1).timeout  # Unbounded coroutine growth
```

**LLM Context Note:** *Await is safe in event handlers and state transitions, but never use it in _process, _physics_process, or inside loops without guards. Use process_mode changes for pausing instead of await loops. Token-efficient summary: [await safety, transition guards, no process awaits].*

---

## SECTION 2: Node Architecture & Scene Composition

### Pattern: UI Object Pooling for Large Rosters
**Godot Version:** 4.x | **Complexity:** High | **Use Case:** Scrolling lists of 50+ provinces/lords, inventory grids

**The Rule:** Pre-instantiate UI elements up to viewport capacity plus buffer (typically 15-25 nodes). Recycle by updating data and visibility rather than creating/destroying nodes.

```gdscript
[CATEGORY:UI_ARCHITECTURE] [COMPLEXITY:HIGH] [RISK:MEMORY_LEAK]

class_name RosterList extends ScrollContainer
    @export var item_scene: PackedScene
    @export var pool_size: int = 20
    
    var _pool: Array[Control] = []
    var _active_count: int = 0
    
    func _ready() -> void:
        for i in range(pool_size):
            var item: Control = item_scene.instantiate()
            item.hide()
            $VBoxContainer.add_child(item)
            _pool.append(item)
    
    func display_items(data_array: Array[Resource]) -> void:
        var needed := mini(data_array.size(), pool_size)
        
        # Update existing nodes
        for i in range(needed):
            _pool[i].set_data(data_array[i])
            if not _pool[i].visible:
                _pool[i].show()
        
        # Hide excess
        for i in range(needed, _active_count):
            _pool[i].hide()
        
        _active_count = needed
    
    func _exit_tree() -> void:
        # CRITICAL: Clean up signal connections before pool destruction
        for item in _pool:
            if item.has_meta("signal_connected"):
                item.pressed.disconnect(_on_item_selected)
```

**Critical Addition – Signal Cleanup:**
When pooling nodes that emit signals (buttons, interactive elements), you must disconnect signals before hiding or the pooled node will accumulate stale connections:

```gdscript
func recycle_item(item: Control) -> void:
    # CRITICAL: Disconnect before returning to pool
    if item.pressed.is_connected(_on_item_pressed):
        item.pressed.disconnect(_on_item_pressed)
    item.hide()
    _available_pool.append(item)
```

---

## Document Metadata
- **Created:** March 2026
- **Godot Version:** 4.5
- **Focus:** Strategy RPG Production Patterns
- **Categories:** Performance, Memory Safety, Editor Tools, Rendering, Security
- **Related:** HexForge Patterns, Jewelflame Architecture
