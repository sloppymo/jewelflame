# Hex Sprite Generation Workflow for HexForge

## Overview

This workflow generates Gemfire-style medieval hex terrain sprites using AI tools like PixelBox, then integrates them into your Godot project.

## Specifications

| Property | Value |
|----------|-------|
| Hex Orientation | Pointy-top |
| Hex Width | 64 pixels (flat-to-flat) |
| Hex Height | 74 pixels (point-to-point) |
| Style | Gemfire SNES medieval tactical |
| Palette | Muted earth tones, desaturated greens, warm grays |

## Terrain Types

| Terrain | Variants | Animation | Notes |
|---------|----------|-----------|-------|
| Plains | 3 | No | Base grassland with grass tuft variations |
| Forest | 2 | No | Tree clusters, varying density |
| Mountain | 2 | No | Rocky peaks + foothill variants |
| Water | 1 | 4-frame | Gentle ripples, looping |
| Road | 1 | No | Dirt path with wagon ruts |
| Marsh | 2 | No | Reeds, standing water, boggy |

## Quick Start

### Step 1: Generate Templates

Run the demo in Godot:

```gdscript
# Add this to any scene
var demo = preload("res://src/hexforge/tools/hex_sprite_generator_demo.gd").new()
add_child(demo)
```

This creates three files in `user://`:
- `hex_template_sheet.png` — Colored layout guide
- `hex_mask_sheet.png` — Black/white mask for ControlNet
- `hex_prompt_guide.txt` — AI prompts for each terrain

### Step 2: Generate AI Art

#### Option A: PixelBox (Free, Fast)

1. Go to https://llamagen.ai (PixelBox)
2. For each terrain, use these prompts:

```
plains: "grassland plains pixel art, 64x64, green grass, medieval, muted tones"
forest: "forest pixel art, 64x64, trees, dark green, medieval, hand-painted"
mountain: "mountain pixel art, 64x64, rocky, gray brown, medieval"
water: "water pixel art, 64x64, river, blue green, ripples, calm"
road: "dirt road pixel art, 64x64, brown path, wagon tracks"
marsh: "marsh swamp pixel art, 64x64, reeds, dark olive, bog"
```

3. Download each as PNG
4. Use the mask sheet to crop to hex shape in GIMP/Photoshop

#### Option B: Stable Diffusion + ControlNet

1. Load `hex_mask_sheet.png` into ControlNet
2. Use model: `control_v11p_sd15_canny` or `control_v11p_sd15_depth`
3. Base prompt:

```
isometric hexagonal terrain tile, top-down view, pointy-top orientation,
64x74 pixels, Gemfire SNES medieval style, muted earth tones,
hand-painted look, game sprite, single tile, no background
```

4. Add terrain-specific details from prompt guide
5. Generate full sheet at once, or individual tiles

#### Option C: Midjourney

```
[upload hex_template_sheet.png]
isometric hex terrain tilesheet, 4x3 grid layout, Gemfire SNES medieval 
strategy game style, hand-painted pixel art, muted earth tones, 
grassland forest mountain water --ar 4:3 --v 6
```

### Step 3: Post-Process

1. Open your AI-generated image
2. Resize to match template exactly (check prompt guide for dimensions)
3. Ensure hexes align with template positions
4. Remove any borders AI added
5. Save as `hex_completed_sheet.png`

### Step 4: Extract Tiles

Back in Godot:

```gdscript
# Extract individual tiles
HexSpriteGenerator.extract_hex_from_sheet("user://hex_completed_sheet.png")

# Creates in user://hex_tiles/:
# - plains.png
# - plains_v1.png
# - plains_v2.png
# - forest.png
# - ... etc
```

### Step 5: Create Godot Atlas

```gdscript
# Load all textures
var textures = HexSpriteGenerator.create_texture_atlas("user://hex_tiles/")

# Or create AtlasTexture manually in Godot editor
# 1. Import all PNGs
# 2. Create AtlasTexture resource
# 3. Add regions for each terrain
```

## Integration with HexRenderer2D

Modify your renderer to use textures instead of procedural drawing:

```gdscript
# In hex_renderer_2d.gd

@export var use_textures: bool = false
@export var texture_atlas: AtlasTexture

var terrain_regions: Dictionary = {
    "plains": Rect2(0, 0, 64, 74),
    "forest": Rect2(64, 0, 64, 74),
    # ... etc
}

func _draw_cell(cell: HexCell) -> void:
    if use_textures and texture_atlas:
        _draw_textured_cell(cell)
    else:
        _draw_procedural_cell(cell)

func _draw_textured_cell(cell: HexCell) -> void:
    var world_pos := _get_cached_world_position(cell.cube_coord)
    var region: Rect2 = terrain_regions.get(cell.terrain_type, terrain_regions["plains"])
    
    texture_atlas.region = region
    draw_texture(texture_atlas, world_pos - Vector2(32, 37))
```

## Gemfire Style Reference

### Color Palette

| Element | Primary | Shadow | Highlight |
|---------|---------|--------|-----------|
| Plains | #7A9B5A | #5A7B3A | #9ABB7A |
| Forest | #4A6B3A | #2A4B1A | #6A8B5A |
| Mountain | #8B7D6B | #6B5D4B | #AB9D8B |
| Water | #5A8BAB | #3A6B8B | #7AABCB |
| Road | #A69B7A | #867B5A | #C6BB9A |
| Marsh | #6A7B4A | #4A5B2A | #8A9B6A |

### Visual Rules

1. **Muted tones** — No saturated colors, everything slightly desaturated
2. **Hand-painted look** — Subtle brush stroke texture, not pixel-perfect
3. **Readable at small size** — Clear silhouettes, distinct terrain types
4. **Consistent lighting** — Top-left light source across all tiles
5. **No hard black outlines** — Use dark shades of the base color instead

## Animation Setup

For water animation, create an AnimatedSprite2D or use shader:

```gdscript
# Simple 4-frame animation
var water_frames: Array[Texture2D] = [
    load("res://hex_tiles/water_f1.png"),
    load("res://hex_tiles/water_f2.png"),
    load("res://hex_tiles/water_f3.png"),
    load("res://hex_tiles/water_f4.png"),
]

# In _draw(), cycle based on time
var frame := int(Time.get_time_dict_from_system()["second"] / 4) % 4
draw_texture(water_frames[frame], position)
```

## File Structure

```
jewelflame/
├── assets/
│   └── hex_tiles/
│       ├── plains.png
│       ├── plains_v1.png
│       ├── plains_v2.png
│       ├── forest.png
│       ├── forest_v1.png
│       ├── mountain.png
│       ├── mountain_v1.png
│       ├── water_f1.png
│       ├── water_f2.png
│       ├── water_f3.png
│       ├── water_f4.png
│       ├── road.png
│       ├── marsh.png
│       └── marsh_v1.png
├── src/
│   └── hexforge/
│       ├── tools/
│       │   ├── hex_sprite_generator.gd
│       │   └── hex_sprite_generator_demo.gd
│       └── rendering/
│           └── hex_renderer_2d.gd
└── docs/
    └── HEX_SPRITE_WORKFLOW.md (this file)
```

## Troubleshooting

**AI generates borders around hexes?**
- Use the mask sheet as an alpha channel
- Or prompt: "no border, no outline, seamless edges"

**Colors too saturated?**
- Add "muted earth tones, desaturated" to prompt
- Post-process: reduce saturation by 20-30%

**Hexes don't align in sheet?**
- Ensure exact dimensions from template
- Use GIMP/Photoshop grid snap to 64×74

**Water animation too jerky?**
- Add intermediate frames (6-8 total)
- Or use shader-based animation instead of frame swap

## Next Steps

1. Generate templates (run demo)
2. Create 3-4 sample terrains in PixelBox
3. Test integration with HexRenderer2D
4. Iterate on style
5. Generate full set
6. Add elevation cliff sprites (south-facing edges)
