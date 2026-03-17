#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in region E16B1C-E1732A.

This region contains two interleaved sections:
1. Widget field descriptor tables (E16B1C-E16C84): StrDesc-style tables
   referenced by naka_header entries, listing field names for each box widget.
2. Naka_header descriptor table (E16C84-E1732A): a flat array of box widget
   descriptors, each with box proc pointer, naka_header, size/flags, and
   pointers to a name string, an empty string, and a field descriptor table.
   The name strings themselves live in the upper part of this region
   (E17076-E17316), interleaved with the descriptor entries.
"""
import os, re

RENAMES = [
    # -----------------------------------------------------------------------
    # StrDesc_CstmCpNameBox: one-field descriptor for PsCstmCpNameBoxProc
    # Fields: "cstmno" (custom number)
    # Referenced by naka_header table at E16B14 (for PsCstmCpNameBoxProc)
    # -----------------------------------------------------------------------
    ('LABEL_E16B14', 'StrDesc_CstmCpNameBox',    'Field descriptor table for PsCstmCpNameBox'),
    ('LABEL_E16B1C', 'StrVal_Empty_CstmCpName',  'Empty string slot in CstmCpNameBox descriptor'),
    ('LABEL_E16B1E', 'StrFld_CstmCpName_CstmNo', 'Field name "cstmno" for CstmCpNameBox'),

    # -----------------------------------------------------------------------
    # StrDesc_AcApcToggle: two-field descriptor for AcApcToggleProc
    # Fields: "pman_ad" (panel manager address), "func"
    # Referenced by naka_header table at E16B26 (for AcApcToggleProc)
    # -----------------------------------------------------------------------
    ('LABEL_E16B26', 'StrDesc_AcApcToggle',       'Field descriptor table for AcApcToggle'),
    ('LABEL_E16B32', 'StrVal_Empty_AcApcToggle',  'Empty string slot in AcApcToggle descriptor'),
    ('LABEL_E16B34', 'StrFld_ApcToggle_PmanAd',   'Field name "pman_ad" for AcApcToggle'),
    ('LABEL_E16B3C', 'StrFld_ApcToggle_Func',     'Field name "func" for AcApcToggle'),

    # -----------------------------------------------------------------------
    # StrDesc_AcSndArgGrid: three-field descriptor for AcSndArgGridBoxProc
    # Fields: "func", "fixedrow", "fixedcol"
    # Referenced by naka_header table at E16B42 (for AcSndArgGridBoxProc)
    # -----------------------------------------------------------------------
    ('LABEL_E16B42', 'StrDesc_AcSndArgGrid',       'Field descriptor table for AcSndArgGridBox'),
    ('LABEL_E16B52', 'StrVal_Empty_AcSndArgGrid',  'Empty string slot in AcSndArgGrid descriptor'),
    ('LABEL_E16B54', 'StrFld_SndArgGrid_Func',     'Field name "func" for AcSndArgGridBox'),
    ('LABEL_E16B5A', 'StrFld_SndArgGrid_FixedRow', 'Field name "fixedrow" for AcSndArgGridBox'),
    ('LABEL_E16B64', 'StrFld_SndArgGrid_FixedCol', 'Field name "fixedcol" for AcSndArgGridBox'),

    # -----------------------------------------------------------------------
    # StrDesc_PsParaListBox: five-field descriptor for PsParaListBoxProc
    # Fields: "sel_num", "row", "column", "fontcolor", "font"
    # Referenced by naka_header table at E16B6E (for PsParaListBoxProc)
    # Note: E16B90 = raw bytes "row\0", E16BA6 = raw bytes for "font\0"
    #       (disassembler shows jr/branch mnemonics due to data/code ambiguity)
    # -----------------------------------------------------------------------
    ('LABEL_E16B6E', 'StrDesc_PsParaListBox',      'Field descriptor table for PsParaListBox'),
    ('LABEL_E16B86', 'StrVal_Empty_PsParaList',    'Empty string slot in PsParaListBox descriptor'),
    ('LABEL_E16B88', 'StrFld_ParaList_SelNum',     'Field name "sel_num" for PsParaListBox'),
    ('LABEL_E16B90', 'StrFld_ParaList_Row',        'Field name "row" (raw bytes) for PsParaListBox'),
    ('LABEL_E16B94', 'StrFld_ParaList_Column',     'Field name "column" for PsParaListBox'),
    ('LABEL_E16B9C', 'StrFld_ParaList_FontColor',  'Field name "fontcolor" for PsParaListBox'),
    ('LABEL_E16BA6', 'StrFld_ParaList_Font',       'Field name "font" (raw bytes) for PsParaListBox'),

    # -----------------------------------------------------------------------
    # StrDesc_PsSCTxtBox2: one-entry descriptor for PsSCTxtBox2Proc
    # Fields: "" (empty only - no named fields)
    # Referenced by naka_header table at E16BB2 (for PsSCTxtBox2Proc)
    # -----------------------------------------------------------------------
    ('LABEL_E16BB2', 'StrDesc_PsSCTxtBox2',        'Field descriptor table for PsSCTxtBox2'),
    ('LABEL_E16BB6', 'StrVal_Empty_PsSCTxtBox2',   'Empty string slot in PsSCTxtBox2 descriptor'),

    # -----------------------------------------------------------------------
    # StrDesc_VwVariBox: six-field descriptor for VwVariBoxProc
    # Fields: "mspbnk", "selected", "editsw", "align", "fontcolor", "font"
    # Referenced by naka_header table at E16BB8 (for VwVariBoxProc)
    # -----------------------------------------------------------------------
    ('LABEL_E16BB8', 'StrDesc_VwVariBox',          'Field descriptor table for VwVariBox'),
    ('LABEL_E16BD4', 'StrVal_Empty_VwVariBox',     'Empty string slot in VwVariBox descriptor'),
    ('LABEL_E16BD6', 'StrFld_VwVari_MspBnk',       'Field name "mspbnk" for VwVariBox'),
    ('LABEL_E16BDE', 'StrFld_VwVari_Selected',     'Field name "selected" for VwVariBox'),
    ('LABEL_E16BE8', 'StrFld_VwVari_EditSw',       'Field name "editsw" for VwVariBox'),
    ('LABEL_E16BF0', 'StrFld_VwVari_Align',        'Field name "align" for VwVariBox'),
    ('LABEL_E16BF6', 'StrFld_VwVari_FontColor',    'Field name "fontcolor" for VwVariBox'),
    ('LABEL_E16C00', 'StrFld_VwVari_Font',         'Field name "font" for VwVariBox'),

    # -----------------------------------------------------------------------
    # StrDesc_YajirushiBox: five-field descriptor for Yajirushi (arrow) widget
    # (LABEL_F1DFB1 proc = arrow/pointer widget)
    # Fields: "tail_y_rate", "tail_x_rate", "dir", "frame_only", "color"
    # Referenced by naka_header table at E16C06 (for F1DFB1/Yajirushi proc)
    # Note: E16C38 = raw bytes "dir\0"
    # -----------------------------------------------------------------------
    ('LABEL_E16C06', 'StrDesc_YajirushiBox',        'Field descriptor table for Yajirushi arrow widget'),
    ('LABEL_E16C1E', 'StrVal_Empty_Yajirushi',      'Empty string slot in Yajirushi descriptor'),
    ('LABEL_E16C20', 'StrFld_Yajirushi_TailYRate',  'Field name "tail_y_rate" for Yajirushi'),
    ('LABEL_E16C2C', 'StrFld_Yajirushi_TailXRate',  'Field name "tail_x_rate" for Yajirushi'),
    ('LABEL_E16C38', 'StrFld_Yajirushi_Dir',        'Field name "dir" (raw bytes) for Yajirushi'),
    ('LABEL_E16C3C', 'StrFld_Yajirushi_FrameOnly',  'Field name "frame_only" for Yajirushi'),
    ('LABEL_E16C48', 'StrFld_Yajirushi_Color',      'Field name "color" for Yajirushi'),

    # -----------------------------------------------------------------------
    # StrDesc_CmpNameMenu: one-entry descriptor for CmpNameMenuBoxProc
    # Fields: "" (empty only)
    # Referenced by naka_header table at E16C4E (for CmpNameMenuBoxProc)
    # -----------------------------------------------------------------------
    ('LABEL_E16C4E', 'StrDesc_CmpNameMenuBox',      'Field descriptor table for CmpNameMenuBox'),
    ('LABEL_E16C52', 'StrVal_Empty_CmpNameMenu',    'Empty string slot in CmpNameMenuBox descriptor'),

    # -----------------------------------------------------------------------
    # StrDesc_S2cGridBox: three-field descriptor for S2cGridBoxProc
    # Fields: "func", "fixedrow", "fixedcol"
    # Referenced by naka_header table at E16C54 (for S2cGridBoxProc)
    # -----------------------------------------------------------------------
    ('LABEL_E16C54', 'StrDesc_S2cGridBox',          'Field descriptor table for S2cGridBox'),
    ('LABEL_E16C64', 'StrVal_Empty_S2cGridBox',     'Empty string slot in S2cGridBox descriptor'),
    ('LABEL_E16C66', 'StrFld_S2cGrid_Func',         'Field name "func" for S2cGridBox'),
    ('LABEL_E16C6C', 'StrFld_S2cGrid_FixedRow',     'Field name "fixedrow" for S2cGridBox'),
    ('LABEL_E16C76', 'StrFld_S2cGrid_FixedCol',     'Field name "fixedcol" for S2cGridBox'),

    # -----------------------------------------------------------------------
    # StrDesc_PsStylCnvVer: one-entry descriptor for PsStylCnvVerProc
    # Fields: "" (empty only)
    # Referenced by naka_header table at E16C80 (for PsStylCnvVerProc)
    # -----------------------------------------------------------------------
    ('LABEL_E16C80', 'StrDesc_PsStylCnvVer',        'Field descriptor table for PsStylCnvVer'),
    ('LABEL_E16C84', 'StrVal_Empty_PsStylCnvVer',   'Empty string slot; also marks start of naka_header table'),

    # -----------------------------------------------------------------------
    # E16FF2: boundary label within the naka_header descriptor table.
    # Falls at the start of the VwVariBoxProc entry's data pointer block
    # (between naka_header bytes and the four data pointers).
    # May be referenced externally as a table entry point.
    # -----------------------------------------------------------------------
    ('LABEL_E16FF2', 'NakaDesc_VwVariBox_DataPtrs', 'Start of VwVariBox descriptor data pointers in naka_header table'),

    # -----------------------------------------------------------------------
    # Name strings for each box widget in the naka_header table.
    # Each box has two labels: StrEmpty_BoxName (= "") and StrName_BoxName (= "BoxName").
    # Some boxes also have prefix bytes (e.g. "XXj\0" or "C\0") before the
    # name string or empty string - these serve as alignment/type markers.
    # -----------------------------------------------------------------------

    # PsStylCnvVer
    ('LABEL_E17076', 'StrEmpty_PsStylCnvVer',     'Empty string prefix for PsStylCnvVer box name'),
    ('LABEL_E17078', 'StrName_PsStylCnvVer',      'Box name string "PsStylCnvVer"'),

    # S2cGridBox (has "XXj\0" prefix bytes before empty string at E17086)
    ('LABEL_E17086', 'StrPrefix_S2cGridBox',       'Prefix bytes "XXj\\0" + name "S2cGridBox" for S2cGridBox'),

    # CmpNameMenuBox
    ('LABEL_E17098', 'StrName_CmpNameMenuBox',     'Box name string "CmpNameMenuBox"'),

    # Yajirushi (arrow widget) - extra strings used by the Yajirushi proc
    ('LABEL_E170A8', 'StrExtra_Yajirushi_JpChars', 'Extra Japanese/encoded string "^GBBB" for Yajirushi'),
    ('LABEL_E170AE', 'StrName_YajirushiBox',       'Box name string "Yajirushi"'),
    ('LABEL_E170B8', 'StrExtra_Yajirushi_JpChars2','Extra Japanese/encoded string "c^demC" for Yajirushi'),

    # VwVariBox
    ('LABEL_E170C0', 'StrName_VwVariBox',          'Box name string "VwVariBox"'),

    # PsSCTxtBox2
    ('LABEL_E170CA', 'StrEmpty_PsSCTxtBox2',       'Empty string prefix for PsSCTxtBox2 box name'),
    ('LABEL_E170CC', 'StrName_PsSCTxtBox2',        'Box name string "PSSCTxtBox2"'),

    # PsSCTxtBox
    ('LABEL_E170D8', 'StrEmpty_PsSCTxtBox',        'Empty string prefix for PsSCTxtBox box name'),
    ('LABEL_E170DA', 'StrName_PsSCTxtBox',         'Box name string "PsSCTxtBox"'),

    # PsParaListBox (E170E6 = Japanese/encoded extra string for para list box)
    ('LABEL_E170E6', 'StrExtra_ParaList_JpChars',  'Extra encoded string "c^AAn" for PsParaListBox'),
    ('LABEL_E170EC', 'StrName_PsParaListBox',      'Box name string "PsParaListBox"'),

    # AcSndArgGridBox (has "XXj\0" prefix bytes)
    ('LABEL_E170FA', 'StrPrefix_AcSndArgGrid',     'Prefix bytes "XXj\\0" before AcSndArgGridBox name'),
    ('LABEL_E170FE', 'StrName_AcSndArgGridBox',    'Box name string "AcSndArgGridBox"'),

    # AcApcToggle (has encoded bytes + "AcApcToggle" string + "C\0" suffix)
    ('LABEL_E1710E', 'StrPrefix_AcApcToggle',      'Prefix/suffix bytes around AcApcToggle box name'),

    # PsCstmCpNameBox
    ('LABEL_E17120', 'StrName_PsCstmCpNameBox',    'Box name string "PsCstmCpNameBox"'),

    # PsMspNameBnk
    ('LABEL_E17130', 'StrEmpty_PsMspNameBnk',      'Empty string prefix for PsMspNameBnk box name'),
    ('LABEL_E17132', 'StrName_PsMspNameBnk',       'Box name string "PsMspNameBnk"'),

    # PsMspRecBnkBox
    ('LABEL_E17140', 'StrEmpty_PsMspRecBnkBox',    'Empty string prefix for PsMspRecBnkBox box name'),
    ('LABEL_E17142', 'StrName_PsMspRecBnkBox',     'Box name string "PsMspRecBnkBox"'),

    # PsMspRecPadBox
    ('LABEL_E17152', 'StrEmpty_PsMspRecPadBox',    'Empty string prefix for PsMspRecPadBox box name'),
    ('LABEL_E17154', 'StrName_PsMspRecPadBox',     'Box name string "PsMspRecPadBox"'),

    # PsMspMemBox
    ('LABEL_E17164', 'StrEmpty_PsMspMemBox',       'Empty string prefix for PsMspMemBox box name'),
    ('LABEL_E17166', 'StrName_PsMspMemBox',        'Box name string "PsMspMemBox"'),

    # PsMspMeasBox
    ('LABEL_E17172', 'StrEmpty_PsMspMeasBox',      'Empty string prefix for PsMspMeasBox box name'),
    ('LABEL_E17174', 'StrName_PsMspMeasBox',       'Box name string "PsMspMeasBox"'),

    # AcEasyCmpGridBox (has "XXj\0" prefix bytes)
    ('LABEL_E17182', 'StrPrefix_AcEasyCmpGrid',    'Prefix bytes "XXj\\0" before AcEasyCmpGridBox name'),
    ('LABEL_E17186', 'StrName_AcEasyCmpGridBox',   'Box name string "AcEasyCmpGridBox"'),

    # PsRgpSetBnkBox
    ('LABEL_E17198', 'StrEmpty_PsRgpSetBnkBox',   'Empty string prefix for PsRgpSetBnkBox box name'),
    ('LABEL_E1719A', 'StrName_PsRgpSetBnkBox',    'Box name string "PsRgpSetBnkBox"'),

    # AcCmpSetGridBox (has "XXj\0" prefix bytes)
    ('LABEL_E171AA', 'StrPrefix_AcCmpSetGrid',     'Prefix bytes "XXj\\0" before AcCmpSetGridBox name'),
    ('LABEL_E171AE', 'StrName_AcCmpSetGridBox',    'Box name string "AcCmpSetGridBox"'),

    # PsNameMemBox
    ('LABEL_E171BE', 'StrEmpty_PsNameMemBox',      'Empty string prefix for PsNameMemBox box name'),
    ('LABEL_E171C0', 'StrName_PsNameMemBox',       'Box name string "PsNameMemBox"'),

    # PsCmpCpFPtnBox
    ('LABEL_E171CE', 'StrEmpty_PsCmpCpFPtnBox',    'Empty string prefix for PsCmpCpFPtnBox box name'),
    ('LABEL_E171D0', 'StrName_PsCmpCpFPtnBox',     'Box name string "PsCmpCpFPtnBox"'),

    # PsCmpCpFVariBox
    ('LABEL_E171E0', 'StrEmpty_PsCmpCpFVariBox',   'Empty string prefix for PsCmpCpFVariBox box name'),
    ('LABEL_E171E2', 'StrName_PsCmpCpFVariBox',    'Box name string "PsCmpCpFVariBox"'),

    # PsCmpCpFGrpBox
    ('LABEL_E171F2', 'StrEmpty_PsCmpCpFGrpBox',    'Empty string prefix for PsCmpCpFGrpBox box name'),
    ('LABEL_E171F4', 'StrName_PsCmpCpFGrpBox',     'Box name string "PsCmpCpFGrpBox"'),

    # AcCmpTempoBox
    ('LABEL_E17204', 'StrEmpty_AcCmpTempoBox',     'Empty string prefix for AcCmpTempoBox box name'),
    ('LABEL_E17206', 'StrName_AcCmpTempoBox',      'Box name string "AcCmpTempoBox"'),

    # PsMspBnkNameBox (has "C\0" prefix bytes)
    ('LABEL_E17214', 'StrPrefix_PsMspBnkNameBox',  'Prefix byte "C\\0" before PsMspBnkNameBox name'),
    ('LABEL_E17216', 'StrName_PsMspBnkNameBox',    'Box name string "PsMspBnkNameBox"'),

    # AcMspBnkSlBox (has "C\0" prefix bytes)
    ('LABEL_E17226', 'StrPrefix_AcMspBnkSlBox',    'Prefix byte "C\\0" before AcMspBnkSlBox name'),
    ('LABEL_E17228', 'StrName_AcMspBnkSlBox',      'Box name string "AcMspBnkSlBox"'),

    # AcApcMdBox (has "C\0" prefix bytes)
    ('LABEL_E17236', 'StrPrefix_AcApcMdBox',       'Prefix byte "C\\0" before AcApcMdBox name'),
    ('LABEL_E17238', 'StrName_AcApcMdBox',         'Box name string "AcApcMdBox"'),

    # AcCmpMdBox (has "C\0" prefix bytes)
    ('LABEL_E17244', 'StrPrefix_AcCmpMdBox',       'Prefix byte "C\\0" before AcCmpMdBox name'),
    ('LABEL_E17246', 'StrName_AcCmpMdBox',         'Box name string "AcCmpMdBox"'),

    # PsCtmAttStrBox
    ('LABEL_E17252', 'StrEmpty_PsCtmAttStrBox',    'Empty string prefix for PsCtmAttStrBox box name'),
    ('LABEL_E17254', 'StrName_PsCtmAttStrBox',     'Box name string "PsCtmAttStrBox"'),

    # PsCstmCpSwBox (has "C\0" prefix bytes)
    ('LABEL_E17264', 'StrPrefix_PsCstmCpSwBox',    'Prefix byte "C\\0" before PsCstmCpSwBox name'),
    ('LABEL_E17266', 'StrName_PsCstmCpSwBox',      'Box name string "PsCstmCpSwBox"'),

    # PsCstmCpBnkBox (has "C\0" prefix bytes)
    ('LABEL_E17274', 'StrPrefix_PsCstmCpBnkBox',   'Prefix byte "C\\0" before PsCstmCpBnkBox name'),
    ('LABEL_E17276', 'StrName_PsCstmCpBnkBox',     'Box name string "PsCstmCpBnkBox"'),

    # PsS2cTransBox
    ('LABEL_E17286', 'StrEmpty_PsS2cTransBox',     'Empty string prefix for PsS2cTransBox box name'),
    ('LABEL_E17288', 'StrName_PsS2cTransBox',      'Box name string "PsS2cTransBox"'),

    # PsSeqSongNoBox
    ('LABEL_E17296', 'StrEmpty_PsSeqSongNoBox',    'Empty string prefix for PsSeqSongNoBox box name'),
    ('LABEL_E17298', 'StrName_PsSeqSongNoBox',     'Box name string "PsSeqSongNoBox"'),

    # PsS2cLmeasBox
    ('LABEL_E172A8', 'StrEmpty_PsS2cLmeasBox',     'Empty string prefix for PsS2cLmeasBox box name'),
    ('LABEL_E172AA', 'StrName_PsS2cLmeasBox',      'Box name string "PsS2cLmeasBox"'),

    # PsS2cFmeasBox
    ('LABEL_E172B8', 'StrEmpty_PsS2cFmeasBox',     'Empty string prefix for PsS2cFmeasBox box name'),
    ('LABEL_E172BA', 'StrName_PsS2cFmeasBox',      'Box name string "PsS2cFmeasBox"'),

    # AcS2cMemNoBox
    ('LABEL_E172C8', 'StrEmpty_AcS2cMemNoBox',     'Empty string prefix for AcS2cMemNoBox box name'),
    ('LABEL_E172CA', 'StrName_AcS2cMemNoBox',      'Box name string "AcS2cMemNoBox"'),

    # PsCmpMemBox
    ('LABEL_E172D8', 'StrEmpty_PsCmpMemBox',       'Empty string prefix for PsCmpMemBox box name'),
    ('LABEL_E172DA', 'StrName_PsCmpMemBox',        'Box name string "PsCmpMemBox"'),

    # PsCmpMeasBox
    ('LABEL_E172E6', 'StrEmpty_PsCmpMeasBox',      'Empty string prefix for PsCmpMeasBox box name'),
    ('LABEL_E172E8', 'StrName_PsCmpMeasBox',       'Box name string "PsCmpMeasBox"'),

    # PsCmpQtzBox
    ('LABEL_E172F6', 'StrEmpty_PsCmpQtzBox',       'Empty string prefix for PsCmpQtzBox box name'),
    ('LABEL_E172F8', 'StrName_PsCmpQtzBox',        'Box name string "PsCmpQtzBox"'),

    # AcCmpRecBox (has "CC\0\xff" prefix bytes - double "C" marker + terminator)
    ('LABEL_E17304', 'StrPrefix_AcCmpRecBox',      'Prefix bytes "CC\\0\\xff" before AcCmpRecBox name'),
    ('LABEL_E17308', 'StrName_AcCmpRecBox',        'Box name string "AcCmpRecBox"'),

    # AcMemNoBox
    ('LABEL_E17314', 'StrEmpty_AcMemNoBox',        'Empty string prefix for AcMemNoBox box name'),
    ('LABEL_E17316', 'StrName_AcMemNoBox',         'Box name string "AcMemNoBox"'),

    # -----------------------------------------------------------------------
    # E1732A: start of the NEXT section (method table pointer list for
    # MT_* method strings, referenced at E173F6 onwards).
    # This label is the last label in our range - it is the boundary.
    # -----------------------------------------------------------------------
    ('LABEL_E1732A', 'NakaMethodTable_PtrsStart',  'Start of MT_* method name pointer table'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')
    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')
    renamed = 0
    for old_label, new_label, comment in RENAMES:
        if old_label not in content:
            print(f'  WARNING: {old_label} not found, skipping')
            continue
        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        new_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)
        if new_content != content:
            content = new_content
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:40s} ({refs} refs)')
    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))
    print(f'\nRenamed {renamed} labels in maincpu')


if __name__ == '__main__':
    main()
