#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in technichord_part_settings.s - Batch 5
Covers Presentation effect/slider screens, Init setting, and Version display."""

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
    # Presentation effect/6A container (lines ~2628-2663)
    'LABEL_E84E72': 'Naka_PresEffect_NavMeta',            # navigation metadata
    'LABEL_E84E88': 'Naka_PresEffect_Type35_Top',          # NAKA_TYPE_0x35
    'LABEL_E84EAC': 'Naka_PresEffect_TopList',             # NAKA_TYPE_LIST
    'LABEL_E84ED6': 'Naka_PresEffect_Type61_Scroll',       # NAKA_TYPE_0x61
    'LABEL_E84EEE': 'Naka_PresEffect_Type35_Left',         # NAKA_TYPE_0x35
    'LABEL_E84F12': 'Naka_PresEffect_LeftList1',           # NAKA_TYPE_LIST
    'LABEL_E84F3C': 'Naka_PresEffect_LeftList2',           # NAKA_TYPE_LIST
    'LABEL_E84F66': 'Naka_PresEffect_Type5F_LeftScr',      # NAKA_TYPE_0x5F
    'LABEL_E84F7E': 'Naka_PresEffect_Type35_Right',        # NAKA_TYPE_0x35
    'LABEL_E84FA2': 'Naka_PresEffect_Type60_RightScr',     # NAKA_TYPE_0x60
    'LABEL_E84FBA': 'Naka_PresEffect_RightList1',          # NAKA_TYPE_LIST
    'LABEL_E84FE4': 'Naka_PresEffect_RightList2',          # NAKA_TYPE_LIST
    'LABEL_E8500E': 'Naka_PresEffect_Type35_Mid',          # NAKA_TYPE_0x35
    'LABEL_E85032': 'Naka_PresEffect_MidList',             # NAKA_TYPE_LIST
    'LABEL_E8505C': 'Naka_PresEffect_Type35_Bottom',       # NAKA_TYPE_0x35
    'LABEL_E85080': 'Naka_PresEffect_Slider1',             # NAKA_TYPE_SLIDER
    'LABEL_E850AC': 'Naka_PresEffect_TagDisp1',            # NAKA_TYPE_0x4F
    'LABEL_E850D8': 'Naka_PresEffect_TagDisp2',            # NAKA_TYPE_0x4F
    'LABEL_E85104': 'Naka_PresEffect_Slider2',             # NAKA_TYPE_SLIDER
    'LABEL_E85130': 'Naka_PresEffect_Type35_LowLeft',      # NAKA_TYPE_0x35
    'LABEL_E85154': 'Naka_PresEffect_LowLeftDisp',         # NAKA_TYPE_0x4F
    'LABEL_E85180': 'Naka_PresEffect_Type35_LowRight',     # NAKA_TYPE_0x35
    'LABEL_E851A4': 'Naka_PresEffect_LowRightRow',         # low right display row

    # Init Setting / All Initial screens (lines ~2834-2912)
    'LABEL_E851C8': 'Naka_InitSetting_Container',          # container
    'LABEL_E851EA': 'Naka_InitSetting_Type6B_Confirm',     # NAKA_TYPE_0x6B
    'LABEL_E85202': 'Naka_InitSetting_NavRow1',            # navigation row 1
    'LABEL_E8521C': 'Naka_InitSetting_NavRow2',            # navigation row 2
    'LABEL_E85236': 'Naka_InitSetting_Type33_Root',        # NAKA_TYPE_0x33
    'LABEL_E85258': 'Naka_InitSetting_AllInitLabel',       # NAKA_TYPE_LABEL "ALL INITIAL SETTING!"
    'LABEL_E8528E': 'Naka_InitSetting_Type6B_Confirm2',    # NAKA_TYPE_0x6B
    'LABEL_E852A6': 'Naka_InitSetting_Type33_Root2',       # NAKA_TYPE_0x33
    'LABEL_E852C8': 'Naka_InitSetting_ConfirmNav',         # confirmation navigation
    'LABEL_E852DE': 'Naka_InitSetting_Type6B_ScrollSel',   # NAKA_TYPE_0x6B
    'LABEL_E852F6': 'Naka_InitSetting_Type12_Select',      # NAKA_TYPE_0x12

    # Soft Version display (lines ~2913-2971)
    'LABEL_E8531A': 'Naka_SoftVersion_Container',          # NAKA_TYPE_CONTAINER "SOFT VERSION"
    'LABEL_E85352': 'Naka_SoftVersion_MainProgRow',        # NAKA_TYPE_0x15 "MAIN PROGRAM :"
    'LABEL_E85394': 'Naka_SoftVersion_MainTableRow',       # NAKA_TYPE_0x15 "MAIN TABLE   :"
    'LABEL_E853D6': 'Naka_SoftVersion_SubProgRow',         # NAKA_TYPE_0x15 "SUB  PROGRAM :"
    'LABEL_E85418': 'Naka_SoftVersion_SoundTableRow',      # NAKA_TYPE_0x15 "SOUND TABLE  :"
    'LABEL_E8545A': 'Naka_SoftVersion_ScrollMeta',         # scroll metadata
}

if __name__ == '__main__':
    print(f"Renaming {len(renames)} labels...")
    rename_labels(renames)
    print("Done!")
