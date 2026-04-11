#!/usr/bin/env python3
"""
Handle cross-line addr24 patterns where a 3-byte address straddles two .byte lines.
Uses binary I/O to preserve Latin-1 encoding.
"""

import os
import re
import tempfile

BASE = "/home/fsanches/compartilhado/kn5000-roms-disasm"

# Map of 3-byte LE addresses (low, mid, high) to symbol names
# Include both v9 and v10 addresses
ADDR_TO_SYM = {
    (0x64, 0x0a, 0xff): "Sprintf_Locked",
    (0x72, 0x0a, 0xff): "Sprintf_Locked",
    (0x3f, 0x0f, 0xff): "Strcpy",
    (0x4d, 0x0f, 0xff): "Strcpy",
    (0x4e, 0x0a, 0xff): "Math_MultiplyAccumulate",
    (0x5c, 0x0a, 0xff): "Math_MultiplyAccumulate",
    (0x72, 0x0e, 0xff): "Malloc",
    (0x80, 0x0e, 0xff): "Malloc",
    (0xe4, 0x0a, 0xff): "Free",
    (0xf2, 0x0a, 0xff): "Free",
    (0xa8, 0xf9, 0xfe): "SendPartDataBlock_Return5",
    (0xb3, 0xf9, 0xfe): "SendPartDataBlock_Return5",
}

def read_file(path):
    with open(path, 'rb') as f:
        return f.read()

def write_file(path, data):
    dirname = os.path.dirname(path)
    fd, tmp = tempfile.mkstemp(dir=dirname, suffix='.tmp')
    try:
        os.write(fd, data)
        os.close(fd)
        os.replace(tmp, path)
    except:
        os.close(fd)
        os.unlink(tmp)
        raise

def parse_byte_line(line):
    """Parse a .byte line and return (indent, values) or None."""
    stripped = line.lstrip(b'\t ')
    if not stripped.startswith(b'.byte '):
        return None
    indent = line[:len(line) - len(line.lstrip(b'\t '))]
    byte_str = stripped[6:]
    parts = [p.strip().rstrip(b',') for p in byte_str.split(b',')]
    try:
        values = [int(p, 0) for p in parts]
        return (indent, values)
    except ValueError:
        return None

def format_byte_line(indent, values):
    """Format byte values as a .byte line."""
    hex_vals = ', '.join(f'0x{v:02x}' for v in values)
    return indent + f'.byte {hex_vals}'.encode('ascii')

def format_addr24_line(indent, sym_name):
    """Format an addr24 macro call."""
    return indent + f'addr24 _addr24_{sym_name}'.encode('ascii')

def process_file_crossline(path):
    """Process a file for cross-line addr24 patterns."""
    data = read_file(path)
    lines = data.split(b'\n')

    changes = 0
    new_lines = []
    i = 0

    while i < len(lines):
        line = lines[i]
        parsed = parse_byte_line(line)

        if parsed is None:
            new_lines.append(line)
            i += 1
            continue

        indent, values = parsed

        # Check if this line has a trailing partial address that continues on next line
        # Look for addresses that span this line and the next
        next_parsed = None
        if i + 1 < len(lines):
            next_parsed = parse_byte_line(lines[i + 1])

        if next_parsed is None:
            # No next .byte line, just emit as-is
            new_lines.append(line)
            i += 1
            continue

        next_indent, next_values = next_parsed

        # Combine the two lines' values and look for addresses that span the boundary
        combined = values + next_values
        boundary = len(values)

        # Find addr24 matches that CROSS the boundary
        cross_matches = []
        for start in range(max(0, boundary - 2), min(boundary, len(combined) - 2)):
            triple = (combined[start], combined[start + 1], combined[start + 2])
            if triple in ADDR_TO_SYM:
                cross_matches.append((start, ADDR_TO_SYM[triple]))

        if not cross_matches:
            # No cross-boundary match, emit line as-is
            new_lines.append(line)
            i += 1
            continue

        # We have a cross-boundary match. Process both lines together.
        # Take the first match (should be at most one per boundary)
        start, sym = cross_matches[0]
        end = start + 3  # exclusive

        # Before the addr24: combined[0:start]
        # The addr24: combined[start:end]
        # After the addr24: combined[end:]
        # But we also need to handle the NEXT line's remaining values
        # that weren't part of the addr24

        # Check if the next line also has non-cross-boundary addr24 matches
        # that we already handled (skip) or new ones

        # For simplicity: emit prefix, addr24, then check remaining bytes
        # from the second line for their own addr24 matches

        prefix_values = combined[0:start]
        suffix_values = combined[end:]

        # Emit prefix if non-empty
        if prefix_values:
            new_lines.append(format_byte_line(indent, prefix_values))

        # Emit addr24
        new_lines.append(format_addr24_line(indent, sym))

        # Now handle the suffix (rest of second line after the addr24)
        # Check for additional addr24 patterns in the suffix
        # But these should already be within-line patterns that were handled
        # by the first script. So just check and emit.
        remaining = suffix_values
        while remaining:
            found = False
            for j in range(len(remaining) - 2):
                triple = (remaining[j], remaining[j+1], remaining[j+2])
                if triple in ADDR_TO_SYM:
                    if j > 0:
                        new_lines.append(format_byte_line(indent, remaining[0:j]))
                    new_lines.append(format_addr24_line(indent, ADDR_TO_SYM[triple]))
                    remaining = remaining[j+3:]
                    found = True
                    break
            if not found:
                if remaining:
                    new_lines.append(format_byte_line(indent, remaining))
                remaining = []

        changes += 1
        i += 2  # Skip both lines

    if changes > 0:
        write_file(path, b'\n'.join(new_lines))

    return changes

def main():
    print("Cross-line addr24 conversion...")

    files_to_process = [
        "midi/computer_interface_pcg.s",
        "ui/drawbar_panel_ui.s",
        "ui/ui_control_panel.s",
        "sequencer/seq_audio_mode.s",
        "ui_widgets/widget_dispatch.s",
    ]

    total = 0
    for rel_path in files_to_process:
        for version in ['v9', 'v10']:
            path = os.path.join(BASE, f"{version}/maincpu/{rel_path}")
            if os.path.exists(path):
                n = process_file_crossline(path)
                if n > 0:
                    print(f"  {version}/{rel_path}: {n} cross-line addr24 conversions")
                total += n

    print(f"Total cross-line conversions: {total}")

if __name__ == '__main__':
    main()
