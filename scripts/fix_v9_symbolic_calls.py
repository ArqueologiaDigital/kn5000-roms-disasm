#!/usr/bin/env python3
"""
Resolve numeric call/jp addresses to symbolic labels in v9 maincpu source files.

Reads the v9 ELF symbol table, scans all .s files for:
  - call DECIMAL_NUMBER (where number >= 0xE00000)
  - jp [COND,] DECIMAL_NUMBER (where number >= 0xE00000)
and replaces the numeric address with the symbol name if found.

Uses binary I/O to preserve Latin-1 encoding.
"""

import os
import re
import subprocess
import sys
from collections import defaultdict

LLVM_NM = "/home/fsanches/compartilhado/llvm-project/build/bin/llvm-nm"
V9_ELF = "rebuilt_ROMs/kn5000_v9_program.llvm.elf"
V9_MAINCPU = "v9/maincpu"
ROM_BASE = 0xE00000

def load_symbols(elf_path):
    """Load address->symbol mapping from ELF. Only ROM-range symbols."""
    result = subprocess.run(
        [LLVM_NM, "--no-sort", elf_path],
        capture_output=True, text=True, check=True
    )
    addr_to_sym = {}
    for line in result.stdout.splitlines():
        parts = line.strip().split()
        if len(parts) >= 3:
            addr_str, sym_type, name = parts[0], parts[1], parts[2]
            try:
                addr = int(addr_str, 16)
            except ValueError:
                continue
            if addr >= ROM_BASE:
                # Prefer 't' (text) symbols over 'a' (absolute) for same address
                if addr not in addr_to_sym or sym_type == 't':
                    addr_to_sym[addr] = name
    return addr_to_sym

def process_file(filepath, addr_to_sym, stats):
    """Process a single .s file, replacing numeric addresses with symbols."""
    with open(filepath, 'rb') as f:
        data = f.read()

    text = data.decode('latin-1')
    lines = text.split('\n')
    modified = False
    file_replacements = 0

    # Pattern for: call DECIMAL_NUMBER
    # Pattern for: jp DECIMAL_NUMBER  or  jp COND, DECIMAL_NUMBER
    # The decimal number must be >= 0xE00000 (14680064)

    call_pattern = re.compile(r'^(\s*call\s+)(\d+)(\s*(?:;.*)?)$', re.IGNORECASE)
    jp_pattern = re.compile(r'^(\s*jp\s+)(\d+)(\s*(?:;.*)?)$', re.IGNORECASE)
    jp_cond_pattern = re.compile(r'^(\s*jp\s+\w+,\s*)(\d+)(\s*(?:;.*)?)$', re.IGNORECASE)

    new_lines = []
    for line in lines:
        new_line = line

        for pattern in [call_pattern, jp_pattern, jp_cond_pattern]:
            m = pattern.match(line)
            if m:
                prefix, num_str, suffix = m.group(1), m.group(2), m.group(3)
                addr = int(num_str)
                if addr >= ROM_BASE and addr in addr_to_sym:
                    sym = addr_to_sym[addr]
                    new_line = prefix + sym + suffix
                    modified = True
                    file_replacements += 1
                    stats['resolved'] += 1
                elif addr >= ROM_BASE:
                    stats['unresolved'] += 1
                break

        new_lines.append(new_line)

    if modified:
        new_text = '\n'.join(new_lines)
        new_data = new_text.encode('latin-1')
        with open(filepath, 'wb') as f:
            f.write(new_data)
        print(f"  {filepath}: {file_replacements} replacements")
        stats['files_modified'] += 1

    return modified

def main():
    os.chdir("/home/fsanches/compartilhado/kn5000-roms-disasm")

    print("Loading v9 ELF symbols...")
    addr_to_sym = load_symbols(V9_ELF)
    rom_syms = {a: s for a, s in addr_to_sym.items() if a >= ROM_BASE}
    print(f"  {len(rom_syms)} symbols in ROM range (>= 0x{ROM_BASE:06X})")

    # Find all .s files
    s_files = []
    for root, dirs, files in os.walk(V9_MAINCPU):
        for f in files:
            if f.endswith('.s'):
                s_files.append(os.path.join(root, f))
    s_files.sort()
    print(f"  {len(s_files)} source files to scan")

    # First pass: count how many we'll fix
    print("\nScanning for numeric call/jp addresses...")
    stats = {'resolved': 0, 'unresolved': 0, 'files_modified': 0}

    for filepath in s_files:
        process_file(filepath, addr_to_sym, stats)

    print(f"\nDone:")
    print(f"  Files modified: {stats['files_modified']}")
    print(f"  Addresses resolved to symbols: {stats['resolved']}")
    print(f"  Addresses with no symbol (kept numeric): {stats['unresolved']}")

if __name__ == '__main__':
    main()
