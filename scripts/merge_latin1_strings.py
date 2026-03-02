#!/usr/bin/env python3
"""Merge interleaved .ascii/.byte sequences into single Latin-1 .ascii strings.

Converts patterns like:
    .ascii "voir diminu"
    .byte 0xe9
    .ascii " sa taille en "
Into:
    .ascii "voir diminué sa taille en "

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
# Match .byte 0xNN, 0xNN, ... where all bytes are in Latin-1 range (0x80-0xFF)
# or printable ASCII that makes sense to inline
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

    merged_count = 0
    new_lines = []
    i = 0

    while i < len(lines):
        # Try to start a merge sequence with .ascii or .asciz
        m = ASCII_RE.match(lines[i])
        if not m:
            new_lines.append(lines[i])
            i += 1
            continue

        indent = m.group(1)
        directive = m.group(2)  # 'ascii' or 'asciz'
        string_content = m.group(3)
        trailing = m.group(4)  # comment or empty

        # Only merge .ascii followed by .byte (not .asciz - that has null terminator)
        if directive != 'ascii':
            new_lines.append(lines[i])
            i += 1
            continue

        # If there's a trailing comment, don't merge
        if trailing.strip():
            new_lines.append(lines[i])
            i += 1
            continue

        # Look ahead: can we merge with following .byte + .ascii/.asciz lines?
        j = i + 1
        accumulated = string_content
        did_merge = False
        final_directive = 'ascii'

        while j < len(lines):
            # Check for .byte line with mergeable values
            bm = BYTE_RE.match(lines[j])
            if bm:
                byte_vals = parse_byte_values(bm.group(1))
                if all(is_mergeable_byte(b) for b in byte_vals):
                    accumulated += bytes_to_latin1_str(byte_vals)
                    did_merge = True
                    j += 1

                    # After .byte, check if next line is .ascii/.asciz to continue
                    if j < len(lines):
                        am = ASCII_RE.match(lines[j])
                        if am and am.group(2) in ('ascii', 'asciz'):
                            if not am.group(4).strip():
                                # Continue merging
                                accumulated += am.group(3)
                                final_directive = am.group(2)
                                j += 1
                                if am.group(2) == 'asciz':
                                    # .asciz ends the sequence (null terminator)
                                    break
                                continue
                            else:
                                # Has trailing comment - take it but stop
                                accumulated += am.group(3)
                                trailing = am.group(4)
                                final_directive = am.group(2)
                                j += 1
                                break
                    break
                else:
                    break
            else:
                break

        if did_merge:
            merged_count += 1
            line = f'{indent}.{final_directive} "{accumulated}"{trailing}\n'
            new_lines.append(line)
            i = j
        else:
            new_lines.append(lines[i])
            i += 1

    print(f"Merged {merged_count} interleaved .ascii/.byte sequences into Latin-1 strings")

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
