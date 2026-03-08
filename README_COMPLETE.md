# 🎮 Jewelflame - Complete Game Documentation

## 📋 Table of Contents
1. [Game Overview](#game-overview)
2. [Installation Guide](#installation-guide)
3. [How to Play](#how-to-play)
4. [Game Mechanics](#game-mechanics)
5. [AI Personalities](#ai-personalities)
6. [Strategic Tips](#strategic-tips)
7. [Technical Details](#technical-details)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 Game Overview

**Jewelflame** is a complete turn-based strategy game inspired by Gemfire (SNES 1991), built with Godot 4.x. Players take on the role of a family leader competing for control of the realm.

### Key Features
- **Turn-based strategic gameplay** with province management
- **AI opponents** with distinct personalities and strategies
- **Tactical battle system** with auto-resolution
- **Vassal system** with lord capture and recruitment
- **Resource management** (Gold, Food, Mana)
- **Professional UI** with animations and tooltips
- **Victory conditions** and end-game content

### Victory Conditions
Conquer **4 out of 5 provinces** to achieve victory and rule the realm!

---

## 🚀 Installation Guide

### Requirements
- **Godot 4.x** (4.2 or later recommended)
- **Operating System**: Windows, macOS, or Linux
- **Memory**: 4GB RAM minimum
- **Storage**: 100MB available space

### Installation Steps
1. **Download Godot** from [godotengine.org](https://godotengine.org)
2. **Extract** the Jewelflame project files
3. **Open** `project.godot` in Godot Editor
4. **Press F5** or click "Play" to start the game

### Quick Start
- The game will open to the strategic map
- You control the **Blanche family** (blue)
- Click **"Plotting Strategy"** to advance turns
- Use command buttons to execute actions

---

## 🎮 How to Play

### Basic Controls
- **Mouse**: Click to select provinces and buttons
- **Enter**: Confirm actions
- **Escape**: Cancel actions or close dialogs
- **Tab**: Navigate between UI elements
- **Space**: Alternative confirm button

### Game Flow
1. **Your Turn**: Select provinces and execute commands
2. **AI Turns**: Watch Lyle and Coryll make their moves
3. **Battle Resolution**: Automatic tactical battles occur
4. **Monthly Upkeep**: Resources and loyalty are processed
5. **Repeat**: Continue until victory conditions are met

### Main Actions
- **Attack Province**: Conquer adjacent enemy territories
- **Recruit Troops**: Build military strength (50 troops for 90 gold)
- **Develop Land**: Improve economy (8 gold per development)

---

## ⚙️ Game Mechanics

### Resource Management
- **Gold**: Used for recruitment and development
- **Food**: Consumed by troops monthly
- **Mana**: Used for special abilities and spells
- **Loyalty**: Lord allegiance (0-100, affects desertion)

### Combat System
- **Terrain Bonuses**: Plains (1.0x), Woods (1.15x), River (1.08x), Mountain (1.25x)
- **Commander Bonus**: Based on lord's command rating
- **Casualties**: Winners lose 15-35%, Losers lose 55-75%
- **Lord Capture**: 18% chance to capture enemy governor

### Vassal System
- **Capture**: Lords can be captured in battle
- **Recruitment**: Pay 80 gold to recruit captured lords
- **Loyalty**: Captured lords start with 20 loyalty
- **Desertion**: Lords may desert if loyalty < 25

### AI Personalities
- **Lyle (Aggressive)**: Attacks at 75% strength, high recruitment
- **Coryll (Opportunistic)**: Attacks isolated targets, balanced approach
- **Blanche (Player)**: Defensive posture, strong development

---

## 🤖 AI Personalities

### Lyle - The Aggressor
- **Attack Strategy**: Seeks weakest targets
- **Economic Focus**: Heavy military spending
- **Risk Tolerance**: Willing to take calculated risks
- **Win Rate**: ~55% (balanced for challenge)

### Coryll - The Opportunist
- **Attack Strategy**: Exploits isolated provinces
- **Economic Focus**: Balanced military and development
- **Risk Tolerance**: Moderate risk assessment
- **Win Rate**: ~45% (provides good challenge)

### AI Decision Making
- **Strategic Analysis**: Evaluates all provinces each turn
- **Target Selection**: Based on personality and opportunity
- **Resource Allocation**: Optimized for family strengths
- **Adaptive Behavior**: Responds to player actions

---

## 💡 Strategic Tips

### Early Game
1. **Secure Borders**: Develop border provinces first
2. **Build Economy**: Focus on cultivation for long-term growth
3. **Recruit Wisely**: Balance military with economic needs
4. **Monitor AI**: Watch for expansion opportunities

### Mid Game
1. **Expand Carefully**: Attack when you have clear advantage
2. **Capture Lords**: Build your vassal army through captures
3. **Maintain Loyalty**: Keep lord loyalty above 50 to prevent desertion
4. **Resource Management**: Maintain positive food balance

### Late Game
1. **Final Push**: Coordinate attacks for decisive victories
2. **Defend Holdings**: Protect conquered territories
3. **Economic Victory**: Outproduce opponents if military stalled
4. **Diplomacy**: Use captured lords to strengthen position

### Combat Tips
- **Terrain Advantage**: Attack from favorable terrain
- **Commander Selection**: Use high-command lords for attacks
- **Force Balance**: Don't attack with overwhelming force (wasteful)
- **Retreat**: Know when to pull back from bad positions

---

## 🔧 Technical Details

### Architecture
- **Engine**: Godot 4.x with GDScript
- **Pattern**: Component-based with autoload singletons
- **State Management**: Turn-based phase system
- **Save System**: JSON-based persistence

### Performance
- **Target FPS**: 60 frames per second
- **Memory Usage**: Under 200MB peak
- **Turn Processing**: Under 2 seconds per AI family
- **Scene Transitions**: Smooth <500ms transitions

### File Structure
```
Jewelflame/
├── autoload/           # Core game systems (21 files)
├── resources/          # Game configuration (7 files)
├── scenes/            # UI and game scenes (19 files)
├── strategic/         # Strategic layer systems
├── tactical/          # Battle system
├── battle/            # Combat resolution
├── tests/             # Test suite (6 files)
└── docs/              # Documentation
```

### Key Systems
- **TurnManager**: Handles turn phases and AI processing
- **CommandHistory**: Manages undo/redo functionality
- **BattleResolver**: Calculates combat outcomes
- **VassalSystem**: Manages lord capture and recruitment
- **PerformanceOptimizer**: Maintains smooth gameplay

---

## 🐛 Troubleshooting

### Common Issues

**Game Won't Start**
- Ensure you're using Godot 4.x (not 3.x)
- Check that `project.godot` is the main scene
- Verify all autoload scripts are present

**Performance Issues**
- Close other applications to free memory
- Check if Godot is using integrated graphics
- Reduce game window size if needed

**AI Not Responding**
- Wait 1-2 seconds for AI decision processing
- Check if provinces are exhausted (can't act)
- Verify AI families have available resources

**Save/Load Problems**
- Ensure write permissions in game directory
- Check available disk space
- Verify save file integrity

### Getting Help
- **In-Game Help**: Press "?" button for contextual help
- **Keyboard Shortcuts**: ESC to cancel, Enter to confirm
- ** tooltips**: Hover over UI elements for information

### Performance Optimization
- **Frame Rate**: Game auto-adjusts quality if FPS drops
- **Memory**: Automatic cleanup every 5 seconds
- **AI Speed**: Batch processing for faster turns

---

## 📚 Additional Resources

### Development Documentation
- **Technical Architecture**: See `docs/TECHNICAL_ARCHITECTURE_SUMMARY.md`
- **Implementation Roadmap**: See `docs/IMPLEMENTATION_ROADMAP.md`
- **API Reference**: See `docs/API_REFERENCE.md`

### Testing
- **Integration Tests**: Run `tests/enhanced_test_runner.gd`
- **Balance Validation**: Check `GameBalanceConfig.validate_balance()`
- **Performance Report**: Use `PerformanceOptimizer.get_performance_report()`

### Modding
- **Balance Tweaks**: Modify `resources/game_balance_config.gd`
- **AI Personalities**: Adjust values in `GameBalanceConfig.AI_BALANCE`
- **Victory Conditions**: Edit `GameBalanceConfig.GAME_PACE_BALANCE`

---

## 🏆 Credits

### Development
- **Concept**: Gemfire (SNES 1991) inspired gameplay
- **Engine**: Godot 4.x
- **Architecture**: Iterative Swarm Development Method
- **Testing**: Comprehensive integration test suite

### Features
- **AI System**: Personality-based decision making
- **Combat**: Balanced tactical battles
- **UI/UX**: Professional polish with animations
- **Performance**: Optimized for smooth gameplay

---

## 📄 License

This project is provided as a complete example of game development using the iterative swarm methodology. Feel free to learn from, modify, and expand upon this foundation.

---

**Enjoy your complete Jewelflame gaming experience! 🎮**

*Last Updated: Production Release v1.0*
