#!/usr/bin/env python3
"""
Extract correct .incbin data for v7 ROM build - Version 2.

Better approach: Use the v9 built ROM's contents to locate each .incbin block.
Since the v9 .bin files are what's currently being included, their bytes should
appear in the v9 rebuilt ROM at the expected addresses. We can then find those
block boundaries in both ROMs using code anchors (the bytes before and after
each block).

Strategy:
1. Build the v7 ELF to get current symbol map (tells us where each .incbin
   block ends up in the current v7 build)
2. Use v9 ELF symbols to map v9 addresses
3. For blocks WITH labels: use the label's address in v9 ELF
4. For blocks WITHOUT labels: find the block by looking at what the v9 built
   ROM contains at the block's position (from the v7 ELF we know the relative
   position, and from the v9 source we know the v9 .bin content)
5. Use code anchors (bytes after block) to find in v7 ROM
6. Extract and write v7 data
"""

import subprocess
import struct
import os
import sys
import re

ROM_BASE = 0xE00000
V9_ROM_PATH = 'original_ROMs/kn5000_v9_program.rom'
V7_ROM_PATH = 'original_ROMs/kn5000_v7_program.rom'
V9_ELF = 'rebuilt_ROMs/kn5000_v9_program.llvm.elf'
V7_ELF = 'rebuilt_ROMs/kn5000_v7_program.llvm.elf'
V9_REBUILT_ROM = 'rebuilt_ROMs/kn5000_v9_program.llvm.rom'
V7_GEN_DIR = 'v7/maincpu/includes/generated'
LLVM_NM = '/home/fsanches/compartilhado/llvm-project/build/bin/llvm-nm'

def load_rom(path):
    with open(path, 'rb') as f:
        return f.read()

def build_symbol_map(elf_path):
    """Build name -> address map from ELF."""
    result = subprocess.run([LLVM_NM, '--no-sort', elf_path],
                          capture_output=True, text=True)
    name_to_addr = {}
    for line in result.stdout.splitlines():
        parts = line.strip().split()
        if len(parts) >= 3:
            addr = int(parts[0], 16)
            sym_type = parts[1]
            name = parts[2]
            if sym_type in ('T', 't', 'D', 'd', 'B', 'b', 'R', 'r'):
                name_to_addr[name] = addr
    return name_to_addr

def find_incbin_blocks_with_context(source_dir):
    """Parse .s files to find .incbin directives, their labels, and enough
    context to locate them in the ROM."""
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

                # Find the label on same line or previous lines
                label = None
                lm = re.match(r'^(\w+):\s*\.incbin', line)
                if lm:
                    label = lm.group(1)
                else:
                    for j in range(i-1, max(i-10, -1), -1):
                        stripped = lines[j].strip()
                        if stripped == '' or stripped.startswith(';'):
                            continue
                        lm = re.match(r'^(\w+):', lines[j])
                        if lm:
                            label = lm.group(1)
                            break
                        # If we hit a non-label, non-empty, non-comment line, stop
                        break

                blocks.append({
                    'label': label,
                    'bin_file': bin_file,
                    'bin_path': os.path.join(V7_GEN_DIR, bin_file),
                    'source_file': fpath,
                    'source_line': i + 1,
                })
    return blocks

def find_all_in_rom(rom, pattern, start=0):
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
    v9_rom = load_rom(V9_ROM_PATH)
    v7_rom = load_rom(V7_ROM_PATH)

    # Also load the rebuilt v9 ROM to verify .bin placement
    if os.path.exists(V9_REBUILT_ROM):
        v9_rebuilt = load_rom(V9_REBUILT_ROM)
    else:
        v9_rebuilt = None

    print("Building symbol maps...")
    v9_syms = build_symbol_map(V9_ELF)
    v7_syms = build_symbol_map(V7_ELF)

    print("Finding .incbin blocks...")
    blocks = find_incbin_blocks_with_context('v7/maincpu')
    print(f"Found {len(blocks)} .incbin blocks")

    # Build sorted list of all v9 symbol addresses for finding block endpoints
    v9_addr_sorted = sorted(set(v9_syms.values()))

    def next_symbol_addr(addr, sorted_addrs):
        """Find the next symbol address after addr."""
        for a in sorted_addrs:
            if a > addr:
                return a
        return None

    ANCHOR_SIZE = 32

    extracted = 0
    failed = 0
    unchanged = 0
    size_changed_list = []

    for block in blocks:
        label = block['label']
        bin_path = block['bin_path']

        if not os.path.exists(bin_path):
            print(f"  SKIP: {block['bin_file']} doesn't exist")
            failed += 1
            continue

        v9_size = os.path.getsize(bin_path)

        # Determine v9 ROM offset for this block
        v9_offset = None

        if label and label in v9_syms:
            v9_addr = v9_syms[label]
            v9_offset = v9_addr - ROM_BASE
        else:
            # No label or label not in v9 symbols.
            # Use the current .bin file content to find it in the v9 original ROM.
            with open(bin_path, 'rb') as f:
                bin_data = f.read()

            if len(bin_data) >= 8:
                # Search for first 16 bytes in v9 ROM
                search_len = min(16, len(bin_data))
                positions = find_all_in_rom(v9_rom, bin_data[:search_len])
                if len(positions) == 1:
                    v9_offset = positions[0]
                elif len(positions) > 1:
                    # Try longer match
                    search_len = min(32, len(bin_data))
                    positions = find_all_in_rom(v9_rom, bin_data[:search_len])
                    if len(positions) == 1:
                        v9_offset = positions[0]
                    elif positions:
                        # Use the one closest to expected range
                        # Most blocks are in the 0x20000-0x1E0000 range
                        v9_offset = positions[0]

                if v9_offset is not None:
                    # Verify full match
                    if v9_rom[v9_offset:v9_offset + len(bin_data)] != bin_data:
                        # Partial match only - the .bin might have been compiled for v9
                        # but contain pointers that differ. Still use the offset.
                        pass

        if v9_offset is None:
            print(f"  FAIL: Cannot locate {block['bin_file']} (label={label}) in v9 ROM")
            failed += 1
            continue

        if v9_offset < 0 or v9_offset >= len(v9_rom):
            print(f"  FAIL: {block['bin_file']} v9_offset={v9_offset:#x} out of range")
            failed += 1
            continue

        # Now find code anchors after this block in v9
        v9_end_offset = v9_offset + v9_size
        anchor_after = v9_rom[v9_end_offset:v9_end_offset + ANCHOR_SIZE]

        if len(anchor_after) < ANCHOR_SIZE:
            print(f"  FAIL: {block['bin_file']} not enough bytes for after-anchor")
            failed += 1
            continue

        # Also get before-anchor
        before_len = min(ANCHOR_SIZE, v9_offset)
        anchor_before = v9_rom[v9_offset - before_len:v9_offset]

        # Find after-anchor in v7
        v7_after_positions = find_all_in_rom(v7_rom, anchor_after)

        if not v7_after_positions:
            # Try shorter anchor
            for try_len in [24, 16, 12, 8]:
                anchor_after_short = v9_rom[v9_end_offset:v9_end_offset + try_len]
                v7_after_positions = find_all_in_rom(v7_rom, anchor_after_short)
                if v7_after_positions:
                    break

        if not v7_after_positions:
            print(f"  FAIL: {block['bin_file']} after-anchor not found in v7 (v9 off={v9_offset:#x}, size={v9_size})")
            failed += 1
            continue

        # Find before-anchor in v7
        v7_before_positions = find_all_in_rom(v7_rom, anchor_before)

        if not v7_before_positions:
            for try_len in [24, 16, 12, 8]:
                anchor_before_short = v9_rom[v9_offset - try_len:v9_offset]
                v7_before_positions = find_all_in_rom(v7_rom, anchor_before_short)
                if v7_before_positions:
                    before_len = try_len
                    break

        if not v7_before_positions:
            # Use only after-anchor, assume same size
            v7_end = min(v7_after_positions, key=lambda p: abs(p - v9_end_offset))
            v7_start = v7_end - v9_size
            v7_size = v9_size
            confidence = "after-only"
        else:
            # Use the best pair of before/after anchors
            best_after = min(v7_after_positions, key=lambda p: abs(p - v9_end_offset))
            best_before = min(v7_before_positions, key=lambda p: abs((p + before_len) - (best_after - v9_size)))
            v7_start = best_before + before_len
            v7_end = best_after
            v7_size = v7_end - v7_start
            confidence = "both"

        if v7_start < 0 or v7_start + v7_size > len(v7_rom) or v7_size < 0:
            print(f"  FAIL: {block['bin_file']} invalid v7 range [{v7_start:#x}:{v7_start+v7_size:#x}]")
            failed += 1
            continue

        # Sanity check: size shouldn't differ by more than a factor of 4
        if v7_size > v9_size * 4 or (v9_size > 100 and v7_size < v9_size // 4):
            print(f"  FAIL: {block['bin_file']} suspicious size: v9={v9_size} v7={v7_size} (skipping)")
            failed += 1
            continue

        # Extract v7 data
        v7_data = v7_rom[v7_start:v7_start + v7_size]

        # Check if it's the same as current .bin
        with open(bin_path, 'rb') as f:
            current_data = f.read()

        if v7_data == current_data:
            unchanged += 1
            continue

        size_diff = v7_size - v9_size

        if size_diff != 0:
            print(f"  SIZE: {block['bin_file']}: v9={v9_size} v7={v7_size} diff={size_diff} ({confidence})")
            size_changed_list.append({
                'bin_file': block['bin_file'],
                'bin_path': bin_path,
                'v9_size': v9_size,
                'v7_size': v7_size,
                'v7_start': v7_start,
                'v7_data': v7_data,
                'label': label,
                'size_diff': size_diff,
            })
            # Still write the v7 data - we'll handle size changes separately
            with open(bin_path, 'wb') as f:
                f.write(v7_data)
            extracted += 1
        else:
            # Same size, different content - just swap
            with open(bin_path, 'wb') as f:
                f.write(v7_data)
            extracted += 1

    print(f"\n--- Summary ---")
    print(f"Total .incbin blocks: {len(blocks)}")
    print(f"Extracted (changed): {extracted}")
    print(f"Unchanged: {unchanged}")
    print(f"Size changed: {len(size_changed_list)}")
    print(f"Failed: {failed}")

    if size_changed_list:
        print(f"\n--- Size-changed blocks (need manual attention) ---")
        for b in size_changed_list:
            print(f"  {b['bin_file']}: v9={b['v9_size']} v7={b['v7_size']} diff={b['size_diff']}")

if __name__ == '__main__':
    main()
