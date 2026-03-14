#!/usr/bin/env python3
"""
Generic ScreenData bytecode parser for the KN5000 ROM.

Parses packed binary commands used by the Style UI and other screen layout systems.
Each command starts with an opcode byte followed by a length byte and payload.

Usage as library:
    from screendata_parser import ScreenDataParser
    parser = ScreenDataParser(rom_bytes)
    commands = parser.parse(offset, max_bytes=500)

Usage standalone:
    python screendata_parser.py <rom_file> <hex_address> [max_bytes]
"""

import sys
import os


# ── Opcode definitions ───────────────────────────────────────────────

OP_NOP          = 0x00
OP_HLINE        = 0x01
OP_VLINE_WIDGET = 0x02
OP_SETUP        = 0x03
OP_CTRL         = 0x04
OP_SETUP5       = 0x05
OP_LABELED_REF  = 0x06
OP_SHORT_REF    = 0x07
OP_MESSAGE      = 0x08
OP_RECT         = 0x09
OP_FILLED_RECT  = 0x0A
OP_CONFIG       = 0x0E
OP_PARAM_LABEL  = 0x17  # parameter label text
OP_BOUNDARY     = 0x1B
OP_FIELD_LABEL  = 0x1C  # field label text
OP_STRING       = 0x20
OP_UNKNOWN_23   = 0x23

# Opcodes that use {opcode, length, ...} format where length is total size
LENGTH_PREFIX_OPS = {
    OP_NOP, OP_HLINE, OP_SETUP, OP_CTRL, OP_SETUP5,
    OP_LABELED_REF, OP_SHORT_REF, OP_MESSAGE,
    OP_RECT, OP_FILLED_RECT, OP_CONFIG,
    OP_PARAM_LABEL, OP_BOUNDARY, OP_FIELD_LABEL,
    OP_STRING, OP_UNKNOWN_23,
}

# Op 0x02 uses subtype byte: 0x0A = VLINE (10 bytes), 0x0F = WIDGET (15 bytes)
SUB_VLINE  = 0x0A
SUB_WIDGET = 0x0F


def u16(data, off):
    """Read uint16_t LE."""
    return data[off] | (data[off + 1] << 8)


def u32(data, off):
    """Read uint32_t LE."""
    return data[off] | (data[off + 1] << 8) | (data[off + 2] << 16) | (data[off + 3] << 24)


class ScreenDataCommand:
    """One parsed ScreenData command."""

    def __init__(self, name, offset, size, raw_bytes, fields=None):
        self.name = name          # e.g. "HLINE", "WIDGET", "STRING"
        self.offset = offset      # byte offset within the block
        self.size = size           # total bytes consumed
        self.raw = raw_bytes       # raw byte list
        self.fields = fields or {} # parsed fields (opcode-specific)

    def __repr__(self):
        return f"<{self.name} @{self.offset} size={self.size}>"


class ScreenDataParser:
    """Parse ScreenData bytecodes from a ROM byte array."""

    def __init__(self, rom_data, rom_base=0xE00000):
        self.rom = rom_data
        self.rom_base = rom_base

    def _read(self, addr, n):
        """Read n bytes from ROM address."""
        off = addr - self.rom_base
        return list(self.rom[off:off + n])

    def parse(self, addr, max_bytes=4096):
        """Parse commands starting at addr. Returns list of ScreenDataCommand."""
        commands = []
        pos = 0

        while pos < max_bytes:
            abs_addr = addr + pos
            off = abs_addr - self.rom_base

            if off >= len(self.rom):
                break

            op = self.rom[off]

            if op == OP_VLINE_WIDGET:
                # Check subtype
                if off + 1 >= len(self.rom):
                    break
                sub = self.rom[off + 1]
                if sub == SUB_VLINE:
                    size = 10
                    fields = self._parse_vline(off)
                    cmd = ScreenDataCommand('VLINE', pos, size,
                                            self._read(abs_addr, size), fields)
                elif sub == SUB_WIDGET:
                    size = 15
                    fields = self._parse_widget(off)
                    cmd = ScreenDataCommand('WIDGET', pos, size,
                                            self._read(abs_addr, size), fields)
                else:
                    # Unknown subtype — use it as length
                    if sub < 4 or sub > 0x40:
                        break  # not a valid command
                    size = sub
                    cmd = ScreenDataCommand(f'VLINE_SUB_{sub:02X}', pos, size,
                                            self._read(abs_addr, size))
                commands.append(cmd)
                pos += size
                continue

            if op in LENGTH_PREFIX_OPS:
                if off + 1 >= len(self.rom):
                    break
                length = self.rom[off + 1]
                if length < 2 or length > 200:
                    break  # invalid length

                raw = self._read(abs_addr, length)
                fields = {}
                name = self._op_name(op)

                if op == OP_HLINE:
                    fields = self._parse_line(off)
                elif op == OP_RECT:
                    fields = self._parse_rect(off)
                elif op == OP_FILLED_RECT:
                    fields = self._parse_rect(off)
                elif op == OP_STRING:
                    fields = self._parse_string(off, length)
                elif op == OP_LABELED_REF:
                    fields = self._parse_labeled_ref(off, length)
                elif op == OP_SHORT_REF:
                    fields = self._parse_short_ref(off, length)
                elif op == OP_MESSAGE:
                    fields = self._parse_message(off, length)
                elif op == OP_SETUP:
                    fields = self._parse_block_hdr(off, length)
                elif op == OP_SETUP5:
                    if length == 0x0A:  # selection rectangle
                        name = 'SELECT_RECT'
                        fields = self._parse_boundary(off)
                    else:
                        fields = self._parse_block_hdr(off, length)
                elif op == OP_CTRL:
                    fields = self._parse_block_hdr(off, length)
                elif op == OP_CONFIG:
                    fields = self._parse_config(off)
                elif op == OP_BOUNDARY:
                    fields = self._parse_boundary(off)
                elif op == OP_NOP:
                    fields = {'data': raw[2:]}

                cmd = ScreenDataCommand(name, pos, length, raw, fields)
                commands.append(cmd)
                pos += length
                continue

            # Unknown opcode — end of stream
            break

        return commands

    def _op_name(self, op):
        names = {
            OP_NOP: 'NOP', OP_HLINE: 'HLINE', OP_RECT: 'RECT',
            OP_FILLED_RECT: 'FILLED_RECT', OP_STRING: 'STRING',
            OP_LABELED_REF: 'LABELED_REF', OP_SHORT_REF: 'SHORT_REF',
            OP_MESSAGE: 'MESSAGE', OP_SETUP: 'SETUP', OP_CTRL: 'CTRL',
            OP_SETUP5: 'SETUP5', OP_CONFIG: 'CONFIG', 0x105: 'SELECT_RECT',
            OP_PARAM_LABEL: 'PARAM_LABEL', OP_BOUNDARY: 'BOUNDARY',
            OP_FIELD_LABEL: 'FIELD_LABEL',
            OP_UNKNOWN_23: 'UNKNOWN_23',
        }
        return names.get(op, f'OP_{op:02X}')

    def _parse_line(self, off):
        return {
            'p1': (u16(self.rom, off + 2), u16(self.rom, off + 4)),
            'p2': (u16(self.rom, off + 6), u16(self.rom, off + 8)),
        }

    def _parse_vline(self, off):
        return {
            'p1': (u16(self.rom, off + 2), u16(self.rom, off + 4)),
            'p2': (u16(self.rom, off + 6), u16(self.rom, off + 8)),
        }

    def _parse_rect(self, off):
        return {
            'top_left': (u16(self.rom, off + 2), u16(self.rom, off + 4)),
            'bottom_right': (u16(self.rom, off + 6), u16(self.rom, off + 8)),
        }

    def _parse_widget(self, off):
        return {
            'subtype': self.rom[off + 1],
            'id': u16(self.rom, off + 2),
            'flags': u16(self.rom, off + 4),
            'ref_tag': self.rom[off + 6],
            'handler': u32(self.rom, off + 7),
            'param': u16(self.rom, off + 11),
            'x': self.rom[off + 13],
            'y': self.rom[off + 14],
        }

    def _parse_string(self, off, length):
        text_len = length - 4
        text = bytes(self.rom[off + 4:off + 4 + text_len])
        return {
            'x': self.rom[off + 2],
            'y': self.rom[off + 3],
            'text': text,
            'text_len': text_len,
        }

    def _parse_labeled_ref(self, off, length):
        data_len = length - 4
        return {
            'addr': u16(self.rom, off + 2),
            'data': list(self.rom[off + 4:off + 4 + data_len]),
            'data_len': data_len,
        }

    def _parse_short_ref(self, off, length):
        data_len = length - 2
        return {
            'data': list(self.rom[off + 2:off + 2 + data_len]),
            'data_len': data_len,
        }

    def _parse_message(self, off, length):
        text_len = length - 4
        text = bytes(self.rom[off + 4:off + 4 + text_len])
        return {
            'x': self.rom[off + 2],
            'y': self.rom[off + 3],
            'text': text,
            'text_len': text_len,
        }

    def _parse_block_hdr(self, off, length):
        return {
            'type': self.rom[off],
            'id': u16(self.rom, off + 2),
            'flags': u16(self.rom, off + 4),
            'tag': self.rom[off + 6],
            'handler': u32(self.rom, off + 7),
        }

    def _parse_config(self, off):
        return {
            'id': u16(self.rom, off + 2),
            'flags': u16(self.rom, off + 4),
            'param': u16(self.rom, off + 6),
        }

    def _parse_boundary(self, off):
        return {
            'p1': (u16(self.rom, off + 2), u16(self.rom, off + 4)),
            'p2': (u16(self.rom, off + 6), u16(self.rom, off + 8)),
        }


def fmt_lcd_byte(b, short_names=False):
    """Format a byte as a C char literal, LCD char define, or hex value."""
    if b == 0x88:
        return 'FLAT' if short_names else 'LCD_CHAR_FLAT'
    elif b == 0x8c:
        return 'SHARP' if short_names else 'LCD_CHAR_SHARP'
    elif b == 0x8b:
        return '0x8b'  # half-sharp or custom char
    elif b == 0x8d:
        return 'LCD_CHAR_VBAR'
    elif b == 0x8e:
        return 'LCD_CHAR_DARROW'
    elif 0x20 <= b < 0x7f:
        c = chr(b)
        if c in ("'", '\\'):
            return f"'\\{c}'"
        return f"'{c}'"
    else:
        return f'0x{b:02x}'


class ScreenDataCGenerator:
    """Generate C source code from parsed ScreenData commands."""

    def __init__(self, commands, block_name, base_addr, struct_name=None):
        self.commands = commands
        self.block_name = block_name
        self.base_addr = base_addr
        self.struct_name = struct_name or f"screendata_{block_name}_t"
        self.total_size = sum(c.size for c in commands)
        # Build offset→field_name map for SD_PTR resolution
        self._offset_to_field = {}
        counters = {}
        for cmd in commands:
            name = cmd.name.lower()
            idx = counters.get(name, 0)
            counters[name] = idx + 1
            self._offset_to_field[cmd.offset] = self._field_name(cmd, idx)

    def _resolve_handler(self, handler_addr):
        """Resolve a handler address to SD_PTR expression if self-referential."""
        offset = handler_addr - self.base_addr
        if 0 <= offset < self.total_size:
            # Find the field containing this offset
            best_field = None
            best_off = -1
            for cmd in self.commands:
                if cmd.offset <= offset < cmd.offset + cmd.size:
                    fname = self._offset_to_field.get(cmd.offset)
                    if fname:
                        delta = offset - cmd.offset
                        if delta == 0:
                            return f'SD_PTR({fname})'
                        else:
                            return f'SD_PTR({fname}) + {delta}'
            # Exact field not found, use raw offset
            return f'SD_PTR({list(self._offset_to_field.values())[0]}) + {offset}'
        return None

    def generate_c(self):
        """Generate complete C source with struct definition and initializer."""
        lines = []
        lines.append(self._header())
        lines.append('#include "screendata_types.h"')
        lines.append('#include <stddef.h>')
        lines.append('')

        # Struct definition
        lines.append(self._struct_def())
        lines.append('')
        lines.append(f'_Static_assert(sizeof({self.struct_name}) == {self.total_size},')
        lines.append(f'\t"{self.block_name} must be exactly {self.total_size} bytes");')
        lines.append('')

        # Base address and SD_PTR
        lines.append(f'#define {self.block_name.upper()}_BASE  0x{self.base_addr:08X}u')
        lines.append(f'#define SD_PTR(field)  ({self.block_name.upper()}_BASE + offsetof({self.struct_name}, field))')
        lines.append('')

        # Initializer
        lines.append(self._initializer())
        lines.append('')

        return '\n'.join(lines)

    def _header(self):
        lines = [
            '/**',
            f' * {self.block_name} — Screen Layout Data',
            f' *',
            f' * Base address: 0x{self.base_addr:06X}',
            f' * Size: {self.total_size} bytes, {len(self.commands)} commands',
            f' *',
            f' * Auto-generated by screendata_parser.py',
            ' */',
            '',
        ]
        return '\n'.join(lines)

    def _field_name(self, cmd, idx):
        """Generate a struct field name for a command."""
        name = cmd.name.lower()
        return f'{name}_{idx}'

    def _field_type(self, cmd):
        """Return the C type for a command."""
        if cmd.name == 'HLINE':
            return 'sd_hline_t'
        elif cmd.name == 'VLINE':
            return 'sd_vline_t'
        elif cmd.name == 'RECT':
            return 'sd_rect_t'
        elif cmd.name == 'FILLED_RECT':
            return 'sd_filled_rect_t'
        elif cmd.name == 'WIDGET':
            return 'sd_widget_t'
        elif cmd.name == 'STRING':
            tl = cmd.fields.get('text_len', cmd.size - 4)
            return f'SD_STRING_TYPE({tl})'
        elif cmd.name == 'LABELED_REF':
            if cmd.size == 10 and cmd.raw[1] == 0x0A:
                return 'sd_ref_ex_t'
            dl = cmd.fields.get('data_len', cmd.size - 4)
            return f'SD_LABELED_REF_TYPE({dl})'
        elif cmd.name == 'SHORT_REF':
            dl = cmd.fields.get('data_len', cmd.size - 2)
            return f'SD_SHORT_REF_TYPE({dl})'
        elif cmd.name == 'MESSAGE':
            tl = cmd.fields.get('text_len', cmd.size - 4)
            return f'SD_MESSAGE_TYPE({tl})'
        elif cmd.name in ('SETUP', 'SETUP5', 'CTRL'):
            return 'sd_block_hdr_t'
        elif cmd.name == 'SELECT_RECT':
            return 'sd_boundary_block_t'
        elif cmd.name == 'CONFIG':
            return 'sd_config_block_t'
        elif cmd.name == 'BOUNDARY':
            return 'sd_boundary_block_t'
        elif cmd.name == 'NOP':
            if cmd.size == 10:
                return 'sd_nop_10_t'
            return f'SD_UNKNOWN_TYPE({cmd.size - 2})'
        elif cmd.name in ('PARAM_LABEL', 'FIELD_LABEL', 'UNKNOWN_23'):
            return f'SD_UNKNOWN_TYPE({cmd.size - 2})'
        else:
            return f'uint8_t'

    def _struct_def(self):
        """Generate the struct type definition."""
        lines = [f'typedef struct __attribute__((packed)) {{']
        counters = {}
        for cmd in self.commands:
            name = cmd.name.lower()
            idx = counters.get(name, 0)
            counters[name] = idx + 1
            fname = self._field_name(cmd, idx)
            ftype = self._field_type(cmd)

            comment = self._field_comment(cmd)
            if ftype.startswith('SD_') or ftype.startswith('sd_'):
                lines.append(f'\t{ftype:30s} {fname};{comment}')
            else:
                lines.append(f'\t{ftype} {fname}[{cmd.size}];{comment}')

        lines.append(f'}} {self.struct_name};')
        return '\n'.join(lines)

    def _field_comment(self, cmd):
        """Generate inline comment for a field."""
        f = cmd.fields
        if cmd.name == 'STRING' and 'text' in f:
            text = f['text'].decode('latin-1', errors='replace').rstrip()
            if text:
                return f'  /* "{text}" at ({f["x"]},{f["y"]}) */'
        elif cmd.name == 'WIDGET' and 'handler' in f:
            return f'  /* handler=0x{f["handler"]:06x} param={f["param"]} ({f["x"]},{f["y"]}) */'
        elif cmd.name in ('HLINE', 'VLINE') and 'p1' in f:
            p1, p2 = f['p1'], f['p2']
            return f'  /* ({p1[0]},{p1[1]})-({p2[0]},{p2[1]}) */'
        elif cmd.name in ('RECT', 'FILLED_RECT') and 'top_left' in f:
            tl, br = f['top_left'], f['bottom_right']
            return f'  /* ({tl[0]},{tl[1]})-({br[0]},{br[1]}) */'
        elif cmd.name in ('SETUP', 'SETUP5', 'CTRL') and 'handler' in f:
            return f'  /* id=0x{f["id"]:04x} handler=0x{f["handler"]:06x} */'
        elif cmd.name in ('BOUNDARY', 'SELECT_RECT') and 'p1' in f:
            p1, p2 = f['p1'], f['p2']
            return f'  /* ({p1[0]},{p1[1]})-({p2[0]},{p2[1]}) */'
        elif cmd.name == 'LABELED_REF' and 'data' in f:
            data = f['data']
            text_chars = [chr(b) for b in data if 0x20 <= b < 0x7f]
            if text_chars:
                return f'  /* "{"".join(text_chars)}" */'
        elif cmd.name in ('PARAM_LABEL', 'FIELD_LABEL'):
            text_chars = [chr(b) for b in cmd.raw[2:] if 0x20 <= b < 0x7f]
            if text_chars:
                return f'  /* "{"".join(text_chars)}" */'
        elif cmd.name == 'MESSAGE' and 'text' in f:
            text = f['text'].decode('latin-1', errors='replace').rstrip()
            return f'  /* "{text}" at ({f["x"]},{f["y"]}) */'
        return ''

    def _initializer(self):
        """Generate the struct initializer."""
        lines = []
        var_name = self.block_name
        lines.append(f'const {self.struct_name} {var_name}')
        lines.append('\t__attribute__((section(".text"), used)) = {')

        counters = {}
        for cmd in self.commands:
            name = cmd.name.lower()
            idx = counters.get(name, 0)
            counters[name] = idx + 1
            fname = self._field_name(cmd, idx)

            init = self._format_initializer(cmd)
            lines.append(f'\t.{fname} = {init}')

        lines.append('};')
        return '\n'.join(lines)

    def _format_initializer(self, cmd):
        """Format C initializer for one command."""
        f = cmd.fields

        if cmd.name == 'HLINE':
            p1, p2 = f['p1'], f['p2']
            return (f'{{ .opcode = SD_OP_HLINE, .length = 0x0a, '
                    f'.p1 = {{ .x = {p1[0]}, .y = {p1[1]} }}, '
                    f'.p2 = {{ .x = {p2[0]}, .y = {p2[1]} }} }},')

        elif cmd.name == 'VLINE':
            p1, p2 = f['p1'], f['p2']
            return (f'{{ .opcode = SD_OP_VLINE_WIDGET, .subtype = SD_SUB_VLINE, '
                    f'.p1 = {{ .x = {p1[0]}, .y = {p1[1]} }}, '
                    f'.p2 = {{ .x = {p2[0]}, .y = {p2[1]} }} }},')

        elif cmd.name == 'RECT':
            tl, br = f['top_left'], f['bottom_right']
            return (f'{{ .opcode = SD_OP_RECT, .length = 0x0a, '
                    f'.top_left = {{ .x = {tl[0]}, .y = {tl[1]} }}, '
                    f'.bottom_right = {{ .x = {br[0]}, .y = {br[1]} }} }},')

        elif cmd.name == 'FILLED_RECT':
            tl, br = f['top_left'], f['bottom_right']
            return (f'{{ .opcode = SD_OP_FILLED_RECT, .length = 0x0a, '
                    f'.top_left = {{ .x = {tl[0]}, .y = {tl[1]} }}, '
                    f'.bottom_right = {{ .x = {br[0]}, .y = {br[1]} }} }},')

        elif cmd.name == 'WIDGET':
            sd_ptr = self._resolve_handler(f['handler'])
            handler_str = sd_ptr if sd_ptr else f'0x{f["handler"]:08x}'
            return (f'{{ .opcode = 0x02, .subtype = 0x{f["subtype"]:02x}, '
                    f'.id = 0x{f["id"]:04x}, .flags = 0x{f["flags"]:04x}, '
                    f'.ref_tag = 0x{f["ref_tag"]:02x}, .handler = {handler_str}, '
                    f'.param = {f["param"]}, .x = {f["x"]}, .y = {f["y"]} }},')

        elif cmd.name == 'STRING':
            text_bytes = list(f['text'])
            parts = ', '.join(fmt_lcd_byte(b) for b in text_bytes)
            return (f'{{ .opcode = SD_OP_STRING, .length = {cmd.size}, '
                    f'.x = {f["x"]}, .y = {f["y"]}, '
                    f'.text = {{ {parts} }} }},')

        elif cmd.name == 'LABELED_REF':
            if cmd.size == 10 and cmd.raw[1] == 0x0A:
                # REF_EX format
                id_val = f['addr']
                data = f['data']
                dstr = ', '.join(f'0x{b:02x}' for b in data)
                return (f'{{ .opcode = SD_OP_LABELED_REF, .length = 0x0a, '
                        f'.id = 0x{id_val:04x}, .data = {{ {dstr} }} }},')
            data = f['data']
            if all(0x20 <= b < 0x7f or b in (0x88, 0x8c, 0x8d, 0x8e) for b in data):
                parts = ', '.join(fmt_lcd_byte(b) for b in data)
            else:
                parts = ', '.join(f'0x{b:02x}' for b in data)
            return (f'{{ .opcode = SD_OP_LABELED_REF, .length = {cmd.size}, '
                    f'.addr = 0x{f["addr"]:04x}, .label = {{ {parts} }} }},')

        elif cmd.name == 'SHORT_REF':
            data = f['data']
            parts = ', '.join(f'0x{b:02x}' for b in data)
            return (f'{{ .opcode = SD_OP_SHORT_REF, .length = {cmd.size}, '
                    f'.data = {{ {parts} }} }},')

        elif cmd.name == 'MESSAGE':
            text_bytes = list(f['text'])
            parts = ', '.join(fmt_lcd_byte(b) for b in text_bytes)
            return (f'{{ .opcode = SD_OP_MESSAGE, .length = {cmd.size}, '
                    f'.x = {f["x"]}, .y = {f["y"]}, '
                    f'.text = {{ {parts} }} }},')

        elif cmd.name == 'SELECT_RECT':
            p1, p2 = f['p1'], f['p2']
            return (f'{{ .type = 0x05, .length = 0x0a, '
                    f'.p1 = {{ .x = {p1[0]}, .y = {p1[1]} }}, '
                    f'.p2 = {{ .x = {p2[0]}, .y = {p2[1]} }} }},')

        elif cmd.name in ('SETUP', 'SETUP5'):
            type_val = f['type']
            type_name = 'SD_BLOCK_SETUP' if type_val == 0x03 else f'0x{type_val:02x}'
            return (f'{{ .type = {type_name}, .length = 0x{cmd.raw[1]:02x}, '
                    f'.id = 0x{f["id"]:04x}, .flags = 0x{f["flags"]:04x}, '
                    f'.tag = 0x{f["tag"]:02x}, .handler = 0x{f["handler"]:08x} }},')

        elif cmd.name == 'CTRL':
            return (f'{{ .type = SD_BLOCK_CTRL, .length = 0x{cmd.raw[1]:02x}, '
                    f'.id = 0x{f["id"]:04x}, .flags = 0x{f["flags"]:04x}, '
                    f'.tag = 0x{f["tag"]:02x}, .handler = 0x{f["handler"]:08x} }},')

        elif cmd.name == 'CONFIG':
            return (f'{{ .type = 0x{cmd.raw[0]:02x}, .length = 0x{cmd.raw[1]:02x}, '
                    f'.id = 0x{f["id"]:04x}, .flags = 0x{f["flags"]:04x}, '
                    f'.param = 0x{f["param"]:04x} }},')

        elif cmd.name == 'BOUNDARY':
            p1, p2 = f['p1'], f['p2']
            return (f'{{ .type = 0x1b, .length = 0x0a, '
                    f'.p1 = {{ .x = {p1[0]}, .y = {p1[1]} }}, '
                    f'.p2 = {{ .x = {p2[0]}, .y = {p2[1]} }} }},')

        elif cmd.name == 'NOP' and cmd.size == 10:
            data = f.get('data', cmd.raw[2:])
            dstr = ', '.join(f'0x{b:02x}' for b in data)
            return (f'{{ .opcode = 0x{cmd.raw[0]:02x}, .length = 0x{cmd.raw[1]:02x}, '
                    f'.data = {{ {dstr} }} }},')

        elif cmd.name in ('PARAM_LABEL', 'FIELD_LABEL', 'UNKNOWN_23', 'NOP'):
            data = cmd.raw[2:]
            dstr = ', '.join(f'0x{b:02x}' for b in data)
            return (f'{{ .opcode = 0x{cmd.raw[0]:02x}, .length = 0x{cmd.raw[1]:02x}, '
                    f'.data = {{ {dstr} }} }},')

        # Fallback: raw bytes
        hex_vals = ', '.join(f'0x{b:02x}' for b in cmd.raw)
        return f'{{ {hex_vals} }},'


# ── CLI entry point ──────────────────────────────────────────────────

def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <rom_file> <hex_address> [max_bytes]")
        print(f"  Parses ScreenData bytecodes starting at the given ROM address.")
        print(f"  Example: {sys.argv[0]} original_ROMs/kn5000_v10_program.rom 0xF6AD37")
        sys.exit(1)

    rom_file = sys.argv[1]
    addr = int(sys.argv[2], 16)
    max_bytes = int(sys.argv[3]) if len(sys.argv) > 3 else 4096

    with open(rom_file, 'rb') as f:
        rom_data = f.read()

    parser = ScreenDataParser(rom_data)
    commands = parser.parse(addr, max_bytes)

    total_size = sum(c.size for c in commands)
    print(f"Parsed {len(commands)} commands ({total_size} bytes) starting at 0x{addr:06X}")
    print()

    for cmd in commands:
        abs_addr = addr + cmd.offset
        print(f"  [{cmd.offset:4d}] {cmd.name:15s} size={cmd.size:3d}  "
              f"@ 0x{abs_addr:06X}", end='')
        f = cmd.fields
        if cmd.name == 'STRING' and 'text' in f:
            text = f['text'].decode('latin-1', errors='replace')
            print(f'  "{text}" at ({f["x"]},{f["y"]})', end='')
        elif cmd.name == 'WIDGET' and 'handler' in f:
            print(f'  handler=0x{f["handler"]:06x} param={f["param"]} '
                  f'({f["x"]},{f["y"]})', end='')
        elif cmd.name in ('HLINE', 'VLINE') and 'p1' in f:
            p1, p2 = f['p1'], f['p2']
            print(f'  ({p1[0]},{p1[1]})-({p2[0]},{p2[1]})', end='')
        elif cmd.name in ('RECT', 'FILLED_RECT') and 'top_left' in f:
            tl, br = f['top_left'], f['bottom_right']
            print(f'  ({tl[0]},{tl[1]})-({br[0]},{br[1]})', end='')
        elif cmd.name == 'LABELED_REF' and 'data' in f:
            text_chars = [chr(b) for b in f['data'] if 0x20 <= b < 0x7f]
            if text_chars:
                print(f'  addr=0x{f["addr"]:04x} "{"".join(text_chars)}"', end='')
            else:
                print(f'  addr=0x{f["addr"]:04x}', end='')
        elif cmd.name in ('SETUP', 'SETUP5', 'CTRL') and 'handler' in f:
            print(f'  id=0x{f["id"]:04x} handler=0x{f["handler"]:06x}', end='')
        print()

    print(f"\nTotal: {total_size} bytes")


if __name__ == '__main__':
    main()
