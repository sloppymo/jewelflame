from PIL import Image, ImageDraw
import os

# Create proper selection highlight - a golden hexagonal glow
size = 128
img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Draw hexagon outline with glow effect
center = size // 2
radius = 50
points = []
for i in range(6):
    angle = 3.14159 * 2 * i / 6 - 3.14159 / 6
    x = center + radius * 0.9 * 1.1 * (1 if i % 2 == 0 else 0.85) * (1 if i in [0, 3] else 0.8)
    y = center + radius * 0.9 * (1 if i in [0, 3] else 0.9)
    if i == 0:
        y -= 10
    elif i == 3:
        y += 10
    elif i in [1, 2]:
        x += 5
    elif i in [4, 5]:
        x -= 5
    points.append((x, y))

# Draw multiple layers for glow effect
colors = [
    (255, 215, 0, 255),   # Gold center
    (255, 223, 64, 200),  # Lighter gold
    (255, 200, 0, 150),   # Orange-gold
    (255, 180, 0, 100),   # Darker gold
    (255, 160, 0, 50),    # Outer glow
]

for i, color in enumerate(colors):
    offset = len(colors) - i
    inflated = []
    for p in points:
        dx = p[0] - center
        dy = p[1] - center
        dist = (dx * dx + dy * dy) ** 0.5
        if dist > 0:
            factor = (dist + offset * 2) / dist
            inflated.append((center + dx * factor, center + dy * factor))
        else:
            inflated.append(p)
    
    if i == 0:
        draw.polygon(inflated, fill=color)
    else:
        draw.polygon(inflated, outline=color)

# Save
img.save('/home/sloppymo/jewelflame/assets/effects/selection.png')
print("Created proper selection highlight")
