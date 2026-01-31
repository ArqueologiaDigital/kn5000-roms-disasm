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


def nibble_to_gray(nibble: int) -> int:
    """Convert 4-bit nibble value to 8-bit grayscale.

    Icons use 4bpp format with 16 grayscale levels.
    Scale 0-15 to 0-255.
    """
    return nibble * 17


def extract_icons(table_data_rom: bytes, maincpu_rom: bytes, output_dir: Path):
    """Extract all icons from the table data ROM."""

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

    # Standard icon size: 24x24 pixels at 4bpp (2 pixels per byte)
    ICON_WIDTH = 24
    ICON_HEIGHT = 24
    ICON_SIZE = (ICON_WIDTH * ICON_HEIGHT) // 2  # 288 bytes at 4bpp

    output_dir.mkdir(parents=True, exist_ok=True)

    for icon in icons:
        icon_id = icon['id']
        data_offset = icon['data_offset']

        dim1 = icon['dim1']
        dim2 = icon['dim2']

        # Check if this is a non-standard size icon
        # Standard icons are 24x24 (dim1=dim2=0x18=24)
        # Non-standard icons (173-175) have larger dimensions
        if dim1 != 0x18 or dim2 != 0x18:
            # For non-standard icons, use the dims as both width and height
            width = dim1
            height = dim2
        else:
            width = ICON_WIDTH
            height = ICON_HEIGHT

        # 4bpp format: 2 pixels per byte
        byte_count = (width * height) // 2

        # Extract pixel data
        pixel_data = table_data_rom[data_offset:data_offset + byte_count]

        if len(pixel_data) < byte_count:
            print(f"  Warning: Icon {icon_id} has insufficient data")
            continue

        # Create image
        img = Image.new('RGB', (width, height))
        pixels = img.load()

        # Decode 4bpp: high nibble = first pixel, low nibble = second pixel
        byte_idx = 0
        for y in range(height):
            for x in range(0, width, 2):
                if byte_idx < len(pixel_data):
                    byte_val = pixel_data[byte_idx]
                    # High nibble = first pixel, low nibble = second pixel
                    p1 = (byte_val >> 4) & 0x0F
                    p2 = byte_val & 0x0F
                    g1 = nibble_to_gray(p1)
                    g2 = nibble_to_gray(p2)
                    pixels[x, y] = (g1, g1, g1)
                    if x + 1 < width:
                        pixels[x + 1, y] = (g2, g2, g2)
                    byte_idx += 1

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
