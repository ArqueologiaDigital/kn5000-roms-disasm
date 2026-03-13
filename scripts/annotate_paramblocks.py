#!/usr/bin/env python3
"""
Annotate all style_ui_paramblock_*.s files with per-command comments.

Uses the same ScreenData bytecode format as the screendata files.
Reads raw .byte data, decodes commands, and writes annotated .s files
with one .byte line per command plus trailing ; comment.

IMPORTANT: Uses binary I/O to preserve Latin-1 bytes in .s files.
"""

import os
import struct
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INCLUDES = os.path.join(REPO, 'maincpu', 'includes')


def le16(data, off):
    return struct.unpack_from('<H', data, off)[0]


def extract_bytes(filepath):
    """Extract raw bytes from .byte lines in a .s file."""
    raw = bytearray()
    with open(filepath, 'rb') as f:
        for line in f:
            line = line.strip()
            if line.startswith(b'.byte'):
                # Strip comments before parsing
                code = line.split(b';')[0]
                parts = code[5:].split(b',')
                for p in parts:
                    p = p.strip()
                    if p.startswith(b'0x'):
                        raw.append(int(p, 16))
    return raw


def cmd_size(op, sub, data, pos):
    """Determine total command size for an opcode."""
    if op == 0x02:
        if sub == 0x0a:
            return 10  # VLINE
        else:
            return 15  # WIDGET
    elif op == 0x01:
        return 10  # HLINE
    elif op == 0x09:
        return 10  # RECT
    elif op == 0x0a:
        return 10  # FILLED_RECT (standard)
    elif op == 0x08:
        return sub  # STRING variant (sub=length)
    elif op == 0x23:
        return sub  # Another STRING variant
    else:
        return sub  # Default: sub_or_len is the length


def decode_commands(data):
    """Parse bytecode into list of (offset, op, sub, size, raw_bytes)."""
    commands = []
    pos = 0
    while pos < len(data):
        if pos + 1 >= len(data):
            commands.append((pos, data[pos], 0, 1, data[pos:pos+1]))
            break
        op = data[pos]
        sub = data[pos + 1]
        size = cmd_size(op, sub, data, pos)
        if size < 2:
            size = 2
        if pos + size > len(data):
            commands.append((pos, op, sub, len(data) - pos, data[pos:]))
            break
        commands.append((pos, op, sub, size, data[pos:pos+size]))
        pos += size
    return commands


def fmt_char(b):
    """Format a byte as a display character."""
    if b == 0x8d:
        return '|'  # vertical bar
    elif b == 0x8e:
        return '~'  # tilde/arrow (down arrow)
    elif b == 0x88:
        return 'b'  # flat
    elif b == 0x8c:
        return '#'  # sharp
    elif 0x20 <= b < 0x7f:
        return chr(b)
    else:
        return f'\\x{b:02x}'


def describe_command(op, sub, size, raw):
    """Return human-readable description of a command."""
    # STRING (op=0x20): len=sub, then x, y, text...
    if op == 0x20:
        if size >= 4:
            x = raw[2]
            y = raw[3]
            text = ''.join(fmt_char(b) for b in raw[4:])
            if not text:
                text = fmt_char(raw[3]) if size == 3 else ''
            return f'STRING "{text}" at ({x},{y})'
        return f'STRING size={size}'

    # HLINE (op=0x01, 10 bytes)
    if op == 0x01 and size == 10:
        x1, y1 = le16(raw, 2), le16(raw, 4)
        x2, y2 = le16(raw, 6), le16(raw, 8)
        return f'HLINE ({x1},{y1})-({x2},{y2})'

    # VLINE (op=0x02, sub=0x0a)
    if op == 0x02 and sub == 0x0a:
        x1, y1 = le16(raw, 2), le16(raw, 4)
        x2, y2 = le16(raw, 6), le16(raw, 8)
        return f'VLINE ({x1},{y1})-({x2},{y2})'

    # WIDGET (op=0x02, size=15)
    if op == 0x02 and size == 15:
        wid = le16(raw, 2)
        flags = le16(raw, 4)
        return f'WIDGET sub=0x{sub:02x} id=0x{wid:04x} flags=0x{flags:04x}'

    # RECT (op=0x09, 10 bytes)
    if op == 0x09 and size == 10:
        x1, y1 = le16(raw, 2), le16(raw, 4)
        x2, y2 = le16(raw, 6), le16(raw, 8)
        return f'RECT ({x1},{y1})-({x2},{y2})'

    # FILLED_RECT (op=0x0a, 10 bytes)
    if op == 0x0a and size == 10:
        x1, y1 = le16(raw, 2), le16(raw, 4)
        x2, y2 = le16(raw, 6), le16(raw, 8)
        return f'FILLED_RECT ({x1},{y1})-({x2},{y2})'

    # LABELED_REF (op=0x06): size=sub, data includes label text
    if op == 0x06:
        label_bytes = raw[4:size]
        label = ''.join(fmt_char(b) for b in label_bytes)
        addr = le16(raw, 2)
        return f'LABELED_REF "{label}" addr=0x{addr:04x}'

    # SHORTREF (op=0x07): size=sub
    if op == 0x07:
        if size > 8:
            # Large shortref may contain embedded text
            text_bytes = raw[4:]
            if all(0x20 <= b < 0x7f or b in (0x88, 0x8c, 0x8d, 0x8e) for b in text_bytes):
                text = ''.join(fmt_char(b) for b in text_bytes)
                x, y = raw[2], raw[3]
                return f'STRING_REF "{text}" at ({x},{y})'
        data_hex = ' '.join(f'{b:02x}' for b in raw[2:])
        return f'SHORTREF [{data_hex}]'

    # OP 0x08: embedded string/message
    if op == 0x08:
        if size >= 4:
            # Might be a different format - check for text
            x = raw[2]
            y = raw[3]
            text = ''.join(fmt_char(b) for b in raw[4:])
            return f'MESSAGE "{text}" at ({x},{y})'
        return f'OP_0x08 size={size}'

    # OP 0x23: another ref/string type
    if op == 0x23:
        data_hex = ' '.join(f'{b:02x}' for b in raw[2:])
        return f'OP_0x23 [{data_hex}]'

    # Default
    data_hex = ' '.join(f'{b:02x}' for b in raw[2:min(20, size)])
    return f'OP_0x{op:02x} sub=0x{sub:02x} size={size} [{data_hex}]'


def fmt_bytes_line(raw):
    """Format raw bytes as a .byte line."""
    return '\t.byte ' + ', '.join(f'0x{b:02x}' for b in raw)


def collect_screen_elements(commands):
    """Analyze commands to build a summary of screen elements."""
    strings = []
    labeled_refs = []
    rects = []
    filled_rects = []
    hlines = []
    shortrefs = []
    messages = []
    other = []

    for off, op, sub, size, raw in commands:
        if op == 0x20 and size >= 4:
            x, y = raw[2], raw[3]
            text = ''.join(fmt_char(b) for b in raw[4:])
            strings.append((text, x, y))
        elif op == 0x06:
            label = ''.join(fmt_char(b) for b in raw[4:size])
            labeled_refs.append(label)
        elif op == 0x07:
            shortrefs.append(off)
        elif op == 0x09 and size == 10:
            x1, y1 = le16(raw, 2), le16(raw, 4)
            x2, y2 = le16(raw, 6), le16(raw, 8)
            rects.append((x1, y1, x2, y2))
        elif op == 0x0a and size == 10:
            x1, y1 = le16(raw, 2), le16(raw, 4)
            x2, y2 = le16(raw, 6), le16(raw, 8)
            filled_rects.append((x1, y1, x2, y2))
        elif op == 0x01 and size == 10:
            x1, y1 = le16(raw, 2), le16(raw, 4)
            x2, y2 = le16(raw, 6), le16(raw, 8)
            hlines.append((x1, y1, x2, y2))
        elif op == 0x08:
            if size >= 4:
                text = ''.join(fmt_char(b) for b in raw[4:])
                messages.append(text)
            else:
                other.append(off)
        else:
            other.append(off)

    return strings, labeled_refs, rects, filled_rects, hlines, shortrefs, messages


def generate_header(name, total_bytes, source, commands):
    """Generate header comment block."""
    strings, labeled_refs, rects, filled_rects, hlines, shortrefs, messages = \
        collect_screen_elements(commands)

    lines = []
    lines.append(f'; StyleUI_ParamBlock_{name}: Style UI parameter block ({name})')
    lines.append(f'; Total: {total_bytes} bytes')
    lines.append(f'; Source: {source}')
    lines.append(';')

    # Screen elements summary
    lines.append('; Screen elements:')
    if labeled_refs:
        lines.append(f';   Labeled REFs: {", ".join(repr(r) for r in labeled_refs)}')
    if strings:
        str_descs = []
        for text, x, y in strings:
            if text and text not in ('|', '~'):
                str_descs.append(f'"{text}" ({x},{y})')
        if str_descs:
            lines.append(f';   Labels: {", ".join(str_descs)}')
        # Count arrow pairs
        arrows_up = sum(1 for t, _, _ in strings if t == '|')
        arrows_dn = sum(1 for t, _, _ in strings if t == '~')
        nav_left = sum(1 for t, _, _ in strings if t == '<')
        nav_right = sum(1 for t, _, _ in strings if t == '>')
        if arrows_up or arrows_dn:
            lines.append(f';   Up/Down arrows: {arrows_up} up ("|"), {arrows_dn} down ("~")')
        if nav_left or nav_right:
            lines.append(f';   Navigation: "<" ">" arrows')
    if messages:
        lines.append(f';   Messages: {", ".join(repr(m) for m in messages)}')
    if rects:
        lines.append(f';   Selection RECTs: {len(rects)} (inner/outer pairs)')
    if filled_rects:
        lines.append(f';   FILLED_RECTs: {len(filled_rects)}')
    if hlines:
        lines.append(f';   HLINEs: {len(hlines)}')

    return lines


def annotate_file(filepath):
    """Annotate a single paramblock file."""
    basename = os.path.basename(filepath)
    # Extract name part: style_ui_paramblock_XXX.s -> XXX
    name = basename.replace('style_ui_paramblock_', '').replace('.s', '')
    # Format display name: BAL, COMMON, AltA, AltB, etc.
    name_map = {
        'bal': 'BAL', 'common': 'Common', 'extended': 'Extended',
        'medium': 'Medium', 'meas': 'MEAS', 'short': 'Short',
        'value': 'VALUE', 'alta': 'AltA', 'altb': 'AltB',
        'altc': 'AltC', 'altd': 'AltD', 'alte': 'AltE',
    }
    name_display = name_map.get(name, name[0].upper() + name[1:] if name else name)

    # Read existing header info
    source = ''
    with open(filepath, 'rb') as f:
        for line in f:
            line_str = line.decode('latin-1', errors='replace').strip()
            if line_str.startswith('; Source:'):
                source = line_str.split('Source:')[1].strip()
                break

    raw = extract_bytes(filepath)
    total_bytes = len(raw)
    commands = decode_commands(raw)

    # Verify total coverage
    total_covered = sum(size for _, _, _, size, _ in commands)
    if total_covered != total_bytes:
        print(f"  WARNING: {basename}: covered {total_covered}/{total_bytes} bytes")

    # Generate header
    header_lines = generate_header(name_display, total_bytes, source, commands)

    # Generate annotated .byte lines
    body_lines = []
    for off, op, sub, size, raw_cmd in commands:
        desc = describe_command(op, sub, size, raw_cmd)
        byte_line = fmt_bytes_line(raw_cmd)
        # Pad to align comments
        padding = max(1, 60 - len(byte_line))
        body_lines.append(f'{byte_line}{" " * padding}; {desc}')

    # Write output
    output = []
    for line in header_lines:
        output.append(line)
    output.append('')  # blank line after header
    for line in body_lines:
        output.append(line)
    output.append('')  # trailing newline

    with open(filepath, 'wb') as f:
        for line in output:
            f.write(line.encode('latin-1') + b'\n')

    print(f"  {basename}: {total_bytes} bytes, {len(commands)} commands")
    return len(commands)


# Special handling for ctlonly (mixed bytecode + data)
def annotate_ctlonly(filepath):
    """Annotate ctlonly file which has bytecode header + raw data tables."""
    basename = os.path.basename(filepath)
    # This file is special - only first 32 bytes are bytecode, rest is data
    # Read it to preserve the existing annotations
    print(f"  {basename}: SKIPPED (mixed bytecode + data tables, already annotated)")


def main():
    files = sorted(f for f in os.listdir(INCLUDES)
                   if f.startswith('style_ui_paramblock_') and f.endswith('.s'))

    print(f"Found {len(files)} paramblock files:")
    total_cmds = 0
    for f in files:
        path = os.path.join(INCLUDES, f)
        total_cmds += annotate_file(path)

    print(f"\nTotal: {total_cmds} commands across {len(files)} files")

    # Also handle screendata files that aren't already annotated
    # (ctlonly is special)


if __name__ == '__main__':
    main()
