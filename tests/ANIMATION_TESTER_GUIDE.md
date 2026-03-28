# Animation Tester v2.0 - Comprehensive Guide

## Overview

The Animation Tester is a Godot 4.x debugging/development tool for testing and previewing sprite animations across 8 different unit types with multiple animation sources per unit. It's designed for rapid iteration when integrating new sprite sheets.

## Files

- `tests/animation_tester.tscn` - Main scene file
- `tests/animation_tester.gd` - Main script (150+ lines)
- `tests/grid_overlay.gd` - Grid rendering helper
- `tests/ANIMATION_TESTER_GUIDE.md` - This document

## Supported Units

| Key | Unit | Frame Sizes | Sources Available |
|-----|------|-------------|-------------------|
| 1 | SwordShield | 16x16 / 32x32 | NC, CO |
| 2 | Archer | 16x16 / 32x32 | NC, CO |
| 3 | Knight (2H) | 16x16 / 32x32 | NC, CO |
| 4 | Heavy Knight | 24x24 / 32x32 | NC, CO, ThrustND, ThrustD |
| 5 | Paladin | 24x24 / 32x32 | NC, CO, ThrustND, ThrustD |
| 6 | Mage (Red) | 16x16 | NC, CO |
| 7 | Rogue (Regular) | 16x16 | NC(Daggers), NC-Alt(Bow), CO, CO-FX |
| 8 | Rogue (Hooded) | 16x16 | NC(Daggers), NC-Alt(Bow), CO, CO-FX |

**Source Definitions:**
- **NC** = Non-Combat (idle, walk, run, etc.)
- **NC-Alt** = Non-Combat Alternate (bow equipped for rogues)
- **CO** = Combat (combat_idle, attack, hurt)
- **CO-FX** = Combat with Effects (attack with VFX)
- **ThrustND** = Thrust animation without dash
- **ThrustD** = Thrust animation with dash

## Controls

### Unit Selection
```
[1-8] - Switch to unit (see table above)
```

### Source Selection (per unit)
```
[Q] - NC (Non-Combat / Daggers)
[W] - NC-Alt (Bow equipped) - Rogues only
[E] - Combat
[R] - Combat with FX - Rogues only
[T] - Thrust NoDash - HeavyKnight/Paladin only
[Y] - Thrust Dash - HeavyKnight/Paladin only
```

### View Controls
```
[Tab]     - Toggle between Animation and Spritesheet view modes
[G]       - Toggle 16px grid overlay with center crosshair
[B]       - Cycle background colors (7 presets)
[C]       - Center sprite (reset pan)
```

### Zoom & Pan
```
]         - Zoom in (1.2x multiplier)
[         - Zoom out (1.2x divider)
\         - Reset zoom to 4x
Ctrl+Scroll - Mouse zoom (Ctrl + mouse wheel)
```

### Animation Navigation
```
↑ / ↓         - Previous/Next animation
PageUp / PageDown - Skip ±10 animations
Space         - Play current animation
P             - Toggle pause/resume
S             - Stop (reset to frame 0)
L             - Toggle loop on/off
← / →         - Step forward/backward one frame (pauses first)
```

### Speed Control
```
+ / =         - Increase speed (+2 FPS)
-             - Decrease speed (-2 FPS, min 1.0)
0             - Reset speed to 10 FPS
```

### System
```
F5            - Full reset (unit, zoom, pan, source, animation)
Esc           - Quit application
```

## UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  UNIT INFO (top-left)      │         DEBUG INFO (top-right) │
│  - Name & Key              │         - Current animation    │
│  - View mode & Source      │         - Frame / Total        │
│  - Frame size & Directions │         - Speed & Loop status  │
│  - Animation count & Zoom  │         - Atlas region (debug) │
├────────────────────────────┴────────────────────────────────┤
│  SOURCE BAR (below info)                                     │
│  Shows available sources for current unit with >>> indicator │
├────────────────────────────┬────────────────────────────────┤
│  ANIMATION LIST (left)     │       CONTROLS (bottom-right)  │
│  - Shows 11 anims around   │       - All key bindings       │
│    current selection       │       - Grouped by category    │
│  - >>> marks current       │                                │
└────────────────────────────┴────────────────────────────────┘
```

## Architecture

### Key Data Structures

```gdscript
enum UnitType { SWORDSHIELD, ARCHER, KNIGHT, HEAVY_KNIGHT, PALADIN, MAGE, ROGUE, ROGUE_HOODED }
enum ViewMode { ANIMATION, SPRITESHEET }
enum SourceType { NC, NC_ALT, CO, CO_FX, THRUST_ND, THRUST_D }

# Each unit has a configuration dictionary
var unit_configs := {
    UnitType.ROGUE: {
        "name": "Rogue",
        "nc_path": "res://assets/animations/rogue_nc_daggers.tres",
        "nc_alt": "res://assets/animations/rogue_nc_bow.tres",
        "co_path": "res://assets/animations/rogue_combat_no_fx.tres",
        "co_fx": "res://assets/animations/rogue_combat_fx.tres",
        "sources": [SourceType.NC, SourceType.NC_ALT, SourceType.CO, SourceType.CO_FX],
        "frame_size": "16x16",
        "directions": "4-dir"
    }
}
```

### Core Methods

- `_setup_sprite()` - Creates AnimatedSprite2D and loads frames
- `_load_unit_frames()` - Loads SpriteFrames from current source path
- `_get_current_source_path()` - Returns path based on current_source enum
- `_switch_unit(unit_type)` - Changes unit, resets source to NC
- `_switch_source(source_type)` - Changes animation source (if available)
- `_refresh_animation_list()` - Populates animation_names array
- `_update_display()` - Updates all UI labels

### Source Switching Logic

The tool dynamically checks if a source is available for the current unit:

```gdscript
func _switch_source(source_type: SourceType):
    var config = unit_configs[current_unit]
    if not source_type in config["sources"]:
        print("Source not available for this unit")
        return
    # ... switch logic
```

## Adding a New Unit

1. **Add to enum:**
```gdscript
enum UnitType { ..., NEW_UNIT }
```

2. **Add to unit_configs:**
```gdscript
UnitType.NEW_UNIT: {
    "name": "New Unit Name",
    "nc_path": "res://assets/animations/new_unit_nc.tres",
    "co_path": "res://assets/animations/new_unit_combat.tres",
    "sources": [SourceType.NC, SourceType.CO],
    "frame_size": "16x16",
    "directions": "4-dir"
}
```

3. **Add key binding in _unhandled_input():**
```gdscript
KEY_9:
    _switch_unit(UnitType.NEW_UNIT)
```

4. **Update UI label** in `animation_tester.tscn` to show new key

5. **Update _get_unit_key():**
```gdscript
UnitType.NEW_UNIT: return "9"
```

## Adding a New Source Type

1. **Add to SourceType enum**
2. **Add to source_names dictionary**
3. **Add key binding** (e.g., KEY_U)
4. **Update _get_source_key()**
5. **Update _get_current_source_path()** with new case
6. **Add path to unit configs** that use it

## Common Use Cases

### Checking All Animations for a Unit
1. Press unit key (1-8)
2. Press Space to play
3. Use ↑/↓ to browse through animations
4. Use ←/→ to inspect individual frames

### Comparing Combat vs Non-Combat
1. Select unit (e.g., 7 for Rogue)
2. Press Q to view NC, E to view Combat
3. Compare animation counts and frame sizes

### Frame Debugging
1. Pause animation (P)
2. Use ←/→ to step through frames
3. Check "Atlas" line in debug panel for exact frame coordinates
4. Enable grid (G) to see pixel alignment

### Zooming for Detail
1. Press ] multiple times to zoom in (up to 16x)
2. Or use Ctrl+Scroll for mouse control
3. Press \ to reset

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Failed to load" error | Check that .tres file exists and path is correct |
| Animation list empty | Verify SpriteFrames resource has animations defined |
| Wrong source shown | Press Q to reset to NC, then try other sources |
| Sprite off-screen | Press C to center, or \ to reset zoom |
| Can't switch source | That unit doesn't have that source type defined |

## Extending the Tool

### Adding Pan with Middle-Mouse
```gdscript
# In _unhandled_input()
if event is InputEventMouseButton:
    if event.button_index == MOUSE_BUTTON_MIDDLE:
        is_panning = event.pressed

if event is InputEventMouseMotion and is_panning:
    pan_offset += event.relative
```

### Adding Frame Export
```gdscript
func _export_current_frame():
    var anim = animation_names[current_anim_index]
    var frame = sprite.frame
    var texture = sprite.sprite_frames.get_frame_texture(anim, frame)
    # Save to disk...
```

### Adding Animation Comparison Mode
Split-screen view showing two units side-by-side with synchronized playback.

## Dependencies

- Godot 4.x
- SpriteFrames resources in `res://assets/animations/`
- Grid overlay script (grid_overlay.gd)

## Notes for AI Assistants

When modifying this tool:
1. Always update the UI label when adding new keys
2. Keep the source switching validation logic
3. Maintain the enum → name → key mapping consistency
4. Test with multiple unit types after changes
5. The grid overlay is optional - tool works without it
