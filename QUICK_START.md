# Jewel Flame - Quick Start for New LLM

## 🎯 Current Priority: Fix Knight Attack Animations

### The Problem
Knight attack animations show broken/partial sprites. The SpriteFrames are being built, but the coordinates are wrong.

### Files to Check
```
scenes/characters/Knight_Combat.gd  (lines 104-150)
assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Combat.png
```

### The Issue
In `build_sprite_frames()`, the row-to-direction mapping may be incorrect:
```gdscript
# Current mapping:
var dirs = ["s", "n", "se", "ne", "e", "w", "sw", "nw"]
# Row 0 = s, Row 1 = n, Row 2 = se, etc.

# But the actual sprite sheet might have a different order!
```

### How to Fix
1. Open `2-Handed_Swordsman_Combat.png` in an image editor
2. Verify which rows correspond to which directions
3. Update the `dirs` array in `build_sprite_frames()` to match
4. Test in Godot (F5 to run)

---

## 🎮 Running the Game

```bash
cd jewelflame
/opt/godot  # or however Godot is installed on this system
```

Then press **F5** in Godot to run.

---

## 📁 Most Important Files

| File | Purpose |
|------|---------|
| `main_strategic.tscn` | Main game scene |
| `scenes/characters/Knight_Combat.gd` | Knight AI + animation builder |
| `scenes/strategic/knight_spawner.gd` | Spawns fighters every 3 seconds |
| `LLM_HANDOFF.md` | Full documentation |

---

## 🐛 Known Issues (Quick List)

1. **Attack animations broken** - Sprite sheet row mapping wrong
2. **Fighters spawn in UI area** - Wrong coordinates in knight_spawner.gd
3. **"idle_s doesn't exist" errors** - Race condition (harmless, but annoying)

---

## 🔧 Common Fixes

### Hide/Show Map Background
Edit `main_strategic.tscn`:
```
[node name="MapBackground" ...]
visible = false  # Set to true to show map again
```

### Change Spawn Rate
Edit `scenes/strategic/knight_spawner.gd`:
```gdscript
@export var spawn_interval: float = 3.0  # Change this
```

### Add More Fighter Types
Edit `scenes/strategic/knight_spawner.gd`, add to `fighter_scenes` array.

---

## 📊 Project Stats
- **Godot Version**: 4.6.stable
- **Fighter Types**: 6 (Knight, Grym, Hark, Janik, Nyro, Serek)
- **Animations per Knight**: 56 (8 directions × 7 animation types)
- **Provinces**: 11
- **Factions**: 3 (Blanche, Coryll, Lyle)

---

See `LLM_HANDOFF.md` for complete documentation.
