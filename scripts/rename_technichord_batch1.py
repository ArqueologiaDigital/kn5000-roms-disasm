#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in technichord_part_settings.s - Batch 1
Covers the Sound Part Setting section and early parameter pages."""

import os
import sys

# All files that may contain references
MAINCPU_DIR = '/mnt/shared/kn5000-roms-disasm/maincpu'

def find_all_s_files(directory):
    """Find all .s files recursively."""
    result = []
    for root, dirs, files in os.walk(directory):
        for f in files:
            if f.endswith('.s'):
                result.append(os.path.join(root, f))
    return result

def rename_labels(renames):
    """Apply label renames across all .s files using binary I/O."""
    s_files = find_all_s_files(MAINCPU_DIR)

    for filepath in s_files:
        with open(filepath, 'rb') as f:
            data = f.read()

        original = data
        for old_name, new_name in renames.items():
            data = data.replace(old_name.encode('ascii'), new_name.encode('ascii'))

        if data != original:
            with open(filepath, 'wb') as f:
                f.write(data)
            print(f"  Updated: {filepath}")

# Batch 1: Sound Part Setting naka widgets (lines 1-500)
# These are naka_header blocks for the SOUND PART SETTING screen
renames = {
    # Sound Part Setting - main container items (type 0x1F, VALUE, LABEL, etc.)
    'LABEL_E81D1A': 'Naka_SndPartSet_Item01',        # naka_header NAKA_TYPE_0x1F
    'LABEL_E81D42': 'Naka_SndPartSet_Item02',        # naka_header NAKA_TYPE_0x1F
    'LABEL_E81D6A': 'Naka_SndPartSet_Value03',       # naka_header NAKA_TYPE_VALUE
    'LABEL_E81D84': 'Naka_SndPartSet_Value04',       # naka_header NAKA_TYPE_VALUE
    'LABEL_E81D9E': 'Naka_SndPartSet_Value05',       # naka_header NAKA_TYPE_VALUE
    'LABEL_E81DB8': 'Naka_SndPartSet_Value06',       # naka_header NAKA_TYPE_VALUE
    'LABEL_E81DD2': 'Naka_SndPartSet_Value07',       # naka_header NAKA_TYPE_VALUE
    'LABEL_E81DEC': 'Naka_SndPartSet_Value08',       # naka_header NAKA_TYPE_VALUE
    'LABEL_E81E06': 'Naka_SndPartSet_PartSelect',    # NAKA_TYPE_LABEL "PART SELECT :"
    'LABEL_E81E34': 'Naka_SndPartSet_Type12_09',     # naka_header NAKA_TYPE_0x12
    'LABEL_E81E58': 'Naka_SndPartSet_Type12_0A',     # naka_header NAKA_TYPE_0x12
    'LABEL_E81E7C': 'Naka_SndPartSet_Vol51',         # naka_header NAKA_TYPE_0x51 - VOL
    'LABEL_E81EAC': 'Naka_SndPartSet_VolStr',        # "VOL" string bytes
    'LABEL_E81EB0': 'Naka_SndPartSet_Pan51',         # naka_header NAKA_TYPE_0x51 - PAN
    'LABEL_E81EE4': 'Naka_SndPartSet_Eff51',         # naka_header NAKA_TYPE_0x51 - EFF
    'LABEL_E81F14': 'Naka_SndPartSet_EffStr',        # "EFF" string bytes
    'LABEL_E81F18': 'Naka_SndPartSet_Sus51',         # naka_header NAKA_TYPE_0x51 - SUS
    'LABEL_E81F4C': 'Naka_SndPartSet_Key51',         # naka_header NAKA_TYPE_0x51 - KEY
    'LABEL_E81F7C': 'Naka_SndPartSet_KeyStr',        # "KEY" string bytes
    'LABEL_E81F80': 'Naka_SndPartSet_Tun51',         # naka_header NAKA_TYPE_0x51 - TUN
    'LABEL_E81FB4': 'Naka_SndPartSet_Bnd51',         # naka_header NAKA_TYPE_0x51 - BND
    'LABEL_E81FE4': 'Naka_SndPartSet_BndStr',        # "BND" string bytes
    'LABEL_E81FE8': 'Naka_SndPartSet_Oth51',         # naka_header NAKA_TYPE_0x51 - OTH

    # OTH sub-items (type 0x3E) - parameter field items
    'LABEL_E8201C': 'Naka_SndPartSet_OthField3E_07', # naka_header NAKA_TYPE_0x3E
    'LABEL_E82048': 'Naka_SndPartSet_OthEmptyStr1',  # aligned_string ""
    'LABEL_E8204A': 'Naka_SndPartSet_BndField3E_06', # naka_header NAKA_TYPE_0x3E
    'LABEL_E82076': 'Naka_SndPartSet_BndPad1',       # .byte 0x00, 0xff
    'LABEL_E82078': 'Naka_SndPartSet_TunField3E_05', # naka_header NAKA_TYPE_0x3E
    'LABEL_E820A4': 'Naka_SndPartSet_TunEmptyStr',   # aligned_string ""
    'LABEL_E820A6': 'Naka_SndPartSet_KeyField3E_04', # naka_header NAKA_TYPE_0x3E
    'LABEL_E820D2': 'Naka_SndPartSet_KeyPad1',       # .byte 0x00, 0xff
    'LABEL_E820D4': 'Naka_SndPartSet_SusField3E_03', # naka_header NAKA_TYPE_0x3E
    'LABEL_E82100': 'Naka_SndPartSet_SusEmptyStr',   # aligned_string ""
    'LABEL_E82102': 'Naka_SndPartSet_EffField3E_02', # naka_header NAKA_TYPE_0x3E
    'LABEL_E8212E': 'Naka_SndPartSet_EffPad1',       # .byte 0x00, 0xff
    'LABEL_E82130': 'Naka_SndPartSet_PanField3E_01', # naka_header NAKA_TYPE_0x3E
    'LABEL_E8215C': 'Naka_SndPartSet_PanEmptyStr',   # aligned_string ""
    'LABEL_E8215E': 'Naka_SndPartSet_VolField3E_00', # naka_header NAKA_TYPE_0x3E
    'LABEL_E8218A': 'Naka_SndPartSet_VolPad1',       # .byte 0x00, 0xff
    'LABEL_E8218C': 'Naka_SndPartSet_ScrollContainer',# scroll/nav container data
    'LABEL_E821A2': 'Naka_SndPartSet_Type35_Main',   # naka_header NAKA_TYPE_0x35

    # VOL page (Page 1) - Sound Part Setting detail parameters
    'LABEL_E821C6': 'Naka_PartVol_PanRow',           # "PAN        :" row
    'LABEL_E8220E': 'Naka_PartVol_RevDepthRow',      # "REV. DEPTH :" row
    'LABEL_E82256': 'Naka_PartVol_DspEffectRow',     # "DSP EFFECT :" row
    'LABEL_E8229E': 'Naka_PartVol_DigEffectRow',     # "DIG.EFFECT :" row
    'LABEL_E822E6': 'Naka_PartVol_SustainRow',       # "SUSTAIN    :" row
    'LABEL_E8232E': 'Naka_PartVol_Type11_Footer',    # naka_header NAKA_TYPE_0x11
    'LABEL_E8234A': 'Naka_PartVol_SusLengthRow',     # "SUS LENGTH :" row
    'LABEL_E82392': 'Naka_PartVol_KeyShiftRow',      # "KEY SHIFT  :" row
    'LABEL_E823DA': 'Naka_PartVol_TuningRow',        # "TUNING     :" row
    'LABEL_E82422': 'Naka_PartVol_BendRangeRow',     # "BEND RANGE :" row
    'LABEL_E8246A': 'Naka_PartVol_GlidePedalRow',    # "GLIDE PEDAL:" row
    'LABEL_E824B2': 'Naka_PartVol_SustPedalRow',     # "SUST.PEDAL :" row
    'LABEL_E824FA': 'Naka_PartVol_VolumeRow',        # "VOLUME     :" row

    # Page 2 - PAN/Volume parameters
    'LABEL_E82546': 'Naka_PartPan_Type35_Main',      # naka_header NAKA_TYPE_0x35
    'LABEL_E8256A': 'Naka_PartPan_Type1F_Nav',       # naka_header NAKA_TYPE_0x1F
    'LABEL_E82592': 'Naka_PartPan_Type11_Footer',    # naka_header NAKA_TYPE_0x11
    'LABEL_E825AE': 'Naka_PartPan_VolumeRow',        # "VOLUME       :" row
    'LABEL_E825FC': 'Naka_PartPan_Type35_Pan',       # naka_header NAKA_TYPE_0x35
    'LABEL_E82620': 'Naka_PartPan_Type11_PanCtrl',   # naka_header NAKA_TYPE_0x11 - PAN control
    'LABEL_E8263C': 'Naka_PartPan_PanValueRow',      # PAN value row with "PAN ="
    'LABEL_E82676': 'Naka_PartPan_PanEqualsStr',     # "PAN =" asciz string
    'LABEL_E8267C': 'Naka_PartPan_PanLabel',         # NAKA_TYPE_LABEL "LEFT CENTER RIGHT"
    'LABEL_E826B8': 'Naka_PartPan_PanSlider',        # PAN slider bar data

    # Page 3 - Reverb/DSP/Digital effect
    'LABEL_E826DC': 'Naka_PartEff_Type1F_Nav',       # naka_header NAKA_TYPE_0x1F - nav
    'LABEL_E82704': 'Naka_PartEff_Type11_Footer',    # naka_header NAKA_TYPE_0x11
    'LABEL_E82720': 'Naka_PartEff_Type35_Main',      # naka_header NAKA_TYPE_0x35
    'LABEL_E82744': 'Naka_PartEff_ReverbDepthRow',   # "REVERB DEPTH:" row
    'LABEL_E8278C': 'Naka_PartEff_DspEffectRow',     # "DSP EFFECT  :" row
    'LABEL_E827D4': 'Naka_PartEff_DigitalEffRow',    # "DIGITAL EFF.:" row
    'LABEL_E8281C': 'Naka_PartEff_Type1F_Nav2',      # naka_header NAKA_TYPE_0x1F - scroll
    'LABEL_E82844': 'Naka_PartEff_Type11_Footer2',   # naka_header NAKA_TYPE_0x11

    # Page 4 - Sustain settings
    'LABEL_E82860': 'Naka_PartSus_Type35_Main',      # naka_header NAKA_TYPE_0x35
    'LABEL_E82884': 'Naka_PartSus_Type1F_Nav',       # naka_header NAKA_TYPE_0x1F
    'LABEL_E828AC': 'Naka_PartSus_OnOffRow',         # "SUSTAIN ON/OFF   :" row
    'LABEL_E828FA': 'Naka_PartSus_LengthRow',        # "SUSTAIN LENGTH   :" row
    'LABEL_E82948': 'Naka_PartSus_Type11_Footer',    # naka_header NAKA_TYPE_0x11

    # Page 5 - Key shift
    'LABEL_E82964': 'Naka_PartKey_Type35_Main',      # naka_header NAKA_TYPE_0x35
    'LABEL_E82988': 'Naka_PartKey_KeyShiftRow',      # "KEY SHIFT    :" row
    'LABEL_E829D2': 'Naka_PartKey_Type1F_Nav',       # naka_header NAKA_TYPE_0x1F
    'LABEL_E829FA': 'Naka_PartKey_Type11_Footer',    # naka_header NAKA_TYPE_0x11

    # Page 6 - Tuning
    'LABEL_E82A16': 'Naka_PartTun_Type35_Main',      # naka_header NAKA_TYPE_0x35
    'LABEL_E82A3A': 'Naka_PartTun_TuningRow',        # "TUNING       :" row
    'LABEL_E82A84': 'Naka_PartTun_Type1F_Nav',       # naka_header NAKA_TYPE_0x1F
    'LABEL_E82AAC': 'Naka_PartTun_Type11_Footer',    # naka_header NAKA_TYPE_0x11

    # Page 7 - Bend range
    'LABEL_E82AC8': 'Naka_PartBnd_Type35_Main',      # naka_header NAKA_TYPE_0x35
    'LABEL_E82AEC': 'Naka_PartBnd_PitchBendRow',     # "PITCH BEND RANGE :" row
    'LABEL_E82B3A': 'Naka_PartBnd_Type1F_Nav',       # naka_header NAKA_TYPE_0x1F
    'LABEL_E82B62': 'Naka_PartBnd_Type11_Footer',    # naka_header NAKA_TYPE_0x11

    # Page 8 - Other settings (Glide, Sustain PDL, After Touch, Key Scaling, Part EXP)
    'LABEL_E82B7E': 'Naka_PartOth_Type35_Main',      # naka_header NAKA_TYPE_0x35
    'LABEL_E82BA2': 'Naka_PartOth_GlidePedalRow',    # "GLIDE PEDAL :" row
    'LABEL_E82BEA': 'Naka_PartOth_SustainPdlRow',    # "SUSTAIN PDL :" row
    'LABEL_E82C32': 'Naka_PartOth_AfterTouchRow',    # "AFTER TOUCH :" row
    'LABEL_E82C7A': 'Naka_PartOth_Type1F_Nav',       # naka_header NAKA_TYPE_0x1F
    'LABEL_E82CA2': 'Naka_PartOth_KeyScalingRow',    # "KEY SCALING :" row
    'LABEL_E82CEA': 'Naka_PartOth_PartExpPdlRow',    # "PART EXP PDL:" row
}

if __name__ == '__main__':
    print(f"Renaming {len(renames)} labels...")
    rename_labels(renames)
    print("Done!")
