#!/usr/bin/env python3
"""
Convert raw hex byte sequences to string literals in assembly files.

This script identifies sequences of printable ASCII bytes in db statements
and converts them to string literals for better readability.

Example:
    db 043h, 06Fh, 06Eh, 076h, 065h, 072h, 074h, 000h
becomes:
    db "Convert", 000h
"""

import re
import sys
from pathlib import Path


def hex_to_char(hex_str):
    """Convert a hex string like '043h' or '06Fh' to its character if printable."""
    # Remove 'h' suffix and leading zero if present
    hex_str = hex_str.lower().rstrip('h')
    if hex_str.startswith('0'):
        hex_str = hex_str[1:] if len(hex_str) > 1 else hex_str
    try:
        value = int(hex_str, 16)
        if 0x20 <= value <= 0x7E:  # Printable ASCII range
            return chr(value)
    except ValueError:
        pass
    return None


def parse_db_line(line):
    """Parse a db line and return (indent, bytes_list, comment)."""
    # Match: optional whitespace, 'db', bytes, optional comment
    match = re.match(r'^(\s*)(db\s+)(.+?)(\s*;.*)?$', line, re.IGNORECASE)
    if not match:
        return None, None, None

    indent = match.group(1) + match.group(2)
    bytes_part = match.group(3)
    comment = match.group(4) or ''

    # Split bytes by comma, handling potential strings already present
    bytes_list = []
    current = ''
    in_string = False

    for char in bytes_part:
        if char == '"' and not in_string:
            in_string = True
            current += char
        elif char == '"' and in_string:
            in_string = False
            current += char
        elif char == ',' and not in_string:
            if current.strip():
                bytes_list.append(current.strip())
            current = ''
        else:
            current += char

    if current.strip():
        bytes_list.append(current.strip())

    return indent, bytes_list, comment


def convert_bytes_to_string(bytes_list):
    """Convert a list of hex bytes to optimized string + bytes representation."""
    result = []
    current_string = ''

    for b in bytes_list:
        # Check if this is already a string literal
        if b.startswith('"'):
            if current_string:
                result.append(f'"{current_string}"')
                current_string = ''
            result.append(b)
            continue

        # Try to convert hex to printable char
        char = hex_to_char(b)
        if char:
            # Handle special characters that need escaping in strings
            if char == '"':
                # Can't easily embed quote, keep as hex
                if current_string:
                    result.append(f'"{current_string}"')
                    current_string = ''
                result.append(b)
            elif char == '\\':
                # Keep backslash as hex to avoid escape issues
                if current_string:
                    result.append(f'"{current_string}"')
                    current_string = ''
                result.append(b)
            else:
                current_string += char
        else:
            # Non-printable byte, flush current string
            if current_string:
                result.append(f'"{current_string}"')
                current_string = ''
            result.append(b)

    # Flush remaining string
    if current_string:
        result.append(f'"{current_string}"')

    return result


def process_line(line):
    """Process a single line and return the converted version."""
    indent, bytes_list, comment = parse_db_line(line)

    if bytes_list is None:
        return line  # Not a db line

    # Convert bytes to optimized representation
    converted = convert_bytes_to_string(bytes_list)

    # Check if anything changed
    if converted == bytes_list:
        return line  # No change needed

    # Check if we actually have any strings (worth converting)
    # Only convert if we have at least one string of 4+ characters
    # and it looks like meaningful text (not control codes)
    def is_meaningful_string(s):
        if not s.startswith('"') or len(s) < 6:  # 6 = 2 quotes + 4 chars minimum
            return False
        content = s[1:-1]  # Remove quotes
        # Skip strings starting with ~ (likely control codes like ~7f, ~80)
        if content.startswith('~'):
            return False
        # Must have at least some alphabetic characters
        alpha_count = sum(1 for c in content if c.isalpha())
        return alpha_count >= 2

    has_meaningful_string = any(is_meaningful_string(b) for b in converted)
    if not has_meaningful_string:
        return line  # Not worth converting control codes or short strings

    # Rebuild the line
    new_bytes = ', '.join(converted)
    return f"{indent}{new_bytes}{comment}\n"


def process_file(input_path, output_path=None, dry_run=False):
    """Process an assembly file and convert hex bytes to strings."""
    input_path = Path(input_path)

    if output_path is None:
        output_path = input_path
    else:
        output_path = Path(output_path)

    with open(input_path, 'r') as f:
        lines = f.readlines()

    converted_count = 0
    new_lines = []

    for i, line in enumerate(lines):
        new_line = process_line(line)
        if new_line != line:
            converted_count += 1
            if dry_run:
                print(f"Line {i+1}:")
                print(f"  Before: {line.rstrip()}")
                print(f"  After:  {new_line.rstrip()}")
        new_lines.append(new_line)

    if not dry_run and converted_count > 0:
        with open(output_path, 'w') as f:
            f.writelines(new_lines)

    return converted_count


def main():
    if len(sys.argv) < 2:
        print("Usage: python convert_hex_to_strings.py <input.asm> [--dry-run]")
        print("       python convert_hex_to_strings.py --all [--dry-run]")
        sys.exit(1)

    dry_run = '--dry-run' in sys.argv

    if '--all' in sys.argv:
        # Process all assembly files
        files = [
            'maincpu/kn5000_v10_program.asm',
            'subcpu/kn5000_subprogram_v142.asm',
            'hdae5000/hd-ae5000_v2_06i.asm',
            'table_data/kn5000_table_data.asm',
        ]

        total = 0
        for f in files:
            path = Path(f)
            if path.exists():
                count = process_file(path, dry_run=dry_run)
                print(f"{path}: {count} lines converted")
                total += count
            else:
                print(f"{path}: not found, skipping")

        print(f"\nTotal: {total} lines converted")
    else:
        input_file = sys.argv[1]
        if input_file.startswith('--'):
            print("Error: Invalid file path")
            sys.exit(1)

        count = process_file(input_file, dry_run=dry_run)
        print(f"Converted {count} lines")

        if dry_run:
            print("\n(Dry run - no files modified)")


if __name__ == '__main__':
    main()
