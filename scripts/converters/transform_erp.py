#!/usr/bin/env python3
"""Transform ERP per-register mnemonics to consolidated register-operand form.

Example transformations:
  ldto_a_berp 0xFB    →  ldto_berp A, 0xFB
  ldfr_wa_werp 0xE6   →  ldfr_werp WA, 0xE6
  ldi3_berp 0xFB      →  ldi_berp 0xFB, 3
  cpi7_werp 0xFB      →  cpi_werp 0xFB, 7
  mul_xwa_werp 0xFB   →  mul_werp WA, 0xFB
  ex_iz_werp 0xFB     →  ex_werp IZ, 0xFB
"""
import re
import sys
import os

# Register name mappings by size suffix
BERP_REGS = {
    'w': 'W', 'a': 'A', 'b': 'B', 'c': 'C',
    'd': 'D', 'e': 'E', 'h': 'H', 'l': 'L',
}
WERP_REGS = {
    'wa': 'WA', 'bc': 'BC', 'de': 'DE', 'hl': 'HL',
    'ix': 'IX', 'iy': 'IY', 'iz': 'IZ',
}
# MUL/EX use 32-bit names in old mnemonics but 16-bit register class
WERP_REGS_32 = {
    'xwa': 'WA', 'xbc': 'BC', 'xde': 'XDE', 'xhl': 'HL',
    'xix': 'IX', 'xiy': 'IY', 'xiz': 'IZ',
}
LERP_REGS = {
    'xwa': 'XWA', 'xbc': 'XBC', 'xde': 'XDE', 'xhl': 'XHL',
    'xix': 'XIX', 'xiy': 'XIY', 'xiz': 'XIZ', 'xsp': 'XSP',
}

# Operations that have per-register variants (sub-opcode = base + reg_enc)
# Format: (operation_prefix, size_suffix) → new_mnemonic
REG_OPS = {
    # 8-bit (BERP)
    ('ldto', 'berp'): ('ldto_berp', BERP_REGS),
    ('ldfr', 'berp'): ('ldfr_berp', BERP_REGS),
    ('add', 'berp'): ('add_berp', BERP_REGS),
    ('sub', 'berp'): ('sub_berp', BERP_REGS),
    ('and', 'berp'): ('and_berp', BERP_REGS),
    ('or', 'berp'): ('or_berp', BERP_REGS),
    ('cp', 'berp'): ('cp_berp', BERP_REGS),
    # 16-bit (WERP)
    ('ldto', 'werp'): ('ldto_werp', WERP_REGS),
    ('ldfr', 'werp'): ('ldfr_werp', WERP_REGS),
    ('add', 'werp'): ('add_werp', WERP_REGS),
    ('sub', 'werp'): ('sub_werp', WERP_REGS),
    ('and', 'werp'): ('and_werp', WERP_REGS),
    ('or', 'werp'): ('or_werp', WERP_REGS),
    ('cp', 'werp'): ('cp_werp', WERP_REGS),
    ('mul', 'werp'): ('mul_werp', WERP_REGS_32),
    ('ex', 'werp'): ('ex_werp', WERP_REGS),
    # 32-bit (LERP)
    ('ldto', 'lerp'): ('ldto_lerp', LERP_REGS),
    ('ldfr', 'lerp'): ('ldfr_lerp', LERP_REGS),
}

# Small-immediate operations: ldiN → ldi + N, cpiN → cpi + N
SMALL_IMM_OPS = {
    ('ldi', 'berp'): 'ldi_berp',
    ('cpi', 'berp'): 'cpi_berp',
    ('ldi', 'werp'): 'ldi_werp',
    ('cpi', 'werp'): 'cpi_werp',
}

def split_comment(rest):
    """Split operand text from trailing comment. Returns (operands, comment_suffix).
    comment_suffix includes leading whitespace+semicolon, or just newline."""
    # Find first semicolon not inside quotes
    idx = rest.find(';')
    if idx < 0:
        return rest.rstrip('\n'), '\n' if rest.endswith('\n') else ''
    operands = rest[:idx].rstrip()
    # Preserve whitespace before comment (typically a tab)
    ws_start = len(rest[:idx].rstrip())
    whitespace = rest[ws_start:idx]
    if not whitespace:
        whitespace = '\t'  # ensure at least a tab before comment
    comment = whitespace + rest[idx:]  # whitespace + ; + comment text
    return operands, comment


def transform_line(line):
    """Transform a single line, returning the modified line."""
    # Skip empty lines, comments, labels, directives
    stripped = line.lstrip()
    if not stripped or stripped.startswith(('//','#',';','.','@')):
        return line
    # Find instruction mnemonic (first non-whitespace token)
    m = re.match(r'(\s*)(\S+)(.*)', line)
    if not m:
        return line
    indent, mnem, rest = m.group(1), m.group(2), m.group(3)
    mnem_lower = mnem.lower()

    has_newline = line.endswith('\n')

    # Check for per-register operations: op_REG_SIZE
    # Pattern: {op}_{reg}_{berp|werp|lerp}
    for (op, size), (new_mnem, reg_map) in REG_OPS.items():
        for reg_key, reg_name in reg_map.items():
            old_mnem = f"{op}_{reg_key}_{size}"
            if mnem_lower == old_mnem:
                operands, comment = split_comment(rest.lstrip())
                result = f"{indent}{new_mnem} {reg_name}, {operands}{comment}"
                if has_newline and not result.endswith('\n'):
                    result += '\n'
                return result

    # Check for small-immediate operations: ldiN_size or cpiN_size
    for (op, size), new_mnem in SMALL_IMM_OPS.items():
        # Match: ldi0_berp through ldi7_berp, cpi0_werp through cpi7_werp
        m2 = re.match(rf'^{op}(\d)_{size}$', mnem_lower)
        if m2:
            imm_val = int(m2.group(1))
            operands, comment = split_comment(rest.lstrip())
            result = f"{indent}{new_mnem} {operands}, {imm_val}{comment}"
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
    root = '/home/fsanches/compartilhado/kn5000-roms-disasm'

    total_changed = 0
    total_files = 0

    for dirpath, _, filenames in os.walk(root):
        # Skip archive directory
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
