# JEWELFLAME: Comprehensive Game Architecture Specification
## For AI Systems Architect - Planning Document

---

## PROJECT OVERVIEW

**Jewelflame** is a turn-based grand strategy game and spiritual successor to Gemfire (SNES). It combines strategic territory management with tactical hex-grid combat.

**Project ID:** 632dde6d-e94f-4ea6-9eb2-a17c56f71126

---

## CORE GAME SYSTEMS

### 1. STRATEGIC LAYER (Territory Map)

**Map Structure:**
- 30 provinces/territories
- Each province has: owner faction, garrison (units), gold/food production, terrain type
- Territory connections define valid movement paths
- No hex grid - abstract strategic movement

**Provinces Data Model:**
```gdscript
class Province:
    var id: String
    var name: String
    var owner_faction: String
    var garrison: Array[Unit]  # Units stationed here
    var terrain: String  # plains, forest, mountain, coastal
    var gold_production: int
    var food_production: int
    var connected_to: Array[String]  # Province IDs
    var has_castle: bool
    var castle_level: int  # 0-3
```

**Strategic Actions (Per Turn):**
- Move units between connected provinces
- Invade enemy province (triggers tactical battle)
- Build/upgrade castle
- Diplomacy: Defect, Plunder, Sabotage
- Manage economy (Gold/Food)

---

### 2. TACTICAL LAYER (Hex Grid Combat)

**Already Implemented:** HexForge system
- Location: `/jewelflame/src/hexforge/`
- 5,941 lines of GDScript
- Core: HexMath, HexCell, HexGrid
- Services: Pathfinder (A*), LineOfSight
- Battle: BattleController, UnitManager, CombatEngine, TurnManager, AIManager
- Rendering: HexRenderer2D, HexCursor, RangeHighlighter

**Integration Required:**
- Connect strategic garrison → tactical spawn
- Return battle results → strategic casualties

**Battle Parameters:**
- Grid size: 11x11 or 15x15 based on terrain
- Max units per side: 8-12
- Victory: Defeat all enemies or capture castle

---

### 3. UNIT SYSTEM

**Unit Types:**
```gdscript
enum UnitType {
    INFANTRY,    # Balanced, cheap
    CAVALRY,     # Fast, strong charge
    ARCHER,      # Ranged, fragile
    SIEGE,       # Anti-castle
    WIZARD       # Fifth Unit - special
}
```

**Unit Stats:**
- HP (hit points)
- Attack
- Defense
- Movement (strategic: provinces/turn, tactical: hexes/turn)
- Range (tactical only)
- Morale (affects combat effectiveness)

**Fifth Unit - Wizard System:**
- 6 elemental jewels: Fire, Water, Earth, Air, Light, Dark
- Each jewel grants unique tactical abilities
- 3-month cooldown between uses
- Wizards are rare and powerful

---

### 4. FACTION SYSTEM

**8 Playable Factions:**
Each faction needs:
- Name, leader, backstory
- Starting territories (4-5 each)
- Unique faction bonus
- Starting units
- Color scheme

**Faction Bonuses Examples:**
- Military: +10% attack
- Economic: +20% gold production
- Diplomatic: Better defection chances
- Magical: Faster jewel cooldowns

---

### 5. ECONOMY SYSTEM

**Resources:**
- **Gold:** Build castles, hire units, diplomacy
- **Food:** Maintain armies (consumption per unit/turn)

**Seasonal Cycle:**
- 4 seasons per year
- Spring: Planting (food bonus next autumn)
- Summer: Campaign season (movement bonus)
- Autumn: Harvest (food income)
- Winter: attrition (food consumption doubled)

**Production:**
- Each province produces Gold/Food based on terrain
- Castles increase production
- Plunder action steals enemy production

---

### 6. DIPLOMACY SYSTEM

**Actions:**
- **Defect:** Convince enemy unit to join you (costs gold, chance-based)
- **Plunder:** Raid province for immediate gold (damages relations)
- **Sabotage:** Damage enemy castle or reduce production
- **Alliance:** Non-aggression pact (AI factions only)

**Relations:**
- Track between each faction pair
- Affects defection success, AI behavior
- Visualized on diplomacy screen

---

## SCENE ARCHITECTURE

```
/jewelflame/
├── project.godot
├── assets/
│   ├── sprites/
│   │   ├── units/           # 8-directional unit sprites
│   │   ├── terrain/         # Strategic map provinces
│   │   ├── hex/             # Tactical hex tiles
│   │   └── ui/              # Interface elements
│   ├── audio/
│   └── fonts/
├── src/
│   ├── autoload/            # Singletons
│   │   ├── GameState.gd     # Global state manager
│   │   ├── EventBus.gd      # Signal routing
│   │   ├── SaveManager.gd   # Save/load system
│   │   └── AudioManager.gd  # Music/sfx
│   ├── strategic/           # Strategic layer
│   │   ├── StrategicMap.gd
│   │   ├── Province.gd
│   │   ├── Garrison.gd
│   │   ├── EconomyManager.gd
│   │   ├── DiplomacyManager.gd
│   │   └── ui/
│   │       ├── StrategicUI.gd
│   │       ├── ProvincePanel.gd
│   │       ├── DiplomacyScreen.gd
│   │       └── EconomyScreen.gd
│   ├── tactical/            # Tactical layer (HexForge)
│   │   └── (already exists in hexforge/)
│   ├── units/               # Shared unit system
│   │   ├── Unit.gd          # Base unit class
│   │   ├── UnitData.gd      # Serializable data
│   │   ├── UnitFactory.gd   # Create units
│   │   └── Wizard.gd        # Fifth unit special
│   ├── factions/            # Faction definitions
│   │   ├── Faction.gd
│   │   ├── FactionManager.gd
│   │   └── FactionDatabase.gd
│   ├── jewels/              # Wizard jewel system
│   │   ├── Jewel.gd
│   │   ├── JewelDatabase.gd
│   │   └── JewelEffects.gd
│   └── common/              # Shared utilities
│       ├── Constants.gd
│       ├── Helpers.gd
│       └── Types.gd
├── scenes/
│   ├── main_menu.tscn
│   ├── strategic_map.tscn
│   ├── tactical_battle.tscn
│   ├── faction_select.tscn
│   └── victory_screen.tscn
└── hexforge/                # (already implemented)
```

---

## DATA FLOW

### Strategic → Tactical Transition

```gdscript
# In StrategicMap.gd
func _on_invade_clicked(target_province: Province):
    var battle_data = {
        "attacker_units": selected_province.garrison,
        "defender_units": target_province.garrison,
        "terrain": target_province.terrain,
        "has_castle": target_province.has_castle,
        "province_id": target_province.id
    }
    
    GameState.start_battle(battle_data)
    get_tree().change_scene_to_file("res://scenes/tactical_battle.tscn")
```

### Tactical → Strategic Return

```gdscript
# In BattleController.gd
func end_battle(victor: String):
    var result = {
        "victor": victor,
        "attacker_casualties": _get_casualties("attacker"),
        "defender_casualties": _get_casualties("defender"),
        "survivors": _get_survivors()
    }
    
    GameState.end_battle(result)
    get_tree().change_scene_to_file("res://scenes/strategic_map.tscn")
```

---

## KEY IMPLEMENTATION DECISIONS

### 1. Save System
- Use Godot's Resource serialization
- Save file: JSON with compressed binary for large data
- Auto-save every turn
- Manual save slots: 3

### 2. AI Architecture
- Strategic AI: FSM (Finite State Machine) per faction
- Tactical AI: Already in HexForge (AIManager)
- Difficulty levels: Easy, Normal, Hard

### 3. UI Framework
- Godot's built-in Control nodes
- Theme: Medieval fantasy aesthetic
- Responsive layout for different resolutions

### 4. Audio
- Music: Dynamic based on situation (peace/war/tension)
- SFX: Unit movement, combat, UI feedback

### 5. Visual Style
- 8-directional sprites for units
- Pixel art aesthetic (16-32 bit style)
- Province map: Stylized, not realistic

---

## TECHNICAL REQUIREMENTS

### Performance Targets
- Strategic map: 60 FPS with 30 provinces
- Tactical battle: 60 FPS with 20 units
- Load time: <3 seconds between scenes
- Save time: <1 second

### Dependencies
- Godot 4.3+
- HexForge (included)
- No external plugins required

### Platform Targets
- PC (Windows/Linux/Mac)
- Optional: Web export

---

## DEVELOPMENT PHASES

### Phase 1: Core Systems (Weeks 1-2)
- GameState singleton
- Save/load system
- Scene transitions
- Basic UI framework

### Phase 2: Strategic Layer (Weeks 3-4)
- Province system
- Territory map
- Basic economy
- Unit movement

### Phase 3: Tactical Integration (Weeks 5-6)
- Connect HexForge
- Battle triggering
- Result application
- Unit serialization

### Phase 4: Factions & Content (Weeks 7-8)
- 8 factions
- Starting scenarios
- Unit types
- Terrain types

### Phase 5: Advanced Systems (Weeks 9-10)
- Diplomacy
- Wizard jewels
- Seasonal cycle
- AI opponents

### Phase 6: Polish (Weeks 11-12)
- Art integration
- Audio
- UI polish
- Bug fixing

---

## DELIVERABLES FOR ARCHITECT

Create a detailed implementation plan including:

1. **Class Diagrams** - All major classes and relationships
2. **Scene Tree Layouts** - Node hierarchy for each scene
3. **Signal Flow Diagram** - How systems communicate
4. **Data Models** - Complete property definitions
5. **API Specifications** - Public methods for each system
6. **File Structure** - Exact folder/file organization
7. **Implementation Order** - Priority sequence with dependencies
8. **Risk Assessment** - Potential blockers and mitigations

Focus on:
- Clean separation of concerns
- Testability
- Extensibility (mods/DLC)
- Performance

---

## REFERENCE MATERIALS

- **Gemfire (SNES):** Gameplay videos, mechanics analysis
- **HexForge:** Already implemented at `/jewelflame/src/hexforge/`
- **Red Blob Games:** Hexagonal grid reference (hexforge follows this)
- **Godot 4.3 Docs:** Best practices for turn-based games

---

## SUCCESS CRITERIA

- [ ] Strategic map with 30 provinces
- [ ] Tactical battles using HexForge
- [ ] 8 playable factions
- [ ] Full economy (Gold/Food)
- [ ] Diplomacy system (Defect/Plunder/Sabotage)
- [ ] Wizard/Fifth Unit system
- [ ] Save/load functional
- [ ] AI opponent
- [ ] Victory conditions

---

*This specification is for planning purposes. The implementing team should review and adjust based on technical constraints and design iteration.*
