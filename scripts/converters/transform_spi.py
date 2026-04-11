#!/usr/bin/env python3
"""Transform SPI/SPD per-register mnemonics to consolidated register-operand form.

Example transformations:
  ld_a_spib 0xE4     →  ld_spib A, 0xE4
  ld_wa_spiw 0xE0    →  ld_spiw WA, 0xE0
  add_xhl_spil 0xEC  →  add_spil XHL, 0xEC
  cp_a_spdb 0xE4     →  cp_spdb A, 0xE4
  cpm_bc_spiw 0xE1   →  cpm_spiw BC, 0xE1
"""
import re
import sys
import os

# Register name mappings by size suffix
SPIB_REGS = {
    'w': 'W', 'a': 'A', 'b': 'B', 'c': 'C',
    'd': 'D', 'e': 'E', 'h': 'H', 'l': 'L',
}
SPIW_REGS = {
    'wa': 'WA', 'bc': 'BC', 'de': 'DE', 'hl': 'HL',
    'ix': 'IX', 'iy': 'IY', 'iz': 'IZ', 'sp': 'SP',
}
SPIL_REGS = {
    'xwa': 'XWA', 'xbc': 'XBC', 'xde': 'XDE', 'xhl': 'XHL',
    'xix': 'XIX', 'xiy': 'XIY', 'xiz': 'XIZ', 'xsp': 'XSP',
}

# Operations: (op_prefix, size_suffix) → (new_mnemonic, reg_map)
SPI_OPS = {
    # SPI 8-bit
    ('ld', 'spib'): ('ld_spib', SPIB_REGS),
    ('add', 'spib'): ('add_spib', SPIB_REGS),
    ('cp', 'spib'): ('cp_spib', SPIB_REGS),
    # SPI 16-bit
    ('ld', 'spiw'): ('ld_spiw', SPIW_REGS),
    ('add', 'spiw'): ('add_spiw', SPIW_REGS),
    ('cp', 'spiw'): ('cp_spiw', SPIW_REGS),
    ('cpm', 'spiw'): ('cpm_spiw', SPIW_REGS),
    # SPI 32-bit
    ('ld', 'spil'): ('ld_spil', SPIL_REGS),
    ('add', 'spil'): ('add_spil', SPIL_REGS),
    # SPD 8-bit
    ('cp', 'spdb'): ('cp_spdb', SPIB_REGS),
}


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

    # Check for per-register operations: op_REG_SUFFIX
    for (op, suffix), (new_mnem, reg_map) in SPI_OPS.items():
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
    root = '/home/fsanches/compartilhado/kn5000-roms-disasm'

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
