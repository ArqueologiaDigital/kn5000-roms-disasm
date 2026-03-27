#!/usr/bin/env python3
"""Compute the v7→v9 shift for every label in the ROM.

For each label in the v9 ELF:
1. Read N bytes from v9 ROM at the label's ELF address
2. Search for that fingerprint in v7 ROM within ±3000 bytes
3. shift = v9_offset − v7_found_offset

Output: v7_shift_map.json mapping label_name → shift_value
"""

import subprocess, json, os, sys

LLVM_NM = '/mnt/shared/llvm-project/build/bin/llvm-nm'
ROM_BASE = 0xE00000


def load_elf_syms(elf_path):
    result = subprocess.run([LLVM_NM, '--no-sort', elf_path],
                           capture_output=True, text=True)
    syms = {}
    for line in result.stdout.strip().split('\n'):
        parts = line.strip().split()
        if len(parts) >= 3:
            try:
                syms[parts[2]] = int(parts[0], 16)
            except ValueError:
                pass
    return syms


def compute_shift_map(v9_elf, v7_rom_path, v9_rom_path):
    v9_syms = load_elf_syms(v9_elf)
    v7_rom = open(v7_rom_path, 'rb').read()
    v9_rom = open(v9_rom_path, 'rb').read()
    rom_size = len(v7_rom)

    # Sort symbols by address for neighbor interpolation
    sorted_syms = sorted(v9_syms.items(), key=lambda x: x[1])

    shift_map = {}
    stats = {'found': 0, 'not_found': 0, 'out_of_range': 0, 'ambiguous': 0}

    for label, v9_addr in sorted_syms:
        v9_offset = v9_addr - ROM_BASE
        if v9_offset < 0 or v9_offset >= rom_size:
            stats['out_of_range'] += 1
            continue

        # Try progressively longer fingerprints
        found = False
        for fp_len in [16, 32, 64]:
            if v9_offset + fp_len > rom_size:
                fp_len = rom_size - v9_offset
            if fp_len < 8:
                break

            fingerprint = v9_rom[v9_offset:v9_offset + fp_len]

            # Search in v7 ROM within ±3000 bytes
            search_start = max(0, v9_offset - 3000)
            search_end = min(rom_size, v9_offset + 3000)

            # Find ALL matches
            matches = []
            pos = search_start
            while pos < search_end:
                idx = v7_rom.find(fingerprint, pos, search_end)
                if idx == -1:
                    break
                matches.append(idx)
                pos = idx + 1

            if len(matches) == 1:
                shift = v9_offset - matches[0]
                shift_map[label] = shift
                stats['found'] += 1
                found = True
                break
            elif len(matches) == 0:
                continue  # try longer fingerprint
            else:
                # Multiple matches — pick closest to v9_offset
                if fp_len >= 32:
                    closest = min(matches, key=lambda x: abs(x - v9_offset))
                    shift = v9_offset - closest
                    shift_map[label] = shift
                    stats['found'] += 1
                    found = True
                    break
                # else try longer fingerprint

        if not found:
            stats['not_found'] += 1

    return shift_map, stats


def main():
    os.chdir('/mnt/shared/kn5000-roms-disasm')

    v9_elf = 'rebuilt_ROMs/kn5000_v9_program.llvm.elf'
    v7_rom = 'original_ROMs/kn5000_v7_program.rom'
    v9_rom = 'original_ROMs/kn5000_v9_program.rom'
    output = 'scripts/analysis/v7_shift_map.json'

    print("Computing v7→v9 shift map for all labels...")
    shift_map, stats = compute_shift_map(v9_elf, v7_rom, v9_rom)

    print(f"\nResults:")
    print(f"  Found:        {stats['found']:,}")
    print(f"  Not found:    {stats['not_found']:,}")
    print(f"  Out of range: {stats['out_of_range']:,}")

    # Shift distribution
    from collections import Counter
    shift_counts = Counter(shift_map.values())
    print(f"\n  Distinct shifts: {len(shift_counts)}")
    print(f"  Shift=0: {shift_counts.get(0, 0)} labels")
    for s, c in shift_counts.most_common(10):
        print(f"    shift={s:+5d}: {c:5d} labels")

    with open(output, 'w') as f:
        json.dump(shift_map, f, indent=None, separators=(',', ':'))

    print(f"\nSaved to {output} ({len(shift_map)} entries)")


if __name__ == '__main__':
    main()
