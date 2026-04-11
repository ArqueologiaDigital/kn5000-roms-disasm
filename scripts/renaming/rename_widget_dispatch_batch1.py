#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in widget_dispatch.s (Batch 1).
Focuses on major structural labels: data tables, config tables, dispatch tables.
Uses binary I/O to preserve Latin-1 bytes."""

import os
import sys

REPO = '/home/fsanches/compartilhado/kn5000-roms-disasm'
TARGET_FILE = os.path.join(REPO, 'maincpu/ui_widgets/widget_dispatch.s')

# Mapping of old label -> new label
# Only labels DEFINED in widget_dispatch.s should be renamed.
RENAMES = {
    # === Naka instruction parameter data blocks (EE00xx) ===
    'LABEL_EE0010': 'NakaInst_Param_Bitmap80',
    'LABEL_EE0012': 'NakaInst_Param_Field02',
    'LABEL_EE0022': 'NakaInst_Param_Term00',
    'LABEL_EE0023': 'NakaInst_Param_Field88',
    'LABEL_EE0034': 'NakaInst_Param_Field81A',
    'LABEL_EE0046': 'NakaInst_Param_Idx01',
    'LABEL_EE004B': 'NakaInst_Param_Field05A',
    'LABEL_EE0058': 'NakaInst_Param_Field81B',
    'LABEL_EE006A': 'NakaInst_Param_Field81C',
    'LABEL_EE006E': 'NakaInst_Param_Field48',
    'LABEL_EE0073': 'NakaInst_Param_TermFF',
    'LABEL_EE007C': 'NakaInst_Param_Field84',
    'LABEL_EE0086': 'NakaInst_Param_EmptyStr',
    'LABEL_EE008E': 'NakaInst_Param_Idx01_88',
    'LABEL_EE0096': 'NakaInst_Param_Val7F',
    'LABEL_EE009B': 'NakaInst_Param_Repeat',
    'LABEL_EE00A0': 'NakaInst_Param_Idx0B_88',
    'LABEL_EE00B2': 'NakaInst_Param_Idx02_88',
    'LABEL_EE00BF': 'NakaInst_Param_Byte01',
    'LABEL_EE00C4': 'NakaInst_Param_Idx03_88',
    'LABEL_EE00D6': 'NakaInst_Param_Idx04_88',
    'LABEL_EE00D8': 'NakaInst_Param_Val02',
    'LABEL_EE00DE': 'NakaInst_Param_Val01_07',
    'LABEL_EE00E8': 'NakaInst_Param_Idx05_88',
    'LABEL_EE00EB': 'NakaInst_Param_Val0A',
    'LABEL_EE00FA': 'NakaInst_Param_Idx06_88',
    'LABEL_EE010C': 'NakaInst_Param_Idx07_88',
    'LABEL_EE0111': 'NakaInst_Param_Val0C',
    'LABEL_EE0113': 'NakaInst_Param_Val00_01',
    'LABEL_EE011E': 'NakaInst_Param_Idx08_88',
    'LABEL_EE0130': 'NakaInst_Param_IdxA0_00',
    'LABEL_EE0139': 'NakaInst_Param_Size05',
    'LABEL_EE013B': 'NakaInst_Param_EndFF',
    'LABEL_EE013C': 'NakaInst_Param_Flag01',
    'LABEL_EE013D': 'NakaInst_Param_PadEnd',
    'LABEL_EE0142': 'NakaInst_Param_IdxA0_01',

    # === Sequencer / MIDI dispatch data ===
    'LABEL_EE1574': 'NakaInst_SoundConfig_LookupTable',
    'LABEL_EE2D6C': 'SeqChan_CommandDispatch_Table',
    'LABEL_EE2F26': 'SeqFormat_ReferenceData',
    'LABEL_EE2F8C': 'SeqData_SubDispatch_Table',

    # === Display script node labels (EE36xx-EE43xx) ===
    'LABEL_EE368A': 'DisplayScript_Node_028',
    'LABEL_EE3696': 'DisplayScript_Node_SelfRef1',
    'LABEL_EE36A2': 'DisplayScript_Node_Loop12',
    'LABEL_EE36F0': 'DisplayScript_Node_Anim7E_02',
    'LABEL_EE37C2': 'DisplayScript_Node_Scroll60_18',
    'LABEL_EE37F2': 'DisplayScript_Node_Scroll00',
    'LABEL_EE383A': 'DisplayScript_Node_Scroll60_10',
    'LABEL_EE386A': 'DisplayScript_Node_Scroll00_5E',
    'LABEL_EE3894': 'DisplayScript_Node_Block50_0E',
    'LABEL_EE38B2': 'DisplayScript_Node_Scroll5A',
    'LABEL_EE38CA': 'DisplayScript_Node_Scroll10_0D',
    'LABEL_EE38E2': 'DisplayScript_Node_Scroll00_D6',
    'LABEL_EE39D8': 'DisplayScript_Node_AnimStep07_01',
    'LABEL_EE39EA': 'DisplayScript_Node_FadeDE',
    'LABEL_EE3A32': 'DisplayScript_Node_AnimStep01_1B',
    'LABEL_EE3A4A': 'DisplayScript_Node_Fade3E',
    'LABEL_EE3A80': 'DisplayScript_Node_AnimStep07_03',
    'LABEL_EE3A92': 'DisplayScript_Node_Fade86',
    'LABEL_EE3ADA': 'DisplayScript_Node_AnimStep01_1B_B',
    'LABEL_EE3B1C': 'DisplayScript_Node_Fade10',
    'LABEL_EE3B28': 'DisplayScript_Node_AnimStep07_05',
    'LABEL_EE3B3A': 'DisplayScript_Node_Fade2E',
    'LABEL_EE3B82': 'DisplayScript_Node_AnimStep01_1B_C',
    'LABEL_EE3B9A': 'DisplayScript_Node_Fade8E',
    'LABEL_EE3BD0': 'DisplayScript_Node_AnimStep07_07',
    'LABEL_EE3BE2': 'DisplayScript_Node_FadeD6',
    'LABEL_EE3C2A': 'DisplayScript_Node_AnimStep01_1B_D',
    'LABEL_EE3C6C': 'DisplayScript_Node_FadeA6',
    'LABEL_EE3C78': 'DisplayScript_Node_AnimStep07_0A',
    'LABEL_EE3C8A': 'DisplayScript_Node_AnimStep01_1B_E',
    'LABEL_EE3CD2': 'DisplayScript_Node_FadeEE',
    'LABEL_EE3D20': 'DisplayScript_Node_AnimSequence_A',
    'LABEL_EE3DAA': 'DisplayScript_Node_AnimStep07_0C',
    'LABEL_EE3DF8': 'DisplayScript_Node_AnimStep01_1B_F',
    'LABEL_EE3E0A': 'DisplayScript_Node_FadeF2',
    'LABEL_EE3E16': 'DisplayScript_Node_AnimStep07_0D',
    'LABEL_EE3E40': 'DisplayScript_Node_AnimStep01_1B_G',
    'LABEL_EE3E52': 'DisplayScript_Node_AnimStep01_1D_A',
    'LABEL_EE3EA0': 'DisplayScript_Node_AnimStep07_0E',
    'LABEL_EE3EB2': 'DisplayScript_Node_AnimStep01_1B_H',
    'LABEL_EE3EFA': 'DisplayScript_Node_AnimStep01_1D_B',
    'LABEL_EE3F48': 'DisplayScript_Node_AnimStep07_0F',
    'LABEL_EE3F5A': 'DisplayScript_Node_FadeAA',
    'LABEL_EE3F66': 'DisplayScript_Node_AnimStep07_10',
    'LABEL_EE3F90': 'DisplayScript_Node_AnimStep01_1B_I',
    'LABEL_EE3FA2': 'DisplayScript_Node_AnimStep01_1D_C',
    'LABEL_EE3FF0': 'DisplayScript_Node_AnimStep07_11',
    'LABEL_EE4002': 'DisplayScript_Node_AnimStep01_1B_J',
    'LABEL_EE404A': 'DisplayScript_Node_AnimStep01_1D_D',
    'LABEL_EE4098': 'DisplayScript_Node_AnimStep07_12',
    'LABEL_EE40AA': 'DisplayScript_Node_FadeBE',
    'LABEL_EE40B6': 'DisplayScript_Node_AnimStep07_13',
    'LABEL_EE40E0': 'DisplayScript_Node_AnimStep01_1B_K',
    'LABEL_EE40F2': 'DisplayScript_Node_AnimStep01_1D_E',
    'LABEL_EE4140': 'DisplayScript_Node_AnimSequence_B',
    'LABEL_EE41D0': 'DisplayScript_Node_AnimStep07_14',
    'LABEL_EE41E2': 'DisplayScript_Node_Fade1E42',
    'LABEL_EE41EE': 'DisplayScript_Node_AnimStep07_15',
    'LABEL_EE422A': 'DisplayScript_Node_AnimStep01_1B_L',
    'LABEL_EE426C': 'DisplayScript_Node_AnimStep01_1D_F',

    # === UIState handler function tables (EE7Fxx-EE81xx) ===
    'LABEL_EE7FA8': 'UIState_HandlerTable_WithProbe',
    'LABEL_EE7FD4': 'UIState_HandlerTable_Standard',
    'LABEL_EE7FFC': 'UIState_HandlerTable_Compact',
    'LABEL_EE8020': 'UIState_HandlerTable_Basic_00',
    'LABEL_EE8040': 'UIState_HandlerTable_Basic_01',
    'LABEL_EE8060': 'UIState_HandlerTable_Basic_02',
    'LABEL_EE8080': 'UIState_HandlerTable_Basic_03',
    'LABEL_EE80A0': 'UIState_HandlerTable_Basic_04',
    'LABEL_EE80C0': 'UIState_HandlerTable_Basic_05',
    'LABEL_EE80E0': 'UIState_HandlerTable_Basic_06',
    'LABEL_EE8100': 'UIState_HandlerTable_Basic_07',

    # === Audio init voice dispatch table ===
    'LABEL_EE8CF8': 'AudioInit_VoiceDispatch_Table',

    # === Character map data / lookup ===
    'LABEL_EE8EB8': 'CharMap_ValueData_A',
    'LABEL_EE8ED8': 'CharMap_ValueData_B',

    # === Character mapping tables per mode ===
    'LABEL_EEC418': 'CharMap_Mode2Forward',
    'LABEL_EEC498': 'CharMap_Mode3Forward',
    'LABEL_EEC518': 'CharMap_Mode4Forward',
    'LABEL_EEC598': 'CharMap_Mode5Forward',
    'LABEL_EEC618': 'CharMap_Mode6Forward',
    'LABEL_EEC718': 'CharMap_Mode2Reverse',
    'LABEL_EEC798': 'CharMap_Mode3Reverse',
    'LABEL_EEC818': 'CharMap_Mode4Reverse',
    'LABEL_EEC898': 'CharMap_Mode5Reverse',
    'LABEL_EEC918': 'CharMap_Mode7',
    'LABEL_EEC998': 'CharMap_Mode8',
    'LABEL_EECA18': 'CharMap_Mode9',
    'LABEL_EECA98': 'CharMap_Mode10',
    'LABEL_EECB18': 'CharMap_Mode11',
    'LABEL_EECB98': 'CharMap_Mode12',
    'LABEL_EECC18': 'CharMap_Mode13',
    'LABEL_EECC98': 'CharMap_Mode14',
    'LABEL_EECD18': 'CharMap_Mode15',
    'LABEL_EECD98': 'CharMap_Mode16',
    'LABEL_EECE18': 'CharMap_Mode17',
    'LABEL_EECE98': 'CharMap_Mode18',
    'LABEL_EECF18': 'CharMap_Mode19',
    'LABEL_EECF98': 'CharMap_Mode20',
    'LABEL_EED018': 'CharMap_Mode21',
    'LABEL_EED098': 'CharMap_Mode22',
    'LABEL_EED118': 'CharMap_FullPermutation',

    # === System config pointer table ===
    'LABEL_EE8C7E': 'SystemConfig_PointerTable',
}

def main():
    # Read all files that need updating
    # First find which labels are referenced externally
    external_labels = set()
    all_files_to_update = {}

    # Read the target file
    with open(TARGET_FILE, 'rb') as f:
        content = f.read()

    # Check all .s files in maincpu/ for external references to our labels
    maincpu_dir = os.path.join(REPO, 'maincpu')
    for root, dirs, files in os.walk(maincpu_dir):
        for fname in files:
            if not fname.endswith('.s'):
                continue
            fpath = os.path.join(root, fname)
            with open(fpath, 'rb') as f:
                fcontent = f.read()

            needs_update = False
            for old_name in RENAMES:
                if old_name.encode('ascii') in fcontent:
                    if fpath != TARGET_FILE:
                        needs_update = True
                        external_labels.add(old_name)

            if needs_update:
                all_files_to_update[fpath] = fcontent

    # Always include the target file
    all_files_to_update[TARGET_FILE] = content

    print(f"Renaming {len(RENAMES)} labels")
    print(f"Labels with external references: {len(external_labels)}")
    print(f"Files to update: {len(all_files_to_update)}")

    # Perform renames
    for fpath, fcontent in all_files_to_update.items():
        original = fcontent
        for old_name, new_name in RENAMES.items():
            fcontent = fcontent.replace(old_name.encode('ascii'), new_name.encode('ascii'))
        if fcontent != original:
            with open(fpath, 'wb') as f:
                f.write(fcontent)
            relpath = os.path.relpath(fpath, REPO)
            print(f"  Updated: {relpath}")

    print("Done!")

if __name__ == '__main__':
    main()
