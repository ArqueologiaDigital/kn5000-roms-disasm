#!/usr/bin/env python3
"""
Create proper v7 source files by adapting v9 source files.

Replaces v7_postshift_blob.bin with proper .s source files that assemble
to produce a 100% byte-matching v7 ROM.

Strategy:
1. Copy v9 .s files to v7 (most code is identical, symbolic labels auto-resolve)
2. Replace 15 code blocks that have different sizes with .incbin of v7 ROM data
3. Fix the .fill padding (use .org 0xfffe80 for auto-padding)
4. Remove the v9-specific .org in fdc_routines.s
5. Generate v7-specific .set directives for:
   a. The 623 inline sub-labels from v9 (with v7 addresses)
   b. Internal labels of .incbin-replaced blocks
6. Extract v7-specific .incbin data blocks from the ROM

Usage:
    cd /home/fsanches/compartilhado/kn5000-roms-disasm
    python3 scripts/build/create_v7_source.py
    make rebuilt_ROMs/kn5000_v7_program.llvm.rom
"""

import subprocess
import os
import re
import sys
import pickle

LLVM_NM = '/home/fsanches/compartilhado/llvm-project/build/bin/llvm-nm'
V7_ROM = 'original_ROMs/kn5000_v7_program.rom'
V9_ROM = 'original_ROMs/kn5000_v9_program.rom'
V9_ELF = 'rebuilt_ROMs/kn5000_v9_program.llvm.elf'

def get_symbols(elf_path):
    """Get all symbols from an ELF file."""
    result = subprocess.run([LLVM_NM, '--numeric-sort', elf_path],
                          capture_output=True, text=True)
    syms = []
    sym_map = {}
    for line in result.stdout.strip().split('\n'):
        parts = line.strip().split()
        if len(parts) >= 3:
            addr = int(parts[0], 16)
            name = parts[2]
            if 0xe00000 <= addr <= 0xffffff:
                syms.append((addr, name))
                sym_map[name] = addr
    syms.sort()
    return syms, sym_map

def build_v7_map(v9_syms, v7_rom, v9_rom):
    """Build v7 symbol map by fingerprinting."""
    v7_map = {}
    FINGERPRINT_LEN = 16

    # Strategy 1: 16-byte fingerprint, +/-2048
    for addr, name in v9_syms:
        off = addr - 0xe00000
        if off < 0 or off + FINGERPRINT_LEN > len(v9_rom):
            continue
        fp = v9_rom[off:off + FINGERPRINT_LEN]
        if len(set(fp)) <= 1:
            continue

        search_start = max(0, off - 2048)
        search_end = min(len(v7_rom) - FINGERPRINT_LEN, off + 2048)

        matches = []
        pos = search_start
        while pos <= search_end:
            idx = v7_rom.find(fp, pos, search_end + FINGERPRINT_LEN)
            if idx == -1:
                break
            matches.append(idx + 0xe00000)
            pos = idx + 1

        if len(matches) == 1:
            v7_map[name] = matches[0]

    # Strategy 2: 32-byte fingerprint, +/-8192
    for addr, name in v9_syms:
        if name in v7_map:
            continue
        off = addr - 0xe00000
        if off < 0 or off + 32 > len(v9_rom):
            continue
        fp = v9_rom[off:off + 32]
        if len(set(fp)) <= 2:
            continue

        search_start = max(0, off - 8192)
        search_end = min(len(v7_rom) - 32, off + 8192)

        matches = []
        pos = search_start
        while pos <= search_end:
            idx = v7_rom.find(fp, pos, search_end + 32)
            if idx == -1:
                break
            matches.append(idx + 0xe00000)
            pos = idx + 1

        if len(matches) == 1:
            v7_map[name] = matches[0]

    # Strategy 3: Interpolate from known neighbors
    mapped_sorted = sorted([(name, v9_addr, v7_map[name])
                           for v9_addr, name in v9_syms if name in v7_map],
                          key=lambda x: x[1])

    for v9_addr, name in v9_syms:
        if name in v7_map:
            continue
        prev = next_s = None
        for mn, mv9, mv7 in mapped_sorted:
            if mv9 <= v9_addr:
                prev = (mn, mv9, mv7)
            elif next_s is None:
                next_s = (mn, mv9, mv7)
                break
        if prev and next_s:
            prev_shift = prev[2] - prev[1]
            next_shift = next_s[2] - next_s[1]
            if prev_shift == next_shift:
                v7_map[name] = v9_addr + prev_shift

    return v7_map


def main():
    if not os.path.exists(V9_ELF):
        print("Building v9 ELF first...")
        os.system('make rebuilt_ROMs/kn5000_v9_program.llvm.rom')

    v7_rom = open(V7_ROM, 'rb').read()
    v9_rom = open(V9_ROM, 'rb').read()

    print("Getting v9 symbols...")
    v9_syms, v9_sym_map = get_symbols(V9_ELF)
    print(f"  {len(v9_syms)} symbols")

    print("Building v7 symbol map...")
    v7_map = build_v7_map(v9_syms, v7_rom, v9_rom)
    print(f"  {len(v7_map)} mapped ({100*len(v7_map)/len(v9_syms):.1f}%)")

    # Save for use by other scripts
    with open('/tmp/v7_symbol_map.pkl', 'wb') as f:
        pickle.dump(v7_map, f)

    print("\nV7 symbol map built successfully.")
    print("Next steps: use this map to create v7-specific source files.")

if __name__ == '__main__':
    main()
