#!/usr/bin/env python3
"""Refine HDAE5000 binary includes: extract strings and add split points.

Operates on the already-split source to:
1. Convert HDAE5000_UI_Config .incbin to .asciz directives
2. Add split points in the large GFX_INIT_PARAMS section (252KB)
3. Convert HDAE5000_Display_Params string portions to assembly
4. Convert HDAE5000_Multilingual_Messages to readable trilingual strings
5. Convert other string-heavy sections to assembly directives

French strings use Latin-1 encoding (accented chars: é=0xE9, è=0xE8, ê=0xEA).
These are emitted as .byte sequences after the ASCII portion.
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
# These are matched by start address
CONVERT_ADDRS = {
    0x29BFE0,   # UI_Config
    0x2E1C82,   # Config_Strings
    0x2E21D8,   # Test_Strings
    0x2E2500,   # Dir_Strings
    0x2E348F,   # Path_Strings
    0x2E3704,   # Multilingual_Messages
    0x2E5B80,   # Lang_Codes
    0x2F8DCE,   # Display_Params
}


def load_binary():
    with open(BINARY_FILE, 'rb') as f:
        return f.read()


def is_printable(b):
    """Check if byte is printable ASCII (0x20-0x7E)."""
    return 0x20 <= b <= 0x7e


def is_latin1_high(b):
    """Check if byte is a Latin-1 high character (accented letters etc.)."""
    return 0x80 <= b <= 0xFF and b not in (0xFF,)


def is_text_byte(b):
    """Check if byte could be part of a text string (ASCII or Latin-1 accented)."""
    return is_printable(b) or is_latin1_high(b)


def escape_string(s):
    """Escape special characters for assembly string literals."""
    return s.replace('\\', '\\\\').replace('"', '\\"')


def emit_string_with_encoding(data, offset, length, null_terminated=True):
    """Emit a string that may contain Latin-1 high bytes.

    Strategy: emit ASCII portions as .ascii/.asciz, high bytes as .byte.
    If the string is pure ASCII, emit as single .asciz/.ascii.
    If it contains high bytes, split into segments.
    """
    raw = data[offset:offset + length]

    # Check if pure ASCII
    if all(is_printable(b) for b in raw):
        s = escape_string(raw.decode('ascii'))
        if null_terminated:
            return [f'\t.asciz "{s}"\n']
        else:
            return [f'\t.ascii "{s}"\n']

    # Mixed: has Latin-1 high bytes. Emit as segments.
    lines = []
    i = 0
    while i < length:
        if is_printable(raw[i]):
            # ASCII run
            start = i
            while i < length and is_printable(raw[i]):
                i += 1
            s = escape_string(raw[start:i].decode('ascii'))
            if i == length and null_terminated:
                lines.append(f'\t.asciz "{s}"\n')
            else:
                lines.append(f'\t.ascii "{s}"\n')
        else:
            # High byte(s) - emit as .byte with Latin-1 comment
            start = i
            while i < length and not is_printable(raw[i]):
                i += 1
            byte_vals = raw[start:i]
            hex_str = ', '.join(f'0x{b:02x}' for b in byte_vals)
            # Add Latin-1 comment for readability
            try:
                latin1 = byte_vals.decode('latin-1')
                comment = f'  ; "{latin1}"'
            except Exception:
                comment = ''
            if i == length and null_terminated:
                lines.append(f'\t.byte {hex_str}{comment}\n')
                lines.append('\t.byte 0x00\n')
            else:
                lines.append(f'\t.byte {hex_str}{comment}\n')

    return lines


def parse_string_section(data, offset, length):
    """Parse a binary region into string/data directives.

    Handles Latin-1 encoded strings (French accented characters).
    """
    lines = []
    i = 0
    while i < length:
        b = data[offset + i]

        # Check for start of a text string (ASCII or Latin-1)
        if is_text_byte(b):
            start = i
            while i < length and is_text_byte(data[offset + i]):
                i += 1

            str_len = i - start
            if i < length and data[offset + i] == 0x00:
                # Null-terminated string
                str_lines = emit_string_with_encoding(
                    data, offset + start, str_len, null_terminated=True)
                lines.extend(str_lines)
                i += 1  # skip null

                # Check for 0xFF alignment padding
                if i < length and data[offset + i] == 0xFF:
                    lines.append('\t.byte 0xff\n')
                    i += 1
            else:
                # Not null-terminated
                str_lines = emit_string_with_encoding(
                    data, offset + start, str_len, null_terminated=False)
                lines.extend(str_lines)
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
                   not is_text_byte(data[offset + i]) and
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

        # Check if this section should be converted to string directives
        if addr_start in CONVERT_ADDRS:
            new_lines = parse_string_section(binary, offset, count)
            label_name = None
            # Find the label above this .incbin
            for j in range(i - 1, max(0, i - 5), -1):
                if ':' in lines[j] and not lines[j].strip().startswith(';'):
                    lm = re.match(r'(\w+):', lines[j])
                    if lm:
                        label_name = lm.group(1)
                        break
            changes.append((i, i + 1, new_lines))
            print(f'  Converted {label_name or hex(addr_start)} '
                  f'({count} bytes -> {len(new_lines)} lines)')

    # Apply changes in reverse order
    changes.sort(key=lambda x: x[0], reverse=True)
    for start, end, new_lines in changes:
        lines[start:end] = new_lines

    with open(SOURCE_FILE, 'w') as f:
        f.writelines(lines)

    print(f'\nDone! Applied {len(changes)} changes.')


if __name__ == '__main__':
    process_file()
