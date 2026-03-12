# Jewelflame Sidebar Redesign - Design Document

**Status:** FINAL v0.7  
**Date:** March 12, 2026  
**Game:** Jewelflame (Gemfire-inspired strategy)  
**Target:** Godot 4.x  

---

## 1. Problem Statement

### Current Issues (from screenshot analysis)
- **Visual hierarchy failure**: Flat purple background with no depth or visual interest
- **Icon confusion**: Resource icons without labels - players can't identify gold vs food vs tools
- **Wasted space**: Bottom half of sidebar is completely empty
- **Identity mismatch**: Top shows "Lyle" but prompt says "Ander" - confusing character context
- **Touch target problems**: Icons too small for comfortable interaction
- **No decorative framing**: Lacks the medieval/medieval-fantasy aesthetic of the game's genre

### Goals
1. Capture the 90s SNES Koei strategy game aesthetic (Gemfire, Nobunaga's Ambition)
2. Make resource status immediately readable at a glance
3. Provide clear action affordances (buttons that look clickable)
4. Match the pixel-art style of the hex map
5. Fix information architecture - character identity should be consistent

---

## 2. Reference Analysis: Gemfire (SNES)

### What Gemfire Does Right

| Element | Implementation | Effect |
|---------|---------------|--------|
| **Portrait** | Large (~80x100px), prominent placement | Character identity is immediately clear |
| **Ornamental framing** | Gold decorative borders top & bottom | Medieval/fantasy aesthetic reinforcement |
| **Resource grid** | 2-column layout (3 rows = 6 resources) | Efficient space usage, scannable |
| **Big numbers** | Large numerals (24-28px) beside icons | Instant resource assessment |
| **Faction shield** | Heraldic crest in header | Faction/political context |
| **Action buttons** | 4 command buttons at bottom | Clear call-to-actions |
| **Message area** | Full-width bar at bottom | "Give how much food? 20 50 80 100" |
| **Textured background** | Subtle pattern (not flat) | Visual depth without distraction |
| **Consistent prompt** | "Lord Karl, what is your command?" matches portrait | Reinforces player-character link |

### Gemfire Layout Structure
```
┌─────────────────────────────┐
│ 🛡️ BLANCHE (Faction Shield) │
│ 5: Petaria (Holding)        │
│ ════════════════════════    │ ← Ornamental divider
│                             │
│ ┌────────┐  Lord Karl       │
│ │Portrait│  ⚔️ Level 5      │
│ └────────┘                  │
│                             │
│ 🪙 497    🚩 56             │ ← 2-col grid
│ 🍞 391    ⚔️ 38             │
│ 🪖   0    🏰 45             │
│                             │
│ ════════════════════════    │ ← Ornamental divider
│                             │
│ [⚔️] [🏛️] [📯] [🪖]        │ ← Action buttons
└─────────────────────────────┘
```

### Color Palette (Gemfire-inspired)
- **Primary background**: Deep royal purple/blue (`#2a1f4c`)
- **Secondary/accent**: Gold/bronze (`#d4af37`, `#ffd700`)
- **Text primary**: Off-white (`#f5f5dc`)
- **Text secondary**: Light gray (`#a0a0a0`)
- **Active/highlight**: Red (`#c41e3a`) or bright gold

---

## 3. Jewelflame Requirements

### Design Philosophy
The sidebar is the **primary gameplay interface**; the map is atmospheric/decorative (not a detailed tactical board). Therefore, the UI deserves generous space (560px) to present information clearly without cramming.

### Must Have
1. **Character identity section**
   - Large portrait card (120×160px with ornate gold frame)
   - Character name (bold, prominent, below card)
   - Title/faction
   - Level/rank indicator

2. **Resource display (6 resources)**
   - Gold, Food, Troops, Wood, Holdings, Influence
   - 2-column grid layout (Gemfire style)
   - Large icon (32×32px) + big number (24px font)

3. **Action buttons (hierarchical 4×4 system)**
   - **4 main sections**: Military, Economy, Diplomacy, System
   - **4 actions per section** (contextual)
   - Always visible, context enables/disables
   - Examples:
     - Military: Attack, Defend, Recruit, Scout
     - Economy: Build, Trade, Tax, Develop
     - Diplomacy: Negotiate, Ally, Threaten, Bribe
     - System: Save, Load, Settings, End Turn

4. **Fixed layout** (no collapsible sections)
   - All information always visible
   - Consistent 560px width
   - Supports 1080p and 1440p with scaling

5. **Decorative elements**
   - Ornate gold card frame (portrait anchor)
   - Decorative dividers between sections
   - Consistent with pixel-art aesthetic

6. **Message/Feedback Area (FULL WIDTH)**
   - Dedicated space at **bottom of entire screen**
   - Spans full 1920px width (not just under sidebar)
   - Rendered in KOEI-style serif font
   - Height: 60-80px (horizontal, not vertical)
   - Examples: "Give how much food? 20 50 80 100"
   - Supports choice options displayed inline

---

## 4. Proposed Design

### Layout Structure (560px Width + Full-Width Message)
```
┌─────────────────────────────────────────────────────────────────┐
│              🛡️ FACTION HEADER                  │                │
│           Lord of [Territory]                   │                │
│  ═══════════════════════════════════════════    │                │
│                                                 │                │
│              ┌─────────────────┐                │                │
│              │   ORNATE GOLD   │                │                │
│              │  CARD FRAME     │                │                │
│              │  ┌───────────┐  │  120×160px    │      MAP       │
│              │  │  PORTRAIT │  │                │     AREA       │
│              │  └───────────┘  │                │   (1360px)     │
│              └─────────────────┘                │                │
│              Character Name                     │                │
│              ⚔️ Level X                         │                │
│                                                 │                │
│  ═══════════════════════════════════════════    │                │
│                                                 │                │
│   🪙 0000      🍞 0000         ⚔️ 000          │                │
│   🪵 000       🏰 00           📯 00           │                │
│                                                 │                │
│  ═══════════════════════════════════════════    │                │
│                                                 │                │
│  [⚔️] [🏛️] [📯] [⚙️]  ← Section tabs (4)       │                │
│                                                 │                │
│  ┌─────────────────────────────────────────┐    │                │
│  │ [⚔️ Attack]    [🛡️ Defend]             │    │                │
│  │ [👥 Recruit]   [👁️ Scout]              │    │                │
│  └─────────────────────────────────────────┘    │                │
│                                                 │                │
└───┬─────────────────────────────────────────┬───┴────────────────┘
    │                                                     │
    └─────────────────────────────────────────────────────┘
    ═══════════════════════════════════════════════════════
    
    FULL-WIDTH MESSAGE PANEL (1920px × 60-80px)
    
    "Give how much food?              20    50    80    100"
    
    ═══════════════════════════════════════════════════════
```

### Dimensions (Revised)
- **Sidebar width**: 560px (fixed) - *Generous space for UI as primary interface*
- **Portrait card**: 120×160px ( ornate gold frame)
- **Resource icon**: 32×32px
- **Resource number**: 24px font
- **Action button**: 80×80px (section tabs), 64×64px (action buttons)
- **Section padding**: 16-24px
- **Spacing between elements**: 12-16px
- **Message panel**: **1920px wide × 60-80px tall** (full width, horizontal)

### Color Scheme (Proposed)
```gdscript
# Core palette
--sidebar-bg: #1a1a2e          # Deep navy-purple
--sidebar-header: #16213e      # Slightly lighter
--accent-gold: #d4af37         # Classic gold
--accent-highlight: #e94560    # Red for active/warning
--text-primary: #f5f5dc        # Cream/off-white
--text-secondary: #a0a0a0      # Muted gray
--section-bg: #252540          # Elevated sections
--border-color: #3d3d5c        # Subtle borders
```

---

## 5. Implementation Approach

### Scene Hierarchy (Godot 4)

**Main UI Container:**
```
GameUI (CanvasLayer)
├── MainContainer (HBoxContainer)
│   ├── GameSidebar (PanelContainer) - 560px wide
│   │   ├── Background (ColorRect)
│   │   ├── MainContent (VBoxContainer)
│   │   │   ├── HeaderSection (PanelContainer)
│   │   │   │   ├── FactionShield (TextureRect)
│   │   │   │   ├── FactionLabel (Label)
│   │   │   │   └── TerritoryLabel (Label)
│   │   │   ├── Divider1 (TextureRect)
│   │   │   ├── CharacterSection (CenterContainer)
│   │   │   │   └── PortraitCard (PanelContainer)
│   │   │   │       ├── FrameBorder (NinePatchRect)
│   │   │   │       └── Portrait (TextureRect) - 120×160
│   │   │   ├── CharacterInfo (VBoxContainer)
│   │   │   │   ├── NameLabel (Label)
│   │   │   │   ├── TitleLabel (Label)
│   │   │   │   └── LevelLabel (Label)
│   │   │   ├── Divider2 (TextureRect)
│   │   │   ├── ResourcesSection (PanelContainer)
│   │   │   │   └── ResourcesGrid (GridContainer, 2 cols)
│   │   │   │       └── ResourceItem × 6
│   │   │   ├── Divider3 (TextureRect)
│   │   │   ├── SectionTabs (HBoxContainer)
│   │   │   │   └── SectionButton × 4
│   │   │   ├── ActionsGrid (GridContainer, 2 cols)
│   │   │   │   └── ActionButton × 4
│   │   │   └── SystemRow (HBoxContainer)
│   │   └── BorderBottom (NinePatchRect)
│   │
│   └── MapArea (Control) - SIZE_EXPAND_FILL
│       └── HexMap (your existing hex grid)
│
└── MessagePanel (PanelContainer) - FULL WIDTH, bottom
    ├── set_anchors_preset(PRESET_BOTTOM_WIDE)
    ├── BorderTop (NinePatchRect) - Full width gold line
    ├── Background (ColorRect)
    ├── Content (HBoxContainer)
    │   ├── MessageLabel (Label) - KOEI font
    │   └── ChoicesContainer (HBoxContainer) - For 20/50/80/100 style
    └── BorderBottom (NinePatchRect)
```

### Required Assets
1. **Portraits** - Character portrait sprites (120×160px with card frame)
2. **Faction shields** - Heraldic crest icons (64×80px)
3. **Resource icons** (32×32px each):
   - Gold coins
   - Food/bread
   - Troops/sword
   - Wood/logs
   - Castle/fortress
   - Banner/influence
4. **Action icons** (48×48px each):
   - Section tabs: Military, Economy, Diplomacy, System
   - Actions: Attack, Defend, Recruit, Scout, Build, Trade, Tax, Develop, Negotiate, Ally, Threaten, Bribe, Save, Load, Settings, End Turn
5. **UI chrome**:
   - Portrait card frame (9-slice, ornate gold)
   - Ornamental border sprites (9-slice)
   - Decorative dividers
   - Button frames (normal, hover, pressed)
   - Section panel backgrounds
6. **Fonts**:
   - KOEI-style serif font (Cinzel or similar) for messages
   - Clean sans-serif for numbers and UI labels

### GDScript Interface
```gdscript
class_name GameSidebar
extends PanelContainer

# Signals
signal action_pressed(action_type: String)
signal resource_clicked(resource_type: String)

# Exported properties
@export var portrait_texture: Texture2D
@export var faction_shield: Texture2D
@export var character_name: String = "Unknown"
@export var character_title: String = ""
@export var character_level: int = 1

# Resource values (auto-update UI)
@export var gold: int = 0 : set = _set_gold
@export var food: int = 0 : set = _set_food
@export var troops: int = 0 : set = _set_troops
@export var wood: int = 0 : set = _set_wood
@export var holdings: int = 0 : set = _set_holdings
@export var influence: int = 0 : set = _set_influence

# State
var current_section: String = "military"
var available_actions: Array[String] = []

# Methods
func set_character(data: CharacterData) -> void
func update_resource(type: String, value: int, max_value: int = -1) -> void
func set_section(section: String) -> void
func set_available_actions(actions: Array[String]) -> void
func set_turn_info(year: int, month: String) -> void
```

---

## 6. Design Decisions (Final)

| Question | Decision | Rationale |
|----------|----------|-----------|
| **Portrait style** | Card-framed pixel art | User provided reference |
| **Portrait dimensions** | 120×160px (3:4 ratio) | Matches card aesthetic |
| **UI chrome style** | Match card frame | Gold ornate borders throughout |
| **Background color** | Dark teal/navy | Complements gold frames |
| **Action buttons** | Fixed 4-button hierarchical menu | 4 sections → 4 actions each (Gemfire pattern) |
| **Collapsible sections** | Fixed layout (no collapse) | Map not priority, always-visible info |
| **Target resolution** | 1080p + 1440p with scaling | Support both |
| **Resource display** | 2-column grid (Gemfire style) | Icon + big number, scannable |
| **Message panel** | **FULL WIDTH (1920px)** | Gemfire authenticity, room for choices |
| **Message height** | **60-80px** | Horizontal layout like "Give how much food?" |

---

## 7. Next Steps

1. ~~Decide on open questions~~ ✅ **ALL DECIDED**
2. Create asset list based on decisions
3. Build Godot scene with placeholder graphics
4. Implement core functionality (setters, signals)
5. Add styling/theming
6. Integration testing with hex map scene

---

## 5.5 Visual Reference: Portrait Card Aesthetic

**User-provided reference:** Ornate golden card frame with pixel-art portrait

![Portrait Reference](./media/portrait_reference.png)

### Key Visual Elements to Replicate

| Element | Specification |
|---------|--------------|
| **Frame style** | Ornate gold decorative border with corner flourishes |
| **Frame color** | Gold `#d4af37` with darker bronze shadow `#8b6914` |
| **Inner background** | Deep teal `#2d5a5a` or dark blue `#1e3a4a` |
| **Portrait size** | ~120×160px (portrait aspect ratio) |
| **Card shape** | Vertical rectangle with decorative top element |

### Sidebar Integration

The portrait card becomes the **visual anchor** of the entire sidebar.

---

## Appendix A: Current vs Target Comparison

| Aspect | Current | Target (Card Aesthetic) |
|--------|---------|------------------------|
| Background | Flat purple `#4a3b5c` | Dark teal `#2d5a5a` or navy `#1a1a2e` |
| Portrait | Tiny (~40×50px), no frame | Large (120×160px), ornate gold card frame |
| Resources | Small icons, no labels | Big icons + large numbers in 2-col grid |
| Layout | Vertical list, scattered | Card-centered, symmetrical |
| Actions | Empty space | 4-6 visible buttons with gold borders |
| Framing | None | Ornate gold card frame as anchor element |
| Identity | Mismatch (Lyle vs Ander) | Consistent character context |
| Message | None | Full-width KOEI-style bar at bottom |

---

## Appendix B: Asset Specifications

### Portrait Cards (Per Character)
- **Size:** 120×160px
- **Format:** PNG with transparency for frame overlay
- **Style:** Pixel art, anime-inspired medieval fantasy
- **Frame:** Ornate gold decorative border (separate sprite for reuse)

### Required Frames
1. **Portrait card frame** (120×160) - Ornate gold border
2. **Section divider** (280×16) - Horizontal gold ornamental line
3. **Action button frame** (48×48) - Gold border, 3 states (normal/hover/pressed)
4. **Resource icon frame** (40×40) - Subtle gold accent
5. **Message panel border** (1920×16) - Full-width gold ornamental line

### Color Palette (Final)
```gdscript
# Primary
--bg-primary: #1a2f3a        # Dark teal-blue
--bg-secondary: #0f1f26      # Darker background
--bg-card: #2d5a5a           # Card inner background

# Accent
--gold-primary: #d4af37      # Bright gold
--gold-shadow: #8b6914       # Darker bronze
--gold-highlight: #f4d03f    # Highlight

# Text
--text-primary: #f5f5dc      # Cream/off-white
--text-secondary: #a8c0c0    # Muted teal-gray
--text-gold: #d4af37         # Gold text for headers

# States
--accent-danger: #c0392b     # Red for warnings
--accent-success: #27ae60    # Green for positive
```

---

## Appendix C: Hierarchical Action Menu System

Based on Gemfire's pattern and user requirements:

### 4 Main Sections (Tabs/Buttons)
1. **⚔️ Military** - Warfare and troop management
2. **🏛️ Economy** - Building and resource management  
3. **📯 Diplomacy** - Relations and agreements
4. **⚙️ System** - Game functions

### 4 Actions Per Section

**Military Actions:**
- Attack - Initiate combat on selected hex
- Defend - Fortify current position
- Recruit - Add troops to army
- Scout - Gather intelligence

**Economy Actions:**
- Build - Construct in selected province
- Trade - Exchange resources
- Tax - Collect from holdings
- Develop - Improve province

**Diplomacy Actions:**
- Negotiate - Open talks with faction
- Ally - Form alliance
- Threaten - Intimidate neighbor
- Bribe - Pay for favor

**System Actions:**
- Save - Save game
- Load - Load game
- Settings - Open options
- End Turn - Finish turn

### UI Implementation
- Section selector at top of action area (4 buttons)
- Current section's 4 actions displayed below
- Highlight active section
- Disable actions not valid for current context

---

## Appendix D: Resolution Scaling Strategy

### Base Design: 1920×1080
- Sidebar width: 560px
- Portrait card: 120×160px
- Resource icons: 32×32px
- Action buttons: 80×80px (with 48×48 icon inside)
- Message panel: 1920×70px

### 2560×1440 Scaling
- Scale factor: 1.33x
- Option A: Scale everything proportionally
- Option B: Keep sidebar fixed width, add more spacing/padding

### Godot Implementation
```gdscript
# Use scalable UI with anchor ratios
# OR fixed size with display scaling
func _ready():
    var screen_size = DisplayServer.window_get_size()
    var scale_factor = screen_size.x / 1920.0
    # Apply scale to relevant nodes
```

---

## Appendix E: Design Intent & Rationale

### Sidebar Width: 560px (Intentional)

**User decision:** Keep 560px width despite standard UX recommendations for narrower sidebars.

**Rationale:**
- The hex map is **atmospheric/decorative**, not a detailed tactical board
- Players do not need to "scour the map" for gameplay-relevant details
- The sidebar contains the **primary gameplay interface** (resources, actions, character info)
- Generous space allows for:
  - Larger, more readable text
  - Comfortable touch targets
  - Ornate decorative elements without crowding
  - Future content expansion (event log, tooltips, etc.)

**Godot Implementation Notes:**
- Use `custom_minimum_size = Vector2(560, 0)` on root PanelContainer
- Set `size_flags_horizontal = Control.SIZE_FILL` for height expansion
- Anchor to left edge with `anchors_preset = Control.PRESET_LEFT_WIDE`
- Map area gets remaining space via `Control.SIZE_EXPAND_FILL`

### Map vs. UI Priority

| Element | Purpose | Screen Share |
|---------|---------|--------------|
| **Sidebar** | Primary gameplay interface | ~29% (560px/1920px) |
| **Hex Map** | Atmospheric/visual context | ~71% (1360px/1920px) |
| **Message Panel** | Command feedback & choices | 100% width × 70px |

This inverts the typical strategy game ratio (where map is 70%+), but aligns with Jewelflame's design where the UI drives interaction and the map provides visual context.

---

## Appendix F: Message/Feedback Area (FULL WIDTH)

### Purpose
Dedicated space for game feedback and narrative text, rendered in KOEI-style serif font at the **bottom of the entire screen** (full width). Replaces intrusive pop-ups with elegant messaging while supporting choice displays.

### Visual Reference
From Gemfire: "Give how much food? 20 50 80 100" - rendered in distinctive serif typeface across full screen width.

### Specifications

| Element | Specification |
|---------|--------------|
| **Position** | Bottom of screen, **full width (1920px)** |
| **Height** | 60-80px (horizontal, not vertical) |
| **Background** | Dark teal `#1a2f3a` with subtle texture |
| **Top border** | Gold ornamental line spanning **full width** |
| **Font** | KOEI-style serif (Cinzel or similar) |
| **Font size** | 20-24px |
| **Text alignment** | Centered or left-aligned with padding |
| **Choice options** | Displayed inline, horizontally spaced |

### Layout Position (FULL WIDTH)
```
┌─────────────────────────────────────────────────────────────────┐
│                             │                                   │
│      SIDEBAR (560px)        │         MAP AREA                  │
│      560px wide             │         (1360px)                  │
│                             │                                   │
│   ┌─────────────────────┐   │                                   │
│   │   PORTRAIT CARD     │   │                                   │
│   └─────────────────────┘   │                                   │
│                             │                                   │
│   [Resources]               │                                   │
│                             │                                   │
│   [Section Tabs]            │                                   │
│   [Action Buttons]          │                                   │
│                             │                                   │
└───┬─────────────────────┬───┴───────────────────────────────────┘
    │                                                     │
    └─────────────────────────────────────────────────────┘
    ═══════════════════════════════════════════════════════
    
    FULL-WIDTH MESSAGE PANEL (1920px × 60-80px)
    
    "Give how much food?              20    50    80    100"
    
    ═══════════════════════════════════════════════════════
```

### Why Full Width?

1. **Gemfire authenticity** - Matches "Give how much food?" layout exactly
2. **Choice display** - Room for 4-6 options horizontally
3. **Better readability** - Longer narrative text without wrapping
4. **Visual balance** - Grounds the entire screen composition
5. **Command line feel** - Like a proper strategy game interface

### Message Types

**Routine Feedback (Message Panel):**
- Combat: "You lost 50 troops!", "Enemy retreated!"
- Economy: "Taxes collected: 200 gold", "Construction complete!"
- Diplomacy: "Trade agreement signed"
- System: "Lord Karl, what is your command?"

**With Choices (Gemfire style):**
```
"Give how much food?                          20      50      80      100"
"Attack which province?                       12      15      22      28"
"Negotiate with:                              Karl    Garth   Blanche Petaria"
```

### Technical Implementation (Godot)

```gdscript
class_name MessagePanel
extends PanelContainer

@onready var message_label: Label = %MessageLabel
@onready var choices_container: HBoxContainer = %ChoicesContainer
@onready var typewriter_timer: Timer = $TypewriterTimer

var current_message: String = ""
var display_speed: float = 0.03  # seconds per character

func _ready():
    # Full width at bottom
    set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    custom_minimum_size = Vector2(0, 70)
    
    # Choice spacing
    choices_container.add_theme_constant_override("separation", 60)

func show_message(text: String, play_sound: bool = true) -> void:
    current_message = text
    message_label.text = ""
    choices_container.visible = false
    
    if play_sound:
        AudioManager.play_sfx("message_appear")
    
    # Typewriter effect
    for i in range(text.length()):
        message_label.text = text.substr(0, i + 1)
        await get_tree().create_timer(display_speed).timeout

func show_message_with_choices(text: String, choices: Array[String]) -> void:
    message_label.text = text
    
    # Clear and populate choices
    for child in choices_container.get_children():
        child.queue_free()
    
    for choice in choices:
        var btn = Button.new()
        btn.text = choice
        btn.pressed.connect(_on_choice_selected.bind(choice))
        choices_container.add_child(btn)
    
    choices_container.visible = true

func show_feedback(feedback_type: String, amount: int = 0) -> void:
    var messages = {
        "troop_loss": "You lost %d troops in the battle!" % amount,
        "troop_gain": "%d new recruits have joined your army!" % amount,
        "gold_earned": "Taxes collected: %d gold" % amount,
        "gold_spent": "You spent %d gold" % amount,
        "victory": "Your army has been victorious!",
        "defeat": "Your forces have been defeated...",
        "construction_complete": "Construction completed!",
        "alliance_formed": "Alliance formed!"
    }
    
    if messages.has(feedback_type):
        show_message(messages[feedback_type])
```

### Font Recommendations

**KOEI-Style Serif Options:**
1. **Cinzel** (Google Fonts) - Closest match, medieval caps
2. **Cinzel Decorative** - More ornate variant
3. **MedievalSharp** - Authentic medieval feel
4. **Uncial Antiqua** - Celtic/medieval hybrid
5. **Almendra** - Spanish medieval (fits Iberian theme)

**Godot Font Import:**
```gdscript
# In project settings or theme
var koei_font = load("res://fonts/Cinzel-Regular.ttf")
message_label.add_theme_font_override("font", koei_font)
message_label.add_theme_font_size_override("font_size", 22)
```

---

## Appendix G: Major Event Pop-up Modals

### Purpose
Full-screen or center-screen modal dialogs for **major game events** that deserve player attention and require acknowledgment. Complements the message panel (routine feedback) with dramatic presentation for significant moments.

### When to Use Pop-ups vs. Message Panel

| Event Type | Delivery Method | Examples |
|------------|-----------------|----------|
| **Routine feedback** | Message panel | "Lost 50 troops", "Taxes collected" |
| **Major victories** | Pop-up modal | "Battle of Dunmoor Won!" |
| **Character death** | Pop-up modal | "Lord Karl has fallen..." |
| **Alliance changes** | Pop-up modal | "House Blanche allies with you!" |
| **Province capture** | Pop-up modal | "Petaria has been conquered!" |
| **Story milestones** | Pop-up modal | "The Crown is within reach..." |
| **Turn/season change** | Pop-up modal | "Year 2, Spring - The thaw begins" |

### Pop-up Specifications

| Element | Specification |
|---------|--------------|
| **Position** | Center screen or full-screen overlay |
| **Size** | 600×400px (centered) or full screen with dimmed background |
| **Background** | Dark overlay (50% black) + decorative modal frame |
| **Frame** | Ornate gold border (matching portrait card style) |
| **Animation** | Fade in + slight scale (0.9 → 1.0) |
| **Font header** | Large KOEI-style serif (28-32px) |
| **Font body** | KOEI-style serif (18-20px) |
| **Sound** | Distinctive fanfare or dramatic sting |

### Pop-up Types

**1. Victory Modal**
- Header: "VICTORY!" with crossed swords icon
- Shows: Battle name, enemy losses, your losses, spoils
- Sound: Triumphant fanfare

**2. Defeat Modal**
- Header: "DEFEAT..." with broken sword icon
- Shows: Battle name, lessons learned, retreat options
- Sound: Somber brass

**3. Character Death Modal**
- Header: Character portrait (grayed) + "FALLEN"
- Shows: Name, title, cause of death, years of service
- Sound: Mournful bell toll

**4. Alliance Modal**
- Header: Two faction shields + "ALLIANCE FORMED"
- Shows: Ally name, terms, duration
- Sound: Formal trumpet

**5. Province Capture Modal**
- Header: Castle icon + "PROVINCE CAPTURED"
- Shows: Province name, previous owner, new income
- Sound: Victory fanfare (shorter)

**6. Season Change Modal**
- Header: Season icon (🌸☀️🍂❄️) + "Year X, Season"
- Shows: Seasonal narrative text, upcoming events preview
- Sound: Ambient seasonal soundscape

### Technical Implementation (Godot)

```gdscript
class_name EventModal
extends PanelContainer

enum ModalType { VICTORY, DEFEAT, DEATH, ALLIANCE, CAPTURE, SEASON }

@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var icon_texture: TextureRect = %IconTexture
@onready var continue_button: Button = %ContinueButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal dismissed

func show_event(event_type: ModalType, data: Dictionary) -> void:
    visible = true
    
    match event_type:
        ModalType.VICTORY:
            title_label.text = "🛡️ VICTORY! 🛡️"
            body_label.text = _format_victory_text(data)
            icon_texture.texture = preload("res://ui/icons/victory.png")
            AudioManager.play_sfx("fanfare_victory")
        
        ModalType.DEFEAT:
            title_label.text = "⚔️ DEFEAT... ⚔️"
            body_label.text = _format_defeat_text(data)
            icon_texture.texture = preload("res://ui/icons/defeat.png")
            AudioManager.play_sfx("fanfare_defeat")
        
        ModalType.DEATH:
            title_label.text = "✝️ FALLEN ✝️"
            body_label.text = _format_death_text(data)
            icon_texture.texture = data["portrait"]
            icon_texture.modulate = Color(0.5, 0.5, 0.5)
            AudioManager.play_sfx("bell_toll")
    
    animation_player.play("modal_appear")
    get_tree().paused = true

func _on_continue_pressed() -> void:
    animation_player.play("modal_disappear")
    await animation_player.animation_finished
    visible = false
    get_tree().paused = false
    dismissed.emit()
```

---

*Document Version: 0.7*  
*Last Updated: March 12, 2026*  
*Status: **DESIGN FINALIZED** - Ready for implementation*

### All Decisions Finalized ✅
1. ✅ Portrait style: Card-framed pixel art, 120×160px
2. ✅ Action buttons: Hierarchical 4×4 system (Military/Economy/Diplomacy/System)
3. ✅ Layout: Fixed (no collapsible sections)
4. ✅ Resolution: 1080p + 1440p with scaling support
5. ✅ Resources: 2-column grid, icon + big number
6. ✅ Sidebar width: 560px (intentional - UI is primary, map is decorative)
7. ✅ **Message panel: FULL WIDTH (1920px) × 60-80px at bottom**
8. ✅ Pop-up modals: Center-screen for major events
