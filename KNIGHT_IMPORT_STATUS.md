# 2-Handed Swordsman Sprite Import - Implementation Status

## ✅ Completed Files

### 1. Import Settings (Fixed)
- **File**: `assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Combat.png.import`
- **File**: `assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Non-Combat.png.import`
- **Settings**: 
  - Mipmaps: Disabled ✓
  - Compression: Lossless (mode=0) ✓
  - **NOTE**: Filter must be set to "Nearest" in Godot Editor (see manual steps below)

### 2. EditorScript - SpriteFrames Generator
- **File**: `tools/gen_knight_frames.gd`
- **Output**: `animations/knight_sprite_frames.tres`
- **Generates 47 animations**:
  - **Idle**: 8 directions (idle_s, idle_n, idle_se, idle_ne, idle_e, idle_w, idle_sw, idle_nw)
  - **Walk**: 8 directions
  - **Run**: 8 directions
  - **Death**: 7 directions (missing NW - fallback to N)
  - **Attack Light**: 8 directions (8 frames each)
  - **Attack Heavy**: 8 directions (8 frames each)
  - **Hurt**: 8 directions (8 frames each)

### 3. Knight Unit Scene
- **File**: `units/knight_unit.tscn`
- **Structure**:
  - CharacterBody2D (root)
  - CollisionShape2D (radius 12)
  - Area2D with CollisionShape2D (radius 14, for mouse input)
  - Troop_0 through Troop_4 (AnimatedSprite2D nodes with shared SpriteFrames)

### 4. Knight Unit Script
- **File**: `units/knight_unit.gd`
- **Features**:
  - 5-troop squad visualization with static formation
  - Damage scales with troop count (20 dmg at full strength)
  - White flash on damage (no health bars)
  - Cyan selection ring when clicked
  - Death fallback for missing NW direction
  - 8-directional facing system

## 🔧 Manual Steps Required in Godot Editor

### Step 1: Set Import Filter to Nearest (CRITICAL)
1. Open Godot Editor
2. In FileSystem dock, navigate to:
   - `assets/Citizens - Guards - Warriors/Warriors/`
3. Select both PNG files:
   - `2-Handed_Swordsman_Combat.png`
   - `2-Handed_Swordsman_Non-Combat.png`
4. In Import tab (next to Scene tab):
   - Change **Filter** to `Nearest`
   - Ensure **Mipmaps** is `Disabled`
   - Ensure **Compress** is `Lossless`
5. Click **Reimport** button

### Step 2: Generate SpriteFrames
1. Open Script Editor
2. Load `tools/gen_knight_frames.gd`
3. Go to **File > Run** (or press Ctrl+Shift+X)
4. Check Output console for: "SUCCESS: Generated knight_sprite_frames.tres with 47 animations"

### Step 3: Assign SpriteFrames UID (if needed)
If Godot reports missing UID for the SpriteFrames:
1. Select `animations/knight_sprite_frames.tres` in FileSystem
2. This will assign a proper UID
3. Update `knight_unit.tscn` with the new UID if necessary

## 📊 Animation Reference

### Non-Combat Sheet (64×496, 4×31 grid)
| Row Range | Animation | Directions | Frames | Speed | Loop |
|-----------|-----------|------------|--------|-------|------|
| 0-7 | idle | 8 | 4 | 6 fps | yes |
| 8-15 | walk | 8 | 4 | 10 fps | yes |
| 16-23 | run | 8 | 4 | 12 fps | yes |
| 24-30 | death | 7* | 4 | 8 fps | no |

*Missing NW direction - code falls back to N

### Combat Sheet (128×384, 8×24 grid)
| Row Range | Animation | Directions | Frames | Speed | Loop |
|-----------|-----------|------------|--------|-------|------|
| 0-7 | attack_light | 8 | 8 | 12 fps | no |
| 8-15 | attack_heavy | 8 | 8 | 10 fps | no |
| 16-23 | hurt | 8 | 8 | 8 fps | no |

### Direction Order (per 8-row group)
- Row +0: S (south, facing camera)
- Row +1: N (north, back to camera)
- Row +2: SE (southeast)
- Row +3: NE (northeast)
- Row +4: E (east, right profile)
- Row +5: W (west, left profile)
- Row +6: SW (southwest)
- Row +7: NW (northwest)

## 🎯 Formation Layout (16×16 optimized)
```
       [0]     <- Leader (front, 0, -6)
    [1]   [2]   <- Left/Right flanks (-8, 2) / (8, 2)
      [3] [4]   <- Back row (-6, 8) / (6, 8)
```

## ⚔️ Damage Calculation
| Troops | Damage |
|--------|--------|
| 5/5 | 20 |
| 4/5 | 16 |
| 3/5 | 12 |
| 2/5 | 8 |
| 1/5 | 4 |
| 0/5 | Dead |

## 🔍 Verification Checklist
- [ ] Import settings: Filter = Nearest, Mipmaps = Disabled
- [ ] SpriteFrames generated with 47 animations
- [ ] All 5 AnimatedSprite2D nodes animate in sync
- [ ] Damage scales correctly with troop count
- [ ] Static gaps maintained on troop loss
- [ ] No health bars visible (white flash on damage)
- [ ] Cyan selection ring appears on click
- [ ] Death animation falls back for missing NW direction
- [ ] Unit dies when all 5 troops lost
