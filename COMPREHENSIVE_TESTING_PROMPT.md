# Comprehensive Game Testing Prompt

You are tasked with comprehensively testing the Jewelflame game to validate all critical fixes have been properly implemented. This is a thorough testing suite to verify stability, performance, and functionality.

## Testing Objectives

### Primary Goals
1. **Validate Critical Stability Fixes** - Ensure no crashes, null references, or error handling issues
2. **Verify Performance Optimizations** - Confirm AI processing limits and memory management
3. **Test Code Quality Improvements** - Validate dependency injection and input validation
4. **Check Gameplay Integration** - Ensure all systems work together seamlessly

## Phase 1: Stability Testing

### 1.1 Null Safety Validation
**Test SafeAccess Utility:**
```gdscript
# Test in debug console:
print("Testing SafeAccess...")

# Test invalid province access
var invalid_province = SafeAccess.get_enhanced_province_safe(999)
print("Invalid province result: ", invalid_province)

# Test valid province access
var valid_province = SafeAccess.get_enhanced_province_safe(1)
print("Valid province result: ", valid_province != null)

# Test character access
var character = SafeAccess.get_enhanced_character_safe("char_erin")
print("Character access result: ", character != null)

# Test safe getters
if valid_province:
    print("Province soldiers: ", SafeAccess.safe_get_province_soldiers(valid_province))
    print("Province gold: ", SafeAccess.safe_get_province_gold(valid_province))
```

**Expected Results:**
- Invalid province returns null with error message
- Valid province returns proper data
- No crashes or null reference errors

### 1.2 Error Handling Validation
**Test ErrorHandler Utility:**
```gdscript
# Test error creation
var error = ErrorHandler.create_error(ErrorHandler.ErrorType.INVALID_PROVINCE, "Test error")
print("Error created: ", error.success, " - ", error.message)

# Test success creation
var success = ErrorHandler.create_success({"test": "data"})
print("Success created: ", success.success, " - ", success.data)

# Test error handling
var result = ErrorHandler.handle_invalid_province(999, "test")
print("Handled error: ", ErrorHandler.get_error_message(result))
```

**Expected Results:**
- All error types create properly formatted responses
- Success responses contain expected data
- Error messages are user-friendly

### 1.3 Scene Transition Testing
**Test SceneManager Memory Management:**
```gdscript
# Test scene transitions
print("Testing scene transitions...")

# Get initial memory
var initial_memory = PerformanceOptimizer.get_current_memory_mb()
print("Initial memory: ", initial_memory, " MB")

# Force multiple scene transitions
for i in range(5):
    print("Transition ", i + 1)
    # Simulate scene transition (call SceneManager methods)
    await get_tree().process_frame
    
    # Check memory after transition
    var current_memory = PerformanceOptimizer.get_current_memory_mb()
    print("Memory after transition ", i + 1, ": ", current_memory, " MB")

print("Scene transition testing complete")
```

**Expected Results:**
- Memory returns to baseline after transitions
- No orphaned nodes or memory leaks
- Smooth transitions without crashes

## Phase 2: Performance Testing

### 2.1 AI Processing Validation
**Test AI Performance Limits:**
```gdscript
# Test AI processing time
print("Testing AI performance...")

if has_node("/root/Strategic/AIController"):
    var ai_controller = get_node("/root/Strategic/AIController")
    
    # Test AI turn processing
    var start_time = Time.get_ticks_msec()
    
    # Process AI turn for each family
    for family_id in ["blanche", "lyle", "coryll"]:
        print("Processing AI for: ", family_id)
        await ai_controller.take_turn(family_id)
        
        var end_time = Time.get_ticks_msec()
        var processing_time = end_time - start_time
        print("AI processing time for ", family_id, ": ", processing_time, "ms")
        
        # Verify within 100ms limit
        assert(processing_time <= 100, "AI processing exceeded 100ms limit!")
    
    # Get performance data
    var perf_data = ai_controller.get_ai_performance_data()
    print("AI Performance Data: ", perf_data)
```

**Expected Results:**
- All AI turns complete within 100ms
- Performance data is properly tracked
- No frame rate drops during AI processing

### 2.2 Memory Management Testing
**Test Resource Cleanup:**
```gdscript
# Test aggressive cleanup
print("Testing memory management...")

var before_cleanup = PerformanceOptimizer.get_current_memory_mb()
print("Memory before cleanup: ", before_cleanup, " MB")

# Trigger aggressive cleanup
await PerformanceOptimizer.aggressive_cleanup()

var after_cleanup = PerformanceOptimizer.get_current_memory_mb()
print("Memory after cleanup: ", after_cleanup, " MB")
print("Memory freed: ", before_cleanup - after_cleanup, " MB")

# Test performance monitoring
var report = PerformanceOptimizer.get_performance_report()
print("Performance Report: ", report)

# Verify memory trends
var trend = PerformanceOptimizer.get_memory_trend()
print("Memory trend: ", trend)
```

**Expected Results:**
- Aggressive cleanup frees measurable memory
- Performance report contains detailed metrics
- Memory trends are properly tracked

## Phase 3: Code Quality Testing

### 3.1 Dependency Injection Validation
**Test ServiceContainer:**
```gdscript
# Test service container
print("Testing dependency injection...")

# Test service registration
var services = ServiceContainer.get_registered_services()
print("Registered services: ", services)

# Test service access
var game_state = ServiceContainer.get_enhanced_game_state()
print("Game State service: ", game_state != null)

var error_handler = ServiceContainer.get_error_handler()
print("Error Handler service: ", error_handler != null)

# Test service validation
var validation = ServiceContainer.validate_service_dependencies()
print("Service validation: ", validation.valid)
if not validation.valid:
    print("Missing services: ", validation.missing_services)
    print("Null services: ", validation.null_services)
```

**Expected Results:**
- All core services are registered
- Service access works properly
- Dependency validation passes

### 3.2 Input Validation Testing
**Test InputValidator:**
```gdscript
# Test input validation
print("Testing input validation...")

# Test province validation
var valid_province = InputValidator.validate_province_id(1)
print("Valid province: ", ErrorHandler.is_success(valid_province))

var invalid_province = InputValidator.validate_province_id(999)
print("Invalid province: ", ErrorHandler.is_success(invalid_province))

# Test character validation
var valid_character = InputValidator.validate_character_id("char_erin")
print("Valid character: ", ErrorHandler.is_success(valid_character))

var invalid_character = InputValidator.validate_character_id("")
print("Invalid character: ", ErrorHandler.is_success(invalid_character))

# Test command validation
var attack_command = {
    "type": "attack",
    "attacker_id": 1,
    "defender_id": 2,
    "attack_force": 100
}
var command_result = InputValidator.validate_single_command(attack_command)
print("Attack command validation: ", ErrorHandler.is_success(command_result))

# Test batch validation
var commands = [attack_command]
var batch_result = InputValidator.validate_command_batch(commands)
print("Batch validation: ", batch_result.success, " - Valid: ", batch_result.valid_commands, "/", batch_result.total_commands)
```

**Expected Results:**
- Valid inputs pass validation
- Invalid inputs are caught with proper errors
- Batch validation processes multiple commands correctly

## Phase 4: Gameplay Integration Testing

### 4.1 Command System Testing
**Test Command Execution:**
```gdscript
# Test command system
print("Testing command system...")

# Create and test attack command
var attack_cmd = AttackProvinceCommand.new(1, 2, [], "char_erin")
print("Attack command created: ", attack_cmd != null)

# Test command validation
var can_execute = attack_cmd.can_execute()
print("Can execute attack: ", ErrorHandler.is_success(can_execute))

# Test safe execution
if ErrorHandler.is_success(can_execute):
    var execute_result = attack_cmd.safe_execute()
    print("Attack execution: ", ErrorHandler.is_success(execute_result))
    
    # Test undo if executed
    if attack_cmd.is_executed:
        var undo_result = attack_cmd.undo()
        print("Attack undo: ", ErrorHandler.is_success(undo_result))
```

**Expected Results:**
- Commands create and validate properly
- Safe execution wrapper works correctly
- Undo functionality operates without errors

### 4.2 Battle System Testing
**Test Battle Resolution:**
```gdscript
# Test battle system
print("Testing battle system...")

# Test battle resolution with valid data
var battle_result = BattleResolver.resolve_province_attack(1, 2, 100)
print("Battle resolution: ", ErrorHandler.is_success(battle_result))

if ErrorHandler.is_success(battle_result):
    var result_data = battle_result.data
    print("Battle result data: ", result_data)
    
    # Verify required fields
    assert(result_data.has("attacker_won"), "Missing attacker_won field")
    assert(result_data.has("attacker_casualties"), "Missing attacker_casualties field")
    assert(result_data.has("defender_casualties"), "Missing defender_casualties field")

# Test battle with invalid data
var invalid_battle = BattleResolver.resolve_province_attack(999, 2, 100)
print("Invalid battle result: ", not ErrorHandler.is_success(invalid_battle))
```

**Expected Results:**
- Valid battles resolve with complete data
- Invalid battles are handled gracefully
- All required result fields are present

## Phase 5: Stress Testing

### 5.1 Extended Gameplay Test
**Test Long-term Stability:**
```gdscript
# Test extended gameplay
print("Starting extended gameplay test...")

var test_duration_minutes = 5  # Adjust as needed
var start_time = Time.get_ticks_msec()
var end_time = start_time + (test_duration_minutes * 60 * 1000)

var frame_count = 0
var error_count = 0

while Time.get_ticks_msec() < end_time:
    # Simulate game loop
    await get_tree().process_frame
    frame_count += 1
    
    # Check for errors every 60 frames
    if frame_count % 60 == 0:
        var current_memory = PerformanceOptimizer.get_current_memory_mb()
        var current_fps = PerformanceOptimizer.get_current_fps()
        
        print("Frame ", frame_count, " - Memory: ", current_memory, "MB - FPS: ", current_fps)
        
        # Check for performance issues
        if current_memory > 200:  # 200MB threshold
            error_count += 1
            print("WARNING: High memory usage detected!")
        
        if current_fps < 30:  # 30 FPS threshold
            error_count += 1
            print("WARNING: Low FPS detected!")

var total_time = Time.get_ticks_msec() - start_time
print("Extended test complete:")
print("- Duration: ", total_time / 1000, " seconds")
print("- Total frames: ", frame_count)
print("- Average FPS: ", frame_count / (total_time / 1000))
print("- Errors detected: ", error_count)
```

**Expected Results:**
- Game remains stable for extended periods
- Memory usage stays within acceptable limits
- Frame rate remains stable
- No crashes or error accumulation

### 5.2 Rapid Action Testing
**Test System Under Load:**
```gdscript
# Test rapid command execution
print("Testing rapid command execution...")

var commands = []
for i in range(10):
    commands.append({
        "type": "attack",
        "attacker_id": 1,
        "defender_id": 2,
        "attack_force": 50 + i * 10
    })

# Test batch validation
var batch_result = InputValidator.validate_command_batch(commands)
print("Batch validation: ", batch_result.valid_commands, "/", batch_result.total_commands, " valid")

# Execute commands rapidly
for i in range(commands.size()):
    var cmd = commands[i]
    print("Executing command ", i + 1, ": ", cmd.type)
    
    # Simulate command processing
    await get_tree().create_timer(0.1).timeout
    
    # Check system health
    var memory = PerformanceOptimizer.get_current_memory_mb()
    var fps = PerformanceOptimizer.get_current_fps()
    
    if memory > 150 or fps < 45:
        print("WARNING: Performance degradation at command ", i + 1)

print("Rapid action test complete")
```

**Expected Results:**
- System handles rapid actions without degradation
- Memory and FPS remain stable under load
- All commands validate and execute properly

## Validation Checklist

### Critical Success Criteria
- [ ] **No crashes** during any test phase
- [ ] **Null safety** - All SafeAccess calls work without errors
- [ ] **Error handling** - All errors are properly formatted and handled
- [ ] **AI performance** - All AI turns complete within 100ms
- [ ] **Memory management** - Memory returns to baseline after cleanup
- [ ] **Dependency injection** - All services accessible through ServiceContainer
- [ ] **Input validation** - All invalid inputs caught and handled
- [ ] **Command system** - Commands execute and undo correctly
- [ ] **Battle system** - Battles resolve with complete data
- [ ] **Extended stability** - Game stable for 5+ minutes
- [ ] **Performance under load** - System handles rapid actions

### Performance Benchmarks
- **Memory Usage**: < 150MB stable during gameplay
- **AI Turn Time**: < 100ms per family
- **Frame Rate**: Stable 60 FPS during all activities
- **Scene Transition**: < 2 seconds with proper cleanup

### Error Handling Validation
- **Null References**: Zero null reference errors
- **Invalid Data**: All invalid inputs caught with proper messages
- **System Recovery**: Game continues gracefully from errors
- **User Feedback**: Clear, actionable error messages

## Automated Test Script

Create this test script and run it to validate all fixes:

```gdscript
# test_all_fixes.gd
extends Node

func _ready():
    print("=== Jewelflame Comprehensive Test Suite ===")
    await test_null_safety()
    await test_error_handling()
    await test_performance()
    await test_dependency_injection()
    await test_input_validation()
    await test_gameplay_integration()
    print("=== Test Suite Complete ===")

async func test_null_safety():
    print("\n1. Testing Null Safety...")
    # Implementation from Phase 1.1

async func test_error_handling():
    print("\n2. Testing Error Handling...")
    # Implementation from Phase 1.2

async func test_performance():
    print("\n3. Testing Performance...")
    # Implementation from Phase 2

async func test_dependency_injection():
    print("\n4. Testing Dependency Injection...")
    # Implementation from Phase 3.1

async func test_input_validation():
    print("\n5. Testing Input Validation...")
    # Implementation from Phase 3.2

async func test_gameplay_integration():
    print("\n6. Testing Gameplay Integration...")
    # Implementation from Phase 4
```

## Reporting Results

Document all test results with:
1. **Pass/Fail status** for each test phase
2. **Performance metrics** (memory, FPS, AI times)
3. **Any errors encountered** with full error messages
4. **Recommendations** for any issues found

Run this comprehensive test suite to validate that all critical fixes are working correctly and the game is stable, performant, and ready for production.
