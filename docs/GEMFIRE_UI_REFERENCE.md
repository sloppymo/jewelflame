# Gemfire SNES UI Reference

This document provides pixel-perfect specifications for the Gemfire-inspired UI.

## Overall Layout

```
┌─────────────────────────────────────────┐  ◄── PANEL_WIDTH: 280px
│  ┌───────────────────────────────────┐  │
│  │  Header Section (56px height)     │  │
│  └───────────────────────────────────┘  │
│  ═════════════════════════════════════  │  ◄── Divider (8px)
│  ┌───────────────────────────────────┐  │
│  │  Portrait Section (96px height)   │  │
│  └───────────────────────────────────┘  │
│  ═════════════════════════════════════  │
│  ┌───────────────────────────────────┐  │
│  │  Stats Grid (6 rows)              │  │
│  └───────────────────────────────────┘  │
│  ═════════════════════════════════════  │
│  ┌───────────────────────────────────┐  │
│  │  Command Palette (56px height)    │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │  Footer Prompt                    │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
         ▲
         └── Padding: 12px all sides
```

---

## Header Section (56px height)

```
┌─────────────────────────────────────────┐
│ ┌────────┬───────────────────────────┐  │
│ │        │ Family Name               │  │  ◄── 16px, white, ALL CAPS
│ │ Shield │ ───────────────────────── │  │
│ │ 48x48  │ ID: Province Name         │  │  ◄── 14px, gold
│ │        │                           │  │
│ └────────┴───────────────────────────┘  │
└─────────────────────────────────────────┘
```

| Element | Specification |
|---------|---------------|
| Shield Icon | 48×48px, left side, family-colored |
| Shield Colors | Blanche: Royal Blue (#4169E1), Lyle: Crimson (#DC143C), Coryll: Forest Green (#228B22) |
| Family Name | 16px font, white (#FFFFFF), ALL CAPS, black shadow |
| Province Label | 14px font, gold (#FFD700), format "ID: Name" |

---

## Portrait Section (96px height)

```
┌─────────────────────────────────────────┐
│ ┌──────────────┬──────────────────────┐ │
│ │  ┌────────┐  │  Title (Lord/King)   │ │  ◄── 14px white
│ │  │        │  │  ──────────────────  │ │
│ │  │Portrait│  │  Name                │ │  ◄── 18px white
│ │  │ 72x72  │  │                      │ │
│ │  │        │  │                      │ │
│ │  └────────┘  │                      │ │
│ │    88x88     │                      │ │
│ │   (frame)    │                      │ │
│ └──────────────┴──────────────────────┘ │
└─────────────────────────────────────────┘
```

| Element | Specification |
|---------|---------------|
| Portrait Frame | 88×88px total |
| Frame Border | 8px ornate gold (NinePatch) |
| Visible Portrait | 72×72px centered |
| Background | Family color darkened |
| Title | "Lord"/"King"/"Knight", 14px white |
| Name | 18px white, stripped of "Lord " prefix |

### Portrait Mask Colors by Family

| Family | Mask Color |
|--------|------------|
| Blanche | Color(0.12, 0.12, 0.3) - Dark blue |
| Lyle | Color(0.3, 0.12, 0.12) - Dark red |
| Coryll | Color(0.12, 0.25, 0.12) - Dark green |

---

## Stats Grid (3 rows, 2 columns)

```
┌─────────────────────────────────────────┐
│ [Coin] Gold      │ [Flag] Loyalty       │ ◄── Row 0
│                  │                      │
│ [Wheat] Food     │ [Swords] Soldiers    │ ◄── Row 1
│                  │                      │
│ [Helmet] Army    │ [Castle] Protection  │ ◄── Row 2
└─────────────────────────────────────────┘
```

| Element | Specification |
|---------|---------------|
| Row Height | ~28px |
| Icon Size | 24×24px |
| Number Size | 18-20px, white, right-aligned |
| Number Shadow | Black, 2px offset |
| Column Gap | 8px |
| Row Gap | 2px |

### Stat Icons

| Slot | Icon | Stat |
|------|------|------|
| 0 | Coin (gold) | Gold |
| 1 | Flag (red/gold) | Loyalty |
| 2 | Wheat (gold/brown) | Food |
| 3 | Swords (silver) | Soldiers |
| 4 | Helmet (steel) | Army |
| 5 | Castle (stone) | Protection |

---

## Command Palette (56px height)

```
┌─────────────────────────────────────────┐
│  ┌────┐  ┌────┐  ┌────┐  ┌────┐        │
│  │ ⚔️  │  │ 🏰  │  │ 🚩  │  │ ⛑️  │        │
│  │    │  │    │  │    │  │    │        │
│  └────┘  └────┘  └────┘  └────┘        │
│  Battle Develop March  Troops           │
│  56x56   56x56   56x56   56x56         │
└─────────────────────────────────────────┘
```

| Element | Specification |
|---------|---------------|
| Button Size | 56×56px each |
| Button Spacing | 4px between |
| Total Width | 56×4 + 4×3 = 236px |
| States | Normal (raised), Pressed (inset), Hover (highlight) |
| Border | 3D beveled gold effect |

### Button Icons

| Button | Icon Description |
|--------|------------------|
| Battle | Crossed swords (silver) |
| Develop | Medieval tower (stone/brown roof) |
| March | Waving banner (red/gold) |
| Troops | Knight helmet (steel) |

### Button Colors

| State | Fill | Highlight | Shadow |
|-------|------|-----------|--------|
| Normal | #5a4f8a | #7a6faa | #3a2f5a |
| Pressed | #3a2f6a | #5a4f8a | #1a0f3a |
| Border | #f4d77a | #fff7aa | #b89627 |

---

## Footer Prompt

```
┌─────────────────────────────────────────┐
│                                         │
│  "Lord Banshea, what is your command?" │ ◄── 12-14px gold, centered
│                                         │
└─────────────────────────────────────────┘
```

| Element | Specification |
|---------|---------------|
| Text | "[Title] [Name], what is your command?" |
| Font Size | 12-14px |
| Color | Gold (#FFD700) |
| Shadow | Black, 2px |
| Alignment | Center |

---

## Color Palette

### Primary Colors

| Name | Hex | Usage |
|------|-----|-------|
| Background | #4a3f6a | Panel background (lighter purple) |
| Dark Background | #3a2f5a | Button normal state |
| Gold | #f4d77a | Borders, accents, highlights |
| Dark Gold | #b89627 | Shadow borders |
| Light Gold | #fff7aa | Corner highlights |
| White | #FFFFFF | Headers, stats |

### Family Colors

| Family | Primary | Dark (Portrait BG) |
|--------|---------|-------------------|
| Blanche | #4169E1 (Royal Blue) | #1e1e4c |
| Lyle | #DC143C (Crimson) | #4c1e1e |
| Coryll | #228B22 (Forest Green) | #1e3c1e |

---

## Typography

### Fonts

- **Primary**: Press Start 2P (pixel font)
- **Fallback**: Courier New, Monospace, DejaVu Sans Mono

### Font Sizes

| Element | Size | Color |
|---------|------|-------|
| Family Name | 16px | White |
| Province Label | 14px | Gold |
| Lord Title | 14px | White |
| Lord Name | 18px | White |
| Stats Numbers | 18px | White |
| Prompt | 12px | Gold |

### Text Effects

All text should have:
- Black shadow (#000000)
- Shadow size: 2px
- Shadow offset: (2, 2)

---

## Procedural vs. Pixel Art

### Current (Procedural)

The current implementation generates textures at runtime using `Image.create()` and drawing pixels.

### Target (Pixel Art)

Replace with actual image files:

```
res://assets/ui/
├── panel_border.png           # NinePatch for panel border
├── portrait_frame.png         # NinePatch for portrait frame
├── divider.png                # NinePatch for dividers
├── icons/
│   ├── icon_gold.png
│   ├── icon_loyalty.png
│   ├── icon_food.png
│   ├── icon_swords.png
│   ├── icon_helmet.png
│   └── icon_castle.png
└── buttons/
    ├── button_battle_normal.png
    ├── button_battle_pressed.png
    ├── button_develop_normal.png
    └── ...
```

---

## Animation Specifications

### Button Press

- Duration: 50ms
- Effect: Switch to pressed texture (inset appearance)
- Audio: Click sound (optional)

### Portrait Fade

- Duration: 150ms
- Effect: Crossfade between portraits
- Easing: Linear

### Shield Color Transition

- Duration: 200ms
- Effect: Instant (no animation for shield color change)

---

## Responsive Considerations

The panel has a **fixed width of 280px** and should:
- Anchor to the left edge of the screen
- Stretch vertically to fill the screen height
- Never resize horizontally
- Maintain all internal proportions
