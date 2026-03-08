#!/usr/bin/env python3
"""
Generate missing stat icons for Jewelflame ProvincePanel
Style: SNES pixel art, 32x32, blue bg, gold icon
"""

from PIL import Image, ImageDraw
import os

def create_icon_directory():
    base = "/home/sloppymo/jewelflame/assets/icons"
    os.makedirs(base, exist_ok=True)
    return base

def generate_icon_flags():
    """Banner/flag icon - represents territory/control"""
    img = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors
    blue_bg = (26, 58, 122)      # #1a3a7a
    gold = (212, 175, 55)         # #d4af37
    gold_dark = (139, 117, 51)    # #8b7533
    dark_outline = (43, 43, 92)   # #2b2b5c
    
    # Blue circle background
    draw.ellipse([2, 2, 30, 30], fill=blue_bg, outline=dark_outline, width=2)
    
    # Flag pole
    draw.rectangle([10, 6, 12, 26], fill=gold_dark, outline=dark_outline)
    
    # Flag banner (waving)
    # Main banner shape
    flag_points = [(12, 6), (24, 8), (24, 18), (12, 20)]
    draw.polygon(flag_points, fill=gold, outline=gold_dark)
    
    # Banner details - fold/wave lines
    draw.line([(14, 8), (14, 18)], fill=gold_dark, width=1)
    draw.line([(18, 9), (18, 17)], fill=gold_dark, width=1)
    draw.line([(22, 9), (22, 17)], fill=gold_dark, width=1)
    
    # Pole top ornament
    draw.ellipse([9, 4, 13, 8], fill=gold, outline=dark_outline)
    
    return img

def generate_icon_swords():
    """Crossed swords icon - represents attack/military"""
    img = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors
    blue_bg = (26, 58, 122)
    gold = (212, 175, 55)
    gold_light = (255, 220, 100)
    gold_dark = (139, 117, 51)
    dark_outline = (43, 43, 92)
    
    # Blue circle background
    draw.ellipse([2, 2, 30, 30], fill=blue_bg, outline=dark_outline, width=2)
    
    # Crossed swords - simplified pixel art style
    # Sword 1 (top-left to bottom-right)
    # Blade
    draw.line([(10, 8), (22, 20)], fill=gold_light, width=3)
    draw.line([(10, 8), (22, 20)], fill=gold, width=1)
    # Guard (crossbar)
    draw.line([(8, 12), (14, 18)], fill=gold_dark, width=2)
    # Hilt
    draw.ellipse([9, 19, 13, 23], fill=gold_dark)
    
    # Sword 2 (top-right to bottom-left) - behind first
    # Blade
    draw.line([(22, 8), (10, 20)], fill=gold, width=3)
    draw.line([(22, 8), (10, 20)], fill=gold_light, width=1)
    # Guard
    draw.line([(18, 12), (24, 18)], fill=gold_dark, width=2)
    # Hilt
    draw.ellipse([19, 19, 23, 23], fill=gold_dark)
    
    return img

def generate_icon_castle():
    """Castle tower icon - represents defense/fortification"""
    img = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors
    blue_bg = (26, 58, 122)
    gold = (212, 175, 55)
    gold_dark = (139, 117, 51)
    dark_outline = (43, 43, 92)
    
    # Blue circle background
    draw.ellipse([2, 2, 30, 30], fill=blue_bg, outline=dark_outline, width=2)
    
    # Castle tower
    # Main tower body
    draw.rectangle([10, 12, 22, 26], fill=gold, outline=gold_dark)
    
    # Tower top (crenellations/battlements)
    # Left turret
    draw.rectangle([8, 8, 13, 14], fill=gold, outline=gold_dark)
    draw.rectangle([9, 6, 12, 8], fill=gold, outline=gold_dark)  # Top
    
    # Center/main turret
    draw.rectangle([13, 6, 19, 14], fill=gold, outline=gold_dark)
    draw.rectangle([14, 4, 18, 6], fill=gold, outline=gold_dark)  # Top
    
    # Right turret
    draw.rectangle([19, 8, 24, 14], fill=gold, outline=gold_dark)
    draw.rectangle([20, 6, 23, 8], fill=gold, outline=gold_dark)  # Top
    
    # Gate/door
    draw.arc([13, 20, 19, 28], 0, 180, fill=gold_dark, width=2)
    
    # Windows
    draw.rectangle([12, 16, 14, 18], fill=gold_dark)
    draw.rectangle([18, 16, 20, 18], fill=gold_dark)
    
    return img

def generate_button_frame_hover():
    """Lightened button frame for hover state"""
    img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors - lightened versions
    blue_light = (40, 80, 150)      # Lighter blue
    gold = (230, 200, 100)           # Brighter gold
    gold_highlight = (255, 230, 150) # Highlight
    
    # Main button background
    draw.rectangle([2, 2, 62, 62], fill=blue_light, outline=gold, width=3)
    
    # Inner bevel (lighter top/left)
    draw.line([(4, 4), (60, 4)], fill=gold_highlight, width=2)
    draw.line([(4, 4), (4, 60)], fill=gold_highlight, width=2)
    
    # Inner fill
    draw.rectangle([8, 8, 56, 56], fill=(50, 90, 160))
    
    return img

def generate_button_frame_pressed():
    """Darkened button frame for pressed state"""
    img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors - darkened versions
    blue_dark = (15, 35, 80)         # Darker blue
    gold_dark = (160, 130, 40)       # Darker gold
    gold_shadow = (100, 80, 25)      # Shadow
    
    # Main button background (inset look)
    draw.rectangle([2, 2, 62, 62], fill=blue_dark, outline=gold_dark, width=3)
    
    # Inner shadow (darker top/left for pressed effect)
    draw.line([(4, 4), (60, 4)], fill=(10, 25, 60), width=2)
    draw.line([(4, 4), (4, 60)], fill=(10, 25, 60), width=2)
    
    # Inner fill
    draw.rectangle([8, 8, 56, 56], fill=(20, 45, 100))
    
    return img

def main():
    base = create_icon_directory()
    print("Generating missing icons...")
    
    # Stat icons
    print("  - icon_flags.png")
    generate_icon_flags().save(f"{base}/icon_flags.png")
    
    print("  - icon_swords.png")
    generate_icon_swords().save(f"{base}/icon_swords.png")
    
    print("  - icon_castle.png")
    generate_icon_castle().save(f"{base}/icon_castle.png")
    
    # Button states
    ui_base = "/home/sloppymo/jewelflame/assets/ui"
    os.makedirs(ui_base, exist_ok=True)
    
    print("  - button_frame_hover.png")
    generate_button_frame_hover().save(f"{ui_base}/button_frame_hover.png")
    
    print("  - button_frame_pressed.png")
    generate_button_frame_pressed().save(f"{ui_base}/button_frame_pressed.png")
    
    print(f"\n✅ Icons generated in: {base}")
    print("Files created:")
    for f in ["icon_flags.png", "icon_swords.png", "icon_castle.png"]:
        path = f"{base}/{f}"
        if os.path.exists(path):
            print(f"  ✓ {f}")

if __name__ == "__main__":
    main()
