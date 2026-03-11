# Jewelflame Godot 4.5+ Development Guide
## AI-Powered Game Development with Knowledge System Integration

**Project:** Jewelflame  
**Engine:** Godot 4.5+ (targeting 4.6-stable)  
**Last Updated:** March 11, 2026  
**Connection ID:** ec74b0f4-ca88-40ad-9532-084ce680ef07

---

## Executive Summary

Jewelflame is a turn-based grand strategy game (Gemfire spiritual successor) built on a custom hex grid engine called HexForge. This document provides the engineering standards, architecture patterns, and integration guidelines for developing within this codebase.

### Key Systems
- **HexForge:** 5,941 lines of battle-tested hex grid code (pathfinding, LOS, combat)
- **Strategic Layer:** Province management, economy, diplomacy (GameState singleton)
- **Tactical Layer:** Hex-based combat using HexForge systems
- **Knowledge System:** AI-assisted development with solved problems database

### Technology Stack
- Godot 4.5+ with GDScript
- HexForge (custom hex grid engine)
- Supabase (knowledge persistence, research tracking)
- GitHub (version control)

---

## 1. Production DDL - Knowledge System Schema

### 1.1 Solved Problems Table
Stores reusable solutions to Godot/HexForge development problems.

```sql
-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Solved problems table
CREATE TABLE solved_problems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    problem_hash VARCHAR(64) UNIQUE NOT NULL,
    problem_summary TEXT NOT NULL,
    problem_embedding VECTOR(384),
    solution TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    source_url TEXT,
    project_id TEXT DEFAULT 'jewelflame',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    usage_count INTEGER DEFAULT 0
);

-- Index for similarity search
CREATE INDEX idx_solved_problems_embedding 
ON solved_problems 
USING ivfflat (problem_embedding vector_cosine_ops);

-- Index for tag searches
CREATE INDEX idx_solved_problems_tags 
ON solved_problems USING GIN(tags);

-- Index for project filtering
CREATE INDEX idx_solved_problems_project 
ON solved_problems(project_id);
```

### 1.2 Godot Patterns Table
Stores architectural patterns specific to Godot/HexForge.

```sql
CREATE TABLE godot_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_name VARCHAR(128) NOT NULL,
    pattern_type VARCHAR(64) NOT NULL, -- 'hexforge', 'ui', 'save_system', etc.
    description TEXT NOT NULL,
    code_sample TEXT,
    related_files TEXT[],
    constraints TEXT[],
    project_id TEXT DEFAULT 'jewelflame',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_godot_patterns_type 
ON godot_patterns(pattern_type);
```

### 1.3 Research Sessions Table
Tracks deep research tasks for complex features.

```sql
CREATE TABLE research_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic TEXT NOT NULL,
    status VARCHAR(32) DEFAULT 'in_progress',
    time_budget_minutes INTEGER,
    depth_level INTEGER DEFAULT 3,
    findings JSONB DEFAULT '{}',
    sources JSONB DEFAULT '[]',
    next_steps TEXT[],
    project_id TEXT DEFAULT 'jewelflame',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX idx_research_sessions_status 
ON research_sessions(status) 
WHERE status = 'in_progress';
```

---

## 2. Architecture Diagrams

### 2.1 High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     STRATEGIC LAYER                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │  Province    │  │   Faction    │  │      Economy         │   │
│  │   System     │  │   System     │  │   (Gold/Food)        │   │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘   │
│         │                 │                      │               │
│         └─────────────────┼──────────────────────┘               │
│                           │                                      │
│                    ┌──────┴──────┐                              │
│                    │  GameState  │  ← Autoload Singleton        │
│                    │   Bridge    │                              │
│                    └──────┬──────┘                              │
└───────────────────────────┼─────────────────────────────────────┘
                            │ start_battle() / end_battle()
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     TACTICAL LAYER                               │
│                    (HexForge Engine)                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │   HexGrid    │  │  Pathfinder  │  │  Line of Sight       │   │
│  │   (Core)     │  │  (Services)  │  │     (Services)       │   │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘   │
│         │                 │                      │               │
│         └─────────────────┼──────────────────────┘               │
│                           │                                      │
│                    ┌──────┴──────┐                              │
│                    │   Battle    │                              │
│                    │  Controller │                              │
│                    └─────────────┘                              │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    KNOWLEDGE SYSTEM                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │   Solved     │  │    Godot     │  │   Research           │   │
│  │   Problems   │  │   Patterns   │  │   Sessions           │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
│         ▲                                                      │
│         │ Similarity Search (pgvector)                          │
│         │                                                      │
│    ┌────┴────┐                                                 │
│    │  LLM    │ ← Queries before generating code                 │
│    │ Cache   │                                                  │
│    └─────────┘                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 HexForge Module Architecture

```
hexforge/
├── core/                    # Pure logic, no Godot dependencies
│   ├── hex_math.gd         # Coordinate conversions, distance
│   ├── hex_cell.gd         # Cell data structure
│   └── hex_grid.gd         # Grid management, queries
│
├── services/                # Thread-safe, no SceneTree access
│   ├── pathfinder.gd       # A* pathfinding
│   └── line_of_sight.gd    # Elevation-based LOS
│
├── rendering/               # Visual representation
│   ├── hex_renderer_2d.gd  # Draws hexes
│   ├── hex_cursor.gd       # Mouse interaction
│   ├── range_highlighter.gd # Movement/attack ranges
│   └── battle_scene.gd     # Scene composition
│
├── battle/                  # Combat logic
│   ├── battle_controller.gd # Turn management
│   ├── battle_grid.gd      # Grid + unit placement
│   ├── unit_manager.gd     # Unit lifecycle
│   ├── turn_manager.gd     # Phase control
│   ├── combat_engine.gd    # Damage calculation
│   └── ai_manager.gd       # AI opponents
│
└── tests/                   # Validation
    ├── hexforge_tests.gd
    └── hexforge_tests_extended.gd
```

### 2.3 Strategic UI Panel Flow

```
StrategicPanel (Control)
├── PanelBackground (NinePatchRect)
│   └── InnerBg (ColorRect - blue fill)
│
├── FactionHeader (HBoxContainer)
│   ├── BannerIcon (TextureRect - 48x64)
│   └── FactionLabels (VBoxContainer)
│       ├── FactionName (Label)
│       └── ProvinceName (Label)
│
├── CharacterSection (HBoxContainer)
│   ├── PortraitFrame (NinePatchRect)
│   │   └── Portrait (TextureRect - 96x144)
│   └── NameSection (VBoxContainer)
│       ├── NameLabel (Label)
│       └── ClassIcon (TextureRect)
│
├── ResourceGrid (GridContainer, 2 cols)
│   └── ResourceSlot (HBox x6)
│       ├── Icon (TextureRect - 32x32)
│       └── Value (Label)
│
├── UnitRow (HBoxContainer)
│   └── UnitBtn (TextureButton x4)
│       └── UnitIcon (TextureRect)
│
└── DialogueLabel (Label)
```

---

## 3. Risk Analysis

### 3.1 High-Risk Areas

| Risk | Impact | Mitigation |
|------|--------|------------|
| **HexForge class_name conflicts** | Build failures, scene load errors | Use preloads instead of class_name; avoid circular dependencies |
| **Scene tree coupling in Core/Services** | Thread safety violations, crashes | Never use get_tree(), Node references in Core/Services |
| **Godot built-in AStar** | Incompatible with hex grid, wrong pathfinding | Always use HexForge Pathfinder, never AStar/AStar2D |
| **Save game corruption** | Lost progress, user frustration | Version saves, validate on load, quarantine corrupt files |
| **Memory leaks in battle scenes** | Performance degradation | Properly free units, disconnect signals, pool where possible |

### 3.2 Medium-Risk Areas

| Risk | Impact | Mitigation |
|------|--------|------------|
| **UI scaling across resolutions** | Layout breakage | Use Control anchors, minimum sizes, nine-patch textures |
| **AI difficulty spikes** | Player frustration | Difficulty settings, gradual AI progression |
| **Asset loading failures** | Missing textures, pink squares | Fallback textures, async loading, validation |
| **Network latency (future multiplayer)** | Desync issues | Lockstep or prediction, state reconciliation |

---

## 4. Python Code Samples

### 4.1 Knowledge System Client

```python
#!/usr/bin/env python3
"""
Jewelflame Knowledge System Client
Queries solved problems before generating new code
"""

import hashlib
import json
from typing import List, Dict, Optional
from supabase_client import SupabaseClient

class JewelflameKnowledge:
    def __init__(self, supabase_url: str, supabase_key: str):
        self.client = SupabaseClient(supabase_url, supabase_key)
        self.project_id = "jewelflame"
    
    def _hash_problem(self, problem_text: str) -> str:
        """Create deterministic hash for problem lookup"""
        return hashlib.sha256(problem_text.lower().strip().encode()).hexdigest()[:64]
    
    def find_similar_problems(
        self, 
        query: str, 
        threshold: float = 0.85,
        limit: int = 3
    ) -> List[Dict]:
        """
        Find similar solved problems using vector similarity
        Returns empty list if no matches above threshold
        """
        # In production, this would use actual embedding
        # For now, use tag-based search
        tags = self._extract_tags(query)
        
        result = self.client.select(
            "solved_problems",
            columns="*",
            filters={"project_id": self.project_id}
        )
        
        if not result.get("success"):
            return []
        
        problems = result.get("data", [])
        
        # Filter by tag overlap (simplified similarity)
        scored = []
        for problem in problems:
            overlap = len(set(problem.get("tags", [])) & set(tags))
            if overlap > 0:
                scored.append((overlap, problem))
        
        scored.sort(reverse=True)
        return [p for _, p in scored[:limit]]
    
    def _extract_tags(self, query: str) -> List[str]:
        """Extract relevant tags from query"""
        tags = []
        keywords = {
            "hex": ["hex", "hexgrid", "hex_cell", "cube", "axial"],
            "pathfinding": ["path", "pathfinder", "astar", "navigation"],
            "ui": ["ui", "panel", "button", "texture", "ninepatch"],
            "combat": ["combat", "battle", "attack", "damage", "unit"],
            "save": ["save", "load", "json", "serialize", "persist"],
            "signal": ["signal", "emit", "connect", "event"],
            "performance": ["performance", "optimize", "memory", "leak"]
        }
        
        query_lower = query.lower()
        for category, keywords_list in keywords.items():
            if any(kw in query_lower for kw in keywords_list):
                tags.append(category)
        
        return tags
    
    def store_solution(
        self,
        problem: str,
        solution: str,
        tags: List[str],
        source_url: Optional[str] = None
    ) -> Dict:
        """Store a new solved problem"""
        problem_hash = self._hash_problem(problem)
        
        data = {
            "problem_hash": problem_hash,
            "problem_summary": problem[:200],
            "solution": solution,
            "tags": tags,
            "source_url": source_url,
            "project_id": self.project_id
        }
        
        return self.client.insert("solved_problems", data)
    
    def get_pattern(self, pattern_type: str, pattern_name: str) -> Optional[Dict]:
        """Retrieve a specific architectural pattern"""
        result = self.client.select(
            "godot_patterns",
            filters={
                "pattern_type": pattern_type,
                "pattern_name": pattern_name,
                "project_id": self.project_id
            }
        )
        
        if result.get("success") and result.get("data"):
            return result["data"][0]
        return None


# Usage example
if __name__ == "__main__":
    knowledge = JewelflameKnowledge(
        "https://idtshpotuasghxgalktp.supabase.co",
        "your_service_role_key"
    )
    
    # Query before generating code
    query = "How to implement hex grid movement with elevation costs?"
    similar = knowledge.find_similar_problems(query)
    
    if similar:
        print(f"Found {len(similar)} similar solutions:")
        for problem in similar:
            print(f"  - {problem['problem_summary'][:60]}...")
    else:
        print("No cached solution found - generating new code...")
```

### 4.2 HexForge Validation Script

```python
#!/usr/bin/env python3
"""
HexForge validation runner
Tests all core systems before integration
"""

import subprocess
import sys
from pathlib import Path

class HexForgeValidator:
    def __init__(self, project_path: Path):
        self.project_path = project_path
        self.errors = []
    
    def validate_syntax(self) -> bool:
        """Run Godot syntax check on all HexForge files"""
        hexforge_path = self.project_path / "hexforge"
        
        gd_files = list(hexforge_path.rglob("*.gd"))
        print(f"Validating {len(gd_files)} HexForge files...")
        
        for gd_file in gd_files:
            result = subprocess.run(
                [
                    "godot", "--headless", "--path", str(self.project_path),
                    "--check-only", "-s", str(gd_file.relative_to(self.project_path))
                ],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode != 0:
                self.errors.append(f"{gd_file.name}: {result.stderr}")
        
        return len(self.errors) == 0
    
    def run_unit_tests(self) -> bool:
        """Run HexForge test suite"""
        result = subprocess.run(
            [
                "godot", "--headless", "--path", str(self.project_path),
                "--script", "res://hexforge/tests/hexforge_tests.gd"
            ],
            capture_output=True,
            text=True,
            timeout=60
        )
        
        if "FAILED" in result.stdout or result.returncode != 0:
            self.errors.append(f"Unit tests failed: {result.stdout}")
            return False
        
        return True
    
    def generate_report(self) -> str:
        """Generate validation report"""
        if not self.errors:
            return "✅ HexForge validation PASSED"
        
        report = "❌ HexForge validation FAILED\n\n"
        for error in self.errors:
            report += f"- {error}\n"
        return report


if __name__ == "__main__":
    validator = HexForgeValidator(Path("/home/sloppymo/jewelflame"))
    
    syntax_ok = validator.validate_syntax()
    tests_ok = validator.run_unit_tests()
    
    print(validator.generate_report())
    sys.exit(0 if (syntax_ok and tests_ok) else 1)
```

---

## 5. Migration Plan

### 5.1 Current State → Target State

**Current:**
- Strategic panel UI exists but portrait is broken
- HexForge integrated but not fully wired to battle scene
- GameState has battle bridge functions
- Tactical battle scene exists but needs testing

**Target:**
- Fully functional strategic→tactical→strategic loop
- Working portrait display with proper textures
- Knowledge system active for development assistance
- All HexForge systems validated and integrated

### 5.2 Migration Steps

#### Phase 1: UI Polish (1-2 days)
- [ ] Fix portrait texture loading in StrategicPanel
- [ ] Hide/remove X button
- [ ] Add faction-colored fallback portraits
- [ ] Verify resource grid alignment

#### Phase 2: Battle Integration (2-3 days)
- [ ] Test tactical battle scene with HexForge
- [ ] Wire province attack button to GameState.start_battle()
- [ ] Verify battle end returns to strategic map
- [ ] Add save/load for mid-battle states

#### Phase 3: Knowledge System (1 day)
- [ ] Deploy Supabase schema
- [ ] Populate with initial HexForge patterns
- [ ] Create query workflow for developers
- [ ] Document usage in this guide

#### Phase 4: Validation (1 day)
- [ ] Run full HexForge test suite
- [ ] Validate save/load round-trip
- [ ] Performance test battle scene
- [ ] Document any remaining issues

### 5.3 Rollback Plan

If integration fails:
1. Revert to commit before HexForge integration
2. Use original battlefield_controller.gd
3. Keep strategic panel improvements
4. Document blockers for future attempt

---

## 6. HexForge Critical Constraints

**NEVER violate these rules:**

1. **No rendering in Core or Services**
   - Core: hex_math, hex_cell, hex_grid
   - Services: pathfinder, line_of_sight
   - These must be pure logic, no CanvasItem, no draw calls

2. **Never use Godot's built-in AStar**
   - Always use HexForge Pathfinder
   - AStar assumes square grids, breaks hex geometry

3. **Never assume specific unit types in Core**
   - Core systems work with generic dictionaries
   - Type-specific logic goes in Battle layer

4. **Always validate cube coordinates**
   ```gdscript
   # Before any coordinate operation
   assert(abs(q + r + s) <= 0.001, "Invalid cube coordinates")
   ```

5. **All Services files must be thread-safe**
   - No SceneTree access
   - No get_tree(), no node lookups
   - Pure functions only

6. **Type-hint all dictionary keys**
   ```gdscript
   var unit_data: Dictionary = {
       "id": unit_id,        # String
       "hp": health,         # int
       "pos": grid_pos       # Vector2i
   }
   ```

---

## 7. Quick Reference Commands

### Validate HexForge
```bash
cd /home/sloppymo/jewelflame
godot --headless --check-only -s hexforge/core/hex_grid.gd
godot --headless --script hexforge/tests/hexforge_tests.gd
```

### Run Strategic Scene
```bash
godot --path . scenes/main_strategic.tscn
```

### Run Tactical Battle Test
```bash
godot --path . scenes/tactical/tactical_battle_hexforge.tscn
```

### Knowledge Query (Python)
```python
from jewelflame_knowledge import JewelflameKnowledge

k = JewelflameKnowledge(url, key)
results = k.find_similar_problems("hex grid pathfinding with elevation")
```

---

## 8. Asset Pipeline

### Portrait Workflow
1. Generate base character (PixelBox/PixelLab)
2. Create 8-directional sprite set
3. Export front-facing view for portrait
4. Place in `assets/portraits/{character_name}.png`
5. Import with 2D Pixel preset (no filter)

### UI Texture Standards
- Panel backgrounds: NinePatchRect, 8px margins
- Icons: 32x32 or 48x48, consistent style
- Fonts: Ishmeria for headers, pixel font for body
- Colors: Faction-specific palettes

---

## 9. Change Log

| Date | Change | Author |
|------|--------|--------|
| 2026-03-11 | Initial Jewelflame guide | Kimi Claw |
| 2026-03-11 | Added knowledge system schema | Kimi Claw |
| 2026-03-11 | HexForge integration complete | Kimi Code |

---

**Connection ID:** ec74b0f4-ca88-40ad-9532-084ce680ef07
