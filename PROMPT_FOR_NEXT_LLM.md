# Prompt for Next LLM - Jewel Flame Project

## 🎯 Your Mission

You are taking over development of **Jewel Flame**, a Godot 4.6 grand strategy RPG. Your job is to fix the knight animation alignment issue and continue development.

---

## 📥 Step 1: Pull the Repository

```bash
git clone https://github.com/sloppymo/jewelflame.git
cd jewelflame
```

Or if already cloned:
```bash
git pull origin master
```

---

## 📖 Step 2: Read the Handoff Documents (CRITICAL)

Read these files in order:

1. **START_HERE.md** - Landing page with quick overview
2. **QUICK_START.md** - Your immediate task and how to run the game
3. **LLM_HANDOFF.md** - Complete project documentation (READ THIS FULLY)
4. **AGENTS.md** - Ongoing notes for AI assistants

```bash
cat START_HERE.md
cat QUICK_START.md
cat LLM_HANDOFF.md
```

---

## 🚨 Step 3: Understand the Current State

### What's Working
- Strategic layer with 11 provinces, 3 factions
- Combat AI with 6 fighter types (Knight, Grym, Hark, Janik, Nyro, Serek)
- Fighter spawning system (1 every 3 seconds)
- Speech bubbles, blood effects, team-based combat

### What's Broken (YOUR PRIORITY)
**Knight attack animations show partial/broken sprites**

The SpriteFrames are being built at runtime, but the row-to-direction mapping is incorrect. When knights attack, you see garbled/partial sprites instead of proper attack animations.

---

## 🔧 Step 4: Fix the Critical Issue

### The Problem
In `scenes/characters/Knight_Combat.gd`, the `build_sprite_frames()` function has an incorrect row mapping:

```gdscript
# Current mapping (lines ~120-130):
var dirs = ["s", "n", "se", "ne", "e", "w", "sw", "nw"]
# Row 0 = s, Row 1 = n, Row 2 = se, etc.
```

### What You Need to Do
1. **Open the sprite sheet**:
   ```
   assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Combat.png
   ```

2. **Analyze the actual layout**:
   - The sheet is 128×384 pixels
   - 8 columns × 24 rows of 16×16 frames
   - Rows 0-7 = attack_light (8 directions)
   - Rows 8-15 = attack_heavy (8 directions)
   - Rows 16-23 = hurt (8 directions)

3. **Verify the direction order**:
   - Look at row 0: Which direction is this actually?
   - Compare with row 8 (should be same direction, attack_heavy)
   - The `dirs` array order may be wrong

4. **Fix the mapping**:
   ```gdscript
   // Current (possibly wrong):
   var dirs = ["s", "n", "se", "ne", "e", "w", "sw", "nw"]
   
   // May need to be (example):
   var dirs = ["s", "se", "e", "ne", "n", "nw", "w", "sw"]
   // Or whatever matches the actual sprite sheet
   ```

5. **Test in Godot**:
   ```bash
   # Run Godot and press F5
   cd jewelflame && /opt/godot  # or: godot
   ```

### Success Criteria
- Knights show complete attack animations
- All 8 frames of attack_light play correctly
- No partial/garbled sprites during attacks

---

## 🎮 Step 5: Run and Test

### Launch the Game
```bash
cd jewelflame
# Option 1: Open in Godot editor
/opt/godot  # or: godot --editor

# Then press F5 to run
```

### What You Should See
- Dark gray background (no map image - intentional for testing)
- Fighters spawning every 3 seconds
- Combat happening automatically
- Speech bubbles ("Charge!", "Hey!", etc.)
- Blood effects when fighters take damage

### Test Scenes
- **main_strategic.tscn** - Full game with spawner
- **test_knight_anims.tscn** - Animation test (SPACE=next anim, RIGHT=next dir)

---

## 📋 Secondary Tasks (After Fixing Animations)

### 1. Fix Fighter Spawn Position
- Fighters currently appear in UI area
- Edit `scenes/strategic/knight_spawner.gd`
- Adjust `map_bounds` Rect2 coordinates

### 2. Add Pre-Built SpriteFrames (Optional)
- Current system builds at runtime (flexible but slower)
- Consider generating `.tres` files for better performance
- Use `tools/gen_spriteframes.py` as starting point

### 3. Add More Fighter Types
- Create new scenes based on `Knight_Fighter.tscn`
- Add to `knight_spawner.gd` fighter_scenes array
- Implement different stats/abilities

---

## 🔍 Key Files to Know

| File | Purpose |
|------|---------|
| `scenes/characters/Knight_Combat.gd` | ⭐ MAIN FILE - Fix this first |
| `scenes/characters/Knight_Fighter.tscn` | Knight scene template |
| `scenes/strategic/knight_spawner.gd` | Fighter spawner |
| `main_strategic.tscn` | Main game scene |
| `LLM_HANDOFF.md` | Full documentation |

---

## 💡 Context You Should Know

### Runtime SpriteFrames
The knights build their SpriteFrames in `_ready()` instead of using pre-built `.tres` files. This is intentional for flexibility, but means:
- Each fighter builds 56 animations on spawn
- Slight CPU cost on instantiation
- Easier to modify sprite mappings in code

### Fighter AI States
```gdscript
enum State { IDLE, WALKING, ATTACKING, HURT, DEAD, FLEEING, DISENGAGING }
```

AI uses target detection, pathfinding to enemies, and state transitions.

### Groups for Targeting
- `"knight_combat"` - All knight instances
- `"artun_combat"` - All fighters (legacy name, used for targeting)

---

## ⚠️ Common Errors You Might See

### "There is no animation with name 'idle_s'"
- **Cause**: Race condition - change_state() called before _ready() builds frames
- **Fix**: Harmless, but can be fixed with call_deferred

### Attack sprites look broken/garbled
- **Cause**: Row-to-direction mapping wrong in build_sprite_frames()
- **Fix**: This is YOUR main task!

### Fighters spawn in wrong location
- **Cause**: map_bounds coordinates in knight_spawner.gd
- **Fix**: Adjust the Rect2 values

---

## ✅ Definition of Done

You have successfully taken over when:
1. ✅ You can pull and run the game
2. ✅ Knight attack animations display correctly
3. ✅ All 8 directions work for attack_light
4. ✅ You've read and understood LLM_HANDOFF.md
5. ✅ You can explain the architecture to the user

---

## 🚀 Next Steps After Animation Fix

Ask the user what they'd like to work on:
1. Polish combat (balance, new abilities)
2. Strategic layer features
3. Add more fighter types
4. UI/UX improvements
5. Performance optimization

---

## 📞 Questions?

The LLM_HANDOFF.md file has:
- Complete file structure
- Technical architecture details
- Common tasks with code examples
- Debugging tips

If you're stuck on the animation issue:
1. Open the PNG in an image editor
2. Look at row 0, column 0 - what direction is the character facing?
3. Compare with row 8, column 0 - should be same pose, combat version
4. Adjust the `dirs` array to match

---

**Good luck! The knight animation fix is the key to unlocking the rest of the project.**
