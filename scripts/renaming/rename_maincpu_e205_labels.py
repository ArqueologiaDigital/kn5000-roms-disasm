#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in region E20566-E24848."""
import os, re

# All LABEL_* symbols in the region E20566-E24848 with semantic names.
#
# The region spans:
#   maincpu/kn5000_v10_program.s lines 4901-5900
#   maincpu/naka/naka_e2107c_e24034.s (included at line 5345)
#
# Context summary:
#   E20566-E206FC  String table: debug/proc-name strings for box procedures
#                  and language check routines (AC=Accompaniment, SQ=Sequencer,
#                  DP=Direct Play, IV=IV mode, TR=Track, GM=GM mode, etc.)
#   E2070E-E208EE  Naka widget property-name string tables (font, row, column,
#                  func, fixedrow, fixedcol, alignment, fontcolor, color, lines,
#                  reversecolor, auto_inc, dial, sel_num, ram, func)
#   E208F8-E20CAF  Naka UI widget definition table for the AC mode box list
#                  (AcModeSelBox, AcDemoSongBox, AcCurrentSongBox, etc.)
#                  plus debug strings for box IDs (IvNamingExit, AcDemoMedleyDispBox, ...)
#   E20CB0-E20E27  Two string pointer tables: one for event names (EV_*)
#                  and one for message-type names (MT_*)
#   E20E28-E2106F  String pointer table with MT_* message handler names;
#                  "MT_DemoSongSel" / "MT_SongNameSet" trailer
#   E2107C-E24034  Naka UI widget tree (included from naka_e2107c_e24034.s):
#                  SMF/DOC/PD Direct Play panels, SMF/DOC/PD/Song Medley panels,
#                  Step Record panel, Track Assign panels, Song Select/Naming panel,
#                  After-Touch Setting panel, Part Balance panel, Demonstration panel
#   E2406E-E24034  End of naka include; after include: more naka data tables
#   E24088-E24848  String table: Naka property-name strings for DpSmf, DpDoc,
#                  DpPd, DpSmfLyr, DpMdlySmf, DpMdlyDoc, DpMdlyPd, DpMdlySmfLyr
#                  window state switch names (DOCOrchSw, SMFMedMuteSw, etc.)

RENAMES = [
    # --- Proc-name debug strings (box procedure names) ---
    ('LABEL_E20566', 'DbgStr_MeasureBoxFunc',        'Debug string: "MeasureBoxFunc"'),
    ('LABEL_E20576', 'DbgStr_MeasureBoxProc',        'Debug string: "MeasureBoxProc"'),
    ('LABEL_E20586', 'DbgStr_DPPauseDspCheck',       'Debug string: "DPPauseDspCheck"'),
    ('LABEL_E20596', 'DbgStr_DPPlayDspCheck',        'Debug string: "DPPlayDspCheck"'),
    ('LABEL_E205A6', 'DbgStr_DemoMedDspCheck',       'Debug string: "DemoMedDspCheck"'),
    ('LABEL_E205B6', 'DbgStr_TrAsGridCheck',         'Debug string: "TrAsGridCheck"'),
    ('LABEL_E205C4', 'DbgStr_SeqNameOKFunc',         'Debug string: "SeqNameOKFunc"'),
    ('LABEL_E205D2', 'DbgStr_SeqNamingCheck',        'Debug string: "SeqNamingCheck"'),
    ('LABEL_E205E2', 'DbgStr_PdOrchMuteFunc',        'Debug string: "PdOrchMuteFunc"'),
    ('LABEL_E205F2', 'DbgStr_DocOrchMuteFunc',       'Debug string: "DocOrchMuteFunc"'),
    ('LABEL_E20602', 'DbgStr_Rt2MuteFunc',           'Debug string: "Rt2MuteFunc"'),
    ('LABEL_E2060E', 'DbgStr_Rt1MuteFunc',           'Debug string: "Rt1MuteFunc"'),
    ('LABEL_E2061A', 'DbgStr_SMFMuteOnOffFunc',      'Debug string: "SMFMuteOnOffFunc"'),
    ('LABEL_E2062C', 'DbgStr_MuteChSetFunc',         'Debug string: "MuteChSetFunc"'),
    ('LABEL_E2063A', 'DbgStr_SqAftSetFunc',          'Debug string: "SqAftSetFunc"'),
    ('LABEL_E20648', 'DbgStr_SmfMuteChSelFunc',      'Debug string: "SmfMuteChSelFunc"'),
    ('LABEL_E2065A', 'DbgStr_DemoSongSelFunc',       'Debug string: "DemoSongSelFunc"'),
    ('LABEL_E2066A', 'DbgStr_SqTrAsPsSongFunc',      'Debug string: "SqTrAsPsSongFunc"'),
    ('LABEL_E2067C', 'DbgStr_TrAsSureLangCheck',     'Debug string: "TrAsSureLangCheck"'),
    ('LABEL_E2068E', 'DbgStr_GmOffSureLangCheck',    'Debug string: "GmOffSureLangCheck"'),
    ('LABEL_E206A2', 'DbgStr_GmOnSureLangCheck',     'Debug string: "GmOnSureLangCheck"'),
    ('LABEL_E206B4', 'DbgStr_AreYouSureLangCheck',   'Debug string: "AreYouSureLangCheck"'),
    ('LABEL_E206C8', 'DbgStr_AtentionLangCheck',     'Debug string: "AtentionLangCheck"'),
    ('LABEL_E206DA', 'DbgStr_TrAsPreLangCheck',      'Debug string: "TrAsPreLangCheck"'),
    ('LABEL_E206EC', 'DbgStr_AfterLangCheck',        'Debug string: "AfterLangCheck"'),
    ('LABEL_E206FC', 'DbgStr_PartSelLangCheck',      'Debug string: "PartSelLangCheck"'),

    # --- Naka widget property-name string table: IvNamingExit container ---
    # E2070E: single-entry ptr table -> empty string (IvNamingExit widget props)
    ('LABEL_E2070E', 'NakaPropTbl_IvNamingExit',     'Naka prop ptr table for IvNamingExit widget (1 entry -> empty)'),
    ('LABEL_E20712', 'NakaPropStr_IvNamingExit_0',   'Empty prop string for IvNamingExit'),

    # E20714: 9-entry prop ptr table (auto_inc/dial/sel_num/row/column/main_func/fontcolor/font + empty)
    ('LABEL_E20714', 'NakaPropTbl_SelBox',           'Naka prop ptr table: auto_inc,dial,sel_num,row,column,main_func,fontcolor,font'),
    ('LABEL_E20738', 'NakaPropStr_SelBox_0',         'Prop name: "" (sentinel/empty)'),
    # E2073A "auto_inc" already has a meaningful label suffix; keep address as anchor
    ('LABEL_E20752', 'NakaPropStr_SelBox_Row',       'Prop name: "row" (raw bytes 72 6f 77 00)'),

    # E20778: 2-entry prop ptr table (empty + "ram")
    ('LABEL_E20778', 'NakaPropTbl_Ram',              'Naka prop ptr table: "" / "ram"'),
    ('LABEL_E20780', 'NakaPropStr_Ram_0',            'Prop name: "" (sentinel)'),
    ('LABEL_E20782', 'NakaPropStr_Ram_1',            'Prop name: "ram" (raw bytes)'),

    # E20786: 2-entry prop ptr table (empty + "func")
    ('LABEL_E20786', 'NakaPropTbl_Func',             'Naka prop ptr table: "" / "func"'),
    ('LABEL_E2078E', 'NakaPropStr_Func_0',           'Prop name: "" (sentinel)'),

    # E20796: 1-entry prop ptr table (empty) - used by AcCurSongNameBoxProc widget
    ('LABEL_E20796', 'NakaPropTbl_CurSongName',      'Naka prop ptr table for CurSongName widget (1 entry)'),
    ('LABEL_E2079A', 'NakaPropStr_CurSongName_0',    'Prop name: "" (sentinel)'),

    # E2079C: 1-entry prop ptr table (empty) - used by AcTrAsGridBoxProc widget
    ('LABEL_E2079C', 'NakaPropTbl_TrAsGrid',         'Naka prop ptr table for TrAsGrid widget (1 entry)'),
    ('LABEL_E207A0', 'NakaPropStr_TrAsGrid_0',       'Prop name: "" (sentinel)'),

    # E207A2: 4-entry prop ptr table (empty/"func"/"fixedrow"/"fixedcol") - grid widget
    ('LABEL_E207A2', 'NakaPropTbl_Grid',             'Naka prop ptr table: "",func,fixedrow,fixedcol'),
    ('LABEL_E207B2', 'NakaPropStr_Grid_0',           'Prop name: "" (sentinel)'),

    # E207CE: 1-entry prop ptr table (empty) - used by AcSmfFileNameBoxProc
    ('LABEL_E207CE', 'NakaPropTbl_SmfFileName',      'Naka prop ptr table for SmfFileName widget (1 entry)'),
    ('LABEL_E207D2', 'NakaPropStr_SmfFileName_0',    'Prop name: "" (sentinel)'),

    # E207D4: 1-entry prop ptr table (empty) - used by AcDocFileNoBoxProc
    ('LABEL_E207D4', 'NakaPropTbl_DocFileNo',        'Naka prop ptr table for DocFileNo widget (1 entry)'),
    ('LABEL_E207D8', 'NakaPropStr_DocFileNo_0',      'Prop name: "" (sentinel)'),

    # E207DA: 1-entry prop ptr table (empty) - used by AcPDFileNoBoxProc
    ('LABEL_E207DA', 'NakaPropTbl_PdFileNo',         'Naka prop ptr table for PdFileNo widget (1 entry)'),
    ('LABEL_E207DE', 'NakaPropStr_PdFileNo_0',       'Prop name: "" (sentinel)'),

    # E207E0: 1-entry prop ptr table (empty) - used by AcSmfSongNameBoxProc
    ('LABEL_E207E0', 'NakaPropTbl_SmfSongName',      'Naka prop ptr table for SmfSongName widget (1 entry)'),
    ('LABEL_E207E4', 'NakaPropStr_SmfSongName_0',    'Prop name: "" (sentinel)'),

    # E207E6: 1-entry prop ptr table (empty) - used by AcDocSongNameBoxProc
    ('LABEL_E207E6', 'NakaPropTbl_DocSongName',      'Naka prop ptr table for DocSongName widget (1 entry)'),
    ('LABEL_E207EA', 'NakaPropStr_DocSongName_0',    'Prop name: "" (sentinel)'),

    # E207EC: 1-entry prop ptr table (empty) - used by AcPDSongNameBoxProc
    ('LABEL_E207EC', 'NakaPropTbl_PdSongName',       'Naka prop ptr table for PdSongName widget (1 entry)'),
    ('LABEL_E207F0', 'NakaPropStr_PdSongName_0',     'Prop name: "" (sentinel)'),

    # E207F2: 1-entry prop ptr table (empty) - used by MeasureBoxProc
    ('LABEL_E207F2', 'NakaPropTbl_MeasureBox',       'Naka prop ptr table for MeasureBox widget (1 entry)'),
    ('LABEL_E207F6', 'NakaPropStr_MeasureBox_0',     'Prop name: "" (sentinel)'),

    # E207F8: 4-entry prop ptr table (empty/"func"/"fontcolor"/"color") - mute toggle widget
    ('LABEL_E207F8', 'NakaPropTbl_MuteToggle',       'Naka prop ptr table: "",func,fontcolor,color'),
    ('LABEL_E20808', 'NakaPropStr_MuteToggle_0',     'Prop name: "" (sentinel)'),

    # E20820: 1-entry prop ptr table (empty) - used by LyricsBoxProc
    ('LABEL_E20820', 'NakaPropTbl_LyricsBox',        'Naka prop ptr table for LyricsBox widget (1 entry)'),
    ('LABEL_E20824', 'NakaPropStr_LyricsBox_0',      'Prop name: "" (sentinel)'),

    # E20826: 6-entry prop ptr table (empty/"lines"/"alignment"/"reversecolor"/"fontcolor"/"font") - text widget
    ('LABEL_E20826', 'NakaPropTbl_TextLabel',        'Naka prop ptr table: "",lines,alignment,reversecolor,fontcolor,font'),
    ('LABEL_E2083E', 'NakaPropStr_TextLabel_0',      'Prop name: "" (sentinel)'),

    # E2086E: 5-entry prop ptr table (empty/"lines"/"alignment"/"fontcolor" + font) - text label widget
    ('LABEL_E2086E', 'NakaPropTbl_TextLabel2',       'Naka prop ptr table: "",lines,alignment,fontcolor,font(inline)'),
    ('LABEL_E20882', 'NakaPropStr_TextLabel2_0',     'Prop name: "" (sentinel)'),

    # E208A8: 4-entry prop ptr table (empty/"lines"/"alignment"/"fontcolor") - lyrics box func widget
    ('LABEL_E208A8', 'NakaPropTbl_LyricsBoxFunc',    'Naka prop ptr table: "",lines,alignment,fontcolor'),
    ('LABEL_E208B8', 'NakaPropStr_LyricsBoxFunc_0',  'Prop name: "" (sentinel)'),

    # E208DA: 1-entry prop ptr table (empty) - AcDemoMedleyDispBoxProc
    ('LABEL_E208DA', 'NakaPropTbl_DemoMedleyDisp',   'Naka prop ptr table for DemoMedleyDisp widget (1 entry)'),
    ('LABEL_E208DE', 'NakaPropStr_DemoMedleyDisp_0', 'Prop name: "" (sentinel)'),

    # E208E0: 1-entry prop ptr table (empty) - IvExitModeTrSelProc
    ('LABEL_E208E0', 'NakaPropTbl_IvExitModeTrSel',  'Naka prop ptr table for IvExitModeTrSel widget (1 entry)'),
    ('LABEL_E208E4', 'NakaPropStr_IvExitModeTrSel_0','Prop name: "" (sentinel)'),

    # E208E6: 1-entry prop ptr table -> bytes (IvExitModeTrSel end marker)
    ('LABEL_E208E6', 'NakaPropTbl_IvExitModeTrSelEnd','Naka prop ptr table: IvExitModeTrSel trailer/end marker'),
    ('LABEL_E208EA', 'NakaPropStr_IvExitModeTrSelEnd_0','End marker bytes for IvExitModeTrSel widget table'),

    # --- Naka AC mode box list widget table (E208F8) ---
    # This is a list of naka widget descriptors for all AC mode boxes
    ('LABEL_E208F8', 'NakaWidgetList_AcModeBoxes',   'Naka widget descriptor list for all AC mode boxes'),

    # --- Naka AC mode box widget data: instance data pointers ---
    # Each box has two data pointers: one for instance state, one for string props.
    # Names derived from associated box proc names.
    ('LABEL_E20B14', 'NakaBoxData_IvExitModeTrSel',  'Instance data for IvExitModeTrSel box (empty state)'),
    ('LABEL_E20B16', 'NakaBoxName_IvExitModeTrSel',  'Box debug name: "IvExitModeTrSel"'),
    ('LABEL_E20B26', 'NakaBoxData_AcDemoMedleyDisp', 'Instance data for AcDemoMedleyDisp box (empty state)'),
    ('LABEL_E20B28', 'NakaBoxName_AcDemoMedleyDisp', 'Box debug name: "AcDemoMedleyDispBox"'),
    ('LABEL_E20B3C', 'NakaBoxData_LyricsBoxFunc',    'Instance data for LyricsBoxFunc box (empty state)'),
    ('LABEL_E20B3E', 'NakaBoxName_LyricsBoxFunc',    'Box debug name: "LyeicsBoxFunc" (sic)'),
    ('LABEL_E20B4C', 'NakaBoxData_ComporserNameBox', 'Instance data for ComporserNameBox (c^dB bytes)'),
    ('LABEL_E20B52', 'NakaBoxName_ComporserNameBox', 'Box debug name: "ComporserNameBox"'),
    ('LABEL_E20B64', 'NakaBoxData_SongNameBox',      'Instance data for SongNameBox (c^dB bytes)'),
    ('LABEL_E20B6A', 'NakaBoxName_SongNameBox',      'Box debug name: "SongNameBox"'),
    ('LABEL_E20B76', 'NakaBoxData_LyricsBox',        'Instance data for LyricsBox (c^dBdB bytes)'),
    ('LABEL_E20B88', 'NakaBoxName_AcMuteToggleBox',  'Box debug name: "AcMuteToggleBox"'),
    ('LABEL_E20B98', 'NakaBoxData_MeasureBox',       'Instance data for MeasureBox (bytes)'),
    ('LABEL_E20B9C', 'NakaBoxName_MeasureBox',       'Box debug name: "MeasureBox"'),
    ('LABEL_E20BA8', 'NakaBoxData_AcPDSongNameBox',  'Instance data for AcPDSongNameBox (empty state)'),
    ('LABEL_E20BAA', 'NakaBoxName_AcPDSongNameBox',  'Box debug name: "AcPDSongNameBox"'),
    ('LABEL_E20BBA', 'NakaBoxData_AcDocSongNameBox', 'Instance data for AcDocSongNameBox (empty state)'),
    ('LABEL_E20BBC', 'NakaBoxName_AcDocSongNameBox', 'Box debug name: "AcDocSongNameBox"'),
    ('LABEL_E20BCE', 'NakaBoxData_AcSmfSongNameBox', 'Instance data for AcSmfSongNameBox (empty state)'),
    ('LABEL_E20BD0', 'NakaBoxName_AcSmfSongNameBox', 'Box debug name: "AcSmfSongNameBox"'),
    ('LABEL_E20BE2', 'NakaBoxData_AcPDFileNoBox',    'Instance data for AcPDFileNoBox (empty state)'),
    ('LABEL_E20BE4', 'NakaBoxName_AcPDFileNoBox',    'Box debug name: "AcPDFileNoBox"'),
    ('LABEL_E20BF2', 'NakaBoxData_AcDocFileNoBox',   'Instance data for AcDocFileNoBox (empty state)'),
    ('LABEL_E20BF4', 'NakaBoxName_AcDocFileNoBox',   'Box debug name: "AcDocFileNoBox"'),
    ('LABEL_E20C04', 'NakaBoxData_AcSmfFileNameBox', 'Instance data for AcSmfFileNameBox (empty state)'),
    ('LABEL_E20C06', 'NakaBoxName_AcSmfFileNameBox', 'Box debug name: "AcSmfFileNameBox"'),
    ('LABEL_E20C18', 'NakaBoxData_AcDiskFileNameBox','Instance data for AcDiskFileNameBox (empty state)'),
    ('LABEL_E20C1A', 'NakaBoxName_AcDiskFileNameBox','Box debug name: "AcDiskFileNameBox"'),
    ('LABEL_E20C2C', 'NakaBoxData_AcTrAsGridBox',   'Instance data for AcTrAsGridBox (bytes)'),
    ('LABEL_E20C30', 'NakaBoxName_AcTrAsGridBox',   'Box debug name: "AcTrAsGridBox"'),
    ('LABEL_E20C3E', 'NakaBoxData_AcCurSongNameBox', 'Instance data for AcCurSongNameBox (empty state)'),
    ('LABEL_E20C40', 'NakaBoxName_AcCurSongNameBox', 'Box debug name: "AcCurSongNameBox"'),
    ('LABEL_E20C52', 'NakaBoxData_AcCurrentSongBox', 'Instance data for AcCurrentSongBox (empty state)'),
    ('LABEL_E20C54', 'NakaBoxName_AcCurrentSongBox', 'Box debug name: "AcCurrentSongBox"'),
    ('LABEL_E20C66', 'NakaBoxData_AcDemoSongBox',    'Instance data for AcDemoSongBox (bytes)'),
    ('LABEL_E20C68', 'NakaBoxName_AcDemoSongBox',    'Box debug name: "AcDemoSongBox"'),
    ('LABEL_E20C76', 'NakaBoxData_AcModeSelBox',     'Instance data for AcModeSelBox (bytes)'),
    ('LABEL_E20C78', 'NakaBoxName_AcModeSelBox',     'Box debug name: "AcModeSelBox"'),
    ('LABEL_E20C86', 'NakaBoxName_PsSongSelBox',     'Box debug name: "PsSongSelBox" (c^kAAnGG scrambled)'),
    ('LABEL_E20C90', 'NakaBoxName_PsSongSelBoxProc', 'Box debug name: "PsSongSelBox" (readable)'),
    ('LABEL_E20C9E', 'NakaBoxData_IvNamingExit',     'Instance data for IvNamingExit box (empty state)'),
    ('LABEL_E20CA0', 'NakaBoxName_IvNamingExit',     'Box debug name: "IvNamingExit"'),

    # --- Event name string pointer table ---
    ('LABEL_E20CB0', 'EvtName_PtrTable',             'String pointer table for event names (EV_*)'),
    ('LABEL_E20D04', 'EvtName_ChangeColor',          'Event name string: "EV_ChangeColor"'),
    ('LABEL_E20D14', 'EvtName_GetEvent',             'Event name string: "EV_GetEvent"'),
    ('LABEL_E20D20', 'EvtName_PlayRequest',          'Event name string: "EV_PlayRequest"'),
    ('LABEL_E20D30', 'EvtName_PlayStartIni',         'Event name string: "EV_PlayStartIni"'),
    ('LABEL_E20D40', 'EvtName_SongWrite',            'Event name string: "EV_SONGWRITE"'),
    ('LABEL_E20D4E', 'EvtName_ComporserWrite',       'Event name string: "EV_COMPORSERWRITE"'),
    ('LABEL_E20D60', 'EvtName_ScrollUp',             'Event name string: "EV_SCROLLUP"'),
    ('LABEL_E20D6C', 'EvtName_Reverse',              'Event name string: "EV_REVERSE"'),
    ('LABEL_E20D78', 'EvtName_Renew',                'Event name string: "EV_RENEW"'),
    ('LABEL_E20D82', 'EvtName_AllDraw',              'Event name string: "EV_ALLDRAW"'),
    ('LABEL_E20D8E', 'EvtName_AllClear',             'Event name string: "EV_ALLCLEAR"'),
    ('LABEL_E20D9A', 'EvtName_PdFileNo',             'Event name string: "EV_PDFILENO"'),
    ('LABEL_E20DA6', 'EvtName_PdSongName',           'Event name string: "EV_PDSONGNAME"'),
    ('LABEL_E20DB4', 'EvtName_DocFileNo',            'Event name string: "EV_DOCFILENO"'),
    ('LABEL_E20DC2', 'EvtName_DocSongName',          'Event name string: "EV_DOCSONGNAME"'),
    ('LABEL_E20DD2', 'EvtName_DocFileName',          'Event name string: "EV_DOCFILENAME"'),
    ('LABEL_E20DE2', 'EvtName_SmfSongName',          'Event name string: "EV_SMFSONGNAME"'),
    ('LABEL_E20DF2', 'EvtName_SmfFileName',          'Event name string: "EV_SMFFILENAME"'),
    ('LABEL_E20E02', 'EvtName_DiskFileName',         'Event name string: "EV_DISKFILENAME"'),
    ('LABEL_E20E12', 'EvtName_CurSongName',          'Event name string: "EV_CURSONGNAME"'),

    # --- Message-type name string pointer table ---
    ('LABEL_E20E28', 'MtName_PtrTable',              'String pointer table for message-type names (MT_*)'),
    ('LABEL_E20E94', 'MtName_GetComporserName',      'MT name string: "MT_GetComporserName"'),
    ('LABEL_E20EA8', 'MtName_GetLyricsSongName',     'MT name string: "MT_GetLyricsSongName"'),
    ('LABEL_E20EBE', 'MtName_LyricsCharaReq',        'MT name string: "MT_LyricsCharaReq"'),
    ('LABEL_E20ED0', 'MtName_GetToggleSw',           'MT name string: "MT_GetToggleSw"'),
    ('LABEL_E20EE0', 'MtName_GetMeasString',         'MT name string: "MT_GetMeasString"'),
    ('LABEL_E20EF2', 'MtName_GetPDFileNo',           'MT name string: "MT_GetPDFileNo"'),
    ('LABEL_E20F02', 'MtName_GetPDSongName',         'MT name string: "MT_GetPDSongName"'),
    ('LABEL_E20F14', 'MtName_GetDocFileNo',          'MT name string: "MT_GetDocFileNo"'),
    ('LABEL_E20F24', 'MtName_GetDocSongName',        'MT name string: "MT_GetDocSongName"'),
    ('LABEL_E20F36', 'MtName_GetDocFileName',        'MT name string: "MT_GetDocFileName"'),
    ('LABEL_E20F48', 'MtName_GetSmfSongName',        'MT name string: "MT_GetSmfSongName"'),
    ('LABEL_E20F5A', 'MtName_GetSmfFileName',        'MT name string: "MT_GetSmfFileName"'),
    ('LABEL_E20F6C', 'MtName_GetDiskFileName',       'MT name string: "MT_GetDiskFileName"'),
    ('LABEL_E20F80', 'MtName_GetCurSongName',        'MT name string: "MT_GetCurSongName"'),
    ('LABEL_E20F92', 'MtName_TrackMidiCall',         'MT name string: "MT_TrackMidiCall"'),
    ('LABEL_E20FA4', 'MtName_DirectPlayMute',        'MT name string: "MT_DirectPlayMute"'),
    ('LABEL_E20FB6', 'MtName_AmdCall',               'MT name string: "MT_AmdCall"'),
    ('LABEL_E20FC2', 'MtName_TrAsPageDec',           'MT name string: "MT_TrAsPageDec"'),
    ('LABEL_E20FD2', 'MtName_TrAsPageInc',           'MT name string: "MT_TrAsPageInc"'),
    ('LABEL_E20FE2', 'MtName_TrAsPartDec',           'MT name string: "MT_TrAsPartDec"'),
    ('LABEL_E20FF2', 'MtName_TrAsPartInc',           'MT name string: "MT_TrAsPartInc"'),
    ('LABEL_E21002', 'MtName_TrAsTrackDec',          'MT name string: "MT_TrAsTrackDec"'),
    ('LABEL_E21012', 'MtName_TrAsTrackInc',          'MT name string: "MT_TrAsTrackInc"'),
    ('LABEL_E21022', 'MtName_SetSelectedFileNum',     'MT name string: "MT_SetSelectedFileNum"'),
    ('LABEL_E21038', 'MtName_PsSongSelBoxID',        'MT name string: "MT_PsSongSelBoxID"'),
    ('LABEL_E2104A', 'MtName_SongNameSet',           'MT name string: "MT_SongNameSet"'),

    # --- Naka UI include: naka_e2107c_e24034.s ---
    # LABEL_E2107C/E2107E are PsSongSelBox strings (just before naka tree)
    ('LABEL_E2107C', 'NakaBoxData_PsSongSelBox',     'Instance data for PsSongSelBox (empty)'),
    ('LABEL_E2107E', 'NakaBoxName_PsSongSelBox',     'Box debug name: "PsSongSelBoxProc"'),

    # SMF DIRECT PLAY panel container and UI elements
    ('LABEL_E210BA', 'NakaStr_SmfDirectPlay',        'UI title string: "SMF DIRECT PLAY  "'),
    ('LABEL_E210CC', 'NakaWidget_SmfDpContainer',    'Naka container widget: SMF Direct Play panel root'),
    ('LABEL_E210F0', 'NakaWidget_SmfDpVolume',       'Naka volume control widget in SMF Direct Play'),
    ('LABEL_E21126', 'NakaStr_Lyrics',               'Widget label string: "LYRICS"'),
    ('LABEL_E2112E', 'NakaWidget_SmfDpGroup',        'Naka group widget: SMF Direct Play mute group'),
    ('LABEL_E21148', 'NakaWidget_SmfDpMuteRow0',     'SMF Direct Play mute row 0 widget'),
    ('LABEL_E2116C', 'NakaWidget_SmfDpMuteRow1',     'SMF Direct Play mute row 1 widget'),
    ('LABEL_E21190', 'NakaWidget_SmfDpLyricsToggle', 'SMF Direct Play lyrics toggle widget'),
    ('LABEL_E211B8', 'NakaWidget_SmfDpMuteToggle',   'SMF Direct Play mute on/off toggle widget'),
    ('LABEL_E211F4', 'NakaWidget_SmfDpMeasureBox',   'SMF Direct Play measure display widget'),
    ('LABEL_E2120E', 'NakaWidget_SmfDpFileSelector', 'SMF Direct Play file selector widget'),
    ('LABEL_E21228', 'NakaWidget_SmfDpFileList',     'SMF Direct Play file list widget'),
    ('LABEL_E21254', 'NakaStr_Off',                  'State string: "OFF"'),
    ('LABEL_E21258', 'NakaStr_On',                   'State string: "ON"'),
    ('LABEL_E2125C', 'NakaWidget_SmfDpMixer',        'SMF Direct Play MIXER channel widget'),
    ('LABEL_E21294', 'NakaWidget_SmfDpMic',          'SMF Direct Play MIC channel widget'),
    ('LABEL_E212CA', 'NakaWidget_SmfDpMuteChLabel',  'SMF Direct Play mute channel label widget'),
    ('LABEL_E212EA', 'NakaStr_MuteChTitle',          'Label string: "-MUTE CH-"'),
    ('LABEL_E212F4', 'NakaWidget_SmfDpMuteChPanel',  'SMF Direct Play mute channel panel container'),
    ('LABEL_E2132C', 'NakaWidget_SmfMedleyItem',     'SMF Medley menu item widget'),
    ('LABEL_E21368', 'NakaWidget_SmfMixerItem',      'SMF MIXER menu item widget'),
    ('LABEL_E2139E', 'NakaStr_Mic',                  'Widget label string: "MIC"'),
    ('LABEL_E213A2', 'NakaWidget_SmfLyricsItem',     'SMF LYRICS menu item widget'),
    ('LABEL_E213E0', 'NakaWidget_SmfDpSubPanel',     'SMF Direct Play sub-panel (type 0x14)'),
    ('LABEL_E21404', 'NakaWidget_SmfDpDisplayMode',  'SMF Direct Play display mode widget (type 0x20)'),
    ('LABEL_E21430', 'NakaWidget_SmfDpSkipLabel',    'SMF Direct Play SKIP label widget'),
    ('LABEL_E21450', 'NakaStr_Skip',                 'Label string: "SKIP"'),
    ('LABEL_E21456', 'NakaWidget_SmfDpLyricsToggle2','SMF Direct Play lyrics toggle widget (type 0x1F)'),
    ('LABEL_E2147E', 'NakaWidget_SmfDpChLabel',      'SMF Direct Play channel label widget'),
    ('LABEL_E214A2', 'NakaWidget_SmfDpMuteGroup',    'SMF Direct Play mute channel group widget'),
    ('LABEL_E214BC', 'NakaWidget_SmfDpMuteSel1',     'SMF Direct Play mute ch select item 1 (type 0x35)'),
    ('LABEL_E214E0', 'NakaWidget_SmfDpMuteSel2',     'SMF Direct Play mute ch select item 2 (type 0x3E)'),
    ('LABEL_E2150C', 'NakaStr_MuteSel1_Empty',       'Empty string for mute select item 1'),
    ('LABEL_E2150E', 'NakaWidget_SmfDpMuteCtrl1',    'SMF Direct Play mute ctrl item (type 0x2C)'),
    ('LABEL_E21528', 'NakaWidget_SmfDpMuteSel3',     'SMF Direct Play mute ch select item 3 (type 0x3E)'),
    ('LABEL_E21554', 'NakaStr_MuteSel3_Empty',       'Empty string for mute select item 3'),
    ('LABEL_E21556', 'NakaWidget_SmfDpMuteCtrl2',    'SMF Direct Play mute ctrl item 2 (type 0x2C)'),
    ('LABEL_E21570', 'NakaWidget_SmfDpMuteSel4',     'SMF Direct Play mute ch select item 4 (type 0x3E)'),
    ('LABEL_E2159C', 'NakaStr_MuteSel4_Empty',       'Empty string for mute select item 4'),
    ('LABEL_E2159E', 'NakaWidget_SmfDpMuteCtrl3',    'SMF Direct Play mute ctrl item 3 (type 0x2C)'),
    ('LABEL_E215B8', 'NakaWidget_SmfDpMuteSel5',     'SMF Direct Play mute ch select item 5 (type 0x3E)'),
    ('LABEL_E215E4', 'NakaStr_MuteSel5_Empty',       'Empty string for mute select item 5'),
    ('LABEL_E215E6', 'NakaWidget_SmfDpMuteCtrl4',    'SMF Direct Play mute ctrl item 4 (type 0x2C)'),
    ('LABEL_E21600', 'NakaWidget_SmfDpMuteSel6',     'SMF Direct Play mute ch select item 6 (type 0x3E)'),
    ('LABEL_E2162C', 'NakaStr_MuteSel6_Empty',       'Empty string for mute select item 6'),
    ('LABEL_E2162E', 'NakaWidget_SmfDpMuteCtrl5',    'SMF Direct Play mute ctrl item 5 (type 0x2C)'),
    ('LABEL_E21648', 'NakaWidget_SmfDpMeasure',      'SMF Direct Play measure counter widget (type 0x29)'),
    ('LABEL_E21662', 'NakaWidget_SmfDpRT1Selector',  'SMF Direct Play RT1 track selector (type 0x4F)'),
    ('LABEL_E2168E', 'NakaWidget_SmfDpRT2Selector',  'SMF Direct Play RT2 track selector (type 0x4F)'),
    ('LABEL_E216BA', 'NakaWidget_SmfDpOrchSel',      'SMF Direct Play ORCH on/off toggle (type 0x35)'),
    ('LABEL_E216DE', 'NakaWidget_SmfDpRT1Display',   'SMF Direct Play RT1 display element'),
    ('LABEL_E21706', 'NakaWidget_SmfDpMuteSwRow0',   'SMF Direct Play mute switch row 0 (type 0x11)'),
    ('LABEL_E21722', 'NakaWidget_SmfDpMuteSwRow1',   'SMF Direct Play mute switch row 1'),
    ('LABEL_E21748', 'NakaWidget_SmfDpMuteSwRow2',   'SMF Direct Play mute switch row 2'),

    # DOC DIRECT PLAY panel
    ('LABEL_E21798', 'NakaStr_DocDirectPlay',        'UI title string: "DOC DIRECT PLAY  "'),
    ('LABEL_E217AA', 'NakaWidget_DocDpContainer',    'Naka container widget: DOC Direct Play panel root'),
    ('LABEL_E217CE', 'NakaWidget_DocDpVolume',       'Naka volume control widget in DOC Direct Play'),
    ('LABEL_E217E8', 'NakaWidget_DocDpGroup',        'Naka group widget: DOC Direct Play mute group'),
    ('LABEL_E2180C', 'NakaWidget_DocDpMuteRow0',     'DOC Direct Play mute row 0 widget'),
    ('LABEL_E21830', 'NakaWidget_DocDpMeasure',      'DOC Direct Play measure counter widget (type 0x29)'),
    ('LABEL_E2184A', 'NakaWidget_DocDpFileSelector', 'DOC Direct Play file selector widget (type 0x4A)'),
    ('LABEL_E21864', 'NakaWidget_DocDpFileList',     'DOC Direct Play file list widget'),
    ('LABEL_E21890', 'NakaStr_DocDp_RT1a',           'DOC Direct Play RT1 string "RT1" (a)'),
    ('LABEL_E21898', 'NakaWidget_DocDpRT2Selector',  'DOC Direct Play RT2 track selector'),
    ('LABEL_E218C4', 'NakaStr_DocDp_RT2a',           'DOC Direct Play RT2 string "RT2" (a)'),
    ('LABEL_E218C8', 'NakaStr_DocDp_RT2b',           'DOC Direct Play RT2 string "RT2" (b)'),
    ('LABEL_E218CC', 'NakaWidget_DocDpOrchSelector', 'DOC Direct Play ORCH selector'),
    ('LABEL_E218F8', 'NakaStr_Orch',                 'Widget label string: "ORCH"'),
    ('LABEL_E21904', 'NakaWidget_DocDpMixer',        'DOC Direct Play MIXER channel widget'),
    ('LABEL_E2193C', 'NakaWidget_DocDpMic',          'DOC Direct Play MIC channel widget'),

    # PIANO DISC DIRECT PLAY panel
    ('LABEL_E21972', 'NakaWidget_PdDpContainer',     'Naka container widget: PD Direct Play panel root'),
    ('LABEL_E219B8', 'NakaWidget_PdDpVolume',        'Naka volume control widget in PD Direct Play'),
    ('LABEL_E219DC', 'NakaWidget_PdDpGroup',         'Naka group widget: PD Direct Play mute group'),
    ('LABEL_E219F6', 'NakaWidget_PdDpMuteRow0',      'PD Direct Play mute row 0 widget'),
    ('LABEL_E21A1A', 'NakaWidget_PdDpMuteRow1',      'PD Direct Play mute row 1 widget'),
    ('LABEL_E21A3E', 'NakaWidget_PdDpMeasure',       'PD Direct Play measure counter widget (type 0x29)'),
    ('LABEL_E21A58', 'NakaWidget_PdDpFileSelector',  'PD Direct Play file selector widget (type 0x4A)'),
    ('LABEL_E21A72', 'NakaWidget_PdDpFileList',      'PD Direct Play file list widget'),
    ('LABEL_E21A9E', 'NakaStr_PdDp_RT1a',            'PD Direct Play RT1 string "RT1" (a)'),
    ('LABEL_E21AA6', 'NakaWidget_PdDpOrchSelector',  'PD Direct Play ORCH selector'),
    ('LABEL_E21AD8', 'NakaStr_PdDp_Orchb',           'PD Direct Play ORCH string (b)'),
    ('LABEL_E21ADE', 'NakaWidget_PdDpMixer',         'PD Direct Play MIXER channel widget'),
    ('LABEL_E21B10', 'NakaStr_Mixer',                'Widget label string: "MIXER"'),
    ('LABEL_E21B16', 'NakaWidget_PdDpMic',           'PD Direct Play MIC channel widget'),
    ('LABEL_E21B48', 'NakaStr_PdDp_Mic',             'PD Direct Play MIC string "MIC"'),

    # SMF MEDLEY (inside Medley SMF container)
    ('LABEL_E21B4C', 'NakaWidget_SmfMdlyContainer',  'Naka container widget: SMF Medley panel root'),
    ('LABEL_E21B88', 'NakaWidget_SmfMdlyVolume',     'Naka volume control widget in SMF Medley'),
    ('LABEL_E21BAC', 'NakaWidget_SmfMdlyMeasure',    'SMF Medley measure counter widget (type 0x29)'),
    ('LABEL_E21BC6', 'NakaWidget_SmfMdlyFileSelector','SMF Medley file selector widget (type 0x4A)'),
    ('LABEL_E21BE0', 'NakaWidget_SmfMdlyMicWidget',  'SMF Medley MIC channel widget (type 0x3D)'),
    ('LABEL_E21C12', 'NakaStr_SmfMdly_Mic',          'SMF Medley MIC string "MIC"'),
    ('LABEL_E21C16', 'NakaWidget_SmfMdlyOrchSel',    'SMF Medley ORCH/MIC selector (type 0x4A)'),
    ('LABEL_E21C30', 'NakaWidget_SmfMdlyOrchRow',    'SMF Medley ORCH row widget'),
    ('LABEL_E21C46', 'NakaWidget_SmfMdlyContainer2', 'Naka container widget: SMF Medley sub-panel'),
    ('LABEL_E21C70', 'NakaStr_SmfMedley',            'UI title string: "SMF MEDLEY"'),
    ('LABEL_E21C7C', 'NakaWidget_SmfMdlyLyricsItem', 'SMF Medley LYRICS menu item widget'),
    ('LABEL_E21CBA', 'NakaWidget_SmfMdlySubPanel',   'SMF Medley sub-panel (type 0x14)'),
    ('LABEL_E21CDE', 'NakaWidget_SmfMdlyLyricsToggle','SMF Medley lyrics toggle widget (type 0x1F)'),
    ('LABEL_E21D06', 'NakaWidget_SmfMdlyGroup',      'SMF Medley group widget'),
    ('LABEL_E21D20', 'NakaWidget_SmfMdlyMuteRow0',   'SMF Medley mute row 0 widget'),
    ('LABEL_E21D44', 'NakaWidget_SmfMdlyMuteRow1',   'SMF Medley mute row 1 widget'),
    ('LABEL_E21D68', 'NakaWidget_SmfMdlyMuteToggle', 'SMF Medley mute on/off toggle widget (type 0x3E)'),
    ('LABEL_E21D94', 'NakaStr_SmfMdlyMute_Empty',    'Empty string for SMF Medley mute toggle'),
    ('LABEL_E21D96', 'NakaWidget_SmfMdlySkipLabel',  'SMF Medley SKIP label widget'),
    ('LABEL_E21DBC', 'NakaWidget_SmfMdlyMutePanel',  'SMF Medley mute panel container (type 0x1B)'),
    ('LABEL_E21DF6', 'NakaStr_SmfMdlyMuteSpace',     'Space byte for SMF Medley mute panel'),
    ('LABEL_E21DF8', 'NakaWidget_SmfMdlyMeasureBox', 'SMF Medley measure box widget (type 0x29)'),
    ('LABEL_E21E12', 'NakaWidget_SmfMdlyOffOnSel',   'SMF Medley OFF/ON selector widget (type 0x47)'),
    ('LABEL_E21E28', 'NakaWidget_SmfMdlyOffOnList',  'SMF Medley OFF/ON list widget'),
    ('LABEL_E21E54', 'NakaStr_SmfMdlyOff',           'State string: "OFF" for SMF Medley'),
    ('LABEL_E21E58', 'NakaStr_SmfMdlyOn',            'State string: "ON" for SMF Medley'),
    ('LABEL_E21E5C', 'NakaWidget_SmfMdlyMixerWidget','SMF Medley MIXER channel widget (type 0x3D)'),
    ('LABEL_E21E94', 'NakaWidget_SmfMdlyMicWidget2', 'SMF Medley MIC channel widget 2 (type 0x3D)'),
    ('LABEL_E21ECA', 'NakaWidget_SmfMdlyMuteChLabel','SMF Medley mute channel label widget'),
    ('LABEL_E21EEA', 'NakaStr_SmfMdlyMuteChTitle',   'Label string: "-MUTE CH-" for SMF Medley'),

    # SMF MEDLEY root container (different from sub-container above)
    ('LABEL_E21F2A', 'NakaWidget_SmfMdlyRootContainer','SMF Medley root container widget'),

    # DOC MEDLEY panel
    ('LABEL_E21F60', 'NakaWidget_DocMdlyContainer',  'Naka container widget: DOC Medley panel root'),
    ('LABEL_E21F7A', 'NakaWidget_DocMdlyGroup',      'DOC Medley group widget'),
    ('LABEL_E21F9E', 'NakaWidget_DocMdlyMuteRow0',   'DOC Medley mute row 0 widget'),
    ('LABEL_E21FC2', 'NakaWidget_DocMdlySubPanel',   'DOC Medley sub-panel (type 0x14)'),
    ('LABEL_E21FE6', 'NakaWidget_DocMdlyMuteToggle', 'DOC Medley mute on/off toggle widget (type 0x3E)'),
    ('LABEL_E22012', 'NakaStr_DocMdlyMute_Empty',    'Padding byte after DOC Medley mute toggle'),
    ('LABEL_E22014', 'NakaWidget_DocMdlySkipLabel',  'DOC Medley SKIP label widget'),
    ('LABEL_E22034', 'NakaStr_DocMdlySkip',          'Label string: "SKIP" for DOC Medley'),
    ('LABEL_E2203A', 'NakaWidget_DocMdlyMeasureBox', 'DOC Medley measure box widget (type 0x29)'),
    ('LABEL_E22054', 'NakaWidget_DocMdlyOffOnSel',   'DOC Medley OFF/ON selector widget (type 0x47)'),
    ('LABEL_E2206A', 'NakaWidget_DocMdlyOffOnList',  'DOC Medley OFF/ON list widget'),
    ('LABEL_E22096', 'NakaStr_DocMdlyRT1a',          'DOC Medley RT1 string "RT1" (a)'),
    ('LABEL_E2209E', 'NakaWidget_DocMdlyRT2Sel',     'DOC Medley RT2 selector widget'),
    ('LABEL_E220CA', 'NakaStr_DocMdlyRT2a',          'DOC Medley RT2 string "RT2" (a)'),
    ('LABEL_E220CE', 'NakaStr_DocMdlyRT2b',          'DOC Medley RT2 string "RT2" (b, asciz)'),
    ('LABEL_E220D2', 'NakaWidget_DocMdlyOrchSel',    'DOC Medley ORCH selector widget'),
    ('LABEL_E220FE', 'NakaStr_DocMdlyOrch',          'DOC Medley ORCH label string'),
    ('LABEL_E2210A', 'NakaWidget_DocMdlyMixer',      'DOC Medley MIXER channel widget'),
    ('LABEL_E22142', 'NakaWidget_DocMdlyMic',        'DOC Medley MIC channel widget'),

    # PIANO DISC MEDLEY panel
    ('LABEL_E221A2', 'NakaStr_PdMedley',             'UI title string: "PIANO DISC MEDLEY    "'),
    ('LABEL_E221B8', 'NakaWidget_PdMdlyContainer',   'Naka container widget: PD Medley panel root'),
    ('LABEL_E221DC', 'NakaWidget_PdMdlyGroup',       'PD Medley group widget'),
    ('LABEL_E221F6', 'NakaWidget_PdMdlyMuteRow0',    'PD Medley mute row 0 widget'),
    ('LABEL_E2221A', 'NakaWidget_PdMdlyMuteRow1',    'PD Medley mute row 1 widget'),
    ('LABEL_E2223E', 'NakaWidget_PdMdlyMuteToggle',  'PD Medley mute on/off toggle widget (type 0x3E)'),
    ('LABEL_E2226A', 'NakaStr_PdMdlyMute_Empty',     'Padding byte after PD Medley mute toggle'),
    ('LABEL_E2226C', 'NakaWidget_PdMdlySkipLabel',   'PD Medley SKIP label widget'),
    ('LABEL_E2228C', 'NakaStr_PdMdlySkip',           'Label string: "SKIP" for PD Medley'),
    ('LABEL_E22292', 'NakaWidget_PdMdlyMeasureBox',  'PD Medley measure box widget (type 0x29)'),
    ('LABEL_E222AC', 'NakaWidget_PdMdlyOffOnSel',    'PD Medley OFF/ON selector widget (type 0x47)'),
    ('LABEL_E222C2', 'NakaWidget_PdMdlyOffOnList',   'PD Medley OFF/ON list widget'),
    ('LABEL_E222EE', 'NakaStr_PdMdlyRT1a',           'PD Medley RT1 string "RT1" (a)'),
    ('LABEL_E222F6', 'NakaWidget_PdMdlyRT2Sel',      'PD Medley RT2 selector widget'),
    ('LABEL_E22322', 'NakaStr_PdMdlyOrcha',          'PD Medley ORCH string (a)'),
    ('LABEL_E22328', 'NakaStr_PdMdlyOrchb',          'PD Medley ORCH string (b)'),
    ('LABEL_E2232E', 'NakaWidget_PdMdlyMixer',       'PD Medley MIXER channel widget'),
    ('LABEL_E22360', 'NakaStr_PdMdlyMixer',          'PD Medley MIXER label string'),
    ('LABEL_E22366', 'NakaWidget_PdMdlyMic',         'PD Medley MIC channel widget'),
    ('LABEL_E22398', 'NakaStr_PdMdlyMic',            'PD Medley MIC string "MIC" (asciz)'),

    # SMF MEDLEY (another instance - appears to be 3rd variant)
    ('LABEL_E223D2', 'NakaWidget_SmfMdly2Container', 'Naka container widget: SMF Medley variant 2 root'),
    ('LABEL_E223F6', 'NakaWidget_SmfMdly2MuteToggle','SMF Medley variant 2 mute toggle (type 0x3E)'),
    ('LABEL_E22422', 'NakaStr_SmfMdly2Mute_Empty',   'Padding byte after SMF Medley 2 mute toggle'),
    ('LABEL_E22424', 'NakaWidget_SmfMdly2SkipLabel', 'SMF Medley variant 2 SKIP label widget'),
    ('LABEL_E22444', 'NakaStr_SmfMdly2Skip',         'Label string: "SKIP" for SMF Medley 2'),
    ('LABEL_E2244A', 'NakaWidget_SmfMdly2MeasureBox','SMF Medley variant 2 measure box (type 0x29)'),
    ('LABEL_E22464', 'NakaWidget_SmfMdly2OffOnSel',  'SMF Medley variant 2 OFF/ON selector (type 0x47)'),
    ('LABEL_E2247A', 'NakaWidget_SmfMdly2MicWidget', 'SMF Medley variant 2 MIC widget (type 0x3D)'),
    ('LABEL_E224B0', 'NakaWidget_SmfMdly2OrchSel',   'SMF Medley variant 2 ORCH/MIC selector (type 0x4A)'),

    # SONG MEDLEY panel
    ('LABEL_E224CA', 'NakaWidget_SongMdlyContainer', 'Naka container widget: Song Medley panel root'),
    ('LABEL_E22508', 'NakaWidget_SongMdlyGroup',     'Song Medley group widget'),
    ('LABEL_E22522', 'NakaWidget_SongMdlyVolume',    'Song Medley volume sub-panel (type 0x14)'),
    ('LABEL_E22546', 'NakaWidget_SongMdlySongSel',   'Song Medley song selector widget (type 0x67)'),
    ('LABEL_E2256A', 'NakaWidget_SongMdlySongList',  'Song Medley song list widget'),
    ('LABEL_E22588', 'NakaWidget_SongMdlyRT1Sel',    'Song Medley RT1 selector widget (type 0x3E)'),
    ('LABEL_E225B4', 'NakaStr_SongMdlyRT1_Empty',    'Empty string for Song Medley RT1 selector'),
    ('LABEL_E225B6', 'NakaWidget_SongMdlyMeasureBox','Song Medley measure box widget (type 0x29)'),
    ('LABEL_E225D0', 'NakaWidget_SongMdlyFileList',  'Song Medley file list display widget'),
    ('LABEL_E225F4', 'NakaWidget_SongMdlyMutePanel', 'Song Medley mute panel widget (type 0x5B)'),
    ('LABEL_E2260A', 'NakaWidget_SongMdlyMuteList',  'Song Medley mute list display widget'),
    ('LABEL_E2262E', 'NakaWidget_SongMdlySkipLabel', 'Song Medley SKIP label widget'),
    ('LABEL_E22654', 'NakaWidget_SongMdlyOffOnSel',  'Song Medley OFF/ON selector widget (type 0x47)'),
    ('LABEL_E2266A', 'NakaWidget_SongMdlyMixer',     'Song Medley MIXER channel widget (type 0x3D)'),
    ('LABEL_E226A2', 'NakaWidget_SongMdlyOrchSel',   'Song Medley ORCH toggle widget (type 0x35)'),
    ('LABEL_E226C6', 'NakaWidget_SongMdlySongSel1',  'Song Medley song selector item 1 (type 0x59)'),
    ('LABEL_E226EA', 'NakaWidget_SongMdlySongSel2',  'Song Medley song selector item 2 (type 0x59)'),
    ('LABEL_E2270E', 'NakaWidget_SongMdlySongSel3',  'Song Medley song selector item 3 (type 0x59)'),
    ('LABEL_E22732', 'NakaWidget_SongMdlySongSel4',  'Song Medley song selector item 4 (type 0x59)'),
    ('LABEL_E22756', 'NakaWidget_SongMdlySongSel5',  'Song Medley song selector item 5 (type 0x59)'),
    ('LABEL_E2277A', 'NakaWidget_SongMdlySongSel6',  'Song Medley song selector item 6 (type 0x59)'),
    ('LABEL_E2279E', 'NakaWidget_SongMdlySongSel7',  'Song Medley song selector item 7 (type 0x59)'),
    ('LABEL_E227C2', 'NakaWidget_SongMdlySongSel8',  'Song Medley song selector item 8 (type 0x59)'),
    ('LABEL_E227E6', 'NakaWidget_SongMdlySongSel9',  'Song Medley song selector item 9 (type 0x59)'),
    ('LABEL_E2280A', 'NakaWidget_SongMdlySongSel10', 'Song Medley song selector item 10 (type 0x59)'),
    ('LABEL_E2282E', 'NakaWidget_SongMdlySongSel11', 'Song Medley song selector item 11 (type 0x59)'),
    ('LABEL_E22852', 'NakaWidget_SongMdlySongSel12', 'Song Medley song selector item 12 (type 0x59)'),
    ('LABEL_E22876', 'NakaWidget_SongMdlySongSel13', 'Song Medley song selector item 13 (type 0x59)'),
    ('LABEL_E2289A', 'NakaWidget_SongMdlySongSel14', 'Song Medley song selector item 14 (type 0x59)'),
    ('LABEL_E228BE', 'NakaWidget_SongMdlySongSel15', 'Song Medley song selector item 15 (type 0x59)'),
    ('LABEL_E228E2', 'NakaWidget_SongMdlySongSel16', 'Song Medley song selector item 16 (type 0x59)'),

    # SONG MEDLEY (second instance)
    ('LABEL_E22930', 'NakaStr_SongMedley',           'UI title string: "SONG MEDLEY"'),
    ('LABEL_E2293C', 'NakaWidget_SongMdly2Group',    'Song Medley 2nd instance group widget'),
    ('LABEL_E22956', 'NakaWidget_SongMdly2Volume',   'Song Medley 2nd instance volume sub-panel'),
    ('LABEL_E2297A', 'NakaWidget_SongMdly2SongList', 'Song Medley 2nd instance song list widget'),
    ('LABEL_E22998', 'NakaWidget_SongMdly2SongSel',  'Song Medley 2nd instance song selector (type 0x67)'),
    ('LABEL_E229BC', 'NakaWidget_SongMdly2RT1Sel',   'Song Medley 2nd instance RT1 selector (type 0x3E)'),
    ('LABEL_E229E8', 'NakaStr_SongMdly2RT1_Empty',   'Empty string for Song Medley 2 RT1 selector'),
    ('LABEL_E229EA', 'NakaWidget_SongMdly2SkipLabel','Song Medley 2nd instance SKIP label widget'),
    ('LABEL_E22A0A', 'NakaStr_SongMdly2Skip',        'Label string: "SKIP" for Song Medley 2'),
    ('LABEL_E22A10', 'NakaWidget_SongMdly2MeasureBox','Song Medley 2nd instance measure box (type 0x29)'),
    ('LABEL_E22A2A', 'NakaWidget_SongMdly2FileList', 'Song Medley 2nd instance file list display widget'),
    ('LABEL_E22A4E', 'NakaWidget_SongMdly2MutePanel','Song Medley 2nd instance mute panel (type 0x5B)'),
    ('LABEL_E22A64', 'NakaWidget_SongMdly2OffOnSel', 'Song Medley 2nd instance OFF/ON selector (type 0x47)'),
    ('LABEL_E22A7A', 'NakaWidget_SongMdly2Mixer',    'Song Medley 2nd instance MIXER widget (type 0x3D)'),

    # STEP RECORD panel
    ('LABEL_E22AB2', 'NakaWidget_StepRecContainer',  'Naka container widget: Step Record panel root'),
    ('LABEL_E22AF0', 'NakaWidget_StepRecPartLabel',  'Step Record part-select label widget'),
    ('LABEL_E22B1E', 'NakaWidget_StepRecPartPanel',  'Step Record part panel (type 0x5B)'),
    ('LABEL_E22B34', 'NakaWidget_StepRecPartList',   'Step Record part list widget (type LIST)'),
    ('LABEL_E22B5E', 'NakaWidget_StepRecOrchRow',    'Step Record ORCH/selector row widget'),
    ('LABEL_E22B74', 'NakaWidget_StepRecSubPanel',   'Step Record sub-panel (type 0x5A)'),

    # TRACK ASSIGN panel
    ('LABEL_E22B96', 'NakaWidget_TrAsContainer',     'Naka container widget: Track Assign panel root'),
    ('LABEL_E22BC0', 'NakaStr_TrackAssign',          'UI title string: "TRACK ASSIGN   "'),
    ('LABEL_E22BD0', 'NakaWidget_TrAsPresetItem',    'Track Assign PRESET menu item widget'),
    ('LABEL_E22C06', 'NakaStr_Preset',               'Widget label string: "PRESET"'),
    ('LABEL_E22C0E', 'NakaWidget_TrAsFileList',      'Track Assign file list widget'),
    ('LABEL_E22C34', 'NakaWidget_TrAsGridDisplay',   'Track Assign grid display widget'),
    ('LABEL_E22C7E', 'NakaStr_TrAsGridHeader',       'Track Assign grid header string (column labels)'),
    ('LABEL_E22CAA', 'NakaStr_TrAsGridData',         'Track Assign grid data format string'),
    ('LABEL_E22CBA', 'NakaWidget_TrAsTrackAssign',   'Track Assign widget (type 0x36): TRACK ASSIGN'),
    ('LABEL_E22CF2', 'NakaWidget_TrAsLocalCont',     'Track Assign LOCAL CONT. widget (type 0x36)'),
    ('LABEL_E22D28', 'NakaWidget_TrAsMidiOut',       'Track Assign MIDI OUT widget (type 0x36)'),
    ('LABEL_E22D50', 'NakaStr_MidiOut',              'Widget label string: "MIDI~0DOUT"'),
    ('LABEL_E22D5C', 'NakaWidget_TrAsMatrix',        'Track Assign matrix display widget (type 0x22)'),
    ('LABEL_E22D86', 'NakaWidget_TrAsRT1Toggle',     'Track Assign RT1 on/off toggle (type 0x1F)'),
    ('LABEL_E22DAE', 'NakaWidget_TrAsRT2Toggle',     'Track Assign RT2 on/off toggle (type 0x1F)'),
    ('LABEL_E22DD6', 'NakaWidget_TrAsMeasureBox',    'Track Assign measure box widget (type 0x29)'),
    ('LABEL_E22DF0', 'NakaWidget_TrAsSubContainer',  'Track Assign sub-container widget'),
    ('LABEL_E22E1A', 'NakaStr_TrackAssign2',         'UI title string: "TRACK ASSIGN"'),
    ('LABEL_E22E28', 'NakaWidget_TrAsGroup',         'Track Assign group widget'),
    ('LABEL_E22E42', 'NakaWidget_TrAsPartList0',     'Track Assign part list widget 0 (type LIST)'),
    ('LABEL_E22E6C', 'NakaWidget_TrAsPartList1',     'Track Assign part list widget 1 (type LIST)'),
    ('LABEL_E22E96', 'NakaWidget_TrAsPartList2',     'Track Assign part list widget 2 (type LIST)'),
    ('LABEL_E22EC0', 'NakaWidget_TrAsMeasureBox2',   'Track Assign measure box 2 (type 0x29)'),
    ('LABEL_E22EDA', 'NakaWidget_TrAsRT1Selector',   'Track Assign RT1 selector widget (type 0x3E)'),
    ('LABEL_E22F06', 'NakaStr_TrAsRT1_Empty',        'Empty string for Track Assign RT1 selector'),
    ('LABEL_E22F08', 'NakaWidget_TrAsRT2Selector',   'Track Assign RT2 selector widget (type 0x3E)'),
    ('LABEL_E22F34', 'NakaStr_TrAsRT2_Empty',        'Empty string for Track Assign RT2 selector'),
    ('LABEL_E22F36', 'NakaWidget_TrAsPresetSel',     'Track Assign preset selection widget (type 0x49)'),

    # TRACK ASSIGN PRESET panel
    ('LABEL_E22F7A', 'NakaStr_TrAsPreset',           'UI title string: "TRACK ASSIGN PRESET"'),
    ('LABEL_E22F8E', 'NakaWidget_TrAsPresetSong',    'Track Assign Preset SONG item'),
    ('LABEL_E22FB4', 'NakaWidget_TrAsPresetMatrix',  'Track Assign Preset matrix display (type 0x22)'),
    ('LABEL_E22FDE', 'NakaWidget_TrAsPresetPanel',   'Track Assign Preset panel container (type 0x1B)'),
    ('LABEL_E23018', 'NakaStr_SongColon',            'Label string: "SONG   : "'),
    ('LABEL_E23022', 'NakaWidget_TrAsPresetInit',    'Track Assign Preset INITIAL item'),
    ('LABEL_E23092', 'NakaStr_TechnicsMultiRec',     'Label string: "TECHNICS MULTI RECORDING"'),
    ('LABEL_E2305E', 'NakaWidget_TrAsPresetGmRec',   'Track Assign Preset GM MULTI RECORDING item'),
    ('LABEL_E230E0', 'NakaStr_GmMultiRec',           'Label string: "GM MULTI RECORDING"'),
    ('LABEL_E230AC', 'NakaWidget_TrAsPresetMeasure', 'Track Assign Preset measure box (type 0x29)'),
    ('LABEL_E230F4', 'NakaWidget_TrAsPresetRT2Sel',  'Track Assign Preset RT2 selector (type 0x3E)'),
    ('LABEL_E2310E', 'NakaWidget_TrAsPresetList',    'Track Assign Preset list widget (type LIST)'),
    ('LABEL_E2313A', 'NakaStr_TrAsPresetList_Pad',   'Padding byte after Track Assign Preset list'),
    ('LABEL_E2313C', 'NakaWidget_TrAsPresetGroup',   'Track Assign Preset group widget'),
    ('LABEL_E23166', 'NakaWidget_TrAsPresetContainer','Track Assign Preset container widget'),
    ('LABEL_E23190', 'NakaStr_TrAsPreset2',          'UI title string: "TRACK ASSIGN PRESET" (asciz variant)'),
    ('LABEL_E231A4', 'NakaWidget_TrAsPresetMeasure2','Track Assign Preset measure box 2 (type 0x29)'),
    ('LABEL_E231BE', 'NakaWidget_TrAsPresetRT1Sel',  'Track Assign Preset RT1 selector (type 0x3E)'),
    ('LABEL_E231EA', 'NakaStr_TrAsPresetRT1_Pad',    'Padding byte after Track Assign Preset RT1 selector'),
    ('LABEL_E231EC', 'NakaWidget_TrAsPresetRT2Sel2', 'Track Assign Preset RT2 selector 2 (type 0x3E)'),
    ('LABEL_E23218', 'NakaStr_TrAsPresetRT2_Empty',  'Empty string for Track Assign Preset RT2 selector 2'),
    ('LABEL_E2321A', 'NakaWidget_TrAsPresetGroup2',  'Track Assign Preset group widget 2'),
    ('LABEL_E23234', 'NakaWidget_TrAsPresetTypeSel', 'Track Assign Preset type selector (type 0x49)'),
    ('LABEL_E2324E', 'NakaWidget_TrAsPresetList2',   'Track Assign Preset list widget 2 (type LIST)'),
    ('LABEL_E23278', 'NakaWidget_TrAsPresetList3',   'Track Assign Preset list widget 3 (type LIST)'),
    ('LABEL_E232A2', 'NakaWidget_TrAsPresetList4',   'Track Assign Preset list widget 4 (type LIST)'),
    ('LABEL_E232CC', 'NakaWidget_TrAsPresetContainer2','Track Assign Preset container widget 2'),
    ('LABEL_E2330A', 'NakaWidget_TrAsPresetGroup3',  'Track Assign Preset group widget 3'),
    ('LABEL_E23324', 'NakaWidget_TrAsPresetTypeSel2','Track Assign Preset type selector 2 (type 0x49)'),
    ('LABEL_E2333E', 'NakaWidget_TrAsPresetList5',   'Track Assign Preset list widget 5 (type LIST)'),
    ('LABEL_E23368', 'NakaWidget_TrAsPresetList6',   'Track Assign Preset list widget 6 (type LIST)'),
    ('LABEL_E23392', 'NakaWidget_TrAsPresetList7',   'Track Assign Preset list widget 7 (type LIST)'),
    ('LABEL_E233BC', 'NakaWidget_TrAsPresetMeasure3','Track Assign Preset measure box 3 (type 0x29)'),
    ('LABEL_E233D6', 'NakaWidget_TrAsPresetRT1Sel2', 'Track Assign Preset RT1 selector 2 (type 0x3E)'),
    ('LABEL_E23402', 'NakaStr_TrAsPresetRT1Sel2_Pad','Padding byte after Track Assign Preset RT1 selector 2'),
    ('LABEL_E23404', 'NakaWidget_TrAsPresetRT2Sel3', 'Track Assign Preset RT2 selector 3 (type 0x3E)'),
    ('LABEL_E23430', 'NakaStr_TrAsPresetRT2Sel3_Empty','Empty string for Track Assign Preset RT2 selector 3'),

    # SONG SELECT/NAMING panel
    ('LABEL_E23432', 'NakaWidget_SongSelNamContainer','Naka container widget: Song Select/Naming panel root'),
    ('LABEL_E23470', 'NakaWidget_SongSelNamNameItem','Song Select/Naming NAMING menu item widget'),
    ('LABEL_E234A6', 'NakaStr_Naming',               'Widget label string: "NAMING"'),
    ('LABEL_E234AE', 'NakaWidget_SongSelNamSongSel', 'Song Select/Naming song selector widget'),
    ('LABEL_E234E0', 'NakaWidget_SongSelNamNameEdit','Song Select/Naming name edit widget'),
    ('LABEL_E23512', 'NakaWidget_SongSelNamDuration','Song Select/Naming duration widget (type 0x22)'),

    # NAMING panel
    ('LABEL_E2353C', 'NakaWidget_NamingContainer',   'Naka container widget: Naming panel root'),
    ('LABEL_E2356E', 'NakaWidget_NamingCharSel',     'Naming character selector widget'),
    ('LABEL_E23592', 'NakaWidget_NamingSeqLabel',    'Naming sequencer label widget'),
    ('LABEL_E235B2', 'NakaStr_SequencerColon',       'Label string: "SEQUENCER       :"'),
    ('LABEL_E235C4', 'NakaWidget_NamingMeasureBox',  'Naming measure box widget (type 0x4D)'),
    ('LABEL_E235DE', 'NakaWidget_NamingDisplayMode', 'Naming display mode widget (type 0x20)'),
    ('LABEL_E2360A', 'NakaWidget_NamingOrchRow',     'Naming ORCH/selector row widget'),

    # AFTER TOUCH SETTING panel
    ('LABEL_E2365E', 'NakaWidget_AftTouchDuration',  'After Touch Setting duration widget (type 0x22)'),
    ('LABEL_E23688', 'NakaWidget_AftTouchChSel',     'After Touch Setting channel selector widget (type 0x43)'),
    ('LABEL_E236DA', 'NakaWidget_AftTouchList',      'After Touch Setting channel list widget (type LIST)'),

    # PART BALANCE panel
    ('LABEL_E2373C', 'NakaWidget_PartBal0',          'Part Balance slider widget 0 (type 0x3C)'),
    ('LABEL_E2375C', 'NakaWidget_PartBal1',          'Part Balance slider widget 1 (type 0x3C)'),
    ('LABEL_E2377C', 'NakaWidget_PartBal2',          'Part Balance slider widget 2 (type 0x3C)'),
    ('LABEL_E2379C', 'NakaWidget_PartBal3',          'Part Balance slider widget 3 (type 0x3C)'),
    ('LABEL_E237BC', 'NakaWidget_PartBal4',          'Part Balance slider widget 4 (type 0x3C)'),

    # DEMONSTRATION panel
    ('LABEL_E237DC', 'NakaWidget_DemoContainer',     'Naka container widget: Demonstration panel root'),
    ('LABEL_E23814', 'NakaWidget_DemoPerfItem',      'Demonstration PERFORMANCES menu item widget'),
    ('LABEL_E23858', 'NakaWidget_DemoFeatPresItem',  'Demonstration FEATURE PRESENTATION menu item widget'),
    ('LABEL_E2388E', 'NakaStr_FeatPresentation',     'Widget label string: "FEATURE PRESENTATION"'),
    ('LABEL_E238A4', 'NakaWidget_DemoMeasureBox',    'Demonstration measure box widget (type 0x48)'),

    # PERFORMANCES sub-panels (Demonstration sub-panel)
    ('LABEL_E238E8', 'NakaStr_Performances',         'UI title string: "PERFORMANCES"'),
    ('LABEL_E238F6', 'NakaWidget_PerfMainMedley',    'Performances: Main Medley item widget'),
    ('LABEL_E2392C', 'NakaStr_MainMedley',           'Performance item string: "Main Medley"'),
    ('LABEL_E23938', 'NakaWidget_PerfAccordionMedley','Performances: Accordion Medley item widget'),
    ('LABEL_E23980', 'NakaWidget_PerfFolkMedley',    'Performances: Folk Medley item widget'),
    ('LABEL_E239C2', 'NakaWidget_PerfClassical',     'Performances: Classical item widget'),
    ('LABEL_E23A02', 'NakaWidget_PerfShow',          'Performances: Show item widget'),
    ('LABEL_E23A3E', 'NakaWidget_PerfContemporary',  'Performances: Contemporary item widget'),
    ('LABEL_E23A74', 'NakaStr_Contemporary',         'Performance item string: "Contemporary"'),
    ('LABEL_E23A82', 'NakaWidget_PerfStyleSel',      'Performances: STYLE selector widget (type 0x45)'),
    ('LABEL_E23AAC', 'NakaStr_PerfStyle1',           'Performance STYLE string (asciz)'),
    ('LABEL_E23AB8', 'NakaWidget_PerfSoundSel',      'Performances: SOUND selector widget (type 0x45)'),
    ('LABEL_E23AE2', 'NakaStr_PerfSound1',           'Performance SOUND string (a)'),
    ('LABEL_E23AE8', 'NakaStr_PerfSound2',           'Performance SOUND string (b)'),
    ('LABEL_E23AEE', 'NakaWidget_PerfRhythmSel',     'Performances: RHYTHM selector widget (type 0x45)'),
    ('LABEL_E23B18', 'NakaStr_PerfRhythm1',          'Performance RHYTHM string (a)'),
    ('LABEL_E23B20', 'NakaStr_PerfRhythm2',          'Performance RHYTHM string (b)'),
    ('LABEL_E23B28', 'NakaWidget_PerfMeasureBox',    'Performances measure box widget (type 0x29)'),
    ('LABEL_E23B42', 'NakaWidget_PerfFileList',      'Performances file list display widget'),

    # Second PERFORMANCES sub-panel instance
    ('LABEL_E23B66', 'NakaWidget_Perf2Container',    'Naka container widget: Performances variant 2 root'),
    ('LABEL_E23B90', 'NakaStr_Performances2',        'UI title string: "PERFORMANCES" (variant 2)'),
    ('LABEL_E23B9E', 'NakaWidget_Perf2Strings',      'Performances 2: Strings item widget'),
    ('LABEL_E23BD4', 'NakaStr_Strings',              'Performance item string: "Strings"'),
    ('LABEL_E23BDC', 'NakaWidget_Perf2Gamelan',      'Performances 2: Gamelan item widget'),
    ('LABEL_E23C58', 'NakaWidget_Perf2Guitar',       'Performances 2: Guitar item widget (Piano)'),
    ('LABEL_E23C94', 'NakaWidget_Perf2SaxBrass',     'Performances 2: Sax&Brass item widget'),
    ('LABEL_E23D10', 'NakaWidget_Perf2StyleSel',     'Performances 2: STYLE selector widget (type 0x45)'),
    ('LABEL_E23D3A', 'NakaStr_Perf2Style1',          'Performance 2 STYLE string (a)'),
    ('LABEL_E23D40', 'NakaStr_Perf2Style2',          'Performance 2 STYLE string (b)'),
    ('LABEL_E23D46', 'NakaWidget_Perf2SoundSel',     'Performances 2: SOUND selector widget (type 0x45)'),
    ('LABEL_E23D70', 'NakaStr_Perf2Sound1',          'Performance 2 SOUND string (a)'),
    ('LABEL_E23D76', 'NakaStr_Perf2Sound2',          'Performance 2 SOUND string (b, asciz)'),
    ('LABEL_E23D7C', 'NakaWidget_Perf2RhythmSel',    'Performances 2: RHYTHM selector widget (type 0x45)'),
    ('LABEL_E23DA6', 'NakaStr_Perf2Rhythm1',         'Performance 2 RHYTHM string (a)'),
    ('LABEL_E23DB6', 'NakaWidget_Perf2MeasureBox',   'Performances 2 measure box widget (type 0x29)'),
    ('LABEL_E23DD0', 'NakaWidget_Perf2FileList',     'Performances 2 file list display widget'),

    # Third PERFORMANCES sub-panel instance
    ('LABEL_E23E2C', 'NakaWidget_Perf3HokieDance',  'Performances 3: Hokie Dance item widget'),
    ('LABEL_E23F80', 'NakaWidget_Perf3ModernBluegrass','Performances 3: Modern Bluegrass item widget'),
    ('LABEL_E23FC8', 'NakaWidget_Perf3StyleSel',     'Performances 3: STYLE selector widget (type 0x45)'),
    ('LABEL_E23FF2', 'NakaStr_Perf3Style1',          'Performance 3 STYLE string (a)'),
    ('LABEL_E23FF8', 'NakaStr_Perf3Style2',          'Performance 3 STYLE string (b)'),
    ('LABEL_E23FFE', 'NakaWidget_Perf3SoundSel',     'Performances 3: SOUND selector widget (type 0x45)'),
    ('LABEL_E24028', 'NakaStr_Perf3Sound1',          'Performance 3 SOUND string (a)'),
    ('LABEL_E2402E', 'NakaStr_Perf3Sound2',          'Performance 3 SOUND string (b, asciz)'),
    ('LABEL_E24034', 'NakaWidget_Perf3RhythmSel',    'Performances 3: RHYTHM selector widget (type 0x45)'),

    # --- Back in kn5000_v10_program.s after naka include ---
    # E2406E, E24088 are data tables referenced from the naka include
    # E2406E: already part of named label after include (LABEL_E2406E)
    # E24088: continuation of data table
    # These two labels appear as targets in the naka include file pointer tables

    # E240B0-E24578: Large tables of naka widget pointers (dispatch/sub-table arrays)
    ('LABEL_E240B0', 'NakaWidgetPtrTbl_SmfDp',       'SMF Direct Play naka widget pointer table (42 entries)'),
    ('LABEL_E24160', 'NakaWidgetPtrTbl_DocDp',       'DOC Direct Play naka widget pointer table (11 entries)'),
    ('LABEL_E24190', 'NakaWidgetPtrTbl_PdDp',        'PD Direct Play naka widget pointer table (11 entries)'),
    ('LABEL_E241C0', 'NakaWidgetPtrTbl_SmfMdly',     'SMF Medley naka widget pointer table (7 entries)'),
    ('LABEL_E241E0', 'NakaWidgetPtrTbl_DocMdly',     'DOC Medley naka widget pointer table (16 entries)'),
    ('LABEL_E24228', 'NakaWidgetPtrTbl_PdMdly',      'PD Medley naka widget pointer table (14 entries)'),
    ('LABEL_E24268', 'NakaWidgetPtrTbl_SmfMdly2',    'SMF Medley variant 2 naka widget pointer table (12 entries)'),
    ('LABEL_E242A0', 'NakaWidgetPtrTbl_SongMdly',    'Song Medley naka widget pointer table (7 entries)'),
    ('LABEL_E242C0', 'NakaWidgetPtrTbl_SongMdly2',   'Song Medley 2nd naka widget pointer table (30 entries)'),
    ('LABEL_E24340', 'NakaWidgetPtrTbl_StepRec',     'Step Record naka widget pointer table (11 entries)'),
    ('LABEL_E24370', 'NakaWidgetPtrTbl_TrAs',        'Track Assign naka widget pointer table'),
    ('LABEL_E243A0', 'NakaWidgetPtrTbl_TrAsPreset',  'Track Assign Preset naka widget pointer table (5 entries)'),
    ('LABEL_E243B8', 'NakaWidgetPtrTbl_TrAsPreset2', 'Track Assign Preset 2 naka widget pointer table (12 entries)'),
    ('LABEL_E243F0', 'NakaWidgetPtrTbl_TrAsPreset3', 'Track Assign Preset 3 naka widget pointer table (27 entries)'),
    ('LABEL_E24460', 'NakaWidgetPtrTbl_SongSelNam',  'Song Select/Naming naka widget pointer table (5 entries)'),
    ('LABEL_E24478', 'NakaWidgetPtrTbl_Naming',      'Naming naka widget pointer table'),
    ('LABEL_E244B0', 'NakaWidgetPtrTbl_AftTouch',    'After Touch Setting naka widget pointer table (5 entries)'),
    ('LABEL_E244C8', 'NakaWidgetPtrTbl_PartBal',     'Part Balance naka widget pointer table (4 entries)'),
    ('LABEL_E244E0', 'NakaWidgetPtrTbl_Demo',        'Demonstration naka widget pointer table (11 entries)'),
    ('LABEL_E24510', 'NakaWidgetPtrTbl_Perf',        'Performances naka widget pointer table (12 entries)'),
    ('LABEL_E24548', 'NakaWidgetPtrTbl_Perf2',       'Performances variant 2 naka widget pointer table (11 entries)'),

    # Window state string tables for Dp* (Direct Play) windows
    ('LABEL_E24578', 'NakaWinStateTbl_DpSmf',        'DpSmf window state name pointer table'),
    ('LABEL_E24628', 'NakaWinStateStr_DpSmf_0',      'DpSmf state name: "" (empty)'),
    # E2462A-E246C2: already have meaningful suffixes from aligned_string content

    # Switch-state string tables (aligned_string labels already readable)
    ('LABEL_E246C8', 'NakaWinStateTbl_DpDoc',        'DpDoc window state name pointer table'),
    ('LABEL_E246FC', 'NakaWinStateStr_DpDoc_0',      'DpDoc state name: "" (empty)'),
    ('LABEL_E246FE', 'NakaWinStateStr_DpDoc_1',      'DpDoc state name: "" (empty)'),
    ('LABEL_E24700', 'NakaWinStateStr_DpDoc_2',      'DpDoc state name: "" (empty)'),
    ('LABEL_E2471C', 'NakaWinStateStr_DpDoc_4',      'DpDoc state name: "" (empty)'),
    ('LABEL_E2471E', 'NakaWinStateStr_DpDoc_5',      'DpDoc state name: "" (empty)'),
    ('LABEL_E24720', 'NakaWinStateStr_DpDoc_6',      'DpDoc state name: "" (empty)'),
    ('LABEL_E24722', 'NakaWinStateStr_DpDoc_7',      'DpDoc state name: "" (empty)'),
    ('LABEL_E24724', 'NakaWinStateStr_DpDoc_8',      'DpDoc state name: "" (empty)'),
    ('LABEL_E24726', 'NakaWinStateStr_DpDoc_9',      'DpDoc state name: "" (empty)'),
    ('LABEL_E2472E', 'NakaWinStateTbl_DpPd',         'DpPd window state name pointer table'),
    ('LABEL_E2475E', 'NakaWinStateStr_DpPd_0',       'DpPd state name: "" (empty)'),
    ('LABEL_E24760', 'NakaWinStateStr_DpPd_1',       'DpPd state name: "" (empty)'),
    ('LABEL_E24762', 'NakaWinStateStr_DpPd_2',       'DpPd state name: "" (empty)'),
    ('LABEL_E24776', 'NakaWinStateStr_DpPd_4',       'DpPd state name: "" (empty)'),
    ('LABEL_E24778', 'NakaWinStateStr_DpPd_5',       'DpPd state name: "" (empty)'),
    ('LABEL_E2477A', 'NakaWinStateStr_DpPd_6',       'DpPd state name: "" (empty)'),
    ('LABEL_E2477C', 'NakaWinStateStr_DpPd_7',       'DpPd state name: "" (empty)'),
    ('LABEL_E2477E', 'NakaWinStateStr_DpPd_8',       'DpPd state name: "" (empty)'),
    ('LABEL_E24780', 'NakaWinStateStr_DpPd_9',       'DpPd state name: "" (empty)'),
    ('LABEL_E24788', 'NakaWinStateTbl_DpSmfLyr',     'DpSmfLyr window state name pointer table'),
    ('LABEL_E247A8', 'NakaWinStateStr_DpSmfLyr_0',   'DpSmfLyr state name: "" (empty)'),
    ('LABEL_E247B6', 'NakaWinStateStr_DpSmfLyr_2',   'DpSmfLyr state name: "" (empty)'),
    ('LABEL_E247B8', 'NakaWinStateStr_DpSmfLyr_3',   'DpSmfLyr state name: "" (empty)'),
    ('LABEL_E247BA', 'NakaWinStateStr_DpSmfLyr_4',   'DpSmfLyr state name: "" (empty)'),
    ('LABEL_E247BC', 'NakaWinStateStr_DpSmfLyr_5',   'DpSmfLyr state name: "" (empty)'),
    ('LABEL_E247BE', 'NakaWinStateStr_DpSmfLyr_6',   'DpSmfLyr state name: "" (empty)'),
    ('LABEL_E247CA', 'NakaWinStateTbl_DpMdlySmf',    'DpMdlySmf window state name pointer table'),
    ('LABEL_E2480E', 'NakaWinStateStr_DpMdlySmf_0',  'DpMdlySmf state name: "" (empty)'),
    ('LABEL_E24810', 'NakaWinStateStr_DpMdlySmf_1',  'DpMdlySmf state name: "" (empty)'),
    ('LABEL_E24812', 'NakaWinStateStr_DpMdlySmf_2',  'DpMdlySmf state name: "" (empty)'),
    ('LABEL_E24814', 'NakaWinStateStr_DpMdlySmf_3',  'DpMdlySmf state name: "" (empty)'),
    ('LABEL_E24824', 'NakaWinStateStr_DpMdlySmf_5',  'DpMdlySmf state name: "" (empty)'),
    ('LABEL_E24826', 'NakaWinStateStr_DpMdlySmf_6',  'DpMdlySmf state name: "" (empty)'),
    ('LABEL_E24828', 'NakaWinStateStr_DpMdlySmf_7',  'DpMdlySmf state name: "" (empty)'),
    ('LABEL_E2482A', 'NakaWinStateStr_DpMdlySmf_8',  'DpMdlySmf state name: "" (empty)'),
    ('LABEL_E2482C', 'NakaWinStateStr_DpMdlySmf_9',  'DpMdlySmf state name: "" (empty)'),
    ('LABEL_E2482E', 'NakaWinStateStr_DpMdlySmf_10', 'DpMdlySmf state name: "" (empty)'),
    ('LABEL_E24830', 'NakaWinStateStr_DpMdlySmf_11', 'DpMdlySmf state name: "" (empty)'),
    ('LABEL_E24832', 'NakaWinStateStr_DpMdlySmf_12', 'DpMdlySmf state name: "" (empty)'),
    ('LABEL_E24834', 'NakaWinStateStr_DpMdlySmf_13', 'DpMdlySmf state name: "" (empty)'),
    ('LABEL_E24836', 'NakaWinStateStr_DpMdlySmf_14', 'DpMdlySmf state name: "" (empty)'),
    ('LABEL_E24838', 'NakaWinStateStr_DpMdlySmf_15', 'DpMdlySmf state name: "" (empty)'),

    # DpMdlyDoc window state pointer table
    ('LABEL_E24848', 'NakaWinStateTbl_DpMdlyDoc',    'DpMdlyDoc window state name pointer table'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')
    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')
    # Also process the naka include file
    naka_src = os.path.join(base, 'maincpu', 'naka', 'naka_e2107c_e24034.s')
    with open(naka_src, 'rb') as f:
        naka_content = f.read().decode('latin-1')

    renamed_main = 0
    renamed_naka = 0
    skipped = 0

    for old_label, new_label, comment in RENAMES:
        found_main = old_label in content
        found_naka = old_label in naka_content
        if not found_main and not found_naka:
            print(f'  WARNING: {old_label} not found in either file, skipping')
            skipped += 1
            continue

        # Rename in main file if present
        if found_main:
            refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
            new_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)
            if new_content != content:
                content = new_content
                renamed_main += 1
                print(f'  {old_label:30s} -> {new_label:40s} ({refs} refs in main)')

        # Rename in naka include file if present
        if found_naka:
            refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', naka_content))
            new_naka = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, naka_content)
            if new_naka != naka_content:
                naka_content = new_naka
                renamed_naka += 1
                print(f'  {old_label:30s} -> {new_label:40s} ({refs} refs in naka)')

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))
    with open(naka_src, 'wb') as f:
        f.write(naka_content.encode('latin-1'))

    print(f'\nRenamed {renamed_main} labels in maincpu/kn5000_v10_program.s')
    print(f'Renamed {renamed_naka} labels in maincpu/naka/naka_e2107c_e24034.s')
    if skipped:
        print(f'Skipped {skipped} labels (not found in either file)')


if __name__ == '__main__':
    main()
