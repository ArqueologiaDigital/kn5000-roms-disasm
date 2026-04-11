#!/usr/bin/env python3
"""Transform ALL remaining x_ mnemonics to semantic form.

Handles: ERP (C7/D7/E7), SRI source non-ALU (C3/D3), SD8/SD16/SD24 (C0-C2/D0-D2),
SPI (C5).
"""
import re
import sys
import os

BYTE_REGS = ['W', 'A', 'B', 'C', 'D', 'E', 'H', 'L']
WORD_REGS = ['WA', 'BC', 'DE', 'HL', 'IX', 'IY', 'IZ', 'SP']
LONG_REGS = ['XWA', 'XBC', 'XDE', 'XHL', 'XIX', 'XIY', 'XIZ', 'XSP']

# Source table ALU-imm sub-opcodes: 0x38-0x3F
SRC_ALU_IMM = {
    0x38: 'add', 0x39: 'adc', 0x3A: 'sub', 0x3B: 'sbc',
    0x3C: 'and', 0x3D: 'xor', 0x3E: 'or', 0x3F: 'cp',
}

# Source table shift/rotate sub-opcodes: 0x78-0x7F
SRC_SHIFT = {
    0x78: 'rlc', 0x79: 'rrc', 0x7A: 'rl', 0x7B: 'rr',
    0x7C: 'sla', 0x7D: 'sra', 0x7E: 'sll', 0x7F: 'srl',
}

# Source table ALU per-register: 0x80-0xFF (rm=reg,mem  mr=mem,reg)
SRC_ALU_REG = [
    (0x80, 'rm', 'add'), (0x88, 'mr', 'add'),
    (0x90, 'rm', 'adc'), (0x98, 'mr', 'adc'),
    (0xA0, 'rm', 'sub'), (0xA8, 'mr', 'sub'),
    (0xB0, 'rm', 'sbc'), (0xB8, 'mr', 'sbc'),
    (0xC0, 'rm', 'and'), (0xC8, 'mr', 'and'),
    (0xD0, 'rm', 'xor'), (0xD8, 'mr', 'xor'),
    (0xE0, 'rm', 'or'),  (0xE8, 'mr', 'or'),
    (0xF0, 'rm', 'cp'),  (0xF8, 'mr', 'cp'),
]

# ERP register prefix second-byte table: sub-opcodes with trailing byte
ERP_IMM_AFTER = {
    0x03: 'ldi',     # LD r, #imm
    0x08: 'mul',     # MUL r, #imm
    0x09: 'muls',    # MULS r, #imm
    0x0A: 'div',     # DIV r, #imm
    0x0B: 'divs',    # DIVS r, #imm
    0x20: 'andcf',   # ANDCF #n, r
    0x21: 'orcf',    # ORCF #n, r
    0x22: 'xorcf',   # XORCF #n, r
    0x23: 'ldcf',    # LDCF #n, r
    0x24: 'stcf',    # STCF #n, r
    0x30: 'res',     # RES #n, r
    0x31: 'set',     # SET #n, r
    0x32: 'chg',     # CHG #n, r
    0x33: 'bit',     # BIT #n, r
    0x34: 'tset',    # TSET #n, r
    0xC8: 'add',     # ADD r, #imm
    0xC9: 'adc',     # ADC r, #imm
    0xCA: 'sub',     # SUB r, #imm
    0xCB: 'sbc',     # SBC r, #imm
    0xCC: 'and',     # AND r, #imm
    0xCD: 'xor',     # XOR r, #imm
    0xCE: 'or',      # OR r, #imm
    0xCF: 'cp',      # CP r, #imm
    0xE8: 'rlc',     # RLC #n, r
    0xE9: 'rrc',     # RRC #n, r
    0xEA: 'rl',      # RL #n, r
    0xEB: 'rr',      # RR #n, r
    0xEC: 'sla',     # SLA #n, r
    0xED: 'sra',     # SRA #n, r
    0xEE: 'sll',     # SLL #n, r
    0xEF: 'srl',     # SRL #n, r
}

# ERP register-register sub-opcode bases
ERP_REG_REG = [
    (0x80, 'add'), (0x88, 'ld'), (0x90, 'adc'), (0x98, 'ld2'),
    (0xA0, 'sub'), (0xB0, 'sbc'), (0xB8, 'ex'),
    (0xC0, 'and'), (0xD0, 'xor'), (0xE0, 'or'), (0xF0, 'cp'),
]

# ERP small-immediate bases
ERP_SMALL_IMM = [
    (0xA8, 'ldi3'),  # LD r, #I3 (quick load)
    (0xD8, 'cpi3'),  # CP r, #I3 (quick compare)
]

# ERP unary sub-opcodes
ERP_UNARY = {
    0x04: 'push', 0x05: 'pop', 0x06: 'cpl', 0x07: 'neg',
    0x0C: 'link', 0x0D: 'unlk',
    0x0E: 'bs1f', 0x0F: 'bs1b',
    0x10: 'daa',
    0x1C: 'djnz',  # actually has trailing disp8
}


def get_regs_for_size(size_char):
    if size_char == 'b':
        return BYTE_REGS
    elif size_char == 'w':
        return WORD_REGS
    elif size_char == 'l':
        return LONG_REGS
    return None


def decode_erp(size_char, nops, sub_opc, trailing):
    """Decode ERP sub-opcode. Returns (new_mnemonic, extra_prefix) or None."""
    cat = f'erp{size_char}'

    if trailing > 0:
        # Check if sub_opc is in the ERPImmAfter table
        if sub_opc in ERP_IMM_AFTER:
            op_name = ERP_IMM_AFTER[sub_opc]
            return (f'{op_name}_{cat}', '')
        return None

    # No trailing bytes — simple sub-opcode
    # Check ERP unary
    if sub_opc in ERP_UNARY:
        op_name = ERP_UNARY[sub_opc]
        return (f'{op_name}_{cat}', '')

    # Check register-register
    regs = get_regs_for_size(size_char)
    for base, op_name in ERP_REG_REG:
        if base <= sub_opc <= base + 7:
            reg_idx = sub_opc & 0x07
            reg_name = regs[reg_idx] if regs else str(reg_idx)
            return (f'{op_name}_{cat}_rr', f'{reg_name}, ')

    # Check small immediate
    for base, op_name in ERP_SMALL_IMM:
        if base <= sub_opc <= base + 7:
            imm3 = sub_opc & 0x07
            return (f'{op_name}_{cat}', f'{imm3}, ')

    return None


def decode_src_simple(cat, size_char, sub_opc):
    """Decode source-table simple sub-opcode (no trailing).
    Returns (new_mnemonic, extra_prefix) or None."""

    # PUSH: 0x04
    if sub_opc == 0x04:
        return (f'push_{cat}', '')

    # RLD/RRD: 0x06/0x07 (byte only)
    if sub_opc == 0x06:
        return (f'rld_{cat}', '')
    if sub_opc == 0x07:
        return (f'rrd_{cat}', '')

    # LD register (0x20-0x27)
    if 0x20 <= sub_opc <= 0x27:
        regs = get_regs_for_size(size_char)
        reg_idx = sub_opc & 0x07
        reg_name = regs[reg_idx] if regs else str(reg_idx)
        return (f'ld_{cat}', f'{reg_name}, ')

    # EX (mem), r (0x30-0x37)
    if 0x30 <= sub_opc <= 0x37:
        regs = get_regs_for_size(size_char)
        reg_idx = sub_opc & 0x07
        reg_name = regs[reg_idx] if regs else str(reg_idx)
        return (f'ex_{cat}', f'{reg_name}, ')

    # MUL/MULS (0x40-0x4F)
    if 0x40 <= sub_opc <= 0x47:
        reg_idx = sub_opc & 0x07
        return (f'mul_{cat}', f'{reg_idx}, ')
    if 0x48 <= sub_opc <= 0x4F:
        reg_idx = sub_opc & 0x07
        return (f'muls_{cat}', f'{reg_idx}, ')

    # DIV/DIVS (0x50-0x5F)
    if 0x50 <= sub_opc <= 0x57:
        reg_idx = sub_opc & 0x07
        return (f'div_{cat}', f'{reg_idx}, ')
    if 0x58 <= sub_opc <= 0x5F:
        reg_idx = sub_opc & 0x07
        return (f'divs_{cat}', f'{reg_idx}, ')

    # INC (0x60-0x67): count = bits[2:0]
    if 0x60 <= sub_opc <= 0x67:
        count = sub_opc & 0x07
        return (f'inc_{cat}', f'{count}, ')

    # DEC (0x68-0x6F)
    if 0x68 <= sub_opc <= 0x6F:
        count = sub_opc & 0x07
        return (f'dec_{cat}', f'{count}, ')

    # Shift/rotate (0x78-0x7F)
    if sub_opc in SRC_SHIFT:
        return (f'{SRC_SHIFT[sub_opc]}_{cat}', '')

    # ALU per-register (0x80-0xFF)
    for base, direction, op_name in SRC_ALU_REG:
        if base <= sub_opc <= base + 7:
            regs = get_regs_for_size(size_char)
            reg_idx = sub_opc & 0x07
            reg_name = regs[reg_idx] if regs else str(reg_idx)
            return (f'{op_name}_{cat}_{direction}', f'{reg_name}, ')

    return None


def decode_src_trailing(cat, size_char, sub_opc, trailing):
    """Decode source-table sub-opcode with trailing bytes.
    Returns (new_mnemonic, extra_prefix) or None."""

    # ALU (mem), #imm: 0x38-0x3F
    if sub_opc in SRC_ALU_IMM:
        return (f'{SRC_ALU_IMM[sub_opc]}_{cat}_im', '')

    # LD (M16), (mem): 0x19
    if sub_opc == 0x19:
        return (f'ldmm_{cat}', '')

    # LDI/LDIR/LDD/LDDR/CPI/CPIR/CPD/CPDR: 0x10-0x17
    ldi_ops = {
        0x10: 'ldi', 0x11: 'ldir', 0x12: 'ldd', 0x13: 'lddr',
        0x14: 'cpi', 0x15: 'cpir', 0x16: 'cpd', 0x17: 'cpdr',
    }
    if sub_opc in ldi_ops:
        return (f'{ldi_ops[sub_opc]}_{cat}', '')

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

    # Match ERP: x_erp{b|w|l}{nops}_s{hex} or x_erp{b|w|l}{nops}_o{hex}_t{trailing}
    m2 = re.match(r'^x_erp([bwl])(\d+)_s([0-9a-f]{2})$', mnem_lower)
    if m2:
        size_char, nops, sub_hex = m2.group(1), int(m2.group(2)), m2.group(3)
        sub_opc = int(sub_hex, 16)
        result_info = decode_erp(size_char, nops, sub_opc, 0)
        if result_info:
            new_mnem, prefix = result_info
            operands, comment = split_comment(rest.lstrip())
            result = f"{indent}{new_mnem} {prefix}{operands}{comment}"
            if has_newline and not result.endswith('\n'):
                result += '\n'
            return result

    m3 = re.match(r'^x_erp([bwl])(\d+)_o([0-9a-f]{2})_t(\d+)$', mnem_lower)
    if m3:
        size_char = m3.group(1)
        nops = int(m3.group(2))
        sub_opc = int(m3.group(3), 16)
        trailing = int(m3.group(4))
        result_info = decode_erp(size_char, nops, sub_opc, trailing)
        if result_info:
            new_mnem, prefix = result_info
            operands, comment = split_comment(rest.lstrip())
            result = f"{indent}{new_mnem} {prefix}{operands}{comment}"
            if has_newline and not result.endswith('\n'):
                result += '\n'
            return result

    # Match SRI/SD8/SD16/SD24/SPI source-table simple: x_{cat}{nops}_s{hex}
    m4 = re.match(r'^x_(srib|sriw|sril|sd8b|sd16b|sd16w|sd24b|sd24w|spib|spiw|spil|spdb)(\d+)_s([0-9a-f]{2})$', mnem_lower)
    if m4:
        cat = m4.group(1)
        nops = int(m4.group(2))
        sub_opc = int(m4.group(3), 16)
        # Determine size char from category
        if cat.endswith('b'):
            size_char = 'b'
        elif cat.endswith('w'):
            size_char = 'w'
        elif cat.endswith('l'):
            size_char = 'l'
        else:
            size_char = 'b'
        result_info = decode_src_simple(cat, size_char, sub_opc)
        if result_info:
            new_mnem, prefix = result_info
            operands, comment = split_comment(rest.lstrip())
            result = f"{indent}{new_mnem} {prefix}{operands}{comment}"
            if has_newline and not result.endswith('\n'):
                result += '\n'
            return result

    # Match SRI/SD/SPI source-table with trailing: x_{cat}{nops}_o{hex}_t{trailing}
    m5 = re.match(r'^x_(srib|sriw|sril|sd8b|sd16b|sd16w|sd24b|sd24w|spib|spiw|spil|spdb)(\d+)_o([0-9a-f]{2})_t(\d+)$', mnem_lower)
    if m5:
        cat = m5.group(1)
        nops = int(m5.group(2))
        sub_opc = int(m5.group(3), 16)
        trailing = int(m5.group(4))
        if cat.endswith('b'):
            size_char = 'b'
        elif cat.endswith('w'):
            size_char = 'w'
        elif cat.endswith('l'):
            size_char = 'l'
        else:
            size_char = 'b'
        result_info = decode_src_trailing(cat, size_char, sub_opc, trailing)
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
