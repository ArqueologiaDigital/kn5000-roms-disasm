#!/usr/bin/env python3
"""
ASL-to-LLVM Assembly Converter for KN5000 ROM disassembly.

Converts ASL (Alfred Arnold's Macro Assembler) assembly files to LLVM
assembly syntax for the TLCS-900 target. Processes the main assembly file
and all its includes, producing parallel .s files under maincpu/llvm/.

Strategy: Each CPU instruction is emitted as a .byte sequence from the
original ROM binary, preserving the original ASL syntax as a comment.
Data directives (db, dw, dd, binclude) and labels are converted to LLVM
equivalents. Native LLVM instructions progressively replace .byte
fallbacks where the LLVM backend supports them.

Usage:
    python scripts/asl_to_llvm.py maincpu/kn5000_v10_program.asm
"""

import bisect
import os
import re
import sys
from pathlib import Path


# ============================================================================
# Configuration
# ============================================================================

BASE_DIR = Path(".")
LLVM_DIR = BASE_DIR / "maincpu" / "llvm"
ROM_BASE = 0xE00000
ROM_SIZE = 0x200000  # 2MB

# Original ROM for byte extraction
ORIGINAL_ROM = None  # Loaded on demand

# Set of known macro names
KNOWN_MACROS = set()

# Known EQU values (for resolving symbol addresses in ORG and data directives)
KNOWN_EQUS = {}

# Address → label name mapping for symbolic references in JP/CALL
ADDR_TO_LABEL = {}
ADDR_TO_LABEL_ALL = {}

# LABEL_XXXXXX collected for .set emission (suppressed from inline).
# Inline labels may have position drift; .set has exact ORG addresses.
SET_ONLY_LABELS = {}  # label_name -> addr

# Labels that conflict with register or condition code names (case-insensitive).
# These cannot be used as branch targets in native JR/JRL/CALR instructions.
RESERVED_LABEL_NAMES = {
    'a', 'w', 'b', 'c', 'e', 'l',                # 8-bit registers
    'wa', 'bc', 'de', 'hl', 'ix', 'iy', 'iz', 'sp',  # 16-bit registers
    'xwa', 'xbc', 'xde', 'xhl', 'xix', 'xiy', 'xiz', 'xsp',  # 32-bit registers
    'sr', 'f',                                      # special registers
    'z', 'nz', 'c', 'nc', 'ov', 'nov', 'mi', 'pl',   # condition codes
    'lt', 'le', 'ge', 'gt', 'ule', 'ugt', 't',
}

# TLCS-900 condition code names for JR/JRL/JPcc instructions
TLCS900_CC_NAMES = {
    0x0: 'f', 0x1: 'lt', 0x2: 'le', 0x3: 'ule',
    0x4: 'ov', 0x5: 'mi', 0x6: 'z', 0x7: 'c',
    0x8: 't', 0x9: 'ge', 0xa: 'gt', 0xb: 'ugt',
    0xc: 'nov', 0xd: 'pl', 0xe: 'nz', 0xf: 'nc',
}

# Register index-to-name tables (for decoding opcodes with embedded register index)
REG8_BY_INDEX = {0: 'w', 1: 'a', 2: 'b', 3: 'c', 4: 'd', 5: 'e', 6: 'h', 7: 'l'}
REG16_BY_INDEX = {0: 'wa', 1: 'bc', 2: 'de', 3: 'hl', 4: 'ix', 5: 'iy', 6: 'iz', 7: 'sp'}
REG32_BY_INDEX = {0: 'xwa', 1: 'xbc', 2: 'xde', 3: 'xhl', 4: 'xix', 5: 'xiy', 6: 'xiz', 7: 'xsp'}

# For 8-bit direct addressing: the sub-opcode reg index uses 8-bit register numbering
# (W=0, A=1, B=2, C=3, D=4, E=5, H=6, L=7). The LLVM GPR register class can only
# encode the low-byte registers (A, C, E, L) via sub_8bit extraction. The high-byte
# registers (W, B, D, H) at even indices are NOT encodable and must fall back to .byte.
REG8_TO_GPR = {1: 'xwa', 3: 'xbc', 5: 'xde', 7: 'xhl'}

# Statistics counters for native vs fallback instructions
NATIVE_INSTR_COUNT = 0
BYTE_FALLBACK_COUNT = 0


def load_original_rom():
    """Load the original ROM binary for byte extraction."""
    global ORIGINAL_ROM
    rom_path = BASE_DIR / "original_ROMs" / "kn5000_v10_program.rom"
    if rom_path.exists():
        ORIGINAL_ROM = rom_path.read_bytes()
        print(f"  Loaded original ROM: {rom_path} ({len(ORIGINAL_ROM)} bytes)")
    else:
        print(f"  WARNING: Original ROM not found: {rom_path}")
        print(f"  Instructions will be emitted as comments only.")
        ORIGINAL_ROM = None


def get_rom_bytes(addr, count):
    """Get bytes from the original ROM at the given absolute address."""
    if ORIGINAL_ROM is None:
        return None
    offset = addr - ROM_BASE
    if offset < 0 or offset + count > len(ORIGINAL_ROM):
        return None
    return ORIGINAL_ROM[offset:offset + count]


# ============================================================================
# Hex conversion
# ============================================================================

def convert_hex_in_text(text):
    """Convert all ASL hex literals to 0x format.

    ASL hex: starts with digit, hex chars, ends with h/H.
    Examples: 0FFh → 0xFF, 2eh → 0x2E, 0E00000h → 0xE00000
    """
    def replacer(m):
        hex_digits = m.group(0)[:-1]  # Remove trailing 'h'
        stripped = hex_digits.lstrip('0') or '0'
        return '0x' + stripped
    return re.sub(r'\b[0-9][0-9A-Fa-f]*[hH]\b', replacer, text)


def convert_expression(expr):
    """Convert an ASL expression to LLVM syntax."""
    expr = convert_hex_in_text(expr)
    expr = re.sub(r'(?<!\w)\$(?!\w)', '.', expr)
    return expr


# ============================================================================
# Operand and comment parsing
# ============================================================================

def split_comment(line):
    """Split line into code and comment parts, respecting quoted strings."""
    in_string = False
    for i, ch in enumerate(line):
        if ch == '"':
            in_string = not in_string
        elif ch == ';' and not in_string:
            return line[:i], line[i:]
    return line, ""


def split_operands(text):
    """Split operand string by commas, respecting parentheses and quotes."""
    parts = []
    depth = 0
    current = ""
    in_string = False
    for ch in text:
        if ch == '"':
            in_string = not in_string
            current += ch
        elif in_string:
            current += ch
        elif ch == '(':
            depth += 1
            current += ch
        elif ch == ')':
            depth -= 1
            current += ch
        elif ch == ',' and depth == 0:
            parts.append(current.strip())
            current = ""
        else:
            current += ch
    if current.strip():
        parts.append(current.strip())
    return parts


def extract_label(code):
    """Extract label from beginning of code line (NAME: pattern)."""
    m = re.match(r'^(\w+):\s*(.*)', code)
    if m:
        return m.group(1), m.group(2)
    return None, code


def get_first_word(text):
    """Get the first whitespace-delimited word and remainder."""
    text = text.strip()
    m = re.match(r'(\S+)\s*(.*)', text)
    if m:
        return m.group(1), m.group(2)
    return text, ""


# ============================================================================
# Address tracking
# ============================================================================

class AddressTracker:
    """Track the current assembly address for ROM byte extraction."""

    def __init__(self):
        self.current_addr = None
        self.frozen = False

    def set_org(self, addr):
        """Set address from ORG directive."""
        if not self.frozen:
            self.current_addr = addr

    def advance(self, nbytes):
        """Advance address by N bytes."""
        if self.current_addr is not None and not self.frozen:
            self.current_addr += nbytes

    def get_addr(self):
        return self.current_addr

    def freeze(self):
        """Freeze: advance/set_org become no-ops. Used inside macro defs."""
        self.frozen = True

    def unfreeze(self):
        """Unfreeze: resume normal tracking."""
        self.frozen = False


# Global address tracker
ADDR_TRACKER = AddressTracker()

# Block byte buffer context: when set, byte-emitting functions (instructions,
# data directives) read from this buffer instead of ORIGINAL_ROM. A "block" is
# the region between two consecutive self-correction labels. Since label
# addresses are known-correct, the bytes in the block are guaranteed correct.
# Instruction sizing errors only affect line breaks, not content or total count.
BLOCK_BUFFER = None      # byte buffer for current block (ROM slice)
BLOCK_CURSOR = 0         # position within block buffer
BLOCK_SIZE = 0           # total size of block (next_label - this_label)
BLOCK_START_ADDR = 0     # absolute address of block start
_SAVED_BLOCK_BUFFER = None  # saved during macro definitions

# Segment-level tracking for the overall segment
SEG_START_ADDR = 0     # start address of segment
SEG_END_ADDR = 0       # end address of segment (next segment start)

# Pending .org corrections from self-correction at labels
PENDING_ORG_CORRECTIONS = []

# Self-correction flag: set by convert_line() when self-correction occurs
SELF_CORRECTION_TRIGGERED = False
SELF_CORRECTION_ADDR = 0

# Macro expansion sizes: maps macro name (upper) → number of leaf instructions.
# Inline macros (defined in source) may expand to multiple instructions.
# tmp94c241.inc macros are all single-instruction (verified).
# Used to emit the correct number of ROM bytes at invocation sites.
MACRO_INSTR_COUNT = {}

# Current macro being defined (for counting instructions during definition)
CURRENT_MACRO_DEF_NAME = None
CURRENT_MACRO_INSTR_COUNT = 0

# Macro definition depth: when > 0, we're inside a .macro/.endm block.
# Lines in macro bodies are converted but must NOT advance ADDR_TRACKER
# because the LLVM assembler stores them without emitting bytes.
IN_MACRO_DEF = 0

# Conditional assembly state: tracks IF/ELSE/ENDIF
# For maincpu, INIT_FLAG_COMPARE_WORD=0, so IF evaluates to false
COND_STATE = {
    'active': True,     # Whether we're currently in an active (emitting) branch
    'depth': 0,         # Nesting depth
    'seen_else': False, # Whether we've seen ELSE at current depth
}

# TLCS-900 instruction encoding sizes (for common instructions)
# Maps (mnemonic_lower, operand_pattern) → byte_count
# This is used to extract the right number of bytes from the ROM.
# For variable-length instructions, we use heuristics based on addressing modes.

# Instead of trying to predict instruction lengths, we compute them from
# the ASL listing file or from the distance between adjacent ORG addresses.
# For Phase 1, we'll use the ASL listing file approach.

# Actually, the simplest approach: parse the ASL listing (.lst) file
# to get the exact byte encoding of each instruction. But that requires
# running ASL first.

# Even simpler: since we have the original ROM and ORG addresses tell us
# where blocks start, we can compute instruction sizes by reading the
# opcode bytes from the ROM and using the TLCS-900 instruction length table.

# Simplest practical approach: use the ASL-assembled ROM (rebuilt) which
# we know is 100% byte-identical. We read it and emit byte sequences
# between ORG boundaries.


# ============================================================================
# Instruction size table for TLCS-900/H2
# ============================================================================

def _extended_addr_overhead(data, pos):
    """Get prefix overhead bytes for extended addressing modes (x0-x5).

    The low 3 bits of the first byte select the sub-mode:
      0: (imm8) = 1 byte
      1: (imm16) = 2 bytes
      2: (imm24) = 3 bytes
      3: register-based (variable, sub-decoded)
      4: (-R32) = 1 byte
      5: (R32+) = 1 byte
    """
    mode = data[pos - 1] & 0x07
    if mode == 0: return 1
    if mode == 1: return 2
    if mode == 2: return 3
    if mode == 4: return 1
    if mode == 5: return 1
    # mode == 3: register-based, read next byte
    if pos >= len(data):
        return 1
    imm = data[pos]
    low2 = imm & 0x03
    if low2 == 0: return 1    # (R32)
    if low2 == 1: return 3    # (R32+d16)
    if low2 == 2: return 1    # reserved
    # low2 == 3: further sub-decode
    if imm in (0x03, 0x07): return 3  # (R32+R8), (R32+R16)
    if imm == 0x13: return 3          # (PC+d16)
    return 1  # unknown variant


# Sub-opcode operand byte tables for prefixed instructions.
# Each table maps sub-opcode (0x00-0xFF) to extra operand bytes
# consumed AFTER the sub-opcode byte itself.

# Byte-size memory operations (mnemonic_80/88/c0)
_SUB_BYTES_80 = [0] * 256
for _i in range(0x38, 0x40): _SUB_BYTES_80[_i] = 1   # ALU M,I8
_SUB_BYTES_80[0x19] = 2  # LD (M16),M

# Word-size memory operations (mnemonic_90/98/d0)
_SUB_BYTES_90 = [0] * 256
for _i in range(0x38, 0x40): _SUB_BYTES_90[_i] = 2   # ALU M,I16
_SUB_BYTES_90[0x19] = 2  # LD (M16),M

# Long-word memory operations (mnemonic_a0)
_SUB_BYTES_A0 = [0] * 256

# Mixed-size memory operations (mnemonic_b0/b8/f0)
_SUB_BYTES_B0 = [0] * 256
_SUB_BYTES_B0[0x00] = 1  # LD M,I8
_SUB_BYTES_B0[0x02] = 2  # LD M,I16
_SUB_BYTES_B0[0x14] = 2  # LD M,M16
_SUB_BYTES_B0[0x16] = 2  # LDW M,M16

# Byte register-direct operations (mnemonic_c8)
_SUB_BYTES_C8 = [0] * 256
_SUB_BYTES_C8[0x03] = 1   # LD R,I8
for _i in (0x08, 0x09, 0x0A, 0x0B): _SUB_BYTES_C8[_i] = 1  # MUL/DIV R,I8
_SUB_BYTES_C8[0x1C] = 1   # DJNZ R,D8
for _i in range(0x20, 0x25): _SUB_BYTES_C8[_i] = 1  # ANDCF/ORCF/XORCF/LDCF/STCF I8,R
_SUB_BYTES_C8[0x2E] = 1   # LDC CR8,R
_SUB_BYTES_C8[0x2F] = 1   # LDC R,CR8
for _i in range(0x30, 0x35): _SUB_BYTES_C8[_i] = 1  # RES/SET/CHG/BIT/TSET I8,R
for _i in range(0xC8, 0xD0): _SUB_BYTES_C8[_i] = 1  # ALU R,I8
for _i in range(0xE8, 0xF0): _SUB_BYTES_C8[_i] = 1  # shift I8,R

# Word register-direct operations (mnemonic_d8)
_SUB_BYTES_D8 = [0] * 256
_SUB_BYTES_D8[0x03] = 2   # LD R,I16
for _i in (0x08, 0x09, 0x0A, 0x0B): _SUB_BYTES_D8[_i] = 2  # MUL/DIV R,I16
_SUB_BYTES_D8[0x1C] = 1   # DJNZ R,D8
for _i in range(0x20, 0x25): _SUB_BYTES_D8[_i] = 1  # ANDCF/ORCF/XORCF/LDCF/STCF I8,R
_SUB_BYTES_D8[0x2E] = 1   # LDC CR16,R
_SUB_BYTES_D8[0x2F] = 1   # LDC R,CR16
for _i in range(0x30, 0x35): _SUB_BYTES_D8[_i] = 1  # RES/SET/CHG/BIT/TSET I8,R
for _i in range(0x38, 0x3F): _SUB_BYTES_D8[_i] = 2  # MINC/MDEC I16,R
for _i in range(0xC8, 0xD0): _SUB_BYTES_D8[_i] = 2  # ALU R,I16
for _i in range(0xE8, 0xF0): _SUB_BYTES_D8[_i] = 1  # shift I8,R

# Long register-direct operations (mnemonic_e8)
_SUB_BYTES_E8 = [0] * 256
_SUB_BYTES_E8[0x03] = 4   # LD R,I32
_SUB_BYTES_E8[0x0C] = 2   # LINK R,I16
_SUB_BYTES_E8[0x2E] = 1   # LDC CR32,R
_SUB_BYTES_E8[0x2F] = 1   # LDC R,CR32
for _i in range(0xC8, 0xD0): _SUB_BYTES_E8[_i] = 4  # ALU R,I32
for _i in range(0xE8, 0xF0): _SUB_BYTES_E8[_i] = 1  # shift I8,R

# Simple instruction lengths for first byte 0x00-0x7F
_SIMPLE_LENGTHS = [
    1, 1, 1, 1, 1, 1, 2, 1,  # 00-07: NOP, NORMAL, PUSH SR, POP SR, MAX, HALT, EI I8, RETI
    3, 2, 4, 3, 1, 1, 1, 3,  # 08-0F: LD(8)I8, PUSH I8, LD(8)I16, PUSH I16, INCF, DECF, RET, RETD I16
    1, 1, 1, 1, 1, 1, 1, 2,  # 10-17: RCF, SCF, CCF, ZCF, PUSH A, POP A, EX F,F', LDF I8
    1, 1, 3, 4, 3, 4, 3, 1,  # 18-1F: PUSH F, POP F, JP I16, JP I24, CALL I16, CALL I24, CALR D16, DB
    2, 2, 2, 2, 2, 2, 2, 2,  # 20-27: LD r8, I8
    1, 1, 1, 1, 1, 1, 1, 1,  # 28-2F: PUSH r16
    3, 3, 3, 3, 3, 3, 3, 3,  # 30-37: LD r16, I16
    1, 1, 1, 1, 1, 1, 1, 1,  # 38-3F: PUSH r32
    5, 5, 5, 5, 5, 5, 5, 5,  # 40-47: LD r32, I32
    1, 1, 1, 1, 1, 1, 1, 1,  # 48-4F: POP r16
    1, 1, 1, 1, 1, 1, 1, 1,  # 50-57: DB (invalid)
    1, 1, 1, 1, 1, 1, 1, 1,  # 58-5F: POP r32
    2, 2, 2, 2, 2, 2, 2, 2,  # 60-67: JR cc, D8
    2, 2, 2, 2, 2, 2, 2, 2,  # 68-6F: JR cc, D8
    3, 3, 3, 3, 3, 3, 3, 3,  # 70-77: JRL cc, D16
    3, 3, 3, 3, 3, 3, 3, 3,  # 78-7F: JRL cc, D16
]


def get_instruction_size_from_rom(addr):
    """Determine instruction size by reading opcode bytes from the ROM.

    TLCS-900 instructions are 1-7 bytes. The first byte determines the
    instruction class and length. Based on MAME's dasm900.cpp.
    """
    if ORIGINAL_ROM is None or addr is None:
        return None

    offset = addr - ROM_BASE
    if offset < 0 or offset >= len(ORIGINAL_ROM):
        return None

    b0 = ORIGINAL_ROM[offset]

    # Simple instructions (0x00-0x7F)
    if b0 < 0x80:
        return _SIMPLE_LENGTHS[b0]

    # Special cases first
    if b0 in (0xC6, 0xD6, 0xE6, 0xF6):
        return 1  # Invalid opcodes
    if b0 == 0xF7:
        return 6  # LDX
    if b0 >= 0xF8:
        return 1  # SWI (3-bit imm embedded)

    hi = b0 >> 4
    lo = b0 & 0x0F

    # Determine prefix overhead and sub-opcode table
    if hi <= 0x0B:  # 0x80-0xBF: register-based prefixes
        has_disp = (b0 & 0x08) != 0
        prefix_overhead = 1 if has_disp else 0

        if hi == 0x08:
            sub_table = _SUB_BYTES_80
        elif hi == 0x09:
            sub_table = _SUB_BYTES_90
        elif hi == 0x0A:
            sub_table = _SUB_BYTES_A0
        else:  # 0x0B
            sub_table = _SUB_BYTES_B0
    else:
        # 0xC0-0xF5: extended addressing or register-direct
        if lo <= 5:
            # Extended addressing (C0-C5, D0-D5, E0-E5, F0-F5)
            prefix_overhead = _extended_addr_overhead(ORIGINAL_ROM, offset + 1)
            if hi == 0x0C:
                sub_table = _SUB_BYTES_80  # byte operations
            elif hi == 0x0D:
                sub_table = _SUB_BYTES_90  # word operations
            elif hi == 0x0E:
                sub_table = _SUB_BYTES_A0  # long operations
            else:  # 0x0F
                sub_table = _SUB_BYTES_B0  # mixed operations
        elif lo == 7:
            # All-register selector (C7, D7, E7)
            prefix_overhead = 1
            if hi == 0x0C:
                sub_table = _SUB_BYTES_C8
            elif hi == 0x0D:
                sub_table = _SUB_BYTES_D8
            else:  # 0x0E
                sub_table = _SUB_BYTES_E8
        else:
            # Current register set (C8-CF, D8-DF, E8-EF)
            prefix_overhead = 0
            if hi == 0x0C:
                sub_table = _SUB_BYTES_C8
            elif hi == 0x0D:
                sub_table = _SUB_BYTES_D8
            else:  # 0x0E
                sub_table = _SUB_BYTES_E8

    # Read the sub-opcode
    sub_offset = offset + 1 + prefix_overhead
    if sub_offset >= len(ORIGINAL_ROM):
        return None
    sub_opcode = ORIGINAL_ROM[sub_offset]

    return 1 + prefix_overhead + 1 + sub_table[sub_opcode]


# ============================================================================
# Include path computation
# ============================================================================

def compute_llvm_include_path(include_path, from_file):
    """Compute the .include path for LLVM output."""
    if include_path.endswith('.inc'):
        new_path = include_path.replace('.inc', '.inc.s')
    elif include_path.endswith('.asm'):
        new_path = include_path.replace('.asm', '.s')
    else:
        new_path = include_path + '.s'

    clean_path = new_path
    while clean_path.startswith('../'):
        clean_path = clean_path[3:]
    return clean_path


# ============================================================================
# Directive classification
# ============================================================================

# ASL CPU instructions (mnemonics recognized by ASL for TLCS-900)
ASL_INSTRUCTIONS = {
    'LD', 'LDW', 'LDA', 'PUSH', 'POP', 'PUSHW', 'POPW',
    'ADD', 'ADC', 'SUB', 'SBC', 'AND', 'OR', 'XOR', 'CP',
    'ADDW', 'ADCW', 'SUBW', 'SBCW', 'CPW',
    'INC', 'INCW', 'DEC', 'DECW',
    'MUL', 'MULS', 'DIV', 'DIVS', 'MULW', 'DIVW',
    'SRL', 'SRLW', 'SRA', 'SLA', 'SLL', 'SLLW', 'RL', 'RLC', 'RR', 'RRC',
    'SET', 'RES', 'BIT', 'TSET', 'CHG',
    'JP', 'JR', 'JRL', 'CALL', 'RET', 'RETI', 'RETD',
    'HALT', 'NOP', 'EI', 'DI', 'SWI',
    'CCF', 'SCF', 'RCF', 'ZCF',
    'EX', 'EXTZ', 'EXTS', 'DAA',
    'NEG', 'CPL', 'MIRR',
    'LDC', 'LDCF', 'STCF',
    'ANDCF', 'ORCF', 'XORCF',
    'ORW', 'ANDW', 'XORW', 'ADDW',
    'LDIR', 'LDDR', 'LDI', 'LDD',
    'LDIRW', 'LDDRW', 'LDIW', 'LDDW',
    'CPIR', 'CPDR',
    'LINK', 'UNLK',
    'DJNZ', 'MINC1', 'MINC2', 'MINC4', 'MDEC1', 'MDEC2', 'MDEC4',
    'SCC', 'BS1F', 'BS1B',
    'CALR',
}

# Data directives (produce bytes directly)
DATA_DIRECTIVES = {'DB', 'DW', 'DD', 'DS'}


def is_instruction(word):
    """Check if word is a CPU instruction mnemonic."""
    return word.upper() in ASL_INSTRUCTIONS


def is_data_directive(word):
    """Check if word is a data directive."""
    return word.upper() in DATA_DIRECTIVES


def is_macro_invocation(word):
    """Check if word is a known macro invocation."""
    return word.upper() in KNOWN_MACROS


# ============================================================================
# Line-by-line conversion
# ============================================================================

def convert_line(line, in_file_path):
    """Convert a single ASL assembly line to LLVM syntax.

    Returns the converted line string.
    """
    global IN_MACRO_DEF, CURRENT_MACRO_DEF_NAME, CURRENT_MACRO_INSTR_COUNT
    global BLOCK_BUFFER, BLOCK_CURSOR, SELF_CORRECTION_TRIGGERED, SELF_CORRECTION_ADDR
    global _SAVED_BLOCK_BUFFER
    global NATIVE_INSTR_COUNT, BYTE_FALLBACK_COUNT

    stripped = line.rstrip()
    if not stripped:
        return "" if COND_STATE['active'] else None

    # Extract comment
    code_part, comment = split_comment(stripped)
    code_stripped = code_part.rstrip()

    # Check for IF/ELSE/ENDIF before anything else
    # (these must be processed even when inactive)
    test_code = code_stripped
    if not test_code:
        # Pure comment — skip if in inactive branch
        if not COND_STATE['active']:
            return None
        return stripped

    _, test_rest = extract_label(test_code)
    test_rest = test_rest.strip()
    if test_rest:
        test_word, test_remainder = get_first_word(test_rest)
        test_upper = test_word.upper()

        if test_upper == 'IF':
            if COND_STATE['depth'] == 0:
                # Evaluate condition: for maincpu, INIT_FLAG_COMPARE_WORD=0
                cond_name = test_remainder.strip()
                cond_val = KNOWN_EQUS.get(cond_name, 0)
                COND_STATE['depth'] = 1
                COND_STATE['active'] = bool(cond_val)
                COND_STATE['seen_else'] = False
                return f"\t; IF {cond_name} (evaluated to {'true' if cond_val else 'false'} for maincpu)"
            else:
                COND_STATE['depth'] += 1
                return None

        if test_upper == 'ELSE':
            if COND_STATE['depth'] == 1:
                COND_STATE['active'] = not COND_STATE['active']
                COND_STATE['seen_else'] = True
                return f"\t; ELSE"
            return None

        if test_upper == 'ENDIF':
            if COND_STATE['depth'] == 1:
                COND_STATE['depth'] = 0
                COND_STATE['active'] = True
                COND_STATE['seen_else'] = False
                return f"\t; ENDIF"
            elif COND_STATE['depth'] > 1:
                COND_STATE['depth'] -= 1
            return None

    # If we're in an inactive branch, skip this line
    if not COND_STATE['active']:
        return None

    # Pure comment line
    if not code_stripped:
        return stripped

    # Parse label
    label, rest = extract_label(code_stripped)
    rest = rest.strip()

    # Self-correct address tracker and segment cursor at labels with known addresses.
    # Labels like LABEL_XXXXXX encode their address in the name.
    # This resets ADDR_TRACKER and SEG_CURSOR to eliminate cumulative drift.
    # Skip labels that are EQU definitions (they alias other names, not addresses).
    is_equ_line = rest and re.match(r'^EQU\b', rest.strip(), re.IGNORECASE)
    if label and ADDR_TRACKER.get_addr() is not None and not is_equ_line:
        expected_addr = None
        m_lbl = re.match(r'^LABEL_([0-9A-Fa-f]{6})$', label)
        if m_lbl:
            expected_addr = int(m_lbl.group(1), 16)
        elif comment:
            m_addr = re.match(r'^;\s*([0-9A-Fa-f]{6})\s*$', comment.strip())
            if m_addr:
                expected_addr = int(m_addr.group(1), 16)
        if expected_addr is not None:
            actual_addr = ADDR_TRACKER.get_addr()
            # Skip backward corrections: these indicate data-section labels
            # with ORG-derived names at different sequential addresses.
            if actual_addr is not None and expected_addr < actual_addr:
                pass  # Backward label — keep current tracker position
            else:
                if expected_addr != actual_addr:
                    ADDR_TRACKER.set_org(expected_addr)
                # Signal block boundary to convert_all() for EVERY forward
                # address-encoding label. Blocks are sized between consecutive
                # labels, limiting instruction sizing error accumulation.
                if BLOCK_BUFFER is not None:
                    if SEG_START_ADDR <= expected_addr <= SEG_END_ADDR:
                        SELF_CORRECTION_TRIGGERED = True
                        SELF_CORRECTION_ADDR = expected_addr

        # Suppress LABEL_XXXXXX inline emission when on a line WITH an instruction.
        # Those labels can drift because instruction bytes are consumed before
        # block correction padding. Label-only lines are safe (no bytes consumed,
        # padding aligns the label to the correct position).
        if m_lbl and expected_addr is not None and rest:
            SET_ONLY_LABELS[label] = expected_addr
            label = None

    # Label-only line
    if not rest:
        result = f"{label}:" if label else ""
        if comment:
            result += f"\t{comment}" if label else comment
        return result

    # When a label has data AND an address comment ("; XXXXXX"), move the
    # address comment to the label line. This keeps the expected address
    # visually associated with the label rather than buried after data.
    label_addr_suffix = ""
    if label and comment and rest:
        m_addr_cmt = re.match(r'^;\s*[0-9A-Fa-f]{6}\s*$', comment.strip())
        if m_addr_cmt:
            label_addr_suffix = f"\t{comment}"
            comment = None

    # Get first word
    first_word, remainder = get_first_word(rest)
    first_upper = first_word.upper()

    # ---- ASL directives (non-code) ----

    # cpu / page / maxmode → comment
    if first_upper in ('CPU', 'PAGE', 'MAXMODE'):
        return f"\t; (ASL directive) {rest}" + (f"\t{comment}" if comment else "")

    # include → comment (includes are inlined by read_all_lines)
    if first_upper == 'INCLUDE':
        path_str = remainder.strip().strip('"').strip("'")
        return f"\t; (include inlined) {path_str}"

    # EQU → .equ
    if first_upper == 'EQU':
        value = convert_expression(remainder.strip())
        result = f".equ {label}, {value}"
        if comment:
            result += f"\t{comment}"
        # Track the value for address resolution
        try:
            KNOWN_EQUS[label] = eval_expr(value)
        except:
            pass
        return result

    # NAME EQU value (no colon on NAME)
    if re.match(r'^EQU(?:\s|$)', remainder.strip(), re.IGNORECASE):
        equ_match = re.match(r'EQU\s+(.*)', remainder.strip(), re.IGNORECASE)
        if equ_match:
            value = convert_expression(equ_match.group(1).strip())
            name = first_word
            result = f".equ {name}, {value}"
            if comment:
                result += f"\t{comment}"
            try:
                KNOWN_EQUS[name] = eval_expr(value)
            except:
                pass
            return result

    # ORG → .org
    if first_upper == 'ORG':
        addr_val = resolve_org_addr(remainder.strip())
        if addr_val is not None:
            ADDR_TRACKER.set_org(addr_val)

        addr_str = convert_expression(remainder.strip())
        result = ""
        if label:
            result = f"{label}:{label_addr_suffix}\n"
        result += f"\t.org {addr_str} - 0xE00000, 0xFF"
        if comment:
            result += f"\t{comment}"
        return result

    # MACRO definition: "NAME MACRO [args]"
    if re.match(r'^MACRO(?:\s|$)', remainder.strip(), re.IGNORECASE):
        IN_MACRO_DEF += 1
        ADDR_TRACKER.freeze()
        # Disable block buffer during macro defs so .byte lines inside the
        # macro template don't consume ROM bytes. The assembler doesn't emit
        # bytes for macro definitions — only for invocations.
        if IN_MACRO_DEF == 1:
            global _SAVED_BLOCK_BUFFER
            _SAVED_BLOCK_BUFFER = BLOCK_BUFFER
            BLOCK_BUFFER = None
        macro_name = first_word
        KNOWN_MACROS.add(macro_name.upper())
        if IN_MACRO_DEF == 1:
            CURRENT_MACRO_DEF_NAME = macro_name.upper()
            CURRENT_MACRO_INSTR_COUNT = 0
        macro_match = re.match(r'MACRO\s*(.*)', remainder.strip(), re.IGNORECASE)
        args_str = macro_match.group(1).strip() if macro_match else ""
        if args_str:
            result = f".macro {macro_name} {args_str}"
        else:
            result = f".macro {macro_name}"
        if comment:
            result += f"\t{comment}"
        return result

    if first_upper == 'ENDM':
        if IN_MACRO_DEF > 0:
            if IN_MACRO_DEF == 1 and CURRENT_MACRO_DEF_NAME:
                MACRO_INSTR_COUNT[CURRENT_MACRO_DEF_NAME] = CURRENT_MACRO_INSTR_COUNT
                CURRENT_MACRO_DEF_NAME = None
            IN_MACRO_DEF -= 1
            if IN_MACRO_DEF == 0:
                ADDR_TRACKER.unfreeze()
                # Restore block buffer after macro definition
                BLOCK_BUFFER = _SAVED_BLOCK_BUFFER
        return ".endm"

    # Count instructions/macros in macro body for expansion size tracking
    if IN_MACRO_DEF > 0 and IN_MACRO_DEF == 1:
        if is_instruction(first_word):
            CURRENT_MACRO_INSTR_COUNT += 1
        elif is_macro_invocation(first_word):
            # Nested macro: add its leaf instruction count
            nested_count = MACRO_INSTR_COUNT.get(first_word.upper(), 1)
            CURRENT_MACRO_INSTR_COUNT += nested_count

    # ---- Data directives ----

    if first_upper == 'DB':
        return convert_db(label, remainder.strip(), comment, in_file_path, label_addr_suffix)

    if first_upper == 'DW':
        return convert_dw(label, remainder.strip(), comment, label_addr_suffix)

    if first_upper == 'DD':
        args_raw = remainder.strip()
        nvalues = len(split_operands(args_raw))
        nbytes = 4 * nvalues
        addr = ADDR_TRACKER.get_addr()

        # When inside a block buffer, always emit from ROM
        if BLOCK_BUFFER is not None:
            remaining = BLOCK_SIZE - BLOCK_CURSOR
            if nbytes > remaining:
                nbytes = remaining
            if nbytes > 0:
                rom_bytes = BLOCK_BUFFER[BLOCK_CURSOR:BLOCK_CURSOR + nbytes]
                original = f"DD {args_raw}"
                result = ""
                if label:
                    result = f"{label}:{label_addr_suffix}\n"
                # Emit as .long values (4 bytes each, little-endian)
                longs = []
                for i in range(0, nbytes, 4):
                    chunk = rom_bytes[i:i+4]
                    if len(chunk) == 4:
                        val = chunk[0] | (chunk[1] << 8) | (chunk[2] << 16) | (chunk[3] << 24)
                        longs.append(f'0x{val:08X}')
                    else:
                        # Partial word at end — emit as .byte
                        byte_str = ', '.join(f'0x{b:02x}' for b in chunk)
                        longs.append(None)
                        valid = [l for l in longs if l]
                        if valid:
                            long_str = ', '.join(valid)
                            result += f"\t.long {long_str}\t; {original}"
                        result += f"\n\t.byte {byte_str}"
                        break
                else:
                    long_str = ', '.join(longs)
                    result += f"\t.long {long_str}\t; {original}"
                BLOCK_CURSOR += nbytes
                ADDR_TRACKER.advance(nbytes)
                if comment:
                    result += f"\t{comment}"
                return result

        # Outside block buffer — use source-based conversion
        if _dw_has_label_refs(args_raw) and addr is not None:
            rom_bytes = get_rom_bytes(addr, nbytes)
            if rom_bytes is not None:
                result = ""
                if label:
                    result = f"{label}:{label_addr_suffix}\n"
                original = f"DD {args_raw}"
                longs = []
                for i in range(0, nbytes, 4):
                    chunk = rom_bytes[i:i+4]
                    if len(chunk) == 4:
                        val = chunk[0] | (chunk[1] << 8) | (chunk[2] << 16) | (chunk[3] << 24)
                        longs.append(f'0x{val:08X}')
                if longs:
                    long_str = ', '.join(longs)
                    result += f"\t.long {long_str}\t; {original}"
                ADDR_TRACKER.advance(nbytes)
                if comment:
                    result += f"\t{comment}"
                return result

        values = convert_expression(args_raw)
        result = ""
        if label:
            result = f"{label}:{label_addr_suffix}\n"
        result += f"\t.long {values}"
        if comment:
            result += f"\t{comment}"
        ADDR_TRACKER.advance(nbytes)
        return result

    if first_upper == 'DS':
        values = convert_expression(remainder.strip())
        result = ""
        if label:
            result = f"{label}:{label_addr_suffix}\n"
        result += f"\t.space {values}"
        if comment:
            result += f"\t{comment}"
        try:
            nbytes = eval_expr(values)
            ADDR_TRACKER.advance(nbytes)
            if BLOCK_BUFFER is not None:
                BLOCK_CURSOR += nbytes
        except:
            pass
        return result

    if first_upper == 'BINCLUDE':
        path_str = remainder.strip().strip('"').strip("'")
        bin_path = os.path.join('maincpu', path_str)
        fsize = os.path.getsize(bin_path) if os.path.exists(bin_path) else 0
        result = ""
        if label:
            result = f"{label}:{label_addr_suffix}\n"
        llvm_path = f"../{path_str}"
        result += f'\t.incbin "{llvm_path}"'
        if comment:
            result += f"\t{comment}"
        if fsize > 0:
            ADDR_TRACKER.advance(fsize)
            if BLOCK_BUFFER is not None:
                BLOCK_CURSOR += fsize
        return result

    # ---- Macro invocations ----
    if is_macro_invocation(first_word):
        # Emit as .byte fallback from ROM.
        # Inline macros may expand to multiple instructions — decode the right count.
        addr = ADDR_TRACKER.get_addr()
        instr_count = MACRO_INSTR_COUNT.get(first_word.upper(), 1)

        # Decode instr_count consecutive instructions from ROM
        nbytes = 0
        if addr is not None:
            cur = addr
            for _ in range(instr_count):
                sz = get_instruction_size_from_rom(cur)
                if sz is None:
                    break
                nbytes += sz
                cur += sz
            if nbytes == 0:
                nbytes = None

        result = ""
        if label:
            result = f"{label}:{label_addr_suffix}\n"

        if BLOCK_BUFFER is not None and nbytes is not None:
            # Use block buffer for macro bytes
            remaining = BLOCK_SIZE - BLOCK_CURSOR
            if nbytes > remaining:
                nbytes = remaining
            if nbytes > 0:
                rom_bytes = BLOCK_BUFFER[BLOCK_CURSOR:BLOCK_CURSOR + nbytes]
                # Try native conversion for single-instruction macros
                native = None
                if instr_count == 1:
                    native = try_convert_native(first_word, remainder.strip(), rom_bytes, nbytes, addr)
                if native is not None:
                    native_asm, _ = native
                    result += f"\t{native_asm}"
                    NATIVE_INSTR_COUNT += 1
                else:
                    byte_str = ', '.join(f'0x{b:02x}' for b in rom_bytes)
                    args = remainder.strip()
                    original = f"{first_word} {args}".strip() if args else first_word
                    result += f"\t.byte {byte_str}\t; {original}"
                    BYTE_FALLBACK_COUNT += 1
                BLOCK_CURSOR += nbytes
                ADDR_TRACKER.advance(nbytes)
            else:
                args = remainder.strip()
                original = f"{first_word} {args}".strip() if args else first_word
                result += f"\t; (block overflow) {original}"
        elif addr is not None and nbytes is not None:
            offset = addr - ROM_BASE
            rom_bytes = ORIGINAL_ROM[offset:offset + nbytes]
            byte_str = ', '.join(f'0x{b:02x}' for b in rom_bytes)
            args = remainder.strip()
            original = f"{first_word} {args}".strip() if args else first_word
            result += f"\t.byte {byte_str}\t; {original}"
            ADDR_TRACKER.advance(nbytes)
        else:
            # Fallback: emit the macro call (may not assemble)
            args = remainder.strip()
            if args:
                arg_list = split_operands(args)
                converted_args = [convert_expression(a) for a in arg_list]
                args_str = ', '.join(converted_args)
                result += f"\t{first_word} {args_str}"
            else:
                result += f"\t{first_word}"
        if comment:
            result += f"\t{comment}"
        return result

    # ---- CPU instructions ----
    # Emit as native LLVM syntax. If the LLVM backend doesn't support
    # the instruction, it will error. We'll fix those iteratively.
    if is_instruction(first_word):
        return convert_instruction(label, first_word, remainder.strip(), comment, label_addr_suffix)

    # ---- Unknown / fallthrough ----
    # If no operands and word looks like a label (starts with letter,
    # not a known directive), treat as a label without colon (ASL syntax)
    if not remainder.strip() and re.match(r'^[A-Za-z_]\w*$', first_word):
        result = ""
        if label:
            result = f"{label}:{label_addr_suffix}\n"
        result += f"{first_word}:"
        if comment:
            result += f"\t{comment}"
        return result

    # Otherwise preserve as-is (may cause assembler error)
    result = ""
    if label:
        result = f"{label}:{label_addr_suffix}\n"
    converted_rest = convert_expression(rest)
    result += f"\t{converted_rest}"
    if comment:
        result += f"\t{comment}"
    return result


# Tier 1: Zero-operand instructions with verified encoding match
NATIVE_ZERO_OPS = {
    'NOP': ('nop', 1),    # 0x00
    'RET': ('ret', 1),    # 0x0E
    'RETI': ('reti', 1),  # 0x07
    'HALT': ('halt', 1),  # 0x05
}

# Tier 2: 32-bit register immediate loads (5-byte encoding only)
# LLVM encodes: prefix_byte + imm32_LE (5 bytes)
# ROM also uses this encoding for non-short-form 32-bit loads.
# Short forms (2-byte, values 0-7) and 16-bit loads (3-byte) don't match LLVM.
NATIVE_LD_32BIT_REGS = {
    'XWA', 'XBC', 'XDE', 'XHL', 'XIX', 'XIY', 'XIZ', 'XSP',
}

# Tier 3: Register-register operations (2-byte encoding)
# All TLCS-900 registers
ALL_REGISTERS = {
    # 8-bit
    'W', 'A', 'B', 'C', 'D', 'E', 'H', 'L',
    # 16-bit
    'WA', 'BC', 'DE', 'HL', 'IX', 'IY', 'IZ', 'SP',
    # 32-bit
    'XWA', 'XBC', 'XDE', 'XHL', 'XIX', 'XIY', 'XIZ', 'XSP',
}

# Two-operand reg-reg ALU mnemonics (ASL → LLVM)
# ASL may use size suffixes (LDW, ADDW) but LLVM always uses base mnemonic
REGREG_ALU_OPS = {
    'LD', 'LDW', 'ADD', 'ADDW', 'SUB', 'SUBW',
    'CP', 'CPW', 'AND', 'ANDW', 'OR', 'ORW', 'XOR', 'XORW',
    'ADC', 'ADCW', 'SBC', 'SBCW',
}

# Single-operand register operations (2-byte)
SINGLE_REG_OPS = {'EXTZ', 'EXTS', 'CPL', 'NEG'}

# Register index within its size class (0-7)
REG_INDEX = {
    # 8-bit
    'W': 0, 'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'H': 6, 'L': 7,
    # 16-bit
    'WA': 0, 'BC': 1, 'DE': 2, 'HL': 3, 'IX': 4, 'IY': 5, 'IZ': 6, 'SP': 7,
    # 32-bit
    'XWA': 0, 'XBC': 1, 'XDE': 2, 'XHL': 3, 'XIX': 4, 'XIY': 5, 'XIZ': 6, 'XSP': 7,
}

# Register prefix byte (first byte of 2-byte encoding)
REG_PREFIX = {
    'W': 0xC8, 'A': 0xC9, 'B': 0xCA, 'C': 0xCB,
    'D': 0xCC, 'E': 0xCD, 'H': 0xCE, 'L': 0xCF,
    'WA': 0xD8, 'BC': 0xD9, 'DE': 0xDA, 'HL': 0xDB,
    'IX': 0xDC, 'IY': 0xDD, 'IZ': 0xDE, 'SP': 0xDF,
    'XWA': 0xE8, 'XBC': 0xE9, 'XDE': 0xEA, 'XHL': 0xEB,
    'XIX': 0xEC, 'XIY': 0xED, 'XIZ': 0xEE, 'XSP': 0xEF,
}

# ALU operation opcode base (second byte = base + dst_index)
ALU_OP_BASE = {
    'ADD': 0x80, 'LD': 0x88, 'ADC': 0x90, 'SUB': 0xA0,
    'SBC': 0xB0, 'AND': 0xC0, 'XOR': 0xD0, 'OR': 0xE0, 'CP': 0xF0,
}

# Single-reg operation opcode (second byte, fixed)
SINGLE_REG_OPCODE = {'EXTZ': 0x12, 'EXTS': 0x13, 'CPL': 0x06, 'NEG': 0x07}


def verify_regreg_encoding(rom_bytes, src_reg, dst_reg, op_base):
    """Verify ROM bytes match expected 2-byte reg-reg encoding."""
    expected_b0 = REG_PREFIX.get(src_reg)
    expected_b1 = op_base + REG_INDEX.get(dst_reg, 99)
    if expected_b0 is None or expected_b1 > 0xFF:
        return False
    return rom_bytes[0] == expected_b0 and rom_bytes[1] == expected_b1


def verify_singlereg_encoding(rom_bytes, reg, opcode):
    """Verify ROM bytes match expected 2-byte single-reg encoding."""
    expected_b0 = REG_PREFIX.get(reg)
    if expected_b0 is None:
        return False
    return rom_bytes[0] == expected_b0 and rom_bytes[1] == opcode


# Strip size suffix from ASL mnemonic to get LLVM mnemonic
def strip_size_suffix(mnem_upper):
    """Strip W/B/L size suffix from ASL mnemonic for LLVM."""
    if len(mnem_upper) > 2 and mnem_upper.endswith('W'):
        base = mnem_upper[:-1]
        if base in ('LD', 'ADD', 'SUB', 'CP', 'AND', 'OR', 'XOR', 'ADC', 'SBC'):
            return base
    return mnem_upper


def parse_asl_immediate(value_str):
    """Parse an ASL immediate value string to an integer.

    Handles: decimal (0, 42), hex with h suffix (0FFh, 00830000h).
    Returns int or None if not a simple immediate.
    """
    value_str = value_str.strip()
    # Hex with h/H suffix
    if re.match(r'^[0-9][0-9A-Fa-f]*[hH]$', value_str):
        return int(value_str[:-1], 16)
    # Plain decimal
    if re.match(r'^[0-9]+$', value_str):
        return int(value_str)
    return None


def try_convert_native(mnemonic, operands_str, rom_bytes, nbytes, addr=None):
    """Try to convert an instruction to native LLVM syntax.

    Returns (native_asm_str, expected_nbytes) or None if not supported.
    The caller must verify nbytes matches expected_nbytes for safety.
    """
    mnem_upper = mnemonic.upper()

    # Tier 1: Zero-operand instructions
    if not operands_str and mnem_upper in NATIVE_ZERO_OPS:
        native_asm, expected_size = NATIVE_ZERO_OPS[mnem_upper]
        if nbytes == expected_size:
            return native_asm, expected_size

    # Tier 2: 32-bit register immediate loads (5-byte form only)
    if mnem_upper in ('LD', 'LDW') and operands_str and nbytes == 5:
        parts = operands_str.split(',', 1)
        if len(parts) == 2:
            reg = parts[0].strip().upper()
            imm_str = parts[1].strip()
            if reg in NATIVE_LD_32BIT_REGS:
                imm_val = parse_asl_immediate(imm_str)
                if imm_val is not None:
                    native_asm = f"ld {reg.lower()}, 0x{imm_val:X}"
                    return native_asm, 5

    # Tier 3: Register-register operations (2-byte encoding)
    # Verify ROM bytes match expected encoding to catch ASL disassembly errors.
    if nbytes == 2 and operands_str and rom_bytes is not None:
        # 3a: Two-operand reg-reg ALU (LD/ADD/SUB/CP/AND/OR/XOR reg, reg)
        if mnem_upper in REGREG_ALU_OPS:
            parts = operands_str.split(',', 1)
            if len(parts) == 2:
                dst = parts[0].strip().upper()
                src = parts[1].strip().upper()
                base_mnem = strip_size_suffix(mnem_upper)
                op_base = ALU_OP_BASE.get(base_mnem)
                if (dst in ALL_REGISTERS and src in ALL_REGISTERS
                        and op_base is not None
                        and verify_regreg_encoding(rom_bytes, src, dst, op_base)):
                    native_asm = f"{base_mnem.lower()} {dst.lower()}, {src.lower()}"
                    return native_asm, 2

        # 3b: Single-operand register ops (EXTZ/EXTS/CPL/NEG reg)
        if mnem_upper in SINGLE_REG_OPS and ',' not in operands_str:
            reg = operands_str.strip().upper()
            opcode = SINGLE_REG_OPCODE.get(mnem_upper)
            if (reg in ALL_REGISTERS and opcode is not None
                    and verify_singlereg_encoding(rom_bytes, reg, opcode)):
                native_asm = f"{mnem_upper.lower()} {reg.lower()}"
                return native_asm, 2

        # 3c: INC/DEC count, reg (2-byte encoding, register only)
        if mnem_upper in ('INC', 'DEC'):
            parts = operands_str.split(',', 1)
            if len(parts) == 2:
                count_str = parts[0].strip()
                reg = parts[1].strip().upper()
                if reg in ALL_REGISTERS and '(' not in operands_str:
                    count = parse_asl_immediate(count_str)
                    if count is not None and 1 <= count <= 8:
                        inc_base = 0x60 if mnem_upper == 'INC' else 0x68
                        # Count encoded as (count % 8): 1→1, 2→2, ..., 7→7, 8→0
                        expected_opcode = inc_base + (count % 8)
                        if verify_singlereg_encoding(rom_bytes, reg, expected_opcode):
                            native_asm = f"{mnem_upper.lower()} {count}, {reg.lower()}"
                            return native_asm, 2

    # Tier 4: Register-immediate ALU (ADD/SUB/CP/AND/OR/XOR/ADC/SBC reg, #imm)
    # Encoding: prefix_byte + alu_imm_opcode + immediate_bytes
    # 8-bit reg: 3 bytes (prefix + opcode + imm8)
    # 16-bit reg: 4 bytes (prefix + opcode + imm16_LE)
    # 32-bit reg: 6 bytes (prefix + opcode + imm32_LE)
    # Short forms (2-byte, values 0-7) don't match LLVM.
    ALU_IMM_OPCODE = {
        'ADD': 0xC8, 'ADC': 0xC9, 'SUB': 0xCA, 'SBC': 0xCB,
        'AND': 0xCC, 'XOR': 0xCD, 'OR': 0xCE, 'CP': 0xCF,
    }
    if operands_str and nbytes in (3, 4, 6) and rom_bytes is not None:
        base_mnem = strip_size_suffix(mnem_upper)
        alu_opcode = ALU_IMM_OPCODE.get(base_mnem)
        if alu_opcode is not None:
            parts = operands_str.split(',', 1)
            if len(parts) == 2:
                reg = parts[0].strip().upper()
                imm_str = parts[1].strip()
                prefix = REG_PREFIX.get(reg)
                if prefix is not None and '(' not in imm_str:
                    imm_val = parse_asl_immediate(imm_str)
                    if imm_val is not None:
                        # Verify ROM bytes: prefix + alu_opcode + imm_LE
                        if rom_bytes[0] == prefix and rom_bytes[1] == alu_opcode:
                            native_asm = f"{base_mnem.lower()} {reg.lower()}, 0x{imm_val:X}"
                            return native_asm, nbytes

    # Tier 5: Unconditional JP and CALL (4-byte absolute address encoding)
    # JP: 0x1b + addr24_LE (4 bytes)
    # CALL: 0x1d + addr24_LE (4 bytes)
    # Use hardcoded target address from ROM bytes (avoids label position errors).
    if nbytes == 4 and rom_bytes is not None:
        if mnem_upper == 'JP' and rom_bytes[0] == 0x1b:
            target_addr = rom_bytes[1] | (rom_bytes[2] << 8) | (rom_bytes[3] << 16)
            label = ADDR_TO_LABEL.get(target_addr)
            native_asm = f"jp {label}" if label else f"jp 0x{target_addr:X}"
            return native_asm, 4
        elif mnem_upper == 'CALL' and rom_bytes[0] == 0x1d:
            target_addr = rom_bytes[1] | (rom_bytes[2] << 8) | (rom_bytes[3] << 16)
            label = ADDR_TO_LABEL.get(target_addr)
            native_asm = f"call {label}" if label else f"call 0x{target_addr:X}"
            return native_asm, 4

    # Tier 6: PUSH/POP (1-byte encoding)
    # PUSH r16: 0x28+r, POP r16: 0x48+r
    # PUSH r32: 0x38+r, POP r32: 0x58+r
    # PUSH SR: 0x02, POP SR: 0x03
    NATIVE_R16_REGS = {'WA', 'BC', 'DE', 'HL', 'IX', 'IY', 'IZ'}  # SP excluded (not in GR16)
    if nbytes == 1 and operands_str and rom_bytes is not None:
        reg = operands_str.strip().upper()
        if reg in NATIVE_LD_32BIT_REGS:
            reg_idx = REG_INDEX.get(reg, 99)
            if mnem_upper == 'PUSH' and rom_bytes[0] == 0x38 + reg_idx:
                native_asm = f"push {reg.lower()}"
                return native_asm, 1
            elif mnem_upper == 'POP' and rom_bytes[0] == 0x58 + reg_idx:
                native_asm = f"pop {reg.lower()}"
                return native_asm, 1
        elif reg in NATIVE_R16_REGS:
            reg_idx = REG_INDEX.get(reg, 99)
            if mnem_upper == 'PUSH' and rom_bytes[0] == 0x28 + reg_idx:
                return f"pushw {reg.lower()}", 1
            elif mnem_upper == 'POP' and rom_bytes[0] == 0x48 + reg_idx:
                return f"popw {reg.lower()}", 1
        elif reg == 'SR':
            if mnem_upper == 'PUSH' and rom_bytes[0] == 0x02:
                return "push_sr", 1
            elif mnem_upper == 'POP' and rom_bytes[0] == 0x03:
                return "pop_sr", 1
        elif reg == 'A':
            if mnem_upper == 'PUSH' and rom_bytes[0] == 0x14:
                return "push_a", 1
            elif mnem_upper == 'POP' and rom_bytes[0] == 0x15:
                return "pop_a", 1
        elif reg == 'F':
            if mnem_upper == 'PUSH' and rom_bytes[0] == 0x18:
                return "push_f", 1
            elif mnem_upper == 'POP' and rom_bytes[0] == 0x19:
                return "pop_f", 1
    # 1-byte flag manipulation
    if nbytes == 1 and rom_bytes is not None:
        SINGLE_BYTE_MAP = {
            ('SCF', 0x11): 'scf', ('RCF', 0x10): 'rcf',
            ('CCF', 0x12): 'ccf', ('ZCF', 0x13): 'zcf',
            ('INCF', 0x0C): 'incf', ('DECF', 0x0D): 'decf',
        }
        key = (mnem_upper, rom_bytes[0])
        if key in SINGLE_BYTE_MAP:
            return SINGLE_BYTE_MAP[key], 1

    # Tier 6b: Prefix PUSH/POP (2-byte encoding)
    # PUSH r8: C8+r, 0x04; POP r8: C8+r, 0x05
    # PUSH r16: D8+r, 0x04; POP r16: D8+r, 0x05 (for SP which isn't in 1-byte form)
    if nbytes == 2 and operands_str and rom_bytes is not None and mnem_upper in ('PUSH', 'POP'):
        reg = operands_str.strip().upper()
        opc = 0x04 if mnem_upper == 'PUSH' else 0x05
        if rom_bytes[1] == opc:
            prefix = rom_bytes[0]
            if reg in ALL_REGISTERS:
                r_idx = REG_INDEX.get(reg, 99)
                if 0xC8 <= prefix <= 0xCF and prefix == 0xC8 + r_idx:
                    return f"{mnem_upper.lower()} {reg.lower()}", 2
                elif 0xD8 <= prefix <= 0xDF and prefix == 0xD8 + r_idx:
                    return f"{mnem_upper.lower()} {reg.lower()}", 2

    # Tier 7: Simple register-indirect LD (2-byte encoding)
    # LD reg, (Xreg): prefix = 0x80/0x90/0xA0 + xreg_idx
    # LD (Xreg), reg: prefix = 0xB0 + xreg_idx
    # Only supports LD (not ALU ops, which LLVM doesn't accept with (Xreg)).
    if nbytes == 2 and operands_str and rom_bytes is not None and mnem_upper in ('LD', 'LDW'):
        # Parse operands for register-indirect forms
        parts = operands_str.split(',', 1)
        if len(parts) == 2:
            op1 = parts[0].strip()
            op2 = parts[1].strip()

            # LD reg, (Xreg) — load from indirect
            indirect_match = re.match(r'^\((\w+)\)$', op2)
            if indirect_match:
                mem_reg = indirect_match.group(1).upper()
                dst_reg = op1.upper()
                if mem_reg in NATIVE_LD_32BIT_REGS and dst_reg in ALL_REGISTERS:
                    mem_idx = REG_INDEX.get(mem_reg, 99)
                    # Determine prefix base from destination register size
                    if dst_reg in ('W','A','B','C','D','E','H','L'):
                        prefix_base = 0x80  # 8-bit dest
                    elif dst_reg in ('WA','BC','DE','HL','IX','IY','IZ','SP'):
                        prefix_base = 0x90  # 16-bit dest
                    else:
                        prefix_base = 0xA0  # 32-bit dest
                    expected_prefix = prefix_base + mem_idx
                    if rom_bytes[0] == expected_prefix:
                        native_asm = f"ld {dst_reg.lower()}, ({mem_reg.lower()})"
                        return native_asm, 2

            # LD (Xreg), reg — store to indirect
            indirect_match = re.match(r'^\((\w+)\)$', op1)
            if indirect_match:
                mem_reg = indirect_match.group(1).upper()
                src_reg = op2.upper()
                if mem_reg in NATIVE_LD_32BIT_REGS and src_reg in ALL_REGISTERS:
                    mem_idx = REG_INDEX.get(mem_reg, 99)
                    expected_prefix = 0xB0 + mem_idx
                    if rom_bytes[0] == expected_prefix:
                        native_asm = f"ld ({mem_reg.lower()}), {src_reg.lower()}"
                        return native_asm, 2

    # Tier 8: JR/JRcc (2-byte relative jump: 0x60+cc, d8)
    # Use ADDR_TO_LABEL (reliable) first, then ADDR_TO_LABEL_ALL for LABEL_XXXXXX only.
    # Named labels in ADDR_TO_LABEL_ALL may have drifted positions causing wrong offsets.
    if nbytes == 2 and rom_bytes is not None and addr is not None:
        opcode = rom_bytes[0]
        if 0x60 <= opcode <= 0x6F and mnem_upper == 'JR':
            cc = opcode & 0x0F
            d8 = rom_bytes[1]
            if d8 > 127:
                d8 -= 256  # sign-extend
            target = addr + 2 + d8
            label = ADDR_TO_LABEL.get(target)
            if not label:
                lbl_all = ADDR_TO_LABEL_ALL.get(target)
                if lbl_all and lbl_all.startswith('LABEL_'):
                    label = lbl_all
            if label and label.lower() not in RESERVED_LABEL_NAMES:
                if cc == 8:  # T (always/unconditional)
                    return f"jr {label}", 2
                else:
                    return f"jr {TLCS900_CC_NAMES[cc]}, {label}", 2

    # Tier 9: JRL/JRLcc (3-byte relative jump: 0x70+cc, d16_LE)
    if nbytes == 3 and rom_bytes is not None and addr is not None:
        opcode = rom_bytes[0]
        if 0x70 <= opcode <= 0x7F and mnem_upper in ('JRL', 'JP'):
            cc = opcode & 0x0F
            d16 = rom_bytes[1] | (rom_bytes[2] << 8)
            if d16 > 32767:
                d16 -= 65536  # sign-extend
            target = addr + 3 + d16
            label = ADDR_TO_LABEL.get(target)
            if not label:
                lbl_all = ADDR_TO_LABEL_ALL.get(target)
                if lbl_all and lbl_all.startswith('LABEL_'):
                    label = lbl_all
            if label and label.lower() not in RESERVED_LABEL_NAMES:
                if cc == 8:  # T (unconditional)
                    return f"jrl {label}", 3
                else:
                    return f"jrl {TLCS900_CC_NAMES[cc]}, {label}", 3

    # Tier 10: CALR (3-byte relative call: 0x1E, d16_LE)
    if nbytes == 3 and rom_bytes is not None and addr is not None:
        if rom_bytes[0] == 0x1E and mnem_upper in ('CALR', 'CALL'):
            d16 = rom_bytes[1] | (rom_bytes[2] << 8)
            if d16 > 32767:
                d16 -= 65536
            target = addr + 3 + d16
            label = ADDR_TO_LABEL.get(target)
            if not label:
                lbl_all = ADDR_TO_LABEL_ALL.get(target)
                if lbl_all and lbl_all.startswith('LABEL_'):
                    label = lbl_all
            if label and label.lower() not in RESERVED_LABEL_NAMES:
                return f"calr {label}", 3

    # Tier 10b: DJNZ (3-byte: prefix + 0x1C + d8)
    # 16-bit: D8+reg, 0x1C, d8 (decrement 16-bit register, jump if not zero)
    # 8-bit:  C8+reg, 0x1C, d8 (decrement 8-bit register, jump if not zero)
    if nbytes == 3 and rom_bytes is not None and addr is not None:
        if mnem_upper == 'DJNZ' and rom_bytes[1] == 0x1C:
            prefix = rom_bytes[0]
            d8 = rom_bytes[2]
            if d8 > 127:
                d8 -= 256  # sign-extend
            target = addr + 3 + d8
            label = ADDR_TO_LABEL.get(target)
            if not label:
                lbl_all = ADDR_TO_LABEL_ALL.get(target)
                if lbl_all and lbl_all.startswith('LABEL_'):
                    label = lbl_all
            if label and label.lower() not in RESERVED_LABEL_NAMES:
                if 0xD8 <= prefix <= 0xDF:
                    # 16-bit DJNZ uses GPR (32-bit names) with D8 prefix
                    reg_name = REG32_BY_INDEX[prefix & 0x07]
                    if reg_name:
                        return f"djnz {reg_name}, {label}", 3
                elif 0xC8 <= prefix <= 0xCF:
                    reg_name = REG8_BY_INDEX[prefix & 0x07]
                    if reg_name:
                        return f"djnz8 {reg_name}, {label}", 3

    # Tier 11: Short-form LD r8, #imm8 (2-byte: 0x20+r, imm8)
    # ASL uses macros LD_A, LD_W, etc. for these, so check startswith('LD').
    if nbytes == 2 and rom_bytes is not None and mnem_upper.startswith('LD'):
        opcode = rom_bytes[0]
        if 0x20 <= opcode <= 0x27:
            r_idx = opcode & 0x07
            reg_name = REG8_BY_INDEX[r_idx]
            imm8 = rom_bytes[1]
            return f"ldb {reg_name}, 0x{imm8:X}", 2

    # Tier 12: Short-form LD r16, #imm16 (3-byte: 0x30+r, imm16_LE)
    if nbytes == 3 and rom_bytes is not None and mnem_upper in ('LD', 'LDW'):
        opcode = rom_bytes[0]
        if 0x30 <= opcode <= 0x37:
            r_idx = opcode & 0x07
            reg_name = REG16_BY_INDEX[r_idx]
            # SP (index 7) is not in GR16 register class — skip
            if r_idx == 7:
                pass  # fall through to .byte fallback
            else:
                imm16 = rom_bytes[1] | (rom_bytes[2] << 8)
                return f"ldw {reg_name}, 0x{imm16:X}", 3

    # Tier 12b: Small-immediate LD r, #(0-7) (2-byte: prefix+r, 0xA8+val)
    # 8-bit: C8+r, 16-bit: D8+r, 32-bit: E8+r
    if nbytes == 2 and rom_bytes is not None and mnem_upper.startswith('LD'):
        opcode = rom_bytes[0]
        sub_opc = rom_bytes[1]
        if 0xA8 <= sub_opc <= 0xAF:
            val = sub_opc & 0x07
            r_idx = opcode & 0x07
            if 0xC8 <= opcode <= 0xCF:
                reg_name = REG8_BY_INDEX[r_idx]
                return f"lds8 {reg_name}, {val}", 2
            elif 0xD8 <= opcode <= 0xDF:
                reg_name = REG16_BY_INDEX[r_idx]
                # SP (index 7) is not in GR16 — skip
                if r_idx != 7:
                    return f"lds {reg_name}, {val}", 2
            elif 0xE8 <= opcode <= 0xEF:
                reg_name = REG32_BY_INDEX.get(r_idx)
                if reg_name:
                    return f"lds32 {reg_name}, {val}", 2

    # Tier 13: Prefix-form LD r8, #imm8 (3-byte: C8+r, 0x03, imm8)
    if nbytes == 3 and rom_bytes is not None and mnem_upper in ('LD', 'LDB'):
        opcode = rom_bytes[0]
        if 0xC8 <= opcode <= 0xCF and rom_bytes[1] == 0x03:
            r_idx = opcode & 0x07
            reg_name = REG8_BY_INDEX[r_idx]
            imm8 = rom_bytes[2]
            return f"ld {reg_name}, 0x{imm8:X}", 3

    # Tier 14: Prefix-form LD r16, #imm16 (4-byte: D8+r, 0x03, imm16_LE)
    if nbytes == 4 and rom_bytes is not None and mnem_upper in ('LD', 'LDW'):
        opcode = rom_bytes[0]
        if 0xD8 <= opcode <= 0xDF and rom_bytes[1] == 0x03:
            r_idx = opcode & 0x07
            reg_name = REG16_BY_INDEX[r_idx]
            # SP (index 7) is not in GR16 — skip
            if r_idx != 7:
                imm16 = rom_bytes[2] | (rom_bytes[3] << 8)
                return f"ld {reg_name}, 0x{imm16:X}", 4

    # Tier 15: Shift/Rotate instructions (3-byte: prefix + sub_opcode + count)
    # Shifts: prefix_r + {0xEC=SLA, 0xED=SRA, 0xEE=SLL, 0xEF=SRL} + count
    # Rotates: prefix_r + {0xE8=RLC, 0xE9=RRC, 0xEA=RL, 0xEB=RR} + 0x01
    # Also handles macro names like SRL_0_XWA, SLL_0_XBC, etc.
    SHIFT_ROTATE_MNEMONICS = {
        'SLL', 'SLA', 'SRL', 'SRA', 'RL', 'RLC', 'RR', 'RRC',
    }
    SHIFT_SUBOPC = {0xEC: 'sla', 0xED: 'sra', 0xEE: 'sll', 0xEF: 'srl'}
    ROTATE_SUBOPC = {0xE8: 'rlc', 0xE9: 'rrc', 0xEA: 'rl', 0xEB: 'rr'}
    _is_shift_mnem = (mnem_upper in SHIFT_ROTATE_MNEMONICS or
                      any(mnem_upper.startswith(m + '_') for m in SHIFT_ROTATE_MNEMONICS))
    if nbytes == 3 and rom_bytes is not None and _is_shift_mnem:
        prefix = rom_bytes[0]
        sub_opc = rom_bytes[1]
        count = rom_bytes[2]
        # Determine register from prefix byte
        reg_name = None
        if 0xC8 <= prefix <= 0xCF:
            reg_name = REG8_BY_INDEX[prefix & 0x07]
        elif 0xD8 <= prefix <= 0xDF:
            reg_name = REG16_BY_INDEX[prefix & 0x07]
        elif 0xE8 <= prefix <= 0xEF:
            reg_name = REG32_BY_INDEX[prefix & 0x07]
        if reg_name is not None:
            if sub_opc in SHIFT_SUBOPC:
                mnem = SHIFT_SUBOPC[sub_opc]
                return f"{mnem} {reg_name}, {count}", 3
            elif sub_opc in ROTATE_SUBOPC and count == 1:
                mnem = ROTATE_SUBOPC[sub_opc]
                return f"{mnem} {reg_name}", 3

    # Tier 15b: Shift-by-A instructions (2-byte: prefix + sub_opcode)
    # Sub-opcodes: 0xFC=SLA, 0xFD=SRA, 0xFE=SLL, 0xFF=SRL (shift count from A)
    SHIFT_BY_A_SUBOPC = {0xFC: 'slaa', 0xFD: 'sraa', 0xFE: 'slla', 0xFF: 'srla'}
    if nbytes == 2 and rom_bytes is not None and _is_shift_mnem:
        prefix = rom_bytes[0]
        sub_opc = rom_bytes[1]
        if sub_opc in SHIFT_BY_A_SUBOPC:
            reg_name = None
            if 0xC8 <= prefix <= 0xCF:
                reg_name = REG8_BY_INDEX[prefix & 0x07]
            elif 0xD8 <= prefix <= 0xDF:
                reg_name = REG16_BY_INDEX[prefix & 0x07]
            elif 0xE8 <= prefix <= 0xEF:
                reg_name = REG32_BY_INDEX[prefix & 0x07]
            if reg_name is not None:
                mnem = SHIFT_BY_A_SUBOPC[sub_opc]
                return f"{mnem} {reg_name}", 2

    # Tier 16: CP short-form (2-byte: prefix + 0xD8+N, compare with 0-7)
    if nbytes == 2 and rom_bytes is not None and mnem_upper == 'CP':
        prefix = rom_bytes[0]
        sub_opc = rom_bytes[1]
        if 0xD8 <= sub_opc <= 0xDF:
            val = sub_opc & 0x07
            reg_name = None
            if 0xC8 <= prefix <= 0xCF:
                reg_name = REG8_BY_INDEX[prefix & 0x07]
            elif 0xD8 <= prefix <= 0xDF:
                r_idx = prefix & 0x07
                if r_idx != 7:  # Skip SP
                    reg_name = REG16_BY_INDEX[r_idx]
            elif 0xE8 <= prefix <= 0xEF:
                reg_name = REG32_BY_INDEX[prefix & 0x07]
            if reg_name is not None:
                return f"cps {reg_name}, {val}", 2

    # Tier 17: BIT/SET/RES register form (3-byte: prefix + sub_opcode + bit_number)
    BIT_SET_RES_MNEMONICS = {'BIT', 'SET', 'RES'}
    BIT_SET_RES_SUBOPC = {0x33: 'bit', 0x31: 'set', 0x30: 'res'}
    if nbytes == 3 and rom_bytes is not None and mnem_upper in BIT_SET_RES_MNEMONICS:
        prefix = rom_bytes[0]
        sub_opc = rom_bytes[1]
        bit_num = rom_bytes[2]
        if sub_opc in BIT_SET_RES_SUBOPC and 0 <= bit_num <= 15:
            reg_name = None
            if 0xC8 <= prefix <= 0xCF:
                reg_name = REG8_BY_INDEX[prefix & 0x07]
            elif 0xD8 <= prefix <= 0xDF:
                r_idx = prefix & 0x07
                if r_idx != 7:  # Skip SP
                    reg_name = REG16_BY_INDEX[r_idx]
            elif 0xE8 <= prefix <= 0xEF:
                reg_name = REG32_BY_INDEX[prefix & 0x07]
            if reg_name is not None:
                mnem = BIT_SET_RES_SUBOPC[sub_opc]
                return f"{mnem} {bit_num}, {reg_name}", 3

    # Tier 18: Register-indirect memory ALU (2 or 3 bytes)
    # No displacement: prefix(1) + sub_opcode(1)
    # d8 displacement: prefix(1) + d8(1) + sub_opcode(1)
    # Memory prefix ranges: 0x80-0x87/0x88-0x8F (8-bit src), 0x90-0x97/0x98-0x9F (16-bit src),
    #                        0xA0-0xA7/0xA8-0xAF (32-bit src)
    # Sub-opcodes: 0x80+r=ADD rm, 0x88+r=ADD mr, 0x90+r=ADC rm, 0x98+r=ADC mr,
    #              0xA0+r=SUB rm, 0xA8+r=SUB mr, 0xB0+r=SBC rm, 0xB8+r=SBC mr,
    #              0xC0+r=AND rm, 0xC8+r=AND mr, 0xD0+r=XOR rm, 0xD8+r=XOR mr,
    #              0xE0+r=OR rm, 0xE8+r=OR mr, 0xF0+r=CP rm, 0xF8+r=CP mr
    MEM_ALU_MNEMONICS = {'ADD', 'ADC', 'SUB', 'SBC', 'AND', 'XOR', 'OR', 'CP', 'LD', 'LDW'}
    # Sub-opcode base -> (mnemonic, direction: 'rm'=reg,mem or 'mr'=mem,reg)
    MEM_ALU_SUBOPC = {
        0x80: ('add', 'rm'), 0x88: ('add', 'mr'),
        0x90: ('adc', 'rm'), 0x98: ('adc', 'mr'),
        0xA0: ('sub', 'rm'), 0xA8: ('sub', 'mr'),
        0xB0: ('sbc', 'rm'), 0xB8: ('sbc', 'mr'),
        0xC0: ('and', 'rm'), 0xC8: ('and', 'mr'),
        0xD0: ('xor', 'rm'), 0xD8: ('xor', 'mr'),
        0xE0: ('or', 'rm'),  0xE8: ('or', 'mr'),
        0xF0: ('cp', 'rm'),  0xF8: ('cp', 'mr'),
    }
    if rom_bytes is not None and mnem_upper in MEM_ALU_MNEMONICS:
        prefix = rom_bytes[0]
        # Determine if this is a source memory prefix and extract base reg + size
        has_disp = False
        data_size = None
        base_idx = None
        if 0x80 <= prefix <= 0xAF:
            base_idx = prefix & 0x07
            has_disp = (prefix & 0x08) != 0
            if prefix < 0x90:
                data_size = 8
            elif prefix < 0xA0:
                data_size = 16
            else:
                data_size = 32
        if base_idx is not None and data_size is not None:
            expected_nbytes = 3 if has_disp else 2
            if nbytes == expected_nbytes:
                disp_byte = rom_bytes[1] if has_disp else None
                sub_opc_byte = rom_bytes[2] if has_disp else rom_bytes[1]
                sub_opc_base = sub_opc_byte & 0xF8
                operand_reg_idx = sub_opc_byte & 0x07
                base_name = REG32_BY_INDEX.get(base_idx)
                if base_name:
                    # Format memory operand string
                    # Skip d8=0 case: LLVM optimizes (reg + 0) to 2-byte no-disp,
                    # but ROM uses 3-byte d8=0 encoding. Leave as .byte fallback.
                    mem_str = None
                    if has_disp:
                        d8 = disp_byte
                        if d8 > 127:
                            d8 -= 256  # sign-extend
                        if d8 < 0:
                            mem_str = f"({base_name} - {-d8})"
                        elif d8 > 0:
                            mem_str = f"({base_name} + {d8})"
                        # d8 == 0: mem_str stays None → skip conversion
                    else:
                        mem_str = f"({base_name})"

                    if mem_str is not None and sub_opc_base in MEM_ALU_SUBOPC:
                        alu_mnem, direction = MEM_ALU_SUBOPC[sub_opc_base]
                        if data_size == 8:
                            op_reg = REG8_BY_INDEX.get(operand_reg_idx)
                        elif data_size == 16:
                            op_reg = REG16_BY_INDEX.get(operand_reg_idx)
                        else:
                            op_reg = REG32_BY_INDEX.get(operand_reg_idx)
                        if op_reg:
                            if direction == 'rm':
                                return f"{alu_mnem} {op_reg}, {mem_str}", expected_nbytes
                            else:
                                return f"{alu_mnem} {mem_str}, {op_reg}", expected_nbytes

                    # LD reg, (mem) — sub-opcode 0x20+r in source memory table
                    if mem_str is not None and 0x20 <= sub_opc_byte <= 0x27:
                        if data_size == 8:
                            op_reg = REG8_BY_INDEX.get(operand_reg_idx)
                        elif data_size == 16:
                            op_reg = REG16_BY_INDEX.get(operand_reg_idx)
                        else:
                            op_reg = REG32_BY_INDEX.get(operand_reg_idx)
                        if op_reg:
                            return f"ld {op_reg}, {mem_str}", expected_nbytes

    # Tier 19: Destination memory (B0/B8 prefix) — LD stores and LDA
    # B0+r = no disp, B8+r = d8 disp
    # Sub-opcodes: 0x40+r=LD(mem),r8, 0x50+r=LD(mem),r16, 0x60+r=LD(mem),r32
    #              0x30+r=LDA r32,mem
    LD_STORE_MNEMONICS = {'LD', 'LDW', 'LDA'}
    if rom_bytes is not None and mnem_upper in LD_STORE_MNEMONICS:
        prefix = rom_bytes[0]
        if 0xB0 <= prefix <= 0xBF:
            base_idx = prefix & 0x07
            has_disp = (prefix & 0x08) != 0
            expected_nbytes = 3 if has_disp else 2
            if nbytes == expected_nbytes:
                disp_byte = rom_bytes[1] if has_disp else None
                sub_opc_byte = rom_bytes[2] if has_disp else rom_bytes[1]
                operand_reg_idx = sub_opc_byte & 0x07
                base_name = REG32_BY_INDEX.get(base_idx)
                if base_name:
                    # Skip d8=0: LLVM optimizes to shorter no-disp encoding
                    mem_str = None
                    if has_disp:
                        d8 = disp_byte
                        if d8 > 127:
                            d8 -= 256
                        if d8 < 0:
                            mem_str = f"({base_name} - {-d8})"
                        elif d8 > 0:
                            mem_str = f"({base_name} + {d8})"
                    else:
                        mem_str = f"({base_name})"
                    if mem_str is None:
                        pass  # d8=0, skip
                    # LD (mem), r8 — sub-opcode 0x40+r
                    elif 0x40 <= sub_opc_byte <= 0x47:
                        op_reg = REG8_BY_INDEX.get(operand_reg_idx)
                        if op_reg:
                            return f"ld {mem_str}, {op_reg}", expected_nbytes
                    # LD (mem), r16 — sub-opcode 0x50+r
                    elif 0x50 <= sub_opc_byte <= 0x57:
                        op_reg = REG16_BY_INDEX.get(operand_reg_idx)
                        if op_reg:
                            return f"ld {mem_str}, {op_reg}", expected_nbytes
                    # LD (mem), r32 — sub-opcode 0x60+r
                    elif 0x60 <= sub_opc_byte <= 0x67:
                        op_reg = REG32_BY_INDEX.get(operand_reg_idx)
                        if op_reg:
                            return f"ld {mem_str}, {op_reg}", expected_nbytes
                    # LDA r32, mem — sub-opcode 0x30+r
                    elif 0x30 <= sub_opc_byte <= 0x37 and mnem_upper == 'LDA':
                        op_reg = REG32_BY_INDEX.get(operand_reg_idx)
                        if op_reg:
                            return f"lda {op_reg}, {mem_str}", expected_nbytes

    # Tier 20: EI (enable interrupts) — 2-byte: 0x06, level
    if nbytes == 2 and rom_bytes is not None and mnem_upper == 'EI':
        if rom_bytes[0] == 0x06:
            level = rom_bytes[1]
            return f"ei {level}", 2

    # Tier 21: RETD (return and deallocate) — 3-byte: 0x0F, imm16_LE
    if nbytes == 3 and rom_bytes is not None and mnem_upper == 'RETD':
        if rom_bytes[0] == 0x0F:
            imm16 = rom_bytes[1] | (rom_bytes[2] << 8)
            return f"retd 0x{imm16:X}", 3

    # Tier 22: MUL/MULS/DIV/DIVS register-register (D8 prefix, 2-byte)
    # Encoding: D8+src_idx, base_opc+dst_idx
    MULDIV_MNEMONICS = {'MUL', 'MULS', 'DIV', 'DIVS'}
    MULDIV_SUBOPC = {0x40: 'mul', 0x48: 'muls', 0x50: 'div', 0x58: 'divs'}
    if nbytes == 2 and rom_bytes is not None and mnem_upper in MULDIV_MNEMONICS:
        prefix = rom_bytes[0]
        if 0xD8 <= prefix <= 0xDF:
            src_idx = prefix & 0x07
            sub_opc = rom_bytes[1]
            sub_base = sub_opc & 0xF8
            dst_idx = sub_opc & 0x07
            if sub_base in MULDIV_SUBOPC and src_idx != 7 and dst_idx != 7:
                src_reg = REG32_BY_INDEX.get(src_idx)
                dst_reg = REG32_BY_INDEX.get(dst_idx)
                if src_reg and dst_reg:
                    mnem = MULDIV_SUBOPC[sub_base]
                    return f"{mnem} {dst_reg}, {src_reg}", 2

    # Tier 23: PUSHW immediate — 3-byte: 0x0B, imm16_LE
    if nbytes == 3 and rom_bytes is not None and mnem_upper == 'PUSHW':
        if rom_bytes[0] == 0x0B:
            imm16 = rom_bytes[1] | (rom_bytes[2] << 8)
            return f"pushw 0x{imm16:X}", 3

    # Tier 24: Conditional RET (RETcc) — 2-byte: 0xB0, 0xF0+cc
    if nbytes == 2 and rom_bytes is not None and mnem_upper == 'RET':
        if rom_bytes[0] == 0xB0 and 0xF0 <= rom_bytes[1] <= 0xFF:
            cc = rom_bytes[1] & 0x0F
            return f"ret {TLCS900_CC_NAMES[cc]}", 2

    # Tier 25: SCC (set condition code) — 2-byte: prefix + 0x70+cc
    # C8+r → 8-bit register, D8+r → 16-bit register
    if nbytes == 2 and rom_bytes is not None and mnem_upper == 'SCC':
        prefix = rom_bytes[0]
        sub_opc = rom_bytes[1]
        if 0x70 <= sub_opc <= 0x7F:
            cc = sub_opc & 0x0F
            r_idx = prefix & 0x07
            if 0xC8 <= prefix <= 0xCF:
                reg_name = REG8_BY_INDEX.get(r_idx)
                if reg_name and r_idx != 7:  # skip SP-mapped index
                    return f"scc8 {TLCS900_CC_NAMES[cc]}, {reg_name}", 2
            elif 0xD8 <= prefix <= 0xDF:
                reg_name = REG16_BY_INDEX.get(r_idx)
                if reg_name and r_idx != 7:  # skip SP
                    return f"scc16 {TLCS900_CC_NAMES[cc]}, {reg_name}", 2

    # Tier 26: EX F,F' — 1-byte: 0x16
    if nbytes == 1 and rom_bytes is not None and mnem_upper == 'EX':
        if rom_bytes[0] == 0x16:
            return "ex_ff", 1

    # Tier 27: Memory-immediate ALU (source memory prefix + sub_opc + imm)
    # 8-bit: prefix(80-8F) + [d8] + sub_opc(0x38-0x3F) + imm8
    # 16-bit: prefix(90-9F) + [d8] + sub_opc(0x38-0x3F) + imm16
    # Sub-opcodes: ADD=0x38, ADC=0x39, SUB=0x3A, SBC=0x3B,
    #              AND=0x3C, XOR=0x3D, OR=0x3E, CP=0x3F
    MEM_IMM_ALU_MNEMONICS = {
        'CP', 'CPW', 'AND', 'ANDW', 'OR', 'ORW', 'ADD', 'ADDW',
        'SUB', 'SUBW', 'ADC', 'ADCW', 'SBC', 'SBCW', 'XOR', 'XORW',
    }
    MEM_IMM_ALU_SUBOPC = {
        0x38: 'add', 0x39: 'adc', 0x3A: 'sub', 0x3B: 'sbc',
        0x3C: 'and', 0x3D: 'xor', 0x3E: 'or', 0x3F: 'cp',
    }
    if rom_bytes is not None and mnem_upper in MEM_IMM_ALU_MNEMONICS:
        prefix = rom_bytes[0]
        # Check for source memory prefix (0x80-0x9F for 8-bit and 16-bit)
        if 0x80 <= prefix <= 0x9F:
            base_idx = prefix & 0x07
            has_disp = (prefix & 0x08) != 0
            data_size = 8 if prefix < 0x90 else 16
            imm_bytes = 1 if data_size == 8 else 2
            size_suffix = '8' if data_size == 8 else '16'
            # Expected: prefix(1) + [d8(1)] + sub_opc(1) + imm(1 or 2)
            expected_nbytes = (1 + (1 if has_disp else 0) + 1 + imm_bytes)
            if nbytes == expected_nbytes:
                disp_offset = 1 if has_disp else 0
                sub_opc_byte = rom_bytes[1 + disp_offset]
                if sub_opc_byte in MEM_IMM_ALU_SUBOPC:
                    base_name = REG32_BY_INDEX.get(base_idx)
                    if base_name:
                        # Build memory operand string (skip d8=0)
                        mem_str = None
                        if has_disp:
                            d8 = rom_bytes[1]
                            if d8 > 127:
                                d8 -= 256
                            if d8 < 0:
                                mem_str = f"({base_name} - {-d8})"
                            elif d8 > 0:
                                mem_str = f"({base_name} + {d8})"
                            # d8 == 0: skip
                        else:
                            mem_str = f"({base_name})"
                        if mem_str is not None:
                            alu_mnem = MEM_IMM_ALU_SUBOPC[sub_opc_byte]
                            # Extract immediate
                            imm_start = 2 + disp_offset
                            if data_size == 8:
                                imm_val = rom_bytes[imm_start]
                            else:
                                imm_val = rom_bytes[imm_start] | (rom_bytes[imm_start + 1] << 8)
                            return f"{alu_mnem}mi{size_suffix} {mem_str}, 0x{imm_val:X}", expected_nbytes

    # Tier 28: LD immediate-to-memory (destination memory prefix B0/B8 + sub_opc + imm)
    # 8-bit:  B0+r + 0x00 + imm8 (3 bytes no disp)  /  B8+r + d8 + 0x00 + imm8 (4 bytes)
    # 16-bit: B0+r + 0x14 + imm16 (4 bytes no disp)  /  B8+r + d8 + 0x14 + imm16 (5 bytes)
    if rom_bytes is not None and mnem_upper in ('LD', 'LDW'):
        prefix = rom_bytes[0]
        if 0xB0 <= prefix <= 0xBF:
            base_idx = prefix & 0x07
            has_disp = (prefix & 0x08) != 0
            disp_offset = 1 if has_disp else 0
            sub_opc_byte = rom_bytes[1 + disp_offset]
            if sub_opc_byte == 0x00:
                # LD (mem), #imm8
                expected_nbytes = 3 + disp_offset
                if nbytes == expected_nbytes:
                    base_name = REG32_BY_INDEX.get(base_idx)
                    if base_name:
                        mem_str = None
                        if has_disp:
                            d8 = rom_bytes[1]
                            if d8 > 127:
                                d8 -= 256
                            if d8 < 0:
                                mem_str = f"({base_name} - {-d8})"
                            elif d8 > 0:
                                mem_str = f"({base_name} + {d8})"
                            # d8 == 0: skip (LLVM optimizes)
                        else:
                            mem_str = f"({base_name})"
                        if mem_str is not None:
                            imm_val = rom_bytes[2 + disp_offset]
                            return f"ldmi8 {mem_str}, 0x{imm_val:X}", expected_nbytes
            elif sub_opc_byte in (0x02, 0x14, 0x16):
                # LD (mem), #imm16 (sub-opcodes: 0x02, 0x14, 0x16)
                expected_nbytes = 4 + disp_offset
                if nbytes == expected_nbytes:
                    base_name = REG32_BY_INDEX.get(base_idx)
                    if base_name:
                        mem_str = None
                        if has_disp:
                            d8 = rom_bytes[1]
                            if d8 > 127:
                                d8 -= 256
                            if d8 < 0:
                                mem_str = f"({base_name} - {-d8})"
                            elif d8 > 0:
                                mem_str = f"({base_name} + {d8})"
                            # d8 == 0: skip (LLVM optimizes)
                        else:
                            mem_str = f"({base_name})"
                        if mem_str is not None:
                            imm_val = rom_bytes[2 + disp_offset] | (rom_bytes[3 + disp_offset] << 8)
                            # Use mnemonic matching the sub-opcode for byte-exact output
                            if sub_opc_byte == 0x02:
                                mnem = 'ldmw'
                            elif sub_opc_byte == 0x16:
                                mnem = 'ldmw2'
                            else:
                                mnem = 'ldmi16'
                            return f"{mnem} {mem_str}, 0x{imm_val:X}", expected_nbytes

    # Tier 29: Indirect CALL (2-byte: B0+r, 0xE8)
    # ASL: "CALL T, XHL" → LLVM: "call (xhl)"
    if nbytes == 2 and rom_bytes is not None and mnem_upper == 'CALL':
        prefix = rom_bytes[0]
        if 0xB0 <= prefix <= 0xB7 and rom_bytes[1] == 0xE8:
            r_idx = prefix & 0x07
            reg_name = REG32_BY_INDEX.get(r_idx)
            if reg_name:
                return f"call ({reg_name})", 2

    # Tier 30: MUL/MULS/DIV/DIVS register-immediate
    # ASL uses macro mnemonics like MULS_WA, DIVS_BC, MUL_A, MULW_WA, etc.
    # 8-bit: C8+r, sub_opc, imm8 (3 bytes)
    # 16-bit: D8+r, sub_opc, imm16_LE (4 bytes)
    MULDIV_IMM_SUBOPC = {0x08: 'mul', 0x09: 'muls', 0x0A: 'div', 0x0B: 'divs'}
    MULDIV_ASL_PREFIXES = {'MUL', 'MULS', 'MULW', 'DIV', 'DIVS', 'DIVW'}
    if rom_bytes is not None and nbytes in (3, 4):
        # Check if ASL mnemonic matches (MUL_*, MULS_*, etc.)
        base_mnem = mnem_upper.split('_')[0] if '_' in mnem_upper else mnem_upper
        if base_mnem in MULDIV_ASL_PREFIXES:
            prefix = rom_bytes[0]
            sub_opc = rom_bytes[1]
            if sub_opc in MULDIV_IMM_SUBOPC:
                native_mnem = MULDIV_IMM_SUBOPC[sub_opc]
                if 0xC8 <= prefix <= 0xCF and nbytes == 3:
                    # 8-bit register prefix
                    r_idx = prefix & 0x07
                    reg_name = REG8_BY_INDEX.get(r_idx)
                    if reg_name:
                        imm_val = rom_bytes[2]
                        return f"{native_mnem} {reg_name}, 0x{imm_val:X}", 3
                elif 0xD8 <= prefix <= 0xDF and nbytes == 4:
                    # 16-bit register prefix
                    r_idx = prefix & 0x07
                    reg_name = REG16_BY_INDEX.get(r_idx)
                    if reg_name and r_idx != 7:  # SP not in GR16
                        imm_val = rom_bytes[2] | (rom_bytes[3] << 8)
                        return f"{native_mnem} {reg_name}, 0x{imm_val:X}", 4

    # Tier 31: Memory INC/DEC (register-indirect, 8-bit and 16-bit data)
    # 8-bit no-disp (2B): 0x80+r, 0x60+count%8 (INC) / 0x68+count%8 (DEC)
    # 8-bit d8 (3B): 0x88+r, d8, 0x60+count%8 / 0x68+count%8
    # 16-bit no-disp (2B): 0x90+r, 0x60+count%8 / 0x68+count%8
    # 16-bit d8 (3B): 0x98+r, d8, 0x60+count%8 / 0x68+count%8
    if rom_bytes is not None and mnem_upper in ('INC', 'INCW', 'DEC', 'DECW'):
        prefix = rom_bytes[0]
        is_inc = mnem_upper in ('INC', 'INCW')
        # Determine prefix range and data size
        if 0x80 <= prefix <= 0x87 and nbytes == 2:
            # 8-bit no-disp
            r_idx = prefix & 0x07
            sub_opc = rom_bytes[1]
            base_opc = 0x60 if is_inc else 0x68
            if base_opc <= sub_opc <= base_opc + 7:
                count = sub_opc - base_opc
                if count == 0:
                    count = 8
                reg_name = REG32_BY_INDEX.get(r_idx)
                if reg_name:
                    mnem = 'incm8' if is_inc else 'decm8'
                    return f"{mnem} {count}, ({reg_name})", 2
        elif 0x88 <= prefix <= 0x8F and nbytes == 3:
            # 8-bit d8
            r_idx = prefix & 0x07
            d8 = rom_bytes[1]
            sub_opc = rom_bytes[2]
            base_opc = 0x60 if is_inc else 0x68
            if base_opc <= sub_opc <= base_opc + 7:
                if d8 == 0:
                    pass  # Skip d8=0: LLVM would emit 2-byte no-disp form
                else:
                    count = sub_opc - base_opc
                    if count == 0:
                        count = 8
                    reg_name = REG32_BY_INDEX.get(r_idx)
                    if reg_name:
                        disp = d8 if d8 <= 127 else d8 - 256
                        mnem = 'incm8' if is_inc else 'decm8'
                        if disp >= 0:
                            return f"{mnem} {count}, ({reg_name} + {disp})", 3
                        else:
                            return f"{mnem} {count}, ({reg_name} - {-disp})", 3
        elif 0x90 <= prefix <= 0x97 and nbytes == 2:
            # 16-bit no-disp
            r_idx = prefix & 0x07
            sub_opc = rom_bytes[1]
            base_opc = 0x60 if is_inc else 0x68
            if base_opc <= sub_opc <= base_opc + 7:
                count = sub_opc - base_opc
                if count == 0:
                    count = 8
                reg_name = REG32_BY_INDEX.get(r_idx)
                if reg_name:
                    mnem = 'incm' if is_inc else 'decm'
                    return f"{mnem} {count}, ({reg_name})", 2
        elif 0x98 <= prefix <= 0x9F and nbytes == 3:
            # 16-bit d8
            r_idx = prefix & 0x07
            d8 = rom_bytes[1]
            sub_opc = rom_bytes[2]
            base_opc = 0x60 if is_inc else 0x68
            if base_opc <= sub_opc <= base_opc + 7:
                if d8 == 0:
                    pass  # Skip d8=0
                else:
                    count = sub_opc - base_opc
                    if count == 0:
                        count = 8
                    reg_name = REG32_BY_INDEX.get(r_idx)
                    if reg_name:
                        disp = d8 if d8 <= 127 else d8 - 256
                        mnem = 'incm' if is_inc else 'decm'
                        if disp >= 0:
                            return f"{mnem} {count}, ({reg_name} + {disp})", 3
                        else:
                            return f"{mnem} {count}, ({reg_name} - {-disp})", 3

    # Tier 32: Indirect JP via B0 prefix (2-byte: B0+r, 0xD8)
    # ASL: "JP T, XHL" → LLVM: "jp (xhl)"
    if nbytes == 2 and rom_bytes is not None and mnem_upper == 'JP':
        prefix = rom_bytes[0]
        if 0xB0 <= prefix <= 0xB7 and rom_bytes[1] == 0xD8:
            r_idx = prefix & 0x07
            reg_name = REG32_BY_INDEX.get(r_idx)
            if reg_name:
                return f"jp ({reg_name})", 2

    # Tier 33: Memory BIT/SET/RES/LDCF/STCF (B0/B8 destination memory prefix)
    # No-disp (2B): B0+r, (base_opc + bit)
    # d8 (3B): B8+r, d8, (base_opc + bit)
    MEM_BIT_OPS = {
        'BIT': (0xC8, 'bitm'), 'SET': (0xB8, 'setm'), 'RES': (0xB0, 'resm'),
        'LDCF': (0x98, 'ldcfm'), 'STCF': (0xA0, 'stcfm'),
    }
    if rom_bytes is not None and mnem_upper in MEM_BIT_OPS:
        prefix = rom_bytes[0]
        if 0xB0 <= prefix <= 0xBF:
            base_opc, native_mnem = MEM_BIT_OPS[mnem_upper]
            base_idx = prefix & 0x07
            has_disp = (prefix & 0x08) != 0
            expected_nbytes = 3 if has_disp else 2
            if nbytes == expected_nbytes:
                sub_opc = rom_bytes[2] if has_disp else rom_bytes[1]
                if base_opc <= sub_opc <= base_opc + 7:
                    bit_num = sub_opc - base_opc
                    base_name = REG32_BY_INDEX.get(base_idx)
                    if base_name:
                        mem_str = None
                        if has_disp:
                            d8 = rom_bytes[1]
                            if d8 > 127:
                                d8 -= 256
                            if d8 < 0:
                                mem_str = f"({base_name} - {-d8})"
                            elif d8 > 0:
                                mem_str = f"({base_name} + {d8})"
                            # d8 == 0: skip
                        else:
                            mem_str = f"({base_name})"
                        if mem_str is not None:
                            return f"{native_mnem} {bit_num}, {mem_str}", expected_nbytes

    # Tier 34: Memory PUSHW (16-bit, register-indirect)
    # No-disp (2B): 0x90+r, 0x04
    # d8 (3B): 0x98+r, d8, 0x04
    if rom_bytes is not None and mnem_upper == 'PUSHW':
        prefix = rom_bytes[0]
        if 0x90 <= prefix <= 0x97 and nbytes == 2:
            if rom_bytes[1] == 0x04:
                r_idx = prefix & 0x07
                reg_name = REG32_BY_INDEX.get(r_idx)
                if reg_name:
                    return f"pushm ({reg_name})", 2
        elif 0x98 <= prefix <= 0x9F and nbytes == 3:
            if rom_bytes[2] == 0x04:
                r_idx = prefix & 0x07
                d8 = rom_bytes[1]
                if d8 == 0:
                    pass  # Skip d8=0
                else:
                    reg_name = REG32_BY_INDEX.get(r_idx)
                    if reg_name:
                        disp = d8 if d8 <= 127 else d8 - 256
                        if disp >= 0:
                            return f"pushm ({reg_name} + {disp})", 3
                        else:
                            return f"pushm ({reg_name} - {-disp})", 3

    # =========================================================================
    # Tier 35: Direct addressing (C1/D1/E1 + addr16 + sub-opcode)
    # Source memory with 16-bit direct address. Sub-opcode table matches
    # register-indirect table. Covers: LD reg,(addr), CP/AND/OR/ADD/SUB
    # (addr)#imm, ALU reg,(addr), INC/DEC (addr).
    # =========================================================================
    if rom_bytes is not None and nbytes >= 4:
        prefix = rom_bytes[0]
        if prefix in (0xC1, 0xD1, 0xE1):
            addr16 = rom_bytes[1] | (rom_bytes[2] << 8)
            sub_opc = rom_bytes[3]
            opsize = {0xC1: 8, 0xD1: 16, 0xE1: 32}[prefix]
            reg_table = {8: REG32_BY_INDEX, 16: REG32_BY_INDEX, 32: REG32_BY_INDEX}
            sz_suffix = {8: '8', 16: '16', 32: '32'}[opsize]
            imm_bytes = {8: 1, 16: 2, 32: 4}[opsize]

            # LD reg, (addr16): sub-opc 0x20-0x27, no extra bytes
            if 0x20 <= sub_opc <= 0x27 and nbytes == 4:
                reg_idx = sub_opc & 0x07
                if opsize == 8:
                    reg_name = REG8_BY_INDEX.get(reg_idx)
                else:
                    reg_name = REG32_BY_INDEX.get(reg_idx)
                if reg_name:
                    return f"ldda{sz_suffix} {reg_name}, {addr16}", nbytes

            # ALU (addr16), #imm: sub-opc 0x38-0x3F, + imm bytes
            if 0x38 <= sub_opc <= 0x3F and nbytes == 4 + imm_bytes:
                alu_idx = sub_opc & 0x07
                imm_val = 0
                for i in range(imm_bytes):
                    imm_val |= rom_bytes[4 + i] << (8 * i)
                alu_ops = {0: 'adddi', 1: 'addci', 2: 'subdi', 3: 'sbcdi',
                           4: 'anddi', 5: 'xordi', 6: 'ordi', 7: 'cpdi'}
                mnem = alu_ops[alu_idx] + sz_suffix
                return f"{mnem} {addr16}, {imm_val}", nbytes

            # ALU reg, (addr16) — load direction: sub-opc 0x80-0xFF (base + reg)
            # ADD=0x80, ADC=0x90, SUB=0xA0, SBC=0xB0, AND=0xC0, XOR=0xD0, OR=0xE0, CP=0xF0
            if sub_opc >= 0x80 and nbytes == 4:
                alu_base = sub_opc & 0xF0
                reg_idx = sub_opc & 0x07
                is_store = (sub_opc & 0x08) != 0  # bit 3 set = result to memory
                if opsize == 8:
                    reg_name = REG8_BY_INDEX.get(reg_idx)
                else:
                    reg_name = REG32_BY_INDEX.get(reg_idx)
                if reg_name:
                    if is_store:
                        alu_store_ops = {0x80: 'adddm', 0x90: 'addcdm', 0xA0: 'subdm',
                                         0xB0: 'sbcdm', 0xC0: 'anddm', 0xD0: 'xordm',
                                         0xE0: 'orddm', 0xF0: 'cpdm'}
                        mnem_base = alu_store_ops.get(alu_base)
                        if mnem_base:
                            mnem = mnem_base + sz_suffix
                            return f"{mnem} {addr16}, {reg_name}", nbytes
                    else:
                        alu_load_ops = {0x80: 'addda', 0x90: 'addcda', 0xA0: 'subda',
                                        0xB0: 'sbcda', 0xC0: 'andda', 0xD0: 'xorda',
                                        0xE0: 'orda', 0xF0: 'cpda'}
                        mnem_base = alu_load_ops.get(alu_base)
                        if mnem_base:
                            mnem = mnem_base + sz_suffix
                            return f"{mnem} {reg_name}, {addr16}", nbytes

            # INC/DEC (addr16): sub-opc 0x60+count / 0x68+count
            if 0x60 <= sub_opc <= 0x6F and nbytes == 4:
                is_dec = (sub_opc & 0x08) != 0
                count = sub_opc & 0x07
                if count == 0:
                    count = 8
                mnem = ('decdi' if is_dec else 'incdi') + sz_suffix
                return f"{mnem} {count}, {addr16}", nbytes

            # LD (dst_addr), (src_addr): sub-opc 0x19, + dst_addr16 (6 bytes)
            if sub_opc == 0x19 and nbytes == 6 and opsize in (8, 16):
                dst_addr = rom_bytes[4] | (rom_bytes[5] << 8)
                mnem = 'ldmm8' if opsize == 8 else 'ldmm16'
                return f"{mnem} {dst_addr}, {addr16}", nbytes

    # =========================================================================
    # Tier 36: Direct addressing (C2/D2/E2 + addr24 + sub-opcode)
    # Source memory with 24-bit direct address. Same sub-opcode table as Tier 35.
    # =========================================================================
    if rom_bytes is not None and nbytes >= 5:
        prefix = rom_bytes[0]
        if prefix in (0xC2, 0xD2, 0xE2):
            addr24 = rom_bytes[1] | (rom_bytes[2] << 8) | (rom_bytes[3] << 16)
            sub_opc = rom_bytes[4]
            opsize = {0xC2: 8, 0xD2: 16, 0xE2: 32}[prefix]
            sz_suffix = {8: '8', 16: '16', 32: '32'}[opsize]
            imm_bytes = {8: 1, 16: 2, 32: 4}[opsize]
            suffix24 = '_24'

            # LD reg, (addr24): sub-opc 0x20-0x27
            if 0x20 <= sub_opc <= 0x27 and nbytes == 5:
                reg_idx = sub_opc & 0x07
                if opsize == 8:
                    reg_name = REG8_BY_INDEX.get(reg_idx)
                else:
                    reg_name = REG32_BY_INDEX.get(reg_idx)
                if reg_name:
                    return f"ldda{sz_suffix}{suffix24} {reg_name}, {addr24}", nbytes

            # ALU (addr24), #imm: sub-opc 0x38-0x3F (all sizes)
            if 0x38 <= sub_opc <= 0x3F and nbytes == 5 + imm_bytes:
                alu_idx = sub_opc & 0x07
                imm_val = 0
                for i in range(imm_bytes):
                    imm_val |= rom_bytes[5 + i] << (8 * i)
                alu_ops = {0: 'adddi', 1: 'addci', 2: 'subdi', 3: 'sbcdi',
                           4: 'anddi', 5: 'xordi', 6: 'ordi', 7: 'cpdi'}
                mnem = alu_ops[alu_idx] + sz_suffix + suffix24
                return f"{mnem} {addr24}, {imm_val}", nbytes

            # ALU reg, (addr24) — load and store direction (all sizes)
            if sub_opc >= 0x80 and nbytes == 5:
                alu_base = sub_opc & 0xF0
                reg_idx = sub_opc & 0x07
                is_store = (sub_opc & 0x08) != 0
                if opsize == 8:
                    reg_name = REG8_BY_INDEX.get(reg_idx)
                else:
                    reg_name = REG32_BY_INDEX.get(reg_idx)
                if reg_name:
                    if is_store:
                        alu_store_ops = {0x80: 'adddm', 0x90: 'addcdm', 0xA0: 'subdm',
                                         0xB0: 'sbcdm', 0xC0: 'anddm', 0xD0: 'xordm',
                                         0xE0: 'ordm', 0xF0: 'cpdm'}
                        mnem_base = alu_store_ops.get(alu_base)
                        if mnem_base:
                            mnem = mnem_base + sz_suffix + suffix24
                            return f"{mnem} {addr24}, {reg_name}", nbytes
                    else:
                        alu_load_ops = {0x80: 'addda', 0x90: 'addcda', 0xA0: 'subda',
                                        0xB0: 'sbcda', 0xC0: 'andda', 0xD0: 'xorda',
                                        0xE0: 'orda', 0xF0: 'cpda'}
                        mnem_base = alu_load_ops.get(alu_base)
                        if mnem_base:
                            mnem = mnem_base + sz_suffix + suffix24
                            return f"{mnem} {reg_name}, {addr24}", nbytes

            # INC/DEC (addr24): sub-opc 0x60+count / 0x68+count
            if 0x60 <= sub_opc <= 0x6F and nbytes == 5:
                is_dec = (sub_opc & 0x08) != 0
                count = sub_opc & 0x07
                if count == 0:
                    count = 8
                mnem = ('decdi' if is_dec else 'incdi') + sz_suffix + suffix24
                return f"{mnem} {count}, {addr24}", nbytes

    # =========================================================================
    # Tier 37: Destination direct addressing (F1 + addr16 + sub-opcode)
    # Covers: LD (addr),reg; LD (addr),#imm; LDA reg,addr; BIT/SET/RES (addr);
    #         INC/DEC (addr) via F1.
    # =========================================================================
    if rom_bytes is not None and nbytes >= 4 and rom_bytes[0] == 0xF1:
        addr16 = rom_bytes[1] | (rom_bytes[2] << 8)
        sub_opc = rom_bytes[3]

        # LD (addr16), reg8: sub-opc 0x40+reg8, nbytes=4
        if 0x40 <= sub_opc <= 0x47 and nbytes == 4:
            reg_idx = sub_opc & 0x07
            reg_name = REG8_BY_INDEX.get(reg_idx)
            if reg_name:
                return f"stda8 {addr16}, {reg_name}", nbytes

        # LD (addr16), reg16: sub-opc 0x50+reg16, nbytes=4
        if 0x50 <= sub_opc <= 0x57 and nbytes == 4:
            reg_idx = sub_opc & 0x07
            reg_name = REG32_BY_INDEX.get(reg_idx)
            if reg_name:
                return f"stda16 {addr16}, {reg_name}", nbytes

        # LD (addr16), reg32: sub-opc 0x60+reg32, nbytes=4
        if 0x60 <= sub_opc <= 0x67 and nbytes == 4:
            reg_idx = sub_opc & 0x07
            reg_name = REG32_BY_INDEX.get(reg_idx)
            if reg_name:
                return f"stda32 {addr16}, {reg_name}", nbytes

        # LD (addr16), #imm8: sub-opc 0x00, nbytes=5
        if sub_opc == 0x00 and nbytes == 5:
            imm8 = rom_bytes[4]
            return f"stdi8 {addr16}, {imm8}", nbytes

        # LDW (addr16), #imm16: sub-opc 0x02, nbytes=6
        if sub_opc == 0x02 and nbytes == 6:
            imm16 = rom_bytes[4] | (rom_bytes[5] << 8)
            return f"stdi16 {addr16}, {imm16}", nbytes

        # LDA reg32, addr16: sub-opc 0x30+reg32, nbytes=4
        if 0x30 <= sub_opc <= 0x37 and nbytes == 4:
            reg_idx = sub_opc & 0x07
            reg_name = REG32_BY_INDEX.get(reg_idx)
            if reg_name:
                return f"ldada {reg_name}, {addr16}", nbytes

        # BIT (addr16), bit: sub-opc 0xC8+bit, nbytes=4
        if 0xC8 <= sub_opc <= 0xCF and nbytes == 4:
            bit_num = sub_opc & 0x07
            return f"bitda {bit_num}, {addr16}", nbytes

        # SET (addr16), bit: sub-opc 0xB8+bit, nbytes=4
        if 0xB8 <= sub_opc <= 0xBF and nbytes == 4:
            bit_num = sub_opc & 0x07
            return f"setda {bit_num}, {addr16}", nbytes

        # RES (addr16), bit: sub-opc 0xB0+bit, nbytes=4
        if 0xB0 <= sub_opc <= 0xB7 and nbytes == 4:
            bit_num = sub_opc & 0x07
            return f"resda {bit_num}, {addr16}", nbytes

        # TSET (addr16), bit: sub-opc 0xA0+bit, nbytes=4
        if 0xA0 <= sub_opc <= 0xA7 and nbytes == 4:
            bit_num = sub_opc & 0x07
            return f"tsetda {bit_num}, {addr16}", nbytes

        # INC (addr16): sub-opc 0x60+count, nbytes=4
        if 0x60 <= sub_opc <= 0x67 and nbytes == 4:
            count = sub_opc & 0x07
            if count == 0:
                count = 8
            return f"incdd8 {count}, {addr16}", nbytes

        # DEC (addr16): sub-opc 0x68+count, nbytes=4
        if 0x68 <= sub_opc <= 0x6F and nbytes == 4:
            count = sub_opc & 0x07
            if count == 0:
                count = 8
            return f"decdd8 {count}, {addr16}", nbytes

        # INCW (addr16): sub-opc 0x70+count, nbytes=4 (word INC in F1 table)
        if 0x70 <= sub_opc <= 0x77 and nbytes == 4:
            count = sub_opc & 0x07
            if count == 0:
                count = 8
            return f"incdd16 {count}, {addr16}", nbytes

        # DECW (addr16): sub-opc 0x78+count, nbytes=4
        if 0x78 <= sub_opc <= 0x7F and nbytes == 4:
            count = sub_opc & 0x07
            if count == 0:
                count = 8
            return f"decdd16 {count}, {addr16}", nbytes

        # ALU (addr16), #imm8: sub-opc 0x38-0x3F (only byte ops under F1)
        # CP=0x3F, OR=0x3E, XOR=0x3D, AND=0x3C, SBC=0x3B, SUB=0x3A, ADC=0x39, ADD=0x38
        # Wait, these are under the destination table... Actually the sub-opcode
        # table for F1 has 0x38-0x3F for ALU (addr), #imm too.
        # These seem to always be 8-bit under F1. Let me check the data.
        # Actually, looking at F1 data: 0x3F = CP etc. but the byte count varies.
        # Under F1, 0x38-0x3F + imm8 would be 5 bytes for byte ops.
        # This needs more investigation. Skip for now.

    # =========================================================================
    # Tier 38: Destination direct addressing (F2 + addr24 + sub-opcode)
    # Same as Tier 37 but with 24-bit address.
    # =========================================================================
    if rom_bytes is not None and nbytes >= 5 and rom_bytes[0] == 0xF2:
        addr24 = rom_bytes[1] | (rom_bytes[2] << 8) | (rom_bytes[3] << 16)
        sub_opc = rom_bytes[4]

        # LD (addr24), reg8: sub-opc 0x40+reg8, nbytes=5
        if 0x40 <= sub_opc <= 0x47 and nbytes == 5:
            reg_idx = sub_opc & 0x07
            reg_name = REG8_BY_INDEX.get(reg_idx)
            if reg_name:
                return f"stda8_24 {addr24}, {reg_name}", nbytes

        # LD (addr24), reg16: sub-opc 0x50+reg16, nbytes=5
        if 0x50 <= sub_opc <= 0x57 and nbytes == 5:
            reg_idx = sub_opc & 0x07
            reg_name = REG32_BY_INDEX.get(reg_idx)
            if reg_name:
                return f"stda16_24 {addr24}, {reg_name}", nbytes

        # LD (addr24), reg32: sub-opc 0x60+reg32, nbytes=5
        if 0x60 <= sub_opc <= 0x67 and nbytes == 5:
            reg_idx = sub_opc & 0x07
            reg_name = REG32_BY_INDEX.get(reg_idx)
            if reg_name:
                return f"stda32_24 {addr24}, {reg_name}", nbytes

        # LD (addr24), #imm8: sub-opc 0x00, nbytes=6
        if sub_opc == 0x00 and nbytes == 6:
            imm8 = rom_bytes[5]
            return f"stdi8_24 {addr24}, {imm8}", nbytes

        # LDW (addr24), #imm16: sub-opc 0x02, nbytes=7
        if sub_opc == 0x02 and nbytes == 7:
            imm16 = rom_bytes[5] | (rom_bytes[6] << 8)
            return f"stdi16_24 {addr24}, {imm16}", nbytes

        # LDA reg32, addr24: sub-opc 0x30+reg32, nbytes=5
        if 0x30 <= sub_opc <= 0x37 and nbytes == 5:
            reg_idx = sub_opc & 0x07
            reg_name = REG32_BY_INDEX.get(reg_idx)
            if reg_name:
                return f"ldada_24 {reg_name}, {addr24}", nbytes

        # BIT (addr24): sub-opc 0xC8+bit, nbytes=5
        if 0xC8 <= sub_opc <= 0xCF and nbytes == 5:
            bit_num = sub_opc & 0x07
            return f"bitda_24 {bit_num}, {addr24}", nbytes

        # SET (addr24): sub-opc 0xB8+bit, nbytes=5
        if 0xB8 <= sub_opc <= 0xBF and nbytes == 5:
            bit_num = sub_opc & 0x07
            return f"setda_24 {bit_num}, {addr24}", nbytes

        # RES (addr24): sub-opc 0xB0+bit, nbytes=5
        if 0xB0 <= sub_opc <= 0xB7 and nbytes == 5:
            bit_num = sub_opc & 0x07
            return f"resda_24 {bit_num}, {addr24}", nbytes

        # CHG (addr24): sub-opc 0xC0+bit, nbytes=5
        if 0xC0 <= sub_opc <= 0xC7 and nbytes == 5:
            bit_num = sub_opc & 0x07
            return f"chgda_24 {bit_num}, {addr24}", nbytes

        # TSET (addr24): sub-opc 0xA0+bit, nbytes=5
        if 0xA0 <= sub_opc <= 0xA7 and nbytes == 5:
            bit_num = sub_opc & 0x07
            return f"tsetda_24 {bit_num}, {addr24}", nbytes

        # INC (addr24): sub-opc 0x60+count, nbytes=5
        if 0x60 <= sub_opc <= 0x67 and nbytes == 5:
            count = sub_opc & 0x07
            if count == 0:
                count = 8
            return f"incdd8_24 {count}, {addr24}", nbytes

        # DEC (addr24): sub-opc 0x68+count, nbytes=5
        if 0x68 <= sub_opc <= 0x6F and nbytes == 5:
            count = sub_opc & 0x07
            if count == 0:
                count = 8
            return f"decdd8_24 {count}, {addr24}", nbytes

        # INCW (addr24): sub-opc 0x70+count, nbytes=5
        if 0x70 <= sub_opc <= 0x77 and nbytes == 5:
            count = sub_opc & 0x07
            if count == 0:
                count = 8
            return f"incdd16_24 {count}, {addr24}", nbytes

        # DECW (addr24): sub-opc 0x78+count, nbytes=5
        if 0x78 <= sub_opc <= 0x7F and nbytes == 5:
            count = sub_opc & 0x07
            if count == 0:
                count = 8
            return f"decdd16_24 {count}, {addr24}", nbytes

    return None  # No native conversion available


def convert_instruction(label, mnemonic, operands_str, comment, label_addr_suffix=""):
    """Convert a CPU instruction to native LLVM or .byte fallback."""
    global BLOCK_CURSOR, NATIVE_INSTR_COUNT, BYTE_FALLBACK_COUNT

    result = ""
    if label:
        result = f"{label}:{label_addr_suffix}\n"

    addr = ADDR_TRACKER.get_addr()
    nbytes = get_instruction_size_from_rom(addr) if addr is not None else None

    if BLOCK_BUFFER is not None and nbytes is not None:
        # Use block buffer — guarantees correct byte content and total count
        remaining = BLOCK_SIZE - BLOCK_CURSOR
        if nbytes > remaining:
            nbytes = remaining  # Clamp to block boundary
        if nbytes > 0:
            rom_bytes = BLOCK_BUFFER[BLOCK_CURSOR:BLOCK_CURSOR + nbytes]
            # Try native conversion first
            native = try_convert_native(mnemonic, operands_str, rom_bytes, nbytes, addr)
            if native is not None:
                native_asm, _ = native
                result += f"\t{native_asm}"
                NATIVE_INSTR_COUNT += 1
            else:
                byte_str = ', '.join(f'0x{b:02x}' for b in rom_bytes)
                original = f"{mnemonic} {operands_str}".strip() if operands_str else mnemonic
                result += f"\t.byte {byte_str}\t; {original}"
                BYTE_FALLBACK_COUNT += 1
            BLOCK_CURSOR += nbytes
            ADDR_TRACKER.advance(nbytes)
        else:
            # Block buffer exhausted — emit as comment only
            original = f"{mnemonic} {operands_str}".strip() if operands_str else mnemonic
            result += f"\t; (block overflow) {original}"
    elif addr is not None and nbytes is not None:
        offset = addr - ROM_BASE
        rom_bytes = ORIGINAL_ROM[offset:offset + nbytes]
        byte_str = ', '.join(f'0x{b:02x}' for b in rom_bytes)
        original = f"{mnemonic} {operands_str}".strip() if operands_str else mnemonic
        result += f"\t.byte {byte_str}\t; {original}"
        ADDR_TRACKER.advance(nbytes)
    else:
        # No address tracking — preserve as comment
        original = f"{mnemonic} {operands_str}".strip() if operands_str else mnemonic
        result += f"\t; (no addr) {original}"

    if comment:
        result += f"\t{comment}"
    return result


# ============================================================================
# Data directive helpers
# ============================================================================

def _escape_string_bytes(byte_seq):
    """Escape bytes for use in .ascii/.asciz string literal."""
    result = []
    for b in byte_seq:
        ch = chr(b)
        if ch == '"':
            result.append('\\"')
        elif ch == '\\':
            result.append('\\\\')
        else:
            result.append(ch)
    return ''.join(result)


def _try_emit_as_string(rom_bytes):
    """Try to emit rom_bytes as .ascii/.asciz/.byte segments.

    Splits mixed content into separate directives for readability:
    - Runs of printable ASCII (>= 4 chars) → .ascii or .asciz
    - Non-printable bytes → .byte

    Returns a string of directives or None if no string segments found.
    """
    if len(rom_bytes) < 4:
        return None

    # Scan for runs of printable ASCII (>= 4 chars)
    segments = []  # (type, data) where type is 'bytes' or 'string'
    i = 0
    while i < len(rom_bytes):
        # Check for a run of printable ASCII
        j = i
        while j < len(rom_bytes) and 0x20 <= rom_bytes[j] <= 0x7E:
            j += 1
        if j - i >= 4:
            # Found a printable string run
            if i > 0 or segments:
                # Flush preceding non-printable bytes
                pass  # Already handled below
            # Check for null terminator
            if j < len(rom_bytes) and rom_bytes[j] == 0x00:
                segments.append(('asciz', rom_bytes[i:j]))
                i = j + 1  # Skip the null byte
            else:
                segments.append(('ascii', rom_bytes[i:j]))
                i = j
        else:
            # Non-printable byte (or short printable run)
            # Collect consecutive non-printable bytes
            k = i
            while k < len(rom_bytes):
                # Check if we're at the start of a printable run >= 4
                if 0x20 <= rom_bytes[k] <= 0x7E:
                    run_end = k
                    while run_end < len(rom_bytes) and 0x20 <= rom_bytes[run_end] <= 0x7E:
                        run_end += 1
                    if run_end - k >= 4:
                        break  # Start of a new string run
                k += 1
            if k > i:
                segments.append(('bytes', rom_bytes[i:k]))
            i = k

    # Only use this if we found at least one string segment
    has_string = any(t in ('ascii', 'asciz') for t, _ in segments)
    if not has_string:
        return None

    parts = []
    for seg_type, seg_data in segments:
        if seg_type == 'bytes':
            byte_str = ', '.join(f'0x{b:02x}' for b in seg_data)
            parts.append(f'.byte {byte_str}')
        elif seg_type == 'ascii':
            s = _escape_string_bytes(seg_data)
            parts.append(f'.ascii "{s}"')
        elif seg_type == 'asciz':
            s = _escape_string_bytes(seg_data)
            parts.append(f'.asciz "{s}"')
    return '\n\t'.join(parts)


def _count_db_bytes(args):
    """Count the number of bytes a db directive emits."""
    # Handle dup pattern
    dup_match = re.match(r'(.+?)\s+dup\s*\(([^)]+)\)', args, re.IGNORECASE)
    if dup_match:
        try:
            count_expr = convert_expression(dup_match.group(1).strip())
            return eval_expr(count_expr)
        except:
            return None

    parts = split_db_args(args)
    total = 0
    for part in parts:
        part = part.strip()
        if part.startswith('"') and part.endswith('"'):
            # String literal: count characters (minus the quotes)
            total += len(part) - 2
        else:
            total += 1  # Single byte value
    return total


def _db_args_all_numeric(args):
    """Check if all DB arguments are literal numeric values (hex/decimal).

    Returns True if the comment is redundant (just restates hex bytes).
    """
    parts = split_db_args(args)
    for part in parts:
        part = part.strip()
        if part.startswith('"') and part.endswith('"'):
            return False  # String literal — comment might add context
        # Check if it's a simple hex or decimal literal
        if not re.match(r'^[0-9][0-9A-Fa-f]*[hH]$', part) and \
           not re.match(r'^0x[0-9A-Fa-f]+$', part) and \
           not re.match(r'^[0-9]+$', part):
            return False  # Contains label/expression
    return True


def _dw_args_all_numeric(args):
    """Check if all DW arguments are literal numeric values."""
    parts = split_operands(args)
    for part in parts:
        part = part.strip()
        if not re.match(r'^[0-9][0-9A-Fa-f]*[hH]$', part) and \
           not re.match(r'^0x[0-9A-Fa-f]+$', part) and \
           not re.match(r'^[0-9]+$', part):
            return False
    return True


def convert_db(label, args, comment, in_file_path, label_addr_suffix=""):
    """Convert db directive - handle strings, bytes, and dup patterns."""
    global BLOCK_CURSOR
    result = ""
    if label:
        result = f"{label}:{label_addr_suffix}\n"

    # Track bytes for address advancement
    nbytes = _count_db_bytes(args)

    # When inside a block buffer, emit from ROM for guaranteed correctness
    if BLOCK_BUFFER is not None and nbytes is not None:
        remaining = BLOCK_SIZE - BLOCK_CURSOR
        if nbytes > remaining:
            nbytes = remaining
        if nbytes > 0:
            rom_bytes = BLOCK_BUFFER[BLOCK_CURSOR:BLOCK_CURSOR + nbytes]
            string_form = _try_emit_as_string(rom_bytes)
            if string_form is not None:
                result += f"\t{string_form}"
            else:
                byte_str = ', '.join(f'0x{b:02x}' for b in rom_bytes)
                if _db_args_all_numeric(args):
                    result += f"\t.byte {byte_str}"
                else:
                    result += f"\t.byte {byte_str}\t; DB {args}"
            BLOCK_CURSOR += nbytes
            ADDR_TRACKER.advance(nbytes)
        if comment:
            result += f"\t{comment}"
        return result

    # Outside block buffer — use source-based conversion
    # Handle ASL dup pattern: db 920 dup (000h) → .fill 920, 1, 0x0
    dup_match = re.match(r'(.+?)\s+dup\s*\(([^)]+)\)', args, re.IGNORECASE)
    if dup_match:
        count = convert_expression(dup_match.group(1).strip())
        fill_value = convert_expression(dup_match.group(2).strip())
        result += f"\t.fill {count}, 1, {fill_value}"
        if comment:
            result += f"\t{comment}"
        if nbytes is not None:
            ADDR_TRACKER.advance(nbytes)
        return result

    # Split into parts
    parts = split_db_args(args)
    converted_parts = []
    current_bytes = []

    for part in parts:
        part = part.strip()
        if part.startswith('"') and part.endswith('"'):
            if current_bytes:
                converted_parts.append(f"\t.byte {', '.join(current_bytes)}")
                current_bytes = []
            converted_parts.append(f'\t.ascii {part}')
        else:
            current_bytes.append(convert_expression(part))

    if current_bytes:
        converted_parts.append(f"\t.byte {', '.join(current_bytes)}")

    result += '\n'.join(converted_parts)
    if comment:
        result += f"\t{comment}"
    if nbytes is not None:
        ADDR_TRACKER.advance(nbytes)
    return result


def split_db_args(args):
    """Split db arguments, respecting quoted strings and parentheses."""
    parts = []
    current = ""
    in_string = False
    depth = 0
    for ch in args:
        if ch == '"':
            in_string = not in_string
            current += ch
        elif in_string:
            current += ch
        elif ch == '(':
            depth += 1
            current += ch
        elif ch == ')':
            depth -= 1
            current += ch
        elif ch == ',' and depth == 0:
            parts.append(current.strip())
            current = ""
        else:
            current += ch
    if current.strip():
        parts.append(current.strip())
    return parts


def _dw_has_label_refs(args):
    """Check if dw arguments reference labels (non-numeric expressions)."""
    parts = split_operands(args)
    for part in parts:
        part = part.strip()
        # If it contains letters (not just hex digits/operators), it's a label ref
        cleaned = convert_expression(part)
        if re.search(r'[A-Za-z_]\w*', cleaned):
            # Check it's not just a hex number
            if not re.match(r'^0x[0-9A-Fa-f]+$', cleaned):
                return True
    return False


def _try_dw_label_arithmetic(args):
    """Try to convert DW args with label arithmetic to symbolic expressions.

    Handles patterns like:
      (LABEL_A - BASE)     → LABEL_A - BASE
      -BASE + LABEL_A      → LABEL_A - BASE

    Returns list of symbolic strings if ALL operands are label arithmetic,
    or None if any operand doesn't match the pattern.
    Uses A - B syntax (required by llvm-mc; -B + A is not supported).
    """
    parts = split_operands(args)

    symbolic = []
    for part in parts:
        part = part.strip()

        # Pattern 1: (A - B) with parens → A - B
        m = re.match(r'^\((\w+)\s*-\s*(\w+)\)$', part)
        if m:
            symbolic.append(f"{m.group(1)} - {m.group(2)}")
            continue

        # Pattern 2: -BASE + LABEL (no parens) → LABEL - BASE
        m = re.match(r'^-(\w+)\s*\+\s*(\w+)$', part)
        if m:
            symbolic.append(f"{m.group(2)} - {m.group(1)}")
            continue

        # Not a label arithmetic pattern
        return None

    return symbolic


def convert_dw(label, args, comment, label_addr_suffix=""):
    """Convert dw to .short, falling back to ROM bytes for label references."""
    global BLOCK_CURSOR
    result = ""
    if label:
        result = f"{label}:{label_addr_suffix}\n"

    nvalues = len(split_operands(args))
    nbytes = 2 * nvalues
    addr = ADDR_TRACKER.get_addr()

    # When inside a block buffer, always emit from ROM
    if BLOCK_BUFFER is not None:
        remaining = BLOCK_SIZE - BLOCK_CURSOR
        if nbytes > remaining:
            nbytes = remaining
        if nbytes > 0:
            rom_bytes = BLOCK_BUFFER[BLOCK_CURSOR:BLOCK_CURSOR + nbytes]
            # Try symbolic label arithmetic (e.g., -BASE + LABEL)
            sym_exprs = _try_dw_label_arithmetic(args)
            if sym_exprs is not None:
                result += f"\t.short {', '.join(sym_exprs)}"
            else:
                shorts = []
                for i in range(0, nbytes, 2):
                    chunk = rom_bytes[i:i+2]
                    if len(chunk) == 2:
                        val = chunk[0] | (chunk[1] << 8)
                        shorts.append(f'0x{val:04X}')
                if shorts:
                    short_str = ', '.join(shorts)
                    if _dw_args_all_numeric(args):
                        result += f"\t.short {short_str}"
                    else:
                        result += f"\t.short {short_str}\t; DW {args}"
            BLOCK_CURSOR += nbytes
            ADDR_TRACKER.advance(nbytes)
        if comment:
            result += f"\t{comment}"
        return result

    # Outside block buffer — use source-based conversion
    # If dw references labels, try symbolic arithmetic or emit raw bytes from ROM
    if _dw_has_label_refs(args) and addr is not None:
        rom_bytes = get_rom_bytes(addr, nbytes)
        if rom_bytes is not None:
            sym_exprs = _try_dw_label_arithmetic(args)
            if sym_exprs is not None:
                result += f"\t.short {', '.join(sym_exprs)}"
            else:
                original = f"DW {args}"
                shorts = []
                for i in range(0, nbytes, 2):
                    chunk = rom_bytes[i:i+2]
                    if len(chunk) == 2:
                        val = chunk[0] | (chunk[1] << 8)
                        shorts.append(f'0x{val:04X}')
                if shorts:
                    result += f"\t.short {', '.join(shorts)}\t; {original}"
            ADDR_TRACKER.advance(nbytes)
            if comment:
                result += f"\t{comment}"
            return result

    values = convert_expression(args)
    result += f"\t.short {values}"
    if comment:
        result += f"\t{comment}"
    ADDR_TRACKER.advance(nbytes)
    return result


# ============================================================================
# Address resolution
# ============================================================================

def resolve_org_addr(addr_expr):
    """Resolve ORG address to integer value."""
    addr_expr = addr_expr.strip()

    # Try ASL hex
    m = re.match(r'^0?([0-9A-Fa-f]+)[hH]$', addr_expr)
    if m:
        return int(m.group(1), 16)

    # Try 0x hex
    m = re.match(r'^0x([0-9A-Fa-f]+)$', addr_expr, re.IGNORECASE)
    if m:
        return int(m.group(1), 16)

    # Try decimal
    m = re.match(r'^(\d+)$', addr_expr)
    if m:
        return int(m.group(1))

    # Try known EQU
    if addr_expr in KNOWN_EQUS:
        return KNOWN_EQUS[addr_expr]

    return None


def eval_expr(expr):
    """Try to evaluate a simple expression to an integer."""
    expr = expr.strip()
    # 0x hex
    m = re.match(r'^0x([0-9A-Fa-f]+)$', expr, re.IGNORECASE)
    if m:
        return int(m.group(1), 16)
    # Decimal
    m = re.match(r'^(\d+)$', expr)
    if m:
        return int(m.group(1))
    raise ValueError(f"Cannot evaluate: {expr}")


# ============================================================================
# Macro library conversion
# ============================================================================

def convert_macro_file(input_path, output_path):
    """Convert the ASL macro library to LLVM .macro/.endm format."""
    with open(input_path, 'r') as f:
        lines = f.readlines()

    output_lines = []
    current_params = []  # Parameter names for current macro

    for line in lines:
        line = line.rstrip('\n')
        stripped = line.strip()

        if not stripped:
            output_lines.append("")
            continue

        if stripped.startswith(';'):
            output_lines.append(line)
            continue

        # MACRO definition
        m = re.match(r'^(\w+)\s+MACRO\s*(.*)', stripped, re.IGNORECASE)
        if m:
            macro_name = m.group(1)
            args_str = m.group(2).strip()
            KNOWN_MACROS.add(macro_name.upper())
            current_params = re.split(r'[,\s]+', args_str) if args_str else []

            if args_str:
                output_lines.append(f".macro {macro_name} {args_str}")
            else:
                output_lines.append(f".macro {macro_name}")
            continue

        # ENDM
        if stripped.upper() == 'ENDM':
            output_lines.append(".endm")
            output_lines.append("")
            current_params = []
            continue

        # Macro body: convert db/dw to .byte/.short with parameter escaping
        code_part, comment = split_comment(stripped)
        code_stripped = code_part.strip()

        if code_stripped:
            first_word, remainder = get_first_word(code_stripped)
            first_upper = first_word.upper()

            if first_upper == 'DB':
                converted = convert_macro_body_bytes(remainder.strip(), current_params)
                line_out = f"\t.byte {converted}"
            elif first_upper == 'DW':
                converted = convert_macro_body_expr(remainder.strip(), current_params)
                line_out = f"\t.short {converted}"
            elif first_upper == 'DD':
                converted = convert_macro_body_expr(remainder.strip(), current_params)
                line_out = f"\t.long {converted}"
            else:
                line_out = f"\t; (unconverted) {stripped}"

            if comment:
                line_out += f"\t{comment}"
            output_lines.append(line_out)
        else:
            output_lines.append(f"\t{comment}" if comment else "")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        f.write('\n'.join(output_lines) + '\n')

    print(f"  Converted macro library: {input_path} → {output_path}")
    print(f"  Found {len(KNOWN_MACROS)} macro definitions")


def convert_macro_body_bytes(args, params):
    """Convert db args in macro body, escaping parameter references."""
    parts = split_db_args(args)
    converted = [convert_macro_body_expr(p.strip(), params) for p in parts]
    return ', '.join(converted)


def convert_macro_body_expr(expr, params):
    """Convert expression in macro body, handling parameter references."""
    expr = convert_hex_in_text(expr)
    expr = re.sub(r'(?<!\w)\$(?!\w)', '.', expr)

    # Escape parameter references: bare param name → \param
    for param in params:
        if param:
            expr = re.sub(r'\b' + re.escape(param) + r'\b', '\\\\' + param, expr)

    return expr


# ============================================================================
# File conversion — global ORG sorting with inlined includes
# ============================================================================

def read_all_lines(input_path, main_dir, depth=0):
    """Recursively read an ASL file, inlining includes (except macro library).

    Returns a list of (line_text, source_file) tuples.
    """
    if depth > 10:
        return []

    result = []
    file_dir = os.path.dirname(input_path)
    with open(input_path, 'r') as f:
        for line in f:
            line = line.rstrip('\n')
            stripped = line.strip()
            code_part, _ = split_comment(stripped)
            code_stripped = code_part.strip()

            # Check for include directive
            m = re.match(r'include\s+"([^"]+)"', code_stripped, re.IGNORECASE)
            if m:
                inc_path = m.group(1)
                if 'tmp94c241.inc' in inc_path:
                    # Skip macro library — handled separately
                    result.append((line, input_path))
                    continue
                full_path = os.path.normpath(os.path.join(file_dir, inc_path))
                if os.path.exists(full_path):
                    result.append((f"; --- begin include: {inc_path} ---", input_path))
                    result.extend(read_all_lines(full_path, main_dir, depth + 1))
                    result.append((f"; --- end include: {inc_path} ---", input_path))
                else:
                    result.append((f"; WARNING: include not found: {inc_path}", input_path))
                continue

            result.append((line, input_path))

    return result


def _record_label(mapping, addr, name):
    """Record label, preferring named labels over LABEL_XXXXXX."""
    is_auto = bool(re.match(r'^LABEL_[0-9A-Fa-f]{6}$', name))
    existing = mapping.get(addr)
    if existing is None:
        mapping[addr] = name
    elif is_auto:
        pass  # Don't overwrite a named label with LABEL_XXXXXX
    else:
        mapping[addr] = name  # Named label takes priority


def _build_addr_to_label_map(sorted_content, seg_end_map, label_only_labels):
    """Pre-pass: build address -> label_name maps from all segments.

    Returns (addr_to_label, addr_to_label_all):
    - addr_to_label: reliable addresses only (LABEL_XXXXXX, label-only segments,
      named labels at segment start / LABEL_ boundaries / address comments).
      Used for JP/CALL symbolization where wrong addresses break byte-matching.
    - addr_to_label_all: includes all labels with address-tracked positions
      (via data directive sizes, binclude ranges, instruction sizes).
      Used for .long symbolization with additional address verification.
    """
    addr_to_label = {}
    addr_to_label_all = {}

    # 1. Label-only segments (explicit ORG addresses — always reliable)
    for addr, names in label_only_labels.items():
        for name in names:
            _record_label(addr_to_label, addr, name)
            _record_label(addr_to_label_all, addr, name)

    # 2. Content segments: extract label addresses using address tracking.
    for seg_addr, seg_lines in sorted_content:
        if seg_addr is None:
            continue
        cur_addr = seg_addr
        at_reliable_boundary = True
        for line, source in seg_lines:
            code_part, cmt = split_comment(line.strip())
            code_stripped = code_part.strip()
            if not code_stripped:
                continue
            label, rest = extract_label(code_stripped)

            if label:
                m_lbl = re.match(r'^LABEL_([0-9A-Fa-f]{6})$', label)
                if m_lbl:
                    cur_addr = int(m_lbl.group(1), 16)
                    _record_label(addr_to_label, cur_addr, label)
                    _record_label(addr_to_label_all, cur_addr, label)
                    at_reliable_boundary = True
                else:
                    # Named label — check for address hint in comment
                    if cmt:
                        m_addr = re.match(r'^;\s*([0-9A-Fa-f]{6})\s*$', cmt.strip())
                        if m_addr:
                            cur_addr = int(m_addr.group(1), 16)
                            at_reliable_boundary = True
                    # Reliable: record in both maps
                    if at_reliable_boundary:
                        _record_label(addr_to_label, cur_addr, label)
                    # All: always record with tracked address
                    _record_label(addr_to_label_all, cur_addr, label)

            # Advance cur_addr by the size of the directive/instruction
            directive = rest.strip() if rest else code_stripped if not label else ''
            if not directive:
                continue
            first, remainder = get_first_word(directive)
            fu = first.upper()
            if fu == 'EQU' or fu == 'SECTION' or fu == 'ENDS' or fu == 'ORG':
                continue  # No bytes emitted
            if fu == 'BINCLUDE':
                bm = re.search(r'([0-9a-fA-F]{5,6})_([0-9a-fA-F]{5,6})\.bin', remainder)
                if bm:
                    bstart = int(bm.group(1), 16)
                    bend = int(bm.group(2), 16)
                    cur_addr += (bend - bstart + 1)
                continue
            at_reliable_boundary = False  # Past data/instructions
            if fu == 'DB':
                nbytes = _count_db_bytes(remainder.strip()) if remainder else 0
                if nbytes:
                    cur_addr += nbytes
            elif fu == 'DW':
                nvalues = len(split_operands(remainder.strip())) if remainder else 0
                cur_addr += 2 * nvalues
            elif fu == 'DD':
                nvalues = len(split_operands(remainder.strip())) if remainder else 0
                cur_addr += 4 * nvalues
            elif fu == 'DS':
                ds_m = re.match(r'\s*(\d+)', remainder) if remainder else None
                if ds_m:
                    cur_addr += int(ds_m.group(1))
            elif fu in ASL_INSTRUCTIONS or fu in KNOWN_MACROS:
                size = get_instruction_size_from_rom(cur_addr)
                if size:
                    if fu in KNOWN_MACROS and fu in MACRO_INSTR_COUNT:
                        total = 0
                        tmp_addr = cur_addr
                        for _ in range(MACRO_INSTR_COUNT[fu]):
                            s = get_instruction_size_from_rom(tmp_addr)
                            if s:
                                total += s
                                tmp_addr += s
                            else:
                                break
                        if total:
                            cur_addr += total
                    else:
                        cur_addr += size

    return addr_to_label, addr_to_label_all


def convert_all(main_file, output_path):
    """Convert the main ASL file + all includes into a single LLVM assembly file.

    Strategy: per-instruction byte extraction. Each instruction gets its own
    .byte line with exact ROM bytes, plus original ASL as comment. Data
    directives are converted to LLVM equivalents. Labels are emitted as real
    LLVM labels. This provides instruction-level granularity needed for
    progressive native instruction replacement (Phase 3).

    Label-only segments (forward references with no code/data between ORGs)
    are emitted as real .org + label directives for branch targets.
    """
    global ADDR_TRACKER, BLOCK_BUFFER, BLOCK_CURSOR, BLOCK_SIZE, BLOCK_START_ADDR
    global SEG_START_ADDR, SEG_END_ADDR, SELF_CORRECTION_TRIGGERED, SELF_CORRECTION_ADDR
    global NATIVE_INSTR_COUNT, BYTE_FALLBACK_COUNT, SET_ONLY_LABELS

    NATIVE_INSTR_COUNT = 0
    BYTE_FALLBACK_COUNT = 0
    SET_ONLY_LABELS = {}

    main_dir = os.path.dirname(main_file)

    print("  Reading all source files (inlining includes)...")
    all_lines = read_all_lines(main_file, main_dir)
    print(f"  Total source lines: {len(all_lines)}")

    # First pass: collect EQU definitions so we can resolve symbolic ORGs
    for line, source in all_lines:
        stripped = line.strip()
        code_part, _ = split_comment(stripped)
        code_stripped = code_part.strip()
        if not code_stripped:
            continue
        lbl, rest = extract_label(code_stripped)
        rest = rest.strip() if rest else ""
        if not rest and lbl:
            continue
        first, remainder = get_first_word(rest) if rest else ("", "")
        fu = first.upper()
        # label: EQU value
        if fu == 'EQU' and lbl:
            val_str = convert_expression(remainder.strip())
            try:
                KNOWN_EQUS[lbl] = eval_expr(val_str)
            except:
                pass
        # NAME EQU value (no colon)
        elif remainder.strip():
            m = re.match(r'^EQU\s+(.*)', remainder.strip(), re.IGNORECASE)
            if m:
                val_str = convert_expression(m.group(1).strip())
                try:
                    KNOWN_EQUS[first] = eval_expr(val_str)
                except:
                    pass

    # Collect all segments with their ORG addresses
    segments = []  # List of (org_addr, [(line, source_file), ...])
    current_org = None
    current_lines = []

    for line, source in all_lines:
        stripped = line.strip()
        code_part, _ = split_comment(stripped)
        code_stripped = code_part.strip()

        lbl, rest = extract_label(code_stripped)
        if not rest:
            rest = code_stripped if not lbl else ""
        first, remainder = get_first_word(rest) if rest else ("", "")

        if first.upper() == 'ORG':
            if current_lines:
                segments.append((current_org, current_lines))
            current_org = resolve_org_addr(remainder.strip())
            current_lines = [(line, source)]
        else:
            current_lines.append((line, source))

    if current_lines:
        segments.append((current_org, current_lines))

    # Classify segments: does a segment emit any bytes?
    DATA_KEYWORDS = {'DB', 'DW', 'DD', 'DS', 'BINCLUDE'}

    def segment_has_content(seg_lines):
        """Check if segment emits any bytes (instructions, data, macros)."""
        for line, _ in seg_lines:
            stripped = line.strip()
            code_part, _ = split_comment(stripped)
            code_stripped = code_part.strip()
            if not code_stripped:
                continue
            lbl, rest = extract_label(code_stripped)
            if not rest:
                rest = code_stripped if not lbl else ''
            first, _ = get_first_word(rest) if rest else ('', '')
            fu = first.upper()
            if fu in DATA_KEYWORDS or is_instruction(first) or is_macro_invocation(first):
                return True
        return False

    # Separate content segments (need .org) from label-only segments
    content_segs = []
    label_only_segs = []
    for org_addr, lines in segments:
        if org_addr is None or segment_has_content(lines):
            content_segs.append((org_addr, lines))
        else:
            label_only_segs.append((org_addr, lines))

    # Sort content segments by ORG address
    none_content = [(a, l) for a, l in content_segs if a is None]
    addr_content = [(a, l) for a, l in content_segs if a is not None]
    addr_content.sort(key=lambda x: x[0])
    sorted_content = none_content + addr_content

    print(f"  Segments: {len(segments)} total ({len(content_segs)} with content, {len(label_only_segs)} label-only)")

    # Build segment end addresses: each content segment ends where the next begins
    seg_end_map = {}
    for i, (addr, _) in enumerate(sorted_content):
        if addr is None:
            continue
        end_addr = ROM_BASE + ROM_SIZE
        for j in range(i + 1, len(sorted_content)):
            next_addr = sorted_content[j][0]
            if next_addr is not None:
                end_addr = next_addr
                break
        seg_end_map[addr] = end_addr

    # Collect label-only labels indexed by address for inline emission
    label_only_labels = {}  # addr -> [label_name, ...]
    for seg_addr, seg_lines in label_only_segs:
        if seg_addr is None:
            continue
        labels = []
        for line, source in seg_lines:
            stripped = line.strip()
            code_part, comment = split_comment(stripped)
            code_stripped = code_part.strip()
            if not code_stripped:
                continue
            lbl, rest = extract_label(code_stripped)
            if not rest:
                rest = code_stripped if not lbl else ''
            first, _ = get_first_word(rest) if rest else ('', '')
            if first.upper() == 'ORG':
                continue
            if lbl:
                labels.append(lbl)
            elif re.match(r'^[A-Za-z_]\w*$', code_stripped):
                labels.append(code_stripped)
        if labels:
            if seg_addr not in label_only_labels:
                label_only_labels[seg_addr] = []
            label_only_labels[seg_addr].extend(labels)

    # Build address → label maps:
    # ADDR_TO_LABEL: reliable addresses only (for JP/CALL symbolization)
    # ADDR_TO_LABEL_ALL: all labels with tracked addresses (for .long)
    global ADDR_TO_LABEL, ADDR_TO_LABEL_ALL
    print("  Building address-to-label map...")
    ADDR_TO_LABEL, ADDR_TO_LABEL_ALL = _build_addr_to_label_map(sorted_content, seg_end_map, label_only_labels)
    print(f"  Labels mapped: {len(ADDR_TO_LABEL)} (JP/CALL), {len(ADDR_TO_LABEL_ALL)} (all)")

    # Build output
    output_lines = []
    output_lines.append(f"; Converted from {main_file} by asl_to_llvm.py (Phase 3)")
    output_lines.append(f"; All includes inlined, segments globally sorted by ORG address.")
    output_lines.append(f"; Per-instruction .byte fallback with progressive native replacement.")
    output_lines.append(f"; This file is auto-generated. Edit the converter, not this file.")
    output_lines.append("")
    output_lines.append("\t.text")
    output_lines.append("")

    total_rom_bytes = 0
    total_padding_bytes = 0
    total_block_corrections = 0
    emitted_label_addrs = set()  # Track label-only labels emitted inline

    # Create a memoryview for zero-copy ROM slicing in start_block()
    rom_view = memoryview(ORIGINAL_ROM) if ORIGINAL_ROM is not None else None

    def start_block(addr, end_addr):
        """Initialize a new block buffer from ROM[addr:end_addr]."""
        global BLOCK_BUFFER, BLOCK_CURSOR, BLOCK_SIZE, BLOCK_START_ADDR
        block_size = end_addr - addr
        rom_offset = addr - ROM_BASE
        BLOCK_BUFFER = rom_view[rom_offset:rom_offset + block_size]
        BLOCK_CURSOR = 0
        BLOCK_SIZE = block_size
        BLOCK_START_ADDR = addr

    def flush_block_padding():
        """Emit remaining bytes in current block as padding."""
        global BLOCK_CURSOR
        nonlocal total_padding_bytes
        if BLOCK_BUFFER is not None and BLOCK_CURSOR < BLOCK_SIZE:
            pad_size = BLOCK_SIZE - BLOCK_CURSOR
            pad_start = BLOCK_START_ADDR + BLOCK_CURSOR
            for i in range(0, pad_size, 16):
                chunk = BLOCK_BUFFER[BLOCK_CURSOR + i:BLOCK_CURSOR + i + 16]
                byte_str = ', '.join(f'0x{b:02x}' for b in chunk)
                addr_comment = f"0x{pad_start + i:06X} (padding)"
                output_lines.append(f"\t.byte {byte_str}\t; {addr_comment}")
            total_padding_bytes += pad_size
            BLOCK_CURSOR = BLOCK_SIZE

    # Pre-scan function: extract address-encoding labels from segment lines.
    # These define block boundaries so instruction sizing errors can't cascade.
    def prescan_label_addrs(seg_lines):
        """Return sorted list of addresses from address-encoding labels."""
        addrs = []
        for line, source in seg_lines:
            stripped = line.rstrip()
            if not stripped:
                continue
            code_part, cmt = split_comment(stripped)
            code_stripped = code_part.rstrip()
            lbl, rest = extract_label(code_stripped)
            if not lbl:
                continue
            rest = rest.strip()
            if rest and re.match(r'^EQU\b', rest, re.IGNORECASE):
                continue
            m_lbl = re.match(r'^LABEL_([0-9A-Fa-f]{6})$', lbl)
            if m_lbl:
                addrs.append(int(m_lbl.group(1), 16))
            elif cmt:
                m_addr = re.match(r'^;\s*([0-9A-Fa-f]{6})\s*$', cmt.strip())
                if m_addr:
                    addrs.append(int(m_addr.group(1), 16))
        return sorted(set(addrs))

    # Helper: perform block transition at a boundary address.
    # Pads the gap from current block cursor to boundary, then starts a new block.
    def do_block_transition(boundary_addr):
        nonlocal total_block_corrections, total_padding_bytes
        total_block_corrections += 1
        expected_block_bytes = boundary_addr - BLOCK_START_ADDR
        gap = expected_block_bytes - BLOCK_CURSOR
        if gap > 0:
            gap_rom_offset = (BLOCK_START_ADDR + BLOCK_CURSOR) - ROM_BASE
            for i in range(0, gap, 16):
                chunk_size = min(16, gap - i)
                chunk = rom_view[gap_rom_offset + i:gap_rom_offset + i + chunk_size]
                byte_str = ', '.join(f'0x{b:02x}' for b in chunk)
                addr_comment = f"0x{BLOCK_START_ADDR + BLOCK_CURSOR + i:06X} (block padding)"
                output_lines.append(f"\t.byte {byte_str}\t; {addr_comment}")
            total_padding_bytes += gap
        elif gap < 0:
            output_lines.append(f"\t; WARNING: block over-emitted by {-gap} bytes before 0x{boundary_addr:06X}")
        if seg_end is not None and boundary_addr < seg_end:
            idx = bisect.bisect_right(seg_label_addrs, boundary_addr)
            next_end = seg_label_addrs[idx] if idx < len(seg_label_addrs) else seg_end
            start_block(boundary_addr, next_end)

    # Emit content segments — per-line conversion with block-level buffers.
    # A "block" spans between two consecutive address-encoding labels (or
    # segment start/end). Each block reads exact ROM bytes. Instruction sizing
    # errors are confined to a single inter-label span and corrected at each
    # label boundary via padding or clamping.
    for seg_addr, seg_lines in sorted_content:
        seg_end = None
        seg_label_addrs = []  # Pre-scanned label addresses for this segment
        if seg_addr is not None:
            # Reset address tracker at each segment boundary
            ADDR_TRACKER = AddressTracker()
            ADDR_TRACKER.set_org(seg_addr)
            SEG_START_ADDR = seg_addr

            if seg_addr in seg_end_map:
                seg_end = seg_end_map[seg_addr]
                SEG_END_ADDR = seg_end
                # Pre-scan for label addresses to define block boundaries
                seg_label_addrs = prescan_label_addrs(seg_lines)
                # Find first block end: next label after seg_addr, or seg_end
                idx = bisect.bisect_right(seg_label_addrs, seg_addr)
                first_end = seg_label_addrs[idx] if idx < len(seg_label_addrs) else seg_end
                start_block(seg_addr, first_end)
            else:
                BLOCK_BUFFER = None
                SEG_END_ADDR = ROM_BASE + ROM_SIZE
        else:
            BLOCK_BUFFER = None

        for line, source in seg_lines:
            # Reset self-correction flag before each line
            SELF_CORRECTION_TRIGGERED = False

            # Emit label-only labels when address tracker reaches their address.
            # These provide inline labels for readability. Position may have minor
            # drift between block boundaries, but .set at end provides the
            # authoritative address for JP/CALL and .long references.
            cur_addr = ADDR_TRACKER.get_addr()
            if cur_addr is not None and cur_addr in label_only_labels and cur_addr not in emitted_label_addrs:
                for lbl_name in label_only_labels[cur_addr]:
                    output_lines.append(f"{lbl_name}:")
                emitted_label_addrs.add(cur_addr)

            # Track whether block was exhausted before convert_line.
            # If so, data directives get 0 bytes and need re-conversion
            # after the block transition creates a fresh block.
            block_was_exhausted = (BLOCK_BUFFER is not None
                                   and BLOCK_CURSOR >= BLOCK_SIZE)

            converted = convert_line(line, source)

            # After convert_line, handle block transitions triggered by
            # self-correction at address-encoding labels.
            if (SELF_CORRECTION_TRIGGERED
                    and SELF_CORRECTION_ADDR != BLOCK_START_ADDR):
                do_block_transition(SELF_CORRECTION_ADDR)
                # If the block was exhausted BEFORE convert_line, data
                # directives on this line got 0 bytes (clamped to remaining=0).
                # Now that a fresh block exists, re-convert to get proper data.
                if block_was_exhausted and BLOCK_BUFFER is not None:
                    converted = convert_line(line, source)

            if converted is not None:
                output_lines.append(converted)

        # After processing all lines, pad remaining block bytes
        flush_block_padding()

        if seg_addr is not None and seg_addr in seg_end_map:
            total_rom_bytes += seg_end_map[seg_addr] - seg_addr

    # Clear block buffer
    BLOCK_BUFFER = None

    # Emit .set labels for those NOT emitted inline.
    # Inline labels get their address from assembled position (usually correct).
    # .set labels get exact addresses from ORG (always correct).
    all_set_labels = []
    # Label-only segments not emitted inline (forward references beyond conversion range)
    for addr in sorted(label_only_labels.keys()):
        if addr not in emitted_label_addrs:
            for lbl_name in label_only_labels[addr]:
                all_set_labels.append((addr, lbl_name))
    # Content-segment LABEL_XXXXXX on instruction lines (suppressed from inline)
    for lbl_name, addr in sorted(SET_ONLY_LABELS.items(), key=lambda x: x[1]):
        all_set_labels.append((addr, lbl_name))

    if all_set_labels:
        output_lines.append("")
        output_lines.append("; Labels emitted as .set (exact addresses from ORG/name)")
        for addr, lbl_name in all_set_labels:
            output_lines.append(f"\t.set {lbl_name}, 0x{addr:06X}")

    # Post-process: symbolize .long values.
    # Use ADDR_TO_LABEL_ALL (all labels with tracked addresses) for
    # address-based lookup, plus .set labels (exact addresses).
    # For comment-based symbolization ("; DD LABEL_NAME"), verify the
    # .long value matches the label's known address to avoid wrong
    # symbolizations from address drift in block buffer regions.
    long_label_map = {}
    for addr, lbl_name in all_set_labels:
        _record_label(long_label_map, addr, lbl_name)
    for addr, lbl_name in ADDR_TO_LABEL_ALL.items():
        if addr not in long_label_map:
            long_label_map[addr] = lbl_name

    # Build label_name -> address reverse map for comment-based verification
    label_to_addr = {}
    for addr, lbl_name in long_label_map.items():
        label_to_addr[lbl_name] = addr

    if long_label_map:
        long_re = re.compile(r'0x([0-9A-Fa-f]{8})')
        dd_label_re = re.compile(r'DD\s+(\w+)')
        symbolic_long_count = 0
        for i, line in enumerate(output_lines):
            if '\t.long ' not in line:
                continue
            # Split off any existing comment
            code_part, cmt_part = line.split('\t; ', 1) if '\t; ' in line else (line, '')
            new_code = code_part
            changed = False
            for m in long_re.finditer(code_part):
                val = int(m.group(1), 16)
                sym = long_label_map.get(val)
                if not sym and cmt_part:
                    # Try extracting label name from "; DD LABEL_NAME" comment.
                    # Verify the .long value matches the label's known address
                    # to avoid wrong symbolizations from block buffer drift.
                    dd_m = dd_label_re.search(cmt_part)
                    if dd_m:
                        dd_label = dd_m.group(1)
                        dd_addr = label_to_addr.get(dd_label)
                        if dd_addr is not None and dd_addr == val:
                            sym = dd_label
                if sym:
                    new_code = new_code.replace(m.group(0), sym, 1)
                    changed = True
            if changed:
                output_lines[i] = new_code  # Drop comment when symbolic
                symbolic_long_count += 1
        print(f"  Symbolic .long replacements: {symbolic_long_count}")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        f.write('\n'.join(output_lines) + '\n')

    # Print statistics
    print(f"  Output: {output_path}")
    print(f"  ROM bytes covered: {total_rom_bytes} / {ROM_SIZE} ({100*total_rom_bytes/ROM_SIZE:.1f}%)")
    print(f"  .byte fallback lines: {BYTE_FALLBACK_COUNT}")
    print(f"  Padding bytes: {total_padding_bytes}")
    print(f"  Block corrections: {total_block_corrections}")
    print(f"  Native instruction lines: {NATIVE_INSTR_COUNT}")
    n_label_only_set = len(all_set_labels) - len(SET_ONLY_LABELS)
    print(f"  Label-only labels: {len(emitted_label_addrs)} inline + {n_label_only_set} .set")
    print(f"  Content LABEL_XXXXXX as .set: {len(SET_ONLY_LABELS)}")


# ============================================================================
# Main
# ============================================================================

def main():
    if len(sys.argv) < 2:
        print("Usage: python scripts/asl_to_llvm.py maincpu/kn5000_v10_program.asm")
        sys.exit(1)

    main_file = sys.argv[1]
    main_dir = os.path.dirname(main_file)

    print(f"ASL-to-LLVM converter (Phase 3)")
    print(f"Input: {main_file}")
    print(f"Output: {LLVM_DIR}/kn5000_v10_program.s")
    print()

    # Load original ROM
    print("Loading original ROM...")
    load_original_rom()
    print()

    # Step 1: Convert macro library (still separate — needed for macro name detection)
    macro_input = os.path.normpath(os.path.join(main_dir, '..', 'tmp94c241.inc'))
    if not os.path.exists(macro_input):
        macro_input = 'tmp94c241.inc'
    macro_output = os.path.join(str(LLVM_DIR), 'tmp94c241.inc.s')

    print("Step 1: Converting macro library...")
    convert_macro_file(macro_input, macro_output)
    print()

    # Step 2: Convert main file + all includes into single output
    print("Step 2: Converting all source files...")
    main_output = os.path.join(str(LLVM_DIR), 'kn5000_v10_program.s')
    convert_all(main_file, main_output)
    print()

    print("Conversion complete.")


if __name__ == '__main__':
    main()
