#!/usr/bin/env python3
"""Rename LABEL_XXXXXX to semantic names in technichord_part_settings.s - Batch 4
Covers Accordion Register (German/Italian types), register pipe data,
and the Presentation/Effect/Version/Init screens."""

import os

MAINCPU_DIR = '/mnt/shared/kn5000-roms-disasm/maincpu'

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
    # Accordion Register section (lines 2215-2500)
    'LABEL_E84706': 'Naka_AccordReg_Type2D_Border',       # NAKA_TYPE_0x2D
    'LABEL_E84720': 'Naka_AccordReg_Type62_Scroll',        # NAKA_TYPE_0x62
    'LABEL_E84738': 'Naka_AccordReg_RegLabel',             # NAKA_TYPE_LABEL "ACCORDION REGISTER"
    'LABEL_E8476C': 'Naka_AccordReg_Type1F_Nav1',          # NAKA_TYPE_0x1F
    'LABEL_E84794': 'Naka_AccordReg_Type1F_Nav2',          # NAKA_TYPE_0x1F
    'LABEL_E847BC': 'Naka_AccordReg_TypeLabel',             # NAKA_TYPE_LABEL "TYPE"
    'LABEL_E847E2': 'Naka_AccordReg_Type12_TypeSel',        # NAKA_TYPE_0x12
    'LABEL_E84806': 'Naka_AccordReg_TypeNavMeta',           # type selection nav metadata
    'LABEL_E8481C': 'Naka_AccordReg_Type35_Main',           # NAKA_TYPE_0x35

    # German accordion type (lines 2288-2453)
    'LABEL_E84840': 'Naka_AccGerman_TypeLabel',             # NAKA_TYPE_LABEL "TYPE : GERMAN"
    'LABEL_E8486E': 'Naka_AccGerman_GridDisplay',           # accordion grid display data
    'LABEL_E84888': 'Naka_AccGerman_Bass1_4E',              # NAKA_TYPE_0x4E "BASS1"
    'LABEL_E848C0': 'Naka_AccGerman_Bass2_4E',              # NAKA_TYPE_0x4E "BASS2"
    'LABEL_E848F8': 'Naka_AccGerman_Pipe1_Data',            # pipe register data
    'LABEL_E8492C': 'Naka_AccGerman_Pipe1_Vals',            # ~95 values
    'LABEL_E84930': 'Naka_AccGerman_Pipe1_ExtraVals',       # additional ~95 values
    'LABEL_E8493C': 'Naka_AccGerman_Pipe2_Data',            # pipe 2 data
    'LABEL_E84970': 'Naka_AccGerman_Pipe2_Vals',            # ~95 values
    'LABEL_E84974': 'Naka_AccGerman_Pipe2_ExtraVals',       # pad + ~95 values
    'LABEL_E8497E': 'Naka_AccGerman_Pipe3_Data',            # pipe 3 data
    'LABEL_E849B2': 'Naka_AccGerman_Pipe3_Vals1',           # ~95 values
    'LABEL_E849B6': 'Naka_AccGerman_Pipe3_Str95',           # .asciz "~95"
    'LABEL_E849BA': 'Naka_AccGerman_Pipe3_EmptyA',          # aligned_string ""
    'LABEL_E849BC': 'Naka_AccGerman_Pipe3_EmptyB',          # aligned_string ""
    'LABEL_E849BE': 'Naka_AccGerman_Pipe4_Data',            # pipe 4 data
    'LABEL_E849F2': 'Naka_AccGerman_Pipe4_Vals1',           # ~95 values
    'LABEL_E849F6': 'Naka_AccGerman_Pipe4_Str95',           # .asciz "~95"
    'LABEL_E84A0E': 'Naka_AccGerman_Pipe5_Data',            # pipe 5 data
    'LABEL_E84A42': 'Naka_AccGerman_Pipe5_Pad',             # .byte 0x00, 0xff
    'LABEL_E84A44': 'Naka_AccGerman_Pipe5_Vals',            # ~95 values
    'LABEL_E84A58': 'Naka_AccGerman_Pipe6_Data',            # pipe 6 data
    'LABEL_E84A8C': 'Naka_AccGerman_Pipe6_PadA',            # .byte 0x00, 0xff
    'LABEL_E84AA4': 'Naka_AccGerman_Pipe7_Data',            # pipe 7 data
    'LABEL_E84AD8': 'Naka_AccGerman_Pipe7_EmptyStr',        # aligned_string ""
    'LABEL_E84ADA': 'Naka_AccGerman_Pipe7_Vals',            # ~95 values
    'LABEL_E84AE6': 'Naka_AccGerman_Pipe8_Data',            # pipe 8 data
    'LABEL_E84B1A': 'Naka_AccGerman_Pipe8_PadA',            # .byte 0x00, 0xff
    'LABEL_E84B1C': 'Naka_AccGerman_Pipe8_PadB',            # .byte 0x00, 0xff
    'LABEL_E84B1E': 'Naka_AccGerman_Pipe8_Str95',           # .asciz "~95"
    'LABEL_E84B22': 'Naka_AccGerman_Pipe8_Vals',            # ~95 values
    'LABEL_E84B26': 'Naka_AccGerman_ScrollMeta',             # scroll metadata

    # Italian accordion type (lines 2454-2625)
    'LABEL_E84B3C': 'Naka_AccItalian_Type35_Main',          # NAKA_TYPE_0x35
    'LABEL_E84B60': 'Naka_AccItalian_TypeLabel',             # NAKA_TYPE_LABEL "TYPE : ITALIAN"
    'LABEL_E84B90': 'Naka_AccItalian_GridDisplay',           # accordion grid display data
    'LABEL_E84BAA': 'Naka_AccItalian_Bass1_4E',             # NAKA_TYPE_0x4E
    'LABEL_E84BD6': 'Naka_AccItalian_Bass1_Str',            # .asciz "BASS1"
    'LABEL_E84BE2': 'Naka_AccItalian_Bass2_4E',             # NAKA_TYPE_0x4E
    'LABEL_E84C0E': 'Naka_AccItalian_Bass2_Str',            # .asciz "BASS2"
    'LABEL_E84C1A': 'Naka_AccItalian_Pipe1_Data',           # pipe 1 data
    'LABEL_E84C4E': 'Naka_AccItalian_Pipe1_Str95',          # .asciz "~95"
    'LABEL_E84C52': 'Naka_AccItalian_Pipe1_Pad',            # .byte 0x00, 0xff
    'LABEL_E84C54': 'Naka_AccItalian_Pipe1_Vals',           # ~95 values
    'LABEL_E84C5C': 'Naka_AccItalian_Pipe2_Data',           # pipe 2 data
    'LABEL_E84C90': 'Naka_AccItalian_Pipe2_Vals1',          # ~95 values
    'LABEL_E84C94': 'Naka_AccItalian_Pipe2_Pads',           # pad bytes
    'LABEL_E84C9A': 'Naka_AccItalian_Pipe3_Data',           # pipe 3 data
    'LABEL_E84CCE': 'Naka_AccItalian_Pipe3_Str95',          # .asciz "~95"
    'LABEL_E84CD2': 'Naka_AccItalian_Pipe3_Vals',           # ~95 values
    'LABEL_E84CD6': 'Naka_AccItalian_Pipe3_EmptyStr',       # aligned_string ""
    'LABEL_E84CDA': 'Naka_AccItalian_Pipe4_Data',           # pipe 4 data
    'LABEL_E84D0E': 'Naka_AccItalian_Pipe4_Str95',          # .asciz "~95"
    'LABEL_E84D12': 'Naka_AccItalian_Pipe4_Vals',           # ~95 values
    'LABEL_E84D26': 'Naka_AccItalian_Pipe5_Data',           # pipe 5 data
    'LABEL_E84D5A': 'Naka_AccItalian_Pipe5_PadA',           # .byte 0x00, 0xff
    'LABEL_E84D5C': 'Naka_AccItalian_Pipe5_Vals',           # ~95 values
    'LABEL_E84D70': 'Naka_AccItalian_Pipe6_Data',           # pipe 6 data
    'LABEL_E84DA4': 'Naka_AccItalian_Pipe6_PadA',           # .byte 0x00, 0xff
    'LABEL_E84DB8': 'Naka_AccItalian_Pipe7_Data',           # pipe 7 data
    'LABEL_E84DEC': 'Naka_AccItalian_Pipe7_PadA',           # .byte 0x00, 0xff
    'LABEL_E84DEE': 'Naka_AccItalian_Pipe7_Vals',           # ~95 values
    'LABEL_E84DFA': 'Naka_AccItalian_Pipe8_Data',           # pipe 8 data
    'LABEL_E84E2E': 'Naka_AccItalian_Pipe8_PadA',           # .byte 0x00, 0xff
    'LABEL_E84E30': 'Naka_AccItalian_Pipe8_EmptyStr',       # aligned_string ""
    'LABEL_E84E32': 'Naka_AccItalian_Pipe8_Vals',           # ~95 values
    'LABEL_E84E3A': 'Naka_AccItalian_ScrollMeta',            # scroll metadata
}

if __name__ == '__main__':
    print(f"Renaming {len(renames)} labels...")
    rename_labels(renames)
    print("Done!")
