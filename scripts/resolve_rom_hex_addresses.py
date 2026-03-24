#!/usr/bin/env python3
"""
Resolve hex ROM addresses (>= 0xe00000) in assembly instruction operands.

Part 1: Replace exact-match addresses with existing ELF symbols.
Part 3: For addresses without ELF symbols, create .set definitions
        with absolute hex addresses and replace hex values with new names.

Usage:
    python3 scripts/resolve_rom_hex_addresses.py [--dry-run] [--part1-only]
"""

import bisect
import os
import re
import subprocess
import sys
import tempfile
from collections import defaultdict

LLVM_NM = "/mnt/shared/llvm-project/build/bin/llvm-nm"
BASE_DIR = "/mnt/shared/kn5000-roms-disasm"


def load_elf_symbols(elf_path):
    """Load address->symbol and sorted symbol list from ELF."""
    result = subprocess.run(
        [LLVM_NM, "--no-sort", elf_path],
        capture_output=True, text=True, check=True
    )
    addr_to_sym = {}
    abs_syms = set()  # symbols that are absolute (.set/.equ defined)
    sorted_syms = []
    for line in result.stdout.splitlines():
        parts = line.split()
        if len(parts) >= 3:
            addr = int(parts[0], 16)
            typ = parts[1]
            name = parts[2]
            if 0xe00000 <= addr <= 0xffffff:
                if addr not in addr_to_sym:
                    addr_to_sym[addr] = name
                if typ == 'a':
                    abs_syms.add(name)
                else:
                    sorted_syms.append((addr, name))
    sorted_syms.sort()
    return addr_to_sym, sorted_syms, abs_syms


def load_all_defined_symbols(files):
    """Load all symbol names defined in source (labels + .set/.equ)."""
    symbols = set()
    set_equ_pat = re.compile(rb'^\s*\.(?:set|equ)\s+(\w+)', re.IGNORECASE)
    label_pat = re.compile(rb'^(\w+):', re.IGNORECASE)
    for f in files:
        with open(f, 'rb') as fh:
            for line in fh:
                m = set_equ_pat.match(line)
                if m:
                    symbols.add(m.group(1).decode('latin-1'))
                m = label_pat.match(line)
                if m:
                    symbols.add(m.group(1).decode('latin-1'))
    return symbols


def find_s_files(version_dir):
    """Find all .s files recursively under a maincpu directory."""
    result = []
    maincpu = os.path.join(BASE_DIR, version_dir, "maincpu")
    for root, dirs, files in os.walk(maincpu):
        for f in files:
            if f.endswith('.s'):
                result.append(os.path.join(root, f))
    return sorted(result)


def find_nearest_label(sorted_syms, sym_addrs, addr):
    """Find nearest preceding label for an address."""
    idx = bisect.bisect_right(sym_addrs, addr) - 1
    if idx >= 0:
        return sorted_syms[idx]
    return None


# Skip patterns
DIRECTIVE_RE = re.compile(rb'^\s*\.(set|equ|byte|long|short|word|ascii|asciz|zero|fill|incbin|include|org)\b', re.IGNORECASE)
MACRO_RE = re.compile(rb'^\s*(Reg\w+|DrawText|DrawBitmap|FillRect|NAKA_HDR|NAKA_ADDR|SELF|ALIGNED_STRING)\b', re.IGNORECASE)
AND_OR_XOR_RE = re.compile(rb'^\s*(and|or|xor)\w*\s', re.IGNORECASE)
HEX_RE = re.compile(rb'(0x00([eEfF][0-9a-fA-F]{5})|0x([eEfF][0-9a-fA-F]{5}))\b')

BITMASK_VALUES = {
    0xff0000, 0xffff0000, 0xff00, 0xff, 0xffff, 0xffffff,
    0xfe0000, 0xfc0000, 0xf00000, 0xff000000, 0x00ff0000,
}


def should_skip_line(line):
    """Check if a line should be skipped for replacement."""
    stripped = line.strip()
    if stripped.startswith(b';') or stripped.startswith(b'#'):
        return True
    if DIRECTIVE_RE.match(line):
        return True
    if MACRO_RE.match(line):
        return True
    if re.match(rb'^\s*\w+:\s*(;.*)?$', line):
        return True
    return False


def is_bitmask_context(line, val):
    """Check if hex value is a bitmask in and/or/xor."""
    if AND_OR_XOR_RE.match(line) and val in BITMASK_VALUES:
        return True
    return False


def extract_rom_addr(match):
    """Extract the 24-bit ROM address from a regex match."""
    hex_part = match.group(2) or match.group(3)
    return int(hex_part, 16)


def collect_hex_addresses(files):
    """Collect all unique hex ROM addresses in instruction operands."""
    addrs = set()
    for filepath in files:
        with open(filepath, 'rb') as f:
            for line in f:
                if should_skip_line(line):
                    continue
                for m in HEX_RE.finditer(line):
                    comment_pos = line.find(b';')
                    if comment_pos >= 0 and m.start() > comment_pos:
                        continue
                    val = extract_rom_addr(m)
                    if not is_bitmask_context(line, val):
                        addrs.add(val)
    return addrs


def find_main_program_file(version_dir):
    """Find the main program .s file where .set definitions should go."""
    name = f'kn5000_{version_dir}_program.s'
    path = os.path.join(BASE_DIR, version_dir, 'maincpu', name)
    if os.path.exists(path):
        return path
    return None


def find_set_insertion_point(lines):
    """Find line index to insert .set definitions.
    MUST insert BEFORE the .org directive so that symbols are defined
    before any code is assembled. This is critical because some instructions
    (addm32_24) don't support forward references/relocations."""
    # Find the .org line — insert before it
    for i, line in enumerate(lines):
        if re.match(rb'\s*\.org\b', line, re.I):
            return i
    # Fallback: before first .include after constants
    for i, line in enumerate(lines):
        if re.match(rb'\s*\.include\b', line, re.I):
            # Skip early constant includes
            if b'macros' in line or b'sfr_' in line or b'constants' in line or b'event_codes' in line:
                continue
            return i
    return 0


def generate_new_label_name(parent_name, offset):
    """Generate a label name for a mid-function entry point."""
    return f"{parent_name}_0x{offset:02X}"


def process_version(version_dir, addr_to_sym, sorted_syms, abs_syms,
                    existing_symbols, part1_only=False, dry_run=False):
    """Process all files in a version directory."""
    files = find_s_files(version_dir)
    sym_addrs = [s[0] for s in sorted_syms]

    hex_addrs = collect_hex_addresses(files)
    print(f"  Total unique hex ROM addresses in instructions: {len(hex_addrs)}")

    resolvable = {}
    needs_label = {}

    for addr in sorted(hex_addrs):
        if addr in addr_to_sym:
            sym = addr_to_sym[addr]
            # Skip absolute symbols (.set/.equ) — using them as forward refs
            # causes "invalid reassignment" when the .set comes after the use
            if sym not in abs_syms:
                resolvable[addr] = sym
            # Fall through to needs_label for absolute symbols
            else:
                if not part1_only:
                    nearest = find_nearest_label(sorted_syms, sym_addrs, addr)
                    if nearest:
                        parent_addr, parent_name = nearest
                        offset = addr - parent_addr
                        if offset > 0:
                            new_name = generate_new_label_name(parent_name, offset)
                            while new_name in existing_symbols:
                                new_name += "_"
                            needs_label[addr] = (parent_name, offset, new_name)
        elif not part1_only:
            nearest = find_nearest_label(sorted_syms, sym_addrs, addr)
            if nearest:
                parent_addr, parent_name = nearest
                offset = addr - parent_addr
                if offset > 0:
                    new_name = generate_new_label_name(parent_name, offset)
                    while new_name in existing_symbols:
                        new_name += "_"
                    needs_label[addr] = (parent_name, offset, new_name)

    print(f"  Resolvable (exact ELF match): {len(resolvable)}")
    print(f"  Needs new .set label: {len(needs_label)}")

    if dry_run:
        for addr, sym in list(resolvable.items())[:5]:
            print(f"    0x{addr:06x} -> {sym} (exact)")
        for addr, (parent, off, name) in list(needs_label.items())[:10]:
            print(f"    0x{addr:06x} -> {name} (.set {name}, 0x{addr:06x})")
        return len(resolvable), len(needs_label), set()

    # Build replacement map
    replacement_map = {}
    for addr, sym in resolvable.items():
        replacement_map[addr] = sym
    for addr, (parent, offset, new_name) in needs_label.items():
        replacement_map[addr] = new_name

    # Insert .set definitions with ABSOLUTE addresses (not parent+offset)
    # This avoids forward reference issues with instructions like addm32_24
    new_set_names = set()
    if needs_label:
        main_file = find_main_program_file(version_dir)
        if main_file:
            set_defs = []
            for addr in sorted(needs_label.keys()):
                parent_name, offset, new_name = needs_label[addr]
                # Use absolute address to avoid forward reference crashes
                set_defs.append(f"\t.set {new_name}, 0x{addr:06x}\n")
                new_set_names.add(new_name)

            with open(main_file, 'rb') as f:
                lines = f.readlines()

            insert_point = find_set_insertion_point(lines)

            set_block = [b"\t; Auto-generated labels for mid-function ROM addresses\n"]
            for d in set_defs:
                set_block.append(d.encode('latin-1'))

            lines[insert_point:insert_point] = set_block

            fd, tmp = tempfile.mkstemp(dir=os.path.dirname(main_file))
            try:
                with os.fdopen(fd, 'wb') as f:
                    f.writelines(lines)
                os.replace(tmp, main_file)
            except:
                os.unlink(tmp)
                raise

            print(f"  Inserted {len(set_defs)} .set definitions in {os.path.relpath(main_file, BASE_DIR)}")

    # Replace hex addresses in all files
    total_replacements = 0
    for filepath in files:
        with open(filepath, 'rb') as f:
            lines = f.readlines()

        file_changes = 0
        new_lines = []

        for line in lines:
            if should_skip_line(line):
                new_lines.append(line)
                continue

            def replace_hex(m):
                nonlocal file_changes
                val = extract_rom_addr(m)
                if val not in replacement_map:
                    return m.group(0)
                comment_pos = line.find(b';')
                if comment_pos >= 0 and m.start() > comment_pos:
                    return m.group(0)
                if is_bitmask_context(line, val):
                    return m.group(0)
                file_changes += 1
                return replacement_map[val].encode('latin-1')

            new_line = HEX_RE.sub(replace_hex, line)
            new_lines.append(new_line)

        if file_changes > 0:
            fd, tmp = tempfile.mkstemp(dir=os.path.dirname(filepath))
            try:
                with os.fdopen(fd, 'wb') as f:
                    f.writelines(new_lines)
                os.replace(tmp, filepath)
            except:
                os.unlink(tmp)
                raise

            total_replacements += file_changes
            print(f"  {os.path.relpath(filepath, BASE_DIR)}: {file_changes} replacements")

    print(f"  Total replacements: {total_replacements}")
    return len(resolvable), len(needs_label), new_set_names


def main():
    dry_run = '--dry-run' in sys.argv
    part1_only = '--part1-only' in sys.argv

    v10_elf = os.path.join(BASE_DIR, "rebuilt_ROMs/kn5000_v10_program.llvm.elf")
    v9_elf = os.path.join(BASE_DIR, "rebuilt_ROMs/kn5000_v9_program.llvm.elf")

    print("Loading v10 ELF symbols...")
    v10_addr_to_sym, v10_sorted, v10_abs = load_elf_symbols(v10_elf)
    print(f"  {len(v10_addr_to_sym)} addr->sym, {len(v10_sorted)} sorted, {len(v10_abs)} absolute")

    print("Loading v9 ELF symbols...")
    v9_addr_to_sym, v9_sorted, v9_abs = load_elf_symbols(v9_elf)
    print(f"  {len(v9_addr_to_sym)} addr->sym, {len(v9_sorted)} sorted, {len(v9_abs)} absolute")

    all_files = find_s_files("v10") + find_s_files("v9")
    existing_symbols = load_all_defined_symbols(all_files)
    print(f"Found {len(existing_symbols)} existing symbol names")

    print("\n=== Processing v10 ===")
    r10, n10, new10 = process_version("v10", v10_addr_to_sym, v10_sorted,
                                       v10_abs, existing_symbols, part1_only, dry_run)

    existing_symbols.update(new10)

    print("\n=== Processing v9 ===")
    r9, n9, new9 = process_version("v9", v9_addr_to_sym, v9_sorted,
                                    v9_abs, existing_symbols, part1_only, dry_run)

    print(f"\n=== TOTALS ===")
    print(f"Exact resolutions: {r10 + r9}")
    print(f"New labels created: {n10 + n9}")
    if dry_run:
        print("(DRY RUN)")


if __name__ == '__main__':
    main()
