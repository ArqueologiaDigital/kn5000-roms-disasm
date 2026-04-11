#!/usr/bin/env python3
"""Split Voice_DSP_InlineData and DSP_VoiceParam_ExtData into labeled functions.

Voice_DSP_InlineData (656 bytes at 0x27CE4) contains 4 functions:
  F1 (237B): Voice_DSP_OutputConfig    - Configure voice→DSP output routing (type 1)
  F2 (237B): Voice_DSP_OutputConfig2   - Configure voice→DSP output routing (type 2)
  F3 (91B):  Voice_DSP_SimpleCopy      - Simple voice→DSP parameter copy (type 1)
  F4 (91B):  Voice_DSP_SimpleCopy2     - Simple voice→DSP parameter copy (type 2)

DSP_VoiceParam_ExtData (155 bytes at 0x3107F) contains 1 function:
  F1 (155B): DSP_VoiceParam_ReadWrite2 - Voice parameter read/write with bit-5 dispatch
"""

import re


def parse_byte_values(text_block):
    """Extract all byte values from .byte and .ascii lines."""
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
    """Format a list of bytes as .byte lines."""
    lines = []
    for i in range(0, len(byte_list), bytes_per_line):
        chunk = byte_list[i:i+bytes_per_line]
        hex_vals = ', '.join(f'0x{b:02x}' for b in chunk)
        lines.append(f'\t.byte {hex_vals}')
    return '\n'.join(lines)


def extract_byte_block(text, label):
    """Extract the .byte block after a label, returning (block_text, byte_values)."""
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
    filepath = '/home/fsanches/compartilhado/kn5000-roms-disasm/subcpu/kn5000_subprogram_v142.s'

    with open(filepath, 'rb') as f:
        text = f.read().decode('latin-1')

    # === Voice_DSP_InlineData (656 bytes, 4 functions) ===
    old_vdi, vdi_bytes = extract_byte_block(text, 'Voice_DSP_InlineData')
    if not old_vdi:
        print("ERROR: Could not find Voice_DSP_InlineData!")
        return
    print(f"Voice_DSP_InlineData: {len(vdi_bytes)} bytes")
    if len(vdi_bytes) != 656:
        print(f"WARNING: Expected 656 bytes, got {len(vdi_bytes)}")

    vdi_functions = [
        (0, 237, 'Voice_DSP_OutputConfig',
         '; ----------------------------------------------------------------------------\n'
         '; Voice_DSP_OutputConfig - Configure voice-to-DSP output routing\n'
         '; Entry: A = voice number, C = channel\n'
         '; Notes: Calls DSP_AlgoType_Dispatch1 for algorithm type lookup\n'
         ';        Stores result to DSP state at 0x04520E\n'
         ';        Iterates voice output list via Voice_BuildOutputList\n'
         ';        Configures tone generator params via ToneGen_ExtParams56b_DataTable\n'
         ';        Two-pass: first updates 0x04520E, then 0x04520C\n'
         '; ----------------------------------------------------------------------------'),
        (237, 237, 'Voice_DSP_OutputConfig2',
         '; ----------------------------------------------------------------------------\n'
         '; Voice_DSP_OutputConfig2 - Configure voice-to-DSP output routing (type 2)\n'
         '; Entry: A = voice number, C = channel\n'
         '; Notes: Same algorithm as Voice_DSP_OutputConfig with different table offsets\n'
         '; ----------------------------------------------------------------------------'),
        (474, 91, 'Voice_DSP_SimpleCopy',
         '; ----------------------------------------------------------------------------\n'
         '; Voice_DSP_SimpleCopy - Simple voice-to-DSP parameter copy\n'
         '; Entry: A = voice number\n'
         '; Notes: Calls DSP function at 0x033B8B, stores to 0x045204\n'
         ';        Iterates voice output list (max 64 entries)\n'
         '; ----------------------------------------------------------------------------'),
        (565, 91, 'Voice_DSP_SimpleCopy2',
         '; ----------------------------------------------------------------------------\n'
         '; Voice_DSP_SimpleCopy2 - Simple voice-to-DSP parameter copy (type 2)\n'
         '; Entry: A = voice number\n'
         '; Notes: Same algorithm as Voice_DSP_SimpleCopy with different offsets\n'
         '; ----------------------------------------------------------------------------'),
    ]

    parts = []
    for offset, length, label, comment in vdi_functions:
        func_bytes = vdi_bytes[offset:offset+length]
        parts.append(comment)
        parts.append(f'{label}:')
        parts.append(format_bytes(func_bytes))
    new_vdi = '\n'.join(parts)

    if old_vdi not in text:
        print("ERROR: Could not match Voice_DSP_InlineData block!")
        return
    text = text.replace(old_vdi, new_vdi)
    print("  -> Split into 4 labeled functions")

    # === DSP_VoiceParam_ExtData (155 bytes, 1 function) ===
    old_vpe, vpe_bytes = extract_byte_block(text, 'DSP_VoiceParam_ExtData')
    if not old_vpe:
        print("ERROR: Could not find DSP_VoiceParam_ExtData!")
        return
    print(f"DSP_VoiceParam_ExtData: {len(vpe_bytes)} bytes")
    if len(vpe_bytes) != 155:
        print(f"WARNING: Expected 155 bytes, got {len(vpe_bytes)}")

    new_vpe = (
        '; ----------------------------------------------------------------------------\n'
        '; DSP_VoiceParam_Dispatch - Voice parameter dispatch with routing type check\n'
        '; Entry: WA = voice parameter, BC = channel/type, XDE = data pointer\n'
        '; Notes: Checks bit 5 of IX (from BC) for routing mode dispatch\n'
        ';        If bit 5 set: uses alternate routing path\n'
        ';        Otherwise: masks WA to 7 bits, extracts HL from BC bits 4:0,\n'
        ';        uses 4-way dispatch on BC bits 7:6 for coefficient table selection\n'
        ';        Computes routing index and copies parameters\n'
        '; ----------------------------------------------------------------------------\n'
        'DSP_VoiceParam_Dispatch:\n'
        + format_bytes(vpe_bytes)
    )

    if old_vpe not in text:
        print("ERROR: Could not match DSP_VoiceParam_ExtData block!")
        return
    text = text.replace(old_vpe, new_vpe)
    print("  -> Renamed to DSP_VoiceParam_Dispatch with documentation")

    # Update symbol reference file
    sympath = '/home/fsanches/compartilhado/kn5000-roms-disasm/symbols/subcpu_symbols_reference.txt'
    with open(sympath, 'rb') as f:
        symtext = f.read().decode('latin-1')

    renames = {
        'Voice_DSP_InlineData': 'Voice_DSP_OutputConfig',
        'DSP_VoiceParam_ExtData': 'DSP_VoiceParam_Dispatch',
    }
    for old, new in renames.items():
        symtext = re.sub(r'\b' + re.escape(old) + r'\b', new, symtext)

    with open(filepath, 'wb') as f:
        f.write(text.encode('latin-1'))
    with open(sympath, 'wb') as f:
        f.write(symtext.encode('latin-1'))

    print("Done. Verify with: make rebuilt_ROMs/kn5000_subprogram_v142.llvm.rom")


if __name__ == '__main__':
    main()
