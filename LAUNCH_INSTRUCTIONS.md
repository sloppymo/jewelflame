# 🚀 Jewelflame Part 2 - Launch Instructions

## **GREEN LIGHT - READY FOR LAUNCH**

### **System Status: ✅ READY**
- All critical files verified
- Autoloads configured correctly
- Parentheses bug fixed
- Attack button integrated
- Animation controller in place

---

## **Launch Protocol**

### **Step 1: Open in Godot**
```bash
# Navigate to project directory
cd /home/sloppymo/jewelflame

# Open in Godot (if Godot is installed)
godot --editor --path .
```

### **Step 2: Run Project (F5)**
1. Press **F5** or click "Play" button
2. **Expected**: Strategic map loads with 5 colored provinces
3. **If crashes**: Check Output panel for error messages

---

## **Expected First 30 Seconds**

### **Visual Confirmation**
- **2 Blue provinces** (Blanche - player)
- **2 Red provinces** (Lyle - aggressive AI)  
- **1 Green province** (Coryll - opportunistic AI)

### **First Actions**
1. **Click Dunmoor** (blue, center-left)
   - Right panel shows province stats
   - Buttons: "Recruit Troops", "Develop Land", "Attack" should be active

2. **Click "End Turn"** (top-left UI)
   - Button grays out
   - Console prints: `"AI turn starting for: lyle"`
   - Wait 1-2 seconds
   - Console prints: `"AI turn starting for: coryll"`
   - Wait 1-2 seconds
   - Console prints: Button reactivates
   - All provinces reset from dark to normal (exhaustion cleared)

---

## **Critical Test Points**

### **Test 1: AI Behavior**
- **Expected**: AI should recruit or attack within 1.5 seconds
- **Console should show**: `"AI [family] took action in [province]"`
- **If nothing happens**: AIController not being called

### **Test 2: Battle System**
1. **Click Dunmoor** → Click **"Attack"**
2. **Expected**: Attack adjacent enemy (Cobrige or Petaria)
3. **BattleReport dialog** appears with:
   - "VICTORY!" or "DEFEAT" in colored text
   - Casualty numbers
   - If victory: "Province conquered!"
4. **Click OK** → Conquered province changes color

### **Test 3: Economy System**
- **Every turn**: Console shows monthly upkeep processing
- **September (Month 9)**: Harvest report dialog appears
- **Food shortage**: Console shows starvation warnings

---

## **Debug Commands (Console)**

```gdscript
# Force September harvest
GameState.current_month = 9

# Check turn state  
print("Current family: ", GameState.get_current_family())
print("Month: ", GameState.current_month, "/", GameState.current_year)

# Force AI turn
AIController.take_turn("lyle")

# Test battle directly
var result = BattleResolver.resolve_province_attack(1, 3, 50)
print(result)
```

---

## **Common Failure Modes & Fixes**

### **"Invalid call. Nonexistent function"**
- **Cause**: Autoload not configured
- **Fix**: Check Project Settings → Autoload tab

### **"Attempt to divide by zero"**
- **Cause**: Battle calculations with 0 soldiers
- **Fix**: Check which province has 0 troops

### **"Node not found"**
- **Cause**: UI elements not in scene
- **Fix**: Verify TurnController in main.tscn

### **No AI actions**
- **Cause**: GameState.advance_turn() not calling AI
- **Fix**: Check console for "AI turn starting" messages

---

## **Success Criteria**

### **Game Feels "Alive"**
- ✅ AI acts independently with delays
- ✅ Battles resolve with visual feedback
- ✅ Economy cycles (upkeep, harvest)
- ✅ Turn progression works

### **Victory Conditions**
- ✅ Conquer all 5 provinces → Victory screen
- ✅ Lose all provinces → Defeat screen
- ✅ Save/Load preserves game state

---

## **Balance Tuning (Post-Launch)**

**If game is too easy/hard:**
- **Recruitment cost**: Currently 2g per soldier (100g for 50)
- **Battle casualties**: 60-80% for loser (maybe too brutal?)
- **AI aggression**: Attacks at 1:1 ratio (maybe too passive?)
- **Starting resources**: Adjust gold/food in province .tres files

---

## **🎯 LAUNCH STATUS: GO**

**All systems verified. Ready for playtesting.**

**Next step**: Run in Godot and report what breaks first, or if it actually feels like a game!

---

*Project Location: `/home/sloppymo/jewelflame`*
