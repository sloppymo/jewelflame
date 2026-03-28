# Manual Test Protocol: Tactical-Strategic Integration

## Pre-Test Setup Checklist

### Step 1: Verify Scene Setup
Open `scenes/test_formation_combat.tscn`:

1. **Add TacticalBattleController:**
   - Right-click root node → Add Child Node → Node
   - Name: `TacticalBattleController`
   - Attach Script: `res://src/systems/tactical_battle_controller.gd`

2. **Verify FormationController Names:**
   - Rename first to: `FormationControllerA`
   - Rename second to: `FormationControllerB`

3. **Verify unit_scene assignment:**
   - Select `FormationControllerA`
   - In Inspector: check `Unit Scene` field is assigned
   - Do same for `FormationControllerB`

4. **Add BattleUI CanvasLayer:**
   - Add Child Node → CanvasLayer
   - Name: `BattleUI`

5. **Save scene**

## Test Suite

### TEST 1: Direct Tactical Scene Load (Baseline)
**Steps:**
1. In Godot, press F6 with `test_formation_combat.tscn` open
2. Observe: Do units spawn?

**Expected:**
- 50 units spawn on left (FormationControllerA) - WEDGE formation
- 50 units spawn on right (FormationControllerB) - LINE formation
- Units begin moving toward each other

### TEST 2: Strategic Map Attack Launch
**Steps:**
1. Press F5 (Play Project)
2. Click your province (blue - Blanche)
3. Click "Select Target" button
4. Click adjacent enemy province
5. Click "Attack [Province]" button

**Expected:**
- Console output: "BattleTransition: Loading tactical battle..."
- Scene changes to tactical combat
- Units spawn with correct counts

### TEST 3: Battle End & Return
**Steps:**
1. Complete TEST 2, let battle run
2. Wait for one side to be wiped out

**Expected:**
- Console output: "Battle ended! Winner: attacker"
- 2-second delay
- Scene changes back to strategic_map.tscn

### TEST 4: Casualty Application
**Steps:**
1. Note army size before battle (e.g., "Army: 30")
2. Complete battle
3. Return to strategic map
4. Click same province

**Expected:**
- Army size reduced by casualties
- If you lost 7 troops, shows "Army: 23"

### TEST 5: Province Capture
**Steps:**
1. Attack adjacent enemy province
2. Win the battle
3. Return to strategic map

**Expected:**
- Province color changes to your faction (blue)
- Console: "Battle won! [Province] captured."
- Province now selectable as your territory

### TEST 6: Auto-Resolve (ESC)
**Steps:**
1. Launch battle from strategic map
2. Press ESC key immediately

**Expected:**
- Battle ends instantly
- Winner determined by BattleResolver
- Returns to strategic map

### TEST 7: Time Scaling (SPACE)
**Steps:**
1. Launch battle
2. Press SPACE key

**Expected:**
- Battle speeds up (2x speed)
- Press SPACE again to return to normal

## Common Issues

### "BattleTransition not found"
**Fix:** Add to project.godot autoloads:
```ini
BattleTransition="*res://src/systems/battle_transition.gd"
```

### "FormationControllerA not found"
**Fix:** Rename your FormationController nodes in the scene to exactly:
- `FormationControllerA`
- `FormationControllerB`

### "Unit Scene not assigned"
**Fix:** In inspector for both FormationControllers, assign:
- Unit Scene = `res://scenes/units/combat_unit.tscn`

### "Battle never ends"
**Fix:** Check that CombatUnit nodes are being added to group "combat_units"
- In combat_unit.gd, verify _ready() has: `add_to_group("combat_units")`

### "After battle, map is wrong"
**Fix:** Check console for errors in return_to_strategic_map
- May be missing BattleUI node (add CanvasLayer named BattleUI)
