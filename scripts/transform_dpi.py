#!/usr/bin/env python3
"""Transform DPI (destination post-increment) x_ mnemonics to consolidated register-operand form.

Example transformations:
  x_dpi2_s31 0xF8     →  st_dpib A, 0xF8
  x_dpi2_s43 0xE0     →  lda_dpi XHL, 0xE0
  x_dpi2_s50 0xE0     →  st_dpiw WA, 0xE0
  x_dpi2_s60 0xE6     →  st_dpil XWA, 0xE6

DPI encoding: [F5, base_reg_addr, sub_opcode]
Sub-opcode groups:
  0x30-0x37: LD (r32)+, r8   (byte store)
  0x40-0x47: LDA r32, (r32)+ (load effective address)
  0x50-0x57: LD (r32)+, r16  (word store)
  0x60-0x67: LD (r32)+, r32  (long store)
"""
import re
import sys
import os

# Register names by sub-opcode group
BYTE_REGS = ['W', 'A', 'B', 'C', 'D', 'E', 'H', 'L']   # 0x30-0x37
LONG_REGS = ['XWA', 'XBC', 'XDE', 'XHL', 'XIX', 'XIY', 'XIZ', 'XSP']  # 0x40-0x47
WORD_REGS = ['WA', 'BC', 'DE', 'HL', 'IX', 'IY', 'IZ', 'SP']  # 0x50-0x57
LONG_REGS2 = ['XWA', 'XBC', 'XDE', 'XHL', 'XIX', 'XIY', 'XIZ', 'XSP']  # 0x60-0x67

# Map sub-opcode → (new_mnemonic, register_name)
DPI_MAP = {}
for i, reg in enumerate(BYTE_REGS):
    DPI_MAP[0x30 + i] = ('st_dpib', reg)
for i, reg in enumerate(LONG_REGS):
    DPI_MAP[0x40 + i] = ('lda_dpi', reg)
for i, reg in enumerate(WORD_REGS):
    DPI_MAP[0x50 + i] = ('st_dpiw', reg)
for i, reg in enumerate(LONG_REGS2):
    DPI_MAP[0x60 + i] = ('st_dpil', reg)


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

    # Match x_dpi2_sXX pattern
    m2 = re.match(r'^x_dpi2_s([0-9a-f]{2})$', mnem_lower)
    if m2:
        sub_opc = int(m2.group(1), 16)
        if sub_opc in DPI_MAP:
            new_mnem, reg_name = DPI_MAP[sub_opc]
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
