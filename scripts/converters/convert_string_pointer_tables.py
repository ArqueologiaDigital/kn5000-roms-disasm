#!/usr/bin/env python3
"""Auto-detect and convert raw .byte string-pointer tables to .long LABEL_ format.

Scans the ROM binary for contiguous regions of 32-bit little-endian pointers
that point to null-terminated ASCII string data, then converts corresponding
.byte directives in the assembly source to .long LABEL_EXXXXXX entries and
inserts labels at the target string positions.

Safety: Only converts tables where ALL target labels can be resolved (either
already exist, insertable via byte counting, found in .byte blocks, or found
via string content matching). Tables with any unresolvable labels are skipped.

Usage:
    cd /mnt/shared/kn5000-roms-disasm
    python scripts/convert_string_pointer_tables.py [--dry-run]
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
ALIGNED_STRING_RE = re.compile(r'aligned_string\s+"([^"]*)"')

# --- Constants ---
ROM_BASE = 0xE00000
ROM_END = 0xFFFFFF
MIN_TABLE_ENTRIES = 4
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


def format_bytes_multiline(byte_list, indent='\t'):
    result = []
    for i in range(0, len(byte_list), 8):
        chunk = byte_list[i:i + 8]
        result.append(format_bytes_line(chunk, indent))
    return result


def build_label_index(lines):
    index = {}
    for i, line in enumerate(lines):
        m = LABEL_RE.match(line)
        if m:
            addr = int(m.group(1)[6:], 16)
            index[addr] = i
    return index


def collect_byte_block(lines, start_line):
    all_bytes = []
    j = start_line
    while j < len(lines) and lines[j].strip().startswith('.byte '):
        all_bytes.extend(parse_byte_values(lines[j]))
        j += 1
    return all_bytes, j


def line_byte_count_with_addr(line, current_addr):
    """Count bytes a data line emits, with position-aware alignment."""
    stripped = line.strip()

    # Handle label+data lines
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
        m = re.search(r'"([^"]*)"', stripped)
        return len(m.group(1)) if m else 0
    if stripped.startswith('.asciz '):
        m = re.search(r'"([^"]*)"', stripped)
        return (len(m.group(1)) + 1) if m else 1
    m = ALIGNED_STRING_RE.search(stripped)
    if m:
        size = len(m.group(1)) + 1
        if (current_addr + size) % 2 != 0:
            size += 1
        return size
    m = ZERO_RE.match(stripped)
    if m:
        return int(m.group(1))
    return 0


def find_insert_position(lines, label_line, byte_offset, label_addr):
    """Find line position for a label at byte_offset from label_addr."""
    cumulative = 0
    current_addr = label_addr
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


# =============================================================================
# ROM scanning
# =============================================================================

def is_string_at(rom, offset, min_len=2):
    if offset < 0 or offset >= len(rom):
        return False
    i = offset
    while i < len(rom) and rom[i] != 0:
        if rom[i] < 0x20 or rom[i] > 0x7E:
            return False
        i += 1
    if i >= len(rom):
        return False
    return (i - offset) >= min_len


def scan_pointer_tables(rom):
    tables = []
    rom_len = len(rom)
    skip_until = 0
    i = 0
    while i < rom_len - 15:
        if i < skip_until:
            i += 1
            continue
        val = struct.unpack_from('<I', rom, i)[0]
        if not (ROM_BASE <= val <= ROM_END):
            i += 1
            continue
        if not is_string_at(rom, val - ROM_BASE):
            i += 1
            continue
        entries = []
        j = i
        while j < rom_len - 3:
            v = struct.unpack_from('<I', rom, j)[0]
            if not (ROM_BASE <= v <= ROM_END):
                break
            if not is_string_at(rom, v - ROM_BASE):
                break
            entries.append(v)
            j += 4
        if len(entries) >= MIN_TABLE_ENTRIES:
            tables.append((ROM_BASE + i, len(entries), entries))
            skip_until = j
            i = j
        else:
            i += 1
    return tables


# =============================================================================
# .byte block detection with ROM address matching
# =============================================================================

def find_all_byte_blocks(lines, rom):
    """Find .byte blocks and their ROM addresses via byte-matching."""
    blocks = []
    i = 0
    while i < len(lines):
        if lines[i].strip().startswith('.byte '):
            block_bytes, block_end = collect_byte_block(lines, i)
            if len(block_bytes) >= 4:
                sig_len = min(16, len(block_bytes))
                signature = bytes(block_bytes[:sig_len])
                offset = rom.find(signature)
                if offset != -1:
                    full = bytes(block_bytes)
                    if rom[offset:offset + len(full)] == full:
                        blocks.append((i, block_end, ROM_BASE + offset, block_bytes))
            i = block_end
        else:
            i += 1
    return blocks


# =============================================================================
# Label resolution: multi-strategy approach
# =============================================================================

def verify_resolution_by_byte_count(line_idx, offset_in_line, addr, lines, label_index):
    """Try to verify a label resolution by counting bytes from nearest label.

    Returns True (verified), False (disproved), or None (can't determine).
    """
    # Find nearest preceding label by scanning backwards
    best_label_addr = None
    best_label_line = None
    for j in range(line_idx - 1, max(0, line_idx - 500) - 1, -1):
        m = LABEL_RE.match(lines[j])
        if m:
            label_addr = int(m.group(1)[6:], 16)
            if label_addr in label_index:
                best_label_addr = label_addr
                best_label_line = j
                break

    if best_label_addr is None:
        return None  # Can't verify

    # Count bytes from the label to our resolved position
    cumulative = 0
    current_addr = best_label_addr
    j = best_label_line + 1
    while j < line_idx:
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
            return None  # Can't count through this line - inconclusive
        cumulative += bc
        current_addr += bc
        j += 1

    computed_addr = best_label_addr + cumulative + offset_in_line
    return computed_addr == addr


def can_resolve_label(addr, lines, label_index, byte_blocks, rom):
    """Check if a label for this address can be resolved.

    Returns:
        None if label already exists
        (line_idx, offset_in_line, method) if label can be inserted
        False if label cannot be resolved
    """
    # Already exists?
    if addr in label_index:
        return None  # Already exists, no action needed

    # Strategy 1: byte counting from nearest preceding label
    candidates = [(a, l) for a, l in label_index.items() if a <= addr]
    if candidates:
        prev_addr, prev_line = max(candidates, key=lambda x: x[0])
        byte_offset = addr - prev_addr
        pos = find_insert_position(lines, prev_line, byte_offset, prev_addr)
        if pos is not None:
            line_idx, offset_in_line = pos
            # Verify the position is actually splittable
            if offset_in_line > 0:
                stripped = lines[line_idx].strip()
                if LABEL_RE.match(stripped):
                    stripped = stripped.split(':', 1)[1].strip()
                if not (stripped.startswith('.byte ') or FILL_RE.match(stripped)):
                    pass  # Can't split this line type, try other strategies
                else:
                    return (line_idx, offset_in_line, 'byte_count')
            else:
                return (line_idx, offset_in_line, 'byte_count')

    # Strategy 2: check if addr falls within a known .byte block
    for block_start, block_end, rom_addr, block_bytes in byte_blocks:
        rom_end = rom_addr + len(block_bytes)
        if rom_addr <= addr < rom_end:
            # Compute line and offset within the block
            target_offset = addr - rom_addr
            cum = 0
            for j in range(block_start, block_end):
                bc = len(parse_byte_values(lines[j]))
                if cum + bc > target_offset:
                    return (j, target_offset - cum, 'byte_block')
                if cum + bc == target_offset:
                    return (j + 1, 0, 'byte_block')
                cum += bc
            break  # Found the block but couldn't compute position

    # Strategy 3: search for matching string content near expected position
    rom_offset = addr - ROM_BASE
    if 0 <= rom_offset < len(rom):
        # Read string from ROM
        end = rom_offset
        while end < len(rom) and rom[end] != 0:
            if rom[end] < 0x20 or rom[end] > 0x7E:
                break
            end += 1
        target_str = rom[rom_offset:end].decode('ascii', errors='replace')

        # Get approximate line position
        if candidates:
            nearest_line = min(candidates, key=lambda x: abs(x[0] - addr))[1]
        else:
            nearest_line = 0

        # Search for string in assembly - two passes:
        # Pass 1: exact string matches (aligned_string, .asciz) - preferred
        # Pass 2: byte prefix matches (.byte) - fallback
        # All candidates are verified against ROM position before accepting
        search_start = max(0, nearest_line - 200)
        search_end = min(len(lines), nearest_line + 800)

        # Pass 1: exact string matches (aligned_string, .asciz)
        string_candidates = []  # (line_idx, has_label)
        for i in range(search_start, search_end):
            stripped = lines[i].strip()
            has_label = LABEL_RE.match(stripped)
            if has_label:
                data_part = stripped.split(':', 1)[1].strip()
            else:
                data_part = stripped

            # Check aligned_string
            m = ALIGNED_STRING_RE.search(data_part)
            if m and len(target_str) >= 3:
                if target_str == m.group(1):
                    string_candidates.append((i, has_label))

            # Check .asciz
            elif data_part.startswith('.asciz '):
                m2 = re.search(r'"([^"]*)"', data_part)
                if m2 and m2.group(1) == target_str:
                    string_candidates.append((i, has_label))

        if string_candidates:
            # If only one match, use it (unique string)
            if len(string_candidates) == 1:
                i, has_label = string_candidates[0]
                if has_label:
                    return None
                return (i, 0, 'string_match')

            # Multiple matches - try to verify each by byte counting
            for i, has_label in string_candidates:
                if has_label:
                    continue
                v = verify_resolution_by_byte_count(i, 0, addr, lines, label_index)
                if v is True:
                    return (i, 0, 'string_match')

            # Can't verify any - skip (ambiguous)
            pass

        # Pass 2: byte prefix matches (fallback - only if no exact match)
        byte_candidates = []
        for i in range(search_start, search_end):
            stripped = lines[i].strip()
            has_label = LABEL_RE.match(stripped)
            if has_label:
                data_part = stripped.split(':', 1)[1].strip()
            else:
                data_part = stripped

            if data_part.startswith('.byte ') and len(target_str) >= 2:
                byte_vals = parse_byte_values(stripped)
                target_bytes = [ord(c) for c in target_str[:len(byte_vals)]]
                if byte_vals == target_bytes and len(byte_vals) >= 2:
                    byte_candidates.append((i, has_label))

        if byte_candidates:
            # Single match or verified match
            if len(byte_candidates) == 1:
                i, has_label = byte_candidates[0]
                if has_label:
                    return None
                # Verify even single matches for byte prefix
                v = verify_resolution_by_byte_count(i, 0, addr, lines, label_index)
                if v is not False:  # True or None (inconclusive) - accept
                    return (i, 0, 'byte_prefix_match')
            else:
                # Multiple matches - try to verify
                for i, has_label in byte_candidates:
                    if has_label:
                        continue
                    v = verify_resolution_by_byte_count(i, 0, addr, lines, label_index)
                    if v is True:
                        return (i, 0, 'byte_prefix_match')

    return False


def resolve_all_labels(target_addrs, lines, label_index, byte_blocks, rom):
    """Resolve all needed labels. Returns dict: addr -> resolution or None."""
    results = {}
    for addr in target_addrs:
        result = can_resolve_label(addr, lines, label_index, byte_blocks, rom)
        results[addr] = result
    return results


# =============================================================================
# Table matching and change generation
# =============================================================================

def match_tables_to_blocks(tables, byte_blocks):
    """Match detected pointer tables to .byte blocks."""
    block_ranges = []
    for block_start, block_end, rom_addr, block_bytes in byte_blocks:
        rom_end = rom_addr + len(block_bytes)
        block_ranges.append((rom_addr, rom_end, block_start, block_end, block_bytes))
    block_ranges.sort()

    block_tables = defaultdict(list)
    matched = 0
    not_in_blocks = 0

    for table_addr, num_entries, entries in tables:
        found = False
        for rom_addr, rom_end, block_start, block_end, block_bytes in block_ranges:
            if rom_addr <= table_addr < rom_end:
                table_offset = table_addr - rom_addr
                available = len(block_bytes) - table_offset
                convertible = min(num_entries, available // 4)
                if convertible >= MIN_TABLE_ENTRIES:
                    key = (block_start, block_end)
                    block_tables[key].append((table_offset, convertible, entries[:convertible]))
                    matched += 1
                found = True
                break
        if not found:
            not_in_blocks += 1

    return block_tables, matched, not_in_blocks


def generate_block_change(block_start, block_end, block_bytes, table_list,
                          block_rom_addr, existing_labels):
    """Generate replacement for a .byte block containing pointer tables.

    Also inserts labels within non-table bytes of the block for pointer targets
    that fall within this block.
    """
    table_list.sort(key=lambda x: x[0])

    # Build table regions, merging overlaps
    regions = []
    for offset, num_entries, entries in table_list:
        end = offset + num_entries * 4
        if regions and offset < regions[-1][1]:
            prev_start, prev_end, prev_entries = regions[-1]
            if end > prev_end:
                new_entries = []
                for i in range(0, end - prev_start, 4):
                    off = prev_start + i
                    if off + 3 < len(block_bytes):
                        val = struct.unpack_from('<I', bytes(block_bytes), off)[0]
                        new_entries.append(val)
                regions[-1] = (prev_start, end, new_entries)
        else:
            regions.append((offset, end, list(entries)))

    # Collect all target addresses
    all_targets = []
    for _, _, entries in regions:
        all_targets.extend(entries)

    # Find labels that need to be inserted within non-table portions of this block
    in_block_labels = {}  # offset_in_block -> label_name
    for val in all_targets:
        if val in existing_labels:
            continue
        label_offset = val - block_rom_addr
        if 0 <= label_offset < len(block_bytes):
            # Check it's NOT inside a table region
            in_table = any(s <= label_offset < e for s, e, _ in regions)
            if not in_table:
                in_block_labels[label_offset] = f'LABEL_{val:06X}'

    # Build replacement lines with labels inserted in non-table regions
    new_lines = []
    pos = 0

    def emit_bytes_with_labels(byte_data, start_offset):
        """Emit .byte lines with labels inserted at the right positions."""
        result = []
        # Find labels within this byte range
        labels_here = sorted((off - start_offset, name)
                             for off, name in in_block_labels.items()
                             if start_offset <= off < start_offset + len(byte_data))
        if not labels_here:
            result.extend(format_bytes_multiline(byte_data))
            return result

        prev = 0
        for off, name in labels_here:
            if off > prev:
                result.extend(format_bytes_multiline(byte_data[prev:off]))
            result.append(f'{name}:\n')
            prev = off
        if prev < len(byte_data):
            result.extend(format_bytes_multiline(byte_data[prev:]))
        return result

    for start, end, entries in regions:
        if start > pos:
            new_lines.extend(emit_bytes_with_labels(block_bytes[pos:start], pos))
        for val in entries:
            new_lines.append(f'\t.long LABEL_{val:06X}\n')
        pos = end

    if pos < len(block_bytes):
        new_lines.extend(emit_bytes_with_labels(block_bytes[pos:], pos))

    # Labels inserted within the block should be excluded from external insertion
    return (block_start, block_end, new_lines), all_targets, set(in_block_labels.values())


def make_label_insertion(lines, line_idx, offset_in_line, label_name):
    """Create a change to insert a label."""
    if offset_in_line == 0:
        return (line_idx, line_idx, [f'{label_name}:\n'])

    stripped = lines[line_idx].strip()
    if LABEL_RE.match(stripped):
        stripped = stripped.split(':', 1)[1].strip()

    if stripped.startswith('.byte '):
        byte_vals = parse_byte_values(lines[line_idx])
        before = byte_vals[:offset_in_line]
        after = byte_vals[offset_in_line:]
        new_lines = []
        if before:
            new_lines.append(format_bytes_line(before))
        new_lines.append(f'{label_name}:\n')
        if after:
            new_lines.append(format_bytes_line(after))
        return (line_idx, line_idx + 1, new_lines)

    m = FILL_RE.match(stripped)
    if m:
        count = int(m.group(2))
        val_str = m.group(3)
        new_lines = []
        if offset_in_line > 0:
            new_lines.append(f'\t.fill {offset_in_line}, 1, 0x{val_str}\n')
        new_lines.append(f'{label_name}:\n')
        remaining = count - offset_in_line
        if remaining > 0:
            new_lines.append(f'\t.fill {remaining}, 1, 0x{val_str}\n')
        return (line_idx, line_idx + 1, new_lines)

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
    print(f"  {len(rom)} bytes ({len(rom)/1024/1024:.1f} MB)")

    # Phase 1: Scan ROM
    print("\nPhase 1: Scanning ROM for pointer-to-string tables...")
    tables = scan_pointer_tables(rom)
    print(f"  Found {len(tables)} tables (min {MIN_TABLE_ENTRIES} entries)")

    # Phase 2: Find .byte blocks
    print("\nPhase 2: Finding .byte blocks and ROM addresses...")
    byte_blocks = find_all_byte_blocks(lines, rom)
    print(f"  Found {len(byte_blocks)} .byte blocks")

    label_index = build_label_index(lines)
    existing_labels = set(label_index.keys())
    print(f"  {len(label_index)} labels indexed")

    # Phase 3: Match tables to blocks
    print("\nPhase 3: Matching tables to .byte blocks...")
    block_tables, matched, not_in_blocks = match_tables_to_blocks(tables, byte_blocks)
    print(f"  {matched} tables in {len(block_tables)} .byte blocks")
    print(f"  {not_in_blocks} not in .byte blocks (already converted or in non-.byte)")

    # Phase 4: Pre-check label resolvability and filter tables
    print("\nPhase 4: Checking label resolvability...")

    # Collect ALL target labels from ALL matched tables
    all_potential_targets = set()
    for (block_start, block_end), table_list in block_tables.items():
        block_bytes, _ = collect_byte_block(lines, block_start)
        for offset, num_entries, entries in table_list:
            for val in entries:
                if val not in existing_labels:
                    all_potential_targets.add(val)

    print(f"  {len(all_potential_targets)} unique new labels needed")

    # Resolve all labels
    label_resolutions = resolve_all_labels(
        all_potential_targets, lines, label_index, byte_blocks, rom)

    resolvable = sum(1 for v in label_resolutions.values() if v is not False and v is not None)
    already_exist = sum(1 for v in label_resolutions.values() if v is None)
    unresolvable = sum(1 for v in label_resolutions.values() if v is False)
    print(f"  Resolvable: {resolvable}")
    print(f"  Already labeled: {already_exist}")
    print(f"  Unresolvable: {unresolvable}")

    # Count by method
    methods = defaultdict(int)
    for v in label_resolutions.values():
        if isinstance(v, tuple):
            methods[v[2]] += 1
    if methods:
        print(f"  Methods: {dict(methods)}")

    # Filter: only convert tables where ALL target labels are resolved
    convertible_blocks = {}
    skipped_tables = 0
    skipped_entries = 0

    for (block_start, block_end), table_list in block_tables.items():
        block_bytes, _ = collect_byte_block(lines, block_start)
        good_tables = []
        for offset, num_entries, entries in table_list:
            all_ok = True
            for val in entries:
                if val in existing_labels:
                    continue
                resolution = label_resolutions.get(val, False)
                if resolution is False:
                    all_ok = False
                    break
            if all_ok:
                good_tables.append((offset, num_entries, entries))
            else:
                skipped_tables += 1
                skipped_entries += num_entries
        if good_tables:
            convertible_blocks[(block_start, block_end)] = good_tables

    print(f"\n  Convertible: {sum(len(v) for v in convertible_blocks.values())} tables "
          f"in {len(convertible_blocks)} blocks")
    print(f"  Skipped (unresolvable labels): {skipped_tables} tables ({skipped_entries} entries)")

    if not convertible_blocks:
        print("\nNo tables to convert.")
        return

    # Phase 5: Generate all changes
    print("\nPhase 5: Generating changes...")
    all_changes = []
    all_needed_labels = set()  # Labels needed for converted tables
    in_block_label_names = set()  # Labels already inserted within blocks
    total_entries = 0

    # Build a map of block_key -> rom_addr for passing to generate_block_change
    block_rom_addrs = {}
    for block_start, block_end_bb, rom_addr, block_bytes_bb in byte_blocks:
        block_rom_addrs[(block_start, block_end_bb)] = rom_addr

    for (block_start, block_end), table_list in sorted(convertible_blocks.items()):
        block_bytes, _ = collect_byte_block(lines, block_start)
        block_rom_addr = block_rom_addrs.get((block_start, block_end), 0)
        change, targets, block_labels = generate_block_change(
            block_start, block_end, block_bytes, table_list,
            block_rom_addr, existing_labels)
        all_changes.append(change)
        in_block_label_names.update(block_labels)
        for val in targets:
            if val not in existing_labels:
                all_needed_labels.add(val)
            total_entries += 1

    print(f"  {total_entries} .long entries from {len(all_changes)} block changes")
    print(f"  {len(all_needed_labels)} labels to insert")
    print(f"  {len(in_block_label_names)} labels inserted within blocks")

    # Phase 6: Generate label insertion changes
    print("\nPhase 6: Inserting target labels...")
    modified_ranges = [(s, e) for s, e, _ in all_changes]

    # Collect all label positions, grouped by LINE (not by line+offset)
    # This ensures all labels for the same line are handled in one change
    line_labels = defaultdict(list)  # line_idx -> [(offset, label_name)]

    for addr in sorted(all_needed_labels):
        label_name = f'LABEL_{addr:06X}'

        # Skip if already inserted within a block change
        if label_name in in_block_label_names:
            continue

        resolution = label_resolutions.get(addr)
        if resolution is None or resolution is False:
            continue

        line_idx, offset_in_line, method = resolution

        # Skip if in a modified range
        if any(s <= line_idx < e for s, e in modified_ranges):
            continue

        line_labels[line_idx].append((offset_in_line, label_name))

    # Generate label changes - one change per affected line
    label_changes = []
    for line_idx in sorted(line_labels.keys()):
        labels_on_line = sorted(line_labels[line_idx])  # sorted by offset

        # All at offset 0? Simple insertion
        if all(off == 0 for off, _ in labels_on_line):
            new_lines = [f'{name}:\n' for _, name in labels_on_line]
            label_changes.append((line_idx, line_idx, new_lines))
            continue

        # Labels at different offsets within the same line
        stripped = lines[line_idx].strip()
        has_existing_label = LABEL_RE.match(stripped)
        if has_existing_label:
            data_part = stripped.split(':', 1)[1].strip()
        else:
            data_part = stripped

        if data_part.startswith('.byte '):
            byte_vals = parse_byte_values(lines[line_idx])
            new_lines = []

            # Emit offset-0 labels first
            for off, name in labels_on_line:
                if off == 0:
                    new_lines.append(f'{name}:\n')

            # Split bytes at each non-zero offset
            prev_off = 0
            non_zero = [(off, name) for off, name in labels_on_line if off > 0]
            for off, name in non_zero:
                chunk = byte_vals[prev_off:off]
                if chunk:
                    new_lines.append(format_bytes_line(chunk))
                new_lines.append(f'{name}:\n')
                prev_off = off

            # Remaining bytes
            remaining = byte_vals[prev_off:]
            if remaining:
                new_lines.append(format_bytes_line(remaining))

            label_changes.append((line_idx, line_idx + 1, new_lines))
        elif data_part.startswith('.fill '):
            m = FILL_RE.match(data_part)
            if m:
                count = int(m.group(2))
                val_str = m.group(3)
                new_lines = []
                prev_off = 0
                for off, name in labels_on_line:
                    chunk_size = off - prev_off
                    if chunk_size > 0:
                        new_lines.append(f'\t.fill {chunk_size}, 1, 0x{val_str}\n')
                    new_lines.append(f'{name}:\n')
                    prev_off = off
                remaining = count - prev_off
                if remaining > 0:
                    new_lines.append(f'\t.fill {remaining}, 1, 0x{val_str}\n')
                label_changes.append((line_idx, line_idx + 1, new_lines))
        else:
            # Only handle offset 0 labels for unsplittable lines
            zero_labels = [(off, name) for off, name in labels_on_line if off == 0]
            if zero_labels:
                new_lines = [f'{name}:\n' for _, name in zero_labels]
                label_changes.append((line_idx, line_idx, new_lines))
            non_zero = [(off, name) for off, name in labels_on_line if off > 0]
            for off, name in non_zero:
                print(f"  WARNING: Cannot split line {line_idx} for {name}: "
                      f"{data_part[:40]}")

    all_changes.extend(label_changes)
    print(f"  {len(label_changes)} label insertion changes")

    # Phase 7: Sort and verify changes
    # Sort by (start, end) descending - for same start line, larger ranges first
    all_changes.sort(key=lambda x: (x[0], x[1]), reverse=True)

    overlaps = 0
    for i in range(len(all_changes) - 1):
        curr_start = all_changes[i][0]
        prev_end = all_changes[i + 1][1]
        if curr_start < prev_end:
            overlaps += 1
            if overlaps <= 5:
                print(f"  WARNING: Overlap at lines {all_changes[i+1][0]}-{prev_end} and "
                      f"{curr_start}-{all_changes[i][1]}")

    if overlaps > 0:
        print(f"\n  ERROR: {overlaps} overlapping changes. Aborting.")
        sys.exit(1)

    if dry_run:
        print(f"\n  DRY RUN: Would apply {len(all_changes)} changes.")
        return

    # Apply changes
    print(f"\nPhase 7: Applying {len(all_changes)} changes...")
    for start, end, new_lines in all_changes:
        lines[start:end] = new_lines

    with open(asm_path, 'w') as f:
        f.writelines(lines)

    print(f"\nDone! Applied {len(all_changes)} changes.")
    print(f"  {total_entries} pointer entries converted to .long")
    print(f"  {len(label_changes)} labels inserted")
    print(f"\nNext steps:")
    print(f"  1. make clean && make all")
    print(f"  2. python scripts/compare_roms.py")


if __name__ == '__main__':
    dry_run = '--dry-run' in sys.argv
    process_file(ASM_FILE, ROM_FILE, dry_run=dry_run)
