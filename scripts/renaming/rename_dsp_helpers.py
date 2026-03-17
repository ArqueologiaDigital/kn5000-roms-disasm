#!/usr/bin/env python3
"""Rename LABEL_* to semantic names for DSP helper routines in subcpu.

Based on analysis of the 0x035000-0x036FFF address range in the SubCPU
audio DSP subsystem. Each rename was verified by analyzing the routine's
code, register usage, called functions, and callers.

Uses binary I/O to handle encoding safely.
"""

import os
import re

# Renames: (old_label, new_label, brief_comment)
RENAMES = [
    # 035xxx range - Voice/tone generator management
    ('LABEL_035007', 'DSP_InitChannelSlot',
     'Init one DSP hardware channel slot (BC=0-127) from voice template'),
    ('LABEL_0350FA', 'DSP_FlushAllSlots',
     'Reinit all 128 DSP channel slots and DMA-transfer to hardware'),
    ('LABEL_0351E2', 'DSP1_ResolveStreamPtr',
     'Resolve register-block pointer for DSP stream/channel index'),
    ('LABEL_035203', 'DSP_ResetAlgoDefaults',
     'Copy 16 bytes of algo defaults from ROM 0x120E3 to DSP buffer'),
    ('LABEL_03522E', 'DSP_WriteAlgoBuffer',
     'Write voice algo config into DSP shadow register buffer'),
    ('LABEL_035323', 'DSP_Reinit_VoiceSlots',
     'Reinit DSP channel slots for one/all voices (A=voice, C=slot)'),
    ('LABEL_035490', 'DSP_VoiceState_Dispatch',
     'Iterate 26 voice slots, dispatch by lifecycle state'),
    ('LABEL_03555F', 'DSP_ResetWriteBufferPtr',
     'Reset DSP write-buffer ptrs (0x04531C/0x045320) to 0x007800'),
    ('LABEL_035577', 'DSP_VelocityToVolume',
     'Quadratic velocity curve: HL = (WA^2 / 4) + 63'),
    ('LABEL_035585', 'DSP_GetEffectRouting',
     'Pack sostenuto bytes at 0x041377/0x04137A into 16-bit HL'),
    ('LABEL_0355AD', 'ToneGen_SetupPolyVoice',
     'Standard poly note-on: copy template, set pitch/vol/effects'),
    ('LABEL_035656', 'ToneGen_SetupPercussionVoice',
     'Percussion note-on: octave/semitone decompose, different pitch table'),
    ('LABEL_03587B', 'DSP_RingBuf_Write2K',
     'Write byte C to 2KB circular ring buffer at XWA'),
    ('LABEL_035933', 'DSP_Enqueue_ReturnOK',
     'Shared return-zero stub: successful buffer operation'),
    ('LABEL_035950', 'DSP_Pack3x7bitFields',
     'Pack three 7-bit fields from (XWA) into 21-bit XHL'),

    # 036xxx range - DSP state management
    ('LABEL_036049', 'DSP_WriteAlgoInitPreset',
     'Look up algo index for voice WA, write init preset to DSP'),
    ('LABEL_03608C', 'DSP_ApplyAlgoForVoiceType',
     'For PCM (0x35) or GM (0x0F) voice types, apply algo state'),
    ('LABEL_03611E', 'DSP_SlotState_DisplayRestore',
     'Read+clear slot 0 state, restore DSP display at audio init'),
    ('LABEL_03632B', 'DSP_WakeAudioTask',
     'Wake audio processing task (tail-jump to task scheduler)'),
    ('LABEL_03640A', 'DSP2_SPI_ClockPulseHigh',
     'Set DSP2 clock line high (bit 2 of port 0x3C)'),
    ('LABEL_0364C4', 'DSP2_SPI_BusIdle',
     'Clear DSP2 clock+data lines, return serial bus to idle'),
    ('LABEL_036A70', 'DSP_StateTable_Reset',
     'Copy 0x91 words from default table at 0x45CA to buffer'),
    ('LABEL_036A7D', 'DSP_AlgoChange_CheckAndFlag',
     'Compare incoming algo with stored; set dirty flag at 0x493E'),
    ('LABEL_036AA2', 'DSP_SlotParam_DiffAndFlag',
     'Compare 5 slot params vs stored; set per-slot dirty flags'),
    ('LABEL_036AFD', 'DSP_EFFParam_DiffAllAndFlag',
     'Compare 5 slots x 4 param arrays; set all dirty flags'),
    ('LABEL_036D80', 'DSP_State_DiffAll',
     'Orchestrate all three diff routines (algo, slot, EFF)'),
    ('LABEL_036D94', 'DSP_State_DiffAndPrepare',
     'Diff all + prepare effect state load'),
    ('LABEL_036DA3', 'DSP_Config_ClampLimits',
     'Clamp algo field to <=1, slot volumes to <=99'),
    ('LABEL_036DF5', 'DSP_SlotMuteState_ReadAndClear',
     'Read slot state from 0x45BC[slot], return in HL, clear entry'),
    ('LABEL_036E3D', 'DSP_State_ApplyAll',
     'Top-level: clamp, diff+prepare, dispatch, reset table'),
    ('LABEL_036E60', 'EFF_SlotActive_UpdateFlags',
     'Set/clear per-slot active flags based on algo change + type'),
    ('LABEL_036FD2', 'EFF_DSPLink_ResetFlags',
     'Reset EFF-to-DSP link pending flags at 0x493A'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'subcpu', 'kn5000_subprogram_v142.s')

    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')

    renamed = 0
    for old_label, new_label, comment in RENAMES:
        # Check the label exists
        if old_label + ':' not in content:
            print(f'  WARNING: {old_label} not found, skipping')
            continue

        # Count references
        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))

        # Replace all occurrences (label definition + all references)
        new_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)

        if new_content != content:
            content = new_content
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:35s} ({refs} refs)')

    # Also check maincpu for cross-references
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
