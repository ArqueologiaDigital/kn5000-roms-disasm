#!/usr/bin/env python3
"""
Annotate all style_ui_paramblock_*.s files with struct-style field labels.

Each bytecode command is decomposed into named struct fields:

  struct ScreenData_String {      // op=0x20
      uint8_t  opcode;            // 0x20
      uint8_t  length;
      uint8_t  x, y;
      char     text[];            // length - 4 bytes
  };

  struct ScreenData_Line {        // op=0x01 (HLINE), op=0x02/sub=0x0a (VLINE)
      uint8_t  opcode;
      uint8_t  length;            // always 0x0a (10)
      uint16_t x1, y1, x2, y2;   // little-endian
  };

  struct ScreenData_Rect {        // op=0x09 (RECT), op=0x0a (FILLED_RECT)
      uint8_t  opcode;
      uint8_t  length;            // always 0x0a (10)
      uint16_t x1, y1, x2, y2;   // little-endian
  };

  struct ScreenData_LabeledRef {  // op=0x06
      uint8_t  opcode;            // 0x06
      uint8_t  length;
      uint16_t addr;              // little-endian
      char     label[];           // length - 4 bytes
  };

  struct ScreenData_ShortRef {    // op=0x07
      uint8_t  opcode;            // 0x07
      uint8_t  length;
      uint8_t  data[];            // length - 2 bytes
  };

  struct ScreenData_Message {     // op=0x08
      uint8_t  opcode;            // 0x08
      uint8_t  length;
      uint8_t  x, y;
      char     text[];            // length - 4 bytes
  };

  struct ScreenData_Widget {      // op=0x02, sub != 0x0a
      uint8_t  opcode;            // 0x02
      uint8_t  subtype;
      uint16_t id;                // little-endian
      uint16_t flags;             // little-endian
      uint8_t  handler[7];        // handler reference
      uint8_t  x, y;
  };

  struct ScreenData_Unknown {     // op=0x23, etc.
      uint8_t  opcode;
      uint8_t  length;
      uint8_t  data[];            // length - 2 bytes
  };

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
        return 10 if sub == 0x0a else 15
    elif op == 0x01:
        return 10
    elif op == 0x09:
        return 10
    elif op == 0x0a:
        return 10
    else:
        return sub  # sub_or_len is the length


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
        return '|'   # vertical bar
    elif b == 0x8e:
        return '~'   # down arrow
    elif b == 0x88:
        return 'b'   # flat
    elif b == 0x8c:
        return '#'   # sharp
    elif 0x20 <= b < 0x7f:
        return chr(b)
    else:
        return f'\\x{b:02x}'


def fmt_bytes(data):
    """Format bytes as 0x.. hex."""
    return ', '.join(f'0x{b:02x}' for b in data)


# --- Opcode names ---

OPCODE_NAMES = {
    0x01: 'HLINE',
    0x02: 'VLINE',  # sub=0x0a; otherwise WIDGET
    0x06: 'LABELED_REF',
    0x07: 'SHORT_REF',
    0x08: 'MESSAGE',
    0x09: 'RECT',
    0x0a: 'FILLED_RECT',
    0x20: 'STRING',
    0x23: 'UNKNOWN_23',
}


def opcode_name(op, sub):
    if op == 0x02 and sub != 0x0a:
        return 'WIDGET'
    return OPCODE_NAMES.get(op, f'UNKNOWN_0x{op:02X}')


# --- Struct-style field emitters ---
# Each returns a list of (bytes_str, comment) tuples for .byte lines.

def emit_string(op, sub, size, raw):
    """STRING: opcode, length, x, y, text[]"""
    lines = []
    name = opcode_name(op, sub)
    x, y = raw[2], raw[3]
    text = ''.join(fmt_char(b) for b in raw[4:])
    lines.append((fmt_bytes(raw[0:1]), f'.opcode  = {name}'))
    lines.append((fmt_bytes(raw[1:2]), f'.length  = {sub}'))
    lines.append((fmt_bytes(raw[2:4]), f'.x, .y   = ({x}, {y})'))
    if len(raw) > 4:
        lines.append((fmt_bytes(raw[4:]),  f'.text    = "{text}"'))
    return lines


def emit_line_or_rect(op, sub, size, raw):
    """HLINE/VLINE/RECT/FILLED_RECT: opcode, length, x1, y1, x2, y2"""
    lines = []
    name = opcode_name(op, sub)
    x1, y1 = le16(raw, 2), le16(raw, 4)
    x2, y2 = le16(raw, 6), le16(raw, 8)
    lines.append((fmt_bytes(raw[0:1]), f'.opcode  = {name}'))
    lines.append((fmt_bytes(raw[1:2]), f'.length  = {sub}'))
    lines.append((fmt_bytes(raw[2:6]), f'.x1, .y1 = ({x1}, {y1})'))
    lines.append((fmt_bytes(raw[6:10]),f'.x2, .y2 = ({x2}, {y2})'))
    return lines


def emit_labeled_ref(op, sub, size, raw):
    """LABELED_REF: opcode, length, addr, label[]"""
    lines = []
    addr = le16(raw, 2)
    label = ''.join(fmt_char(b) for b in raw[4:size])
    lines.append((fmt_bytes(raw[0:1]), f'.opcode  = LABELED_REF'))
    lines.append((fmt_bytes(raw[1:2]), f'.length  = {sub}'))
    lines.append((fmt_bytes(raw[2:4]), f'.addr    = 0x{addr:04X}'))
    if size > 4:
        lines.append((fmt_bytes(raw[4:size]), f'.label   = "{label}"'))
    return lines


def emit_short_ref(op, sub, size, raw):
    """SHORT_REF: opcode, length, data[]"""
    lines = []
    # Check if data portion is printable text (for STRING_REF variant)
    data_bytes = raw[4:] if size > 4 else raw[2:]
    has_text = size > 8 and all(
        0x20 <= b < 0x7f or b in (0x88, 0x8c, 0x8d, 0x8e)
        for b in raw[4:]
    )
    lines.append((fmt_bytes(raw[0:1]), f'.opcode  = SHORT_REF'))
    lines.append((fmt_bytes(raw[1:2]), f'.length  = {sub}'))
    if has_text:
        text = ''.join(fmt_char(b) for b in raw[4:])
        x, y = raw[2], raw[3]
        lines.append((fmt_bytes(raw[2:4]), f'.x, .y   = ({x}, {y})'))
        lines.append((fmt_bytes(raw[4:]),  f'.text    = "{text}"'))
    else:
        data_hex = ' '.join(f'{b:02x}' for b in raw[2:])
        lines.append((fmt_bytes(raw[2:]),  f'.data    = [{data_hex}]'))
    return lines


def emit_message(op, sub, size, raw):
    """MESSAGE: opcode, length, x, y, text[]"""
    lines = []
    x, y = raw[2], raw[3]
    text = ''.join(fmt_char(b) for b in raw[4:])
    lines.append((fmt_bytes(raw[0:1]), f'.opcode  = MESSAGE'))
    lines.append((fmt_bytes(raw[1:2]), f'.length  = {sub}'))
    lines.append((fmt_bytes(raw[2:4]), f'.x, .y   = ({x}, {y})'))
    if len(raw) > 4:
        lines.append((fmt_bytes(raw[4:]),  f'.text    = "{text}"'))
    return lines


def emit_widget(op, sub, size, raw):
    """WIDGET: opcode, subtype, id, flags, handler[7], x, y"""
    lines = []
    wid = le16(raw, 2) if size >= 4 else 0
    flags = le16(raw, 4) if size >= 6 else 0
    lines.append((fmt_bytes(raw[0:1]),  f'.opcode  = WIDGET'))
    lines.append((fmt_bytes(raw[1:2]),  f'.subtype = 0x{sub:02X}'))
    if size >= 4:
        lines.append((fmt_bytes(raw[2:4]),  f'.id      = 0x{wid:04X}'))
    if size >= 6:
        lines.append((fmt_bytes(raw[4:6]),  f'.flags   = 0x{flags:04X}'))
    if size >= 13:
        handler_hex = ' '.join(f'{b:02x}' for b in raw[6:13])
        lines.append((fmt_bytes(raw[6:13]), f'.handler = [{handler_hex}]'))
    if size >= 15:
        lines.append((fmt_bytes(raw[13:15]),f'.x, .y   = ({raw[13]}, {raw[14]})'))
    return lines


def emit_unknown(op, sub, size, raw):
    """Unknown opcode: opcode, length, data[]"""
    lines = []
    name = opcode_name(op, sub)
    lines.append((fmt_bytes(raw[0:1]), f'.opcode  = {name}'))
    lines.append((fmt_bytes(raw[1:2]), f'.length  = {sub}'))
    if size > 2:
        data_hex = ' '.join(f'{b:02x}' for b in raw[2:])
        lines.append((fmt_bytes(raw[2:]),  f'.data    = [{data_hex}]'))
    return lines


def emit_command(op, sub, size, raw):
    """Dispatch to the appropriate struct emitter."""
    if op == 0x20:
        return emit_string(op, sub, size, raw)
    elif op in (0x01, 0x09, 0x0a) or (op == 0x02 and sub == 0x0a):
        return emit_line_or_rect(op, sub, size, raw)
    elif op == 0x06:
        return emit_labeled_ref(op, sub, size, raw)
    elif op == 0x07:
        return emit_short_ref(op, sub, size, raw)
    elif op == 0x08:
        return emit_message(op, sub, size, raw)
    elif op == 0x02:
        return emit_widget(op, sub, size, raw)
    else:
        return emit_unknown(op, sub, size, raw)


def command_summary(op, sub, size, raw):
    """One-line summary for the section comment."""
    name = opcode_name(op, sub)
    if op == 0x20 and size >= 4:
        text = ''.join(fmt_char(b) for b in raw[4:])
        return f'{name} "{text}" at ({raw[2]},{raw[3]})'
    if op in (0x01, 0x09, 0x0a) or (op == 0x02 and sub == 0x0a):
        x1, y1 = le16(raw, 2), le16(raw, 4)
        x2, y2 = le16(raw, 6), le16(raw, 8)
        return f'{name} ({x1},{y1})-({x2},{y2})'
    if op == 0x06:
        label = ''.join(fmt_char(b) for b in raw[4:size])
        return f'{name} "{label}"'
    if op == 0x07:
        if size > 8 and all(0x20 <= b < 0x7f or b in (0x88, 0x8c, 0x8d, 0x8e) for b in raw[4:]):
            text = ''.join(fmt_char(b) for b in raw[4:])
            return f'SHORT_REF "{text}" at ({raw[2]},{raw[3]})'
        return f'SHORT_REF'
    if op == 0x08 and size >= 4:
        text = ''.join(fmt_char(b) for b in raw[4:])
        return f'{name} "{text}" at ({raw[2]},{raw[3]})'
    if op == 0x02:
        return f'WIDGET sub=0x{sub:02X}'
    return f'{name}'


# --- File-level logic ---

def collect_screen_elements(commands):
    """Analyze commands to build a summary."""
    strings = []
    labeled_refs = []
    rects = []
    filled_rects = []
    hlines = []
    messages = []

    for off, op, sub, size, raw in commands:
        if op == 0x20 and size >= 4:
            text = ''.join(fmt_char(b) for b in raw[4:])
            strings.append((text, raw[2], raw[3]))
        elif op == 0x06:
            label = ''.join(fmt_char(b) for b in raw[4:size])
            labeled_refs.append(label)
        elif op == 0x09 and size == 10:
            rects.append((le16(raw,2), le16(raw,4), le16(raw,6), le16(raw,8)))
        elif op == 0x0a and size == 10:
            filled_rects.append((le16(raw,2), le16(raw,4), le16(raw,6), le16(raw,8)))
        elif op == 0x01 and size == 10:
            hlines.append((le16(raw,2), le16(raw,4), le16(raw,6), le16(raw,8)))
        elif op == 0x08 and size >= 4:
            text = ''.join(fmt_char(b) for b in raw[4:])
            messages.append(text)

    return strings, labeled_refs, rects, filled_rects, hlines, messages


def generate_header(name, total_bytes, source, commands):
    """Generate header comment block."""
    strings, labeled_refs, rects, filled_rects, hlines, messages = \
        collect_screen_elements(commands)

    lines = []
    lines.append(f'; StyleUI_ParamBlock_{name}: Style UI parameter block ({name})')
    lines.append(f'; Total: {total_bytes} bytes, {len(commands)} commands')
    lines.append(f'; Source: {source}')
    lines.append(';')

    lines.append('; Screen elements:')
    if labeled_refs:
        lines.append(f';   Labeled REFs: {", ".join(repr(r) for r in labeled_refs)}')
    if strings:
        str_descs = [f'"{t}" ({x},{y})' for t, x, y in strings if t not in ('|', '~', '<', '>')]
        if str_descs:
            lines.append(f';   Labels: {", ".join(str_descs)}')
        arrows_up = sum(1 for t, _, _ in strings if t == '|')
        arrows_dn = sum(1 for t, _, _ in strings if t == '~')
        if arrows_up or arrows_dn:
            lines.append(f';   Up/Down arrows: {arrows_up} up, {arrows_dn} down')
        if any(t in ('<', '>') for t, _, _ in strings):
            lines.append(f';   Navigation: "<" / ">" arrows')
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
    """Annotate a single paramblock file with struct-style fields."""
    basename = os.path.basename(filepath)
    name = basename.replace('style_ui_paramblock_', '').replace('.s', '')
    name_map = {
        'bal': 'BAL', 'common': 'Common', 'extended': 'Extended',
        'medium': 'Medium', 'meas': 'MEAS', 'short': 'Short',
        'value': 'VALUE', 'alta': 'AltA', 'altb': 'AltB',
        'altc': 'AltC', 'altd': 'AltD', 'alte': 'AltE',
    }
    name_display = name_map.get(name, name[0].upper() + name[1:] if name else name)

    # Read existing source tag
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

    total_covered = sum(size for _, _, _, size, _ in commands)
    if total_covered != total_bytes:
        print(f"  WARNING: {basename}: covered {total_covered}/{total_bytes} bytes")

    header_lines = generate_header(name_display, total_bytes, source, commands)

    # Generate struct-annotated body
    body_lines = []
    for i, (off, op, sub, size, raw_cmd) in enumerate(commands):
        # Section comment with one-line summary
        summary = command_summary(op, sub, size, raw_cmd)
        body_lines.append(f'; [{i}] {summary}')

        # Struct field lines
        field_lines = emit_command(op, sub, size, raw_cmd)
        for byte_str, comment in field_lines:
            line = f'\t.byte {byte_str}'
            padding = max(1, 48 - len(line))
            body_lines.append(f'{line}{" " * padding}; {comment}')

    # Write output
    output = header_lines + [''] + body_lines + ['']

    with open(filepath, 'wb') as f:
        for line in output:
            f.write(line.encode('latin-1') + b'\n')

    print(f"  {basename}: {total_bytes} bytes, {len(commands)} commands")
    return len(commands)


def main():
    files = sorted(f for f in os.listdir(INCLUDES)
                   if f.startswith('style_ui_paramblock_') and f.endswith('.s'))

    print(f"Found {len(files)} paramblock files:")
    total_cmds = 0
    for f in files:
        path = os.path.join(INCLUDES, f)
        total_cmds += annotate_file(path)

    print(f"\nTotal: {total_cmds} commands across {len(files)} files")


if __name__ == '__main__':
    main()
