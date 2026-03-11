# Godot 4.5+ Common Issues & Solutions
## Quick Reference for Development Troubleshooting

**Project:** Jewelflame / General Godot 4.5+  
**Last Updated:** March 11, 2026  

---

## Class & Type System

### Issue: "Parser Error: Class "X" hides a global script class"
**Symptoms:**
```
Parser Error: Class "UnitData" hides a global script class.
```

**Cause:** Inner class name conflicts with `class_name` declared in another file.

**Solution:**
```gdscript
# Instead of inner class with conflicting name
class UnitDataInner:  # Rename to avoid conflict
    var id: String
    var hp: int

# Or remove class_name from external file if not needed globally
```

---

### Issue: "Parser Error: Could not find type "X" in the current scope"
**Symptoms:**
```
Could not find type "HexGrid" in the current scope.
```

**Cause:** Using `class_name` type annotations with dynamically loaded scripts.

**Solution:**
```gdscript
# Use const preloads instead of class_name
const HexGrid = preload("res://hexforge/core/hex_grid.gd")
const HexCell = preload("res://hexforge/core/hex_cell.gd")

# Then use without class_name prefix
var grid = HexGrid.new()
var cell: Variant = HexCell.new(0, 0, 0)  # Use Variant instead of HexCell
```

---

### Issue: "Parser Error: The function signature doesn't match the parent"
**Symptoms:**
```
The function signature doesn't match the parent. Parent: to_string()
```

**Cause:** Defining `to_string()` which conflicts with Object's built-in method.

**Solution:**
```gdscript
# Rename your method
func to_string_debug() -> String:
    return "Hex(%d, %d, %d)" % [q, r, s]

# Or override _to_string() for custom string representation
func _to_string() -> String:
    return "HexCell(%d, %d, %d)" % [q, r, s]
```

---

### Issue: "Parser Error: The method "is_processing()" already exists in parent class"
**Symptoms:**
```
The method "is_processing()" already exists in parent class.
```

**Cause:** Method name conflicts with Node built-in method.

**Solution:**
```gdscript
# Rename your method
func is_ai_processing() -> bool:
    return _processing_state
```

---

## Type Annotations & Inference

### Issue: "Parser Error: Could not infer the type of variable"
**Symptoms:**
```
Could not infer the type of the variable "cell" because the value doesn't have a set type.
```

**Cause:** Using `:=` with untyped return values.

**Solution:**
```gdscript
# Instead of inferred type
var cell := grid.get_cell(pos)  # FAILS if get_cell returns Variant

# Use explicit type or Variant
var cell: Variant = grid.get_cell(pos)
# OR
var cell = grid.get_cell(pos)  # Remove : if type is unknown
```

---

### Issue: "Parser Error: Static function cannot access instance variables"
**Symptoms:**
```
Static function cannot access instance variable "_grid".
```

**Cause:** Trying to access instance variables in @staticmethod.

**Solution:**
```gdscript
# Pass instance as parameter
static func from_dict(data: Dictionary, grid: Variant) -> Variant:
    var cell = HexCell.new(data.q, data.r, data.s)
    cell._grid = grid  # grid passed as parameter
    return cell
```

---

## Scene Tree & Node Issues

### Issue: "Attempt to call function "X" on a null instance"
**Symptoms:**
```
Attempt to call function "queue_free" on a null instance.
```

**Cause:** Node was freed but variable still references it.

**Solution:**
```gdscript
# Check if node exists before using
if is_instance_valid(node) and not node.is_queued_for_deletion():
    node.queue_free()

# Or use weakref for potentially freed nodes
var weak_ref = weakref(node)
if weak_ref.get_ref():
    weak_ref.get_ref().do_something()
```

---

### Issue: "Signal "X" does not exist on type"
**Symptoms:**
```
Signal "button_pressed" does not exist on type "Button"
```

**Cause:** Wrong signal name (Button uses `pressed`, not `button_pressed`).

**Solution:**
```gdscript
# Check correct signal names in documentation
button.pressed.connect(_on_button_pressed)  # ✅ Correct
button.button_pressed.connect(...)           # ❌ Wrong name
```

---

### Issue: "Cannot get path of node as it is not in the scene tree"
**Symptoms:**
```
Cannot get path of node as it is not in the scene tree.
```

**Cause:** Trying to get_node_path() on a node before it's added to tree.

**Solution:**
```gdscript
# Wait for node to enter tree
await ready  # In _ready()
# OR
if is_inside_tree():
    var path = get_path()
```

---

## Autoload & Singletons

### Issue: "Parser Error: Could not find singleton"
**Symptoms:**
```
Parser Error: Could not find singleton "GameState"
```

**Cause:** Autoload not configured in Project Settings.

**Solution:**
```gdscript
# Project -> Project Settings -> Autoload
# Add: res://autoload/game_state.gd
# Name: GameState

# Access with @onready in scenes
@onready var game_state = get_node("/root/GameState")
# OR use class_name if GameState has it
```

---

### Issue: "Cyclic reference" between autoloads
**Symptoms:**
```
Cyclic reference between 'res://autoload/a.gd' and 'res://autoload/b.gd'.
```

**Cause:** Two autoloads reference each other with preloads.

**Solution:**
```gdscript
# Instead of preload at top
const OtherAutoload = preload("res://autoload/b.gd")  # ❌ Causes cycle

# Use get_node() at runtime
var other = get_node("/root/OtherAutoload")  # ✅ Runtime lookup
```

---

## Resource Loading

### Issue: "Failed loading resource: res://X"
**Symptoms:**
```
Failed loading resource: res://assets/portraits/lord_karl.png
```

**Cause:** File doesn't exist or wrong path.

**Solution:**
```gdscript
# Verify file exists before loading
var path = "res://assets/portraits/lord_karl.png"
if FileAccess.file_exists(path):
    var texture = load(path)
else:
    push_warning("Missing texture: " + path)
    texture = load("res://assets/portraits/placeholder.png")
```

---

### Issue: "Invalid call. Nonexistent function 'instance'"
**Symptoms:**
```
Invalid call. Nonexistent function 'instance' in base 'PackedScene'.
```

**Cause:** Using Godot 3.x syntax in Godot 4.

**Solution:**
```gdscript
# Godot 3.x (OLD)
var node = scene.instance()  # ❌ No longer works

# Godot 4.x (NEW)
var node = scene.instantiate()  # ✅ Correct
```

---

### Issue: "Texture has no data"
**Symptoms:**
```
Texture has no data (or has been freed).
```

**Cause:** Texture not imported or import settings wrong.

**Solution:**
```
# In Godot Editor:
# 1. Select texture in FileSystem
# 2. Check Import tab
# 3. Set Preset to "2D Pixel" for pixel art
# 4. Click "Reimport"
```

---

## UI & Control Nodes

### Issue: "TextureRect showing "No Image" placeholder"
**Symptoms:**
TextureRect displays gray box with "No Image" text.

**Cause:** Texture is null or failed to load.

**Solution:**
```gdscript
@onready var portrait: TextureRect = $PortraitFrame/Portrait

func _ready():
    # Set texture
    portrait.texture = load("res://assets/portraits/hero.png")
    
    # If texture is null, set a fallback
    if portrait.texture == null:
        portrait.texture = preload("res://assets/ui/placeholder.png")
    
    # For debugging - check what's assigned
    print("Portrait texture: ", portrait.texture)
```

---

### Issue: "NinePatchRect not stretching correctly"
**Symptoms:**
Borders appear stretched or corners don't render.

**Cause:** Incorrect patch margins.

**Solution:**
```gdscript
# In code or Inspector
patch_margin_left = 8
patch_margin_right = 8
patch_margin_top = 8
patch_margin_bottom = 8

# Set stretch mode
axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_TILE
axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_TILE
```

---

### Issue: "Control nodes not resizing with window"
**Symptoms:**
UI stays fixed size when window is resized.

**Cause:** No anchors or container layout set.

**Solution:**
```gdscript
# Set anchors to fill parent
anchors_preset = Control.PRESET_FULL_RECT

# OR use specific anchors
anchor_left = 0.0
anchor_right = 1.0
anchor_top = 0.0
anchor_bottom = 1.0
offset_left = 10
offset_right = -10
offset_top = 10
offset_bottom = -10
```

---

## HexForge Specific Issues

### Issue: "Invalid cube coordinates" assertion failure
**Symptoms:**
```
Assertion failed: Invalid cube coordinates (q + r + s != 0)
```

**Cause:** Cube coordinates don't sum to zero.

**Solution:**
```gdscript
# Always validate
func create_cell(q: int, r: int, s: int) -> HexCell:
    assert(abs(q + r + s) <= 0.001, "Invalid cube: %d + %d + %d = %d" % [q, r, s, q+r+s])
    return HexCell.new(q, r, s)

# Or convert axial properly
func axial_to_cube(q: int, r: int) -> Vector3i:
    return Vector3i(q, r, -q - r)
```

---

### Issue: "Pathfinder returns empty path"
**Symptoms:**
Pathfinder returns empty array when path should exist.

**Cause:** Obstacles blocking all routes or invalid start/end.

**Solution:**
```gdscript
# Debug pathfinding
func find_path_debug(start: Vector2i, end: Vector2i):
    print("Finding path from ", start, " to ", end)
    
    # Check if cells exist
    if not grid.has_cell(start):
        push_error("Start cell doesn't exist")
        return []
    if not grid.has_cell(end):
        push_error("End cell doesn't exist")
        return []
    
    # Check if end is blocked
    var end_cell = grid.get_cell(end)
    if end_cell.movement_cost < 0:
        push_warning("End cell is blocked")
    
    return Pathfinder.find_path(grid, start, end)
```

---

### Issue: "Line of sight blocked incorrectly"
**Symptoms:**
LOS says blocked when it should be clear, or vice versa.

**Cause:** Elevation calculation error.

**Solution:**
```gdscript
# Debug LOS
func check_los_debug(start: Vector2i, end: Vector2i):
    var start_cell = grid.get_cell(start)
    var end_cell = grid.get_cell(end)
    
    print("Start elevation: ", start_cell.elevation)
    print("End elevation: ", end_cell.elevation)
    print("Max elevation between: ", _get_max_elevation_on_line(start, end))
    
    return LineOfSight.has_line_of_sight(grid, start, end)
```

---

## Save/Load Issues

### Issue: "Error parsing JSON"
**Symptoms:**
```
Error parsing JSON: Unexpected character at line 1.
```

**Cause:** Corrupted save file or malformed JSON.

**Solution:**
```gdscript
func load_game(slot: String) -> bool:
    var path = "user://saves/%s.json" % slot
    
    if not FileAccess.file_exists(path):
        return false
    
    var file = FileAccess.open(path, FileAccess.READ)
    var json_string = file.get_as_text()
    file.close()
    
    var result = JSON.parse_string(json_string)
    if result == null:
        push_error("Corrupted save file: " + slot)
        # Quarantine corrupted file
        var quarantine_path = path + ".corrupt-" + str(Time.get_unix_time_from_system())
        DirAccess.rename_absolute(path, quarantine_path)
        return false
    
    # Continue loading...
    return true
```

---

### Issue: "Resource ID out of bounds" on load
**Symptoms:**
```
Resource ID out of bounds: 12345
```

**Cause:** Trying to access resource that wasn't saved/loaded properly.

**Solution:**
```gdscript
# Save resources by unique path, not by instance ID
func serialize_resource(res: Resource) -> Dictionary:
    return {
        "path": res.resource_path,
        "sub_resources": serialize_sub_resources(res)
    }

func deserialize_resource(data: Dictionary) -> Resource:
    if ResourceLoader.exists(data.path):
        return load(data.path)
    else:
        push_warning("Missing resource: " + data.path)
        return null
```

---

## Performance Issues

### Issue: "Frame drops during hex grid operations"
**Symptoms:**
FPS drops when rendering large grids or calculating paths.

**Cause:** Inefficient algorithms or too many draw calls.

**Solution:**
```gdscript
# Use viewport culling
func _process(delta):
    # Only render visible hexes
    var viewport_rect = get_viewport_rect()
    for cell in grid.get_cells():
        var world_pos = hex_to_world(cell.axial)
        if viewport_rect.has_point(world_pos):
            render_cell(cell)

# Cache expensive calculations
var _path_cache: Dictionary = {}

func get_cached_path(start: Vector2i, end: Vector2i) -> Array:
    var key = "%d,%d-%d,%d" % [start.x, start.y, end.x, end.y]
    if not _path_cache.has(key):
        _path_cache[key] = Pathfinder.find_path(grid, start, end)
    return _path_cache[key]
```

---

### Issue: "Memory leak: Instances not being freed"
**Symptoms:**
Memory usage grows over time, nodes accumulate in Remote Tree.

**Cause:** References preventing garbage collection.

**Solution:**
```gdscript
# Disconnect signals before freeing
func cleanup_unit(unit: Node):
    unit.tree_exiting.disconnect(_on_unit_died)
    unit.health_changed.disconnect(_on_health_changed)
    
    # Remove from lists
    _active_units.erase(unit)
    
    # Now safe to free
    unit.queue_free()

# Use weakref for non-owning references
var _weak_unit_ref = weakref(unit)
# Later...
if _weak_unit_ref.get_ref():
    _weak_unit_ref.get_ref().do_something()
```

---

## Quick Fixes Reference

| Error | Quick Fix |
|-------|-----------|
| `Could not find type` | Use `const X = preload("...")` + `Variant` type |
| `Class hides global class` | Rename inner class or remove external `class_name` |
| `Already exists in parent` | Rename method to avoid Godot built-in |
| `Cannot infer type` | Change `:=` to `=` or use `: Variant` |
| `Nonexistent function 'instance'` | Change to `instantiate()` (Godot 4) |
| `Failed loading resource` | Check `FileAccess.file_exists()` before loading |
| `Cyclic reference` | Use `get_node()` instead of `preload()` for autoloads |
| `Signal does not exist` | Check correct signal name in docs |
| `Texture has no data` | Reimport with "2D Pixel" preset |
| `Invalid cube coords` | Ensure q + r + s = 0 |

---

## Debug Output Helpers

```gdscript
# Print node hierarchy
func print_tree_pretty(node: Node, indent: String = ""):
    print(indent + node.name + " (" + node.get_class() + ")")
    for child in node.get_children():
        print_tree_pretty(child, indent + "  ")

# Print dictionary formatted
func print_dict(d: Dictionary):
    print(JSON.stringify(d, "  "))

# Measure performance
func time_operation(name: String, callable: Callable):
    var start = Time.get_ticks_usec()
    callable.call()
    var end = Time.get_ticks_usec()
    print("%s took %d μs" % [name, end - start])
```

---

**Connection ID:** ec74b0f4-ca88-40ad-9532-084ce680ef07
