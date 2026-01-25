#!/usr/bin/env python3
"""
Create a hero banner for the KN5000 documentation website.

Combines the Technics and KN5000 logos with a styled background
using colors from the extracted firmware palette.
"""

import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:
    print("Error: Pillow is required. Install with: pip install Pillow")
    sys.exit(1)


def load_palette(palette_path: Path) -> list:
    """Load palette and return as list of RGB tuples."""
    with open(palette_path, 'rb') as f:
        data = f.read()

    colors = []
    for i in range(256):
        r = data[i * 4 + 0]
        g = data[i * 4 + 1]
        b = data[i * 4 + 2]
        colors.append((r, g, b))
    return colors


def create_gradient(width: int, height: int, color1: tuple, color2: tuple) -> Image.Image:
    """Create a vertical gradient image."""
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)

    for y in range(height):
        # Linear interpolation
        ratio = y / height
        r = int(color1[0] * (1 - ratio) + color2[0] * ratio)
        g = int(color1[1] * (1 - ratio) + color2[1] * ratio)
        b = int(color1[2] * (1 - ratio) + color2[2] * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))

    return img


def create_hero_banner(output_path: Path, gallery_path: Path, palette_path: Path):
    """Create the hero banner image."""

    # Banner dimensions (wide format for header)
    banner_width = 800
    banner_height = 180

    # Load palette for colors
    palette = load_palette(palette_path)

    # Use dark blue/teal colors from typical Technics styling
    # These are approximations of the KN5000's LCD background colors
    top_color = (0x19, 0x2B, 0x2E)      # Dark teal (from palette)
    bottom_color = (0x06, 0x06, 0x26)   # Very dark blue

    # Create gradient background
    banner = create_gradient(banner_width, banner_height, top_color, bottom_color)

    # Load logos
    technics_logo_path = gallery_path / "BitmapTechnicsLogo.png"
    kn5000_logo_path = gallery_path / "BitmapKN5000Logo.png"

    if not technics_logo_path.exists() or not kn5000_logo_path.exists():
        print(f"Error: Logo files not found in {gallery_path}")
        return False

    technics_logo = Image.open(technics_logo_path).convert('RGBA')
    kn5000_logo = Image.open(kn5000_logo_path).convert('RGBA')

    # Make black pixels transparent (logos have black background)
    def make_transparent(img, threshold=30):
        """Make dark pixels transparent."""
        data = img.getdata()
        new_data = []
        for item in data:
            # If pixel is very dark, make it transparent
            if item[0] < threshold and item[1] < threshold and item[2] < threshold:
                new_data.append((0, 0, 0, 0))
            else:
                new_data.append(item)
        img.putdata(new_data)
        return img

    technics_logo = make_transparent(technics_logo)
    kn5000_logo = make_transparent(kn5000_logo)

    # Scale logos up slightly for better visibility
    scale = 1.5
    technics_logo = technics_logo.resize(
        (int(technics_logo.width * scale), int(technics_logo.height * scale)),
        Image.Resampling.NEAREST
    )
    kn5000_logo = kn5000_logo.resize(
        (int(kn5000_logo.width * scale), int(kn5000_logo.height * scale)),
        Image.Resampling.NEAREST
    )

    # Position logos - Technics on top, KN5000 below
    technics_x = (banner_width - technics_logo.width) // 2
    technics_y = 25

    kn5000_x = (banner_width - kn5000_logo.width) // 2
    kn5000_y = technics_y + technics_logo.height + 15

    # Convert banner to RGBA for compositing
    banner = banner.convert('RGBA')

    # Paste logos with transparency
    banner.paste(technics_logo, (technics_x, technics_y), technics_logo)
    banner.paste(kn5000_logo, (kn5000_x, kn5000_y), kn5000_logo)

    # Add subtle decorative line
    draw = ImageDraw.Draw(banner)
    line_y = banner_height - 20
    line_color = (0x36, 0xA6, 0xBB, 180)  # Teal accent color with alpha
    draw.line([(50, line_y), (banner_width - 50, line_y)], fill=line_color[:3], width=2)

    # Save as PNG
    banner = banner.convert('RGB')
    banner.save(output_path, 'PNG')
    print(f"Created hero banner: {output_path}")
    print(f"Dimensions: {banner_width}x{banner_height}")
    return True


def main():
    script_dir = Path(__file__).parent

    gallery_path = script_dir.parent / "kn5000-docs" / "assets" / "images" / "gallery"
    palette_path = script_dir / "maincpu" / "images" / "Palette_8bit_RGBA.bin"
    output_path = script_dir.parent / "kn5000-docs" / "assets" / "images" / "hero-banner.png"

    if len(sys.argv) > 1:
        output_path = Path(sys.argv[1])

    if not palette_path.exists():
        print(f"Error: Palette not found: {palette_path}")
        sys.exit(1)

    if not gallery_path.exists():
        print(f"Error: Gallery not found: {gallery_path}")
        sys.exit(1)

    output_path.parent.mkdir(parents=True, exist_ok=True)

    if create_hero_banner(output_path, gallery_path, palette_path):
        print("Done!")
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
