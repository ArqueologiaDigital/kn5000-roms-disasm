#!/usr/bin/env python3
"""Convert char array initializers to string literals in C source files.

Transforms: .text = { 'M', 'E', 'A', 'S' }  →  .text = "MEAS"
Leaves alone: LCD_CHAR_*, hex values (0x15), single printable chars like '<'/'>'
"""

import re
import glob
import os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
C_SRC = os.path.join(REPO, 'maincpu', 'c_src')

# Pattern to match char array initializers spanning potentially multiple lines
# Matches: { 'X', 'Y', ... } possibly across lines
CHAR_ARRAY_RE = re.compile(
    r"""(\.(text|label)\s*=\s*)\{([^}]+)\}""",
    re.DOTALL
)

def convert_char_array(match):
    prefix = match.group(1)  # ".text = " or ".label = "
    content = match.group(3).strip()

    # Check if content contains LCD_CHAR or hex values - leave alone
    if 'LCD_CHAR' in content or '0x' in content or '0X' in content:
        return match.group(0)

    # Extract all char literals
    chars = re.findall(r"'(.)'", content)
    if not chars:
        return match.group(0)

    # Build string literal
    text = ''.join(chars)
    return f'{prefix}"{text}"'


def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    new_content = CHAR_ARRAY_RE.sub(convert_char_array, content)

    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        return True
    return False


files = sorted(glob.glob(os.path.join(C_SRC, 'style_ui_*.c')))
changed = 0
for f in files:
    name = os.path.basename(f)
    if process_file(f):
        print(f"  UPDATED: {name}")
        changed += 1
    else:
        print(f"  (no change): {name}")

print(f"\nDone. {changed}/{len(files)} files updated.")
