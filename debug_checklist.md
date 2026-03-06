# Jewelflame Part 2 Debug Checklist

## ✅ Fixed Issues

### 1. Parentheses Bug - FIXED
- **Issue**: Extra closing parentheses in battle resolver casualty calculations
- **Solution**: Rewrote battle_resolver.gd with correct syntax
- **Verification**: Lines 51 and 55 now have proper parentheses

### 2. Autoload Configuration - VERIFIED
- **AIController**: ✓ Configured
- **BattleResolver**: ✓ Configured  
- **HarvestSystem**: ✓ Configured
- **EconomyManager**: ✓ Configured
- **RandomEvents**: ✓ Configured
- **AnimationController**: ✓ Added to strategic_map.tscn with group

### 3. Attack Button Integration - VERIFIED
- **AttackButton**: ✓ Added to province_panel.tscn
- **Connection**: ✓ Connected to _on_attack_button_pressed()
- **Text**: Shows "Attack" (simple, no cost display)

## 🔍 Quick Test Protocol

### Test 1: Turn Cycle
1. Open Godot, run project (F5)
2. Click "End Turn" 
3. **Expected**: Console shows "AI turn starting for: lyle", then "AI turn starting for: coryll", then back to player
4. **If crash**: Check Output for "Invalid call" errors (missing autoload)

### Test 2: AI Behavior  
1. Wait for Lyle's turn (Cobrige province)
2. **Expected**: Console shows either "recruited X soldiers" or "attacks [Province]" or "developed [type]"
3. **If nothing happens**: AIController.take_turn() not being called

### Test 3: Battle Resolution
1. Select Dunmoor, click Attack button
2. Target Cobrige (adjacent enemy) 
3. **Expected**: BattleReport dialog pops up with casualties and loot
4. **If no dialog**: BattleResolver not connected to UI

### Test 4: September Harvest
1. Open Debug > Console
2. Type: `GameState.current_month = 9`
3. Click End Turn twice (to advance to next family)
4. **Expected**: "September Harvest Report" dialog appears
5. **If nothing**: HarvestSystem not connected to turn flow

## 🚨 Common Failure Modes

### AI Doesn't Act
- **Symptom**: Turn advances but no AI actions in console
- **Cause**: AIController.take_turn() not being called from GameState
- **Fix**: Check GameState.advance_turn() calls AIController for non-player families

### Battles Don't Resolve  
- **Symptom**: Attack button does nothing or crashes
- **Cause**: BattleResolver not configured as autoload or signal connection missing
- **Fix**: Verify BattleResolver in project.godot and EventBus.BattleResolved connection

### No Harvest Popup
- **Symptom**: September passes without harvest report
- **Cause**: Signal connection missing between HarvestSystem and HarvestReport
- **Fix**: Verify EventBus.HarvestReportReady connection in turn_controller.gd

### Animation Issues
- **Symptom**: Attack animations don't show
- **Cause**: AnimationController not found by province panel
- **Fix**: Verify AnimationController has "animation_controller" group and is in strategic_map.tscn

## 🛠️ Debug Commands

### Console Commands for Testing
```gdscript
# Force September harvest
GameState.current_month = 9

# Check turn state
print("Current family: ", GameState.get_current_family())
print("Month: ", GameState.current_month, "/", GameState.current_year)

# Force AI turn
AIController.take_turn("lyle")

# Test battle directly
var result = BattleResolver.resolve_province_attack(1, 3, 50)
print(result)
```

### File Locations to Check
- `project.godot` - Autoload configuration
- `strategic/map/strategic_map.tscn` - UI elements and AnimationController
- `ui/province_panel.tscn` - Attack button
- `battle/battle_resolver.gd` - Parentheses fix
- `autoload/game_state.gd` - AI turn calling

## 📊 Expected Behavior

### Normal Game Flow
1. Player turn: Can recruit, develop, attack
2. End Turn: Advances to Lyle (aggressive AI)
3. Lyle turn: Should recruit or attack within 1.5s delays
4. End Turn: Advances to Coryll (opportunistic AI)  
5. Coryll turn: Should act within 1.5s delays
6. End Turn: Back to player, month may advance

### AI Personalities
- **Lyle (aggressive)**: Attacks when 0.8+ strength ratio, recruits large armies
- **Coryll (opportunistic)**: Attacks isolated targets, balanced development
- **Player (Blanche)**: Defensive AI if controlled by AI

### Battle System
- Terrain bonuses applied (woods 1.2x, river 1.1x, etc.)
- Defender gets 1.1x bonus
- Casualties: Winner 0-40%, Loser 60-80%
- Conquest transfers 30% loot and ownership

## ✅ Ready for Testing

All critical integration points verified:
- Parentheses bug fixed
- Autoloads configured
- Attack button integrated
- UI elements in scenes
- Signal connections present

**Status**: Ready for Godot playtesting
