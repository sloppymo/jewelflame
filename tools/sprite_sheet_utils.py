"""
Sprite Sheet Utilities for Godot/Jewelflame
Helps prepare and validate sprite sheets for import.
"""

from PIL import Image
import json
from pathlib import Path
from typing import Tuple, List, Dict


class SpriteSheetValidator:
    """Validates sprite sheets meet Godot requirements."""
    
    VALID_SIZES = [16, 32, 64, 128, 256]
    
    def __init__(self, image_path: str):
        self.image = Image.open(image_path)
        self.width, self.height = self.image.size
        self.issues = []
    
    def _is_power_of_two(n: int) -> bool:
        """Check if n is a power of 2."""
        return n > 0 and (n & (n - 1)) == 0
    
    def validate(self, expected_frame_size: Tuple[int, int]) -> Dict:
        """
        Validate sprite sheet against Godot best practices.
        
        Args:
            expected_frame_size: (width, height) of each frame
            
        Returns:
            Dict with validation results
        """
        frame_w, frame_h = expected_frame_size
        self.issues = []
        
        # Check frame size is power of 2
        def _is_power_of_two(n: int) -> bool:
            return n > 0 and (n & (n - 1)) == 0
        
        if not _is_power_of_two(frame_w) or not _is_power_of_two(frame_h):
            self.issues.append(
                f"Frame size {frame_w}x{frame_h} is not a power of 2. "
                f"Recommended: 16, 32, 64, 128"
            )
        
        # Check dimensions are divisible by frame size
        if self.width % frame_w != 0:
            self.issues.append(
                f"Width {self.width} not divisible by frame width {frame_w}"
            )
        if self.height % frame_h != 0:
            self.issues.append(
                f"Height {self.height} not divisible by frame height {frame_h}"
            )
        
        # Calculate grid
        cols = self.width // frame_w
        rows = self.height // frame_h
        total_frames = cols * rows
        
        return {
            "valid": len(self.issues) == 0,
            "issues": self.issues,
            "dimensions": (self.width, self.height),
            "frame_size": expected_frame_size,
            "grid": (cols, rows),
            "total_frames": total_frames,
            "format": self.image.format,
            "mode": self.image.mode
        }
    
    def suggest_padding(self, padding: int = 2) -> Tuple[int, int]:
        """
        Calculate new dimensions with padding added.
        
        Args:
            padding: Padding in pixels to add around each frame
            
        Returns:
            (new_width, new_height)
        """
        # Try to detect frame size
        for size in self.VALID_SIZES:
            if self.width % size == 0 and self.height % size == 0:
                frame_w = frame_h = size
                break
        else:
            return (0, 0)
        
        cols = self.width // frame_w
        rows = self.height // frame_h
        
        new_w = cols * (frame_w + padding * 2)
        new_h = rows * (frame_h + padding * 2)
        
        return (new_w, new_h)
    
    def _detect_frame_size(self) -> Tuple[int, int]:
        """Attempt to detect frame size from image dimensions."""
        for size in self.VALID_SIZES:
            if self.width % size == 0 and self.height % size == 0:
                return (size, size)
        return (None, None)


class SpriteSheetGenerator:
    """Generate Godot-ready sprite sheets from individual frames."""
    
    def __init__(self, frame_size: Tuple[int, int], padding: int = 2):
        """
        Args:
            frame_size: (width, height) of each frame
            padding: Padding to add around each frame
        """
        self.frame_w, self.frame_h = frame_size
        self.padding = padding
    
    def create_from_frames(
        self, 
        frame_paths: List[str], 
        layout: str = "rows",
        max_per_row: int = 8
    ) -> Image.Image:
        """
        Create a sprite sheet from individual frame images.
        
        Args:
            frame_paths: List of paths to frame images
            layout: "rows" or "columns"
            max_per_row: Maximum frames per row (for "rows" layout)
            
        Returns:
            PIL Image of the sprite sheet
        """
        frames = [Image.open(p) for p in frame_paths]
        
        # Validate all frames are same size
        for i, frame in enumerate(frames):
            if frame.size != (self.frame_w, self.frame_h):
                raise ValueError(
                    f"Frame {i} size {frame.size} doesn't match "
                    f"expected ({self.frame_w}, {self.frame_h})"
                )
        
        # Calculate grid dimensions
        if layout == "rows":
            cols = min(len(frames), max_per_row)
            rows = (len(frames) + max_per_row - 1) // max_per_row
        else:
            rows = min(len(frames), max_per_row)
            cols = (len(frames) + max_per_row - 1) // max_per_row
        
        # Calculate output size with padding
        out_w = cols * (self.frame_w + self.padding * 2)
        out_h = rows * (self.frame_h + self.padding * 2)
        
        # Create output image with transparency
        output = Image.new('RGBA', (out_w, out_h), (0, 0, 0, 0))
        
        # Place frames
        for i, frame in enumerate(frames):
            if layout == "rows":
                col = i % max_per_row
                row = i // max_per_row
            else:
                row = i % max_per_row
                col = i // max_per_row
            
            x = col * (self.frame_w + self.padding * 2) + self.padding
            y = row * (self.frame_h + self.padding * 2) + self.padding
            
            output.paste(frame, (x, y), frame if frame.mode == 'RGBA' else None)
        
        return output
    
    def add_padding_to_existing(
        self, 
        input_path: str, 
        output_path: str,
        frame_size: Tuple[int, int]
    ) -> Dict:
        """
        Add padding to an existing sprite sheet.
        
        Args:
            input_path: Path to existing sprite sheet
            output_path: Where to save padded version
            frame_size: (width, height) of each frame
            
        Returns:
            Info dict about the operation
        """
        img = Image.open(input_path)
        img_w, img_h = img.size
        frame_w, frame_h = frame_size
        
        cols = img_w // frame_w
        rows = img_h // frame_h
        
        # Create new image with padding
        new_w = cols * (frame_w + self.padding * 2)
        new_h = rows * (frame_h + self.padding * 2)
        
        output = Image.new('RGBA', (new_w, new_h), (0, 0, 0, 0))
        
        # Copy frames with padding
        for row in range(rows):
            for col in range(cols):
                # Extract frame
                src_x = col * frame_w
                src_y = row * frame_h
                frame = img.crop((src_x, src_y, src_x + frame_w, src_y + frame_h))
                
                # Calculate destination with padding
                dst_x = col * (frame_w + self.padding * 2) + self.padding
                dst_y = row * (frame_h + self.padding * 2) + self.padding
                
                output.paste(frame, (dst_x, dst_y))
        
        output.save(output_path, 'PNG')
        
        return {
            "input_size": (img_w, img_h),
            "output_size": (new_w, new_h),
            "grid": (cols, rows),
            "frames": cols * rows,
            "saved_to": output_path
        }


def generate_godot_spriteframes_code(
    sheet_path: str,
    frame_size: Tuple[int, int],
    animations: Dict[str, List[int]],
    sheet_cols: int = 4,          # Jewelflame sheets are 4 columns wide
    output_path: str = None
) -> str:
    """
    Generate GDScript code for runtime SpriteFrames generation.
    
    Args:
        sheet_path: Path to sprite sheet in Godot project
        frame_size: (width, height) of each frame
        animations: Dict mapping animation name to list of frame indices
        sheet_cols: Number of columns in the sheet (default 4 for Jewelflame)
        output_path: Optional path to save the generated code
        
    Returns:
        Generated GDScript code as string
    """
    frame_w, frame_h = frame_size
    cols = sheet_cols             # Use parameter, not hardcoded 8

    code = f'''# Auto-generated SpriteFrames setup for {Path(sheet_path).name}
# Frame size: {frame_w}x{frame_h}

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
    animated_sprite.sprite_frames = build_sprite_frames()
    animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func build_sprite_frames() -> SpriteFrames:
    var sf = SpriteFrames.new()
    var atlas = load("{sheet_path}")

'''
    
    for anim_name, frame_indices in animations.items():
        code += f'''    # {anim_name}
    sf.add_animation("{anim_name}")
    sf.set_animation_speed("{anim_name}", 10)
    sf.set_animation_loop("{anim_name}", true)
'''
        for frame_idx in frame_indices:
            row = frame_idx // cols
            col = frame_idx % cols
            code += f'''    var tex_{anim_name}_{frame_idx} = AtlasTexture.new()
    tex_{anim_name}_{frame_idx}.atlas = atlas
    tex_{anim_name}_{frame_idx}.region = Rect2({col * frame_w}, {row * frame_h}, {frame_w}, {frame_h})
    tex_{anim_name}_{frame_idx}.filter_clip = true
    sf.add_frame("{anim_name}", tex_{anim_name}_{frame_idx})
'''
        code += '\n'
    
    code += '    return sf\n'
    
    if output_path:
        with open(output_path, 'w') as f:
            f.write(code)
    
    return code


def validate_jewelflame_sheet(image_path: str) -> dict:
    """
    Validate a sprite sheet against Jewelflame's confirmed specs.
    Knows about the actual sheets in the project.
    """
    known_sheets = {
        "Sword_and_Shield_Fighter_Non-Combat.png": {"frame": (16, 16), "grid": (4, 31)},
        "Sword_and_Shield_Fighter_Combat.png":     {"frame": (32, 32), "grid": (4, 20)},
        "Archer_Non-Combat.png":                   {"frame": (16, 16), "grid": (4, 31)},
        "Archer_Combat.png":                       {"frame": (32, 32), "grid": (4,  8)},
    }

    filename = Path(image_path).name
    if filename not in known_sheets:
        return {"known": False, "filename": filename,
                "message": "Not a known Jewelflame sheet. Use SpriteSheetValidator directly."}

    spec = known_sheets[filename]
    validator = SpriteSheetValidator(image_path)
    result = validator.validate(spec["frame"])

    expected_grid = spec["grid"]
    actual_grid   = result["grid"]
    grid_ok = (actual_grid == expected_grid)

    if not grid_ok:
        result["issues"].append(
            f"Grid mismatch: expected {expected_grid}, got {actual_grid}"
        )
        result["valid"] = False

    result["known"] = True
    result["expected_grid"] = expected_grid
    result["grid_match"] = grid_ok

    return result


def example_validate():
    """Example: Validate a sprite sheet."""
    validator = SpriteSheetValidator("sprites/knight.png")
    result = validator.validate((64, 64))
    print(json.dumps(result, indent=2))


def example_create_sheet():
    """Example: Create a sprite sheet from frames."""
    generator = SpriteSheetGenerator((32, 32), padding=2)
    
    # Get all frame files
    frame_files = sorted(Path("frames/walk").glob("*.png"))
    
    # Create sheet
    sheet = generator.create_from_frames(
        [str(f) for f in frame_files],
        layout="rows",
        max_per_row=4
    )
    
    sheet.save("output/walk_sheet.png")
    print("Sprite sheet created!")


def example_add_padding():
    """Example: Add padding to existing sheet."""
    generator = SpriteSheetGenerator((64, 64), padding=2)
    result = generator.add_padding_to_existing(
        "input/knight.png",
        "output/knight_padded.png",
        (64, 64)
    )
    print(json.dumps(result, indent=2))


def example_generate_code():
    """Example: Generate GDScript code."""
    animations = {
        "walk_s": [0, 1, 2, 3],
        "walk_n": [4, 5, 6, 7],
    }
    code = generate_godot_spriteframes_code(
        "res://sprites/knight.png",
        (64, 64),
        animations,
        sheet_cols=4   # Jewelflame sheets are 4 columns wide
    )
    print("Code generated!")


if __name__ == "__main__":
    print("Sprite Sheet Utilities for Godot")
    print("================================")
    print()
    print("Available functions:")
    print("  - SpriteSheetValidator: Validate existing sheets")
    print("  - SpriteSheetGenerator: Create new sheets or add padding")
    print("  - generate_godot_spriteframes_code: Generate GDScript")
    print("  - validate_jewelflame_sheet: Validate known Jewelflame sheets")
    print()
    print("See example_* functions for usage.")
