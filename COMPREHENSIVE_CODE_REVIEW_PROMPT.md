# PROMPT: Comprehensive Code Review and Bug Detection for Jewelflame Game

You are conducting a **comprehensive code review** of the Jewelflame turn-based strategy game built with Godot 4.x. This is a complete, production-ready game that has undergone iterative development through 4 swarms (Architecture → Implementation → Integration → Polish & Balance).

## PROJECT OVERVIEW

**Jewelflame** is a Gemfire-inspired strategy game featuring:
- Turn-based strategic gameplay with 3 AI families
- Command system with undo/redo functionality  
- Tactical battle transitions with auto-resolution
- Vassal capture and recruitment mechanics
- Professional UI with animations and polish
- Performance optimization targeting 60 FPS

## CODEBASE STRUCTURE

```
Jewelflame/
├── autoload/              # Core game systems (21 autoloads)
│   ├── event_bus.gd      # Global signal system
│   ├── game_state.gd      # Game state management
│   ├── turn_manager.gd    # Turn-based phase system
│   ├── command_history.gd # Command pattern with undo/redo
│   ├── enhanced_ai_controller.gd # AI decision making
│   ├── battle_resolver.gd # Combat calculations
│   ├── vassal_system_integration.gd # Lord capture/recruitment
│   ├── game_balance_config.gd # Balance parameters
│   ├── performance_optimizer.gd # Performance monitoring
│   ├── ui_enhancer.gd     # UI polish and animations
│   └── content_polisher.gd # Victory screens, help system
├── resources/             # Data models and configurations
│   ├── data_classes/      # LordData, UnitData, BattleData, etc.
│   └── game_balance_config.gd # Balance tuning
├── scenes/               # UI and game scenes
│   ├── main.tscn         # Main scene container
│   ├── strategic_map.tscn # Strategic gameplay
│   └── tactical_battle.tscn # Battle system
├── strategic/            # Strategic layer systems
│   ├── commands/         # Command pattern implementation
│   ├── ai/              # AI decision making
│   ├── economy/         # Resource management
│   └── map/             # Strategic map rendering
├── tactical/             # Battle system
│   └── battlefield/      # Tactical combat
├── battle/               # Combat resolution
└── tests/                # Comprehensive test suite
```

## CRITICAL AREAS TO REVIEW

### **1. Core Game Systems**
- **TurnManager**: Turn phase transitions, AI processing
- **GameState**: Data persistence, save/load functionality
- **CommandHistory**: Undo/redo implementation, state management
- **BattleResolver**: Combat calculations, balance integration

### **2. AI System**
- **EnhancedAIController**: Personality-based decision making
- **GameBalanceConfig**: AI difficulty tuning and parameters
- **Strategic Analysis**: Province evaluation, target selection

### **3. Combat & Battle System**
- **BattleData**: Tactical battle data structure
- **BattlefieldController**: Scene transitions, unit placement
- **VassalSystem**: Lord capture, recruitment, loyalty mechanics

### **4. UI/UX Systems**
- **UIEnhancer**: Animations, tooltips, keyboard navigation
- **SceneManager**: Scene transitions, state preservation
- **ContentPolisher**: Victory screens, help system

### **5. Performance & Optimization**
- **PerformanceOptimizer**: Frame rate monitoring, memory management
- **Object Pooling**: Efficient resource usage
- **AI Processing**: Batch processing for speed

## SPECIFIC BUG PATTERNS TO CHECK

### **Signal Connection Issues**
- Missing signal declarations in EventBus
- Unconnected signal handlers
- Signal parameter mismatches
- Double connections causing memory leaks

### **Null Reference Errors**
- GameState.get_province() without null checks
- Scene node access without validation
- AI controller initialization failures
- Command execution with invalid targets

### **State Management Bugs**
- Turn phase state corruption
- Command undo/redo state inconsistency
- Save/load data serialization errors
- AI decision state conflicts

### **Performance Issues**
- Inefficient AI processing loops
- Memory leaks in object pooling
- Excessive signal emissions
- Scene transition bottlenecks

### **Balance & Logic Errors**
- Combat calculation formula errors
- AI decision logic contradictions
- Resource management inconsistencies
- Victory condition failures

## CODE REVIEW METHODOLOGY

### **Phase 1: Static Analysis**
1. **Syntax Validation**: Check all GDScript files for syntax errors
2. **Dependency Analysis**: Verify all autoloads and class references
3. **Signal Audit**: Ensure all signals are properly declared and connected
4. **Resource Validation**: Check scene files and asset references

### **Phase 2: Logic Review**
1. **Game Flow**: Trace complete turn cycle execution
2. **AI Decision Making**: Verify AI logic and balance integration
3. **Combat System**: Validate battle calculations and outcomes
4. **Command System**: Check undo/redo state management

### **Phase 3: Integration Testing**
1. **Scene Transitions**: Test strategic to tactical battle flow
2. **AI vs AI**: Verify complete AI game cycles
3. **Save/Load**: Test game state persistence
4. **Performance**: Monitor frame rate and memory usage

### **Phase 4: Edge Case Analysis**
1. **Error Conditions**: Null inputs, invalid commands
2. **Boundary Cases**: Maximum units, minimum resources
3. **Concurrent Operations**: Multiple simultaneous actions
4. **Memory Pressure**: Extended gameplay sessions

## SPECIFIC FILES TO EXAMINE

### **High Priority**
- `autoload/turn_manager.gd` - Core game flow
- `autoload/enhanced_ai_controller.gd` - AI decision making
- `strategic/commands/command_history.gd` - Command pattern
- `battle/battle_resolver.gd` - Combat calculations
- `autoload/event_bus.gd` - Signal system

### **Medium Priority**
- `autoload/game_state.gd` - Data persistence
- `strategic/commands/base_command.gd` - Command interface
- `autoload/vassal_system_integration.gd` - Vassal mechanics
- `tactical/battlefield/battlefield_controller.gd` - Battle UI
- `resources/game_balance_config.gd` - Balance parameters

### **Low Priority**
- `autoload/ui_enhancer.gd` - UI polish
- `autoload/performance_optimizer.gd` - Performance monitoring
- `autoload/content_polisher.gd` - Victory screens
- Test files and documentation

## COMMON GODOT-SPECIFIC ISSUES

### **Scene Tree Issues**
- Nodes not in expected groups
- Scene loading timing problems
- Node path changes after instancing
- Scene transition state loss

### **Resource Management**
- Resource reference cycles
- Improper resource unloading
- Scene instance memory leaks
- Asset path resolution

### **Signal System**
- Signal connection timing
- Parameter type mismatches
- Double connection prevention
- Signal cleanup on scene change

### **Autoload Dependencies**
- Initialization order dependencies
- Circular autoload references
- Missing autoload configurations
- Cross-autoload communication

## OUTPUT EXPECTATIONS

### **Bug Report Format**
For each issue found, provide:
```
**BUG [Severity]: Brief Description**
- **Location**: File path and line number
- **Issue**: Detailed explanation of the problem
- **Impact**: How it affects gameplay
- **Fix**: Recommended solution
- **Priority**: Critical/High/Medium/Low
```

### **Categories**
- **Critical**: Game crashes, unplayable states
- **High**: Major gameplay disruption
- **Medium**: Noticeable issues, workarounds exist
- **Low**: Minor annoyances, cosmetic issues

### **Summary Statistics**
- Total bugs found by severity
- Most problematic files
- Common bug patterns
- Recommended fix priorities

## VALIDATION CRITERIA

### **Game Functionality**
- Complete turn cycle works end-to-end
- AI opponents make intelligent decisions
- Commands execute and undo correctly
- Battles transition and resolve properly
- Save/load preserves game state

### **Performance Standards**
- Maintains 60 FPS during normal gameplay
- Memory usage stays under 200MB
- AI turns complete in under 2 seconds
- Scene transitions under 500ms

### **Code Quality**
- No syntax errors or warnings
- Proper error handling throughout
- Consistent coding patterns
- Comprehensive documentation

### **Balance Validation**
- AI win rates within 40-60% range
- Resource economy balanced and playable
- Combat outcomes logical and fair
- Victory conditions achievable

## DELIVERABLE

Provide a **comprehensive bug report** covering:
1. **Executive Summary** - Overall code quality assessment
2. **Critical Issues** - Game-breaking bugs requiring immediate fixes
3. **High Priority Issues** - Major gameplay problems
4. **Medium/Low Issues** - Minor improvements and polish
5. **Recommendations** - Code quality improvements and best practices
6. **Validation Results** - Test outcomes and performance metrics

Focus on **actionable feedback** that will improve the game's stability, performance, and player experience. The goal is to ensure this production-ready game meets professional quality standards.

---

**CONTEXT**: This game has completed 4 development swarms and is considered production-ready, but a fresh expert review is needed to catch any remaining issues before final deployment.
