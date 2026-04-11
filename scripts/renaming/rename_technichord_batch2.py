#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in technichord_part_settings.s - Batch 2
Covers Master Tuning, Key Scaling, Left Hold, Mixer, TechniChord sections."""

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
    # Master Tuning container and items (lines ~814-856)
    'LABEL_E82D32': 'Naka_MasterTuning_Container',    # NAKA_TYPE_CONTAINER "MASTER TUNING"
    'LABEL_E82D6A': 'Naka_MasterTuning_ValueRow',     # NAKA_TYPE_0x1A "MASTER TUNING  :"
    'LABEL_E82DB6': 'Naka_MasterTuning_HzLabel',      # NAKA_TYPE_LABEL (Hz value)
    'LABEL_E82DDA': 'Naka_MasterTuning_Type22_Nav',   # NAKA_TYPE_0x22

    # Key Scaling container (line 856-860) — external ref from widget_dispatch.s
    'LABEL_E82E00': 'Naka_KeyScaling_NavTrail',        # .byte 0x07, 0x00, 0x03, 0x00 (nav trail data)

    # Key Scaling screen (lines 867-1163)
    'LABEL_E82E3A': 'Naka_KeyScaling_Container',       # NAKA_TYPE_CONTAINER "KEY SCALING"
    'LABEL_E82E5E': 'Naka_KeyScaling_Type25_Scroll',   # NAKA_TYPE_0x25
    'LABEL_E82E7A': 'Naka_KeyScaling_Type28_Grid1',    # NAKA_TYPE_0x28
    'LABEL_E82E96': 'Naka_KeyScaling_Type28_Grid2',    # NAKA_TYPE_0x28
    'LABEL_E82EB0': 'Naka_KeyScaling_Type64_Grid3',    # NAKA_TYPE_0x64
    'LABEL_E82ED4': 'Naka_KeyScaling_Type35_Main',     # NAKA_TYPE_0x35
    'LABEL_E82EFE': 'Naka_KeyScaling_ScalingTypeRow',  # NAKA_TYPE_0x1A "SCALING TYPE  :"
    'LABEL_E82F48': 'Naka_KeyScaling_ScalingShiftRow', # NAKA_TYPE_0x1A "SCALING SHIFT :"
    'LABEL_E82F92': 'Naka_KeyScaling_ScalingGraph',    # NAKA_TYPE_0x13 (graph/display)
    'LABEL_E82FBE': 'Naka_KeyScaling_ScalingModeRow',  # NAKA_TYPE_0x1A "SCALING MODE  :"
    'LABEL_E83008': 'Naka_KeyScaling_Type35_Sub',      # NAKA_TYPE_0x35
    'LABEL_E8302C': 'Naka_KeyScaling_UserLabel',       # NAKA_TYPE_LABEL "USER KEY SCALING"
    'LABEL_E8305E': 'Naka_KeyScaling_Type2D_Border',   # NAKA_TYPE_0x2D
    'LABEL_E83078': 'Naka_KeyScaling_Type22_Nav1',     # NAKA_TYPE_0x22
    'LABEL_E830A2': 'Naka_KeyScaling_Type22_Nav2',     # NAKA_TYPE_0x22
    'LABEL_E830CC': 'Naka_KeyScaling_Type22_Nav3',     # NAKA_TYPE_0x22

    # Key Scaling grid value rows (12 cells x 2 = 24 items)
    'LABEL_E830F6': 'Naka_KeyScaling_Cell_Row1_Val1',  # NAKA_TYPE_0x1A row1 value
    'LABEL_E83132': 'Naka_KeyScaling_Cell_Row1_Name1', # NAKA_TYPE_0x1A row1 note name
    'LABEL_E8316E': 'Naka_KeyScaling_Cell_Row1_Val2',  # NAKA_TYPE_0x1A
    'LABEL_E831AA': 'Naka_KeyScaling_Cell_Row1_Name2', # NAKA_TYPE_0x1A
    'LABEL_E831E6': 'Naka_KeyScaling_Cell_Row1_Val3',  # NAKA_TYPE_0x1A
    'LABEL_E83222': 'Naka_KeyScaling_Cell_Row1_Name3', # NAKA_TYPE_0x1A
    'LABEL_E8325E': 'Naka_KeyScaling_Cell_Row2_Val1',  # NAKA_TYPE_0x1A
    'LABEL_E8329A': 'Naka_KeyScaling_Cell_Row2_Name1', # NAKA_TYPE_0x1A
    'LABEL_E832D6': 'Naka_KeyScaling_Cell_Row2_Val2',  # NAKA_TYPE_0x1A
    'LABEL_E83312': 'Naka_KeyScaling_Cell_Row2_Name2', # NAKA_TYPE_0x1A
    'LABEL_E8334E': 'Naka_KeyScaling_Cell_Row2_Val3',  # NAKA_TYPE_0x1A
    'LABEL_E8338A': 'Naka_KeyScaling_Cell_Row2_Name3', # NAKA_TYPE_0x1A

    # Key Scaling nav buttons and value cells
    'LABEL_E833C6': 'Naka_KeyScaling_NavBtn_Row1L',    # NAKA_TYPE_0x11 (left nav, row 1)
    'LABEL_E833E2': 'Naka_KeyScaling_NavBtn_Row1R',    # NAKA_TYPE_0x11
    'LABEL_E833FE': 'Naka_KeyScaling_NavBtn_Row1Mid',  # NAKA_TYPE_0x11
    'LABEL_E8341A': 'Naka_KeyScaling_NavBtn_Row2L1',   # NAKA_TYPE_0x11
    'LABEL_E83436': 'Naka_KeyScaling_NavBtn_Row2L2',   # NAKA_TYPE_0x11
    'LABEL_E83452': 'Naka_KeyScaling_NavBtn_Row2Mid',  # NAKA_TYPE_0x11
    'LABEL_E8346E': 'Naka_KeyScaling_NavBtn_Row3L1',   # NAKA_TYPE_0x11
    'LABEL_E8348A': 'Naka_KeyScaling_NavBtn_Row3Mid',  # NAKA_TYPE_0x11
    'LABEL_E834A6': 'Naka_KeyScaling_NavBtn_Row3R',    # NAKA_TYPE_0x11
    'LABEL_E834C2': 'Naka_KeyScaling_NavBtn_Row3Mid2', # NAKA_TYPE_0x11
    'LABEL_E834DE': 'Naka_KeyScaling_NavBtn_Row4L',    # NAKA_TYPE_0x11
    'LABEL_E834FA': 'Naka_KeyScaling_NavBtn_Row4Mid',  # NAKA_TYPE_0x11

    # Key Scaling VALUE items (sliders/indicators for each key)
    'LABEL_E83516': 'Naka_KeyScaling_ValItem_01',      # NAKA_TYPE_VALUE
    'LABEL_E83530': 'Naka_KeyScaling_ValItem_02',      # NAKA_TYPE_VALUE
    'LABEL_E8354A': 'Naka_KeyScaling_ValItem_03',      # NAKA_TYPE_VALUE
    'LABEL_E83564': 'Naka_KeyScaling_ValItem_04',      # NAKA_TYPE_VALUE
    'LABEL_E8357E': 'Naka_KeyScaling_ValItem_05',      # NAKA_TYPE_VALUE
    'LABEL_E83598': 'Naka_KeyScaling_ValItem_06',      # NAKA_TYPE_VALUE
    'LABEL_E835B2': 'Naka_KeyScaling_ValItem_07',      # NAKA_TYPE_VALUE
    'LABEL_E835CC': 'Naka_KeyScaling_ValItem_08',      # NAKA_TYPE_VALUE
    'LABEL_E835E6': 'Naka_KeyScaling_ValItem_09',      # NAKA_TYPE_VALUE
    'LABEL_E83600': 'Naka_KeyScaling_ValItem_10',      # NAKA_TYPE_VALUE
    'LABEL_E8361A': 'Naka_KeyScaling_ValItem_11',      # NAKA_TYPE_VALUE
    'LABEL_E83634': 'Naka_KeyScaling_ValItem_12',      # NAKA_TYPE_VALUE
    'LABEL_E8364E': 'Naka_KeyScaling_ScrollMeta',      # scroll metadata

    # Left Hold Setting container (lines 1355-1387)
    'LABEL_E83664': 'Naka_LeftHold_Container',         # NAKA_TYPE_CONTAINER "LEFT HOLD SETTING"
    'LABEL_E836A0': 'Naka_LeftHold_Type22_Nav',        # NAKA_TYPE_0x22
    'LABEL_E836CA': 'Naka_LeftHold_ValueRow',          # NAKA_TYPE_0x1A "LEFT HOLD      :"

    # Mixer container and items (lines 1388-1420)
    'LABEL_E83716': 'Naka_Mixer_Container',            # NAKA_TYPE_CONTAINER "MIXER"
    'LABEL_E83746': 'Naka_Mixer_Type25_Scroll',        # NAKA_TYPE_0x25 (with scroll)
    'LABEL_E8376A': 'Naka_Mixer_Type1F_Nav',           # NAKA_TYPE_0x1F navigation
    'LABEL_E8378E': 'Naka_Mixer_Type47_Grid',          # NAKA_TYPE_0x47

    # TechniChord container and items (lines 1429-1510)
    'LABEL_E837DC': 'Naka_TChord_Type25_Scroll',       # NAKA_TYPE_0x25 scroll
    'LABEL_E83800': 'Naka_TChord_Type28_Grid1',        # NAKA_TYPE_0x28
    'LABEL_E8381C': 'Naka_TChord_Type28_Grid2',        # NAKA_TYPE_0x28
    'LABEL_E83838': 'Naka_TChord_Type28_Grid3',        # .byte data
    'LABEL_E8384E': 'Naka_TChord_Type63_Border',       # NAKA_TYPE_0x63
    'LABEL_E83866': 'Naka_TChord_Type35_Main',         # NAKA_TYPE_0x35
    'LABEL_E8388A': 'Naka_TChord_Type22_Nav',          # NAKA_TYPE_0x22
    'LABEL_E838B4': 'Naka_TChord_Type1F_Scroll1',      # NAKA_TYPE_0x1F
    'LABEL_E838DC': 'Naka_TChord_Type1F_Scroll2',      # NAKA_TYPE_0x1F
    'LABEL_E83904': 'Naka_TChord_CloseBtn',            # "CLOSE" button
    'LABEL_E83934': 'Naka_TChord_CloseStr',            # .asciz "CLOSE"
    'LABEL_E8393A': 'Naka_TChord_Open1Btn',            # "OPEN 1" button
    'LABEL_E83972': 'Naka_TChord_Open2Btn',            # "OPEN 2" button
    'LABEL_E839AA': 'Naka_TChord_Duet1Btn',            # "DUET 1" button
    'LABEL_E839E2': 'Naka_TChord_Duet2Btn',            # "DUET 2" button
    'LABEL_E83A1A': 'Naka_TChord_CountryBtn',          # "COUNTRY" button
    'LABEL_E83A52': 'Naka_TChord_TheatreBtn',          # "THEATRE" button
    'LABEL_E83A8A': 'Naka_TChord_HymnBtn',             # "HYMN" button
    'LABEL_E83AC0': 'Naka_TChord_BigBandBrassBtn',     # "BIG BAND BRASS" button
    'LABEL_E83B00': 'Naka_TChord_BigBandReedsBtn',     # "BIG BAND REEDS" button
    'LABEL_E83B40': 'Naka_TChord_OctaveBtn',           # "OCTAVE" button
    'LABEL_E83B78': 'Naka_TChord_BlockBtn',            # "BLOCK" button
    'LABEL_E83BAE': 'Naka_TChord_HardRockBtn',         # "HARD ROCK" button
    'LABEL_E83BE8': 'Naka_TChord_FanfareBtn',          # "FANFARE" button
    'LABEL_E83C20': 'Naka_TChord_ScrollMeta',          # scroll metadata
    'LABEL_E83C36': 'Naka_TChord_Type35_Sub',          # NAKA_TYPE_0x35
    'LABEL_E83C5A': 'Naka_TChord_Type22_OrcNav',       # NAKA_TYPE_0x22 (orchestrator nav)
    'LABEL_E83C84': 'Naka_TChord_OrchestratorRow',     # NAKA_TYPE_0x1A "ORCHESTRATOR  :"
    'LABEL_E83CCE': 'Naka_TChord_ValueLabel',          # NAKA_TYPE_LABEL "VALUE"
}

if __name__ == '__main__':
    print(f"Renaming {len(renames)} labels...")
    rename_labels(renames)
    print("Done!")
