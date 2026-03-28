# Animation Showcase

A peaceful scene where all your sprites show off their animations!

## How to Run

1. Open `tests/battle_arena.tscn` in Godot
2. Press **F6** (Play Current Scene)
3. Watch all the animations!

## Controls

| Key | Action |
|-----|--------|
| **Space** | Spawn unit at mouse cursor |
| **R** | Reset (clear and respawn) |
| **Esc** | Quit |

## What You'll See

- **16 units** initially (2 of each type)
- Units cycle through animations automatically:
  - **Idle** - standing, rolling, interacting
  - **Walk/Run/Jump** - moving around
  - **Attack** - attacking poses
  - **Hurt** - damage reactions
  - **Death** - dying and respawning
- **No health bars** - clean visuals
- **No camera shake** - steady view

## Animation Cycle

Each unit automatically cycles through states every 2.5 seconds:
1. Idle (with random variations: roll, interact)
2. Wander (walk, run, or jump)
3. Attack (attack animation)
4. Hurt (damage reaction)
5. Death (dies, then respawns after 1.5s)

## Unit Types

| Unit | Description |
|------|-------------|
| SwordShield | 8-directional, 16x16 frames |
| Archer | 8-directional, 16x16 frames |
| Knight | 8-directional, 16x16 frames |
| HeavyKnight | 4-directional, 24x24 frames |
| Paladin | 4-directional, 24x24 frames |
| Mage | 4-directional, 16x16 frames |
| Rogue | 4-directional, 16x16 frames |
| HoodedRogue | 4-directional, 16x16 frames |

## Troubleshooting

**Animations not showing?**
- Make sure you've generated the .tres files with the corrected scripts

**Some animations missing?**
- Not all units have all animations (e.g., interact only has down/up)
- The code falls back to "_down" if a direction doesn't exist
