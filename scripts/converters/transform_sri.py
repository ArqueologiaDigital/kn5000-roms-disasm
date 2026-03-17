#!/usr/bin/env python3
"""Transform SRI/DRI per-register mnemonics to consolidated register-operand form.

Example transformations:
  ld_a_srib3 0x07, 0xEC, 0xF4    →  ld_srib3 A, 0x07, 0xEC, 0xF4
  ld_wa_sriw1 0x04                →  ld_sriw1 WA, 0x04
  ld_xwa_sril3 0x07, 0xEC, 0xF4  →  ld_sril3 XWA, 0x07, 0xEC, 0xF4
  st_a_dri3 0x07, 0xEC, 0xF4     →  st_dri3b A, 0x07, 0xEC, 0xF4
  st_wa_dri3 0x07, 0xEC, 0xF4    →  st_dri3w WA, 0x07, 0xEC, 0xF4
  st_xwa_dri3 0x07, 0xEC, 0xF4   →  st_dri3l XWA, 0x07, 0xEC, 0xF4
  lda_xhl_dri3 0x07, 0xEC, 0xF4  →  lda_dri3 XHL, 0x07, 0xEC, 0xF4
"""
import re
import sys
import os

# Register name mappings by size
BYTE_REGS = {
    'w': 'W', 'a': 'A', 'b': 'B', 'c': 'C',
    'd': 'D', 'e': 'E', 'h': 'H', 'l': 'L',
}
WORD_REGS = {
    'wa': 'WA', 'bc': 'BC', 'de': 'DE', 'hl': 'HL',
    'ix': 'IX', 'iy': 'IY', 'iz': 'IZ', 'sp': 'SP',
}
LONG_REGS = {
    'xwa': 'XWA', 'xbc': 'XBC', 'xde': 'XDE', 'xhl': 'XHL',
    'xix': 'XIX', 'xiy': 'XIY', 'xiz': 'XIZ', 'xsp': 'XSP',
}

# SRI load operations: (op, sri_suffix) → (new_mnemonic, reg_map)
# Pattern: {op}_{reg}_{sri_suffix} → {new_mnemonic} {REG}, operands
SRI_OPS = {
    # SRI byte-register loads (1 and 3 address bytes)
    ('ld', 'srib3'): ('ld_srib3', BYTE_REGS),
    ('ld', 'srib1'): ('ld_srib1', BYTE_REGS),
    # SRI word-register loads
    ('ld', 'sriw3'): ('ld_sriw3', WORD_REGS),
    ('ld', 'sriw1'): ('ld_sriw1', WORD_REGS),
    # SRI long-register loads
    ('ld', 'sril3'): ('ld_sril3', LONG_REGS),
    ('ld', 'sril1'): ('ld_sril1', LONG_REGS),
}

# DRI store operations: st_{reg}_dri3 → st_dri3{b|w|l} {REG}, operands
# The size suffix depends on the register size
DRI_STORE_OPS = [
    ('st', 'dri3', BYTE_REGS, 'st_dri3b'),   # byte regs → st_dri3b
    ('st', 'dri3', WORD_REGS, 'st_dri3w'),    # word regs → st_dri3w
    ('st', 'dri3', LONG_REGS, 'st_dri3l'),    # long regs → st_dri3l
]

# DRI LDA operations: lda_{reg}_dri3 → lda_dri3 {REG}, operands
DRI_LDA_OPS = [
    ('lda', 'dri3', LONG_REGS, 'lda_dri3'),
]


def split_comment(rest):
    """Split operand text from trailing comment. Returns (operands, comment_suffix)."""
    idx = rest.find(';')
    if idx < 0:
        return rest.rstrip('\n'), '\n' if rest.endswith('\n') else ''
    operands = rest[:idx].rstrip()
    ws_start = len(rest[:idx].rstrip())
    whitespace = rest[ws_start:idx]
    if not whitespace:
        whitespace = '\t'
    comment = whitespace + rest[idx:]
    return operands, comment


def transform_line(line):
    """Transform a single line, returning the modified line."""
    stripped = line.lstrip()
    if not stripped or stripped.startswith(('//', '#', ';', '.', '@')):
        return line
    m = re.match(r'(\s*)(\S+)(.*)', line)
    if not m:
        return line
    indent, mnem, rest = m.group(1), m.group(2), m.group(3)
    mnem_lower = mnem.lower()
    has_newline = line.endswith('\n')

    # Check SRI load operations: ld_{reg}_{sriXN}
    for (op, suffix), (new_mnem, reg_map) in SRI_OPS.items():
        for reg_key, reg_name in reg_map.items():
            old_mnem = f"{op}_{reg_key}_{suffix}"
            if mnem_lower == old_mnem:
                operands, comment = split_comment(rest.lstrip())
                result = f"{indent}{new_mnem} {reg_name}, {operands}{comment}"
                if has_newline and not result.endswith('\n'):
                    result += '\n'
                return result

    # Check DRI store and LDA operations: st_{reg}_dri3, lda_{reg}_dri3
    for op, suffix, reg_map, new_mnem in DRI_STORE_OPS + DRI_LDA_OPS:
        for reg_key, reg_name in reg_map.items():
            old_mnem = f"{op}_{reg_key}_{suffix}"
            if mnem_lower == old_mnem:
                operands, comment = split_comment(rest.lstrip())
                result = f"{indent}{new_mnem} {reg_name}, {operands}{comment}"
                if has_newline and not result.endswith('\n'):
                    result += '\n'
                return result

    return line


def transform_file(filepath, dry_run=False):
    """Transform a single .s file. Returns (changed_count, total_lines)."""
    with open(filepath, 'r') as f:
        lines = f.readlines()

    new_lines = []
    changed = 0
    for line in lines:
        new_line = transform_line(line)
        if new_line != line:
            changed += 1
        new_lines.append(new_line)

    if changed > 0 and not dry_run:
        with open(filepath, 'w') as f:
            f.writelines(new_lines)

    return changed, len(lines)


def main():
    dry_run = '--dry-run' in sys.argv
    root = '/mnt/shared/kn5000-roms-disasm'

    total_changed = 0
    total_files = 0

    for dirpath, _, filenames in os.walk(root):
        if '/archive/' in dirpath:
            continue
        for fn in sorted(filenames):
            if not fn.endswith('.s'):
                continue
            filepath = os.path.join(dirpath, fn)
            changed, lines = transform_file(filepath, dry_run)
            if changed > 0:
                total_files += 1
                total_changed += changed
                if dry_run:
                    print(f"  {filepath}: {changed} changes")

    action = "Would change" if dry_run else "Changed"
    print(f"{action} {total_changed} lines in {total_files} files")


if __name__ == '__main__':
    main()
