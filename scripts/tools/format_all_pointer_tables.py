#!/usr/bin/env python3
"""Add missing labels and group separators to all pointer+string tables.

This script:
1. Finds all runs of `.long LABEL_` lines (pointer tables)
2. For unlabeled standalone tables (4+ entries), computes the ROM address
   and inserts LABEL_XXXXXX: before the first .long
3. Converts raw `.byte` 4-byte pointers adjacent to .long runs into .long LABEL_
4. Adds double blank line separators between pointer+string groups
5. Removes .set directives for labels that now have position labels

Uses nearby LABEL_XXXXXX: anchors and data byte counting for address computation.

Usage:
    cd /mnt/shared/kn5000-roms-disasm
    python scripts/format_all_pointer_tables.py [--dry-run]
"""

import re
import sys
from collections import defaultdict

ASM_FILE = 'maincpu/kn5000_v10_program.s'
ROM_FILE = '/mnt/shared/kn5000_original_roms/kn5000/kn5000_v10_program.rom'
ROM_BASE = 0xE00000

LABEL_RE = re.compile(r'^(LABEL_[0-9A-F]{6}):(.*)$')
ANY_LABEL_RE = re.compile(r'^([A-Za-z_]\w*):(.*)$')
BYTE_RE = re.compile(r'0x([0-9a-fA-F]{2})')
ALIGNED_STRING_RE = re.compile(r'aligned_string\s+"((?:[^"\\]|\\.)*)"')
QUOTED_STRING_RE = re.compile(r'"((?:[^"\\]|\\.)*)"')
SET_RE = re.compile(r'\s*\.set\s+(LABEL_[0-9A-F]{6}),\s*0x([0-9A-Fa-f]+)')
LONG_LABEL_RE = re.compile(r'^\t\.long\s+LABEL_[0-9A-F]{6}\s*$')
BYTE_4_RE = re.compile(r'^\t\.byte\s+0x([0-9a-fA-F]{2}),\s*0x([0-9a-fA-F]{2}),\s*0x([0-9a-fA-F]{2}),\s*0x([0-9a-fA-F]{2})\s*$')


def asm_string_byte_len(s):
    """Calculate byte length of an assembly string with escape sequences."""
    i = 0
    length = 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            next_char = s[i + 1]
            if next_char == 'x' and i + 3 < len(s):
                i += 4
            elif next_char in '01234567':
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


def line_byte_count(stripped, current_addr):
    """Count bytes a data directive emits. Returns None for instructions/unknown."""
    # Handle label+data on same line
    lm = LABEL_RE.match(stripped)
    if lm:
        stripped = lm.group(2).strip()
    alm = ANY_LABEL_RE.match(stripped)
    if alm:
        stripped = alm.group(2).strip()
    if not stripped:
        return 0

    if stripped.startswith('.byte '):
        return len(BYTE_RE.findall(stripped))
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
    if stripped.startswith('.long ') or stripped.startswith('.4byte '):
        return 4
    if stripped.startswith('.short ') or stripped.startswith('.2byte '):
        return 2
    m = re.match(r'\.zero\s+(\d+)', stripped)
    if m:
        return int(m.group(1))
    m = re.match(r'\.fill\s+(\d+)', stripped)
    if m:
        return int(m.group(1))
    return None


def find_address_for_line(lines, target_line, label_index):
    """Find the ROM address corresponding to a line in the assembly.

    Walks backward to find the nearest LABEL_XXXXXX anchor, then counts
    data bytes forward to the target line. Returns None if any instruction
    (unknown byte count) is encountered between anchor and target.
    """
    # Look backward for a LABEL_XXXXXX
    for back in range(0, min(200, target_line)):
        idx = target_line - back
        if idx < 0:
            break
        stripped = lines[idx].strip()
        lm = LABEL_RE.match(stripped)
        if lm:
            try:
                label_addr = int(lm.group(1)[6:], 16)
            except ValueError:
                continue

            # Count bytes from this label to target_line
            current_addr = label_addr
            # Check if label line itself has data
            label_data = lm.group(2).strip()
            if label_data:
                bc = line_byte_count(label_data, current_addr)
                if bc is None:
                    continue  # Can't count through instructions
                current_addr += bc

            for fwd in range(idx + 1, target_line):
                s = lines[fwd].strip()
                if not s or s.startswith(';') or s.startswith('//'):
                    continue
                bc = line_byte_count(s, current_addr)
                if bc is None:
                    current_addr = None
                    break
                current_addr += bc

            if current_addr is not None:
                return current_addr

    return None


def process_file(filepath, rom_path, dry_run=False):
    with open(rom_path, 'rb') as f:
        rom = f.read()

    with open(filepath, 'r', encoding='latin-1') as f:
        lines = f.readlines()

    print(f"Loaded {len(lines)} lines, ROM {len(rom)} bytes")

    # Build label index
    label_index = {}  # addr -> line
    for i, line in enumerate(lines):
        m = LABEL_RE.match(line.strip())
        if m:
            try:
                addr = int(m.group(1)[6:], 16)
                label_index[addr] = i
            except ValueError:
                pass

    # Build set of known label addresses (position + .set)
    known_labels = set(label_index.keys())
    set_labels = {}  # addr -> line
    for i, line in enumerate(lines):
        m = SET_RE.match(line)
        if m:
            try:
                addr = int(m.group(2), 16)
                known_labels.add(addr)
                set_labels[addr] = i
            except ValueError:
                pass

    print(f"Position labels: {len(label_index)}, .set labels: {len(set_labels)}")

    # --- Phase 1: Find all .long LABEL_ runs ---
    runs = []  # (start_line, end_line, entry_count)
    i = 0
    while i < len(lines):
        if LONG_LABEL_RE.match(lines[i]):
            start = i
            while i < len(lines) and LONG_LABEL_RE.match(lines[i]):
                i += 1
            runs.append((start, i, i - start))
        else:
            i += 1

    print(f"Found {len(runs)} .long LABEL_ runs ({sum(r[2] for r in runs)} entries)")

    # --- Phase 2: Classify runs as labeled/unlabeled ---
    unlabeled_runs = []
    for start, end, count in runs:
        # Check if there's a label on/before the first .long line
        has_label = False
        # Check the .long line itself for a label prefix (shouldn't happen, but check)
        if ANY_LABEL_RE.match(lines[start].strip()):
            has_label = True
        # Check preceding non-blank line
        if not has_label:
            for back in range(1, 4):
                if start - back < 0:
                    break
                prev = lines[start - back].strip()
                if not prev:
                    continue
                if LABEL_RE.match(prev) and not LABEL_RE.match(prev).group(2).strip():
                    has_label = True  # Bare label on preceding line
                break  # Only check the nearest non-blank line

        if not has_label and count >= 4:
            unlabeled_runs.append((start, end, count))

    print(f"Unlabeled runs with 4+ entries: {len(unlabeled_runs)}")

    # --- Phase 3: Compute addresses for unlabeled runs ---
    changes = []  # (line, type, data)
    set_lines_to_remove = set()
    labels_added = 0
    labels_failed = 0

    for start, end, count in unlabeled_runs:
        addr = find_address_for_line(lines, start, label_index)
        if addr is None:
            labels_failed += 1
            continue

        # Verify: ROM at this address should contain LE pointers to known labels
        rom_off = addr - ROM_BASE
        if rom_off < 0 or rom_off + 4 > len(rom):
            labels_failed += 1
            continue

        # Read first pointer from ROM and verify it matches the .long target
        first_long = lines[start].strip()
        m = re.match(r'\.long\s+LABEL_([0-9A-F]{6})', first_long)
        if m:
            expected_ptr = int(m.group(1), 16)
            rom_ptr = rom[rom_off] | (rom[rom_off+1] << 8) | (rom[rom_off+2] << 16) | (rom[rom_off+3] << 24)
            if rom_ptr != expected_ptr:
                labels_failed += 1
                continue

        label_name = f'LABEL_{addr:06X}'

        # Check if this label already exists as a position label
        if addr in label_index:
            continue  # Already has a position label elsewhere

        # Check if we need to remove a .set directive
        if addr in set_labels:
            set_lines_to_remove.add(set_labels[addr])

        # Insert label before the first .long line
        changes.append((start, 'insert_label', label_name))
        labels_added += 1

    print(f"Labels to add: {labels_added}, failed: {labels_failed}")

    # --- Phase 4: Convert raw .byte pointers adjacent to .long runs ---
    byte_ptr_converted = 0
    for start, end, count in runs:
        # Check line before start for raw .byte pointer
        if start > 0:
            prev_line = lines[start - 1]
            m = BYTE_4_RE.match(prev_line)
            if m:
                byte_vals = [int(m.group(j), 16) for j in range(1, 5)]
                ptr = byte_vals[0] | (byte_vals[1] << 8) | (byte_vals[2] << 16) | (byte_vals[3] << 24)
                if ptr in known_labels:
                    label_name = f'LABEL_{ptr:06X}'
                    changes.append((start - 1, 'replace_byte_ptr', label_name))
                    byte_ptr_converted += 1

        # Check line after end for raw .byte pointer
        if end < len(lines):
            next_line = lines[end]
            m = BYTE_4_RE.match(next_line)
            if m:
                byte_vals = [int(m.group(j), 16) for j in range(1, 5)]
                ptr = byte_vals[0] | (byte_vals[1] << 8) | (byte_vals[2] << 16) | (byte_vals[3] << 24)
                if ptr in known_labels:
                    label_name = f'LABEL_{ptr:06X}'
                    changes.append((end, 'replace_byte_ptr', label_name))
                    byte_ptr_converted += 1

    # Also check for .byte 0xff, ptr patterns (pad + pointer)
    # The pattern: .byte 0xff, 0xNN, 0xNN, 0xNN, 0x00
    BYTE_5_RE = re.compile(
        r'^\t\.byte\s+0xff,\s*0x([0-9a-fA-F]{2}),\s*0x([0-9a-fA-F]{2}),\s*0x([0-9a-fA-F]{2}),\s*0x00\s*$')
    for start, end, count in runs:
        if start > 0:
            m = BYTE_5_RE.match(lines[start - 1])
            if m:
                # This is: aligned_string padding (0xFF) + pointer (3 bytes + 0x00)
                # Actually 0xFF, lo, mid, hi, 0x00 → LE ptr = 0x00HHMM LL
                byte_vals = [int(m.group(j), 16) for j in range(1, 4)]
                ptr = byte_vals[0] | (byte_vals[1] << 8) | (byte_vals[2] << 16)
                # This doesn't quite work — the 0xff is padding for the preceding aligned_string
                # and the remaining 4 bytes are the pointer. Skip this complex case.
                pass

    print(f"Raw .byte pointers to convert: {byte_ptr_converted}")

    # --- Phase 5: Add group separators ---
    # A pointer+string group is: [label:] .long... strings...
    # Between consecutive groups, add double blank lines
    # A group ends when the strings end, and the next group's .long lines begin
    separator_inserts = []
    for idx in range(len(runs) - 1):
        _, end1, count1 = runs[idx]
        start2, _, count2 = runs[idx + 1]

        if count1 < 4 or count2 < 4:
            continue  # Only separate substantial groups

        # Check if there are already 2+ blank lines between end1 and start2
        blank_count = 0
        has_data_between = False
        for k in range(end1, start2):
            if not lines[k].strip():
                blank_count += 1
            elif lines[k].strip():
                has_data_between = True
                blank_count = 0  # Reset — blanks must be consecutive before start2

        # Check consecutive blank lines immediately before start2
        pre_blanks = 0
        for k in range(start2 - 1, end1 - 1, -1):
            if not lines[k].strip():
                pre_blanks += 1
            else:
                break

        if pre_blanks < 2 and has_data_between:
            # Need separator between groups. Insert before start2's label or .long.
            # Find the actual start (might have a label line inserted above)
            insert_at = start2
            # Check if there's a bare label on the line before
            if start2 > 0 and LABEL_RE.match(lines[start2-1].strip()):
                s = lines[start2-1].strip()
                lm = LABEL_RE.match(s)
                if lm and not lm.group(2).strip():
                    insert_at = start2 - 1

            needed = 2 - pre_blanks
            if needed > 0:
                separator_inserts.append((insert_at, needed))

    print(f"Group separators to add: {len(separator_inserts)}")

    # --- Phase 6: Remove .set directives ---
    for set_line in set_lines_to_remove:
        changes.append((set_line, 'remove_set', None))

    print(f".set lines to remove: {len(set_lines_to_remove)}")

    # --- Phase 7: Apply changes ---
    # Convert all changes to (line, start, end, new_lines) format
    edits = []

    for line, change_type, data in changes:
        if change_type == 'insert_label':
            edits.append((line, line, [f'{data}:\n']))
        elif change_type == 'replace_byte_ptr':
            edits.append((line, line + 1, [f'\t.long {data}\n']))
        elif change_type == 'remove_set':
            edits.append((line, line + 1, []))

    for insert_at, count in separator_inserts:
        edits.append((insert_at, insert_at, ['\n'] * count))

    # Sort by line in reverse order, check for overlaps
    edits.sort(key=lambda x: (x[0], -x[1]), reverse=True)

    # Deduplicate: if two edits target the same line, keep only the first
    seen_lines = set()
    deduped = []
    for start, end, new_lines in edits:
        if start not in seen_lines:
            seen_lines.add(start)
            deduped.append((start, end, new_lines))
    edits = deduped

    total_changes = len(edits)
    print(f"\nTotal changes to apply: {total_changes}")

    if dry_run:
        # Show first 30 changes
        shown = 0
        for start, end, new_lines in reversed(edits):
            if shown >= 30:
                print(f"... and {total_changes - shown} more changes")
                break
            if end > start:
                print(f"\nLines {start+1}-{end}: replace with {len(new_lines)} lines")
                for k in range(start, min(end, start+3)):
                    print(f"  OLD: {lines[k].rstrip()[:80]}")
                for nl in new_lines[:3]:
                    print(f"  NEW: {nl.rstrip()[:80]}")
            else:
                print(f"\nBefore line {start+1}: insert {len(new_lines)} lines")
                for nl in new_lines[:3]:
                    print(f"  NEW: {nl.rstrip()[:80]}")
            shown += 1
        print(f"\n[DRY RUN] No changes written.")
        return

    for start, end, new_lines in edits:
        lines[start:end] = new_lines

    with open(filepath, 'w', encoding='latin-1') as f:
        f.writelines(lines)

    print(f"Applied {total_changes} changes")
    print(f"  Labels added: {labels_added}")
    print(f"  .byte→.long: {byte_ptr_converted}")
    print(f"  Separators: {len(separator_inserts)}")
    print(f"  .set removed: {len(set_lines_to_remove)}")


if __name__ == '__main__':
    dry_run = '--dry-run' in sys.argv
    process_file(ASM_FILE, ROM_FILE, dry_run)
