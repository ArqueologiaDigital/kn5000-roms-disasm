#!/usr/bin/env python3
"""
Extract UI icons from KN5000 Table Data ROM.

Icon data discovered via DrawIcons routine analysis:
- Icon table at 0x938000 (table_data ROM offset 0x138000)
- 176 icons, each entry is 8 bytes
- Color lookup table at 0xEAABF2 (maincpu ROM offset 0xAABF2)
- Icons are 12x24 pixels at 8bpp

Usage:
    python extract_icons.py [output_dir]

Default output_dir is table_data/images/icons/
"""

import os
import sys
import struct
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow is required. Install with: pip install Pillow")
    sys.exit(1)


# Icon table location in table_data ROM
ICON_TABLE_OFFSET = 0x138000  # CPU address 0x938000
ICON_TABLE_BASE = 0x800000    # table_data ROM base address

# Color lookup table in maincpu ROM
COLOR_LUT_OFFSET = 0xAABF2    # CPU address 0xEAABF2


def load_color_lut(maincpu_rom: bytes) -> list:
    """Load the 256-entry 16-bit color lookup table."""
    lut = []
    for i in range(256):
        offset = COLOR_LUT_OFFSET + i * 2
        value = struct.unpack_from('<H', maincpu_rom, offset)[0]
        lut.append(value)
    return lut


def color16_to_rgb(color16: int) -> tuple:
    """Convert 16-bit color to RGB.

    The KN5000 uses a custom 16-bit format where:
    - High byte encodes one color channel
    - Low byte encodes another color channel

    Based on the LUT structure, it appears to be:
    - Bits 15-11: Red (5 bits)
    - Bits 10-8: Green high (3 bits)
    - Bits 7-3: Green low + Blue high mixed
    - Bits 2-0: Blue (3 bits)

    Actually examining the pattern more carefully:
    The table maps palette index to a custom 2-byte value.
    Let's try interpreting as RGB565 first.
    """
    # Try RGB565: RRRRRGGG GGGBBBBB
    r = (color16 >> 11) & 0x1F
    g = (color16 >> 5) & 0x3F
    b = color16 & 0x1F

    # Scale to 8-bit
    r = (r << 3) | (r >> 2)
    g = (g << 2) | (g >> 4)
    b = (b << 3) | (b >> 2)

    return (r, g, b)


def extract_icons(table_data_rom: bytes, maincpu_rom: bytes, output_dir: Path):
    """Extract all icons from the table data ROM."""

    # Load color lookup table
    color_lut = load_color_lut(maincpu_rom)

    # Parse icon table
    icons = []
    offset = ICON_TABLE_OFFSET
    icon_id = 0

    while True:
        # Read 8-byte entry
        entry = struct.unpack_from('<HHII', table_data_rom, offset)[:3]
        # Entry format: dim1, dim2, data_ptr (as 2 words)
        entry = struct.unpack_from('<HHI', table_data_rom, offset)
        dim1, dim2, data_ptr = entry

        # Check for end of table (null entry)
        if dim1 == 0 and dim2 == 0:
            break

        # Convert CPU address to ROM offset
        data_offset = data_ptr - ICON_TABLE_BASE

        icons.append({
            'id': icon_id,
            'dim1': dim1,
            'dim2': dim2,
            'data_ptr': data_ptr,
            'data_offset': data_offset
        })

        offset += 8
        icon_id += 1

    print(f"Found {len(icons)} icons in table")

    # Standard icon size from code analysis
    ICON_WIDTH = 12
    ICON_HEIGHT = 24
    ICON_SIZE = ICON_WIDTH * ICON_HEIGHT  # 288 bytes

    output_dir.mkdir(parents=True, exist_ok=True)

    for icon in icons:
        icon_id = icon['id']
        data_offset = icon['data_offset']

        # Determine actual dimensions
        # Most icons are 12x24, but some entries show different dims
        dim1 = icon['dim1']
        dim2 = icon['dim2']

        # The dims appear to be in a special format
        # 0x0018 = 24, 0x001b = 27, 0x001c = 28
        width = ICON_WIDTH
        height = ICON_HEIGHT

        # Check if this is a non-standard size icon
        # Standard icons are 12x24 (dim1=dim2=0x18=24)
        # Non-standard icons (173-175) have larger dimensions
        if dim1 != 0x18 or dim2 != 0x18:
            # For non-standard icons, use the dims as both width and height
            # dims=(27,27) means 27x27, dims=(28,28) means 28x28
            width = dim1
            height = dim2

        pixel_count = width * height

        # Extract pixel data
        pixel_data = table_data_rom[data_offset:data_offset + pixel_count]

        if len(pixel_data) < pixel_count:
            print(f"  Warning: Icon {icon_id} has insufficient data")
            continue

        # Create image
        img = Image.new('RGB', (width, height))
        pixels = img.load()

        for y in range(height):
            for x in range(width):
                idx = y * width + x
                color_idx = pixel_data[idx]
                color16 = color_lut[color_idx]
                rgb = color16_to_rgb(color16)
                pixels[x, y] = rgb

        # Save icon
        output_path = output_dir / f"Icon_{icon_id:03d}.png"
        img.save(output_path)

    print(f"Extracted {len(icons)} icons to {output_dir}")

    # Generate summary
    print("\nIcon summary:")
    print(f"  Standard size: {ICON_WIDTH}x{ICON_HEIGHT}")
    print(f"  Total icons: {len(icons)}")

    # Find non-standard icons
    non_standard = [i for i in icons if i['dim1'] != 0x18 or i['dim2'] != 0x18]
    if non_standard:
        print(f"  Non-standard size icons: {len(non_standard)}")
        for icon in non_standard:
            print(f"    Icon {icon['id']}: dims=({icon['dim1']}, {icon['dim2']})")

    # Create sprite sheet for gallery (16 icons per row)
    create_sprite_sheet(icons, output_dir, ICON_WIDTH, ICON_HEIGHT)


def create_sprite_sheet(icons, output_dir: Path, std_width: int, std_height: int):
    """Create a combined sprite sheet of all standard icons for the gallery."""

    # Only include standard size icons in the sprite sheet
    std_icons = [i for i in icons if i['dim1'] == 0x18 and i['dim2'] == 0x18]

    if not std_icons:
        return

    icons_per_row = 16
    num_rows = (len(std_icons) + icons_per_row - 1) // icons_per_row

    sheet_width = icons_per_row * std_width
    sheet_height = num_rows * std_height

    sheet = Image.new('RGB', (sheet_width, sheet_height), (128, 128, 128))

    for idx, icon_info in enumerate(std_icons):
        icon_id = icon_info['id']
        icon_path = output_dir / f"Icon_{icon_id:03d}.png"
        if icon_path.exists():
            icon_img = Image.open(icon_path)
            x = (idx % icons_per_row) * std_width
            y = (idx // icons_per_row) * std_height
            sheet.paste(icon_img, (x, y))

    sprite_sheet_path = output_dir / "IconSpriteSheet.png"
    sheet.save(sprite_sheet_path)
    print(f"\nCreated sprite sheet: {sprite_sheet_path}")
    print(f"  Size: {sheet_width}x{sheet_height} ({len(std_icons)} standard icons)")


def main():
    script_dir = Path(__file__).parent
    project_dir = script_dir.parent

    # ROM file paths
    table_data_path = project_dir / "original_ROMs" / "kn5000_table_data.rom"
    maincpu_path = project_dir / "original_ROMs" / "kn5000_v10_program.rom"

    if not table_data_path.exists():
        print(f"Error: Table data ROM not found: {table_data_path}")
        sys.exit(1)

    if not maincpu_path.exists():
        print(f"Error: Main CPU ROM not found: {maincpu_path}")
        sys.exit(1)

    # Output directory
    if len(sys.argv) > 1:
        output_dir = Path(sys.argv[1])
    else:
        output_dir = project_dir / "table_data" / "images" / "icons"

    print(f"Loading ROMs...")
    print(f"  Table data: {table_data_path}")
    print(f"  Main CPU: {maincpu_path}")

    with open(table_data_path, 'rb') as f:
        table_data_rom = f.read()

    with open(maincpu_path, 'rb') as f:
        maincpu_rom = f.read()

    print(f"Output directory: {output_dir}")
    print()

    extract_icons(table_data_rom, maincpu_rom, output_dir)


if __name__ == "__main__":
    main()
