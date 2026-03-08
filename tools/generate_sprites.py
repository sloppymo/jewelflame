#!/usr/bin/env python3
"""
Generate SNES-style pixel art sprites for Jewelflame
16-bit aesthetic, pixel-perfect, limited palette
"""

from PIL import Image, ImageDraw
import os

def create_sprite_directory():
    """Create output directories."""
    base = "/home/sloppymo/jewelflame/assets/generated"
    dirs = ["units", "portraits", "ui", "terrain"]
    for d in dirs:
        os.makedirs(f"{base}/{d}", exist_ok=True)
    return base

def draw_pixel_line(draw, x1, y1, x2, y2, color):
    """Draw pixel-perfect line using Bresenham's algorithm."""
    dx = abs(x2 - x1)
    dy = abs(y2 - y1)
    sx = 1 if x1 < x2 else -1
    sy = 1 if y1 < y2 else -1
    err = dx - dy
    
    while True:
        draw.point((x1, y1), fill=color)
        if x1 == x2 and y1 == y2:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x1 += sx
        if e2 < dx:
            err += dx
            y1 += sy

def generate_knight_sprite():
    """Generate a 32x48 knight sprite (blue faction)."""
    img = Image.new('RGBA', (32, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Palette
    armor_light = (140, 140, 200)  # Light blue armor
    armor_dark = (74, 74, 158)     # Dark blue armor (Blanche color)
    armor_highlight = (180, 180, 220)
    skin = (240, 200, 160)
    metal = (200, 200, 200)
    metal_dark = (120, 120, 120)
    
    # Helmet (top)
    draw.rectangle([10, 2, 22, 12], fill=armor_dark)
    draw.rectangle([12, 4, 20, 10], fill=armor_light)
    # Visor slit
    draw.rectangle([14, 8, 18, 9], fill=(30, 30, 30))
    
    # Helmet plume/feather
    draw.rectangle([14, 0, 18, 2], fill=(200, 180, 100))
    
    # Body - breastplate
    draw.rectangle([8, 12, 24, 28], fill=armor_dark)
    draw.rectangle([10, 14, 22, 26], fill=armor_light)
    # Chest highlight
    draw.rectangle([14, 16, 18, 22], fill=armor_highlight)
    
    # Arms
    draw.rectangle([4, 14, 8, 24], fill=armor_light)   # Left arm
    draw.rectangle([24, 14, 28, 24], fill=armor_light) # Right arm
    
    # Hands
    draw.rectangle([4, 24, 8, 28], fill=skin)
    draw.rectangle([24, 24, 28, 28], fill=skin)
    
    # Sword in right hand
    # Hilt
    draw.rectangle([26, 26, 30, 28], fill=(160, 100, 60))
    # Crossguard
    draw.rectangle([24, 24, 32, 26], fill=metal)
    # Blade
    draw.rectangle([27, 4, 29, 24], fill=metal)
    draw.rectangle([27, 4, 28, 24], fill=(240, 240, 240))  # Highlight
    
    # Shield in left hand
    draw.ellipse([2, 18, 12, 32], fill=(160, 100, 60))  # Wood rim
    draw.ellipse([4, 20, 10, 30], fill=armor_dark)       # Metal face
    draw.ellipse([5, 21, 9, 29], fill=armor_light)       # Center
    # Shield emblem (simple cross)
    draw.rectangle([6, 23, 8, 27], fill=(200, 180, 100))
    draw.rectangle([5, 24, 9, 26], fill=(200, 180, 100))
    
    # Legs
    draw.rectangle([10, 28, 15, 44], fill=armor_dark)   # Left leg
    draw.rectangle([17, 28, 22, 44], fill=armor_dark)   # Right leg
    draw.rectangle([11, 30, 14, 42], fill=armor_light)  # Left shin
    draw.rectangle([18, 30, 21, 42], fill=armor_light)  # Right shin
    
    # Boots
    draw.rectangle([10, 44, 15, 48], fill=(100, 60, 40))
    draw.rectangle([17, 44, 22, 48], fill=(100, 60, 40))
    
    return img

def generate_horseman_sprite():
    """Generate a 32x48 horseman sprite."""
    img = Image.new('RGBA', (32, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Palette
    armor = (180, 60, 60)      # Red armor (Lyle)
    armor_dark = (140, 40, 40)
    horse_brown = (140, 100, 60)
    horse_dark = (100, 70, 40)
    horse_light = (180, 140, 90)
    metal = (200, 200, 200)
    
    # Horse body
    draw.rectangle([6, 24, 26, 40], fill=horse_brown)
    draw.rectangle([8, 26, 24, 38], fill=horse_light)
    
    # Horse head
    draw.rectangle([22, 16, 30, 26], fill=horse_brown)
    draw.rectangle([24, 18, 28, 24], fill=horse_light)
    # Mane
    draw.rectangle([20, 14, 24, 22], fill=(60, 40, 20))
    
    # Horse legs
    draw.rectangle([8, 40, 12, 48], fill=horse_dark)   # Front
    draw.rectangle([20, 40, 24, 48], fill=horse_dark)  # Back
    # Hooves
    draw.rectangle([8, 46, 12, 48], fill=(40, 30, 20))
    draw.rectangle([20, 46, 24, 48], fill=(40, 30, 20))
    
    # Horse tail
    draw.rectangle([4, 26, 8, 36], fill=(60, 40, 20))
    
    # Rider body
    draw.rectangle([10, 14, 22, 28], fill=armor_dark)
    draw.rectangle([12, 16, 20, 26], fill=armor)
    
    # Rider head (helmet)
    draw.rectangle([12, 6, 20, 14], fill=armor_dark)
    draw.rectangle([14, 8, 18, 12], fill=armor)
    
    # Lance
    draw.rectangle([28, 2, 30, 32], fill=(160, 100, 60))  # Shaft
    draw.rectangle([27, 2, 31, 6], fill=metal)            # Tip
    
    return img

def generate_archer_sprite():
    """Generate a 32x48 archer sprite."""
    img = Image.new('RGBA', (32, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Palette
    tunic = (60, 140, 60)       # Green (Coryll)
    tunic_dark = (40, 100, 40)
    skin = (240, 200, 160)
    wood = (140, 100, 60)
    
    # Legs
    draw.rectangle([10, 32, 14, 48], fill=(80, 60, 40))
    draw.rectangle([18, 32, 22, 48], fill=(80, 60, 40))
    
    # Body
    draw.rectangle([8, 16, 24, 34], fill=tunic_dark)
    draw.rectangle([10, 18, 22, 32], fill=tunic)
    
    # Head
    draw.rectangle([12, 6, 20, 16], fill=skin)
    # Hood
    draw.rectangle([10, 4, 22, 12], fill=tunic_dark)
    draw.rectangle([12, 6, 20, 10], fill=tunic)
    
    # Arms (bow drawing pose)
    draw.rectangle([4, 18, 10, 26], fill=tunic)   # Left arm back
    draw.rectangle([22, 18, 28, 26], fill=tunic)  # Right arm forward
    
    # Bow
    draw.arc([2, 12, 14, 32], 270, 90, fill=wood, width=2)
    # Bowstring
    draw.line([(8, 14), (8, 30)], fill=(240, 240, 240), width=1)
    
    # Quiver on back
    draw.rectangle([20, 12, 26, 24], fill=(120, 80, 40))
    # Arrows
    draw.line([(22, 8), (22, 12)], fill=wood, width=2)
    draw.line([(24, 8), (24, 12)], fill=wood, width=2)
    
    return img

def generate_mage_sprite():
    """Generate a 32x48 mage sprite."""
    img = Image.new('RGBA', (32, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Palette
    robe = (100, 60, 140)       # Purple
    robe_light = (140, 100, 180)
    robe_dark = (60, 40, 80)
    skin = (240, 200, 160)
    gold = (200, 180, 100)
    
    # Robe body
    draw.rectangle([6, 16, 26, 48], fill=robe_dark)
    draw.rectangle([8, 18, 24, 46], fill=robe)
    
    # Robe trim/gold
    draw.rectangle([10, 20, 12, 44], fill=gold)
    draw.rectangle([20, 20, 22, 44], fill=gold)
    
    # Head
    draw.rectangle([12, 6, 20, 16], fill=skin)
    
    # Hood up
    draw.rectangle([10, 2, 22, 10], fill=robe_dark)
    draw.rectangle([12, 4, 20, 8], fill=robe)
    
    # Staff
    draw.rectangle([24, 4, 26, 48], fill=(160, 120, 80))
    # Staff gem
    draw.ellipse([22, 2, 28, 8], fill=(100, 200, 255))
    draw.ellipse([23, 3, 27, 7], fill=(150, 220, 255))
    
    # Hands
    draw.rectangle([10, 22, 14, 26], fill=skin)
    draw.rectangle([18, 22, 22, 26], fill=skin)
    
    # Spell effect (glowing hands)
    draw.ellipse([8, 20, 16, 28], outline=(100, 200, 255))
    
    return img

def generate_gold_icon():
    """Generate 32x32 gold coin icon."""
    img = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    gold = (212, 175, 55)       # #d4af37
    gold_dark = (160, 130, 40)
    gold_light = (255, 220, 100)
    
    # Coin stack (3 coins)
    for i, y_offset in enumerate([16, 10, 4]):
        y = 20 - i * 6
        # Coin body
        draw.ellipse([4, y, 28, y + 12], fill=gold_dark)
        draw.ellipse([6, y + 2, 26, y + 10], fill=gold)
        draw.ellipse([10, y + 4, 22, y + 8], fill=gold_light)
        # $ symbol
        draw.text((14, y + 2), "$", fill=gold_dark)
    
    return img

def generate_portrait_placeholder(name, bg_color):
    """Generate 128x192 portrait placeholder."""
    img = Image.new('RGBA', (128, 192), bg_color)
    draw = ImageDraw.Draw(img)
    
    # Gold frame
    gold = (212, 175, 55)
    draw.rectangle([0, 0, 127, 191], outline=gold, width=4)
    draw.rectangle([8, 8, 119, 183], outline=(180, 150, 80), width=2)
    
    # Simple face silhouette
    skin = (240, 200, 160)
    draw.ellipse([32, 40, 96, 104], fill=skin)
    
    # Eyes
    draw.ellipse([48, 64, 56, 72], fill=(60, 40, 20))
    draw.ellipse([72, 64, 80, 72], fill=(60, 40, 20))
    
    # Simple body
    draw.rectangle([24, 100, 104, 176], fill=(100, 100, 120))
    
    # Name
    draw.text((40, 160), name[:8], fill=(240, 240, 240))
    
    return img

def generate_hex_terrain(terrain_type):
    """Generate 80x80 hex terrain tile."""
    img = Image.new('RGBA', (80, 80), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Hexagon points
    cx, cy = 40, 40
    size = 35
    points = []
    for i in range(6):
        angle = 3.14159 / 180 * (60 * i - 30)
        x = cx + size * 1.0 * (1 if i in [0, 3] else (0.5 if i in [1, 5] else -0.5) if i in [2, 4] else -1)
        y = cy + size * (0 if i in [0, 3] else (0.87 if i in [1, 2] else -0.87))
        points.append((x, y))
    
    if terrain_type == "plains":
        color = (120, 160, 80)
        color_dark = (80, 120, 60)
        # Grass
        draw.polygon(points, fill=color)
        # Add some texture
        for _ in range(10):
            x = 20 + (_ * 5) % 40
            y = 20 + (_ * 7) % 40
            draw.ellipse([x, y, x+3, y+3], fill=color_dark)
    
    elif terrain_type == "forest":
        color = (60, 120, 60)
        color_dark = (40, 80, 40)
        draw.polygon(points, fill=color)
        # Trees
        for i in range(5):
            x = 25 + (i * 12) % 35
            y = 25 + (i * 15) % 35
            # Tree trunk
            draw.rectangle([x, y+8, x+4, y+16], fill=(100, 70, 40))
            # Tree top
            draw.polygon([(x-4, y+8), (x+8, y+8), (x+2, y-4)], fill=color_dark)
    
    elif terrain_type == "river":
        color = (100, 150, 200)
        color_dark = (60, 100, 160)
        draw.polygon(points, fill=(120, 160, 120))  # Grass base
        # Water
        river_points = [(30, 20), (50, 60), (60, 55), (40, 15)]
        draw.polygon(river_points, fill=color)
    
    # Border
    draw.polygon(points, outline=(60, 60, 60), width=2)
    
    return img

def main():
    base = create_sprite_directory()
    print("Generating SNES-style sprites...")
    
    # Units
    print("  - Knight sprite")
    generate_knight_sprite().save(f"{base}/units/knight_blue.png")
    
    print("  - Horseman sprite")
    generate_horseman_sprite().save(f"{base}/units/horseman_red.png")
    
    print("  - Archer sprite")
    generate_archer_sprite().save(f"{base}/units/archer_green.png")
    
    print("  - Mage sprite")
    generate_mage_sprite().save(f"{base}/units/mage_purple.png")
    
    # Icons
    print("  - Gold icon")
    generate_gold_icon().save(f"{base}/ui/icon_gold.png")
    
    # Portraits
    print("  - Portrait placeholders")
    generate_portrait_placeholder("Erin", (80, 120, 120)).save(f"{base}/portraits/erin.png")
    generate_portrait_placeholder("Ander", (140, 80, 80)).save(f"{base}/portraits/ander.png")
    generate_portrait_placeholder("Lars", (80, 120, 80)).save(f"{base}/portraits/lars.png")
    
    # Terrain
    print("  - Terrain hexes")
    generate_hex_terrain("plains").save(f"{base}/terrain/plains.png")
    generate_hex_terrain("forest").save(f"{base}/terrain/forest.png")
    generate_hex_terrain("river").save(f"{base}/terrain/river.png")
    
    print(f"\n✅ Sprites generated in: {base}")
    print("\nFiles created:")
    for root, dirs, files in os.walk(base):
        for f in files:
            path = os.path.join(root, f)
            size = os.path.getsize(path)
            print(f"  {path.replace(base, '')} ({size} bytes)")

if __name__ == "__main__":
    main()
