# DESIGN_GAPS.md - Jewelflame Game Design Analysis

## Mechanics That Exist But Fail to Engage

### 1. Defense Development ("Defend" Command)

**Current Implementation:** `ui/sidebar.gd:288-304`, `resources/data_classes/province_data.gd:26-28`

**The Math:**
- Cost scales as `200 * 1.5^(level-1)`: 200 → 300 → 450 → 675 → 1012 gold
- Defense bonus: `1.0 + (level-1) * 0.2`: 1.0 → 1.2 → 1.4 → 1.6 → 1.8 multiplier

**The Problem:** A level 5 defense costs **2,637 total gold** for an 80% defensive bonus. With starting gold of 800 and income of ~100-150/turn, this requires ~20 turns of investment. However:
- Attacks happen every 2-3 turns
- Troop recruitment (100 gold = 10 troops) provides immediate defense
- 1,000 gold spent on troops = 100 troops = more raw power than defense levels

**Why Players Ignore It:** No feedback loop shows defense value. The 1.8x multiplier is invisible during battles—players see troop counts, not calculated power.

**Quick Fix:** Add a pre-battle preview showing:
```
"Estimated Power: 200 troops × 1.8 defense = 360 effective strength"
```
in the sidebar.

---

### 2. Scout Command

**Current Implementation:** `ui/sidebar.gd:306-313` (stub only)

**The Gap:** UI button exists, handler switches to `SELECT_SOURCE` mode, but:
- No fog of war system actually hides information
- `_execute_scout()` reveals nothing that isn't already visible
- No cost, no risk, no meaningful decision

**Why It Fails:** Gemfire's scouting revealed hidden enemy troop movements and hidden lords. Without hidden information, scouting has no purpose.

**Fix Options:**
- **A)** Implement fog of war (hides enemy troops in non-adjacent provinces)
- **B)** Remove the button until tactical battles integrate
- **C)** Make scouting reveal AI's next predicted move (requires AI lookahead)

---

### 3. AI Without Personality

**Current Implementation:** `autoload/ai_manager.gd:6-9`

**The Promise:** README mentions Aggressive/Defensive/Opportunistic personalities

**The Reality:** Single hardcoded threshold for all AI:
```gdscript
const ATTACK_ADVANTAGE_THRESHOLD := 1.5  # All factions use this
```

**Why It Matters:** Players can't learn AI patterns or exploit weaknesses. Lyle (blue, expansionist in lore) and Coryll (red, aggressive) behave identically.

**The Fix:**
```gdscript
# strategic/ai/ai_personalities.gd (exists but unused)
const PERSONALITIES := {
    "lyle": {"attack_threshold": 1.2, "recruit_bias": 1.5, "expansion_focus": true},
    "coryll": {"attack_threshold": 0.9, "recruit_bias": 0.8, "aggression_bonus": 20}
}
```

---

### 4. Events Without Consequence

**Current Implementation:** `autoload/event_manager.gd:40-64`

**The Events:**
- **Trade Flourishing:** +50 gold, +10 income (permanent!)
- **Plague:** -25% troops (one-time)
- **Bountiful Harvest:** +100 gold (one-time)
- **Bandit Raid:** -20% troops (one-time)
- **Mercenary Arrival:** +30 troops (one-time)

**The Problem:** No event chain, no choice, no lasting impact. Trade Flourishing is strictly positive (always good), Plague is strictly negative (unavoidable). No risk/reward tradeoffs.

**Gemfire Comparison:** Events in Gemfire often presented choices ("Bandits demand tribute—pay 100g or fight?").

**Fix:** Add binary choice events:
```gdscript
# New event type
EVENT_MERCENARY_OFFER: {
    "message": "Mercenaries offer services. Pay 150g for 50 troops?",
    "choices": [
        {"text": "Hire", "gold": -150, "troops": 50},
        {"text": "Refuse", "prestige": -5}  # Could affect vassal recruitment
    ]
}
```

---

## Missing Systems Blocking Strategic Depth

### 5. No Food/Starvation System

**Claimed In:** Old README

**Reality:** Only gold economy exists (`faction.gold`)

**Impact:** Provinces can sustain infinite troops with zero infrastructure. No supply lines to cut, no sieges to starve out defenders. Combat is purely about troop count × defense bonus.

**Implementation Blocker:** Would require:
- Troop consumption per turn
- Province food production/storage
- Supply line pathfinding between provinces
- UI to display food metrics

**Dependency:** HexForge pathfinder could calculate supply routes (needs integration).

---

### 6. No 5th Unit (Creatures/Monsters)

**Current State:** Button exists in sidebar (`ui/sidebar.tscn`), no creature database

**Gemfire Context:** The 5th unit slot was for special creatures (dragons, elementals) with unique abilities. Added asymmetry and faction identity.

**Implementation Path:**
1. Define creature types in `resources/data_classes/creature_data.gd`
2. Add capture mechanics in tactical battles
3. Create creature assignment UI in sidebar
4. Add creature combat bonuses in CombatResolver

**Effort:** Medium (2-3 days). Requires tactical battle integration first.

---

### 7. No Vassal/Lord System

**Current State:** `strategic/commands/recruit_vassal_command.gd` exists but disconnected

**The Gap:** ProvinceData has no `governor_id` field linked to characters. Characters exist as a data class but aren't instantiated.

**Gemfire Comparison:** Lords provided:
- Combat bonuses (attack/defense ratings)
- Province management bonuses
- Capture/ransom mechanics
- Succession drama

**Implementation Blocker:** Requires character instantiation in GameState and UI to display lord info.

---

### 8. No Fog of War

**Claimed In:** Old README

**Reality:** All province data visible to all players

**Impact:** No information asymmetry means no bluffing, no surprise attacks, no need for scouting. Player sees AI troop counts exactly.

**Technical Challenge:** Requires:
- Visibility tracking per faction
- Conditional rendering in ProvinceNode
- Server authoritative visibility (for multiplayer) or deterministic AI vision rules

**Quick Win:** Start with "adjacent visibility only"—hide non-adjacent province troop counts.

---

### 9. No Terrain Combat Modifiers

**Current State:** `ProvinceData.terrain_type` field exists but unused

**CombatResolver Formula:**
```gdscript
var defense_power := target.troops * target.get_defense_bonus()
# get_defense_bonus() only uses defense_level, ignores terrain
```

**Missed Opportunity:** Forest/mountain defense bonuses would make terrain control strategically valuable.

**Implementation:**
```gdscript
# province_data.gd
func get_terrain_defense_bonus() -> float:
    match terrain_type:
        "forest": return 0.3
        "mountain": return 0.5
        "plains": return 0.0
    return 0.0
```

---

## Quick-Win UX Improvements

### 10. Sidebar Information Hierarchy

**Current Issues:**
- Province name in gold (hard to read on bright backgrounds)
- No visual distinction between owned/enemy provinces
- Event message panel dominates vertical space

**Fixes (No Code Required):**
- Add faction-colored border to portrait frame
- Move province name to banner texture background
- Reduce event panel height from 220px to 150px
- Add troop delta indicators (+/- from last turn)

---

### 11. Missing Combat Preview

**Current State:** Player clicks Attack → combat resolves immediately

**Gemfire Context:** Original showed attacker vs defender power comparison before confirming.

**Implementation:**
```gdscript
# sidebar.gd - before executing attack
func _show_attack_preview(source: ProvinceData, target: ProvinceData):
    var attack_power = source.troops
    var defense_power = target.troops * target.get_defense_bonus()
    
    show_event_message(
        "Attack Preview:\n" +
        "Your Power: %d\n" % attack_power +
        "Enemy Power: %d (%.1fx)\n" % [defense_power, target.get_defense_bonus()] +
        "Odds: %s" % ("Favorable" if attack_power > defense_power * 1.2 else "Risky")
    )
```

---

### 12. Turn End Without Confirmation

**Current State:** Spacebar or EndTurnBtn immediately ends turn

**The Problem:** Misclicks are punishing—AI takes multiple actions while player watches helplessly.

**Fix:** Add confirmation dialog when actions remain:
```gdscript
# turn_manager.gd
func end_player_turn():
    var remaining_actions = _get_remaining_actions()  # Unmoved troops, unspent gold
    if remaining_actions > 0:
        # Show confirmation UI
        return
    # ... proceed with turn end
```

---

### 13. No Battle History

**Current State:** Battles resolve, result shown in message panel, then gone

**Gemfire Context:** Original had "Battle Reports" view showing history of conflicts

**Implementation:** Add battle log to GameState:
```gdscript
# game_state.gd
var battle_history: Array[BattleRecord] = []

func record_battle_result(result):
    battle_history.append(result)
    battle_recorded.emit(result)
```
Then add "View History" button to sidebar.

---

## Priority Ranking (Effort vs Impact)

| Fix | Effort | Impact | Priority |
|-----|--------|--------|----------|
| Combat Preview | 2 hrs | High | **1** |
| AI Personalities | 4 hrs | High | **2** |
| Defense Value Feedback | 2 hrs | Medium | **3** |
| Terrain Bonuses | 4 hrs | Medium | **4** |
| Event Choices | 6 hrs | High | **5** |
| Fog of War (Basic) | 8 hrs | High | **6** |
| Food System | 3 days | Very High | **7** |
| Lord System | 4 days | Very High | **8** |
| 5th Unit | 3 days | Medium | **9** |

---

## Design Philosophy Recommendation

The codebase has solid fundamentals (turn state machine, combat resolver, event system) but lacks **feedback loops**—mechanics that show players the consequences of their decisions.

### Immediate Focus:
1. **Make defense upgrades visible** in combat previews
2. **Give AI distinct personalities** so players can learn patterns
3. **Add basic fog of war** to make scouting meaningful

These three changes would transform Jewelflame from a "click troops, win game" experience to one with genuine strategic decisions.

---

*Analysis completed from codebase review on 2026-03-12*
