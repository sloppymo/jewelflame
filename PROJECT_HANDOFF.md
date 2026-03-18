# Jewelflame Project Handoff

## Project Overview
**Jewelflame** is a Dragon Force (Sega Saturn) clone - a strategy game combining strategic province conquest with real-time tactical battles.

## Current Phase
**Phase 1 Battle MVP** - COMPLETE with unit variety

## What's Working

### Phase 0 - Strategic Layer
- 5 provinces (Dunmoor, Carveti, Cobrige, Banshea, Petaria) with road connections
- Army markers that move between provinces
- Battle triggers when enemy armies collide
- Scene transition to battle

### Phase 1 - Battle System
- **RTS Controls**: Left-click select, drag box-select, right-click move, shift-queue waypoints
- **Unit Variety** (6 types):
  - `GeneralUnit` - Standard melee fighter
  - `SpecialUnit` - Wave/cleave attack (90° arc, 70% damage to secondary targets)
  - `CavalryUnit` - Fast (180 speed), charge bonus damage, trample
  - `ArcherUnit` - Ranged (140 range), kites away from melee
  - `MonsterUnit` - Tank (250 HP), fear aura, splash damage, terrifying roar
- **Troop Visualization**: 10 dots in V formation per unit, update as troops die
- **Weight of Battle**: When a unit dies, nearby units lose 1 troop from trauma
- **Combat**: Automatic when units touch, damage based on troop count
- **AI**: Simple chase nearest player, doesn't interrupt combat
- **Battle End**: Detects victory/defeat, returns to strategic map

## Architecture

### Key Files
```
dragon_force/
├── battle_scene.gd/tscn      # Main battle controller
├── general_unit.gd/tscn      # Base unit class (extend this)
├── special_unit.gd           # Wave attack unit
├── cavalry_unit.gd           # Fast charge unit
├── archer_unit.gd            # Ranged kiting unit
├── monster_unit.gd           # Tank/fear unit
├── troop_manager.gd          # Visual troop dots

strategic/
├── strategic_map.tscn        # Entry point scene
├── strategic_map_controller.gd
├── strategic_graph.gd        # Province connections
├── army_marker.gd/tscn       # Moving armies
```

### Unit Class Hierarchy
```
GeneralUnit (general_unit.gd)
├── SpecialUnit (special_unit.gd)  # extends via set_script
├── CavalryUnit (cavalry_unit.gd)
├── ArcherUnit (archer_unit.gd)
└── MonsterUnit (monster_unit.gd)
```

### Key Unit Properties
- `@export var unit_name: String`
- `@export var team: int` (0 = player, 1 = enemy)
- `@export var max_hp: int`
- `@export var max_troops: int` (default 10)
- `@export var move_speed: float`
- `@export var attack_damage: int`
- `@export var attack_range: float`

### State Machine
```gdscript
enum State { IDLE, WALKING, ATTACKING, HURT, DEAD }
```

### Signals
- `unit_selected(unit)` - Emitted when clicked
- `unit_died(unit)` - Emitted on death
- `troops_changed(count)` - Emitted when troops change

## How to Run
```bash
cd /home/sloppymo/jewelflame
/snap/bin/godot-4 --path . res://strategic/strategic_map.tscn
```

Battle triggers automatically when armies collide on the strategic map.

## Battle Controls
- **Left Click**: Select unit
- **Drag**: Box select multiple units
- **Right Click**: Issue move order
- **Shift + Right Click**: Queue waypoint
- **Click ground**: Deselect

## Known Issues / Technical Debt
1. `special_unit.tscn` has invalid UID warning (non-breaking)
2. Enemy AI is very basic - no flanking or focus-fire
3. No terrain effects in battle
4. Battle results don't persist to strategic layer (armies respawn)
5. No spell system yet (placeholder file exists)
6. Unit collision can cause clumping

## Next Steps (Suggested)
- Terrain bonuses (forests, hills)
- Spell system for generals
- Better AI (flanking, target prioritization)
- Battle results affecting strategic layer
- More provinces on strategic map
- Unit recruitment/formation setup before battle

## Git
Last commit: "Add Phase 1 Battle MVP - RTS combat system with special units"
Repository: https://github.com/sloppymo/jewelflame

## Engine
Godot 4.6.1 Mono
Resolution: 800x600 (battle scene)
