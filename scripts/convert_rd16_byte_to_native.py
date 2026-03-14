#!/usr/bin/env python3
"""
Convert .byte instruction fallbacks with R+d16 addressing to native LLVM mnemonics.

The TLCS-900 R+d16 addressing mode uses prefix bytes C3/D3/E3 (source memory)
and F3 (destination memory/stores) with a mode byte indicating (Xrr+d16) addressing.

Format: [prefix] [mode_byte] [d16_lo] [d16_hi] [opcode] [optional_immediate...]

Mode bytes for d16: 0xE1 (XWA), 0xE5 (XBC), 0xE9 (XDE), 0xED (XHL),
                    0xF1 (XIX), 0xF5 (XIY), 0xF9 (XIZ), 0xFD (XSP)

This script:
1. Finds .byte sequences matching R+d16 patterns (at ANY position in the line)
2. Decodes them to native LLVM assembly
3. Verifies round-trip (assembles back to same bytes)
4. Splits .byte lines around the native mnemonic
5. Uses binary I/O to preserve Latin-1 encoding

Usage: python3 scripts/convert_rd16_byte_to_native.py [--dry-run] [--file PATH]
"""

import os
import re
import subprocess
import struct
import sys
from collections import defaultdict

LLVM_MC = '/mnt/shared/llvm-project/build/bin/llvm-mc'
REPO_ROOT = '/mnt/shared/kn5000-roms-disasm'

# Mode byte -> register name mapping for d16 addressing
D16_MODE_BYTES = {
    0xE1: 'xwa', 0xE5: 'xbc', 0xE9: 'xde', 0xED: 'xhl',
    0xF1: 'xix', 0xF5: 'xiy', 0xF9: 'xiz', 0xFD: 'xsp',
}

# Register names by code for each size
REGS_8 = {0: 'w', 1: 'a', 2: 'b', 3: 'c', 4: 'd', 5: 'e', 6: 'h', 7: 'l'}
REGS_16 = {0: 'wa', 1: 'bc', 2: 'de', 3: 'hl', 4: 'ix', 5: 'iy', 6: 'iz'}
REGS_32 = {0: 'xwa', 1: 'xbc', 2: 'xde', 3: 'xhl', 4: 'xix', 5: 'xiy', 6: 'xiz'}

ALU_OPS = {0: 'add', 1: 'adc', 2: 'sub', 3: 'sbc', 4: 'and', 5: 'xor', 6: 'or', 7: 'cp'}

# Cache for verification results
_verify_cache = {}


def verify_encoding(asm_line, expected_bytes):
    """Assemble an instruction and check if encoding matches expected bytes."""
    key = (asm_line, tuple(expected_bytes))
    if key in _verify_cache:
        return _verify_cache[key]

    result_val = False
    try:
        result = subprocess.run(
            [LLVM_MC, '--triple=tlcs900', '--show-encoding'],
            input=asm_line, capture_output=True, text=True, timeout=5
        )
        for line in result.stdout.splitlines():
            m = re.search(r'encoding: \[([^\]]+)\]', line)
            if m:
                enc_str = m.group(1)
                enc_bytes = [int(x.strip(), 16) for x in enc_str.split(',')]
                result_val = (enc_bytes == expected_bytes)
                break
    except:
        pass

    _verify_cache[key] = result_val
    return result_val


def format_mem_operand(base_reg, d16_lo, d16_hi):
    """Format a (reg+disp) memory operand."""
    disp = struct.unpack('<h', bytes([d16_lo, d16_hi]))[0]  # signed 16-bit
    if disp >= 0:
        return f'({base_reg}+{disp})'
    else:
        return f'({base_reg}{disp})'


def decode_source_8(byte_values, offset):
    """Decode C3-prefix (8-bit source) instruction at offset in byte_values."""
    if offset + 5 > len(byte_values):
        return None, 0

    mode = byte_values[offset + 1]
    if mode not in D16_MODE_BYTES:
        return None, 0

    base_reg = D16_MODE_BYTES[mode]
    mem = format_mem_operand(base_reg, byte_values[offset + 2], byte_values[offset + 3])
    opcode = byte_values[offset + 4]

    # LD reg8, (mem): 0x20-0x27
    if 0x20 <= opcode <= 0x27:
        return f'ld\t{REGS_8[opcode - 0x20]}, {mem}', 5

    # ALU reg8, (mem) - source: 0x80-0xF7 (bit 3 clear)
    if 0x80 <= opcode <= 0xF7 and not (opcode & 0x08):
        alu_idx = (opcode >> 4) - 8
        reg_idx = opcode & 0x07
        if alu_idx in ALU_OPS and reg_idx in REGS_8:
            return f'{ALU_OPS[alu_idx]}\t{REGS_8[reg_idx]}, {mem}', 5

    # ALU (mem), reg8 - dst: 0x88-0xFF (bit 3 set)
    if 0x88 <= opcode <= 0xFF and (opcode & 0x08):
        alu_idx = (opcode >> 4) - 8
        reg_idx = opcode & 0x07
        if alu_idx in ALU_OPS and reg_idx in REGS_8:
            return f'{ALU_OPS[alu_idx]}\t{mem}, {REGS_8[reg_idx]}', 5

    # ALU (mem), imm8: 0x38-0x3F + 1-byte imm
    if 0x38 <= opcode <= 0x3F and offset + 6 <= len(byte_values):
        alu_ops_imm = {0x38: 'add', 0x39: 'adc', 0x3A: 'sub', 0x3B: 'sbc',
                       0x3C: 'andmi8', 0x3D: 'xor', 0x3E: 'or', 0x3F: 'cp'}
        imm = byte_values[offset + 5]
        return f'{alu_ops_imm[opcode]}\t{mem}, {imm}', 6

    # LD (mem), imm8: 0x00 + 1-byte imm
    if opcode == 0x00 and offset + 6 <= len(byte_values):
        imm = byte_values[offset + 5]
        return f'ld\t{mem}, {imm}', 6

    return None, 0


def decode_source_16(byte_values, offset):
    """Decode D3-prefix (16-bit source) instruction."""
    if offset + 5 > len(byte_values):
        return None, 0

    mode = byte_values[offset + 1]
    if mode not in D16_MODE_BYTES:
        return None, 0

    base_reg = D16_MODE_BYTES[mode]
    mem = format_mem_operand(base_reg, byte_values[offset + 2], byte_values[offset + 3])
    opcode = byte_values[offset + 4]

    # LD reg16, (mem): 0x20-0x26
    if 0x20 <= opcode <= 0x26:
        reg = REGS_16.get(opcode - 0x20)
        if reg:
            return f'ld\t{reg}, {mem}', 5

    # ALU reg16, (mem) - source: bit 3 clear
    if 0x80 <= opcode <= 0xF6 and not (opcode & 0x08):
        alu_idx = (opcode >> 4) - 8
        reg_idx = opcode & 0x07
        if alu_idx in ALU_OPS and reg_idx in REGS_16:
            return f'{ALU_OPS[alu_idx]}\t{REGS_16[reg_idx]}, {mem}', 5

    # ALU (mem), reg16 - dst: bit 3 set
    if 0x88 <= opcode <= 0xFE and (opcode & 0x08):
        alu_idx = (opcode >> 4) - 8
        reg_idx = opcode & 0x07
        if alu_idx in ALU_OPS and reg_idx in REGS_16:
            return f'{ALU_OPS[alu_idx]}\t{mem}, {REGS_16[reg_idx]}', 5

    # ALU (mem), imm16: 0x38-0x3F + 2-byte imm
    if 0x38 <= opcode <= 0x3F and offset + 7 <= len(byte_values):
        alu_ops_imm = {0x38: 'add', 0x39: 'adc', 0x3A: 'sub', 0x3B: 'sbc',
                       0x3C: 'and', 0x3D: 'xor', 0x3E: 'or', 0x3F: 'cp'}
        alu = alu_ops_imm[opcode]
        # Use cpw for 16-bit cp/and with memory
        if alu == 'cp':
            alu = 'cpw'
        imm = struct.unpack('<H', bytes(byte_values[offset + 5:offset + 7]))[0]
        return f'{alu}\t{mem}, {imm}', 7

    # LD (mem), imm16: 0x02 + 2-byte imm
    if opcode == 0x02 and offset + 7 <= len(byte_values):
        imm = struct.unpack('<H', bytes(byte_values[offset + 5:offset + 7]))[0]
        return f'ldw\t{mem}, {imm}', 7

    return None, 0


def decode_source_32(byte_values, offset):
    """Decode E3-prefix (32-bit source) instruction."""
    if offset + 5 > len(byte_values):
        return None, 0

    mode = byte_values[offset + 1]
    if mode not in D16_MODE_BYTES:
        return None, 0

    base_reg = D16_MODE_BYTES[mode]
    mem = format_mem_operand(base_reg, byte_values[offset + 2], byte_values[offset + 3])
    opcode = byte_values[offset + 4]

    # LD xreg32, (mem): 0x20-0x26
    if 0x20 <= opcode <= 0x26:
        reg = REGS_32.get(opcode - 0x20)
        if reg:
            return f'ld\t{reg}, {mem}', 5

    # ALU xreg32, (mem) - source: bit 3 clear
    if 0x80 <= opcode <= 0xF6 and not (opcode & 0x08):
        alu_idx = (opcode >> 4) - 8
        reg_idx = opcode & 0x07
        if alu_idx in ALU_OPS and reg_idx in REGS_32:
            return f'{ALU_OPS[alu_idx]}\t{REGS_32[reg_idx]}, {mem}', 5

    # ALU (mem), xreg32 - dst: bit 3 set
    if 0x88 <= opcode <= 0xFE and (opcode & 0x08):
        alu_idx = (opcode >> 4) - 8
        reg_idx = opcode & 0x07
        if alu_idx in ALU_OPS and reg_idx in REGS_32:
            return f'{ALU_OPS[alu_idx]}\t{mem}, {REGS_32[reg_idx]}', 5

    return None, 0


def decode_dst_mem(byte_values, offset):
    """Decode F3-prefix (destination memory / store) instruction."""
    if offset + 5 > len(byte_values):
        return None, 0

    mode = byte_values[offset + 1]
    if mode not in D16_MODE_BYTES:
        return None, 0

    base_reg = D16_MODE_BYTES[mode]
    mem = format_mem_operand(base_reg, byte_values[offset + 2], byte_values[offset + 3])
    opcode = byte_values[offset + 4]

    # LD (mem), imm8: 0x00 + 1-byte imm
    if opcode == 0x00 and offset + 6 <= len(byte_values):
        imm = byte_values[offset + 5]
        return f'ld\t{mem}, {imm}', 6

    # LDW (mem), imm16: 0x02 + 2-byte imm
    if opcode == 0x02 and offset + 7 <= len(byte_values):
        imm = struct.unpack('<H', bytes(byte_values[offset + 5:offset + 7]))[0]
        return f'ldw\t{mem}, {imm}', 7

    # LDA xreg32, (mem): 0x30-0x36
    if 0x30 <= opcode <= 0x36:
        reg = REGS_32.get(opcode - 0x30)
        if reg:
            return f'lda\t{reg}, {mem}', 5

    # LD (mem), reg8: 0x40-0x47
    if 0x40 <= opcode <= 0x47:
        return f'ld\t{mem}, {REGS_8[opcode - 0x40]}', 5

    # LD (mem), reg16: 0x50-0x56
    if 0x50 <= opcode <= 0x56:
        reg = REGS_16.get(opcode - 0x50)
        if reg:
            return f'ld\t{mem}, {reg}', 5

    # LD (mem), xreg32: 0x60-0x66
    if 0x60 <= opcode <= 0x66:
        reg = REGS_32.get(opcode - 0x60)
        if reg:
            return f'ld\t{mem}, {reg}', 5

    return None, 0


DECODERS = {
    0xC3: decode_source_8,
    0xD3: decode_source_16,
    0xE3: decode_source_32,
    0xF3: decode_dst_mem,
}


def parse_byte_values(byte_str):
    """Parse .byte directive hex values -> list of ints."""
    code_part = byte_str.split(';')[0].strip()
    if not code_part.startswith('.byte'):
        return []
    hex_part = code_part[5:].strip()
    values = []
    for v in hex_part.split(','):
        v = v.strip()
        if v:
            try:
                values.append(int(v, 16) if v.lower().startswith('0x') else int(v))
            except ValueError:
                break
    return values


def format_byte_directive(byte_values):
    """Format byte values into .byte directive string."""
    return '.byte ' + ', '.join(f'0x{b:02x}' for b in byte_values)


def find_rd16_in_bytes(byte_values):
    """Find all R+d16 instructions in a byte sequence.
    Returns list of (offset, mnemonic, length) tuples, non-overlapping, left-to-right.
    """
    found = []
    pos = 0
    while pos < len(byte_values):
        b = byte_values[pos]
        if b in DECODERS:
            decoder = DECODERS[b]
            mnemonic, instr_len = decoder(byte_values, pos)
            if mnemonic and instr_len > 0:
                # Verify round-trip
                instr_bytes = byte_values[pos:pos + instr_len]
                if verify_encoding(mnemonic, instr_bytes):
                    found.append((pos, mnemonic, instr_len))
                    pos += instr_len
                    continue
                # Try with tab -> space
                mnemonic_notab = mnemonic.replace('\t', ' ')
                if verify_encoding(mnemonic_notab, instr_bytes):
                    found.append((pos, mnemonic, instr_len))
                    pos += instr_len
                    continue
        pos += 1
    return found


def process_file(filepath, dry_run=False):
    """Process a single .s file."""
    with open(filepath, 'rb') as f:
        lines = f.readlines()

    conversions = []
    modified = False
    new_lines = []

    for line_idx, line_bytes in enumerate(lines):
        line_str = line_bytes.decode('latin-1')
        stripped = line_str.strip()

        if not stripped.startswith('.byte'):
            new_lines.append(line_bytes)
            continue

        byte_values = parse_byte_values(stripped)
        if len(byte_values) < 5:
            new_lines.append(line_bytes)
            continue

        # Find all R+d16 patterns in this .byte line
        matches = find_rd16_in_bytes(byte_values)
        if not matches:
            new_lines.append(line_bytes)
            continue

        # Determine indentation
        indent = ''
        for ch in line_str:
            if ch in (' ', '\t'):
                indent += ch
            else:
                break

        # Build replacement lines: split around each match
        replacement_parts = []
        prev_end = 0
        for offset, mnemonic, instr_len in matches:
            # Bytes before this instruction
            if offset > prev_end:
                before = byte_values[prev_end:offset]
                replacement_parts.append(('bytes', before))
            # The native instruction
            replacement_parts.append(('mnemonic', mnemonic))
            prev_end = offset + instr_len

            conversions.append({
                'file': filepath,
                'line': line_idx + 1,
                'original': stripped,
                'mnemonic': mnemonic,
                'instr_bytes': byte_values[offset:offset + instr_len],
            })

        # Bytes after last instruction
        if prev_end < len(byte_values):
            after = byte_values[prev_end:]
            replacement_parts.append(('bytes', after))

        # Build replacement text
        replacement_lines = []
        for kind, data in replacement_parts:
            if kind == 'bytes':
                replacement_lines.append(indent + format_byte_directive(data) + '\n')
            else:
                replacement_lines.append(indent + data + '\n')

        new_lines.append(''.join(replacement_lines).encode('latin-1'))
        modified = True

    if modified and not dry_run:
        with open(filepath, 'wb') as f:
            f.writelines(new_lines)

    return conversions


def find_assembly_files():
    """Find all .s files in the repository."""
    files = []
    for dirpath, dirnames, filenames in os.walk(REPO_ROOT):
        if 'archive' in dirpath:
            continue
        for fn in filenames:
            if fn.endswith('.s'):
                files.append(os.path.join(dirpath, fn))
    return sorted(files)


def main():
    dry_run = '--dry-run' in sys.argv
    target_file = None
    for i, arg in enumerate(sys.argv):
        if arg == '--file' and i + 1 < len(sys.argv):
            target_file = sys.argv[i + 1]

    if target_file:
        files = [target_file]
    else:
        files = find_assembly_files()

    total_conversions = 0
    by_file = defaultdict(int)
    all_conversions = []

    for filepath in files:
        conversions = process_file(filepath, dry_run=dry_run)
        if conversions:
            for c in conversions:
                total_conversions += 1
                by_file[filepath] += 1
                all_conversions.append(c)

    # Print summary
    print(f"\n{'DRY RUN - ' if dry_run else ''}R+d16 .byte -> native conversion summary:")
    print(f"  Total conversions: {total_conversions}")
    print(f"  Files modified: {len(by_file)}")
    print()

    if by_file:
        print("Conversions by file:")
        for filepath, count in sorted(by_file.items(), key=lambda x: -x[1]):
            relpath = os.path.relpath(filepath, REPO_ROOT)
            print(f"  {relpath}: {count}")

    if dry_run and all_conversions:
        print(f"\nFirst 30 conversions (of {len(all_conversions)}):")
        for c in all_conversions[:30]:
            relpath = os.path.relpath(c['file'], REPO_ROOT)
            print(f"  {relpath}:{c['line']}")
            print(f"    FROM: {c['original'][:120]}")
            print(f"    TO:   {c['mnemonic']}")

    return total_conversions


if __name__ == '__main__':
    main()
