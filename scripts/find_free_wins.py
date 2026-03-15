#!/usr/bin/env python3
"""
find_free_wins.py — Find .byte sequences that LLVM can already encode.

Uses MAME's unidasm (reference disassembler) to decode .byte sequences,
then tests if the LLVM encoder can reproduce the same bytes.

"Free wins" are .byte blocks where:
  1. unidasm decodes them to a valid instruction
  2. We can translate the unidasm syntax to LLVM syntax
  3. LLVM's encoder produces the exact same bytes

Usage:
    python scripts/find_free_wins.py [--file PATH] [--convert] [--verbose]
"""

import os
import re
import sys
import struct
import subprocess
import tempfile
from pathlib import Path
from collections import defaultdict, Counter

LLVM_MC = "/mnt/shared/llvm-project/build/bin/llvm-mc"
UNIDASM = "/mnt/shared/tools/unidasm"
REPO_ROOT = Path("/mnt/shared/kn5000-roms-disasm")

ROM_DIRS = ["maincpu", "subcpu", "hdae5000", "table_data"]

# Regex for .byte line
BYTE_LINE_RE = re.compile(r'^\s*\.byte\s+((?:0x[0-9a-fA-F]{2}\s*,?\s*)+)', re.IGNORECASE)
BYTE_VAL_RE = re.compile(r'0x([0-9a-fA-F]{2})')
LABEL_RE = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)\s*:')
COMMENT_RE = re.compile(r'^\s*[;#/]')
EMPTY_RE = re.compile(r'^\s*$')
DIRECTIVE_RE = re.compile(r'^\s*\.(byte|long|short|ascii|asciz|zero|fill|incbin|include|global|type|section|align|org|space|set|equ|if|else|endif|macro|endm|file|loc|size)', re.IGNORECASE)


def is_native_instruction(line):
    stripped = line.strip()
    if not stripped:
        return False
    if stripped.startswith(';') or stripped.startswith('#') or stripped.startswith('//'):
        return False
    if LABEL_RE.match(stripped):
        return False
    if DIRECTIVE_RE.match(stripped):
        return False
    if line and (line[0] == '\t' or line.startswith('  ')):
        return True
    return False


def find_s_files(specific_file=None):
    if specific_file:
        p = Path(specific_file)
        if not p.is_absolute():
            p = REPO_ROOT / p
        return [p]
    files = []
    for rom_dir in ROM_DIRS:
        d = REPO_ROOT / rom_dir
        if d.is_dir():
            for root, dirs, filenames in os.walk(d):
                for fn in sorted(filenames):
                    if fn.endswith('.s'):
                        files.append(Path(root) / fn)
    return sorted(files)


def extract_code_byte_blocks(file_path):
    """Extract .byte blocks that are in code context (between native instructions)."""
    try:
        with open(file_path, 'rb') as f:
            raw = f.read()
        lines = raw.decode('latin-1').split('\n')
    except Exception as e:
        print(f"  Warning: cannot read {file_path}: {e}", file=sys.stderr)
        return []

    blocks = []
    current_bytes = []
    current_start = None
    last_was_instruction = False
    in_code_context = False

    for i, line in enumerate(lines, 1):
        if LABEL_RE.match(line):
            # Flush current block
            if current_bytes and in_code_context:
                blocks.append((file_path, current_start, i - 1, current_bytes[:]))
            current_bytes = []
            current_start = None
            last_was_instruction = False
            in_code_context = False
            continue

        if COMMENT_RE.match(line) or EMPTY_RE.match(line):
            continue

        m = BYTE_LINE_RE.match(line)
        if m:
            vals = [int(v, 16) for v in BYTE_VAL_RE.findall(m.group(1))]
            if not current_bytes:
                current_start = i
                in_code_context = last_was_instruction
            current_bytes.extend(vals)
            continue

        # Non-.byte, non-label line
        if current_bytes:
            followed_by_inst = is_native_instruction(line)
            if in_code_context or followed_by_inst:
                blocks.append((file_path, current_start, i - 1, current_bytes[:]))
            current_bytes = []
            current_start = None

        last_was_instruction = is_native_instruction(line)
        in_code_context = last_was_instruction

    # Flush final block
    if current_bytes and in_code_context:
        blocks.append((file_path, current_start, len(lines), current_bytes[:]))

    return blocks


def unidasm_decode(raw_bytes):
    """Decode bytes using unidasm. Returns list of (offset, length, mnemonic) tuples."""
    with tempfile.NamedTemporaryFile(suffix='.bin', delete=False) as f:
        f.write(bytes(raw_bytes))
        tmppath = f.name

    try:
        result = subprocess.run(
            [UNIDASM, tmppath, '-arch', 'tlcs900', '-norawbytes'],
            capture_output=True, text=True, timeout=5
        )
    except (subprocess.TimeoutExpired, FileNotFoundError):
        os.unlink(tmppath)
        return []
    finally:
        try:
            os.unlink(tmppath)
        except:
            pass

    instructions = []
    for line in result.stdout.splitlines():
        m = re.match(r'^\s*([0-9a-fA-F]+):\s+(.+)$', line)
        if m:
            offset = int(m.group(1), 16)
            mnemonic = m.group(2).strip()
            instructions.append((offset, mnemonic))

    # Calculate instruction lengths from offsets
    decoded = []
    for idx, (offset, mnem) in enumerate(instructions):
        if idx + 1 < len(instructions):
            length = instructions[idx + 1][0] - offset
        else:
            length = len(raw_bytes) - offset
        decoded.append((offset, length, mnem))

    return decoded


# Translation table: unidasm syntax → LLVM syntax
UNIDASM_REG_MAP = {
    # 8-bit
    'W': 'w', 'A': 'a', 'B': 'b', 'C': 'c',
    'D': 'd', 'E': 'e', 'H': 'h', 'L': 'l',
    # 16-bit
    'WA': 'wa', 'BC': 'bc', 'DE': 'de', 'HL': 'hl',
    'IX': 'ix', 'IY': 'iy', 'IZ': 'iz', 'SP': 'sp',
    # 32-bit
    'XWA': 'xwa', 'XBC': 'xbc', 'XDE': 'xde', 'XHL': 'xhl',
    'XIX': 'xix', 'XIY': 'xiy', 'XIZ': 'xiz', 'XSP': 'xsp',
    # Prevbank 16-bit
    'QWA': 'qwa', 'QBC': 'qbc', 'QDE': 'qde', 'QHL': 'qhl',
    'QIX': 'qix', 'QIY': 'qiy', 'QIZ': 'qiz', 'QSP': 'qsp',
    # Prevbank 8-bit
    'QAH': 'qah', 'QAL': 'qal', 'QBH': 'qbh', 'QBL': 'qbl',
    'QCH': 'qch', 'QCL': 'qcl', 'QDH': 'qdh', 'QDL': 'qdl',
    'QEH': 'qeh', 'QEL': 'qel', 'QFH': 'qfh', 'QFL': 'qfl',
    'QGH': 'qgh', 'QGL': 'qgl', 'QHH': 'qhh', 'QHL': 'qhl',
    'QWAH': 'qwah', 'QWAL': 'qwal', 'QBCH': 'qbch', 'QBCL': 'qbcl',
    'QDEH': 'qdeh', 'QDEL': 'qdel', 'QHLH': 'qhlh', 'QHLL': 'qhll',
    'QIXH': 'qixh', 'QIXL': 'qixl', 'QIYH': 'qiyh', 'QIYL': 'qiyl',
    'QIZH': 'qizh', 'QIZL': 'qizl', 'QSPH': 'qsph', 'QSPL': 'qspl',
    # Conditions
    'F': 'f', 'LT': 'lt', 'LE': 'le', 'ULE': 'ule',
    'PE': 'pe', 'MI': 'mi', 'Z': 'z', 'C': 'c',
    'T': 't', 'GE': 'ge', 'GT': 'gt', 'UGT': 'ugt',
    'PO': 'po', 'PL': 'pl', 'NZ': 'nz', 'NC': 'nc',
    'EQ': 'z', 'NE': 'nz',
    'SR': 'sr',
}


# ERP bank register name → C7/D7/E7 bank index byte
# These are registers accessible via the Extended Register Prefix (C7=8-bit, D7=16-bit, E7=32-bit)
# Mapping from unidasm register names to bank index bytes
ERP_BANK_REGS = {
    # Bank 0 registers
    'RA0': 0x00, 'RW0': 0x01, 'QA0': 0x02, 'QW0': 0x03,
    'RC0': 0x04, 'RB0': 0x05, 'QC0': 0x06, 'QB0': 0x07,
    'RE0': 0x08, 'RD0': 0x09, 'QE0': 0x0A, 'QD0': 0x0B,
    'RL0': 0x0C, 'RH0': 0x0D, 'QL0': 0x0E, 'QH0': 0x0F,
    # Bank 1 registers
    'RA1': 0x10, 'RW1': 0x11, 'QA1': 0x12, 'QW1': 0x13,
    'RC1': 0x14, 'RB1': 0x15, 'QC1': 0x16, 'QB1': 0x17,
    'RE1': 0x18, 'RD1': 0x19, 'QE1': 0x1A, 'QD1': 0x1B,
    'RL1': 0x1C, 'RH1': 0x1D, 'QL1': 0x1E, 'QH1': 0x1F,
    # Bank 2 registers
    'RA2': 0x20, 'RW2': 0x21, 'QA2': 0x22, 'QW2': 0x23,
    'RC2': 0x24, 'RB2': 0x25, 'QC2': 0x26, 'QB2': 0x27,
    'RE2': 0x28, 'RD2': 0x29, 'QE2': 0x2A, 'QD2': 0x2B,
    'RL2': 0x2C, 'RH2': 0x2D, 'QL2': 0x2E, 'QH2': 0x2F,
    # Bank 3 registers
    'RA3': 0x30, 'RW3': 0x31, 'QA3': 0x32, 'QW3': 0x33,
    'RC3': 0x34, 'RB3': 0x35, 'QC3': 0x36, 'QB3': 0x37,
    'RE3': 0x38, 'RD3': 0x39, 'QE3': 0x3A, 'QD3': 0x3B,
    'RL3': 0x3C, 'RH3': 0x3D, 'QL3': 0x3E, 'QH3': 0x3F,
    # Current bank named registers (0xE0-0xEF)
    # 'A': 0xE0, 'W': 0xE1 — these are in normal register set, skip
    'QA': 0xE2, 'QW': 0xE3, 'QC': 0xE6, 'QB': 0xE7,
    'QE': 0xEA, 'QD': 0xEB, 'QL': 0xEE, 'QH': 0xEF,
    # Index/stack pointer bytes (0xF0-0xFF)
    'IXL': 0xF0, 'IXH': 0xF1, 'QIXL': 0xF2, 'QIXH': 0xF3,
    'IYL': 0xF4, 'IYH': 0xF5, 'QIYL': 0xF6, 'QIYH': 0xF7,
    'IZL': 0xF8, 'IZH': 0xF9, 'QIZL': 0xFA, 'QIZH': 0xFB,
    'SPL': 0xFC, 'SPH': 0xFD, 'QSPL': 0xFE, 'QSPH': 0xFF,
}

# 8-bit register names used in LDTO/LDFR ERP instructions
ERP_REG8 = {'A', 'W', 'B', 'C', 'D', 'E', 'H', 'L'}


def translate_unidasm_to_llvm(mnemonic):
    """Attempt to translate unidasm mnemonic to LLVM assembly syntax.

    Returns the LLVM instruction string, or None if translation not possible.
    May also return a list of alternative forms to try (for compact/extended).
    """
    mnem = mnemonic.strip()

    # Skip known untranslatable patterns
    if mnem.startswith('db') or mnem == 'max' or mnem == 'normal':
        return None

    # ── ERP bank register operations (C7 prefix) ──
    # Pattern: "ld REG8, BANK_REG" → ldto_berp reg8, bank_idx
    m = re.match(r'^ld\s+([A-Z])\s*,\s*([A-Z][A-Z0-9]+)$', mnem)
    if m and m.group(1) in ERP_REG8 and m.group(2) in ERP_BANK_REGS:
        reg = m.group(1).lower()
        bank_idx = ERP_BANK_REGS[m.group(2)]
        return f'ldto_berp\t{reg}, {bank_idx}'

    # Pattern: "ld BANK_REG, REG8" → ldfr_berp reg8, bank_idx
    m = re.match(r'^ld\s+([A-Z][A-Z0-9]+)\s*,\s*([A-Z])$', mnem)
    if m and m.group(1) in ERP_BANK_REGS and m.group(2) in ERP_REG8:
        reg = m.group(2).lower()
        bank_idx = ERP_BANK_REGS[m.group(1)]
        return f'ldfr_berp\t{reg}, {bank_idx}'

    # Pattern: "ld BANK_REG, imm" → ldi_berp (compact 0-7) or ldi_erpb (extended)
    m = re.match(r'^ld\s+([A-Z][A-Z0-9]+)\s*,\s*(0x[0-9a-fA-F]+|\d+)$', mnem)
    if m and m.group(1) in ERP_BANK_REGS:
        bank_idx = ERP_BANK_REGS[m.group(1)]
        val = int(m.group(2), 16) if m.group(2).startswith('0x') else int(m.group(2))
        forms = []
        if 0 <= val <= 7:
            forms.append(f'ldi_berp\t{bank_idx}, {val}')
        forms.append(f'ldi_erpb\t{bank_idx}, {val}')
        return forms

    # Pattern: "inc N, BANK_REG" → inc_berp bank_idx, N
    m = re.match(r'^inc\s+(0x[0-9a-fA-F]+|\d+)\s*,\s*([A-Z][A-Z0-9]+)$', mnem)
    if m and m.group(2) in ERP_BANK_REGS:
        bank_idx = ERP_BANK_REGS[m.group(2)]
        val = int(m.group(1), 16) if m.group(1).startswith('0x') else int(m.group(1))
        return f'inc_berp\t{bank_idx}, {val}'

    # Pattern: "dec N, BANK_REG" → dec_berp bank_idx, N
    m = re.match(r'^dec\s+(0x[0-9a-fA-F]+|\d+)\s*,\s*([A-Z][A-Z0-9]+)$', mnem)
    if m and m.group(2) in ERP_BANK_REGS:
        bank_idx = ERP_BANK_REGS[m.group(2)]
        val = int(m.group(1), 16) if m.group(1).startswith('0x') else int(m.group(1))
        return f'dec_berp\t{bank_idx}, {val}'

    # Pattern: "cp BANK_REG, imm" → cpi_berp (0-7) or cp_erpb (any)
    m = re.match(r'^cp\s+([A-Z][A-Z0-9]+)\s*,\s*(0x[0-9a-fA-F]+|\d+)$', mnem)
    if m and m.group(1) in ERP_BANK_REGS:
        bank_idx = ERP_BANK_REGS[m.group(1)]
        val = int(m.group(2), 16) if m.group(2).startswith('0x') else int(m.group(2))
        forms = []
        if 0 <= val <= 7:
            forms.append(f'cpi_berp\t{bank_idx}, {val}')
        forms.append(f'cp_erpb\t{bank_idx}, {val}')
        return forms

    # Pattern: "add REG8, BANK_REG" / "sub REG8, BANK_REG" / "and REG8, BANK_REG" etc.
    # → add_berp/sub_berp/and_berp/or_berp/cp_berp reg8, bank_idx
    ALU_OPS = {'add', 'sub', 'and', 'or', 'xor', 'cp'}
    m = re.match(r'^(\w+)\s+([A-Z])\s*,\s*([A-Z][A-Z0-9]+)$', mnem)
    if m and m.group(1).lower() in ALU_OPS and m.group(2) in ERP_REG8 and m.group(3) in ERP_BANK_REGS:
        op = m.group(1).lower()
        reg = m.group(2).lower()
        bank_idx = ERP_BANK_REGS[m.group(3)]
        return f'{op}_berp\t{reg}, {bank_idx}'

    # ── Direct I/O address operations: ld (0xNN), 0xNN → ldio/ldwio ──
    # 8-bit: "ld (0xNN),0xNN" → ldio addr, val
    m = re.match(r'^ld\s+\((0x[0-9a-fA-F]+)\)\s*,\s*(0x[0-9a-fA-F]+)$', mnem)
    if m:
        addr = int(m.group(1), 16)
        val = int(m.group(2), 16)
        if addr <= 0xFF and val <= 0xFF:
            return f'ldio\t{addr}, {val}'
        elif addr <= 0xFF and val <= 0xFFFF:
            return [f'ldio\t{addr}, {val}', f'ldwio\t{addr}, {val}']

    # ── Special single-byte instructions (LLVM uses underscored mnemonics) ──
    if mnem == 'push SR':
        return 'push_sr'
    if mnem == 'pop SR':
        return 'pop_sr'
    if mnem == 'push F':
        return 'push_f'
    if mnem == 'pop F':
        return 'pop_f'
    if mnem == 'push A':
        return 'push_a'
    if mnem == 'pop A':
        return 'pop_a'
    if mnem == "ex F,F'":
        return 'ex_ff'
    if mnem == 'incf':
        return 'incf'
    if mnem == 'decf':
        return 'decf'
    if mnem == 'rcf':
        return 'rcf'
    if mnem == 'scf':
        return 'scf'
    if mnem == 'ccf':
        return 'ccf'
    if mnem == 'zcf':
        return 'zcf'

    # ── Block transfer instructions — try prefix variants ──
    # ROM may use 0x83 or 0x85 prefix instead of standard 0x80
    BLOCK_VARIANTS = {
        'ldi':  ['ldi', 'ldi85'],
        'ldir': ['ldir', 'ldir85', 'ldir83'],
        'ldd':  ['ldd'],
        'lddr': ['lddr', 'lddr85', 'lddr83'],
        'cpi':  ['cpi'],
        'cpir': ['cpir', 'cpir83'],
        'cpd':  ['cpd'],
        'cpdr': ['cpdr'],
        'ldx':  ['ldx'],
    }
    if mnem in BLOCK_VARIANTS:
        return BLOCK_VARIANTS[mnem]

    # ── 16-bit block transfer variants ──
    BLOCK_W_VARIANTS = {
        'ldiw':  ['ldiw'],
        'ldirw': ['ldirw', 'ldirw93'],
    }
    if mnem in BLOCK_W_VARIANTS:
        return BLOCK_W_VARIANTS[mnem]

    # ── LDF instruction: "ldf 0xNN" → "ldf N" ──
    m = re.match(r'^ldf\s+0x([0-9a-fA-F]+)$', mnem)
    if m:
        val = int(m.group(1), 16)
        return f'ldf\t{val}'
    m = re.match(r'^ldf\s+(\d+)$', mnem)
    if m:
        return f'ldf\t{m.group(1)}'

    # ── Shift/rotate with reversed operand order ──
    # unidasm: "sla 0x02,WA" → LLVM: "sla wa, 2"
    # unidasm: "sra 0x01,BC" → LLVM: "sra bc, 1"
    SHIFT_OPS = {'sla', 'sra', 'srl', 'sll', 'rl', 'rlc', 'rr', 'rrc'}
    m = re.match(r'^(\w+)\s+0x([0-9a-fA-F]+)\s*,\s*([A-Z]+)$', mnem)
    if m and m.group(1).lower() in SHIFT_OPS:
        op = m.group(1).lower()
        count = int(m.group(2), 16)
        reg = UNIDASM_REG_MAP.get(m.group(3))
        if reg:
            return f'{op}\t{reg}, {count}'
    m = re.match(r'^(\w+)\s+(\d+)\s*,\s*([A-Z]+)$', mnem)
    if m and m.group(1).lower() in SHIFT_OPS:
        op = m.group(1).lower()
        count = int(m.group(2))
        reg = UNIDASM_REG_MAP.get(m.group(3))
        if reg:
            return f'{op}\t{reg}, {count}'

    # ── Push immediate: "push 0xNNNN" — try 8-bit (0x09) then 16-bit (0x0B) ──
    m = re.match(r'^push\s+0x([0-9a-fA-F]+)$', mnem)
    if m:
        val = int(m.group(1), 16)
        return [f'push {val}', f'pushw {val}']

    # ── Call T,XRR — unconditional call to register-indirect ──
    # "call T,XHL" → "call (xhl)" (T = always true, implicit)
    m = re.match(r'^call\s+T\s*,\s*([A-Z]+)$', mnem)
    if m:
        reg = UNIDASM_REG_MAP.get(m.group(1))
        if reg:
            return f'call\t({reg})'

    # ── JP T,XRR — unconditional jump to register-indirect ──
    # "jp T,XHL" → "jp (xhl)" (T = always true, implicit)
    m = re.match(r'^jp\s+T\s*,\s*([A-Z]+)$', mnem)
    if m:
        reg = UNIDASM_REG_MAP.get(m.group(1))
        if reg:
            return f'jp\t({reg})'

    # ── Push register — try both compact (pushw) and extended (push) ──
    # 16-bit regs: pushw wa (0x28) is 1-byte compact, push wa (0xd8 0x04) is 2-byte
    PUSH16_SHORT = {'WA': 'wa', 'BC': 'bc', 'DE': 'de', 'HL': 'hl',
                    'IX': 'ix', 'IY': 'iy', 'IZ': 'iz', 'SP': 'sp'}
    m = re.match(r'^push\s+([A-Z]+)$', mnem)
    if m:
        regname = m.group(1)
        if regname in PUSH16_SHORT:
            # Return list: try compact first, then extended
            return [f'pushw {PUSH16_SHORT[regname]}', f'push {PUSH16_SHORT[regname]}']
        reg = UNIDASM_REG_MAP.get(regname)
        if reg:
            return f'push {reg}'

    # ── Pop register — try both compact and extended ──
    POP16_SHORT = {'WA': 'wa', 'BC': 'bc', 'DE': 'de', 'HL': 'hl',
                   'IX': 'ix', 'IY': 'iy', 'IZ': 'iz', 'SP': 'sp'}
    m = re.match(r'^pop\s+([A-Z]+)$', mnem)
    if m:
        regname = m.group(1)
        if regname in POP16_SHORT:
            # pop16_short uses 0x48+r, pop16 uses prefix 0xD8+r 0x05
            return [f'popw {POP16_SHORT[regname]}', f'pop {POP16_SHORT[regname]}']
        reg = UNIDASM_REG_MAP.get(regname)
        if reg:
            return f'pop {reg}'

    # Generic instruction translation:
    # 1. Lowercase the mnemonic
    # 2. Replace register names
    # 3. Handle memory addressing

    # Split into mnemonic and operands
    parts = mnem.split(None, 1)
    if not parts:
        return None

    op = parts[0].lower()
    operands = parts[1] if len(parts) > 1 else ''

    def translate_operand(operand):
        operand = operand.strip()

        # Memory indirect with displacement: (XRR+0xNN)
        m = re.match(r'^\(([A-Z]+)\+(0x[0-9a-fA-F]+)\)$', operand)
        if m:
            reg = UNIDASM_REG_MAP.get(m.group(1))
            disp = int(m.group(2), 16)
            if reg:
                return f'({reg}+{disp})'

        # Memory indirect with negative disp: (XRR-0xNN)
        m = re.match(r'^\(([A-Z]+)-(0x[0-9a-fA-F]+)\)$', operand)
        if m:
            reg = UNIDASM_REG_MAP.get(m.group(1))
            disp = int(m.group(2), 16)
            if reg:
                return f'({reg}-{disp})'

        # Memory indirect no disp: (XRR)
        m = re.match(r'^\(([A-Z]+)\)$', operand)
        if m:
            reg = UNIDASM_REG_MAP.get(m.group(1))
            if reg:
                return f'({reg})'

        # Post-increment: (XRR+) → return POSTINC:reg_name marker
        m = re.match(r'^\(([A-Z]+)\+\)$', operand)
        if m:
            reg = UNIDASM_REG_MAP.get(m.group(1))
            if reg:
                return f'POSTINC:{reg}'
            return None

        # Pre-decrement: (-XRR)
        m = re.match(r'^\(-([A-Z]+)\)$', operand)
        if m:
            return None  # LLVM doesn't support this syntax

        # Register+Register: (XRR+RR) → REGPAIR:base:index marker
        m = re.match(r'^\(([A-Z]+)\+([A-Z]+)\)$', operand)
        if m:
            base = UNIDASM_REG_MAP.get(m.group(1))
            idx = UNIDASM_REG_MAP.get(m.group(2))
            if base and idx:
                return f'REGPAIR:{base}:{idx}'
            return None

        # Direct memory address: (0xNNNN) → return as DIRECT:nnn marker
        m = re.match(r'^\((0x[0-9a-fA-F]+)\)$', operand)
        if m:
            addr = int(m.group(1), 16)
            return f'DIRECT:{addr}'

        # Bare register+displacement: XRR+0xNN (used by lda)
        m = re.match(r'^([A-Z]+)\+(0x[0-9a-fA-F]+)$', operand)
        if m:
            reg = UNIDASM_REG_MAP.get(m.group(1))
            disp = int(m.group(2), 16)
            if reg:
                return f'({reg}+{disp})'

        # Bare register+register: XRR+RR (used by jp T, XRR+RR and lda)
        m = re.match(r'^([A-Z]+)\+([A-Z]+)$', operand)
        if m:
            base = UNIDASM_REG_MAP.get(m.group(1))
            idx = UNIDASM_REG_MAP.get(m.group(2))
            if base and idx:
                return f'REGPAIR:{base}:{idx}'
            return None

        # Register
        reg = UNIDASM_REG_MAP.get(operand)
        if reg:
            return reg

        # Hex immediate
        m = re.match(r'^0x([0-9a-fA-F]+)$', operand)
        if m:
            return str(int(m.group(1), 16))

        # Decimal immediate
        m = re.match(r'^(\d+)$', operand)
        if m:
            return operand

        # Condition codes in JP/JR/CALL
        cond = UNIDASM_REG_MAP.get(operand.upper())
        if cond:
            return cond

        return None

    # Split operands by comma
    if operands:
        ops = [o.strip() for o in operands.split(',')]
    else:
        ops = []

    # Translate operands
    translated_ops = []
    for o in ops:
        t = translate_operand(o)
        if t is None:
            return None  # Can't translate this operand
        translated_ops.append(t)

    # Handle mnemonic translation
    # Some unidasm mnemonics differ from LLVM
    llvm_op = op
    if op == 'ldw':
        llvm_op = 'ld'  # LLVM uses ld for all sizes, operand size determines encoding

    # ── Memory-immediate ALU: and/or/xor (mem), imm → andmi8/ormi8/xormi8 ──
    MEM_IMM_OPS = {'and': 'andmi8', 'or': 'ormi8', 'xor': 'xormi8'}
    if op in MEM_IMM_OPS and len(translated_ops) == 2:
        mem_op = translated_ops[0]
        imm_str = translated_ops[1]
        is_mem = mem_op.startswith('(')
        is_imm = imm_str.lstrip('-').isdigit()
        if is_mem and is_imm:
            mi_mnem = MEM_IMM_OPS[op]
            return [f'{mi_mnem}\t{mem_op}, {imm_str}', f'{op}\t{mem_op}, {imm_str}']

    # ── Direct address operations (C1/D1/E1/F1/F2 prefix) ──
    # Detect DIRECT:nnn markers from translate_operand
    def _is_direct(s):
        return s.startswith('DIRECT:')

    def _direct_addr(s):
        return int(s.split(':')[1])

    def _direct_forms(addr, mnemonics_16, mnemonics_24, *extra_args):
        """Generate alternatives for 16-bit and 24-bit address forms."""
        forms = []
        args_str = ', '.join(str(a) for a in extra_args)
        comma = ', ' if args_str else ''
        if addr <= 0xFFFF and mnemonics_16:
            forms.append(f'{mnemonics_16}\t{args_str}{comma}{addr}' if extra_args
                         else f'{mnemonics_16}\t{addr}')
        if mnemonics_24:
            forms.append(f'{mnemonics_24}\t{args_str}{comma}{addr}' if extra_args
                         else f'{mnemonics_24}\t{addr}')
        return forms

    REG8_SET = {'a', 'w', 'b', 'c', 'd', 'e', 'h', 'l'}
    REG16_SET = {'wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp'}
    REG32_SET = {'xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp'}

    def _reg_size(r):
        if r in REG8_SET: return 8
        if r in REG16_SET: return 16
        if r in REG32_SET: return 32
        return None

    if len(translated_ops) == 2:
        op0, op1 = translated_ops

        # ── LD/LDW reg, (direct_addr) — load from direct address ──
        if op in ('ld', 'ldw') and not _is_direct(op0) and _is_direct(op1):
            reg = op0
            addr = _direct_addr(op1)
            sz = _reg_size(reg)
            da16_map = {8: 'ldda8', 16: 'ldda16', 32: 'ldda32'}
            da24_map = {8: 'ld8_24', 16: 'ld16_24', 32: 'ld32_24'}
            if sz:
                forms = []
                if addr <= 0xFFFF and sz in da16_map:
                    forms.append(f'{da16_map[sz]}\t{reg}, {addr}')
                if sz in da24_map:
                    forms.append(f'{da24_map[sz]}\t{reg}, {addr}')
                if forms:
                    return forms

        # ── LD/LDW (direct_addr), reg — store to direct address ──
        if op in ('ld', 'ldw') and _is_direct(op0) and not _is_direct(op1):
            addr = _direct_addr(op0)
            reg = op1
            sz = _reg_size(reg)
            if sz and not reg.lstrip('-').isdigit():
                da16_map = {8: 'stda8', 16: 'stda16', 32: 'stda32'}
                da24_map = {8: 'st8_24', 16: 'st16_24', 32: 'st32_24'}
                forms = []
                if addr <= 0xFFFF and sz in da16_map:
                    forms.append(f'{da16_map[sz]}\t{addr}, {reg}')
                if sz in da24_map:
                    forms.append(f'{da24_map[sz]}\t{addr}, {reg}')
                if forms:
                    return forms

        # ── LD/LDW (direct_addr), imm — store immediate to direct address ──
        if op in ('ld', 'ldw') and _is_direct(op0) and op1.lstrip('-').isdigit():
            addr = _direct_addr(op0)
            imm = op1
            forms = []
            if op == 'ld':
                if addr <= 0xFFFF:
                    forms.append(f'stdi8\t{addr}, {imm}')
                forms.append(f'sti8_24\t{addr}, {imm}')
            else:  # ldw
                if addr <= 0xFFFF:
                    forms.append(f'stdi16\t{addr}, {imm}')
                forms.append(f'sti16_24\t{addr}, {imm}')
            if forms:
                return forms

        # ── ALU reg, (direct_addr) — load direction ──
        ALU_DA_OPS = {'add', 'adc', 'sub', 'sbc', 'and', 'xor', 'or', 'cp'}
        if op in ALU_DA_OPS and not _is_direct(op0) and _is_direct(op1):
            reg = op0
            addr = _direct_addr(op1)
            sz = _reg_size(reg)
            da8_16 = {'add': 'addda8', 'adc': 'adcda8', 'sub': 'subda8',
                      'sbc': 'sbcda8', 'and': 'andda8', 'xor': 'xorda8',
                      'or': 'orda8', 'cp': 'cpda8'}
            da16_16 = {'add': 'addda16', 'sub': 'subda16', 'and': 'andda16',
                       'or': 'orda16', 'cp': 'cpda16'}
            da32_16 = {'add': 'addda32', 'sub': 'subda32', 'cp': 'cpda32'}
            # 24-bit addr variants
            # 24-bit addr load-direction mnemonics (exact names from InstrInfo.td)
            da8_24_map = {'add': 'addda8_24', 'adc': 'addcda8_24', 'sub': 'subda8_24',
                          'sbc': 'sbcda8_24', 'and': 'andda8_24', 'xor': 'xorda8_24',
                          'or': 'orda8_24', 'cp': 'cpda8_24'}
            da16_24_map = {'add': 'addda16_24', 'sub': 'subda16_24', 'and': 'andda16_24',
                           'xor': 'xorda16_24', 'or': 'orda16_24', 'cp': 'cpda16_24'}
            da32_24_map = {'add': 'addda32_24', 'sub': 'sub32_24', 'and': 'andda32_24',
                           'or': 'orda32_24', 'cp': 'cpda32_24'}
            forms = []
            if sz == 8:
                if addr <= 0xFFFF and op in da8_16:
                    forms.append(f'{da8_16[op]}\t{reg}, {addr}')
                if op in da8_24_map:
                    forms.append(f'{da8_24_map[op]}\t{reg}, {addr}')
            elif sz == 16:
                if addr <= 0xFFFF and op in da16_16:
                    forms.append(f'{da16_16[op]}\t{reg}, {addr}')
                if op in da16_24_map:
                    forms.append(f'{da16_24_map[op]}\t{reg}, {addr}')
            elif sz == 32:
                if addr <= 0xFFFF and op in da32_16:
                    forms.append(f'{da32_16[op]}\t{reg}, {addr}')
                if op in da32_24_map:
                    forms.append(f'{da32_24_map[op]}\t{reg}, {addr}')
            if forms:
                return forms

        # ── ALU (direct_addr), reg — store direction ──
        if op in ALU_DA_OPS and _is_direct(op0) and not op1.lstrip('-').isdigit():
            addr = _direct_addr(op0)
            reg = op1
            sz = _reg_size(reg)
            dm8_16 = {'add': 'adddm8', 'sub': 'subdm8', 'and': 'anddm8',
                      'xor': 'xordm8', 'or': 'orddm8', 'cp': 'cpdm8'}
            dm16_16 = {'add': 'adddm16', 'sub': 'subdm16', 'and': 'anddm16',
                       'xor': 'xordm16', 'or': 'orddm16', 'cp': 'cpdm16'}
            dm32_16 = {'add': 'adddm32', 'sub': 'subdm32', 'cp': 'cpdm32'}
            # 24-bit addr store-direction mnemonics (exact names from InstrInfo.td)
            dm8_24 = {'add': 'adddm8_24', 'sub': 'subdm8_24', 'and': 'anddm8_24',
                      'xor': 'xordm8_24', 'or': 'ordm8_24', 'cp': 'cpdm8_24'}
            dm16_24 = {'add': 'adddm16_24', 'sub': 'subdm16_24', 'and': 'anddm16_24',
                       'xor': 'xordm16_24', 'or': 'orddm16_24', 'cp': 'cpdm16_24'}
            dm32_24 = {'add': 'addm32_24', 'sub': 'subdm32_24', 'and': 'anddm32_24',
                       'or': 'ordm32_24', 'cp': 'cpdm32_24'}
            forms = []
            if sz == 8:
                if addr <= 0xFFFF and op in dm8_16:
                    forms.append(f'{dm8_16[op]}\t{addr}, {reg}')
                if op in dm8_24:
                    forms.append(f'{dm8_24[op]}\t{addr}, {reg}')
            elif sz == 16:
                if addr <= 0xFFFF and op in dm16_16:
                    forms.append(f'{dm16_16[op]}\t{addr}, {reg}')
                if op in dm16_24:
                    forms.append(f'{dm16_24[op]}\t{addr}, {reg}')
            elif sz == 32:
                if addr <= 0xFFFF and op in dm32_16:
                    forms.append(f'{dm32_16[op]}\t{addr}, {reg}')
                if op in dm32_24:
                    forms.append(f'{dm32_24[op]}\t{addr}, {reg}')
            if forms:
                return forms

        # ── ALU (direct_addr), imm — immediate to direct memory ──
        if op in ALU_DA_OPS and _is_direct(op0) and op1.lstrip('-').isdigit():
            addr = _direct_addr(op0)
            imm = op1
            # 8-bit op variants (C1 prefix)
            di8_16 = {'add': 'adddi8', 'adc': 'adcdi8', 'sub': 'subdi8',
                      'sbc': 'sbcdi8', 'and': 'anddi8', 'xor': 'xordi8',
                      'or': 'ordi8', 'cp': 'cpdi8'}
            # 16-bit op variants (D1 prefix) — for ldw/cpw
            di16_16 = {'add': 'adddi16', 'sub': 'subdi16', 'and': 'anddi16',
                       'or': 'ordi16', 'cp': 'cpdi16'}
            # 24-bit addr immediate mnemonics (exact names from InstrInfo.td)
            di8_24 = {'add': 'adddi8_24', 'adc': 'addci8_24', 'sub': 'subdi8_24',
                      'sbc': 'sbcdi8_24', 'and': 'anddi8_24', 'xor': 'xordi8_24',
                      'or': 'ordi8_24', 'cp': 'cpi8_24'}
            di16_24 = {'add': 'adddi16_24', 'sub': 'subdi16_24', 'and': 'anddi16_24',
                       'or': 'ordi16_24', 'cp': 'cpdi16_24'}
            forms = []
            # Try 8-bit immediate first (shorter encoding)
            if addr <= 0xFFFF and op in di8_16:
                forms.append(f'{di8_16[op]}\t{addr}, {imm}')
            if op in di8_24:
                forms.append(f'{di8_24[op]}\t{addr}, {imm}')
            # Also try 16-bit immediate forms
            if addr <= 0xFFFF and op in di16_16:
                forms.append(f'{di16_16[op]}\t{addr}, {imm}')
            if op in di16_24:
                forms.append(f'{di16_24[op]}\t{addr}, {imm}')
            if forms:
                return forms

        # ── INC/DEC N, (direct_addr) ──
        # Source direction (C1/D1): incdi8/decdi8, incdi16/decdi16
        # Dest direction (F1): incdd8/decdd8, incdd16/decdd16
        if op in ('inc', 'dec') and not _is_direct(op0) and _is_direct(op1):
            count = op0
            addr = _direct_addr(op1)
            forms = []
            if op == 'inc':
                if addr <= 0xFFFF:
                    forms += [f'incdi8\t{count}, {addr}', f'incdi16\t{count}, {addr}',
                              f'incdd8\t{count}, {addr}', f'incdd16\t{count}, {addr}']
                forms += [f'incdi8_24\t{count}, {addr}', f'incdi16_24\t{count}, {addr}',
                          f'incdd8_24\t{count}, {addr}', f'incdd16_24\t{count}, {addr}']
            else:
                if addr <= 0xFFFF:
                    forms += [f'decdi8\t{count}, {addr}', f'decdi16\t{count}, {addr}',
                              f'decdd8\t{count}, {addr}', f'decdd16\t{count}, {addr}']
                forms += [f'decdi8_24\t{count}, {addr}', f'decdi16_24\t{count}, {addr}',
                          f'decdd8_24\t{count}, {addr}', f'decdd16_24\t{count}, {addr}']
            if forms:
                return forms

        # ── BIT/SET/RES/TSET N, (direct_addr) ──
        BIT_DA_OPS = {'bit': ('bitda', 'bitda_24'), 'set': ('setda', 'setda_24'),
                      'res': ('resda', 'resda_24'), 'tset': ('tsetda', 'tsetda_24'),
                      'chg': ('chgda', 'chgda_24')}
        if op in BIT_DA_OPS and not _is_direct(op0) and _is_direct(op1):
            bit = op0
            addr = _direct_addr(op1)
            mn16, mn24 = BIT_DA_OPS[op]
            forms = []
            if addr <= 0xFFFF:
                forms.append(f'{mn16}\t{bit}, {addr}')
            forms.append(f'{mn24}\t{bit}, {addr}')
            if forms:
                return forms

        # ── LDA reg, reg (zero-displacement form) ──
        # Unidasm shows: lda XBC,XSP → ROM uses d8=0: lda_rid8 xsp, 0, xbc
        # Also try lda_ri (no-disp) and lda (mem)
        if op == 'lda' and op1 in REG32_SET:
            forms = []
            forms.append(f'lda_rid8\t{op1}, 0, {op0}')
            forms.append(f'lda_ri\t{op1}, {op0}')
            forms.append(f'lda\t{op0}, ({op1})')
            forms.append(f'lda\t{op0}, ({op1}+0)')
            return forms

        # ── LDA reg, direct_addr ──
        # Unidasm may show (0xNNNN) → DIRECT:nnn or bare 0xNNNN → decimal
        if op == 'lda':
            reg = op0
            addr_val = None
            if _is_direct(op1):
                addr_val = _direct_addr(op1)
            elif op1.isdigit():
                addr_val = int(op1)
            if addr_val is not None:
                forms = []
                if addr_val <= 0xFFFF:
                    forms.append(f'ldada\t{reg}, {addr_val}')
                forms.append(f'lda_24\t{reg}, {addr_val}')
                if forms:
                    return forms

    # ── Single operand direct address operations ──
    if len(translated_ops) == 1 and _is_direct(translated_ops[0]):
        addr = _direct_addr(translated_ops[0])
        # PUSH (direct_addr) — only 24-bit form exists (pushdi_24, D2 prefix)
        if op == 'push':
            return [f'pushdi_24\t{addr}']

    # ── JP cc, (direct_addr) — conditional jump via direct address ──
    # Only 24-bit form exists (jp_24, F2 prefix)
    if op == 'jp' and len(translated_ops) == 2:
        cc, target = translated_ops
        if _is_direct(target):
            addr = _direct_addr(target)
            return [f'jp_24\t{cc}, {addr}']

    # ── CALL cc, (direct_addr) — conditional call via direct address ──
    # Only 24-bit form exists (call_24, F2 prefix)
    if op == 'call' and len(translated_ops) == 2:
        cc, target = translated_ops
        if _is_direct(target):
            addr = _direct_addr(target)
            return [f'call_24\t{cc}, {addr}']

    # ── Memory-indirect bit operations: bit/set/res/tset/chg N, (reg) ──
    # Unidasm produces: bit 0, (XIX) → LLVM needs: bitm 0, (xix)
    MEM_BIT_OPS = {'bit': 'bitm', 'set': 'setm', 'res': 'resm',
                   'tset': 'tsetm', 'chg': 'chgm'}
    if op in MEM_BIT_OPS and len(translated_ops) == 2:
        bit_num = translated_ops[0]
        mem_op = translated_ops[1]
        if bit_num.isdigit() and mem_op.startswith('(') and not _is_direct(mem_op):
            llvm_mnem = MEM_BIT_OPS[op]
            return [f'{llvm_mnem}\t{bit_num}, {mem_op}']

    # ── Memory-indirect carry flag bit ops: orcf/andcf/xorcf N, (reg) ──
    # Unidasm produces: orcf 6, (XDE) → LLVM needs: orcfn_ri xde, 6
    MEM_CF_OPS = {'orcf': 'orcfn_ri', 'andcf': 'andcfn_ri', 'xorcf': 'xorcfn_ri'}
    if op in MEM_CF_OPS and len(translated_ops) == 2:
        bit_num = translated_ops[0]
        mem_op = translated_ops[1]
        if bit_num.isdigit() and mem_op.startswith('(') and not _is_direct(mem_op):
            # Extract register from (xde) → xde
            reg_match = re.match(r'^\((\w+)\)$', mem_op)
            if reg_match:
                reg = reg_match.group(1)
                llvm_mnem = MEM_CF_OPS[op]
                return [f'{llvm_mnem}\t{reg}, {bit_num}']

    # ── Memory-indirect stcf/ldcf: stcf N, (reg) → stcfm N, (reg) ──
    MEM_CF_OPS2 = {'stcf': 'stcfm', 'ldcf': 'ldcfm'}
    if op in MEM_CF_OPS2 and len(translated_ops) == 2:
        bit_num = translated_ops[0]
        mem_op = translated_ops[1]
        if bit_num.isdigit() and mem_op.startswith('(') and not _is_direct(mem_op):
            llvm_mnem = MEM_CF_OPS2[op]
            return [f'{llvm_mnem}\t{bit_num}, {mem_op}']

    # ── Post-increment addressing: ld (R+),reg / ld reg,(R+) / ld (R+),imm ──
    # The addr_byte encodes which register is the base pointer. The hardware only
    # uses bits 2:0 to select the register (0=XWA..7=XSP), but the upper nibble
    # varies by assembler. We generate all common upper-nibble variants and let
    # byte matching find the ROM's exact encoding.
    _PI_REG_NUM = {'xwa': 0, 'xbc': 1, 'xde': 2, 'xhl': 3,
                   'xix': 4, 'xiy': 5, 'xiz': 6, 'xsp': 7}
    def _is_postinc(s):
        return s.startswith('POSTINC:')
    def _postinc_reg(s):
        return s.split(':')[1]
    def _pi_addr_variants(reg_name):
        """Generate all plausible addr_byte values for post-increment base.
        Unidasm often misidentifies the register, so we try all 8 registers
        with common upper nibble variants and let byte matching find the right one."""
        variants = []
        for n in range(8):
            for base in [0xF0, 0xE8, 0xE0, 0xD0, 0x00]:
                variants.append(base + n)
        return variants

    if len(translated_ops) == 2 and op == 'ld':
        op0, op1 = translated_ops
        # Store to post-increment: ld (R+), reg → st_dpib/st_dpiw/st_dpil
        if _is_postinc(op0) and not _is_postinc(op1):
            base_reg = _postinc_reg(op0)
            data_reg = op1
            addr_variants = _pi_addr_variants(base_reg)
            sz = _reg_size(data_reg)
            if addr_variants and sz:
                forms = []
                mnem = {8: 'st_dpib', 16: 'st_dpiw', 32: 'st_dpil'}[sz]
                for ab in addr_variants:
                    forms.append(f'{mnem}\t{data_reg}, {ab}')
                return forms
            # Store immediate to post-increment: ld (R+), imm → stib_dpi/stiw_dpi
            imm_str = op1
            is_imm = imm_str.lstrip('-').isdigit()
            if is_imm and addr_variants:
                imm_val = int(imm_str)
                forms = []
                for ab in addr_variants:
                    forms.append(f'stib_dpi\t{ab}, {imm_val}')
                    if 0 <= imm_val <= 0xFFFF:
                        lo = imm_val & 0xFF
                        hi = (imm_val >> 8) & 0xFF
                        forms.append(f'stiw_dpi\t{ab}, {lo}, {hi}')
                return forms
        # Load from post-increment: ld reg, (R+) → ld_spib/ld_spiw/ld_spil
        if _is_postinc(op1) and not _is_postinc(op0):
            data_reg = op0
            base_reg = _postinc_reg(op1)
            addr_variants = _pi_addr_variants(base_reg)
            sz = _reg_size(data_reg)
            if addr_variants and sz:
                forms = []
                mnem = {8: 'ld_spib', 16: 'ld_spiw', 32: 'ld_spil'}[sz]
                for ab in addr_variants:
                    forms.append(f'{mnem}\t{data_reg}, {ab}')
                return forms

    # ── Generate alternative forms for compact encodings ──

    # For LD with register and small immediate: try compact forms
    if op == 'ld' and len(translated_ops) == 2:
        reg16 = {'wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp'}
        reg32 = {'xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp'}
        reg8 = {'a', 'w', 'b', 'c', 'd', 'e', 'h', 'l'}
        imm_str = translated_ops[1]
        is_imm = imm_str.lstrip('-').isdigit()

        if is_imm:
            imm_val = int(imm_str)
            if translated_ops[0] in reg16:
                forms = []
                # lds (compact small imm 0-7) → 2 bytes
                if 0 <= imm_val <= 7:
                    forms.append(f'lds\t{translated_ops[0]}, {imm_val}')
                # ldw (compact 3-byte form)
                forms.append(f'ldw\t{translated_ops[0]}, {imm_str}')
                # ld (extended 4-byte form)
                forms.append(f'ld\t{translated_ops[0]}, {imm_str}')
                return forms
            elif translated_ops[0] in reg32:
                forms = []
                if 0 <= imm_val <= 7:
                    forms.append(f'lds32\t{translated_ops[0]}, {imm_val}')
                forms.append(f'ld\t{translated_ops[0]}, {imm_str}')
                return forms
            elif translated_ops[0] in reg8:
                forms = []
                if 0 <= imm_val <= 7:
                    forms.append(f'lds8\t{translated_ops[0]}, {imm_val}')
                forms.append(f'ldb\t{translated_ops[0]}, {imm_str}')
                forms.append(f'ld\t{translated_ops[0]}, {imm_str}')
                return forms
        elif translated_ops[0] in reg16 and not translated_ops[1].startswith('REGPAIR:'):
            # Non-immediate second operand (register, not R+R)
            return [f'ldw\t{translated_ops[0]}, {translated_ops[1]}',
                    f'ld\t{translated_ops[0]}, {translated_ops[1]}']
        elif translated_ops[0] in reg8 and not translated_ops[1].startswith('REGPAIR:'):
            return [f'ldb\t{translated_ops[0]}, {translated_ops[1]}',
                    f'ld\t{translated_ops[0]}, {translated_ops[1]}']

    # For CP with register: try compact cps form
    if op == 'cp' and len(translated_ops) == 2:
        reg16 = {'wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp'}
        reg8 = {'a', 'w', 'b', 'c', 'd', 'e', 'h', 'l'}
        reg32 = {'xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp'}
        imm_str = translated_ops[1]
        is_imm = imm_str.lstrip('-').isdigit()
        if is_imm:
            imm_val = int(imm_str)
            if translated_ops[0] in reg16:
                forms = []
                if 0 <= imm_val <= 7:
                    forms.append(f'cps\t{translated_ops[0]}, {imm_val}')
                forms.append(f'cpw\t{translated_ops[0]}, {imm_str}')
                forms.append(f'cp\t{translated_ops[0]}, {imm_str}')
                return forms
            elif translated_ops[0] in reg8:
                forms = []
                if 0 <= imm_val <= 7:
                    forms.append(f'cps\t{translated_ops[0]}, {imm_val}')
                forms.append(f'cp\t{translated_ops[0]}, {imm_str}')
                return forms
            elif translated_ops[0] in reg32:
                forms = []
                if 0 <= imm_val <= 7:
                    forms.append(f'cps\t{translated_ops[0]}, {imm_val}')
                forms.append(f'cp\t{translated_ops[0]}, {imm_str}')
                return forms

    # ── Memory+immediate: try both 8-bit and 16-bit mnemonic variants ──
    # For ops like cp/ld/add/sub/etc with (mem), imm — ROM may use 16-bit encoding
    MEM_IMM_16BIT = {'cp': 'cpw', 'ld': 'ldw', 'add': 'add', 'sub': 'sub',
                     'adc': 'adc', 'sbc': 'sbc'}
    if op in MEM_IMM_16BIT and len(translated_ops) == 2:
        mem_op = translated_ops[0]
        imm_str = translated_ops[1]
        is_mem = mem_op.startswith('(') and not _is_direct(mem_op)
        is_imm = imm_str.lstrip('-').isdigit()
        if is_mem and is_imm:
            w_mnem = MEM_IMM_16BIT[op]
            forms = [f'{llvm_op}\t{mem_op}, {imm_str}']
            if w_mnem != llvm_op:
                forms.append(f'{w_mnem}\t{mem_op}, {imm_str}')
            return forms

    # ── Memory+register: try both 8-bit and 16-bit mnemonic variants ──
    # For ops like xor/add/etc with (mem), reg — ROM may use 16-bit encoding
    MEM_REG_OPS = {'xor', 'and', 'or', 'add', 'sub', 'adc', 'sbc', 'cp',
                   'ld'}
    if op in MEM_REG_OPS and len(translated_ops) == 2:
        op0, op1 = translated_ops
        is_mem0 = op0.startswith('(') and not _is_direct(op0)
        is_mem1 = op1.startswith('(') and not _is_direct(op1)
        if (is_mem0 or is_mem1) and not (is_mem0 and is_mem1):
            forms = [f'{llvm_op}\t{op0}, {op1}']
            # For ld: also try ldw/ldb
            if op == 'ld':
                forms.append(f'ldw\t{op0}, {op1}')
                forms.append(f'ldb\t{op0}, {op1}')
            elif op == 'cp':
                forms.append(f'cpw\t{op0}, {op1}')
            return forms

    # ── R+R addressing: ld reg, (base+idx) / ld (base+idx), reg / lda / jp ──
    def _is_regpair(s):
        return s.startswith('REGPAIR:')

    def _regpair_parts(s):
        """Extract (base, index) from REGPAIR:base:index marker."""
        _, base, idx = s.split(':')
        return base, idx

    if len(translated_ops) == 2:
        op0, op1 = translated_ops

        # ld reg, (base+idx) — source R+R load
        if op in ('ld', 'ldw') and not _is_regpair(op0) and _is_regpair(op1):
            base, idx = _regpair_parts(op1)
            dest = op0
            forms = []
            if dest in REG8_SET:
                forms.append(f'ld_rrb\t{dest}, {base}, {idx}')
            elif dest in REG16_SET:
                forms.append(f'ld_rrw\t{dest}, {base}, {idx}')
            elif dest in REG32_SET:
                forms.append(f'ld_rrl\t{dest}, {base}, {idx}')
            if forms:
                return forms

        # ld (base+idx), reg — destination R+R store
        if op in ('ld', 'ldw') and _is_regpair(op0) and not _is_regpair(op1):
            base, idx = _regpair_parts(op0)
            src = op1
            forms = []
            if src in REG8_SET:
                forms.append(f'st_rrb\t{src}, {base}, {idx}')
            elif src in REG16_SET:
                forms.append(f'st_rrw\t{src}, {base}, {idx}')
            elif src in REG32_SET:
                forms.append(f'st_rrl\t{src}, {base}, {idx}')
            if forms:
                return forms

        # lda reg, (base+idx) — load effective address
        if op == 'lda' and not _is_regpair(op0) and _is_regpair(op1):
            base, idx = _regpair_parts(op1)
            dest = op0
            if dest in REG32_SET:
                return [f'lda_rr\t{dest}, {base}, {idx}']

        # lda reg, base+idx (bare, no parens — unidasm format for lda)
        if op == 'lda' and _is_regpair(op0) and op1 in REG32_SET:
            # unidasm: lda XBC, XBC+WA → ops: REGPAIR:xbc:wa, xbc
            # Actually unidasm puts dest first: lda dest, src
            # But regpair marker on op0 means it was parsed as base+idx
            base, idx = _regpair_parts(op0)
            dest = op1
            return [f'lda_rr\t{dest}, {base}, {idx}']

        # jp cc, (base+idx) — jump through R+R
        if op == 'jp' and not _is_regpair(op0) and _is_regpair(op1):
            cc_str = op0
            base, idx = _regpair_parts(op1)
            # Convert condition name to number
            CC_MAP = {'f': 0, 'lt': 1, 'le': 2, 'ule': 3,
                      'pe': 4, 'mi': 5, 'z': 6, 'c': 7,
                      't': 8, 'ge': 9, 'gt': 10, 'ugt': 11,
                      'po': 12, 'pl': 13, 'nz': 14, 'nc': 15}
            cc_num = CC_MAP.get(cc_str)
            if cc_num is not None:
                return [f'jp_rr\t{cc_num}, {base}, {idx}']

    if translated_ops:
        return f'{llvm_op}\t{", ".join(translated_ops)}'
    else:
        return llvm_op


def try_llvm_encode(instruction):
    """Try to encode an instruction with LLVM. Returns bytes or None."""
    try:
        result = subprocess.run(
            [LLVM_MC, '--triple=tlcs900', '--show-encoding'],
            input=instruction + '\n',
            capture_output=True, text=True, timeout=5
        )
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return None

    if result.returncode != 0:
        return None

    for line in result.stdout.splitlines():
        m = re.search(r'[;#] encoding:\s*\[(.*?)\]', line)
        if m:
            hex_vals = re.findall(r'0x([0-9a-fA-F]{2})', m.group(1))
            return [int(v, 16) for v in hex_vals]
    return None


def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--file', type=str, help='Audit only this file')
    parser.add_argument('--verbose', '-v', action='store_true')
    parser.add_argument('--convert', action='store_true', help='Apply conversions')
    args = parser.parse_args()

    files = find_s_files(args.file)
    print(f"Scanning {len(files)} .s files...", file=sys.stderr)

    total_blocks = 0
    total_bytes = 0
    free_wins = 0
    free_win_bytes = 0
    needs_llvm = 0
    needs_llvm_bytes = 0
    cant_translate = 0
    cant_translate_bytes = 0
    data_blocks = 0

    # Track categories of failures
    failure_categories = Counter()
    success_instructions = []

    # Track per-file stats for conversion
    file_conversions = defaultdict(list)  # file -> [(start_line, end_line, old_bytes, new_instruction)]

    for fpath in files:
        blocks = extract_code_byte_blocks(fpath)
        if not blocks:
            continue

        rel = fpath.relative_to(REPO_ROOT)

        for file_path, start_line, end_line, raw_bytes in blocks:
            if len(raw_bytes) < 2:
                data_blocks += 1
                continue

            total_blocks += 1
            total_bytes += len(raw_bytes)

            # Decode with unidasm
            decoded = unidasm_decode(raw_bytes)
            if not decoded:
                cant_translate += 1
                cant_translate_bytes += len(raw_bytes)
                continue

            # For each instruction in the block
            block_free = True
            block_instructions = []

            for offset, length, mnem in decoded:
                if mnem.startswith('db') or mnem == 'max' or mnem == 'normal':
                    block_free = False
                    failure_categories['unidasm_failed'] += 1
                    continue

                # Translate to LLVM syntax
                llvm_result = translate_unidasm_to_llvm(mnem)
                if llvm_result is None:
                    block_free = False
                    failure_categories[f'no_translation: {mnem[:40]}'] += 1
                    continue

                # Handle alternative forms (list) or single form (string)
                if isinstance(llvm_result, list):
                    candidates = llvm_result
                else:
                    candidates = [llvm_result]

                # Try each candidate and find one that byte-matches
                inst_bytes = raw_bytes[offset:offset + length]
                matched_inst = None
                last_encoded = None
                last_candidate = None
                for candidate in candidates:
                    encoded = try_llvm_encode(candidate)
                    if encoded is not None and encoded == inst_bytes:
                        matched_inst = candidate
                        break
                    if encoded is not None:
                        last_encoded = encoded
                        last_candidate = candidate
                    elif last_candidate is None:
                        last_candidate = candidate

                if matched_inst is None:
                    block_free = False
                    # Categorize the failure
                    disp = last_candidate or candidates[0]
                    if last_encoded is not None:
                        failure_categories[f'byte_mismatch: {disp[:40]}'] += 1
                        if args.verbose:
                            print(f"  MISMATCH {rel}:{start_line}: "
                                  f"expected {' '.join(f'{b:02x}' for b in inst_bytes)}, "
                                  f"got {' '.join(f'{b:02x}' for b in last_encoded)} "
                                  f"for: {disp}", file=sys.stderr)
                    else:
                        failure_categories[f'llvm_cant_encode: {disp[:40]}'] += 1
                    continue

                block_instructions.append((offset, length, matched_inst))

            if block_instructions:
                if block_free:
                    free_wins += 1
                    free_win_bytes += len(raw_bytes)
                else:
                    # Partial block — some instructions convertible
                    needs_llvm += 1
                    needs_llvm_bytes += len(raw_bytes)

                if args.verbose:
                    for offset, length, inst in block_instructions:
                        tag = "FREE WIN" if block_free else "PARTIAL"
                        print(f"  {tag} {rel}:{start_line}+{offset}: {inst}")

                # Record for conversion (both full and partial)
                file_conversions[str(file_path)].append(
                    (start_line, end_line, raw_bytes, block_instructions)
                )
                success_instructions.extend(inst for _, _, inst in block_instructions)
            else:
                cant_translate += 1
                cant_translate_bytes += len(raw_bytes)

    # Report
    print("\n" + "=" * 80)
    print("FREE WINS AUDIT REPORT")
    print("=" * 80)
    print(f"\nTotal code .byte blocks: {total_blocks} ({total_bytes} bytes)")
    print(f"Free wins (fully encodable): {free_wins} ({free_win_bytes} bytes)")
    print(f"Needs LLVM work: {needs_llvm} ({needs_llvm_bytes} bytes)")
    print(f"Can't translate: {cant_translate} ({cant_translate_bytes} bytes)")
    print(f"Data/small blocks skipped: {data_blocks}")

    if failure_categories:
        print(f"\nFailure categories:")
        for cat, count in failure_categories.most_common(30):
            print(f"  {count:4d}  {cat}")

    if success_instructions:
        # Count unique instruction types
        inst_types = Counter()
        for inst in success_instructions:
            op = inst.split()[0]
            inst_types[op] += 1
        print(f"\nFree win instruction types:")
        for op, count in inst_types.most_common(20):
            print(f"  {count:4d}  {op}")

    if file_conversions:
        print(f"\nFiles with convertible blocks:")
        for fpath, convs in sorted(file_conversions.items(), key=lambda x: -len(x[1])):
            rel = Path(fpath).relative_to(REPO_ROOT)
            total_conv_bytes = sum(len(raw) for _, _, raw, _ in convs)
            print(f"  {len(convs):4d} blocks ({total_conv_bytes:5d} bytes): {rel}")

    # Apply conversions
    if args.convert and file_conversions:
        print(f"\nApplying conversions...", file=sys.stderr)
        total_applied = 0
        for fpath, convs in sorted(file_conversions.items()):
            applied = apply_conversions(fpath, convs)
            total_applied += applied
            rel = Path(fpath).relative_to(REPO_ROOT)
            print(f"  {applied} conversions applied in {rel}", file=sys.stderr)
        print(f"\nTotal: {total_applied} conversions applied.", file=sys.stderr)


def apply_conversions(file_path, conversions):
    """Apply conversions to a file using binary I/O (Latin-1 safe).

    Handles both full and partial block conversions. For partial blocks,
    emits native instructions for matched parts and .byte for gaps.
    """
    with open(file_path, 'rb') as f:
        raw = f.read()
    # IMPORTANT: use split('\n') not splitlines() because splitlines()
    # splits on Latin-1 0x85 (NEL) which appears in UTF-8 encoded comments
    lines = [line + '\n' for line in raw.decode('latin-1').split('\n')]
    if lines and lines[-1] == '\n':
        lines[-1] = ''  # Last element after split is empty if file ends with \n

    replacements = {}  # line_number (1-indexed) -> list of replacement strings
    lines_to_remove = set()

    for start_line, end_line, raw_bytes, block_instructions in conversions:
        # Safety: verify instruction offsets are within bounds
        valid_insts = [(o, l, inst) for o, l, inst in block_instructions
                       if o >= 0 and o + l <= len(raw_bytes)]
        if not valid_insts:
            continue

        # Sort instructions by offset
        sorted_insts = sorted(valid_insts, key=lambda x: x[0])

        # Build mixed output: native instructions + .byte for gaps
        new_lines = []
        pos = 0  # current position in raw_bytes

        for offset, length, llvm_inst in sorted_insts:
            # Emit .byte for gap before this instruction
            if offset > pos:
                gap_bytes = raw_bytes[pos:offset]
                new_lines.append(_format_byte_line(gap_bytes))

            # Emit the native instruction
            new_lines.append(f'\t{llvm_inst}\n')
            pos = offset + length

        # Emit .byte for any trailing gap
        if pos < len(raw_bytes):
            gap_bytes = raw_bytes[pos:]
            new_lines.append(_format_byte_line(gap_bytes))

        # Safety: verify the generated content encodes the same bytes
        # Count bytes: each .byte line contributes its values, each native
        # instruction contributes its length
        total_gen_bytes = sum(l for _, l, _ in sorted_insts)
        total_gap_bytes = len(raw_bytes) - total_gen_bytes
        if total_gen_bytes + total_gap_bytes != len(raw_bytes):
            print(f"  WARNING: byte count mismatch in {file_path}:{start_line}, skipping",
                  file=sys.stderr)
            continue

        # Find the .byte lines in this range
        byte_line_numbers = []
        for line_no in range(start_line, end_line + 1):
            if line_no <= len(lines):
                line = lines[line_no - 1]
                if BYTE_LINE_RE.match(line):
                    byte_line_numbers.append(line_no)

        if not byte_line_numbers:
            continue

        # Verify: total bytes from original .byte lines should match raw_bytes
        orig_byte_count = 0
        for ln in byte_line_numbers:
            m = BYTE_LINE_RE.match(lines[ln - 1])
            if m:
                orig_byte_count += len(BYTE_VAL_RE.findall(m.group(1)))
        if orig_byte_count != len(raw_bytes):
            print(f"  WARNING: original byte count {orig_byte_count} != "
                  f"raw_bytes {len(raw_bytes)} in {file_path}:{start_line}, skipping",
                  file=sys.stderr)
            continue

        # Replace first .byte line with the new content
        replacements[byte_line_numbers[0]] = new_lines
        # Mark remaining .byte lines for removal
        for ln in byte_line_numbers[1:]:
            lines_to_remove.add(ln)

    if not replacements and not lines_to_remove:
        return 0

    # Build new file content
    new_lines_list = []
    for i, line in enumerate(lines, 1):
        if i in lines_to_remove:
            continue
        if i in replacements:
            new_lines_list.extend(replacements[i])
        else:
            new_lines_list.append(line)

    # Write back using binary I/O
    new_content = ''.join(new_lines_list).encode('latin-1')
    with open(file_path, 'wb') as f:
        f.write(new_content)

    return len(replacements)


def _format_byte_line(byte_vals):
    """Format a sequence of bytes as a .byte directive line."""
    if not byte_vals:
        return ''
    hex_strs = [f'0x{b:02x}' for b in byte_vals]
    # Split into lines of max 8 bytes each
    result = []
    for i in range(0, len(hex_strs), 8):
        chunk = hex_strs[i:i+8]
        result.append(f'\t.byte {", ".join(chunk)}\n')
    return ''.join(result)


if __name__ == '__main__':
    main()
