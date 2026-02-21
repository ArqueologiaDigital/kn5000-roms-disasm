#!/usr/bin/env python3
"""
ASL-to-LLVM Assembly Converter for KN5000 ROM disassembly.

Converts ASL (Alfred Arnold's Macro Assembler) assembly files to LLVM
assembly syntax for the TLCS-900 target. Processes the main assembly file
and all its includes, producing parallel .s files under maincpu/llvm/.

Strategy: All CPU instructions are emitted as .byte sequences from the
original ROM binary, preserving the original ASL syntax as comments.
Data directives (db, dw, dd, binclude) and labels are converted to LLVM
equivalents. This ensures 100% byte-match with the original ROM.

Phase 2 will progressively replace .byte with native LLVM instructions.

Usage:
    python scripts/asl_to_llvm.py maincpu/kn5000_v10_program.asm
"""

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

# Pending .org corrections from self-correction at labels
PENDING_ORG_CORRECTIONS = []

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

    # Self-correct address tracker at labels with known addresses.
    # Labels like LABEL_XXXXXX encode their address in the name.
    # This resets ADDR_TRACKER to eliminate cumulative drift from sizing errors.
    # Only affects which ROM bytes are read — does NOT affect assembler position.
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
            if expected_addr != actual_addr:
                ADDR_TRACKER.set_org(expected_addr)

    # Label-only line
    if not rest:
        result = f"{label}:" if label else ""
        if comment:
            result += f"\t{comment}" if label else comment
        return result

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
            result = f"{label}:\n"
        result += f"\t.org {addr_str} - 0xE00000, 0xFF"
        if comment:
            result += f"\t{comment}"
        return result

    # MACRO definition: "NAME MACRO [args]"
    if re.match(r'^MACRO(?:\s|$)', remainder.strip(), re.IGNORECASE):
        IN_MACRO_DEF += 1
        ADDR_TRACKER.freeze()
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
        return convert_db(label, remainder.strip(), comment, in_file_path)

    if first_upper == 'DW':
        return convert_dw(label, remainder.strip(), comment)

    if first_upper == 'DD':
        args_raw = remainder.strip()
        nvalues = len(split_operands(args_raw))
        nbytes = 4 * nvalues
        addr = ADDR_TRACKER.get_addr()

        # If dd references labels, emit raw bytes from ROM
        if _dw_has_label_refs(args_raw) and addr is not None:
            rom_bytes = get_rom_bytes(addr, nbytes)
            if rom_bytes is not None:
                result = ""
                if label:
                    result = f"{label}:\n"
                byte_str = ', '.join(f'0x{b:02x}' for b in rom_bytes)
                original = f"DD {args_raw}"
                result += f"\t.byte {byte_str}\t; {original}"
                ADDR_TRACKER.advance(nbytes)
                if comment:
                    result += f"\t{comment}"
                return result

        values = convert_expression(args_raw)
        result = ""
        if label:
            result = f"{label}:\n"
        result += f"\t.long {values}"
        if comment:
            result += f"\t{comment}"
        ADDR_TRACKER.advance(nbytes)
        return result

    if first_upper == 'DS':
        values = convert_expression(remainder.strip())
        result = ""
        if label:
            result = f"{label}:\n"
        result += f"\t.space {values}"
        if comment:
            result += f"\t{comment}"
        try:
            nbytes = eval_expr(values)
            ADDR_TRACKER.advance(nbytes)
        except:
            pass
        return result

    if first_upper == 'BINCLUDE':
        path_str = remainder.strip().strip('"').strip("'")
        result = ""
        if label:
            result = f"{label}:\n"
        # Path relative to maincpu/ → relative to maincpu/llvm/ is ../
        llvm_path = f"../{path_str}"
        result += f'\t.incbin "{llvm_path}"'
        if comment:
            result += f"\t{comment}"
        # Advance by file size
        bin_path = os.path.join('maincpu', path_str)
        if os.path.exists(bin_path):
            ADDR_TRACKER.advance(os.path.getsize(bin_path))
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
            result = f"{label}:\n"

        if addr is not None and nbytes is not None:
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
        return convert_instruction(label, first_word, remainder.strip(), comment)

    # ---- Unknown / fallthrough ----
    # If no operands and word looks like a label (starts with letter,
    # not a known directive), treat as a label without colon (ASL syntax)
    if not remainder.strip() and re.match(r'^[A-Za-z_]\w*$', first_word):
        result = ""
        if label:
            result = f"{label}:\n"
        result += f"{first_word}:"
        if comment:
            result += f"\t{comment}"
        return result

    # Otherwise preserve as-is (may cause assembler error)
    result = ""
    if label:
        result = f"{label}:\n"
    converted_rest = convert_expression(rest)
    result += f"\t{converted_rest}"
    if comment:
        result += f"\t{comment}"
    return result


def convert_instruction(label, mnemonic, operands_str, comment):
    """Convert a CPU instruction to .byte fallback with original ASL as comment."""
    result = ""
    if label:
        result = f"{label}:\n"

    addr = ADDR_TRACKER.get_addr()
    nbytes = get_instruction_size_from_rom(addr) if addr is not None else None

    if addr is not None and nbytes is not None:
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


def convert_db(label, args, comment, in_file_path):
    """Convert db directive - handle strings, bytes, and dup patterns."""
    result = ""
    if label:
        result = f"{label}:\n"

    # Track bytes for address advancement
    nbytes = _count_db_bytes(args)

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


def convert_dw(label, args, comment):
    """Convert dw to .short, falling back to ROM bytes for label references."""
    result = ""
    if label:
        result = f"{label}:\n"

    nvalues = len(split_operands(args))
    nbytes = 2 * nvalues
    addr = ADDR_TRACKER.get_addr()

    # If dw references labels, emit raw bytes from ROM instead
    if _dw_has_label_refs(args) and addr is not None:
        rom_bytes = get_rom_bytes(addr, nbytes)
        if rom_bytes is not None:
            byte_str = ', '.join(f'0x{b:02x}' for b in rom_bytes)
            original = f"DW {args}"
            result += f"\t.byte {byte_str}\t; {original}"
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


def convert_all(main_file, output_path):
    """Convert the main ASL file + all includes into a single LLVM assembly file.

    Strategy: segment-level ROM byte extraction. For each content segment
    between ORG addresses, ALL bytes are extracted directly from the original
    ROM binary and emitted as .byte directives. The original ASL source is
    preserved as comments for readability. This guarantees byte-identical
    output by bypassing line-by-line address tracking entirely.

    Label-only segments (forward references with no code/data) are emitted
    as comments at the end.
    """
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
    # (or at ROM end for the last segment)
    seg_end_map = {}  # seg_start_addr -> end_addr
    for i, (addr, _) in enumerate(sorted_content):
        if addr is None:
            continue
        # Find next segment with a valid address
        end_addr = ROM_BASE + ROM_SIZE  # default: end of ROM
        for j in range(i + 1, len(sorted_content)):
            next_addr = sorted_content[j][0]
            if next_addr is not None:
                end_addr = next_addr
                break
        seg_end_map[addr] = end_addr

    # Build output
    output_lines = []
    output_lines.append(f"; Converted from {main_file} by asl_to_llvm.py (Phase 2)")
    output_lines.append(f"; All includes inlined, segments globally sorted by ORG address.")
    output_lines.append(f"; Bytes extracted directly from original ROM — guaranteed byte-identical.")
    output_lines.append(f"; This file is auto-generated. Edit the converter, not this file.")
    output_lines.append("")
    output_lines.append("\t.text")
    output_lines.append("")

    total_rom_bytes = 0

    # Emit content segments
    for seg_addr, seg_lines in sorted_content:
        if seg_addr is not None and seg_addr in seg_end_map:
            # Segment-level ROM byte extraction
            end_addr = seg_end_map[seg_addr]
            seg_size = end_addr - seg_addr

            # Emit .org
            output_lines.append(f"\t.org 0x{seg_addr:X} - 0x{ROM_BASE:X}, 0xFF")
            output_lines.append("")

            # Emit ASL source as comments
            for line, source in seg_lines:
                stripped = line.rstrip()
                if stripped:
                    output_lines.append(f";\t{stripped}")

            output_lines.append("")

            # Emit ROM bytes in 16-byte chunks
            rom_offset = seg_addr - ROM_BASE
            for chunk_start in range(0, seg_size, 16):
                chunk_end = min(chunk_start + 16, seg_size)
                chunk = ORIGINAL_ROM[rom_offset + chunk_start:rom_offset + chunk_end]
                byte_str = ', '.join(f'0x{b:02x}' for b in chunk)
                addr_comment = f"0x{seg_addr + chunk_start:06X}"
                output_lines.append(f"\t.byte {byte_str}\t; {addr_comment}")

            output_lines.append("")
            total_rom_bytes += seg_size
        else:
            # No address (preamble) or unknown — convert line by line
            for line, source in seg_lines:
                converted = convert_line(line, source)
                if converted is not None:
                    output_lines.append(converted)

    # Emit label-only segments as comments
    if label_only_segs:
        output_lines.append("")
        output_lines.append("; Label-only forward references (no .org needed)")
        for seg_addr, seg_lines in label_only_segs:
            for line, source in seg_lines:
                stripped = line.strip()
                code_part, comment = split_comment(stripped)
                code_stripped = code_part.strip()
                if not code_stripped:
                    continue
                lbl, rest = extract_label(code_stripped)
                if not rest:
                    rest = code_stripped if not lbl else ''
                first, remainder = get_first_word(rest) if rest else ('', '')
                if first.upper() == 'ORG':
                    continue
                if lbl:
                    if seg_addr:
                        output_lines.append(f"; {lbl}: (0x{seg_addr:06X})")
                    else:
                        output_lines.append(f"; {lbl}:")
                elif re.match(r'^[A-Za-z_]\w*$', code_stripped):
                    if seg_addr:
                        output_lines.append(f"; {code_stripped}: (0x{seg_addr:06X})")
                    else:
                        output_lines.append(f"; {code_stripped}:")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        f.write('\n'.join(output_lines) + '\n')

    print(f"  Output: {output_path}")
    print(f"  ROM bytes emitted: {total_rom_bytes} / {ROM_SIZE} ({100*total_rom_bytes/ROM_SIZE:.1f}%)")


# ============================================================================
# Main
# ============================================================================

def main():
    if len(sys.argv) < 2:
        print("Usage: python scripts/asl_to_llvm.py maincpu/kn5000_v10_program.asm")
        sys.exit(1)

    main_file = sys.argv[1]
    main_dir = os.path.dirname(main_file)

    print(f"ASL-to-LLVM converter (Phase 2)")
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
