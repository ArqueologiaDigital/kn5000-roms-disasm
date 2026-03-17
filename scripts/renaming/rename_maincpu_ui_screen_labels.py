#!/usr/bin/env python3
"""Rename LABEL_* to semantic names for UI/screen procedures in maincpu.

Covers 17 functions spanning group box, radio box, screen, track switch,
ID procedures, initialization, grid check, MSA/PM screens, sequencer
ring buffers, and I/O grid box:

  GroupBoxProc_SSFItemLoop (F9A2FB-F9A536)
  PsRadioBoxProc (F9D3DE-F9D702)
  ScreenProc (F9A709-F9A92E)
  PsTrackSwitchProc (FA367A-FA39E6)
  ModeIDProc (FA8D53-FA8F68)
  TitleIDProc (FA8F99-FA91AE)
  EventIDProc / LABEL_FA9304 common ID proc (FA9304-FA94A3)
  LABEL_FA94A8 ID count helper (FA94A8-FA950D)
  LABEL_FA951C ID cursor advance (FA951C-FA9561+)
  InitializeRoot (FB2B06-FB3089+)
  MstStyle2GridCheck (FBA3FF-FBA6DA)
  MsaModeScreenProc (FBD630-FBD83C)
  PmemModeBoxProc (FBD89A-FBDB36)
  AcPmBkEditBoxProc (FBDBFC-FBE0BC)
  PmBankScreenProc (FC1A87-FC1F1F)
  GET_COMPUTER_INTERFACE_SELECTION (FDBB3C-FDBD2B)
  SeqAlt3_ReadByte region (EF2C2F-EF2E1F)
  Seq_RingBuf_Init_2048 region (EF3130-EF3276)
  AcInOutGridBoxProc (F757BC-F75A7E)

NAKA event codes referenced:
  0x1C00001=Init, 0x1C00002=Close, 0x1C00007=OK, 0x1C00009=Deactivate,
  0x1C0000B=Show, 0x1C0000C=Hide, 0x1C0000D=Paint, 0x1C0000E=Select,
  0x1C0000F=Confirm, 0x1C00015=Navigate, 0x1C00016=OpenDialog,
  0x1C00017=ScrollUp, 0x1C00018=ScrollDown, 0x1C00019=AutoIncUp,
  0x1C0001A=AutoIncDown, 0x1C0001B=Release, 0x1C0001C=Match,
  0x1C0001D=Assign, 0x1C0001E=PageChange, 0x1C00026=GroupNotify,
  0x1C00029=TrackActivate, 0x1C0002A=RadioSelect, 0x1C0002C=Reset,
  0x1C00036=DisplayUpdate, 0x1C20002=BankChanged, 0x1C20003=BankEdit,
  0x1E0000B=GetNext, 0x1E0000C=EnumOpen, 0x1E0000D=EnumFill,
  0x1E0000E=EnumCount, 0x1E00014=CheckType, 0x1E00015=GetName,
  0x1E00024=Dispatch, 0x1E0003A=GetText, 0x1E0003B=SetValue,
  0x1E0003C=CanScroll, 0x1E0003D=AddDelta, 0x1E0003E=GetUpStep,
  0x1E0003F=GetDownStep, 0x1E00043=GetMinBound, 0x1E00044=GetMaxBound,
  0x1E00045=GetDataSource, 0x1E00046=GetDataCount,
  0x1E0004B=GetStoredValue, 0x1E0004D=SetIndex, 0x1E0004E=NotifyIndex,
  0x1E00048=GetInitParam, 0x1E00049=SetStoredValue, 0x1E0004A=GetDefault,
  0x1E00050=CanScrollEvt, 0x1E00053=HitTest, 0x1E0006E=CancelBack,
  0x1E0006F=DialEnable, 0x1E00070=DialDown, 0x1E00071=DialUp,
  0x1E00077=SetNavigation, 0x1E00078=NavDown, 0x1E00079=NavUp,
  0x1E0007A=CanNavUp, 0x1E00087=SetDialFocus, 0x1E00088=GetDialFocus,
  0x1E0008A=GetColText, 0x1E0008B=GetRowText, 0x1E0008C=PlayAudio,
  0x1E0008D=CellSelect, 0x1E0008F=GetCellIndex, 0x1E00091=CanScrollAlt,
  0x1E0009A=NavComplete, 0x1E000AA=HasAutoRepeat, 0x1E000B1=GetWallPaper,
  0x1E000B2=GetWallColor, 0x1E000B4=NavActivate,
  0x1E20010=PmBankUpdate, 0x1E20011=PmBankSelect,
  0x1E2000E=PmBankNotifySelect, 0x1E2000F=PmBankEnumInit

Uses binary I/O to handle Latin-1 encoding safely.  Never use the Edit
tool on kn5000_v10_program.s -- it corrupts the Latin-1 encoding.
"""

import os
import re

# ---------------------------------------------------------------------------
# Rename table: (old_label, new_label, brief_comment)
#
# Groups follow the natural function boundaries visible in the source.
# ---------------------------------------------------------------------------

RENAMES = [
    # ==================================================================
    # GroupBoxProc_SSFItemLoop  (F9A2FB - F9A536)
    # Group box SSF item loop: handles Cancel/Back, Dial control,
    # UP/DOWN navigation, display update, and item close-all.
    # ==================================================================
    ('LABEL_F9A2FB', 'GroupBox_CancelBack',
     'Event 0x1E0006E: Cancel/Back handler, iterates 17-entry widget array'),

    ('LABEL_F9A2FD', 'GroupBox_CancelBack_Loop',
     'Loop over 17 entries (stride 28), index in IZ'),

    ('LABEL_F9A379', 'GroupBox_CancelBack_ActivateSecondary',
     'Activate secondary entry at computed offset for current index'),

    ('LABEL_F9A3C2', 'GroupBox_CancelBack_Deactivate',
     'XWA==0 branch: deactivate active entries, send 0x1C00026'),

    ('LABEL_F9A3E9', 'GroupBox_CancelBack_DeactivateSecondary',
     'Deactivate secondary entry at offset+14 for current index'),

    ('LABEL_F9A42E', 'GroupBox_CancelBack_LoopNext',
     'Increment IZ, loop while <= 0x10'),

    ('LABEL_F9A43A', 'GroupBox_DialEnable',
     'Event 0x1E0006F: store WA into dial enable register at 0x03EF50'),

    ('LABEL_F9A442', 'GroupBox_DialDown',
     'Event 0x1E00070: register down-direction dial params'),

    ('LABEL_F9A453', 'GroupBox_DialUp',
     'Event 0x1E00071: register up-direction dial params'),

    ('LABEL_F9A464', 'GroupBox_GetDialFocus',
     'Event 0x1E00088: return dial focus from 0x03EF6A in XHL'),

    ('LABEL_F9A46A', 'GroupBox_SetDialFocus',
     'Event 0x1E00087: store dial focus at 0x03EF6A, broadcast 0x1C0002C'),

    ('LABEL_F9A470', 'GroupBox_NavUpDown',
     'Events 0x1E00079/0x1E00078: UP/DOWN navigation dispatch'),

    ('LABEL_F9A4A9', 'GroupBox_NavDispatch',
     'Dispatch event via FA9660, then close-all active entries'),

    ('LABEL_F9A4B1', 'GroupBox_CloseAll_Loop',
     'Loop: send 0x1C00009 to all active primary entries'),

    ('LABEL_F9A4D9', 'GroupBox_CloseAll_Secondary',
     'Send 0x1C00009 to active secondary entries'),

    ('LABEL_F9A50C', 'GroupBox_CloseAll_Next',
     'Advance to next entry in close-all loop'),

    ('LABEL_F9A516', 'GroupBox_DisplayUpdate',
     'Event 0x1C00036: enable display, call UpdateScreen, disable'),

    ('LABEL_F9A522', 'GroupBox_DisableDisplay',
     'Disable display after UpdateScreen (call FAA761 with WA=0)'),

    ('LABEL_F9A526', 'GroupBox_ReturnZero',
     'Return XHL=0, epilogue path'),

    ('LABEL_F9A52A', 'GroupBox_ForwardToBoxProc',
     'Default: forward unhandled events to BoxProc'),

    ('LABEL_F9A536', 'GroupBox_Epilogue',
     'Epilogue: pop xiz, adjust stack, return'),

    # ==================================================================
    # PsRadioBoxProc  (F9D3DE - F9D702)
    # Radio box widget procedure: handles Paint, Confirm, Select, Reset,
    # OK, Release, RadioSelect, SetIndex, GetText, HitTest events.
    # ==================================================================
    ('LABEL_F9D3DE', 'PsRadioBox_Paint_SendConfirm',
     'After Paint/VwBoxProc: send Confirm then Select to self'),

    ('LABEL_F9D3FD', 'PsRadioBox_Confirm',
     'Handle 0x1C0000F Confirm: draw radio items with focus check'),

    ('LABEL_F9D458', 'PsRadioBox_Confirm_CopyText',
     'Copy provided text (non-null XDE) via Strcpy'),

    ('LABEL_F9D465', 'PsRadioBox_Confirm_Draw',
     'Get dial focus, set draw params, invoke FAD084 draw'),

    ('LABEL_F9D4A9', 'PsRadioBox_Confirm_DrawUnfocused',
     'Item is not focused: draw with flag=0'),

    ('LABEL_F9D4BA', 'PsRadioBox_Confirm_DrawCall',
     'Call FAD084 to render radio item, then return'),

    ('LABEL_F9D4C1', 'PsRadioBox_Select',
     'Handle 0x1C0000E Select: check dial focus, send NotifyIndex'),

    ('LABEL_F9D4F6', 'PsRadioBox_Select_GetIndex',
     'Dial not focused: read current index from data ptr, send NotifyIndex'),

    ('LABEL_F9D50D', 'PsRadioBox_Reset',
     'Handle 0x1C0002C Reset: forward to VwBoxProc, reselect if radio==1'),

    ('LABEL_F9D538', 'PsRadioBox_Reset_CheckValue',
     'Check if radio value==1, if so send Select'),

    ('LABEL_F9D55A', 'PsRadioBox_OK',
     'Handle 0x1C00007 OK: hit test, if match send SetIndex'),

    ('LABEL_F9D596', 'PsRadioBox_OK_Forward',
     'No hit: forward OK to VwBoxProc via tail jump'),

    ('LABEL_F9D5A8', 'PsRadioBox_Release',
     'Handle 0x1C0001B Release: verify focus matches, send SetIndex'),

    ('LABEL_F9D5E9', 'PsRadioBox_RadioSelect',
     'Handle 0x1C0002A RadioSelect: verify value match, send SetIndex'),

    ('LABEL_F9D63B', 'PsRadioBox_SetIndex',
     'Handle 0x1E0004D SetIndex: update radio state, send Release+Select'),

    ('LABEL_F9D696', 'PsRadioBox_SetIndex_Store',
     'Store new index into data pointer, send Select'),

    ('LABEL_F9D6AF', 'PsRadioBox_DispatchAndReturn',
     'Call FA9660 to dispatch event, then return zero'),

    ('LABEL_F9D6B5', 'PsRadioBox_GetText',
     'Handle 0x1E0003A GetText: zero out text buffer'),

    ('LABEL_F9D6BD', 'PsRadioBox_ReturnZero',
     'Return XHL=0 (success)'),

    ('LABEL_F9D6C1', 'PsRadioBox_HitTest',
     'Handle 0x1E00053 HitTest: check position against radio index'),

    ('LABEL_F9D6F0', 'PsRadioBox_Default',
     'Default: forward unhandled events to VwBoxProc'),

    ('LABEL_F9D6FF', 'PsRadioBox_CallVwBoxProc',
     'Tail call to VwBoxProc'),

    ('LABEL_F9D702', 'PsRadioBox_Return',
     'Epilogue: pop xiz, return'),

    # ==================================================================
    # ScreenProc  (F9A709 - F9A92E)
    # Screen procedure: handles Init, Close, Paint, Deactivate, OK,
    # GetInitParam, SetStoredValue, GetStoredValue, GetDefault events.
    # ==================================================================
    ('LABEL_F9A709', 'Screen_Init_RegisterChild',
     'Register a child screen returned from GetStoredValue query'),

    ('LABEL_F9A70F', 'Screen_Init',
     'Handle 0x1C00001 Init: enumerate children via GetStoredValue loop'),

    ('LABEL_F9A740', 'Screen_Init_CloseDeadChildren',
     'Close children failing CheckType 0x1600033, re-query until valid'),

    ('LABEL_F9A768', 'Screen_Init_Setup',
     'Close dead child, get instance info, branch by init param (xiz)'),

    ('LABEL_F9A79E', 'Screen_Init_ClearStoredValue',
     'For params 0/3/5: clear stored value to 0xFFFFFFFF'),

    ('LABEL_F9A7AB', 'Screen_Init_SetWall',
     'Set wallpaper and wall color from events 0xB1/0xB2, setup navigation'),

    ('LABEL_F9A825', 'Screen_ReturnZero',
     'Return XHL=0 (handled)'),

    ('LABEL_F9A82A', 'Screen_Close',
     'Handle 0x1C00002 Close: forward to GroupBoxProc, clear stored value'),

    ('LABEL_F9A858', 'Screen_Close_ClearValue',
     'For params 0/4/5: set stored value to 0xFFFFFFFF'),

    ('LABEL_F9A864', 'Screen_Paint',
     'Handle 0x1C0000D Paint: call FABB73 repaint helper'),

    ('LABEL_F9A86A', 'Screen_Deactivate',
     'Handle 0x1C00009: forward to GroupBoxProc, display update cycle'),

    ('LABEL_F9A887', 'Screen_OK',
     'Handle 0x1C00007 OK: check dispatch/type, navigate or forward'),

    ('LABEL_F9A8DD', 'Screen_OK_NavUp',
     'OK with CanNavUp: send NavUp then NavComplete'),

    ('LABEL_F9A8FF', 'Screen_OK_Forward',
     'Forward OK to GroupBoxProc'),

    ('LABEL_F9A907', 'Screen_ForwardToGroupBox',
     'Tail call to GroupBoxProc (default or OK forward)'),

    ('LABEL_F9A90C', 'Screen_SetStoredValue',
     'Handle 0x1E00049: store xiz into (field+30)'),

    ('LABEL_F9A91B', 'Screen_GetStoredValue',
     'Handle 0x1E0004B: return value from (field+30) in XHL'),

    ('LABEL_F9A929', 'Screen_GetDefault',
     'Handle 0x1E0004A: return 0xFFFFFFFF in XHL'),

    ('LABEL_F9A92E', 'Screen_Return',
     'Epilogue: pop xiz, adjust stack, return'),

    # ==================================================================
    # PsTrackSwitchProc  (FA367A - FA39E6)
    # Track switch procedure: handles Show/Hide, Confirm, Select,
    # HitTest events for track on/off switches (16 tracks).
    # ==================================================================
    ('LABEL_FA367A', 'PsTrkSw_ShowHide',
     'Handle 0x1C0000B Show / 0x1C0000C Hide: setup track display params'),

    ('LABEL_FA36E5', 'PsTrkSw_ReturnZero',
     'Return XHL=0 (handled)'),

    ('LABEL_FA36EA', 'PsTrkSw_Confirm',
     'Handle 0x1C0000F Confirm: store track values, compute box geometry'),

    ('LABEL_FA3711', 'PsTrkSw_Confirm_SetSub',
     'Store sub-track value if param != 0xFFFF'),

    ('LABEL_FA3724', 'PsTrkSw_Confirm_DrawGeometry',
     'Compute box center, audio feedback, draw track indicator'),

    ('LABEL_FA381F', 'PsTrkSw_Confirm_DrawOff',
     'Track value==0: draw OFF indicator with color 7'),

    ('LABEL_FA3855', 'PsTrkSw_Confirm_Track8Plus',
     'Tracks 8+: use different box style (0xCC)'),

    ('LABEL_FA389C', 'PsTrkSw_Confirm_Track8PlusOff',
     'Tracks 8+, value==0: draw OFF with color 7'),

    ('LABEL_FA38D0', 'PsTrkSw_Confirm_DrawMark',
     'Call FACEAC to draw track state mark'),

    ('LABEL_FA38D4', 'PsTrkSw_Confirm_DrawSecondary',
     'Draw secondary track indicator from sub-track data'),

    ('LABEL_FA38FD', 'PsTrkSw_Select',
     'Handle 0x1C0000E Select: update track selection and draw cursor'),

    ('LABEL_FA391C', 'PsTrkSw_Select_CalcPos',
     'Calculate position: box style by track number (0x96 or 0xE3)'),

    ('LABEL_FA3933', 'PsTrkSw_Select_SetE3',
     'Track >= 8: use box style 0xE3'),

    ('LABEL_FA3937', 'PsTrkSw_Select_DrawBox',
     'Compute bounding box from track column, draw selection'),

    ('LABEL_FA39A6', 'PsTrkSw_DrawAndReturn',
     'Call FACEAC draw, then return zero'),

    ('LABEL_FA39AD', 'PsTrkSw_HitTest',
     'Handle 0x1E00053 HitTest: check if point is in track column'),

    ('LABEL_FA39CD', 'PsTrkSw_HitTest_Track8Plus',
     'Track >= 8: add 0x78 offset before comparing'),

    ('LABEL_FA39DD', 'PsTrkSw_HitTest_Match',
     'Point matches: return XHL=1'),

    ('LABEL_FA39DF', 'PsTrkSw_Epilogue',
     'Epilogue: pop xiz, return'),

    ('LABEL_FA39E6', 'PsTrkSw_TrailingData',
     'Trailing data bytes after PsTrackSwitchProc'),

    # ==================================================================
    # ModeIDProc  (FA8D53 - FA8F68)
    # Mode ID procedure: enumerates modes (0x180-0x19F), handles
    # EnumOpen, EnumFill, EnumCount, GetNext, GetCurrent, GetName.
    # ==================================================================
    ('LABEL_FA8D53', 'ModeID_BuildTable',
     'EnumOpen/EnumFill/EnumCount: build mode ID table (0x180-0x19F range)'),

    ('LABEL_FA8D60', 'ModeID_BuildTable_OuterLoop',
     'Outer loop over mode group index (0x180..0x19F)'),

    ('LABEL_FA8D75', 'ModeID_BuildTable_InnerLoop',
     'Inner loop: store mode IDs into table, increment count'),

    ('LABEL_FA8D97', 'ModeID_BuildTable_NextGroup',
     'Advance to next mode group'),

    ('LABEL_FA8DA7', 'ModeID_EventDispatch',
     'Secondary dispatch: EnumOpen, GetNext, GetCurrent, EnumCount, EnumFill'),

    ('LABEL_FA8DE3', 'ModeID_EnumFill',
     'Handle 0x1E0000D EnumFill: look up name, copy to buffer or send audio'),

    ('LABEL_FA8E1F', 'ModeID_EnumFill_HasName',
     'Name exists: push for Strcpy'),

    ('LABEL_FA8E24', 'ModeID_EnumCount',
     'Handle 0x1E0000E EnumCount: return count in XHL'),

    ('LABEL_FA8E2A', 'ModeID_GetCurrent',
     'Handle 0x1E00009 GetCurrent: advance cursor, look up name'),

    ('LABEL_FA8E57', 'ModeID_GetCurrent_HasName',
     'Name exists: push name addr (EAAB80) for Audio_SendCommand'),

    ('LABEL_FA8E5D', 'ModeID_GetCurrent_SendAudio',
     'Push audio command params and call Audio_SendCommand'),

    ('LABEL_FA8E6B', 'ModeID_GetNext',
     'Handle 0x1E0000B GetNext: advance cursor, copy name or send audio'),

    ('LABEL_FA8EA9', 'ModeID_GetNext_HasName',
     'Name exists: push for Strcpy'),

    ('LABEL_FA8EAD', 'ModeID_Strcpy',
     'Call Strcpy to copy name string'),

    ('LABEL_FA8EB3', 'ModeID_ReturnZero',
     'Return XHL=0'),

    ('LABEL_FA8EB8', 'ModeID_EnumOpen',
     'Handle 0x1E0000C EnumOpen: search table for matching name'),

    ('LABEL_FA8ED5', 'ModeID_EnumOpen_SearchLoop',
     'Search loop: get name, compare via Strcpy then FF0F35'),

    ('LABEL_FA8F14', 'ModeID_EnumOpen_Compare',
     'Call FF0F35 to compare strings'),

    ('LABEL_FA8F3F', 'ModeID_EnumOpen_SearchNext',
     'No match: advance search index'),

    ('LABEL_FA8F4C', 'ModeID_EnumOpen_CheckResult',
     'Check if any match was found'),

    ('LABEL_FA8F53', 'ModeID_EnumOpen_UpdateCursor',
     'Match found: update cursor position via FA951C helper'),

    ('LABEL_FA8F65', 'ModeID_EnumOpen_Return',
     'Return match result in XHL'),

    ('LABEL_FA8F68', 'ModeID_Return',
     'Epilogue: pop xiz, return'),

    # ==================================================================
    # TitleIDProc  (FA8F99 - FA91AE)
    # Title ID procedure: enumerates titles (0x1A0-0x1BF), handles
    # same events as ModeIDProc but for title IDs.
    # ==================================================================
    ('LABEL_FA8F99', 'TitleID_BuildTable',
     'EnumOpen/EnumFill/EnumCount: build title ID table (0x1A0-0x1BF range)'),

    ('LABEL_FA8FA6', 'TitleID_BuildTable_OuterLoop',
     'Outer loop over title group index (0x1A0..0x1BF)'),

    ('LABEL_FA8FBB', 'TitleID_BuildTable_InnerLoop',
     'Inner loop: store title IDs into table, increment count'),

    ('LABEL_FA8FDD', 'TitleID_BuildTable_NextGroup',
     'Advance to next title group'),

    ('LABEL_FA8FED', 'TitleID_EventDispatch',
     'Secondary dispatch: EnumOpen, GetNext, GetCurrent, EnumCount, EnumFill'),

    ('LABEL_FA9029', 'TitleID_EnumFill',
     'Handle 0x1E0000D EnumFill: look up name, copy to buffer or send audio'),

    ('LABEL_FA9065', 'TitleID_EnumFill_HasName',
     'Name exists: push for Strcpy'),

    ('LABEL_FA906A', 'TitleID_EnumCount',
     'Handle 0x1E0000E EnumCount: return count in XHL'),

    ('LABEL_FA9070', 'TitleID_GetCurrent',
     'Handle 0x1E00009 GetCurrent: advance cursor, look up name'),

    ('LABEL_FA909D', 'TitleID_GetCurrent_HasName',
     'Name exists: push name addr (EAABAC) for Audio_SendCommand'),

    ('LABEL_FA90A3', 'TitleID_GetCurrent_SendAudio',
     'Push audio command params and call Audio_SendCommand'),

    ('LABEL_FA90B1', 'TitleID_GetNext',
     'Handle 0x1E0000B GetNext: advance cursor, copy name or send audio'),

    ('LABEL_FA90EF', 'TitleID_GetNext_HasName',
     'Name exists: push for Strcpy'),

    ('LABEL_FA90F3', 'TitleID_Strcpy',
     'Call Strcpy to copy name string'),

    ('LABEL_FA90F9', 'TitleID_ReturnZero',
     'Return XHL=0'),

    ('LABEL_FA90FE', 'TitleID_EnumOpen',
     'Handle 0x1E0000C EnumOpen: search table for matching name'),

    ('LABEL_FA911B', 'TitleID_EnumOpen_SearchLoop',
     'Search loop: get name, compare via Strcpy then FF0F35'),

    ('LABEL_FA915A', 'TitleID_EnumOpen_Compare',
     'Call FF0F35 to compare strings'),

    ('LABEL_FA9185', 'TitleID_EnumOpen_SearchNext',
     'No match: advance search index'),

    ('LABEL_FA9192', 'TitleID_EnumOpen_CheckResult',
     'Check if any match was found'),

    ('LABEL_FA9199', 'TitleID_EnumOpen_UpdateCursor',
     'Match found: update cursor position via FA951C helper'),

    ('LABEL_FA91AB', 'TitleID_EnumOpen_Return',
     'Return match result in XHL'),

    ('LABEL_FA91AE', 'TitleID_Return',
     'Epilogue: pop xiz, return'),

    # ==================================================================
    # EventIDProc / LABEL_FA9304 common ID proc (FA9304 - FA94A3)
    # Common ID procedure used by ModeIDProc, TitleIDProc, etc.
    # Handles GetInfoStr, CheckAvail, Dispatch, and search operations.
    # ==================================================================
    ('LABEL_FA9304', 'CommonIDProc',
     'Common ID handler: dispatch table for GetInfoStr, CheckAvail, etc.'),

    ('LABEL_FA936F', 'CommonIDProc_JumpTable',
     'Jump table data for event sub-dispatch'),

    ('LABEL_FA938D', 'CommonIDProc_CheckAvail',
     'Handle 0x1E00026: return 1 (available)'),

    ('LABEL_FA93DF', 'CommonIDProc_SearchLoop_Compare',
     'Compare target ID with table entry, copy name if match'),

    ('LABEL_FA93F6', 'CommonIDProc_SearchLoop_Next',
     'Advance to next entry in search table'),

    ('LABEL_FA93FA', 'CommonIDProc_SearchLoop_Check',
     'Check if table entry is non-null, continue search'),

    ('LABEL_FA9405', 'CommonIDProc_ReturnZero',
     'Return XHL=0 (handled/not found)'),

    ('LABEL_FA941F', 'CommonIDProc_EnumSearch_Compare',
     'Enum search: compare string via FF0F35, update on match'),

    ('LABEL_FA944B', 'CommonIDProc_EnumSearch_Next',
     'Advance enum search index'),

    ('LABEL_FA944D', 'CommonIDProc_EnumSearch_Check',
     'Compute table offset, check if entry is valid'),

    ('LABEL_FA9461', 'CommonIDProc_EnumSearch_EndCheck',
     'Check if current entry is null (end of list)'),

    ('LABEL_FA947F', 'CommonIDProc_EnumSearch_Atoi',
     'No table: convert text to numeric via FF09F6'),

    ('LABEL_FA9492', 'CommonIDProc_EnumSearch_Result',
     'Load search result into XHL'),

    ('LABEL_FA9497', 'CommonIDProc_Default',
     'Default: forward to FA4409 generic handler'),

    ('LABEL_FA94A3', 'CommonIDProc_Epilogue',
     'Epilogue: pop xiz, adjust stack, return'),

    # ==================================================================
    # LABEL_FA94A8 ID count helper (FA94A8 - FA950D)
    # Counts items across alphabetic categories (A-Z), used by ID procs.
    # ==================================================================
    ('LABEL_FA94A8', 'IDCountHelper',
     'Count items across A-Z categories via GetItemCount(0x1E00019/0x27)'),

    ('LABEL_FA94DA', 'IDCountHelper_Loop',
     'Loop over category characters (0x41+), accumulate counts'),

    ('LABEL_FA950D', 'IDCountHelper_Done',
     'Store total count, return'),

    # ==================================================================
    # LABEL_FA951C ID cursor advance (FA951C - FA9561+)
    # Advances ID cursor to indexed position by summing category counts.
    # ==================================================================
    ('LABEL_FA951C', 'IDCursorAdvance',
     'Advance cursor: sum category counts via GetItemCount up to index'),

    ('LABEL_FA953D', 'IDCursorAdvance_Loop',
     'Loop: read category char, query count (0x1E00027), accumulate'),

    ('LABEL_FA9561', 'IDCursorAdvance_Check',
     'Check if loop index < total count, continue or finish'),

    # ==================================================================
    # InitializeRoot  (FB2B06 - FB3089+)
    # VGA initialization and palette setup for the LCD display.
    # ==================================================================
    ('LABEL_FB2B06', 'VGA_Initialize',
     'Full VGA register initialization for 320x240 8bpp LCD'),

    ('LABEL_FB2F12', 'VGA_Init_ExtSeq0F_44',
     'Extended sequencer reg 0x0F = 0x44 for non-type-4 displays'),

    ('LABEL_FB2F21', 'VGA_Init_WriteExtSeq',
     'Write extended sequencer register value'),

    ('LABEL_FB2F24', 'VGA_Init_FinalRegs',
     'Final VGA register setup: ext sequencer, CRTC lock, palette'),

    ('LABEL_FB2FA1', 'VGA_Palette_Loop',
     'Palette write loop: 256 entries, 4 bytes per entry from table'),

    ('LABEL_FB2FCA', 'VGA_Palette_HighNibble',
     'Red >= 0xF0: extract high nibble without increment'),

    ('LABEL_FB2FD6', 'VGA_Palette_LowNibble',
     'Red bit3 clear: extract high nibble'),

    ('LABEL_FB2FE0', 'VGA_Palette_WriteRed',
     'Write red component to palette DAC (0x3C9)'),

    ('LABEL_FB3004', 'VGA_Palette_GreenHigh',
     'Green >= 0xF0: high nibble without increment'),

    ('LABEL_FB3009', 'VGA_Palette_GreenLow',
     'Green bit3 clear: high nibble'),

    ('LABEL_FB300C', 'VGA_Palette_WriteGreen',
     'Write green component to palette DAC'),

    ('LABEL_FB3030', 'VGA_Palette_BlueHigh',
     'Blue >= 0xF0: high nibble without increment'),

    ('LABEL_FB3035', 'VGA_Palette_BlueLow',
     'Blue bit3 clear: high nibble'),

    ('LABEL_FB3038', 'VGA_Palette_WriteBlue',
     'Write blue component, loop to next palette entry'),

    ('LABEL_FB3060', 'VGA_Stub_1',
     'Single ret (unused/placeholder)'),

    ('LABEL_FB3061', 'VGA_Stub_2',
     'Single ret (unused/placeholder)'),

    ('LABEL_FB3062', 'VGA_Stub_3',
     'Single ret (unused/placeholder)'),

    ('LABEL_FB3063', 'VGA_ClearVRAM',
     'Clear both VRAM pages (0x1A0000 and 0x1A9600) with Memset'),

    ('LABEL_FB3089', 'VGA_WriteReg_Delay',
     'Delay loop before VGA register write'),

    # ==================================================================
    # MstStyle2GridCheck  (FBA3FF - FBA6DA)
    # Master style 2 grid check: handles CellSelect (0x1E0008D) and
    # scroll events, builds display text for style grid cells.
    # ==================================================================
    ('LABEL_FBA3FF', 'MstGrid2_ScrollJumpTable',
     'Jump table data for scroll event dispatch'),

    ('LABEL_FBA486', 'MstGrid2_CellSelect',
     'Handle 0x1E0008D CellSelect: identify cell, build display text'),

    ('LABEL_FBA51D', 'MstGrid2_PadLeft_LoopA',
     'Pad loop A: prepend spaces (ED0E12 fmt) until string fills width'),

    ('LABEL_FBA534', 'MstGrid2_PadLeft_CheckA',
     'Check if padding count < (32 - strlen), continue loop A'),

    ('LABEL_FBA560', 'MstGrid2_OutOfRange_LowCol',
     'Column out of range (low): use fallback string 0xED0E14'),

    ('LABEL_FBA568', 'MstGrid2_UpperHalf',
     'Column >= 4: check against upper bound, build upper-half text'),

    ('LABEL_FBA582', 'MstGrid2_PadLeft_LoopB',
     'Pad loop B: prepend spaces (ED0E36 fmt) for upper-half text'),

    ('LABEL_FBA599', 'MstGrid2_PadLeft_CheckB',
     'Check if padding count < (32 - strlen), continue loop B'),

    ('LABEL_FBA5C7', 'MstGrid2_OutOfRange_HighCol',
     'Column out of range (high, upper half): use fallback 0xED0E38'),

    ('LABEL_FBA5CF', 'MstGrid2_LowerSection',
     'Row >= max: process lower section of grid'),

    ('LABEL_FBA5EA', 'MstGrid2_PadLeft_LoopC',
     'Pad loop C: prepend spaces (ED0E5A fmt) for lower-left text'),

    ('LABEL_FBA601', 'MstGrid2_PadLeft_CheckC',
     'Check if padding count < (32 - strlen), continue loop C'),

    ('LABEL_FBA62D', 'MstGrid2_OutOfRange_LowCol2',
     'Lower section column out of range: use fallback 0xED0E5C'),

    ('LABEL_FBA635', 'MstGrid2_BottomRight',
     'Bottom-right quadrant: check double-row boundary'),

    ('LABEL_FBA666', 'MstGrid2_PadLeft_LoopD',
     'Pad loop D: prepend spaces (ED0E7E fmt) for bottom-right text'),

    ('LABEL_FBA67D', 'MstGrid2_PadLeft_CheckD',
     'Check if padding count < (32 - strlen), continue loop D'),

    ('LABEL_FBA6AA', 'MstGrid2_OutOfRange_HighCol2',
     'Bottom-right column out of range: use fallback 0xED0E80'),

    ('LABEL_FBA6B1', 'MstGrid2_OutOfRange_BeyondMax',
     'Beyond maximum row*2: use fallback 0xED0EA2'),

    ('LABEL_FBA6B6', 'MstGrid2_CopyFallback',
     'Copy fallback string to output via Strcpy'),

    ('LABEL_FBA6C1', 'MstGrid2_CheckPlayAudio',
     'If column==1: send PlayAudio (0x1E0008C) event'),

    ('LABEL_FBA6DA', 'MstGrid2_Return',
     'Return XHL=0, epilogue'),

    ('LABEL_FBA6E1', 'MstGrid2_Boundary',
     'Trailing label (function boundary)'),

    # ==================================================================
    # MsaModeScreenProc  (FBD630 - FBD83C)
    # MSA mode screen procedure: handles Init, Show, Match, Paint,
    # Select, OK events. Manages mode selection display.
    # ==================================================================
    ('LABEL_FBD630', 'MsaMode_Init_Forward',
     'Init done: forward Init to FA4409 generic handler'),

    ('LABEL_FBD63F', 'MsaMode_Show',
     'Handle 0x1C0000B Show: forward to handler, update mode display 0x401'),

    ('LABEL_FBD65E', 'MsaMode_Match',
     'Handle 0x1C0001C Match: update selection from match result'),

    ('LABEL_FBD69E', 'MsaMode_Paint',
     'Handle 0x1C0000D Paint: forward, then send Select'),

    ('LABEL_FBD6B4', 'MsaMode_DispatchSelect',
     'Call FA9660 to dispatch Select event'),

    ('LABEL_FBD6BB', 'MsaMode_Select',
     'Handle 0x1C0000E Select: compute highlight rect for mode display'),

    ('LABEL_FBD71A', 'MsaMode_Select_RightSide',
     'Mode on right side: set rect x=0xA3..0x137'),

    ('LABEL_FBD722', 'MsaMode_Select_DrawHighlight1',
     'Draw first highlight with pushw 0xF5, call F9C86F'),

    ('LABEL_FBD776', 'MsaMode_Select_RightSide2',
     'Second mode entry on right side: set rect x=0xA3..0x137'),

    ('LABEL_FBD77E', 'MsaMode_Select_DrawHighlight2',
     'Draw second highlight with pushw 0xF2, call F9C86F'),

    ('LABEL_FBD78C', 'MsaMode_OK',
     'Handle 0x1C00007 OK: dispatch by sub-command'),

    ('LABEL_FBD7EA', 'MsaMode_OK_Cmd89',
     'OK sub-command 0x89: call F9F88A with bc=1, de=1'),

    ('LABEL_FBD7F5', 'MsaMode_OK_Cmd8A',
     'OK sub-command 0x8A: call F9F88A with bc=2, de=1'),

    ('LABEL_FBD800', 'MsaMode_OK_Cmd8B',
     'OK sub-command 0x8B: call F9F88A with bc=3, de=1'),

    ('LABEL_FBD809', 'MsaMode_OK_ModeChange',
     'Call F9F88A for mode change'),

    ('LABEL_FBD80F', 'MsaMode_OK_Navigate',
     'No CanNavUp: send Navigate 0x1C00015 to 0x1A00040'),

    ('LABEL_FBD822', 'MsaMode_ReturnZero',
     'Return XHL=0'),

    ('LABEL_FBD826', 'MsaMode_OK_DefaultForward',
     'OK unrecognized sub-command: forward to FA4409'),

    ('LABEL_FBD830', 'MsaMode_Default',
     'Default: forward unhandled events to FA4409'),

    ('LABEL_FBD838', 'MsaMode_CallHandler',
     'Tail call to FA4409 generic handler'),

    ('LABEL_FBD83C', 'MsaMode_Epilogue',
     'Epilogue: pop xiz, adjust stack, return'),

    ('LABEL_FBD841', 'MsaMode_Boundary',
     'Trailing label (function boundary)'),

    # ==================================================================
    # PmemModeBoxProc  (FBD89A - FBDB36)
    # Performance memory mode box procedure: handles Init, Show, Match,
    # Paint, Select, OK events. Manages perf-memory mode selection.
    # ==================================================================
    ('LABEL_FBD89A', 'PmemMode_Show',
     'Handle 0x1C0000B Show: forward, update perf-memory display 0x302'),

    ('LABEL_FBD8BF', 'PmemMode_Match',
     'Handle 0x1C0001C Match: update stored mode from match result'),

    ('LABEL_FBD90A', 'PmemMode_Paint',
     'Handle 0x1C0000D Paint: draw mode box with centered label text'),

    ('LABEL_FBD9A2', 'PmemMode_DispatchSelect',
     'Call FA9660 to dispatch Select, then return'),

    ('LABEL_FBD9A9', 'PmemMode_Select',
     'Handle 0x1C0000E Select: compute highlight rect for perf-memory mode'),

    ('LABEL_FBDA14', 'PmemMode_Select_RightSide',
     'Mode on right side: set rect x=0xA3..0x137'),

    ('LABEL_FBDA1C', 'PmemMode_Select_DrawHighlight1',
     'Draw first highlight with pushw 0xF5, call F9C86F'),

    ('LABEL_FBDA76', 'PmemMode_Select_RightSide2',
     'Second entry on right side: set rect x=0xA3..0x137'),

    ('LABEL_FBDA7E', 'PmemMode_Select_DrawHighlight2',
     'Draw second highlight with pushw 0xF2, call F9C86F'),

    ('LABEL_FBDA8B', 'PmemMode_OK',
     'Handle 0x1C00007 OK: dispatch by sub-command'),

    ('LABEL_FBDAE9', 'PmemMode_OK_Cmd89',
     'OK sub-command 0x89: call F9F88A with bc=0, de=1'),

    ('LABEL_FBDAF4', 'PmemMode_OK_Cmd8B',
     'OK sub-command 0x8B: call F9F88A with bc=1, de=1'),

    ('LABEL_FBDAFD', 'PmemMode_OK_ModeChange',
     'Call F9F88A for mode change'),

    ('LABEL_FBDB01', 'PmemMode_ReturnZero',
     'Return XHL=0'),

    ('LABEL_FBDB05', 'PmemMode_OK_Navigate',
     'No CanNavUp: send Navigate 0x1C00015 to 0x1A00040'),

    ('LABEL_FBDB18', 'PmemMode_OK_DefaultForward',
     'OK unrecognized sub-command: forward to FA4409'),

    ('LABEL_FBDB26', 'PmemMode_Default',
     'Default: forward unhandled events to FA4409'),

    ('LABEL_FBDB32', 'PmemMode_CallHandler',
     'Tail call to FA4409 generic handler'),

    ('LABEL_FBDB36', 'PmemMode_Epilogue',
     'Epilogue: pop xiz, return'),

    ('LABEL_FBDB3D', 'PmemMode_Boundary',
     'Trailing label (function boundary)'),

    # ==================================================================
    # AcPmBkEditBoxProc  (FBDBFC - FBE0BC)
    # PM bank edit box procedure: handles GetText, BankChanged, BankEdit,
    # SetValue, AddDelta, Show/Hide, Assign, AutoInc/Dec, ScrollUp/Down,
    # OK (with save/load/delete actions).
    # ==================================================================
    ('LABEL_FBDBFC', 'AcPmBkEdit_BankChanged',
     'Handle 0x1C20002 BankChanged: audio feedback, send Confirm'),

    ('LABEL_FBDC40', 'AcPmBkEdit_BankChanged_UpdateLoop',
     'Loop: update bank display entries 1..8 via PmBankUpdate'),

    ('LABEL_FBDC73', 'AcPmBkEdit_BankEdit',
     'Handle 0x1C20003 BankEdit: draw edit box, audio feedback'),

    ('LABEL_FBDCF8', 'AcPmBkEdit_BankEdit_DrawDiff',
     'Bank differs from current: draw with color 0xFF/0xF5'),

    ('LABEL_FBDD05', 'AcPmBkEdit_BankEdit_DrawCall',
     'Call FACF4A to render bank edit display'),

    ('LABEL_FBDD0C', 'AcPmBkEdit_SetValue',
     'Handle 0x1E0003B SetValue: query data source and bounds'),

    ('LABEL_FBDD7D', 'AcPmBkEdit_AddDelta',
     'Handle 0x1E0003D AddDelta: query data source and bounds'),

    ('LABEL_FBDDEE', 'AcPmBkEdit_ShowHide',
     'Handle 0x1C0000B/0x1C0000C Show/Hide: forward, setup data display'),

    ('LABEL_FBDE32', 'AcPmBkEdit_Assign',
     'Handle 0x1C0001D Assign: verify data source match, store and confirm'),

    ('LABEL_FBDE7C', 'AcPmBkEdit_AutoIncUp',
     'Handle 0x1C00019 AutoIncUp: check CanScroll, get up step, apply delta'),

    ('LABEL_FBDECA', 'AcPmBkEdit_ScrollUp',
     'Handle 0x1C00017 ScrollUp: check CanScroll, get up step, apply delta'),

    ('LABEL_FBDF18', 'AcPmBkEdit_ScrollDown',
     'Handle 0x1C00018 ScrollDown: negate up step, apply delta'),

    ('LABEL_FBDF6C', 'AcPmBkEdit_AutoIncDown',
     'Handle 0x1C0001A AutoIncDown: negate down step, apply delta'),

    ('LABEL_FBDFBE', 'AcPmBkEdit_DispatchAndReturn',
     'Dispatch event via FA9660, then return'),

    ('LABEL_FBDFC5', 'AcPmBkEdit_OK',
     'Handle 0x1C00007 OK: dispatch by sub-command (save/load/delete)'),

    ('LABEL_FBE026', 'AcPmBkEdit_OK_Load',
     'OK sub-command 0xA: load bank (check if slot occupied)'),

    ('LABEL_FBE058', 'AcPmBkEdit_OK_LoadEmpty',
     'Slot empty: show warning dialog 0x1A000EE'),

    ('LABEL_FBE072', 'AcPmBkEdit_OK_SaveDelete',
     'OK sub-commands 0x10/0x90: save or delete bank'),

    ('LABEL_FBE0A6', 'AcPmBkEdit_OK_NavComplete',
     'Call FA9752 NavComplete and return'),

    ('LABEL_FBE0AA', 'AcPmBkEdit_ReturnZero',
     'Return XHL=0'),

    ('LABEL_FBE0AE', 'AcPmBkEdit_Default',
     'Default: forward unhandled events to FA4409'),

    ('LABEL_FBE0BC', 'AcPmBkEdit_Epilogue',
     'Epilogue: pop xiz, return'),

    # ==================================================================
    # PmBankScreenProc  (FC1A87 - FC1F1F)
    # PM bank screen procedure: handles Init, Show, EnumNotify, Paint,
    # Select, Confirm, BankChanged, OK (with 10 bank slot sub-commands).
    # ==================================================================
    ('LABEL_FC1A87', 'PmBank_Show',
     'Handle 0x1C0000B Show: forward, send PmBankEnumInit (0x1E2000F)'),

    ('LABEL_FC1AA6', 'PmBank_EnumNotify',
     'Handle 0x1E2000E EnumNotifySelect: send Confirm then Select'),

    ('LABEL_FC1ADD', 'PmBank_Paint',
     'Handle 0x1C0000D Paint: forward to FA4409'),

    ('LABEL_FC1AE9', 'PmBank_ForwardToHandler',
     'Tail call to FA4409'),

    ('LABEL_FC1AF0', 'PmBank_Select',
     'Handle 0x1C0000E Select: draw bank name with highlight rect'),

    ('LABEL_FC1B73', 'PmBank_Select_RightSide',
     'Bank on right side: set rect x=0xA3..0x137'),

    ('LABEL_FC1B7B', 'PmBank_Select_DrawFirstRow',
     'Draw first row: bank name with F5 color, send PmBankUpdate'),

    ('LABEL_FC1BF5', 'PmBank_Select_SecondRightSide',
     'Second bank row on right side: set rect x=0xA3..0x137'),

    ('LABEL_FC1BFD', 'PmBank_Select_DrawSecondRow',
     'Draw second row: bank indicator with C1 color, send PmBankUpdate'),

    ('LABEL_FC1C27', 'PmBank_Confirm',
     'Handle 0x1C0000F Confirm: update all 10 bank slots'),

    ('LABEL_FC1C43', 'PmBank_Confirm_Loop',
     'Loop 0..9: send PmBankUpdate for each bank slot'),

    ('LABEL_FC1C6C', 'PmBank_BankChanged',
     'Handle 0x1C20002 BankChanged: redraw bank slot with feedback'),

    ('LABEL_FC1C95', 'PmBank_BankChanged_Lookup',
     'Look up bank position, highlight, audio, draw text'),

    ('LABEL_FC1CFE', 'PmBank_BankChanged_RightSide',
     'Bank on right side: set rect x=0xA3..0xBE'),

    ('LABEL_FC1D06', 'PmBank_BankChanged_DrawSlot',
     'Draw slot: audio SendCommand, text render via FACF4A'),

    ('LABEL_FC1D7F', 'PmBank_BankChanged_SecondRight',
     'Second indicator on right side: set rect x=0xAB..0x137'),

    ('LABEL_FC1D87', 'PmBank_BankChanged_DrawIndicator',
     'Draw bank occupancy indicator via FACF4A'),

    ('LABEL_FC1DA9', 'PmBank_OK',
     'Handle 0x1C00007 OK: dispatch by bank slot sub-command'),

    ('LABEL_FC1E2F', 'PmBank_OK_SaveDelete',
     'OK sub-commands 0x10/0x90: save/delete bank with dialog'),

    ('LABEL_FC1E67', 'PmBank_OK_Forward',
     'Forward OK to FA4409'),

    ('LABEL_FC1E76', 'PmBank_OK_Slot0',
     'OK sub-command 0x88: select bank slot 0'),

    ('LABEL_FC1E85', 'PmBank_OK_Slot1',
     'OK sub-command 0x89: select bank slot 1'),

    ('LABEL_FC1E93', 'PmBank_OK_Slot2',
     'OK sub-command 0x8A: select bank slot 2'),

    ('LABEL_FC1EA1', 'PmBank_OK_Slot3',
     'OK sub-command 0x8B: select bank slot 3'),

    ('LABEL_FC1EAF', 'PmBank_OK_Slot4',
     'OK sub-command 0x8C: select bank slot 4'),

    ('LABEL_FC1EBD', 'PmBank_OK_Slot5',
     'OK sub-command 0x8: select bank slot 5'),

    ('LABEL_FC1ECB', 'PmBank_OK_Slot6',
     'OK sub-command 0x9: select bank slot 6'),

    ('LABEL_FC1ED9', 'PmBank_OK_Slot7',
     'OK sub-command 0xA: select bank slot 7'),

    ('LABEL_FC1EE7', 'PmBank_OK_Slot8',
     'OK sub-command 0xB: select bank slot 8'),

    ('LABEL_FC1EF8', 'PmBank_OK_Slot9',
     'OK sub-command 0xC: select bank slot 9'),

    ('LABEL_FC1F07', 'PmBank_DispatchBankSelect',
     'Call FA4A63 to dispatch bank selection event'),

    ('LABEL_FC1F0B', 'PmBank_ReturnZero',
     'Return XHL=0'),

    ('LABEL_FC1F0F', 'PmBank_Default',
     'Default: forward unhandled events to FA4409'),

    ('LABEL_FC1F1B', 'PmBank_CallHandler',
     'Tail call to FA4409'),

    ('LABEL_FC1F1F', 'PmBank_Epilogue',
     'Epilogue: pop xiz, return'),

    ('LABEL_FC1F26', 'PmBank_Boundary',
     'Trailing label (function boundary)'),

    # ==================================================================
    # GET_COMPUTER_INTERFACE_SELECTION region (FDBB3C - FDBD2B)
    # Computer interface (expression pedal/pitch bend) processing.
    # Handles MIDI CC filtering, up/down ramp, calibration.
    # ==================================================================
    ('LABEL_FDBB3C', 'CompIface_ProcessInput',
     'Main input processor: check active bits, dispatch to up/down/filter'),

    ('LABEL_FDBB65', 'CompIface_CheckUpDown',
     'Check bit4/5 of status: dispatch to ramp-up or ramp-down'),

    ('LABEL_FDBB75', 'CompIface_RampDown',
     'Bit5 set: ramp-down handler (call F59AD3, then F3CAC1)'),

    ('LABEL_FDBB87', 'CompIface_RampDown_Start',
     'Set bit1 of 9834, call F59AD3'),

    ('LABEL_FDBB8D', 'CompIface_FilterBySource',
     'Filter by source register bits (1054 vs 1057)'),

    ('LABEL_FDBB9F', 'CompIface_FromSource2',
     'Source from reg 1057 bit2: check ramp-down, call FEBF7A'),

    ('LABEL_FDBBBB', 'CompIface_Source2_ZeroCheck',
     'FEBF7A result & 7 == 0: check expression pedal position'),

    ('LABEL_FDBBC3', 'CompIface_SetPedalBit',
     'Set bit1 in pedal state register 9834'),

    ('LABEL_FDBBC7', 'CompIface_CallFilterA',
     'Call F59AB9 filter handler A'),

    ('LABEL_FDBBCB', 'CompIface_CallSync',
     'Call F3CAC1 synchronization routine'),

    ('LABEL_FDBBCF', 'CompIface_PostProcess',
     'Post-process: call F6E63A, check bit6 for auto-release'),

    ('LABEL_FDBC00', 'CompIface_RampControl',
     'Ramp control: compute delta from position, apply up or down'),

    ('LABEL_FDBC35', 'CompIface_RampUp_Clamp',
     'Clamp ramp-up value to max 0x7F00'),

    ('LABEL_FDBC66', 'CompIface_RampDown_Apply',
     'Apply ramp-down: subtract delta, clamp to 0'),

    ('LABEL_FDBC88', 'CompIface_RampDown_Clamp',
     'Clamp ramp-down value to min 0'),

    ('LABEL_FDBCBB', 'CompIface_ResetPedal',
     'Reset pedal state: clear bit2, set bit0, send 0x4D command'),

    ('LABEL_FDBCD1', 'CompIface_SetMax',
     'Set volume to 0x7F max, call FDB283+EF14D8'),

    ('LABEL_FDBCE8', 'CompIface_ScaleValue',
     'Scale 8-bit value by 0x1D4C0, divide by BC (linear interpolation)'),

    ('LABEL_FDBD04', 'CompIface_ScaleAndNormalize',
     'Scale by 0x1EF0, divide by BC, then divide by 0x7F00'),

    ('LABEL_FDBD2B', 'CompIface_WriteVolume',
     'Write volume byte to 49644, send SoundParam 0x4005 notify'),

    # ==================================================================
    # SeqAlt3_ReadByte region (EF2C2F - EF2E1F)
    # Sequencer ring buffer operations for alternate channels.
    # Channel 3 uses buffer at 0x0201C1, channel 4 at 0x0202CB,
    # channel 5 at 0x0203D5.
    # ==================================================================
    ('LABEL_EF2C2F', 'SeqAlt3_WriteByte',
     'Write single byte to ring buffer at 0x0201C1'),

    ('LABEL_EF2C45', 'SeqAlt3_WriteBlock',
     'Write BC bytes from (XIY) to ring buffer at 0x0201C1'),

    ('LABEL_EF2C57', 'SeqAlt3_WriteBlock_Loop',
     'Loop: write each byte from source buffer to ring buffer'),

    ('LABEL_EF2C67', 'SeqAlt3_CheckEmpty',
     'Check if ring buffer 3 is empty (compare write/read pointers)'),

    ('LABEL_EF2C78', 'SeqAlt3_CheckEmpty_Done',
     'Return HL=0 (empty) or HL=0xFFFF (not empty)'),

    ('LABEL_EF2C79', 'SeqAlt3_GetWritePos',
     'Return current write position of ring buffer 3'),

    ('LABEL_EF2C7F', 'SeqAlt3_Flush',
     'Flush ring buffer 3 via EF2F69'),

    ('LABEL_EF2C8D', 'SeqAlt3_SaveWritePtr',
     'Save write pointer: copy (0x0201B9) to (0x0201B7)'),

    ('LABEL_EF2C9A', 'SeqAlt3_CommitWrite',
     'Commit write: call EF2FA1 with buffer at 0x0201C1'),

    ('LABEL_EF2CA8', 'SeqAlt3_RollbackWrite',
     'Rollback write: call EF2FBC with buffer at 0x0201C1'),

    ('LABEL_EF2CB6', 'SeqAlt3_SaveReadPtr',
     'Save read pointer: copy (0x0201BB) to (0x0201B9)'),

    ('LABEL_EF2CC3', 'SeqAlt3_AdvanceCheckpoint',
     'Advance checkpoint: copy (0x0201BD) to (0x0201BB)'),

    ('LABEL_EF2CD0', 'SeqAlt4_ReadByte',
     'Read single byte from ring buffer at 0x0202CB'),

    ('LABEL_EF2CDD', 'SeqAlt4_WriteByte_Data',
     'Write byte data block for ring buffer 4 (0x0202CB)'),

    ('LABEL_EF2D2D', 'SeqAlt4_Flush',
     'Flush ring buffer 4 via EF2F69'),

    ('LABEL_EF2D3B', 'SeqAlt4_SaveWritePtr',
     'Save write pointer: copy (0x020283) to (0x020281)'),

    ('LABEL_EF2D8B', 'SeqAlt4_WriteByte_Block',
     'Write byte block data for ring buffer 4'),

    ('LABEL_EF2DDB', 'SeqAlt5_Flush',
     'Flush ring buffer 5 (0x0203D5) via EF2F69'),

    ('LABEL_EF2DE9', 'SeqAlt5_SaveWritePtr',
     'Save write pointer for ring buffer 5'),

    ('LABEL_EF2DF6', 'SeqAlt5_CommitWrite',
     'Commit write: call EF2FA1 with buffer at 0x0203D5'),

    ('LABEL_EF2E04', 'SeqAlt5_RollbackWrite',
     'Rollback write: call EF2FBC with buffer at 0x0203D5'),

    ('LABEL_EF2E12', 'SeqAlt5_SaveReadPtr',
     'Save read pointer for ring buffer 5'),

    ('LABEL_EF2E1F', 'SeqAlt5_AdvanceCheckpoint',
     'Advance checkpoint for ring buffer 5'),

    # ==================================================================
    # Seq_RingBuf_Init_2048 region (EF3130 - EF3276)
    # Ring buffer operations: peek, write, read for 2048-byte buffers.
    # Also multi-byte write wrappers.
    # ==================================================================
    ('LABEL_EF3130', 'Seq_RingBuf_PeekByte',
     'Peek next byte from ring buffer without consuming (check read!=write)'),

    ('LABEL_EF313C', 'Seq_RingBuf_PeekByte_Read',
     'Read byte at read pointer, advance with 0x7FF wrap, increment avail'),

    ('LABEL_EF314E', 'Seq_RingBuf_WriteByte_Data',
     'Embedded .byte data block for write-byte operation'),

    ('LABEL_EF3169', 'Seq_RingBuf_ReadAhead',
     'Read-ahead: peek byte at undo pointer without consuming'),

    ('LABEL_EF3175', 'Seq_RingBuf_ReadAhead_Read',
     'Read byte at undo pointer, advance with 0x7FF wrap'),

    ('LABEL_EF3184', 'Seq_RingBuf_WriteByte_Check',
     'Check if buffer has space (avail != 0) before writing'),

    ('LABEL_EF318F', 'Seq_RingBuf_WriteByte_Store',
     'Store byte at write pointer, advance with 0x7FF wrap, decrement avail'),

    ('LABEL_EF31A5', 'Seq_RingBuf_Nop',
     'No-op return (unused ring buffer stub)'),

    ('LABEL_EF31A6', 'Seq_MultiWrite_Alt4',
     'Multi-byte write wrapper for ring buffer 4 (SeqAlt4)'),

    ('LABEL_EF31BA', 'Seq_MultiWrite_Alt4_Loop',
     'Loop: extract bytes from XBC, write each via SeqAlt4_WriteByte'),

    ('LABEL_EF31D7', 'Seq_MultiWrite_Alt4_Done',
     'Multi-write done: restore iz, clean stack'),

    ('LABEL_EF31DB', 'Seq_MultiWrite_Alt3',
     'Multi-byte write wrapper for ring buffer 3 (SeqAlt3)'),

    ('LABEL_EF31EF', 'Seq_MultiWrite_Alt3_Loop',
     'Loop: extract bytes from XBC, write each via SeqAlt3_WriteByte'),

    ('LABEL_EF320C', 'Seq_MultiWrite_Alt3_Done',
     'Multi-write done: restore iz, clean stack'),

    ('LABEL_EF3210', 'Seq_MultiWrite_Alt1',
     'Multi-byte write wrapper for ring buffer 1'),

    ('LABEL_EF3224', 'Seq_MultiWrite_Alt1_Loop',
     'Loop: extract bytes from XBC, write each via 0xEF2A25'),

    ('LABEL_EF3241', 'Seq_MultiWrite_Alt1_Done',
     'Multi-write done: restore iz, clean stack'),

    ('LABEL_EF3245', 'Seq_MultiWrite_Alt5',
     'Multi-byte write wrapper for ring buffer 5 (SeqAlt5)'),

    ('LABEL_EF3259', 'Seq_MultiWrite_Alt5_Loop',
     'Loop: extract bytes from XBC, write each via SeqAlt5_WriteByte'),

    ('LABEL_EF3276', 'Seq_MultiWrite_Alt5_Done',
     'Multi-write done: restore iz, clean stack'),

    ('LABEL_EF327A', 'Seq_WriteMidi90',
     'Write MIDI 0x90 (Note On) two-byte payload to ring buffer 4'),

    ('LABEL_EF329C', 'Seq_WriteMidi90_Done',
     'Note On write complete: pop xiz, return'),

    # ==================================================================
    # AcInOutGridBoxProc  (F757BC - F75A7E)
    # In/Out grid box procedure: handles Init (with scroll setup),
    # ScrollUp/ScrollDown, GetColText, GetRowText, CellSelect events.
    # ==================================================================
    ('LABEL_F757BC', 'AcInOutGrid_Init',
     'Handle 0x1C00001 Init: get cell index, setup scroll boundaries'),

    ('LABEL_F7588B', 'AcInOutGrid_ScrollUp_AltTable',
     'ScrollUp with alt table (0xE7F9F2): compute delta, send Select'),

    ('LABEL_F758AB', 'AcInOutGrid_ScrollUp_Dispatch',
     'Dispatch Select event after scroll computation'),

    ('LABEL_F758BF', 'AcInOutGrid_ScrollUp_CheckAlt',
     'Check CanScrollAlt (0x1E00091): if yes, use alternate handler'),

    ('LABEL_F75978', 'AcInOutGrid_ScrollDown_AltTable',
     'ScrollDown with alt table (0xE7FA16): compute delta, send Select'),

    ('LABEL_F75996', 'AcInOutGrid_ScrollDown_Dispatch',
     'Dispatch Select event after scroll-down computation'),

    ('LABEL_F759AA', 'AcInOutGrid_ScrollDown_CheckAlt',
     'Check CanScrollAlt (0x1E00091): if yes, use alternate handler'),

    ('LABEL_F759FF', 'AcInOutGrid_SetScrollBounds',
     'Call F9A53B to finalize scroll boundaries'),

    ('LABEL_F75A05', 'AcInOutGrid_GetColText',
     'Handle 0x1E0008A GetColText: return text from field+62'),

    ('LABEL_F75A12', 'AcInOutGrid_GetRowText',
     'Handle 0x1E0008B GetRowText: lookup row text by data source'),

    ('LABEL_F75A2E', 'AcInOutGrid_GetRowText_Src1',
     'Data source 1: use table at 0xE7FAE2'),

    ('LABEL_F75A35', 'AcInOutGrid_GetRowText_Src2',
     'Data source 2: use table at 0xE7FBB4'),

    ('LABEL_F75A3A', 'AcInOutGrid_GetRowText_Push',
     'Push text address for Strcpy'),

    ('LABEL_F75A3B', 'AcInOutGrid_Strcpy',
     'Call Strcpy to copy text to output buffer'),

    ('LABEL_F75A59', 'AcInOutGrid_CellSelect',
     'Handle 0x1E0008D CellSelect: forward to FA49B7 with field+70'),

    ('LABEL_F75A69', 'AcInOutGrid_CellSelect_Call',
     'Tail call to FA49B7 cell select handler'),

    ('LABEL_F75A6D', 'AcInOutGrid_ReturnZero',
     'Return XHL=0'),

    ('LABEL_F75A71', 'AcInOutGrid_Default',
     'Default: forward unhandled events to FA4409'),

    ('LABEL_F75A7E', 'AcInOutGrid_Epilogue',
     'Epilogue: pop xiz, adjust stack, return'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')

    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')

    renamed = 0
    for old_label, new_label, comment in RENAMES:
        if old_label + ':' not in content:
            print(f'  WARNING: {old_label} not found, skipping')
            continue

        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        new_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)

        if new_content != content:
            content = new_content
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:45s} ({refs} refs)')

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in maincpu')


if __name__ == '__main__':
    main()
