# Godot Sprite Sheet Reference for Jewelflame

Quick reference guide for preparing and importing sprite sheets into Godot 4.x.

---

## Quick Checklist

### Before Exporting from Aseprite/LibreSprite
- [ ] All frames are the **same size** (16×16, 32×32, 64×64, or 128×128)
- [ ] **Merge Duplicates** is enabled
- [ ] **Border Padding**: 1-2 pixels
- [ ] **Spacing**: 1-2 pixels between frames
- [ ] **Sheet Type**: By Rows

### Godot Import Settings
- [ ] Filter: **Nearest**
- [ ] Mipmaps: **Disabled**
- [ ] Repeat: **Disabled**
- [ ] Compress: **Lossless**

### Code Setup
- [ ] `texture_filter = TEXTURE_FILTER_NEAREST` on sprite nodes
- [ ] `filter_clip = true` on AtlasTexture when using sprite sheets
- [ ] Integer scaling only (1×, 2×, 3× — never 1.5×)

---

## Frame Size Standards

| Size | Use Case |
|------|----------|
| 16×16 | Tiny characters, icons, bullets |
| 32×32 | Small characters, items |
| 64×64 | Standard characters, enemies |
| 128×128 | Large characters, bosses |

**Rule**: Powers of 2 are GPU-friendly. Stick to these sizes.

---

## Sprite Sheet Layout

```
Row 0: [Frame 0] [Frame 1] [Frame 2] [Frame 3]   ← Walk_South
Row 1: [Frame 0] [Frame 1] [Frame 2] [Frame 3]   ← Walk_North
Row 2: [Frame 0] [Frame 1] [Frame 2] [Frame 3]   ← Walk_East
Row 3: [Frame 0] [Frame 1] [Frame 2] [Frame 3]   ← Walk_West
```

**⚠ WARNING: Direction row order varies by artist/pack. Always measure — never assume.**

The generic mapping below is one common convention. Jewelflame's actual sheets
use a different order confirmed by pixel analysis. See JEWELFLAME CONFIRMED below.

### GENERIC REFERENCE (common convention — may differ per asset pack):
```gdscript
const DIRECTION_ROWS_GENERIC = {
    "s": 0, "n": 1, "e": 2, "w": 3,
    "se": 4, "sw": 5, "ne": 6, "nw": 7
}
```

### JEWELFLAME CONFIRMED (pixel mass analysis — use this for Jewelflame sheets):
```gdscript
const DIRECTION_ROWS_JEWELFLAME = {
    "s": 0, "n": 1, "se": 2, "ne": 3,
    "e": 4, "w": 5, "sw": 6, "nw": 7
}
```

---

## Runtime SpriteFrames Generation

Use this when dynamically building animations from sprite sheets:

```gdscript
func build_sprite_frames(sprite_sheet_path: String, frame_size: Vector2i) -> SpriteFrames:
    var sf = SpriteFrames.new()
    var atlas = load(sprite_sheet_path)
    
    for direction in ["s", "n", "e", "w", "se", "sw", "ne", "nw"]:
        var anim_name = "walk_" + direction
        sf.add_animation(anim_name)
        sf.set_animation_speed(anim_name, 10)
        sf.set_animation_loop(anim_name, true)
        
        # Add 4 frames per direction
        for frame in range(4):
            var tex = AtlasTexture.new()
            tex.atlas = atlas
            tex.region = Rect2(
                frame * frame_size.x,                    # Column
                DIRECTION_ROWS[direction] * frame_size.y, # Row
                frame_size.x,
                frame_size.y
            )
            tex.filter_clip = true  # Prevents one-pixel bleed between adjacent frames
            sf.add_frame(anim_name, tex)
    
    return sf
```

**Usage**:
```gdscript
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
    animated_sprite.sprite_frames = build_sprite_frames(
        "res://sprites/knight.png",
        Vector2i(64, 64)
    )
    animated_sprite.play("walk_s")
```

---

## Animation Speed Guidelines

| Animation Type | FPS Range | Notes |
|----------------|-----------|-------|
| Idle | 8-12 | Subtle breathing |
| Walk | 10-12 | Retro feel |
| Run | 12-16 | Faster movement |
| Attack | 12-24 | Faster = more responsive |
| Effects | 24-60 | Smooth particles/spells |

---

## Common Issues & Fixes

| Problem | Cause | Solution |
|---------|-------|----------|
| Ghost pixels at edges | Frame bleeding | Add 1-2px padding; enable `filter_clip` |
| Blurry sprites | Wrong filter | Set Filter to **Nearest** in import settings |
| Flickering lines | No padding + scaling | Add padding; use integer scaling only |
| Stutter on first spawn | Runtime generation | Pre-build in loading screen or use .tres |
| Animation misaligned | Uneven frame sizes | Re-export with consistent frame sizes |

---

## Project Settings (One-Time Setup)

```
Project Settings → Rendering → Textures:
├── Default Texture Filter: Nearest
├── Canvas Textures → Default Texture Filter: Nearest
└── Lossless Compression → Force PNG: ON
```

```
Project Settings → Rendering → 2D:
└── GPU Pixel Snap: ON (prevents sub-pixel jitter)
```

---

## Recommended Animation Setup

For characters with hitboxes (combat):

```
Player (CharacterBody2D)
├── AnimatedSprite2D        # Sprite animation only
│   └── texture_filter = TEXTURE_FILTER_NEAREST
├── AnimationPlayer         # Coordinates hitboxes, sounds, effects
│   └── Attack: enables hitbox at frame 3
└── Hitbox (CollisionShape2D)  # Toggled by AnimationPlayer
```

---

## Tools

| Tool | Purpose | Cost |
|------|---------|------|
| Aseprite | Pixel art + animation | $20 |
| LibreSprite | Free Aseprite alternative | Free |
| Piskel | Browser-based, quick work | Free |
| TexturePacker | Advanced sheet packing | Paid |
| ShoeBox | Free sheet extractor | Free |

---

## Quick Reference: Export Settings

### Aseprite Export (File → Export Sprite Sheet)

| Setting | Value |
|---------|-------|
| Layout | By Rows |
| Border Padding | 2px |
| Shape Padding | 2px |
| Merge Duplicates | ✓ |
| Output File | .png |

---

## Code Snippets Library

### Fallback Animation Handler
```gdscript
func get_animation_name(base: String, direction: String) -> String:
    var full = base + "_" + direction
    if sprite_frames.has_animation(full):
        return full
    
    # Fallbacks for diagonal directions
    if direction == "nw" and not sprite_frames.has_animation(full):
        return base + "_n"
    if direction == "ne" and not sprite_frames.has_animation(full):
        return base + "_n"
    if direction == "sw" and not sprite_frames.has_animation(full):
        return base + "_s"
    if direction == "se" and not sprite_frames.has_animation(full):
        return base + "_s"
    
    return base + "_s"  # Default to south
```

### Preload SpriteFrames (.tres approach)
```gdscript
# Faster than runtime generation
@onready var sprite_frames = preload("res://animations/player_animations.tres")

func _ready():
    animated_sprite.sprite_frames = sprite_frames
```

---

## Jewelflame Confirmed Sheet Specs

| Sheet | Frame | Grid | Notes |
|-------|-------|------|-------|
| Sword_and_Shield_Fighter_Non-Combat.png | 16×16 | 4×31 | 8-dir, 3 walk groups + death |
| Sword_and_Shield_Fighter_Combat.png | 32×32 | 4×20 | 4-dir, 5 animation groups |
| Archer_Non-Combat.png | 16×16 | 4×31 | Same structure as S&S non-combat |
| Archer_Combat.png | 32×32 | 4×8 | 4 shoot + 2 hurt + 2 death dirs |

**Archer combat mirror rows (mathematically confirmed):**
Row 01 = Row 00 flipped horizontally (shoot_w = shoot_e mirrored)
Row 05 = Row 04 flipped horizontally (hurt_w = hurt_e mirrored)

**Corpse frame signature:**
Row 28 in both non-combat sheets has pixel diff = 3.3–4.2 (near-static).
This is the corpse hold frame. Use 2fps, no loop.

**All frame sizes confirmed by Python pixel analysis — not guessed.**
