#!/usr/bin/env python3
"""
Create a hero banner for the KN5000 documentation website.

Uses a photo of the KN5000 keyboard with subtle styling.
Photo source: Sound on Sound review (March 1998) - used under fair use.
"""

import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
except ImportError:
    print("Error: Pillow is required. Install with: pip install Pillow")
    sys.exit(1)


def create_hero_banner(output_path: Path, photo_path: Path):
    """Create the hero banner image from the KN5000 photo."""

    if not photo_path.exists():
        print(f"Error: Photo not found: {photo_path}")
        return False

    # Load the photo
    photo = Image.open(photo_path).convert('RGB')

    # Target banner dimensions
    banner_width = 800
    banner_height = 300

    # Scale photo to fit banner width while maintaining aspect ratio
    scale = banner_width / photo.width
    new_height = int(photo.height * scale)
    photo = photo.resize((banner_width, new_height), Image.Resampling.LANCZOS)

    # Create banner with dark background
    banner = Image.new('RGB', (banner_width, banner_height), (0x10, 0x10, 0x18))

    # Center the photo vertically
    photo_y = (banner_height - photo.height) // 2
    banner.paste(photo, (0, photo_y))

    # Add subtle vignette effect (darken edges)
    vignette = Image.new('RGBA', (banner_width, banner_height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(vignette)

    # Top gradient fade
    for y in range(40):
        alpha = int(180 * (1 - y / 40))
        draw.line([(0, y), (banner_width, y)], fill=(0x10, 0x10, 0x18, alpha))

    # Bottom gradient fade
    for y in range(40):
        alpha = int(180 * (1 - y / 40))
        draw.line([(0, banner_height - 1 - y), (banner_width, banner_height - 1 - y)],
                  fill=(0x10, 0x10, 0x18, alpha))

    # Composite vignette
    banner = banner.convert('RGBA')
    banner = Image.alpha_composite(banner, vignette)

    # Save as PNG
    banner = banner.convert('RGB')
    banner.save(output_path, 'PNG', quality=95)
    print(f"Created hero banner: {output_path}")
    print(f"Dimensions: {banner_width}x{banner_height}")
    return True


def main():
    script_dir = Path(__file__).parent
    docs_dir = script_dir.parent / "kn5000-docs"

    photo_path = docs_dir / "assets" / "images" / "kn5000-photo.jpg"
    output_path = docs_dir / "assets" / "images" / "hero-banner.png"

    if len(sys.argv) > 1:
        output_path = Path(sys.argv[1])

    if not photo_path.exists():
        print(f"Error: Photo not found: {photo_path}")
        print("Download a KN5000 photo to assets/images/kn5000-photo.jpg")
        sys.exit(1)

    output_path.parent.mkdir(parents=True, exist_ok=True)

    if create_hero_banner(output_path, photo_path):
        print("Done!")
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
