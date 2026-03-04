#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in region E55778-E7F7BC.
Uses binary I/O to handle encoding safely.

This region covers:
  - NAKA UI widget property descriptor tables (E55778-E559E0)
  - MidiMenu message type table (E55CE0)
  - MidiMenu proc name string table (E55DF2)
  - NAKA include block: reverb/EQ, control-message, split-point data (E55E36)
  - NAKA UI object descriptor tables continued in main file:
      MidiCommonSetting, MidiInOutSetting, MidiPresets, MidiExclusive,
      MidiComputerConnection, MidiPanelMemoryOutput, MidiSetup,
      EntertainerVocal, EntertainerFade, SplitSetting, MainFunc dispatch
  - Bitmap data (Bitmap_SplitPoint_*, Bitmap_MIDIConnections_*, Bitmap_Bmphk)
  - MidiPart display data, page strings, MIDI channel display, octave strings,
    Recv/Trans/After format strings, MIDI Part column widths (E7ECF2-E7EE5C)
  - Harmony local string, GM mode attention strings (E7EFFC-E7F14A)
  - GM mode on/off prompt strings and split-point key prompt strings (E7F150-E7F778)
  - Split-point key name table (E7F778)
"""
import os, re

RENAMES = [
    # -----------------------------------------------------------------------
    # E55768 region: page/window UI widget property descriptor tables
    # The table at E55768 (before our region) references these strings.
    # -----------------------------------------------------------------------
    ('LABEL_E55778', 'NakaDesc_PageWindow_NullStr',    'Empty string for page/window descriptor null entry'),
    ('LABEL_E5577A', 'NakaDesc_PageWindow_Window1',    'String "window1" in page/window descriptor'),
    ('LABEL_E55782', 'NakaDesc_PageWindow_Window0',    'String "window0" in page/window descriptor'),
    ('LABEL_E5578A', 'NakaDesc_PageWindow_Page',       'String "page" in page/window descriptor'),
    ('LABEL_E55790', 'NakaDesc_OnOffStyle_Table',      'Pointer table for onoff/style widget descriptor'),
    ('LABEL_E557A4', 'NakaDesc_OnOffStyle_NullStr',    'Empty string for onoff/style descriptor null entry'),
    ('LABEL_E557A6', 'NakaDesc_OnOffStyle_Onoff',      'String "onoff" in onoff/style descriptor'),
    ('LABEL_E557AC', 'NakaDesc_OnOffStyle_Str',        'String "str" in onoff/style descriptor'),
    ('LABEL_E557B0', 'NakaDesc_OnOffStyle_Func',       'String "func" in onoff/style descriptor'),
    ('LABEL_E557B6', 'NakaDesc_OnOffStyle_Style',      'String "style" in onoff/style descriptor'),
    ('LABEL_E557C0', 'NakaDesc_PmanOnOff_NullTerm',    'Null terminator / end marker before pman on/off descriptor'),
    ('LABEL_E557C2', 'NakaDesc_PmanOnOff1_Table',      'Pointer table for first pman on/off data descriptor'),
    ('LABEL_E557DA', 'NakaDesc_PmanOnOff1_NullEntry',  'Null entry in first pman on/off descriptor'),
    ('LABEL_E557DC', 'NakaDesc_PmanOnOff1_PmanOut',    'String "pman_out" in first pman on/off descriptor'),
    ('LABEL_E557E6', 'NakaDesc_PmanOnOff1_PmanAdr',    'String "pman_adr" in first pman on/off descriptor'),
    ('LABEL_E557F0', 'NakaDesc_PmanOnOff1_OffStr',     'String "off_str" in first pman on/off descriptor'),
    ('LABEL_E557F8', 'NakaDesc_PmanOnOff1_OnStr',      'String "on_str" in first pman on/off descriptor'),
    ('LABEL_E55800', 'NakaDesc_PmanOnOff1_Data',       'String "data" in first pman on/off descriptor'),
    ('LABEL_E55806', 'NakaDesc_PmanOnOff2_Table',      'Pointer table for second pman on/off data descriptor'),
    ('LABEL_E5581E', 'NakaDesc_PmanOnOff2_NullEntry',  'Null entry in second pman on/off descriptor'),
    ('LABEL_E55820', 'NakaDesc_PmanOnOff2_PmanOut',    'String "pman_out" in second pman on/off descriptor'),
    ('LABEL_E5582A', 'NakaDesc_PmanOnOff2_PmanAdr',    'String "pman_adr" in second pman on/off descriptor'),
    ('LABEL_E55834', 'NakaDesc_PmanOnOff2_OffStr',     'String "off_str" in second pman on/off descriptor'),
    ('LABEL_E5583C', 'NakaDesc_PmanOnOff2_OnStr',      'String "on_str" in second pman on/off descriptor'),
    ('LABEL_E55844', 'NakaDesc_PmanOnOff2_Data',       'String "data" in second pman on/off descriptor'),

    # -----------------------------------------------------------------------
    # Grid widget property descriptors: groups of {null, func, fixedrow, fixedcol}
    # These are NAKA grid box widget descriptor tables used for various MIDI pages.
    # -----------------------------------------------------------------------
    ('LABEL_E5585A', 'NakaDesc_GridBox1_NullEntry',    'Null entry for grid box widget descriptor #1'),
    ('LABEL_E5585C', 'NakaDesc_GridBox1_Func',         'String "func" in grid box widget descriptor #1'),
    ('LABEL_E55862', 'NakaDesc_GridBox1_FixedRow',     'String "fixedrow" in grid box widget descriptor #1'),
    ('LABEL_E5586C', 'NakaDesc_GridBox1_FixedCol',     'String "fixedcol" in grid box widget descriptor #1'),
    ('LABEL_E55886', 'NakaDesc_GridBox2_NullEntry',    'Null entry for grid box widget descriptor #2'),
    ('LABEL_E55888', 'NakaDesc_GridBox2_Func',         'String "func" in grid box widget descriptor #2'),
    ('LABEL_E5588E', 'NakaDesc_GridBox2_FixedRow',     'String "fixedrow" in grid box widget descriptor #2'),
    ('LABEL_E55898', 'NakaDesc_GridBox2_FixedCol',     'String "fixedcol" in grid box widget descriptor #2'),
    ('LABEL_E558B2', 'NakaDesc_GridBox3_NullEntry',    'Null entry for grid box widget descriptor #3'),
    ('LABEL_E558B4', 'NakaDesc_GridBox3_Func',         'String "func" in grid box widget descriptor #3'),
    ('LABEL_E558BA', 'NakaDesc_GridBox3_FixedRow',     'String "fixedrow" in grid box widget descriptor #3'),
    ('LABEL_E558C4', 'NakaDesc_GridBox3_FixedCol',     'String "fixedcol" in grid box widget descriptor #3'),
    ('LABEL_E558DE', 'NakaDesc_GridBox4_NullEntry',    'Null entry for grid box widget descriptor #4'),
    ('LABEL_E558E0', 'NakaDesc_GridBox4_Func',         'String "func" in grid box widget descriptor #4'),
    ('LABEL_E558E6', 'NakaDesc_GridBox4_FixedRow',     'String "fixedrow" in grid box widget descriptor #4'),
    ('LABEL_E558F0', 'NakaDesc_GridBox4_FixedCol',     'String "fixedcol" in grid box widget descriptor #4'),
    ('LABEL_E5590A', 'NakaDesc_GridBox5_NullEntry',    'Null entry for grid box widget descriptor #5'),
    ('LABEL_E5590C', 'NakaDesc_GridBox5_Func',         'String "func" in grid box widget descriptor #5'),
    ('LABEL_E55912', 'NakaDesc_GridBox5_FixedRow',     'String "fixedrow" in grid box widget descriptor #5'),
    ('LABEL_E5591C', 'NakaDesc_GridBox5_FixedCol',     'String "fixedcol" in grid box widget descriptor #5'),
    ('LABEL_E55936', 'NakaDesc_GridBox6_NullEntry',    'Null entry for grid box widget descriptor #6'),
    ('LABEL_E55938', 'NakaDesc_GridBox6_Func',         'String "func" in grid box widget descriptor #6'),
    ('LABEL_E5593E', 'NakaDesc_GridBox6_FixedRow',     'String "fixedrow" in grid box widget descriptor #6'),
    ('LABEL_E55948', 'NakaDesc_GridBox6_FixedCol',     'String "fixedcol" in grid box widget descriptor #6'),
    ('LABEL_E55962', 'NakaDesc_GridBox7_NullEntry',    'Null entry for grid box widget descriptor #7'),
    ('LABEL_E55964', 'NakaDesc_GridBox7_Func',         'String "func" in grid box widget descriptor #7'),
    ('LABEL_E5596A', 'NakaDesc_GridBox7_FixedRow',     'String "fixedrow" in grid box widget descriptor #7'),
    ('LABEL_E55974', 'NakaDesc_GridBox7_FixedCol',     'String "fixedcol" in grid box widget descriptor #7'),

    # -----------------------------------------------------------------------
    # Page+grid combo widget descriptor (page + func + fixedrow + fixedcol)
    # -----------------------------------------------------------------------
    ('LABEL_E5597E', 'NakaDesc_PageGridBox1_Table',    'Pointer table for page+grid widget descriptor #1'),
    ('LABEL_E55992', 'NakaDesc_PageGridBox1_Null',     'Null entry for page+grid widget descriptor #1'),
    ('LABEL_E55994', 'NakaDesc_PageGridBox1_Page',     'String "page" in page+grid widget descriptor #1'),
    ('LABEL_E5599A', 'NakaDesc_PageGridBox1_Func',     'String "func" in page+grid widget descriptor #1'),
    ('LABEL_E559A0', 'NakaDesc_PageGridBox1_FixedRow', 'String "fixedrow" in page+grid widget descriptor #1'),
    ('LABEL_E559AA', 'NakaDesc_PageGridBox1_FixedCol', 'String "fixedcol" in page+grid widget descriptor #1'),
    ('LABEL_E559B8', 'NakaDesc_PageGridBox2_Table',    'Pointer table for page+grid widget descriptor #2'),
    ('LABEL_E559C8', 'NakaDesc_PageGridBox2_NullStr',  'Empty string in page+grid widget descriptor #2'),
    ('LABEL_E559CA', 'NakaDesc_PageGridBox2_Page',     'String "page" in page+grid widget descriptor #2'),
    ('LABEL_E559D0', 'NakaDesc_PageGridBox2_Func',     'String "func" in page+grid widget descriptor #2'),
    ('LABEL_E559D6', 'NakaDesc_PageGridBox2_FixedRow', 'String "fixedrow" in page+grid widget descriptor #2'),
    ('LABEL_E559E0', 'NakaDesc_PageGridBox2_FixedCol', 'String "fixedcol" in page+grid widget descriptor #2'),

    # -----------------------------------------------------------------------
    # MidiMenu message-type name table (MT_* strings)
    # Pointer table at E55CE0, then strings follow
    # -----------------------------------------------------------------------
    ('LABEL_E55CE0', 'MidiMenu_MsgType_Table',         'Pointer table of MIDI menu message type name strings'),
    ('LABEL_E55D10', 'MsgType_RevEqLoad',              'Message type string "MT_REVEQLOAD"'),
    ('LABEL_E55D1E', 'MsgType_EqLoad',                 'Message type string "MT_EQLOAD"'),
    ('LABEL_E55D28', 'MsgType_RevLoad',                'Message type string "MT_REVLOAD"'),
    ('LABEL_E55D34', 'MsgType_VstSendOk',              'Message type string "MT_VST_SEND_OK"'),
    ('LABEL_E55D44', 'MsgType_VstPstOk',               'Message type string "MT_VST_PST_OK"'),
    ('LABEL_E55D52', 'MsgType_FlashLoad',              'Message type string "MT_FLASHLOAD"'),
    ('LABEL_E55D60', 'MsgType_FlashWrite',             'Message type string "MT_FLASHWRITE"'),
    ('LABEL_E55D6E', 'MsgType_MpstWrite',              'Message type string "MT_MPSTWRITE"'),
    ('LABEL_E55D7C', 'MsgType_MpstLoad',               'Message type string "MT_MPSTLOAD"'),
    ('LABEL_E55D88', 'MsgType_DrawKey',                'Message type string "MT_DRAWKEY"'),
    ('LABEL_E55D94', 'MsgType_ExcSend',                'Message type string "MT_EXCSEND"'),

    # -----------------------------------------------------------------------
    # MidiMenu NAKA proc-name string table
    # Pointer table at E55DF2, then proc names from naka include
    # -----------------------------------------------------------------------
    ('LABEL_E55DF2', 'MidiMenu_NakaProcName_Table',    'Pointer table of NAKA proc name strings for MIDI menu'),
    ('LABEL_E55E36', 'NakaProc_NullEntry',             'Null terminator entry in NAKA proc name table'),

    # -----------------------------------------------------------------------
    # From naka_e55e38_e5a38e.s (included at line 16937):
    # NAKA proc name strings (E55E38-E55F70) are already named in the include.
    # The labels below appear in the naka include and are unnamed table headers
    # or sentinel entries.
    # -----------------------------------------------------------------------

    # -----------------------------------------------------------------------
    # MidiCommonSetting NAKA object descriptor (from main file, post-include)
    # -----------------------------------------------------------------------
    ('LABEL_E5A448', 'NakaObj_MidiCommonSetting_Table',   'Pointer table for MidiCommonSetting NAKA object descriptor'),
    ('LABEL_E5A460', 'NakaObj_MidiCommonSetting_Null1',   'Null placeholder in MidiCommonSetting descriptor'),
    ('LABEL_E5A462', 'NakaObj_MidiCommonSetting_Null2',   'Null placeholder in MidiCommonSetting descriptor'),
    ('LABEL_E5A464', 'NakaObj_MidiCommonSetting_Null3',   'Null placeholder in MidiCommonSetting descriptor'),
    ('LABEL_E5A466', 'NakaObj_MidiCommonSetting_Null4',   'Null placeholder in MidiCommonSetting descriptor'),
    ('LABEL_E5A468', 'NakaObj_MidiCommonSetting_GridBox', 'String "ComSetGridBox" in MidiCommonSetting descriptor'),
    ('LABEL_E5A476', 'NakaObj_MidiCommonSetting_Name',    'String "MidiCommonSetting" in descriptor'),

    # -----------------------------------------------------------------------
    # MidiInOutSetting NAKA object descriptor
    # -----------------------------------------------------------------------
    ('LABEL_E5A488', 'NakaObj_MidiInOutSetting_Table',    'Pointer table for MidiInOutSetting NAKA object descriptor'),
    ('LABEL_E5A4A0', 'NakaObj_MidiInOutSetting_Null1',    'Null placeholder in MidiInOutSetting descriptor'),
    ('LABEL_E5A4A2', 'NakaObj_MidiInOutSetting_Null2',    'Null placeholder in MidiInOutSetting descriptor'),
    ('LABEL_E5A4A4', 'NakaObj_MidiInOutSetting_Null3',    'Null placeholder in MidiInOutSetting descriptor'),
    ('LABEL_E5A4A6', 'NakaObj_MidiInOutSetting_Null4',    'Null placeholder in MidiInOutSetting descriptor'),
    ('LABEL_E5A4A8', 'NakaObj_MidiInOutSetting_GridBox',  'String "InOutGridBox" in MidiInOutSetting descriptor'),
    ('LABEL_E5A4B6', 'NakaObj_MidiInOutSetting_Name',     'String "MidiInOutSetting" in descriptor'),

    # -----------------------------------------------------------------------
    # MidiPresets NAKA object descriptor (large pointer table)
    # -----------------------------------------------------------------------
    ('LABEL_E5A4C8', 'NakaObj_MidiPresets_Table',         'Pointer table for MidiPresets NAKA object descriptor'),
    ('LABEL_E5A5D8', 'NakaObj_MidiPresets_Null1',         'Null placeholder in MidiPresets descriptor'),
    ('LABEL_E5A5DA', 'NakaObj_MidiPresets_Null2',         'Null placeholder in MidiPresets descriptor'),
    ('LABEL_E5A5DC', 'NakaObj_MidiPresets_Null3',         'Null placeholder in MidiPresets descriptor'),
    ('LABEL_E5A5DE', 'NakaObj_MidiPresets_Null4',         'Null placeholder in MidiPresets descriptor'),
    ('LABEL_E5A5E0', 'NakaObj_MidiPresets_Null5',         'Null placeholder in MidiPresets descriptor'),
    ('LABEL_E5A5E2', 'NakaObj_MidiPresets_Null6',         'Null placeholder in MidiPresets descriptor'),
    ('LABEL_E5A5E4', 'NakaObj_MidiPresets_Null7',         'Null placeholder in MidiPresets descriptor'),
    ('LABEL_E5A5E6', 'NakaObj_MidiPresets_Null8',         'Null placeholder in MidiPresets descriptor'),
    ('LABEL_E5A5E8', 'NakaObj_MidiPresets_Null9',         'Null placeholder in MidiPresets descriptor'),
    ('LABEL_E5A5EA', 'NakaObj_MidiPresets_Null10',        'Null placeholder in MidiPresets descriptor'),
    ('LABEL_E5A5EC', 'NakaObj_MidiPresets_MasterWithList','String "MpstMasterWithList" in MidiPresets descriptor'),
    ('LABEL_E5A600', 'NakaObj_MidiPresets_MasterWithNull','Null placeholder before MidiPresetMasterWith name'),
    ('LABEL_E5A602', 'NakaObj_MidiPresets_MasterWith',    'String "MidiPresetMasterWith" in MidiPresets descriptor'),
    ('LABEL_E5A618', 'NakaObj_MidiPresets_MWO_Null1',     'Null placeholder in MidiPresetMasterWithout group'),
    ('LABEL_E5A61A', 'NakaObj_MidiPresets_MWO_Null2',     'Null placeholder in MidiPresetMasterWithout group'),
    ('LABEL_E5A61C', 'NakaObj_MidiPresets_MWO_Null3',     'Null placeholder in MidiPresetMasterWithout group'),
    ('LABEL_E5A61E', 'NakaObj_MidiPresets_MWO_Null4',     'Null placeholder in MidiPresetMasterWithout group'),
    ('LABEL_E5A620', 'NakaObj_MidiPresets_MWO_Null5',     'Null placeholder in MidiPresetMasterWithout group'),
    ('LABEL_E5A622', 'NakaObj_MidiPresets_MWO_Null6',     'Null placeholder in MidiPresetMasterWithout group'),
    ('LABEL_E5A624', 'NakaObj_MidiPresets_MWO_Null7',     'Null placeholder in MidiPresetMasterWithout group'),
    ('LABEL_E5A626', 'NakaObj_MidiPresets_MWO_Null8',     'Null placeholder in MidiPresetMasterWithout group'),
    ('LABEL_E5A628', 'NakaObj_MidiPresets_MWO_Null9',     'Null placeholder in MidiPresetMasterWithout group'),
    ('LABEL_E5A62A', 'NakaObj_MidiPresets_MasterWithoutList','String "MpstMasterWithoutList" in descriptor'),
    ('LABEL_E5A640', 'NakaObj_MidiPresets_MasterWithoutNull','Null before MidiPresetMasterWithout name'),
    ('LABEL_E5A642', 'NakaObj_MidiPresets_MasterWithout', 'String "MidiPresetMasterWithout" in descriptor'),
    ('LABEL_E5A65A', 'NakaObj_MidiPresets_SplitNull',     'Null placeholder before MdpstSplitBox'),
    ('LABEL_E5A65C', 'NakaObj_MidiPresets_SplitBox',      'String "MdpstSplitBox" in MidiPresets descriptor'),
    ('LABEL_E5A66A', 'NakaObj_MidiPresets_Page4_Null1',   'Null placeholder in MidiPresetPage4 group'),
    ('LABEL_E5A66C', 'NakaObj_MidiPresets_Page4_Null2',   'Null placeholder in MidiPresetPage4 group'),
    ('LABEL_E5A66E', 'NakaObj_MidiPresets_Page4_Null3',   'Null placeholder in MidiPresetPage4 group'),
    ('LABEL_E5A670', 'NakaObj_MidiPresets_UserWriteList', 'String "MdPresetUserWriteList" in descriptor'),
    ('LABEL_E5A686', 'NakaObj_MidiPresets_Page4',         'String "MidiPresetPage4" in MidiPresets descriptor'),
    ('LABEL_E5A696', 'NakaObj_MidiPresets_Page3_Null1',   'Null placeholder in MidiPresetPage3 group'),
    ('LABEL_E5A698', 'NakaObj_MidiPresets_Page3_Null2',   'Null placeholder in MidiPresetPage3 group'),
    ('LABEL_E5A69A', 'NakaObj_MidiPresets_Page3_Null3',   'Null placeholder in MidiPresetPage3 group'),
    ('LABEL_E5A69C', 'NakaObj_MidiPresets_UserLoadList',  'String "MdPresetUserLoadList" in descriptor'),
    ('LABEL_E5A6B2', 'NakaObj_MidiPresets_Page3',         'String "MidiPresetPage3" in MidiPresets descriptor'),
    ('LABEL_E5A6C2', 'NakaObj_MidiPresets_SWO_Null1',     'Null placeholder in MidiPresetSlaveWithout group'),
    ('LABEL_E5A6C4', 'NakaObj_MidiPresets_SWO_Null2',     'Null placeholder in MidiPresetSlaveWithout group'),
    ('LABEL_E5A6C6', 'NakaObj_MidiPresets_SWO_Null3',     'Null placeholder in MidiPresetSlaveWithout group'),
    ('LABEL_E5A6C8', 'NakaObj_MidiPresets_SWO_Null4',     'Null placeholder in MidiPresetSlaveWithout group'),
    ('LABEL_E5A6CA', 'NakaObj_MidiPresets_SWO_Null5',     'Null placeholder in MidiPresetSlaveWithout group'),
    ('LABEL_E5A6CC', 'NakaObj_MidiPresets_SWO_Null6',     'Null placeholder in MidiPresetSlaveWithout group'),
    ('LABEL_E5A6CE', 'NakaObj_MidiPresets_SWO_Null7',     'Null placeholder in MidiPresetSlaveWithout group'),
    ('LABEL_E5A6D0', 'NakaObj_MidiPresets_SWO_Null8',     'Null placeholder in MidiPresetSlaveWithout group'),
    ('LABEL_E5A6D2', 'NakaObj_MidiPresets_SWO_Null9',     'Null placeholder in MidiPresetSlaveWithout group'),
    ('LABEL_E5A6D4', 'NakaObj_MidiPresets_SlaveWithList', 'String "MpstSlaveWithList" in descriptor'),
    ('LABEL_E5A6E6', 'NakaObj_MidiPresets_SlaveWithNull', 'Null before MidiPresetSlaveWith name'),
    ('LABEL_E5A6E8', 'NakaObj_MidiPresets_SlaveWith',     'String "MidiPresetSlaveWith" in descriptor'),
    ('LABEL_E5A6FC', 'NakaObj_MidiPresets_SW_Null1',      'Null placeholder in MidiPresetSlaveWith group'),
    ('LABEL_E5A6FE', 'NakaObj_MidiPresets_SW_Null2',      'Null placeholder in MidiPresetSlaveWith group'),
    ('LABEL_E5A700', 'NakaObj_MidiPresets_SW_Null3',      'Null placeholder in MidiPresetSlaveWith group'),
    ('LABEL_E5A702', 'NakaObj_MidiPresets_SW_Null4',      'Null placeholder in MidiPresetSlaveWith group'),
    ('LABEL_E5A704', 'NakaObj_MidiPresets_SW_Null5',      'Null placeholder in MidiPresetSlaveWith group'),
    ('LABEL_E5A706', 'NakaObj_MidiPresets_SW_Null6',      'Null placeholder in MidiPresetSlaveWith group'),
    ('LABEL_E5A708', 'NakaObj_MidiPresets_SlaveWithoutList','String "MpstSlaveWithoutList" in descriptor'),
    ('LABEL_E5A71E', 'NakaObj_MidiPresets_SlaveWithoutNull1','Null in MidiPresetSlaveWithout name group'),
    ('LABEL_E5A720', 'NakaObj_MidiPresets_SlaveWithoutNull2','Null in MidiPresetSlaveWithout name group'),
    ('LABEL_E5A722', 'NakaObj_MidiPresets_SlaveWithoutNull3','Null in MidiPresetSlaveWithout name group'),
    ('LABEL_E5A724', 'NakaObj_MidiPresets_SlaveWithoutNull4','Null in MidiPresetSlaveWithout name group'),
    ('LABEL_E5A726', 'NakaObj_MidiPresets_SlaveWithout',  'String "MidiPresetSlaveWithout" in descriptor'),
    ('LABEL_E5A73E', 'NakaObj_MidiPresets_PageCtlNull',   'Null placeholder before MpstPageCtl entries'),
    ('LABEL_E5A740', 'NakaObj_MidiPresets_PageCtl2',      'String "MpstPageCtl2" in MidiPresets descriptor'),
    ('LABEL_E5A74E', 'NakaObj_MidiPresets_PageCtl1',      'String "MpstPageCtl1" in MidiPresets descriptor'),
    ('LABEL_E5A75C', 'NakaObj_MidiPresets_PageBoxNull1',  'Null placeholder before MdPresetPageBox'),
    ('LABEL_E5A75E', 'NakaObj_MidiPresets_PageBoxNull2',  'Null placeholder before MdPresetPageBox'),
    ('LABEL_E5A760', 'NakaObj_MidiPresets_PageBox',       'String "MdPresetPageBox" in MidiPresets descriptor'),
    ('LABEL_E5A770', 'NakaObj_MidiPresets_Name',          'String "MidiPresets" root name in descriptor'),

    # -----------------------------------------------------------------------
    # MidiExclusive NAKA object descriptor
    # -----------------------------------------------------------------------
    ('LABEL_E5A780', 'NakaObj_MidiExclusive_Table',       'Pointer table for MidiExclusive NAKA object descriptor'),
    ('LABEL_E5A7F0', 'NakaObj_MidiExclusive_RcvDotNull',  'Null placeholder before ExcRcvDotBox'),
    ('LABEL_E5A7F2', 'NakaObj_MidiExclusive_RcvDot',      'String "ExcRcvDotBox" in MidiExclusive descriptor'),
    ('LABEL_E5A800', 'NakaObj_MidiExclusive_RcvMsp',      'String "ExcRcvMspBox" in MidiExclusive descriptor'),
    ('LABEL_E5A80E', 'NakaObj_MidiExclusive_RcvSeq',      'String "ExcRcvSeqBox" in MidiExclusive descriptor'),
    ('LABEL_E5A81C', 'NakaObj_MidiExclusive_RcvCmp',      'String "ExcRcvCmpBox" in MidiExclusive descriptor'),
    ('LABEL_E5A82A', 'NakaObj_MidiExclusive_RcvSmem',     'String "ExcRcvSmemBox" in MidiExclusive descriptor'),
    ('LABEL_E5A838', 'NakaObj_MidiExclusive_RcvPmem',     'String "ExcRcvPmemBox" in MidiExclusive descriptor'),
    ('LABEL_E5A846', 'NakaObj_MidiExclusive_RcvShow',     'String "ExcRcvShowBox" in MidiExclusive descriptor'),
    ('LABEL_E5A854', 'NakaObj_MidiExclusive_RcvWinNull1', 'Null placeholder in ExcRcvWindow group'),
    ('LABEL_E5A856', 'NakaObj_MidiExclusive_RcvWinNull2', 'Null placeholder in ExcRcvWindow group'),
    ('LABEL_E5A858', 'NakaObj_MidiExclusive_RcvWinNull3', 'Null placeholder in ExcRcvWindow group'),
    ('LABEL_E5A85A', 'NakaObj_MidiExclusive_RcvWindow',   'String "ExcRcvWindow" in MidiExclusive descriptor'),
    ('LABEL_E5A868', 'NakaObj_MidiExclusive_SendDot',     'String "ExcSendDotBox" in MidiExclusive descriptor'),
    ('LABEL_E5A876', 'NakaObj_MidiExclusive_SendMsp',     'String "ExcSendMspBox" in MidiExclusive descriptor'),
    ('LABEL_E5A884', 'NakaObj_MidiExclusive_SendSeq',     'String "ExcSendSeqBox" in MidiExclusive descriptor'),
    ('LABEL_E5A892', 'NakaObj_MidiExclusive_SendCmp',     'String "ExcSendCmpBox" in MidiExclusive descriptor'),
    ('LABEL_E5A8A0', 'NakaObj_MidiExclusive_SendSmem',    'String "ExcSendSmemBox" in MidiExclusive descriptor'),
    ('LABEL_E5A8B0', 'NakaObj_MidiExclusive_SendPmem',    'String "ExcSendPmemBox" in MidiExclusive descriptor'),
    ('LABEL_E5A8C0', 'NakaObj_MidiExclusive_SendShow',    'String "ExcSendShowBox" in MidiExclusive descriptor'),
    ('LABEL_E5A8D0', 'NakaObj_MidiExclusive_SendWinNull1','Null placeholder in ExcSendWindow group'),
    ('LABEL_E5A8D2', 'NakaObj_MidiExclusive_SendWinNull2','Null placeholder in ExcSendWindow group'),
    ('LABEL_E5A8D4', 'NakaObj_MidiExclusive_SendWinNull3','Null placeholder in ExcSendWindow group'),
    ('LABEL_E5A8D6', 'NakaObj_MidiExclusive_SendWindow',  'String "ExcSendWindow" in MidiExclusive descriptor'),
    ('LABEL_E5A8E4', 'NakaObj_MidiExclusive_ListNull1',   'Null placeholder before ExcListBox'),
    ('LABEL_E5A8E6', 'NakaObj_MidiExclusive_ListNull2',   'Null placeholder before ExcListBox'),
    ('LABEL_E5A8E8', 'NakaObj_MidiExclusive_ListBox',     'String "ExcListBox" in MidiExclusive descriptor'),
    ('LABEL_E5A8F4', 'NakaObj_MidiExclusive_NameNull1',   'Null placeholder before MidiExclusive name'),
    ('LABEL_E5A8F6', 'NakaObj_MidiExclusive_NameNull2',   'Null placeholder before MidiExclusive name'),
    ('LABEL_E5A8F8', 'NakaObj_MidiExclusive_Name',        'String "MidiExclusive" root name in descriptor'),

    # -----------------------------------------------------------------------
    # MidiComputerConnection NAKA object descriptor
    # -----------------------------------------------------------------------
    ('LABEL_E5A9F0', 'NakaObj_MidiComputerConn_Table',    'Pointer table for MidiComputerConnection NAKA descriptor'),
    ('LABEL_E5AA0C', 'NakaObj_MidiComputerConn_Null1',    'Null placeholder in MidiComputerConnection descriptor'),
    ('LABEL_E5AA0E', 'NakaObj_MidiComputerConn_Null2',    'Null placeholder in MidiComputerConnection descriptor'),
    ('LABEL_E5AA10', 'NakaObj_MidiComputerConn_Null3',    'Null placeholder in MidiComputerConnection descriptor'),
    ('LABEL_E5AA12', 'NakaObj_MidiComputerConn_Null4',    'Null placeholder in MidiComputerConnection descriptor'),
    ('LABEL_E5AA14', 'NakaObj_MidiComputerConn_Null5',    'Null placeholder in MidiComputerConnection descriptor'),
    ('LABEL_E5AA16', 'NakaObj_MidiComputerConn_Null6',    'Null placeholder in MidiComputerConnection descriptor'),
    ('LABEL_E5AA18', 'NakaObj_MidiComputerConn_Name',     'String "MidiComputerConnection" in descriptor'),

    # -----------------------------------------------------------------------
    # MidiPanelMemoryOutput (PmemOut) NAKA object descriptor
    # -----------------------------------------------------------------------
    ('LABEL_E5AA30', 'NakaObj_MidiPmemOutput_Table',      'Pointer table for MidiPanelMemoryOutput NAKA descriptor'),
    ('LABEL_E5AA78', 'NakaObj_MidiPmemOutput_Null1',      'Null placeholder in MidiPanelMemoryOutput descriptor'),
    ('LABEL_E5AA7A', 'NakaObj_MidiPmemOutput_Null2',      'Null placeholder in MidiPanelMemoryOutput descriptor'),
    ('LABEL_E5AA7C', 'NakaObj_MidiPmemOutput_Null3',      'Null placeholder in MidiPanelMemoryOutput descriptor'),
    ('LABEL_E5AA7E', 'NakaObj_MidiPmemOutput_Null4',      'Null placeholder in MidiPanelMemoryOutput descriptor'),
    ('LABEL_E5AA80', 'NakaObj_MidiPmemOutput_Null5',      'Null placeholder in MidiPanelMemoryOutput descriptor'),
    ('LABEL_E5AA82', 'NakaObj_MidiPmemOutput_Null6',      'Null placeholder in MidiPanelMemoryOutput descriptor'),
    ('LABEL_E5AA84', 'NakaObj_MidiPmemOutput_Null7',      'Null placeholder in MidiPanelMemoryOutput descriptor'),
    ('LABEL_E5AA86', 'NakaObj_MidiPmemOutput_Null8',      'Null placeholder in MidiPanelMemoryOutput descriptor'),
    ('LABEL_E5AA88', 'NakaObj_MidiPmemOutput_Right',      'String "PmemOutRight" in MidiPmemOutput descriptor'),
    ('LABEL_E5AA96', 'NakaObj_MidiPmemOutput_Left',       'String "PmemOutLeft" in MidiPmemOutput descriptor'),
    ('LABEL_E5AAA2', 'NakaObj_MidiPmemOutput_RNull1',     'Null placeholder in PmemOut right-side group'),
    ('LABEL_E5AAA4', 'NakaObj_MidiPmemOutput_RNull2',     'Null placeholder in PmemOut right-side group'),
    ('LABEL_E5AAA6', 'NakaObj_MidiPmemOutput_RNull3',     'Null placeholder in PmemOut right-side group'),
    ('LABEL_E5AAA8', 'NakaObj_MidiPmemOutput_RNull4',     'Null placeholder in PmemOut right-side group'),
    ('LABEL_E5AAAA', 'NakaObj_MidiPmemOutput_RNull5',     'Null placeholder in PmemOut right-side group'),
    ('LABEL_E5AAAC', 'NakaObj_MidiPmemOutput_RNull6',     'Null placeholder in PmemOut right-side group'),
    ('LABEL_E5AAAE', 'NakaObj_MidiPmemOutput_RNull7',     'Null placeholder in PmemOut right-side group'),
    ('LABEL_E5AAB0', 'NakaObj_MidiPmemOutput_Name',       'String "MidiPanelMemoryOutput" in descriptor'),

    # -----------------------------------------------------------------------
    # MidiSetup NAKA object descriptor
    # -----------------------------------------------------------------------
    ('LABEL_E5AAEA', 'NakaObj_MidiSetup_Null1',           'Null placeholder in MidiSetup descriptor'),
    ('LABEL_E5AAEC', 'NakaObj_MidiSetup_Null2',           'Null placeholder in MidiSetup descriptor'),
    ('LABEL_E5AAEE', 'NakaObj_MidiSetup_Null3',           'Null placeholder in MidiSetup descriptor'),
    ('LABEL_E5AAF2', 'NakaObj_MidiSetup_Null4',           'Null placeholder in MidiSetup descriptor'),
    ('LABEL_E5AAF4', 'NakaObj_MidiSetup_Null5',           'Null placeholder in MidiSetup descriptor'),
    ('LABEL_E5AAF6', 'NakaObj_MidiSetup_Null6',           'Null placeholder in MidiSetup descriptor'),
    ('LABEL_E5AAF8', 'NakaObj_MidiSetup_GridBox',         'String "MdSetOptGridBox" in MidiSetup descriptor'),
    ('LABEL_E5AB08', 'NakaObj_MidiSetup_Name',            'String "MidiSetup" in descriptor'),

    # -----------------------------------------------------------------------
    # EntertainerVocal (Vocalist) NAKA object descriptor
    # -----------------------------------------------------------------------
    ('LABEL_E5AB76', 'NakaObj_EntertainerVocal_Null1',    'Null placeholder in EntertainerVocal descriptor'),
    ('LABEL_E5AB7A', 'NakaObj_EntertainerVocal_Null2',    'Null placeholder in EntertainerVocal descriptor'),
    ('LABEL_E5AB7C', 'NakaObj_EntertainerVocal_Null3',    'Null placeholder in EntertainerVocal descriptor'),
    ('LABEL_E5AB7E', 'NakaObj_EntertainerVocal_Null4',    'Null placeholder in EntertainerVocal descriptor'),
    ('LABEL_E5AB82', 'NakaObj_EntertainerVocal_Null5',    'Null placeholder in EntertainerVocal descriptor'),
    ('LABEL_E5AB84', 'NakaObj_EntertainerVocal_Null6',    'Null placeholder in EntertainerVocal descriptor'),
    ('LABEL_E5AB86', 'NakaObj_EntertainerVocal_Null7',    'Null placeholder in EntertainerVocal descriptor'),
    ('LABEL_E5AB88', 'NakaObj_EntertainerVocal_Page2Null','Null placeholder before VocalistPage2Box'),
    ('LABEL_E5AB8A', 'NakaObj_EntertainerVocal_Page2Box', 'String "VocalistPage2Box" in descriptor'),
    ('LABEL_E5AB9C', 'NakaObj_EntertainerVocal_Page2',    'String "VocalistPage2" in descriptor'),
    ('LABEL_E5ABAA', 'NakaObj_EntertainerVocal_HarmOnOff','String "HarmOnOffBox" in descriptor'),
    ('LABEL_E5ABB8', 'NakaObj_EntertainerVocal_ListNull', 'Null placeholder before VocalistListBox'),
    ('LABEL_E5ABBA', 'NakaObj_EntertainerVocal_ListBox',  'String "VocalistListBox" in descriptor'),
    ('LABEL_E5ABCC', 'NakaObj_EntertainerVocal_Page1Null1','Null placeholder in VocalistPage1 group'),
    ('LABEL_E5ABCE', 'NakaObj_EntertainerVocal_Page1Null2','Null placeholder in VocalistPage1 group'),
    ('LABEL_E5ABD0', 'NakaObj_EntertainerVocal_Page1Null3','Null placeholder in VocalistPage1 group'),
    ('LABEL_E5ABD2', 'NakaObj_EntertainerVocal_Page1',    'String "VocalistPage1" in descriptor'),
    ('LABEL_E5ABE0', 'NakaObj_EntertainerVocal_PageNull', 'Null placeholder before VocalistPage name'),
    ('LABEL_E5ABE2', 'NakaObj_EntertainerVocal_Page',     'String "VocalistPage" root name in descriptor'),
    ('LABEL_E5ABF2', 'NakaObj_EntertainerVocal_NameNull', 'Null placeholder before EntertainerVocal name'),
    ('LABEL_E5ABF4', 'NakaObj_EntertainerVocal_Name',     'String "EntertainerVocal" root name in descriptor'),

    # -----------------------------------------------------------------------
    # EntertainerFade (Fade In/Out) NAKA object descriptor
    # -----------------------------------------------------------------------
    ('LABEL_E5AC2A', 'NakaObj_EntertainerFade_Null1',     'Null placeholder in EntertainerFade descriptor'),
    ('LABEL_E5AC2C', 'NakaObj_EntertainerFade_Null2',     'Null placeholder in EntertainerFade descriptor'),
    ('LABEL_E5AC2E', 'NakaObj_EntertainerFade_Null3',     'Null placeholder in EntertainerFade descriptor'),
    ('LABEL_E5AC32', 'NakaObj_EntertainerFade_Null4',     'Null placeholder in EntertainerFade descriptor'),
    ('LABEL_E5AC34', 'NakaObj_EntertainerFade_Null5',     'Null placeholder in EntertainerFade descriptor'),
    ('LABEL_E5AC36', 'NakaObj_EntertainerFade_Null6',     'Null placeholder in EntertainerFade descriptor'),
    ('LABEL_E5AC38', 'NakaObj_EntertainerFade_GridBox',   'String "FadeInOutGridBox" in descriptor'),
    ('LABEL_E5AC4A', 'NakaObj_EntertainerFade_Name',      'String "EntertainerFade" root name in descriptor'),
    ('LABEL_E5AC76', 'NakaObj_SplitSetting_Null1',        'Null placeholder in SplitSetting descriptor'),
    ('LABEL_E5AC7A', 'NakaObj_SplitSetting_Null2',        'Null placeholder in SplitSetting descriptor'),
    ('LABEL_E5AC7C', 'NakaObj_SplitSetting_Null3',        'Null placeholder in SplitSetting descriptor'),
    ('LABEL_E5AC7E', 'NakaObj_SplitSetting_Null4',        'Null placeholder in SplitSetting descriptor'),
    ('LABEL_E5AC80', 'NakaObj_SplitSetting_NameNull',     'Null placeholder before SplitSetting name'),
    ('LABEL_E5AC82', 'NakaObj_SplitSetting_Name',         'String "SplitSetting" root name in descriptor'),

    # -----------------------------------------------------------------------
    # MainFunc dispatch table and main function name strings
    # -----------------------------------------------------------------------
    ('LABEL_E5ADB0', 'MainFunc_DispatchTable',            'Dispatch pointer table for top-level main function names'),
    ('LABEL_E5ADCC', 'MainFunc_NullEntry',                'Null/empty entry in main function dispatch table'),
    ('LABEL_E5ADCE', 'MainFunc_RevEqPresetLoad',          'String "MainRevEqPresetLoad" in dispatch table'),
    ('LABEL_E5ADE2', 'MainFunc_VocalistPage2OKFunc',      'String "MainVocalistPage2OKFunc" in dispatch table'),
    ('LABEL_E5ADFA', 'MainFunc_VocalistPage1OKFunc',      'String "MainVocalistPage1OKFunc" in dispatch table'),
    ('LABEL_E5AE12', 'MainFunc_FlashFunc',                'String "MainFlashFunc" in dispatch table'),
    ('LABEL_E5AE20', 'MainFunc_MpstFunc',                 'String "MainMpstFunc" in dispatch table'),
    ('LABEL_E5AE2E', 'MainFunc_ExcSend',                  'String "MainExcSend" in dispatch table'),
    ('LABEL_E5AE3A', 'MainFunc_PcgOutSend',               'String "MainPcgOutSend" in dispatch table'),

    # -----------------------------------------------------------------------
    # E7ECF2: MIDI part display parameters data block (after bitmap data)
    # Pairs of (value, pointer) for page label display
    # -----------------------------------------------------------------------
    ('LABEL_E7ECF2', 'MidiPart_PageDisplay_Data',         'MIDI part page display parameter data block'),
    ('LABEL_E7ED06', 'MidiPart_PageStr_2of2',             'Page label string "PAGE 2/2"'),
    ('LABEL_E7ED10', 'MidiPart_PageStr_1of2',             'Page label string "PAGE 1/2"'),
    ('LABEL_E7ED26', 'MidiPart_PageStr_3of3',             'Page label string "PAGE 3/3"'),
    ('LABEL_E7ED30', 'MidiPart_PageStr_2of3',             'Page label string "PAGE 2/3"'),
    ('LABEL_E7ED3A', 'MidiPart_PageStr_1of3',             'Page label string "PAGE 1/3"'),
    ('LABEL_E7ED92', 'MidiPart_AboveStr',                 'Display string "ABOVE" for part range'),
    ('LABEL_E7ED98', 'MidiPart_BelowStr',                 'Display string "BELOW" for part range'),

    # -----------------------------------------------------------------------
    # MIDI part key-name table (A-G note names with display attributes)
    # E7ED9E = pointer table mapping note indices to display code + name
    # -----------------------------------------------------------------------
    ('LABEL_E7ED9E', 'MidiPart_NoteNameTable',            'Pointer table of MIDI note name entries (A-G with display codes)'),
    ('LABEL_E7EDCE', 'MidiPart_NoteEntry_B_Code',         'Note B display code bytes (0x42 0x20)'),
    ('LABEL_E7EDD2', 'MidiPart_NoteStr_B',                'Note name string "B~a0"'),
    ('LABEL_E7EDD8', 'MidiPart_NoteEntry_A_Code',         'Note A display code bytes (0x41 0x20)'),
    ('LABEL_E7EDDC', 'MidiPart_NoteStr_A',                'Note name string "A~a0"'),
    ('LABEL_E7EDE2', 'MidiPart_NoteEntry_G_Code',         'Note G display code bytes (0x47 0x20)'),
    ('LABEL_E7EDE6', 'MidiPart_NoteStr_G',                'Note name string "F~9e" (G in KN display font)'),
    ('LABEL_E7EDEC', 'MidiPart_NoteEntry_F_Code',         'Note F display code bytes (0x46 0x20)'),
    ('LABEL_E7EDF0', 'MidiPart_NoteEntry_E_Code',         'Note E display code bytes (0x45 0x20)'),
    ('LABEL_E7EDF4', 'MidiPart_NoteStr_E',                'Note name string "E~a0"'),
    ('LABEL_E7EDFA', 'MidiPart_NoteEntry_D_Code',         'Note D display code bytes (0x44 0x20)'),
    ('LABEL_E7EDFE', 'MidiPart_NoteStr_D',                'Note name string "D~a0"'),
    ('LABEL_E7EE04', 'MidiPart_NoteEntry_C_Code',         'Note C display code bytes (0x43 0x20)'),

    # -----------------------------------------------------------------------
    # MIDI part octave/transpose value table
    # E7EE08 = pointer table of octave strings (" 8" down to "-2")
    # -----------------------------------------------------------------------
    ('LABEL_E7EE08', 'MidiPart_OctaveTable',              'Pointer table of octave/transpose display strings'),
    ('LABEL_E7EE34', 'MidiPart_OctaveStr_p8',             'Octave string " 8" (space 0x38)'),
    ('LABEL_E7EE38', 'MidiPart_OctaveStr_p7',             'Octave string " 7" (space 0x37)'),
    ('LABEL_E7EE3C', 'MidiPart_OctaveStr_p6',             'Octave string " 6" (space 0x36)'),
    ('LABEL_E7EE40', 'MidiPart_OctaveStr_p5',             'Octave string " 5" (space 0x35)'),
    ('LABEL_E7EE44', 'MidiPart_OctaveStr_p4',             'Octave string " 4" (space 0x34)'),
    ('LABEL_E7EE48', 'MidiPart_OctaveStr_p3',             'Octave string " 3" (space 0x33)'),
    ('LABEL_E7EE4C', 'MidiPart_OctaveStr_p2',             'Octave string " 2" (space 0x32)'),
    ('LABEL_E7EE50', 'MidiPart_OctaveStr_p1',             'Octave string " 1" (space 0x31)'),
    ('LABEL_E7EE54', 'MidiPart_OctaveStr_0',              'Octave string " 0" (space 0x30)'),
    ('LABEL_E7EE58', 'MidiPart_OctaveStr_m1',             'Octave string "-1" (0x2d 0x31)'),
    ('LABEL_E7EE5C', 'MidiPart_OctaveStr_m2',             'Octave string "-2" (0x2d 0x32)'),

    # -----------------------------------------------------------------------
    # Recv/Trans/After format strings and related MIDI part data
    # -----------------------------------------------------------------------
    ('LABEL_E7EFFC', 'MidiPart_RecvTransStr',             'String "Recv+Trans" for MIDI part display (second copy)'),
    ('LABEL_E7F014', 'MidiPart_AfterStr',                 'String "  AFTER   " for MIDI part display (second copy)'),

    # -----------------------------------------------------------------------
    # MIDI part column width data table
    # E7F070: pairs of (width, height) for MIDI part display columns
    # -----------------------------------------------------------------------
    ('LABEL_E7F070', 'MidiPart_ColWidthData',             'MIDI part display column width/height parameter data'),
    ('LABEL_E7F0B6', 'MidiPart_HarmLocalStr',             'String "HARMONY PART LOCAL: ---" for harmony part display'),

    # -----------------------------------------------------------------------
    # GM mode attention/warning string table (multilingual)
    # E7F0F8 = pointer table for "ATTENTION!" in 6 languages
    # -----------------------------------------------------------------------
    ('LABEL_E7F0F8', 'GMMode_AttentionTable',             'Pointer table of "ATTENTION!" warning strings (6 languages)'),
    ('LABEL_E7F110', 'GMMode_Attention_Indonesian',       'Indonesian "Perhatian !" attention string'),
    ('LABEL_E7F11C', 'GMMode_Attention_English',          'English "ATTENTION!" string'),
    ('LABEL_E7F128', 'GMMode_Attention_Spanish',          'Spanish "ATENCION!" attention string'),
    ('LABEL_E7F134', 'GMMode_Attention_French',           'French "ATTENTION!" string'),
    ('LABEL_E7F140', 'GMMode_Attention_German',           'German "ACHTUNG !" attention string'),
    ('LABEL_E7F14A', 'GMMode_Attention_English2',         'English "ATTENTION!" string (second entry)'),

    # -----------------------------------------------------------------------
    # Split-point key name table (A-G note entries with display codes)
    # E7F778 = pointer table for split-point key names
    # Same structure as MidiPart_NoteNameTable but for split-point screen
    # -----------------------------------------------------------------------
    ('LABEL_E7F778', 'SplitPoint_NoteNameTable',          'Pointer table of split-point key name entries'),
    ('LABEL_E7F7A8', 'SplitPoint_NoteEntry_B_Code',       'Split-point note B display code bytes'),
    ('LABEL_E7F7AC', 'SplitPoint_NoteStr_B',              'Split-point note name string "B~a0"'),
    ('LABEL_E7F7B2', 'SplitPoint_NoteEntry_A_Code',       'Split-point note A display code bytes'),
    ('LABEL_E7F7B6', 'SplitPoint_NoteStr_A',              'Split-point note name string "A~a0"'),
    ('LABEL_E7F7BC', 'SplitPoint_NoteEntry_G_Code',       'Split-point note G display code bytes'),
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
