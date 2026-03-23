#!/usr/bin/env python3
"""Rename LABEL_* to semantic names for sound/voice/UI widget procedures in maincpu.

Covers 16 functions spanning sound argument grids, performance memory output,
sound part/drawbar/accordion procedures, welcome screen, switch-button writer,
and rhythm MIDI CC handling:

  AcSndArgGridBoxProc, SndArgGridCheck,
  VwVariBoxProc,
  AcCtlMsgGridBoxProc,
  AcPmemOutLGridBoxProc, AcPmemOutRGridBoxProc,
  IvSdpartProc, AcLswPartEditBoxProc, AcLswPartPanProc,
  IvAccordionProc,
  AcWelcomScreenProc,
  IvDrawbarProc, AcDrawbarNameProc, IvDrawbar1Proc,
  SwbtWr,
  RhythmMidi_HandleCC

Each rename was determined by analyzing the dispatch tables, event code
comparisons, control flow, and widget field access patterns.

NAKA event codes referenced:
  0x1C00001=Init, 0x1C00002=Close, 0x1C00007=OK, 0x1C0000B=Show,
  0x1C0000C=Hide, 0x1C0000D=Paint, 0x1C0000E=Select, 0x1C0000F=Confirm,
  0x1C00017=ScrollUp, 0x1C00018=ScrollDown, 0x1C00019=AutoIncUp,
  0x1C0001A=AutoIncDown, 0x1C0001B=Release, 0x1C0001C=Match,
  0x1C0001E=PageChange, 0x1C00020=Notify, 0x1C00023=Update,
  0x1C00029=PageSelect, 0x1C0002F=Refresh, 0x1C00031=Snap,
  0x1C00035=TabSelect, 0x1C10000=PartSelect, 0x1C10004=SubCpuError,
  0x1C10008=DrawbarInit, 0x1C10009=SubCpuLoaded,
  0x1E0003A=GetText, 0x1E0003B=SetValue, 0x1E0003C=CanScroll,
  0x1E0003D=AddDelta, 0x1E0003E=GetUpStep, 0x1E0003F=GetDownStep,
  0x1E0004D=SetIndex, 0x1E00050=CanScrollEvt,
  0x1E0008A=GetColText, 0x1E0008B=GetRowText, 0x1E0008C=PlayAudio,
  0x1E0008D=CellSelect, 0x1E0008E=GridScroll, 0x1E0008F=GetCellIndex,
  0x1E00091=CanAutoScroll, 0x1E000A7=DrawbarUpdate,
  0x1E000B3=SwitchMode, 0x1E10008=DrawbarLoadVals,
  0x1E1000A=DrawbarSetParam, 0x1E1000E=DrawbarNameSet,
  0x1E40022=PlayColAudio, 0x1E40023=PlayRowAudio

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
    # AcSndArgGridBoxProc  (F1D2A2 - F1D693)
    # Sound argument grid box procedure: handles grid cell selection,
    # scrolling, column/row text, audio playback for sound arguments.
    # Dispatches events 0x1E0008C, 0x1E40023/22, 0x1E0008D, 0x1E0008B,
    # 0x1E0008A, 0x1C00001 (Init), and ScrollUp/Down jump table.
    # ==================================================================
    ('LABEL_F1D2EE', 'AcSndArgGrid_Init',
     'Handle 0x1C00001 Init: forward to base, get cell index, set scroll bounds'),

    ('LABEL_F1D3E1', 'AcSndArgGrid_ScrollUp_NoCanScroll',
     'ScrollUp when CanScrollEvt=0: try CanAutoScroll fallback'),

    ('LABEL_F1D4BF', 'AcSndArgGrid_ScrollDown_NoCanScroll',
     'ScrollDown when CanScrollEvt=0: try CanAutoScroll fallback'),

    ('LABEL_F1D515', 'AcSndArgGrid_ScrollCommit',
     'Commit scroll: call 0xF9A53B then return handled'),

    ('LABEL_F1D51C', 'AcSndArgGrid_GetColText',
     'Handle 0x1E0008A GetColText: set offset 0x3E for col text buffer'),

    ('LABEL_F1D526', 'AcSndArgGrid_GetRowText',
     'Handle 0x1E0008B GetRowText: set offset 0x42 for row text buffer'),

    ('LABEL_F1D52E', 'AcSndArgGrid_CopyText',
     'Common text copy: get widget data at offset, Strcpy to caller buffer'),

    ('LABEL_F1D5E0', 'AcSndArgGrid_CellSel_CC00',
     'CellSelect for key 0xCC00/CC20: row=1 col=3'),

    ('LABEL_F1D5EF', 'AcSndArgGrid_CellSel_CC5E',
     'CellSelect for key 0xCC5E: row=2 col=3'),

    ('LABEL_F1D5FE', 'AcSndArgGrid_CellSel_C000',
     'CellSelect for key 0xC000/C020: row=1 col=4'),

    ('LABEL_F1D60D', 'AcSndArgGrid_CellSel_C05E',
     'CellSelect for key 0xC05E: row=2 col=4'),

    ('LABEL_F1D61C', 'AcSndArgGrid_CellSel_C400',
     'CellSelect for key 0xC400/C420: row=1 col=5'),

    ('LABEL_F1D62B', 'AcSndArgGrid_CellSel_C45E',
     'CellSelect for key 0xC45E: row=2 col=5'),

    ('LABEL_F1D63A', 'AcSndArgGrid_CellSel_C800',
     'CellSelect for key 0xC800/C820: row=1 col=6'),

    ('LABEL_F1D649', 'AcSndArgGrid_CellSel_C85E',
     'CellSelect for key 0xC85E: row=2 col=6'),

    ('LABEL_F1D656', 'AcSndArgGrid_CellSel_Dispatch',
     'Dispatch CellSelect event with computed row/col'),

    ('LABEL_F1D65C', 'AcSndArgGrid_ForwardToParent',
     'Forward PlayRowAudio/PlayColAudio/CellSelect to parent widget'),

    ('LABEL_F1D671', 'AcSndArgGrid_PlayAudio',
     'Handle 0x1E0008C PlayAudio: check caller 0x1A000EE'),

    ('LABEL_F1D67D', 'AcSndArgGrid_ReturnHandled',
     'Return xhl=0 (event handled)'),

    ('LABEL_F1D681', 'AcSndArgGrid_ForwardToBase',
     'Forward unhandled event to AcGridBoxProc base'),

    ('LABEL_F1D68D', 'AcSndArgGrid_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # SndArgGridCheck  (F1D693 - F1D7E7)
    # Sound argument grid check helper: handles CellSelect, PlayColAudio,
    # PlayRowAudio events with index-based audio command dispatch.
    # ==================================================================
    ('LABEL_F1D6FA', 'SndArgGridCheck_JumpTableFallthrough',
     'Jump table fallthrough point for scroll events'),

    ('LABEL_F1D6FD', 'SndArgGridCheck_CellSelect',
     'Handle 0x1E0008D CellSelect: store values, compare row for action'),

    ('LABEL_F1D721', 'SndArgGridCheck_CellSel_Row2',
     'CellSelect row=2: send PlayRowAudio event 0x1E40021'),

    ('LABEL_F1D72B', 'SndArgGridCheck_CellSel_SendEvent',
     'Common call to send PlayColAudio/PlayRowAudio event'),

    ('LABEL_F1D732', 'SndArgGridCheck_PlayColAudio',
     'Handle 0x1E40022 PlayColAudio: lookup column audio command'),

    ('LABEL_F1D75B', 'SndArgGridCheck_PlayCol_1',
     'PlayColAudio column 1: ldada 14857'),

    ('LABEL_F1D761', 'SndArgGridCheck_PlayCol_2',
     'PlayColAudio column 2: ldada 14874'),

    ('LABEL_F1D767', 'SndArgGridCheck_PlayCol_3',
     'PlayColAudio column 3: ldada 14891'),

    ('LABEL_F1D76D', 'SndArgGridCheck_PlayCol_4',
     'PlayColAudio column 4: ldada 14908'),

    ('LABEL_F1D771', 'SndArgGridCheck_PlayCol_Strcpy',
     'Copy column audio string and continue'),

    ('LABEL_F1D779', 'SndArgGridCheck_PlayCol_Send',
     'Finalize column audio: call 0xFA44D0, send PlayAudio event'),

    ('LABEL_F1D789', 'SndArgGridCheck_PlayRowAudio',
     'Handle 0x1E40023 PlayRowAudio: lookup row audio command'),

    ('LABEL_F1D7B2', 'SndArgGridCheck_PlayRow_1',
     'PlayRowAudio row 1: ldada 14824'),

    ('LABEL_F1D7B8', 'SndArgGridCheck_PlayRow_2',
     'PlayRowAudio row 2: ldada 14828'),

    ('LABEL_F1D7BE', 'SndArgGridCheck_PlayRow_3',
     'PlayRowAudio row 3: ldada 14832'),

    ('LABEL_F1D7C4', 'SndArgGridCheck_PlayRow_4',
     'PlayRowAudio row 4: ldada 14836'),

    ('LABEL_F1D7C8', 'SndArgGridCheck_PlayRow_Send',
     'Send row audio command via Sprintf_Locked'),

    ('LABEL_F1D7D0', 'SndArgGridCheck_PlayRow_Finalize',
     'Finalize row audio: call 0xFA44D0, send PlayAudio event'),

    ('LABEL_F1D7DE', 'SndArgGridCheck_DispatchPlayAudio',
     'Dispatch PlayAudio event to widget'),

    ('LABEL_F1D7E2', 'SndArgGridCheck_ReturnHandled',
     'Return xhl=0 (event handled)'),

    ('LABEL_F1D7E4', 'SndArgGridCheck_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # VwVariBoxProc  (F1C610 - F1C9A7)
    # View variable box procedure: manages display of a variable-value
    # widget with audio preview, match detection, and text rendering.
    # ==================================================================
    ('LABEL_F1C63D', 'VwVariBox_Init',
     'Handle 0x1C00001 Init: allocate memory, forward init, check bounds'),

    ('LABEL_F1C682', 'VwVariBox_Match',
     'Handle 0x1C0001C Match: forward, check key match, update selection'),

    ('LABEL_F1C6CC', 'VwVariBox_Match_ValueMismatch',
     'Match value differs: query variation count, update navigation'),

    ('LABEL_F1C70D', 'VwVariBox_Match_HighIndex',
     'Match index >=10: use alternate variation query (0x1E00056 cp 2)'),

    ('LABEL_F1C741', 'VwVariBox_Match_DispatchConfirm',
     'Dispatch Confirm event to update widget'),

    ('LABEL_F1C745', 'VwVariBox_Match_Repaint',
     'Send Paint event to refresh display'),

    ('LABEL_F1C754', 'VwVariBox_Paint',
     'Handle 0x1C0000D Paint: check selection state, draw or grey out'),

    ('LABEL_F1C77E', 'VwVariBox_Paint_Greyed',
     'Paint greyed-out state: draw with color 0xF5 (dimmed)'),

    ('LABEL_F1C798', 'VwVariBox_Paint_DrawLabel',
     'Paint label text and send Confirm'),

    ('LABEL_F1C7B1', 'VwVariBox_Confirm',
     'Handle 0x1C0000F Confirm: format variable text with GetText'),

    ('LABEL_F1C7E1', 'VwVariBox_Confirm_ClearBuf',
     'Clear buffer loop: zero-fill text area'),

    ('LABEL_F1C82E', 'VwVariBox_Confirm_NoSelection',
     'No selection active: render with 0xFF filler'),

    ('LABEL_F1C83C', 'VwVariBox_Confirm_Render',
     'Call text renderer 0xFAD049 with formatted string'),

    ('LABEL_F1C840', 'VwVariBox_ReturnHandled',
     'Return xhl=0 (event handled)'),

    ('LABEL_F1C845', 'VwVariBox_GetText',
     'Handle 0x1E0003A GetText: lookup and play audio for current value'),

    ('LABEL_F1C85D', 'VwVariBox_GetText_LookupAudio',
     'GetText low index path: lookup from table at 0xE1DFD0'),

    ('LABEL_F1C87D', 'VwVariBox_GetText_HighValues',
     'GetText value 0xD-0x10: map to special audio addresses'),

    ('LABEL_F1C898', 'VwVariBox_GetText_Val0E',
     'GetText value 0xE: audio addr 0x1E8A90'),

    ('LABEL_F1C89F', 'VwVariBox_GetText_Val0F',
     'GetText value 0xF: audio addr 0x1E8A40'),

    ('LABEL_F1C8A6', 'VwVariBox_GetText_Val10',
     'GetText value 0x10: audio addr 0x1E8A50'),

    ('LABEL_F1C8AB', 'VwVariBox_GetText_PlaySample',
     'Play audio sample via 0xFF0D99 with length 0x10'),

    ('LABEL_F1C8BE', 'VwVariBox_OK',
     'Handle 0x1C00007 OK: verify match, release and set new index'),

    ('LABEL_F1C91F', 'VwVariBox_OK_Forward',
     'OK no match: forward to base class'),

    ('LABEL_F1C92D', 'VwVariBox_Release',
     'Handle 0x1C0001B Release: forward, check if selection matches'),

    ('LABEL_F1C969', 'VwVariBox_DispatchAndReturn',
     'Dispatch event via 0xFA9660 then return handled'),

    ('LABEL_F1C970', 'VwVariBox_CanScroll',
     'Handle 0x1E0003C CanScroll: check if variable box supports scrolling'),

    ('LABEL_F1C994', 'VwVariBox_Default',
     'Default: forward unhandled event to base class'),

    ('LABEL_F1C9A0', 'VwVariBox_ForwardToBase',
     'Call base class handler 0xFA4409'),

    ('LABEL_F1C9A4', 'VwVariBox_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # AcCtlMsgGridBoxProc  (F79B24 - F79F87)
    # Control message grid box: manages a grid for MIDI control messages
    # with cycling page index, Show label display, and cell selection.
    # ==================================================================
    ('LABEL_F79B5D', 'AcCtlMsgGrid_Init',
     'Handle 0x1C00001 Init: forward, store page val from 0x024776, set scroll bounds'),

    ('LABEL_F79BD8', 'AcCtlMsgGrid_Show',
     'Handle 0x1C0000B Show: render label from table at 0xE7ECFE via page index'),

    ('LABEL_F79C37', 'AcCtlMsgGrid_OK',
     'Handle 0x1C00007 OK: increment/decrement page index by direction 0x10/0x90'),

    ('LABEL_F79C76', 'AcCtlMsgGrid_OK_Up_Store',
     'OK Up: store new page, refresh Show, send GridScroll'),

    ('LABEL_F79C9C', 'AcCtlMsgGrid_OK_Down',
     'OK direction 0x90: decrement page index with wrap'),

    ('LABEL_F79CB0', 'AcCtlMsgGrid_OK_Down_Store',
     'OK Down: store new page, refresh Show, send GridScroll'),

    ('LABEL_F79CD4', 'AcCtlMsgGrid_OK_DispatchScroll',
     'Dispatch GridScroll event after page change'),

    ('LABEL_F79D32', 'AcCtlMsgGrid_ScrollUp_PageDec',
     'ScrollUp at page boundary: decrement page index'),

    ('LABEL_F79D7F', 'AcCtlMsgGrid_ScrollUp_CellNav',
     'ScrollUp normal: navigate to previous cell'),

    ('LABEL_F79DA5', 'AcCtlMsgGrid_ScrollUp_AutoScroll',
     'ScrollUp CanAutoScroll fallback: forward to parent widget'),

    ('LABEL_F79E5E', 'AcCtlMsgGrid_ScrollDown_PageInc',
     'ScrollDown at page boundary: increment page index'),

    ('LABEL_F79E91', 'AcCtlMsgGrid_ScrollDown_CellNav',
     'ScrollDown normal: navigate to next cell'),

    ('LABEL_F79EB4', 'AcCtlMsgGrid_ScrollRelease',
     'Common scroll release: call 0xF9A5BD'),

    ('LABEL_F79EBB', 'AcCtlMsgGrid_ScrollDown_AutoScroll',
     'ScrollDown CanAutoScroll fallback: forward to parent widget'),

    ('LABEL_F79F0C', 'AcCtlMsgGrid_ScrollCommit',
     'Commit scroll: call 0xF9A53B'),

    ('LABEL_F79F12', 'AcCtlMsgGrid_GetColText',
     'Handle 0x1E0008A GetColText: copy col text from offset 62'),

    ('LABEL_F79F1F', 'AcCtlMsgGrid_GetRowText',
     'Handle 0x1E0008B GetRowText: lookup by page index (0 or 1)'),

    ('LABEL_F79F3A', 'AcCtlMsgGrid_GetRowText_Page1',
     'GetRowText page 1: use table at 0xE8030E'),

    ('LABEL_F79F3F', 'AcCtlMsgGrid_GetRowText_Push',
     'Push row text address and Strcpy'),

    ('LABEL_F79F40', 'AcCtlMsgGrid_GetRowText_Strcpy',
     'Strcpy row text to caller buffer'),

    ('LABEL_F79F5E', 'AcCtlMsgGrid_CellSelect',
     'Handle 0x1E0008D CellSelect: forward to parent via offset 70'),

    ('LABEL_F79F6E', 'AcCtlMsgGrid_ForwardToParent',
     'Call parent handler 0xFA49B7'),

    ('LABEL_F79F72', 'AcCtlMsgGrid_ReturnHandled',
     'Return xhl=0 (event handled)'),

    ('LABEL_F79F76', 'AcCtlMsgGrid_ForwardToBase',
     'Forward unhandled event to AcGridBoxProc base'),

    ('LABEL_F79F83', 'AcCtlMsgGrid_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # AcPmemOutLGridBoxProc  (F7835A - F7867B)
    # Performance memory output L grid box: manages left-side output
    # channel assignment grid (cells 0, 1, 3) with linked widget 0x5B0009.
    # ==================================================================
    ('LABEL_F7838B', 'AcPmemOutL_Init',
     'Handle 0x1C00001 Init: get cell index, branch by cell 0/1/3'),

    ('LABEL_F783AA', 'AcPmemOutL_Init_Cell01',
     'Init cell 0 or 1: compute scroll bounds from cell index + offset 26'),

    ('LABEL_F783E8', 'AcPmemOutL_Init_Cell3',
     'Init cell 3: compute scroll bounds with inc 1 adjustment'),

    ('LABEL_F7842C', 'AcPmemOutL_Init_ScrollCommit',
     'Commit scroll setup: call 0xF9A53B'),

    ('LABEL_F78430', 'AcPmemOutL_Init_ForwardBase',
     'Forward Init to base after scroll setup'),

    ('LABEL_F784CE', 'AcPmemOutL_AutoIncUp_Cell0_FwdParent',
     'AutoIncUp cell=0: forward to parent widget'),

    ('LABEL_F784E1', 'AcPmemOutL_AutoIncUp_Cell2',
     'AutoIncUp cell 2 path: set scroll, check grid boundary'),

    ('LABEL_F78561', 'AcPmemOutL_AutoIncUp_Cell2_FwdParent',
     'AutoIncUp cell=1 boundary: forward to parent widget'),

    ('LABEL_F78574', 'AcPmemOutL_AutoIncDown_Cell3',
     'AutoIncDown cell 3 path: set scroll, check grid boundary'),

    ('LABEL_F785F0', 'AcPmemOutL_DispatchEvent',
     'Dispatch event via 0xFA9660'),

    ('LABEL_F785F6', 'AcPmemOutL_AutoIncDown_Cell3_FwdParent',
     'AutoIncDown cell=3 boundary: forward to parent widget'),

    ('LABEL_F78606', 'AcPmemOutL_ForwardToParent',
     'Call parent handler 0xFA49B7'),

    ('LABEL_F7860A', 'AcPmemOutL_ReloadAndForward',
     'Reload params and forward to base'),

    ('LABEL_F78613', 'AcPmemOutL_CallBase',
     'Call base handler 0xFA4409'),

    ('LABEL_F78619', 'AcPmemOutL_GetColText',
     'Handle 0x1E0008A GetColText: offset 0x3E'),

    ('LABEL_F78623', 'AcPmemOutL_GetRowText',
     'Handle 0x1E0008B GetRowText: offset 0x42'),

    ('LABEL_F7862B', 'AcPmemOutL_CopyText',
     'Common text copy: widget data + offset, Strcpy'),

    ('LABEL_F78652', 'AcPmemOutL_CellSelect',
     'Handle 0x1E0008D CellSelect: forward to parent via offset 70'),

    ('LABEL_F78662', 'AcPmemOutL_CellSelect_Forward',
     'Forward CellSelect to parent 0xFA49B7'),

    ('LABEL_F78666', 'AcPmemOutL_ReturnHandled',
     'Return xhl=0 (event handled)'),

    ('LABEL_F7866A', 'AcPmemOutL_ForwardToBase',
     'Forward unhandled event to base'),

    ('LABEL_F78677', 'AcPmemOutL_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # AcPmemOutRGridBoxProc  (F786A0 - F78987)
    # Performance memory output R grid box: manages right-side output
    # channel assignment grid (cells 5, 6, 7) with linked widget 0x5B0008.
    # ==================================================================
    ('LABEL_F786DE', 'AcPmemOutR_Init',
     'Handle 0x1C00001 Init: get cell index, branch by cell 5/6/7'),

    ('LABEL_F786FC', 'AcPmemOutR_Init_Cell567',
     'Init cells 5/6/7: compute scroll bounds from cell index + offset 26'),

    ('LABEL_F7873C', 'AcPmemOutR_Init_ForwardBase',
     'Forward Init to base after scroll setup'),

    ('LABEL_F787DA', 'AcPmemOutR_AutoIncUp_Cell5_FwdParent',
     'AutoIncUp cell=0 boundary: forward to parent widget'),

    ('LABEL_F787ED', 'AcPmemOutR_AutoIncUp_Cell6',
     'AutoIncUp cell 6 path: set scroll, check grid boundary'),

    ('LABEL_F7886D', 'AcPmemOutR_AutoIncUp_Cell6_FwdParent',
     'AutoIncUp cell=1 boundary: forward to parent widget'),

    ('LABEL_F78880', 'AcPmemOutR_AutoIncDown_Cell7',
     'AutoIncDown cell 7 path: set scroll, check grid boundary'),

    ('LABEL_F788FC', 'AcPmemOutR_DispatchEvent',
     'Dispatch event via 0xFA9660'),

    ('LABEL_F78902', 'AcPmemOutR_AutoIncDown_Cell7_FwdParent',
     'AutoIncDown cell=2 boundary: forward to parent widget'),

    ('LABEL_F78912', 'AcPmemOutR_ForwardToParent',
     'Call parent handler 0xFA49B7'),

    ('LABEL_F78916', 'AcPmemOutR_ReloadAndForward',
     'Reload params and forward to base'),

    ('LABEL_F7891F', 'AcPmemOutR_CallBase',
     'Call base handler 0xFA4409'),

    ('LABEL_F78925', 'AcPmemOutR_GetColText',
     'Handle 0x1E0008A GetColText: offset 0x3E'),

    ('LABEL_F7892F', 'AcPmemOutR_GetRowText',
     'Handle 0x1E0008B GetRowText: offset 0x42'),

    ('LABEL_F78937', 'AcPmemOutR_CopyText',
     'Common text copy: widget data + offset, Strcpy'),

    ('LABEL_F7895E', 'AcPmemOutR_CellSelect',
     'Handle 0x1E0008D CellSelect: forward to parent via offset 70'),

    ('LABEL_F7896E', 'AcPmemOutR_CellSelect_Forward',
     'Forward CellSelect to parent 0xFA49B7'),

    ('LABEL_F78972', 'AcPmemOutR_ReturnHandled',
     'Return xhl=0 (event handled)'),

    ('LABEL_F78976', 'AcPmemOutR_ForwardToBase',
     'Forward unhandled event to base'),

    ('LABEL_F78983', 'AcPmemOutR_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # IvSdpartProc  (F7B770 - F7BB6E)
    # Sound part (Sdpart) procedure: manages sound part switching with
    # 8-part page tabs, part selection, and refresh with audio lookup.
    # Uses tables at 0xE953AA (part descriptors) and 0xE953CE (part IDs).
    # ==================================================================
    ('LABEL_F7B7AE', 'IvSdpart_Init',
     'Handle 0x1C00001 Init: forward, check part=5/0, reset to part 8 tab'),

    ('LABEL_F7B7C9', 'IvSdpart_Init_ResetPart',
     'Init reset: set current part to 8, release old, lookup descriptor'),

    ('LABEL_F7B7EA', 'IvSdpart_Init_LoadDescriptor',
     'Load part descriptor from table, send Init event'),

    ('LABEL_F7B806', 'IvSdpart_Close',
     'Handle 0x1C00002 Close: forward, send SetUndo if part=5/0'),

    ('LABEL_F7B822', 'IvSdpart_Close_SetUndo',
     'Send SetUndo event 0x1E000A0 with undo flag=0x3F'),

    ('LABEL_F7B838', 'IvSdpart_ShowHide',
     'Handle 0x1C0000B Show / 0x1C0000C Hide: update part ID table lookup'),

    ('LABEL_F7B868', 'IvSdpart_ShowHide_UpdateUI',
     'Update UI: call CB64 helper, send Confirm event to part widget'),

    ('LABEL_F7B88A', 'IvSdpart_OK',
     'Handle 0x1C00007 OK: check if OK=0xF, verify sound lock'),

    ('LABEL_F7B8F6', 'IvSdpart_OK_ExitToMenu',
     'OK with part=8: send Exit event to main menu'),

    ('LABEL_F7B908', 'IvSdpart_OK_Forward',
     'OK not handled: forward to base'),

    ('LABEL_F7B913', 'IvSdpart_PageSelect',
     'Handle 0x1C00029 PageSelect: switch to new part tab'),

    ('LABEL_F7BA34', 'IvSdpart_Refresh',
     'Handle 0x1C0002F Refresh: re-lookup part, update UI'),

    ('LABEL_F7BAEB', 'IvSdpart_Match_HitTest',
     'Match hit test: compare encoded part ID, open editor if match'),

    ('LABEL_F7BB2F', 'IvSdpart_Paint',
     'Handle 0x1C0000D Paint: forward, send Confirm'),

    ('LABEL_F7BB45', 'IvSdpart_DispatchEvent',
     'Dispatch event via 0xFA9660'),

    ('LABEL_F7BB4B', 'IvSdpart_GetText',
     'Handle 0x1E0003A GetText: copy "Sound Part" string'),

    ('LABEL_F7BB5B', 'IvSdpart_ReturnHandled',
     'Return xhl=0 (event handled)'),

    ('LABEL_F7BB5F', 'IvSdpart_ForwardToBase',
     'Forward unhandled event to base'),

    ('LABEL_F7BB67', 'IvSdpart_CallBase',
     'Call base handler 0xFA4409'),

    ('LABEL_F7BB6B', 'IvSdpart_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # AcLswPartEditBoxProc  (F7BB75 - F7C09C)
    # LSW part edit box: manages part parameter editing with bidirectional
    # scrolling, value get/set, delta accumulation, and snap reset.
    # Uses sound part index from 0x03E99E and part descriptors via offset 50/54.
    # ==================================================================
    ('LABEL_F7BC4E', 'AcLswPartEdit_SetValue',
     'Handle 0x1E0003B SetValue: check bounds, store value by range type'),

    ('LABEL_F7BCD5', 'AcLswPartEdit_SetValue_Unbounded',
     'SetValue with unbounded range: store directly via 0xF9F88A'),

    ('LABEL_F7BCF6', 'AcLswPartEdit_AddDelta',
     'Handle 0x1E0003D AddDelta: accumulate delta to current value'),

    ('LABEL_F7BD7D', 'AcLswPartEdit_AddDelta_Unbounded',
     'AddDelta with unbounded range: store directly via 0xF9F942'),

    ('LABEL_F7BD97', 'AcLswPartEdit_ShowHide',
     'Handle 0x1C0000B Show / 0x1C0000C Hide: compute display value'),

    ('LABEL_F7BDEA', 'AcLswPartEdit_ShowHide_Unbounded',
     'ShowHide with unbounded range: compute via LABEL_FCD437'),

    ('LABEL_F7BDFB', 'AcLswPartEdit_ShowHide_StoreAndForward',
     'Store computed display value, forward to base'),

    ('LABEL_F7BE12', 'AcLswPartEdit_Paint',
     'Handle 0x1C0000D Paint: forward, then send Confirm'),

    ('LABEL_F7BE2B', 'AcLswPartEdit_Match',
     'Handle 0x1C0001C Match: decode match data, verify part/param match'),

    ('LABEL_F7BEBC', 'AcLswPartEdit_Match_Unbounded',
     'Match with unbounded range: verify by column only'),

    ('LABEL_F7BF00', 'AcLswPartEdit_AutoIncUp',
     'Handle 0x1C00019 AutoIncUp: check CanScroll, get up step'),

    ('LABEL_F7BF47', 'AcLswPartEdit_ScrollUp',
     'Handle 0x1C00017 ScrollUp: check CanScroll, get down step'),

    ('LABEL_F7BF8E', 'AcLswPartEdit_AutoIncDown',
     'Handle 0x1C0001A AutoIncDown: check CanScroll, negate up step'),

    ('LABEL_F7BFDC', 'AcLswPartEdit_ScrollDown',
     'Handle 0x1C00018 ScrollDown: check CanScroll, negate down step'),

    ('LABEL_F7C029', 'AcLswPartEdit_Snap',
     'Handle 0x1C00031 Snap: check CanScroll, query snap bounds, set value'),

    ('LABEL_F7C085', 'AcLswPartEdit_DispatchEvent',
     'Dispatch event via 0xFA9660'),

    ('LABEL_F7C089', 'AcLswPartEdit_ReturnHandled',
     'Return xhl=0 (event handled)'),

    ('LABEL_F7C08D', 'AcLswPartEdit_ForwardToBase',
     'Forward unhandled event to base'),

    ('LABEL_F7C099', 'AcLswPartEdit_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # AcLswPartPanProc  (F7C7E4 - F7CB10)
    # LSW part pan procedure: manages pan knob with geometric layout
    # (dial positions computed from center/quarter/three-quarter points),
    # Match handling, and hardware parameter feedback via multiply-accumulate.
    # Also contains 3 small helper functions used by Sdpart and related procs.
    # ==================================================================
    ('LABEL_F7C854', 'AcLswPartPan_ShowHide',
     'Handle 0x1C0000B Show / 0x1C0000C Hide: compute range bounds'),

    ('LABEL_F7C8A7', 'AcLswPartPan_ShowHide_Unbounded',
     'ShowHide unbounded: compute via LABEL_FCD437'),

    ('LABEL_F7C8B8', 'AcLswPartPan_ShowHide_StoreAndForward',
     'Store display value, forward to base'),

    ('LABEL_F7C8CF', 'AcLswPartPan_Paint',
     'Handle 0x1C0000D Paint: forward, then send Confirm'),

    ('LABEL_F7C8E8', 'AcLswPartPan_Confirm',
     'Handle 0x1C0000F Confirm: compute dial layout with geometric positions'),

    ('LABEL_F7CA65', 'AcLswPartPan_Match',
     'Handle 0x1C0001C Match: decode match data, verify part/param, store value'),

    ('LABEL_F7CAE2', 'AcLswPartPan_Match_Unbounded',
     'Match unbounded: verify column only, store value'),

    ('LABEL_F7CB07', 'AcLswPartPan_DispatchEvent',
     'Dispatch event via 0xFA9660'),

    ('LABEL_F7CB0B', 'AcLswPartPan_ReturnHandled',
     'Return xhl=0 (event handled)'),

    ('LABEL_F7CB0D', 'AcLswPartPan_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # -- Helper: SdpartLookupPartId (F7CB12 - F7CB31)
    # Searches a word table for a matching part ID.
    ('LABEL_F7CB12', 'SdpartLookupPartId',
     'Search word table (xwa) for value (bc), return index in hl or 0xFFFF'),

    ('LABEL_F7CB1A', 'SdpartLookupPartId_Loop',
     'Scan loop: compare current entry, advance'),

    ('LABEL_F7CB28', 'SdpartLookupPartId_CheckEnd',
     'Check for 0xFFFF sentinel (not found)'),

    # -- Helper: SdpartScrollDelta (F7CB32 - F7CB63)
    # Computes scroll delta from event code.
    ('LABEL_F7CB32', 'SdpartScrollDelta',
     'Compute scroll delta: map event code to +1/-1 step'),

    ('LABEL_F7CB55', 'SdpartScrollDelta_Up',
     'ScrollUp: return +de'),

    ('LABEL_F7CB58', 'SdpartScrollDelta_Down',
     'AutoIncDown: negate hl (= -bc)'),

    ('LABEL_F7CB5A', 'SdpartScrollDelta_Negate',
     'Negate delta: mul by 0xFFFF'),

    ('LABEL_F7CB61', 'SdpartScrollDelta_Zero',
     'Unrecognized event: return 0'),

    # -- Helper: SdpartUpdatePartUI (F7CB64 - F7CB9E)
    # Updates part UI: looks up part descriptor, sends confirm/open editor.
    ('LABEL_F7CB64', 'SdpartUpdatePartUI',
     'Update part UI: lookup descriptor, check flag, send open-editor or confirm'),

    ('LABEL_F7CB9A', 'SdpartUpdatePartUI_Confirm',
     'Part has no editor flag: send Confirm to part widget'),

    # ==================================================================
    # IvAccordionProc  (F7E27C - F7E654)
    # Accordion procedure: manages accordion mode switching (bellows on/off),
    # part selection, and parameter updates. Controls widgets 0xEB0009
    # (bellows off) and 0xEB0017 (bellows on) based on accordion state.
    # State stored at 0x02477C-0x024782.
    # ==================================================================
    ('LABEL_F7E2EF', 'IvAccordion_Close',
     'Handle 0x1C00002 Close: forward to base'),

    ('LABEL_F7E2FB', 'IvAccordion_ShowHide',
     'Handle 0x1C0000B Show / 0x1C0000C Hide: init state, lookup part, update'),

    ('LABEL_F7E36F', 'IvAccordion_ShowHide_NoBellows',
     'ShowHide no bellows: close bellows-on widget, open bellows-off'),

    ('LABEL_F7E399', 'IvAccordion_ShowHide_Toggle',
     'Toggle bellows state and send Init to active widget'),

    ('LABEL_F7E3A9', 'IvAccordion_ShowHide_UpdatePart',
     'Update part display: lookup descriptor, send Confirm'),

    ('LABEL_F7E3C8', 'IvAccordion_Paint',
     'Handle 0x1C0000D Paint: forward, then send Confirm'),

    ('LABEL_F7E3DE', 'IvAccordion_Scroll',
     'Handle 0x1C00017/0x1C00018 Scroll: toggle bellows mode'),

    ('LABEL_F7E454', 'IvAccordion_Scroll_SetOff',
     'Scroll sets bellows off: close bellows-on, open bellows-off'),

    ('LABEL_F7E4AA', 'IvAccordion_PageSelect',
     'Handle 0x1C00029 PageSelect / 0x1C10000 PartSelect: send part update'),

    ('LABEL_F7E4E9', 'IvAccordion_Update',
     'Handle 0x1C00023 Update: match current part, toggle bellows if needed'),

    ('LABEL_F7E54D', 'IvAccordion_Update_BellowsOn',
     'Update bellows on: close off-widget, open on-widget'),

    ('LABEL_F7E580', 'IvAccordion_Update_CommitToggle',
     'Commit bellows toggle: dispatch Init event'),

    ('LABEL_F7E584', 'IvAccordion_Update_SendPartParam',
     'Send part parameter update with encoded note/channel'),

    ('LABEL_F7E5A4', 'IvAccordion_Update_NonNote',
     'Update non-note event: forward as generic param 0x1E00079'),

    ('LABEL_F7E5B0', 'IvAccordion_Update_Dispatch',
     'Dispatch update via LABEL_FA9752'),

    ('LABEL_F7E5B7', 'IvAccordion_Match',
     'Handle 0x1C0001C Match: check encoded part ID, update display'),

    ('LABEL_F7E5E2', 'IvAccordion_Match_Found',
     'Match found: lookup part name, send Update event'),

    ('LABEL_F7E5F1', 'IvAccordion_Refresh',
     'Handle 0x1C0002F Refresh: re-lookup part, send Confirm and Update'),

    ('LABEL_F7E630', 'IvAccordion_DispatchEvent',
     'Dispatch event via 0xFA9660'),

    ('LABEL_F7E636', 'IvAccordion_GetText',
     'Handle 0x1E0003A GetText: copy "Accordion" string at 0xE9D9BA'),

    ('LABEL_F7E643', 'IvAccordion_ReturnHandled',
     'Return xhl=0 (event handled)'),

    ('LABEL_F7E647', 'IvAccordion_ForwardToBase',
     'Forward unhandled event to base'),

    ('LABEL_F7E650', 'IvAccordion_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # AcWelcomScreenProc  (F7F4F2 - F7FA59)
    # Welcome screen procedure: manages the boot welcome screen with
    # animated display, subcpu error/loaded detection, wallpaper rendering.
    # Contains inline .byte rendering bytecode at LABEL_F7F649.
    # ==================================================================
    ('LABEL_F7F51A', 'AcWelcomScreen_Init_StoreData',
     'Store wallpaper data pointer, forward Init to base'),

    ('LABEL_F7F541', 'AcWelcomScreen_Init_CheckSubCpu',
     'Check SubCPU payload error: if error, trigger SubCpuError event'),

    ('LABEL_F7F555', 'AcWelcomScreen_Init_DispatchTimer',
     'Dispatch timed event via LABEL_FA9752'),

    ('LABEL_F7F55C', 'AcWelcomScreen_Init_SwitchMode',
     'SubCPU OK: send SwitchMode event 0x1E000B3'),

    ('LABEL_F7F56B', 'AcWelcomScreen_Close',
     'Handle 0x1C00002 Close: unregister timer, forward Close'),

    ('LABEL_F7F595', 'AcWelcomScreen_Activate',
     'Handle 0x1C0000A Activate: check first-run, show LCD, render wallpaper'),

    ('LABEL_F7F5C0', 'AcWelcomScreen_Activate_Setup',
     'Post-activate: register animation timer, set step counter'),

    ('LABEL_F7F5FA', 'AcWelcomScreen_ShowHide',
     'Handle 0x1C0000B Show / 0x1C0000C Hide: forward to base'),

    ('LABEL_F7F605', 'AcWelcomScreen_Select',
     'Handle 0x1C0000E Select: execute render step from bytecode table'),

    ('LABEL_F7F649', 'AcWelcomScreen_RenderBytecode',
     'Inline rendering bytecode for welcome screen animation frames'),

    ('LABEL_F7F9C9', 'AcWelcomScreen_Select_NextStep',
     'Advance to next animation step, loop or trigger timer'),

    ('LABEL_F7F9FB', 'AcWelcomScreen_Select_StartTimer',
     'Start animation timer via 0xFAA135'),

    ('LABEL_F7FA01', 'AcWelcomScreen_SubCpuError',
     'Handle 0x1C10004 SubCpuError: show error firmware screen'),

    ('LABEL_F7FA1B', 'AcWelcomScreen_SubCpuLoaded',
     'Handle 0x1C10009 SubCpuLoaded: show normal startup screen'),

    ('LABEL_F7FA33', 'AcWelcomScreen_DispatchEvent',
     'Dispatch event via 0xFA9660'),

    ('LABEL_F7FA39', 'AcWelcomScreen_Paint',
     'Handle 0x1C0000D Paint: forward to base'),

    ('LABEL_F7FA41', 'AcWelcomScreen_CallBase',
     'Call base handler 0xFA4409'),

    ('LABEL_F7FA45', 'AcWelcomScreen_ReturnHandled',
     'Return xhl=0 (event handled)'),

    ('LABEL_F7FA49', 'AcWelcomScreen_ForwardToBase',
     'Forward unhandled event to base'),

    ('LABEL_F7FA55', 'AcWelcomScreen_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # IvDrawbarProc  (F82528 - F82A5E)
    # Drawbar procedure: manages organ drawbar display with dual-mode
    # switching (classic/modern), 3-tab layout (drawbar/upper/lower),
    # value persistence at 0x024798-0x0247C4, and part name lookup.
    # ==================================================================
    ('LABEL_F82553', 'IvDrawbar_Init_Part03',
     'Init for part 0 or 3: reset drawbar tab, get instrument, check mode'),

    ('LABEL_F82582', 'IvDrawbar_Init_CheckDualMode',
     'Check dual-drawbar mode bit at 0x0205F2'),

    ('LABEL_F8259E', 'IvDrawbar_Init_DispatchLoadVals',
     'Dispatch DrawbarLoadVals event'),

    ('LABEL_F825A2', 'IvDrawbar_Init_SetupMode',
     'Check mode: classic vs modern drawbar setup'),

    ('LABEL_F8262E', 'IvDrawbar_Init_ModernMode',
     'Modern mode: enable modern UI, close classic, open modern widget'),

    ('LABEL_F82690', 'IvDrawbar_Close',
     'Handle 0x1C00002 Close: forward to base'),

    ('LABEL_F8269B', 'IvDrawbar_ShowHide',
     'Handle 0x1C0000B Show / 0x1C0000C Hide: update instrument, refresh tabs'),

    ('LABEL_F826EC', 'IvDrawbar_Paint',
     'Handle 0x1C0000D Paint: forward, then send Confirm'),

    ('LABEL_F82705', 'IvDrawbar_LoadVals',
     'Handle 0x1E10008 DrawbarLoadVals: read upper/lower channel values'),

    ('LABEL_F82736', 'IvDrawbar_LoadVals_DualMode',
     'LoadVals dual mode: send DrawbarInit to linked widget'),

    ('LABEL_F82745', 'IvDrawbar_DrawbarUpdate',
     'Handle 0x1E000A7 DrawbarUpdate: apply update to upper/lower drawbar'),

    ('LABEL_F82781', 'IvDrawbar_DrawbarUpdate_UpperOff',
     'DrawbarUpdate upper channel off: set value 0, repaint'),

    ('LABEL_F827A0', 'IvDrawbar_DrawbarUpdate_Lower',
     'DrawbarUpdate lower channel: set value from stored 0x0247C4'),

    ('LABEL_F827B4', 'IvDrawbar_OK',
     'Handle 0x1C00007 OK: check direction, handle page change or sound lock'),

    ('LABEL_F827EE', 'IvDrawbar_OK_Locked',
     'OK sound locked: send generic param 0x1E00079'),

    ('LABEL_F827FA', 'IvDrawbar_OK_Dispatch',
     'Dispatch OK action event'),

    ('LABEL_F82801', 'IvDrawbar_OK_PageChange',
     'OK triggers page change: reset tab, send PageChange event'),

    ('LABEL_F82825', 'IvDrawbar_OK_Forward',
     'OK not handled: forward to base'),

    ('LABEL_F82830', 'IvDrawbar_Release',
     'Handle 0x1C0001B Release: switch by sub-index (1/2/3)'),

    ('LABEL_F8288B', 'IvDrawbar_Release_Upper',
     'Release upper channel: write value to part or send DrawbarSetParam'),

    ('LABEL_F828A6', 'IvDrawbar_Release_Upper_DualMode',
     'Release upper dual mode: encode on/off, send DrawbarSetParam'),

    ('LABEL_F828C3', 'IvDrawbar_Release_Lower',
     'Release lower channel: write value or send DrawbarSetParam'),

    ('LABEL_F828DC', 'IvDrawbar_Release_WriteValue',
     'Write release value via 0xF9F8DD'),

    ('LABEL_F828E3', 'IvDrawbar_Release_Lower_DualMode',
     'Release lower dual mode: encode on/off, send DrawbarSetParam'),

    ('LABEL_F828FE', 'IvDrawbar_Release_SendParam',
     'Send DrawbarSetParam via 0xFA4A63'),

    ('LABEL_F82905', 'IvDrawbar_Update',
     'Handle 0x1C00023 Update: check mode, process part note event'),

    ('LABEL_F8294A', 'IvDrawbar_Update_GenericParam',
     'Update generic param: send 0x1E00079'),

    ('LABEL_F82956', 'IvDrawbar_Update_Dispatch',
     'Dispatch update via LABEL_FA9752'),

    ('LABEL_F8295D', 'IvDrawbar_Match',
     'Handle 0x1C0001C Match: check encoded drawbar/upper/lower IDs'),

    ('LABEL_F82987', 'IvDrawbar_Match_Drawbar',
     'Match drawbar: lookup name, send Update event'),

    ('LABEL_F82998', 'IvDrawbar_Match_CheckUpper',
     'Match check upper channel ID 0x82C1'),

    ('LABEL_F829BB', 'IvDrawbar_Match_CheckLower',
     'Match check lower channel ID 0x82C0'),

    ('LABEL_F829D4', 'IvDrawbar_Match_DispatchEvent',
     'Dispatch match event via 0xFA9660'),

    ('LABEL_F829D8', 'IvDrawbar_Match_Forward',
     'Forward Match to base'),

    ('LABEL_F829E0', 'IvDrawbar_CallBase',
     'Call base handler 0xFA4409'),

    ('LABEL_F829E6', 'IvDrawbar_Refresh',
     'Handle 0x1C0002F Refresh: re-lookup instrument, refresh all tabs'),

    ('LABEL_F82A34', 'IvDrawbar_DispatchEvent',
     'Dispatch event via 0xFA9660'),

    ('LABEL_F82A3A', 'IvDrawbar_GetText',
     'Handle 0x1E0003A GetText: copy "Drawbar" string at 0xE9F92A'),

    ('LABEL_F82A4A', 'IvDrawbar_ReturnHandled',
     'Return xhl=0 (event handled)'),

    ('LABEL_F82A4E', 'IvDrawbar_ForwardToBase',
     'Forward unhandled event to base'),

    ('LABEL_F82A56', 'IvDrawbar_ForwardCallBase',
     'Call base handler 0xFA4409 (alternate entry)'),

    ('LABEL_F82A5A', 'IvDrawbar_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # AcDrawbarNameProc  (F82AA5 - F82DDD)
    # Drawbar name procedure: manages drawbar/organ stop name display,
    # handles initialization, Show/Hide, Paint, OK, Match, Refresh,
    # Notify, and DrawbarInit events. Resolves names by instrument index.
    # ==================================================================
    ('LABEL_F82B72', 'AcDrawbarName_Close',
     'Handle 0x1C00002 Close: forward to base'),

    ('LABEL_F82B7A', 'AcDrawbarName_Init_Forward',
     'Forward Init/Close to base handler 0xFA4409'),

    ('LABEL_F82B81', 'AcDrawbarName_ShowHide',
     'Handle 0x1C0000B Show / 0x1C0000C Hide: resolve name by instrument index'),

    ('LABEL_F82BAE', 'AcDrawbarName_ShowHide_NoInstr',
     'ShowHide no instrument: lookup current part, send DrawbarNameSet'),

    ('LABEL_F82BC3', 'AcDrawbarName_Paint',
     'Handle 0x1C0000D Paint: forward, check mode, resolve and draw name'),

    ('LABEL_F82C01', 'AcDrawbarName_OK',
     'Handle 0x1C00007 OK: check if value matches, send scroll event'),

    ('LABEL_F82C33', 'AcDrawbarName_OK_ScrollUp',
     'OK value match: send ScrollUp event'),

    ('LABEL_F82C40', 'AcDrawbarName_OK_Forward',
     'OK value mismatch: forward to base'),

    ('LABEL_F82C4B', 'AcDrawbarName_Match',
     'Handle 0x1C0001C Match: check encoded drawbar ID, send DrawbarNameSet'),

    ('LABEL_F82C8A', 'AcDrawbarName_Match_SendName',
     'Match found: send DrawbarNameSet to linked widget'),

    ('LABEL_F82C96', 'AcDrawbarName_Match_NoInstr',
     'Match no instrument: lookup part, check encoded IDs'),

    ('LABEL_F82CC3', 'AcDrawbarName_Match_NoInstr_Send',
     'Match no instrument found: send DrawbarNameSet'),

    ('LABEL_F82CD7', 'AcDrawbarName_Refresh',
     'Handle 0x1C0002F Refresh: check instrument, send DrawbarNameSet'),

    ('LABEL_F82D04', 'AcDrawbarName_SendDrawbarNameSet',
     'Send DrawbarNameSet event via 0xFA4A63'),

    ('LABEL_F82D0B', 'AcDrawbarName_DrawbarInit',
     'Handle 0x1C10008 DrawbarInit: resolve instrument, open editor'),

    ('LABEL_F82D4D', 'AcDrawbarName_DrawbarInit_NoInstr',
     'DrawbarInit no instrument: lookup part, verify, open editor'),

    ('LABEL_F82D77', 'AcDrawbarName_DrawbarInit_OpenEditor',
     'Open drawbar editor via 0xFA4932'),

    ('LABEL_F82D7D', 'AcDrawbarName_Notify',
     'Handle 0x1C00020 Notify: verify instrument match, send Confirm'),

    ('LABEL_F82DAF', 'AcDrawbarName_Notify_NoInstr',
     'Notify no instrument: lookup part, verify match, send Confirm'),

    ('LABEL_F82DC5', 'AcDrawbarName_DispatchEvent',
     'Dispatch event via 0xFA9660'),

    ('LABEL_F82DC9', 'AcDrawbarName_ReturnHandled',
     'Return xhl=0 (event handled)'),

    ('LABEL_F82DCD', 'AcDrawbarName_ForwardToBase',
     'Forward unhandled event to base'),

    ('LABEL_F82DD5', 'AcDrawbarName_CallBase',
     'Call base handler 0xFA4409'),

    ('LABEL_F82DD9', 'AcDrawbarName_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # IvDrawbar1Proc  (F8339C - F837E7)
    # Drawbar 1 (individual drawbar slider) procedure: manages a single
    # drawbar slider with 9 channels (0-8), value animation, Match for
    # 9 parameter addresses (0x8280-0x8288), and slider rendering.
    # ==================================================================
    ('LABEL_F833CB', 'IvDrawbar1_Close',
     'Handle 0x1C00002 Close: forward to base'),

    ('LABEL_F833D7', 'IvDrawbar1_ShowHide',
     'Handle 0x1C0000B Show / 0x1C0000C Hide: init instrument, load drawbar value'),

    ('LABEL_F83420', 'IvDrawbar1_Paint',
     'Handle 0x1C0000D Paint: forward, then send Confirm'),

    ('LABEL_F8343A', 'IvDrawbar1_LoadVals',
     'Handle 0x1E10008 DrawbarLoadVals: load all 9 channel target values'),

    ('LABEL_F83448', 'IvDrawbar1_LoadVals_Loop',
     'Loop: read channel values from instrument, store to 0x247B0 array'),

    ('LABEL_F8347A', 'IvDrawbar1_LoadVals_DualMode',
     'LoadVals dual mode: send DrawbarInit to linked widget'),

    ('LABEL_F8348D', 'IvDrawbar1_DrawbarUpdate',
     'Handle 0x1E000A7 DrawbarUpdate: animate slider(s) toward target'),

    ('LABEL_F8349A', 'IvDrawbar1_DrawbarUpdate_AllSliders',
     'Update all 9 sliders: dispatch DrawbarUpdate to each'),

    ('LABEL_F834B5', 'IvDrawbar1_DrawbarUpdate_OneSlider',
     'Update one slider: animate current value toward target'),

    ('LABEL_F834D8', 'IvDrawbar1_DrawbarUpdate_Inc',
     'Slider value < target: increment'),

    ('LABEL_F834DA', 'IvDrawbar1_DrawbarUpdate_Store',
     'Store updated slider value'),

    ('LABEL_F834DC', 'IvDrawbar1_DrawbarUpdate_Render',
     'Render slider, flip LCD buffers, check if done'),

    ('LABEL_F8351E', 'IvDrawbar1_OK',
     'Handle 0x1C00007 OK: get bounds, validate range, apply scroll'),

    ('LABEL_F8353F', 'IvDrawbar1_OK_CheckSixteen',
     'OK bounds check: treat 16 as 8'),

    ('LABEL_F8354B', 'IvDrawbar1_OK_ComputeNewValue',
     'Compute new slider value from target array'),

    ('LABEL_F83596', 'IvDrawbar1_OK_ScrollUp_DualMode',
     'ScrollUp dual mode: clamp value, send DrawbarSetParam'),

    ('LABEL_F835CB', 'IvDrawbar1_OK_ScrollRelease',
     'Release scroll after OK'),

    ('LABEL_F835D6', 'IvDrawbar1_OK_ScrollDown',
     'OK scroll down path: decrement slider'),

    ('LABEL_F83608', 'IvDrawbar1_OK_ScrollDown_DualMode',
     'ScrollDown dual mode: clamp value, send DrawbarSetParam'),

    ('LABEL_F83636', 'IvDrawbar1_OK_ScrollDown_Release',
     'Release scroll after down'),

    ('LABEL_F8363F', 'IvDrawbar1_OK_ScrollCommit',
     'Commit scroll via 0xF9A5BD'),

    ('LABEL_F83646', 'IvDrawbar1_OK_Forward',
     'OK out of range: forward to base'),

    ('LABEL_F83652', 'IvDrawbar1_Match',
     'Handle 0x1C0001C Match: decode 9 parameter addresses'),

    ('LABEL_F83685', 'IvDrawbar1_Match_Ch1',
     'Match channel 1 (0x8282): store to 0x0247B2'),

    ('LABEL_F836A5', 'IvDrawbar1_Match_Ch2',
     'Match channel 2 (0x8281): store to 0x0247B4'),

    ('LABEL_F836C5', 'IvDrawbar1_Match_Ch3',
     'Match channel 3 (0x8283): store to 0x0247B6'),

    ('LABEL_F836E5', 'IvDrawbar1_Match_Ch4',
     'Match channel 4 (0x8284): store to 0x0247B0+8'),

    ('LABEL_F83707', 'IvDrawbar1_Match_Ch5',
     'Match channel 5 (0x8285): store to 0x0247B0+10'),

    ('LABEL_F83724', 'IvDrawbar1_Match_Ch6',
     'Match channel 6 (0x8286): store to 0x0247B0+12'),

    ('LABEL_F83741', 'IvDrawbar1_Match_Ch7',
     'Match channel 7 (0x8287): store to 0x0247B0+14'),

    ('LABEL_F8375E', 'IvDrawbar1_Match_Ch8',
     'Match channel 8 (0x8288): store to 0x0247B0+16'),

    ('LABEL_F83778', 'IvDrawbar1_Match_DispatchUpdate',
     'Dispatch DrawbarUpdate event for matched channel'),

    ('LABEL_F8377C', 'IvDrawbar1_Match_Forward',
     'Forward Match to base'),

    ('LABEL_F83785', 'IvDrawbar1_CallBase',
     'Call base handler 0xFA4409'),

    ('LABEL_F8378B', 'IvDrawbar1_Refresh',
     'Handle 0x1C0002F Refresh: reload instrument, load vals, update all'),

    ('LABEL_F837BC', 'IvDrawbar1_DispatchEvent',
     'Dispatch event via 0xFA9660'),

    ('LABEL_F837C2', 'IvDrawbar1_GetText',
     'Handle 0x1E0003A GetText: copy "Drawbar" string at 0xE9F936'),

    ('LABEL_F837D2', 'IvDrawbar1_ReturnHandled',
     'Return xhl=0 (event handled)'),

    ('LABEL_F837D6', 'IvDrawbar1_ForwardToBase',
     'Forward unhandled event to base'),

    ('LABEL_F837DF', 'IvDrawbar1_ForwardCallBase',
     'Call base handler 0xFA4409 (alternate entry)'),

    ('LABEL_F837E3', 'IvDrawbar1_Return',
     'Epilogue: pop xiz, restore frame, return'),

    # ==================================================================
    # SwbtWr  (FDB253 - FDB434)
    # Switch-button writer: queues switch-button events into a buffer,
    # then processes them via callback tables. Contains initialization
    # routines for 3 sound bank sets and a dispatcher loop.
    # ==================================================================
    ('LABEL_FDB263', 'SwbtWr_ScanEnd',
     'Scan loop: advance xiy to find 0xFF sentinel in buffer'),

    ('LABEL_FDB26A', 'SwbtWr_CheckSpace',
     'Check if buffer has space (xiy < limit at xix+60)'),

    ('LABEL_FDB280', 'SwbtWr_Done',
     'Buffer full or entry written: return (retd 2)'),

    ('LABEL_FDB283', 'SwbtWr_CallProcessAll',
     'Wrapper: push xiz, call ProcessAll, pop xiz, return'),

    ('LABEL_FDB289', 'SwbtWr_SoundBankParamTable',
     'Inline parameter table for sound bank configuration (18 bytes)'),

    ('LABEL_FDB29B', 'SwbtWr_ProcessAll',
     'Process all switch-button events: compact buffer, dispatch callbacks'),

    ('LABEL_FDB2B2', 'SwbtWr_ProcessAll_CompactDone',
     'Buffer compacted: write sentinel, reset counters'),

    ('LABEL_FDB2CB', 'SwbtWr_InitBank1',
     'Init bank 1: set callback tables from 0xEE7786-0xEE7CA3'),

    ('LABEL_FDB2EA', 'SwbtWr_InitBank2',
     'Init bank 2: set callback tables from 0xEE7CA7-0xEE86B4'),

    ('LABEL_FDB309', 'SwbtWr_InitBank3',
     'Init bank 3: set callback tables from 0xEE86D0-0xEE8C79'),

    ('LABEL_FDB328', 'SwbtWr_DispatchLoop_Init',
     'Initialize dispatch loop: reset offset counter'),

    ('LABEL_FDB32E', 'SwbtWr_DispatchLoop',
     'Main dispatch loop: read event, lookup callback table, execute'),

    ('LABEL_FDB35A', 'SwbtWr_DispatchLoop_ScanCallbacks',
     'Scan callback table entries for matching handler'),

    ('LABEL_FDB367', 'SwbtWr_DispatchLoop_ExecuteCallback',
     'Found matching callback: save context, call handler, restore'),

    ('LABEL_FDB3AF', 'SwbtWr_DispatchLoop_NextEvent',
     'Advance to next event in buffer'),

    ('LABEL_FDB3B8', 'SwbtWr_DispatchLoop_PostCallbacks',
     'Run post-dispatch callback list'),

    ('LABEL_FDB3BC', 'SwbtWr_PostCallback_Loop',
     'Post-callback loop: iterate and call each post-handler'),

    ('LABEL_FDB3D0', 'SwbtWr_PostCallback_Done',
     'All post-callbacks executed: return'),

    ('LABEL_FDB3D1', 'SwbtWr_QueueMainEvent',
     'Queue event to main buffer (0xBD3C): check space, write 4 bytes'),

    ('LABEL_FDB3F0', 'SwbtWr_QueueMainEvent_Done',
     'Main buffer queue done'),

    ('LABEL_FDB3F1', 'SwbtWr_QueuePostEvent',
     'Queue event to post buffer (0xBF39): check space, write 4 bytes'),

    ('LABEL_FDB411', 'SwbtWr_QueuePostEvent_Done',
     'Post buffer queue done'),

    ('LABEL_FDB412', 'SwbtWr_TrailingBytecode',
     'Trailing bytecode/data after SwbtWr (34 bytes)'),

    # ==================================================================
    # RhythmMidi_HandleCC  (FE0BA2 - FE0E7F)
    # Rhythm MIDI CC handler: processes MIDI control change messages
    # for rhythm parts. Handles all-notes-off (0x7F), local control (0x7E),
    # all-sound-off (0x7D), and per-part CC routing with note-to-part
    # mapping table at 0xEE8EF0. Also processes sequencer events.
    # ==================================================================
    ('LABEL_FE0BD3', 'RhythmMidi_CC7F_PartLoop',
     'All-Notes-Off loop: iterate 5 rhythm parts, send note-off'),

    ('LABEL_FE0C0B', 'RhythmMidi_CC7E',
     'Handle CC 0x7E Local Control: set all 5 part mute flags'),

    ('LABEL_FE0C22', 'RhythmMidi_CC7D',
     'Handle CC 0x7D All-Sound-Off: iterate parts, stop active sounds'),

    ('LABEL_FE0C2B', 'RhythmMidi_CC7D_PartLoop',
     'All-Sound-Off loop: check part mute flag, stop if active'),

    ('LABEL_FE0C76', 'RhythmMidi_CC7D_PartNext',
     'Advance to next part in All-Sound-Off loop'),

    ('LABEL_FE0C80', 'RhythmMidi_CC_Default',
     'Default CC handler: route by CC number (0x70+ or standard)'),

    ('LABEL_FE0CC8', 'RhythmMidi_CC_Standard',
     'Standard CC: lookup note-to-part mapping, set mute flag'),

    ('LABEL_FE0CE8', 'RhythmMidi_CC_UpdateOutput',
     'Post-CC: update audio output parameters'),

    ('LABEL_FE0CFD', 'RhythmMidi_CC_PostProcess',
     'Post-process: iterate parts, send pending note events'),

    ('LABEL_FE0D05', 'RhythmMidi_CC_PostLoop',
     'Post-process loop: check mute flag, send note event if active'),

    ('LABEL_FE0D42', 'RhythmMidi_CC_PostNext',
     'Advance to next part in post-process loop'),

    ('LABEL_FE0D4A', 'RhythmMidi_CC_Return',
     'Epilogue: restore context, return'),

    # -- RhythmMidi sequencer event handler (FE0D53 - FE0E7F)
    # Processes sequencer buffer events for rhythm MIDI:
    # 0x90=NoteOn (map to part), 0xB0=CC (7E/7F/default).
    ('LABEL_FE0D53', 'RhythmMidi_SeqEvt',
     'Sequencer event handler: init buffer reader, process events'),

    ('LABEL_FE0D7F', 'RhythmMidi_SeqEvt_Dispatch',
     'Dispatch sequencer event: branch by status 0x90 or 0xB0'),

    ('LABEL_FE0DB3', 'RhythmMidi_SeqEvt_CC',
     'Sequencer CC event: check for 0x7E/0x7F special cases'),

    ('LABEL_FE0DC9', 'RhythmMidi_SeqEvt_CC7F_Loop',
     'Sequencer All-Notes-Off loop: iterate 2 parts'),

    ('LABEL_FE0DF1', 'RhythmMidi_SeqEvt_CC7F_Next',
     'Advance to next part in sequencer All-Notes-Off'),

    ('LABEL_FE0DFB', 'RhythmMidi_SeqEvt_CC7E',
     'Sequencer Local Control: iterate 1 part'),

    ('LABEL_FE0E03', 'RhythmMidi_SeqEvt_CC7E_Loop',
     'Sequencer Local Control loop: map note to part, send CC'),

    ('LABEL_FE0E2B', 'RhythmMidi_SeqEvt_CC7E_Next',
     'Advance to next part in sequencer Local Control'),

    ('LABEL_FE0E35', 'RhythmMidi_SeqEvt_CC_Default',
     'Sequencer default CC: lookup part, send CC'),

    ('LABEL_FE0E57', 'RhythmMidi_SeqEvt_ReadNext',
     'Read next sequencer event from buffer'),

    ('LABEL_FE0E6C', 'RhythmMidi_SeqEvt_Return',
     'Sequencer handler epilogue: restore, return'),
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
