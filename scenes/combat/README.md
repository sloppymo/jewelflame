# Mass Battle System - Real-Time with Pause (RTwP)

## Overview
A new combat system for Jewelflame featuring 20 vs 20 battles organized into 4 groups of 5 fighters per side.

## Architecture

### Core Components

1. **CombatGroup** (`combat_group.gd`)
   - Manages a group of 5 individual fighters
   - Handles group movement and orders
   - Tracks group health and status
   - Visual selection highlighting

2. **MassBattleController** (`mass_battle_controller.gd`)
   - Main battle orchestrator
   - Handles pause/unpause
   - Manages group selection and orders
   - Detects battle end conditions

3. **MassBattleUI** (`mass_battle_ui.gd`)
   - Pause/Resume button
   - Order buttons (Select, Move, Attack, Hold)
   - Auto-Command checkbox
   - Group status display
   - Victory/Defeat panel

4. **BattleLauncher Integration** (`battle_launcher.gd`)
   - Updated to launch mass battles instead of old tactical system
   - Passes attacker/defender data from strategic layer

## Controls

| Key/Button | Action |
|------------|--------|
| SPACE | Pause/Unpause battle |
| ESC | Cancel current order / Deselect |
| Left Click | Select group / Issue order |
| Right Click | Cancel order |
| Drag Box | Multi-select groups |
| Move Button | Issue move order |
| Attack Button | Issue attack order |
| Hold Button | Issue hold order |

## Order System

### Order Modes
1. **SELECT** - Default mode, click to select groups
2. **MOVE** - Click ground to move selected groups
3. **ATTACK** - Click enemy group to attack
4. **HOLD** - Selected groups hold position

### Order Execution
- Orders can only be given while paused
- Groups execute orders when unpaused
- Individual fighters use their own AI for combat

## Group States
- **IDLE** - Waiting for orders
- **MOVING** - Moving to target position
- **ENGAGED** - Moving toward and fighting enemy group
- **FLEEING** - Retreating (not implemented yet)
- **DEFEATED** - All fighters dead

## Testing

### Test Scene
Run `mass_battle_test.tscn` to test the system in isolation:
```bash
godot --path . --scene res://scenes/combat/mass_battle_test.tscn
```

### Integration Test
1. Launch main game
2. Select Attack action
3. Select source province (yours)
4. Select target province (enemy)
5. Mass battle should launch

## Future Enhancements

1. **Formation System** - Line, wedge, shield wall formations
2. **Special Abilities** - Charge, shield wall, volley fire
3. **Terrain Effects** - Hills, forests affecting combat
4. **Camera Controls** - Pan, zoom, follow units
5. **Replay System** - Save and replay battles

## Known Issues

1. Fighter AI is autonomous - they find their own targets once in range
2. No pathfinding around obstacles yet
3. Camera is static
4. No sound effects hooked up
