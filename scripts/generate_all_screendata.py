#!/usr/bin/env python3
"""
Generate C source files for all non-Style-UI ScreenData blocks in the ROM.

Reads the ROM binary, parses ScreenData bytecodes at known addresses,
generates typed C struct source files, and writes them to the source tree.

Each group of overlapping blocks becomes one C file.
"""

import os
import sys
import subprocess

# Add scripts dir to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from screendata_parser import ScreenDataParser, ScreenDataCGenerator

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM_FILE = os.path.join(REPO, 'original_ROMs', 'kn5000_v10_program.rom')

# ── Block definitions ─────────────────────────────────────────────────
# Each entry: (name, address, directory, max_parse_bytes)
# Blocks with the same name prefix that overlap will be combined.

SOUND_EDITOR_BLOCKS = [
    # Draw call XIY blocks (visual layout commands)
    ('se_drumkit_display', 0xF12B86, 500),
    ('se_general_edit', 0xF12D66, 500),
    ('se_compare_screen', 0xF12F95, 500),
    ('se_name_editor', 0xF131E5, 500),
    ('se_parameter_grid', 0xF144E7, 500),
    ('se_setup_sel3', 0xF14E28, 500),
    ('se_transport_display', 0xF149D9, 500),
    ('se_transport_sub', 0xF14A3D, 500),  # subset of transport
    ('se_apply_confirm', 0xF163AA, 500),

    # Setup call XIY blocks (interactive elements)
    ('se_setup_waveform', 0xF1115E, 500),
    ('se_setup_params_full', 0xF11964, 500),
    ('se_setup_params_sub1', 0xF11A14, 500),  # subset
    ('se_setup_params_sub2', 0xF11A37, 500),  # subset
    ('se_setup_labels', 0xF11D41, 500),
    ('se_setup_env', 0xF11E96, 500),
    ('se_setup_nav_full', 0xF12341, 500),
    ('se_setup_nav_sub1', 0xF12386, 500),  # subset
    ('se_setup_nav_sub2', 0xF12391, 500),  # subset
    ('se_setup_ctrl_list', 0xF124F3, 500),
    ('se_setup_sel1', 0xF12B49, 500),
    ('se_setup_drumkit', 0xF12C44, 500),
    ('se_setup_sel2', 0xF12D01, 500),
    ('se_setup_rhythm', 0xF13F72, 500),
    ('se_setup_ctrl_full', 0xF14809, 500),
    ('se_setup_ctrl_sub', 0xF14838, 500),  # subset
    ('se_setup_transport', 0xF1493C, 500),
    ('se_setup_sel_rects', 0xF14DD2, 500),
    ('se_setup_editor_full', 0xF1616F, 500),
    ('se_setup_editor_sub', 0xF16239, 500),  # subset
    ('se_setup_confirm', 0xF163AA, 500),  # same addr as draw
    ('se_setup_sel4', 0xF1659F, 500),
]

ACCOMP_BLOCKS = [
    ('accomp_section_widget', 0xF6AC91, 500),
    ('accomp_part_widget', 0xF6AD18, 500),
    ('accomp_display_full', 0xF6AD2D, 500),
    ('accomp_display', 0xF6AD37, 500),
]


def find_groups(blocks, parser):
    """Group overlapping blocks together."""
    parsed = []
    for name, addr, max_bytes in blocks:
        cmds = parser.parse(addr, max_bytes)
        total = sum(c.size for c in cmds)
        if total > 0:
            parsed.append((name, addr, addr + total, total, cmds))

    parsed.sort(key=lambda x: x[1])  # sort by start address

    groups = []
    if not parsed:
        return groups

    current_group = [parsed[0]]
    for block in parsed[1:]:
        if block[1] < current_group[-1][2]:  # overlaps
            current_group.append(block)
        else:
            groups.append(current_group)
            current_group = [block]
    groups.append(current_group)

    return groups


def generate_group_file(group, output_dir):
    """Generate a single C file for a group of overlapping blocks.

    Uses the earliest (longest) block as the primary data.
    """
    # Use the first (earliest, longest) block
    primary = group[0]
    name, addr, end, size, cmds = primary

    gen = ScreenDataCGenerator(cmds, name, addr)
    code = gen.generate_c()

    # Add entry point comments for sub-blocks
    if len(group) > 1:
        # Insert comment before the struct definition
        lines = code.split('\n')
        insert_idx = next(i for i, l in enumerate(lines) if 'typedef struct' in l)
        entry_comments = ['/* Entry points into this block:']
        for n, a, e, s, c in group:
            offset = a - addr
            entry_comments.append(f' *   {n}: offset {offset} (0x{a:06X}, {s} bytes)')
        entry_comments.append(' */')
        entry_comments.append('')
        lines[insert_idx:insert_idx] = entry_comments
        code = '\n'.join(lines)

    filepath = os.path.join(output_dir, f'{name}.c')
    with open(filepath, 'w') as f:
        f.write(code)

    return filepath, size


def main():
    with open(ROM_FILE, 'rb') as f:
        rom_data = f.read()

    parser = ScreenDataParser(rom_data)

    # Sound editor screens
    se_dir = os.path.join(REPO, 'maincpu', 'audio', 'sound_editor_screens')
    os.makedirs(se_dir, exist_ok=True)

    print("=== Sound Editor Screen Data ===")
    se_groups = find_groups(SOUND_EDITOR_BLOCKS, parser)
    se_total = 0
    se_files = []
    for group in se_groups:
        filepath, size = generate_group_file(group, se_dir)
        se_total += size
        se_files.append(filepath)
        names = ', '.join(b[0] for b in group)
        print(f"  {os.path.basename(filepath):35s} {size:4d} bytes  ({names})")

    print(f"  Total: {len(se_files)} files, {se_total} bytes")
    print()

    # Accompaniment engine screens
    acmp_dir = os.path.join(REPO, 'maincpu', 'sequencer', 'accomp_screens')
    os.makedirs(acmp_dir, exist_ok=True)

    print("=== Accompaniment Engine Screen Data ===")
    acmp_groups = find_groups(ACCOMP_BLOCKS, parser)
    acmp_total = 0
    acmp_files = []
    for group in acmp_groups:
        filepath, size = generate_group_file(group, acmp_dir)
        acmp_total += size
        acmp_files.append(filepath)
        names = ', '.join(b[0] for b in group)
        print(f"  {os.path.basename(filepath):35s} {size:4d} bytes  ({names})")

    print(f"  Total: {len(acmp_files)} files, {acmp_total} bytes")
    print()

    # Verify all generated files compile and byte-match
    print("=== Verification ===")
    clang = os.path.join('/mnt/shared/llvm-project/build/bin/clang')
    objcopy = os.path.join('/mnt/shared/llvm-project/build/bin/llvm-objcopy')
    types_h = os.path.join(REPO, 'maincpu', 'style_ui', 'screendata_types.h')

    all_files = se_files + acmp_files
    passed = 0
    failed = 0

    for filepath in all_files:
        basename = os.path.basename(filepath)
        dirname = os.path.dirname(filepath)

        # Read the C file to extract base address
        with open(filepath) as f:
            content = f.read()
        import re
        m = re.search(r'Base address: 0x([0-9A-Fa-f]+)', content)
        if not m:
            print(f"  {basename}: cannot find base address")
            failed += 1
            continue
        base_addr = int(m.group(1), 16)

        m2 = re.search(r'Size: (\d+) bytes', content)
        expected_size = int(m2.group(1))

        # Copy header to the same directory for include
        import shutil
        local_types = os.path.join(dirname, 'screendata_types.h')
        if not os.path.exists(local_types):
            shutil.copy(types_h, local_types)

        # Compile
        o_file = filepath.replace('.c', '.o')
        bin_file = filepath.replace('.c', '.bin')

        result = subprocess.run(
            [clang, '-target', 'tlcs900', '-ffreestanding', '-c', '-O2',
             filepath, '-o', o_file],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"  {basename}: COMPILE ERROR")
            failed += 1
            continue

        subprocess.run(
            [objcopy, '-O', 'binary', '-j', '.text', o_file, bin_file],
            capture_output=True
        )

        compiled = open(bin_file, 'rb').read()
        off = base_addr - 0xE00000
        original = rom_data[off:off+len(compiled)]

        if compiled == original and len(compiled) == expected_size:
            print(f"  {basename:35s} {expected_size:4d} bytes — MATCH")
            passed += 1
        else:
            mismatches = sum(1 for a, b in zip(compiled, original) if a != b)
            print(f"  {basename:35s} — MISMATCH ({mismatches} bytes, size={len(compiled)} expected={expected_size})")
            failed += 1

        # Clean up temp files
        for f in [o_file, bin_file]:
            if os.path.exists(f):
                os.remove(f)

    # Clean up copied headers
    for d in [se_dir, acmp_dir]:
        h = os.path.join(d, 'screendata_types.h')
        if os.path.exists(h):
            os.remove(h)

    print(f"\n{passed} passed, {failed} failed out of {len(all_files)} files")
    return 0 if failed == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
