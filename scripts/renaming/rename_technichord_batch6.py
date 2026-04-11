#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in technichord_part_settings.s - Batch 6 (final)
Covers remaining labels: SoundConfig empty strings, Sdpart parameter pads,
SdmTune placeholders, ScalingKey placeholders, Sdscltyp placeholders, and end-of-file pads."""

import os

MAINCPU_DIR = '/home/fsanches/compartilhado/kn5000-roms-disasm/maincpu'

def find_all_s_files(directory):
    result = []
    for root, dirs, files in os.walk(directory):
        for f in files:
            if f.endswith('.s'):
                result.append(os.path.join(root, f))
    return result

def rename_labels(renames):
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

renames = {
    # SoundConfig table empty strings (lines ~3346-3385)
    # These are empty placeholder strings referenced from Naka_SoundConfig_Table
    'LABEL_E85A48': 'Naka_SdConfig_EmptyStr01',
    'LABEL_E85A4A': 'Naka_SdConfig_EmptyStr02',
    'LABEL_E85A4C': 'Naka_SdConfig_EmptyStr03',
    'LABEL_E85A56': 'Naka_SdConfig_EmptyStr04',
    'LABEL_E85A58': 'Naka_SdConfig_EmptyStr05',
    'LABEL_E85A5A': 'Naka_SdConfig_EmptyStr06',
    'LABEL_E85A5C': 'Naka_SdConfig_EmptyStr07',
    'LABEL_E85A5E': 'Naka_SdConfig_EmptyStr08',
    'LABEL_E85A60': 'Naka_SdConfig_EmptyStr09',
    'LABEL_E85A62': 'Naka_SdConfig_EmptyStr10',
    'LABEL_E85A64': 'Naka_SdConfig_EmptyStr11',
    'LABEL_E85A66': 'Naka_SdConfig_EmptyStr12',
    'LABEL_E85A68': 'Naka_SdConfig_EmptyStr13',
    'LABEL_E85A72': 'Naka_SdConfig_EmptyStr14',
    'LABEL_E85A74': 'Naka_SdConfig_EmptyStr15',
    'LABEL_E85A76': 'Naka_SdConfig_EmptyStr16',
    'LABEL_E85A78': 'Naka_SdConfig_EmptyStr17',

    # Sdpart parameter pad bytes (lines ~3432-3565)
    # These are .byte 0x00, 0xff pad entries between named Sdpart parameter sections
    # After SdpartMain (main sound part)
    'LABEL_E85BE2': 'Naka_Sdpart_Pad01',
    'LABEL_E85BE4': 'Naka_Sdpart_Pad02',
    'LABEL_E85BE6': 'Naka_Sdpart_Pad03',
    'LABEL_E85BEA': 'Naka_Sdpart_Pad04',
    'LABEL_E85BEC': 'Naka_Sdpart_Pad05',
    'LABEL_E85BEE': 'Naka_Sdpart_Pad06',
    # After SdpartOth
    'LABEL_E85BFC': 'Naka_SdpartOth_Pad1',
    'LABEL_E85BFE': 'Naka_SdpartOth_Pad2',
    # After SdpartBnd
    'LABEL_E85C0C': 'Naka_SdpartBnd_Pad1',
    'LABEL_E85C0E': 'Naka_SdpartBnd_Pad2',
    # After SdpartTun
    'LABEL_E85C1C': 'Naka_SdpartTun_Pad1',
    'LABEL_E85C1E': 'Naka_SdpartTun_Pad2',
    # After SdpartKey
    'LABEL_E85C2C': 'Naka_SdpartKey_Pad1',
    'LABEL_E85C2E': 'Naka_SdpartKey_Pad2',
    'LABEL_E85C30': 'Naka_SdpartKey_EmptyStr',    # aligned_string ""
    # After SdpartSus
    'LABEL_E85C3E': 'Naka_SdpartSus_Pad1',
    'LABEL_E85C42': 'Naka_SdpartSus_Pad2',
    'LABEL_E85C44': 'Naka_SdpartSus_Pad3',
    # After SdpartEff
    'LABEL_E85C52': 'Naka_SdpartEff_Pad1',
    'LABEL_E85C54': 'Naka_SdpartEff_Pad2',
    'LABEL_E85C56': 'Naka_SdpartEff_Pad3',
    'LABEL_E85C5A': 'Naka_SdpartEff_Pad4',
    # After SdpartPan
    'LABEL_E85C66': 'Naka_SdpartPan_EmptyStr',    # aligned_string ""
    'LABEL_E85C6A': 'Naka_SdpartPan_Pad1',
    # After SdpartVol
    'LABEL_E85C76': 'Naka_SdpartVol_EmptyStr',    # aligned_string ""
    'LABEL_E85C7A': 'Naka_SdpartVol_Pad1',
    'LABEL_E85C7C': 'Naka_SdpartVol_Pad2',
    'LABEL_E85C7E': 'Naka_SdpartVol_Pad3',
    'LABEL_E85C82': 'Naka_SdpartVol_Pad4',
    'LABEL_E85C84': 'Naka_SdpartVol_Pad5',
    'LABEL_E85C86': 'Naka_SdpartVol_Pad6',
    'LABEL_E85C8A': 'Naka_SdpartVol_Pad7',
    'LABEL_E85C8C': 'Naka_SdpartVol_Pad8',
    'LABEL_E85C8E': 'Naka_SdpartVol_Pad9',
    # After SdpartMain
    'LABEL_E85C9E': 'Naka_SdpartMain_Pad1',
    'LABEL_E85CA2': 'Naka_SdpartMain_Pad2',
    'LABEL_E85CA4': 'Naka_SdpartMain_Pad3',
    'LABEL_E85CA6': 'Naka_SdpartMain_Pad4',
    'LABEL_E85CAA': 'Naka_SdpartMain_Pad5',
    'LABEL_E85CAC': 'Naka_SdpartMain_Pad6',
    'LABEL_E85CAE': 'Naka_SdpartMain_Pad7',
    'LABEL_E85CB2': 'Naka_SdpartMain_Pad8',
    'LABEL_E85CB4': 'Naka_SdpartMain_Pad9',
    'LABEL_E85CB6': 'Naka_SdpartMain_PadA',
    'LABEL_E85CBA': 'Naka_SdpartMain_PadB',
    'LABEL_E85CBC': 'Naka_SdpartMain_PadC',
    # After SdpartSound
    'LABEL_E85CD6': 'Naka_SdpartSound_EmptyStr',  # aligned_string ""
    'LABEL_E85CDA': 'Naka_SdpartSound_Pad1',
    'LABEL_E85CDC': 'Naka_SdpartSound_Pad2',
    'LABEL_E85CDE': 'Naka_SdpartSound_Pad3',
    'LABEL_E85CE2': 'Naka_SdpartSound_Pad4',
    'LABEL_E85CE4': 'Naka_SdpartSound_Pad5',
    'LABEL_E85CE6': 'Naka_SdpartSound_Pad6',

    # SdmTune table empty strings (lines ~3566-3575)
    'LABEL_E85D04': 'Naka_SdmTune_EmptyStr1',
    'LABEL_E85D06': 'Naka_SdmTune_EmptyStr2',
    'LABEL_E85D08': 'Naka_SdmTune_EmptyStr3',
    'LABEL_E85D0A': 'Naka_SdmTune_EmptyStr4',

    # ScalingKey table empty strings (lines ~3607-3658)
    # 26 empty placeholder strings referenced from SoundParam2_Table
    'LABEL_E85DF0': 'Naka_ScalingKey_EmptyStr01',
    'LABEL_E85DF2': 'Naka_ScalingKey_EmptyStr02',
    'LABEL_E85DF4': 'Naka_ScalingKey_EmptyStr03',
    'LABEL_E85DF6': 'Naka_ScalingKey_EmptyStr04',
    'LABEL_E85DF8': 'Naka_ScalingKey_EmptyStr05',
    'LABEL_E85DFA': 'Naka_ScalingKey_EmptyStr06',
    'LABEL_E85DFC': 'Naka_ScalingKey_EmptyStr07',
    'LABEL_E85DFE': 'Naka_ScalingKey_EmptyStr08',
    'LABEL_E85E00': 'Naka_ScalingKey_EmptyStr09',
    'LABEL_E85E02': 'Naka_ScalingKey_EmptyStr10',
    'LABEL_E85E04': 'Naka_ScalingKey_EmptyStr11',
    'LABEL_E85E06': 'Naka_ScalingKey_EmptyStr12',
    'LABEL_E85E08': 'Naka_ScalingKey_EmptyStr13',
    'LABEL_E85E0A': 'Naka_ScalingKey_EmptyStr14',
    'LABEL_E85E0C': 'Naka_ScalingKey_EmptyStr15',
    'LABEL_E85E0E': 'Naka_ScalingKey_EmptyStr16',
    'LABEL_E85E10': 'Naka_ScalingKey_EmptyStr17',
    'LABEL_E85E12': 'Naka_ScalingKey_EmptyStr18',
    'LABEL_E85E14': 'Naka_ScalingKey_EmptyStr19',
    'LABEL_E85E16': 'Naka_ScalingKey_EmptyStr20',
    'LABEL_E85E18': 'Naka_ScalingKey_EmptyStr21',
    'LABEL_E85E1A': 'Naka_ScalingKey_EmptyStr22',
    'LABEL_E85E1C': 'Naka_ScalingKey_EmptyStr23',
    'LABEL_E85E1E': 'Naka_ScalingKey_EmptyStr24',
    'LABEL_E85E20': 'Naka_ScalingKey_EmptyStr25',
    'LABEL_E85E22': 'Naka_ScalingKey_EmptyStr26',

    # Sdscltyp table empty strings (lines ~3671-3685)
    'LABEL_E85EBA': 'Naka_Sdscltyp_EmptyStr01',
    'LABEL_E85EBC': 'Naka_Sdscltyp_EmptyStr02',
    'LABEL_E85EBE': 'Naka_Sdscltyp_EmptyStr03',
    'LABEL_E85EC0': 'Naka_Sdscltyp_EmptyStr04',
    'LABEL_E85EC2': 'Naka_Sdscltyp_EmptyStr05',
    'LABEL_E85ECE': 'Naka_Sdscltyp_EmptyStr06',
    'LABEL_E85ED0': 'Naka_Sdscltyp_EmptyStr07',
    'LABEL_E85ED2': 'Naka_Sdscltyp_EmptyStr08',
    'LABEL_E85EE0': 'Naka_Sdscltyp_EmptyStr09',
    'LABEL_E85EEC': 'Naka_Sdscltyp_EmptyStr10',
    'LABEL_E85EEE': 'Naka_Sdscltyp_EmptyStr11',
    'LABEL_E85EF0': 'Naka_Sdscltyp_EmptyStr12',

    # Sdlfthld (Left Hold) pad bytes (lines ~3691-3695)
    'LABEL_E85F1A': 'Naka_Sdlfthld_Pad1',
    'LABEL_E85F1C': 'Naka_Sdlfthld_Pad2',
    'LABEL_E85F1E': 'Naka_Sdlfthld_Pad3',

    # Sdmixer end-of-file pad bytes (lines ~3701-3706)
    'LABEL_E85F3E': 'Naka_Sdmixer_Pad1',
    'LABEL_E85F42': 'Naka_Sdmixer_Pad2',
    'LABEL_E85F44': 'Naka_Sdmixer_Pad3',
}

if __name__ == '__main__':
    print(f"Renaming {len(renames)} labels...")
    rename_labels(renames)
    print("Done!")
