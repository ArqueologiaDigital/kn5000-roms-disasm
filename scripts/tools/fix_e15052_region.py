#!/usr/bin/env python3
"""Fix pointer+string group formatting in the E15052-E155CC region.

This script applies structural fixes to the assembly source file:
1. Converts .asciz to aligned_string where ROM has 0xFF pad (LABEL_E15168)
2. Splits .byte lines containing mixed padding + pointer data
3. Adds missing labels on pointer tables (E151BC, E15240, E153E2, E15452, E155B4)
4. Adds missing labels on strings (E15354, E15396)
5. Merges .byte 0xa1 + aligned_string into single aligned_string
6. Merges fragmented .ascii/.byte/.asciz into single aligned_string/asciz
7. Converts raw .byte pointer to .long LABEL_
8. Adds double blank line separation between groups
9. Removes .set directives for labels that now have position labels

All file I/O uses Latin-1 encoding to preserve single-byte characters.

Usage:
    cd /home/fsanches/compartilhado/kn5000-roms-disasm
    python scripts/fix_e15052_region.py [--dry-run]
"""

import sys

ASM_FILE = 'maincpu/kn5000_v10_program.s'
ROM_FILE = '/home/fsanches/compartilhado/kn5000_original_roms/kn5000/kn5000_v10_program.rom'
ROM_BASE = 0xE00000


def read_rom_string(rom, addr):
    """Read a null-terminated Latin-1 string from ROM at given address."""
    off = addr - ROM_BASE
    end = off
    while end < len(rom) and rom[end] != 0x00:
        end += 1
    return rom[off:end].decode('latin-1')


def rom_string_needs_align_pad(rom, addr):
    """Check if the string at addr needs aligned_string (0xFF pad after null)."""
    off = addr - ROM_BASE
    end = off
    while end < len(rom) and rom[end] != 0x00:
        end += 1
    total_with_null = (end - off) + 1
    end_addr = addr + total_with_null
    if end_addr % 2 != 0:
        # Check if ROM has 0xFF pad
        pad_off = end + 1
        if pad_off < len(rom) and rom[pad_off] == 0xFF:
            return True
    return False


def escape_latin1(s):
    """Escape non-printable Latin-1 characters for assembly string literals.

    Characters that can be directly embedded (0x20-0x7E printable ASCII,
    0xA0-0xFF Latin-1 upper) are left as-is. Others get \\xNN escapes.
    Double quotes and backslashes are escaped.
    """
    result = []
    for ch in s:
        b = ord(ch)
        if b == 0x22:  # double quote
            result.append('\\"')
        elif b == 0x5C:  # backslash
            result.append('\\\\')
        elif 0x20 <= b <= 0x7E:
            result.append(ch)
        elif 0xA0 <= b <= 0xFF:
            result.append(ch)  # Latin-1 upper — stays as raw byte in Latin-1 file
        elif b in (0xA1,):  # inverted exclamation — already handled above
            result.append(ch)
        else:
            result.append(f'\\x{b:02x}')
    return ''.join(result)


def process_file(filepath, rom_path, dry_run=False):
    with open(rom_path, 'rb') as f:
        rom = f.read()

    with open(filepath, 'r', encoding='latin-1') as f:
        lines = f.readlines()

    print(f"Loaded {len(lines)} lines, ROM {len(rom)} bytes")

    # --- Phase 1: Find the target region ---
    # Find lines by label
    label_lines = {}
    set_lines_to_remove = []
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('LABEL_E15052:') or stripped.startswith('LABEL_E15052\t'):
            label_lines['E15052'] = i
        if stripped.startswith('LABEL_E150B0:') or stripped.startswith('LABEL_E150B0\t'):
            label_lines['E150B0'] = i
        if stripped.startswith('LABEL_E15110:') or stripped.startswith('LABEL_E15110\t'):
            label_lines['E15110'] = i
        if stripped.startswith('LABEL_E15168:') or stripped.startswith('LABEL_E15168\t'):
            label_lines['E15168'] = i
        if stripped.startswith('LABEL_E1522C:') or stripped.startswith('LABEL_E1522C\t'):
            label_lines['E1522C'] = i
        if stripped.startswith('LABEL_E152A8:') or stripped.startswith('LABEL_E152A8\t'):
            label_lines['E152A8'] = i
        if stripped.startswith('LABEL_E152FE:') or stripped.startswith('LABEL_E152FE\t'):
            label_lines['E152FE'] = i
        if stripped.startswith('LABEL_E154AC:') or stripped.startswith('LABEL_E154AC\t'):
            label_lines['E154AC'] = i
        if stripped.startswith('LABEL_E154E6:') or stripped.startswith('LABEL_E154E6\t'):
            label_lines['E154E6'] = i
        if stripped.startswith('LABEL_E1553C:') or stripped.startswith('LABEL_E1553C\t'):
            label_lines['E1553C'] = i
        if stripped.startswith('LABEL_E15582:') or stripped.startswith('LABEL_E15582\t'):
            label_lines['E15582'] = i
        if stripped.startswith('LABEL_E1561C:') or stripped.startswith('LABEL_E1561C\t'):
            label_lines['E1561C'] = i
        # Detect .set lines to remove
        if '.set LABEL_E15354,' in stripped or '.set LABEL_E15396,' in stripped:
            set_lines_to_remove.append(i)

    print(f"Found labels: {sorted(label_lines.keys())}")
    print(f".set lines to remove: {set_lines_to_remove}")

    # --- Phase 2: Build replacement blocks ---
    # We'll collect (start_line, end_line, new_lines) tuples
    # and apply them in reverse order.
    changes = []

    # === Fix 1: LABEL_E15052 — merge .byte 0xa1 + aligned_string ===
    # Current: LABEL_E15052:\n\t.byte 0xa1\n\taligned_string "Memorice..."
    # Target:  LABEL_E15052:\taligned_string "\xa1Memorice..."
    i = label_lines['E15052']
    assert lines[i].strip() == 'LABEL_E15052:', f"Expected bare label at line {i+1}"
    assert lines[i+1].strip() == '.byte 0xa1', f"Expected .byte 0xa1 at line {i+2}"
    assert 'aligned_string' in lines[i+2], f"Expected aligned_string at line {i+3}"
    # Extract the string content
    s = lines[i+2].strip()
    # aligned_string "..."
    quote_start = s.index('"') + 1
    quote_end = s.rindex('"')
    old_text = s[quote_start:quote_end]
    rom_text = read_rom_string(rom, 0xE15052)
    new_text = escape_latin1(rom_text)
    changes.append((i, i+3, [
        f'LABEL_E15052:\taligned_string "{new_text}"\n'
    ], 'E15052 merge .byte 0xa1'))

    # === Fix 2: LABEL_E150B0 — merge fragmented French string ===
    # Current lines 7246-7248:
    #   LABEL_E150B0: .ascii "Enregistrez vos motifs pr"
    #   \t.byte 0xe9, 0x66, 0xe9, 0x72, 0xe9, 0x73, 0x20
    #   \t.asciz "dans le groupe  « Custom Rhythm Group » ...de façon permanente!"
    # Target: LABEL_E150B0:\tasciz "..." (even alignment, no pad needed)
    i = label_lines['E150B0']
    rom_text = read_rom_string(rom, 0xE150B0)
    new_text = escape_latin1(rom_text)
    # This string is 95 bytes + null = 96 (even), so .asciz is fine
    # But ROM shows it aligned (E15110 follows at even boundary), use aligned_string for consistency
    changes.append((i, i+3, [
        f'LABEL_E150B0:\taligned_string "{new_text}"\n'
    ], 'E150B0 merge fragmented French'))

    # === Fix 3: LABEL_E15168 — convert .asciz to aligned_string ===
    # Current: LABEL_E15168:\t.asciz "Store your..."
    # The string is 82 bytes + null = 83 (odd), ROM has 0xFF pad at E151BB
    # Next line is: .byte 0xff, 0x2c, 0x52, 0xe1, 0x00
    # The 0xff is the pad, rest is a pointer (0x00E1522C = LABEL_E1522C)
    i = label_lines['E15168']
    rom_text = read_rom_string(rom, 0xE15168)
    new_text = escape_latin1(rom_text)
    # Check the next line
    next_line = lines[i+1].strip()
    assert next_line == '.byte 0xff, 0x2c, 0x52, 0xe1, 0x00', \
        f"Expected .byte 0xff,0x2c,0x52,0xe1,0x00 at line {i+2}, got: {next_line}"
    changes.append((i, i+2, [
        f'LABEL_E15168:\taligned_string "{new_text}"\n',
        f'LABEL_E151BC:\n',
        f'\t.long LABEL_E1522C\n',
    ], 'E15168 .asciz→aligned_string + split pointer'))

    # === Fix 4: After LABEL_E1522C — add LABEL_E15240 before table 2 ===
    # Current: line after E1522C starts with .long LABEL_E15396
    # Need to add LABEL_E15240: before that line
    i = label_lines['E1522C']
    # Line i is LABEL_E1522C: aligned_string "Accordion Register"
    # Line i+1 should be: \t.long LABEL_E15396
    assert '.long LABEL_E15396' in lines[i+1], \
        f"Expected .long LABEL_E15396 at line {i+2}, got: {lines[i+1].strip()}"
    # Insert LABEL_E15240: before the .long lines, with double blank line separator
    changes.append((i+1, i+1, [
        '\n',
        '\n',
        'LABEL_E15240:\n',
    ], 'Add LABEL_E15240'))

    # === Fix 5: LABEL_E152A8 — merge .byte 0xa1 + aligned_string ===
    i = label_lines['E152A8']
    assert lines[i].strip() == 'LABEL_E152A8:', f"Expected bare label at line {i+1}"
    assert lines[i+1].strip() == '.byte 0xa1', f"Expected .byte 0xa1 at line {i+2}"
    rom_text = read_rom_string(rom, 0xE152A8)
    new_text = escape_latin1(rom_text)
    changes.append((i, i+3, [
        f'LABEL_E152A8:\taligned_string "{new_text}"\n'
    ], 'E152A8 merge .byte 0xa1'))

    # === Fix 6: After LABEL_E152FE — add missing LABEL_E15354 and LABEL_E15396 ===
    # Current around E152FE:
    #   LABEL_E152FE:
    #   \taligned_string "Avec la fonction..."  (line i+1)
    #   \taligned_string "ACCORDION REGISTER eröffnet..."  (line i+2) — needs LABEL_E15354
    #   \taligned_string "A World of Accordion..."  (line i+3) — needs LABEL_E15396
    i = label_lines['E152FE']
    # Verify current structure
    assert lines[i].strip() == 'LABEL_E152FE:', f"Unexpected at line {i+1}"
    # The aligned_string on i+1 is the French text
    assert 'aligned_string' in lines[i+1], f"Expected aligned_string at line {i+2}"
    # i+2 should be German (needs LABEL_E15354)
    assert 'ACCORDION REGISTER' in lines[i+2], f"Expected German at line {i+3}"
    # i+3 should be English (needs LABEL_E15396)
    assert 'A World of Accordion' in lines[i+3], f"Expected English at line {i+4}"

    # Get ROM strings for verification
    rom_fr = read_rom_string(rom, 0xE152FE)
    rom_de = read_rom_string(rom, 0xE15354)
    rom_en = read_rom_string(rom, 0xE15396)

    changes.append((i, i+4, [
        f'LABEL_E152FE:\taligned_string "{escape_latin1(rom_fr)}"\n',
        f'LABEL_E15354:\taligned_string "{escape_latin1(rom_de)}"\n',
        f'LABEL_E15396:\taligned_string "{escape_latin1(rom_en)}"\n',
    ], 'E152FE/E15354/E15396 add labels'))

    # === Fix 7: Add LABEL_E153E2 before table 3 ===
    # After the last aligned_string "A World of Accordion..."
    # the .long LABEL_E15442 line needs LABEL_E153E2: before it
    # Find the .long LABEL_E15442 line after E15396 region
    # It's currently at a fixed offset — let's find it
    for j in range(label_lines['E152FE'], label_lines['E152FE'] + 20):
        if '.long LABEL_E15442' in lines[j]:
            table3_start = j
            break
    else:
        raise RuntimeError("Could not find .long LABEL_E15442")

    changes.append((table3_start, table3_start, [
        '\n',
        '\n',
        'LABEL_E153E2:\n',
    ], 'Add LABEL_E153E2'))

    # === Fix 8: Add LABEL_E15452 before table 4 ===
    # Find .long LABEL_E15582 after table 3 strings
    for j in range(table3_start, table3_start + 30):
        if '.long LABEL_E15582' in lines[j]:
            table4_start = j
            break
    else:
        raise RuntimeError("Could not find .long LABEL_E15582")

    changes.append((table4_start, table4_start, [
        '\n',
        '\n',
        'LABEL_E15452:\n',
    ], 'Add LABEL_E15452'))

    # === Fix 9: LABEL_E154AC — merge .byte 0xa1 + remaining bytes ===
    # Current:
    #   LABEL_E154AC:
    #   \t.byte 0xa1, 0x53, 0x6f, 0x6e
    #   \taligned_string "idos de órgano clásicos con barras para Jazz y Rock!"
    i = label_lines['E154AC']
    assert lines[i].strip() == 'LABEL_E154AC:', f"Expected bare label at line {i+1}"
    rom_text = read_rom_string(rom, 0xE154AC)
    new_text = escape_latin1(rom_text)
    changes.append((i, i+3, [
        f'LABEL_E154AC:\taligned_string "{new_text}"\n'
    ], 'E154AC merge .byte+aligned_string'))

    # === Fix 10: LABEL_E154E6 — merge .byte + .asciz ===
    # Current:
    #   LABEL_E154E6:
    #   \t.byte 0x41, 0x76
    #   \t.asciz "ec les tirettes harmoniques..."
    i = label_lines['E154E6']
    assert lines[i].strip() == 'LABEL_E154E6:', f"Expected bare label at line {i+1}"
    rom_text = read_rom_string(rom, 0xE154E6)
    new_text = escape_latin1(rom_text)
    # 85+1=86 even, so .asciz = aligned_string (no pad needed)
    changes.append((i, i+3, [
        f'LABEL_E154E6:\taligned_string "{new_text}"\n'
    ], 'E154E6 merge .byte+.asciz'))

    # === Fix 11: LABEL_E1553C — merge .ascii + .byte + aligned_string ===
    # Current:
    #   LABEL_E1553C: .ascii "Erzeugen Sie legend"
    #   \t.byte 0xe4
    #   \taligned_string "re Orgelsounds mit den Jazz- und Rock-Zugriegeln!"
    i = label_lines['E1553C']
    rom_text = read_rom_string(rom, 0xE1553C)
    new_text = escape_latin1(rom_text)
    # 69+1=70 even, aligned_string or asciz both work
    changes.append((i, i+3, [
        f'LABEL_E1553C:\taligned_string "{new_text}"\n'
    ], 'E1553C merge .ascii+.byte+aligned_string'))

    # === Fix 12: After LABEL_E15582 — convert raw .byte to .long + add LABEL_E155B4 ===
    # Current:
    #   LABEL_E15582: aligned_string "Classic Organ Sounds..."
    #   \t.byte 0x1c, 0x56, 0xe1, 0x00
    #   \t.long LABEL_E1560A
    i = label_lines['E15582']
    next_stripped = lines[i+1].strip()
    assert next_stripped == '.byte 0x1c, 0x56, 0xe1, 0x00', \
        f"Expected .byte ptr at line {i+2}, got: {next_stripped}"
    # 0x00E1561C = LABEL_E1561C
    # Next line: .long LABEL_E1560A
    assert '.long LABEL_E1560A' in lines[i+2], f"Expected .long at line {i+3}"
    changes.append((i+1, i+2, [
        '\n',
        '\n',
        'LABEL_E155B4:\n',
        '\t.long LABEL_E1561C\n',
    ], 'E155B4 add label + convert .byte to .long'))

    # === Fix 13: Add double blank lines before table 1 (E151BC) ===
    # This is handled by Fix 3 which restructures that area

    # === Fix 14: Add double blank lines between groups ===
    # We need separators:
    # - Before table 1 (E151BC) — handled by Fix 3
    # - Before table 2 (E15240) — handled by Fix 4
    # - Before table 3 (E153E2) — handled by Fix 7
    # - Before table 4 (E15452) — handled by Fix 8
    # - Before table 5 (E155B4) — handled by Fix 12

    # === Fix 15: Remove .set lines ===
    for set_line in set_lines_to_remove:
        changes.append((set_line, set_line+1, [], f'Remove .set at line {set_line+1}'))

    # --- Phase 3: Sort and apply ---
    # Sort by start line in reverse order
    changes.sort(key=lambda x: x[0], reverse=True)

    print(f"\nChanges to apply ({len(changes)}):")
    for start, end, new_lines, desc in changes:
        print(f"  Lines {start+1}-{end}: {desc} ({end-start} lines → {len(new_lines)} lines)")

    if dry_run:
        print("\n[DRY RUN] No changes written.")
        for start, end, new_lines, desc in changes:
            print(f"\n--- {desc} ---")
            print(f"OLD (lines {start+1}-{end}):")
            for k in range(start, end):
                print(f"  {lines[k].rstrip()}")
            print(f"NEW ({len(new_lines)} lines):")
            for nl in new_lines:
                print(f"  {nl.rstrip()}")
        return

    # Check for overlaps
    for i in range(len(changes) - 1):
        curr_start = changes[i][0]
        prev_end = changes[i + 1][1]
        if curr_start < prev_end:
            print(f"ERROR: Overlapping changes at lines "
                  f"{changes[i+1][0]+1}-{prev_end} and "
                  f"{curr_start+1}-{changes[i][1]}")
            sys.exit(1)

    for start, end, new_lines, desc in changes:
        lines[start:end] = new_lines

    with open(filepath, 'w', encoding='latin-1') as f:
        f.writelines(lines)

    print(f"\nApplied {len(changes)} changes")


if __name__ == '__main__':
    dry_run = '--dry-run' in sys.argv
    process_file(ASM_FILE, ROM_FILE, dry_run)
