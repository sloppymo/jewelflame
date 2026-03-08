# Jewelflame Technical Architecture Summary

## Overview
This document provides a complete technical blueprint for implementing **Jewelflame**, a Gemfire (SNES 1991) clone in Godot 4.x with enhanced two-layer combat, vassalage system, and modern AI architecture.

## Architecture Highlights

### 1. Enhanced Data Models
- **LordData**: Extended character system with loyalty, capture mechanics, and Gemfire-specific stats
- **UnitData**: Four base unit types + 5th special unit slot with formations and experience
- **BattleData**: Comprehensive tactical battle data structure with weather and terrain effects
- **ProvinceData**: Enhanced with unit composition, mana resources, and weather systems

### 2. Two-Layer Scene Architecture
- **Strategic Map Scene**: Hex-based province management with lord roster and command categories
- **Tactical Battle Scene**: Side-view animated combat with formations and special abilities
- **Scene Transition System**: Seamless switching with state preservation and fade effects

### 3. Advanced State Management
- **Turn Phase System**: Family selection → Lord commands → Battle resolution → Events → Upkeep
- **Command Pattern**: Full undo/redo support with validation and state preservation
- **Enhanced AI**: Personality-driven decision making for both strategic and tactical layers

### 4. Core Systems Integration

#### Vassalage System
- Lord loyalty mechanics with desertion chances
- Capture/recruit/banish/release options after battles
- Family affiliation and loyalty drift over time

#### Resource Management
- Three-pillar economy: Gold/Food/Mana
- Transport logistics between provinces
- Monthly upkeep and seasonal harvest cycles

#### Combat System
- **Strategic Layer**: Province attacks with force allocation
- **Tactical Layer**: Side-view battles with formations and terrain
- **Auto-Resolution**: Quick combat for AI vs AI or player preference

## Key Technical Decisions

### Data-Driven Design
- Godot `Resource` classes for all data definitions
- JSON serialization for save/load system
- Scriptable objects for unit types and AI personalities

### Modular Architecture
- Separate autoloads for each major system
- Command pattern for player actions with undo/redo
- Event-driven communication via EventBus

### AI Architecture
- **Strategic AI**: Personality-based decision making (Aggressive/Defensive/Opportunistic)
- **Tactical AI**: Formation selection and target prioritization
- **Utility AI**: Score-based decision making with configurable weights

### Performance Considerations
- Object pooling for battle effects
- Lazy loading of large assets
- Efficient hex grid rendering with culling

## Implementation Strategy

### Phase 1: Strategic Foundation (4-6 weeks)
1. Enhanced data models and core systems
2. Strategic map with Gemfire mechanics
3. Lord management and recruitment
4. Command system with undo/redo
5. Enhanced AI personalities

### Phase 2: Tactical Foundation (3-4 weeks)
1. Tactical battle scene structure
2. Scene transition system
3. Auto-resolution combat
4. Formation mechanics
5. Battle results processing

### Phase 3: Full Tactical Combat (4-5 weeks)
1. Turn-based combat flow
2. Unit animations and effects
3. Special ability system
4. Tactical AI decision making
5. Complete UI integration

### Phase 4: Advanced Features (3-4 weeks)
1. Special units (5th slot)
2. Unit abilities and spells
3. Advanced AI strategies
4. Diplomatic system
5. Campaign scenarios

## File Structure Summary

```
res://
├── autoload/              # 15 core singletons
├── resources/             # Data classes and instances
├── strategic/             # Strategic layer systems
├── tactical/              # Tactical battle systems
├── ui/                    # User interface components
├── audio/                 # Sound and music
├── assets/                # Visual assets
├── tests/                 # Testing framework
└── docs/                  # Documentation
```

## Autoload Architecture

### Core Systems
- `EventBus`: Global signal communication
- `GameState`: Turn and state management
- `SceneManager`: Scene transitions
- `CommandHistory`: Undo/redo system

### Game Systems
- `VassalSystem`: Lord management
- `WeatherSystem`: Environmental effects
- `FormationSystem`: Battle formations
- `TacticalBattleManager`: Combat control

### AI Systems
- `AIController`: Existing strategic AI
- `EnhancedAIController`: Personality-driven AI
- `TacticalAIController`: Battle decision making

## UI Architecture

### Strategic UI Panels
- **Lord Roster**: Character portraits and stats
- **Command Categories**: Domestic/Diplomatic/Military tabs
- **Province Info**: Resource and unit details
- **Intelligence Views**: One/Many/Land/5th Unit displays

### Tactical UI Panels
- **Formation Panel**: Battle formation selection
- **Unit Status**: Real-time unit information
- **Battle Log**: Combat event history
- **Results Panel**: Victory/defeat outcomes

## AI Personality System

### Personality Types
- **Aggressive (Lyle)**: Low attack threshold, high recruitment
- **Defensive (Blanche)**: High defense, cautious expansion
- **Opportunistic (Coryll)**: Balanced, targets weak provinces
- **Tactical**: Adaptive formations, strategic targeting

### Decision Layers
1. **Strategic**: Province selection and resource allocation
2. **Operational**: Army composition and movement
3. **Tactical**: Formation selection and target prioritization

## Battle System Flow

### Strategic to Tactical Transition
1. Player initiates province attack
2. Battle data assembled with units and commanders
3. Scene transition with fade effect
4. Tactical battlefield initialized
5. Combat executed with formations and abilities
6. Results processed and applied
7. Return to strategic map with updated state

### Auto-Resolution Path
1. Quick strength calculation
2. Terrain and commander bonuses applied
3. Random factor for unpredictability
4. Casualties calculated
5. Province ownership updated
6. Loot and prisoners processed

## Save System Architecture

### Data Serialization
- All game state stored in JSON format
- Resource classes implement to_dict()/from_dict()
- Command history preserved for undo functionality
- Battle state saved mid-combat

### Compatibility
- Backward compatible with existing saves
- Version migration system
- Validation and error recovery

## Performance Optimizations

### Rendering
- Viewport culling for off-screen provinces
- LOD system for unit sprites
- Particle pooling for effects

### Calculations
- Cached combat results
- Lazy AI evaluation
- Efficient pathfinding

### Memory Management
- Resource pooling for battles
- Asset unloading between scenes
- Garbage collection optimization

## Testing Strategy

### Unit Tests
- Data model validation
- Command execution and undo
- AI decision logic
- Battle calculations

### Integration Tests
- Complete game flow scenarios
- Save/load functionality
- Scene transitions
- Multi-turn simulations

### Performance Tests
- Memory usage profiling
- Frame rate benchmarks
- Loading time measurements
- AI calculation performance

## Success Metrics

### Gameplay Metrics
- AI provides challenging opposition
- Game mechanics match Gemfire feel
- Combat system is engaging
- UI is intuitive and responsive

### Technical Metrics
- 60 FPS on minimum specifications
- < 2 second scene transitions
- < 100MB memory usage
- < 5 second save/load times

### Quality Metrics
- 90%+ code test coverage
- Zero critical bugs in release
- Comprehensive documentation
- Maintainable code architecture

## Next Steps

1. **Immediate**: Begin Phase 1 implementation with data models
2. **Week 2**: Set up enhanced autoload structure
3. **Month 1**: Complete strategic foundation
4. **Month 2**: Implement tactical battles
5. **Month 3**: Polish and optimization
6. **Month 4**: Advanced features and testing

This architecture provides a solid foundation for a faithful Gemfire clone with modern enhancements, maintainable code structure, and room for future expansion.
