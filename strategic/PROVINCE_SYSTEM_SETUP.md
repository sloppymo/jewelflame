# Province Selection System Setup Guide

## Overview
This system uses a **Color ID Map** technique where each province on the map is assigned a unique RGB color on a hidden data map. This allows pixel-perfect province selection without needing hex grids or collision shapes.

## File Structure
```
strategic/
├── province_manager.gd      # Main province management script
├── PROVINCE_SYSTEM_SETUP.md # This file
└── (your map scenes)

shaders/
└── province_highlight.gdshader # Visual highlight effect

assets/maps/
├── strategic_map.png        # Visual map (what player sees)
└── data_map.png             # Hidden color-coded map
```

## Node Tree Setup

### 1. Main Scene Structure
```
MainStrategic (Node2D)
├── CanvasLayer
│   ├── GameSidebar (Control)     # Your existing sidebar
│   └── ProvinceTooltip (Control) # Optional hover tooltip
├── ProvinceManager (Node2D)      # Attach province_manager.gd
└── StrategicMap (Node2D)
    ├── VisualMap (Sprite2D)      # The pretty pixel art map
    └── HighlightOverlay (Sprite2D) # Optional: for shader effects
```

### 2. Setting Up ProvinceManager
1. Add a **Node2D** to your main scene
2. Rename it to `ProvinceManager`
3. Attach the script `res://strategic/province_manager.gd`
4. In the Inspector, assign:
   - **Visual Map**: Drag your map Sprite2D here
   - **Data Map Texture**: Load `res://assets/maps/data_map.png`
   - **Highlight Shader**: (Optional) Load the highlight shader material

### 3. Creating the Data Map

The data map is a PNG image where each province is filled with a unique solid color.

#### Step-by-Step Creation:
1. Open your visual map in your art program (Aseprite, Photoshop, GIMP)
2. Create a new layer above the map
3. Hide the visual map layer (or lower opacity)
4. For each province:
   - Use the **Paint Bucket** tool (Contiguous = OFF)
   - Fill the province with a unique RGB color
   - Suggested colors (avoid pure black/white):
     - `#FF0001` - Red (Dunmoor)
     - `#00FF02` - Green (Carveti)
     - `#0003FF` - Blue (Banshea)
     - `#FFFF04` - Yellow (Cobrige)
     - `#FF05FF` - Magenta (Petaria)
     - `#05FFFF` - Cyan
     - `#FF8000` - Orange
     - `#8000FF` - Purple
5. Delete/hide all other layers (water, borders, etc.)
6. Save as `data_map.png` in `assets/maps/`

#### Important Rules:
- **Each province = exactly one unique color**
- **No anti-aliasing** - use hard edges
- **Avoid pure black** (`#000000`) - used for empty space
- **Avoid pure white** (`#FFFFFF`) - used for background
- **Map dimensions must match** the visual map exactly

### 4. Connecting to Your Game

#### In your Main Scene script:
```gdscript
extends Node2D

@onready var province_manager: ProvinceManager = $ProvinceManager
@onready var sidebar: GameSidebar = $CanvasLayer/GameSidebar

func _ready():
    # Connect province signals
    province_manager.province_selected.connect(_on_province_selected)
    province_manager.province_hovered.connect(_on_province_hovered)
    province_manager.province_deselected.connect(_on_province_deselected)

func _process(_delta):
    # Update hover detection every frame
    province_manager.update_hover()

func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            province_manager.handle_click()

func _on_province_selected(province_id: int, data: Dictionary):
    print("Selected: ", data.name)
    sidebar.update_for_province(province_id, data)

func _on_province_hovered(province_id: int, data: Dictionary):
    # Optional: Show tooltip or preview
    pass

func _on_province_deselected():
    # Optional: Hide tooltip
    pass
```

### 5. Alternative: JSON Data Loading

Instead of hardcoding province data, create a JSON file:

**`assets/data/provinces.json`**:
```json
[
  {
    "id": 1,
    "color_hex": "#FF0001",
    "name": "Dunmoor",
    "owner_id": 1,
    "garrison": 1200,
    "defense": "High",
    "income": 450,
    "loyalty": 85,
    "castle_level": 2,
    "terrain": "plains"
  },
  {
    "id": 2,
    "color_hex": "#00FF02",
    "name": "Carveti",
    "owner_id": 2,
    "garrison": 800,
    "defense": "Medium",
    "income": 320,
    "loyalty": 70,
    "castle_level": 1,
    "terrain": "forest"
  }
]
```

Load it in your main script:
```gdscript
func _ready():
    province_manager.load_province_data_from_json("res://assets/data/provinces.json")
```

## Performance Optimization

### Why This Is Fast:
1. **Single memory read** - `Image.get_pixel()` is O(1)
2. **No collision detection** - No Area2D physics overhead
3. **Cached data** - Data map loaded once at startup
4. **Dictionary lookup** - Color→Province is O(1)

### Scaling to 50+ Provinces:
- This system handles 50-100 provinces easily
- For 200+ provinces, consider:
  - Quadtree spatial partitioning
  - Only checking pixels when mouse moves X pixels
  - Caching province boundaries

## Visual Highlighting Options

### Option 1: Shader (Recommended)
Apply the `province_highlight.gdshader` to your map sprite:
```gdscript
# When province is selected
visual_map.material.set_shader_parameter("target_color", province_color)
visual_map.material.set_shader_parameter("highlight_intensity", 1.3)
```

### Option 2: Overlay Sprite
Create a separate highlight sprite that shows province borders:
```gdscript
# Create highlight overlay
var highlight = Sprite2D.new()
highlight.texture = generate_highlight_texture(province_id)
highlight.modulate = Color(1.0, 0.843, 0.0, 0.5)  # Gold tint
add_child(highlight)
```

### Option 3: Border Outline
Draw a polygon around the province using Line2D:
```gdscript
var outline = Line2D.new()
outline.points = get_province_border_points(province_id)
outline.width = 3
outline.default_color = Color.GOLD
add_child(outline)
```

## Debugging

### Visualize Data Map In-Game:
Call this to see the color map instead of the visual map:
```gdscript
province_manager.toggle_data_map_visibility()
```

### Check Color at Mouse Position:
```gdscript
func _process(_delta):
    if Input.is_action_just_pressed("ui_accept"):  # Spacebar
        var color = province_manager._get_data_map_pixel_at_mouse()
        print("Color at mouse: ", color)
```

## Common Issues

### Issue: Clicking doesn't select province
**Solution**: Check that:
1. Data map is same size as visual map
2. Data map has no transparency on provinces
3. Colors match exactly between JSON and image
4. `visual_map` node is assigned in ProvinceManager

### Issue: Wrong province selected
**Solution**: The coordinate conversion might be wrong. Check:
1. Sprite scale factors
2. Node2D vs Sprite2D positioning
3. Camera offset if using Camera2D

### Issue: Lag when moving mouse
**Solution**: Move `update_hover()` from `_process` to `_input`:
```gdscript
func _input(event):
    if event is InputEventMouseMotion:
        province_manager.update_hover()
```

## Integration with Existing Systems

### Turn Manager Integration:
```gdscript
# In your turn manager
func can_attack(from_province: int, to_province: int) -> bool:
    var from_data = province_manager.get_province_data(from_province)
    var to_data = province_manager.get_province_data(to_province)
    
    return from_data.owner_id == current_player_id and \
           to_data.owner_id != current_player_id
```

### Save/Load System:
```gdscript
func save_game() -> Dictionary:
    return {
        "selected_province": province_manager.selected_province,
        "province_owners": province_manager.get_all_owners()
    }

func load_game(data: Dictionary) -> void:
    province_manager.selected_province = data.selected_province
    # Restore province owners, garrisons, etc.
```

## Summary

This system gives you:
- ✅ **Pixel-perfect accuracy** - Click anywhere in a province
- ✅ **No hex grid math** - Simple color lookup
- ✅ **Easy to edit** - Just paint provinces in your art tool
- ✅ **Fast performance** - O(1) lookups, no physics
- ✅ **Scalable** - Works for any number of provinces

**Next Steps**:
1. Create your `data_map.png`
2. Set up the ProvinceManager node
3. Connect signals to your sidebar
4. Test clicking provinces!
