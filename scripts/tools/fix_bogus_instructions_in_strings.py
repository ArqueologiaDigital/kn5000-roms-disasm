#!/usr/bin/env python3
"""Fix bogus disassembled instructions that are actually string data.

When the disassembler encounters bytes like 0xE9 0x6F (= "éo" in Latin-1),
it may decode them as an instruction like `dec 7, xbc`. This script:

1. Finds .ascii/.byte + instruction + aligned_string/.asciz sequences
2. Uses the nearest LABEL_XXXXXX to determine the exact ROM address
3. Checks the ROM to verify the full range is one null-terminated string
4. Replaces the fragmented sequence with a single aligned_string or .asciz

SAFETY: Only fixes runs where the ROM address can be precisely determined
from a LABEL_XXXXXX on or near the first line. Never relies on incremental
address tracking through instructions.

Usage:
    cd /home/fsanches/compartilhado/kn5000-roms-disasm
    python scripts/fix_bogus_instructions_in_strings.py [--dry-run]
"""

import re
import sys

ASM_FILE = 'maincpu/kn5000_v10_program.s'
ROM_FILE = '/home/fsanches/compartilhado/kn5000_original_roms/kn5000/kn5000_v10_program.rom'
ROM_BASE = 0xE00000

LABEL_RE = re.compile(r'^(LABEL_[0-9A-F]{6}):(.*)$')
ANY_LABEL_RE = re.compile(r'^([A-Za-z_]\w*):(.*)$')
BYTE_RE = re.compile(r'0x([0-9a-fA-F]{2})')
ALIGNED_STRING_RE = re.compile(r'aligned_string\s+"((?:[^"\\]|\\.)*)"')
QUOTED_STRING_RE = re.compile(r'"((?:[^"\\]|\\.)*)"')


def asm_string_byte_len(s):
    """Calculate actual byte length of an assembly string with escape sequences."""
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


def data_byte_count(stripped, current_addr=0):
    """Count bytes for a DATA directive only. Returns None for instructions."""
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
    m = re.match(r'^\s*\.zero\s+(\d+)', stripped)
    if m:
        return int(m.group(1))
    m = re.match(r'^\s*\.fill\s+(\d+)', stripped)
    if m:
        return int(m.group(1))
    return None  # Not a data directive (instruction or unknown)


def can_inline_byte(b):
    """Check if byte can be directly embedded in a Latin-1 string literal."""
    if b == 0x00 or b == 0x22 or b == 0x5C:  # null, double-quote, backslash
        return False
    if 0x20 <= b <= 0x7E:
        return True
    if 0xA0 <= b <= 0xFF:
        return True
    # Some KN5000 strings use characters in 0x80-0x9F range
    if b in (0x95, 0x96, 0x9E, 0x9F, 0x8C, 0x8E):
        return True
    return False


def is_real_text_string(data):
    """Check if byte sequence is real human-readable text (≥50% letters/spaces, ≥8 chars)."""
    if len(data) < 8:
        return False
    ascii_count = sum(1 for b in data if (0x41 <= b <= 0x5A) or (0x61 <= b <= 0x7A) or b == 0x20)
    return ascii_count >= len(data) * 0.5


def is_string_directive(stripped):
    """Check if stripped line is a string/byte data directive."""
    return (stripped.startswith('.ascii ') or
            stripped.startswith('.asciz ') or
            stripped.startswith('aligned_string ') or
            stripped.startswith('.byte 0x'))


def strip_label(stripped):
    """Remove label prefix from a line, returning (label_name_or_None, data_part)."""
    m = LABEL_RE.match(stripped)
    if m:
        return m.group(1), m.group(2).strip()
    m = ANY_LABEL_RE.match(stripped)
    if m:
        return m.group(1), m.group(2).strip()
    return None, stripped


def find_run_address(lines, run_start, run):
    """Determine the ROM address of a run's first byte.

    Strategy: Look for LABEL_XXXXXX on the first line of the run,
    or on a preceding label-only line. Then count data bytes forward
    to the run start. If any instruction is between the label and
    the run start, return None (unreliable).
    """
    # Check if the first run line has a LABEL_
    first_stripped = lines[run[0]].strip()
    lm = LABEL_RE.match(first_stripped)
    if lm:
        return int(lm.group(1)[6:], 16)

    # Look backwards for a LABEL_ (at most 5 lines)
    for back in range(1, 6):
        idx = run[0] - back
        if idx < 0:
            break
        s = lines[idx].strip()
        lm = LABEL_RE.match(s)
        if lm:
            label_addr = int(lm.group(1)[6:], 16)
            # Count data bytes from this label to run start
            byte_offset = 0
            current_addr = label_addr
            label_data = lm.group(2).strip()
            if label_data:
                bc = data_byte_count(label_data, current_addr)
                if bc is None:
                    return None  # Instruction between label and run
                byte_offset += bc
                current_addr += bc

            for fwd in range(idx + 1, run[0]):
                fs = lines[fwd].strip()
                if not fs:
                    continue
                _, fdata = strip_label(fs)
                if not fdata:
                    continue
                bc = data_byte_count(fdata, current_addr)
                if bc is None:
                    return None  # Instruction between label and run
                byte_offset += bc
                current_addr += bc

            return label_addr + byte_offset

    return None


def process_file(filepath, rom_path, dry_run=False):
    with open(rom_path, 'rb') as f:
        rom = f.read()

    with open(filepath, 'r', encoding='latin-1') as f:
        lines = f.readlines()

    print(f"Loaded {len(lines)} lines, ROM {len(rom)} bytes")

    fixes = []
    skipped_no_addr = 0
    skipped_no_string = 0
    skipped_not_text = 0
    skipped_byte_mismatch = 0
    i = 0

    while i < len(lines):
        stripped = lines[i].strip()
        label_name, data_part = strip_label(stripped)

        # Must start with a string-like directive
        if not is_string_directive(data_part):
            i += 1
            continue

        # Don't start from .asciz or aligned_string (those end strings)
        if data_part.startswith('.asciz ') or data_part.startswith('aligned_string '):
            i += 1
            continue

        # Scan forward to find: [string data...] [instruction] [string end]
        run = [i]  # line indices
        found_instruction = False
        instruction_line = None
        j = i + 1
        max_j = min(j + 8, len(lines))

        while j < max_j:
            s = lines[j].strip()
            if not s:
                j += 1
                continue

            # Any label stops the run
            lbl, sdata = strip_label(s)
            if lbl:
                break

            # String directive continues
            if is_string_directive(sdata):
                # .byte with 0x00 (null) ends the string
                if sdata.startswith('.byte 0x'):
                    byte_vals = [int(m, 16) for m in BYTE_RE.findall(sdata)]
                    if 0x00 in byte_vals:
                        break
                run.append(j)
                j += 1
                if sdata.startswith('aligned_string ') or sdata.startswith('.asciz '):
                    break  # String terminator found
                continue

            # Not a directive — could be an instruction
            if not s.startswith('.') and not s.startswith(';') and not s.startswith('//'):
                if found_instruction:
                    break  # Only allow one instruction
                found_instruction = True
                instruction_line = j
                run.append(j)
                j += 1
                continue

            break

        if not found_instruction or len(run) < 3:
            i += 1
            continue

        # Must end with aligned_string or .asciz
        last_data = strip_label(lines[run[-1]].strip())[1]
        if not (last_data.startswith('aligned_string ') or last_data.startswith('.asciz ')):
            i += 1
            continue

        # Determine ROM address
        addr = find_run_address(lines, run[0], run)
        if addr is None:
            skipped_no_addr += 1
            i += 1
            continue

        rom_offset = addr - ROM_BASE
        if rom_offset < 0 or rom_offset >= len(rom):
            skipped_no_addr += 1
            i += 1
            continue

        # Read ROM string at this address
        k = rom_offset
        while k < len(rom) and rom[k] != 0x00:
            if not can_inline_byte(rom[k]):
                break
            k += 1

        if k >= len(rom) or rom[k] != 0x00:
            skipped_no_string += 1
            i += 1
            continue

        str_bytes = rom[rom_offset:k]
        if not is_real_text_string(str_bytes):
            skipped_not_text += 1
            i += 1
            continue

        decoded = str_bytes.decode('latin-1')
        total_with_null = len(str_bytes) + 1

        # Verify: first data line's bytes must match ROM string start
        ok = True
        first_data_part = strip_label(lines[run[0]].strip())[1]
        first_rom_offset = rom_offset

        if first_data_part.startswith('.byte 0x'):
            byte_vals = [int(m, 16) for m in BYTE_RE.findall(first_data_part)]
            for bi, bv in enumerate(byte_vals):
                if first_rom_offset + bi >= len(rom) or rom[first_rom_offset + bi] != bv:
                    ok = False
                    break
        elif first_data_part.startswith('.ascii '):
            m = QUOTED_STRING_RE.search(first_data_part)
            if m:
                try:
                    ascii_bytes = m.group(1).encode('latin-1')
                except UnicodeEncodeError:
                    ok = False
                if ok:
                    for bi, ab in enumerate(ascii_bytes):
                        if first_rom_offset + bi >= len(rom) or rom[first_rom_offset + bi] != ab:
                            ok = False
                            break

        # Also verify last data line's string matches ROM string end
        if ok:
            last_data_part = strip_label(lines[run[-1]].strip())[1]
            m = QUOTED_STRING_RE.search(last_data_part)
            if m:
                try:
                    end_bytes = m.group(1).encode('latin-1')
                except UnicodeEncodeError:
                    ok = False
                if ok and len(end_bytes) > 0:
                    # The end bytes should match the END of the ROM string
                    end_offset = len(str_bytes) - len(end_bytes)
                    if end_offset < 0:
                        ok = False
                    else:
                        for bi, eb in enumerate(end_bytes):
                            if str_bytes[end_offset + bi] != eb:
                                ok = False
                                break

        if not ok:
            skipped_byte_mismatch += 1
            i += 1
            continue

        # Determine if aligned_string or .asciz
        # aligned_string adds .p2align 1,0xff — pads with 0xFF if total is odd
        use_aligned = False
        pad_rom_offset = rom_offset + total_with_null  # byte after null
        if (addr + total_with_null) % 2 != 0:
            # Odd total — aligned_string would add 0xFF pad
            if pad_rom_offset < len(rom) and rom[pad_rom_offset] == 0xFF:
                use_aligned = True
        # If original last line was aligned_string, keep it unless padding breaks
        elif last_data.startswith('aligned_string '):
            # Even total — aligned_string adds no pad, same as .asciz
            use_aligned = True

        # Build replacement
        if use_aligned:
            directive = f'aligned_string "{decoded}"'
        else:
            directive = f'.asciz "{decoded}"'

        # Preserve label from first line
        first_label = strip_label(lines[run[0]].strip())[0]
        if first_label:
            new_line = f'{first_label}:\t{directive}\n'
        else:
            new_line = f'\t{directive}\n'

        replace_start = run[0]
        replace_end = run[-1] + 1

        fixes.append((replace_start, replace_end, new_line, decoded[:60]))
        i = j

    print(f"\nFound {len(fixes)} fixable bogus instruction sequences")
    print(f"Skipped: {skipped_no_addr} no address, {skipped_no_string} no ROM string, "
          f"{skipped_not_text} not text, {skipped_byte_mismatch} byte mismatch")

    if dry_run:
        for start, end, content, desc in fixes:
            print(f"  Lines {start+1}-{end}: \"{desc}\"")
        print("\n[DRY RUN] No changes written.")
        return

    # Apply fixes in reverse order
    fixes.sort(key=lambda x: x[0], reverse=True)
    for start, end, content, desc in fixes:
        lines[start:end] = [content]

    with open(filepath, 'w', encoding='latin-1') as f:
        f.writelines(lines)

    print(f"Applied {len(fixes)} fixes")


if __name__ == '__main__':
    dry_run = '--dry-run' in sys.argv
    process_file(ASM_FILE, ROM_FILE, dry_run)
