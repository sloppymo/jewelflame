# Jewelflame - Strategic Province Management Game

## Overview
Jewelflame is a turn-based strategy game focused on province management, resource allocation, and tactical decision-making. This implementation includes both Part 1 (core systems) and Part 2 (complete game loop).

## Features Implemented

### Core Systems (Part 1)
- **Resource Management**: Gold, food, soldiers, and development stats
- **Province Control**: 5 unique provinces with different terrain types
- **Family System**: 3 competing families with distinct colors and AI personalities
- **Character Management**: Rulers and lords with leadership stats
- **Save/Load System**: Persistent game state using JSON serialization

### Strategic Map (Part 1)
- **Interactive Hexagonal Map**: Click provinces to view details
- **Fog of War**: Enemy troop counts hidden unless adjacent
- **Visual Feedback**: Color-coded ownership, selection highlighting, exhaustion overlays
- **Province Panel**: Dynamic UI showing stats and available actions

### Command System (Part 1)
- **Recruit Troops**: 50 soldiers for 100 gold
- **Develop Land**: Improve cultivation or protection for 10 gold
- **Exhaustion System**: One action per province per turn
- **Cost Validation**: Prevents actions without sufficient resources

### Game Loop (Part 2)
- **Turn Management**: Sequential family turns with month/year progression
- **AI Opponents**: Three distinct personalities (aggressive, defensive, opportunistic)
- **Battle Resolution**: Realistic combat with terrain bonuses and casualties
- **Economic Cycles**: Monthly upkeep, September harvest, random events
- **Victory Conditions**: Conquer all provinces or elimination

### Advanced Features (Part 2)
- **Intelligent AI**: Personality-driven decision making with risk assessment
- **Battle System**: Power calculations, terrain modifiers, loot mechanics
- **Economy**: Food consumption, desertion, harvest yields based on cultivation
- **Random Events**: Disasters (flood, plague, fire, snow) and positive events
- **Animated Combat**: Attack arrows and province capture effects
- **Comprehensive UI**: Battle reports, harvest summaries, turn indicators

## Game Setup

### Provinces
1. **Dunmoor** (Red) - Blanche capital, plains terrain
2. **Carveti** (Green) - Blanche territory, plains terrain  
3. **Cobrige** (Blue) - Lyle capital, woods terrain
4. **Banshea** (Yellow) - Lyle territory, woods terrain
5. **Petaria** (Magenta) - Coryll capital, river terrain

### Families
- **Blanche** (Royal Blue) - Player family, defensive AI
- **Lyle** (Crimson) - Aggressive AI opponent
- **Coryll** (Forest Green) - Opportunistic AI opponent

### Characters
- **Erin** - Blanche ruler (high charm)
- **Ander** - Lyle ruler (high command)
- **Lars** - Coryll ruler (high leadership)
- **Lord Carveti** - Blanche governor
- **Lord Banshea** - Lyle governor

## How to Play

1. **Start Game**: Run project in Godot
2. **Player Turn**: Select provinces, recruit troops, develop land, attack enemies
3. **End Turn**: Click button to advance to AI families
4. **AI Turns**: Watch opponents make intelligent decisions with 1.5s delays
5. **Battle Reports**: View detailed combat results with casualties and loot
6. **Economic Management**: Monitor food consumption and September harvests
7. **Victory**: Conquer all 5 provinces or eliminate all rivals

## Controls
- **Left Click**: Select province
- **Recruit Troops**: Add 50 soldiers for 100 gold
- **Develop Land**: Improve cultivation/protection for 10 gold
- **Attack**: Launch assaults on adjacent enemy provinces
- **End Turn**: Advance to next family's turn
- **Save/Load**: Access through console commands

## AI Personalities

### Aggressive (Lyle)
- **Attack Threshold**: 0.8 strength ratio
- **Risk Tolerance**: 1.0 (moderate)
- **Behavior**: Attacks when advantage, recruits large armies, focuses on conquest

### Defensive (Player - Blanche)
- **Attack Threshold**: 1.2 strength ratio
- **Risk Tolerance**: 2.0 (cautious)
- **Behavior**: Defends when threatened, maintains strong garrisons, develops protection

### Opportunistic (Coryll)
- **Attack Threshold**: 1.0 strength ratio
- **Risk Tolerance**: 1.5 (balanced)
- **Behavior**: Attacks isolated targets, balanced economy development

## Battle Mechanics

### Power Calculation
```
Power = Soldiers × (Command/50) × Terrain × Defense × Random(0.8-1.2)
```

### Terrain Bonuses
- **Plains**: 1.0x (no bonus)
- **Woods**: 1.2x (defensive advantage)
- **River**: 1.1x (moderate defense)
- **Mountain**: 1.3x (strong defense)

### Casualties
- **Winner**: 0-40% losses based on fight dominance
- **Loser**: 60-80% losses
- **Defender Bonus**: Additional 1.1x multiplier

### Conquest Mechanics
- **Province Transfer**: Ownership changes immediately
- **Loot**: 30% of defender's gold and food transferred
- **Prisoners**: 20% chance to capture enemy governor
- **Exhaustion**: Attacker marked as exhausted after battle

## Economic System

### Monthly Upkeep
- **Food Cost**: 1 food per 10 soldiers per month
- **Desertion**: 2× food deficit in soldiers lost if starving
- **Loyalty Penalty**: -10 loyalty for supply shortages

### September Harvest
- **Formula**: `Yield = Cultivation × 2 × (Loyalty/100)`
- **Benefit**: Only affects player-owned provinces for UI display
- **Report**: Comprehensive summary of all province yields

### Random Events
- **Disasters** (5% monthly): Flood, Plague, Fire, Snow
- **Positive Events** (10% on develop): Unicorn, Leprechaun, Gwraig
- **Effects**: Temporary stat modifications and resource changes

## Technical Architecture

### Autoloads
- `EventBus`: Global signal system
- `GameState`: Runtime state and turn management
- `SaveManager`: JSON persistence
- `CommandProcessor`: Action validation
- `MilitaryCommands`: Recruitment and movement
- `DomesticCommands`: Development and trade
- `AIController`: AI decision making and turn execution
- `BattleResolver`: Combat calculations and resolution
- `HarvestSystem`: September harvest processing
- `EconomyManager`: Monthly upkeep and desertion
- `RandomEvents`: Disaster and positive event system

### File Structure
```
res://
├── autoload/           # Global singletons
├── resources/
│   ├── data_classes/   # Resource class definitions
│   └── instances/     # Game data (provinces, families, characters)
├── strategic/
│   ├── ai/           # AI personality and control systems
│   ├── commands/      # Game action validation and execution
│   ├── economy/       # Harvest and upkeep systems
│   ├── map/          # Map rendering and interaction
│   └── random_events.gd # Random event system
├── battle/            # Battle resolution mechanics
├── ui/               # User interface components
└── assets/           # Art and media assets
```

## Testing

Run validation script to verify project integrity:
```bash
python3 validate_part2.py
```

## Development Notes
- Built with Godot 4.6
- Complete game loop with AI opponents
- Modular architecture for easy extension
- Preserves Part 1 save compatibility
- Animated combat feedback and comprehensive UI
- Intelligent AI with personality-driven behavior

## Next Steps
- Enhanced battle animations and sound effects
- More complex random events and quests
- Diplomacy system between families
- Multiplayer support
- Campaign scenarios and custom maps
