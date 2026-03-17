#!/usr/bin/env python3
"""
convert_seq_channels.py -- Convert naka_sequencer_channels.c from raw byte array
to named C structs with symbolic pointer resolution.

Reads the ROM binary and ELF symbol table to generate a proper C struct file.
"""

import struct
import subprocess
import sys
from pathlib import Path

ROMS_DIR = Path(__file__).parent.parent
ROM_PATH = Path("/mnt/shared/kn5000_original_roms/kn5000/kn5000_v10_program.rom")
ELF_PATH = ROMS_DIR / "rebuilt_ROMs" / "kn5000_v10_program.llvm.elf"
LLVM_NM = Path("/mnt/shared/llvm-project/build/bin/llvm-nm")
ROM_BASE = 0xE00000

BLOCK_START = 0xEEE078
BLOCK_SIZE = 7936
BLOCK_END = BLOCK_START + BLOCK_SIZE

# Named regions from .equ offsets in sequencer_channel_containers.s
REGIONS = [
    (0x0000, 'widgets',                    None),   # 13 widgets + child data
    (0x06A0, 'drawbar_organ_screens',      None),   # function pointer table
    (0x07A8, 'feature_demo_callback',      None),   # callback data
    (0x0888, 'system_handler_data',        None),   # handler config
    (0x0C48, 'mixer_part_name_ptrs',       None),   # pointer table
    (0x0CCC, 'drawbar_control_table',      None),   # pointer table
    (0x0D5C, 'midi_part_config_names',     None),   # pointer tables
    (0x0F48, 'drawbar_slider_resources',   None),   # resource data
    (0x12D8, 'drawbar_display_table1',     None),   # pointer table
    (0x1358, 'drawbar_display_table2',     None),   # pointer table + data
    (0x1510, 'drawbar_reg_table',          None),   # register config
    (0x1A78, 'palette_data',               None),   # 8-bit RGBA palette
]


def load_symbols():
    """Load symbol table from ELF."""
    result = subprocess.run(
        [str(LLVM_NM), "--no-sort", str(ELF_PATH)],
        capture_output=True, text=True
    )
    addr_to_sym = {}
    sym_to_addr = {}
    for line in result.stdout.splitlines():
        parts = line.split()
        if len(parts) >= 3:
            addr = int(parts[0], 16)
            name = parts[2]
            addr_to_sym[addr] = name
            sym_to_addr[name] = addr
    return addr_to_sym, sym_to_addr


def load_rom():
    with open(ROM_PATH, 'rb') as f:
        return f.read()


def format_val16(val):
    if val == 0xFFFF:
        return "NAKA_NONE"
    elif val == 0:
        return "0x0000"
    elif val <= 0xF:
        return f"{val}"
    else:
        return f"0x{val:04X}"


def format_val32(val, syms, self_base=None, self_struct=None, self_field=None):
    """Format a 32-bit value, resolving symbols where possible."""
    if val == 0:
        return "0x00000000"
    if val == 0xFFFFFFFF:
        return "0xFFFFFFFF"
    if syms and val in syms:
        return f"NAKA_ADDR({syms[val]})"
    if self_base and self_struct and self_field:
        offset_in_struct = val - self_base
        if 0 <= offset_in_struct < BLOCK_SIZE:
            return f"SELF({self_field})"
    return f"0x{val:08X}"


def is_printable_ascii(b):
    return 0x20 <= b <= 0x7E


def format_bytes_as_hex(data, indent=8):
    """Format raw bytes as C hex array initializer."""
    prefix = ' ' * indent
    lines = []
    for i in range(0, len(data), 12):
        chunk = data[i:i+12]
        hex_str = ', '.join(f"0x{b:02X}" for b in chunk)
        lines.append(prefix + hex_str)
    return ',\n'.join(lines)


def format_ptr_table(data, syms, name, indent=8):
    """Format a region as a uint32_t pointer table."""
    prefix = ' ' * indent
    lines = []
    count = len(data) // 4
    for i in range(count):
        val = struct.unpack_from('<I', data, i * 4)[0]
        sym_str = format_val32(val, syms)
        lines.append(f"{prefix}{sym_str},")
    # Handle trailing bytes (if not aligned to 4)
    rem = len(data) % 4
    if rem > 0:
        hex_str = ', '.join(f"0x{b:02X}" for b in data[count*4:])
        lines.append(f"{prefix}/* trailing: {hex_str} */")
    return '\n'.join(lines)


def analyze_region_pointers(data, syms):
    """Check how many 4-byte aligned values resolve to symbols."""
    resolved = 0
    total = len(data) // 4
    for i in range(total):
        val = struct.unpack_from('<I', data, i * 4)[0]
        if val in syms:
            resolved += 1
    return resolved, total


def find_naka_headers(data, max_offset=None):
    """Find NAKA widget headers (XX 00 60 01) in data."""
    if max_offset is None:
        max_offset = len(data)
    headers = []
    for i in range(min(len(data) - 3, max_offset)):
        if (data[i+1] == 0x00 and data[i+2] == 0x60 and data[i+3] == 0x01
                and data[i] <= 0x6F):
            headers.append((i, data[i]))
    return headers


# Widget type sizes (total including 4-byte header)
WIDGET_SIZES = {
    0x34: 42,   # CONTAINER
    0x1D: 54,   # MENU_ITEM
    0x2B: 32,   # LABEL
    0x30: 44,   # SLIDER
    0x31: 26,   # GROUP
    0x48: 26,   # TYPE_0x48
}

WIDGET_TYPE_NAMES = {
    0x34: "CONTAINER", 0x1D: "MENU_ITEM", 0x2B: "LABEL",
    0x30: "SLIDER", 0x31: "GROUP", 0x48: "0x48",
    0x22: "0x22", 0x3E: "0x3E", 0x20: "0x20", 0x4E: "0x4E",
}


def main():
    print("Loading symbols...")
    syms, names = load_symbols()
    print(f"  {len(syms)} symbols")

    print("Loading ROM...")
    rom = load_rom()
    data = rom[BLOCK_START - ROM_BASE:BLOCK_END - ROM_BASE]
    assert len(data) == BLOCK_SIZE

    # Compute region sizes
    region_list = []
    for i, (off, name, _) in enumerate(REGIONS):
        if i + 1 < len(REGIONS):
            end = REGIONS[i+1][0]
        else:
            end = BLOCK_SIZE
        region_list.append((off, end, name, data[off:end]))

    # Collect extern symbols only from known pointer table regions
    POINTER_TABLE_REGIONS = {
        'mixer_part_name_ptrs', 'drawbar_control_table',
        'midi_part_config_names', 'drawbar_display_table1',
    }
    extern_syms = set()

    for off, end, name, region_data in region_list:
        if name not in POINTER_TABLE_REGIONS:
            continue
        # Scan at 4-byte alignment only
        for i in range(0, len(region_data) - 3, 4):
            val = struct.unpack_from('<I', region_data, i)[0]
            if val in syms and val != 0 and val != 0xFFFFFFFF:
                extern_syms.add(syms[val])

    print(f"  {len(extern_syms)} extern symbols to declare")

    # Generate C file
    out = []
    out.append('/**')
    out.append(' * naka_sequencer_channels.c -- Sequencer channel containers + drawbar/mixer data')
    out.append(' *')
    out.append(' * 13 widgets + drawbar organ screens, feature demo callbacks,')
    out.append(' * system handler data, mixer/MIDI config tables, drawbar controls,')
    out.append(' * display resources, register config, and palette data.')
    out.append(' *')
    out.append(' * NOTE: Widget region kept as raw bytes due to complex heterogeneous')
    out.append(' * structure (13 widgets with variable-size bodies + inline child data).')
    out.append(' *')
    out.append(f' * Base ROM address: 0x{BLOCK_START:06X}')
    out.append(f' * Total size: {BLOCK_SIZE} bytes')
    out.append(' * Converted from raw byte array to named struct fields.')
    out.append(' */')
    out.append('')
    out.append('#include "naka_types.h"')
    out.append('')

    # Extern declarations
    out.append('/* -- External symbols (addresses resolved by linker script) -- */')
    out.append('')
    for sym in sorted(extern_syms):
        out.append(f'extern const char {sym};')
    out.append('')

    # Base/SELF macros
    out.append(f'#define BASE  0x{BLOCK_START:08X}u')
    out.append('')

    # Struct typedef
    out.append('typedef struct __attribute__((packed)) {')

    # Region: widgets (0x0000-0x06A0)
    widget_region = data[0:0x06A0]
    widget_size = 0x06A0
    out.append(f'    /* -- Widget region (0x0000-0x069F, {widget_size} bytes) -- */')
    out.append(f'    uint8_t widget_data[{widget_size}];')

    # Remaining regions as named arrays
    # Only these specific regions use uint32_t pointer tables with NAKA_ADDR
    PTR_TABLE_REGIONS = {
        'mixer_part_name_ptrs', 'drawbar_control_table',
        'midi_part_config_names', 'drawbar_display_table1',
    }
    for off, end, name, region_data in region_list[1:]:  # skip widget region
        size = len(region_data)
        if name in PTR_TABLE_REGIONS and size % 4 == 0:
            resolved, total_words = analyze_region_pointers(region_data, syms)
            out.append(f'    /* {name} (0x{off:04X}, {size} bytes, {resolved}/{total_words} ptrs resolved) */')
            out.append(f'    uint32_t {name}[{size // 4}];')
        else:
            out.append(f'    /* {name} (0x{off:04X}, {size} bytes) */')
            out.append(f'    uint8_t {name}[{size}];')

    out.append('} naka_sequencer_channels_t;')
    out.append('')
    out.append('#define SELF(field) \\')
    out.append('    ((uint32_t)(BASE + __builtin_offsetof(naka_sequencer_channels_t, field)))')
    out.append('')
    out.append(f'_Static_assert(sizeof(naka_sequencer_channels_t) == {BLOCK_SIZE},')
    out.append(f'    "naka_sequencer_channels must be exactly {BLOCK_SIZE} bytes");')
    out.append('')

    # Data initializer
    out.append('const naka_sequencer_channels_t sequencer_channel_data')
    out.append('    __attribute__((section(".text"), used)) = {')
    out.append('')

    # Widget region -- output as raw hex (complex structure)
    out.append('    /* -- Widget region: 13 widgets + child descriptor data -- */')
    out.append('    .widget_data = {')
    out.append(format_bytes_as_hex(widget_region))
    out.append('    },')
    out.append('')

    # Remaining regions
    for off, end, name, region_data in region_list[1:]:
        size = len(region_data)
        resolved, total_words = analyze_region_pointers(region_data, syms)

        if (name in ('mixer_part_name_ptrs', 'drawbar_control_table',
                      'midi_part_config_names', 'drawbar_display_table1')
                and size % 4 == 0 and resolved > total_words * 0.3):
            # Pointer table with symbol resolution
            out.append(f'    /* -- {name} -- */')
            out.append(f'    .{name} = {{')
            for i in range(size // 4):
                val = struct.unpack_from('<I', region_data, i * 4)[0]
                sym_str = format_val32(val, syms)
                out.append(f'        {sym_str},')
            out.append('    },')
        elif name == 'drawbar_organ_screens':
            # Function pointer table -- resolve symbols
            out.append(f'    /* -- {name} -- function pointer table -- */')
            out.append(f'    .{name} = {{')
            out.append(format_bytes_as_hex(region_data))
            out.append('    },')
        elif name == 'palette_data':
            # Palette: 4-byte RGBA entries
            out.append(f'    /* -- {name} -- 8-bit RGBA palette entries -- */')
            out.append(f'    .{name} = {{')
            out.append(format_bytes_as_hex(region_data))
            out.append('    },')
        else:
            out.append(f'    /* -- {name} -- */')
            out.append(f'    .{name} = {{')
            out.append(format_bytes_as_hex(region_data))
            out.append('    },')
        out.append('')

    out.append('};')
    out.append('')
    out.append('#undef SELF')
    out.append('#undef BASE')
    out.append('')

    # Write the C file
    c_path = ROMS_DIR / 'maincpu' / 'ui_widgets' / 'naka_sequencer_channels.c'
    content = '\n'.join(out)
    with open(c_path, 'wb') as f:
        f.write(content.encode('ascii'))
    print(f"Written: {c_path}")
    print(f"  {len(content)} bytes, {len(out)} lines")

    # Generate/update linker script
    ld_path = ROMS_DIR / 'maincpu' / 'ui_widgets' / 'naka_sequencer_channels_link.ld'
    ld_lines = []
    ld_lines.append(f'/* naka_sequencer_channels_link.ld -- Linker script for naka_sequencer_channels.c')
    ld_lines.append(f' * Auto-generated by scripts/convert_seq_channels.py')
    ld_lines.append(f' */')
    ld_lines.append(f'')
    ld_lines.append(f'ENTRY(0)')
    ld_lines.append(f'')
    ld_lines.append(f'SECTIONS {{')
    ld_lines.append(f'    .text : {{ *(.text*) }}')
    ld_lines.append(f'    /DISCARD/ : {{ *(.comment) *(.note*) *(.eh_frame*) }}')
    ld_lines.append(f'}}')
    ld_lines.append(f'')
    for sym in sorted(extern_syms):
        if sym in names:
            ld_lines.append(f'{sym} = 0x{names[sym]:08X};')
        else:
            ld_lines.append(f'/* WARNING: {sym} not found in ELF */')
    ld_lines.append(f'')

    ld_content = '\n'.join(ld_lines)
    with open(ld_path, 'wb') as f:
        f.write(ld_content.encode('ascii'))
    print(f"Written: {ld_path}")


if __name__ == '__main__':
    main()
