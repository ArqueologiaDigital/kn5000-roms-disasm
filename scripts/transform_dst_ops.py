#!/usr/bin/env python3
"""Transform destination-table x_ mnemonics to consolidated register-operand form.

Handles DD8, DD16, DD24, DRI, DPI, DPD categories with destination table sub-opcodes.

Destination table sub-opcode groups:
  0x00: LD (mem), #imm8 (t1)     0x02: LD (mem), #imm16 (t2)
  0x04: POP byte                  0x06: POP word
  0x14: LD (M16),(mem) byte (t2)  0x16: LD (M16),(mem) word (t2)
  0x20-0x27: LDA r16, (mem)      0x2C: STCF A, (mem)
  0x30-0x37: LDA r32, (mem)
  0x40-0x47: LD (mem), r8        0x50-0x57: LD (mem), r16    0x60-0x67: LD (mem), r32
  0x80-0x87: ANDCF #n            0x88-0x8F: ORCF #n
  0x90-0x97: XORCF #n            0x98-0x9F: LDCF #n
  0xA0-0xA7: STCF #n             0xA8-0xAF: TSET #n
  0xB0-0xB7: RES #n              0xB8-0xBF: SET #n
  0xC0-0xC7: CHG #n              0xC8-0xCF: BIT #n
  0xD0-0xDF: JP cc               0xE0-0xEF: CALL cc
"""
import re
import sys
import os

WORD_REGS = ['WA', 'BC', 'DE', 'HL', 'IX', 'IY', 'IZ', 'SP']
LONG_REGS = ['XWA', 'XBC', 'XDE', 'XHL', 'XIX', 'XIY', 'XIZ', 'XSP']
BYTE_REGS = ['W', 'A', 'B', 'C', 'D', 'E', 'H', 'L']

# Condition codes
CC_NAMES = ['F', 'LT', 'LE', 'ULE', 'PE', 'MI', 'Z', 'C',
            'T', 'GE', 'GT', 'UGT', 'PO', 'PL', 'NZ', 'NC']

# Category info: prefix → (is_destination, category_name)
# Destination prefixes: F0=DD8, F1=DD16, F2=DD24, F3=DRI, F4=DPD, F5=DPI
DST_CATEGORIES = {
    'dd8': 'dd8',    # prefix F0
    'dd16': 'dd16',  # prefix F1
    'dd24': 'dd24',  # prefix F2
    'dri': 'dri',    # prefix F3
    'dpi': 'dpi',    # prefix F5
    'dpd': 'dpd',    # prefix F4
}


def decode_dst_simple(cat, sub_opc, nops):
    """Decode a simple (no trailing) destination table sub-opcode.
    Returns (new_mnemonic, extra_operand_prefix) or None."""

    # LDA r16, (mem): 0x20-0x27
    if 0x20 <= sub_opc <= 0x27:
        reg = WORD_REGS[sub_opc & 0x07]
        return (f'lda_{cat}w', f'{reg}, ')

    # STCF A, (mem): 0x2C
    if sub_opc == 0x2C:
        return (f'stcfa_{cat}', '')

    # LDA r32, (mem): 0x30-0x37
    if 0x30 <= sub_opc <= 0x37:
        reg = LONG_REGS[sub_opc & 0x07]
        return (f'lda_{cat}l', f'{reg}, ')

    # LD (mem), r8: 0x40-0x47
    if 0x40 <= sub_opc <= 0x47:
        reg = BYTE_REGS[sub_opc & 0x07]
        return (f'st_{cat}b', f'{reg}, ')

    # LD (mem), r16: 0x50-0x57
    if 0x50 <= sub_opc <= 0x57:
        reg = WORD_REGS[sub_opc & 0x07]
        return (f'st_{cat}w', f'{reg}, ')

    # LD (mem), r32: 0x60-0x67
    if 0x60 <= sub_opc <= 0x67:
        reg = LONG_REGS[sub_opc & 0x07]
        return (f'st_{cat}l', f'{reg}, ')

    # Bit/flag operations with 3-bit modifier
    bit_ops = [
        (0x80, 'andcf'), (0x88, 'orcf'), (0x90, 'xorcf'), (0x98, 'ldcf'),
        (0xA0, 'stcf'), (0xA8, 'tset'), (0xB0, 'res'), (0xB8, 'set'),
        (0xC0, 'chg'), (0xC8, 'bit'),
    ]
    for base, op_name in bit_ops:
        if base <= sub_opc <= base + 7:
            n = sub_opc & 0x07
            return (f'{op_name}_{cat}', f'{n}, ')

    # JP cc, (mem): 0xD0-0xDF — encode cc as numeric operand
    if 0xD0 <= sub_opc <= 0xDF:
        cc = sub_opc & 0x0F
        return (f'jp_{cat}', f'{cc}, ')

    # CALL cc, (mem): 0xE0-0xEF — encode cc as numeric operand
    if 0xE0 <= sub_opc <= 0xEF:
        cc = sub_opc & 0x0F
        return (f'call_{cat}', f'{cc}, ')

    # POP byte: 0x04
    if sub_opc == 0x04:
        return (f'popb_{cat}', '')

    # POP word: 0x06
    if sub_opc == 0x06:
        return (f'popw_{cat}', '')

    return None


def decode_dst_trailing(cat, sub_opc, nops, trailing):
    """Decode a destination table sub-opcode with trailing bytes.
    Returns (new_mnemonic, extra_operand_prefix) or None."""

    # LD (mem), #imm8: sub_opc 0x00, 1 trailing byte
    if sub_opc == 0x00 and trailing == 1:
        return (f'stib_{cat}', '')

    # LD (mem), #imm16: sub_opc 0x02, 2 trailing bytes
    if sub_opc == 0x02 and trailing == 2:
        return (f'stiw_{cat}', '')

    # LD (M16), (mem) byte: sub_opc 0x14, 2 trailing bytes
    if sub_opc == 0x14 and trailing == 2:
        return (f'ldmmb_{cat}', '')

    # LD (M16), (mem) word: sub_opc 0x16, 2 trailing bytes
    if sub_opc == 0x16 and trailing == 2:
        return (f'ldmmw_{cat}', '')

    return None


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

    # Match x_{cat}{nops}_s{hex} pattern (simple sub-opcode, no trailing)
    m2 = re.match(r'^x_(dd8|dd16|dd24|dri|dpi|dpd)(\d+)_s([0-9a-f]{2})$', mnem_lower)
    if m2:
        cat = m2.group(1)
        nops = int(m2.group(2))
        sub_opc = int(m2.group(3), 16)
        result_info = decode_dst_simple(cat, sub_opc, nops)
        if result_info:
            new_mnem, prefix = result_info
            operands, comment = split_comment(rest.lstrip())
            result = f"{indent}{new_mnem} {prefix}{operands}{comment}"
            if has_newline and not result.endswith('\n'):
                result += '\n'
            return result

    # Match x_{cat}{nops}_o{hex}_t{trailing} pattern (sub-opcode + trailing bytes)
    m3 = re.match(r'^x_(dd8|dd16|dd24|dri|dpi|dpd)(\d+)_o([0-9a-f]{2})_t(\d+)$', mnem_lower)
    if m3:
        cat = m3.group(1)
        nops = int(m3.group(2))
        sub_opc = int(m3.group(3), 16)
        trailing = int(m3.group(4))
        result_info = decode_dst_trailing(cat, sub_opc, nops, trailing)
        if result_info:
            new_mnem, prefix = result_info
            operands, comment = split_comment(rest.lstrip())
            result = f"{indent}{new_mnem} {prefix}{operands}{comment}"
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
