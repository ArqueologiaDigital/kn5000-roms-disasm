#!/usr/bin/env python3
"""
Extract correct .incbin data for v7 ROM build.

Strategy:
1. Build v9 symbol map from ELF
2. For each .incbin label, find its v9 ROM address and size
3. Find the code anchor AFTER each .incbin block in v9 ROM
4. Search for that same code anchor in v7 ROM
5. Calculate the v7 block start by looking at the code anchor BEFORE the block
6. Extract v7 data and write to .bin file
"""

import subprocess
import struct
import os
import sys
import re

ROM_BASE = 0xE00000
V9_ROM = 'original_ROMs/kn5000_v9_program.rom'
V7_ROM = 'original_ROMs/kn5000_v7_program.rom'
V9_ELF = 'rebuilt_ROMs/kn5000_v9_program.llvm.elf'
V7_GEN_DIR = 'v7/maincpu/includes/generated'
LLVM_NM = '/mnt/shared/llvm-project/build/bin/llvm-nm'

def load_rom(path):
    with open(path, 'rb') as f:
        return f.read()

def build_symbol_map(elf_path):
    """Build address -> name and name -> address maps from ELF."""
    result = subprocess.run([LLVM_NM, '--no-sort', elf_path],
                          capture_output=True, text=True)
    addr_to_name = {}
    name_to_addr = {}
    for line in result.stdout.splitlines():
        parts = line.strip().split()
        if len(parts) >= 3:
            addr = int(parts[0], 16)
            sym_type = parts[1]
            name = parts[2]
            if sym_type in ('T', 't', 'D', 'd', 'B', 'b', 'R', 'r'):
                addr_to_name[addr] = name
                name_to_addr[name] = addr
    return addr_to_name, name_to_addr

def find_incbin_blocks(source_dir):
    """Parse .s files to find .incbin directives and their labels."""
    blocks = []
    for root, dirs, files in os.walk(source_dir):
        for fname in sorted(files):
            if not fname.endswith('.s'):
                continue
            fpath = os.path.join(root, fname)
            with open(fpath, 'rb') as f:
                lines = f.read().decode('latin-1').splitlines()

            for i, line in enumerate(lines):
                m = re.search(r'\.incbin\s+"includes/generated/([^"]+)"', line)
                if not m:
                    continue
                bin_file = m.group(1)
                # Find the label - could be on same line or previous lines
                label = None
                # Check same line (label: .incbin ...)
                lm = re.match(r'^(\w+):\s*\.incbin', line)
                if lm:
                    label = lm.group(1)
                else:
                    # Look backwards for the label
                    for j in range(i-1, max(i-5, -1), -1):
                        lm = re.match(r'^(\w+):', lines[j])
                        if lm:
                            label = lm.group(1)
                            break

                blocks.append({
                    'label': label,
                    'bin_file': bin_file,
                    'bin_path': os.path.join(V7_GEN_DIR, bin_file),
                    'source_file': fpath,
                    'source_line': i,
                })
    return blocks

def find_bytes_in_rom(rom, pattern, start=0):
    """Find all occurrences of a byte pattern in ROM."""
    results = []
    pos = start
    while True:
        pos = rom.find(pattern, pos)
        if pos == -1:
            break
        results.append(pos)
        pos += 1
    return results

def main():
    print("Loading ROMs...")
    v9_rom = load_rom(V9_ROM)
    v7_rom = load_rom(V7_ROM)

    print("Building v9 symbol map...")
    addr_to_name, name_to_addr = build_symbol_map(V9_ELF)

    print("Finding .incbin blocks...")
    blocks = find_incbin_blocks('v7/maincpu')
    print(f"Found {len(blocks)} .incbin blocks")

    # Get sorted list of all symbol addresses for finding block boundaries
    all_addrs = sorted(addr_to_name.keys())

    # For each block, determine v9 address, size, and extract from v7
    results = []
    for block in blocks:
        label = block['label']
        if label is None:
            print(f"  WARNING: No label found for {block['bin_file']}")
            continue

        if label not in name_to_addr:
            print(f"  WARNING: Label {label} not in v9 symbol map")
            continue

        v9_addr = name_to_addr[label]
        v9_offset = v9_addr - ROM_BASE

        if v9_offset < 0 or v9_offset >= len(v9_rom):
            print(f"  WARNING: {label} at {v9_addr:#x} outside ROM range")
            continue

        # Current .bin file size = v9 block size
        if not os.path.exists(block['bin_path']):
            print(f"  WARNING: {block['bin_path']} doesn't exist")
            continue

        v9_size = os.path.getsize(block['bin_path'])

        block['v9_addr'] = v9_addr
        block['v9_offset'] = v9_offset
        block['v9_size'] = v9_size
        results.append(block)

    # Sort by v9 address
    results.sort(key=lambda b: b['v9_addr'])

    print(f"\n{'Label':<45} {'v9 addr':>10} {'v9 size':>8}")
    print("-" * 70)
    for b in results:
        print(f"{b['label']:<45} {b['v9_addr']:#010x} {b['v9_size']:>8}")

    # Now find each block in v7 by using code anchors
    # Strategy: Take N bytes of code right after each .incbin block in v9,
    # search for them in v7. The position in v7 minus the block size gives
    # the v7 block start.

    ANCHOR_SIZE = 32  # bytes of code to use as anchor

    extracted = 0
    failed = 0
    unchanged = 0
    changed_size = 0

    for idx, block in enumerate(results):
        v9_end_offset = block['v9_offset'] + block['v9_size']

        # Get code anchor: bytes immediately after this block in v9
        anchor_after = v9_rom[v9_end_offset:v9_end_offset + ANCHOR_SIZE]

        if len(anchor_after) < ANCHOR_SIZE:
            print(f"  {block['label']}: Not enough bytes for anchor at end of ROM")
            failed += 1
            continue

        # Also get code anchor BEFORE the block (for cross-validation)
        anchor_before_start = max(0, block['v9_offset'] - ANCHOR_SIZE)
        anchor_before = v9_rom[anchor_before_start:block['v9_offset']]

        # Find the after-anchor in v7
        v7_after_positions = find_bytes_in_rom(v7_rom, anchor_after)

        if len(v7_after_positions) == 0:
            # Try shorter anchor
            anchor_after = v9_rom[v9_end_offset:v9_end_offset + 16]
            v7_after_positions = find_bytes_in_rom(v7_rom, anchor_after)
            if len(v7_after_positions) == 0:
                print(f"  {block['label']}: After-anchor not found in v7")
                failed += 1
                continue

        if len(v7_after_positions) > 1:
            # Multiple matches - try to disambiguate using before-anchor
            # Pick the one closest to expected position
            expected_v7_pos = v9_end_offset  # rough approximation
            v7_after_positions.sort(key=lambda p: abs(p - expected_v7_pos))

        v7_after_pos = v7_after_positions[0]

        # Find the before-anchor in v7
        v7_before_positions = find_bytes_in_rom(v7_rom, anchor_before)

        if len(v7_before_positions) == 0:
            # Try shorter
            anchor_before = v9_rom[block['v9_offset'] - 16:block['v9_offset']]
            v7_before_positions = find_bytes_in_rom(v7_rom, anchor_before)

        if len(v7_before_positions) == 0:
            # Can't find before-anchor. Use after-anchor only.
            # Assume same size as v9
            v7_block_start = v7_after_pos - block['v9_size']
            v7_block_size = block['v9_size']
            confidence = "low"
        else:
            # Use closest before-anchor to the after-anchor
            best_before = min(v7_before_positions,
                            key=lambda p: abs((p + len(anchor_before)) - (v7_after_pos - block['v9_size'])))
            v7_block_start = best_before + len(anchor_before)
            v7_block_size = v7_after_pos - v7_block_start
            confidence = "high"

        if v7_block_start < 0 or v7_block_start + v7_block_size > len(v7_rom):
            print(f"  {block['label']}: Invalid v7 range [{v7_block_start:#x}:{v7_block_start+v7_block_size:#x}]")
            failed += 1
            continue

        # Extract v7 data
        v7_data = v7_rom[v7_block_start:v7_block_start + v7_block_size]
        v9_data = v9_rom[block['v9_offset']:block['v9_offset'] + block['v9_size']]

        size_diff = v7_block_size - block['v9_size']

        if v7_data == v9_data:
            unchanged += 1
            continue

        if size_diff != 0:
            print(f"  {block['label']}: SIZE CHANGED v9={block['v9_size']} v7={v7_block_size} diff={size_diff} ({confidence})")
            changed_size += 1
        else:
            pass  # Same size, different content - normal pointer diffs

        # Write extracted v7 data
        with open(block['bin_path'], 'wb') as f:
            f.write(v7_data)
        extracted += 1

        block['v7_offset'] = v7_block_start
        block['v7_size'] = v7_block_size
        block['size_diff'] = size_diff

    print(f"\n--- Summary ---")
    print(f"Total .incbin blocks: {len(results)}")
    print(f"Extracted (changed): {extracted}")
    print(f"Unchanged: {unchanged}")
    print(f"Size changed: {changed_size}")
    print(f"Failed: {failed}")

    # Show size-changed blocks
    size_changed = [b for b in results if b.get('size_diff', 0) != 0]
    if size_changed:
        print(f"\n--- Size-changed blocks ---")
        for b in size_changed:
            print(f"  {b['label']}: v9={b['v9_size']} v7={b['v7_size']} diff={b['size_diff']}")

if __name__ == '__main__':
    main()
