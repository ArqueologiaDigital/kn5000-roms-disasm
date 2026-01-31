#!/usr/bin/env python3
"""
Concatenate fragmented string literals in assembly files.

This script identifies consecutive db lines containing string fragments
and concatenates them into complete, readable strings.

Strings are concatenated until a null terminator (0x00) is reached.
Lines are split at reasonable widths for readability.
"""

import re
import sys
from pathlib import Path


def parse_db_tokens(line):
    """Parse a db line and return list of tokens (strings or hex bytes)."""
    # Match db statement
    match = re.match(r'^(\s*)(db\s+)(.+?)(\s*;.*)?$', line, re.IGNORECASE)
    if not match:
        return None, None, None, None

    indent = match.group(1)
    db_keyword = match.group(2)
    content = match.group(3)
    comment = match.group(4) or ''

    tokens = []
    current = ''
    in_string = False

    i = 0
    while i < len(content):
        char = content[i]

        if char == '"' and not in_string:
            in_string = True
            current += char
        elif char == '"' and in_string:
            in_string = False
            current += char
            tokens.append(current.strip())
            current = ''
        elif char == ',' and not in_string:
            if current.strip():
                tokens.append(current.strip())
            current = ''
        else:
            current += char
        i += 1

    if current.strip():
        tokens.append(current.strip())

    return indent, db_keyword, tokens, comment


def token_to_value(token):
    """Convert a token to its byte value(s). Returns list of (value, is_string_char)."""
    if token.startswith('"') and token.endswith('"'):
        # String literal
        content = token[1:-1]
        return [(ord(c), True) for c in content]
    else:
        # Hex byte like 0FFh or 000h
        token_lower = token.lower().rstrip('h')
        if token_lower.startswith('0'):
            token_lower = token_lower[1:] if len(token_lower) > 1 else token_lower
        try:
            val = int(token_lower, 16)
            # Check if it's a printable ASCII that should be in a string
            is_printable = 0x20 <= val <= 0x7E
            return [(val, is_printable)]
        except ValueError:
            return None  # Not a simple byte


def is_null_terminator(tokens):
    """Check if tokens end with a null terminator."""
    if not tokens:
        return False
    for token in reversed(tokens):
        values = token_to_value(token)
        if values:
            last_val = values[-1][0]
            if last_val == 0x00:
                return True
            elif last_val != 0xFF:  # 0xFF often follows null, skip it
                return False
    return False


def format_string_line(byte_values, max_width=100):
    """Format byte values into a readable db line with strings."""
    if not byte_values:
        return []

    lines = []
    current_line = []
    current_string = ''
    current_width = 0

    def flush_string():
        nonlocal current_string, current_line
        if current_string:
            current_line.append(f'"{current_string}"')
            current_string = ''

    def flush_line():
        nonlocal current_line, lines, current_width
        if current_line:
            lines.append('\tdb ' + ', '.join(current_line))
            current_line = []
            current_width = 0

    for val, is_printable in byte_values:
        # Extended ASCII characters (accented letters) - keep as hex
        if val > 0x7E or val < 0x20:
            flush_string()
            hex_str = f'0{val:02X}h'
            if current_width + len(hex_str) + 2 > max_width:
                flush_line()
            current_line.append(hex_str)
            current_width += len(hex_str) + 2

            # After null terminator, start new line for next string
            if val == 0x00:
                flush_line()
        else:
            # Printable ASCII
            char = chr(val)
            if char == '"':
                # Handle embedded quotes
                flush_string()
                current_line.append('022h')  # Quote as hex
                current_width += 6
            elif char == '\\':
                flush_string()
                current_line.append('05Ch')  # Backslash as hex
                current_width += 6
            else:
                current_string += char
                current_width += 1

            # Check line width
            if current_width > max_width:
                flush_string()
                flush_line()

    flush_string()
    flush_line()

    return lines


def process_region(lines, start_line, end_line=None):
    """Process a region of the file, concatenating string fragments."""
    if end_line is None:
        end_line = len(lines)

    result = []
    i = start_line
    accumulated_bytes = []
    region_start = None
    pending_label = None

    while i < end_line:
        line = lines[i]
        original_line = line

        # Check for label
        label_match = re.match(r'^(LABEL_[A-F0-9]+):\s*(db\s+.+)?$', line)
        if label_match:
            # Flush accumulated bytes before label
            if accumulated_bytes:
                formatted = format_string_line(accumulated_bytes)
                result.extend(formatted)
                accumulated_bytes = []

            label = label_match.group(1)
            rest = label_match.group(2)

            if rest:
                # Label with db on same line
                indent, db_kw, tokens, comment = parse_db_tokens('\t' + rest)
                if tokens:
                    # Add label on its own line
                    result.append(f'{label}:')
                    # Process the db content
                    for token in tokens:
                        values = token_to_value(token)
                        if values:
                            accumulated_bytes.extend(values)
                    if is_null_terminator(tokens):
                        formatted = format_string_line(accumulated_bytes)
                        result.extend(formatted)
                        accumulated_bytes = []
                else:
                    result.append(original_line.rstrip())
            else:
                result.append(original_line.rstrip())
            i += 1
            continue

        # Check for dd (pointer) lines - these break string sequences
        if re.match(r'^\s*dd\s+', line, re.IGNORECASE):
            if accumulated_bytes:
                formatted = format_string_line(accumulated_bytes)
                result.extend(formatted)
                accumulated_bytes = []
            result.append(original_line.rstrip())
            i += 1
            continue

        # Parse db line
        indent, db_kw, tokens, comment = parse_db_tokens(line)

        if tokens is None:
            # Not a db line
            if accumulated_bytes:
                formatted = format_string_line(accumulated_bytes)
                result.extend(formatted)
                accumulated_bytes = []
            result.append(original_line.rstrip())
            i += 1
            continue

        # Accumulate bytes from this line
        for token in tokens:
            values = token_to_value(token)
            if values:
                accumulated_bytes.extend(values)

        # Check if we hit a null terminator
        if is_null_terminator(tokens):
            formatted = format_string_line(accumulated_bytes)
            result.extend(formatted)
            accumulated_bytes = []

        i += 1

    # Flush any remaining bytes
    if accumulated_bytes:
        formatted = format_string_line(accumulated_bytes)
        result.extend(formatted)

    return result


def find_string_regions(lines):
    """Find regions that contain fragmented strings."""
    regions = []
    in_region = False
    region_start = None
    consecutive_db = 0

    for i, line in enumerate(lines):
        is_db = bool(re.match(r'^\s*db\s+', line, re.IGNORECASE))
        is_label_db = bool(re.match(r'^LABEL_[A-F0-9]+:\s*db\s+', line))
        is_dd = bool(re.match(r'^\s*dd\s+', line, re.IGNORECASE))

        if is_db or is_label_db:
            if not in_region:
                region_start = i
                in_region = True
            consecutive_db += 1
        elif is_dd and in_region:
            # dd lines can be within string regions (pointer tables)
            pass
        else:
            if in_region and consecutive_db >= 3:
                # End of a significant region
                regions.append((region_start, i))
            in_region = False
            consecutive_db = 0
            region_start = None

    if in_region and consecutive_db >= 3:
        regions.append((region_start, len(lines)))

    return regions


def process_file(input_path, start_label=None, dry_run=False):
    """Process an assembly file."""
    with open(input_path, 'r') as f:
        lines = f.readlines()

    # Find the starting line if a label is specified
    start_idx = 0
    if start_label:
        for i, line in enumerate(lines):
            if line.startswith(f'{start_label}:'):
                start_idx = i
                break
        else:
            print(f"Label {start_label} not found")
            return 0

    # Find string regions
    regions = find_string_regions(lines[start_idx:])
    regions = [(r[0] + start_idx, r[1] + start_idx) for r in regions]

    if not regions:
        print("No string regions found")
        return 0

    print(f"Found {len(regions)} string regions")

    # Process regions from end to start to preserve line numbers
    new_lines = lines[:]
    total_changes = 0

    for region_start, region_end in reversed(regions):
        print(f"Processing region lines {region_start+1}-{region_end}")

        region_lines = lines[region_start:region_end]
        processed = process_region(lines, region_start, region_end)

        if dry_run:
            print(f"  Would replace {region_end - region_start} lines with {len(processed)} lines")
            for line in processed[:20]:
                print(f"    {line}")
            if len(processed) > 20:
                print(f"    ... and {len(processed) - 20} more lines")
        else:
            # Replace the region
            new_lines[region_start:region_end] = [l + '\n' for l in processed]
            total_changes += 1

    if not dry_run and total_changes > 0:
        with open(input_path, 'w') as f:
            f.writelines(new_lines)

    return total_changes


def main():
    if len(sys.argv) < 2:
        print("Usage: python concatenate_strings.py <file.asm> [--label LABEL] [--dry-run]")
        sys.exit(1)

    input_file = sys.argv[1]
    dry_run = '--dry-run' in sys.argv
    start_label = None

    for i, arg in enumerate(sys.argv):
        if arg == '--label' and i + 1 < len(sys.argv):
            start_label = sys.argv[i + 1]

    changes = process_file(input_file, start_label, dry_run)
    print(f"Processed {changes} regions")

    if dry_run:
        print("\n(Dry run - no files modified)")


if __name__ == '__main__':
    main()
