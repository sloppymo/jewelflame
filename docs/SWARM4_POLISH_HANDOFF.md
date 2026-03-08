# PROMPT: Iteration Swarm — Polish & Balance Pass Phase

You are the Conductor for **Jewelflame Polish & Balance Swarm Gamma**. You are NOT implementing new features—you are POLISHING, BALANCING, and OPTIMIZING the complete working game from Swarm 3.

## CONTEXT FROM PREVIOUS SWARM (Swarm 3 - Systems Integration)

### Complete Game Status: ✅ FULLY PLAYABLE
- **AI Opponents**: Lyle (Aggressive) & Coryll (Opportunistic) making intelligent decisions
- **Command System**: Player can execute Attack/Recruit/Develop with undo/redo
- **Tactical Battles**: Scene transitions with auto-resolution and unit placement
- **Vassal System**: Lord capture, recruitment, loyalty, and desertion mechanics
- **Complete Loop**: Turn-based gameplay with all phases working

### Working Features (All Tested & Functional):
```gdscript
# Core Gameplay (Verified Working)
- Turn cycle: Player → AI Lyle → AI Coryll → Month advance
- AI decisions: Attacks, recruitments, developments based on personality
- Player commands: Attack provinces, recruit troops, develop land
- Tactical battles: Trigger from attacks, show results, return to map
- Vassal system: Capture lords (20% chance), recruit (100 gold), loyalty changes
- Resource management: Gold, food, mana with monthly cycles
- Save/load: JSON persistence with all complex state

# Integration Points (All Connected)
- TurnManager ↔ Enhanced AI Controller ↔ Command History
- Strategic Map ↔ SceneManager ↔ Tactical Battle
- Battle Resolver ↔ Vassal System ↔ GameState
- All systems communicating via EventBus signals
```

### Current Game Balance (Needs Polish):
- **AI Attack Thresholds**: Lyle 70%, Coryll 100% (may need adjustment)
- **Recruitment Costs**: 50 troops for 100 gold (may need balancing)
- **Battle Casualties**: 20-40% winner, 60-80% loser (may need tuning)
- **Loyalty Mechanics**: Desertion at <30 loyalty (may need refinement)
- **Victory Conditions**: Conquer all provinces (may need additional options)

### Performance Metrics (Baseline):
- **71 GDScript files** total system
- **Turn cycle time**: ~3-4 seconds per family
- **Battle resolution**: ~1 second
- **Memory usage**: Baseline established
- **Scene transitions**: <1 second

## VERIFICATION STATUS (Confirmed Working):
- [x] Complete AI vs AI game cycles functional
- [x] Player commands execute and persist
- [x] Tactical battle transitions work end-to-end
- [x] Lord capture and recruitment complete
- [x] Save/load handles complex game state
- [x] All integration tests passing

## YOUR SWARM (4 Agents, Parallel where possible):

### **Agent A: Game Balance & Tuning**
- Task: Balance AI difficulty, combat mechanics, and economy. Make game challenging but fair.
- Constraint: Use existing AI personalities and combat formulas. Only adjust numerical values.
- Deliverable: Balanced game where AI provides good challenge without being overwhelming.

### **Agent B: UI/UX Polish**  
- Task: Enhance user interface with better visual feedback, tooltips, and smooth transitions.
- Constraint: Maintain existing scene structure. Only improve presentation and usability.
- Deliverable: Polished UI with clear information hierarchy and professional appearance.

### **Agent C: Performance Optimization**
- Task: Optimize turn processing, battle calculations, and memory usage. Target 60 FPS.
- Constraint: Do not change game mechanics. Only improve execution efficiency.
- Deliverable: Smooth performance with faster AI turns and reduced memory footprint.

### **Agent D: Content & Features Polish**
- Task: Add visual polish, sound effects, victory screens, and quality-of-life improvements.
- Constraint: Use existing systems. Only enhance presentation and add finishing touches.
- Deliverable: Production-ready feel with animations, effects, and complete user experience.

## CONDUCTOR (You):

After Agents A-D report:
1. Run complete balance test (10 AI vs AI cycles)
2. Measure performance improvements
3. Validate UI/UX enhancements
4. Test complete polished experience
5. Create final build and documentation

## SUCCESS CRITERIA:
- **Balance**: AI provides challenging but fair gameplay (win rate ~40-60%)
- **Performance**: Turn cycles complete in <2 seconds, 60 FPS maintained
- **UI/UX**: Professional appearance with clear information and smooth interactions
- **Polish**: Complete package with animations, effects, and satisfying feedback
- **Stability**: No crashes or memory leaks in extended play sessions

## BALANCE TARGETS:
- **AI Win Rates**: Lyle ~55%, Coryll ~45%, Player ~50% (balanced)
- **Game Length**: 20-40 turns for complete game (engaging but not tedious)
- **Resource Economy**: Strategic decisions matter, but recovery possible
- **Combat**: Tactics matter, but numbers aren't overwhelming
- **Vassal System**: Meaningful choices without being overpowered

## PERFORMANCE TARGETS:
- **Turn Processing**: <2 seconds per AI family
- **Battle Resolution**: <500ms for auto-resolve
- **Memory Usage**: <200MB peak
- **Scene Transitions**: <500ms with smooth fade
- **Frame Rate**: Solid 60 FPS during all gameplay

## POLISH REQUIREMENTS:
- **Visual Feedback**: All actions have clear visual indicators
- **Sound Design**: Appropriate audio for all interactions
- **Animations**: Smooth transitions and unit movements
- **Information**: Clear display of all relevant game state
- **Professional Feel**: Consistent styling and presentation

## CONSTRAINTS:
- DO NOT add new game mechanics or features
- DO NOT change core AI personalities or decision structures
- MUST maintain save/load compatibility
- ALL changes must enhance existing functionality

## TESTING REQUIREMENTS:
- Balance test: 10 complete AI vs AI games
- Performance test: 1 hour continuous play
- UX test: Complete player experience from start to victory
- Stress test: Maximum units and lords on map
- Compatibility test: Save/load with all features

---

**IMPLEMENTATION PRIORITY:**
1. Game Balance & Tuning (Agent A)
2. Performance Optimization (Agent C)
3. UI/UX Polish (Agent B)
4. Content & Features Polish (Agent D)
5. Conductor final integration and validation

**DELIVERABLE: Production-ready Jewelflame game with balanced gameplay, smooth performance, and professional polish.**
