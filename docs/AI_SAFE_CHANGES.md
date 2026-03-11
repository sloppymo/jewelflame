# AI Safe Changes Guide

## Files You Can Modify Freely

| File | What You Can Change |
|------|---------------------|
| `ui/strategic_menu_panel.gd` | Visuals, colors, fonts, textures (not signal connections) |
| `strategic/ai/ai_personality.gd` | Weight values, personality modifiers |
| `battle/battle_resolver.gd` | Numbers/formulas (keep function signatures) |

## Constants You Can Tune

```gdscript
# Panel dimensions (keep fixed for layout)
PANEL_WIDTH = 280
PORTRAIT_SIZE = 88

# Visual sizes
STAT_ICON_SIZE = 24
BUTTON_SIZE = 56

# Font sizes
header_font_size = 16
subheader_font_size = 14
stats_font_size = 18
prompt_font_size = 12

# Colors
COLOR_BACKGROUND = Color("#4a3f6a")  # Panel background
COLOR_GOLD = Color("#f4d77a")        # Decorative gold
COLOR_DARK_GOLD = Color("#b89627")
COLOR_LIGHT_GOLD = Color("#fff7aa")
```

## Functions That Generate Textures

Replace these with actual art later by loading external textures:

| Function | Purpose | Replace With |
|----------|---------|--------------|
| `_create_coin_icon()` | Gold stat icon | `res://assets/ui/icon_gold.png` |
| `_create_flag_icon()` | Loyalty stat icon | `res://assets/ui/icon_loyalty.png` |
| `_create_wheat_icon()` | Food stat icon | `res://assets/ui/icon_food.png` |
| `_create_swords_icon()` | Soldiers stat icon | `res://assets/ui/icon_swords.png` |
| `_create_helmet_icon()` | Army stat icon | `res://assets/ui/icon_helmet.png` |
| `_create_castle_icon()` | Protection stat icon | `res://assets/ui/icon_castle.png` |

## Debug Mode

Enable debug logging by setting the export variable in the Inspector:

```gdscript
@export_group("Debug")
@export var debug_mode: bool = true  # Enable verbose logging
```

When enabled, you'll see:
- Province selection details
- Portrait loading status
- Scene tree validation

## Common Gotchas

1. **Always check `ResourceLoader.exists()` before loading**
   ```gdscript
   if ResourceLoader.exists(path):
       var tex = load(path) as Texture2D
   ```

2. **Use `TEXTURE_FILTER_NEAREST` for pixel art**
   ```gdscript
   texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
   ```

3. **Portrait discovery scans folders; don't rely on portrait_path field**
   - System scans `res://assets/portraits/house_{family_id}/`
   - Falls back to silhouette if no portrait found

4. **Node exports must be assigned in the scene file**
   - If you see "Missing required export" errors, check the .tscn file
   - The `node_paths` array maps exports to actual node paths

## Signal Safety

These signals are connected in `_ready()` and disconnected in `_exit_tree()`:
- `EventBus.ProvinceSelected` → `_on_province_selected`
- `EventBus.FamilyTurnStarted` → `_on_turn_started`

**Don't change these connections** without also updating `_cleanup_signals()`.

## Type Safety

All functions now have complete type hints:

```gdscript
func _update_stat(slot: int, value: int) -> void:
func _get_portrait_for_lord(lord_id: String, family_id: String) -> String:
func _create_button_texture(icon_drawer: Callable, pressed: bool) -> ImageTexture:
```

Keep these signatures when making modifications.
