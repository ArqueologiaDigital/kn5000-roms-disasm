#!/usr/bin/env python3
"""Find .byte blocks that can be round-trip converted to native LLVM instructions.

For each .byte block:
1. Extract raw bytes
2. Disassemble with llvm-mc --triple=tlcs900 --disassemble
3. Re-assemble each instruction with llvm-mc --triple=tlcs900 --show-encoding
4. Compare re-assembled bytes to original
5. Report blocks where ALL instructions round-trip successfully

These are safe candidates for .byte → native instruction conversion.
"""

import re
import subprocess
import sys
import os

LLVM_MC = '/mnt/shared/llvm-project/build/bin/llvm-mc'


def extract_byte_blocks(filepath):
    """Extract all consecutive .byte blocks from the file."""
    with open(filepath, 'rb') as f:
        lines = f.read().decode('latin-1').split('\n')

    blocks = []
    current_bytes = []
    current_start = None
    current_lines = []
    current_label = None

    for i, line in enumerate(lines):
        stripped = line.strip()

        # Track labels
        if stripped.endswith(':') and not stripped.startswith('.') and not stripped.startswith(';'):
            current_label = stripped[:-1]

        if stripped.startswith('.byte '):
            byte_matches = re.findall(r'0x([0-9a-fA-F]{2})', stripped)
            if len(byte_matches) >= 3:
                if not current_bytes:
                    current_start = i + 1  # 1-indexed
                current_bytes.extend([int(b, 16) for b in byte_matches])
                current_lines.append(i + 1)
                continue

        # End of block
        if current_bytes and len(current_lines) >= 3 and len(current_bytes) >= 10:
            blocks.append({
                'start_line': current_start,
                'end_line': current_lines[-1],
                'num_lines': len(current_lines),
                'total_bytes': len(current_bytes),
                'raw_bytes': bytes(current_bytes),
                'label': current_label,
                'line_numbers': current_lines,
            })
        current_bytes = []
        current_lines = []

    return blocks


def disassemble(raw_bytes):
    """Disassemble bytes using llvm-mc. Returns list of (instruction_text, byte_count) or None on failure."""
    hex_str = ' '.join(f'0x{b:02x}' for b in raw_bytes)
    try:
        result = subprocess.run(
            [LLVM_MC, '--triple=tlcs900', '--disassemble'],
            input=hex_str, capture_output=True, text=True, timeout=10
        )
    except subprocess.TimeoutExpired:
        return None

    # Count warnings (invalid instruction encoding)
    warnings = result.stderr.count('warning: invalid instruction encoding')

    # Parse instructions from stdout
    instructions = []
    for line in result.stdout.strip().split('\n'):
        line = line.strip()
        if line and not line.startswith('.'):
            instructions.append(line)

    return instructions, warnings


def assemble_instruction(text):
    """Assemble a single instruction, return the encoded bytes or None."""
    try:
        result = subprocess.run(
            [LLVM_MC, '--triple=tlcs900', '--show-encoding'],
            input=text + '\n', capture_output=True, text=True, timeout=10
        )
    except subprocess.TimeoutExpired:
        return None

    if result.returncode != 0:
        return None

    # Parse encoding from output like: "ret  # encoding: [0x0e]"
    for line in result.stdout.split('\n'):
        m = re.search(r'# encoding: \[([^\]]+)\]', line)
        if m:
            hex_parts = m.group(1).split(',')
            try:
                return bytes(int(h.strip(), 16) for h in hex_parts)
            except ValueError:
                return None

    return None


def roundtrip_block(block):
    """Try to round-trip a block. Returns (success, instructions, issues)."""
    result = disassemble(block['raw_bytes'])
    if result is None:
        return False, [], ['disassembly failed']

    instructions, warnings = result
    if warnings > 0:
        return False, instructions, [f'{warnings} disassembly warnings']

    if not instructions:
        return False, [], ['no instructions decoded']

    # Try to re-assemble each instruction and collect bytes
    reassembled = b''
    issues = []
    good_instructions = []

    for inst in instructions:
        encoded = assemble_instruction(inst)
        if encoded is None:
            issues.append(f'cannot assemble: {inst}')
            return False, instructions, issues
        reassembled += encoded
        good_instructions.append((inst, encoded))

    # Compare reassembled bytes to original
    original = block['raw_bytes']
    if reassembled == original:
        return True, good_instructions, []
    elif len(reassembled) != len(original):
        issues.append(f'length mismatch: {len(reassembled)} vs {len(original)}')
        return False, good_instructions, issues
    else:
        # Find first mismatch
        for i, (a, b) in enumerate(zip(reassembled, original)):
            if a != b:
                issues.append(f'byte mismatch at offset {i}: got 0x{a:02x} vs expected 0x{b:02x}')
                break
        return False, good_instructions, issues


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')

    min_bytes = int(sys.argv[1]) if len(sys.argv) > 1 else 10
    max_bytes = int(sys.argv[2]) if len(sys.argv) > 2 else 500

    print(f'Scanning for .byte blocks ({min_bytes}-{max_bytes} bytes)...')
    blocks = extract_byte_blocks(src)

    # Filter by size
    blocks = [b for b in blocks if min_bytes <= b['total_bytes'] <= max_bytes]
    print(f'Found {len(blocks)} blocks in size range')

    success_count = 0
    success_bytes = 0
    success_blocks = []

    for i, block in enumerate(blocks):
        success, instructions, issues = roundtrip_block(block)
        if success:
            success_count += 1
            success_bytes += block['total_bytes']
            success_blocks.append(block)
            inst_count = len(instructions)
            print(f'  OK  Line {block["start_line"]:6d} ({block["total_bytes"]:4d}B, {inst_count:3d} insns) near {block["label"]}')

        # Progress indicator every 100 blocks
        if (i + 1) % 200 == 0:
            print(f'  ... processed {i + 1}/{len(blocks)} blocks ...')

    print(f'\n=== Summary ===')
    print(f'Blocks tested: {len(blocks)}')
    print(f'Blocks that round-trip: {success_count}')
    print(f'Total convertible bytes: {success_bytes}')

    # Print the top candidates
    if success_blocks:
        print(f'\nTop candidates by size:')
        success_blocks.sort(key=lambda b: -b['total_bytes'])
        for b in success_blocks[:50]:
            print(f'  Line {b["start_line"]:6d}-{b["end_line"]:6d} ({b["total_bytes"]:4d}B, {b["num_lines"]:3d}L) near {b["label"]}')


if __name__ == '__main__':
    main()
