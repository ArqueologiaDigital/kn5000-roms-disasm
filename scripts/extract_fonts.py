#!/usr/bin/env python3
"""Extract font glyphs from KN5000 Table Data ROM.

The KN5000 stores a font glyph table at address 0x945C00 in the table data ROM.
Each font entry is 16 bytes:
  +0x00: word width (pixels per character)
  +0x02: word height (pixels)
  +0x04: word descent (pixels below baseline)
  +0x06: word ascent (pixels above baseline)
  +0x08: long glyph_data_ptr (24-bit pointer to 1bpp bitmap data)
  +0x0C: long kerning_table_ptr (0 = fixed-width; non-zero = per-char widths)

Glyphs are 1bpp bitmaps, 8 pixels per byte, MSB first.
Characters use ASCII with 0x20 offset (char 0 = space, char 1 = '!', etc.)

Usage:
  python scripts/extract_fonts.py [output_dir]

Outputs PGM atlas images and BDF font files for each valid font.
"""

import struct
import sys
from pathlib import Path

# Table data ROM maps to 0x800000-0x9FFFFF in the KN5000 address space
TABLE_DATA_BASE = 0x800000
TABLE_DATA_SIZE = 0x200000  # 2MB combined
MAIN_ROM_BASE = 0xE00000
MAIN_ROM_SIZE = 0x200000

# Font table location
FONT_TABLE_ADDR = 0x945C00
FONT_ENTRY_SIZE = 16
NUM_FONTS = 10  # Font IDs 0-9 (10-15 are empty/garbage)

# ASCII printable range (0x20-0x7E = 95 characters)
FIRST_CHAR = 0x20  # space
LAST_CHAR = 0x7E   # tilde
NUM_CHARS = LAST_CHAR - FIRST_CHAR + 1


def read_word(data, offset):
    """Read 16-bit little-endian word."""
    return struct.unpack_from('<H', data, offset)[0]


def read_long(data, offset):
    """Read 32-bit little-endian long (only low 24 bits are address)."""
    return struct.unpack_from('<I', data, offset)[0] & 0xFFFFFF


def resolve_addr(addr, table_rom, main_rom):
    """Resolve a 24-bit CPU address to a byte in the ROM data."""
    if TABLE_DATA_BASE <= addr < TABLE_DATA_BASE + TABLE_DATA_SIZE:
        off = addr - TABLE_DATA_BASE
        if off < len(table_rom):
            return table_rom, off
    if MAIN_ROM_BASE <= addr < MAIN_ROM_BASE + MAIN_ROM_SIZE:
        off = addr - MAIN_ROM_BASE
        if off < len(main_rom):
            return main_rom, off
    return None, None


def extract_font_entry(rom_data, font_id):
    """Extract a single font entry from the table."""
    table_offset = FONT_TABLE_ADDR - TABLE_DATA_BASE
    entry_offset = table_offset + font_id * FONT_ENTRY_SIZE

    width = read_word(rom_data, entry_offset + 0)
    height = read_word(rom_data, entry_offset + 2)
    descent = read_word(rom_data, entry_offset + 4)
    ascent = read_word(rom_data, entry_offset + 6)
    glyph_ptr = read_long(rom_data, entry_offset + 8)
    kerning_ptr = read_long(rom_data, entry_offset + 12)

    return {
        'id': font_id,
        'width': width,
        'height': height,
        'descent': descent,
        'ascent': ascent,
        'glyph_ptr': glyph_ptr,
        'kerning_ptr': kerning_ptr,
    }


def extract_glyph(table_rom, main_rom, glyph_ptr, width, height,
                   char_index, kerning_ptr):
    """Extract a single character glyph as a 2D pixel array.

    Returns (pixel_array, char_width).

    For variable-width fonts (kerning_ptr != 0), the kerning table has
    4-byte entries per character: {word char_width, word glyph_offset}.
    Each glyph uses ceil(char_width/8) * height bytes at glyph_ptr + offset.

    For fixed-width fonts, glyph N is at glyph_ptr + N * (ceil(width/8) * height).
    """
    if kerning_ptr != 0:
        # Variable-width font: read {width, offset} from 4-byte kerning entry
        rom, off = resolve_addr(kerning_ptr + char_index * 4, table_rom, main_rom)
        if rom is None or off + 4 > len(rom):
            return None, 0
        char_width = read_word(rom, off)
        glyph_offset = read_word(rom, off + 2)
        glyph_addr = glyph_ptr + glyph_offset
        columns = (char_width + 7) // 8
    else:
        # Fixed-width font
        char_width = width
        columns = (width + 7) // 8
        glyph_size = columns * height
        glyph_addr = glyph_ptr + char_index * glyph_size

    if char_width == 0 or height == 0:
        return None, char_width

    glyph_size = columns * height
    rom, off = resolve_addr(glyph_addr, table_rom, main_rom)
    if rom is None or off + glyph_size > len(rom):
        return None, char_width

    data = rom[off:off + glyph_size]
    actual_width = columns * 8

    # Decode 1bpp bitmap
    # Data: columns of height bytes each, 8 pixels per byte, MSB first
    pixels = [[0] * actual_width for _ in range(height)]
    for col in range(columns):
        x_base = col * 8
        for row in range(height):
            byte_idx = col * height + row
            if byte_idx < len(data):
                byte = data[byte_idx]
                for bit in range(8):
                    x = x_base + bit
                    if x < actual_width:
                        pixels[row][x] = 1 if (byte & (0x80 >> bit)) else 0

    # Trim to actual char_width
    trimmed = [row[:char_width] for row in pixels]
    return trimmed, char_width


def render_font_to_pgm(font_info, table_rom, main_rom, output_path):
    """Render all printable ASCII characters to a PGM atlas image."""
    width = font_info['width']
    height = font_info['height']
    glyph_ptr = font_info['glyph_ptr']
    kerning_ptr = font_info['kerning_ptr']

    if height == 0 or glyph_ptr == 0:
        return False

    # Extract all printable characters
    chars = []
    max_char_width = 0
    for i in range(NUM_CHARS):
        pixels, cw = extract_glyph(table_rom, main_rom, glyph_ptr, width,
                                   height, i, kerning_ptr)
        chars.append((pixels, cw))
        if cw > max_char_width:
            max_char_width = cw

    if max_char_width == 0:
        return False

    # Layout: 16 chars per row
    chars_per_row = 16
    num_rows = (NUM_CHARS + chars_per_row - 1) // chars_per_row
    cell_w = max_char_width + 1
    cell_h = height + 1
    img_w = chars_per_row * cell_w + 1
    img_h = num_rows * cell_h + 1

    # Build image as flat bytes for speed
    img = bytearray(b'\xff' * (img_w * img_h))

    # Draw grid lines (200 = light gray)
    for row_idx in range(num_rows + 1):
        y = row_idx * cell_h
        if y < img_h:
            for x in range(img_w):
                img[y * img_w + x] = 200
    for col_idx in range(chars_per_row + 1):
        x = col_idx * cell_w
        if x < img_w:
            for y in range(img_h):
                img[y * img_w + x] = 200

    # Render each character
    for i, (pixels, cw) in enumerate(chars):
        if pixels is None:
            continue
        col = i % chars_per_row
        row = i // chars_per_row
        x_off = col * cell_w + 1
        y_off = row * cell_h + 1

        for py in range(len(pixels)):
            for px in range(len(pixels[py])):
                if pixels[py][px]:
                    img[(y_off + py) * img_w + (x_off + px)] = 0

    # Write PGM (binary P5 for speed)
    with open(output_path, 'wb') as f:
        header = f'P5\n{img_w} {img_h}\n255\n'.encode()
        f.write(header)
        f.write(bytes(img))

    return True


def render_font_to_bdf(font_info, table_rom, main_rom, output_path):
    """Export font to BDF format (Bitmap Distribution Format)."""
    font_id = font_info['id']
    width = font_info['width']
    height = font_info['height']
    descent = font_info['descent']
    ascent = font_info['ascent']
    glyph_ptr = font_info['glyph_ptr']
    kerning_ptr = font_info['kerning_ptr']

    if height == 0 or glyph_ptr == 0:
        return False

    # Collect valid glyphs
    glyphs = []
    for i in range(NUM_CHARS):
        pixels, cw = extract_glyph(table_rom, main_rom, glyph_ptr, width,
                                   height, i, kerning_ptr)
        if pixels is not None and cw > 0:
            glyphs.append((FIRST_CHAR + i, pixels, cw))

    if not glyphs:
        return False

    # Use max width for BDF bounding box
    max_w = max(cw for _, _, cw in glyphs)
    font_name = f"KN5000-Font{font_id}"
    effective_width = max_w if width == 0 else width

    lines = []
    lines.append('STARTFONT 2.1')
    lines.append(f'FONT -{font_name}-medium-r-normal--{height}-{height*10}'
                 f'-72-72-c-{effective_width*10}-iso8859-1')
    lines.append(f'SIZE {height} 72 72')
    lines.append(f'FONTBOUNDINGBOX {effective_width} {height} 0 -{descent}')
    lines.append(f'STARTPROPERTIES 5')
    lines.append(f'FONT_ASCENT {ascent}')
    lines.append(f'FONT_DESCENT {descent}')
    lines.append(f'PIXEL_SIZE {height}')
    lines.append(f'POINT_SIZE {height * 10}')
    lines.append(f'DEFAULT_CHAR {FIRST_CHAR}')
    lines.append(f'ENDPROPERTIES')
    lines.append(f'CHARS {len(glyphs)}')

    for encoding, pixels, cw in glyphs:
        bdf_width = ((cw + 7) // 8) * 8
        bytes_per_row = bdf_width // 8

        lines.append(f'STARTCHAR U+{encoding:04X}')
        lines.append(f'ENCODING {encoding}')
        lines.append(f'SWIDTH {cw * 1000 // max(height, 1)} 0')
        lines.append(f'DWIDTH {cw} 0')
        lines.append(f'BBX {cw} {height} 0 -{descent}')
        lines.append(f'BITMAP')

        for row in pixels:
            hex_str = ''
            for b in range(bytes_per_row):
                byte_val = 0
                for bit in range(8):
                    px = b * 8 + bit
                    if px < len(row) and row[px]:
                        byte_val |= (0x80 >> bit)
                hex_str += f'{byte_val:02X}'
            lines.append(hex_str)

        lines.append('ENDCHAR')

    lines.append('ENDFONT')

    with open(output_path, 'w') as f:
        f.write('\n'.join(lines) + '\n')

    return True


def main():
    script_dir = Path(__file__).parent.parent
    rom_dir = script_dir / 'original_ROMs'
    table_rom_path = rom_dir / 'kn5000_table_data.rom'
    main_rom_path = rom_dir / 'kn5000_v10_program.rom'

    if len(sys.argv) > 1:
        output_dir = Path(sys.argv[1])
    else:
        output_dir = script_dir / 'extracted_fonts'
    output_dir.mkdir(exist_ok=True)

    print("Loading table data ROM (pre-combined)...")
    with open(table_rom_path, 'rb') as f:
        table_rom = f.read()
    print(f"  Size: {len(table_rom)} bytes")

    print("Loading main program ROM...")
    with open(main_rom_path, 'rb') as f:
        main_rom = f.read()
    print(f"  Size: {len(main_rom)} bytes")

    print(f"\nFont table at 0x{FONT_TABLE_ADDR:06X} "
          f"(ROM offset 0x{FONT_TABLE_ADDR - TABLE_DATA_BASE:06X})")
    print('=' * 72)

    valid_fonts = 0
    for font_id in range(NUM_FONTS):
        info = extract_font_entry(table_rom, font_id)

        rom_region = "table_data"
        _, off = resolve_addr(info['glyph_ptr'], table_rom, main_rom)
        if off is None:
            _, off = resolve_addr(info['glyph_ptr'], b'', main_rom)
            if off is not None:
                rom_region = "main_rom"
            else:
                rom_region = "unknown"

        kern_str = f"  kern=0x{info['kerning_ptr']:06X}" if info['kerning_ptr'] else ''
        print(f"\nFont {font_id:2d}: {info['width']:3d}x{info['height']:2d} "
              f"(ascent={info['ascent']}, descent={info['descent']}) "
              f"glyph=0x{info['glyph_ptr']:06X} ({rom_region}) "
              f"{'varwidth' if info['kerning_ptr'] else 'fixed'}"
              f"{kern_str}")

        if info['height'] == 0 or info['glyph_ptr'] == 0:
            print("  [skipped: empty font entry]")
            continue

        # Export PGM atlas
        pgm_path = output_dir / f'font_{font_id:02d}.pgm'
        if render_font_to_pgm(info, table_rom, main_rom, str(pgm_path)):
            print(f"  -> {pgm_path}")
            valid_fonts += 1
        else:
            print("  [skipped: could not render]")
            continue

        # Export BDF
        bdf_path = output_dir / f'font_{font_id:02d}.bdf'
        if render_font_to_bdf(info, table_rom, main_rom, str(bdf_path)):
            print(f"  -> {bdf_path}")

    print(f"\n{'=' * 72}")
    print(f"Extracted {valid_fonts} fonts to {output_dir}/")


if __name__ == '__main__':
    main()
