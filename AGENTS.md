# Jewel Flame - Agent Notes

## 🆕 New Agent? Start Here!

**Read these files first:**
1. `QUICK_START.md` - Get oriented fast
2. `LLM_HANDOFF.md` - Full project documentation

---

## Project Context

This is a **Godot 4.6** grand strategy RPG with:
- Strategic overworld map
- Real-time tactical combat
- Multiple fighter types with animations

---

## Current Status (2026-03-19)

### ✅ Working
- Strategic layer with provinces and factions
- Combat AI (IDLE, WALK, ATTACK, HURT, DEAD states)
- Fighter spawning system (1 every 3 seconds)
- Speech bubbles (barks)
- Blood effects

### ⚠️ Broken / Needs Fix
- **Knight attack animations** - sprites appear misaligned
  - See: `scenes/characters/Knight_Combat.gd`
  - Issue: Row-to-direction mapping in sprite sheet

### 🔧 In Progress
- Animation system refinement
- Performance optimization
- UI polish

---

## Quick Commands

```bash
# Run game
cd jewelflame && /opt/godot

# Then press F5 in Godot
```

---

## Key Technical Details

### SpriteFrames
Knights build their SpriteFrames **at runtime** in `_ready()`:
```gdscript
# Knight_Combat.gd
func build_sprite_frames()
```

This avoids needing `.tres` files but may have coordinate issues.

### Fighter Spawner
Location: `scenes/strategic/knight_spawner.gd`
- Spawns random fighters every 3 seconds
- Configurable spawn area (map_bounds)

### Groups
- `"knight_combat"` - All knight instances
- `"artun_combat"` - All fighters (legacy name)

---

## Assets Location

```
assets/Citizens - Guards - Warriors/Warriors/
├── 2-Handed_Swordsman_Combat.png      # Attack/Hurt animations
├── 2-Handed_Swordsman_Non-Combat.png  # Idle/Walk/Run/Death
└── ...
```

Sprite sheet format:
- **Frame size**: 16×16 pixels
- **Combat**: 8 cols × 24 rows (128×384)
- **Non-combat**: 4 cols × 31 rows (64×496)

---

## When In Doubt

1. Check `LLM_HANDOFF.md` for detailed info
2. Look at `scenes/characters/Artun_Fighter.tscn` as reference
3. Run the game and check the Output panel for errors
4. The knight animation issue is the #1 priority to fix
