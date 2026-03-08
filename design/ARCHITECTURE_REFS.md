# JEWELFLAME — Architectural Reference Analysis

## License Summary

| Repository | License | Status |
|------------|---------|--------|
| ramaureirac/godot-tactical-rpg | MIT | ✅ Safe to reference/copy with attribution |
| Strongground/godot-turnbased-hex-strategy | GPL-3.0 | ⚠️ Reference only; don't copy code |
| GDQuest demos | MIT (typical) | ✅ Safe, but repo URLs changed |

---

## Key Finding: ramaureirac Architecture (MIT — Safe)

### Project Structure (Godot 4.3)
```
data/
├── main.gd                    # Entry point
├── models/                    # Data classes & logic
│   ├── config/               # Configuration data
│   ├── view/                 # View/presentation models
│   └── world/                # World state models
└── modules/                   # Self-contained reusable nodes
    ├── stats/                # Stats system
    ├── tactics/              # Tactical combat logic
    └── ui/                   # UI components

assets/
├── maps/                     # Map files
└── scene/                    # Scene files
```

### Architectural Patterns Worth Adapting

#### 1. Models/Modules Separation
- **Models**: Centralized storage for class parameters & logic (pure data)
- **Modules**: Self-contained reusable Godot Nodes (scene + script)
- This mirrors your RuntimeServices pattern nicely

#### 2. Input Handling (from project.godot)
```
camera_right/left/forward/backwards  # WASD + gamepad
camera_rotate_right/left             # Q/E + shoulder buttons
camera_free_look                     # Middle mouse
```
- Clean separation of camera controls from UI
- Gamepad support built-in

#### 3. Autoload Structure
```
DebugMenu  # Toggleable debug overlay
```
- Minimal autoloads — avoids spaghetti

---

## GPL-3 Project Insights (Strongground)

**Reference only** — do not copy code. Key architectural concepts:

### Hex Grid System Design
- Underlying map graphic + hexagonal overlay
- Terrain types: road, hills, village
- Ownership system (faction control)
- Unit stats: ammo, fuel, manpower, experience, morale
- Temporary status effects (encircled, fortified)

### Multi-Faction Support
- X factions per session (not limited to 1v1)
- Different goals per faction
- Influence mapping (complex — would need simplification)

### Advanced Concepts (Over-Engineered for JEWELFLAME)
- Fortification creation (worker units)
- Civilian entities
- Diverse victory conditions
- Terrain destruction

---

## Recommendations for JEWELFLAME

### Use Directly (MIT-safe)
1. **Input map structure** — WASD + gamepad camera
2. **Models/Modules separation** — clean architecture
3. **Folder organization** — color-coded in editor

### Rebuild with LLM (Conceptual Inspiration)
| Component | Inspiration Source | Notes |
|-----------|-------------------|-------|
| GridManager | ramaureirac tactics module | Square grid (not hex) for Gemfire fidelity |
| TurnState | ramaureirac models/world | I-Go-You-Go phased turns |
| Territory data | Strongground influence map | Simplified: owner + resources + garrison |
| Unit stats | Both projects | War/Command/Politics (Gemfire style) |
| Camera | ramaureirac input scheme | 2D strategic map + isometric battle |

### Generate Fresh (Too Project-Specific)
- Food/Gold economy (core to your design)
- Fifth Unit wizard system (unique to Gemfire)
- Seasonal turn structure (Spring/Summer/Fall/Winter)
- Diplomacy (ally/defection/plunder/sabotage)
- 8-family faction system

---

## Attribution Template

For any MIT-licensed code adapted:
```gdscript
# Adapted from godot-tactical-rpg by ramaureirac
# https://github.com/ramaureirac/godot-tactical-rpg
# Licensed under MIT
```

---

## Next Steps

1. **Start with strategic map** — territory display, ownership colors
2. **Add turn structure** — monthly cycle with seasons
3. **Build tactical layer** — square grid, unit movement
4. **Integrate Fifth Unit** — wizard selection, cooldown system
5. **Layer in diplomacy** — once core loops work

---

*Analysis completed: 2026-03-04*
*References: ramaureirac/godot-tactical-rpg (MIT), Strongground/godot-turnbased-hex-strategy (GPL-3)*
