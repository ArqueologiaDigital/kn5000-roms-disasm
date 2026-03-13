#!/usr/bin/env python3
"""
Decode Style UI ScreenData bytecode format.

Format: sequence of (opcode, sub/len, data...) commands.
For most opcodes, byte 2 is the total command length.
For op=0x02, byte 2 is a sub-type: 0x0a=VLINE (10 bytes), anything else=WIDGET (15 bytes).

Coordinates are little-endian 16-bit.
"""

import sys
import os
import struct

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def le16(data, off):
    return struct.unpack_from('<H', data, off)[0]


def cmd_size(op, sub_or_len, data, pos):
    """Determine total command size for an opcode."""
    if op == 0x02:
        # Sub-type byte, NOT length
        if sub_or_len == 0x0a:
            return 10  # VLINE: op + sub + 4x le16 coords
        else:
            return 15  # WIDGET: op + sub + id(2) + flags(2) + handler(7) + pos(2)
    elif op == 0x01:
        return 10  # HLINE: always 10
    elif op == 0x06:
        return sub_or_len  # Length byte
    elif op == 0x0a:
        return sub_or_len  # FILLED_RECT variants
    elif op == 0x00:
        return sub_or_len  # Variable
    elif op == 0x20:
        return sub_or_len  # STRING
    elif op == 0x03:
        return sub_or_len
    elif op == 0x04:
        return sub_or_len
    elif op == 0x0e:
        return sub_or_len
    elif op == 0x09:
        return sub_or_len
    elif op == 0x0b:
        return sub_or_len
    else:
        return sub_or_len  # Default: treat as length


def decode_commands(data):
    """Parse the bytecode into a list of (offset, opcode, sub, total_size, raw_bytes) tuples."""
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
            # Truncated
            commands.append((pos, op, sub, len(data) - pos, data[pos:len(data)]))
            break
        commands.append((pos, op, sub, size, data[pos:pos+size]))
        pos += size
    return commands


def fmt_widget_handler(data, start):
    """Format the 7-byte handler reference starting at data[start].
    Format: 06 addr_lo addr_mid addr_hi 00 param 00"""
    if start + 7 > len(data):
        return "???"
    if data[start] != 0x06:
        return f"raw={' '.join(f'{b:02x}' for b in data[start:start+7])}"
    addr = data[start+1] | (data[start+2] << 8) | (data[start+3] << 16)
    param = data[start+5]
    return f"handler=0x{addr:06x} param={param}"


def describe_command(op, sub, size, raw):
    """Return a human-readable description of a command."""
    if op == 0x01 and size == 10:
        x1, y1 = le16(raw, 2), le16(raw, 4)
        x2, y2 = le16(raw, 6), le16(raw, 8)
        return f"HLINE ({x1},{y1})-({x2},{y2})"

    if op == 0x02 and sub == 0x0a:
        x1, y1 = le16(raw, 2), le16(raw, 4)
        x2, y2 = le16(raw, 6), le16(raw, 8)
        return f"VLINE ({x1},{y1})-({x2},{y2})"

    if op == 0x02 and size == 15:
        wid = le16(raw, 2)
        flags = le16(raw, 4)
        handler_desc = fmt_widget_handler(raw, 6)
        x = raw[13]
        y = raw[14]
        return f"WIDGET sub=0x{sub:02x} id=0x{wid:04x} flags=0x{flags:04x} {handler_desc} pos=({x},{y})"

    if op == 0x06:
        if size == 5:
            addr = le16(raw, 2)
            param = raw[4]
            return f"REF addr=0x{addr:04x} param={param}"
        elif size == 10:
            wid = le16(raw, 2)
            flags = le16(raw, 4)
            return f"REF_EX id=0x{wid:04x} flags=0x{flags:04x} data={' '.join(f'{b:02x}' for b in raw[6:])}"
        else:
            return f"REF size={size} data={' '.join(f'{b:02x}' for b in raw[2:])}"

    if op == 0x0a:
        if size == 10:
            x1, y1 = le16(raw, 2), le16(raw, 4)
            x2, y2 = le16(raw, 6), le16(raw, 8)
            return f"FILLED_RECT ({x1},{y1})-({x2},{y2})"
        elif size == 8:
            return f"FILLED_RECT_8 data={' '.join(f'{b:02x}' for b in raw[2:])}"
        return f"FILLED_RECT size={size} data={' '.join(f'{b:02x}' for b in raw[2:])}"

    if op == 0x09 and size == 10:
        x1, y1 = le16(raw, 2), le16(raw, 4)
        x2, y2 = le16(raw, 6), le16(raw, 8)
        return f"RECT ({x1},{y1})-({x2},{y2})"

    if op == 0x20:
        text_bytes = raw[2:]
        printable = ''
        for b in text_bytes:
            if 0x20 <= b < 0x7f:
                printable += chr(b)
            elif b == 0x88:
                printable += '#'
            elif b == 0x8c:
                printable += 'b'
            else:
                printable += f'\\x{b:02x}'
        return f'STRING "{printable}"'

    if op == 0x00:
        return f"NOP/PAD size={size}"

    if op == 0x03:
        return f"SETUP size={size} data={' '.join(f'{b:02x}' for b in raw[2:min(22,size)])}"

    if op == 0x04:
        return f"CONTROL size={size} data={' '.join(f'{b:02x}' for b in raw[2:min(22,size)])}"

    if op == 0x0b:
        return f"BLOCK size={size} data={' '.join(f'{b:02x}' for b in raw[2:min(22,size)])}"

    if op == 0x0e:
        return f"CALLBACK size={size} data={' '.join(f'{b:02x}' for b in raw[2:min(22,size)])}"

    return f"OP_0x{op:02x} sub=0x{sub:02x} size={size} data={' '.join(f'{b:02x}' for b in raw[2:min(22,size)])}"


def main():
    src = os.path.join(REPO, 'maincpu', 'includes', 'style_ui_screendata_main.s')
    with open(src, 'rb') as f:
        text = f.read()

    raw_bytes = bytearray()
    for line in text.split(b'\n'):
        line = line.strip()
        if line.startswith(b'.byte'):
            # Strip comments (;) before parsing
            code = line.split(b';')[0]
            parts = code[5:].split(b',')
            for p in parts:
                p = p.strip()
                if p.startswith(b'0x'):
                    raw_bytes.append(int(p, 16))

    print(f"Total bytes: {len(raw_bytes)}")
    print()

    commands = decode_commands(raw_bytes)
    print(f"Total commands: {len(commands)}")
    print()

    # Group commands by sections
    prev_section = None
    for off, op, sub, size, raw in commands:
        desc = describe_command(op, sub, size, raw)

        # Detect section transitions
        section = None
        if op == 0x01 or (op == 0x02 and sub == 0x0a):
            section = "GRID"
        elif op == 0x02 and sub != 0x0a:
            section = "WIDGET"
        elif op == 0x06:
            section = "REF"
        elif op == 0x20:
            section = "STRING"
        elif op == 0x0a:
            section = "FILLED_RECT"

        if section != prev_section and section is not None:
            print(f"\n--- {section} section ---")
            prev_section = section

        print(f"[{off:5d}] op=0x{op:02x} sub=0x{sub:02x} size={size:3d}  {desc}")

    # Summary statistics
    print(f"\n\n=== Summary ===")
    op_counts = {}
    for off, op, sub, size, raw in commands:
        key = f"0x{op:02x}"
        op_counts[key] = op_counts.get(key, 0) + 1
    for k in sorted(op_counts.keys()):
        print(f"  op={k}: {op_counts[k]} commands")

    # Check for total byte coverage
    total_covered = sum(size for _, _, _, size, _ in commands)
    print(f"\n  Total bytes covered: {total_covered} / {len(raw_bytes)}")


if __name__ == '__main__':
    main()
