# Dragon Force Battle System

## Overview
Dragon Force-style real-time battle system for Jewelflame. 1v1 General battles with troop representation.

## Architecture

### Core Components

| File | Purpose |
|------|---------|
| `general.gd` | General character controller - HP, MP, troops, movement, combat |
| `troop_manager.gd` | Visual troop dots around general - formations, rendering |
| `formation_controller.gd` | Formation state machine (Melee, Standby, Advance, Retreat) |
| `dragon_force_ai.gd` | Real-time AI for enemy generals |
| `spell_system.gd` | AOE spell effects (Fireball, Ice Storm, Lightning, Heal) |
| `dragon_force_battle.gd` | Main battle controller - input, selection, battle flow |
| `dragon_force_ui.gd` | Battle UI - formation buttons, spell casting, info display |

### Scenes

| File | Purpose |
|------|---------|
| `general_base.tscn` | General character scene with sprite, troops, health bar |
| `dragon_force_battle.tscn` | Main battle scene with UI, camera, effects |
| `test_battle.tscn` | Quick test scene |

## Phase 1 Features (Implemented)

### Single General vs General
- [x] Warrior General (Player) vs Rogue General (AI)
- [x] 100 troops per general, visualized as dots
- [x] Click to select, right-click to move
- [x] Auto-engagement when enemies in range
- [x] Troop depletion during combat

### Formations
- [x] **MELEE** (1) - Aggressive swarm, chase enemies
- [x] **STANDBY** (2) - Defensive wall, hold position
- [x] **ADVANCE** (3) - Move forward, engage on contact
- [x] **RETREAT** (4) - Flee toward map edge

### Spell System
- [x] Fireball AOE (20 MP cost)
- [x] MP charges over time during battle
- [x] Click spell button → click target area
- [x] Damage affects both troops and HP

### AI
- [x] Personality system (Aggressive, Defensive, Balanced, Opportunistic)
- [x] Real-time decision making
- [x] Formation switching based on situation
- [x] Spell casting when MP is full

## Controls

| Key | Action |
|-----|--------|
| Left Click | Select general / Issue order |
| Right Click | Cancel / Move order (in move mode) |
| Drag Box | Multi-select (future) |
| 1 | Formation: Melee |
| 2 | Formation: Standby |
| 3 | Formation: Advance |
| 4 | Formation: Retreat |
| ESC | Cancel current mode |

## Integration

The Dragon Force battle is automatically used when `use_dragon_force = true` in CombatResolver.

To toggle between battle modes:
```gdscript
# In CombatResolver
use_dragon_force = true   # Use Dragon Force RTS
use_dragon_force = false  # Use legacy mass battle
```

## Art Assets Used

- **Electric Lemon Pixel Grit**: 16x16 character sprites (Artun, Janik, Nyro)
- **4-direction animations**: walk_up/down/left/right, attack_up/down/left/right, idle, hurt
- **Team colors**: Blue tint for player, Red tint for enemy

## Future Phases

### Phase 2: Formation & AI Improvements
- Multiple generals per side (up to 5)
- Class abilities (Warrior tanky, Rogue fast, Mage ranged)
- Duel mode when troops depleted

### Phase 3: Strategic Layer Integration
- Province nodes trigger Dragon Force battles
- Persistent troop counts between battles
- General capture/recruitment

### Phase 4: Full 5v5 Battles
- 5 generals per side
- Combined arms tactics
- Spell combos and counters
