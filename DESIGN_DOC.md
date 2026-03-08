# COMPREHENSIVE BRIEF: Jewelflame Tactical RPG

---

## **1. EXECUTIVE SUMMARY**

**Jewelflame** is a **Gemfire (SNES, 1991) clone**—a turn-based strategy game combining feudal province management with tactical RPG combat. Built in **Godot 4.6**, 100% GDScript.

**Core Loop:** Strategic Map (move armies, manage resources) → Tactical Battle (side-view stack combat) → Province Conquest.

**Current Date:** March 2026. Project is 3 months into development. MVP is functional but needs visual polish and battle scene integration.

---

## **2. VISUAL IDENTITY (NON-NEGOTIABLE)**

**Era:** 16-bit SNES (1991-1994), pixel-perfect, no anti-aliasing.

**Color Palette:**
- **Backgrounds:** Deep royal blue `#1a2f3f` (primary), `#2b2b5c` (panel)
- **Accents:** Rich gold `#d4af37` (ornate frames), cream `#f4e4c1` (text)
- **Factions:** Royal Blue (Blanche/player), Crimson `#8b2a2a` (Lyle/enemy), Forest Green `#2a6b3a` (Coryll/enemy)
- **UI:** Forest green `#4a8b4a` (buttons), dark teal `#1a4a5a` (water)

**UI Structure:**
- **Left 40%:** Ornate panel (`panel_border.png` as NinePatchRect) containing:
  - Family crest (golden lion on blue shield)
  - Province name ("3: Cobrige") in cream pixel font
  - **Portrait:** 256×384px display of lord (pre-framed pixel art: `sister.png`, `son.png`)
  - Stats grid: Gold coins, Wheat, Mana (blue crystal), Troops (helmet) with 32×32 icons + large numbers
  - Action buttons: Recruit, Develop, Attack, Info (beveled 3D style, lighter top/left, darker bottom/right)
- **Right 60%:** Hexagonal strategic map with terrain (forests, rivers, farmland, coastlines)

**Typography:**
- **Headers:** Press Start 2P (16px, gold with black drop shadow)
- **Numbers:** VT323 (24px, cream, calculator aesthetic)
- **Body:** Pixelify Sans (14px)

**Texture Filtering:** `TEXTURE_FILTER_NEAREST` on **everything**. No blur. Integer scaling only (1×, 2×, 3×).

---

## **3. GAMEPLAY ARCHITECTURE**

**Strategic Layer:**
- **5 Provinces:** Dunmoor (1), Carveti (2), Cobrige (3), Banshea (4), Petaria (5)
- **3 Families:** Blanche (player, blue), Lyle (aggressive AI, red), Coryll (opportunistic AI, green)
- **Turns:** Monthly cycle (Jan-Dec, Year 1+). Each family acts sequentially.
- **Commands (per province/turn):**
  - **Recruit:** 50 soldiers for 100 gold
  - **Develop:** +10 cultivation OR protection for 10 gold
  - **Attack:** Invade adjacent enemy province → launches Tactical Battle
  - **Move:** Transfer troops between owned provinces
- **Exhaustion:** One action per province per turn (visual overlay: grayed out hex)

**Tactical Layer:**
- **Combat:** Side-view animated battle (separate scene: `tactical_battle.tscn`)
- **Units:** Stack-based (not individual HP). "30 Knights" vs "17 Horsemen"
- **Unit Types:** Knights (heavy), Horsemen (fast), Archers (ranged), Mages (lightning spells), 5th Unit (creatures/dragons)
- **Casualties:** Calculated via power ratios, terrain mods, random (0.8-1.2)
- **Resolution:** Winner occupies province, loots 30% resources, 20% chance capture lord

**Economic Model:**
- **Resources:** Gold (recruitment/diplomacy), Food (army upkeep), Mana (magic)
- **Monthly:** Upkeep costs (1 food per 10 soldiers)
- **Harvest:** September only. Yield = Cultivation × 2 × (Loyalty/100)
- **Desertion:** Starving armies lose 2× deficit in soldiers

---

## **4. TECHNICAL ARCHITECTURE**

**Engine:** Godot 4.6, GDScript, 2D renderer.

**Key Files & Structure:**
```
autoload/                    # Global singletons
├── event_bus.gd            # All signals (ProvinceSelected, TurnEnded, BattleResolved)
├── game_state.gd           # provinces{}, families{}, current_family, current_month/year
├── save_manager.gd         # JSON serialization
├── command_processor.gd    # Action validation
├── military_commands.gd    # Recruitment, attacks, movement
├── domestic_commands.gd    # Development actions
├── ai_controller.gd        # AI decision making (DISABLED - see Status)
├── battle_resolver.gd      # Combat calculations (DISABLED)
└── economy_manager.gd      # Monthly upkeep (DISABLED)

strategic/
├── map/
│   └── province_renderer.gd    # Hex rendering, Area2D input, color coding
├── commands/
├── ai/
└── economy/

ui/
├── province_panel.tscn/.gd     # Main interaction UI (WORKING)
├── turn_indicator.tscn/.gd     # Year/month display
└── battle_report.tscn/.gd      # Post-combat summary

resources/
├── data_classes/               # ProvinceData, FamilyData, CharacterData (Resource scripts)
└── instances/                  # .tres files with actual game data

assets/
├── ui/panel_border.png         # NinePatchRect border (24px margins)
├── portraits/sister.png        # Lady Elara, 128×192 pre-framed
├── portraits/son.png           # Lord Roland, 128×192 pre-framed  
├── ui/icon_*.png               # Stat icons (gold, wheat, helmet, crown, swords, castle)
└── fonts/                      # Press Start 2P, VT323, Pixelify Sans

scenes/
├── tactical_battle.tscn        # Working but disconnected from strategic
└── strategic_map.tscn          # Main game view
```

**Critical Technical Rules:**
1. **Node Types:** Provinces are `Area2D` + `CollisionPolygon2D` + `Polygon2D` (visual)
2. **Signals:** All communication via `EventBus` (autoloaded). Never direct node references across scenes.
3. **Pixel Art:** `texture_filter = TEXTURE_FILTER_NEAREST` on all TextureRect and Sprite nodes
4. **Scaling:** Integer only. Portraits display at 256×384 (2× native 128×192)
5. **Colors:** Use theme overrides or direct Color constants. No shaders for UI.

---

## **5. CURRENT STATUS (As of 2026-03-08)**

**✅ WORKING (Do Not Break):**
- All scenes load with **0 script errors**
- Province clicking (Area2D input) → Panel opens
- Province panel displays: Name, lord, stats (gold/food/mana/troops)
- Recruit/Develop buttons functional (cost validation, exhaustion tracking)
- Turn system advances (Month/Year display updates)
- Save/Load JSON serialization
- EventBus signals all connected

**❌ DISABLED (in project.godot):**
- `AIController` - Uncomment to enable AI turns (currently manual only)
- `BattleResolver` - Combat math exists but not wired to UI
- `EconomyManager` - Monthly upkeep not processing
- `HarvestSystem` - September harvest not triggering
- `RandomEvents` - Disasters/events disabled

**🚧 CURRENT BLOCKER:**
The **Attack button** in `province_panel.gd` does not launch `tactical_battle.tscn`. The strategic layer works, the tactical scene works, but they are disconnected. This is the **highest priority integration**.

---

## **6. DESIGN PILLARS (Constraints)**

1. **Authenticity Over Polish:** SNES games had visible pixels, limited colors, and dithering. Do not smooth anything.
2. **Information Density:** Every UI element must convey game state. No decorative fluff without function.
3. **Immediate Feedback:** Every click must have visual response (hover brighten, click pulse, sound if possible).
4. **Feudal Logic:** Defeated enemies become vassals (not killed). Loyalty matters. Territory equals power.
5. **KISS:** One action per province per turn. Simple rules, complex emergent strategy.

---

## **7. ASSET INVENTORY**

**Available Now:**
- `panel_border.png` - Ornate golden NinePatchRect border (use 24px margins)
- `sister.png` - Lady Elara portrait, teal background, ornate gold frame, 128×192
- `son.png` - Lord Roland portrait, green background, ornate gold frame, 128×192  
- Stat icons: Gold coins, Wheat, Helmet, Crown, Crossed swords, Castle (all 32×32)
- Fonts: Press Start 2P, VT323, Pixelify Sans (imported)

**Needed (Generate These):**
- Terrain sprites: Forest clusters (dark green), Farmland stripes (yellow-brown), River bends (blue)
- Castle variants: Blue castle (Blanche), Red fortress (Lyle), Green keep (Coryll)
- Unit sprites for tactical battle (Knight, Horseman, Archer, Mage - side view, 16-bit)
- 5th Unit creatures (Dragon, etc.)

---

## **8. DEVELOPMENT PRIORITIES**

**Priority 1: Battle Scene Integration**
Hook the Attack button → Tactical scene → Return to strategic with results.

**Priority 2: Visual Polish**
Integrate portraits into province panel with color-coordinated backgrounds (teal tint for sister.png, warm tint for son.png).

**Priority 3: Terrain Rendering**
Add forest/farm/river sprites to strategic map hexes (multiply blend under faction color tint).

**Priority 4: AI Enablement**
Uncomment AIController autoload and ensure AI families take turns automatically.

---

## **9. CONTEXT FOR CODING TASKS**

When asked to generate GDScript:
- Use **Godot 4.6** syntax (`await` not `yield`, `get_tree().change_scene_to_file()` not `change_scene()`)
- Include `extends Node` or appropriate type
- Add type hints (`func _on_button_pressed() -> void:`)
- Use `EventBus.emit_signal("SignalName", params)` for cross-system communication
- Reference `GameState.provinces["1"]` for data (never hardcode province data in scripts)
- For UI: Use `add_theme_color_override()`, `custom_minimum_size`, `NinePatchRect`

When asked about visuals:
- Reference Gemfire (SNES 1991) as the aesthetic north star
- Specify TEXTURE_FILTER_NEAREST for all pixel art
- Recommend 2× integer scaling for portraits (256×384)
- Use the color palette specified in Section 2

---

**This is your canonical reference. When uncertain, default to: "What would a 1991 SNES strategy game do?"**
