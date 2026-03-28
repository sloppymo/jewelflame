# Main Menu Setup Guide

## Option 1: Create Main Menu Scene (Recommended)

Create `scenes/main_menu.tscn`:

1. **Root Node:** Control (or Node2D)
   - Full Rect size
   - ColorRect or TextureRect for background

2. **UI Layout:**

```
MainMenu (Control)
├── Background (ColorRect or TextureRect)
└── VBoxContainer (centered)
    ├── TitleLabel ("JEWELFLAME")
    ├── ContinueButton (Button)
    ├── NewGameButton (Button)
    ├── OptionsButton (Button)
    └── QuitButton (Button)
```

3. **Script:** Attach `res://src/ui/main_menu.gd`

4. **Button Names (must match script):**
   - `ContinueButton`
   - `NewGameButton`
   - `OptionsButton`
   - `QuitButton`

5. **Project Settings:**
   - Change `run/main_scene` to `res://scenes/main_menu.tscn`

## Option 2: Quick Test (Skip Main Menu)

For testing without main menu:

1. Keep `run/main_scene` as `res://scenes/strategic_map.tscn`
2. Game auto-initializes on run
3. Use manual save/load via debug (see below)

## Save/Load Controls

**Auto-save triggers:**
- After every battle
- After every turn end

**Manual save:** Add to strategic map UI
```gdscript
# In strategic_controller.gd, add to _ready:
var save_button = Button.new()
save_button.text = "Save"
save_button.pressed.connect(func(): SaveManager.save_game())
ui.add_child(save_button)
```

**Keyboard shortcut:** Add to project.godot input
```
[input]
save_game={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194336,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
```

Then in strategic_controller.gd:
```gdscript
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("save_game"):
        SaveManager.save_game()
```

## Save File Location

Save files are stored in:
- **Windows:** `%APPDATA%/Godot/app_userdata/Jewelflame/`
- **macOS:** `~/Library/Application Support/Godot/app_userdata/Jewelflame/`
- **Linux:** `~/.local/share/godot/app_userdata/Jewelflame/`

File: `jewelflame_save.json`
