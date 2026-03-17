#!/usr/bin/env python3
"""Split DSP_SetCoeff_ExtData into labeled functions.

This 2088-byte block at subcpu address 0x3122F contains 8 DSP coefficient
setup functions, all operating on the coefficient tables at 0x045210-0x045314.
"""

import re


def parse_byte_values(text_block):
    values = []
    for line in text_block.split('\n'):
        line = line.strip()
        if line.startswith('.byte'):
            parts = line[5:].split(',')
            for p in parts:
                p = p.strip()
                if p.startswith('0x'):
                    values.append(int(p, 16))
        elif line.startswith('.ascii'):
            m = re.search(r'"([^"]*)"', line)
            if m:
                for ch in m.group(1):
                    values.append(ord(ch))
    return values


def format_bytes(byte_list, bytes_per_line=8):
    lines = []
    for i in range(0, len(byte_list), bytes_per_line):
        chunk = byte_list[i:i+bytes_per_line]
        hex_vals = ', '.join(f'0x{b:02x}' for b in chunk)
        lines.append(f'\t.byte {hex_vals}')
    return '\n'.join(lines)


def extract_byte_block(text, label):
    marker = label + ':\n'
    idx = text.find(marker)
    if idx < 0:
        return None, None
    block_start = idx + len(marker)
    lines_after = text[block_start:].split('\n')
    byte_lines = []
    for line in lines_after:
        stripped = line.strip()
        if stripped.startswith('.byte') or stripped.startswith('.ascii'):
            byte_lines.append(line)
        elif stripped == '':
            continue
        else:
            break
    block_text = marker + '\n'.join(byte_lines)
    byte_values = parse_byte_values('\n'.join(byte_lines))
    return block_text, byte_values


def main():
    filepath = '/mnt/shared/kn5000-roms-disasm/subcpu/kn5000_subprogram_v142.s'

    with open(filepath, 'rb') as f:
        text = f.read().decode('latin-1')

    old_block, all_bytes = extract_byte_block(text, 'DSP_SetCoeff_ExtData')
    if not old_block:
        print("ERROR: Could not find DSP_SetCoeff_ExtData!")
        return
    print(f"DSP_SetCoeff_ExtData: {len(all_bytes)} bytes")
    if len(all_bytes) != 2088:
        print(f"WARNING: Expected 2088 bytes, got {len(all_bytes)}")

    functions = [
        (0, 69, 'DSP_SetCoeff_CopyDirect',
         '; ----------------------------------------------------------------------------\n'
         '; DSP_SetCoeff_CopyDirect - Copy coefficients directly to DSP buffer\n'
         '; Notes: Reads routing config from (0x45314), adds base from (0x45310)\n'
         ';        Copies to DSP coefficient buffer at 0x45210\n'
         '; ----------------------------------------------------------------------------'),
        (69, 344, 'DSP_SetCoeff_RouteComplex',
         '; ----------------------------------------------------------------------------\n'
         '; DSP_SetCoeff_RouteComplex - Complex coefficient routing with table lookup\n'
         '; Notes: Multiple table lookups via (0x45314) and (0x45310)\n'
         ';        Extended routing with coefficient transformation\n'
         ';        Writes to coefficient buffer at 0x45210\n'
         '; ----------------------------------------------------------------------------'),
        (413, 69, 'DSP_SetCoeff_CopyDirect2',
         '; ----------------------------------------------------------------------------\n'
         '; DSP_SetCoeff_CopyDirect2 - Copy coefficients directly (variant 2)\n'
         '; Notes: Same pattern as DSP_SetCoeff_CopyDirect with different offsets\n'
         '; ----------------------------------------------------------------------------'),
        (482, 291, 'DSP_SetCoeff_RouteWithCallback',
         '; ----------------------------------------------------------------------------\n'
         '; DSP_SetCoeff_RouteWithCallback - Coefficient routing with callback function\n'
         '; Notes: Calls 0x032AE0 for parameter transformation\n'
         ';        Routes coefficients via (0x45314) tables\n'
         ';        Uses (0x45310) base for address computation\n'
         '; ----------------------------------------------------------------------------'),
        (773, 384, 'DSP_SetCoeff_FullPipeline',
         '; ----------------------------------------------------------------------------\n'
         '; DSP_SetCoeff_FullPipeline - Full coefficient setup pipeline\n'
         '; Notes: Largest coefficient setup function (384 bytes)\n'
         ';        Calls 0x032AE0 and 0x032682 for multi-stage processing\n'
         ';        Full routing table lookup chain via (0x45314)/(0x45310)\n'
         ';        Writes computed coefficients to DSP buffer at 0x45210\n'
         '; ----------------------------------------------------------------------------'),
        (1157, 135, 'DSP_SetCoeff_WithDispatch',
         '; ----------------------------------------------------------------------------\n'
         '; DSP_SetCoeff_WithDispatch - Coefficient setup with type dispatch\n'
         '; Notes: Loads from (0x45314), dispatches by routing type\n'
         ';        Copies coefficients to DSP buffer at 0x45210\n'
         '; ----------------------------------------------------------------------------'),
        (1292, 90, 'DSP_SetCoeff_WriteParams',
         '; ----------------------------------------------------------------------------\n'
         '; DSP_SetCoeff_WriteParams - Write individual coefficient parameters\n'
         '; Notes: Writes directly to DSP coefficient bytes at 0x045216/0x045217\n'
         ';        Handles special parameter formatting\n'
         '; ----------------------------------------------------------------------------'),
        (1382, 706, 'DSP_SetCoeff_MasterConfig',
         '; ----------------------------------------------------------------------------\n'
         '; DSP_SetCoeff_MasterConfig - Master coefficient configuration routine\n'
         '; Notes: Largest DSP coefficient function (706 bytes)\n'
         ';        References 0x045216 (coefficient buffer) extensively\n'
         ';        Calls 0x02B014 for coefficient computation\n'
         ';        Full DSP state setup with all coefficient types\n'
         ';        Writes to coefficient output table at 0x45210\n'
         '; ----------------------------------------------------------------------------'),
    ]

    # Verify total
    total = sum(f[1] for f in functions)
    if total != len(all_bytes):
        print(f"ERROR: Function sizes sum to {total}, expected {len(all_bytes)}")
        return

    parts = []
    for offset, length, label, comment in functions:
        func_bytes = all_bytes[offset:offset+length]
        parts.append(comment)
        parts.append(f'{label}:')
        parts.append(format_bytes(func_bytes))
    new_block = '\n'.join(parts)

    if old_block not in text:
        print("ERROR: Could not match old block!")
        return
    text = text.replace(old_block, new_block)

    # Update symbol reference
    sympath = '/mnt/shared/kn5000-roms-disasm/symbols/subcpu_symbols_reference.txt'
    with open(sympath, 'rb') as f:
        symtext = f.read().decode('latin-1')
    symtext = re.sub(r'\bDSP_SetCoeff_ExtData\b', 'DSP_SetCoeff_CopyDirect', symtext)

    with open(filepath, 'wb') as f:
        f.write(text.encode('latin-1'))
    with open(sympath, 'wb') as f:
        f.write(symtext.encode('latin-1'))

    print(f"  -> Split into {len(functions)} labeled functions")
    print("Verify with: make rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom")


if __name__ == '__main__':
    main()
