#!/usr/bin/env python3
"""
Annotate style_ui_screendata_main.s with structural labels and comments.
Binary I/O for Latin-1 safety.

The screen data uses a bytecode format:
- op=0x01 len=10: HLINE (x1,y1)-(x2,y2) as 4x le16
- op=0x02 sub=0x0a: VLINE (10 bytes, same coord format)
- op=0x02 sub=other: WIDGET (15 bytes: id, flags, handler_ref, position)
- op=0x06 len=5/7/10: REF/LABELED_REF
- op=0x07 len=var: CONTROL
- op=0x09 len=10: RECT
- op=0x0a len=10: FILLED_RECT
- op=0x20 len=var: STRING (x, y, text...)
- op=0x03 len=var: SETUP/BLOCK
- op=0x04 len=var: CONTROL
- op=0x0e len=var: CALLBACK

For op=0x02, the second byte is a sub-type/flags, NOT a length.
All WIDGET commands are 15 bytes. VLINE (sub=0x0a) is 10 bytes.
"""

import os
import struct

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILE = os.path.join(REPO, 'maincpu', 'includes', 'style_ui_screendata_main.s')


def le16(data, off):
    return struct.unpack_from('<H', data, off)[0]


def extract_bytes(text):
    """Extract raw bytes from .byte directives."""
    raw = bytearray()
    for line in text.split(b'\n'):
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


def fmt_bytes(data, per_line=16):
    """Format bytes as .byte directives."""
    lines = []
    for i in range(0, len(data), per_line):
        chunk = data[i:i+per_line]
        hex_vals = ', '.join(f'0x{b:02x}' for b in chunk)
        lines.append(f'\t.byte {hex_vals}')
    return '\n'.join(lines)


def fmt_bytes_with_ascii(data, per_line=16):
    """Format bytes as .byte directives with ASCII comment."""
    lines = []
    for i in range(0, len(data), per_line):
        chunk = data[i:i+per_line]
        hex_vals = ', '.join(f'0x{b:02x}' for b in chunk)
        # ASCII representation
        ascii_str = ''
        for b in chunk:
            if 0x20 <= b < 0x7f:
                ascii_str += chr(b)
            elif b == 0x88:
                ascii_str += 'b'  # flat
            elif b == 0x8c:
                ascii_str += '#'  # sharp
            else:
                ascii_str += '.'
        lines.append(f'\t.byte {hex_vals}\t; "{ascii_str}"')
    return '\n'.join(lines)


def describe_widget(data, offset):
    """Describe a 15-byte WIDGET command."""
    sub = data[offset + 1]
    wid = le16(data, offset + 2)
    flags = le16(data, offset + 4)
    # Handler reference: bytes 6-12
    if data[offset + 6] == 0x06:
        addr = data[offset + 7] | (data[offset + 8] << 8) | (data[offset + 9] << 16)
        param = data[offset + 11]
        handler = f'handler=0x{addr:06x} param={param}'
    else:
        handler = f'raw={" ".join(f"{b:02x}" for b in data[offset+6:offset+13])}'
    x = data[offset + 13]
    y = data[offset + 14]
    return f'WIDGET id=0x{wid:04x} flags=0x{flags:04x} sub=0x{sub:02x} {handler} pos=({x},{y})'


def main():
    with open(FILE, 'rb') as f:
        text = f.read()

    raw = extract_bytes(text)
    assert len(raw) == 3531, f"Expected 3531 bytes, got {len(raw)}"

    # Build the annotated output
    out = []
    out.append(b'; ===========================================================================')
    out.append(b'; StyleUI_ScreenData_Main: Style UI Main Screen Layout')
    out.append(b'; ===========================================================================')
    out.append(b';')
    out.append(b'; Total: 3531 bytes')
    out.append(b'; Source: e0bb90_e0c95a.bin')
    out.append(b';')
    out.append(b'; Screen layout for the accompaniment style editor main view.')
    out.append(b'; The 320x240 LCD is divided into:')
    out.append(b';   - Top row (y=35): 4 chord name display boxes')
    out.append(b';   - 3 parameter rows at y=80, 125, 170 with 4 columns each')
    out.append(b';   - Bottom area (y=210-236): 8 filled rectangles + divider lines')
    out.append(b';')
    out.append(b'; Bytecode format: opcode(1) + length/subtype(1) + data(variable)')
    out.append(b'; For op=0x02 WIDGET: subtype byte is flags, size always 15 bytes')
    out.append(b';')
    out.append(b'; Widget handler addresses:')
    out.append(b';   0xe0bd98 - Parameter value display (BAL, VOL, etc.)')
    out.append(b';   0xe0c3a6 - Chord root name')
    out.append(b';   0xe0c3c6 - Chord type suffix')
    out.append(b';   0xe0c506 - Chord quality indicator')
    out.append(b';   0xe0c8cc - Track status display')
    out.append(b';   0x000eca - END REP marker')
    out.append(b';   0x000ef8 - Empty slot')
    out.append(b';   0x000f16 - Cursor position')
    out.append(b';   0x000f34 - Selection marker')
    out.append(b'; ===========================================================================')
    out.append(b'')

    # --- Section 1: Chord Name Box Grid (bytes 0-179) ---
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'; Chord Name Boxes (top row, y=35)')
    out.append(b'; 4 boxes with split horizontal lines and vertical corners')
    out.append(b'; Box positions: x=10-70, 74-134, 138-198, 202-262')
    out.append(b'; Each box: 2 HLINE + 2 VLINE + 1 REF (chord name widget)')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'')

    # Box 1: x=10-70
    out.append(b'; Chord box 1 (x=10..70)')
    out.append(fmt_bytes(raw[0:10]).encode('latin-1') + b'\t; HLINE (10,35)-(39,35)')
    out.append(fmt_bytes(raw[10:20]).encode('latin-1') + b'\t; HLINE (48,35)-(70,35)')
    out.append(fmt_bytes(raw[20:30]).encode('latin-1') + b'\t; VLINE (10,36)-(10,39)')
    out.append(fmt_bytes(raw[30:40]).encode('latin-1') + b'\t; VLINE (70,36)-(70,39)')
    out.append(fmt_bytes(raw[40:45]).encode('latin-1') + b'\t; REF chord_name_1, param=21')

    # Box 2: x=74-134
    out.append(b'; Chord box 2 (x=74..134)')
    out.append(fmt_bytes(raw[45:55]).encode('latin-1') + b'\t; HLINE (74,35)-(103,35)')
    out.append(fmt_bytes(raw[55:65]).encode('latin-1') + b'\t; HLINE (112,35)-(134,35)')
    out.append(fmt_bytes(raw[65:75]).encode('latin-1') + b'\t; VLINE (74,36)-(74,39)')
    out.append(fmt_bytes(raw[75:85]).encode('latin-1') + b'\t; VLINE (134,36)-(134,39)')
    out.append(fmt_bytes(raw[85:90]).encode('latin-1') + b'\t; REF chord_name_2, param=21')

    # Box 3: x=138-198
    out.append(b'; Chord box 3 (x=138..198)')
    out.append(fmt_bytes(raw[90:100]).encode('latin-1') + b'\t; HLINE (138,35)-(167,35)')
    out.append(fmt_bytes(raw[100:110]).encode('latin-1') + b'\t; HLINE (176,35)-(198,35)')
    out.append(fmt_bytes(raw[110:120]).encode('latin-1') + b'\t; VLINE (138,36)-(138,39)')
    out.append(fmt_bytes(raw[120:130]).encode('latin-1') + b'\t; VLINE (198,36)-(198,39)')
    out.append(fmt_bytes(raw[130:135]).encode('latin-1') + b'\t; REF chord_name_3, param=21')

    # Box 4: x=202-262
    out.append(b'; Chord box 4 (x=202..262)')
    out.append(fmt_bytes(raw[135:145]).encode('latin-1') + b'\t; VLINE (202,36)-(202,39)')
    out.append(fmt_bytes(raw[145:155]).encode('latin-1') + b'\t; VLINE (262,36)-(262,39)')
    out.append(fmt_bytes(raw[155:160]).encode('latin-1') + b'\t; REF chord_name_4, param=21')
    out.append(fmt_bytes(raw[160:170]).encode('latin-1') + b'\t; HLINE (202,35)-(231,35)')
    out.append(fmt_bytes(raw[170:180]).encode('latin-1') + b'\t; HLINE (240,35)-(262,35)')

    # --- Section 2: Parameter Grid (bytes 180-449) ---
    out.append(b'')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'; Parameter Grid Lines (3 rows x 4 columns)')
    out.append(b'; Row separators at y=80, 125, 170')
    out.append(b'; Column dividers at x=5, 73, 137, 201, 265')
    out.append(b'; Each row: 5 VLINE corners (5px tall) + 4 HLINE bars')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'')

    # Row 1: y=80
    out.append(b'; Row 1 (y=80)')
    for i, off in enumerate(range(180, 270, 10)):
        x1, y1 = le16(raw, off+2), le16(raw, off+4)
        x2, y2 = le16(raw, off+6), le16(raw, off+8)
        op_name = 'HLINE' if raw[off] == 0x01 else 'VLINE'
        comment = f'\t; {op_name} ({x1},{y1})-({x2},{y2})'
        out.append(fmt_bytes(raw[off:off+10]).encode('latin-1') + comment.encode('latin-1'))

    # Row 2: y=125
    out.append(b'; Row 2 (y=125)')
    for off in range(270, 360, 10):
        x1, y1 = le16(raw, off+2), le16(raw, off+4)
        x2, y2 = le16(raw, off+6), le16(raw, off+8)
        op_name = 'HLINE' if raw[off] == 0x01 else 'VLINE'
        comment = f'\t; {op_name} ({x1},{y1})-({x2},{y2})'
        out.append(fmt_bytes(raw[off:off+10]).encode('latin-1') + comment.encode('latin-1'))

    # Row 3: y=170
    out.append(b'; Row 3 (y=170)')
    for off in range(360, 450, 10):
        x1, y1 = le16(raw, off+2), le16(raw, off+4)
        x2, y2 = le16(raw, off+6), le16(raw, off+8)
        op_name = 'HLINE' if raw[off] == 0x01 else 'VLINE'
        comment = f'\t; {op_name} ({x1},{y1})-({x2},{y2})'
        out.append(fmt_bytes(raw[off:off+10]).encode('latin-1') + comment.encode('latin-1'))

    # --- Section 3: References (bytes 450-504) ---
    out.append(b'')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'; Row Label References & Control')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'')
    # 3 REF_EX (10 bytes each) + 3 REF (5 bytes each) + 1 NOP (10 bytes)
    out.append(fmt_bytes(raw[450:460]).encode('latin-1') + b'\t; REF_EX id=0x1187 row_label_1')
    out.append(fmt_bytes(raw[460:470]).encode('latin-1') + b'\t; REF_EX id=0x1189 row_label_2')
    out.append(fmt_bytes(raw[470:480]).encode('latin-1') + b'\t; REF_EX id=0x118b row_label_3')
    out.append(fmt_bytes(raw[480:485]).encode('latin-1') + b'\t; REF param=45')
    out.append(fmt_bytes(raw[485:490]).encode('latin-1') + b'\t; REF param=45')
    out.append(fmt_bytes(raw[490:495]).encode('latin-1') + b'\t; REF param=45')
    out.append(fmt_bytes(raw[495:505]).encode('latin-1') + b'\t; NOP/PAD')

    # --- Section 4: Control Widgets (bytes 505-629) ---
    out.append(b'')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'; Control Widgets (END REP, track status, cursor)')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'')
    # Widget at 505
    out.append(fmt_bytes(raw[505:520]).encode('latin-1') + b'\t; ' + describe_widget(raw, 505).encode('latin-1'))
    # STRING "END REP" at 520
    out.append(fmt_bytes(raw[520:552]).encode('latin-1') + b'\t; STRING "  END REP ..."')
    # NOP/control at 552
    out.append(fmt_bytes(raw[552:585]).encode('latin-1'))
    out.append(b'\t\t\t\t\t\t\t; control/setup block')
    # Widgets at 585, 600, 615
    out.append(fmt_bytes(raw[585:600]).encode('latin-1') + b'\t; ' + describe_widget(raw, 585).encode('latin-1'))
    out.append(fmt_bytes(raw[600:615]).encode('latin-1') + b'\t; ' + describe_widget(raw, 600).encode('latin-1'))
    out.append(fmt_bytes(raw[615:630]).encode('latin-1') + b'\t; ' + describe_widget(raw, 615).encode('latin-1'))

    # --- Section 5: Parameter Value Widgets (bytes 630-989) ---
    out.append(b'')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'; Parameter Value Widgets (24 slots, handler 0xe0bd98)')
    out.append(b'; 3 rows x 8 columns of parameter display cells')
    out.append(b';   Row 1 (y=8):  IDs 0x119b-0x11a2, pos x=33..61 step 4')
    out.append(b';   Row 2 (y=15): IDs 0x11a3-0x11aa, pos x=41..69 step 4')
    out.append(b';   Row 3 (y=22): IDs 0x11ab-0x11b2, pos x=49..77 step 4')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'')
    for off in range(630, 990, 15):
        desc = describe_widget(raw, off)
        out.append(fmt_bytes(raw[off:off+15]).encode('latin-1') + b'\t; ' + desc.encode('latin-1'))

    # --- Section 6: Chord Widgets (bytes 990-2069) ---
    out.append(b'')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'; Chord Root/Type/Quality Widgets (72 entries = 24 cells x 3 layers)')
    out.append(b'; Each cell has 3 widgets:')
    out.append(b';   1. Root name   (handler 0xe0c3a6, param=2)')
    out.append(b';   2. Type suffix (handler 0xe0c3c6, param=5)')
    out.append(b';   3. Quality     (handler 0xe0c506, param=2, id=0x11b3)')
    out.append(b'; Arranged in 3 rows matching the parameter grid:')
    out.append(b';   Row 1 (y=8):  8 cells, x=33..63 step ~4')
    out.append(b';   Row 2 (y=15): 8 cells, x=41..71 step ~4')
    out.append(b';   Row 3 (y=22): 8 cells, x=49..79 step ~4')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'')
    for off in range(990, 2070, 15):
        desc = describe_widget(raw, off)
        # Group into triplets with blank line every 3
        idx = (off - 990) // 15
        if idx > 0 and idx % 3 == 0:
            out.append(b'')
        out.append(fmt_bytes(raw[off:off+15]).encode('latin-1') + b'\t; ' + desc.encode('latin-1'))

    # --- Section 7: Chord Name String Tables (bytes 2070-2407) ---
    out.append(b'')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'; Chord Name & Type String Tables')
    out.append(b'; LCD character codes: 0x88=flat(b), 0x8c=sharp(#)')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'')

    # Chord root names (2070-2101, 32 bytes)
    out.append(b'; Chord root names (12 entries, 2 bytes each + 8 padding)')
    out.append(b'; C  Db D  Eb E  F  F# G  Ab A  Bb B')
    out.append(fmt_bytes_with_ascii(raw[2070:2102]).encode('latin-1'))

    # Chord type suffixes (2102-2407, ~306 bytes)
    out.append(b'')
    out.append(b'; Chord type names (5 bytes per entry)')
    out.append(b'; Row 1: (none) 7  Maj7 aug min min7 dim m7#5 mM7 7sus4 6')
    out.append(b'; Row 2: aug7 #5 7#5 79 7#9 M79 69 m6 m#5 m79 m69 sus4')
    out.append(b'; Row 3: 7b9 M7#5 M7b5 mM7#5   139b5 #9 13b9 13 #13#9 #13b9 #13')
    out.append(b'; Row 4: 13 #137 b11 m7 11 +7b11 add9 madd9')
    out.append(fmt_bytes_with_ascii(raw[2102:2408]).encode('latin-1'))

    # --- Section 8: Footer Strings and Control (bytes 2408-2447) ---
    out.append(b'')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'; Footer Labels and Control Bytes')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'')
    out.append(fmt_bytes_with_ascii(raw[2408:2448]).encode('latin-1'))

    # --- Section 9: Parameter Box Layout (bytes 2448-2963) ---
    out.append(b'')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'; Parameter Box Layout Data')
    out.append(b'; SETUP blocks defining rectangle regions for parameter editing')
    out.append(b'; Coordinate pairs (x1,y1,x2,y2) for selection highlight boxes')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'')

    # First SETUP block at 2448
    out.append(b'; SETUP block (op=0x03)')
    out.append(fmt_bytes(raw[2448:2459]).encode('latin-1') + b'\t; SETUP id=0x1192 handler=0xe0c52b')

    # Coordinate pair data - groups of rectangles
    # These appear to be (x_lo, x_hi, y_lo, y_hi) or similar packed coords
    out.append(b'; Selection box coordinates (8 bytes each: x1_lo x1_hi y1_lo y1_hi)')
    out.append(fmt_bytes(raw[2459:2491]).encode('latin-1'))

    # Second SETUP block
    out.append(b'')
    out.append(b'; SETUP block (op=0x03)')
    out.append(fmt_bytes(raw[2491:2502]).encode('latin-1') + b'\t; SETUP id=0x1191 handler=0xe0c556')

    # More coordinate data
    out.append(b'; Selection box coordinates (wide spacing, 8 positions)')
    out.append(fmt_bytes(raw[2502:2582]).encode('latin-1'))

    # Third SETUP block
    out.append(b'')
    out.append(b'; SETUP block (op=0x03)')
    out.append(fmt_bytes(raw[2582:2593]).encode('latin-1') + b'\t; SETUP id=0x118f handler=0xe0c5a1')

    # More coordinate data (32 beat positions)
    out.append(b'; Beat position coordinates (32 positions)')
    out.append(fmt_bytes(raw[2593:2849]).encode('latin-1'))

    # --- Section 10: Callback/Control entries ---
    out.append(b'')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'; Callback References')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'')
    out.append(fmt_bytes(raw[2849:2893]).encode('latin-1'))

    # --- Section 11: Bottom filled rectangles ---
    out.append(b'')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'; Bottom Bar Layout')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'')

    # Locate FILLED_RECT commands in the tail
    # From the decoder: offset ~3388 onwards has FILLED_RECT + HLINE commands
    # But also 2893-2963 has more control data
    out.append(b'; Control/status data and lookup tables')
    out.append(fmt_bytes(raw[2893:2964]).encode('latin-1'))

    # --- Section 12: Chord Enable Bitmap (bytes 2964-3027) ---
    out.append(b'')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'; Chord Recognition Enable Bitmap (64 bytes)')
    out.append(b'; 0x91 = chord type enabled, 0x2a = disabled')
    out.append(b'; Used to determine which chord types the auto-accompaniment recognizes')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'')
    out.append(fmt_bytes(raw[2964:3028]).encode('latin-1'))

    # --- Section 13: Second Widget Set + Footer (bytes 3028-3531) ---
    out.append(b'')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'; Second Parameter Widget Set & Bottom Grid')
    out.append(b'; Mirrors the first widget set with different flags (0x8560)')
    out.append(b'; Plus bottom bar: 8 FILLED_RECT + 6 HLINE at y=223')
    out.append(b'; ---------------------------------------------------------------------------')
    out.append(b'')

    # Widgets from 3028 to end
    pos = 3028
    while pos < len(raw):
        # Try to identify the command
        op = raw[pos]
        if op == 0x02 and pos + 15 <= len(raw) and raw[pos+1] != 0x0a:
            # WIDGET (15 bytes)
            desc = describe_widget(raw, pos)
            out.append(fmt_bytes(raw[pos:pos+15]).encode('latin-1') + b'\t; ' + desc.encode('latin-1'))
            pos += 15
        elif op == 0x0a and pos + 10 <= len(raw):
            # FILLED_RECT (10 bytes)
            x1, y1 = le16(raw, pos+2), le16(raw, pos+4)
            x2, y2 = le16(raw, pos+6), le16(raw, pos+8)
            out.append(fmt_bytes(raw[pos:pos+10]).encode('latin-1') +
                       f'\t; FILLED_RECT ({x1},{y1})-({x2},{y2})'.encode('latin-1'))
            pos += 10
        elif op == 0x01 and pos + 10 <= len(raw):
            # HLINE (10 bytes)
            x1, y1 = le16(raw, pos+2), le16(raw, pos+4)
            x2, y2 = le16(raw, pos+6), le16(raw, pos+8)
            out.append(fmt_bytes(raw[pos:pos+10]).encode('latin-1') +
                       f'\t; HLINE ({x1},{y1})-({x2},{y2})'.encode('latin-1'))
            pos += 10
        elif op == 0x20 and pos + 2 <= len(raw):
            # STRING (variable length)
            length = raw[pos+1]
            end = min(pos + length, len(raw))
            out.append(fmt_bytes(raw[pos:end]).encode('latin-1') + b'\t; STRING')
            pos = end
        else:
            # Unknown - output as raw bytes
            end = min(pos + 16, len(raw))
            out.append(fmt_bytes(raw[pos:end]).encode('latin-1'))
            pos = end

    # Write output
    output = b'\n'.join(out) + b'\n'

    with open(FILE, 'wb') as f:
        f.write(output)

    print(f"Wrote annotated file: {FILE}")
    print(f"Total bytes in data: {len(raw)}")


if __name__ == '__main__':
    main()
