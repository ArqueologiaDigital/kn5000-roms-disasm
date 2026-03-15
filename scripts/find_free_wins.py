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
        lines = raw.decode('latin-1').splitlines()
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


def translate_unidasm_to_llvm(mnemonic):
    """Attempt to translate unidasm mnemonic to LLVM assembly syntax.

    Returns the LLVM instruction string, or None if translation not possible.
    """
    mnem = mnemonic.strip()

    # Skip known untranslatable patterns
    if mnem.startswith('db') or mnem == 'max' or mnem == 'normal':
        return None

    # Handle some specific patterns
    # push immediate: "push 0xNNNN"
    m = re.match(r'^push\s+0x([0-9a-fA-F]+)$', mnem)
    if m:
        val = int(m.group(1), 16)
        return f'pushw {val}'

    # push register
    m = re.match(r'^push\s+([A-Z]+)$', mnem)
    if m:
        reg = UNIDASM_REG_MAP.get(m.group(1))
        if reg:
            return f'push {reg}'

    # pop register
    m = re.match(r'^pop\s+([A-Z]+)$', mnem)
    if m:
        reg = UNIDASM_REG_MAP.get(m.group(1))
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

    # Handle ld/ldw/cp/add/sub/and/or/xor with memory operands
    def translate_operand(operand):
        operand = operand.strip()

        # Memory indirect with displacement: (XRR+0xNN)
        m = re.match(r'^\(([A-Z]+)\+(0x[0-9a-fA-F]+)\)$', operand)
        if m:
            reg = UNIDASM_REG_MAP.get(m.group(1))
            disp = int(m.group(2), 16)
            if reg:
                return f'({reg}+{disp})'

        # Memory indirect with negative disp: (XRR-0xNN) — unidasm may not use this
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

        # Post-increment: (XRR+)
        m = re.match(r'^\(([A-Z]+)\+\)$', operand)
        if m:
            return None  # LLVM doesn't support this syntax

        # Pre-decrement: (-XRR)
        m = re.match(r'^\(-([A-Z]+)\)$', operand)
        if m:
            return None  # LLVM doesn't support this syntax

        # Register+Register: (XRR+RR)
        m = re.match(r'^\(([A-Z]+)\+([A-Z]+)\)$', operand)
        if m:
            return None  # LLVM doesn't support R+R addressing

        # Direct memory address: (0xNNNN)
        m = re.match(r'^\((0x[0-9a-fA-F]+)\)$', operand)
        if m:
            return None  # May need special handling

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
                llvm_inst = translate_unidasm_to_llvm(mnem)
                if llvm_inst is None:
                    block_free = False
                    failure_categories[f'no_translation: {mnem[:40]}'] += 1
                    continue

                # Try LLVM encoding
                encoded = try_llvm_encode(llvm_inst)
                if encoded is None:
                    block_free = False
                    failure_categories[f'llvm_cant_encode: {llvm_inst[:40]}'] += 1
                    continue

                # Check byte match
                inst_bytes = raw_bytes[offset:offset + length]
                if encoded != inst_bytes:
                    block_free = False
                    failure_categories[f'byte_mismatch: {llvm_inst[:40]}'] += 1
                    if args.verbose:
                        print(f"  MISMATCH {rel}:{start_line}: "
                              f"expected {' '.join(f'{b:02x}' for b in inst_bytes)}, "
                              f"got {' '.join(f'{b:02x}' for b in encoded)} "
                              f"for: {llvm_inst}", file=sys.stderr)
                    continue

                block_instructions.append((offset, length, llvm_inst))

            if block_free and block_instructions:
                free_wins += 1
                free_win_bytes += len(raw_bytes)
                if args.verbose:
                    for offset, length, inst in block_instructions:
                        print(f"  FREE WIN {rel}:{start_line}+{offset}: {inst}")

                # Record for conversion
                file_conversions[str(file_path)].append(
                    (start_line, end_line, raw_bytes, block_instructions)
                )
                success_instructions.extend(inst for _, _, inst in block_instructions)
            elif block_instructions:
                # Partial — some instructions translatable, some not
                needs_llvm += 1
                needs_llvm_bytes += len(raw_bytes)
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
    """Apply free win conversions to a file using binary I/O (Latin-1 safe)."""
    with open(file_path, 'rb') as f:
        raw = f.read()
    lines = raw.decode('latin-1').splitlines(keepends=True)

    # Build a mapping: line_number -> replacement instruction
    # Each conversion: (start_line, end_line, raw_bytes, [(offset, length, llvm_inst), ...])
    # A free win block has contiguous .byte lines that decode to native instructions.
    # We need to replace the .byte lines with the instruction(s).

    replacements = {}  # line_number (1-indexed) -> list of replacement strings
    lines_to_remove = set()

    for start_line, end_line, raw_bytes, block_instructions in conversions:
        # Generate replacement lines
        new_lines = []
        for offset, length, llvm_inst in block_instructions:
            new_lines.append(f'\t{llvm_inst}\n')

        # Find the .byte lines in this range
        byte_line_numbers = []
        for line_no in range(start_line, end_line + 1):
            if line_no <= len(lines):
                line = lines[line_no - 1]
                if BYTE_LINE_RE.match(line):
                    byte_line_numbers.append(line_no)

        if not byte_line_numbers:
            continue

        # Replace first .byte line with the new instruction(s)
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


if __name__ == '__main__':
    main()
