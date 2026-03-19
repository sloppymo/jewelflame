#!/usr/bin/env python3
"""Generate knight_sprite_frames.tres for Godot 4.x"""

import os

OUTPUT_FILE = "animations/knight_sprite_frames.tres"

NONCOMBAT_PATH = "res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Non-Combat.png"
COMBAT_PATH = "res://assets/Citizens - Guards - Warriors/Warriors/2-Handed_Swordsman_Combat.png"

# Direction mapping based on sprite sheet layout
# Rows 0-7: s, n, se, ne, e, w, sw, nw
DIRECTIONS = ["s", "n", "se", "ne", "e", "w", "sw", "nw"]

def main():
    textures = []
    animations = []
    tex_id = 1
    
    # Non-combat sheet: 4 cols x 31 rows
    # Create AtlasTextures for each frame
    nc_tex_indices = {}  # (row, col) -> texture id
    
    for row in range(31):
        for col in range(4):
            textures.append(f'''[sub_resource type="AtlasTexture" id="AtlasTexture_{tex_id}"]
atlas = ExtResource("1_ngnc")
region = Rect2({col * 16}, {row * 16}, 16, 16)''')
            nc_tex_indices[(row, col)] = tex_id
            tex_id += 1
    
    # Combat sheet: 8 cols x 24 rows
    c_tex_indices = {}  # (row, col) -> texture id
    
    for row in range(24):
        for col in range(8):
            textures.append(f'''[sub_resource type="AtlasTexture" id="AtlasTexture_{tex_id}"]
atlas = ExtResource("2_cmbt")
region = Rect2({col * 16}, {row * 16}, 16, 16)''')
            c_tex_indices[(row, col)] = tex_id
            tex_id += 1
    
    total_load_steps = tex_id  # +1 for the resource itself
    
    # Build header
    output = f'''[gd_resource type="SpriteFrames" load_steps={total_load_steps} format=3]

[ext_resource type="Texture2D" path="{NONCOMBAT_PATH}" id="1_ngnc"]
[ext_resource type="Texture2D" path="{COMBAT_PATH}" id="2_cmbt"]

'''
    
    # Add all texture sub-resources
    output += '\n\n'.join(textures)
    output += '\n\n[resource]\n'
    
    # Build animations
    anim_entries = []
    
    # NON-COMBAT animations
    # Idle: 4 frames, rows 0-7
    for i, dir in enumerate(DIRECTIONS):
        row = i
        frame_ids = [nc_tex_indices[(row, c)] for c in range(4)]
        frames_str = ', '.join([f'SubResource("AtlasTexture_{fid}")' for fid in frame_ids])
        anim_entries.append(f'''"idle_{dir}": {{
"speed": 6.0,
"loop": true,
"frames": [{frames_str}]
}}''')
    
    # Walk: 4 frames, rows 8-15
    for i, dir in enumerate(DIRECTIONS):
        row = i + 8
        frame_ids = [nc_tex_indices[(row, c)] for c in range(4)]
        frames_str = ', '.join([f'SubResource("AtlasTexture_{fid}")' for fid in frame_ids])
        anim_entries.append(f'''"walk_{dir}": {{
"speed": 10.0,
"loop": true,
"frames": [{frames_str}]
}}''')
    
    # Run: 4 frames, rows 16-23
    for i, dir in enumerate(DIRECTIONS):
        row = i + 16
        frame_ids = [nc_tex_indices[(row, c)] for c in range(4)]
        frames_str = ', '.join([f'SubResource("AtlasTexture_{fid}")' for fid in frame_ids])
        anim_entries.append(f'''"run_{dir}": {{
"speed": 12.0,
"loop": true,
"frames": [{frames_str}]
}}''')
    
    # Death: 4 frames, rows 24-30 (7 directions, no nw)
    DEATH_DIRS = ["s", "n", "se", "ne", "e", "w", "sw"]
    for i, dir in enumerate(DEATH_DIRS):
        row = i + 24
        frame_ids = [nc_tex_indices[(row, c)] for c in range(4)]
        frames_str = ', '.join([f'SubResource("AtlasTexture_{fid}")' for fid in frame_ids])
        anim_entries.append(f'''"death_{dir}": {{
"speed": 8.0,
"loop": false,
"frames": [{frames_str}]
}}''')
    
    # COMBAT animations
    # Attack Light: 8 frames, rows 0-7
    for i, dir in enumerate(DIRECTIONS):
        row = i
        frame_ids = [c_tex_indices[(row, c)] for c in range(8)]
        frames_str = ', '.join([f'SubResource("AtlasTexture_{fid}")' for fid in frame_ids])
        anim_entries.append(f'''"attack_light_{dir}": {{
"speed": 12.0,
"loop": false,
"frames": [{frames_str}]
}}''')
    
    # Attack Heavy: 8 frames, rows 8-15
    for i, dir in enumerate(DIRECTIONS):
        row = i + 8
        frame_ids = [c_tex_indices[(row, c)] for c in range(8)]
        frames_str = ', '.join([f'SubResource("AtlasTexture_{fid}")' for fid in frame_ids])
        anim_entries.append(f'''"attack_heavy_{dir}": {{
"speed": 10.0,
"loop": false,
"frames": [{frames_str}]
}}''')
    
    # Hurt: 8 frames, rows 16-23
    for i, dir in enumerate(DIRECTIONS):
        row = i + 16
        frame_ids = [c_tex_indices[(row, c)] for c in range(8)]
        frames_str = ', '.join([f'SubResource("AtlasTexture_{fid}")' for fid in frame_ids])
        anim_entries.append(f'''"hurt_{dir}": {{
"speed": 8.0,
"loop": false,
"frames": [{frames_str}]
}}''')
    
    # Combine all animations
    output += 'animations = {\n'
    output += ',\n'.join(anim_entries)
    output += '\n}\n'
    
    # Write file
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, 'w') as f:
        f.write(output)
    
    print(f"Generated {OUTPUT_FILE} with {len(anim_entries)} animations")
    print(f"Total AtlasTexture sub-resources: {tex_id - 1}")

if __name__ == "__main__":
    main()
