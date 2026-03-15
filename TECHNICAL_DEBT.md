# TECHNICAL_DEBT.md - Jewelflame Architecture Audit

## Executive Summary

| | |
|---|---|
| **Biggest Risk** | Save system references non-existent `to_dict()` methods on Resource classes, making persistence impossible |
| **Biggest Opportunity** | CommandProcessor autoload is commented out—re-enabling with StringName-based province IDs would centralize validation and enable undo/redo |
| **First Action** | Fix SaveManager to use Resource-based serialization via ResourceSaver instead of custom JSON dictionaries |

---

## Critical Issues (Break Core Functionality)

### 1. Save System Completely Broken

**File:** `autoload/save_manager.gd:17-35`

**Issue:** Attempts to call `to_dict()` and `from_dict()` on Resource classes that don't implement these methods. The SaveManager references legacy `families` and `characters` dictionaries that are never populated in the new StringName-based system.

**Current Broken Code:**
```gdscript
# save_manager.gd:19-24
for province in GameState.provinces.values():
    save_data.provinces.append(province.to_dict())  # ERROR: Method doesn't exist
```

**Godot Doc Reference:** [ResourceSaver](https://docs.godotengine.org/en/stable/classes/class_resourcesaver.html) - "ResourceSaver provides a method to save resources to the filesystem."

**Remediation:**
```gdscript
# Replace JSON serialization with Godot's built-in Resource saving
func save_game(slot: int) -> bool:
    var save_path = SAVE_DIR + "save_%d.tres" % slot
    
    # Create a wrapper resource that contains all game state
    var game_save := GameSaveResource.new()
    game_save.turn_number = TurnManager.turn_number
    game_save.faction_data = GameState.factions.duplicate()
    game_save.province_data = GameState.provinces.duplicate()
    
    var err := ResourceSaver.save(game_save, save_path)
    return err == OK
```

---

### 2. CommandProcessor Autoload Disabled

**File:** `project.godot:30`

**Issue:** CommandProcessor is commented out, forcing all validation logic into `sidebar.gd`. This creates UI-business logic coupling and prevents undo/redo.

**Current State:**
```ini
#project.godot
#CommandProcessor="*res://strategic/commands/command_processor.gd"
```

**Godot Doc Reference:** [Autoload Singletons](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html) - "Singletons are loaded before any other scene."

**Remediation:**

**project.godot** - Re-enable with proper initialization order:
```ini
CommandProcessor="*res://strategic/commands/command_processor.gd"
```

**strategic/commands/command_processor.gd** - Update to use StringName province IDs:
```gdscript
class_name CommandProcessor extends Node

var command_history: Array[Command] = []
var redo_stack: Array[Command] = []

func execute_attack(source_id: StringName, target_id: StringName) -> bool:
    if not _validate_attack(source_id, target_id):
        return false
    
    var cmd := AttackCommand.new(source_id, target_id)
    cmd.execute()
    command_history.append(cmd)
    redo_stack.clear()
    return true
```

---

### 3. Type Safety Violations in Sidebar

**File:** `ui/sidebar.gd:84-93`

**Issue:** Comparing enum values to integers without proper casting, causing potential state machine mismatches.

**Current Code:**
```gdscript
# sidebar.gd:84-93
var player_turn_value = 1  # Magic number
var ai_turn_value = 2

if new_state == player_turn_value:  # Risky integer comparison
```

**Godot Doc Reference:** [GDScript Static Typing](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html) - "Using static typing helps Godot detect errors at compile time."

**Remediation:**
```gdscript
# Use proper enum comparison
if new_state == TurnManager.State.PLAYER_TURN:
    _set_buttons_enabled(true)
elif new_state == TurnManager.State.AI_TURN:
    _set_buttons_enabled(false)
```

---

## High Severity (Cause Bugs/Performance Issues)

### 4. Signal Double-Connection Warning

**File:** `ui/sidebar.gd:59`

**Issue:** Button signals connected both in `.tscn` file and in `_ready()`, causing harmless but noisy warnings.

**Godot Doc Reference:** [Signals](https://docs.godotengine.org/en/stable/tutorials/scripting/signals.html) - "Avoid connecting the same signal multiple times."

**Remediation:** Remove the `call_deferred("_connect_signals")` since `.tscn` already handles connections via `[connection]` tags.

---

### 5. Legacy Integer-Based Province IDs in StrategicLayer

**File:** `scenes/strategic/strategic_layer.gd:49-58, 142-148`

**Issue:** StrategicLayer uses `int` for province IDs while the rest of the system uses StringName. Creates type mismatch when connecting to GameState.

**Current Code:**
```gdscript
# strategic_layer.gd:49
var selected_province_id: int = -1  # Old int-based system

# vs GameState which uses:
var selected_province_id: StringName = &""  # New system
```

**Remediation:** Refactor StrategicLayer to use StringName throughout.

---

### 6. BattleLauncher Uses Wrong Property Names

**File:** `autoload/battle_launcher.gd:35-36, 48-49`

**Issue:** References `province.name`, `province.owner_id`, `province.soldiers` which don't exist on ProvinceData resource (uses `province_name`, `owner_faction_id`, `troops`).

**Current Code:**
```gdscript
var attacker_province = GameState.provinces.get(attacker_province_id)
...
"province_name": attacker_province.name,  # ERROR: should be province_name
"family_id": attacker_province.owner_id,  # ERROR: should be owner_faction_id
```

**Remediation:** Update all property references to match ProvinceData schema.

---

## Medium Severity (Technical Debt)

### 7. Empty Character/Family Dictionaries

**File:** `autoload/game_state.gd:41-42, 221-264`

**Issue:** Maintains empty legacy dictionaries `families` and `characters` alongside the new typed system. Dead code increases maintenance burden.

**Remediation:** Remove legacy compatibility code or implement full character system.

---

### 8. Hardcoded Costs in Sidebar

**File:** `ui/sidebar.gd:322`

**Issue:** Defense upgrade cost calculation duplicated in sidebar instead of using ProvinceData method.

**Current Code:**
```gdscript
var cost: int = 10 * 10  # RECRUIT_COST * 10 - magic numbers
```

**Remediation:** Use `province.get_development_cost()` consistently.

---

### 9. EventBus Signals Use Wrong Types

**File:** `autoload/event_bus.gd:8-34`

**Issue:** Signals declare `int` parameters but GameState emits StringName for province/faction IDs.

**Current Code:**
```gdscript
signal ProvinceSelected(id: int)  # Should be StringName
```

**Remediation:** Update all signal signatures to use StringName.

---

### 10. DebugOverlay Accesses Tree in _process

**File:** `autoload/debug_overlay.gd:33-58`

**Issue:** Uses `get_node_or_null()` every frame for autoload access, causing unnecessary string lookups.

**Godot Doc Reference:** [Optimization](https://docs.godotengine.org/en/stable/tutorials/performance/index.html) - "Cache node references instead of looking them up repeatedly."

**Remediation:** Cache GameState and TurnManager references in `_ready()`.

---

## Low Severity (Code Quality)

### 11. Unused Method Parameters

**File:** `scenes/strategic/province_node.gd:58`

**Issue:** `_on_input_event` ignores `_viewport` and `_shape_idx` parameters.

**Remediation:** Prefix unused parameters with underscore: `_on_input_event(_v, event, _s)`.

---

### 12. Orphaned UI Controller Reference

**File:** `main_strategic.tscn:11`

**Issue:** References `strategic_ui_controller.gd` script but node uses `strategic_layer.gd` instead.

**Remediation:** Remove unused ext_resource entry.

---

### 13. Missing Type Hints in HexForge

**File:** `hexforge/core/hex_cell.gd:200`

**Issue:** `duplicate_data()` lacks return type annotation.

**Remediation:** Add explicit `-> HexCell` return type.

---

## Godot Documentation References

| Topic | URL | Justification |
|-------|-----|---------------|
| Resource Serialization | https://docs.godotengine.org/en/stable/classes/class_resourcesaver.html | Justifies using ResourceSaver over custom JSON |
| Autoload Initialization Order | https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html | Documents why TurnManager can access GameState in _ready |
| GDScript Static Typing | https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html | Explains why StringName > int for IDs |
| Signal Best Practices | https://docs.godotengine.org/en/stable/tutorials/scripting/signals.html | Documents signal connection patterns |
| Scene Tree Optimization | https://docs.godotengine.org/en/stable/tutorials/performance/index.html | Explains node reference caching |

---

## Action Priority Matrix

| Issue | Effort | Impact | Priority |
|-------|--------|--------|----------|
| 1. Save System Broken | Medium | Critical | **P0** |
| 2. CommandProcessor Disabled | Medium | High | **P1** |
| 6. BattleLauncher Property Names | Low | High | **P1** |
| 5. Integer vs StringName IDs | Medium | High | **P1** |
| 3. Type Safety Violations | Low | Medium | **P2** |
| 4. Signal Double-Connection | Low | Low | **P3** |
| 7. Empty Dictionaries | Low | Low | **P3** |
| 8. Hardcoded Costs | Low | Low | **P3** |
| 9. EventBus Types | Low | Medium | **P2** |
| 10. DebugOverlay Caching | Low | Low | **P3** |

---

*Generated from codebase audit on 2026-03-12*
