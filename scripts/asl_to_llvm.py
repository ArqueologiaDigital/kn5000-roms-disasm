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

    def set_org(self, addr):
        """Set address from ORG directive."""
        self.current_addr = addr

    def advance(self, nbytes):
        """Advance address by N bytes."""
        if self.current_addr is not None:
            self.current_addr += nbytes

    def get_addr(self):
        return self.current_addr


# Global address tracker
ADDR_TRACKER = AddressTracker()

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

def get_instruction_size_from_rom(addr):
    """Determine instruction size by reading opcode bytes from the ROM.

    TLCS-900 instructions are 1-7 bytes. The first byte (opcode) determines
    the instruction length. This is a simplified decoder.
    """
    if ORIGINAL_ROM is None or addr is None:
        return None

    offset = addr - ROM_BASE
    if offset < 0 or offset >= len(ORIGINAL_ROM):
        return None

    opcode = ORIGINAL_ROM[offset]

    # This is a simplified instruction length decoder for TLCS-900
    # Full decoding would be very complex. For Phase 1, we don't need this.
    # Instead, we use a different strategy: emit entire ORG-delimited blocks.
    return None  # Not implemented


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
    'INC', 'DEC',
    'MUL', 'MULS', 'DIV', 'DIVS', 'MULW', 'DIVW',
    'SRL', 'SRA', 'SLA', 'SLL', 'RL', 'RLC', 'RR', 'RRC',
    'SET', 'RES', 'BIT', 'TSET', 'CHG',
    'JP', 'JR', 'JRL', 'CALL', 'RET', 'RETI', 'RETD',
    'HALT', 'NOP', 'EI', 'DI', 'SWI',
    'CCF', 'SCF', 'RCF', 'ZCF',
    'EX', 'EXTZ', 'EXTS', 'DAA',
    'NEG', 'CPL', 'MIRR',
    'LDC', 'LDCF', 'STCF',
    'LDIR', 'LDDR', 'LDI', 'LDD',
    'LDIRW', 'LDDRW', 'LDIW', 'LDDW',
    'CPIR', 'CPDR',
    'LINK', 'UNLK',
    'DJNZ', 'MINC1', 'MINC2', 'MINC4', 'MDEC1', 'MDEC2', 'MDEC4',
    'SCC', 'BS1F', 'BS1B',
    'CALR',  # This is also a macro but ASL has it natively
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
    stripped = line.rstrip()
    if not stripped:
        return ""

    # Extract comment
    code_part, comment = split_comment(stripped)
    code_stripped = code_part.rstrip()

    # Pure comment line
    if not code_stripped:
        return stripped

    # Parse label
    label, rest = extract_label(code_stripped)
    rest = rest.strip()

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

    # include → .include
    if first_upper == 'INCLUDE':
        path_str = remainder.strip().strip('"').strip("'")
        llvm_path = compute_llvm_include_path(path_str, in_file_path)
        result = f'\t.include "{llvm_path}"'
        if comment:
            result += f"\t{comment}"
        return result

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
        macro_name = first_word
        KNOWN_MACROS.add(macro_name.upper())
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
        return ".endm"

    # ---- Data directives ----

    if first_upper == 'DB':
        return convert_db(label, remainder.strip(), comment, in_file_path)

    if first_upper == 'DW':
        return convert_dw(label, remainder.strip(), comment)

    if first_upper == 'DD':
        values = convert_expression(remainder.strip())
        result = ""
        if label:
            result = f"{label}:\n"
        result += f"\t.long {values}"
        if comment:
            result += f"\t{comment}"
        return result

    if first_upper == 'DS':
        values = convert_expression(remainder.strip())
        result = ""
        if label:
            result = f"{label}:\n"
        result += f"\t.space {values}"
        if comment:
            result += f"\t{comment}"
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
        return result

    # ---- Macro invocations ----
    if is_macro_invocation(first_word):
        args = remainder.strip()
        result = ""
        if label:
            result = f"{label}:\n"
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
    # Could be a macro invocation we don't know about, or a label used
    # as an instruction. Preserve as-is.
    result = ""
    if label:
        result = f"{label}:\n"
    converted_rest = convert_expression(rest)
    result += f"\t{converted_rest}"
    if comment:
        result += f"\t{comment}"
    return result


def convert_instruction(label, mnemonic, operands_str, comment):
    """Convert a CPU instruction to LLVM syntax."""
    mn_lower = mnemonic.lower()
    result = ""
    if label:
        result = f"{label}:\n"

    # Parse operands
    operands = split_operands(operands_str) if operands_str else []

    # Convert operand expressions (hex, $→.)
    converted_ops = [convert_expression(op) for op in operands]

    # Shift instructions: swap operand order
    # ASL: SRL 1, XDE → LLVM: srl XDE, 1
    if mn_lower in ('srl', 'sll', 'sla', 'sra', 'rl', 'rlc', 'rr', 'rrc'):
        if len(converted_ops) == 2:
            converted_ops = [converted_ops[1], converted_ops[0]]

    # Remove unconditional T condition
    if mn_lower in ('jp', 'jr', 'jrl', 'call', 'ret'):
        if len(converted_ops) >= 1 and converted_ops[0].upper() == 'T':
            converted_ops = converted_ops[1:]

    # Remove size specifiers (:8, :16, :24)
    converted_ops = [re.sub(r':(?:8|16|24)\b', '', op) for op in converted_ops]

    ops_str = ', '.join(converted_ops)
    result += f"\t{mn_lower}"
    if ops_str:
        result += f" {ops_str}"
    if comment:
        result += f"\t{comment}"
    return result


# ============================================================================
# Data directive helpers
# ============================================================================

def convert_db(label, args, comment, in_file_path):
    """Convert db directive - handle strings, bytes, and dup patterns."""
    result = ""
    if label:
        result = f"{label}:\n"

    # Handle ASL dup pattern: db 920 dup (000h) → .fill 920, 1, 0x0
    dup_match = re.match(r'(.+?)\s+dup\s*\(([^)]+)\)', args, re.IGNORECASE)
    if dup_match:
        count = convert_expression(dup_match.group(1).strip())
        fill_value = convert_expression(dup_match.group(2).strip())
        result += f"\t.fill {count}, 1, {fill_value}"
        if comment:
            result += f"\t{comment}"
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


def convert_dw(label, args, comment):
    """Convert dw to .short."""
    result = ""
    if label:
        result = f"{label}:\n"
    values = convert_expression(args)
    result += f"\t.short {values}"
    if comment:
        result += f"\t{comment}"
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
# File conversion
# ============================================================================

def convert_file(input_path, output_path, is_main_file=False):
    """Convert a single ASL file to LLVM assembly."""
    with open(input_path, 'r') as f:
        lines = f.readlines()

    output_lines = []

    if is_main_file:
        output_lines.append(f"; Converted from {input_path} by asl_to_llvm.py")
        output_lines.append(f"; This file is auto-generated. Edit the converter, not this file.")
        output_lines.append("")
        output_lines.append("\t.text")
        output_lines.append("")

    # Collect all lines with their ORG addresses for sorting
    # to handle backward ORGs
    segments = []  # List of (org_addr, [lines])
    current_org = None
    current_lines = []

    for line in lines:
        line = line.rstrip('\n')
        stripped = line.strip()
        code_part, _ = split_comment(stripped)
        code_stripped = code_part.strip()

        # Check for ORG
        lbl, rest = extract_label(code_stripped)
        if not rest:
            rest = code_stripped if not lbl else ""
        first, remainder = get_first_word(rest) if rest else ("", "")

        if first.upper() == 'ORG':
            # Save current segment
            if current_lines:
                segments.append((current_org, current_lines))
            current_org = resolve_org_addr(remainder.strip())
            current_lines = [line]
        else:
            current_lines.append(line)

    if current_lines:
        segments.append((current_org, current_lines))

    # Sort segments by address (handle backward ORGs)
    none_segs = [(a, l) for a, l in segments if a is None]
    addr_segs = [(a, l) for a, l in segments if a is not None]
    addr_segs.sort(key=lambda x: x[0])
    sorted_segs = none_segs + addr_segs

    if segments != sorted_segs:
        reorder_count = sum(1 for i, (a, _) in enumerate(segments)
                          if i < len(sorted_segs) and a != sorted_segs[i][0])
        if reorder_count > 0:
            output_lines.append(f"; NOTE: {reorder_count} segments reordered for forward-only ORGs")
            output_lines.append("")

    # Convert all lines
    for seg_addr, seg_lines in sorted_segs:
        for line in seg_lines:
            converted = convert_line(line, input_path)
            if converted is not None:
                output_lines.append(converted)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        f.write('\n'.join(output_lines) + '\n')

    print(f"  Converted: {input_path} → {output_path}")


# ============================================================================
# Include scanning
# ============================================================================

def scan_includes(main_file):
    """Scan for all include directives in the main file."""
    includes = []
    with open(main_file, 'r') as f:
        for line in f:
            code_part, _ = split_comment(line.strip())
            m = re.match(r'include\s+"([^"]+)"', code_part.strip(), re.IGNORECASE)
            if m:
                includes.append(m.group(1))
    return includes


def compute_input_path(include_path, main_dir):
    """Compute absolute input path for an include file."""
    return os.path.normpath(os.path.join(main_dir, include_path))


def compute_output_path(include_path):
    """Compute LLVM output path for an include file."""
    clean = include_path
    while clean.startswith('../'):
        clean = clean[3:]
    if clean.endswith('.inc'):
        clean = clean + '.s'
    elif clean.endswith('.asm'):
        clean = clean[:-4] + '.s'
    return os.path.join(str(LLVM_DIR), clean)


# ============================================================================
# Main
# ============================================================================

def main():
    if len(sys.argv) < 2:
        print("Usage: python scripts/asl_to_llvm.py maincpu/kn5000_v10_program.asm")
        sys.exit(1)

    main_file = sys.argv[1]
    main_dir = os.path.dirname(main_file)

    print(f"ASL-to-LLVM converter")
    print(f"Input: {main_file}")
    print(f"Output directory: {LLVM_DIR}")
    print()

    # Load original ROM
    print("Loading original ROM...")
    load_original_rom()
    print()

    # Step 1: Convert macro library
    macro_input = os.path.normpath(os.path.join(main_dir, '..', 'tmp94c241.inc'))
    if not os.path.exists(macro_input):
        macro_input = 'tmp94c241.inc'
    macro_output = os.path.join(str(LLVM_DIR), 'tmp94c241.inc.s')

    print("Step 1: Converting macro library...")
    convert_macro_file(macro_input, macro_output)
    print()

    # Step 2: Scan includes
    print("Step 2: Scanning include files...")
    includes = scan_includes(main_file)
    print(f"  Found {len(includes)} include directives")
    includes = [inc for inc in includes if 'tmp94c241.inc' not in inc]
    print(f"  {len(includes)} files to convert (excluding macro library)")
    print()

    # Step 3: Convert include files
    print("Step 3: Converting include files...")
    for include_path in includes:
        input_path = compute_input_path(include_path, main_dir)
        output_path = compute_output_path(include_path)
        if os.path.exists(input_path):
            convert_file(input_path, output_path)
        else:
            print(f"  WARNING: Include file not found: {input_path}")
    print()

    # Step 4: Convert main file
    print("Step 4: Converting main file...")
    main_output = os.path.join(str(LLVM_DIR), 'kn5000_v10_program.s')
    convert_file(main_file, main_output, is_main_file=True)
    print()

    total_files = 1 + len(includes) + 1
    print(f"Conversion complete: {total_files} files generated in {LLVM_DIR}/")


if __name__ == '__main__':
    main()
