#!/usr/bin/env python3
"""Fix incorrectly split aligned_string / .asciz directives.

Pattern: A .byte line ending with printable ASCII bytes after the last 0xFF,
immediately followed by an aligned_string or .asciz whose first characters
are missing (they were placed as raw hex on the .byte line).

Fix: Move those ASCII bytes from the .byte line into the string directive.

Example:
  Before:
    .byte 0xff, 0x43, 0x4f
    aligned_string "NCERT REVERB 2"
  After:
    .byte 0xff
    aligned_string "CONCERT REVERB 2"
"""

import re
import sys


def parse_byte_line(line):
    """Parse a .byte line, returning (prefix_whitespace, values_list, comment_str).
    values_list contains tuples of (original_text, int_value).
    Returns None if not a .byte line."""
    stripped = line.strip()
    if not stripped.startswith('.byte '):
        return None

    # Get leading whitespace
    prefix = line[:len(line) - len(line.lstrip())]

    # Split off comment
    rest = stripped[6:]  # after '.byte '
    comment = ''
    # Handle comments - but be careful about strings
    if ';' in rest:
        idx = rest.index(';')
        comment = rest[idx:]
        rest = rest[:idx]

    rest = rest.strip()
    if not rest:
        return None

    raw_vals = [v.strip() for v in rest.split(',')]
    values = []
    for rv in raw_vals:
        try:
            values.append((rv, int(rv, 16)))
        except ValueError:
            values.append((rv, -1))

    return prefix, values, comment


def find_last_ff(values):
    """Find the index of the last 0xFF in values list."""
    for i in range(len(values) - 1, -1, -1):
        if values[i][1] == 0xff:
            return i
    return -1


def extract_ascii_after_ff(values):
    """Extract printable ASCII bytes after the last 0xFF.
    Returns (remaining_values, ascii_chars) or None if no match."""
    last_ff = find_last_ff(values)
    if last_ff == -1:
        return None

    after = values[last_ff + 1:]
    if not after:
        return None

    # Check all bytes after last 0xFF are printable ASCII
    for _, val in after:
        if val < 0x20 or val > 0x7e:
            return None

    ascii_chars = ''.join(chr(v) for _, v in after)
    remaining = values[:last_ff + 1]
    return remaining, ascii_chars


def extract_string_content(line):
    """Extract the string content from aligned_string or .asciz directive.
    Returns (directive, string_content, has_label_prefix, label_prefix) or None."""
    stripped = line.strip()

    # Check for label prefix on same line (e.g., "LABEL:\taligned_string ...")
    label_prefix = ''
    working = stripped
    if ':' in stripped:
        # Could be a label:directive on same line
        parts = stripped.split(':', 1)
        # Check if after the colon we have a directive
        after_colon = parts[1].strip()
        if after_colon.startswith('aligned_string ') or after_colon.startswith('.asciz '):
            label_prefix = parts[0] + ':'
            working = after_colon

    if working.startswith('aligned_string '):
        directive = 'aligned_string'
        rest = working[len('aligned_string '):]
    elif working.startswith('.asciz '):
        directive = '.asciz'
        rest = working[len('.asciz '):]
    else:
        return None

    # Extract string between quotes
    rest = rest.strip()
    if rest.startswith('"') and rest.endswith('"'):
        content = rest[1:-1]
        return directive, content, bool(label_prefix), label_prefix

    return None


def rebuild_byte_line(prefix, remaining_values):
    """Rebuild a .byte line from remaining values."""
    if not remaining_values:
        return None  # Line should be removed
    vals_str = ', '.join(rv for rv, _ in remaining_values)
    return f'{prefix}.byte {vals_str}\n'


def rebuild_string_line(line, directive, new_content, label_prefix=''):
    """Rebuild a string directive line preserving original formatting."""
    prefix = line[:len(line) - len(line.lstrip())]
    if label_prefix:
        # Find original formatting between label and directive
        stripped = line.strip()
        colon_idx = stripped.index(':')
        between = stripped[colon_idx + 1:stripped.index(directive)]
        return f'{prefix}{label_prefix}{between}{directive} "{new_content}"\n'
    else:
        return f'{prefix}{directive} "{new_content}"\n'


def fix_split_strings(filepath, dry_run=False):
    """Fix all split string instances in a file."""
    with open(filepath) as f:
        lines = f.readlines()

    fixes = []
    i = 0
    while i < len(lines):
        parsed = parse_byte_line(lines[i])
        if parsed is None:
            i += 1
            continue

        prefix, values, comment = parsed

        result = extract_ascii_after_ff(values)
        if result is None:
            i += 1
            continue

        remaining, ascii_chars = result

        # Find next non-empty line
        next_idx = i + 1
        while next_idx < len(lines) and lines[next_idx].strip() == '':
            next_idx += 1

        if next_idx >= len(lines):
            i += 1
            continue

        # Check if next non-empty line is a string directive
        string_info = extract_string_content(lines[next_idx])
        if string_info is None:
            # Check if it's a label followed by a string directive
            next_stripped = lines[next_idx].strip()
            if next_stripped.endswith(':'):
                # Label on its own line - skip this case (only 1 instance)
                i += 1
                continue
            i += 1
            continue

        directive, old_content, has_label, label_prefix = string_info
        new_content = ascii_chars + old_content

        fixes.append({
            'byte_line': i,
            'string_line': next_idx,
            'old_byte': lines[i].rstrip(),
            'old_string': lines[next_idx].rstrip(),
            'ascii_moved': ascii_chars,
            'new_content': new_content,
            'remaining_values': remaining,
            'prefix': prefix,
            'directive': directive,
            'label_prefix': label_prefix,
        })

        i = next_idx + 1

    if dry_run:
        print(f'Found {len(fixes)} split strings to fix')
        for fix in fixes[:10]:
            print(f"\n  Line {fix['byte_line']+1}: {fix['old_byte']}")
            print(f"  Line {fix['string_line']+1}: {fix['old_string']}")
            print(f"  Moving '{fix['ascii_moved']}' → {fix['directive']} \"{fix['new_content']}\"")
        if len(fixes) > 10:
            print(f'\n  ... and {len(fixes) - 10} more')
        return len(fixes)

    # Apply fixes in reverse order to preserve line numbers
    for fix in reversed(fixes):
        byte_idx = fix['byte_line']
        str_idx = fix['string_line']

        # Rebuild string line
        lines[str_idx] = rebuild_string_line(
            lines[str_idx],
            fix['directive'],
            fix['new_content'],
            fix['label_prefix']
        )

        # Rebuild or remove byte line
        new_byte = rebuild_byte_line(fix['prefix'], fix['remaining_values'])
        if new_byte is None:
            del lines[byte_idx]
        else:
            lines[byte_idx] = new_byte

    with open(filepath, 'w') as f:
        f.writelines(lines)

    print(f'Fixed {len(fixes)} split strings')
    return len(fixes)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f'Usage: {sys.argv[0]} <file.s> [--dry-run]')
        sys.exit(1)

    filepath = sys.argv[1]
    dry_run = '--dry-run' in sys.argv

    fix_split_strings(filepath, dry_run=dry_run)
