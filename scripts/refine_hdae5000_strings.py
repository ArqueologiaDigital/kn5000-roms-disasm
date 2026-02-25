#!/usr/bin/env python3
"""Refine HDAE5000 binary includes: extract strings and add split points.

Operates on the already-split source to:
1. Convert HDAE5000_UI_Config .incbin to .asciz directives
2. Add split points in the large GFX_INIT_PARAMS section (252KB)
3. Convert HDAE5000_Display_Params string portions to assembly
"""

import re
import sys

BINARY_FILE = 'hdae5000/includes/code_29af2d_2fffff.bin'
SOURCE_FILE = 'hdae5000/hd-ae5000_v2_06i.s'
BIN_START = 0x29AF2D

# New split points within existing sections (addr -> (label, comment))
# These subdivide the huge GFX_INIT_PARAMS section
NEW_SPLIT_POINTS = {
    0x2BA1A6: ('HDAE5000_Font_Data', 'Font bitmap data (large block)'),
    0x2E1C82: ('HDAE5000_Config_Strings', 'Configuration and version strings'),
    0x2E21D8: ('HDAE5000_Test_Strings', 'PPORT test and debug strings'),
    0x2E2500: ('HDAE5000_Dir_Strings', 'Directory management strings'),
    0x2E2E76: ('HDAE5000_Char_Tables', 'Character set tables'),
    0x2E348F: ('HDAE5000_Path_Strings', 'File path and config strings'),
    0x2E365D: ('HDAE5000_UI_Icons', 'UI icon/pattern data with language IDs'),
    0x2E3704: ('HDAE5000_Multilingual_Messages', 'Trilingual UI messages (EN/DE/FR)'),
    0x2E5B80: ('HDAE5000_Lang_Codes', 'Language code strings and file types'),
}

# Sections to convert from .incbin to assembly directives
# (start_addr, end_addr) -> these will be replaced with parsed content
CONVERT_SECTIONS = {
    'UI_Config': (0x29BFE0, 0x29C0AA),
    'Display_Params': (0x2F8DCE, 0x2F94B2),
}


def load_binary():
    with open(BINARY_FILE, 'rb') as f:
        return f.read()


def parse_string_data(data, offset, length):
    """Parse a binary region into string/data directives."""
    lines = []
    i = 0
    while i < length:
        b = data[offset + i]

        # Check for a null-terminated string
        if 0x20 <= b <= 0x7e:
            start = i
            while i < length and 0x20 <= data[offset + i] <= 0x7e:
                i += 1
            s = data[offset + start:offset + i].decode('ascii')

            if i < length and data[offset + i] == 0x00:
                # Null-terminated string
                lines.append(f'\t.asciz "{s}"\n')
                i += 1  # skip null

                # Check for 0xFF alignment padding
                if i < length and data[offset + i] == 0xFF:
                    lines.append(f'\t.byte 0xff\n')
                    i += 1
            else:
                # Not null-terminated, emit as .ascii
                lines.append(f'\t.ascii "{s}"\n')
        elif b == 0x00:
            # Zero bytes - collect run
            start = i
            while i < length and data[offset + i] == 0x00:
                i += 1
            count = i - start
            if count == 1:
                lines.append('\t.byte 0x00\n')
            else:
                lines.append(f'\t.zero {count}\n')
        elif b == 0xFF:
            # FF bytes - collect run
            start = i
            while i < length and data[offset + i] == 0xFF:
                i += 1
            count = i - start
            if count == 1:
                lines.append('\t.byte 0xff\n')
            else:
                lines.append(f'\t.fill {count}, 1, 0xff\n')
        else:
            # Other non-printable bytes - collect run
            start = i
            while (i < length and
                   not (0x20 <= data[offset + i] <= 0x7e) and
                   data[offset + i] != 0x00 and
                   data[offset + i] != 0xFF):
                i += 1
            byte_vals = data[offset + start:offset + i]
            # Emit in groups of up to 16
            for j in range(0, len(byte_vals), 16):
                chunk = byte_vals[j:j + 16]
                hex_str = ', '.join(f'0x{bv:02x}' for bv in chunk)
                lines.append(f'\t.byte {hex_str}\n')

    return lines


def parse_display_params(data, offset, length):
    """Parse Display_Params with its mixed string/pointer structure."""
    lines = []
    i = 0

    while i < length:
        b = data[offset + i]

        # Check for a null-terminated string (4+ chars or known short ones)
        if 0x20 <= b <= 0x7e:
            start = i
            while i < length and 0x20 <= data[offset + i] <= 0x7e:
                i += 1
            s = data[offset + start:offset + i].decode('ascii')

            if i < length and data[offset + i] == 0x00:
                lines.append(f'\t.asciz "{s}"\n')
                i += 1
                # Check for padding
                if i < length and data[offset + i] == 0xFF:
                    lines.append('\t.byte 0xff\n')
                    i += 1
            else:
                lines.append(f'\t.ascii "{s}"\n')
        elif b == 0x00:
            # Zero bytes
            start = i
            while i < length and data[offset + i] == 0x00:
                i += 1
            count = i - start
            if count == 1:
                lines.append('\t.byte 0x00\n')
            else:
                lines.append(f'\t.zero {count}\n')
        else:
            # Binary data - collect
            start = i
            while (i < length and
                   not (0x20 <= data[offset + i] <= 0x7e) and
                   data[offset + i] != 0x00):
                i += 1
            byte_vals = data[offset + start:offset + i]
            for j in range(0, len(byte_vals), 16):
                chunk = byte_vals[j:j + 16]
                hex_str = ', '.join(f'0x{bv:02x}' for bv in chunk)
                lines.append(f'\t.byte {hex_str}\n')

    return lines


def process_file():
    binary = load_binary()

    with open(SOURCE_FILE, 'r') as f:
        lines = f.readlines()

    incbin_re = re.compile(
        r'(\s*)\.incbin\s+"includes/code_29af2d_2fffff\.bin"\s*,\s*(\d+)\s*,\s*(\d+)')

    changes = []  # (line_idx, line_idx_end, new_lines)

    for i, line in enumerate(lines):
        m = incbin_re.match(line)
        if not m:
            continue

        offset = int(m.group(2))
        count = int(m.group(3))
        addr_start = BIN_START + offset
        addr_end = addr_start + count

        # Check if we should add split points within this segment
        splits_here = sorted(
            (addr, name, comment)
            for addr, (name, comment) in NEW_SPLIT_POINTS.items()
            if addr_start < addr < addr_end
        )

        if splits_here:
            new_lines = []
            prev_offset = offset
            for addr, name, comment in splits_here:
                seg_offset = addr - BIN_START
                seg_count = seg_offset - prev_offset
                if seg_count > 0:
                    new_lines.append(
                        f'\t.incbin "includes/code_29af2d_2fffff.bin", '
                        f'{prev_offset}, {seg_count}\n')
                new_lines.append(f'\n{name}:\t; 0x{addr:06X}\n')
                new_lines.append(f'\t; {comment}\n')
                prev_offset = seg_offset

            # Remaining bytes
            remaining = count - (prev_offset - offset)
            if remaining > 0:
                new_lines.append(
                    f'\t.incbin "includes/code_29af2d_2fffff.bin", '
                    f'{prev_offset}, {remaining}\n')

            changes.append((i, i + 1, new_lines))
            print(f'  Split .incbin at offset {offset} ({count} bytes): '
                  f'{len(splits_here)} new labels')
            continue

        # Check if this is a section to convert to string directives
        if addr_start == 0x29BFE0 and addr_end == 0x29C0AA:
            new_lines = parse_string_data(binary, offset, count)
            changes.append((i, i + 1, new_lines))
            print(f'  Converted UI_Config ({count} bytes -> '
                  f'{len(new_lines)} lines)')

        elif addr_start == 0x2F8DCE and addr_end == 0x2F94B2:
            new_lines = parse_display_params(binary, offset, count)
            changes.append((i, i + 1, new_lines))
            print(f'  Converted Display_Params ({count} bytes -> '
                  f'{len(new_lines)} lines)')

    # Apply changes in reverse order
    changes.sort(key=lambda x: x[0], reverse=True)
    for start, end, new_lines in changes:
        lines[start:end] = new_lines

    with open(SOURCE_FILE, 'w') as f:
        f.writelines(lines)

    print(f'\nDone! Applied {len(changes)} changes.')


if __name__ == '__main__':
    process_file()
