#!/usr/bin/env python3
"""
version_patch.py — Patch a ROM disassembly source tree to match a target ROM version.

Given:
  - A reference ELF (built from the source tree)
  - The target ROM binary (what we want to match)
  - The reference ROM binary (what the source currently produces)

This script:
  1. Finds all byte differences between reference and target ROMs
  2. Maps each difference to an ELF symbol
  3. Locates the corresponding source line in the .s files
  4. Patches the source to produce the target bytes

Usage:
  python version_patch.py --ref-elf rebuilt_ROMs/kn5000_v10_program.llvm.elf \
    --ref-rom original_ROMs/kn5000_v10_program.rom \
    --target-rom original_ROMs/kn5000_v9_program.rom \
    --source-dir v9/maincpu \
    --rom-base 0xE00000 \
    [--dry-run]
"""

import argparse
import subprocess
import struct
import sys
import os
import re
from collections import defaultdict


def parse_args():
    p = argparse.ArgumentParser(description='Patch ROM disassembly for a different version')
    p.add_argument('--ref-elf', required=True, help='Reference ELF file (built from source)')
    p.add_argument('--ref-rom', required=True, help='Reference ROM binary')
    p.add_argument('--target-rom', required=True, help='Target ROM binary to match')
    p.add_argument('--source-dir', required=True, help='Source directory to patch')
    p.add_argument('--rom-base', required=True, help='ROM base address (hex, e.g. 0xE00000)')
    p.add_argument('--llvm-bin', default='/home/fsanches/compartilhado/llvm-project/build/bin',
                   help='Path to LLVM bin directory')
    p.add_argument('--dry-run', action='store_true', help='Report changes without modifying files')
    return p.parse_args()


def load_symbols(llvm_bin, elf_path):
    """Load symbols from ELF, returns sorted list of (addr, name)."""
    result = subprocess.run(
        [f'{llvm_bin}/llvm-nm', '--no-sort', elf_path],
        capture_output=True, text=True
    )
    symbols = []
    for line in result.stdout.strip().split('\n'):
        parts = line.split()
        if len(parts) >= 3:
            addr = int(parts[0], 16)
            name = parts[2]
            symbols.append((addr, name))
    symbols.sort()
    return symbols


def find_symbol(symbols, addr):
    """Find the symbol containing the given address."""
    lo, hi = 0, len(symbols) - 1
    best = None
    while lo <= hi:
        mid = (lo + hi) // 2
        if symbols[mid][0] <= addr:
            best = mid
            lo = mid + 1
        else:
            hi = mid - 1
    if best is not None:
        return symbols[best]
    return None


def find_diffs(ref_rom, target_rom, rom_base):
    """Find all differing byte ranges between two ROMs.
    Returns list of (rom_addr, ref_bytes, target_bytes)."""
    assert len(ref_rom) == len(target_rom), "ROM sizes must match"
    diffs = []
    i = 0
    while i < len(ref_rom):
        if ref_rom[i] != target_rom[i]:
            start = i
            while i < len(ref_rom) and ref_rom[i] != target_rom[i]:
                i += 1
            addr = rom_base + start
            ref_bytes = ref_rom[start:i]
            target_bytes = target_rom[start:i]
            diffs.append((addr, ref_bytes, target_bytes))
        else:
            i += 1
    return diffs


def build_address_to_source_map(source_dir, llvm_bin, rom_base):
    """Build a mapping from ROM addresses to source file lines.

    Uses llvm-mc --show-encoding to get byte offsets for each source line,
    then maps offsets to absolute ROM addresses via the linker script.

    This is complex, so we use an alternative approach: parse the source files
    and track the cumulative byte position based on directive sizes.
    """
    # Alternative: use llvm-objdump on the ELF to get addr→instruction mapping,
    # then match instructions back to source lines via label proximity.
    # For now, we'll use a simpler approach based on label addresses.
    pass


def find_source_file_for_symbol(source_dir, symbol_name):
    """Find which .s file defines a given symbol (label:)."""
    # Search for "symbol_name:" at the start of a line
    pattern = re.compile(rb'^' + re.escape(symbol_name.encode()) + rb'\s*:', re.MULTILINE)

    for root, dirs, files in os.walk(source_dir):
        for fname in files:
            if fname.endswith('.s'):
                fpath = os.path.join(root, fname)
                with open(fpath, 'rb') as f:
                    content = f.read()
                if pattern.search(content):
                    return fpath
    return None


def patch_byte_in_source(source_file, symbol_name, offset_in_symbol, ref_byte, target_byte,
                          ref_rom, target_rom, rom_base, symbols, dry_run=False):
    """Attempt to patch a single byte difference in a source file.

    Returns True if patched, False if manual intervention needed.
    """
    # This is the hard part. We need to find the exact source line that
    # produces the byte at (symbol_addr + offset_in_symbol).
    #
    # For now, just report what needs changing.
    return False


def main():
    args = parse_args()
    rom_base = int(args.rom_base, 16)

    # Load ROMs
    with open(args.ref_rom, 'rb') as f:
        ref_rom = f.read()
    with open(args.target_rom, 'rb') as f:
        target_rom = f.read()

    # Load symbols
    symbols = load_symbols(args.llvm_bin, args.ref_elf)
    print(f"Loaded {len(symbols)} symbols from {args.ref_elf}")

    # Find diffs
    diffs = find_diffs(ref_rom, target_rom, rom_base)
    total_bytes = sum(len(d[1]) for d in diffs)
    print(f"Found {len(diffs)} diff regions ({total_bytes} bytes total)")

    # Group by symbol
    symbol_diffs = defaultdict(list)
    for addr, ref_bytes, target_bytes in diffs:
        sym = find_symbol(symbols, addr)
        if sym:
            sym_addr, sym_name = sym
            offset = addr - sym_addr
            symbol_diffs[sym_name].append({
                'addr': addr,
                'offset': offset,
                'ref_bytes': ref_bytes,
                'target_bytes': target_bytes,
            })

    # Find source files for each symbol
    print(f"\nMapping {len(symbol_diffs)} affected symbols to source files...")

    file_diffs = defaultdict(list)
    unmapped = []

    for sym_name, sym_diff_list in symbol_diffs.items():
        source_file = find_source_file_for_symbol(args.source_dir, sym_name)
        if source_file:
            for d in sym_diff_list:
                d['symbol'] = sym_name
            file_diffs[source_file].extend(sym_diff_list)
        else:
            unmapped.append((sym_name, sym_diff_list))

    # Report
    print(f"\nDiffs by source file:")
    for fpath, fdiffs in sorted(file_diffs.items()):
        rel_path = os.path.relpath(fpath, args.source_dir)
        total_bytes = sum(len(d['ref_bytes']) for d in fdiffs)
        n_regions = len(fdiffs)
        n_symbols = len(set(d['symbol'] for d in fdiffs))
        print(f"  {rel_path}: {n_regions} regions, {total_bytes} bytes, {n_symbols} symbols")

    if unmapped:
        print(f"\nUnmapped symbols ({len(unmapped)}):")
        for sym_name, sym_diff_list in unmapped[:10]:
            total = sum(len(d['ref_bytes']) for d in sym_diff_list)
            print(f"  {sym_name}: {len(sym_diff_list)} regions, {total} bytes")
        if len(unmapped) > 10:
            print(f"  ... and {len(unmapped) - 10} more")

    # Detailed per-file report for manual patching
    if args.dry_run:
        print(f"\n{'='*70}")
        print(f"DRY RUN — Detailed change report")
        print(f"{'='*70}")
        for fpath, fdiffs in sorted(file_diffs.items()):
            rel_path = os.path.relpath(fpath, args.source_dir)
            print(f"\n--- {rel_path} ---")
            for d in sorted(fdiffs, key=lambda x: x['addr']):
                ref_hex = ' '.join(f'{b:02x}' for b in d['ref_bytes'][:16])
                tgt_hex = ' '.join(f'{b:02x}' for b in d['target_bytes'][:16])
                suffix = '...' if len(d['ref_bytes']) > 16 else ''
                print(f"  0x{d['addr']:06X} ({d['symbol']}+{d['offset']}):")
                print(f"    ref: {ref_hex}{suffix}")
                print(f"    tgt: {tgt_hex}{suffix}")


if __name__ == '__main__':
    main()
