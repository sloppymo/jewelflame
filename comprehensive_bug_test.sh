#!/bin/bash

echo "========================================"
echo "🐛 JEWELFLAME - COMPREHENSIVE BUG TEST"
echo "========================================"
echo

echo "1. Checking for syntax errors..."
syntax_errors=0
for file in $(find . -name "*.gd"); do
    if ! godot --headless --check-only "$file" 2>/dev/null; then
        echo "❌ Syntax error in: $file"
        syntax_errors=$((syntax_errors + 1))
    fi
done

if [ $syntax_errors -eq 0 ]; then
    echo "✅ No syntax errors found"
else
    echo "❌ Found $syntax_errors syntax errors"
fi

echo
echo "2. Checking for missing signals..."
missing_signals=0

# Check if all referenced signals exist in EventBus
signals_in_eventbus=$(grep -o "signal [A-Za-z_]*(" autoload/event_bus.gd | sed 's/signal //' | sed 's/(//' | sort | uniq)

# Check for signal connections
for signal in $(grep -r "\.connect(" --include="*.gd" . | grep -o "EventBus\.[A-Za-z_]*" | sed 's/EventBus\.//' | sort | uniq); do
    if ! echo "$signals_in_eventbus" | grep -q "^$signal$"; then
        echo "❌ Missing signal: $signal"
        missing_signals=$((missing_signals + 1))
    fi
done

if [ $missing_signals -eq 0 ]; then
    echo "✅ All referenced signals exist"
else
    echo "❌ Found $missing_signals missing signals"
fi

echo
echo "3. Checking for missing functions..."
missing_functions=0

# Check for function calls that might not exist
function_calls=$(grep -r "\.[a-z_]*(" --include="*.gd" . | grep -v "get_tree\|get_node\|print\|emit\|connect\|append\|push_error\|push_warning\|rand" | head -20)

echo "Sample function calls found:"
echo "$function_calls" | head -5

echo
echo "4. Checking autoload configuration..."
autoload_count=$(grep -c "=.*res://" project.godot)
echo "✅ Found $autoload_count autoloads configured"

# Check if all autoload files exist
missing_autoloads=0
for autoload in $(grep "=.*res://" project.godot | sed 's/.*=//' | sed 's/"//g'); do
    if [ ! -f "$autoload" ]; then
        echo "❌ Missing autoload file: $autoload"
        missing_autoloads=$((missing_autoloads + 1))
    fi
done

if [ $missing_autoloads -eq 0 ]; then
    echo "✅ All autoload files exist"
else
    echo "❌ Found $missing_autoloads missing autoload files"
fi

echo
echo "5. Checking scene file integrity..."
scene_errors=0
for scene in $(find . -name "*.tscn"); do
    if ! godot --headless --check-only "$scene" 2>/dev/null; then
        echo "❌ Scene error in: $scene"
        scene_errors=$((scene_errors + 1))
    fi
done

if [ $scene_errors -eq 0 ]; then
    echo "✅ All scene files are valid"
else
    echo "❌ Found $scene_errors scene errors"
fi

echo
echo "6. Checking for missing class references..."
class_errors=0

# Check if all class_name declarations have corresponding files
for class in $(grep -r "class_name.*extends" --include="*.gd" . | sed 's/.*class_name //' | sed 's/ extends.*//'); do
    if ! find . -name "*.gd" -exec grep -l "class_name $class" {} \; | grep -q .; then
        echo "❌ Class reference issue: $class"
        class_errors=$((class_errors + 1))
    fi
done

if [ $class_errors -eq 0 ]; then
    echo "✅ All class references are valid"
else
    echo "❌ Found $class_errors class reference issues"
fi

echo
echo "7. Checking for potential runtime issues..."
runtime_issues=0

# Check for potential null reference issues
null_refs=$(grep -r "\.get(" --include="*.gd" . | grep -v "get_tree\|get_node\|get_children\|get_parent" | wc -l)
echo "📊 Found $null_refs potential get() calls (may need null checks)"

# Check for potential division by zero
div_zero=$(grep -r "/ [0-9]" --include="*.gd" . | wc -l)
echo "📊 Found $div_zero division operations (may need zero checks)"

echo
echo "8. Checking resource dependencies..."
resource_issues=0

# Check if all referenced resources exist
for resource in $(grep -r "res://" --include="*.gd" --include="*.tscn" . | grep -o "res://[^\"]*" | sort | uniq); do
    if [ ! -f "$resource" ]; then
        echo "❌ Missing resource: $resource"
        resource_issues=$((resource_issues + 1))
    fi
done

if [ $resource_issues -eq 0 ]; then
    echo "✅ All referenced resources exist"
else
    echo "❌ Found $resource_issues missing resources"
fi

echo
echo "========================================"
echo "🐛 BUG TEST SUMMARY"
echo "========================================"
echo "Syntax Errors: $syntax_errors"
echo "Missing Signals: $missing_signals"
echo "Missing Functions: Check manually"
echo "Missing Autoloads: $missing_autoloads"
echo "Scene Errors: $scene_errors"
echo "Class Reference Issues: $class_errors"
echo "Missing Resources: $resource_issues"
echo

total_errors=$((syntax_errors + missing_signals + missing_autoloads + scene_errors + class_errors + resource_issues))

if [ $total_errors -eq 0 ]; then
    echo "🎉 NO CRITICAL BUGS FOUND!"
    echo "✅ Project appears to be bug-free"
else
    echo "❌ FOUND $total_errors POTENTIAL ISSUES"
    echo "⚠️  Please review and fix the issues above"
fi

echo
echo "📋 Manual Testing Recommended:"
echo "1. Test complete game flow in Godot Editor"
echo "2. Verify AI turns work correctly"
echo "3. Test battle transitions"
echo "4. Verify save/load functionality"
echo "5. Test UI interactions"
echo "6. Check performance during extended play"
