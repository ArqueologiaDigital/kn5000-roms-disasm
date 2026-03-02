#!/usr/bin/env python3
"""Merge interleaved .ascii/.byte sequences into single Latin-1 strings.

Converts patterns like:
    .ascii "voir diminu"
    .byte 0xe9
    .ascii " sa taille en "
Into:
    .ascii "voir diminué sa taille en "

Also merges:
    .ascii "ACCORDION REGISTER eröffnet..."
    aligned_string "nge!"
Into:
    aligned_string "ACCORDION REGISTER eröffnet...nge!"

The assembly file is read/written in Latin-1 encoding so that characters
like é (0xE9) remain as single bytes, not multi-byte UTF-8.

Usage:
    cd /mnt/shared/kn5000-roms-disasm
    python scripts/merge_latin1_strings.py [--dry-run]
"""

import re
import sys

ASM_FILE = 'maincpu/kn5000_v10_program.s'

# Match .ascii "..." or .asciz "..."
ASCII_RE = re.compile(r'^(\t)\.(ascii|asciz)\s+"((?:[^"\\]|\\.)*)"(.*)$')
# Match aligned_string "..."
ALIGNED_STRING_RE = re.compile(r'^(\t)aligned_string\s+"((?:[^"\\]|\\.)*)"(.*)$')
# Match .byte 0xNN, 0xNN, ... (all values)
BYTE_RE = re.compile(r'^\t\.byte\s+((?:0x[0-9a-fA-F]{2}(?:,\s*)?)+)\s*$')


def parse_byte_values(byte_str):
    """Parse '0xe9, 0x20, 0x76' into list of ints."""
    return [int(x.strip(), 16) for x in byte_str.split(',')]


def is_mergeable_byte(b):
    """Check if a byte value can be inlined into a Latin-1 .ascii string."""
    # Printable Latin-1: 0x20-0x7E (ASCII printable) and 0x80-0xFF (Latin-1 upper)
    # Exclude 0x00 (null), 0x22 (double quote), 0x5C (backslash)
    if b == 0x00 or b == 0x22 or b == 0x5C:
        return False
    if 0x20 <= b <= 0x7E:
        return True
    if 0x80 <= b <= 0xFF:
        return True
    return False


def bytes_to_latin1_str(byte_vals):
    """Convert byte values to a Latin-1 string for embedding in .ascii."""
    return bytes(byte_vals).decode('latin-1')


def process_file(filepath, dry_run=False):
    # Read in Latin-1 so bytes 0x80-0xFF stay as single bytes
    with open(filepath, 'r', encoding='latin-1') as f:
        lines = f.readlines()

    print(f"Loaded {len(lines)} lines")

    byte_merged_count = 0
    aligned_merged_count = 0
    new_lines = []
    i = 0

    while i < len(lines):
        # Try to start a merge sequence with .ascii
        m = ASCII_RE.match(lines[i])
        if not m:
            new_lines.append(lines[i])
            i += 1
            continue

        indent = m.group(1)
        directive = m.group(2)  # 'ascii' or 'asciz'
        string_content = m.group(3)
        trailing = m.group(4)  # comment or empty

        # Only merge .ascii (not .asciz - that has null terminator)
        if directive != 'ascii':
            new_lines.append(lines[i])
            i += 1
            continue

        # If there's a trailing comment, don't merge
        if trailing.strip():
            new_lines.append(lines[i])
            i += 1
            continue

        # Look ahead: can we merge with following .byte/.ascii/.asciz/aligned_string?
        j = i + 1
        accumulated = string_content
        did_byte_merge = False
        final_directive = 'ascii'
        final_trailing = ''

        while j < len(lines):
            # Check for .byte line with mergeable values
            bm = BYTE_RE.match(lines[j])
            if bm:
                byte_vals = parse_byte_values(bm.group(1))
                if all(is_mergeable_byte(b) for b in byte_vals):
                    accumulated += bytes_to_latin1_str(byte_vals)
                    did_byte_merge = True
                    j += 1

                    # After .byte, check if next line continues the string
                    if j < len(lines):
                        # Check aligned_string
                        am_aligned = ALIGNED_STRING_RE.match(lines[j])
                        if am_aligned:
                            accumulated += am_aligned.group(2)
                            final_trailing = am_aligned.group(3)
                            final_directive = 'aligned_string'
                            j += 1
                            break

                        # Check .ascii/.asciz
                        am = ASCII_RE.match(lines[j])
                        if am and am.group(2) in ('ascii', 'asciz'):
                            if not am.group(4).strip():
                                accumulated += am.group(3)
                                final_directive = am.group(2)
                                j += 1
                                if am.group(2) == 'asciz':
                                    break
                                continue
                            else:
                                accumulated += am.group(3)
                                final_trailing = am.group(4)
                                final_directive = am.group(2)
                                j += 1
                                break
                    break
                else:
                    break
            else:
                # Check for aligned_string (no preceding .byte merge needed)
                am_aligned = ALIGNED_STRING_RE.match(lines[j])
                if am_aligned:
                    accumulated += am_aligned.group(2)
                    final_trailing = am_aligned.group(3)
                    final_directive = 'aligned_string'
                    j += 1
                    break
                break

        did_merge = did_byte_merge or (final_directive == 'aligned_string')

        if did_merge:
            if did_byte_merge:
                byte_merged_count += 1
            if final_directive == 'aligned_string':
                aligned_merged_count += 1
                line = f'{indent}aligned_string "{accumulated}"{final_trailing}\n'
            else:
                line = f'{indent}.{final_directive} "{accumulated}"{final_trailing}\n'
            new_lines.append(line)
            i = j
        else:
            new_lines.append(lines[i])
            i += 1

    print(f"Merged {byte_merged_count} .ascii/.byte sequences (Latin-1 inlining)")
    print(f"Merged {aligned_merged_count} .ascii + aligned_string sequences")
    total = byte_merged_count + aligned_merged_count
    # Some merges are both (ascii+byte+aligned_string), avoid double-counting
    unique = len(lines) - len(new_lines)
    print(f"Total lines removed: {unique}")

    if dry_run:
        print("[DRY RUN] No changes written.")
        return

    # Write in Latin-1 encoding to preserve single-byte characters
    with open(filepath, 'w', encoding='latin-1') as f:
        f.writelines(new_lines)

    print(f"Written {len(new_lines)} lines (was {len(lines)})")


if __name__ == '__main__':
    dry_run = '--dry-run' in sys.argv
    process_file(ASM_FILE, dry_run)
