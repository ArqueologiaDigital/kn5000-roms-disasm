#!/usr/bin/env python3
"""Clean up C source files:
1. Remove redundant /* [...] */ comments (index comments that repeat struct data)
2. Convert hex x/y coordinates to decimal
3. Remove redundant trailing inline comments in screendata_main.c
"""

import re
import glob
import os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
C_SRC = os.path.join(REPO, 'maincpu', 'style_ui')


def remove_index_comments(content):
    """Remove lines that are just /* [N] ... */ index comments."""
    lines = content.split('\n')
    out = []
    for line in lines:
        stripped = line.strip()
        # Match: /* [0] STRING "MEAS" at (25,31) */
        # Match: /* [0-3] YES button */
        # Match: /* [0] UNKNOWN_23 */
        # Match: /* [0] MESSAGE "Are You Sure?" at (56, 17) */
        # Match: /* [0] LABELED_REF "YES" */
        # Match: /* [0] SHORT_REF */
        # Match: /* [0] SHORT_REF "STEP RECORD:" at (51,0) */
        # Match: /* [0] FILLED_RECT (5,210)-(35,236) */
        # Match: /* [0] HLINE (5,223)-(35,223) */
        # Match: /* [0-1] YES selection box */
        # Match: /* [0] STRING "|" at (225,32) — up arrow */
        # Match: /* [0] STRING "~" at (233,34) — down arrow */
        # Match: /* [0] "Are You Sure?" prompt */
        if re.match(r'^\s*/\*\s*\[\d+', stripped):
            continue
        out.append(line)
    return '\n'.join(out)


def remove_redundant_trailing_comments(content):
    """Remove trailing comments that just repeat coordinate/addr data from the struct."""
    # Pattern: },  /* (10,35)-(39,35) */
    content = re.sub(r'\s*/\*\s*\(\d+,\d+\)-\(\d+,\d+\)\s*\*/', '', content)
    # Pattern: },  /* addr=0x04b5 param=21 */
    content = re.sub(r'\s*/\*\s*addr=0x[0-9a-fA-F]+\s*param=\d+\s*\*/', '', content)
    return content


def hex_to_dec_xy(content):
    """Convert .x = 0xNN and .y = 0xNN to decimal."""
    def hex_field_to_dec(match):
        prefix = match.group(1)  # ".x = " or ".y = "
        value = int(match.group(2), 16)
        return f'{prefix}{value}'

    # Match .x = 0xNN or .y = 0xNN (but not .x inside nested structs like .p1 = { .x = N })
    content = re.sub(r'(\.[xy]\s*=\s*)0x([0-9a-fA-F]+)', hex_field_to_dec, content)
    return content


def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    new_content = content
    new_content = remove_index_comments(new_content)
    new_content = remove_redundant_trailing_comments(new_content)
    new_content = hex_to_dec_xy(new_content)

    # Clean up double blank lines left by comment removal
    while '\n\n\n' in new_content:
        new_content = new_content.replace('\n\n\n', '\n\n')

    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        return True
    return False


files = sorted(glob.glob(os.path.join(C_SRC, '*.c')) +
               glob.glob(os.path.join(C_SRC, 'paramblock', '*.c')))
changed = 0
for f in files:
    name = os.path.basename(f)
    if process_file(f):
        print(f"  UPDATED: {name}")
        changed += 1
    else:
        print(f"  (no change): {name}")

print(f"\nDone. {changed}/{len(files)} files updated.")
