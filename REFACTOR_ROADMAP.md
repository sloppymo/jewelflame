# REFACTOR_ROADMAP.md - Jewelflame Development

## Roadmap

### Dependency Graph

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           CRITICAL PATH                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    │
│   │  Save System    │───→│ Tactical Battle │───→│ Polish/Release  │    │
│   │    Repair       │    │  Integration    │    │                 │    │
│   └─────────────────┘    └─────────────────┘    └─────────────────┘    │
│          │                      ▲                                      │
│          │                      │                                      │
│          ▼                      │                                      │
│   ┌─────────────────┐           │                                      │
│   │  CommandProc    │───────────┘                                      │
│   │    Restore      │   (enables undo/redo)                            │
│   └─────────────────┘                                                  │
│          │                                                             │
│          ▼                                                             │
│   ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    │
│   │  AI Personality │───→│   Fog of War    │───→│  Lord/Vassal    │    │
│   │     System      │    │    (Basic)      │    │     System      │    │
│   └─────────────────┘    └─────────────────┘    └─────────────────┘    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    PARALLEL TRACKS (Non-Blocking)                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Track A: UX/Feedback      Track B: Content        Track C: Tech Debt  │
│  ───────────────────       ───────────────         ────────────────    │
│  ┌─────────────┐           ┌─────────────┐         ┌─────────────┐     │
│  │   Combat    │           │   5th Unit  │         │ Type Safety │     │
│  │   Preview   │           │  Creatures  │         │   Cleanup   │     │
│  └─────────────┘           └─────────────┘         └─────────────┘     │
│  ┌─────────────┐           ┌─────────────┐         ┌─────────────┐     │
│  │   Defense   │           │    Event    │         │   Signal    │     │
│  │  Feedback   │           │   Choices   │         │    Fixes    │     │
│  └─────────────┘           └─────────────┘         └─────────────┘     │
│  ┌─────────────┐           ┌─────────────┐                             │
│  │   Turn End  │           │   Terrain   │                             │
│  │  Confirm    │           │  Modifiers  │                             │
│  └─────────────┘           └─────────────┘                             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Sprint 1: Foundation (Weeks 1-2)

**Theme:** "If we only fix the save system, players can actually complete campaigns"

### Goals
- [ ] Repair SaveManager using ResourceSaver
- [ ] Implement proper save/load UI flow
- [ ] Add save slot selection

### Key Changes

**New:** `resources/game_save_resource.gd`
```gdscript
class_name GameSaveResource extends Resource

@export var version: String = "1.0"
@export var timestamp: int
@export var turn_number: int
@export var faction_data: Dictionary[StringName, FactionData]
@export var province_data: Dictionary[StringName, ProvinceData]
@export var battle_history: Array[BattleRecord]
```

### Success Criteria
- Player can save at turn 5, load at turn 5, state is identical
- Save survives game restart
- 3 save slots available

### Files Modified
- `autoload/save_manager.gd` (complete rewrite)
- `ui/sidebar.gd` (add save/load buttons)
- `resources/game_save_resource.gd` (new)

---

## Sprint 2: Command Architecture (Weeks 3-4)

**Theme:** "If we only restore CommandProcessor, we enable undo/redo and centralized validation"

### Goals
- [ ] Re-enable CommandProcessor autoload
- [ ] Migrate StringName province IDs to command system
- [ ] Implement command history with undo
- [ ] Add command validation layer

### Key Changes

**`strategic/commands/command_processor.gd` (restored)**
```gdscript
class_name CommandProcessor extends Node

var _history: Array[Command] = []
var _redo_stack: Array[Command] = []

func execute(command: Command) -> bool:
    if not command.validate():
        return false
    command.execute()
    _history.append(command)
    _redo_stack.clear()
    return true

func undo() -> bool:
    if _history.is_empty():
        return false
    var cmd = _history.pop_back()
    cmd.undo()
    _redo_stack.append(cmd)
    return true
```

### Success Criteria
- All commands go through CommandProcessor
- Ctrl+Z undoes last action
- Invalid commands (attack with 0 troops) are blocked with error message
- Sidebar only calls CommandProcessor, no direct GameState manipulation

### Files Modified
- `project.godot` (uncomment CommandProcessor)
- `strategic/commands/command_processor.gd` (rewrite)
- `strategic/commands/base_command.gd` (new abstract class)
- `ui/sidebar.gd` (delegate to CommandProcessor)

---

## Sprint 3: AI Personality (Weeks 5-6)

**Theme:** "If we only give AI distinct personalities, players can learn and exploit patterns"

### Goals
- [ ] Define personality data structures
- [ ] Implement personality-based decision thresholds
- [ ] Add AI behavior visualization (debug)
- [ ] Balance personality parameters

### Key Changes

**`strategic/ai/ai_personality.gd`**
```gdscript
class_name AIPersonality extends Resource

@export var faction_id: StringName
@export var attack_threshold: float = 1.5  # 1.5x power advantage needed
@export var recruit_bias: float = 1.0      # Multiplier on recruit desire
@export var defense_focus: bool = false    # Prioritize defense upgrades
@export var expansion_focus: bool = false  # Prioritize new provinces

# Coryll: Aggressive
# attack_threshold: 0.9, recruit_bias: 0.8, expansion_focus: true

# Lyle: Opportunistic 
# attack_threshold: 1.2, recruit_bias: 1.2, defense_focus: true
```

### Success Criteria
- Coryll attacks more aggressively (lower threshold)
- Lyle recruits more troops (higher bias)
- Player can observe and predict AI behavior after 3-4 turns
- Win rates balanced (no personality dominates)

### Files Modified
- `strategic/ai/ai_personality.gd` (new)
- `autoload/ai_manager.gd` (integrate personalities)
- `autoload/game_state.gd` (load personality configs)

---

## Sprint 4: Tactical Integration (Weeks 7-8)

**Theme:** "If we only integrate tactical battles, combat becomes skill-based instead of deterministic"

### Goals
- [ ] Connect BattleLauncher to CombatResolver
- [ ] Implement strategic → tactical transition
- [ ] Implement tactical → strategic return with results
- [ ] Add tactical battle frequency option (auto-resolve vs play)

### Key Changes

**`autoload/combat_resolver.gd` - modified**
```gdscript
func resolve_battle(attacker_id: StringName, defender_id: StringName,
                   source_id: StringName, target_id: StringName) -> BattleResult:
    
    # Check if player wants tactical battle
    if GameConfig.ENABLE_TACTICAL_BATTLES and _is_player_involved(attacker_id, defender_id):
        BattleLauncher.launch_battle(source_id, target_id, 0.7)
        # Result will come async via TacticalBattleCompleted signal
        return null
    
    # Otherwise, use existing deterministic resolution
    return _resolve_deterministic(...)
```

### Success Criteria
- Player can choose "Fight Battle" or "Auto-Resolve"
- Tactical battle launches with correct province data
- Results (troop losses, province capture) reflect tactical outcome
- Camera transitions smoothly between scenes

### Files Modified
- `autoload/battle_launcher.gd` (fix property names, integrate)
- `autoload/combat_resolver.gd` (add tactical branch)
- `scenes/tactical/tactical_battle.gd` (ensure result emission)
- `scenes/strategic/strategic_layer.gd` (handle return)

---

## Sprint 5: Fog of War (Weeks 9-10)

**Theme:** "If we only add fog of war, scouting becomes meaningful and information becomes strategic"

### Goals
- [ ] Implement visibility system per faction
- [ ] Hide non-adjacent province troop counts
- [ ] Show "unknown" indicators for unexplored areas
- [ ] Add scout command functionality

### Key Changes

**`resources/data_classes/faction_data.gd`**
```gdscript
@export var visible_provinces: Array[StringName] = []
@export var explored_provinces: Array[StringName] = []

func can_see_province(province_id: StringName) -> bool:
    return province_id in visible_provinces

func update_visibility(all_provinces: Dictionary):
    visible_provinces.clear()
    for owned_id in owned_province_ids:
        var province: ProvinceData = all_provinces[owned_id]
        visible_provinces.append(owned_id)
        for adj_id in province.adjacent_province_ids:
            if not visible_provinces.has(adj_id):
                visible_provinces.append(adj_id)
```

### Success Criteria
- Player can only see troop counts in own and adjacent provinces
- Enemy provinces show "?" for troop count
- Scout command reveals target province for 1 turn
- AI respects visibility (doesn't magically know player troop counts)

### Files Modified
- `resources/data_classes/faction_data.gd` (visibility arrays)
- `scenes/strategic/province_node.gd` (conditional display)
- `ui/sidebar.gd` (handle unknown data)
- `autoload/ai_manager.gd` (AI vision rules)

---

## Sprint 6: UX Polish (Weeks 11-12)

**Theme:** "If we only polish the UI feedback, players understand their decisions better"

### Goals
- [ ] Add combat preview before attacking
- [ ] Show defense value in troop calculations
- [ ] Add turn-end confirmation when actions remain
- [ ] Add battle history log

### Key Changes

**`ui/sidebar.gd` - combat preview**
```gdscript
func _show_combat_preview(source: ProvinceData, target: ProvinceData):
    var attack_power = source.troops
    var defense_power = target.troops * target.get_defense_bonus()
    var odds = attack_power / defense_power
    
    var odds_text: String
    if odds >= 1.5: odds_text = "Overwhelming Advantage"
    elif odds >= 1.2: odds_text = "Favorable"
    elif odds >= 0.9: odds_text = "Even"
    else: odds_text = "Risky"
    
    show_event_message(
        "Attack Preview\n" +
        "Your Power: %d\n" % attack_power +
        "Enemy Power: %d × %.1f = %.0f\n" % [target.troops, target.get_defense_bonus(), defense_power] +
        "Odds: %s" % odds_text
    )
```

### Success Criteria
- Player sees power comparison before confirming attack
- Defense upgrades show "1.4x" multiplier in UI
- Turn end warns about unmoved troops/unspent gold
- Battle log accessible from sidebar

### Files Modified
- `ui/sidebar.gd` (preview functions)
- `autoload/game_state.gd` (battle history)
- `ui/battle_log_panel.tscn` (new scene)

---

## Sprint 7: Content Expansion (Weeks 13-14)

**Theme:** "If we only add terrain modifiers and event choices, strategic depth increases significantly"

### Goals
- [ ] Implement terrain combat bonuses
- [ ] Add event choice system
- [ ] Balance event weights and outcomes
- [ ] Add terrain visualization to map

### Key Changes

**`resources/data_classes/province_data.gd`**
```gdscript
@export var terrain_type: String = "plains"

func get_terrain_defense_bonus() -> float:
    match terrain_type:
        "forest": return 0.3
        "mountain": return 0.5
        "marsh": return 0.2
        _: return 0.0

func get_defense_bonus() -> float:
    var base = 1.0 + (defense_level - 1) * 0.2
    return base + get_terrain_defense_bonus()
```

### Success Criteria
- Forest provinces grant +30% defense
- Mountain provinces grant +50% defense
- Events present meaningful binary choices
- Terrain types visible on province nodes (color coding)

### Files Modified
- `resources/data_classes/province_data.gd` (terrain bonuses)
- `autoload/event_manager.gd` (choice system)
- `scenes/strategic/province_node.gd` (terrain visuals)

---

## Sprint 8: Advanced Systems (Weeks 15-16)

**Theme:** "If we only add lords and the 5th unit, we reach feature parity with Gemfire's core systems"

### Goals
- [ ] Implement LordData assignment to provinces
- [ ] Create lord recruitment UI
- [ ] Add creature/5th unit database
- [ ] Implement creature capture in tactical battles

### Key Changes

**`resources/data_classes/province_data.gd`**
```gdscript
@export var governor_id: StringName = &""  # Assigned lord

func get_total_defense_power() -> int:
    var base = troops * get_defense_bonus()
    if governor_id != &"":
        var lord: LordData = GameState.get_lord(governor_id)
        if lord:
            base += lord.defense_rating * 2
    return int(base)
```

### Success Criteria
- Lords can be assigned as province governors
- Lord stats affect combat outcomes
- Creatures can be captured and assigned to 5th unit slot
- Vassal recruitment works through UI

### Files Modified
- `resources/data_classes/lord_data.gd` (expand)
- `resources/data_classes/province_data.gd` (governor)
- `ui/sidebar.gd` (lord/creature UI)
- `strategic/commands/recruit_vassal_command.gd` (connect)

---

## Post-MVP (Future Sprints)

### Sprint 9: Food/Economy System
- Add troop consumption per turn
- Implement supply line pathfinding
- Add siege/starvation mechanics

### Sprint 10: Multiplayer Foundation
- Extract game state to server-authoritative model
- Add network synchronization
- Implement lobby system

### Sprint 11: Campaign/Scenario Mode
- Add scenario editor
- Create preset scenarios (historical battles)
- Add victory condition variants

---

## Milestone Summary

| Milestone | Sprint | Deliverable | Success Metric |
|-----------|--------|-------------|----------------|
| Save/Load | 1 | Working persistence | 100% state restoration |
| Commands | 2 | Undo/redo system | Ctrl+Z works for all actions |
| AI | 3 | Distinct personalities | Player can predict AI behavior |
| Tactical | 4 | Battle integration | 50% of battles played tactically |
| Fog | 5 | Information hiding | Scouting required for intel |
| Polish | 6 | UX improvements | Player survey satisfaction +30% |
| Content | 7 | Terrain/events | 3+ viable strategies per map |
| Lords | 8 | Character system | Lord choice affects outcomes |

---

## Risk Mitigation

### High Risk: Save Format Changes
**Mitigation:** Version all save files. Support migration from old formats.

### Medium Risk: Tactical Battle Balance
**Mitigation:** Keep deterministic auto-resolve as fallback option.

### Low Risk: AI Personality Imbalance
**Mitigation:** Expose parameters in config file for player tuning.

---

*Generated from technical debt audit and architecture review on 2026-03-12*
