from PIL import Image, ImageDraw
import math

# Create proper selection highlight - hexagonal glow
size = 128
img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

center_x, center_y = size // 2, size // 2
hex_radius = 45

# Generate hexagon points
points = []
for i in range(6):
    angle = math.pi / 3 * i - math.pi / 6  # -30 degrees to start at top
    x = center_x + hex_radius * math.cos(angle)
    y = center_y + hex_radius * math.sin(angle)
    points.append((x, y))

# Draw glow layers (outer to inner)
glow_colors = [
    (255, 215, 0, 60),    # Outer gold glow
    (255, 223, 0, 100),   # Mid glow  
    (255, 230, 64, 150),  # Inner glow
    (255, 240, 128, 200), # Bright inner
]

for i, color in enumerate(glow_colors):
    expansion = (4 - i) * 4  # 16, 12, 8, 4 pixels expansion
    expanded = []
    for p in points:
        dx = p[0] - center_x
        dy = p[1] - center_y
        dist = math.sqrt(dx*dx + dy*dy)
        if dist > 0:
            factor = (dist + expansion) / dist
            expanded.append((center_x + dx * factor, center_y + dy * factor))
        else:
            expanded.append(p)
    
    draw.polygon(expanded, fill=color)

# Draw bright center
draw.polygon(points, fill=(255, 255, 200, 255))

# Draw golden border
border_points = []
for i in range(6):
    angle = math.pi / 3 * i - math.pi / 6
    x = center_x + (hex_radius - 2) * math.cos(angle)
    y = center_y + (hex_radius - 2) * math.sin(angle)
    border_points.append((x, y))
draw.polygon(border_points, outline=(218, 165, 32, 255), width=2)

img.save('/home/sloppymo/jewelflame/assets/effects/selection.png')
print("Created golden hexagon selection highlight")
