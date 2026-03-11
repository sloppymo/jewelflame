#!/usr/bin/env python3
"""
Chop UI buttons from the provided image.
Uses color detection to find blue-background buttons and extract them.
"""

from PIL import Image
import os

# Load the source image
input_path = "/root/.openclaw/media/inbound/file_101---ff344c11-0e7a-4973-8c85-7a95d52310b7.jpg"
output_dir = "/root/.openclaw/workspace/jewelflame/assets/ui/buttons"

os.makedirs(output_dir, exist_ok=True)

img = Image.open(input_path)
print(f"Image size: {img.size}")

# Manual crop coordinates based on visual inspection
# Format: (left, top, right, bottom, filename, description)
buttons = [
    # Row 1
    (140, 5, 260, 85, "btn_crops", "Wheat/Agriculture"),
    (370, 5, 490, 85, "btn_banner", "Red Flag/Banner"),
    
    # Row 2  
    (140, 110, 260, 190, "btn_helmet", "Blue Helmet/Armor"),
    (270, 110, 390, 190, "btn_crown", "Gold Crown"),
    
    # Row 3
    (80, 215, 200, 295, "btn_bread", "Bread/Food"),
    (210, 215, 330, 295, "btn_gold", "Gold/Coins"),
    
    # Row 4
    (20, 320, 140, 400, "btn_catapult", "Catapult/Siege"),
    (150, 320, 270, 400, "btn_worker", "Worker with Shovel"),
    (280, 320, 400, 400, "btn_diplomacy", "Diplomacy/Handshake"),
    
    # Row 5 (right side)
    (400, 215, 520, 345, "btn_scout", "Scout with Telescope"),
]

for left, top, right, bottom, filename, description in buttons:
    # Crop the button
    cropped = img.crop((left, top, right, bottom))
    
    # Save as PNG (preserve transparency if we add it later)
    output_path = os.path.join(output_dir, f"{filename}.png")
    cropped.save(output_path, "PNG")
    
    print(f"✅ {filename}.png ({cropped.size[0]}x{cropped.size[1]}) - {description}")

print(f"\n=== Extracted {len(buttons)} buttons to {output_dir} ===")

# Also create a sprite sheet/atlas for efficient loading
print("\nCreating sprite sheet atlas...")

# Calculate atlas dimensions
atlas_width = max(b[2] - b[0] for b in buttons) * 5  # 5 buttons wide
atlas_height = max(b[3] - b[1] for b in buttons) * 2  # 2 rows

atlas = Image.new('RGBA', (atlas_width, atlas_height), (0, 0, 0, 0))

# Simple layout - just place them in a grid
x, y = 0, 0
row_height = 100
for left, top, right, bottom, filename, description in buttons:
    cropped = img.crop((left, top, right, bottom))
    
    # Convert to RGBA
    if cropped.mode != 'RGBA':
        cropped = cropped.convert('RGBA')
    
    # Paste into atlas
    atlas.paste(cropped, (x, y))
    
    x += (right - left) + 10
    if x > atlas_width - 100:
        x = 0
        y += row_height

atlas_path = os.path.join(output_dir, "ui_buttons_atlas.png")
atlas.save(atlas_path, "PNG")
print(f"✅ Created atlas: {atlas_path}")

print("\nDone! Buttons ready for Godot TextureButton nodes.")
