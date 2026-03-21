#!/bin/bash
# Screenshot Helper for Godot/Jewelflame
# Usage: ./screenshot_helper.sh [window_name] [output_path]

WINDOW_NAME="${1:-Godot}"
OUTPUT_PATH="${2:-/tmp/godot_screenshot.png}"

# Find window ID
WINDOW_ID=$(xwininfo -root -tree | grep -i "$WINDOW_NAME" | head -1 | awk '{print $1}')

if [ -z "$WINDOW_ID" ]; then
    echo "ERROR: Could not find window matching '$WINDOW_NAME'"
    exit 1
fi

echo "Found window: $WINDOW_ID"
echo "Capturing to: $OUTPUT_PATH"

# Capture screenshot using ImageMagick
import -window "$WINDOW_ID" "$OUTPUT_PATH"

if [ $? -eq 0 ]; then
    echo "SUCCESS: Screenshot saved to $OUTPUT_PATH"
    ls -la "$OUTPUT_PATH"
else
    echo "ERROR: Failed to capture screenshot"
    exit 1
fi
