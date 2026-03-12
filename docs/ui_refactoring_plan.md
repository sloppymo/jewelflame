# UI System Refactoring Plan

## Executive Summary

Refactor the Jewelflame UI system to eliminate anti-patterns, fix memory leaks, and improve Godot 4.x best practices compliance. Critical fixes include proper scene files, safe signal handling, and multi-resolution support.

---

## Phase 1: Critical Fixes (Must Do)

### 1.1 Convert MessagePanel to Proper .tscn Scene
**Problem:** Dynamic node creation prevents editor debugging
**Solution:** Create full node hierarchy in .tscn file
**Files:** `message_panel.tscn`, `message_panel.gd`

### 1.2 Convert EventModal to Proper .tscn Scene
**Problem:** Logic/script split between game_ui.tscn and event_modal.gd
**Solution:** Create standalone event_modal.tscn
**Files:** `event_modal.tscn`, `event_modal.gd`

### 1.3 Fix Signal Disconnect Pattern
**Problem:** Calling disconnect() on unconnected signal throws error
**Solution:** Check is_connected() before disconnect
**Files:** `sidebar.gd`

### 1.4 Fix Choice Container Memory Leak
**Problem:** queue_free() doesn't immediately remove from tree
**Solution:** Call remove_child() before queue_free()
**Files:** `message_panel.gd`, `event_modal.gd`

---

## Phase 2: Safety & Stability

### 2.1 Add is_instance_valid() Checks
**Problem:** await coroutines crash if node freed
**Solution:** Check validity before accessing self
**Files:** `game_ui.gd`, `message_panel.gd`

### 2.2 Fix Node Path String Formatting
**Problem:** String concatenation for node paths is fragile
**Solution:** Use @export Array[Button] or Dictionary
**Files:** `sidebar.gd`

### 2.3 Fix Input Handling
**Problem:** Clicks on buttons also trigger skip_typing()
**Solution:** Check focus and handle input properly
**Files:** `message_panel.gd`

---

## Phase 3: Architecture Improvements

### 3.1 Implement Pause Stack System
**Problem:** Global pause affects everything, no stacking
**Solution:** Create PauseManager singleton
**Files:** New `pause_manager.gd`

### 3.2 Fix Message Panel Anchoring
**Problem:** Pixel offsets break on different resolutions
**Solution:** Use anchors only
**Files:** `message_panel.tscn`

### 3.3 Add @tool for Editor Preview
**Problem:** Can't preview UI in editor
**Solution:** Add @tool annotation
**Files:** All UI scripts

---

## Phase 4: Quality Improvements

### 4.1 Add Type Safety
**Problem:** Several untyped variables
**Solution:** Add static typing throughout
**Files:** All .gd files

### 4.2 Add Error Handling
**Problem:** No null checks on external resources
**Solution:** Add validation and fallback behavior
**Files:** All .gd files

---

## Implementation Order

1. **Create PauseManager** (dependency for other fixes)
2. **Rebuild MessagePanel** (most complex fix)
3. **Rebuild EventModal** (depends on MessagePanel pattern)
4. **Fix Sidebar** (signal paths, node references)
5. **Fix GameUI** (pause integration, safety checks)
6. **Final Review** (type safety, error handling)

---

## Risk Analysis

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Breaking existing functionality | Medium | High | Test each component after fix |
| Scene file corruption | Low | High | Keep backups |
| Signal connections lost | Medium | Medium | Verify in remote scene tab |
| Performance regression | Low | Low | Profile after changes |

---

## Testing Checklist

- [ ] MessagePanel displays text correctly
- [ ] MessagePanel choices work and clean up properly
- [ ] EventModal shows all event types
- [ ] Sidebar buttons respond to clicks
- [ ] Sidebar section switching works
- [ ] Resource updates reflect in UI
- [ ] Pause/unpause works correctly
- [ ] Input handling doesn't conflict
- [ ] No errors in debugger
- [ ] Works at 1920x1080 and 2560x1440
