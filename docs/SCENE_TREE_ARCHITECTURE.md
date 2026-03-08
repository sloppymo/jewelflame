# Jewelflame Scene Tree Architecture
# Two-Layer Combat System Design

## Strategic Map Scene (strategic_map.tscn)
```
StrategicMap (Node2D)
├── Camera2D
├── UI_Layer (CanvasLayer)
│   ├── TopBar (HBoxContainer)
│   │   ├── TurnIndicator (Label)
│   │   ├── DateDisplay (Label)
│   │   └── EndTurnButton (Button)
│   ├── LeftPanel (VBoxContainer)
│   │   ├── LordRoster (ScrollContainer)
│   │   │   └── LordList (VBoxContainer)
│   │   ├── CommandCategories (TabContainer)
│   │   │   ├── DomesticCommands (VBoxContainer)
│   │   │   ├── DiplomaticCommands (VBoxContainer)
│   │   │   └── MilitaryCommands (VBoxContainer)
│   │   └── PlottingStrategyButton (Button)
│   ├── RightPanel (VBoxContainer)
│   │   ├── ProvinceInfo (Panel)
│   │   ├── IntelligencePanel (TabContainer)
│   │   │   ├── ViewOne (Panel)
│   │   │   ├── ViewMany (Panel)
│   │   │   ├── ViewLand (Panel)
│   │   │   └── View5thUnit (Panel)
│   │   └── MiniMap (Panel)
│   └── ModalLayer (CanvasLayer)
│       ├── BattleReport (Panel)
│       ├── HarvestReport (Panel)
│       ├── VassalRecruitment (Panel)
│       └── EventNotifications (Panel)
├── Map_Layer (Node2D)
│   ├── ProvinceAreas (Node2D)
│   │   ├── Province01 (Polygon2D)
│   │   ├── Province02 (Polygon2D)
│   │   └── ...
│   ├── ProvinceLabels (Node2D)
│   ├── ProvinceHighlights (Node2D)
│   ├── FogOfWar (Node2D)
│   └── WeatherEffects (Node2D)
├── Animation_Layer (Node2D)
│   ├── AttackArrows (Node2D)
│   ├── ProvinceCaptureEffects (Node2D)
│   └── WeatherAnimations (Node2D)
└── Audio_Layer (Node)
    ├── MusicPlayer (AudioStreamPlayer)
    ├── SoundEffects (Node)
    │   ├── AttackSound (AudioStreamPlayer)
    │   ├── MoveSound (AudioStreamPlayer)
    │   └── NotificationSound (AudioStreamPlayer)
    └── AmbientSounds (AudioStreamPlayer)
```

## Tactical Battle Scene (tactical_battle.tscn)
```
TacticalBattle (Node2D)
├── Camera2D
├── UI_Layer (CanvasLayer)
│   ├── TopBar (HBoxContainer)
│   │   ├── BattleStatus (Label)
│   │   ├── RoundCounter (Label)
│   │   └── AutoResolveButton (Button)
│   ├── BottomPanel (HBoxContainer)
│   │   ├── FormationPanel (Panel)
│   │   ├── UnitStatus (Panel)
│   │   └── BattleLog (ScrollContainer)
│   └── ModalLayer (CanvasLayer)
│       ├── BattleResults (Panel)
│       ├── VassalCaptureDialog (Panel)
│       └── LootDistribution (Panel)
├── Battlefield_Layer (Node2D)
│   ├── Background (Sprite2D)
│   ├── TerrainFeatures (Node2D)
│   │   ├── Hills (Sprite2D)
│   │   ├── Trees (Sprite2D)
│   │   └── Rivers (Sprite2D)
│   ├── WeatherEffects (Node2D)
│   └── LightingEffects (Node2D)
├── Unit_Layer (Node2D)
│   ├── AttackerUnits (Node2D)
│   │   ├── UnitSprite1 (AnimatedSprite2D)
│   │   ├── UnitSprite2 (AnimatedSprite2D)
│   │   └── ...
│   ├── DefenderUnits (Node2D)
│   │   ├── UnitSprite1 (AnimatedSprite2D)
│   │   ├── UnitSprite2 (AnimatedSprite2D)
│   │   └── ...
│   └── UnitMarkers (Node2D)
├── Animation_Layer (Node2D)
│   ├── CombatAnimations (Node2D)
│   ├── ProjectileEffects (Node2D)
│   ├── ExplosionEffects (Node2D)
│   └── SpellEffects (GPUParticles2D)
└── Audio_Layer (Node)
    ├── BattleMusic (AudioStreamPlayer)
    ├── CombatSounds (Node)
    │   ├── SwordClash (AudioStreamPlayer)
    │   ├── ArrowFire (AudioStreamPlayer)
    │   ├── SpellCast (AudioStreamPlayer)
    │   └── UnitDeath (AudioStreamPlayer)
    └── VoiceOvers (AudioStreamPlayer)
```

## Enhanced Autoload Singletons
```
Autoload Configuration (project.godot)
├── EventBus (Global signal system)
├── GameState (Turn and state management)
├── SaveManager (JSON serialization)
├── SceneManager (Scene transitions)
├── CommandProcessor (Action validation)
├── TacticalBattleManager (Tactical combat control)
├── VassalSystem (Lord management and recruitment)
├── WeatherSystem (Weather and environmental effects)
├── FormationSystem (Battle formation mechanics)
├── AIController (Strategic and tactical AI)
├── BattleResolver (Combat calculations)
├── EconomyManager (Resource management)
├── HarvestSystem (Seasonal resource generation)
├── RandomEvents (Dynamic events system)
└── AudioManager (Sound and music management)
```

## Scene Transition Flow
```
Strategic Map
    ↓ [Province Attack Click]
Battle Preparation Dialog
    ↓ [Confirm Attack]
Load Tactical Battle Scene
    ↓ [Battle Complete]
Battle Results Dialog
    ↓ [Vassal Recruitment Choice]
Return to Strategic Map
    ↓ [Update Province States]
Continue Strategic Turn
```

## UI Component Specifications

### Strategic Map UI
- **TopBar**: 1920x80px, shows current turn, date, and end turn button
- **LeftPanel**: 300x1080px, lord roster and command categories
- **RightPanel**: 400x1080px, province info and intelligence views
- **ModalLayer**: Overlay for reports and dialogs

### Tactical Battle UI  
- **TopBar**: 1920x100px, battle status and controls
- **BottomPanel**: 1920x200px, formations and unit status
- **Battlefield**: 1920x780px, main combat area
- **ModalLayer**: Battle results and vassal capture dialogs

## Node Type Recommendations

### Containers
- **HBoxContainer/VBoxContainer**: For UI layout
- **TabContainer**: For command categories and intelligence views
- **ScrollContainer**: For lists and logs
- **Panel**: For grouping UI elements

### Interactive Elements
- **Button**: All clickable actions
- **Label**: Static text displays
- **RichTextLabel**: Formatted text (battle logs, reports)
- **ProgressBar**: Resource indicators, loyalty meters

### Visual Elements
- **Polygon2D**: Province shapes on strategic map
- **AnimatedSprite2D**: Unit sprites in tactical battles
- **GPUParticles2D**: Weather and spell effects
- **Sprite2D**: Static visual elements

### Audio
- **AudioStreamPlayer**: Music and sound effects
- **AudioStreamPlayer2D**: Positional audio (battle sounds)
