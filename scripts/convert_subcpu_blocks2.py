#!/usr/bin/env python3
"""Convert two remaining subcpu .byte blocks to native instructions with documentation.

Block 1: LABEL_029E5B (280 bytes) - Audio channel dispatch table
  25 ret-terminated handler stubs. Each stub zero-extends registers,
  pushes a channel/parameter number (0-3), and calls a common handler via calr.
  3 initial entries redirect via jrl to alternate handlers.

Block 2: LABEL_031AA1 (152 bytes) - MIDI/tone command dispatcher
  Reads command bytes from structure at XIZ, dispatches to different handlers
  based on byte fields. Handles velocity, channel assignment, and note-on/off
  routing through various calr targets.

Uses the automated round-trip approach (disassemble + reassemble + verify)
since both blocks pass round-trip checks. Documentation comments are added manually.

Uses binary I/O to handle encoding safely.
"""

import re
import subprocess
import os

LLVM_MC = '/mnt/shared/llvm-project/build/bin/llvm-mc'
ENC_RE = re.compile(r'[;#] encoding: \[([^\]]+)\]')

# Documentation comments to insert before each label
DOCS = {
    'LABEL_029E5B': [
        '; --- AudioChannel_DispatchTable: 25 handler stubs for audio channel commands ---',
        '; Entry: WA = command parameter, BC = secondary parameter',
        '; Each stub: zero-extends WA/BC, pushes channel index (0-3),',
        '; calls a common audio handler via calr, then returns.',
        '; First 3 entries redirect via jrl to alternate handler routines.',
        '; Called from jump table indexed by HL.',
    ],
    'LABEL_031AA1': [
        '; --- ToneCmd_Dispatcher: Route tone/MIDI commands by type and channel ---',
        '; Entry: XIZ = pointer to command structure',
        ';   byte[0] = command type, byte[1] = note/key, byte[2] = velocity/flags',
        '; Dispatches to velocity handlers, channel assignment (BC=0-3),',
        '; note-on/off routing, and special command handlers.',
        '; Each dispatch path exits via jrl to common return.',
    ],
}


def disassemble(raw_bytes):
    """Disassemble bytes. Returns list of instruction strings."""
    hex_str = ' '.join(f'0x{b:02x}' for b in raw_bytes)
    result = subprocess.run(
        [LLVM_MC, '--triple=tlcs900', '--disassemble'],
        input=hex_str, capture_output=True, text=True, timeout=10
    )
    warnings = result.stderr.count('warning: invalid instruction encoding')
    if warnings > 0:
        return None
    instructions = [l.strip() for l in result.stdout.strip().split('\n')
                    if l.strip() and not l.strip().startswith('.')]
    return instructions


def verify_roundtrip(raw_bytes, instructions):
    """Verify that reassembled instructions match original bytes."""
    reassembled = b''
    for inst in instructions:
        result = subprocess.run(
            [LLVM_MC, '--triple=tlcs900', '--show-encoding'],
            input=inst + '\n', capture_output=True, text=True, timeout=10
        )
        if result.returncode != 0:
            return False
        for line in result.stdout.split('\n'):
            m = ENC_RE.search(line)
            if m:
                try:
                    reassembled += bytes(int(h.strip(), 16) for h in m.group(1).split(','))
                except ValueError:
                    return False
                break
        else:
            return False
    return reassembled == raw_bytes


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'subcpu', 'kn5000_subprogram_v142.s')

    with open(src, 'rb') as f:
        lines = f.read().decode('latin-1').split('\n')

    converted = 0

    for label, comments in DOCS.items():
        # Find label
        label_idx = None
        for i, line in enumerate(lines):
            if line.strip() == label + ':':
                label_idx = i
                break

        if label_idx is None:
            print(f'  WARNING: label {label} not found')
            continue

        # Find .byte block
        byte_start = None
        byte_end = None
        raw_bytes = []
        for i in range(label_idx + 1, min(label_idx + 100, len(lines))):
            stripped = lines[i].strip()
            if stripped.startswith('.byte '):
                if byte_start is None:
                    byte_start = i
                byte_end = i
                raw_bytes.extend(int(b, 16) for b in re.findall(r'0x([0-9a-fA-F]{2})', stripped))
            elif byte_start is not None:
                break

        if byte_start is None:
            print(f'  WARNING: no .byte block after {label}')
            continue

        raw = bytes(raw_bytes)
        instructions = disassemble(raw)
        if instructions is None:
            print(f'  WARNING: disassembly failed for {label}')
            continue

        if not verify_roundtrip(raw, instructions):
            print(f'  WARNING: round-trip failed for {label}')
            continue

        # Replace .byte block with instructions
        new_lines = ['\t' + inst for inst in instructions]
        lines[byte_start:byte_end + 1] = new_lines

        # Insert comments before label
        for j, comment in enumerate(comments):
            lines.insert(label_idx + j, comment)

        converted += 1
        print(f'  Converted {label}: {len(raw)}B -> {len(instructions)} instructions')

    with open(src, 'wb') as f:
        f.write('\n'.join(lines).encode('latin-1'))

    print(f'\nConverted {converted} blocks')


if __name__ == '__main__':
    main()
