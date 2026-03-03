#!/usr/bin/env python3
"""Rename LABEL_* to semantic names for DSP helper routines in subcpu (037-038 range).

Based on analysis of the 0x037000-0x038FFF address range in the SubCPU
audio DSP subsystem. Each rename was verified by analyzing the routine's
code, register usage, called functions, and callers.

Uses binary I/O to handle encoding safely.
"""

import os
import re

# Renames: (old_label, new_label, brief_comment)
RENAMES = [
    # 037xxx - EFF state init
    ('LABEL_03701A', 'EFF_DspChannel_InitFlags',
     'Loop 5 EFF slots, write active-channel flags to DSP state tables'),

    # 038xxx - DSP hardware write primitives
    ('LABEL_038405', 'DSP_WriteParamWord',
     'Send 16-bit value as 2 bytes to DSP chip via DSP_DispatchData'),
    ('LABEL_038439', 'DSP_WriteParamCmd30',
     'Send cmd 0x30 + 1-byte field + 16-bit data to DSP chip'),
    ('LABEL_03846C', 'DSP_WriteFreqParam_AlgoType',
     'Write 10-byte freq packet with algo-type-selected params'),
    ('LABEL_038539', 'DSP_WriteFreqParam',
     'Write 10-byte freq packet (standard single-table variant)'),
    ('LABEL_038606', 'DSP_WriteCoeffData_5B',
     'Send 5-byte coefficient packet (suffix 0x15) in sequence'),
    ('LABEL_038675', 'DSP_UnpackParam3B',
     'Read 3 packed bytes, assemble 16-bit value, advance iterator'),
    ('LABEL_03869B', 'DSP_WriteLUTParamSet',
     'Write full LUT param set: 1x freq + 3x coeff per entry'),
    ('LABEL_0387E6', 'DSP_WriteOscParam',
     'Write 10-byte oscillator param packet with cmd 0x21'),
    ('LABEL_0388B3', 'DSP_WriteCoeffData_5B_Direct',
     'Send standalone 5-byte coefficient packet (suffix 0x26)'),
    ('LABEL_038922', 'DSP_WriteOscParam_Offset',
     'Write osc param packet with cmd 0x25 and stack offset'),

    # 038xxx - DSP state management
    ('LABEL_038DEF', 'DSP_State_DmaLoadPresets',
     'DMA-load default preset state for both DSP chips from ROM'),
    ('LABEL_038E31', 'DSP_State_ApplyBuf',
     'Copy state buffer to DMA area and trigger commit to hardware'),
    ('LABEL_038E6E', 'DSP_State_LoadAndApplyAll',
     'Copy state to global buffer then call DSP_State_ApplyAll'),

    # 038xxx - Parameter decode/scale
    ('LABEL_038EAC', 'DSP_ParamFetch_SingleTable',
     'Pointer lookup from single table at 0x12B33'),
    ('LABEL_038EB9', 'DSP_ParamFetch_AlgoTypeTable',
     'Pointer from algo-type-dependent table, advance iterator'),
    ('LABEL_038EF6', 'DSP_AlgoParam_Decode',
     'Decode packed algorithm stream data via FP math'),
    ('LABEL_038F9B', 'DSP_PitchParam_Scale',
     'Convert raw pitch to DSP frequency via log/multiply'),
    ('LABEL_038FE8', 'DSP_VolumeParam_Scale',
     'Convert raw amplitude to DSP register via piecewise curve'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'subcpu', 'kn5000_subprogram_v142.s')

    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')

    renamed = 0
    for old_label, new_label, comment in RENAMES:
        if old_label + ':' not in content:
            print(f'  WARNING: {old_label} not found, skipping')
            continue

        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        new_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)

        if new_content != content:
            content = new_content
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:40s} ({refs} refs)')

    # Check maincpu for cross-references
    maincpu_src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')
    with open(maincpu_src, 'rb') as f:
        maincpu_content = f.read().decode('latin-1')

    maincpu_renames = 0
    for old_label, new_label, _ in RENAMES:
        if old_label in maincpu_content:
            maincpu_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, maincpu_content)
            maincpu_renames += 1

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    if maincpu_renames > 0:
        with open(maincpu_src, 'wb') as f:
            f.write(maincpu_content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in subcpu ({maincpu_renames} cross-refs in maincpu)')


if __name__ == '__main__':
    main()
