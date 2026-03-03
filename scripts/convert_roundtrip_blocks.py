#!/usr/bin/env python3
"""Convert .byte blocks that round-trip cleanly to native LLVM instructions.

For each .byte block:
1. Extract raw bytes
2. Disassemble with llvm-mc --triple=tlcs900 --disassemble
3. Re-assemble each instruction with llvm-mc --triple=tlcs900 --show-encoding
4. Compare re-assembled bytes to original
5. Apply code-quality heuristics to filter out data blocks
6. If all checks pass, replace .byte lines with native instruction lines

Uses binary I/O to safely handle Latin-1 characters.
"""

import re
import subprocess
import sys
import os

LLVM_MC = '/mnt/shared/llvm-project/build/bin/llvm-mc'
ENC_RE = re.compile(r'[;#] encoding: \[([^\]]+)\]')

# 1-byte "data-like" instructions that commonly appear when data is decoded
DATA_LIKE_OPS = {
    'nop', 'ccf', 'rcf', 'scf', 'zcf', 'ei', 'di', 'reti',
    'push_a', 'push_f', 'pop_a', 'pop_sr',
}

# Multi-byte code-like instructions (control flow, register ops)
CODE_LIKE_PREFIXES = {
    'call', 'calr', 'jp', 'jr', 'jrl', 'djnz',
    'ld', 'lda', 'ldb', 'ldw', 'lds',
    'cp', 'cps', 'cpw',
    'add', 'sub', 'and', 'or', 'xor',
    'inc', 'dec',
    'sla', 'sra', 'srl', 'sll', 'rl', 'rr',
    'mul', 'div',
    'push', 'pop', 'pushw',
    'bit', 'set', 'res',
    'extz', 'exts',
    'sti8_24', 'sti16_24',
    'ldda8', 'ldda16',
}


def is_code_block(instructions, raw_bytes):
    """Heuristic: is this a real code block or data misinterpreted as instructions?

    Real code blocks have:
    - Multi-byte instructions (avg instruction length > 1.5)
    - At least one control flow instruction (call/jp/jr/ret)
    - Not dominated by data-like 1-byte ops (nop/swi/ccf)
    """
    if not instructions:
        return False

    total_bytes = len(raw_bytes)
    num_insns = len(instructions)

    # Average instruction length
    avg_len = total_bytes / num_insns
    if avg_len < 1.5:
        return False  # Almost all 1-byte ops → likely data

    # Count code-like vs data-like instructions
    code_like = 0
    data_like = 0
    has_control_flow = False

    for inst in instructions:
        mnemonic = inst.split()[0] if inst.split() else ''

        if mnemonic in ('ret',):
            has_control_flow = True
            code_like += 1
        elif mnemonic in DATA_LIKE_OPS:
            data_like += 1
        elif mnemonic.startswith('swi'):
            data_like += 1
        elif any(mnemonic.startswith(p) for p in ('call', 'calr', 'jp', 'jr', 'jrl', 'djnz')):
            has_control_flow = True
            code_like += 1
        elif any(mnemonic.startswith(p) for p in CODE_LIKE_PREFIXES):
            code_like += 1
        elif mnemonic.startswith('push') or mnemonic.startswith('pop'):
            code_like += 1

    # Must have at least one control flow instruction
    if not has_control_flow:
        return False

    # Code-like instructions should dominate
    if code_like < num_insns * 0.3:
        return False

    # Data-like ops shouldn't dominate
    if data_like > num_insns * 0.5:
        return False

    return True


def disassemble(raw_bytes):
    """Disassemble bytes. Returns (instructions_list, warning_count)."""
    hex_str = ' '.join(f'0x{b:02x}' for b in raw_bytes)
    try:
        result = subprocess.run(
            [LLVM_MC, '--triple=tlcs900', '--disassemble'],
            input=hex_str, capture_output=True, text=True, timeout=10
        )
    except subprocess.TimeoutExpired:
        return None, 999
    warnings = result.stderr.count('warning: invalid instruction encoding')
    instructions = [l.strip() for l in result.stdout.strip().split('\n')
                    if l.strip() and not l.strip().startswith('.')]
    return instructions, warnings


def assemble_instruction(text):
    """Assemble a single instruction, return encoded bytes or None."""
    try:
        result = subprocess.run(
            [LLVM_MC, '--triple=tlcs900', '--show-encoding'],
            input=text + '\n', capture_output=True, text=True, timeout=10
        )
    except subprocess.TimeoutExpired:
        return None
    if result.returncode != 0:
        return None
    for line in result.stdout.split('\n'):
        m = ENC_RE.search(line)
        if m:
            try:
                return bytes(int(h.strip(), 16) for h in m.group(1).split(','))
            except ValueError:
                return None
    return None


def roundtrip_check(raw_bytes):
    """Check if a block round-trips AND looks like code.
    Returns (True, instructions) or (False, None)."""
    instructions, warnings = disassemble(raw_bytes)
    if warnings > 0 or not instructions:
        return False, None

    # Heuristic: reject data blocks
    if not is_code_block(instructions, raw_bytes):
        return False, None

    # Round-trip verify
    reassembled = b''
    for inst in instructions:
        encoded = assemble_instruction(inst)
        if encoded is None:
            return False, None
        reassembled += encoded

    if reassembled == raw_bytes:
        return True, instructions
    return False, None


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')

    min_bytes = int(sys.argv[1]) if len(sys.argv) > 1 else 10
    max_bytes = int(sys.argv[2]) if len(sys.argv) > 2 else 200
    dry_run = '--dry-run' in sys.argv

    # Read file
    with open(src, 'rb') as f:
        lines = f.read().decode('latin-1').split('\n')

    # Find all .byte blocks
    blocks = []
    current_bytes = []
    current_start = None
    current_line_indices = []
    current_label = None

    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.endswith(':') and not stripped.startswith('.') and not stripped.startswith(';'):
            current_label = stripped[:-1]
        if stripped.startswith('.byte '):
            byte_matches = re.findall(r'0x([0-9a-fA-F]{2})', stripped)
            if len(byte_matches) >= 3:
                if not current_bytes:
                    current_start = i
                current_bytes.extend([int(b, 16) for b in byte_matches])
                current_line_indices.append(i)
                continue

        if current_bytes and len(current_line_indices) >= 3:
            total = len(current_bytes)
            if min_bytes <= total <= max_bytes:
                blocks.append({
                    'start_idx': current_start,
                    'line_indices': current_line_indices[:],
                    'raw_bytes': bytes(current_bytes),
                    'label': current_label,
                })
        current_bytes = []
        current_line_indices = []

    print(f'Found {len(blocks)} blocks ({min_bytes}-{max_bytes}B, 3+ lines)')

    # Process blocks in reverse order (so line indices remain valid)
    converted_count = 0
    converted_bytes = 0

    for block in reversed(blocks):
        success, instructions = roundtrip_check(block['raw_bytes'])
        if not success:
            continue

        if dry_run:
            start_line = block['line_indices'][0] + 1
            end_line = block['line_indices'][-1] + 1
            print(f'  Would convert: Line {start_line}-{end_line} '
                  f'({len(block["raw_bytes"])}B, {len(instructions)} insns) '
                  f'near {block["label"]}')
            converted_count += 1
            converted_bytes += len(block['raw_bytes'])
            continue

        # Build replacement lines
        new_lines = []
        for inst in instructions:
            new_lines.append('\t' + inst)

        # Replace the .byte lines
        start = block['line_indices'][0]
        end = block['line_indices'][-1]
        lines[start:end + 1] = new_lines

        converted_count += 1
        converted_bytes += len(block['raw_bytes'])

    # Write back
    if converted_count > 0 and not dry_run:
        with open(src, 'wb') as f:
            f.write('\n'.join(lines).encode('latin-1'))

    mode = "DRY RUN: " if dry_run else ""
    print(f'\n{mode}Converted {converted_count} blocks ({converted_bytes} bytes)')


if __name__ == '__main__':
    main()
