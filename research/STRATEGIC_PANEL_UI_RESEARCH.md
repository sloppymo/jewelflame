# Strategic Panel UI Research: Godot 4 Implementation Patterns

**Research Date:** March 11, 2026  
**Scope:** Strategic/info panels in turn-based strategy games  
**Sources:** Godot documentation, tutorials, devlogs, community discussions

---

## Executive Summary

Based on research of Godot strategy game implementations, successful strategic panels follow consistent patterns:

1. **NinePatchRect for scalable frames** - The industry standard for pixel-art UI panels
2. **Container-based layouts** - HBox/VBox/Grid containers for responsive positioning
3. **Hierarchical structure** - Nested containers for complex panel arrangements
4. **State-driven updates** - Signals from game state to UI components
5. **Fallback textures** - Always provide default textures for dynamic content

---

## 1. Core UI Components for Strategy Panels

### 1.1 NinePatchRect: The Foundation

**Purpose:** Creates scalable UI frames that preserve pixel-art corners while stretching the middle.

**How it works:**
- Define 9 regions: 4 corners (fixed), 4 edges (stretch/tile), 1 center (stretch/tile)
- Set `patch_margin_*` properties to define corner sizes
- Supports both stretching and tiling for middle sections

**Implementation:**
```gdscript
# NinePatchRect configuration for panel frame
@onready var panel_frame: NinePatchRect = $PanelFrame

func _ready():
    panel_frame.texture = preload("res://assets/ui/panel_frame.png")
    panel_frame.patch_margin_left = 8
    panel_frame.patch_margin_right = 8
    panel_frame.patch_margin_top = 8
    panel_frame.patch_margin_bottom = 8
    
    # Use tiling for smoother scaling
    panel_frame.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_TILE
    panel_frame.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_TILE
```

**Source:** *The Power of Nine-Patching in Godot* (Medium, 2025)

### 1.2 Container Hierarchy Pattern

**Standard Structure:**
```
StrategicPanel (Control or MarginContainer)
├── Background (NinePatchRect) - Scalable frame
├── ContentContainer (VBoxContainer) - Vertical layout
│   ├── HeaderSection (HBoxContainer)
│   │   ├── PortraitFrame (NinePatchRect)
│   │   │   └── Portrait (TextureRect)
│   │   └── InfoColumn (VBoxContainer)
│   │       ├── NameLabel (Label)
│   │       └── FactionLabel (Label)
│   ├── ResourceGrid (GridContainer, 2 columns)
│   │   └── ResourceSlot (HBox) x N
│   ├── UnitRow (HBoxContainer)
│   └── DialogueSection (VBox)
└── CloseButton (TextureButton) - Optional
```

**Key Principles:**
- Use `MarginContainer` at root for consistent padding
- Nest `HBoxContainer` and `VBoxContainer` for 1D layouts
- Use `GridContainer` for 2D resource arrays
- Set `size_flags` for flexible sizing

**Source:** *Control Node Fundamentals and Layout Containers* (Uhiyama Lab, 2025)

---

## 2. Portrait Display Patterns

### 2.1 TextureRect with Fallback

**Problem:** Dynamic portraits may fail to load or be missing.

**Solution:** Always implement fallback chain:

```gdscript
@onready var portrait: TextureRect = $PortraitFrame/Portrait

var fallback_textures: Dictionary = {
    "blanche": preload("res://assets/portraits/house_blanche/lord_blanche.png"),
    "lyle": preload("res://assets/portraits/house_lyle/lord_lyle.png"),
    "coryll": preload("res://assets/portraits/house_coryll/lord_coryll.png")
}

func set_character(character_id: String, faction: String):
    var portrait_path = "res://assets/portraits/%s/%s.png" % [faction, character_id]
    
    if ResourceLoader.exists(portrait_path):
        portrait.texture = load(portrait_path)
    elif fallback_textures.has(faction):
        portrait.texture = fallback_textures[faction]
    else:
        portrait.texture = preload("res://assets/ui/placeholder_portrait.png")
    
    # Critical for pixel art
    portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
```

**Source:** *Building a head-up display in Godot* (Cyberglads, 2023)

### 2.2 Portrait Frame Styling

**Visual Enhancement:** Use NinePatchRect for decorative frame:

```
PortraitFrame (NinePatchRect)
├── Portrait (TextureRect)
│   - stretch_mode: KEEP_ASPECT_CENTERED
│   - size: 96x144 (or your target aspect)
└── ClassIcon (TextureRect)
    - position: bottom-right corner
    - size: 24x24
```

**Configuration:**
```gdscript
portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
```

---

## 3. Resource Display Patterns

### 3.1 Grid Layout for Resources

**Standard Grid:** 2-column layout for resource pairs:

```gdscript
# Resource grid setup
@onready var resource_grid: GridContainer = $ResourceGrid

func _ready():
    resource_grid.columns = 2
    resource_grid.add_theme_constant_override("h_separation", 16)
    resource_grid.add_theme_constant_override("v_separation", 8)

func create_resource_slot(icon: Texture, value: int) -> HBoxContainer:
    var slot = HBoxContainer.new()
    
    var icon_rect = TextureRect.new()
    icon_rect.texture = icon
    icon_rect.custom_minimum_size = Vector2(32, 32)
    icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    
    var value_label = Label.new()
    value_label.text = str(value)
    value_label.add_theme_font_size_override("font_size", 18)
    
    slot.add_child(icon_rect)
    slot.add_child(value_label)
    
    return slot
```

### 3.2 Resource Update Strategy

**Signal-Driven Updates:**
```gdscript
# Connect to GameState signals
func _ready():
    GameState.resources_changed.connect(_on_resources_changed)

func _on_resources_changed(gold: int, food: int, troops: int):
    _update_resource_display("gold", gold)
    _update_resource_display("food", food)
    _update_resource_display("troops", troops)

func _update_resource_display(type: String, value: int):
    if resource_labels.has(type):
        resource_labels[type].text = str(value)
```

**Source:** *Godot Tactics RPG – Ability Menu* (The Liquid Fire, 2024)

---

## 4. Responsive Layout Techniques

### 4.1 Size Flags for Flexible Layouts

**Container Sizing:**
```gdscript
# Fill available space
panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

# Shrink to content
content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

# Fixed ratio
portrait.size_flags_stretch_ratio = 0.3  # 30% of available space
```

**Source:** *Making Responsive UI in Godot* (Kodeco, 2024)

### 4.2 Anchor-Based Positioning

**For Fixed Panels:**
```gdscript
# Left panel that stays on left regardless of resolution
anchors_preset = Control.PRESET_CENTER_LEFT
anchor_left = 0.0
anchor_right = 0.0
offset_left = 16
offset_right = 256  # Fixed width
```

**For Full-Screen Overlays:**
```gdscript
anchors_preset = Control.PRESET_FULL_RECT
anchor_left = 0.0
anchor_right = 1.0
anchor_top = 0.0
anchor_bottom = 1.0
```

### 4.3 Minimum Sizes

**Prevent Collapse:**
```gdscript
# Set minimum sizes to prevent UI squishing
custom_minimum_size = Vector2(240, 400)
portrait.custom_minimum_size = Vector2(96, 144)
resource_grid.custom_minimum_size = Vector2(200, 120)
```

---

## 5. Strategic Panel Architecture

### 5.1 MVC-Inspired Pattern

**Separation of Concerns:**

```gdscript
# Model: GameState (already exists)
# - Stores current province, faction, resources

# View: StrategicPanel
# - Displays data, handles visual updates
# - No game logic

# Controller: StrategicLayer or signals
# - Handles input
# - Updates GameState

class_name StrategicPanel
extends MarginContainer

@onready var game_state = get_node("/root/GameState")

func _ready():
    # Subscribe to data changes
    game_state.province_selected.connect(_on_province_selected)
    game_state.turn_changed.connect(_on_turn_changed)

func _on_province_selected(province_data: ProvinceData):
    _update_portrait(province_data.lord)
    _update_resources(province_data.resources)
    _update_faction(province_data.faction)
```

### 5.2 Panel State Management

**Visibility Toggle:**
```gdscript
func show_panel():
    visible = true
    # Optional: animate in
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.2)
    tween.tween_property(self, "position:x", target_x, 0.2)

func hide_panel():
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.2)
    await tween.finished
    visible = false
```

---

## 6. Common Patterns from Strategy Games

### 6.1 Gemfire-Style Panel

**Layout Reference:**
```
┌─────────────────────┐ ← NinePatchRect frame (gold/decorative)
│ ┌───┐ FACTION       │ ← Banner + name header
│ │ ⚔ │ Province      │
│ └───┘               │
│ ┌───────────┐       │ ← Portrait area (larger)
│ │           │       │
│ │  PORTRAIT │       │
│ │           │       │
│ └───────────┘       │
│ Name        [icon]  │
├─────────────────────┤
│ [💰] 1000 [🍞] 500  │ ← Resource grid (2x3)
│ [⚔️] 100  [🏰] 5    │
│ [👥] 50   [⭐] 10   │
├─────────────────────┤
│ [Unit1][Unit2]...   │ ← Unit type buttons
├─────────────────────┤
│ "Dialogue text..."  │ ← Dialogue/orders
└─────────────────────┘
```

### 6.2 Panel Transitions

**Slide-in Animation:**
```gdscript
func _animate_panel_entry():
    var start_pos = Vector2(-size.x, position.y)
    var end_pos = Vector2(0, position.y)
    
    position = start_pos
    
    var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(self, "position", end_pos, 0.3)
```

---

## 7. Performance Considerations

### 7.1 Texture Management

**Best Practices:**
- Preload UI textures at startup
- Use TextureAtlases for icon sets
- Implement texture caching for portraits

```gdscript
# Texture cache for portraits
var _portrait_cache: Dictionary = {}

func get_portrait(path: String) -> Texture2D:
    if not _portrait_cache.has(path):
        if ResourceLoader.exists(path):
            _portrait_cache[path] = load(path)
        else:
            return fallback_texture
    return _portrait_cache[path]
```

### 7.2 Layout Updates

**Minimize Re-layouts:**
- Batch updates using `set_deferred()`
- Disconnect signals during bulk updates
- Use `queue_sort()` on containers

```gdscript
func update_all_resources(resources: Dictionary):
    # Prevent layout thrashing
    resource_grid.visible = false
    
    for type in resources:
        _update_resource_label(type, resources[type])
    
    resource_grid.visible = true
    resource_grid.queue_sort()
```

---

## 8. Implementation Checklist

### UI Structure
- [ ] Root MarginContainer with proper margins (16px typical)
- [ ] NinePatchRect background with 8px patch margins
- [ ] VBoxContainer for vertical content flow
- [ ] HBoxContainers for horizontal sections
- [ ] GridContainer (2 columns) for resources

### Portrait Section
- [ ] PortraitFrame (NinePatchRect) with decorative border
- [ ] Portrait (TextureRect) with KEEP_ASPECT_CENTERED
- [ ] Fallback texture loading chain
- [ ] TEXTURE_FILTER_NEAREST for pixel art

### Resource Section
- [ ] Icon + Label pairs in HBoxContainers
- [ ] Consistent icon size (32x32 typical)
- [ ] Proper spacing (h_separation, v_separation)

### Signals
- [ ] province_selected → update display
- [ ] turn_changed → update faction highlight
- [ ] resources_changed → update resource labels

### Fallbacks
- [ ] Missing portrait → faction default
- [ ] Missing faction default → placeholder
- [ ] Missing textures logged for debugging

---

## 9. Common Pitfalls

### Issue: "UI stretches weirdly at different resolutions"
**Fix:** Use containers with size_flags instead of fixed pixel positions

### Issue: "Portrait looks blurry"
**Fix:** Set `texture_filter = TEXTURE_FILTER_NEAREST`

### Issue: "Resource values don't update"
**Fix:** Connect to GameState signals, don't poll in _process()

### Issue: "Panel too big/small on different screens"
**Fix:** Use anchors_preset with offsets, not fixed sizes

### Issue: "NinePatchRect corners stretch"
**Fix:** Verify patch_margin_* values match your texture's corner size

---

## 10. Research Sources

1. **"The Power of Nine-Patching in Godot"** - Mina Pêcheux, Medium (2025)
2. **"Godot Tactics RPG – Ability Menu"** - The Liquid Fire (2024)
3. **"Building a head-up display in Godot"** - Cyberglads (2023)
4. **"Programming a tactical strategy game in Godot 4"** - Shaggy Dev (2024)
5. **"Making Responsive UI in Godot"** - Kodeco (2024)
6. **"Control Node Fundamentals"** - Uhiyama Lab (2025)
7. **Godot Official Documentation** - UI tutorials (stable branch)
8. **Reddit r/godot** - Community patterns for strategy UI

---

**Key Takeaway:** Successful strategy panels combine NinePatchRect frames with nested container layouts, use signal-driven updates from a central game state, and always provide fallback textures for dynamic content like portraits.
