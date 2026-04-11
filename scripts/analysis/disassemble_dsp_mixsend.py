#!/usr/bin/env python3
"""Split DSP_MixSendConfig_ExtData .byte block into labeled functions.

This 1395-byte block at subcpu address 0x30A0A contains 7 functions,
all mislabeled as a single "ExtData" block. MAME unidasm disassembly reveals:

  F1 (0x30A0A, 163B): DSP_RouteCoeffs_TypeA - Route DSP coefficients (table offsets 0x44-0x50)
  F2 (0x30AAD, 163B): DSP_RouteCoeffs_TypeB - Route DSP coefficients (table offsets 0x58-0x64)
  F3 (0x30B50, 67B):  DSP_CopyCoeffs_TypeA  - Copy coefficients (direct, offset 0x50)
  F4 (0x30B93, 67B):  DSP_CopyCoeffs_TypeB  - Copy coefficients (direct, offset 0x64)
  F5 (0x30BD6, 365B): DSP_VoiceCoeffRoute   - Voice-specific coefficient routing
  F6 (0x30D43, 430B): DSP_VoiceCoeffRoute2  - Voice coefficient routing (variant 2)
  F7 (0x30EF1, 140B): DSP_AlgoCoeffLookup   - Algorithm-based coefficient table lookup

All functions operate on DSP parameter tables at:
  0x041368: Voice allocation table (voice × 287 entries)
  0x045210: DSP coefficient output buffer
  0x045310: Base pointer for routing tables
  0x045314: Pointer to routing configuration structure
"""

import re


def parse_byte_values(text_block):
    """Extract all byte values from .byte and .ascii lines."""
    values = []
    for line in text_block.split('\n'):
        line = line.strip()
        if line.startswith('.byte'):
            # Parse hex values
            parts = line[5:].split(',')
            for p in parts:
                p = p.strip()
                if p.startswith('0x'):
                    values.append(int(p, 16))
        elif line.startswith('.ascii'):
            # Parse quoted string
            m = re.search(r'"([^"]*)"', line)
            if m:
                for ch in m.group(1):
                    values.append(ord(ch))
    return values


def format_bytes(byte_list, bytes_per_line=8):
    """Format a list of bytes as .byte lines."""
    lines = []
    for i in range(0, len(byte_list), bytes_per_line):
        chunk = byte_list[i:i+bytes_per_line]
        hex_vals = ', '.join(f'0x{b:02x}' for b in chunk)
        lines.append(f'\t.byte {hex_vals}')
    return '\n'.join(lines)


def main():
    filepath = '/home/fsanches/compartilhado/kn5000-roms-disasm/subcpu/kn5000_subprogram_v142.s'

    with open(filepath, 'rb') as f:
        text = f.read().decode('latin-1')

    # Find the DSP_MixSendConfig_ExtData block
    # It starts with the label and ends before the next labeled section
    start_marker = 'DSP_MixSendConfig_ExtData:\n'
    start_idx = text.find(start_marker)
    if start_idx < 0:
        print("ERROR: Could not find DSP_MixSendConfig_ExtData label!")
        return

    # Find the end: next label (line starting without tab/space, containing ':')
    block_start = start_idx + len(start_marker)

    # Collect all .byte/.ascii lines until we hit a non-.byte line
    lines_after = text[block_start:].split('\n')
    byte_lines = []
    for line in lines_after:
        stripped = line.strip()
        if stripped.startswith('.byte') or stripped.startswith('.ascii'):
            byte_lines.append(line)
        elif stripped == '':
            byte_lines.append(line)  # Keep blank lines for now
        else:
            break

    # Remove trailing blank lines
    while byte_lines and byte_lines[-1].strip() == '':
        byte_lines.pop()

    old_block_text = start_marker + '\n'.join(byte_lines)

    # Parse all bytes
    all_bytes = parse_byte_values('\n'.join(byte_lines))
    print(f"Parsed {len(all_bytes)} bytes from DSP_MixSendConfig_ExtData")

    if len(all_bytes) != 1395:
        print(f"WARNING: Expected 1395 bytes, got {len(all_bytes)}")
        # Try to continue anyway

    # Function boundaries (byte offsets within the block)
    # F1: 0x30A0A, 163 bytes (0 to 162)
    # F2: 0x30AAD, 163 bytes (163 to 325)
    # F3: 0x30B50, 67 bytes (326 to 392)
    # F4: 0x30B93, 67 bytes (393 to 459)
    # F5: 0x30BD6, 365 bytes (460 to 824)
    # F6: 0x30D43, 430 bytes (825 to 1254)
    # F7: 0x30EF1, 140 bytes (1255 to 1394)
    functions = [
        (0, 163, 'DSP_RouteCoeffs_TypeA',
         '; ----------------------------------------------------------------------------\n'
         '; DSP_RouteCoeffs_TypeA - Route DSP coefficients via type-A table\n'
         '; Entry: WA = voice parameter (masked to 7 bits)\n'
         ';        BC = channel/type packed (low 4 bits = channel, bits 6-7 = type)\n'
         '; Notes: 4-way dispatch based on type bits to select coefficient table\n'
         ';        Table offsets: 0x44/0x48/0x4C from routing config at (0x45314)\n'
         ';        Computes index: (channel << 7 + voice) * 2\n'
         ';        Copies 13 bytes from source to DSP buffer at 0x45210\n'
         '; ----------------------------------------------------------------------------'),
        (163, 163, 'DSP_RouteCoeffs_TypeB',
         '; ----------------------------------------------------------------------------\n'
         '; DSP_RouteCoeffs_TypeB - Route DSP coefficients via type-B table\n'
         '; Entry: Same as TypeA\n'
         '; Notes: Same algorithm as TypeA with different table offsets (0x58-0x64)\n'
         '; ----------------------------------------------------------------------------'),
        (326, 67, 'DSP_CopyCoeffs_TypeA',
         '; ----------------------------------------------------------------------------\n'
         '; DSP_CopyCoeffs_TypeA - Direct coefficient copy (type A)\n'
         '; Entry: WA = voice parameter\n'
         '; Notes: Direct copy without 4-way dispatch, uses offset 0x50\n'
         ';        Copies 13 bytes from source to DSP buffer at 0x45210\n'
         '; ----------------------------------------------------------------------------'),
        (393, 67, 'DSP_CopyCoeffs_TypeB',
         '; ----------------------------------------------------------------------------\n'
         '; DSP_CopyCoeffs_TypeB - Direct coefficient copy (type B)\n'
         '; Entry: WA = voice parameter\n'
         '; Notes: Direct copy without 4-way dispatch, uses offset 0x64\n'
         ';        Copies 13 bytes from source to DSP buffer at 0x45210\n'
         '; ----------------------------------------------------------------------------'),
        (460, 365, 'DSP_VoiceCoeffRoute',
         '; ----------------------------------------------------------------------------\n'
         '; DSP_VoiceCoeffRoute - Voice-specific coefficient routing\n'
         '; Entry: A = voice number, C = channel (low 4 bits)\n'
         '; Notes: Looks up voice allocation at 0x41368 (voice * 287 + chan * 37 + 110)\n'
         ';        Reads routing type from allocation entry byte 2 (bits 6-7)\n'
         ';        4-way dispatch to select coefficient source table\n'
         ';        Copies 13 coefficient bytes + 3 extra config bytes\n'
         ';        Extra bytes: voice DE value (low, 0x00, high >> 8)\n'
         '; ----------------------------------------------------------------------------'),
        (825, 430, 'DSP_VoiceCoeffRoute2',
         '; ----------------------------------------------------------------------------\n'
         '; DSP_VoiceCoeffRoute2 - Voice coefficient routing (variant 2)\n'
         '; Entry: A = voice number, C = channel/type packed\n'
         '; Notes: Similar to DSP_VoiceCoeffRoute but extracts both channel\n'
         ';        and type from C (low 4 = channel, high 4 >> 4 = type)\n'
         ';        Uses prevbank registers (D7 prefix) for extended operations\n'
         ';        Multiple nested table lookups with different coefficient sets\n'
         ';        Includes filter and vibrato coefficient routing\n'
         '; ----------------------------------------------------------------------------'),
        (1255, 140, 'DSP_AlgoCoeffLookup',
         '; ----------------------------------------------------------------------------\n'
         '; DSP_AlgoCoeffLookup - Algorithm-based coefficient table lookup\n'
         '; Entry: A = algorithm number (0-4)\n'
         '; Notes: 5-way dispatch based on algorithm (0-4) to select table\n'
         ';        Tables at config offsets: 0x54, 0x70, 0x7C, 0x88-0x98\n'
         ';        Reads entry count from byte 2 of selected table entry\n'
         ';        Copies coefficient data to DSP buffer at 0x45210\n'
         '; ----------------------------------------------------------------------------'),
    ]

    # Build the new block
    parts = []
    for offset, length, label, comment in functions:
        func_bytes = all_bytes[offset:offset+length]
        parts.append(comment)
        parts.append(f'{label}:')
        parts.append(format_bytes(func_bytes))

    new_block = '\n'.join(parts)

    # Replace the old block
    if old_block_text not in text:
        print("ERROR: Could not match old block text for replacement!")
        print(f"Looking for block starting at index {start_idx}")
        # Debug: show first 200 chars of what we're looking for
        print(f"Old block starts with: {repr(old_block_text[:200])}")
        return

    text = text.replace(old_block_text, new_block)

    # Update symbol reference file
    sympath = '/home/fsanches/compartilhado/kn5000-roms-disasm/symbols/subcpu_symbols_reference.txt'
    with open(sympath, 'rb') as f:
        symtext = f.read().decode('latin-1')

    # Rename the label
    symtext = re.sub(r'\bDSP_MixSendConfig_ExtData\b', 'DSP_RouteCoeffs_TypeA', symtext)

    with open(filepath, 'wb') as f:
        f.write(text.encode('latin-1'))

    with open(sympath, 'wb') as f:
        f.write(symtext.encode('latin-1'))

    print(f"{filepath}: DSP_MixSendConfig_ExtData split into 7 labeled functions")
    print(f"Functions: {', '.join(f[2] for f in functions)}")


if __name__ == '__main__':
    main()
