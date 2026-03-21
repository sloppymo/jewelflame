# Sprite Sheet Animation Evaluation Request

## Project Context
**Jewelflame** - Godot 4.x RTS game with sprite-based units

## What Was Implemented
Sprite sheet import system for 2D pixel art characters with 8-directional movement and combat animations.

## Source Assets (Purchased - Do Not Modify)
Located at: `/home/sloppymo/jewelflame/assets/Citizens - Guards - Warriors/Warriors/`

### Sheet 1: Sword & Shield Fighter
| File | Dimensions | Frame Size | Grid | Total Frames |
|------|-----------|------------|------|--------------|
| Sword_and_Shield_Fighter_Non-Combat.png | 64×496 | 16×16 | 4 cols × 31 rows | 124 |
| Sword_and_Shield_Fighter_Combat.png | 128×640 | 32×32 | 4 cols × 20 rows | 80 |

### Sheet 2: Archer
| File | Dimensions | Frame Size | Grid | Total Frames |
|------|-----------|------------|------|--------------|
| Archer_Non-Combat.png | 64×496 | 16×16 | 4 cols × 31 rows | 124 |
| Archer_Combat.png | 128×256 | 32×32 | 4 cols × 8 rows | 32 |

## Animation Structure (As Implemented)

### Non-Combat Sheets (Both Characters)
**Row Groupings (8 rows per group, 4 frames per animation):**
- Rows 0-7: IDLE (8 directions) - 6 fps, looping
- Rows 8-15: WALK (8 directions) - 8 fps, looping
- Rows 16-23: WALK2 (8 directions) - 8 fps, looping
- Rows 24-30: DEATH (7 rows only - missing one diagonal direction)

**Direction Order (Critical - Confirmed by pixel mass analysis):**
```
Row +0 = S (south, facing camera)
Row +1 = N (north, back to camera)
Row +2 = SE (southeast diagonal)
Row +3 = NE (northeast diagonal)
Row +4 = E (east, right profile)
Row +5 = W (west, left profile)
Row +6 = SW (southwest diagonal)
Row +7 = NW (northwest diagonal)
```

E/W confirmed by X-center pixel shifts (E shifts right 7.9→11.0, W shifts left 7.1→4.0).

### Combat Sheets

#### Sword & Shield Combat (32×32 frames, 4 directions)
**Row Groupings (4 rows per group, 4 frames per animation):**
- Rows 0-3: ATTACK1 (overhead swing) - 10 fps
- Rows 4-7: ATTACK2 (diagonal slash) - 10 fps
- Rows 8-11: ATTACK3 (thrust/stab) - 8 fps
- Rows 12-15: HURT (flinch reaction) - 8 fps
- Rows 16-19: SPECIAL (fire/magic effect, orange palette) - 8 fps

**Direction Order (4 directions, best estimate):**
```
Row +0 = S (toward viewer)
Row +1 = N (away from viewer)
Row +2 = W (left-facing)
Row +3 = E (right-facing)
```
⚠️ NOTE: This order was NOT confirmed by pixel analysis - verify visually.

#### Archer Combat (32×32 frames)
**Row Groupings:**
- Rows 0-3: SHOOT (4 directions: E, W, S, N) - 10 fps, damage at frame 2
- Rows 4-5: HURT (2 directions + horizontal mirror) - 8 fps
- Rows 6-7: DEATH (2 directions) - 6 fps

**Critical Finding - Mirror Rows (Mathematically Confirmed):**
- Row 01 = Row 00 horizontally flipped (flipped_diff = 0.0)
- Row 05 = Row 04 horizontally flipped (flipped_diff = 0.0)

This means shoot_w is a mirror of shoot_e, and hurt_w is a mirror of hurt_e.

## Generated Files

### SpriteFrames Resources (.tres)
Located at: `/home/sloppymo/jewelflame/assets/animations/`
1. `swordshield_non_combat.tres` - 31 animations
2. `swordshield_combat.tres` - 20 animations
3. `archer_non_combat.tres` - 31 animations
4. `archer_combat.tres` - 8 animations

### Unit Scenes
Located at: `/home/sloppymo/jewelflame/units/`
1. `sword_shield_unit.tscn` + `sword_shield_unit.gd`
2. `archer_unit.tscn` + `archer_unit.gd`

### Test Scenes
Located at: `/home/sloppymo/jewelflame/tests/`
1. `sword_shield_test.tscn` - Test scene for sword & shield
2. `archer_test.tscn` - Test scene for archer

## Technical Implementation Details

### EditorScripts (Generation Tools)
Located at: `/home/sloppymo/jewelflame/tools/`
- `gen_non_combat_frames.gd` - Generates non-combat animations
- `gen_combat_frames.gd` - Generates sword/shield combat animations
- `gen_archer_non_combat_frames.gd` - Generates archer non-combat
- `gen_archer_combat_frames.gd` - Generates archer combat

All use `AtlasTexture` with `filter_clip = true` to prevent bleeding.

### Unit Script Features
- **Formation**: V-shape, 5 troops (Troop_0 through Troop_4)
- **State Machine**: IDLE, WALKING, ATTACKING, HURT, DEAD
- **Dynamic SpriteFrames**: Switches between non-combat (16×16) and combat (32×32)
- **Offset Handling**: Combat sprites offset by Vector2(-8, -4) to prevent viewport clipping
- **Troop Visibility**: Static gaps when troops die (no repositioning)
- **Damage Scaling**: Based on remaining troop count

## Evaluation Checklist

Please verify the following:

### 1. Animation Completeness
- [ ] All 31 non-combat animations present per character
- [ ] All combat animations present (20 for S&S, 8 for archer)
- [ ] Frame counts correct (4 frames per animation)
- [ ] Animation speeds appropriate (idle: 6fps, walk: 8fps, attack: 10fps)

### 2. Direction Accuracy
- [ ] Non-combat 8-direction order matches pixel analysis
- [ ] Combat 4-direction order is visually correct
- [ ] Diagonal directions (NE, NW, SE, SW) animate correctly
- [ ] No direction flipping (E vs W confusion)

### 3. Visual Quality
- [ ] No sprite bleeding between frames
- [ ] Combat sprites (32×32) don't clip at viewport edges during swings
- [ ] Formation spacing looks natural (troops not overlapping/clipping)
- [ ] Color palettes correct (especially SPECIAL animation orange/fire)

### 4. Mirror Handling
- [ ] Archer shoot_w correctly mirrors shoot_e
- [ ] Archer hurt_w correctly mirrors hurt_e
- [ ] No visual glitches on mirrored animations

### 5. Death Animation
- [ ] 7 directions present (one missing diagonal handled gracefully)
- [ ] death_corpse frame is near-static (2fps, appropriate)
- [ ] death_prone_s/n look correct (Y center ~10.2)

### 6. Code Quality
- [ ] No class_name conflicts (SwordShieldUnit, ArcherUnit)
- [ ] Proper type declarations (no inference errors)
- [ ] SpriteFrames resources load correctly
- [ ] Test scenes run without errors

### 7. Combat Offset
- [ ] Sword swings fully visible (not clipped at top)
- [ ] Archer bow draw visible
- [ ] 32×32 sprites centered properly on 16×16 base positions

## Known Issues to Check

1. **Combat Direction Order**: The 4-direction order (S, N, W, E) for combat sheets was a "best estimate" - verify if correct or if it should be (S, N, E, W) or different.

2. **Offset Tuning**: Combat sprite offset is Vector2(-8, -4). Verify this keeps swords/arrows fully visible during all animation frames.

3. **Formation Spacing**: Current formation has Troop_0 at (0,0), others at ±10px X and +8/+16px Y. Check if spacing prevents overlap during combat animations.

4. **Missing Death Direction**: Non-combat sheets have only 7 death rows (missing one diagonal). Verify the fallback logic handles this gracefully.

## How to Test

1. Open `tests/sword_shield_test.tscn`
2. Run scene (F6)
3. Click to move unit - check walk animation directions
4. Press 3 for attack - verify sword swing is fully visible
5. Press 4 for hurt - check reaction animation
6. Repeat for `tests/archer_test.tscn`

## Questions to Answer

1. Does the direction order look correct in all 8 directions?
2. Are combat animations (especially sword swings) fully visible or clipped?
3. Do mirrored archer animations (shoot_w, hurt_w) look correct?
4. Is the formation spacing appropriate for the sprite sizes?
5. Should the combat direction order be changed?
6. Are there any missing animations or frames?
7. Do the death animations play correctly with only 7 directions?

## File Locations for Review

```
/home/sloppymo/jewelflame/
├── assets/
│   └── Citizens - Guards - Warriors/
│       └── Warriors/
│           ├── Sword_and_Shield_Fighter_Non-Combat.png
│           ├── Sword_and_Shield_Fighter_Combat.png
│           ├── Archer_Non-Combat.png
│           └── Archer_Combat.png
├── assets/animations/
│   ├── swordshield_non_combat.tres
│   ├── swordshield_combat.tres
│   ├── archer_non_combat.tres
│   └── archer_combat.tres
├── units/
│   ├── sword_shield_unit.gd
│   ├── sword_shield_unit.tscn
│   ├── archer_unit.gd
│   └── archer_unit.tscn
└── tests/
    ├── sword_shield_test.tscn
    └── archer_test.tscn
```

## Deliverables

Please provide:
1. Evaluation of animation correctness (directions, frames, timing)
2. Visual quality assessment (clipping, bleeding, spacing)
3. Recommendations for any fixes needed
4. Confirmation of which direction orders are correct vs need changing
5. Suggested offset values if current ones cause clipping
