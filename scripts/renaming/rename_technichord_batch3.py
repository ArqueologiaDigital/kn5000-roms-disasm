#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in technichord_part_settings.s - Batch 3
Covers Track Mixer, Feature Presentation, Drawbar Setting, and Percussive/Accordion sections."""

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
    # Track Mixer section (lines ~1677-1706)
    'LABEL_E83D2A': 'Naka_TrackMixer_Type25_Scroll',    # NAKA_TYPE_0x25
    'LABEL_E83D4E': 'Naka_TrackMixer_Type1F_Nav',       # track mixer nav
    'LABEL_E83D72': 'Naka_TrackMixer_Type47_Grid',       # NAKA_TYPE_0x47

    # Feature Presentation section (lines 1697-1820)
    'LABEL_E83D88': 'Naka_FeatPres_Container',           # NAKA_TYPE_CONTAINER "FEATURE PRESENTATION"
    'LABEL_E83DC8': 'Naka_FeatPres_StartInternalDemo',   # "Start the internal DEMO" item
    'LABEL_E83E10': 'Naka_FeatPres_Type35_Main',         # NAKA_TYPE_0x35
    'LABEL_E83E34': 'Naka_FeatPres_Type28_Grid',         # .byte data
    'LABEL_E83E4A': 'Naka_FeatPres_DemoList',            # NAKA_TYPE_LIST
    'LABEL_E83E74': 'Naka_FeatPres_Type35_Sub',          # NAKA_TYPE_0x35
    'LABEL_E83E98': 'Naka_FeatPres_Type28_Nav',          # .byte data
    'LABEL_E83EAE': 'Naka_FeatPres_StartLoadedDemo',     # "Start the loaded DEMO" item
    'LABEL_E83EF4': 'Naka_FeatPres_Type12_Select',       # NAKA_TYPE_0x12
    'LABEL_E83F18': 'Naka_FeatPres_Type33_Root',         # NAKA_TYPE_0x33
    'LABEL_E83F3A': 'Naka_FeatPres_SongHeader',          # song/presentation header data
    'LABEL_E83F5E': 'Naka_FeatPres_PresLabel',           # NAKA_TYPE_LABEL "Presentation Mode"
    'LABEL_E83F90': 'Naka_FeatPres_Type33_Loader',       # NAKA_TYPE_0x33 (loader)
    'LABEL_E83FB2': 'Naka_FeatPres_LoadingNowLabel',     # NAKA_TYPE_LABEL "Loading Now...."
    'LABEL_E83FE2': 'Naka_FeatPres_Type12_LoadSel',      # NAKA_TYPE_0x12

    # Sound Edit / Percussive section (lines 1820-1938)
    'LABEL_E84006': 'Naka_SoundEdit_Container',           # NAKA_TYPE_CONTAINER (empty title)
    'LABEL_E84030': 'Naka_SoundEdit_EmptyStr',            # aligned_string ""
    'LABEL_E84032': 'Naka_SoundEdit_Type62_Scroll',       # NAKA_TYPE_0x62
    'LABEL_E8404A': 'Naka_SoundEdit_Type4E_TimeDisp1',   # NAKA_TYPE_0x4E
    'LABEL_E84076': 'Naka_SoundEdit_TimeData1',           # time display data ("2  '")
    'LABEL_E8407E': 'Naka_SoundEdit_Type4E_TimeDisp2',   # NAKA_TYPE_0x4E
    'LABEL_E840AA': 'Naka_SoundEdit_TimeStr2a',           # "2  '"
    'LABEL_E840B0': 'Naka_SoundEdit_TimeStr2b',           # "2  '"
    'LABEL_E840B6': 'Naka_SoundEdit_FracLabel1',          # NAKA_TYPE_LABEL "2/3"
    'LABEL_E840DA': 'Naka_SoundEdit_FracLabel2',          # NAKA_TYPE_LABEL "2/3"
    'LABEL_E840FA': 'Naka_SoundEdit_FracStr',             # "2/3" string data
    'LABEL_E840FE': 'Naka_SoundEdit_PercussiveLabel',     # NAKA_TYPE_LABEL "PERCUSSIVE"
    'LABEL_E8412A': 'Naka_SoundEdit_Type47_Grid',         # NAKA_TYPE_0x47
    'LABEL_E84140': 'Naka_SoundEdit_ToneLabel',           # NAKA_TYPE_LABEL "TONE"
    'LABEL_E84166': 'Naka_SoundEdit_NavRow1',             # navigation row 1
    'LABEL_E84182': 'Naka_SoundEdit_NavRow2',             # navigation row 2
    'LABEL_E8419E': 'Naka_SoundEdit_NavRow3',             # navigation row 3

    # Drawbar Setting section (lines 1929-2079)
    'LABEL_E841B4': 'Naka_Drawbar_SettingLabel',          # "DRAWBAR SETTING" label item
    'LABEL_E84200': 'Naka_Drawbar_Type35_Main',           # NAKA_TYPE_0x35
    'LABEL_E84224': 'Naka_Drawbar_Type11_Header',         # NAKA_TYPE_0x11
    'LABEL_E84240': 'Naka_Drawbar_Type37_FeetRow',        # NAKA_TYPE_0x37 "16' 5' 8'..."
    'LABEL_E8428A': 'Naka_Drawbar_FracLabel_1_3',         # NAKA_TYPE_LABEL "1/3"
    'LABEL_E842AA': 'Naka_Drawbar_FracStr_1_3',           # "1/3" bytes
    'LABEL_E842AE': 'Naka_Drawbar_FracLabel_2_3',         # NAKA_TYPE_LABEL "2/3"
    'LABEL_E842D2': 'Naka_Drawbar_FracLabel_3_5',         # NAKA_TYPE_LABEL "3/5"
    'LABEL_E842F2': 'Naka_Drawbar_FracStr_3_5',           # "3/5" bytes
    'LABEL_E842F6': 'Naka_Drawbar_FracLabel_1_3b',        # NAKA_TYPE_LABEL "1/3"
    'LABEL_E8431A': 'Naka_Drawbar_NavPage1',              # page navigation data
    'LABEL_E84330': 'Naka_Drawbar_ScrollBar',              # scroll bar data
    'LABEL_E8434A': 'Naka_Drawbar_Type35_Sub',            # NAKA_TYPE_0x35
    'LABEL_E8436E': 'Naka_Drawbar_DecayRow',              # "DECAY :" row
    'LABEL_E843B0': 'Naka_Drawbar_LevelRow',              # "LEVEL :" row
    'LABEL_E843F2': 'Naka_Drawbar_AttackTimeRow',         # "ATTACK TIME  :" row
    'LABEL_E8443C': 'Naka_Drawbar_ReleaseTimeRow',        # "RELEASE TIME :" row
    'LABEL_E84486': 'Naka_Drawbar_Type22_Nav',            # NAKA_TYPE_0x22
    'LABEL_E844B0': 'Naka_Drawbar_NavPage2',              # page 2 navigation
    'LABEL_E844C6': 'Naka_Drawbar_HelpArea',              # help area data
    'LABEL_E844EE': 'Naka_Drawbar_Type35_Speed',          # NAKA_TYPE_0x35 (speed area)
    'LABEL_E84512': 'Naka_Drawbar_Type12_SpeedSel',       # NAKA_TYPE_0x12
    'LABEL_E84536': 'Naka_Drawbar_Type4E_SpeedDisp',      # NAKA_TYPE_0x4E SLOW/FAST
    'LABEL_E8456E': 'Naka_Drawbar_TremoloLabel',          # NAKA_TYPE_LABEL "TREMOLO"
    'LABEL_E84596': 'Naka_Drawbar_NavPage3',              # page 3 navigation
    'LABEL_E845AC': 'Naka_Drawbar_Type11_Footer',         # NAKA_TYPE_0x11
    'LABEL_E845C8': 'Naka_Drawbar_Type2D_Border',         # NAKA_TYPE_0x2D
    'LABEL_E845E2': 'Naka_Drawbar_DrawbarEditLabel',      # NAKA_TYPE_LABEL "DRAWBAR" (edit)

    # Drawbar Edit write/settings section
    'LABEL_E8460A': 'Naka_DrawbarEdit_Type35_Main',        # NAKA_TYPE_0x35
    'LABEL_E8462E': 'Naka_DrawbarEdit_NavPage',            # page navigation
    'LABEL_E84644': 'Naka_DrawbarEdit_WriteBtn',           # NAKA_TYPE_MENU_ITEM "WRITE"
    'LABEL_E84680': 'Naka_DrawbarEdit_Type11_Header',      # NAKA_TYPE_0x11
    'LABEL_E8469C': 'Naka_DrawbarEdit_Type2D_Border',      # NAKA_TYPE_0x2D
    'LABEL_E846B6': 'Naka_DrawbarEdit_EditLabel',          # NAKA_TYPE_LABEL "DRAWBAR EDIT"
}

if __name__ == '__main__':
    print(f"Renaming {len(renames)} labels...")
    rename_labels(renames)
    print("Done!")
