#!/usr/bin/env python3
"""
Patch remaining mismatched bytes in v7 assembly source files.

Strategy:
1. Build v7 ROM and identify all mismatched byte positions
2. For each mismatch, find the enclosing symbol and its source file/line
3. Find the byte pattern in the source file's .byte/.long directives
4. Replace with the correct v7 byte values
"""

import struct
import subprocess
import os
import re
import sys

ROM_BASE = 0xE00000
LLVM_NM = '/mnt/shared/llvm-project/build/bin/llvm-nm'
V7_ORIG = 'original_ROMs/kn5000_v7_program.rom'
V7_BUILT = 'rebuilt_ROMs/kn5000_v7_program.llvm.rom'
V7_ELF = 'rebuilt_ROMs/kn5000_v7_program.llvm.elf'

def load_rom(path):
    with open(path, 'rb') as f:
        return f.read()

def get_symbols(elf_path):
    result = subprocess.run([LLVM_NM, '--no-sort', elf_path],
                          capture_output=True, text=True)
    syms = {}
    for line in result.stdout.splitlines():
        parts = line.strip().split()
        if len(parts) >= 3 and parts[1] in ('t','T','d','D','r','R'):
            addr = int(parts[0], 16)
            if addr not in syms:
                syms[addr] = parts[2]
    return syms

def find_mismatch_groups(orig, built):
    """Find 4-byte aligned mismatch groups."""
    groups = {}
    for i in range(len(orig)):
        if orig[i] != built[i]:
            aligned = i & ~3
            if aligned not in groups:
                b = built[aligned:aligned+4]
                o = orig[aligned:aligned+4]
                groups[aligned] = {
                    'built_bytes': b,
                    'orig_bytes': o,
                    'offsets': [],
                }
            groups[aligned]['offsets'].append(i)
    return groups

def find_byte_pattern_in_file(filepath, pattern_bytes, max_context=8):
    """Find a byte pattern in a .s file's .byte directives."""
    with open(filepath, 'rb') as f:
        content = f.read()
    text = content.decode('latin-1')
    lines = text.split('\n')

    # Convert pattern bytes to hex strings
    hex_pattern = [f'0x{b:02x}' for b in pattern_bytes]

    # Search for consecutive .byte values matching the pattern
    for i, line in enumerate(lines):
        if '.byte' not in line and '.long' not in line:
            continue
        # Extract hex values from .byte directives
        m = re.search(r'\.byte\s+((?:0x[0-9a-fA-F]+(?:\s*,\s*)?)+)', line)
        if m:
            byte_vals = re.findall(r'0x([0-9a-fA-F]+)', m.group(1))
            for j in range(len(byte_vals) - len(pattern_bytes) + 1):
                match = True
                for k in range(len(pattern_bytes)):
                    if int(byte_vals[j+k], 16) != pattern_bytes[k]:
                        match = False
                        break
                if match:
                    return i, j, line

    return None, None, None

def main():
    print("Loading ROMs...")
    orig = load_rom(V7_ORIG)
    built = load_rom(V7_BUILT)

    print("Getting symbols...")
    syms = get_symbols(V7_ELF)
    sorted_addrs = sorted(syms.keys())

    print("Finding mismatches...")
    groups = find_mismatch_groups(orig, built)
    print(f"Found {len(groups)} 4-byte mismatch groups ({sum(len(g['offsets']) for g in groups.values())} bytes)")

    # For each mismatch, find the enclosing symbol
    for aligned_off, group in groups.items():
        addr = ROM_BASE + aligned_off
        sym_name = "unknown"
        sym_addr = 0
        for sa in sorted_addrs:
            if sa <= addr:
                sym_name = syms[sa]
                sym_addr = sa
            else:
                break
        group['symbol'] = sym_name
        group['sym_addr'] = sym_addr

    # For each mismatch group, find the bytes we need to replace in the source
    # The built bytes contain v9 pointer values, orig bytes contain v7 values
    # We need to search the source files for the built byte pattern and replace
    # with orig bytes

    # Instead of searching source files (complex), let me take a different approach:
    # Generate a binary patch file that contains the byte corrections,
    # and apply it to the rebuilt ROM to verify the approach works.
    # Then we can decide whether to patch source files or use a simpler method.

    # Actually, the SIMPLEST approach: create a Python script that patches
    # the individual .byte values in each .s file. But given the Latin-1 constraint,
    # we need to be very careful with file I/O.

    # For now, let's just create a mapping of (source_symbol, offset_in_symbol) -> correct_byte
    # and use that to inform manual or scripted fixes.

    # Group by symbol for reporting
    by_symbol = {}
    for aligned_off, group in groups.items():
        sym = group['symbol']
        if sym not in by_symbol:
            by_symbol[sym] = {'count': 0, 'byte_fixes': []}
        by_symbol[sym]['count'] += len(group['offsets'])
        for off in group['offsets']:
            sym_offset = off - (group['sym_addr'] - ROM_BASE)
            by_symbol[sym]['byte_fixes'].append({
                'rom_offset': off,
                'sym_offset': sym_offset,
                'built': built[off],
                'orig': orig[off],
            })

    # Sort by byte count
    for sym, info in sorted(by_symbol.items(), key=lambda x: -x[1]['count']):
        if info['count'] >= 3:
            print(f"  {sym}: {info['count']} bytes to fix")

    print(f"\nTotal symbols to fix: {len(by_symbol)}")
    print(f"Total bytes to fix: {sum(info['count'] for info in by_symbol.values())}")

if __name__ == '__main__':
    main()
