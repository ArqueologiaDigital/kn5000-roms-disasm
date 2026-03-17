#!/usr/bin/env python3
"""Transform SRI per-register ALU mnemonics to consolidated register-operand form.

Example transformations:
  x_srib4_s89 0x07, 0xEC, 0xF4  →  add_srib_mr A, 0x07, 0xEC, 0xF4
  x_sriw4_s82 0x07, 0xEC, 0xF4  →  add_sriw_rm DE, 0x07, 0xEC, 0xF4
  x_sril4_sf0 0x07, 0xEC, 0xF4  →  cp_sril_rm XWA, 0x07, 0xEC, 0xF4

Source table sub-opcodes 0x80-0xFF:
  0x80-0x87: ADD r,(mem)  0x88-0x8F: ADD (mem),r
  0x90-0x97: ADC r,(mem)  0x98-0x9F: ADC (mem),r
  0xA0-0xA7: SUB r,(mem)  0xA8-0xAF: SUB (mem),r
  0xB0-0xB7: SBC r,(mem)  0xB8-0xBF: SBC (mem),r
  0xC0-0xC7: AND r,(mem)  0xC8-0xCF: AND (mem),r
  0xD0-0xD7: XOR r,(mem)  0xD8-0xDF: XOR (mem),r
  0xE0-0xE7: OR r,(mem)   0xE8-0xEF: OR (mem),r
  0xF0-0xF7: CP r,(mem)   0xF8-0xFF: CP (mem),r
"""
import re
import sys
import os

# Register names by size
BYTE_REGS = ['W', 'A', 'B', 'C', 'D', 'E', 'H', 'L']
WORD_REGS = ['WA', 'BC', 'DE', 'HL', 'IX', 'IY', 'IZ', 'SP']
LONG_REGS = ['XWA', 'XBC', 'XDE', 'XHL', 'XIX', 'XIY', 'XIZ', 'XSP']

# ALU operation table: (base_sub_opc, direction, op_name)
ALU_OPS = [
    (0x80, 'rm', 'add'),
    (0x88, 'mr', 'add'),
    (0x90, 'rm', 'adc'),
    (0x98, 'mr', 'adc'),
    (0xA0, 'rm', 'sub'),
    (0xA8, 'mr', 'sub'),
    (0xB0, 'rm', 'sbc'),
    (0xB8, 'mr', 'sbc'),
    (0xC0, 'rm', 'and'),
    (0xC8, 'mr', 'and'),
    (0xD0, 'rm', 'xor'),
    (0xD8, 'mr', 'xor'),
    (0xE0, 'rm', 'or'),
    (0xE8, 'mr', 'or'),
    (0xF0, 'rm', 'cp'),
    (0xF8, 'mr', 'cp'),
]

# Build mapping: (size_suffix, sub_opcode) → (new_mnemonic, reg_name)
ALU_MAP = {}
for size_suffix, regs in [('b', BYTE_REGS), ('w', WORD_REGS), ('l', LONG_REGS)]:
    for base, direction, op_name in ALU_OPS:
        for i, reg in enumerate(regs):
            sub_opc = base + i
            new_mnem = f"{op_name}_sri{size_suffix}_{direction}"
            ALU_MAP[(size_suffix, sub_opc)] = (new_mnem, reg)


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

    # Match x_sri{b|w|l}4_s{hex} pattern (4-operand SRI ALU)
    m2 = re.match(r'^x_sri([bwl])4_s([0-9a-f]{2})$', mnem_lower)
    if m2:
        size_char = m2.group(1)
        sub_opc = int(m2.group(2), 16)
        key = (size_char, sub_opc)
        if key in ALU_MAP:
            new_mnem, reg_name = ALU_MAP[key]
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
