#!/usr/bin/env python3
"""Comprehensive pointer+string table formatting for KN5000 ROM disassembly.

Handles raw .byte pointers → .long LABEL_, missing labels on target strings,
raw .byte strings → aligned_string (only where safe), and conflicting .set removal.

Strategy:
- Phase 5: For each group, replace ONLY the pointer section with .long LABEL_ entries
  (never touches the string section, avoiding alignment/padding issues)
- Phase 6: Add missing labels to target strings via byte counting
- Phase 7: Convert raw .byte strings to aligned_string (only where byte count matches)
- Phase 8: Remove .set directives that conflict with newly added position labels

Usage:
    cd /mnt/shared/kn5000-roms-disasm
    python scripts/format_pointer_string_groups.py [--dry-run]
"""

import re
import struct
import sys
from collections import defaultdict

# --- Regex patterns ---
BYTE_RE = re.compile(r'0x([0-9a-fA-F]{2})')
LABEL_RE = re.compile(r'^(LABEL_[0-9A-F]{6}):')
FILL_RE = re.compile(r'(\s*)\.fill\s+(\d+)\s*,\s*1\s*,\s*0x([0-9a-fA-F]+)')
ZERO_RE = re.compile(r'\s*\.zero\s+(\d+)')
ALIGNED_STRING_RE = re.compile(r'aligned_string\s+"((?:[^"\\]|\\.)*)"')
QUOTED_STRING_RE = re.compile(r'"((?:[^"\\]|\\.)*)"')
SET_RE = re.compile(r'\s*\.set\s+(LABEL_[0-9A-F]{6}),\s*0x([0-9A-Fa-f]+)')

# --- Constants ---
ROM_BASE = 0xE00000
ROM_END = 0xFFFFFF
ASM_FILE = 'maincpu/kn5000_v10_program.s'
ROM_FILE = 'original_ROMs/kn5000_v10_program.rom'


# =============================================================================
# Utility functions
# =============================================================================

def parse_byte_values(line):
    return [int(m, 16) for m in BYTE_RE.findall(line)]


def format_bytes_line(byte_list, indent='\t'):
    hex_str = ', '.join(f'0x{b:02x}' for b in byte_list)
    return f'{indent}.byte {hex_str}\n'


def asm_string_byte_len(s):
    i = 0
    length = 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            nc = s[i + 1]
            if nc == 'x' and i + 3 < len(s):
                i += 4
            elif nc in '01234567':
                end = i + 2
                while end < len(s) and end < i + 4 and s[end] in '01234567':
                    end += 1
                i = end
            else:
                i += 2
            length += 1
        else:
            i += 1
            length += 1
    return length


def line_byte_count_with_addr(line, current_addr):
    stripped = line.strip()
    if LABEL_RE.match(stripped):
        rest = stripped.split(':', 1)[1].strip()
        if not rest:
            return 0
        stripped = rest
    if stripped.startswith('.byte '):
        return len(BYTE_RE.findall(line))
    m = FILL_RE.match(stripped)
    if m:
        return int(m.group(2))
    if stripped.startswith('.long '):
        return 4
    if stripped.startswith('.ascii '):
        m = QUOTED_STRING_RE.search(stripped)
        return asm_string_byte_len(m.group(1)) if m else 0
    if stripped.startswith('.asciz '):
        m = QUOTED_STRING_RE.search(stripped)
        return (asm_string_byte_len(m.group(1)) + 1) if m else 1
    m = ALIGNED_STRING_RE.search(stripped)
    if m:
        size = asm_string_byte_len(m.group(1)) + 1
        if (current_addr + size) % 2 != 0:
            size += 1
        return size
    m = ZERO_RE.match(stripped)
    if m:
        return int(m.group(1))
    if stripped.startswith('.short ') or stripped.startswith('.2byte '):
        return 2
    if stripped.startswith('.4byte '):
        return 4
    return 0


def build_label_index(lines):
    index = {}
    for i, line in enumerate(lines):
        m = LABEL_RE.match(line)
        if m:
            addr = int(m.group(1)[6:], 16)
            index[addr] = i
    return index


def get_string_at(rom, offset):
    if offset < 0 or offset >= len(rom):
        return None
    chars = []
    i = offset
    while i < len(rom) and rom[i] != 0:
        if rom[i] < 0x20 or rom[i] > 0x7E:
            return None
        chars.append(chr(rom[i]))
        i += 1
    if i >= len(rom):
        return None
    return ''.join(chars)


def string_rom_size(rom, offset):
    """Total bytes of string in ROM: content + null + optional 0xFF pad."""
    s = get_string_at(rom, offset)
    if s is None:
        return 0
    size = len(s) + 1
    if offset + size < len(rom) and rom[offset + size] == 0xFF:
        size += 1
    return size


def get_data_part(stripped):
    m = LABEL_RE.match(stripped)
    if m:
        return stripped.split(':', 1)[1].strip()
    return stripped


# =============================================================================
# ROM scanning
# =============================================================================

def scan_groups(rom):
    """Scan ROM for structurally valid pointer+string groups."""
    groups = []
    rom_len = len(rom)
    skip_until = 0
    i = 0
    while i < rom_len - 3:
        if i < skip_until:
            i += 1
            continue
        val = struct.unpack_from('<I', rom, i)[0]
        if not (ROM_BASE <= val <= ROM_END):
            i += 1
            continue
        if get_string_at(rom, val - ROM_BASE) is None:
            i += 1
            continue
        entries = [(ROM_BASE + i, val)]
        j = i + 4
        while j < rom_len - 3:
            v = struct.unpack_from('<I', rom, j)[0]
            if not (ROM_BASE <= v <= ROM_END):
                break
            if get_string_at(rom, v - ROM_BASE) is None:
                break
            entries.append((ROM_BASE + j, v))
            j += 4
        n = len(entries)
        ptr_end_addr = ROM_BASE + i + n * 4
        min_target = min(e[1] for e in entries)
        gap = min_target - ptr_end_addr
        if 0 <= gap <= 2:
            groups.append((ROM_BASE + i, n, entries))
        skip_until = j
        i = j
    return groups


# =============================================================================
# Core: convert pointer section only
# =============================================================================

def convert_pointers_for_group(lines, rom, group_addr, num_entries, entries,
                                label_index):
    """Convert raw .byte pointer entries to .long LABEL_ for one group.

    Only replaces the POINTER section (not strings). Returns:
        (start_line, end_line, new_lines) or None if no work needed.
    """
    group_line = label_index.get(group_addr)
    if group_line is None:
        return None

    ptr_end_addr = group_addr + num_entries * 4

    # Find start of data
    data_start = group_line
    stripped = lines[group_line].strip()
    if LABEL_RE.match(stripped) and not get_data_part(stripped):
        data_start = group_line + 1

    # Walk forward, consuming only the POINTER section bytes
    current_addr = group_addr
    j = data_start
    data_end = data_start
    has_raw_bytes = False

    while current_addr < ptr_end_addr and j < len(lines):
        stripped = lines[j].strip()
        if stripped == '' or stripped.startswith(';'):
            j += 1
            continue

        m_label = LABEL_RE.match(stripped)
        if m_label:
            label_addr = int(m_label.group(1)[6:], 16)
            if label_addr >= ptr_end_addr:
                break  # Past pointer section
            data = get_data_part(stripped)
            if not data:
                j += 1
                continue
        else:
            data = stripped

        if data.startswith('.long LABEL_'):
            current_addr += 4
            data_end = j + 1
            j += 1
            continue

        if data.startswith('.byte '):
            has_raw_bytes = True
            bc = len(parse_byte_values(lines[j]))
            current_addr += bc
            data_end = j + 1
            j += 1
            continue

        # Something else — stop
        break

    if not has_raw_bytes:
        return None  # All pointers already converted

    if data_end <= data_start:
        return None

    # Generate replacement: only .long entries + any trailing non-pointer bytes
    new_lines = []

    # Preserve group label only if it's being replaced
    if data_start == group_line:
        new_lines.append(f'LABEL_{group_addr:06X}:\n')

    # Emit pointer entries
    for ptr_addr, target_addr in entries:
        new_lines.append(f'\t.long LABEL_{target_addr:06X}\n')

    # Any bytes consumed beyond the pointer section?
    if current_addr > ptr_end_addr:
        # We consumed more bytes than just the pointers
        # Emit the excess as .byte
        excess_start = ptr_end_addr - ROM_BASE
        excess_end = current_addr - ROM_BASE
        excess_bytes = list(rom[excess_start:excess_end])
        if excess_bytes:
            new_lines.append(format_bytes_line(excess_bytes))

    return (data_start, data_end, new_lines)


# =============================================================================
# Label placement via byte counting
# =============================================================================

def find_line_for_addr(addr, lines, label_index):
    """Find line index for address using byte counting from nearest label."""
    preceding = [(a, l) for a, l in label_index.items() if a <= addr]
    if not preceding:
        return None
    prev_addr, prev_line = max(preceding, key=lambda x: x[0])
    byte_offset = addr - prev_addr
    if byte_offset == 0:
        return (prev_line, 0)

    cumulative = 0
    current_addr = prev_addr

    # Check if label line has inline data
    stripped = lines[prev_line].strip()
    m = LABEL_RE.match(stripped)
    if m:
        rest = stripped.split(':', 1)[1].strip()
        if rest:
            bc = line_byte_count_with_addr(lines[prev_line], current_addr)
            if bc > 0:
                if bc > byte_offset:
                    return (prev_line, byte_offset)
                if bc == byte_offset:
                    return (prev_line + 1, 0)
                cumulative = bc
                current_addr += bc

    j = prev_line + 1
    while j < len(lines) and j < prev_line + 500:
        stripped = lines[j].strip()
        if stripped == '' or stripped.startswith(';') or stripped.startswith('//'):
            j += 1
            continue
        if LABEL_RE.match(stripped):
            rest = stripped.split(':', 1)[1].strip()
            if not rest:
                j += 1
                continue
        bc = line_byte_count_with_addr(lines[j], current_addr)
        if bc == 0:
            break
        if cumulative + bc > byte_offset:
            return (j, byte_offset - cumulative)
        if cumulative + bc == byte_offset:
            return (j + 1, 0)
        cumulative += bc
        current_addr += bc
        j += 1
    return None


# =============================================================================
# Main pipeline
# =============================================================================

def process_file(asm_path, rom_path, dry_run=False):
    print(f"Reading assembly: {asm_path}")
    with open(asm_path, 'r') as f:
        lines = f.readlines()
    print(f"  {len(lines)} lines")

    print(f"Reading ROM: {rom_path}")
    with open(rom_path, 'rb') as f:
        rom = f.read()
    print(f"  {len(rom)} bytes")

    # Phase 1: Scan ROM
    print("\nPhase 1: Scanning ROM for pointer+string groups...")
    groups = scan_groups(rom)
    by_size = defaultdict(int)
    for _, n, _ in groups:
        by_size[n] += 1
    print(f"  Found {len(groups)} groups")
    for size in sorted(by_size.keys())[:10]:
        print(f"    {size}-entry: {by_size[size]}")

    # Phase 2: Build label index
    print("\nPhase 2: Building label index...")
    label_index = build_label_index(lines)
    print(f"  {len(label_index)} labels")

    # Phase 3: Pre-fix: fix broken backslash string escaping
    print("\nPhase 3: Fixing broken string escapes...")
    escape_fixes = 0
    for i in range(len(lines)):
        s = lines[i].strip()
        if s == 'aligned_string "\\"':
            lines[i] = '\taligned_string "\\\\"\n'
            escape_fixes += 1
    print(f"  Fixed {escape_fixes} broken escapes")

    # Phase 4: Generate pointer conversion changes
    print("\nPhase 4: Analyzing groups for pointer conversion...")
    changes = []
    skipped_no_label = 0
    skipped_unresolvable = 0

    for group_addr, num_entries, entries in groups:
        if group_addr not in label_index:
            skipped_no_label += 1
            continue

        # Pre-validate: ALL target addresses must be resolvable
        all_resolvable = True
        for ptr_addr, target_addr in entries:
            if target_addr in label_index:
                continue  # Already has a label
            # Check if we can place a label there via byte counting
            pos = find_line_for_addr(target_addr, lines, label_index)
            if pos is None:
                all_resolvable = False
                break
        if not all_resolvable:
            skipped_unresolvable += 1
            continue

        result = convert_pointers_for_group(lines, rom, group_addr, num_entries,
                                             entries, label_index)
        if result is not None:
            changes.append(result)

    print(f"  Pointer changes: {len(changes)}")
    print(f"  Skipped (no label in asm): {skipped_no_label}")
    print(f"  Skipped (unresolvable targets): {skipped_unresolvable}")

    # Sort descending, filter overlaps
    changes.sort(key=lambda x: x[0], reverse=True)
    filtered = []
    occupied = set()
    for s, e, nl in changes:
        conflict = any(line in occupied for line in range(s, max(e, s + 1)))
        if conflict:
            continue
        for line in range(s, max(e, s + 1)):
            occupied.add(line)
        filtered.append((s, e, nl))
    changes = filtered

    # Phase 5: Apply pointer changes
    if changes and not dry_run:
        print(f"\nPhase 5: Applying {len(changes)} pointer changes...")
        changes.sort(key=lambda x: x[0], reverse=True)
        for s, e, nl in changes:
            lines[s:e] = nl
    elif changes and dry_run:
        print(f"\nPhase 5: DRY RUN — {len(changes)} pointer changes")
        for s, e, nl in sorted(changes[:20], key=lambda x: x[0]):
            print(f"  Lines {s+1}-{e}:")
            for o in [lines[i].rstrip() for i in range(s, min(e, len(lines)))][:3]:
                print(f"    - {o}")
            for n in nl[:3]:
                print(f"    + {n.rstrip()}")

    # Phase 6: Add missing labels to target strings
    print(f"\nPhase 6: Adding missing labels to target strings...")
    label_index = build_label_index(lines)

    # Collect all target addresses that need labels
    needed_labels = set()
    for group_addr, num_entries, entries in groups:
        for ptr_addr, target_addr in entries:
            if target_addr not in label_index:
                needed_labels.add(target_addr)

    print(f"  Need labels: {len(needed_labels)}")

    label_additions = 0
    failed_labels = 0

    # Sort by address for deterministic processing
    for addr in sorted(needed_labels):
        if addr in label_index:
            continue

        label_name = f'LABEL_{addr:06X}'
        pos = find_line_for_addr(addr, lines, label_index)
        if pos is None:
            failed_labels += 1
            continue

        line_idx, offset = pos
        if offset == 0:
            stripped = lines[line_idx].strip()
            if stripped and not LABEL_RE.match(stripped):
                if dry_run:
                    label_additions += 1
                    continue
                # Add label prefix to data line
                lines[line_idx] = f'{label_name}:\t{stripped}\n'
                label_index[addr] = line_idx
                label_additions += 1
            elif not stripped:
                if dry_run:
                    label_additions += 1
                    continue
                lines.insert(line_idx, f'{label_name}:\n')
                label_index = build_label_index(lines)
                label_additions += 1
            else:
                # Already has a label — insert bare label before
                if dry_run:
                    label_additions += 1
                    continue
                lines.insert(line_idx, f'{label_name}:\n')
                label_index = build_label_index(lines)
                label_additions += 1
        elif offset > 0:
            data = get_data_part(lines[line_idx].strip())
            if data.startswith('.byte '):
                if dry_run:
                    label_additions += 1
                    continue
                bv = parse_byte_values(lines[line_idx])
                before = bv[:offset]
                after = bv[offset:]
                new_lines = []
                if before:
                    new_lines.append(format_bytes_line(before))
                new_lines.append(f'{label_name}:\n')
                if after:
                    new_lines.append(format_bytes_line(after))
                lines[line_idx:line_idx + 1] = new_lines
                label_index = build_label_index(lines)
                label_additions += 1
            elif FILL_RE.match(data):
                m = FILL_RE.match(data)
                count = int(m.group(2))
                val_str = m.group(3)
                if dry_run:
                    label_additions += 1
                    continue
                new_lines = []
                if offset > 0:
                    new_lines.append(f'\t.fill {offset}, 1, 0x{val_str}\n')
                new_lines.append(f'{label_name}:\n')
                remaining = count - offset
                if remaining > 0:
                    new_lines.append(f'\t.fill {remaining}, 1, 0x{val_str}\n')
                lines[line_idx:line_idx + 1] = new_lines
                label_index = build_label_index(lines)
                label_additions += 1
            else:
                failed_labels += 1

    print(f"  Added: {label_additions}")
    print(f"  Failed: {failed_labels}")

    # Phase 7: Convert raw .byte strings to aligned_string (safe conversions only)
    # aligned_string emits .asciz + .p2align 1, 0xff — so its byte count is:
    #   len(string) + 1 (null) + (1 if (addr + len + 1) is odd, else 0)
    # Only convert when the aligned_string output matches the original ROM bytes exactly.
    if not dry_run:
        print(f"\nPhase 7: Converting raw .byte strings to aligned_string...")
        label_index = build_label_index(lines)
        string_conversions = 0
        skipped_alignment = 0

        for group_addr, num_entries, entries in groups:
            for ptr_addr, target_addr in entries:
                tl = label_index.get(target_addr)
                if tl is None:
                    continue
                stripped = lines[tl].strip()
                data = get_data_part(stripped)
                if 'aligned_string' in data or data.startswith('.long ') or not data:
                    continue

                rom_str = get_string_at(rom, target_addr - ROM_BASE)
                if rom_str is None:
                    continue

                rom_off = target_addr - ROM_BASE
                total_size = string_rom_size(rom, rom_off)

                # Compute what aligned_string would emit
                str_len = len(rom_str) + 1  # string + null terminator
                aligned_size = str_len
                if (target_addr + str_len) % 2 != 0:
                    aligned_size += 1  # .p2align adds 0xFF pad
                if aligned_size != total_size:
                    skipped_alignment += 1
                    continue

                # Verify the padding byte is 0xFF (required by aligned_string)
                if aligned_size > str_len:
                    pad_off = rom_off + str_len
                    if pad_off < len(rom) and rom[pad_off] != 0xFF:
                        skipped_alignment += 1
                        continue

                if data.startswith('.byte '):
                    # Check if the .byte data matches the string exactly
                    bv = parse_byte_values(lines[tl])

                    # Collect enough bytes
                    collected = [tl]
                    byte_count = len(bv)
                    k = tl + 1
                    while byte_count < total_size and k < len(lines):
                        s = lines[k].strip()
                        if LABEL_RE.match(s):
                            break
                        if get_data_part(s).startswith('.byte '):
                            byte_count += len(parse_byte_values(lines[k]))
                            collected.append(k)
                            k += 1
                        else:
                            break

                    # Safety: only convert if byte count matches exactly
                    if byte_count != total_size:
                        continue

                    # Verify the bytes match the ROM
                    all_bytes = []
                    for cl in collected:
                        all_bytes.extend(parse_byte_values(lines[cl]))
                    rom_bytes = list(rom[rom_off:rom_off + total_size])
                    if all_bytes[:total_size] != rom_bytes:
                        continue

                    label_name = f'LABEL_{target_addr:06X}'
                    escaped = rom_str.replace('\\', '\\\\').replace('"', '\\"')
                    new_line = f'{label_name}:\taligned_string "{escaped}"\n'
                    lines[collected[0]:collected[-1] + 1] = [new_line]
                    label_index = build_label_index(lines)
                    string_conversions += 1

        print(f"  Converted: {string_conversions}")
        print(f"  Skipped (alignment mismatch): {skipped_alignment}")

    # Phase 8: Remove conflicting .set directives
    if not dry_run:
        print(f"\nPhase 8: Removing conflicting .set directives...")
        label_index = build_label_index(lines)
        position_labels = set()
        for line in lines:
            m = LABEL_RE.match(line)
            if m:
                position_labels.add(m.group(1))

        to_remove = []
        for i, line in enumerate(lines):
            m = SET_RE.match(line)
            if m and m.group(1) in position_labels:
                to_remove.append(i)

        for i in reversed(to_remove):
            del lines[i]

        print(f"  Removed: {len(to_remove)} .set directives")

    # Write output
    if not dry_run:
        with open(asm_path, 'w') as f:
            f.writelines(lines)
        total = len(changes) + label_additions + (string_conversions if 'string_conversions' in dir() else 0)
        print(f"\nDone! Pointer changes: {len(changes)}, labels: {label_additions}")
        print(f"\nNext steps:")
        print(f"  1. make clean && make all")
        print(f"  2. python scripts/compare_roms.py")
    else:
        print(f"\nDRY RUN complete.")


if __name__ == '__main__':
    dry_run = '--dry-run' in sys.argv
    process_file(ASM_FILE, ROM_FILE, dry_run=dry_run)
