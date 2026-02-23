#!/usr/bin/env python3
"""
ASL-to-LLVM Assembly Converter for KN5000 ROM disassembly.

Converts ASL (Alfred Arnold's Macro Assembler) assembly files to LLVM
assembly syntax for the TLCS-900 target. Processes the main assembly file
and all its includes, producing parallel .s files under the output directory.

Strategy: Each CPU instruction is emitted as a .byte sequence from the
original ROM binary, preserving the original ASL syntax as a comment.
Data directives (db, dw, dd, binclude) and labels are converted to LLVM
equivalents. Native LLVM instructions progressively replace .byte
fallbacks where the LLVM backend supports them.

Usage:
    python scripts/asl_to_llvm.py <input.asm> [--rom-base 0xE00000] [--rom-size 0x200000] \\
        [--rom-file original_ROMs/foo.rom] [--output-dir maincpu]
"""

import argparse
import os
import re
import sys
from pathlib import Path


# ============================================================================
# Configuration
# ============================================================================

BASE_DIR = Path(".")
LLVM_DIR = BASE_DIR / "maincpu"  # Default; overridden by --output-dir
ROM_BASE = 0xE00000  # Default; overridden by --rom-base
ROM_SIZE = 0x200000  # Default; overridden by --rom-size

# Input source directory (for resolving binclude paths)
INPUT_DIR = ""  # Set in main() from input file path

# Original ROM for byte extraction
ORIGINAL_ROM = None  # Loaded on demand

# Set of known macro names
KNOWN_MACROS = set()

# Known EQU values (for resolving symbol addresses in ORG and data directives)
KNOWN_EQUS = {}

# Address → label name mapping for symbolic references in JP/CALL
ADDR_TO_LABEL = {}
ADDR_TO_LABEL_ALL = {}

# Synthetic forward labels needed by JR T $+2 (delay NOP) conversion.
# Maps target address → label name. Emitted in convert_all() before the next instruction.
SYNTHETIC_FORWARD_LABELS = {}  # addr -> label_name

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

# EQU names promoted to inline labels (suppressed from .equ emission).
# Populated during convert_all() after label maps are built.
EQU_INLINE_LABELS = set()

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

# Local label qualification: ASL local labels (.name) are scoped to the
# preceding global label. LLVM assembly has file-global labels, so we
# prefix local labels with the parent global label to avoid conflicts.
CURRENT_PARENT_LABEL = ""  # Most recent global label name


def load_original_rom(rom_path=None):
    """Load the original ROM binary for byte extraction."""
    global ORIGINAL_ROM
    if rom_path is None:
        rom_path = BASE_DIR / "original_ROMs" / "kn5000_v10_program.rom"
    else:
        rom_path = Path(rom_path)
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
    """Extract label from beginning of code line (NAME: or .name: pattern).

    Returns (label, rest) where label includes ASL local labels (.name).
    For local labels, the leading dot is preserved in the returned name.
    """
    # Match global label (word chars) or local label (.word chars)
    m = re.match(r'^(\.?\w+):\s*(.*)', code)
    if m:
        return m.group(1), m.group(2)
    return None, code


def qualify_local_label(name):
    """Qualify an ASL local label (.name) with the current parent label.

    Returns the qualified name (e.g., 'DSP_Select_Chip__done' for '.done'
    under parent 'DSP_Select_Chip'). Non-local labels are returned as-is.
    """
    if name and name.startswith('.'):
        return f"{CURRENT_PARENT_LABEL}__{name[1:]}" if CURRENT_PARENT_LABEL else name[1:]
    return name


def qualify_local_refs(text):
    """Replace ASL local label references (.name) in operand text with qualified names.

    Only qualifies references that look like ASL local labels (lowercase .name
    patterns used in branch targets), NOT file extensions, LLVM directives, etc.
    """
    # Don't process text inside quoted strings (binclude paths, etc.)
    if '"' in text or "'" in text:
        return text
    def _qualify(m):
        name = m.group(0)
        # Skip if preceded by a word character (e.g., file.ext)
        start = m.start()
        if start > 0 and text[start - 1].isalnum():
            return name
        # Skip LLVM/ASL directives and common file extensions
        if name.lower() in {'.byte', '.org', '.text', '.set', '.long', '.short',
                            '.incbin', '.if', '.else', '.endif', '.endm', '.macro',
                            '.zero', '.fill', '.align', '.section', '.globl',
                            '.type', '.size', '.equ', '.space', '.comm',
                            '.asciz', '.ascii', '.word', '.hword', '.quad',
                            '.bin', '.rom', '.dat', '.bmp', '.ssf', '.asm',
                            '.inc', '.p', '.s', '.o', '.elf', '.ld'}:
            return name
        return qualify_local_label(name)
    return re.sub(r'\.\w+', _qualify, text)


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
        """Return current address, or None if frozen (inside macro def)."""
        if self.frozen:
            return None
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
# Segment-level tracking for the overall segment
SEG_START_ADDR = 0     # start address of segment
SEG_END_ADDR = 0       # end address of segment (next segment start)

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

# REPT depth: when > 0, we're inside an ASL rept/endm block.
# The corresponding ENDM should become .endr instead of .endm.
IN_REPT = 0


def _mb(*lines):
    """Build multi-line string by joining lines with newlines."""
    return '\n'.join(lines)


# Hand-crafted LLVM macro bodies for inline-defined ASL macros.
# Keyed by uppercase macro name. When a macro is in this dict, the converter:
# 1. Emits this body at the definition site (instead of converting ASL body lines)
# 2. Emits macro calls at invocation sites (instead of inline expansion)
# Uses .if/.else/.endif for encoding-dependent instructions (lds vs ldw, etc.)
LLVM_MACRO_BODIES = {
    # --- Leaf VGA macros ---
    'VGA_WRITE': _mb(
        ".macro VGA_WRITE regnum, value",
        "\t.if \\regnum <= 7",
        "\tlds wa, \\regnum",
        "\t.else",
        "\tldw wa, \\regnum",
        "\t.endif",
        "\t.if \\value <= 7",
        "\tlds bc, \\value",
        "\t.else",
        "\tldw bc, \\value",
        "\t.endif",
        "\tcalr Write_VGA_Register",
        ".endm",
    ),
    '_VGA_WRITE': _mb(
        ".macro _VGA_WRITE regnum, value",
        "\t.if \\regnum <= 7",
        "\tlds wa, \\regnum",
        "\t.else",
        "\tldw wa, \\regnum",
        "\t.endif",
        "\t.if \\value <= 7",
        "\tlds bc, \\value",
        "\t.else",
        "\tldw bc, \\value",
        "\t.endif",
        "\tcalr _Write_VGA_Register",
        ".endm",
    ),
    '_VGA_READ': _mb(
        ".macro _VGA_READ regnum",
        "\t.if \\regnum <= 7",
        "\tlds wa, \\regnum",
        "\t.else",
        "\tldw wa, \\regnum",
        "\t.endif",
        "\tcalr _Read_VGA_Register",
        ".endm",
    ),
    'RET_VGA_WRITE': _mb(
        ".macro RET_VGA_WRITE regnum, value",
        "\t.if \\regnum <= 7",
        "\tlds wa, \\regnum",
        "\t.else",
        "\tldw wa, \\regnum",
        "\t.endif",
        "\t.if \\value <= 7",
        "\tlds bc, \\value",
        "\t.else",
        "\tldw bc, \\value",
        "\t.endif",
        "\tjrl t, Write_VGA_Register",
        ".endm",
    ),
    # --- Compound VGA macros (call leaf macros) ---
    'VGA_SEQUENCER': _mb(
        ".macro VGA_SEQUENCER field, value",
        "\tVGA_WRITE 0x3C4, \\field",
        "\tVGA_WRITE 0x3C5, \\value",
        ".endm",
    ),
    'VGA_GFX_CONTROLLER': _mb(
        ".macro VGA_GFX_CONTROLLER field, value",
        "\tVGA_WRITE 0x3CE, \\field",
        "\tVGA_WRITE 0x3CF, \\value",
        ".endm",
    ),
    'VGA_COLOR_CRTC': _mb(
        ".macro VGA_COLOR_CRTC field, value",
        "\tVGA_WRITE 0x3D4, \\field",
        "\tVGA_WRITE 0x3D5, \\value",
        ".endm",
    ),
    'VGA_ATTRIBUTE': _mb(
        ".macro VGA_ATTRIBUTE field, value",
        "\tVGA_WRITE 0x3C0, \\field",
        "\tVGA_WRITE 0x3C0, \\value",
        ".endm",
    ),
    'RET_VGA_SEQUENCER': _mb(
        ".macro RET_VGA_SEQUENCER field, value",
        "\tVGA_WRITE 0x3C4, \\field",
        "\tRET_VGA_WRITE 0x3C5, \\value",
        ".endm",
    ),
    '_VGA_SEQUENCER': _mb(
        ".macro _VGA_SEQUENCER field, value",
        "\t_VGA_WRITE 0x3C4, \\field",
        "\t_VGA_WRITE 0x3C5, \\value",
        ".endm",
    ),
    '_VGA_GFX_CONTROLLER': _mb(
        ".macro _VGA_GFX_CONTROLLER field, value",
        "\t_VGA_WRITE 0x3CE, \\field",
        "\t_VGA_WRITE 0x3CF, \\value",
        ".endm",
    ),
    '_VGA_COLOR_CRTC': _mb(
        ".macro _VGA_COLOR_CRTC field, value",
        "\t_VGA_WRITE 0x3D4, \\field",
        "\t_VGA_WRITE 0x3D5, \\value",
        ".endm",
    ),
    '_VGA_ATTRIBUTE': _mb(
        ".macro _VGA_ATTRIBUTE field, value",
        "\t_VGA_WRITE 0x3C0, \\field",
        "\t_VGA_WRITE 0x3C0, \\value",
        ".endm",
    ),
    # --- Palette macro (0 invocations, defined for ASL fidelity) ---
    '_PALLETE_WRITE': _mb(
        ".macro _PALLETE_WRITE red, green, blue",
        "\tldw wa, 0x3C9",
        "\t.if \\red <= 7",
        "\tlds bc, \\red",
        "\t.else",
        "\tldw bc, \\red",
        "\t.endif",
        "\tcalr _Write_VGA_Register",
        "\t.if \\green <= 7",
        "\tlds bc, \\green",
        "\t.else",
        "\tldw bc, \\green",
        "\t.endif",
        "\tcalr _Write_VGA_Register",
        "\t.if \\blue <= 7",
        "\tlds bc, \\blue",
        "\t.else",
        "\tldw bc, \\blue",
        "\t.endif",
        "\tcalr _Write_VGA_Register",
        ".endm",
    ),
    # --- Reg* macros ---
    'REGOBJTABLE': _mb(
        ".macro RegObjTable ParamA, ParamB, ParamC, ParamD, ParamE",
        "\tmrid2 0xB7, 0x31",
        "\t.if \\ParamA <= 7",
        "\tlds32 xwa, \\ParamA",
        "\t.else",
        "\tld xwa, \\ParamA",
        "\t.endif",
        "\tld (xbc), xwa",
        "\tldada_24 xwa, \\ParamB",
        "\tld (xbc + 4), xwa",
        "\tldda16_24 xwa, \\ParamC",
        "\tld (xbc + 8), wa",
        "\tldada_24 xwa, \\ParamD",
        "\tld (xbc + 10), xwa",
        "\t.if \\ParamE <= 7",
        "\tlds wa, \\ParamE",
        "\t.else",
        "\tldw wa, \\ParamE",
        "\t.endif",
        "\tcall RegisterObjectTable",
        ".endm",
    ),
    'REGOBJTABL': _mb(
        ".macro RegObjTabl ParamA, ParamB, ParamC, ParamD, ParamE",
        "\tmrid2 0xB7, 0x31",
        "\t.if \\ParamA <= 7",
        "\tlds32 xwa, \\ParamA",
        "\t.else",
        "\tld xwa, \\ParamA",
        "\t.endif",
        "\tld (xbc), xwa",
        "\tldada_24 xwa, \\ParamB",
        "\tld (xbc + 4), xwa",
        "\tldmw (xbc + 8), \\ParamC",
        "\tldada_24 xwa, \\ParamD",
        "\tld (xbc + 10), xwa",
        "\t.if \\ParamE <= 7",
        "\tlds wa, \\ParamE",
        "\t.else",
        "\tldw wa, \\ParamE",
        "\t.endif",
        "\tcall RegisterObjectTable",
        ".endm",
    ),
    'REGOBJTABLEHAMA': _mb(
        ".macro RegObjTableHama ParamA, ParamB, ParamC, ParamD, ParamE",
        "\t.if \\ParamA <= 7",
        "\tlds32 xwa, \\ParamA",
        "\t.else",
        "\tld xwa, \\ParamA",
        "\t.endif",
        "\tld (xsp + 256), xwa",
        "\tldada_24 xwa, \\ParamB",
        "\tld (xsp + 4), xwa",
        "\tldda16_24 xwa, \\ParamC",
        "\tld (xsp + 8), wa",
        "\tldada_24 xwa, \\ParamD",
        "\tld (xsp + 10), xwa",
        "\tmrid2 0xB7, 0x30",
        "\tld xbc, xwa",
        "\t.if \\ParamE <= 7",
        "\tlds wa, \\ParamE",
        "\t.else",
        "\tldw wa, \\ParamE",
        "\t.endif",
        "\tcall RegisterObjectTable",
        ".endm",
    ),
    'REGOBJTABLHAMA': _mb(
        ".macro RegObjTablHama ParamA, ParamB, ParamC, ParamD, ParamE",
        "\t.if \\ParamA <= 7",
        "\tlds32 xwa, \\ParamA",
        "\t.else",
        "\tld xwa, \\ParamA",
        "\t.endif",
        "\tld (xsp + 256), xwa",
        "\tldada_24 xwa, \\ParamB",
        "\tld (xsp + 4), xwa",
        "\tldmw (xsp + 8), \\ParamC",
        "\tldada_24 xwa, \\ParamD",
        "\tld (xsp + 10), xwa",
        "\tmrid2 0xB7, 0x30",
        "\tld xbc, xwa",
        "\t.if \\ParamE <= 7",
        "\tlds wa, \\ParamE",
        "\t.else",
        "\tldw wa, \\ParamE",
        "\t.endif",
        "\tcall RegisterObjectTable",
        ".endm",
    ),
    'REGMODE': _mb(
        ".macro RegMode ParamA, ParamBhi, ParamBlow, ParamC, ParamD, ParamE",
        "\tpushw \\ParamA",
        "\tpushw \\ParamBhi",
        "\tpushw \\ParamBlow",
        "\t.if \\ParamC <= 7",
        "\tlds32 xwa, \\ParamC",
        "\t.else",
        "\tld xwa, \\ParamC",
        "\t.endif",
        "\t.if \\ParamD <= 7",
        "\tlds32 xbc, \\ParamD",
        "\t.else",
        "\tld xbc, \\ParamD",
        "\t.endif",
        "\t.if \\ParamE <= 7",
        "\tlds32 xde, \\ParamE",
        "\t.else",
        "\tld xde, \\ParamE",
        "\t.endif",
        "\tcall RegisterMode",
        ".endm",
    ),
    'REGTITLE': _mb(
        ".macro RegTitle ParamA, ParamBhi, ParamBlow, ParamC, ParamD, ParamE",
        "\tpushw \\ParamA",
        "\tpushw \\ParamBhi",
        "\tpushw \\ParamBlow",
        "\t.if \\ParamC <= 7",
        "\tlds32 xwa, \\ParamC",
        "\t.else",
        "\tld xwa, \\ParamC",
        "\t.endif",
        "\t.if \\ParamD <= 7",
        "\tlds32 xbc, \\ParamD",
        "\t.else",
        "\tld xbc, \\ParamD",
        "\t.endif",
        "\t.if \\ParamE <= 7",
        "\tlds32 xde, \\ParamE",
        "\t.else",
        "\tld xde, \\ParamE",
        "\t.endif",
        "\tcall RegisterTitle",
        ".endm",
    ),
    'REGTITLEHAMA': _mb(
        ".macro RegTitleHama ParamA, ParamB, ParamC, ParamD, ParamE",
        "\tpushw \\ParamA",
        "\tldada_24 xwa, \\ParamB",
        "\tpush xwa",
        "\t.if \\ParamC <= 7",
        "\tlds32 xwa, \\ParamC",
        "\t.else",
        "\tld xwa, \\ParamC",
        "\t.endif",
        "\t.if \\ParamD <= 7",
        "\tlds32 xbc, \\ParamD",
        "\t.else",
        "\tld xbc, \\ParamD",
        "\t.endif",
        "\t.if \\ParamE <= 7",
        "\tlds32 xde, \\ParamE",
        "\t.else",
        "\tld xde, \\ParamE",
        "\t.endif",
        "\tcall RegisterTitle",
        ".endm",
    ),
}


# Conditional assembly state: tracks IF/ELSE/ENDIF
# IF conditions are evaluated using KNOWN_EQUS values (0 = false)
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

def compute_llvm_include_path(include_path, from_file=None):
    """Compute the .include path for LLVM output.

    Converts ASL include paths to LLVM-style paths:
    - ../shared/vga_constants.asm → shared/vga_constants.s
    - fdc_constants.asm → fdc_constants.s
    - file_io/title_handlers.asm → file_io/title_handlers.s
    """
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


def split_output_into_includes(output_lines, output_dir):
    """Split monolithic output at include boundaries into separate files.

    Scans output_lines for '; --- begin include: ...' / '; --- end include: ...'
    markers. Extracts content between them to separate .s files, replacing the
    inlined section with a .include directive.

    Returns the modified output_lines list.
    """
    result = []
    include_stack = []  # Stack of (include_path, lines_buffer)
    include_files_written = []

    for line in output_lines:
        # Check for include begin marker
        m = re.match(r'^; --- begin include: (.+) ---$', line)
        if m:
            inc_path = m.group(1)
            include_stack.append((inc_path, []))
            continue

        # Check for include end marker
        m = re.match(r'^; --- end include: (.+) ---$', line)
        if m:
            if include_stack:
                inc_path, inc_lines = include_stack.pop()
                llvm_path = compute_llvm_include_path(inc_path)
                full_path = os.path.join(output_dir, llvm_path)

                # Write include file
                os.makedirs(os.path.dirname(full_path), exist_ok=True)
                with open(full_path, 'w') as f:
                    f.write('\n'.join(inc_lines) + '\n')
                include_files_written.append(llvm_path)

                # Add .include directive to parent (or top-level result)
                directive = f'\t.include "{llvm_path}"'
                if include_stack:
                    include_stack[-1][1].append(directive)
                else:
                    result.append(directive)
            continue

        # Append line to current include buffer or top-level result
        if include_stack:
            include_stack[-1][1].append(line)
        else:
            result.append(line)

    if include_files_written:
        print(f"  Include files written: {len(include_files_written)}")
    return result


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
                # Evaluate condition using KNOWN_EQUS (0 = false)
                cond_name = test_remainder.strip()
                cond_val = KNOWN_EQUS.get(cond_name, 0)
                COND_STATE['depth'] = 1
                COND_STATE['active'] = bool(cond_val)
                COND_STATE['seen_else'] = False
                return f"\t; IF {cond_name} (evaluated to {'true' if cond_val else 'false'})"
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

    # Track parent label for local label qualification.
    # A global label (not starting with '.') becomes the new parent scope.
    global CURRENT_PARENT_LABEL
    if label and not label.startswith('.'):
        CURRENT_PARENT_LABEL = label
    # Qualify local labels (starting with '.') to avoid file-scope conflicts
    if label and label.startswith('.'):
        label = qualify_local_label(label)

    # Reset address tracker at labels with known addresses.
    # Labels like LABEL_XXXXXX encode their address in the name.
    # Skip labels that are EQU definitions (they alias other names, not addresses).
    is_equ_line = rest and re.match(r'^EQU\b', rest.strip(), re.IGNORECASE)
    if label and not is_equ_line:
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
                ADDR_TRACKER.set_org(expected_addr)

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

    # EQU → .equ (suppressed for names promoted to inline labels)
    if first_upper == 'EQU':
        value = convert_expression(remainder.strip())
        # Track the value for address resolution
        try:
            KNOWN_EQUS[label] = eval_expr(value)
        except:
            pass
        if label in EQU_INLINE_LABELS:
            return f"\t; (EQU→inline label) {label} = {value}"
        result = f".equ {label}, {value}"
        if comment:
            result += f"\t{comment}"
        return result

    # NAME EQU value (no colon on NAME)
    if re.match(r'^EQU(?:\s|$)', remainder.strip(), re.IGNORECASE):
        equ_match = re.match(r'EQU\s+(.*)', remainder.strip(), re.IGNORECASE)
        if equ_match:
            value = convert_expression(equ_match.group(1).strip())
            name = first_word
            try:
                KNOWN_EQUS[name] = eval_expr(value)
            except:
                pass
            if name in EQU_INLINE_LABELS:
                return f"\t; (EQU→inline label) {name} = {value}"
            result = f".equ {name}, {value}"
            if comment:
                result += f"\t{comment}"
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
        result += f"\t.org {addr_str} - 0x{ROM_BASE:X}, 0xFF"
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
        # Hand-crafted LLVM body for known macros
        if macro_name.upper() in LLVM_MACRO_BODIES:
            return LLVM_MACRO_BODIES[macro_name.upper()]
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
            is_known_endm = (IN_MACRO_DEF == 1 and CURRENT_MACRO_DEF_NAME
                             and CURRENT_MACRO_DEF_NAME in LLVM_MACRO_BODIES)
            if IN_MACRO_DEF == 1 and CURRENT_MACRO_DEF_NAME:
                MACRO_INSTR_COUNT[CURRENT_MACRO_DEF_NAME] = CURRENT_MACRO_INSTR_COUNT
                CURRENT_MACRO_DEF_NAME = None
            IN_MACRO_DEF -= 1
            if IN_MACRO_DEF == 0:
                ADDR_TRACKER.unfreeze()
                if is_known_endm:
                    return ""
        return ".endm"

    # Count instructions/macros in macro body for expansion size tracking
    if IN_MACRO_DEF > 0 and IN_MACRO_DEF == 1:
        if is_instruction(first_word):
            CURRENT_MACRO_INSTR_COUNT += 1
        elif is_macro_invocation(first_word):
            # Nested macro: add its leaf instruction count
            nested_count = MACRO_INSTR_COUNT.get(first_word.upper(), 1)
            CURRENT_MACRO_INSTR_COUNT += nested_count

    # Suppress body lines for known macros (hand-crafted body already emitted)
    if (IN_MACRO_DEF > 0 and CURRENT_MACRO_DEF_NAME
            and CURRENT_MACRO_DEF_NAME in LLVM_MACRO_BODIES):
        return ""

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

        # When ROM is available and args reference labels, emit from ROM
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
        # Determine fill byte from original ROM content (ASL ds reserves space;
        # p2bin fills uninitialized space with 0xFF)
        fill_byte = 0xFF  # Default: flash ROM erased state
        try:
            nbytes = eval_expr(values)
            addr = ADDR_TRACKER.get_addr()
            if addr is not None and ORIGINAL_ROM is not None:
                rom_offset = addr - ROM_BASE
                if 0 <= rom_offset < len(ORIGINAL_ROM):
                    end = min(rom_offset + nbytes, len(ORIGINAL_ROM))
                    region = ORIGINAL_ROM[rom_offset:end]
                    if region and all(b == 0x00 for b in region):
                        fill_byte = 0x00
                    elif region and all(b == 0xFF for b in region):
                        fill_byte = 0xFF
        except:
            nbytes = None
        result += f"\t.space {values}, 0x{fill_byte:02X}"
        if comment:
            result += f"\t{comment}"
        if nbytes is not None:
            ADDR_TRACKER.advance(nbytes)
        return result

    if first_upper == 'BINCLUDE':
        path_str = remainder.strip().strip('"').strip("'")
        bin_path = os.path.join(INPUT_DIR, path_str) if INPUT_DIR else path_str
        if not os.path.exists(bin_path) and LLVM_DIR:
            bin_path = os.path.join(str(LLVM_DIR), path_str)
        fsize = os.path.getsize(bin_path) if os.path.exists(bin_path) else 0
        result = ""
        if label:
            result = f"{label}:{label_addr_suffix}\n"
        llvm_path = path_str
        result += f'\t.incbin "{llvm_path}"'
        if comment:
            result += f"\t{comment}"
        if fsize > 0:
            ADDR_TRACKER.advance(fsize)
        return result

    # ---- Macro invocations ----
    if is_macro_invocation(first_word):
        # Emit as .byte fallback from ROM.
        # Inline macros may expand to multiple instructions — decode the right count.
        addr = ADDR_TRACKER.get_addr()
        instr_count = MACRO_INSTR_COUNT.get(first_word.upper(), 1)
        # db-only macros (like PUSH_WORD) have instr_count=0 because their
        # body contains only db directives.  Treat them as single-instruction.
        if instr_count == 0:
            instr_count = 1

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

        if first_word.upper() in LLVM_MACRO_BODIES:
            args = remainder.strip()
            if args:
                arg_list = split_operands(args)
                converted_args = [convert_expression(a) for a in arg_list]
                # Resolve LABEL_XXXXXX references to numeric addresses.
                # ExtAddrMode instructions (ldada_24, ldda16_24) inside
                # macro bodies don't support symbol relocations.
                for i, ca in enumerate(converted_args):
                    m = re.match(r'^LABEL_([0-9A-Fa-f]+)$', ca)
                    if m:
                        converted_args[i] = '0x' + m.group(1)
                args_str = ', '.join(converted_args)
                result += f"\t{first_word} {args_str}"
            else:
                result += f"\t{first_word}"
            NATIVE_INSTR_COUNT += instr_count
            if nbytes is not None:
                ADDR_TRACKER.advance(nbytes)
            if comment:
                result += f"\t{comment}"
            return result

        if addr is not None and nbytes is not None:
            rom_bytes = get_rom_bytes(addr, nbytes)
            if rom_bytes is not None:
                if instr_count == 1:
                    # Single-instruction macro: try native conversion
                    native = try_convert_native(first_word, remainder.strip(), rom_bytes, nbytes, addr)
                    # If macro name isn't a known mnemonic, try opcode-based guessing
                    if native is None:
                        for mnem in guess_mnemonics_from_opcode(rom_bytes[0]):
                            native = try_convert_native(mnem, '', rom_bytes, nbytes, addr)
                            if native is not None:
                                break
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
                else:
                    # Multi-instruction macro: split and convert each sub-instruction
                    args = remainder.strip()
                    original = f"{first_word} {args}".strip() if args else first_word
                    result += f"\t; {original}"
                    cur_offset = 0
                    cur_addr = addr
                    for i in range(instr_count):
                        if cur_offset >= nbytes:
                            break
                        sz = get_instruction_size_from_rom(cur_addr)
                        if sz is None or cur_offset + sz > nbytes:
                            # Can't decode — emit remaining bytes as .byte
                            rem = rom_bytes[cur_offset:]
                            byte_str = ', '.join(f'0x{b:02x}' for b in rem)
                            result += f"\n\t.byte {byte_str}"
                            BYTE_FALLBACK_COUNT += 1
                            break
                        sub_bytes = bytes(rom_bytes[cur_offset:cur_offset + sz])
                        # Try native conversion with guessed mnemonics
                        converted = False
                        for mnem in guess_mnemonics_from_opcode(sub_bytes[0]):
                            native = try_convert_native(mnem, '', sub_bytes, sz, cur_addr)
                            if native is not None:
                                native_asm, _ = native
                                result += f"\n\t{native_asm}"
                                NATIVE_INSTR_COUNT += 1
                                converted = True
                                break
                        if not converted:
                            byte_str = ', '.join(f'0x{b:02x}' for b in sub_bytes)
                            result += f"\n\t.byte {byte_str}"
                            BYTE_FALLBACK_COUNT += 1
                        cur_offset += sz
                        cur_addr += sz
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
        operands = remainder.strip()
        # Qualify local label references in operands (e.g., .done → Parent__done)
        if operands and '.' in operands:
            operands = qualify_local_refs(operands)
        return convert_instruction(label, first_word, operands, comment, label_addr_suffix)

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


def guess_mnemonics_from_opcode(first_byte):
    """Return candidate ASL mnemonics for an instruction based on its first opcode byte.
    Used when converting individual instructions within macro expansions where the
    original ASL mnemonic is unknown."""
    b = first_byte
    if b == 0x00: return ['NOP']
    if b == 0x06: return ['EI']
    if b == 0x07: return ['RETI']
    if b == 0x08: return ['LD']
    if b in (0x09, 0x0A): return ['LDW']
    if b == 0x0B: return ['PUSHW']
    if b == 0x0E: return ['RET']
    if b == 0x0F: return ['RETD']
    if b == 0x16: return ['EX']
    if b == 0x1B: return ['JP']
    if b == 0x1D: return ['CALL']
    if b == 0x1E: return ['CALR']
    if 0x20 <= b <= 0x27: return ['LD']
    if 0x28 <= b <= 0x2F: return ['PUSH']
    if 0x30 <= b <= 0x37: return ['LDW']
    if 0x38 <= b <= 0x3F: return ['PUSH']
    if 0x40 <= b <= 0x47: return ['LD']
    if 0x48 <= b <= 0x4F: return ['POP']
    if 0x58 <= b <= 0x5F: return ['POP']
    if 0x60 <= b <= 0x6F: return ['JR']
    if 0x70 <= b <= 0x7F: return ['JRL']
    if 0x80 <= b <= 0xBF:
        return ['LD', 'LDW', 'LDA', 'ADD', 'ADC', 'SUB', 'SBC',
                'AND', 'OR', 'XOR', 'CP', 'INC', 'INCW', 'DEC', 'DECW',
                'PUSHW', 'BIT', 'SET', 'RES', 'LDCF', 'STCF', 'CALL', 'JP']
    if 0xC0 <= b <= 0xFF:
        return ['LD', 'LDW', 'ADD', 'ADC', 'SUB', 'SBC', 'AND', 'OR', 'XOR', 'CP',
                'NEG', 'CPL', 'EXTS', 'EXTZ', 'INC', 'INCW', 'DEC', 'DECW',
                'SLA', 'SRA', 'SRL', 'RLC', 'RRC', 'RL', 'RR',
                'SET', 'RES', 'BIT', 'CHG', 'TSET',
                'PUSH', 'POP', 'SCC', 'DJNZ', 'MUL', 'MULS', 'DIV', 'DIVS',
                'EX', 'UNLK', 'XORCF', 'STCF', 'LDC']
    return ['LD', 'NOP']


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

    # Tier 1b: SWI (software interrupt) — 1-byte: 0xF8+imm3
    if nbytes == 1 and rom_bytes is not None and mnem_upper == 'SWI':
        if rom_bytes[0] >= 0xF8:
            imm3 = rom_bytes[0] - 0xF8
            return f"swi {imm3}", 1

    # Tier 2: 32-bit register immediate loads (5-byte form only)
    if mnem_upper in ('LD', 'LDW') and nbytes == 5:
        if operands_str:
            parts = operands_str.split(',', 1)
            if len(parts) == 2:
                reg = parts[0].strip().upper()
                imm_str = parts[1].strip()
                if reg in NATIVE_LD_32BIT_REGS:
                    imm_val = parse_asl_immediate(imm_str)
                    # Fallback: extract immediate from ROM bytes (0x40+r, imm32_LE)
                    if imm_val is None and rom_bytes is not None and 0x40 <= rom_bytes[0] <= 0x47:
                        imm_val = (rom_bytes[1] | (rom_bytes[2] << 8) |
                                   (rom_bytes[3] << 16) | (rom_bytes[4] << 24))
                    if imm_val is not None:
                        native_asm = f"ld {reg.lower()}, 0x{imm_val:X}"
                        return native_asm, 5
        # ROM-bytes-only fallback for macro-split instructions (no operands_str)
        if rom_bytes is not None and 0x40 <= rom_bytes[0] <= 0x47:
            r_idx = rom_bytes[0] - 0x40
            reg = REG32_BY_INDEX.get(r_idx)
            if reg:
                imm_val = (rom_bytes[1] | (rom_bytes[2] << 8) |
                           (rom_bytes[3] << 16) | (rom_bytes[4] << 24))
                return f"ld {reg}, 0x{imm_val:X}", 5

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
    # ROM-bytes-only fallback for 1-byte PUSH/POP and other single-byte opcodes
    if nbytes == 1 and rom_bytes is not None and not operands_str:
        b = rom_bytes[0]
        if 0x28 <= b <= 0x2E and mnem_upper == 'PUSH':
            r_idx = b - 0x28
            reg = REG16_BY_INDEX.get(r_idx)
            if reg:
                return f"pushw {reg}", 1
        elif 0x38 <= b <= 0x3E and mnem_upper == 'PUSH':
            r_idx = b - 0x38
            reg = REG32_BY_INDEX.get(r_idx)
            if reg:
                return f"push {reg}", 1
        elif 0x48 <= b <= 0x4E and mnem_upper == 'POP':
            r_idx = b - 0x48
            reg = REG16_BY_INDEX.get(r_idx)
            if reg:
                return f"popw {reg}", 1
        elif 0x58 <= b <= 0x5E and mnem_upper == 'POP':
            r_idx = b - 0x58
            reg = REG32_BY_INDEX.get(r_idx)
            if reg:
                return f"pop {reg}", 1
        elif b == 0x02 and mnem_upper == 'PUSH': return "push_sr", 1
        elif b == 0x03 and mnem_upper == 'POP': return "pop_sr", 1
        elif b == 0x14 and mnem_upper == 'PUSH': return "push_a", 1
        elif b == 0x15 and mnem_upper == 'POP': return "pop_a", 1
        elif b == 0x18 and mnem_upper == 'PUSH': return "push_f", 1
        elif b == 0x19 and mnem_upper == 'POP': return "pop_f", 1
        elif b == 0x16 and mnem_upper == 'EX': return "ex_ff", 1
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
    # Use ADDR_TO_LABEL (reliable) first, then ADDR_TO_LABEL_ALL (all tracked labels).
    if nbytes == 2 and rom_bytes is not None and addr is not None:
        opcode = rom_bytes[0]
        if 0x60 <= opcode <= 0x6F and mnem_upper == 'JR':
            cc = opcode & 0x0F
            d8 = rom_bytes[1]
            if d8 > 127:
                d8 -= 256  # sign-extend
            target = addr + 2 + d8
            # Special case: d8==0 means JR T, $+2 (delay NOP — jump to next instruction).
            # No label exists at target. Create a synthetic forward label.
            if d8 == 0 and cc == 8:
                synth_label = f"__jrt_nop_{target:06X}"
                SYNTHETIC_FORWARD_LABELS[target] = synth_label
                return f"jr {synth_label}", 2
            label = ADDR_TO_LABEL.get(target)
            if not label:
                label = ADDR_TO_LABEL_ALL.get(target)
            if label:
                ll = label.lower()
                if ll not in RESERVED_LABEL_NAMES:
                    if cc == 8:  # T (always/unconditional)
                        return f"jr {label}", 2
                    else:
                        return f"jr {TLCS900_CC_NAMES[cc]}, {label}", 2
            else:
                # Fallback: if operands reference a label (local or named),
                # use it directly — the label should exist in the LLVM output
                # and the assembler will compute the correct offset.
                # Byte-match verification catches any drift issues.
                if operands_str:
                    parts = operands_str.split(',')
                    if len(parts) >= 2:
                        target_part = parts[-1].strip()
                        # Only use operand if it's a proper label name
                        if re.match(r'^[A-Za-z_]\w*$', target_part) or \
                           re.match(r'^\.\w+$', target_part):
                            if cc == 8:
                                return f"jr {target_part}", 2
                            else:
                                return f"jr {TLCS900_CC_NAMES[cc]}, {target_part}", 2

    # Tier 9: JRL/JRLcc (3-byte relative jump: 0x70+cc, d16_LE)
    # Also matches ASL cc-suffixed mnemonics like JRL_T, JRL_Z, etc.
    _is_jrl_mnem = mnem_upper in ('JRL', 'JP') or mnem_upper.startswith('JRL_')
    if nbytes == 3 and rom_bytes is not None and addr is not None:
        opcode = rom_bytes[0]
        if 0x70 <= opcode <= 0x7F and _is_jrl_mnem:
            cc = opcode & 0x0F
            d16 = rom_bytes[1] | (rom_bytes[2] << 8)
            if d16 > 32767:
                d16 -= 65536  # sign-extend
            target = addr + 3 + d16
            label = ADDR_TO_LABEL.get(target)
            if not label:
                label = ADDR_TO_LABEL_ALL.get(target)
            if label:
                ll = label.lower()
                if ll not in RESERVED_LABEL_NAMES:
                    if cc == 8:  # T (unconditional)
                        return f"jrl {label}", 3
                    else:
                        return f"jrl {TLCS900_CC_NAMES[cc]}, {label}", 3
            else:
                # Fallback: use operand label directly if available.
                if operands_str:
                    parts = operands_str.split(',')
                    # For cc-suffixed mnemonics (JRL_T label), operand is single (no comma)
                    target_part = parts[-1].strip() if len(parts) >= 2 else operands_str.strip()
                    target_part = convert_expression(target_part)  # ASL→LLVM hex notation
                    if re.match(r'^[A-Za-z_]\w*(\s*[+\-]\s*(0x[\da-fA-F]+|\d+))?$', target_part) or \
                       re.match(r'^\.\w+$', target_part):
                        if cc == 8:
                            return f"jrl {target_part}", 3
                        else:
                            return f"jrl {TLCS900_CC_NAMES[cc]}, {target_part}", 3

    # Tier 10: CALR (3-byte relative call: 0x1E, d16_LE)
    if nbytes == 3 and rom_bytes is not None and addr is not None:
        if rom_bytes[0] == 0x1E and mnem_upper in ('CALR', 'CALL'):
            d16 = rom_bytes[1] | (rom_bytes[2] << 8)
            if d16 > 32767:
                d16 -= 65536
            target = addr + 3 + d16
            label = ADDR_TO_LABEL.get(target)
            if not label:
                label = ADDR_TO_LABEL_ALL.get(target)
            if label:
                ll = label.lower()
                if ll not in RESERVED_LABEL_NAMES:
                    return f"calr {label}", 3
            else:
                # Fallback: use operand label if it exists in assembly output.
                if operands_str:
                    target_part = operands_str.strip()
                    if re.match(r'^[A-Za-z_]\w*$', target_part):
                        return f"calr {target_part}", 3

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
                label = ADDR_TO_LABEL_ALL.get(target)
            if label:
                ll = label.lower()
                if ll in RESERVED_LABEL_NAMES:
                    label = None
            if label:
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
                    mem_str = None
                    if has_disp:
                        d8 = disp_byte
                        if d8 > 127:
                            d8 -= 256  # sign-extend
                        if d8 < 0:
                            mem_str = f"({base_name} - {-d8})"
                        elif d8 > 0:
                            mem_str = f"({base_name} + {d8})"
                        else:
                            mem_str = f"({base_name} + 256)"  # Force d8=0 encoding
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
                            mem_str = f"({base_name} + 256)"  # Force d8=0 encoding
                    else:
                        mem_str = f"({base_name})"
                    # LD (mem), r8 — sub-opcode 0x40+r
                    if 0x40 <= sub_opc_byte <= 0x47:
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

    # Tier 23: PUSH/PUSHW immediate — 3-byte: 0x0B, imm16_LE
    if nbytes == 3 and rom_bytes is not None and mnem_upper in ('PUSH', 'PUSHW'):
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
                        # Build memory operand string
                        mem_str = None
                        if has_disp:
                            d8 = rom_bytes[1]
                            if d8 > 127:
                                d8 -= 256
                            if d8 < 0:
                                mem_str = f"({base_name} - {-d8})"
                            elif d8 > 0:
                                mem_str = f"({base_name} + {d8})"
                            else:
                                mem_str = f"({base_name} + 256)"  # Force d8=0 encoding
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
        if 0xB0 <= prefix <= 0xBF and nbytes >= 3:
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
                            else:
                                mem_str = f"({base_name} + 256)"  # Force d8=0 encoding
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
                            else:
                                mem_str = f"({base_name} + 256)"  # Force d8=0 encoding
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
                count = sub_opc - base_opc
                if count == 0:
                    count = 8
                reg_name = REG32_BY_INDEX.get(r_idx)
                if reg_name:
                    mnem = 'incm8' if is_inc else 'decm8'
                    if d8 == 0:
                        return f"{mnem} {count}, ({reg_name} + 256)", 3  # Force d8=0
                    else:
                        disp = d8 if d8 <= 127 else d8 - 256
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
                count = sub_opc - base_opc
                if count == 0:
                    count = 8
                reg_name = REG32_BY_INDEX.get(r_idx)
                if reg_name:
                    mnem = 'incm' if is_inc else 'decm'
                    if d8 == 0:
                        return f"{mnem} {count}, ({reg_name} + 256)", 3  # Force d8=0
                    else:
                        disp = d8 if d8 <= 127 else d8 - 256
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
                            else:
                                mem_str = f"({base_name} + 256)"  # Force d8=0 encoding
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
                reg_name = REG32_BY_INDEX.get(r_idx)
                if reg_name:
                    if d8 == 0:
                        return f"pushm ({reg_name} + 256)", 3  # Force d8=0
                    else:
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

    # Tier 39: Block transfer variants (non-standard prefix bytes)
    # Standard LDI/LDIR/LDD/LDDR use 0x80 prefix (handled by existing _SIMPLE_LENGTHS).
    # ROM uses variant prefixes (0x85, 0x83, 0x93, 0x95) that need separate instructions.
    BLOCK_TRANSFER_MNEMONICS = {
        'LDIRW_95', 'LDIW', 'LDIR', 'LDI', 'LDDR', 'LDDR_85',
        'LDIR_83', 'LDIRW_93', 'CPIR',
    }
    if nbytes == 2 and rom_bytes is not None and mnem_upper in BLOCK_TRANSFER_MNEMONICS:
        prefix = rom_bytes[0]
        sub_opc = rom_bytes[1]
        # Map (prefix, sub_opc) to LLVM instruction mnemonic
        BLOCK_XFER_MAP = {
            (0x85, 0x10): 'ldi85',
            (0x85, 0x11): 'ldir85',
            (0x85, 0x13): 'lddr85',
            (0x83, 0x11): 'ldir83',
            (0x83, 0x13): 'lddr83',
            (0x83, 0x15): 'cpir83',
            (0x95, 0x10): 'ldiw',
            (0x95, 0x11): 'ldirw',
            (0x93, 0x11): 'ldirw93',
        }
        native_mnem = BLOCK_XFER_MAP.get((prefix, sub_opc))
        if native_mnem:
            return native_mnem, 2

    # Tier 40: F2 conditional CALL (5-byte: F2 + addr24_LE + 0xE0+cc)
    if nbytes == 5 and rom_bytes is not None and mnem_upper == 'CALL':
        if rom_bytes[0] == 0xF2:
            sub_opc = rom_bytes[4]
            if 0xE0 <= sub_opc <= 0xEF:
                addr24 = rom_bytes[1] | (rom_bytes[2] << 8) | (rom_bytes[3] << 16)
                cc = sub_opc & 0x0F
                return f"callcc_24 {cc}, 0x{addr24:X}", 5

    # Tier 41: F2 conditional JP (5-byte: F2 + addr24_LE + 0xD0+cc)
    if nbytes == 5 and rom_bytes is not None and mnem_upper == 'JP':
        if rom_bytes[0] == 0xF2:
            sub_opc = rom_bytes[4]
            if 0xD0 <= sub_opc <= 0xDF:
                addr24 = rom_bytes[1] | (rom_bytes[2] << 8) | (rom_bytes[3] << 16)
                cc = sub_opc & 0x0F
                return f"jpcc_24 {cc}, 0x{addr24:X}", 5

    # Tier 42: LD (n), #n — I/O register write (3-byte: 0x08 + addr8 + imm8)
    if nbytes == 3 and rom_bytes is not None and mnem_upper == 'LD':
        if rom_bytes[0] == 0x08:
            addr8 = rom_bytes[1]
            imm8 = rom_bytes[2]
            return f"ldio 0x{addr8:02X}, 0x{imm8:02X}", 3

    # Tier 42b: LDW (n), #nn — I/O register word write (4-byte: 0x0A + addr8 + imm16)
    if nbytes == 4 and rom_bytes is not None and mnem_upper == 'LDW':
        if rom_bytes[0] == 0x0A:
            addr8 = rom_bytes[1]
            imm16 = rom_bytes[2] | (rom_bytes[3] << 8)
            return f"ldwio 0x{addr8:02X}, 0x{imm16:04X}", 4

    # Tier 43: Extended addressing mode instructions — categorized prefix patterns.
    # Classifies prefix bytes into semantic categories with computed prefix:
    #   Source addressing (C/D/E prefix, size=8/16/32):
    #     sd8 (C0/D0/E0): 8-bit direct address
    #     sd16 (C1/D1/E1): 16-bit direct address
    #     sd24 (C2/D2/E2): 24-bit direct address
    #     sri (C3/D3/E3): register-indirect complex
    #     spd (C4/D4/E4): pre-decrement
    #     spi (C5/D5/E5): post-increment
    #     erp (C7/D7/E7): extended register prefix — bank register access
    #   Destination addressing (F prefix, size-independent):
    #     dd8 (F0): 8-bit direct address
    #     dd16 (F1): 16-bit direct address
    #     dd24 (F2): 24-bit direct address
    #     dri (F3): register-indirect complex
    #     dpd (F4): pre-decrement
    #     dpi (F5): post-increment
    #   Memory addressing (80-BF, register-indirect):
    #     mri (80-87/90-97/A0-A7): no displacement
    #     mrd (88-8F/98-9F/A8-AF): with d8 displacement
    #     mdi (B0-B7): destination no displacement
    #     mdd (B8-BF): destination with d8 displacement
    if rom_bytes is not None and 2 <= nbytes <= 10:
        first = rom_bytes[0]
        if first >= 0x80:
            # Determine category from prefix byte
            low_nibble = first & 0x0F
            hi_nibble = first >> 4
            operand_bytes = rom_bytes[1:nbytes]
            nop = nbytes - 1  # operand byte count (excluding prefix)

            # Source addressing categories (C/D/E prefix, low nibble selects mode)
            if hi_nibble in (0xC, 0xD, 0xE) and low_nibble <= 7:
                size_char = {0xC: 'b', 0xD: 'w', 0xE: 'l'}[hi_nibble]

                # For sri (C3/D3/E3): try to extract LD sub-opcode
                # C3 sub-addressing mode byte bits 1-0:
                #   0: (r32) = 1 addr byte, 1: (r32+d16) = 3 addr bytes,
                #   3: special (0x03=r32+r8, 0x07=r32+r16, 0x13=PC+d16) = 3 addr bytes
                if low_nibble == 3 and nop >= 2:
                    addr_mode = operand_bytes[0]
                    mode_type = addr_mode & 0x03
                    if mode_type == 0:
                        addr_len = 1  # (r32) — just register, no displacement
                    elif mode_type in (1, 3):
                        addr_len = 3  # (r32+d16), (r32+r8), (r32+r16), (PC+d16)
                    else:
                        addr_len = 0  # unknown mode type 2
                    # Check if sub-opcode after addr bytes is LD (0x20-0x27)
                    if addr_len > 0 and nop == addr_len + 1:
                        sub_opc = operand_bytes[addr_len]
                        if 0x20 <= sub_opc <= 0x27:
                            REG_NAMES_8 = {0x20:'w', 0x21:'a', 0x22:'b', 0x23:'c',
                                           0x24:'d', 0x25:'e', 0x26:'h', 0x27:'l'}
                            REG_NAMES_16 = {0x20:'wa', 0x21:'bc', 0x22:'de', 0x23:'hl',
                                            0x24:'ix', 0x25:'iy', 0x26:'iz', 0x27:'sp'}
                            REG_NAMES_32 = {0x20:'xwa', 0x21:'xbc', 0x22:'xde', 0x23:'xhl',
                                            0x24:'xix', 0x25:'xiy', 0x26:'xiz', 0x27:'xsp'}
                            reg_table = {0xC: REG_NAMES_8, 0xD: REG_NAMES_16, 0xE: REG_NAMES_32}
                            reg_name = reg_table[hi_nibble].get(sub_opc, '')
                            if reg_name:
                                addr_bytes = operand_bytes[:addr_len]
                                byte_args = ', '.join(f'0x{b:02X}' for b in addr_bytes)
                                return f"ld_{reg_name}_sri{size_char}{addr_len} {byte_args}", nbytes

                # For spi/spd (C5/D5/E5 and C4/D4/E4): extract sub-opcode
                if low_nibble in (4, 5) and nop == 2:
                    reg_idx = operand_bytes[0]
                    sub_opc = operand_bytes[1]
                    cat_name = 'spi' if low_nibble == 5 else 'spd'
                    SPI_SPD_MAP = {
                        ('spi','b',0x21):'ld_a_spib', ('spi','b',0x23):'ld_c_spib',
                        ('spi','b',0x25):'ld_e_spib', ('spi','b',0x27):'ld_l_spib',
                        ('spi','b',0x83):'add_c_spib', ('spi','b',0x85):'add_e_spib',
                        ('spi','b',0xF1):'cp_a_spib',
                        ('spi','w',0x20):'ld_wa_spiw', ('spi','w',0x21):'ld_bc_spiw',
                        ('spi','w',0x22):'ld_de_spiw', ('spi','w',0x26):'ld_iz_spiw',
                        ('spi','w',0x81):'add_bc_spiw', ('spi','w',0x82):'add_de_spiw',
                        ('spi','w',0x83):'add_hl_spiw', ('spi','w',0xF2):'cp_de_spiw',
                        ('spi','w',0xF9):'cpm_bc_spiw',
                        ('spi','l',0x20):'ld_xwa_spil', ('spi','l',0x21):'ld_xbc_spil',
                        ('spi','l',0x23):'ld_xhl_spil', ('spi','l',0x83):'add_xhl_spil',
                        ('spd','b',0xF1):'cp_a_spdb',
                    }
                    mnem = SPI_SPD_MAP.get((cat_name, size_char, sub_opc))
                    if mnem:
                        return f"{mnem} 0x{reg_idx:02X}", nbytes

                # For erp (C7/D7/E7): extract sub-opcode for known operations
                # Format: [reg_idx, sub_opc] — nop==2 means trail=0 (sub_opc is last byte)
                if low_nibble == 7 and nop == 2:
                    reg_idx = operand_bytes[0]
                    sub_opc = operand_bytes[1]
                    # ERP suffix mapping: (size_char, sub_opc) → mnemonic
                    ERP_SUFFIX_MAP = {
                        ('b', 0x2A): 'xorcf_a_berp', ('b', 0x61): 'inc1_berp', ('b', 0x69): 'dec1_berp',
                        ('b', 0x81): 'add_a_berp', ('b', 0x83): 'add_c_berp',
                        ('b', 0x88): 'ldto_w_berp', ('b', 0x89): 'ldto_a_berp', ('b', 0x8A): 'ldto_b_berp',
                        ('b', 0x8B): 'ldto_c_berp', ('b', 0x8D): 'ldto_e_berp', ('b', 0x8F): 'ldto_l_berp',
                        ('b', 0x98): 'ldfr_w_berp', ('b', 0x99): 'ldfr_a_berp', ('b', 0x9B): 'ldfr_c_berp',
                        ('b', 0x9C): 'ldfr_d_berp', ('b', 0x9D): 'ldfr_e_berp', ('b', 0x9E): 'ldfr_h_berp',
                        ('b', 0x9F): 'ldfr_l_berp', ('b', 0xA1): 'sub_a_berp', ('b', 0xA3): 'sub_c_berp',
                        ('b', 0xA8): 'ldi0_berp', ('b', 0xA9): 'ldi1_berp', ('b', 0xAA): 'ldi2_berp',
                        ('b', 0xAB): 'ldi3_berp', ('b', 0xAC): 'ldi4_berp', ('b', 0xAD): 'ldi5_berp',
                        ('b', 0xAE): 'ldi6_berp', ('b', 0xAF): 'ldi7_berp', ('b', 0xC1): 'and_a_berp',
                        ('b', 0xD8): 'cpi0_berp', ('b', 0xD9): 'cpi1_berp', ('b', 0xDA): 'cpi2_berp',
                        ('b', 0xDB): 'cpi3_berp', ('b', 0xDC): 'cpi4_berp', ('b', 0xDD): 'cpi5_berp',
                        ('b', 0xDE): 'cpi6_berp', ('b', 0xDF): 'cpi7_berp',
                        ('b', 0xE0): 'or_w_berp', ('b', 0xE1): 'or_a_berp', ('b', 0xE3): 'or_c_berp',
                        ('b', 0xF1): 'cp_a_berp', ('b', 0xF3): 'cp_c_berp', ('b', 0xF7): 'cp_l_berp',
                        ('b', 0xFE): 'sll_a_berp',
                        ('w', 0x04): 'push_werp', ('w', 0x05): 'pop_werp', ('w', 0x06): 'cpl_werp',
                        ('w', 0x2A): 'xorcf_a_werp', ('w', 0x2C): 'stcf_a_werp',
                        ('w', 0x40): 'mul_xwa_werp', ('w', 0x41): 'mul_xbc_werp',
                        ('w', 0x61): 'inc1_werp', ('w', 0x64): 'inc4_werp', ('w', 0x69): 'dec1_werp',
                        ('w', 0x80): 'add_wa_werp', ('w', 0x81): 'add_bc_werp',
                        ('w', 0x88): 'ldto_wa_werp', ('w', 0x89): 'ldto_bc_werp',
                        ('w', 0x8A): 'ldto_de_werp', ('w', 0x8B): 'ldto_hl_werp',
                        ('w', 0x8C): 'ldto_ix_werp', ('w', 0x8D): 'ldto_iy_werp',
                        ('w', 0x8E): 'ldto_iz_werp', ('w', 0x98): 'ldfr_wa_werp',
                        ('w', 0x99): 'ldfr_bc_werp', ('w', 0x9A): 'ldfr_de_werp',
                        ('w', 0x9B): 'ldfr_hl_werp', ('w', 0x9D): 'ldfr_iy_werp',
                        ('w', 0x9E): 'ldfr_iz_werp', ('w', 0xA0): 'sub_wa_werp',
                        ('w', 0xA1): 'sub_bc_werp', ('w', 0xA2): 'sub_de_werp',
                        ('w', 0xA8): 'ldi0_werp', ('w', 0xA9): 'ldi1_werp', ('w', 0xAA): 'ldi2_werp',
                        ('w', 0xAB): 'ldi3_werp', ('w', 0xAC): 'ldi4_werp', ('w', 0xAE): 'ldi6_werp',
                        ('w', 0xAF): 'ldi7_werp', ('w', 0xB8): 'ex_wa_werp', ('w', 0xBE): 'ex_iz_werp',
                        ('w', 0xC0): 'and_wa_werp', ('w', 0xC2): 'and_de_werp',
                        ('w', 0xD8): 'cpi0_werp', ('w', 0xD9): 'cpi1_werp', ('w', 0xDB): 'cpi3_werp',
                        ('w', 0xDC): 'cpi4_werp', ('w', 0xDE): 'cpi6_werp', ('w', 0xDF): 'cpi7_werp',
                        ('w', 0xE0): 'or_wa_werp', ('w', 0xF0): 'cp_wa_werp', ('w', 0xF1): 'cp_bc_werp',
                        ('w', 0xF3): 'cp_hl_werp', ('w', 0xF6): 'cp_iz_werp', ('w', 0xFC): 'sla_a_werp',
                        ('l', 0x04): 'push_lerp', ('l', 0x05): 'pop_lerp', ('l', 0x64): 'inc4_lerp',
                        ('l', 0x88): 'ldto_xwa_lerp', ('l', 0x8B): 'ldto_xhl_lerp',
                        ('l', 0x8C): 'ldto_xix_lerp', ('l', 0x8D): 'ldto_xiy_lerp',
                        ('l', 0x8E): 'ldto_xiz_lerp', ('l', 0x98): 'ldfr_xwa_lerp',
                        ('l', 0x99): 'ldfr_xbc_lerp', ('l', 0x9B): 'ldfr_xhl_lerp',
                        ('l', 0x9C): 'ldfr_xix_lerp', ('l', 0x9D): 'ldfr_xiy_lerp',
                        ('l', 0x9E): 'ldfr_xiz_lerp',
                    }
                    mnem = ERP_SUFFIX_MAP.get((size_char, sub_opc))
                    if mnem:
                        return f"{mnem} 0x{reg_idx:02X}", nbytes

                # Map low nibble to category mnemonic
                CATEGORY_MAP = {
                    0: 'sd8',   # 8-bit direct address
                    1: 'sd16',  # 16-bit direct address
                    2: 'sd24',  # 24-bit direct address
                    3: 'sri',   # register-indirect complex
                    4: 'spd',   # pre-decrement
                    5: 'spi',   # post-increment
                    7: 'erp',   # extended register prefix
                }
                cat = CATEGORY_MAP.get(low_nibble)
                if cat and 1 <= nop <= 8:
                    byte_args = ', '.join(f'0x{b:02X}' for b in operand_bytes)
                    return f"{cat}{size_char}{nop} {byte_args}", nbytes

            # Destination addressing categories (F prefix)
            if hi_nibble == 0xF and low_nibble <= 5:
                # For dri (F3): try to extract LD/LDA sub-opcode
                if low_nibble == 3 and nop >= 2:
                    addr_mode = operand_bytes[0]
                    mode_type = addr_mode & 0x03
                    if mode_type == 0:
                        addr_len = 1
                    elif mode_type in (1, 3):
                        addr_len = 3
                    else:
                        addr_len = 0
                    if addr_len > 0 and nop == addr_len + 1:
                        sub_opc = operand_bytes[addr_len]
                        # LD (mem), r8 — sub-opc 0x30-0x37
                        if 0x30 <= sub_opc <= 0x37:
                            REG8 = {0x30:'w', 0x31:'a', 0x32:'b', 0x33:'c',
                                    0x34:'d', 0x35:'e', 0x36:'h', 0x37:'l'}
                            reg = REG8[sub_opc]
                            addr_bytes = operand_bytes[:addr_len]
                            byte_args = ', '.join(f'0x{b:02X}' for b in addr_bytes)
                            return f"st_{reg}_dri{addr_len} {byte_args}", nbytes
                        # LDA r32, mem — sub-opc 0x40-0x47
                        if 0x40 <= sub_opc <= 0x47:
                            REG32 = {0x40:'xwa', 0x41:'xbc', 0x42:'xde', 0x43:'xhl',
                                     0x44:'xix', 0x45:'xiy', 0x46:'xiz', 0x47:'xsp'}
                            reg = REG32[sub_opc]
                            addr_bytes = operand_bytes[:addr_len]
                            byte_args = ', '.join(f'0x{b:02X}' for b in addr_bytes)
                            return f"lda_{reg}_dri{addr_len} {byte_args}", nbytes
                        # LD (mem), r16 — sub-opc 0x50-0x57
                        if 0x50 <= sub_opc <= 0x57:
                            REG16 = {0x50:'wa', 0x51:'bc', 0x52:'de', 0x53:'hl',
                                     0x54:'ix', 0x55:'iy', 0x56:'iz', 0x57:'sp'}
                            reg = REG16[sub_opc]
                            addr_bytes = operand_bytes[:addr_len]
                            byte_args = ', '.join(f'0x{b:02X}' for b in addr_bytes)
                            return f"st_{reg}_dri{addr_len} {byte_args}", nbytes
                        # LD (mem), r32 — sub-opc 0x60-0x67
                        if 0x60 <= sub_opc <= 0x67:
                            REG32 = {0x60:'xwa', 0x61:'xbc', 0x62:'xde', 0x63:'xhl',
                                     0x64:'xix', 0x65:'xiy', 0x66:'xiz', 0x67:'xsp'}
                            reg = REG32[sub_opc]
                            addr_bytes = operand_bytes[:addr_len]
                            byte_args = ', '.join(f'0x{b:02X}' for b in addr_bytes)
                            return f"st_{reg}_dri{addr_len} {byte_args}", nbytes

                DEST_CATEGORY = {
                    0: 'dd8',   # 8-bit direct address
                    1: 'dd16',  # 16-bit direct address
                    2: 'dd24',  # 24-bit direct address
                    3: 'dri',   # register-indirect complex
                    4: 'dpd',   # pre-decrement
                    5: 'dpi',   # post-increment
                }
                cat = DEST_CATEGORY.get(low_nibble)
                if cat and 1 <= nop <= 8:
                    byte_args = ', '.join(f'0x{b:02X}' for b in operand_bytes)
                    return f"{cat}{nop} {byte_args}", nbytes

            # Memory addressing categories (80-BF: register-indirect)
            # Uses literal bytes (prefix byte included as first operand) since
            # the prefix encodes register index which varies per instruction.
            if 0x80 <= first <= 0xBF:
                grp = (first >> 4) & 0x3  # 0=8-bit, 1=16-bit, 2=32-bit, 3=dst
                has_disp = (first & 0x08) != 0
                size_char = {0: 'b', 1: 'w', 2: 'l', 3: 'd'}[grp]
                cat = f"mr{'d' if has_disp else 'i'}{size_char}"
                if 2 <= nbytes <= 7:
                    all_bytes = rom_bytes[:nbytes]
                    byte_args = ', '.join(f'0x{b:02X}' for b in all_bytes)
                    return f"{cat}{nbytes} {byte_args}", nbytes

            # Standard register prefix (C8-EF) sub-opcode decode
            if 0xC8 <= first <= 0xEF and nbytes >= 2:
                prefix = first
                sub_opc = rom_bytes[1]
                if first <= 0xCF:
                    size_idx = 0  # 8-bit
                    reg_idx = first - 0xC8
                elif first <= 0xDF:
                    size_idx = 1  # 16-bit
                    reg_idx = first - 0xD8
                else:
                    size_idx = 2  # 32-bit
                    reg_idx = first - 0xE8
                REG8 = ['w','a','b','c','d','e','h','l']
                REG16 = ['wa','bc','de','hl','ix','iy','iz','sp']
                REG32 = ['xwa','xbc','xde','xhl','xix','xiy','xiz','xsp']
                REG_ALL = [REG8, REG16, REG32]
                reg_name = REG_ALL[size_idx][reg_idx]
                sz_suffix = ['8', '16', '32'][size_idx]

                # UNLK r32 (sub=0x0D, 32-bit only, 2 bytes)
                if sub_opc == 0x0D and size_idx == 2 and nbytes == 2:
                    return f"unlk32 {reg_name}", 2

                # LINK r32,d16 (sub=0x0C, 32-bit only, 4 bytes) — ExtPrefix
                if sub_opc == 0x0C and size_idx == 2 and nbytes == 4:
                    b = rom_bytes
                    return (f"link32 0x{b[0]:02X}, 0x{b[1]:02X}, "
                            f"0x{b[2]:02X}, 0x{b[3]:02X}"), 4

                # XORCF A,r (sub=0x2A, 8/16-bit, 2 bytes)
                if sub_opc == 0x2A and size_idx < 2 and nbytes == 2:
                    return f"xorcf_a_{sz_suffix} {reg_name}", 2

                # STCF A,r (sub=0x2C, 8/16-bit, 2 bytes)
                if sub_opc == 0x2C and size_idx < 2 and nbytes == 2:
                    return f"stcf_a_{sz_suffix} {reg_name}", 2

                # LDC cr,r (sub=0x2E) / LDC r,cr (sub=0x2F), 3 bytes
                if sub_opc in (0x2E, 0x2F) and nbytes == 3:
                    cr_num = rom_bytes[2]
                    if sub_opc == 0x2E:
                        return f"ldc_cr{sz_suffix} {reg_name}, 0x{cr_num:02X}", 3
                    else:
                        return f"ldc_{sz_suffix}_cr {reg_name}, 0x{cr_num:02X}", 3

                # MINC1 (sub=0x38) / MINC4 (sub=0x3A), 16-bit, 4 bytes
                if sub_opc in (0x38, 0x3A) and size_idx == 1 and nbytes == 4:
                    imm16 = rom_bytes[2] | (rom_bytes[3] << 8)
                    name = 'minc1_16' if sub_opc == 0x38 else 'minc4_16'
                    return f"{name} {reg_name}, 0x{imm16:X}", 4

                # MUL/MULS/DIV/DIVS rr,r8 (sub=0x40-0x5F, 8-bit, 2 bytes)
                if 0x40 <= sub_opc <= 0x5F and size_idx == 0 and nbytes == 2:
                    other_idx = sub_opc & 0x07
                    other_reg = REG8[other_idx]
                    op_idx = (sub_opc >> 3) & 0x03
                    op_name = ['mul8rr','muls8rr','div8rr','divs8rr'][op_idx]
                    return f"{op_name} {other_reg}, {reg_name}", 2

                # INC/DEC register (sub=0x60-0x6F, 2 bytes)
                if 0x60 <= sub_opc <= 0x6F and nbytes == 2:
                    count = sub_opc & 0x07
                    if count == 0:
                        count = 8
                    is_inc = sub_opc < 0x68
                    name = 'inc' if is_inc else 'dec'
                    return f"{name} {count}, {reg_name}", 2

                # SCC cc,r (sub=0x70-0x7F, 2 bytes)
                if 0x70 <= sub_opc <= 0x7F and nbytes == 2:
                    cc = sub_opc & 0x0F
                    CC_NAMES = ['f','lt','le','ule','ov','mi','z','c',
                                't','ge','gt','ugt','nov','pl','nz','nc']
                    cc_name = CC_NAMES[cc]
                    mnem = ['scc8', 'scc16', 'scc32'][size_idx]
                    return f"{mnem} {cc_name}, {reg_name}", 2

                # LD r2,r (sub=0x88-0x8F, 2 bytes)
                if 0x88 <= sub_opc <= 0x8F and nbytes == 2:
                    other_idx = sub_opc & 0x07
                    other_reg = REG_ALL[size_idx][other_idx]
                    return f"ld {other_reg}, {reg_name}", 2

                # LD r,r2 (sub=0x98-0x9F, 2 bytes)
                if 0x98 <= sub_opc <= 0x9F and nbytes == 2:
                    other_idx = sub_opc & 0x07
                    other_reg = REG_ALL[size_idx][other_idx]
                    return f"ld {reg_name}, {other_reg}", 2

                # LD r,I3 (sub=0xA8-0xAF, 2 bytes)
                if 0xA8 <= sub_opc <= 0xAF and nbytes == 2:
                    imm3 = sub_opc & 0x07
                    mnem = ['lds8', 'lds', 'lds32'][size_idx]
                    return f"{mnem} {reg_name}, {imm3}", 2

                # EX r2,r (sub=0xB8-0xBF, 8/16-bit, 2 bytes)
                if 0xB8 <= sub_opc <= 0xBF and size_idx < 2 and nbytes == 2:
                    other_idx = sub_opc & 0x07
                    other_reg = REG_ALL[size_idx][other_idx]
                    return f"ex{sz_suffix} {other_reg}, {reg_name}", 2

                # CP r,I3 (sub=0xD8-0xDF, 2 bytes)
                if 0xD8 <= sub_opc <= 0xDF and nbytes == 2:
                    imm3 = sub_opc & 0x07
                    return f"cps {reg_name}, {imm3}", 2

                # RLC/RRC with immediate count (sub=0xE8/0xE9, 3 bytes)
                if sub_opc in (0xE8, 0xE9) and nbytes == 3:
                    count = rom_bytes[2]
                    name = 'rlc_i' if sub_opc == 0xE8 else 'rrc_i'
                    return f"{name}_{sz_suffix} {reg_name}, {count}", 3

                # DJNZ r,d8 (sub=0x1C, 3 bytes)
                if sub_opc == 0x1C and size_idx == 1 and nbytes == 3:
                    d8 = rom_bytes[2]
                    if d8 > 127:
                        d8 -= 256
                    return f"djnz16 {reg_name}, {d8}", 3

                # ADD/ADC/SUB/SBC/AND/XOR/OR/CP r,#imm (sub=0xC8-0xCF)
                if 0xC8 <= sub_opc <= 0xCF and nbytes >= 3:
                    ALU_NAMES = {0xC8:'add',0xC9:'adc',0xCA:'sub',0xCB:'sbc',
                                 0xCC:'and',0xCD:'xor',0xCE:'or',0xCF:'cp'}
                    alu_name = ALU_NAMES[sub_opc]
                    imm_bytes = nbytes - 2
                    imm_val = 0
                    for i in range(imm_bytes):
                        imm_val |= rom_bytes[2 + i] << (8 * i)
                    return f"{alu_name} {reg_name}, 0x{imm_val:X}", nbytes

            # Fallback: generic extpfx for remaining patterns
            # (C8-CF, D8-DF, E8-EF register prefix with unhandled sub-opcodes)
            byte_args = ', '.join(f'0x{b:02X}' for b in rom_bytes[:nbytes])
            return f"extpfx{nbytes} {byte_args}", nbytes

    return None  # No native conversion available


def convert_instruction(label, mnemonic, operands_str, comment, label_addr_suffix=""):
    """Convert a CPU instruction to native LLVM or .byte fallback."""
    global NATIVE_INSTR_COUNT, BYTE_FALLBACK_COUNT

    result = ""
    if label:
        result = f"{label}:{label_addr_suffix}\n"

    addr = ADDR_TRACKER.get_addr()
    nbytes = get_instruction_size_from_rom(addr) if addr is not None else None

    if addr is not None and nbytes is not None:
        rom_bytes = get_rom_bytes(addr, nbytes)
        if rom_bytes is not None:
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
    result = ""
    if label:
        result = f"{label}:{label_addr_suffix}\n"

    # Track bytes for address advancement
    nbytes = _count_db_bytes(args)

    # When ROM is available, emit from ROM for guaranteed correctness
    addr = ADDR_TRACKER.get_addr()
    if addr is not None and nbytes is not None and nbytes > 0:
        rom_bytes = get_rom_bytes(addr, nbytes)
        if rom_bytes is not None:
            # Try native instruction conversion for db lines with instruction comments.
            # Only attempt if the ASL comment starts with a known TLCS-900 mnemonic.
            DB_INSTR_MNEMONICS = {
                'NOP', 'EI', 'DI', 'RETI', 'RET', 'RETD', 'HALT', 'SWI', 'PUSH', 'POP',
                'PUSHW', 'LD', 'LDW', 'LDA', 'ADD', 'ADC', 'SUB', 'SBC', 'AND', 'OR',
                'XOR', 'CP', 'INC', 'INCW', 'DEC', 'DECW', 'NEG', 'CPL', 'EXTS', 'EXTZ', 'EX',
                'SLA', 'SRA', 'SRL', 'SLL', 'RLC', 'RRC', 'RL', 'RR',
                'SET', 'RES', 'BIT', 'CHG', 'TSET', 'CALL', 'CALR', 'JP', 'JR', 'JRL',
                'DJNZ', 'MUL', 'MULS', 'DIV', 'DIVS', 'SCC', 'INCF', 'DECF',
                'LDI', 'LDIR', 'LDIW', 'LDIRW', 'LDDR', 'CPIR',
                'SRLW',
            }
            native_done = False
            if 1 <= nbytes <= 7 and comment:
                # Try native instruction conversion using comment mnemonic.
                ctext = comment.lstrip('; \t')
                cmnem = ctext.split()[0].upper() if ctext else ''
                use_opcode_guess = False
                if cmnem not in DB_INSTR_MNEMONICS:
                    # Try "Fix ASL: MNEMONIC" pattern
                    m = re.search(r'Fix ASL:\s*(\w+)', ctext, re.IGNORECASE)
                    if m and m.group(1).upper() in DB_INSTR_MNEMONICS:
                        cmnem = m.group(1).upper()
                if cmnem not in DB_INSTR_MNEMONICS:
                    # Try stripping suffixes from macro names (e.g. LDW_16_16 → LDW)
                    base = cmnem.split('_')[0]
                    if base in DB_INSTR_MNEMONICS:
                        cmnem = base
                        use_opcode_guess = True
                if cmnem not in DB_INSTR_MNEMONICS:
                    # Try "ADDR: MNEMONIC" pattern (e.g. "; F20DAD: LD ...")
                    m = re.match(r'[0-9A-Fa-f]+:\s*(\w+)', ctext)
                    if m and m.group(1).upper() in DB_INSTR_MNEMONICS:
                        cmnem = m.group(1).upper()
                        use_opcode_guess = True
                if cmnem in DB_INSTR_MNEMONICS:
                    # Extract operands from comment for label resolution
                    # E.g. "; CALR FDC_ReadStatus" → operands = "FDC_ReadStatus"
                    # E.g. "; JR Z, .wait_loop" → operands = "Z, .wait_loop"
                    comment_operands = ''
                    words = ctext.split(None, 1)
                    if len(words) > 1:
                        comment_operands = words[1].split(';')[0].strip()
                        # Strip parenthetical notes
                        comment_operands = re.sub(r'\s*\(.*?\)\s*$', '', comment_operands)
                        # Strip trailing human text after " - " separator
                        comment_operands = re.sub(r'\s+-\s+\w.*$', '', comment_operands)
                        # Strip trailing descriptive words (not valid operand chars)
                        comment_operands = re.sub(r'\s+[a-z][\w\s]*$', '', comment_operands)
                        # For branch instructions, validate comment labels:
                        # 1. No local labels (.xxx) — they're unqualified in comments
                        # 2. Label must exist at the correct target address
                        #    (comments sometimes reference nearby but wrong labels)
                        if cmnem in ('JR', 'JRL', 'CALR'):
                            cparts = comment_operands.split(',')
                            clabel = cparts[-1].strip()
                            # Reject unqualified local labels — they won't resolve
                            if clabel.startswith('.'):
                                comment_operands = ''
                            elif re.match(r'^[A-Za-z_]\w*$', clabel):
                                # Compute actual target from ROM bytes
                                rom_target = None
                                if cmnem == 'JR' and nbytes == 2:
                                    d8 = rom_bytes[1]
                                    if d8 > 127: d8 -= 256
                                    rom_target = addr + 2 + d8
                                elif cmnem in ('JRL', 'CALR') and nbytes == 3:
                                    d16 = rom_bytes[1] | (rom_bytes[2] << 8)
                                    if d16 > 32767: d16 -= 65536
                                    rom_target = addr + 3 + d16
                                # Check label exists at the exact target address
                                label_addr = None
                                for a, n in ADDR_TO_LABEL_ALL.items():
                                    if n == clabel:
                                        label_addr = a
                                        break
                                if label_addr is None or \
                                   (rom_target is not None and label_addr != rom_target):
                                    comment_operands = ''  # wrong or missing label
                    try:
                        native = try_convert_native(cmnem, comment_operands, rom_bytes, nbytes, addr)
                        if native is None and use_opcode_guess:
                            # Opcode-based guessing when comment mnemonic was wrong
                            for mnem in guess_mnemonics_from_opcode(rom_bytes[0]):
                                native = try_convert_native(mnem, comment_operands, rom_bytes, nbytes, addr)
                                if native is not None:
                                    break
                        if native is not None:
                            native_asm, _ = native
                            result += f"\t{native_asm}"
                            native_done = True
                    except (IndexError, KeyError, ValueError):
                        pass  # Fall through to .byte emission
            if not native_done:
                string_form = _try_emit_as_string(rom_bytes)
                if string_form is not None:
                    result += f"\t{string_form}"
                elif len(rom_bytes) >= 2 and all(b == 0x00 for b in rom_bytes):
                    result += f"\t.zero {len(rom_bytes)}"
                elif len(rom_bytes) >= 2 and all(b == rom_bytes[0] for b in rom_bytes):
                    result += f"\t.fill {len(rom_bytes)}, 1, 0x{rom_bytes[0]:02x}"
                else:
                    byte_str = ', '.join(f'0x{b:02x}' for b in rom_bytes)
                    if _db_args_all_numeric(args):
                        result += f"\t.byte {byte_str}"
                    else:
                        result += f"\t.byte {byte_str}\t; DB {args}"
            ADDR_TRACKER.advance(nbytes)
            if comment:
                result += f"\t{comment}"
            return result

    # Source-based conversion (no ROM available)
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
    result = ""
    if label:
        result = f"{label}:{label_addr_suffix}\n"

    nvalues = len(split_operands(args))
    nbytes = 2 * nvalues
    addr = ADDR_TRACKER.get_addr()

    # If dw references labels, emit raw bytes from ROM (labels may not resolve)
    if _dw_has_label_refs(args) and addr is not None:
        rom_bytes = get_rom_bytes(addr, nbytes)
        if rom_bytes is not None:
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
    """Parse the ASL macro library to populate KNOWN_MACROS.

    The tmp94c241.inc macros are all ASL workarounds that emit raw bytes.
    Since the LLVM backend supports all these instructions natively, we
    only need to parse macro names for recognition during conversion —
    no output file is generated.
    """
    with open(input_path, 'r') as f:
        lines = f.readlines()

    for line in lines:
        stripped = line.strip()
        m = re.match(r'^(\w+)\s+MACRO\s*(.*)', stripped, re.IGNORECASE)
        if m:
            macro_name = m.group(1)
            KNOWN_MACROS.add(macro_name.upper())

    print(f"  Parsed macro library: {input_path}")
    print(f"  Found {len(KNOWN_MACROS)} macro definitions (no output file generated)")


# ============================================================================
# File conversion — global ORG sorting with inlined includes
# ============================================================================

def read_all_lines(input_path, main_dir, depth=0):
    """Recursively read an ASL file, inlining includes (except macro library).

    Also expands REPT/ENDM blocks inline so the converter sees flat content.

    Returns a list of (line_text, source_file) tuples.
    """
    if depth > 10:
        return []

    result = []
    file_dir = os.path.dirname(input_path)
    # Stack for nested REPT blocks: each entry is (count, body_lines)
    rept_stack = []

    with open(input_path, 'r') as f:
        for line in f:
            line = line.rstrip('\n')
            stripped = line.strip()
            code_part, _ = split_comment(stripped)
            code_stripped = code_part.strip()

            # Check for REPT directive
            m_rept = re.match(r'rept\s+([0-9A-Fa-f]+[hH]|\d+)', code_stripped, re.IGNORECASE)
            if m_rept:
                count_str = m_rept.group(1)
                if count_str.upper().endswith('H'):
                    count = int(count_str[:-1], 16)
                else:
                    count = int(count_str)
                rept_stack.append((count, []))
                continue

            # Check for ENDM closing a REPT
            if code_stripped.upper() == 'ENDM' and rept_stack:
                count, body = rept_stack.pop()
                expanded = body * count
                if rept_stack:
                    # Nested rept — add to parent's body
                    rept_stack[-1][1].extend(expanded)
                else:
                    result.extend(expanded)
                continue

            # If inside a REPT block, collect body lines
            if rept_stack:
                rept_stack[-1][1].append((line, input_path))
                continue

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
    parent_label = ""  # Track parent label for local label qualification
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
                # Track parent label scope for local label qualification
                if not label.startswith('.'):
                    parent_label = label
                # Qualify local labels (starting with '.')
                record_name = label
                if label.startswith('.'):
                    record_name = f"{parent_label}__{label[1:]}" if parent_label else label[1:]

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
                        _record_label(addr_to_label, cur_addr, record_name)
                    # All: always record with tracked address
                    _record_label(addr_to_label_all, cur_addr, record_name)

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
            else:
                # Unrecognized first word: might be an ASL label without colon.
                # Pattern: "LabelName ; XXXXXX" (no colon, address in comment)
                if not remainder and cmt:
                    m_addr = re.match(r'^;\s*([0-9A-Fa-f]{6})\s*$', cmt.strip())
                    if m_addr:
                        cur_addr = int(m_addr.group(1), 16)
                        _record_label(addr_to_label, cur_addr, first)
                        _record_label(addr_to_label_all, cur_addr, first)
                        at_reliable_boundary = True

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
    global ADDR_TRACKER
    global SEG_START_ADDR, SEG_END_ADDR
    global NATIVE_INSTR_COUNT, BYTE_FALLBACK_COUNT
    global SYNTHETIC_FORWARD_LABELS

    NATIVE_INSTR_COUNT = 0
    BYTE_FALLBACK_COUNT = 0
    SYNTHETIC_FORWARD_LABELS = {}

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

    # Add EQU-defined addresses to label maps and label_only_labels.
    # EQU names that point to ROM addresses (0xE00000-0xFFFFFF) can serve as
    # branch targets for CALR/JR/JRL, but ONLY if emitted as inline labels
    # (not .equ constants, which don't produce correct PC-relative offsets).
    # EQU names that become inline labels (suppressed from .equ emission).
    global EQU_INLINE_LABELS
    EQU_INLINE_LABELS = set()
    equ_labels_added = 0
    for equ_name, equ_val in KNOWN_EQUS.items():
        if isinstance(equ_val, int) and ROM_BASE <= equ_val < ROM_BASE + ROM_SIZE:
            # Skip if a label already exists at this address
            if equ_val in ADDR_TO_LABEL:
                continue
            # Skip register/condition code name conflicts
            if equ_name.lower() in RESERVED_LABEL_NAMES:
                continue
            ADDR_TO_LABEL[equ_val] = equ_name
            ADDR_TO_LABEL_ALL[equ_val] = equ_name
            # Add to label_only_labels for inline emission
            if equ_val not in label_only_labels:
                label_only_labels[equ_val] = []
            if equ_name not in label_only_labels[equ_val]:
                label_only_labels[equ_val].append(equ_name)
            EQU_INLINE_LABELS.add(equ_name)
            equ_labels_added += 1
    if equ_labels_added:
        print(f"  EQU labels added to maps: {equ_labels_added}")

    # Build output
    output_lines = []
    output_lines.append(f"; Converted from {main_file} by asl_to_llvm.py")
    output_lines.append(f"; Modular includes preserved, segments globally sorted by ORG address.")
    output_lines.append(f"; Per-instruction .byte fallback with progressive native replacement.")
    output_lines.append(f"; This file is auto-generated. Edit the converter, not this file.")
    output_lines.append("")
    output_lines.append("\t.text")
    output_lines.append("")

    total_rom_bytes = 0
    emitted_label_addrs = set()  # Track label-only labels emitted inline

    # Emit content segments — per-line conversion with direct ROM access.
    # Address tracker is reset at each address-encoding label. Instructions
    # and data are read directly from ROM at the tracked address.
    for seg_addr, seg_lines in sorted_content:
        seg_end = None
        if seg_addr is not None:
            # Reset address tracker at each segment boundary
            ADDR_TRACKER = AddressTracker()
            ADDR_TRACKER.set_org(seg_addr)
            SEG_START_ADDR = seg_addr

            if seg_addr in seg_end_map:
                seg_end = seg_end_map[seg_addr]
                SEG_END_ADDR = seg_end
            else:
                SEG_END_ADDR = ROM_BASE + ROM_SIZE

        for line, source in seg_lines:
            # Emit label-only labels when address tracker reaches their address.
            cur_addr = ADDR_TRACKER.get_addr()
            if cur_addr is not None and cur_addr in label_only_labels and cur_addr not in emitted_label_addrs:
                for lbl_name in label_only_labels[cur_addr]:
                    output_lines.append(f"{lbl_name}:")
                emitted_label_addrs.add(cur_addr)

            # Emit synthetic forward labels (created by JR T $+2 delay NOPs).
            if cur_addr is not None and cur_addr in SYNTHETIC_FORWARD_LABELS:
                synth_label = SYNTHETIC_FORWARD_LABELS.pop(cur_addr)
                output_lines.append(f"{synth_label}:")

            converted = convert_line(line, source)

            if converted is not None:
                output_lines.append(converted)

        if seg_addr is not None and seg_addr in seg_end_map:
            total_rom_bytes += seg_end_map[seg_addr] - seg_addr

    # Emit .set labels for those NOT emitted inline.
    # These are label-only labels at addresses not reached during conversion.
    all_set_labels = []
    for addr in sorted(label_only_labels.keys()):
        if addr not in emitted_label_addrs:
            for lbl_name in label_only_labels[addr]:
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

    # Split output into modular include files (if any include boundaries exist)
    output_dir = os.path.dirname(output_path)
    output_lines = split_output_into_includes(output_lines, output_dir)

    os.makedirs(output_dir, exist_ok=True)
    with open(output_path, 'w') as f:
        f.write('\n'.join(output_lines) + '\n')

    # Print statistics
    print(f"  Output: {output_path}")
    print(f"  ROM bytes covered: {total_rom_bytes} / {ROM_SIZE} ({100*total_rom_bytes/ROM_SIZE:.1f}%)")
    print(f"  .byte fallback lines: {BYTE_FALLBACK_COUNT}")
    print(f"  Native instruction lines: {NATIVE_INSTR_COUNT}")
    print(f"  Labels: {len(emitted_label_addrs)} inline + {len(all_set_labels)} .set")


# ============================================================================
# Main
# ============================================================================

def main():
    global ROM_BASE, ROM_SIZE, LLVM_DIR, INPUT_DIR

    parser = argparse.ArgumentParser(
        description='ASL-to-LLVM Assembly Converter for KN5000 ROM disassembly.')
    parser.add_argument('input_file', help='Main ASL assembly file to convert')
    parser.add_argument('--rom-base', type=lambda x: int(x, 0), default=0xE00000,
                        help='ROM base address (default: 0xE00000)')
    parser.add_argument('--rom-size', type=lambda x: int(x, 0), default=0x200000,
                        help='ROM size in bytes (default: 0x200000)')
    parser.add_argument('--rom-file', default=None,
                        help='Path to original ROM file (default: auto-detect)')
    parser.add_argument('--output-dir', default=None,
                        help='Output directory for LLVM files (default: <input-dir>/llvm)')

    args = parser.parse_args()

    main_file = args.input_file
    main_dir = os.path.dirname(main_file)
    INPUT_DIR = main_dir

    ROM_BASE = args.rom_base
    ROM_SIZE = args.rom_size

    if args.output_dir:
        LLVM_DIR = Path(args.output_dir)
    else:
        LLVM_DIR = Path(main_dir) / "llvm"

    # Derive output filename from input filename
    input_basename = os.path.splitext(os.path.basename(main_file))[0]
    main_output = os.path.join(str(LLVM_DIR), f'{input_basename}.s')

    print(f"ASL-to-LLVM converter (Phase 3)")
    print(f"Input: {main_file}")
    print(f"Output: {main_output}")
    print(f"ROM base: 0x{ROM_BASE:X}, size: 0x{ROM_SIZE:X}")
    print()

    # Load original ROM
    print("Loading original ROM...")
    load_original_rom(args.rom_file)
    print()

    # Step 1: Parse macro library for KNOWN_MACROS (no output file generated)
    # Search for tmp94c241.inc: check parent directories up to 3 levels
    macro_input = None
    search_dir = main_dir or '.'
    for _ in range(4):
        candidate = os.path.normpath(os.path.join(search_dir, 'tmp94c241.inc'))
        if os.path.exists(candidate):
            macro_input = candidate
            break
        parent = os.path.dirname(search_dir)
        if parent == search_dir:
            break
        search_dir = parent
    if macro_input is None:
        macro_input = 'tmp94c241.inc'

    print("Step 1: Parsing macro library...")
    convert_macro_file(macro_input, None)
    print()

    # Step 2: Convert main file + all includes into single output
    print("Step 2: Converting all source files...")
    convert_all(main_file, main_output)
    print()

    print("Conversion complete.")


if __name__ == '__main__':
    main()
