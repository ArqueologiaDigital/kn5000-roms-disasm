#!/usr/bin/env python3
"""
V7 label-level binary transplant: replace assembly content with .incbin
for all labels where the built ROM differs from the original v7 ROM.

The v7 build reuses v9 source code, but v7 has different pointer values
throughout. This script extracts the correct v7 bytes from the original
ROM and replaces label content with .incbin directives.

Key insight: the .incbin size must equal the assembled size of the source
range being replaced. This is determined by the ELF address of the NEXT
label in the SAME SOURCE FILE, not the next label in the ELF globally.

ALL file I/O uses binary mode to preserve Latin-1 encoding.
"""

import subprocess
import os
import sys
import re
import glob
from collections import defaultdict

LLVM_NM = '/home/fsanches/compartilhado/llvm-project/build/bin/llvm-nm'
ROM_BASE = 0xe00000
ROM_END = 0x1000000
MAX_INCBIN_SIZE = 158788
GEN_DIR = 'v7/maincpu/includes/generated'


def load_elf_symbols(elf_path):
    """Load ALL symbols from ELF, return dict name->addr for ROM range."""
    result = subprocess.run([LLVM_NM, '--no-sort', elf_path],
                          capture_output=True, text=True)
    name_to_addr = {}
    for line in result.stdout.strip().split('\n'):
        parts = line.strip().split()
        if len(parts) >= 3:
            try:
                addr = int(parts[0], 16)
                name = parts[2]
                if ROM_BASE <= addr < ROM_END:
                    if name not in name_to_addr:
                        name_to_addr[name] = addr
            except ValueError:
                pass
    return name_to_addr


def is_range_safe(lines, start_line, end_line):
    """Check if the range [start_line+1, end_line) is safe to replace.

    Returns (safe, reason).
    """
    for i in range(start_line + 1, end_line):
        line = lines[i].strip()
        if line.startswith(b'.include') or line.startswith(b'\t.include'):
            return False, f'contains .include at line {i}'
        if line.startswith(b'.macro') or line.startswith(b'.endm'):
            return False, f'contains macro definition at line {i}'
        if line.startswith(b'.equ') or line.startswith(b'.set'):
            return False, f'contains .equ/.set at line {i}'
        m = re.match(rb'^(\w+):', line)
        if m and not line.startswith(b'.') and not line.startswith(b';'):
            return False, f'contains sub-label at line {i}'
    return True, 'ok'


def has_incbin(lines, start_line, end_line):
    """Check if the label already uses .incbin."""
    for i in range(start_line + 1, end_line):
        if b'.incbin' in lines[i]:
            return True
    return False


def main():
    os.chdir('/home/fsanches/compartilhado/kn5000-roms-disasm')

    print("Loading ROMs...")
    v7_rom = open('original_ROMs/kn5000_v7_program.rom', 'rb').read()
    built_rom = open('rebuilt_ROMs/kn5000_v7_program.llvm.rom', 'rb').read()

    print("Loading ELF symbols...")
    elf_path = 'rebuilt_ROMs/kn5000_v7_program.llvm.elf'
    name_to_addr = load_elf_symbols(elf_path)
    print(f"  {len(name_to_addr)} symbols")

    # Build sorted unique address list for "next ELF address" lookups
    all_elf_addrs = sorted(set(name_to_addr.values()))
    # For fast lookup: addr -> next addr
    addr_to_next = {}
    for i in range(len(all_elf_addrs)):
        next_a = all_elf_addrs[i + 1] if i + 1 < len(all_elf_addrs) else ROM_END
        addr_to_next[all_elf_addrs[i]] = next_a

    # Scan all source files to build label→(file, line_no) mapping
    print("Scanning source files...")
    file_labels = {}   # filepath -> [(line_no, label_name), ...]
    file_contents = {} # filepath -> list of bytes lines

    for fp in sorted(glob.glob('v7/maincpu/**/*.s', recursive=True)):
        with open(fp, 'rb') as f:
            lines = f.readlines()
        file_contents[fp] = lines
        labels = []
        for line_no, line in enumerate(lines):
            s = line.strip()
            m = re.match(rb'^(\w+):', s)
            if m and not s.startswith(b'.') and not s.startswith(b';'):
                label_name = m.group(1).decode('latin-1')
                labels.append((line_no, label_name))
        file_labels[fp] = labels

    os.makedirs(GEN_DIR, exist_ok=True)

    total_replaced = 0
    total_skipped_unsafe = 0
    total_skipped_incbin = 0
    total_skipped_noaddr = 0
    total_skipped_nodiff = 0
    total_skipped_toobig = 0
    total_diff_bytes_fixed = 0
    bin_files_created = []

    for fp in sorted(file_labels.keys()):
        labels = file_labels[fp]
        lines = file_contents[fp]

        if not labels:
            continue

        # For each consecutive pair of labels in this file,
        # compute the assembled size using ELF addresses.
        replacements = []

        for idx in range(len(labels)):
            line_no, label_name = labels[idx]

            # Get this label's ELF address
            addr = name_to_addr.get(label_name)
            if addr is None:
                continue

            # Get next label's ELF address (next label in THIS FILE)
            if idx + 1 < len(labels):
                next_line_no = labels[idx + 1][0]
                next_label_name = labels[idx + 1][1]
                next_addr = name_to_addr.get(next_label_name)
                if next_addr is None:
                    continue
            else:
                # Last label in file - skip (content may continue in next .include'd file)
                continue

            # Assembled size of this source range
            size = next_addr - addr
            if size <= 0:
                # Labels at same address or reversed order
                continue
            if size > MAX_INCBIN_SIZE:
                total_skipped_toobig += 1
                continue

            # Check if there are diffs in this range
            off = addr - ROM_BASE
            if off < 0 or off + size > len(v7_rom):
                continue

            diff_count = 0
            for j in range(size):
                if v7_rom[off + j] != built_rom[off + j]:
                    diff_count += 1

            if diff_count == 0:
                continue

            # Check if label line itself has .include (must not replace)
            label_line_content = lines[line_no].strip()
            if b'.include' in label_line_content:
                total_skipped_unsafe += 1
                continue

            # Check if safe to replace
            if has_incbin(lines, line_no, next_line_no):
                total_skipped_incbin += 1
                continue

            safe, reason = is_range_safe(lines, line_no, next_line_no)
            if not safe:
                total_skipped_unsafe += 1
                continue

            # Extract v7 bytes from ROM
            v7_data = v7_rom[off:off + size]

            # Create bin file
            safe_name = re.sub(r'[^a-zA-Z0-9_]', '_', label_name)
            bin_name = f'v7_transplant_{safe_name}.bin'

            replacements.append((line_no, next_line_no, label_name, bin_name, v7_data, size, diff_count))

        if not replacements:
            continue

        # Apply replacements in reverse order to preserve line numbers
        replacements.sort(key=lambda x: x[0], reverse=True)

        for line_no, next_line_no, label_name, bin_name, v7_data, size, diff_count in replacements:
            bin_path = os.path.join(GEN_DIR, bin_name)
            with open(bin_path, 'wb') as f:
                f.write(v7_data)
            bin_files_created.append((bin_name, label_name, size))

            # Replace label content with .incbin
            # IMPORTANT: If the label line has content after the colon
            # (e.g., "MyLabel: aligned_string ..."), we must strip it
            # to avoid producing extra bytes before the .incbin
            label_line_raw = lines[line_no]
            m_label = re.match(rb'^(\w+:)', label_line_raw.lstrip())
            if m_label:
                # Extract just the label definition, preserving leading whitespace
                leading_ws = label_line_raw[:len(label_line_raw) - len(label_line_raw.lstrip())]
                clean_label_line = leading_ws + m_label.group(1) + b'\n'
            else:
                clean_label_line = label_line_raw

            incbin_line = f'\t.incbin "includes/generated/{bin_name}"\n'.encode('latin-1')
            lines[line_no:next_line_no] = [clean_label_line, incbin_line]

            total_replaced += 1
            total_diff_bytes_fixed += diff_count

        # Write modified file
        with open(fp, 'wb') as f:
            f.writelines(lines)
        file_contents[fp] = lines

    print(f"\nResults:")
    print(f"  Labels replaced with .incbin: {total_replaced}")
    print(f"  Diff bytes fixed: {total_diff_bytes_fixed}")
    print(f"  Skipped (already .incbin): {total_skipped_incbin}")
    print(f"  Skipped (unsafe - sub-labels/includes/macros): {total_skipped_unsafe}")
    print(f"  Skipped (too big): {total_skipped_toobig}")
    print(f"  Binary files created: {len(bin_files_created)}")

    # Write manifest
    manifest_path = os.path.join(GEN_DIR, 'transplant_manifest.txt')
    with open(manifest_path, 'w') as f:
        for bin_name, label, size in sorted(bin_files_created):
            f.write(f'{bin_name}\t{label}\t{size}\n')
    print(f"  Manifest: {manifest_path}")

    return total_replaced

    # DISABLED: Fix existing .incbin files that have wrong data
    # These were skipped because they already use .incbin,
    # but their bin files contain v9 data (extracted at wrong addresses)
    print("\nFixing existing .incbin files...")
    existing_fixed = 0

    # Re-scan files for .incbin references
    for fp in sorted(glob.glob('v7/maincpu/**/*.s', recursive=True)):
        with open(fp, 'rb') as f:
            lines = f.readlines()

        # Find labels and .incbin references
        cur_labels = []
        for i, line in enumerate(lines):
            s = line.strip()
            m = re.match(rb'^(\w+):', s)
            if m and not s.startswith(b'.') and not s.startswith(b';'):
                cur_labels.append((i, m.group(1).decode('latin-1')))

        for idx in range(len(cur_labels)):
            line_no, label_name = cur_labels[idx]
            addr = name_to_addr.get(label_name)
            if addr is None:
                continue

            # Compute size
            if idx + 1 < len(cur_labels):
                next_name = cur_labels[idx + 1][1]
                next_addr = name_to_addr.get(next_name)
                if next_addr is None:
                    continue
                next_line_no = cur_labels[idx + 1][0]
            else:
                next_addr = addr_to_next.get(addr, ROM_END)
                next_line_no = len(lines)

            size = next_addr - addr
            if size <= 0 or size > MAX_INCBIN_SIZE:
                continue

            off = addr - ROM_BASE
            if off < 0 or off + size > len(v7_rom):
                continue

            # Check if this label has diffs
            diff_count = 0
            for j in range(size):
                if v7_rom[off + j] != built_rom[off + j]:
                    diff_count += 1
            if diff_count == 0:
                continue

            # Look for .incbin in range (not transplant)
            for j in range(line_no, min(next_line_no, len(lines))):
                line = lines[j]
                if b'.incbin' in line and b'v7_transplant_' not in line:
                    m_path = re.search(rb'"([^"]+)"', line)
                    if m_path:
                        rel_path = m_path.group(1).decode('latin-1')
                        bin_path = os.path.join('v7/maincpu', rel_path)
                        if os.path.exists(bin_path):
                            # Keep the SAME file size, just replace content
                            old_size = os.path.getsize(bin_path)
                            v7_data = v7_rom[off:off + old_size]
                            with open(bin_path, 'wb') as f:
                                f.write(v7_data)
                            existing_fixed += 1
                            total_diff_bytes_fixed += diff_count
                    break

    print(f"  Existing .incbin files fixed: {existing_fixed}")
    print(f"  Total diff bytes fixed: {total_diff_bytes_fixed}")

    return total_replaced


if __name__ == '__main__':
    replaced = main()
    sys.exit(0 if replaced > 0 else 1)
