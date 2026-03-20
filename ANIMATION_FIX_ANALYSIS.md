# Knight Attack Animation Fix - Deep Dive Analysis

## Problem Statement
Knight attack animations show broken/partial sprites during the swing animation.

## Root Cause Analysis

### 1. Wrong Direction Mapping
The current code assumes this row-to-direction mapping:
```gdscript
var dirs = ["s", "n", "se", "ne", "e", "w", "sw", "nw"]
```

**Actual sprite sheet layout** (based on visual analysis):
| Row | Direction | Evidence |
|-----|-----------|----------|
| 0 | s (South) | Front view, sword low |
| 1 | n (North) | Back view (top-down) |
| 2 | e (East) | Side view, facing right |
| 3 | w (West) | Side view, facing left |
| 4 | se (Southeast) | 45° angle view |
| 5 | nw (Northwest) | 45° angle view |
| 6 | sw (Southwest) | 45° angle view |
| 7 | ne (Northeast) | 45° angle view |

**Fix**: Change direction array to match actual sprite layout.

### 2. Frame Count Issue
The code assumes 8 frames per animation:
```gdscript
_add_anim(sf, c_tex, "attack_light_" + dir, i, 8, 12.0, false)
```

**Analysis of frame pixel counts** (Row 0 example):
| Column | Pixels | Status |
|--------|--------|--------|
| 0 | 63 | Valid frame |
| 1 | 19 | Transition/partial |
| 2 | 65 | Valid frame |
| 3 | 19 | Transition/partial |
| 4 | 31 | Valid frame (less content) |
| 5 | 119 | **Main attack frame** (most pixels) |
| 6 | 17 | Transition/partial |
| 7 | 62 | Valid frame |

**Issue**: Columns 1, 3, 6 have very few pixels (17-19) and appear to be 
transition/wind-up frames that don't render well.

### 3. Frame Sequence Problem
Even with correct frames, the sequence might be wrong. Looking at the animation:
- Frame 5 (col 5) has the most pixels - this is likely the MAIN attack frame
- The sequence should probably be: wind-up → swing → follow-through

## Solution Options

### Option A: Fix Direction Mapping Only (Quick Fix)
```gdscript
var dirs = ["s", "n", "e", "w", "se", "nw", "sw", "ne"]
```

### Option B: Fix Direction + Filter Empty Frames
```gdscript
# Only use frames with >30 pixels
var valid_frames = [0, 2, 4, 5, 7]  # Skip cols 1, 3, 6
```

### Option C: Fix Direction + Reorder Frames
```gdscript
# Reorder to proper animation sequence
var frame_order = [0, 2, 5, 7, 4]  # Wind-up, swing, main, follow-through, recover
```

### Option D: Complete Rewrite (Recommended)
```gdscript
# 1. Fix direction mapping
var dirs = ["s", "n", "e", "w", "se", "nw", "sw", "ne"]

# 2. Use specific frame indices for each animation type
# Attack animations use cols: 0, 2, 4, 5, 7 (skip 1, 3, 6)
# OR reorder based on actual animation sequence
```

## Implementation Steps

1. **Verify the direction mapping** by testing each row visually in Godot
2. **Determine valid frames** by checking pixel counts
3. **Establish frame sequence** by analyzing the animation flow
4. **Update build_sprite_frames()** with correct mapping
5. **Test all 8 directions** to ensure consistency

## Files to Modify
- `scenes/characters/Knight_Combat.gd` - `build_sprite_frames()` function

## Testing Protocol
1. Run game with fixed mapping
2. Watch knights attack in each direction
3. Verify no partial/broken sprites
4. Check animation smoothness

## Additional Considerations

### Attack Heavy (Rows 8-15)
Same issue likely exists for attack_heavy animations.
Apply same fix to rows 8-15.

### Hurt Animations (Rows 16-23)
May also need direction remapping.

### Non-Combat Sheet
The non-combat sheet (idle/walk/run) uses 4 columns, not 8.
Direction mapping might be different there too!

## Quick Test Code
```gdscript
# Add this to _ready() temporarily to test direction mapping
for dir in ["s", "n", "e", "w", "se", "sw", "ne", "nw"]:
    print("Testing direction: ", dir)
    play("attack_light_" + dir)
    await get_tree().create_timer(1.0).timeout
```

## Conclusion
The broken sprites are caused by:
1. **Wrong direction-to-row mapping** (primary issue)
2. **Including empty/transition frames** (secondary issue)
3. **Possible frame sequence misordering** (tertiary issue)

Fixing the direction array is the first step. If animations still look wrong,
filter out the low-pixel frames (cols 1, 3, 6) or reorder the sequence.
