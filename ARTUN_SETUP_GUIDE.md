# Artun Character Setup Guide

## Files Created
- `scenes/characters/Artun.tscn` - Character scene
- `scenes/characters/Artun.gd` - Movement script
- `scenes/characters/Artun_SpriteFrames.tres` - SpriteFrames resource (needs editing in Godot)

## Sprite Sheet Info
- **File**: `assets/Old Town - Citizens v0.1/Masc. Citizens/Artun/Artun.png`
- **Dimensions**: 64×496 pixels
- **Grid Size**: 16×16 pixels per frame
- **Layout**: 4 columns (directions) × 31 rows (animations)

## Setup Steps in Godot

### 1. Import Settings (CRITICAL)
1. In Godot's **FileSystem** dock, find:
   `res://assets/Old Town - Citizens v0.1/Masc. Citizens/Artun/Artun.png`

2. Click the PNG file → Go to **Import** tab (next to Scene tab)

3. Change these settings:
   - **Filter**: Change from "Linear" to **"Nearest"**
   - **Mipmaps → Generate**: **UNCHECK** this box
   - **Texture Format**: Keep as "VRAM Compressed"

4. Click **"Reimport"** button

### 2. Edit SpriteFrames Resource

1. Open `scenes/characters/Artun_SpriteFrames.tres`
   - Double-click in FileSystem dock
   - This opens the SpriteFrames editor at bottom

2. Click **"Add Frames from Sprite Sheet"** button

3. Select the Artun.png file

4. In the Sprite Sheet dialog:
   - **Vertical**: Check "ON"
   - **Horizontal**: Check "ON"
   - **Size**: Set to **16×16** pixels
   - You should see grid lines appear over the sprite

5. Click **"Select All Frames"** then **"Add Frames"**

### 3. Create Walk Animations

Based on typical RPG Maker-style sheets, frame layout is:
- **Row 0-3**: Idle animations (4 directions)
- **Row 4-7**: Walk animations (4 directions, 4 frames each)
- **Row 8+**: Combat, death, etc.

Create these animations:

#### walk_down
- Frames: Row 4, columns 0-3 (frames 16, 17, 18, 19)
- Speed: 8 FPS
- Loop: ON

#### walk_left  
- Frames: Row 5, columns 0-3 (frames 20, 21, 22, 23)
- Speed: 8 FPS
- Loop: ON

#### walk_right
- Frames: Row 6, columns 0-3 (frames 24, 25, 26, 27)
- Speed: 8 FPS
- Loop: ON

#### walk_up
- Frames: Row 7, columns 0-3 (frames 28, 29, 30, 31)
- Speed: 8 FPS
- Loop: ON

### 4. Assign SpriteFrames to Character

1. Open `scenes/characters/Artun.tscn`

2. Select the "Artun" node (AnimatedSprite2D)

3. In Inspector:
   - **Sprite Frames**: Drag `Artun_SpriteFrames.tres` here
   - **Animation**: Type "walk_down" (or your first animation name)
   - **Playing**: Check this to test

### 5. Test the Scene

1. Press **F6** to run the scene
2. Artun should be walking in place
3. Use **Arrow Keys** to move around

## Frame Reference (Estimated)

| Row | Animation | Frames |
|-----|-----------|--------|
| 0 | idle_down | 0-3 |
| 1 | idle_left | 4-7 |
| 2 | idle_right | 8-11 |
| 3 | idle_up | 12-15 |
| 4 | walk_down | 16-19 |
| 5 | walk_left | 20-23 |
| 6 | walk_right | 24-27 |
| 7 | walk_up | 28-31 |

Total: 31 rows × 4 frames = 124 frames

## Troubleshooting

### Animation not playing?
- Check SpriteFrames is assigned to AnimatedSprite2D
- Verify animation name matches exactly (case-sensitive)
- Check "Playing" checkbox in Inspector

### Sprite looks blurry?
- Reimport with **Filter: Nearest**
- Make sure mipmaps are disabled

### Frames cut off/wrong?
- Grid size might be wrong - try 16×16, 24×24, or 32×32
- Check import settings - ensure texture isn't being resized

### Character moves but animation stuck?
- Check animation names match in script (walk_down, walk_left, etc.)
- Verify frame indices are correct in SpriteFrames editor
