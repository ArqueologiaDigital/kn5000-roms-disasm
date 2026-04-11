#!/usr/bin/env python3
"""
convert_code_bytes.py — Convert .byte code blocks to native TLCS-900 mnemonics.

Uses MAME's unidasm for authoritative TLCS-900 decoding, then maps the decoded
instructions to LLVM assembly mnemonics. Verifies each conversion via round-trip
with llvm-mc --show-encoding.

Usage:
    python scripts/convert_code_bytes.py --file <path> [--dry-run] [--verbose]
    python scripts/convert_code_bytes.py --all [--dry-run] [--verbose]
"""

import os
import re
import sys
import struct
import subprocess
import tempfile
import argparse
from pathlib import Path
from collections import defaultdict

LLVM_MC = "/home/fsanches/compartilhado/llvm-project/build/bin/llvm-mc"
UNIDASM = "/home/fsanches/compartilhado/tools/unidasm"
REPO_ROOT = Path("/home/fsanches/compartilhado/kn5000-roms-disasm")

BYTE_LINE_RE = re.compile(r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+)', re.IGNORECASE)
BYTE_VAL_RE = re.compile(r'0x([0-9a-fA-F]{2})')
LABEL_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)\s*:')

# Map from unidasm mnemonic patterns to LLVM mnemonic templates
# These handle the size/addressing differences between unidasm and LLVM output
# Format: (unidasm_regex, llvm_template_func)

# Register name mappings (unidasm uses uppercase)
UC_TO_LC = str.maketrans('ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')


def parse_bytes_from_line(line):
    """Extract bytes from a .byte directive line."""
    m = BYTE_LINE_RE.match(line)
    if not m:
        return None
    vals = BYTE_VAL_RE.findall(m.group(1))
    return [int(v, 16) for v in vals]


def unidasm_decode(raw_bytes, base_pc=0):
    """Decode bytes using MAME's unidasm. Returns list of (offset, size, mnemonic)."""
    with tempfile.NamedTemporaryFile(suffix='.bin', delete=False) as f:
        f.write(bytes(raw_bytes))
        tmppath = f.name

    try:
        result = subprocess.run(
            [UNIDASM, tmppath, '-arch', 'tlcs900', '-basepc', f'{base_pc:x}'],
            capture_output=True, text=True, timeout=10
        )
    except (subprocess.TimeoutExpired, FileNotFoundError) as e:
        os.unlink(tmppath)
        return []
    finally:
        try:
            os.unlink(tmppath)
        except:
            pass

    instructions = []
    for line in result.stdout.splitlines():
        # Format: "f96d72: 3e              push XIZ"
        m = re.match(r'([0-9a-f]+):\s+((?:[0-9a-f]{2}\s)+)\s+(.+)$', line.strip())
        if m:
            addr = int(m.group(1), 16)
            hex_bytes = m.group(2).strip().split()
            nbytes = len(hex_bytes)
            mnemonic = m.group(3).strip()
            offset = addr - base_pc
            instructions.append((offset, nbytes, mnemonic))

    return instructions


def unidasm_to_llvm(mnemonic, raw_bytes, offset, nbytes):
    """Convert a unidasm mnemonic to an LLVM assembly mnemonic.

    Returns the LLVM mnemonic string, or None if conversion is not possible.
    """
    # Bounds check — ensure all bytes for this instruction are accessible
    if offset + nbytes > len(raw_bytes):
        return None

    parts = mnemonic.split(None, 1)
    op = parts[0].lower()
    args = parts[1] if len(parts) > 1 else ''

    # Normalize register names to lowercase
    args_lc = args.translate(UC_TO_LC)

    # Simple 1:1 mappings (same mnemonic in LLVM)
    simple_ops = {
        'nop', 'ret', 'reti', 'halt', 'ccf', 'rcf', 'scf', 'zcf',
        'incf', 'decf', 'ei', 'di', 'swi',
    }
    if op in simple_ops:
        if args_lc:
            return f'{op}\t{args_lc}'
        return op

    # Push/Pop
    if op == 'push':
        reg = args_lc.strip()
        # LLVM uses pushw for 16-bit, push for 32-bit and special
        if reg in ('a', 'f', 'sr'):
            return f'push\t{reg}'
        if reg in ('xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp'):
            return f'push\t{reg}'
        if reg in ('wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz'):
            return f'pushw\t{reg}'
        return None

    if op == 'pop':
        reg = args_lc.strip()
        if reg in ('a', 'f', 'sr'):
            return f'pop\t{reg}'
        if reg in ('xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp'):
            return f'pop\t{reg}'
        if reg in ('wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz'):
            return f'popw\t{reg}'
        return None

    # LDF
    if op == 'ldf':
        return f'ldf\t{args_lc}'

    # EX F,F'
    if op == 'ex' and 'f' in args_lc:
        return "ex\tf, f'"

    # RET with displacement
    if op == 'retd':
        return f'retd\t{args_lc}'

    # Condition code normalization (unidasm → LLVM)
    CC_MAP = {
        'm/mi': 'mi', 'p/pl': 'pl', 'm': 'mi', 'p': 'pl',
        'pe/v': 'v', 'po/nv': 'nv', 'v': 'v', 'nv': 'nv',
    }
    def norm_cc(cc):
        return CC_MAP.get(cc, cc)

    # Branches: JR, JRL, JP, CALL, CALR
    if op == 'jr':
        # unidasm: "jr CC,0xADDR" or "jr 0xADDR" (unconditional = T)
        parts = args_lc.split(',')
        if len(parts) == 2:
            cc = parts[0].strip()
            target = parts[1].strip()
        else:
            cc = 't'  # unconditional
            target = parts[0].strip()
        # Compute relative displacement
        target_addr = int(target, 0) if target.startswith('0x') else int(target)
        # For JR: displacement is target - (current_pc + 2)
        # We encode displacement directly since we don't know absolute PC
        # The raw byte at offset+1 IS the signed displacement
        disp = struct.unpack_from('b', bytes(raw_bytes), offset + 1)[0]
        cc = norm_cc(cc)
        if cc == 't':
            return f'jr\t{disp}'
        return f'jr\t{cc}, {disp}'

    if op == 'jrl':
        parts = args_lc.split(',')
        if len(parts) == 2:
            cc = norm_cc(parts[0].strip())
        else:
            cc = 't'
        disp = struct.unpack_from('<h', bytes(raw_bytes), offset + 1)[0]
        if cc == 't':
            return f'jrl\t{disp}'
        return f'jrl\t{cc}, {disp}'

    if op == 'calr':
        disp = struct.unpack_from('<h', bytes(raw_bytes), offset + 1)[0]
        return f'calr\t{disp}'

    if op == 'jp':
        target = args_lc.strip()
        # JP can be 16 or 24-bit absolute
        if nbytes == 3:
            addr = raw_bytes[offset + 1] | (raw_bytes[offset + 2] << 8)
            return f'jp\t{addr}'
        elif nbytes == 4:
            addr = raw_bytes[offset + 1] | (raw_bytes[offset + 2] << 8) | (raw_bytes[offset + 3] << 16)
            return f'jp\t{addr}'
        return None

    if op == 'call':
        if nbytes == 3:
            addr = raw_bytes[offset + 1] | (raw_bytes[offset + 2] << 8)
            return f'call\t{addr}'
        elif nbytes == 4:
            addr = raw_bytes[offset + 1] | (raw_bytes[offset + 2] << 8) | (raw_bytes[offset + 3] << 16)
            return f'call\t{addr}'
        return None

    # Compact register loads: LDB r,N (0x20+r)
    if op == 'ld' and nbytes == 2 and 0x20 <= raw_bytes[offset] <= 0x27:
        r_idx = raw_bytes[offset] - 0x20
        r = ['w', 'a', 'b', 'c', 'd', 'e', 'h', 'l'][r_idx]
        n = raw_bytes[offset + 1]
        return f'ldb\t{r}, {n}'

    # Compact word loads: LDW rr,NN (0x30+rr)
    if op == 'ld' and nbytes == 3 and 0x30 <= raw_bytes[offset] <= 0x37:
        r_idx = raw_bytes[offset] - 0x30
        r = ['wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp'][r_idx]
        nn = raw_bytes[offset + 1] | (raw_bytes[offset + 2] << 8)
        return f'ldw\t{r}, {nn}'

    # Compact LD small immediate (lds/lds32)
    prefix = raw_bytes[offset]
    if (0xD8 <= prefix <= 0xDF or 0xE8 <= prefix <= 0xEF) and nbytes == 2:
        subop = raw_bytes[offset + 1]
        if 0xA8 <= subop <= 0xAF:
            n = subop - 0xA8
            if 0xD8 <= prefix <= 0xDF:
                r_idx = prefix - 0xD8
                r = ['wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp'][r_idx]
                return f'lds\t{r}, {n}'
            else:
                r_idx = prefix - 0xE8
                r = ['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp'][r_idx]
                return f'lds32\t{r}, {n}'

    # Compact compare-with-zero (cps)
    if (0xC8 <= prefix <= 0xEF) and nbytes == 2 and raw_bytes[offset + 1] == 0xD8:
        if 0xC8 <= prefix <= 0xCF:
            r_idx = prefix - 0xC8
            r = ['w', 'a', 'b', 'c', 'd', 'e', 'h', 'l'][r_idx]
            return f'cps\t{r}, 0'
        elif 0xD8 <= prefix <= 0xDF:
            r_idx = prefix - 0xD8
            r = ['wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp'][r_idx]
            return f'cps\t{r}, 0'
        elif 0xE8 <= prefix <= 0xEF:
            r_idx = prefix - 0xE8
            r = ['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp'][r_idx]
            return f'cps\t{r}, 0'

    # Prevbank (D7 prefix)
    if prefix == 0xD7 and nbytes >= 3:
        mode = raw_bytes[offset + 1]
        qr_idx = (mode - 0xE0) // 4 if mode >= 0xE0 else -1
        if 0 <= qr_idx <= 7:
            qr = ['qwa', 'qbc', 'qde', 'qhl', 'qix', 'qiy', 'qiz', 'qsp'][qr_idx]
            subop = raw_bytes[offset + 2]

            # LD qr, small_imm
            if 0xA8 <= subop <= 0xAF:
                return f'ld\t{qr}, {subop - 0xA8}'
            # LD qr, imm16
            if subop == 0x03 and nbytes >= 5:
                imm = raw_bytes[offset + 3] | (raw_bytes[offset + 4] << 8)
                return f'ldw\t{qr}, {imm}'
            # CP qr, imm16
            if subop == 0xCF and nbytes >= 5:
                imm = raw_bytes[offset + 3] | (raw_bytes[offset + 4] << 8)
                return f'cpw\t{qr}, {imm}'
            # CP qr, 0 (compact)
            if subop == 0xD8:
                return f'cp\t{qr}, 0'
            # LD qr, rr (from register)
            if 0x90 <= subop <= 0x97:
                r = ['wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp'][subop - 0x90]
                return f'ld\t{qr}, {r}'
            # LD rr, qr (to register)
            if 0x88 <= subop <= 0x8F:
                r = ['wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp'][subop - 0x88]
                return f'ld\t{r}, {qr}'
            # INC/DEC
            if 0x60 <= subop <= 0x67:
                return f'inc\t{(subop & 7) + 1}, {qr}'
            if 0x68 <= subop <= 0x6F:
                return f'dec\t{(subop & 7) + 1}, {qr}'
            # PUSH/POP
            if subop == 0x04:
                return f'push\t{qr}'
            if subop == 0x05:
                return f'pop\t{qr}'
            # NEG
            if subop == 0x07:
                return f'neg\t{qr}'
            # EXTZ/EXTS
            if subop == 0x12:
                return f'extz\t{qr}'
            if subop == 0x13:
                return f'exts\t{qr}'

    # Direct source addressing (C1/D1/E1)
    if prefix in (0xC1, 0xD1, 0xE1) and nbytes >= 4 and offset + nbytes <= len(raw_bytes):
        addr = raw_bytes[offset + 1] | (raw_bytes[offset + 2] << 8)
        subop = raw_bytes[offset + 3]
        size = {0xC1: 8, 0xD1: 16, 0xE1: 32}[prefix]

        # LD r, (da16)
        if 0x20 <= subop <= 0x27:
            if size == 8:
                r = ['w', 'a', 'b', 'c', 'd', 'e', 'h', 'l'][subop - 0x20]
                return f'ldda8\t{r}, {addr}'
            elif size == 16:
                r = ['wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp'][subop - 0x20]
                return f'ldda16\t{r}, {addr}'
            elif size == 32:
                r = ['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp'][subop - 0x20]
                return f'ldda32\t{r}, {addr}'

        # Memory-to-memory LD: NOT in LLVM
        if 0x18 <= subop <= 0x1F:
            return None  # Must remain as .byte

        # ALU operations
        alu_base = subop & 0xF8
        r_idx = subop & 0x07

        # ALU r, (da16)
        alu_src = {
            0x80: 'add', 0x90: 'adc', 0xA0: 'sub', 0xB0: 'sbc',
            0xC0: 'and', 0xD0: 'xor', 0xE0: 'or', 0xF0: 'cp',
        }
        if alu_base in alu_src:
            suffix = {8: 'da8', 16: 'da16', 32: 'da32'}[size]
            regs = {8: ['w','a','b','c','d','e','h','l'],
                    16: ['wa','bc','de','hl','ix','iy','iz','sp'],
                    32: ['xwa','xbc','xde','xhl','xix','xiy','xiz','xsp']}
            r = regs[size][r_idx]
            mnem = alu_src[alu_base] + suffix
            return f'{mnem}\t{r}, {addr}'

        # ALU (da16), r (memory destination)
        alu_dst = {
            0x88: 'add', 0xA8: 'sub', 0xC8: 'and',
            0xD8: 'xor', 0xE8: 'or', 0xF8: 'cp',
        }
        if alu_base in alu_dst:
            sz = {8: '8', 16: '16', 32: '32'}[size]
            regs = {8: ['w','a','b','c','d','e','h','l'],
                    16: ['wa','bc','de','hl','ix','iy','iz','sp'],
                    32: ['xwa','xbc','xde','xhl','xix','xiy','xiz','xsp']}
            r = regs[size][r_idx]
            mnem = alu_dst[alu_base] + 'dm' + sz
            return f'{mnem}\t{addr}, {r}'

        # CP/AND/etc (da16), imm
        if subop == 0x3F:
            if size == 8 and nbytes >= 5:
                imm = raw_bytes[offset + 4]
                return f'cpdi8\t{addr}, {imm}'
            elif size == 16 and nbytes >= 6:
                imm = raw_bytes[offset + 4] | (raw_bytes[offset + 5] << 8)
                return f'cpdi16\t{addr}, {imm}'

    # Direct destination addressing (F1/F2)
    if prefix in (0xF1, 0xF2) and offset + nbytes <= len(raw_bytes):
        is24 = (prefix == 0xF2)
        addr_len = 3 if is24 else 2
        if nbytes < addr_len + 2:
            return None
        if is24:
            addr = raw_bytes[offset + 1] | (raw_bytes[offset + 2] << 8) | (raw_bytes[offset + 3] << 16)
        else:
            addr = raw_bytes[offset + 1] | (raw_bytes[offset + 2] << 8)
        subop = raw_bytes[offset + 1 + addr_len]

        # LD (da), r8
        if 0x40 <= subop <= 0x47:
            r = ['w', 'a', 'b', 'c', 'd', 'e', 'h', 'l'][subop - 0x40]
            if is24:
                return f'st8_24\t{addr}, {r}'
            return f'stda8\t{addr}, {r}'

        # LD (da), r16
        if 0x50 <= subop <= 0x57:
            r = ['wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp'][subop - 0x50]
            if is24:
                return f'st16_24\t{addr}, {r}'
            return f'stda16\t{addr}, {r}'

        # LD (da), r32
        if 0x60 <= subop <= 0x67:
            r = ['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp'][subop - 0x60]
            if is24:
                return f'st32_24\t{addr}, {r}'
            return f'stda32\t{addr}, {r}'

        # LD (da), imm8
        if subop == 0x00:
            imm = raw_bytes[offset + 2 + addr_len]
            if is24:
                return f'sti8_24\t{addr}, {imm}'
            return f'stdi8\t{addr}, {imm}'

        # LD (da), imm16
        if subop == 0x02:
            imm = raw_bytes[offset + 2 + addr_len] | (raw_bytes[offset + 3 + addr_len] << 8)
            if is24:
                return f'sti16_24\t{addr}, {imm}'
            return f'stdi16\t{addr}, {imm}'

        # LDA — sub-ops 0x30-0x37 select destination register
        if 0x30 <= subop <= 0x37:
            r_idx = subop - 0x30
            r32 = ['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp'][r_idx]
            if is24:
                return f'lda_24\t{r32}, {addr}'
            return f'ldada\t{r32}, {addr}'

    # Register prefix operations (C8-CF, D8-DF, E8-EF only — NOT D0-D7/E0-E7)
    is_reg_prefix = ((0xC8 <= prefix <= 0xCF) or
                     (0xD8 <= prefix <= 0xDF) or
                     (0xE8 <= prefix <= 0xEF))
    if is_reg_prefix and nbytes >= 2:
        subop = raw_bytes[offset + 1]

        if 0xC8 <= prefix <= 0xCF:
            r_idx = prefix - 0xC8
            regs8 = ['w', 'a', 'b', 'c', 'd', 'e', 'h', 'l']
            r = regs8[r_idx]
            sz = 8
        elif 0xD8 <= prefix <= 0xDF:
            r_idx = prefix - 0xD8
            regs16 = ['wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp']
            r = regs16[r_idx]
            sz = 16
        else:
            r_idx = prefix - 0xE8
            regs32 = ['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp']
            r = regs32[r_idx]
            sz = 32

        # INC/DEC
        if 0x60 <= subop <= 0x67:
            n = (subop & 7) or 8
            return f'inc\t{n}, {r}'
        if 0x68 <= subop <= 0x6F:
            n = (subop & 7) or 8
            return f'dec\t{n}, {r}'

        # EXTZ/EXTS
        if subop == 0x12:
            return f'extz\t{r}'
        if subop == 0x13:
            return f'exts\t{r}'

        # NEG/CPL
        if subop == 0x07:
            return f'neg\t{r}'
        if subop == 0x06:
            return f'cpl\t{r}'

        # PUSH/POP
        if subop == 0x04:
            if sz == 16:
                return f'pushw\t{r}'
            return f'push\t{r}'
        if subop == 0x05:
            if sz == 16:
                return f'popw\t{r}'
            return f'pop\t{r}'

        # LD r, imm
        if subop == 0x03:
            if sz == 8 and nbytes >= 3:
                return f'ld\t{r}, {raw_bytes[offset + 2]}'
            elif sz == 16 and nbytes >= 4:
                imm = raw_bytes[offset + 2] | (raw_bytes[offset + 3] << 8)
                return f'ld\t{r}, {imm}'
            elif sz == 32 and nbytes >= 6:
                imm = struct.unpack_from('<I', bytes(raw_bytes), offset + 2)[0]
                return f'ld\t{r}, {imm}'

        # LD r2, r (register-register): sub-op 0x88+n = LD reg[n], prefix_reg
        if 0x88 <= subop <= 0x8F:
            r2_idx = subop - 0x88
            if sz == 8:
                r2 = ['w', 'a', 'b', 'c', 'd', 'e', 'h', 'l'][r2_idx]
            elif sz == 16:
                r2 = ['wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp'][r2_idx]
            else:
                r2 = ['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp'][r2_idx]
            return f'ld\t{r2}, {r}'

        # ALU r, imm
        alu_imm = {0xC8: 'add', 0xC9: 'adc', 0xCA: 'sub', 0xCB: 'sbc',
                   0xCC: 'and', 0xCD: 'xor', 0xCE: 'or', 0xCF: 'cp'}
        if subop in alu_imm:
            mnem = alu_imm[subop]
            if sz == 8 and nbytes >= 3:
                return f'{mnem}\t{r}, {raw_bytes[offset + 2]}'
            elif sz == 16 and nbytes >= 4:
                imm = raw_bytes[offset + 2] | (raw_bytes[offset + 3] << 8)
                return f'{mnem}\t{r}, {imm}'
            elif sz == 32 and nbytes >= 6:
                imm = struct.unpack_from('<I', bytes(raw_bytes), offset + 2)[0]
                return f'{mnem}\t{r}, {imm}'

        # ALU r, r' (sub-op base: reg[n] operates with prefix_reg)
        alu_rr_base = subop & 0xF8
        alu_rr_idx = subop & 0x07
        alu_rr_ops = {
            0x80: 'add', 0x90: 'adc', 0x98: 'sub', 0xA0: 'sub',
            0xB0: 'sbc', 0xB8: 'cp', 0xC0: 'and', 0xD0: 'xor',
            0xE0: 'or',
        }
        if alu_rr_base in alu_rr_ops:
            mnem = alu_rr_ops[alu_rr_base]
            if sz == 8:
                r2 = ['w', 'a', 'b', 'c', 'd', 'e', 'h', 'l'][alu_rr_idx]
            elif sz == 16:
                r2 = ['wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp'][alu_rr_idx]
            else:
                r2 = ['xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp'][alu_rr_idx]
            return f'{mnem}\t{r2}, {r}'

        # BIT/SET/RES — 3-byte: prefix + sub-op + bit_number
        # RES=0x30, SET=0x31, BIT=0x33 (each followed by bit number byte)
        if subop in (0x30, 0x31, 0x33) and nbytes >= 3:
            bit_num = raw_bytes[offset + 2]
            bit_ops = {0x30: 'res', 0x31: 'set', 0x33: 'bit'}
            return f'{bit_ops[subop]}\t{bit_num}, {r}'

        # MUL/MULS/DIV/DIVS — not in LLVM, must remain as .byte

        # Shift/Rotate by 1
        shift_map = {
            0xE8: 'rrc', 0xE9: 'rlc', 0xEA: 'rr', 0xEB: 'rl',
            0xEC: 'sla', 0xED: 'sra', 0xEE: 'sll', 0xEF: 'srl',
        }
        if subop in shift_map:
            return f'{shift_map[subop]}\t1, {r}'

        # SWAP
        if subop == 0xF4:
            return f'swap\t{r}'

        # DAA
        if subop == 0x10:
            return f'daa\t{r}'

        # (MUL/MULS/DIV/DIVS handled above)

    # Register indirect with displacement (80-BF range)
    if 0x80 <= prefix <= 0xBF and nbytes >= 2:
        # Complex — many sub-opcodes possible
        # For now, try to pass through to LLVM via the disassembler
        pass

    # Fallback: try LLVM disassembler directly
    hex_input = ' '.join(f'0x{b:02x}' for b in raw_bytes[offset:offset+nbytes])
    try:
        result = subprocess.run(
            [LLVM_MC, '--triple=tlcs900', '--disassemble'],
            input=hex_input, capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            for line in result.stdout.splitlines():
                stripped = line.strip()
                if stripped and not stripped.startswith('.text'):
                    # Verify this round-trips
                    if verify_roundtrip(stripped, list(raw_bytes[offset:offset+nbytes])):
                        return stripped
    except:
        pass

    return None


def verify_roundtrip(mnemonic, expected_bytes):
    """Verify that assembling mnemonic produces expected_bytes."""
    try:
        result = subprocess.run(
            [LLVM_MC, '--triple=tlcs900', '--show-encoding'],
            input=mnemonic + '\n',
            capture_output=True, text=True, timeout=5
        )
    except:
        return False

    for line in result.stdout.splitlines():
        m = re.search(r'[;#] encoding:\s*\[(.*?)\]', line)
        if m:
            hex_vals = re.findall(r'0x([0-9a-fA-F]{2})', m.group(1))
            actual = [int(v, 16) for v in hex_vals]
            return actual == expected_bytes
    return False


def convert_block(raw_bytes, base_pc=0, verbose=False):
    """Convert a .byte block to native instructions using unidasm + LLVM.

    Returns list of (mnemonic_or_none, offset, nbytes).
    """
    # First decode with unidasm
    decoded = unidasm_decode(raw_bytes, base_pc)

    if not decoded:
        return [(None, 0, len(raw_bytes))]

    results = []
    for offset, nbytes, unidasm_mnem in decoded:
        # Try to convert to LLVM
        llvm_mnem = unidasm_to_llvm(unidasm_mnem, raw_bytes, offset, nbytes)

        if llvm_mnem is not None:
            # Verify round-trip
            expected = list(raw_bytes[offset:offset + nbytes])
            if verify_roundtrip(llvm_mnem, expected):
                results.append((llvm_mnem, offset, nbytes))
                if verbose:
                    print(f"    ✓ {unidasm_mnem} → {llvm_mnem}", file=sys.stderr)
                continue
            elif verbose:
                print(f"    ✗ RT fail: {unidasm_mnem} → {llvm_mnem}", file=sys.stderr)

        # Failed — mark as unconverted
        results.append((None, offset, nbytes))
        if verbose:
            print(f"    - {unidasm_mnem} → .byte (no LLVM equivalent)", file=sys.stderr)

    return results


def process_file(file_path, dry_run=True, verbose=False):
    """Process a single .s file."""
    try:
        with open(file_path, 'rb') as f:
            raw = f.read()
        lines = raw.decode('latin-1').splitlines(keepends=True)
    except Exception as e:
        print(f"Error reading {file_path}: {e}", file=sys.stderr)
        return 0, 0

    total_converted = 0
    total_remaining = 0
    changes = []

    i = 0
    while i < len(lines):
        byte_vals = parse_bytes_from_line(lines[i])
        if byte_vals is None:
            i += 1
            continue

        block_start = i
        block_bytes = list(byte_vals)
        i += 1
        while i < len(lines):
            bv = parse_bytes_from_line(lines[i])
            if bv is None:
                break
            block_bytes.extend(bv)
            i += 1
        block_end = i - 1

        if len(block_bytes) < 3:
            continue

        # Get label and context
        label = None
        is_data = False
        for j in range(block_start - 1, max(block_start - 10, -1), -1):
            line_j = lines[j].strip()
            m = LABEL_RE.match(lines[j])
            if m:
                label = m.group(1)
                break
            # Detect NAKA widget data (naka_header macro precedes .byte data)
            if 'naka_header' in line_j:
                is_data = True
                break
            # Detect aligned_string (data marker)
            if 'aligned_string' in line_j:
                is_data = True
                break
            # Detect .ascii/.asciz (data context)
            if line_j.startswith('.ascii') or line_j.startswith('.asciz'):
                is_data = True
                break

        # Skip data labels — labels starting with known data prefixes
        if label and any(label.startswith(p) for p in (
            'Str_', 'Tbl_', 'Arr_', 'Naka', 'NakaDesc_', 'NakaMenu',
            'NakaWidget', 'SE_', 'SoundData_', 'StyleBitmap_',
            'ExtData_', 'ChordTable_', 'Param_', 'Default_',
            'FontData_', 'BitmapData_', 'StringTable_',
        )):
            is_data = True

        # Skip entire data-oriented files
        file_str = str(file_path)
        if any(d in file_str for d in (
            '/ui_widgets/', '/sound_data_', '_data_tables.s',
            'gui_display_struct_data.s', 'gui_format_strings.s',
            'msp_factory_defaults.s', 'msp_recording_screens.s',
            'composer_msp_defaults.s', 'extension_data.s',
            'factory_test/', 'test_data.s', 'fd_test_data.s',
        )):
            is_data = True

        # Also check: if the .byte block starts with NAKA header bytes
        if len(block_bytes) >= 4 and block_bytes[1] == 0x00 and block_bytes[2] == 0x60 and block_bytes[3] == 0x01:
            is_data = True

        if is_data:
            if verbose:
                print(f"  SKIP data block at line {block_start+1} ({len(block_bytes)}B) label={label}", file=sys.stderr)
            continue

        if verbose:
            print(f"  Block at line {block_start+1} ({len(block_bytes)}B) label={label}", file=sys.stderr)

        # Convert
        results = convert_block(block_bytes, base_pc=0, verbose=verbose)

        # Build new lines
        converted_bytes = sum(nb for mnem, _, nb in results if mnem is not None)
        remaining_bytes = sum(nb for mnem, _, nb in results if mnem is None)

        if converted_bytes == 0:
            continue

        new_lines = []
        undecoded_run = []

        def flush():
            if undecoded_run:
                hex_str = ', '.join(f'0x{b:02x}' for b in undecoded_run)
                new_lines.append(f'\t.byte {hex_str}\n')
                undecoded_run.clear()

        for mnem, off, nb in results:
            if mnem is None:
                undecoded_run.extend(block_bytes[off:off+nb])
            else:
                flush()
                new_lines.append(f'\t{mnem}\n')

        flush()

        total_converted += converted_bytes
        total_remaining += remaining_bytes

        if dry_run:
            rel = file_path.relative_to(REPO_ROOT) if REPO_ROOT in file_path.parents else file_path
            print(f"\n--- {rel}:{block_start+1}-{block_end+1} ({label or '?'}) ---")
            print(f"  {converted_bytes}/{len(block_bytes)} bytes converted, {remaining_bytes} remaining")
            for nl in new_lines:
                print(f"  {nl.rstrip()}")
        else:
            changes.append((block_start, block_end, new_lines))

    if not dry_run and changes:
        for start, end, new_lines in reversed(changes):
            lines[start:end + 1] = new_lines
        with open(file_path, 'wb') as f:
            f.write(''.join(lines).encode('latin-1'))

    return total_converted, total_remaining


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--file', type=str)
    parser.add_argument('--all', action='store_true')
    parser.add_argument('--verbose', '-v', action='store_true')
    args = parser.parse_args()

    if args.file:
        p = Path(args.file)
        if not p.is_absolute():
            p = REPO_ROOT / p
        files = [p]
    elif args.all:
        files = []
        for d in ['maincpu', 'subcpu', 'hdae5000', 'table_data', 'custom_data']:
            dd = REPO_ROOT / d
            if dd.is_dir():
                for root, _, fns in os.walk(dd):
                    for fn in sorted(fns):
                        if fn.endswith('.s'):
                            files.append(Path(root) / fn)
        files.sort()
    else:
        print("Specify --file <path> or --all", file=sys.stderr)
        sys.exit(1)

    grand_converted = 0
    grand_remaining = 0
    for f in files:
        converted, remaining = process_file(f, dry_run=args.dry_run, verbose=args.verbose)
        if converted > 0:
            rel = f.relative_to(REPO_ROOT) if REPO_ROOT in f.parents else f
            print(f"  {rel}: {converted}B converted, {remaining}B remaining", file=sys.stderr)
        grand_converted += converted
        grand_remaining += remaining

    print(f"\nTotal: {grand_converted}B converted, {grand_remaining}B remaining", file=sys.stderr)
    if args.dry_run:
        print("(dry run — no files modified)", file=sys.stderr)


if __name__ == '__main__':
    main()
