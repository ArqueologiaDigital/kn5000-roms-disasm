#!/usr/bin/env python3
"""Convert annotated .byte lines to native LLVM instructions.

Many single-line .byte entries in the source have manual comments describing
the instruction they encode (e.g., "; sla 2, wa [not in LLVM]" or
"; ld hl, (0x01F26B) [D2 prefix]"). These were kept as .byte because the
LLVM backend couldn't assemble them at the time.

This script finds such annotated .byte lines, verifies they round-trip
correctly through llvm-mc, and replaces them with native instructions.

Safety filters:
- Only converts .byte lines that have a semicolon comment
- Skips any that decode to data-like instructions (nop, swi, halt, etc.)
- Skips any that fail round-trip verification
- Skips any that decode to multiple instructions (single-instruction only)

Uses binary I/O to handle Latin-1 encoding safely.
"""

import re
import subprocess
import sys
import os

LLVM_MC = '/mnt/shared/llvm-project/build/bin/llvm-mc'
ENC_RE = re.compile(r'[;#] encoding: \[([^\]]+)\]')

# Data-like single-byte ops that indicate data, not code
DATA_OPS = {'nop', 'ccf', 'rcf', 'scf', 'zcf', 'ei', 'di', 'halt',
            'push_a', 'push_f', 'pop_a', 'pop_sr', 'incf', 'ex_ff'}


def disassemble_and_roundtrip(raw_bytes):
    """Disassemble bytes and verify round-trip. Returns instruction string or None."""
    hex_str = ' '.join(f'0x{b:02x}' for b in raw_bytes)
    try:
        r = subprocess.run(
            [LLVM_MC, '--triple=tlcs900', '--disassemble'],
            input=hex_str, capture_output=True, text=True, timeout=5
        )
    except subprocess.TimeoutExpired:
        return None

    if r.stderr.count('warning') > 0:
        return None

    instructions = [l.strip() for l in r.stdout.strip().split('\n')
                    if l.strip() and not l.strip().startswith('.')]
    if not instructions:
        return None

    # Only convert single-instruction .byte lines
    if len(instructions) > 1:
        return None

    inst = instructions[0]
    mnemonic = inst.split()[0] if inst.split() else ''

    # Skip data-like instructions
    if mnemonic in DATA_OPS or mnemonic.startswith('swi'):
        return None

    # Round-trip verify
    try:
        r2 = subprocess.run(
            [LLVM_MC, '--triple=tlcs900', '--show-encoding'],
            input=inst + '\n', capture_output=True, text=True, timeout=5
        )
    except subprocess.TimeoutExpired:
        return None

    if r2.returncode != 0:
        return None

    for line in r2.stdout.split('\n'):
        m = ENC_RE.search(line)
        if m:
            try:
                reassembled = bytes(int(h.strip(), 16) for h in m.group(1).split(','))
            except ValueError:
                return None
            if reassembled == raw_bytes:
                return inst
            return None

    return None


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')

    dry_run = '--dry-run' in sys.argv

    with open(src, 'rb') as f:
        lines = f.read().decode('latin-1').split('\n')

    converted = 0
    converted_bytes = 0

    for i in range(len(lines)):
        stripped = lines[i].strip()
        if not stripped.startswith('.byte '):
            continue

        # Must have a comment
        if ';' not in stripped:
            continue

        # Extract bytes (only from the part before the comment)
        byte_part = stripped.split(';')[0]
        bytes_m = re.findall(r'0x([0-9a-fA-F]{2})', byte_part)
        if len(bytes_m) < 2:
            continue

        raw = bytes(int(b, 16) for b in bytes_m)

        # Try to convert
        inst = disassemble_and_roundtrip(raw)
        if inst is None:
            continue

        if dry_run:
            print(f'  Would convert line {i+1}: {stripped[:70]:70s} -> {inst}')
            converted += 1
            converted_bytes += len(raw)
            continue

        # Preserve indentation (use tab like native instructions)
        lines[i] = '\t' + inst
        converted += 1
        converted_bytes += len(raw)

    if converted > 0 and not dry_run:
        with open(src, 'wb') as f:
            f.write('\n'.join(lines).encode('latin-1'))

    mode = "DRY RUN: " if dry_run else ""
    print(f'\n{mode}Converted {converted} annotated .byte lines ({converted_bytes} bytes)')


if __name__ == '__main__':
    main()
