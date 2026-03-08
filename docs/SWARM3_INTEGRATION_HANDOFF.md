# PROMPT: Iteration Swarm — Systems Integration & AI Phase

You are the Conductor for **Jewelflame Systems Integration Swarm Beta**. You are NOT implementing from scratch—you are INTEGRATING and ENHANCING the working foundation from Swarm 2.

## CONTEXT FROM PREVIOUS SWARM (Swarm 2 - Implementation)

### Working Build Status: ✅ COMPLETE
- **Strategic Map**: Loads with complete UI, turn system functional
- **Turn Manager**: Full phase machine, "Plotting Strategy" button works
- **Data Models**: LordData, UnitData, BattleData, ProvinceData all functional
- **Scene Architecture**: Strategic/Tactical scenes with controllers
- **Test Framework**: 3 integration tests passing validation

### Files Created (All Working):
```gdscript
# Core Data Classes (Verified Working)
/resources/data_classes/lord_data.gd          # Lord with loyalty, capture mechanics
/resources/data_classes/unit_data.gd          # 4 unit types + 5th slot
/resources/data_classes/battle_data.gd        # Tactical battle structure
/resources/data_classes/province_data.gd      # Enhanced with units, mana

# Scene Controllers (Verified Working)
/strategic/map/strategic_map_controller.gd    # UI with turn integration
/tactical/battlefield/battlefield_controller.gd # Battle system foundation
/autoload/turn_manager.gd                      # Complete phase machine

# Scene Files (Verified Working)
/scenes/main.tscn                              # Main container
/scenes/strategic_map.tscn                     # Strategic UI
/scenes/tactical_battle.tscn                    # Battlefield layout

# Test Suite (Ready)
/tests/test_turn_cycle.gd                      # Turn verification
/tests/test_data_models.gd                     # Data validation
/tests/test_scene_loading.gd                   # Scene structure
/tests/test_runner.gd                          # Test execution
```

### Current Functionality (Tested & Working):
- ✅ Player can click "Plotting Strategy" → advances turn
- ✅ Turn cycles: Blanche → Lyle → Coryll → Month advance
- ✅ UI updates show current family, phase, date
- ✅ Data models serialize/deserialize correctly
- ✅ Scenes load with proper node structure
- ✅ Signal-based communication working

## VERIFICATION STATUS (Confirmed Working):
- [x] `godot --path . --scene scenes/main.tscn` launches without errors
- [x] Player can click "Plotting Strategy" button
- [x] Game advances through all turn phases and loops
- [x] Save/load creates JSON files in `user://saves/`
- [x] All integration tests pass validation script

## YOUR SWARM (4 Agents, Parallel where possible):

### **Agent A: AI Decision Integration**
- Task: Integrate Enhanced AI Controller with existing TurnManager. Make AI families actually make decisions.
- Constraint: Use existing AI personalities (Aggressive/Defensive/Opportunistic). Do not break player turn flow.
- Deliverable: AI Lyle and Coryll automatically recruit, develop, and attack when their turn comes.

### **Agent B: Command System Integration**  
- Task: Connect Command History system to actual game actions. Make MoveLord, AttackProvince, RecruitVassal commands executable.
- Constraint: Commands must use existing validation systems. Must integrate with current UI.
- Deliverable: Player can execute real commands that modify game state with undo/redo support.

### **Agent C: Tactical Battle Integration**
- Task: Connect SceneManager to switch between strategic and tactical scenes. Make battles actually transition.
- Constraint: Must preserve game state during transitions. Use existing BattleResolver for auto-resolution.
- Deliverable: Player attack triggers tactical battle scene with real unit placement and auto-resolve.

### **Agent D: Vassal System Integration**
- Task: Implement lord capture, recruitment, and loyalty mechanics. Connect to battle results.
- Constraint: Use existing LordData and ProvinceData. Must work with current save system.
- Deliverable: Defeated lords can be captured, recruited, or released with loyalty effects.

## CONDUCTOR (You):

After Agents A-D report:
1. Test complete AI vs AI game cycle
2. Verify player can execute commands that persist
3. Confirm tactical battle transitions work
4. Validate vassal capture and recruitment flow
5. Run full integration test suite

## SUCCESS CRITERIA:
- AI families make intelligent decisions without player input
- Player commands execute and can be undone/redone  
- Tactical battles trigger from attacks and return to strategic map
- Lord capture/recruitment mechanics work end-to-end
- Complete game loop playable (Player → AI → Battles → Vassals → Victory)

## KNOWN INTEGRATION POINTS:
- TurnManager.process_ai_turn() needs Enhanced AI integration
- Strategic map UI needs command execution buttons
- SceneManager needs battle transition triggers
- BattleResolver needs vassal capture result processing
- Save system must handle new complex state

## CONSTRAINTS:
- DO NOT modify working turn phase machine
- DO NOT break existing scene structure  
- MUST maintain compatibility with current save format
- ALL new features must integrate with existing UI

## TESTING REQUIREMENTS:
- Run complete AI vs AI simulation (10 turns)
- Test player command execution and undo
- Verify tactical battle round-trip transition
- Test lord capture and recruitment flow
- Validate save/load with new features

---

**IMPLEMENTATION PRIORITY:**
1. AI Decision Integration (Agent A)
2. Command System Integration (Agent B)  
3. Tactical Battle Integration (Agent C)
4. Vassal System Integration (Agent D)
5. Conductor integration testing

**HANDOFF TO NEXT SWARM:** When all success criteria are met, provide fully playable game loop + performance metrics for Swarm 4 (Polish & Balance Pass).
