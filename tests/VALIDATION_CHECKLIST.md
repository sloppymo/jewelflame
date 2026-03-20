# Knight Unit Validation Checklist

**Test Scene**: `res://tests/knight_validation.tscn`

---

## Pre-Test Setup
- [ ] Run `tools/gen_knight_frames.gd` to generate `animations/knight_sprite_frames.tres`
- [ ] Verify both PNG imports have Filter: Nearest
- [ ] Open `knight_validation.tscn` and ensure KnightUnit is visible

---

## Animation Sync Tests

| Test | Steps | Expected Result | Status |
|------|-------|-----------------|--------|
| Idle Sync | Start scene | All 5 troops play `idle_s`, same frame | [ ] |
| Direction N | Click "Test Directions" once | All face North (back to camera) | [ ] |
| Direction E | Click 3 more times | All face East (right profile) | [ ] |
| Walk NE | Click "Move NE" | All play `walk_ne` synchronized | [ ] |
| Stop | Click "Stop" | Seamless transition to `idle_ne` | [ ] |
| Attack | Click "Test Attack" | All play `attack_light_ne` (8 frames) | [ ] |
| Full Cycle | Click "Test Directions" 8 times | All 8 directions work without desync | [ ] |

**Issues Found:**
- 

---

## Damage Pipeline Tests

| Test | Steps | Expected Result | Status |
|------|-------|-----------------|--------|
| Lose 1 Troop | Click "Damage 20 HP" | Troop_4 disappears, gap remains | [ ] |
| Stats Update | Check label | Shows "Troops: 4/5 | Damage: 16" | [ ] |
| White Flash | Watch troops | Brief white flash on remaining 4 | [ ] |
| Lose 2 More | Click "Damage 40 HP" | Troop_3 and Troop_2 disappear | [ ] |
| Stats Update | Check label | Shows "Troops: 2/5 | Damage: 8" | [ ] |
| Kill Unit | Click "Kill Unit" | Death animation plays, unit removed | [ ] |
| Death Signal | Check output | "Unit died" printed to console | [ ] |
| Respawn | Click "Reset Unit" | New unit with 5 troops appears | [ ] |

**Issues Found:**
- 

---

## Edge Case Tests

| Test | Steps | Expected Result | Status |
|------|-------|-----------------|--------|
| Attack Priority | Move while attacking | Attack completes before walk resumes | [ ] |
| 1 Troop Damage | Damage to 1 troop, check calc | calculate_damage() returns 4 | [ ] |
| NW Death | Face NW, kill unit | Plays `death_n` (fallback), no crash | [ ] |
| Rapid Damage | Spam damage button | No negative troops, no crash | [ ] |
| Leader Death | Damage to 1 troop (leader) | Troop_0 hides, Troop_1 becomes "leader" | [ ] |
| Double Death | Kill twice rapidly | Only one death animation plays | [ ] |

**Issues Found:**
- 

---

## Visual Polish Tests

| Test | Steps | Expected Result | Status |
|------|-------|-----------------|--------|
| Selection Ring | Click on knight | Cyan ring appears around unit | [ ] |
| Deselect | Click elsewhere | Ring disappears (test manually) | [ ] |
| No Health Bars | Visual inspection | No HP bars visible anywhere | [ ] |
| Formation Spacing | Visual at 16×16 scale | Troops not overlapping, looks good | [ ] |
| Z-Sorting | Move vertically | Troops render in correct Y-order | [ ] |
| Frame Sync | Watch carefully | All troops on exact same frame | [ ] |

**Issues Found:**
- 

---

## Performance Tests

| Test | Steps | Expected Result | Status |
|------|-------|-----------------|--------|
| 10 Units | Instance 10 knights | No frame drops, all animate smoothly | [ ] |
| Memory | Monitor during test | No memory leaks on reset/kill | [ ] |

**Issues Found:**
- 

---

## Stat Balance Notes

Current values being tested:
```gdscript
max_troops = 5
base_damage = 20        # 5 troops = 20 dmg, 1 troop = 4 dmg
move_speed = 80.0       # Melee speed
attack_range = 20.0     # Must touch enemy
max_hp = 100            # 20 HP per knight
```

**Feel Notes:**
- Tanky but slow? [ ] Yes [ ] Needs adjustment
- Damage scaling fair? [ ] Yes [ ] Needs adjustment
- Formation readable? [ ] Yes [ ] Needs adjustment

---

## Final Sign-Off

**Animation Count**: 47/47 loaded [ ] Yes [ ] No - Missing: ___

**Sync Issues**: [ ] None found [ ] Minor [ ] Major - Describe: ___

**Damage Scaling**: [ ] Linear 20→4 working [ ] Broken - Describe: ___

**Death Fallback**: [ ] NW→N fallback functional [ ] Broken

**Formation Spacing**: [ ] Just right [ ] Too tight [ ] Too loose

**Ready for Archer Import?** [ ] YES - Template is solid [ ] NO - Fix issues first

---

## Discovered Bugs & Fixes

### Bug 1: 
**Symptom:** 
**Root Cause:** 
**Fix Applied:** 
**File Modified:** 

### Bug 2: 
**Symptom:** 
**Root Cause:** 
**Fix Applied:** 
**File Modified:** 

### Bug 3: 
**Symptom:** 
**Root Cause:** 
**Fix Applied:** 
**File Modified:** 
