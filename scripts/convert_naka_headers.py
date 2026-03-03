#!/usr/bin/env python3
"""Convert raw .byte NAKA widget headers to naka_header macro calls.

Replaces patterns like:
    .byte 0xNN, 0x00, 0x60, 0x01, ...remaining...
with:
    naka_header NAKA_TYPE_XXX
    .byte ...remaining...

When the header bytes appear on the same line as body bytes, splits the line:
the macro call goes on its own line, remaining bytes become a new .byte line.

Uses binary I/O to safely handle Latin-1 characters in kn5000_v10_program.s.
"""

import re
import sys
import os
import glob

# Map type byte values to named constants (semantic names known)
NAMED_TYPES = {
    0x16: 'NAKA_TYPE_DIAGLIST',
    0x1d: 'NAKA_TYPE_MENU_ITEM',
    0x1e: 'NAKA_TYPE_PANEL',
    0x2b: 'NAKA_TYPE_LABEL',
    0x2e: 'NAKA_TYPE_VALUE',
    0x2f: 'NAKA_TYPE_OPTION',
    0x30: 'NAKA_TYPE_SLIDER',
    0x31: 'NAKA_TYPE_GROUP',
    0x34: 'NAKA_TYPE_CONTAINER',
    0x66: 'NAKA_TYPE_LIST',
    0x6c: 'NAKA_TYPE_BITMAP',
}


def type_name(byte_val):
    """Get the NAKA_TYPE constant name for a given type byte."""
    if byte_val in NAMED_TYPES:
        return NAMED_TYPES[byte_val]
    return f'NAKA_TYPE_0x{byte_val:02X}'


def convert_line(line_bytes):
    """Convert a single line (as bytes). Returns list of output lines (as bytes)."""
    line = line_bytes.decode("latin-1")

    # Match: .byte 0xNN, 0x00, 0x60, 0x01 possibly followed by more bytes
    m = re.search(
        r"(\t)\.byte (0x[0-9a-fA-F]{2}), 0x00, 0x60, 0x01(, .+)?$",
        line
    )
    if not m:
        return [line_bytes]

    indent = m.group(1)
    type_str = m.group(2)
    trailing = m.group(3)  # e.g. ", 0x05, 0x00, 0xff, 0xff" or None
    type_val = int(type_str, 16)
    name = type_name(type_val)

    # Build macro line (preserve any label prefix before the .byte)
    prefix = line[:m.start()]
    macro_line = f"{prefix}{indent}naka_header {name}"

    result = []
    if trailing:
        # Split: macro on one line, remaining bytes on the next
        rest_bytes = trailing[2:]  # remove leading ", "
        result.append(macro_line.encode("latin-1"))
        body_line = f"{indent}.byte {rest_bytes}"
        result.append(body_line.encode("latin-1"))
    else:
        result.append(macro_line.encode("latin-1"))

    return result


def convert_file(filepath):
    """Convert raw NAKA headers in a single file. Returns count of replacements."""
    with open(filepath, 'rb') as f:
        data = f.read()

    lines = data.split(b"\n")
    count = 0
    new_lines = []

    for line_bytes in lines:
        converted = convert_line(line_bytes)
        if len(converted) != 1 or converted[0] != line_bytes:
            count += 1
        new_lines.extend(converted)

    if count > 0:
        with open(filepath, 'wb') as f:
            f.write(b"\n".join(new_lines))

    return count


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    # Files to process
    files = []

    # All naka/ files
    naka_dir = os.path.join(base, 'maincpu', 'naka')
    files.extend(sorted(glob.glob(os.path.join(naka_dir, '*.s'))))

    # Main program file
    main_prog = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')
    files.append(main_prog)

    total = 0
    for filepath in files:
        count = convert_file(filepath)
        if count > 0:
            name = os.path.relpath(filepath, base)
            print(f'  {name}: {count} headers converted')
            total += count

    print(f'\nTotal: {total} headers converted')


if __name__ == '__main__':
    main()
