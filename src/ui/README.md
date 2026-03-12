# Jewelflame UI System - REFACTORED

Complete UI implementation for Jewelflame strategy game with Godot 4.x best practices.

## What's Fixed

### ✅ Critical Fixes (Phase 1)
1. **MessagePanel** - Now a proper `.tscn` scene file (no dynamic node creation)
2. **EventModal** - Now a proper `.tscn` scene file with full node hierarchy
3. **Signal Safety** - Fixed disconnect/connect pattern using connection iteration
4. **Memory Leaks** - Fixed choice container cleanup (remove_child before queue_free)

### ✅ Safety & Stability (Phase 2)
1. **is_instance_valid() checks** - All await coroutines check validity
2. **Node References** - Using Dictionary arrays instead of string paths
3. **Input Handling** - Changed to _gui_input() for proper focus handling
4. **Pause System** - New PauseManager singleton for stacked pause sources

### ✅ Architecture (Phase 3)
1. **Anchoring** - MessagePanel uses anchors only (no pixel offsets)
2. **Type Safety** - Strong typing throughout
3. **Tween-based typewriter** - More efficient than timer callbacks

## File Structure

```
jewelflame/
└── src/
    └── ui/
        ├── game_ui.tscn          # Main UI scene
        ├── game_ui.gd            # Main UI controller
        ├── sidebar.tscn          # Sidebar scene
        ├── sidebar.gd            # Sidebar logic (FIXED)
        ├── message_panel.tscn    # Message panel scene (NEW - proper scene)
        ├── message_panel.gd      # Message panel logic (FIXED)
        ├── event_modal.tscn      # Event modal scene (NEW - proper scene)
        ├── event_modal.gd        # Event modal logic (FIXED)
        ├── pause_manager.gd      # Pause stack manager (NEW)
        └── README.md             # This file
```

## Installation

1. Copy all files to `res://src/ui/`
2. **Add PauseManager as Autoload:**
   - Project Settings → Autoload
   - Path: `res://src/ui/pause_manager.gd`
   - Name: `PauseManager`
3. Add `game_ui.tscn` as child of your main game scene
4. Move your hex map under `GameUI/MainContainer/MapArea`

## Key API Changes

### PauseManager (New)
```gdscript
# Instead of get_tree().paused = true
PauseManager.push_pause("event_modal")

# Later...
PauseManager.pop_pause("event_modal")

# Check stack
print(PauseManager.get_pause_stack())  # ["event_modal", "dialog"]
```

### MessagePanel (Fixed)
```gdscript
# Same API, but now uses Tweens internally (more efficient)
message_panel.show_message("Text with typewriter effect")
message_panel.show_message_with_choices("Question?", ["A", "B", "C"])

# Choices now properly clean up (no memory leak)
```

### EventModal (Fixed)
```gdscript
# Now uses PauseManager instead of direct pause
event_modal.show_event(EventModal.ModalType.VICTORY, data)

# Full scene file - editable in Godot editor
```

### Sidebar (Fixed)
```gdscript
# Same API, but safer signal handling
sidebar.action_pressed.connect(func(action): ...)

# Buttons referenced via Dictionary (no string paths)
```

## Safety Features

### 1. Instance Validity Checks
All coroutines check `is_instance_valid(self)` after awaits:
```gdscript
await timer.timeout
if not is_instance_valid(self):
    return
# Continue safely...
```

### 2. Safe Signal Disconnecting
```gdscript
# Get all connections and disconnect safely
for connection in btn.pressed.get_connections():
    btn.pressed.disconnect(connection.callable)
```

### 3. Proper Node Cleanup
```gdscript
# Remove from tree BEFORE queue_free (prevents memory leak)
for child in container.get_children():
    container.remove_child(child)
    child.queue_free()
```

### 4. Focus-Aware Input
```gdscript
func _gui_input(event):
    # Only handles input when this control has focus
    # Won't interfere with other UI elements
```

## Testing Checklist

- [ ] MessagePanel displays text with typewriter effect
- [ ] Clicking during typewriter skips to end
- [ ] Choices appear and are clickable
- [ ] Choices clean up properly (check Remote scene tree)
- [ ] EventModal shows all event types
- [ ] Modal pauses game, unpauses on dismiss
- [ ] Sidebar buttons respond to clicks
- [ ] Section switching works
- [ ] Resource updates reflect in UI
- [ ] No errors in Output panel
- [ ] Works at 1920x1080 and 2560x1440

## Migration from Old Version

If you were using the previous version:

1. Replace all `.gd` files with new versions
2. Replace `message_panel.tscn` with new version
3. Add new files: `event_modal.tscn`, `pause_manager.gd`
4. Set up PauseManager autoload in Project Settings
5. Update any direct `get_tree().paused = true` calls to use PauseManager

## Performance Notes

- **Tweens** - Typewriter effect uses Tweens (GPU-accelerated)
- **No dynamic node creation** - All nodes in .tscn files
- **Efficient cleanup** - Proper tree removal before free
- **Minimal string operations** - Dictionary lookups instead of string paths

## Color Scheme

| Element | Color | Hex |
|---------|-------|-----|
| Background (dark teal) | #1a2f3a | Dark teal-blue |
| Gold accent | #d4af37 | Bright gold |
| Text (cream) | #f5f5dc | Off-white |
| Text (muted) | #a8c0c0 | Teal-gray |

## License

Same as Jewelflame project.
