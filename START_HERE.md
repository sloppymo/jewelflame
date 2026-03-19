# 👋 START HERE - New LLM Onboarding

## Welcome to Jewel Flame!

This is a Godot 4.6 grand strategy RPG. You're taking over development.

---

## 📚 Read These Files (In Order)

### 1. **QUICK_START.md** ⭐ START HERE
Quick orientation + the #1 thing to fix (knight animations)

### 2. **LLM_HANDOFF.md** 📖 FULL GUIDE
Complete project documentation, file structure, common tasks

### 3. **AGENTS.md** 📝 QUICK REFERENCE
Ongoing notes for AI assistants

---

## 🎯 Your First Task (Critical!)

**Fix the knight attack animations.**

They're showing broken/partial sprites. The SpriteFrames builder is working, but the row-to-direction mapping is wrong.

**Files:**
- `scenes/characters/Knight_Combat.gd` (lines 104-150)
- `assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Combat.png`

**Hint:** Check if the `dirs` array matches the actual sprite sheet layout:
```gdscript
var dirs = ["s", "n", "se", "ne", "e", "w", "sw", "nw"]
```

---

## 🎮 Running the Game

```bash
cd jewelflame
/opt/godot  # or: godot --editor
```

Then press **F5** in Godot.

Current state:
- ✅ Game runs
- ✅ Fighters spawn every 3 seconds
- ✅ Combat AI works
- ⚠️ Attack animations broken (your job!)

---

## 📂 Key Directories

```
scenes/characters/     # Fighter scenes + Knight_Combat.gd
scenes/strategic/      # Strategic layer + knight_spawner.gd
autoload/             # Game systems (singletons)
assets/               # Sprite sheets
```

---

## 🐛 Known Issues (See LLM_HANDOFF.md for details)

1. **Attack animations broken** ← FIX THIS
2. Fighters spawn in UI area
3. "idle_s doesn't exist" errors (harmless)

---

## 💬 Questions?

Check `LLM_HANDOFF.md` for:
- Complete file listing
- Code examples
- Debugging tips
- Common tasks

---

**Ready?** Open `QUICK_START.md` and get to work! 🚀
