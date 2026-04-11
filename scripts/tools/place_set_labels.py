#!/usr/bin/env python3
"""Place .set-only labels at their actual positions in the assembly file.

This script:
1. Finds all .set LABEL_XXXXXX definitions that lack position labels (LABEL_XXX:)
2. Uses position-aware byte counting from the nearest preceding position label
   to find where each .set label should be placed
3. Inserts LABEL_XXXXXX: at the correct position
4. Removes the .set directive
5. Also converts LABEL_XXX: .byte 0x00, 0xff → LABEL_XXX: aligned_string ""

Multiple labels targeting the same line are handled together in a single
combined split operation to avoid overlapping changes.

Usage:
    cd /home/fsanches/compartilhado/kn5000-roms-disasm
    python scripts/place_set_labels.py [--dry-run]
"""

import re
import sys
from collections import defaultdict

# --- Regex patterns ---
BYTE_RE = re.compile(r'0x([0-9a-fA-F]{2})')
LABEL_RE = re.compile(r'^(LABEL_[0-9A-F]{6}):')
FILL_RE = re.compile(r'(\s*)\.fill\s+(\d+)\s*,\s*1\s*,\s*0x([0-9a-fA-F]+)')
ZERO_RE = re.compile(r'\s*\.zero\s+(\d+)')
ALIGNED_STRING_RE = re.compile(r'aligned_string\s+"((?:[^"\\]|\\.)*)"')
SET_RE = re.compile(r'\s*\.set\s+(LABEL_[0-9A-F]{6}),\s*0x([0-9A-Fa-f]+)')
# Regex for quoted strings that handles escape sequences like \"
QUOTED_STRING_RE = re.compile(r'"((?:[^"\\]|\\.)*)"')

ASM_FILE = 'maincpu/kn5000_v10_program.s'


def parse_byte_values(line):
    return [int(m, 16) for m in BYTE_RE.findall(line)]


def asm_string_byte_len(s):
    """Calculate the actual byte length of an assembly string with escape sequences."""
    i = 0
    length = 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            next_char = s[i + 1]
            if next_char == 'x' and i + 3 < len(s):
                # \xNN — 1 byte
                i += 4
            elif next_char in '01234567':
                # Octal escape — 1 byte (consume up to 3 octal digits)
                end = i + 2
                while end < len(s) and end < i + 4 and s[end] in '01234567':
                    end += 1
                i = end
            else:
                # \", \\, \n, \t, etc. — 1 byte
                i += 2
            length += 1
        else:
            i += 1
            length += 1
    return length


def line_byte_count_with_addr(line, current_addr):
    """Count bytes a line emits, with position-aware alignment for aligned_string."""
    stripped = line.strip()

    # Handle label+data on same line (e.g., "LABEL_XXX: aligned_string ...")
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
        size = asm_string_byte_len(m.group(1)) + 1  # string + null
        if (current_addr + size) % 2 != 0:
            size += 1  # alignment padding
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
    """Build address -> line_index map for all position labels."""
    index = {}
    for i, line in enumerate(lines):
        m = LABEL_RE.match(line)
        if m:
            addr = int(m.group(1)[6:], 16)
            index[addr] = i
    return index


def find_insert_position(lines, label_line, byte_offset, label_addr):
    """Find line position for a label at byte_offset from label_addr.

    Returns (line_idx, offset_within_line) or None.
    """
    cumulative = 0
    current_addr = label_addr

    # Check if the label line itself has data (e.g., "LABEL_XXX: aligned_string ...")
    # If so, count those bytes before starting to walk subsequent lines.
    label_stripped = lines[label_line].strip()
    label_m = LABEL_RE.match(label_stripped)
    if label_m:
        rest = label_stripped.split(':', 1)[1].strip()
        if rest:
            bc = line_byte_count_with_addr(lines[label_line], current_addr)
            if bc > 0:
                if bc > byte_offset:
                    # Target is within the label line's data — can't split
                    return None
                if bc == byte_offset:
                    return (label_line + 1, 0)
                cumulative = bc
                current_addr += bc

    j = label_line + 1

    while j < len(lines):
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


def make_combined_split(lines, line_idx, labels_at_offsets):
    """Split a single line at multiple offsets, inserting labels.

    labels_at_offsets: sorted list of (offset_in_line, label_name).
    Returns (start_line, end_line, new_lines) or None.
    """
    # Handle all-at-zero case (pure insertions before the line)
    if all(off == 0 for off, _ in labels_at_offsets):
        new_lines = [f'{name}:\n' for _, name in labels_at_offsets]
        return (line_idx, line_idx, new_lines)

    stripped = lines[line_idx].strip()

    if stripped.startswith('.byte '):
        byte_vals = parse_byte_values(lines[line_idx])
        new_lines = []
        prev_offset = 0
        for offset, label_name in labels_at_offsets:
            if offset > prev_offset:
                chunk = byte_vals[prev_offset:offset]
                hex_str = ', '.join(f'0x{b:02x}' for b in chunk)
                new_lines.append(f'\t.byte {hex_str}\n')
            new_lines.append(f'{label_name}:\n')
            prev_offset = offset
        # Remaining bytes after last label
        if prev_offset < len(byte_vals):
            chunk = byte_vals[prev_offset:]
            hex_str = ', '.join(f'0x{b:02x}' for b in chunk)
            new_lines.append(f'\t.byte {hex_str}\n')
        return (line_idx, line_idx + 1, new_lines)

    m = FILL_RE.match(lines[line_idx])
    if m:
        indent = m.group(1)
        count = int(m.group(2))
        val_str = m.group(3)
        new_lines = []
        prev_offset = 0
        for offset, label_name in labels_at_offsets:
            chunk_size = offset - prev_offset
            if chunk_size > 0:
                new_lines.append(f'{indent}.fill {chunk_size}, 1, 0x{val_str}\n')
            new_lines.append(f'{label_name}:\n')
            prev_offset = offset
        remaining = count - prev_offset
        if remaining > 0:
            new_lines.append(f'{indent}.fill {remaining}, 1, 0x{val_str}\n')
        return (line_idx, line_idx + 1, new_lines)

    m = ZERO_RE.match(lines[line_idx])
    if m:
        count = int(m.group(1))
        new_lines = []
        prev_offset = 0
        for offset, label_name in labels_at_offsets:
            chunk_size = offset - prev_offset
            if chunk_size > 0:
                new_lines.append(f'\t.zero {chunk_size}\n')
            new_lines.append(f'{label_name}:\n')
            prev_offset = offset
        remaining = count - prev_offset
        if remaining > 0:
            new_lines.append(f'\t.zero {remaining}\n')
        return (line_idx, line_idx + 1, new_lines)

    # Can't split .long, aligned_string, etc.
    # But offset=0 insertions are OK (handled above)
    if len(labels_at_offsets) == 1 and labels_at_offsets[0][0] == 0:
        return (line_idx, line_idx, [f'{labels_at_offsets[0][1]}:\n'])

    return None


def process_file(filepath, dry_run=False):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    print(f"Loaded {len(lines)} lines")

    # --- Phase 0: Convert LABEL_XXX: .byte 0x00, 0xff → aligned_string "" ---
    empty_string_count = 0
    for i in range(1, len(lines)):
        if lines[i].strip() == '.byte 0x00, 0xff':
            prev = lines[i - 1].strip()
            if re.match(r'^LABEL_[0-9A-F]{6}:$', prev):
                lines[i] = '\taligned_string ""\n'
                empty_string_count += 1
    print(f"Phase 0: Converted {empty_string_count} LABEL: .byte 0x00, 0xff "
          f"→ aligned_string \"\"")

    # --- Phase 1: Collect .set labels and position labels ---
    print("Building label index...")
    label_index = build_label_index(lines)
    existing_labels = set(label_index.keys())

    set_labels = {}  # name -> (addr, line_idx)
    for i, line in enumerate(lines):
        m = SET_RE.match(line)
        if m:
            name = m.group(1)
            addr = int(m.group(2), 16)
            set_labels[name] = (addr, i)

    # Filter to .set-only labels (no position label exists)
    set_only = {name: info for name, info in set_labels.items()
                if info[0] not in existing_labels}

    print(f"Position labels: {len(label_index)}")
    print(f".set labels: {len(set_labels)}")
    print(f".set-only (need placement): {len(set_only)}")

    # --- Phase 2: Find insertion positions ---
    sorted_pos_labels = sorted(label_index.items())

    # Collect all placements: (line_idx, offset_in_line, label_name, set_line)
    placements = []
    failed = 0
    failed_names = []

    for name in sorted(set_only.keys(), key=lambda n: set_only[n][0]):
        addr, set_line = set_only[name]

        # Find nearest preceding position label
        preceding = None
        for pa, pl in sorted_pos_labels:
            if pa <= addr:
                preceding = (pa, pl)
            else:
                break

        if preceding is None:
            failed += 1
            failed_names.append(name)
            continue

        prev_addr, prev_line = preceding
        byte_offset = addr - prev_addr

        if byte_offset == 0:
            failed += 1
            continue

        pos = find_insert_position(lines, prev_line, byte_offset, prev_addr)
        if pos is None:
            failed += 1
            if len(failed_names) < 20:
                failed_names.append(f"{name} (0x{addr:06X}), offset {byte_offset} "
                                    f"from LABEL_{prev_addr:06X}")
            continue

        line_idx, offset_in_line = pos

        # Quick check: can we split at this line type?
        stripped = lines[line_idx].strip()
        if offset_in_line > 0:
            # Need to split - check if line type supports it
            if not (stripped.startswith('.byte ') or
                    FILL_RE.match(stripped) or
                    ZERO_RE.match(stripped)):
                failed += 1
                if len(failed_names) < 20:
                    failed_names.append(f"{name} split at line {line_idx}, "
                                        f"offset {offset_in_line}")
                continue

        placements.append((line_idx, offset_in_line, name, set_line))

    if failed_names:
        print(f"\nSample failures ({len(failed_names)}):")
        for fn in failed_names[:20]:
            print(f"  {fn}")

    print(f"\nPhase 2: {len(placements)} placements found, {failed} failed")

    # --- Phase 3: Group placements by target line ---
    line_groups = defaultdict(list)  # line_idx -> [(offset, name, set_line)]
    for line_idx, offset, name, set_line in placements:
        line_groups[line_idx].append((offset, name, set_line))

    # Sort each group by offset
    for line_idx in line_groups:
        line_groups[line_idx].sort(key=lambda x: x[0])

    # --- Phase 4: Generate changes ---
    changes = []  # (start_line, end_line, new_lines)
    set_lines_to_remove = set()
    placed = 0

    for line_idx in sorted(line_groups.keys()):
        group = line_groups[line_idx]
        labels_at_offsets = [(offset, name) for offset, name, _ in group]

        change = make_combined_split(lines, line_idx, labels_at_offsets)
        if change is None:
            failed += len(group)
            continue

        changes.append(change)
        placed += len(group)
        for _, _, set_line in group:
            set_lines_to_remove.add(set_line)

    # Add .set removal changes
    for set_line in set_lines_to_remove:
        changes.append((set_line, set_line + 1, []))

    print(f"Phase 4: {placed} labels to place, "
          f"{len(set_lines_to_remove)} .set lines to remove")

    # --- Phase 5: Sort and verify no overlaps ---
    changes.sort(key=lambda x: x[0], reverse=True)

    for i in range(len(changes) - 1):
        curr_start = changes[i][0]
        prev_end = changes[i + 1][1]
        if curr_start < prev_end:
            print(f"ERROR: Overlapping changes at lines "
                  f"{changes[i+1][0]}-{prev_end} and "
                  f"{curr_start}-{changes[i][1]}")
            sys.exit(1)

    if dry_run:
        print(f"\n[DRY RUN] Would apply {len(changes)} changes "
              f"({placed} placements + {len(set_lines_to_remove)} removals)")
        return

    # --- Phase 6: Apply changes ---
    for start, end, new_lines in changes:
        lines[start:end] = new_lines

    with open(filepath, 'w') as f:
        f.writelines(lines)

    print(f"\nDone! Placed {placed} labels, converted {empty_string_count} "
          f"empty strings, removed {len(set_lines_to_remove)} .set directives.")
    print(f"Failed to place: {failed}")


if __name__ == '__main__':
    dry_run = '--dry-run' in sys.argv
    process_file(ASM_FILE, dry_run)
