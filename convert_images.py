#!/usr/bin/env python3
"""
Convert extracted KN5000 bitmap images from raw .bin format to PNG.

This script knows the dimensions and format of each extracted image.
When new images are extracted, add their metadata to IMAGE_METADATA.

Uses the extracted 8-bit RGBA palette (Palette_8bit_RGBA.bin) for proper
color rendering of indexed images.

Usage:
    python convert_images.py [output_dir]

Default output_dir is ../kn5000-docs/assets/images/gallery/
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow is required. Install with: pip install Pillow")
    sys.exit(1)

# Palette file for 8-bit indexed images
PALETTE_FILE = "Palette_8bit_RGBA.bin"


def load_palette(palette_path: Path) -> list:
    """Load 256-color RGBA palette from binary file.

    The palette is stored as 256 entries of 4 bytes each in RGBA format
    (Red, Green, Blue, Alpha).
    Returns a list of 256 RGB values (flattened) for PIL palette.
    """
    if not palette_path.exists():
        print(f"  Warning: Palette file not found: {palette_path}")
        return None

    with open(palette_path, 'rb') as f:
        data = f.read()

    if len(data) != 1024:
        print(f"  Warning: Palette file size mismatch: {len(data)} bytes, expected 1024")
        return None

    # Extract RGB from RGBA palette (flatten for PIL)
    palette = []
    for i in range(256):
        r = data[i * 4 + 0]
        g = data[i * 4 + 1]
        b = data[i * 4 + 2]
        # a = data[i * 4 + 3]  # Alpha ignored for now
        palette.extend([r, g, b])

    return palette


# Image metadata: filename -> (width, height, bit_depth, description)
# bit_depth: 1 = monochrome, 4 = 16 colors, 8 = 256 colors
IMAGE_METADATA = {
    # 1-bit status messages (224x22, 28 bytes per row, from disassembly comment)
    "Bitmap_1bit_Flash_Memory_Update.bin": (224, 22, 1, "Flash Memory Update message"),
    "Bitmap_1bit_Now_Erasing.bin": (224, 22, 1, "Now Erasing message"),
    "Bitmap_1bit_FD_to_Flash_Memory.bin": (224, 22, 1, "FD to Flash Memory message"),
    "Bitmap_1bit_Completed.bin": (224, 22, 1, "Completed message"),
    "Bitmap_1bit_Please_Wait.bin": (224, 22, 1, "Please Wait message"),
    "Bitmap_1bit_Change_FD_2_of_2.bin": (224, 22, 1, "Change FD 2 of 2 message"),
    "Bitmap_1bit_Illegal_Disk.bin": (224, 22, 1, "Illegal Disk message"),
    "Bitmap_1bit_Turn_On_AGAIN.bin": (224, 22, 1, "Turn On AGAIN message"),

    # Logos - dimensions from assembly code (a2=width, a3=height)
    # TechnicsLogo: a2=0x138=312, a3=0x2D=45, 312*45=14040 bytes
    "BitmapTechnicsLogo.bin": (312, 45, 8, "Technics brand logo"),
    # KN5000Logo: a2=0xC7=199, a3=0x24=36, stride=200, 200*36=7200 bytes
    "BitmapKN5000Logo.bin": (200, 36, 8, "KN5000 model logo"),

    # Split point indicators - 3016 bytes each, likely 58x52 at 8bpp
    "BitmapSplitPoint_C.bin": (58, 52, 8, "Split point C"),
    "BitmapSplitPoint_Db.bin": (58, 52, 8, "Split point Db"),
    "BitmapSplitPoint_D.bin": (58, 52, 8, "Split point D"),
    "BitmapSplitPoint_Eb.bin": (58, 52, 8, "Split point Eb"),
    "BitmapSplitPoint_E.bin": (58, 52, 8, "Split point E"),
    "BitmapSplitPoint_F.bin": (58, 52, 8, "Split point F"),
    "BitmapSplitPoint_Gb.bin": (58, 52, 8, "Split point Gb"),
    "BitmapSplitPoint_G.bin": (58, 52, 8, "Split point G"),
    "BitmapSplitPoint_Ab.bin": (58, 52, 8, "Split point Ab"),
    "BitmapSplitPoint_A.bin": (58, 52, 8, "Split point A"),
    "BitmapSplitPoint_Bb.bin": (58, 52, 8, "Split point Bb"),
    "BitmapSplitPoint_B.bin": (58, 52, 8, "Split point B"),
    "BitmapSplitPoint_no_split.bin": (58, 52, 8, "Split point - no split"),

    # Drawbar sliders - 4884 bytes each, 22x222 at 8bpp
    "BitmapDrawbarNumberedSlider_1.bin": (22, 222, 8, "Drawbar slider 1"),
    "BitmapDrawbarNumberedSlider_2.bin": (22, 222, 8, "Drawbar slider 2"),
    "BitmapDrawbarNumberedSlider_3.bin": (22, 222, 8, "Drawbar slider 3"),

    # MIDI connection diagrams - 31968 bytes each, likely 296x108 at 8bpp or 148x216
    "BitmapMIDIConnections_1.bin": (296, 108, 8, "MIDI connections diagram 1"),
    "BitmapMIDIConnections_2.bin": (296, 108, 8, "MIDI connections diagram 2"),
    "BitmapMIDIConnections_3.bin": (296, 108, 8, "MIDI connections diagram 3"),

    # Other UI elements - dimensions from assembly code
    "BitmapWormWearingHat.bin": (24, 24, 8, "Easter egg - worm wearing hat"),
    # SomeArrows: a2=0x126=294, 1764/294=6
    "BitmapSomeArrows.bin": (294, 6, 8, "Arrow icons strip"),
    # FadeInPicture: a2=0x70=112, 2800/112=25
    "BitmapFadeInPicture.bin": (112, 25, 8, "Fade in picture effect"),
    # FadeOutPicture: a2=0x71=113, 2850/114=25 (padded stride)
    "BitmapFadeOutPicture.bin": (114, 25, 8, "Fade out picture effect"),
    # FadeInText: a2=0x50=80, 1440/80=18
    "BitmapFadeInText.bin": (80, 18, 8, "Fade in text effect"),
    # FadeOutText: a2=0x6C=108, 2160/108=20
    "BitmapFadeOutText.bin": (108, 20, 8, "Fade out text effect"),

    # Larger graphics - dimensions from assembly code
    # Accger16: a2=0x78=120, 11400/120=95
    "BitmapAccger16.bin": (120, 95, 8, "Accompaniment graphic (German)"),
    # Accita16: a2=0x78=120, 11400/120=95
    "BitmapAccita16.bin": (120, 95, 8, "Accompaniment graphic (Italian)"),
    # Bmphk: a2=0x64=100, 12000/100=120
    "BitmapBmphk.bin": (100, 120, 8, "Unknown graphic"),
    # Dredt0d: a2=0xA8=168, 19992/168=119
    "BitmapDredt0d.bin": (168, 119, 8, "Unknown graphic"),
    # Dredt0k: a2=0x58=88, 10472/88=119
    "BitmapDredt0k.bin": (88, 119, 8, "Unknown graphic"),
    # Ntedt0d: a2=0xF0=240, 30480/240=127
    "BitmapNtedt0d.bin": (240, 127, 8, "Note edit graphic"),
    # Ntedt0k: a2=0x10=16, 2032/16=127
    "BitmapNtedt0k.bin": (127, 16, 8, "Note edit graphic small"),

    # HDAE5000 Hard Disk Expansion ROM images (320x240, 8-bit grayscale)
    # These images are stored in the HD-AE5000 expansion ROM at specific offsets
    # ROM offset 0x28c00: Logo with hard disk graphic
    "HDAE5000_Logo.bin": (320, 240, 8, "HD-AE5000 product logo with hard disk graphic"),
    # ROM offset 0x3b800: Hands operating the unit
    "HDAE5000_Hands.bin": (320, 240, 8, "Hands operating HD-AE5000 unit"),
    # ROM offset 0x4e400: File selection UI
    "HDAE5000_FilePanel.bin": (320, 240, 8, "File selection UI panel"),
    # ROM offset 0x60400: Startup screen
    "HDAE5000_StartupScreen.bin": (320, 240, 8, "HD-AE5000 Version 2 startup screen"),
}


def convert_1bit_image(data: bytes, width: int, height: int) -> Image.Image:
    """Convert 1-bit packed bitmap to PIL Image.

    Note: 1-bit images are stored bottom-to-top, so we flip the y-axis.
    """
    img = Image.new('1', (width, height), 1)  # White background
    pixels = img.load()

    bytes_per_row = (width + 7) // 8

    for y in range(height):
        for x in range(width):
            byte_idx = y * bytes_per_row + x // 8
            if byte_idx < len(data):
                bit_idx = 7 - (x % 8)
                pixel = (data[byte_idx] >> bit_idx) & 1
                pixels[x, height - 1 - y] = pixel  # Flip y-axis

    return img


def convert_8bit_image(data: bytes, width: int, height: int, palette: list = None) -> Image.Image:
    """Convert 8-bit indexed bitmap to PIL Image.

    If palette is provided, creates an indexed color image with the palette.
    Otherwise falls back to grayscale.
    """
    if palette:
        # Create indexed color image with palette
        img = Image.new('P', (width, height), 0)
        img.putpalette(palette)
        pixels = img.load()

        for y in range(height):
            for x in range(width):
                idx = y * width + x
                if idx < len(data):
                    pixels[x, y] = data[idx]

        # Convert to RGB for better PNG output
        img = img.convert('RGB')
    else:
        # Fallback to grayscale
        img = Image.new('L', (width, height), 255)
        pixels = img.load()

        for y in range(height):
            for x in range(width):
                idx = y * width + x
                if idx < len(data):
                    pixels[x, y] = data[idx]

    return img


def convert_4bit_image(data: bytes, width: int, height: int) -> Image.Image:
    """Convert 4-bit packed bitmap to PIL Image."""
    img = Image.new('L', (width, height), 255)
    pixels = img.load()

    for y in range(height):
        for x in range(width):
            byte_idx = (y * width + x) // 2
            if byte_idx < len(data):
                if x % 2 == 0:
                    pixel = (data[byte_idx] >> 4) & 0x0F
                else:
                    pixel = data[byte_idx] & 0x0F
                pixels[x, y] = pixel * 17  # Scale 0-15 to 0-255

    return img


def convert_image(bin_path: Path, output_dir: Path, palette: list = None) -> bool:
    """Convert a single .bin image to PNG."""
    filename = bin_path.name

    if filename not in IMAGE_METADATA:
        if filename == PALETTE_FILE:
            return False  # Skip the palette file itself
        print(f"  Warning: Unknown image {filename} - skipping (add to IMAGE_METADATA)")
        return False

    width, height, bit_depth, description = IMAGE_METADATA[filename]

    with open(bin_path, 'rb') as f:
        data = f.read()

    # Verify size matches expected
    if bit_depth == 1:
        expected_size = ((width + 7) // 8) * height
    elif bit_depth == 4:
        expected_size = ((width + 1) // 2) * height
    else:
        expected_size = width * height

    if len(data) != expected_size:
        print(f"  Warning: {filename} size mismatch: {len(data)} bytes, expected {expected_size}")
        print(f"           Dimensions {width}x{height} at {bit_depth}bpp may be wrong")
        # Try to convert anyway

    try:
        if bit_depth == 1:
            img = convert_1bit_image(data, width, height)
        elif bit_depth == 4:
            img = convert_4bit_image(data, width, height)
        else:
            img = convert_8bit_image(data, width, height, palette)

        output_name = bin_path.stem + ".png"
        output_path = output_dir / output_name
        img.save(output_path)
        color_info = "indexed color" if (bit_depth == 8 and palette) else f"{bit_depth}bpp"
        print(f"  Converted: {filename} -> {output_name} ({width}x{height}, {color_info})")
        return True

    except Exception as e:
        print(f"  Error converting {filename}: {e}")
        return False


def main():
    # Determine paths
    script_dir = Path(__file__).parent

    if len(sys.argv) > 1:
        output_dir = Path(sys.argv[1])
    else:
        output_dir = script_dir.parent / "kn5000-docs" / "assets" / "images" / "gallery"

    output_dir.mkdir(parents=True, exist_ok=True)

    # Image directories to process
    image_dirs = [
        ("Main CPU", script_dir / "maincpu" / "images"),
        ("HDAE5000", script_dir / "hdae5000" / "images"),
    ]

    print(f"Output directory: {output_dir}")

    # Load palette for 8-bit indexed color images (from maincpu)
    maincpu_images = script_dir / "maincpu" / "images"
    palette_path = maincpu_images / PALETTE_FILE
    palette = load_palette(palette_path)
    if palette:
        print(f"Loaded palette: {PALETTE_FILE}")
    else:
        print("Warning: No palette loaded, 8-bit images will be grayscale")
    print()

    total_converted = 0
    total_skipped = 0

    for dir_name, images_dir in image_dirs:
        if not images_dir.exists():
            print(f"Skipping {dir_name}: directory not found ({images_dir})")
            continue

        print(f"=== {dir_name} Images ===")
        print(f"Source: {images_dir}")

        bin_files = sorted(images_dir.glob("*.bin"))
        converted = 0
        skipped = 0

        for bin_path in bin_files:
            # HDAE5000 images don't use the main CPU palette (grayscale)
            use_palette = palette if dir_name != "HDAE5000" else None
            if convert_image(bin_path, output_dir, use_palette):
                converted += 1
            else:
                skipped += 1

        print(f"  {dir_name}: {converted} converted, {skipped} skipped")
        print()

        total_converted += converted
        total_skipped += skipped

    print(f"Total: {total_converted} converted, {total_skipped} skipped")

    if total_skipped > 0:
        print("\nTo add support for skipped images:")
        print("1. Determine dimensions from disassembly or experimentation")
        print("2. Add entry to IMAGE_METADATA in this script")
        print("3. Run again")


if __name__ == "__main__":
    main()
