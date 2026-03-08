# HexForge — Revised Architecture Specification

## Project Overview
HexForge is a reusable hexagonal grid infrastructure system for Godot 4.x, designed to power tactical strategy games (initially JEWELFLAME, a Gemfire-inspired game). Prioritizes data/visual separation, performance, and clean serialization.

---

## Architectural Principles

### 1. Cube Coordinate Standard
All internal logic uses cube coordinates (x, y, z where x+y+z=0). Conversions happen only at input/output boundaries.

### 2. Strict Separation of Concerns
| Layer | Type | Responsibility |
|-------|------|----------------|
| Core | RefCounted/Resource | Pure data and math, zero Node dependencies |
| Services | RefCounted | Algorithms (pathfinding, LoS), no rendering |
| Rendering | Node2D | Visual representation only, no game logic |

### 3. Zero Dependencies
Pure GDScript 4. No external addons or C++ modules.

### 4. Performance Targets
- Grid instantiation: <10ms for 500 cells (tactical battle size)
- Pathfinding: <2ms for 15×15 search space
- JSON serialization: <10ms for 500 cells
- Frame time: Never exceed 16ms (60fps minimum)

*Note: Original 10,000-cell target reduced — tactical battles are 11×15 (165) to 15×15 (225) hexes. Optimize for actual use case, not theoretical maximum.*

---

## Directory Structure

```
res://hexforge/
├── core/
│   ├── hex_math.gd           # Static utilities: distance, line, ring, spiral
│   ├── hex_cell.gd           # Resource: terrain, elevation, occupant
│   └── hex_grid.gd           # Resource: spatial index Dictionary[Vector3i, HexCell]
├── services/
│   ├── pathfinder.gd         # A* with binary heap, movement cost functions
│   ├── line_of_sight.gd      # Bresenham on cube coords + height checks
│   └── terrain_rules.gd      # Cost lookup tables by unit type
└── rendering/
    ├── hex_renderer_2d.gd    # Node2D: sprite instantiation, culling
    ├── hex_cursor.gd         # Input handling: pixel→cube conversion
    └── range_highlighter.gd  # Visual feedback for movement/attack ranges
```

---

## Key Data Structures

### HexCell extends Resource
```gdscript
var cube_coord: Vector3i           # x+y+z must equal 0
var terrain_type: String           # "plains", "forest", "mountain", "water"
var elevation: int                 # 0=valley, 1=hill, 2=cliff
var blocking: bool                 # Impassable terrain flag
var occupant: Unit                 # Reference to unit occupying this hex (null if empty)
var custom_data: Dictionary        # Game-specific extensions
```

*Note: `occupant` added — movement validation requires checking if hex is occupied.*

### HexGrid extends Resource
```gdscript
var cells: Dictionary              # Vector3i → HexCell
var bounds: Rect2i                 # For culling/iteration

func get_cell(cube: Vector3i) -> HexCell
func set_cell(cube: Vector3i, cell: HexCell) -> void
func get_neighbors(cube: Vector3i) -> Array[Vector3i]
func get_range(center: Vector3i, radius: int) -> Array[Vector3i]
func to_json() -> String           # Axial storage: [x, z], compute y on load
func from_json(json: String) -> void
```

*Note: HexGrid changed from RefCounted to Resource for cleaner serialization. JSON stores axial [x, z] only — reconstruct y = -x-z on load. Saves ~33% disk space.*

---

## Pathfinding Specifications

- **Algorithm:** A* with binary heap priority queue
- **Heuristic:** Cube distance (exact, never overestimates)
- **Cost Function:**
  ```
  total_cost = base_terrain_cost + (elevation_diff * 2)
  if target_cell.occupant != null: total_cost += 1000  # Occupied hex penalty
  if target_cell.blocking: total_cost = INF
  ```
- **Optimization:** Cache last 20 paths, invalidate on grid mutation
- **Early Exit:** Return partial path if exceeding max_movement_range

---

## Terrain Rules (Default)

| Terrain | Base Cost | Cavalry | Infantry | Notes |
|---------|-----------|---------|----------|-------|
| Plains | 1.0 | 1.0 | 1.0 | Default |
| Forest | 2.0 | 3.0 | 1.5 | Blocks LoS |
| Mountain | INF | INF | INF | Impassable (except flying) |
| Water | INF | INF | INF | Impassable (except naval) |
| River | 3.0 | 3.0 | 3.0 | Crossing penalty only |

*Note: Elevation affects both movement (climbing cost) and LoS (height advantage).*

---

## Line of Sight

- **Algorithm:** Cube coordinate line drawing (Bresenham adaptation)
- **Blockers:**
  - Elevation difference > 1 between adjacent hexes
  - `blocking` terrain type (forest, mountain)
- **Range:** Max distance check before casting ray

---

## Rendering Specifications

- **Visual Style:** 2D pixel art, 32×32 hex sprites
- **Elevation:** Fake 3D via Y-offset (`-elevation * 8` pixels)
- **Culling:** Only render cells within camera rect + 2-cell margin
- **Z-Ordering:** Y-sort enabled for proper depth
- **Unit Rendering:** Separate from terrain; units are child nodes of HexRenderer2D, positioned at hex center

---

## Input Handling

HexCursor converts mouse position → axial → cube coordinates.

**Signals:**
- `cell_selected(cube: Vector3i)` — Left click
- `cell_hovered(cube: Vector3i)` — Mouse movement
- `cell_right_clicked(cube: Vector3i)` — Right click context menu

**Features:**
- Drag-selection (hold + drag)
- Multi-select modifiers (Ctrl/Cmd)

---

## Serialization Format (JSON)

```json
{
  "version": "1.0",
  "bounds": {"min_x": -5, "max_x": 5, "min_z": -5, "max_z": 5},
  "cells": [
    {"axial": [0, 0], "terrain": "plains", "elevation": 0, "blocking": false},
    {"axial": [1, 0], "terrain": "forest", "elevation": 1, "blocking": false}
  ]
}
```

*Note: Stores axial [x, z] only. Reconstruct cube y = -x-z on load. Cell.occupant NOT serialized in grid — units serialize separately with their cube_coord reference.*

---

## Game Integration (JEWELFLAME)

### Strategic Layer (Overworld)
- **Not a hex grid** — simple node graph of 30 territories
- Territory data: owner, garrison (Array[Unit]), resources
- Garrison units stored as data only — no hex positioning needed
- Triggers tactical battles via EventBus

### Tactical Layer (Battle)
- Full HexGrid instantiation: 11×11 (121) to 15×15 (225) hexes
- Units spawn at predefined spawn coordinates
- Real-time interaction: selection, movement, combat
- Battle result serialized back to Strategic layer (casualties, XP gains)

---

## Critical Constraints

| Rule | Enforcement |
|------|-------------|
| NEVER couple rendering in Core/Services | Code review check |
| NEVER use Godot's AStar class | Custom A* implementation |
| NEVER assume specific unit types | String keys for flexibility |
| ALWAYS validate cube coordinates | `assert(cube.x + cube.y + cube.z == 0)` in debug builds |
| ALWAYS type hint Dictionary keys | `Dictionary[Vector3i, HexCell]` |

---

## Testing Checklist

- [ ] Cube coordinates validate (x+y+z == 0)
- [ ] Path returns empty array if no valid path exists
- [ ] Pathfinding respects blocking terrain, elevation, and occupied hexes
- [ ] JSON roundtrip preserves all cell data exactly
- [ ] Renderer culls off-screen hexes
- [ ] Memory cleanup: HexGrid frees properly
- [ ] Multi-threading safety: No SceneTree access in Services

---

## Coding Style

- Static typing mandatory
- Explicit variable names (`cube_coord`, not `c` or `pos`)
- Comments for complex algorithms
- Signal emission for all state changes

---

## Key Changes from Original Prompt

1. **Performance targets reduced** — 500 cells max (not 10,000) matches actual tactical battle sizes
2. **HexGrid extends Resource** (not RefCounted) — cleaner save/load serialization
3. **JSON stores axial [x, z]** — reconstruct y on load, saves 33% space
4. **HexCell.occupant added** — required for movement validation
5. **Strategic layer clarified** — no hex grid, just node graph with garrison arrays
6. **Unit serialization separated** — occupant reference not stored in grid JSON

---

*Revised: 2026-03-04*
