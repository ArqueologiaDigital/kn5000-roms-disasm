#!/usr/bin/env python3
"""Convert char-by-char string initializers in NAKA C files to ASTR() macros.

Transforms:
  .w18_text = { 'C', 'O', 'N', 'T', 'R', 'O', 'L', 'L', 'E', 'R', 0, 0xFF },
into:
  .w18_text = ASTR("CONTROLLER"),

Only converts pure aligned_string patterns (chars + NUL + optional 0xFF).
Mixed data fields (string + binary) are left unchanged.
"""

import re
import sys
import os


def try_convert_initializer(init_text):
    """Try to convert a { ... } initializer to ASTR() or bare string.

    Returns (new_text, converted) or (None, False) if not convertible.
    """
    # Parse comma-separated values
    vals = [v.strip() for v in init_text.split(',') if v.strip()]

    chars = []
    has_nul = False
    has_pad = False

    for i, v in enumerate(vals):
        if re.match(r"^'(.)'$", v):
            if has_nul:
                return None, False  # char after NUL = not a pure string
            ch = re.match(r"^'(.)'$", v).group(1)
            chars.append(ch)
        elif v in ('0', '0x00'):
            if has_nul:
                return None, False  # double NUL
            has_nul = True
        elif v == '0xFF':
            if not has_nul:
                return None, False  # 0xFF before NUL
            if has_pad:
                return None, False  # double pad
            has_pad = True
        else:
            return None, False  # hex byte or other non-char value

    if not has_nul:
        return None, False

    # Build the string, escaping special C chars
    s = ''
    for ch in chars:
        if ch == '\\':
            s += '\\\\'
        elif ch == '"':
            s += '\\"'
        elif ch == "'":
            s += "'"
        elif ch == '\t':
            s += '\\t'
        elif ch == '\n':
            s += '\\n'
        else:
            # Check if printable ASCII
            if 0x20 <= ord(ch) <= 0x7E:
                s += ch
            else:
                s += f'\\x{ord(ch):02X}'

    if has_pad:
        return f'ASTR("{s}")', True
    else:
        return f'"{s}"', True


def process_file(filepath, dry_run=False):
    with open(filepath, 'r') as f:
        content = f.read()

    # Match patterns like:  .wNN_text = { ... },  or  .wNN_text = { ... }
    # The field name contains _text and the initializer is { ... }
    pattern = re.compile(
        r'(\.\w+_text\s*=\s*)\{([^}]+)\}'
    )

    conversions = 0

    def replacer(m):
        nonlocal conversions
        prefix = m.group(1)
        init = m.group(2)
        new_text, converted = try_convert_initializer(init)
        if converted:
            conversions += 1
            return f'{prefix}{new_text}'
        return m.group(0)  # no change

    new_content = pattern.sub(replacer, content)

    if conversions > 0 and not dry_run:
        with open(filepath, 'w') as f:
            f.write(new_content)

    return conversions


def main():
    dry_run = '--dry-run' in sys.argv

    # Find all struct-based NAKA C files
    widget_dir = os.path.join(os.path.dirname(__file__), '..', 'maincpu', 'ui_widgets')
    c_files = sorted(f for f in os.listdir(widget_dir)
                     if f.startswith('naka_') and f.endswith('.c'))

    total = 0
    for f in c_files:
        filepath = os.path.join(widget_dir, f)
        # Skip raw byte array files (they don't have _text fields)
        with open(filepath) as fh:
            first_lines = fh.read(500)
        if '_text' not in first_lines and 'w1_text' not in first_lines:
            # Quick check if file has any text fields at all
            with open(filepath) as fh:
                if '_text' not in fh.read():
                    continue

        n = process_file(filepath, dry_run)
        if n > 0:
            print(f'  {f}: {n} strings converted')
            total += n

    action = "would convert" if dry_run else "converted"
    print(f'\nTotal: {action} {total} string initializers')


if __name__ == '__main__':
    main()
