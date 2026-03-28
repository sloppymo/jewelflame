# Tactical-Strategic Integration Setup

## What Was Added

### New Files
1. `src/systems/battle_transition.gd` - Autoload singleton that handles scene transitions
2. `src/systems/tactical_battle_controller.gd` - Manages the tactical battle flow
3. `src/ui/pre_battle_deployment.gd` - Optional deployment screen (can be skipped for now)

### Modified Files
1. `src/systems/strategic_controller.gd` - Now calls `_launch_tactical_battle()` instead of auto-resolving
2. `project.godot` - Added `BattleTransition` as autoload

## How It Works

### Flow: Strategic → Tactical → Strategic

1. Player clicks "Attack" on strategic map
2. StrategicController._launch_tactical_battle() called
3. BattleTransition.initiate_battle() stores battle context
4. Scene changes to test_formation_combat.tscn
5. TacticalBattleController._ready() detects pending battle
6. Tactical battle plays out (50v50 combat)
7. Victory conditions checked (rout, wipeout, timeout)
8. TacticalBattleController._end_battle() called
9. BattleTransition.return_to_strategic_map() applies results
10. Scene changes back to strategic_map.tscn
11. Province ownership updated, casualties applied

## Required Scene Changes

### 1. Update test_formation_combat.tscn

Add a new node as child of root:

```
TacticalBattleController (Node)
  Script: res://src/systems/tactical_battle_controller.gd
```

Rename your existing FormationControllers to:
- `FormationControllerA` (attacker - left side)
- `FormationControllerB` (defender - right side)

### 2. Update CombatUnit.tscn (if needed)

Ensure CombatUnit scene has:
- AnimatedSprite2D node
- AttackCooldown Timer node (or script creates one)

### 3. Optional: Create PreBattleDeployment scene

Create `scenes/pre_battle_deployment.tscn`:
- Root: Control node
- Add PreBattleDeployment.gd script
- UI showing attacker vs defender info
- Formation selection dropdown
- Confirm/Cancel buttons

## Testing the Integration

### Quick Test
1. Run strategic_map.tscn
2. Select your province, click "Select Target"
3. Click enemy province, click "Attack [Province]"
4. Should load tactical combat scene
5. Battle plays out automatically
6. After victory/defeat, returns to strategic map
7. Province ownership updated

### Debug Controls (in tactical battle)
- **ESC**: Auto-resolve instantly
- **SPACE**: Speed up/slow down time

## Battle End Conditions

| Condition | Result |
|-----------|--------|
| One side wiped out | Immediate victory for survivors |
| 70% total casualties | Rout - side with more troops wins |
| 3 minute timeout | Defender advantage (defender wins unless attacker has 50% more troops) |
| Formation broken | Attacker formation break = instant defender win. Defender break = 10 second window |

## Known Limitations (v1)

1. **Hero system is skeleton** - Heroes exist in data but have no UI or assignment flow
2. **No pre-battle deployment** - Uses default WEDGE vs LINE formations
3. **AI battles still auto-resolve** - Only player battles go to tactical
4. **No visual feedback** - No battle result popup yet
5. **No retreat option** - Once battle starts, must finish
