# Jewel Flame - LLM Handoff Document

## Project Overview
**Jewel Flame** is a 2D pixel-art grand strategy RPG being built in Godot 4.6. The game features:
- Strategic overworld map with province control
- Turn-based faction gameplay with 3 houses (Blanche, Coryll, Lyle)
- Real-time tactical combat with animated fighters
- Multiple character types (knights and other warriors)
- RPG elements (lords, equipment, units)

## Current State (Last Updated: 2026-03-19)

### What's Working
1. **Strategic Layer**
   - Province system with 11 provinces across 3 factions
   - Turn-based gameplay structure
   - Sidebar UI for province/faction info
   - Army markers on strategic map
   - Strategic graph with province connections

2. **Combat System**
   - Knight fighters with 8-directional animations
   - 6 different fighter types: Knight, Grym, Hark, Janik, Nyro, Serek
   - AI state machine (IDLE, WALKING, ATTACKING, HURT, DEAD, FLEEING, DISENGAGING)
   - Speech bubbles (barks) during combat
   - Blood effects on damage
   - Team-based targeting (teams 0-3)

3. **Animation System**
   - SpriteFrames generated programmatically at runtime
   - 56 animations per knight type (8 directions × 7 states)
   - 16x16 pixel frames scaled to 2.5x

4. **Autoload Systems**
   - GameState - Central game state management
   - TurnManager - Turn-based game flow
   - LordManager - Lord/character management
   - EventBus - Event communication
   - CombatResolver - Battle resolution
   - PauseManager - Game pause handling
   - SaveManager - Save/load functionality
   - BattleLauncher - Launches battles from strategic layer

### Known Issues / TODO

#### Critical Issues (Fix First!)
1. **Knight Animation Glitch**
   - Attack animations show partial/broken sprites
   - Root cause: Incorrect row mapping in sprite sheet interpretation
   - The 2-Handed_Swordsman_Combat.png has attack frames that appear misaligned
   - See: `scenes/characters/Knight_Combat.gd` lines 104-150 (build_sprite_frames function)
   - **PRIORITY**: This blocks visual polish

2. **Fighter Spawn Position**
   - Newly spawned fighters appear in wrong location
   - Check: `scenes/strategic/knight_spawner.gd` map_bounds Rect2 coordinates

#### Medium Priority
3. **Animation Loading Race Condition**
   - "There is no animation with name 'idle_s'" errors when spawning
   - Happens because change_state() is called before _ready() builds SpriteFrames
   - Solution: Add a guard check or use call_deferred for initial state change

4. **Death Animation Missing NW Direction**
   - Non-combat sheet only has 7 death directions (missing NW)
   - Fallback implemented: death_nw → death_n

#### Low Priority / Polish
5. **Performance**
   - Spawning many fighters will cause performance issues
   - Consider object pooling for blood effects

## Project Structure

```
jewelflame/
├── autoload/                  # Singletons (AutoLoaded)
│   ├── game_state.gd         # Core game state
│   ├── turn_manager.gd       # Turn management
│   ├── lord_manager.gd       # Lord/hero management
│   ├── combat_resolver.gd    # Battle resolution logic
│   ├── battle_launcher.gd    # Battle scene transition
│   ├── event_bus.gd          # Global event system
│   ├── pause_manager.gd      # Pause functionality
│   ├── save_manager.gd       # Save/load system
│   ├── ai_manager.gd         # AI coordination
│   ├── scene_manager_integration.gd
│   ├── game_config.gd
│   ├── debug_overlay.gd
│   └── error_handler.gd
│
├── scenes/
│   ├── characters/           # Combat fighters
│   │   ├── Knight_Fighter.tscn
│   │   ├── Knight_Combat.gd        # ⭐ MAIN COMBAT SCRIPT
│   │   ├── Artun_Fighter.tscn      # Reference implementation
│   │   ├── Grym_Fighter.tscn
│   │   ├── Hark_Fighter.tscn
│   │   ├── Janik_Fighter.tscn
│   │   ├── Nyro_Fighter.tscn
│   │   ├── Serek_Fighter.tscn
│   │   └── Artun_Combat.gd
│   │
│   ├── strategic/            # Strategic layer
│   │   ├── strategic_layer.gd      # Main strategic controller
│   │   ├── province_manager.gd
│   │   ├── army_marker.gd
│   │   ├── army_marker.tscn
│   │   └── knight_spawner.gd       # Test spawner
│   │
│   ├── effects/              # Visual effects
│   │   └── pixel_blood.tscn
│   │
│   └── lords/                # Lord/character scenes
│       └── [lord scenes...]
│
├── resources/
│   └── data_classes/         # Data structures
│       ├── lord_data.gd
│       ├── faction_data.gd
│       ├── province_data.gd
│       ├── unit_data.gd
│       ├── equipment_data.gd
│       ├── character_data.gd
│       ├── monster_data.gd
│       ├── battle_data.gd
│       └── family_data.gd
│
├── ui/                       # User interface
│   ├── sidebar.tscn
│   ├── left_panel_gemfire.gd
│   ├── province_panel.gd
│   ├── battle_report.gd
│   └── [other UI...]
│
├── assets/                   # Game assets
│   ├── Citizens - Guards - Warriors/
│   │   └── Warriors/
│   │       ├── 2-Handed_Swordsman_Combat.png      # ⭐ COMBAT SHEET
│   │       ├── 2-Handed_Swordsman_Non-Combat.png  # ⭐ MOVEMENT SHEET
│   │       └── [other warriors...]
│   │
│   ├── Old Town - Citizens v0.1/
│   │   └── Masc. Citizens/
│   │       └── [Artun, Grym, Hark, etc.]
│   │
│   └── maps/
│       └── right_panel_map.jpeg
│
├── tools/                    # Helper scripts
│   ├── gen_spriteframes.py
│   ├── knight_spawner.gd
│   └── test_knight_anims.tscn
│
├── main_strategic.tscn       # ⭐ MAIN GAME SCENE
└── project.godot            # Godot project settings
```

## Key File Locations

### Most Important Files (Read These First)

| File | Purpose | Priority |
|------|---------|----------|
| `main_strategic.tscn` | Main game entry point | ⭐⭐⭐ |
| `scenes/characters/Knight_Combat.gd` | Knight AI + animation builder | ⭐⭐⭐ |
| `scenes/strategic/knight_spawner.gd` | Test spawner configuration | ⭐⭐⭐ |
| `autoload/game_state.gd` | Central game state | ⭐⭐ |
| `autoload/turn_manager.gd` | Turn management | ⭐⭐ |
| `autoload/lord_manager.gd` | Lord/character data | ⭐⭐ |
| `scenes/strategic/strategic_layer.gd` | Strategic map controller | ⭐ |

## Critical Code Sections

### 1. SpriteFrames Building (Knight_Combat.gd)
```gdscript
func build_sprite_frames():
    # Loads textures and creates 56 animations programmatically
    # Non-combat: idle (rows 0-7), walk (8-15), run (16-23), death (24-30)
    # Combat: attack_light (0-7), attack_heavy (8-15), hurt (16-23)
    # Directions: s, n, se, ne, e, w, sw, nw
    
    # ⚠️ KNOWN ISSUE: Row mapping may be wrong!
    var dirs = ["s", "n", "se", "ne", "e", "w", "sw", "nw"]
```

### 2. AI State Machine (Knight_Combat.gd)
```gdscript
enum State { IDLE, WALKING, ATTACKING, HURT, DEAD, FLEEING, DISENGAGING }

func _update_attacking(delta):
    # Attack logic with damage at 0.3s
    # Animation timeout at 1.0s
```

### 3. Fighter Spawner (knight_spawner.gd)
```gdscript
@export var spawn_interval: float = 3.0
@export var map_bounds: Rect2 = Rect2(650, 350, 1100, 700)

var fighter_scenes = [
    preload("res://scenes/characters/Knight_Fighter.tscn"),
    preload("res://scenes/characters/Grym_Fighter.tscn"),
    # ... etc
]
```

## How to Test

### Run the Game
1. Open Godot 4.6
2. Open project from `jewelflame/` folder
3. Press **F5** to run main_strategic.tscn

### Test Scenes
- **main_strategic.tscn**: Full game with spawner active
- **test_knight_anims.tscn**: Animation verification (SPACE=next anim, RIGHT=next dir)

### Debug Output
- Knights print attack info to console
- Blood spawn coordinates logged
- Spawner prints: "Spawned #N: Type at (x,y) - Team N"

## Asset Import Settings

### Sprite Sheets (Critical!)
When importing new sprite sheets:
1. Select the PNG in Godot's FileSystem
2. In Import tab:
   - **Filter**: Nearest (for pixel art)
   - **Mipmaps**: Disabled
   - **Compress**: Lossless
3. Click "Reimport"

### Frame Specifications
- **Frame size**: 16×16 pixels
- **Combat sheet**: 8 columns × 24 rows (128×384)
- **Non-combat sheet**: 4 columns × 31 rows (64×496)

## Common Tasks for New LLM

### Fix Attack Animation Alignment (PRIORITY #1)
1. Open `scenes/characters/Knight_Combat.gd`
2. Look at `build_sprite_frames()` function (lines 104-150)
3. Verify the row-to-direction mapping matches the actual sprite sheet
4. Open `2-Handed_Swordsman_Combat.png` in image editor to verify layout
5. Update the `dirs` array if needed:
   ```gdscript
   # Current mapping (may be wrong):
   var dirs = ["s", "n", "se", "ne", "e", "w", "sw", "nw"]
   ```

### Add New Fighter Type
1. Create new scene: `NewType_Fighter.tscn`
2. Use `Knight_Fighter.tscn` as template (root is AnimatedSprite2D)
3. Modify `build_sprite_frames()` to point to new sprite sheets
4. Add to `knight_spawner.gd` fighter_scenes array
5. Create combat script extending `Knight_Combat.gd` or `Artun_Combat.gd`

### Adjust Spawn Rate/Location
Edit `scenes/strategic/knight_spawner.gd`:
```gdscript
@export var spawn_interval: float = 3.0  # Change this
@export var map_bounds: Rect2 = Rect2(650, 350, 1100, 700)  # Change this
```

### Modify Combat Balance
Edit `scenes/characters/Knight_Combat.gd`:
```gdscript
@export var health: int = 250
@export var attack_damage: int = 20
@export var attack_range: float = 50.0
@export var walk_speed: float = 80.0
```

## Technical Architecture

### Godot Version
- **Godot 4.6.stable** (official)
- Uses GDScript 2.0

### Autoload Order (Project Settings)
Check `project.godot` for autoload order. Key ones:
- GameState (loaded early)
- TurnManager
- LordManager
- EventBus

### Groups Used
- `"knight_combat"` - All knight fighter instances
- `"artun_combat"` - All fighters (for backwards compatibility)
- `"artun_combat"` used for targeting system

### Communication Pattern
```
Strategic Layer → BattleLauncher → [Combat Scene]
     ↑___________________________|
           (returns results)
```

### Data Flow
1. GameState holds central state
2. EventBus broadcasts events
3. Autoloads manage specific systems
4. Scenes react to events and update UI

## Performance Considerations

### Current Limitations
- SpriteFrames built at runtime (CPU cost on spawn)
- Blood effects are instantiated nodes (GC pressure)
- AI runs in _process() for all fighters

### Future Optimizations
- Object pooling for blood effects
- Pre-built SpriteFrames resources
- Spatial partitioning for AI targeting

## Recent Changes (Last Session)
1. ✅ Added runtime SpriteFrames generation (Knight_Combat.gd)
2. ✅ Created knight spawner (1 fighter every 3 seconds)
3. ✅ Hidden map background for clearer testing
4. ✅ Added test background (dark gray)
5. ✅ Fixed animation errors by building frames in _ready()
6. ⚠️ Attack animations still visually broken (NEEDS FIX)

## Questions to Investigate

### High Priority
1. What is the correct row order in `2-Handed_Swordsman_Combat.png`?
   - Open the image and visually inspect which rows are which directions
   - Compare with current `dirs` array mapping

2. Why do spawned fighters appear in the UI area?
   - Check `knight_spawner.gd` map_bounds vs actual screen coordinates
   - May need to offset by CanvasLayer position

### Medium Priority
3. Should we switch to pre-built SpriteFrames resources?
   - Would be more performant
   - But runtime generation is more flexible

4. How to implement proper object pooling?
   - For blood effects
   - For frequently spawned/destroyed fighters

### Low Priority
5. How to balance combat?
   - Health, damage, speed values need tuning
   - AI behavior (flee threshold, attack range)

## Debugging Tips

### Enable Debug Output
Check `autoload/debug_overlay.gd` for debug display options.

### Common Error Messages
- `"There is no animation with name 'idle_s'"` - Race condition, usually harmless
- `"Failed loading resource"` - Missing texture import, reimport in Godot

### Visual Debugging
- Add `print()` statements in `_update_attacking()` to see combat flow
- Blood spawn coordinates help verify hit detection
- Use "Remote" scene tree in Godot debugger to inspect spawned nodes

## External Dependencies

### Assets Used
- **2-Handed Swordsman** - Electric Lemon Games (license in assets folder)
- **Old Town Citizens** - [Asset pack for Artun/Grym/Hark/etc.]

### Godot Plugins
None currently (pure GDScript)

## Contact / Context

- This project is developed iteratively with AI assistance
- The knight animation issue is the current blocker
- All other core systems are functional
- Next milestone: Polished combat with correct animations

---

**See Also:**
- `QUICK_START.md` - For immediate orientation
- `AGENTS.md` - Quick reference card

**Document Version:** 2026-03-19-v1
