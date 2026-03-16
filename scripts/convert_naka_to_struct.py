#!/usr/bin/env python3
"""
convert_naka_to_struct.py -- General-purpose converter for NAKA widget C files.

Converts raw unsigned char byte arrays to packed C structs with named regions,
symbol-resolved pointer tables, and _Static_assert size verification.

Usage:
    python3 scripts/convert_naka_to_struct.py <c_file> [--dry-run]

The script:
1. Reads the raw C file to find the byte array size and ROM address range
2. Parses the corresponding .s wrapper for .equ offsets (named regions)
3. Loads the ROM binary and ELF symbol table
4. Generates a converted C file with named struct fields
5. Updates the linker script with extern symbol definitions
"""

import struct
import subprocess
import sys
import re
from pathlib import Path

ROMS_DIR = Path(__file__).parent.parent
ROM_PATH = Path("/mnt/shared/kn5000_original_roms/kn5000/kn5000_v10_program.rom")
ELF_PATH = ROMS_DIR / "rebuilt_ROMs" / "kn5000_v10_program.llvm.elf"
LLVM_NM = Path("/mnt/shared/llvm-project/build/bin/llvm-nm")
ROM_BASE = 0xE00000


def load_symbols():
    """Load symbol table from ELF."""
    if not ELF_PATH.exists():
        print("  WARNING: ELF not found, building first...")
        return {}, {}
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


def parse_c_file(c_path):
    """Parse the raw C file to extract ROM address range and array size."""
    with open(c_path, 'rb') as f:
        content = f.read().decode('latin-1')

    # Find address range from comment
    m = re.search(r'ROM data at (0x[0-9A-Fa-f]+)-(0x[0-9A-Fa-f]+)', content)
    if m:
        start_addr = int(m.group(1), 16)
        end_addr = int(m.group(2), 16)
    else:
        raise ValueError(f"Cannot find ROM address range in {c_path}")

    # Find array size
    m = re.search(r'\[(\d+)\]\s*=\s*\{', content)
    if m:
        array_size = int(m.group(1))
    else:
        raise ValueError(f"Cannot find array size in {c_path}")

    # Find variable name
    m = re.search(r'(?:const\s+)?unsigned\s+char\s+(\w+)\s*\[', content)
    if m:
        var_name = m.group(1)
    else:
        var_name = 'data'

    return start_addr, end_addr, array_size, var_name


def find_s_wrapper(c_path):
    """Find the .s wrapper file that includes this C file's binary."""
    c_name = c_path.stem
    bin_name = c_name + '.bin'
    widgets_dir = c_path.parent
    for s_file in widgets_dir.glob('*.s'):
        try:
            with open(s_file, 'rb') as f:
                content = f.read().decode('latin-1')
            if bin_name in content:
                return s_file
        except Exception:
            continue
    return None


def parse_s_wrapper(s_path):
    """Parse .s wrapper for .equ offsets and base label."""
    with open(s_path, 'rb') as f:
        content = f.read().decode('latin-1')

    # Find base label (the label before .incbin)
    m = re.search(r'^(\w+):\s*$', content, re.MULTILINE)
    base_label = m.group(1) if m else None

    # Parse .equ definitions
    equs = []
    for m in re.finditer(r'\.equ\s+(\w+),\s*\w+\s*\+\s*(0x[0-9A-Fa-f]+)', content):
        name = m.group(1)
        offset = int(m.group(2), 16)
        equs.append((offset, name))

    equs.sort(key=lambda x: x[0])
    return base_label, equs


def format_bytes_as_hex(data, indent=8):
    """Format raw bytes as C hex array initializer."""
    prefix = ' ' * indent
    lines = []
    for i in range(0, len(data), 12):
        chunk = data[i:i+12]
        hex_str = ', '.join(f"0x{b:02X}" for b in chunk)
        lines.append(prefix + hex_str)
    return ',\n'.join(lines)


def format_val32(val, syms):
    """Format a 32-bit value, resolving symbols."""
    if val == 0:
        return "0x00000000"
    if val == 0xFFFFFFFF:
        return "0xFFFFFFFF"
    if syms and val in syms:
        return f"NAKA_ADDR({syms[val]})"
    return f"0x{val:08X}"


def is_pointer_table(data, syms, threshold=0.25):
    """Check if data looks like a pointer table (uint32_t aligned, many symbols)."""
    if len(data) < 8 or len(data) % 4 != 0:
        return False, 0, 0
    total = len(data) // 4
    resolved = 0
    for i in range(total):
        val = struct.unpack_from('<I', data, i * 4)[0]
        if val in syms and val != 0 and val != 0xFFFFFFFF:
            resolved += 1
    return resolved >= total * threshold, resolved, total


def sanitize_field_name(name):
    """Convert a label name to a valid C field name (lowercase, underscored)."""
    # Remove common prefixes
    for prefix in ['NakaData_', 'Naka_', 'NakaInst_', 'WidgetName_', 'Data_']:
        if name.startswith(prefix):
            name = name[len(prefix):]
            break
    # Convert CamelCase to snake_case
    result = re.sub(r'([A-Z][a-z])', lambda m: '_' + m.group(0).lower(), name)
    result = re.sub(r'([A-Z]+)', lambda m: '_' + m.group(0).lower(), result)
    result = result.strip('_').lower()
    # Replace non-alphanumeric with underscore
    result = re.sub(r'[^a-z0-9_]', '_', result)
    # Collapse multiple underscores
    result = re.sub(r'_+', '_', result)
    # C identifiers cannot start with a digit
    if result and result[0].isdigit():
        result = 'n' + result
    return result


def generate_conversion(c_path, dry_run=False, overrides=None):
    """Main conversion logic."""
    if overrides is None:
        overrides = {}
    print(f"Converting: {c_path}")

    # Parse source file or use overrides
    if 'start_addr' in overrides and 'size' in overrides:
        start_addr = overrides['start_addr']
        block_size = overrides['size']
        var_name = overrides.get('var_name', c_path.stem + '_data')
        print(f"  ROM: 0x{start_addr:06X} ({block_size} bytes) [from cmdline]")
    else:
        start_addr, end_addr, array_size, var_name = parse_c_file(c_path)
        block_size = array_size
        if 'var_name' in overrides:
            var_name = overrides['var_name']
        print(f"  ROM: 0x{start_addr:06X} ({block_size} bytes)")
    print(f"  var: {var_name}")

    # Find and parse .s wrapper
    s_path = find_s_wrapper(c_path)
    if s_path:
        print(f"  Wrapper: {s_path.name}")
        base_label, equs = parse_s_wrapper(s_path)
        print(f"  Base label: {base_label}, {len(equs)} .equ offsets")
    else:
        print("  WARNING: No .s wrapper found")
        base_label = None
        equs = []

    # Load ROM and symbols
    print("  Loading symbols...")
    syms, names = load_symbols()
    print(f"  {len(syms)} symbols")

    rom = load_rom()
    data = rom[start_addr - ROM_BASE:start_addr - ROM_BASE + block_size]
    assert len(data) == block_size, f"ROM data size mismatch: {len(data)} != {block_size}"

    # Build region list from .equ offsets
    regions = []
    if equs:
        # First region: from 0 to first .equ
        if equs[0][0] > 0:
            regions.append((0, equs[0][0], 'widget_data'))
        # Regions from .equ offsets
        for i, (off, name) in enumerate(equs):
            field_name = sanitize_field_name(name)
            if i + 1 < len(equs):
                end = equs[i + 1][0]
            else:
                end = block_size
            regions.append((off, end, field_name))
    else:
        # No .equ offsets -- single region
        regions.append((0, block_size, 'data'))

    # Merge very small regions (< 4 bytes) into preceding region
    merged = []
    for off, end, name in regions:
        size = end - off
        if merged and size < 4:
            # Extend previous region
            prev_off, prev_end, prev_name = merged[-1]
            merged[-1] = (prev_off, end, prev_name)
        else:
            merged.append((off, end, name))
    regions = merged

    print(f"  {len(regions)} regions")

    # Identify pointer table regions and collect extern symbols
    extern_syms = set()
    ptr_table_regions = set()
    for off, end, name in regions:
        region_data = data[off:end]
        is_ptr, resolved, total = is_pointer_table(region_data, syms, threshold=0.3)
        if is_ptr and len(region_data) >= 16:
            ptr_table_regions.add(name)
            # Collect extern symbols from this pointer table
            for i in range(total):
                val = struct.unpack_from('<I', region_data, i * 4)[0]
                if val in syms and val != 0 and val != 0xFFFFFFFF:
                    extern_syms.add(syms[val])

    print(f"  {len(ptr_table_regions)} pointer table regions")
    print(f"  {len(extern_syms)} extern symbols")

    # Derive struct name from C file name
    c_name = c_path.stem  # e.g. naka_widget_names_charmap
    struct_name = c_name + '_t'

    # Generate C file
    out = []
    out.append('/**')
    out.append(f' * {c_path.name} -- NAKA widget data (C struct conversion)')
    out.append(' *')
    out.append(f' * Base ROM address: 0x{start_addr:06X}')
    out.append(f' * Total size: {block_size} bytes')
    out.append(' * Converted from raw byte array to named struct fields.')
    out.append(' */')
    out.append('')
    out.append('#include "naka_types.h"')
    out.append('')

    # Extern declarations
    if extern_syms:
        out.append('/* External symbols (addresses resolved by linker script) */')
        out.append('')
        for sym in sorted(extern_syms):
            out.append(f'extern const char {sym};')
        out.append('')

    out.append(f'#define BASE  0x{start_addr:08X}u')
    out.append('')

    # Struct typedef
    out.append(f'typedef struct __attribute__((packed)) {{')
    for off, end, name in regions:
        size = end - off
        if name in ptr_table_regions:
            out.append(f'    uint32_t {name}[{size // 4}];  /* 0x{off:04X}, {size} bytes */')
        else:
            out.append(f'    uint8_t {name}[{size}];  /* 0x{off:04X}, {size} bytes */')
    out.append(f'}} {struct_name};')
    out.append('')
    out.append(f'#define SELF(field) \\')
    out.append(f'    ((uint32_t)(BASE + __builtin_offsetof({struct_name}, field)))')
    out.append('')
    out.append(f'_Static_assert(sizeof({struct_name}) == {block_size},')
    out.append(f'    "{c_name} must be exactly {block_size} bytes");')
    out.append('')

    # Data initializer
    out.append(f'const {struct_name} {var_name}')
    out.append(f'    __attribute__((section(".text"), used)) = {{')
    out.append('')

    for off, end, name in regions:
        region_data = data[off:end]
        size = len(region_data)

        if name in ptr_table_regions:
            out.append(f'    /* {name} - pointer table */')
            out.append(f'    .{name} = {{')
            for i in range(size // 4):
                val = struct.unpack_from('<I', region_data, i * 4)[0]
                sym_str = format_val32(val, syms)
                out.append(f'        {sym_str},')
            out.append('    },')
        else:
            out.append(f'    /* {name} */')
            out.append(f'    .{name} = {{')
            out.append(format_bytes_as_hex(region_data))
            out.append('    },')
        out.append('')

    out.append('};')
    out.append('')
    out.append('#undef SELF')
    out.append('#undef BASE')
    out.append('')

    content = '\n'.join(out)

    # Verify all content is ASCII
    try:
        content.encode('ascii')
    except UnicodeEncodeError as e:
        print(f"  ERROR: Non-ASCII character in output: {e}")
        # Find and replace non-ASCII
        clean = content.encode('ascii', errors='replace').decode('ascii')
        content = clean

    if dry_run:
        print(f"\n=== Generated C file ({len(out)} lines) ===")
        print(content[:3000])
        print("...")
        return

    # Write C file
    with open(c_path, 'wb') as f:
        f.write(content.encode('ascii'))
    print(f"  Written: {c_path} ({len(content)} bytes)")

    # Generate linker script
    ld_path = c_path.with_name(c_name + '_link.ld')
    ld_lines = []
    ld_lines.append(f'/* {ld_path.name} -- Linker script for {c_path.name}')
    ld_lines.append(f' * Auto-generated by scripts/convert_naka_to_struct.py')
    ld_lines.append(f' */')
    ld_lines.append('')
    ld_lines.append('ENTRY(0)')
    ld_lines.append('')
    ld_lines.append('SECTIONS {')
    ld_lines.append('    .text : { *(.text*) }')
    ld_lines.append('    /DISCARD/ : { *(.comment) *(.note*) *(.eh_frame*) }')
    ld_lines.append('}')
    ld_lines.append('')
    for sym in sorted(extern_syms):
        if sym in names:
            ld_lines.append(f'{sym} = 0x{names[sym]:08X};')
        else:
            ld_lines.append(f'/* WARNING: {sym} not found in ELF */')
    ld_lines.append('')

    ld_content = '\n'.join(ld_lines)
    with open(ld_path, 'wb') as f:
        f.write(ld_content.encode('ascii'))
    print(f"  Written: {ld_path}")


def main():
    import argparse
    parser = argparse.ArgumentParser(description='Convert NAKA C file to struct')
    parser.add_argument('c_file', help='Path to the raw C file')
    parser.add_argument('--start-addr', help='Start ROM address (hex, e.g. 0xEAD470)')
    parser.add_argument('--size', type=int, help='Data size in bytes')
    parser.add_argument('--var-name', help='Variable name override')
    parser.add_argument('--dry-run', action='store_true', help='Print without writing')
    args = parser.parse_args()

    c_path = Path(args.c_file)
    if not c_path.exists():
        print(f"ERROR: {c_path} not found")
        sys.exit(1)

    overrides = {}
    if args.start_addr:
        overrides['start_addr'] = int(args.start_addr, 16)
    if args.size:
        overrides['size'] = args.size
    if args.var_name:
        overrides['var_name'] = args.var_name

    generate_conversion(c_path, args.dry_run, overrides)


if __name__ == '__main__':
    main()
