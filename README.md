# Jewelflame - Implementation-Accurate Documentation

**Godot Version:** 4.6.stable  
**Last Updated:** 2026-03-12  
**Status:** MVP Core Functional - See "Feature Inventory" for exact implementation status

---

## 1. FEATURE INVENTORY (Ground Truth)

### ✅ Complete Systems

| Feature | Status | Evidence |
|---------|--------|----------|
| **Turn State Machine** | ✅ Working | `autoload/turn_manager.gd:20-54` - 6-state enum (EVENT_PHASE, PLAYER_TURN, AI_TURN, COMBAT_RESOLUTION, TURN_END, GAME_OVER) |
| **Province Selection** | ✅ Working | `scenes/strategic/province_node.gd:68-72` - Area2D input handling, emits to GameState |
| **Sidebar UI** | ✅ Working | `ui/sidebar.tscn` - Portrait, 4 stat boxes, 4 action buttons, event message panel |
| **Debug Overlay** | ✅ Working | `autoload/debug_overlay.gd` - F12 toggle, shows turn/state/faction stats |
| **Faction Data** | ✅ Working | `resources/data_classes/faction_data.gd` - Typed Resource with StringName IDs |
| **Province Data** | ✅ Working | `resources/data_classes/province_data.gd` - Defense levels, income calculation, adjacency |
| **Battle Resolution** | ✅ Working | `autoload/combat_resolver.gd:66-103` - Deterministic power comparison, explicit 30%/70% loss ratios |
| **AI Turn Processing** | ✅ Working | `autoload/ai_manager.gd:14-43` - 3-phase AI (Recruit→Move→Attack) with `await` delays |
| **Random Events** | ✅ Working | `autoload/event_manager.gd:40-64` - 30% chance per turn, 5 event types with weighted selection |
| **Province Ownership Transfer** | ✅ Working | `autoload/game_state.gd:174-192` - Updates both province and faction data structures |

### 🚧 Partial Systems

| Feature | Status | Details |
|---------|--------|---------|
| **Command System** | 🚧 UI Only | Attack/Defend/Recruit/Scout buttons exist in `ui/sidebar.tscn:361-415` but only Attack and Defend have backend handlers. CommandProcessor autoload is **commented out** in `project.godot:30` |
| **Save/Load** | 🚧 Partial | `autoload/save_manager.gd:8-35` - JSON serialization exists but uses legacy `families`/`characters` dictionaries that are empty in new system. **Broken:** References `to_dict()` methods that don't exist on new Resource classes |
| **Transport Command** | 🚧 Stub | `strategic/commands/transport_command.gd` exists but not integrated |
| **Vassal System** | 🚧 Stub | `strategic/commands/recruit_vassal_command.gd` exists but not connected to UI |
| **Character System** | 🚧 Legacy | CharacterData resource exists but no characters are instantiated in `game_state.gd:41-42` |

### ❌ Stubs/Non-Functional

| Feature | Status | Location |
|---------|--------|----------|
| **5th Unit (Creatures)** | ❌ UI Slot Only | Button exists in `ui/sidebar.tscn` but no creature database |
| **Tactical Battle Scene** | ❌ Not Integrated | `scenes/tactical/tactical_battle.tscn` exists but transition not implemented |
| **Fog of War** | ❌ Not Implemented | Claimed in old README - no code exists |
| **Food/Starvation System** | ❌ Not Implemented | Claimed in old README - economy uses only gold |
| **Monthly Upkeep** | ❌ Not Implemented | Turn cycle exists but no recurring costs |
| **Terrain Combat Bonuses** | ❌ Not Implemented | Provinces have terrain_type field but CombatResolver doesn't use it |
| **Loot Transfer** | ❌ Not Implemented | Old README claimed 30% loot - actual code transfers province ownership only |
| **AI Personalities** | ❌ Hardcoded | All AI use same threshold (1.5x) - no personality variation implemented |

---

## 2. TECHNICAL ARCHITECTURE

### Autoload Initialization Order

From `project.godot:18-34` (Godot loads in this order):

```
1. GameConfig          # Constants only, no dependencies
2. TurnManager         # Depends on GameState (validated in _ready)
3. CombatResolver      # Depends on GameState, GameConfig
4. EventManager        # Depends on GameState, GameConfig
5. AIManager           # Depends on GameState, CombatResolver
6. DebugOverlay        # Depends on TurnManager, GameState
7. EventBus            # No dependencies (signal router)
8. GameState           # Self-contained, creates data in _ready
9. SaveManager         # Depends on GameState
10. BattleLauncher     # Depends on GameState
11. PauseManager       # No dependencies
```

**Critical:** TurnManager validates GameState in `_ready:28-29` using `get_node_or_null()` to avoid static analysis errors.

### Signal Routing

| Signal | Emitter | File:Line | Consumers |
|--------|---------|-----------|-----------|
| `province_selected` | GameState | `autoload/game_state.gd:172` | Sidebar `_on_province_selected:252` |
| `state_changed` | TurnManager | `autoload/turn_manager.gd:44` | Sidebar `_on_state_changed:84`, StrategicLayer `_on_state_changed:61` |
| `battle_resolved` | CombatResolver | `autoload/combat_resolver.gd:110` | StrategicLayer `_on_battle_resolved:72` |
| `ai_turn_started` | TurnManager | `autoload/turn_manager.gd:91` | StrategicLayer `_on_ai_turn_started:52` |
| `event_triggered` | EventManager | `autoload/event_manager.gd:138` | StrategicLayer `_on_event_triggered:82` |

### Data Flow Example (Attack Command)

```
1. User clicks AttackBtn
   → ui/sidebar.tscn:361 (button pressed signal)
   → ui/sidebar.gd:241 (_on_attack_pressed)
   
2. State changes to SELECT_SOURCE
   → ui/sidebar.gd:38 (current_action = "attack")
   
3. User clicks province
   → scenes/strategic/province_node.gd:71 (input_event)
   → autoload/game_state.gd:169 (select_province)
   → ui/sidebar.gd:252 (_on_province_selected)
   
4. Action executes
   → ui/sidebar.gd:359 (_execute_attack)
   → autoload/combat_resolver.gd:30 (resolve_battle)
   → autoload/game_state.gd:174 (transfer_province_ownership)
   → ui/sidebar.gd:410 (_show_battle_result)
```

---

## 3. SCENE & UI INVENTORY

### Main Scene Tree (`main_strategic.tscn`)

```
MainStrategic (Node2D)
└── CanvasLayer
    ├── GameSidebar (Control) ← ui/sidebar.tscn instance
    │   ├── StainedGlassBg (TextureRect, z_index=-1)
    │   ├── Frame (NinePatchRect)
    │   ├── Banner (Control, scripted)
    │   ├── Portrait (Control, scripted)
    │   ├── ProvinceName (Label, unique_name)
    │   ├── RulerName (Label, unique_name)
    │   ├── StatsGrid (GridContainer)
    │   │   ├── DefenseBox (NinePatchRect)
    │   │   ├── IncomeBox (NinePatchRect)
    │   │   ├── GarrisonBox (NinePatchRect)
    │   │   └── LoyaltyBox (NinePatchRect)
    │   ├── AttackBtn (Button, unique_name)
    │   ├── DefendBtn (Button, unique_name)
    │   ├── RecruitBtn (Button, unique_name)
    │   ├── ScoutBtn (Button, unique_name)
    │   ├── EventMessageBg (NinePatchRect)
    │   ├── EventMessageLabel (Label, unique_name, z_index=1)
    │   └── EndTurnBtn (Button, unique_name)
    ├── MapContainer (Control, offset_left=600)
    │   ├── MapBackground (TextureRect, right_panel_map.jpeg)
    │   └── ProvinceManager (Node2D, scripted)
    │       ├── ProvinceContainer (Node2D)
    │       └── Connections (Node2D, z_index=-1)
    ├── TurnIndicator (Label)
    └── HelpText (Label)
```

### Instantiations

| Scene | Pre-placed | Dynamic | Script |
|-------|------------|---------|--------|
| ProvinceNode | ❌ | ✅ x5 | `province_manager.gd:24-30` instantiates from `province_node.tscn` |
| GameSidebar | ✅ | ❌ | Attached to CanvasLayer |
| TurnIndicator | ✅ | ❌ | Simple Label |

---

## 4. COMMAND SYSTEM REALITY CHECK

| Command | Status | Cost | Validation | Persistence |
|---------|--------|------|------------|-------------|
| **Attack** | ✅ Working | Free | `sidebar.gd:241` checks `TurnManager.is_action_allowed()` | ✅ Province ownership updates |
| **Defend** (Develop) | ✅ Working | `200 * 1.5^(level-1)` | `sidebar.gd:288` checks `_can_be_source()` | ✅ Defense level increments |
| **Recruit** | ✅ Working | 100 gold (10 × 10) | Same as Defend | ✅ Troops += 10 |
| **Scout** | 🚧 Stub | Free | UI exists, no logic | ❌ |
| **Transport** | ❌ Not Connected | N/A | File exists, not in UI | ❌ |

**Validation Location:** All validation is in `ui/sidebar.gd` - **NOT** in a backend command processor as originally designed. The CommandProcessor autoload is commented out.

---

## 5. BATTLE SYSTEM (Actual Formulas)

From `autoload/combat_resolver.gd:66-103`:

```gdscript
# Power calculation (line 66-67)
var attack_power := source.troops * 1.0
var defense_power := target.troops * target.get_defense_bonus()

# Defense bonus (resources/data_classes/province_data.gd:18-19)
func get_defense_bonus() -> float:
    return 1.0 + (defense_level - 1) * 0.2  # Level 1 = 1.0, Level 5 = 1.8

# Attacker wins (line 74-90)
attacker_losses = source.troops * 0.3      # 30% losses
troops_moved = survivors * 0.7             # 70% occupy target
troops_returned = survivors * 0.3          # 30% return home

# Attacker loses (line 91-103)
attacker_losses = source.troops * 0.5      # 50% losses retreating
defender_losses = target.troops * 0.2      # 20% losses when defending

# Minimum garrison enforcement (line 99-103)
if source.troops < GameConfig.MIN_GARRISON_SIZE:  # MIN_GARRISON_SIZE = 1
    source.troops = GameConfig.MIN_GARRISON_SIZE
```

**Note:** No randomness. No terrain modifiers despite provinces having terrain_type field.

---

## 6. AI IMPLEMENTATION DETAILS

### Decision Tree (`autoload/ai_manager.gd`)

```gdscript
# Phase 1: Recruitment (lines 44-57)
if province.troops < 100 and faction.gold >= 10:
    amount = min(50, affordable_amount)
    faction.gold -= amount * 10
    province.troops += amount
    await get_tree().create_timer(0.2).timeout

# Phase 2: Movement (lines 59-82)
if source.troops > 50:  # AI_MIN_GARRISON
    for adjacent_owned_province:
        if target.troops < source.troops:
            amount = min(source.troops - 50, 50)
            move_troops(source, target, amount)
            await get_tree().create_timer(0.3).timeout
            break  # One move per source

# Phase 3: Attack (lines 84-118)
my_power = source.troops
their_power = target.troops * target.get_defense_bonus()
if my_power > their_power * 1.5:  # ATTACK_ADVANTAGE_THRESHOLD
    CombatResolver.resolve_battle(...)
    await get_tree().create_timer(0.5).timeout
```

### Timing
- Recruit: 0.2s delay
- Move: 0.3s delay  
- Attack: 0.5s delay
- Between factions: 0.3s delay (`turn_manager.gd:97`)

### Personality Parameters
**All AI use the same hardcoded values:**
- Attack threshold: 1.5x power advantage (line 6)
- Recruit threshold: <100 troops (line 7)
- Max recruit: 50 troops (line 9)
- Min garrison: 50 troops retained (uses GameConfig.AI_MIN_GARRISON)

**No personality variation exists** - Lyle, Coryll, and hypothetical AI-controlled Blanche all use identical logic.

---

## 7. KNOWN ISSUES & TECHNICAL DEBT

### Critical Issues

| Issue | Impact | File | Workaround |
|-------|--------|------|------------|
| **Save system broken** | Cannot persist games | `autoload/save_manager.gd:17-24` | Uses legacy dictionaries that are empty |
| **CommandProcessor disabled** | No centralized command validation | `project.godot:30` | Validation duplicated in sidebar.gd |
| **Static analysis errors** | 50+ GDScript warnings | Multiple | Uses `get_node_or_null()` pattern to avoid cross-autoload references |

### UI Issues

| Issue | Location | Details |
|-------|----------|---------|
| Ornate divider transparency | `ui/sidebar.tscn:132-143` | Requires chroma key shader (`shaders/divider_transparency.gdshader`) |
| Button signal double-connect | `ui/sidebar.gd:59` | Signals connected both in .tscn and _ready - harmless but logs warnings |
| Event message z-index | `ui/sidebar.tscn:431` | Explicit z_index=1 required to render above background panel |

### Technical Debt

| Issue | Location | Recommended Fix |
|-------|----------|-----------------|
| Legacy compatibility code | `autoload/game_state.gd:221-264` | Remove after migration complete |
| Empty character dictionaries | `autoload/game_state.gd:41-42` | Implement character system or remove |
| Unused command files | `strategic/commands/` | Integrate or delete |
| Hardcoded costs in sidebar | `ui/sidebar.gd:322` | Move to GameConfig |

---

## 8. FILE STRUCTURE MAP

### Hot Paths (Change Frequently During Development)
- `autoload/game_state.gd` - Core data, balance changes
- `autoload/turn_manager.gd` - Turn flow modifications
- `autoload/combat_resolver.gd` - Combat balance
- `ui/sidebar.gd` - UI behavior
- `resources/data_classes/*.gd` - Data structure changes

### Stable (Resource Classes, Rarely Change)
- `resources/data_classes/province_data.gd` - Data structure stable
- `resources/data_classes/faction_data.gd` - Data structure stable
- `scenes/strategic/province_node.tscn` - Visual template stable

### Unused/Dead Code
- `strategic/commands/command_processor.gd` - Referenced but autoload commented out
- `strategic/commands/military_commands.gd` - Int-based province IDs (deprecated)
- `strategic/commands/domestic_commands.gd` - Int-based province IDs (deprecated)
- `strategic/random_events.gd` - Autoload commented out, uses old system
- `ui/strategic_ui_controller.gd` - Referenced in main_strategic.tscn but node removed

---

## 9. DEVELOPMENT SETUP (Verified)

### Requirements
- **Godot Engine:** 4.6.stable (confirmed working)
- **OS:** Linux/Windows/macOS (developed on Linux)
- **Display:** 1920×1080 (configured in `project.godot:38-39`)

### Running the Game
```bash
# From project root
godot --path . --scene res://main_strategic.tscn

# Or open in Godot Editor and press F5
```

### Reset Save Data
```bash
# Linux
rm ~/.local/share/godot/app_userdata/Jewelflame/saves/*.json

# Windows
# %APPDATA%\Godot\app_userdata\Jewelflame\saves\
```

### Debug Controls
- **F12:** Toggle debug overlay (shows turn, state, faction stats)
- **Space:** End player turn
- **Left Click:** Select province
- **Right Click:** Cancel (not fully implemented)

---

## 10. EXTENSION GUIDE

### Adding a New Command

1. **Add button to sidebar:**
   ```gdscript
   # ui/sidebar.tscn - Copy existing button structure
   [node name="NewCommandBtn" type="Button" parent="."]
   unique_name_in_owner = true
   text = "New Command"
   ```

2. **Connect signal in sidebar.gd:**
   ```gdscript
   # ui/sidebar.gd:_ready - Button connections auto-loaded from .tscn
   # Add handler method:
   func _on_new_command_pressed():
       if not TurnManager.is_action_allowed():
           return
       current_action = "new_command"
       current_mode = ActionMode.SELECT_SOURCE
   ```

3. **Implement execution:**
   ```gdscript
   # ui/sidebar.gd:_execute_action
   "new_command":
       _execute_new_command(selected_source, selected_target)
   
   func _execute_new_command(source, target):
       # Implementation here
       pass
   ```

### Adding a New Event Type

1. **Add to EventManager:**
   ```gdscript
   # autoload/event_manager.gd:11-15
   const EVENT_NEW := &"new_event"
   
   # Add to event_templates dictionary
   EVENT_NEW: {
       "message": "Event text: {param}",
       "weight": 20
   }
   ```

2. **Add handler in _execute_event:**
   ```gdscript
   # autoload/event_manager.gd:85+
   EVENT_NEW:
       var param := 123
       message = template.message.format({"param": param})
   ```

---

## 11. DISCREPANCY REPORT: Old README vs Reality

| Old README Claim | Reality | Evidence |
|------------------|---------|----------|
| "Fog of War: Enemy troop counts hidden" | ❌ Not implemented | No fog-of-war code exists |
| "AI Personalities: Aggressive/Defensive/Opportunistic" | ❌ All AI identical | `ai_manager.gd:6-9` - single threshold value |
| "Attack Threshold: 0.8/1.0/1.2 strength ratios" | ❌ Hardcoded 1.5x | `ai_manager.gd:6` - ATTACK_ADVANTAGE_THRESHOLD = 1.5 |
| "Food consumption, starvation, desertion" | ❌ Not implemented | Only gold economy exists |
| "September harvest" | ❌ Not implemented | Old code in `strategic/random_events.gd` but autoload disabled |
| "Animated combat with attack arrows" | ❌ Not implemented | No animation system connected |
| "Vassal capture system" | 🚧 UI button only | Button exists, backend not connected |
| "Comprehensive save/load" | 🚧 Broken | Uses legacy data structures |
| "Random events: flood, plague, fire, snow" | 🚧 Partial | 5 events exist but simplified |
| "Battle animations and province capture effects" | ❌ Not implemented | No capture animation code |

---

## LICENSE

[Add your license here]

---

**Generated from codebase analysis on 2026-03-12**  
**For implementation questions, grep the cited file:line references**