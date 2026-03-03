#!/usr/bin/env python3
"""Rename LABEL_* to semantic names for maincpu sequencer, note-edit and track-assign functions.

Covers 10 function groups in kn5000_v10_program.s:
  1. CDlikeSwTtlFunc   (F21864-F21D0D)  CD-like switch title function
  2. AcTrAsGridBoxProc (F2BF89-F2C474)  Track assign grid box procedure
  3. TrAsGridCheck     (F2C4B4-F2C99D)  Track assign grid check
  4. NoteEditFunc      (F2FAD1-F2FD44)  Note edit function
  5. SqplyValProc      (F30ABD-F3106C)  Sequencer play value procedure
  6. SqedtValProc      (F310C0-F31548)  Sequencer edit value procedure
  7. AccIllProc        (F331BA-F33449)  Acoustic illusion procedure
  8. SqplyFunc         (F346ED-F349CF)  Sequencer play function
  9. NoteEditSyori     (F466C7-F46A47)  Note edit processing
  10. MainExeCall       (F470F7-F475E8)  Main execute call dispatcher

Each rename was verified by analysing the routine's code, register usage,
called functions, and callers within the file.

Uses binary I/O to handle Latin-1 encoding safely.  Never use the Edit tool on
kn5000_v10_program.s -- it corrupts the Latin-1 encoding.
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
    # 1. CDlikeSwTtlFunc (lines 87488-87936, 41 labels)
    #    CD-like switch title function: handles song/doc/pd list navigation,
    #    name display, and title bar updates for CD-like UI mode.
    # ==================================================================

    ('LABEL_F21864', 'CDlikeSwTtl_ReturnZero',
     'Return XHL=0 (no match for event code)'),

    ('LABEL_F21867', 'CDlikeSwTtl_ShowSongTitle',
     'Display song title: fetch name at offset 0xC via LABEL_F89AC7, Strncpy to 0x1C1E'),

    ('LABEL_F218BB', 'CDlikeSwTtl_ShowDocTitle',
     'Display document title: fetch name via LABEL_F8A7CE, Strncpy to 0x1C2C'),

    ('LABEL_F218FF', 'CDlikeSwTtl_ShowPdTitle',
     'Display program data title: fetch name via LABEL_F8A4C8, Strncpy to 0x1C3A'),

    ('LABEL_F21943', 'CDlikeSwTtl_SongBit1Check',
     'Song mode: check FEBF7A bit1 for redraw vs bit0 for title display'),

    ('LABEL_F21961', 'CDlikeSwTtl_SongBit0Check',
     'Song mode bit0 path: calls FEBF7A, falls through to ShowSongTitle or sends event'),

    ('LABEL_F2197E', 'CDlikeSwTtl_JumpToFA9D58',
     'Tail call to 0xFA9D58 (event dispatch)'),

    ('LABEL_F21982', 'CDlikeSwTtl_DocBitCheck',
     'Doc mode: check FEBF7A bit1/bit0 for redraw vs ShowDocTitle'),

    ('LABEL_F21995', 'CDlikeSwTtl_DocRedraw',
     'Doc mode redraw: call LABEL_F22ABF then LABEL_FEC11C'),

    ('LABEL_F2199C', 'CDlikeSwTtl_PdBitCheck',
     'PD mode: check FEBF7A bit1/bit0 for redraw vs ShowPdTitle'),

    ('LABEL_F219AF', 'CDlikeSwTtl_PdRedraw',
     'PD mode redraw: call LABEL_F22ABF then LABEL_FEC11C'),

    ('LABEL_F219B6', 'CDlikeSwTtl_SongConfirmStart',
     'Song confirm mode: set state 3/2/1 in mem[7498] based on FEBF7A bits'),

    ('LABEL_F219C6', 'CDlikeSwTtl_SongConfirmBit0',
     'Song confirm: bit0 path, set state=2'),

    ('LABEL_F219D6', 'CDlikeSwTtl_SongConfirmDefault',
     'Song confirm: default path, set state=1, call ShowSongTitle+LABEL_F22A8E'),

    ('LABEL_F219E1', 'CDlikeSwTtl_SongConfirmJump',
     'Jump to LABEL_FEC1F3 (confirm handler)'),

    ('LABEL_F219E5', 'CDlikeSwTtl_SongConfirmDispatch',
     'Dispatch on confirm state (1/2/3) from mem[7498]'),

    ('LABEL_F219F5', 'CDlikeSwTtl_SongConfirmState1',
     'Confirm state 1: call LABEL_F22A8E, jump to LABEL_FEC1C3'),

    ('LABEL_F219FC', 'CDlikeSwTtl_SongConfirmState2',
     'Confirm state 2: call LABEL_F22A5D, jump to LABEL_FEC1E1'),

    ('LABEL_F21A03', 'CDlikeSwTtl_DocConfirmStart',
     'Doc confirm mode: set state 3/2/1 in mem[7498] based on FEBF7A bits'),

    ('LABEL_F21A13', 'CDlikeSwTtl_DocConfirmBit0',
     'Doc confirm: bit0 path, set state=2'),

    ('LABEL_F21A23', 'CDlikeSwTtl_DocConfirmDefault',
     'Doc confirm: default path, set state=1, call ShowDocTitle+LABEL_F22A8E'),

    ('LABEL_F21A2E', 'CDlikeSwTtl_DocConfirmJump',
     'Jump to LABEL_FEC1F3 (confirm handler)'),

    ('LABEL_F21A32', 'CDlikeSwTtl_PdConfirmStart',
     'PD confirm mode: set state 3/2/1 in mem[7498] based on FEBF7A bits'),

    ('LABEL_F21A42', 'CDlikeSwTtl_PdConfirmBit0',
     'PD confirm: bit0 path, set state=2'),

    ('LABEL_F21A52', 'CDlikeSwTtl_PdConfirmDefault',
     'PD confirm: default path, set state=1, call ShowPdTitle+LABEL_F22A8E'),

    ('LABEL_F21A5D', 'CDlikeSwTtl_PdConfirmJump',
     'Jump to LABEL_FEC1F3 (confirm handler)'),

    ('LABEL_F21A61', 'CDlikeSwTtl_SongNavDispatch',
     'Song navigation dispatch: saves WA to IZ, checks FEBF7A bit1/bit0'),

    ('LABEL_F21AD5', 'CDlikeSwTtl_SongNavBit0',
     'Song nav bit0 path: NavigateSongList, clear state, refresh names'),

    ('LABEL_F21B44', 'CDlikeSwTtl_SongNavFinishNames',
     'Finish name refresh: call NameGetFuncCall, then ShowSongTitle'),

    ('LABEL_F21B4C', 'CDlikeSwTtl_SongNavNoRedraw',
     'Song nav no-redraw path: NavigateSongList, clear state, refresh all names'),

    ('LABEL_F21BA1', 'CDlikeSwTtl_SongNavReturn',
     'Pop IZ and return from song navigation'),

    ('LABEL_F21BA3', 'CDlikeSwTtl_DocNavDispatch',
     'Doc navigation dispatch: saves WA to IZ, checks FEBF7A bit1/bit0'),

    ('LABEL_F21BE3', 'CDlikeSwTtl_DocNavBit0',
     'Doc nav bit0 path: NavigateDocList, clear state, refresh names'),

    ('LABEL_F21C1E', 'CDlikeSwTtl_DocNavFinishNames',
     'Finish doc name refresh: call NameGetFuncCall, then ShowDocTitle'),

    ('LABEL_F21C26', 'CDlikeSwTtl_DocNavNoRedraw',
     'Doc nav no-redraw path: NavigateDocList, refresh all names'),

    ('LABEL_F21C57', 'CDlikeSwTtl_DocNavReturn',
     'Pop IZ and return from doc navigation'),

    ('LABEL_F21C59', 'CDlikeSwTtl_PdNavDispatch',
     'PD navigation dispatch: saves WA to IZ, checks FEBF7A bit1/bit0'),

    ('LABEL_F21C99', 'CDlikeSwTtl_PdNavBit0',
     'PD nav bit0 path: NavigatePdList, clear state, refresh names'),

    ('LABEL_F21CD4', 'CDlikeSwTtl_PdNavFinishNames',
     'Finish PD name refresh: call NameGetFuncCall, then ShowPdTitle'),

    ('LABEL_F21CDC', 'CDlikeSwTtl_PdNavNoRedraw',
     'PD nav no-redraw path: NavigatePdList, refresh all names'),

    ('LABEL_F21D0D', 'CDlikeSwTtl_PdNavReturn',
     'Pop IZ and return from PD navigation'),

    # ==================================================================
    # 2. AcTrAsGridBoxProc (lines 103636-104119, 32 labels)
    #    Track assign grid box procedure: handles grid UI events for
    #    track assignment including scrolling, cursor movement, and
    #    grid state toggling.
    # ==================================================================

    ('LABEL_F2BF89', 'TrAsGrid_HandleInit',
     'Initialize grid: set 0xC0 via LABEL_FCD437, configure 0x8B0009 event'),

    ('LABEL_F2BF9F', 'TrAsGrid_InitStateZero',
     'Init state: LABEL_FCD437 returned 0, set BC=1'),

    ('LABEL_F2BFA6', 'TrAsGrid_InitDispatch',
     'Call 0xFA5E8C and FA4409, then get widget info via FA6266'),

    ('LABEL_F2C049', 'TrAsGrid_ScrollDown',
     'Scroll down: increment cursor position by 5 in grid'),

    ('LABEL_F2C060', 'TrAsGrid_ApplyScrollOffset',
     'Apply scroll offset: call LABEL_F2BF11, store to 0x021082'),

    ('LABEL_F2C0B9', 'TrAsGrid_CheckScrollBoundary',
     'Check scroll boundary: compare with bit0 flag and position 0'),

    ('LABEL_F2C0EA', 'TrAsGrid_DispatchNavigate',
     'Dispatch grid navigate event and refresh display'),

    ('LABEL_F2C117', 'TrAsGrid_HandleOtherEvent',
     'Handle 0x1E00091 event: check bitda 2 flag, process track selection'),

    ('LABEL_F2C1B6', 'TrAsGrid_ScrollDown2',
     'Second grid direction: increment by 7'),

    ('LABEL_F2C1CD', 'TrAsGrid_ApplyScrollOffset2',
     'Apply second scroll offset: call LABEL_F2BF11, store to 0x021082'),

    ('LABEL_F2C224', 'TrAsGrid_CheckScrollBoundary2',
     'Check second scroll boundary: compare with bit0 flag and position 7'),

    ('LABEL_F2C255', 'TrAsGrid_DispatchNavigate2',
     'Dispatch second grid navigate event and refresh display'),

    ('LABEL_F2C282', 'TrAsGrid_HandleOtherEvent2',
     'Handle 0x1E00091 for second direction: check bitda 2 flag'),

    ('LABEL_F2C2EB', 'TrAsGrid_CallUpdateSorted',
     'Call 0xF9A53B (update sorted list) and jump to return'),

    ('LABEL_F2C2F2', 'TrAsGrid_GetWidgetLabel',
     'Get widget label string from (xhl+62) for 0x1E0008A event'),

    ('LABEL_F2C2FF', 'TrAsGrid_GetDirectionLabel',
     'Get direction label based on bit0 flag at mem[3296]'),

    ('LABEL_F2C30C', 'TrAsGrid_DirectionLabel2',
     'Load second direction label string address'),

    ('LABEL_F2C311', 'TrAsGrid_PushLabelAddr',
     'Push label address for Strcpy call'),

    ('LABEL_F2C312', 'TrAsGrid_CopyLabel',
     'Copy label string via Strcpy, return to common exit'),

    ('LABEL_F2C31F', 'TrAsGrid_HandleSelectEvent',
     'Handle 0x1C00007 event: process grid cell selection toggle'),

    ('LABEL_F2C38C', 'TrAsGrid_DeselectCell',
     'Deselect grid cell: clear bit0 in flag, dispatch deselect event'),

    ('LABEL_F2C3D7', 'TrAsGrid_FinishCellUpdate',
     'Call FA4932 and F9884B to finish cell update'),

    ('LABEL_F2C3E1', 'TrAsGrid_HandleResizeEvent',
     'Handle 0x1E0008D event: get widget info at (xhl+70), call FA49B7'),

    ('LABEL_F2C3F5', 'TrAsGrid_ReturnZero',
     'Return XHL=0 (common successful return)'),

    ('LABEL_F2C3F9', 'TrAsGrid_PassThrough',
     'Pass through unhandled event to FA4409'),

    ('LABEL_F2C406', 'TrAsGrid_Epilogue',
     'Pop XIZ, restore stack, return'),

    ('LABEL_F2C40B', 'TrAsGrid_LookupTable',
     'Lookup word from table at 0xE26448 indexed by WA'),

    ('LABEL_F2C41A', 'TrAsGrid_ByteData1',
     'Inline .byte data for grid state machine'),

    ('LABEL_F2C446', 'TrAsGrid_CheckTrackType',
     'Check if track type is 0xE or 0xD (drum/perc): return L=1 if yes'),

    ('LABEL_F2C462', 'TrAsGrid_NotDrumType',
     'Return L=0 (not a drum/percussion track type)'),

    ('LABEL_F2C465', 'TrAsGrid_CheckCurrentCell',
     'Check current cell type at 0x021082 for 0xE/0xD'),

    ('LABEL_F2C474', 'TrAsGrid_IsDrumType',
     'Return L=1 (is drum/percussion track type)'),

    # ==================================================================
    # 3. TrAsGridCheck (lines 104120-104491, 24 labels)
    #    Track assign grid check: validates grid assignments, sends
    #    audio commands based on grid cell type (part 1/2/3),
    #    handles drum/percussion special cases.
    # ==================================================================

    ('LABEL_F2C4B4', 'TrAsGridChk_ByteData',
     'Inline .byte data block for grid check jump table'),

    ('LABEL_F2C735', 'TrAsGridChk_HandleResizeEvent',
     'Handle 0x1E0008D event: decode grid position and dispatch by part type'),

    ('LABEL_F2C782', 'TrAsGridChk_Part1_AdjustDown',
     'Part 1: position mismatch, check bit0 flag and adjust offset down by 2'),

    ('LABEL_F2C791', 'TrAsGridChk_Part1_AdjustUp',
     'Part 1: adjust offset up by 6'),

    ('LABEL_F2C798', 'TrAsGridChk_Part1_SendAudio',
     'Part 1: lookup audio command from 0xE262CA, call Audio_SendCommand'),

    ('LABEL_F2C7C3', 'TrAsGridChk_Part2_Start',
     'Part 2 handler: check bit0 flag, lookup table, send audio command'),

    ('LABEL_F2C7E5', 'TrAsGridChk_Part2_PushCmd',
     'Part 2: push audio command address and call Audio_SendCommand'),

    ('LABEL_F2C81E', 'TrAsGridChk_Part2_CheckType0',
     'Part 2: check track type with mode=0 (non-matching position)'),

    ('LABEL_F2C82E', 'TrAsGridChk_Part2_UpDir',
     'Part 2 up-direction: adjust offset up by 6, lookup table'),

    ('LABEL_F2C84A', 'TrAsGridChk_Part2_UpPushCmd',
     'Part 2 up-direction: push audio command and call Audio_SendCommand'),

    ('LABEL_F2C882', 'TrAsGridChk_Part2_UpCheckType0',
     'Part 2 up-direction: check track type with mode=0'),

    ('LABEL_F2C890', 'TrAsGridChk_SendExtraAudioCmd',
     'Send extra audio command: push XWA, call Audio_SendCommand'),

    ('LABEL_F2C89B', 'TrAsGridChk_Part2_Finish',
     'Part 2 finish: call FA44D0, dispatch 0x1E0008C event'),

    ('LABEL_F2C8AC', 'TrAsGridChk_Part3_Start',
     'Part 3 handler: check bit0 flag, lookup table at 62096, send audio'),

    ('LABEL_F2C8CB', 'TrAsGridChk_Part3_PushCmd',
     'Part 3: push audio command and call Audio_SendCommand'),

    ('LABEL_F2C907', 'TrAsGridChk_Part3_CheckType0',
     'Part 3: check track type with mode=0 (non-matching position)'),

    ('LABEL_F2C917', 'TrAsGridChk_Part3_UpDir',
     'Part 3 up-direction: adjust offset up by 6, lookup table'),

    ('LABEL_F2C930', 'TrAsGridChk_Part3_UpPushCmd',
     'Part 3 up-direction: push audio command and call Audio_SendCommand'),

    ('LABEL_F2C96B', 'TrAsGridChk_Part3_UpCheckType0',
     'Part 3 up-direction: check track type with mode=0'),

    ('LABEL_F2C979', 'TrAsGridChk_SendExtraAudioCmd2',
     'Send extra audio command for part 3: push XWA, call Audio_SendCommand'),

    ('LABEL_F2C984', 'TrAsGridChk_Part3_Finish',
     'Part 3 finish: call FA44D0, dispatch 0x1E0008C event'),

    ('LABEL_F2C992', 'TrAsGridChk_DispatchAndReturn',
     'Call FA9660 and fall through to return'),

    ('LABEL_F2C996', 'TrAsGridChk_ReturnZero',
     'Return XHL=0, pop XIZ, restore stack'),

    ('LABEL_F2C99D', 'TrAsGridChk_End',
     'End sentinel for TrAsGridCheck function'),

    # ==================================================================
    # 4. NoteEditFunc (lines 107377-107685, 28 labels)
    #    Note edit function: formats note parameters for display including
    #    tempo, time signature, note name, velocity, gate time, etc.
    # ==================================================================

    ('LABEL_F2FAD1', 'NoteEdit_FormatTempo',
     'Format tempo value: if <= 0x3E7 call Audio_SendCommand, else copy string'),

    ('LABEL_F2FAF2', 'NoteEdit_FormatTempoString',
     'Format tempo as string via Strcpy from 0xE3466E'),

    ('LABEL_F2FB54', 'NoteEdit_FormatNoteOther',
     'Format note name: push value and use format string at 0xE34680'),

    ('LABEL_F2FBD9', 'NoteEdit_GateTime0C',
     'Gate time 0x0C: load format string 0xE346A0'),

    ('LABEL_F2FBE0', 'NoteEdit_GateTime10',
     'Gate time 0x10: load format string 0xE346A8'),

    ('LABEL_F2FBE5', 'NoteEdit_GateTimePushFormat',
     'Push gate time format string and string buffer pointer'),

    ('LABEL_F2FBEB', 'NoteEdit_GateTime18',
     'Gate time 0x18: load format string 0xE346B0'),

    ('LABEL_F2FBF2', 'NoteEdit_GateTime20',
     'Gate time 0x20: load format string 0xE346B8'),

    ('LABEL_F2FBF9', 'NoteEdit_GateTime30',
     'Gate time 0x30: load format string 0xE346C0'),

    ('LABEL_F2FC00', 'NoteEdit_GateTime60',
     'Gate time 0x60: load format string 0xE346C8 (full note)'),

    ('LABEL_F2FC05', 'NoteEdit_GateTimePushAndCopy',
     'Push gate time format and copy via Strcpy'),

    ('LABEL_F2FC0A', 'NoteEdit_GateTimeStrcpy',
     'Call Strcpy for gate time string, adjust stack'),

    ('LABEL_F2FC13', 'NoteEdit_GateTimeNumeric',
     'Format gate time as numeric value via Audio_SendCommand with 0xE346D0'),

    ('LABEL_F2FC1D', 'NoteEdit_FormatChordType',
     'Format chord type: lookup offset from mem[10142]+mem[135318]'),

    ('LABEL_F2FC30', 'NoteEdit_PushFormatAndCopy',
     'Common: push format addr, push dest buffer, call Audio_SendCommand or Strcpy'),

    ('LABEL_F2FC35', 'NoteEdit_CallAudioSendCmd',
     'Call Audio_SendCommand with 10-byte stack frame, adjust stack'),

    ('LABEL_F2FC3F', 'NoteEdit_FormatChordNotes',
     'Format chord notes: compute table offset via Math_MultiplyAccumulate'),

    ('LABEL_F2FC64', 'NoteEdit_GetParamValue',
     'Get parameter value by index via jump table at 0xE346D8'),

    ('LABEL_F2FC8A', 'NoteEdit_ParamJumpTable',
     'Inline jump table body: dispatch to parameter load by DE index'),

    ('LABEL_F2FCC0', 'NoteEdit_GetTempoValue',
     'Get tempo value from mem[10052], extend to XHL'),

    ('LABEL_F2FD07', 'NoteEdit_FormatNoteNameHigh',
     'Format note name (high): 6-byte Strncpy from note table + (vel+1)*6'),

    ('LABEL_F2FD14', 'NoteEdit_FormatNoteNameLow',
     'Format note name (low): 6-byte Strncpy from note table + vel*6'),

    ('LABEL_F2FD1D', 'NoteEdit_CopyNoteName',
     'Compute note name offset (WA * 6 + XHL), push for Strncpy'),

    ('LABEL_F2FD28', 'NoteEdit_DoStrncpy',
     'Call Strncpy with 10-byte frame for note name'),

    ('LABEL_F2FD33', 'NoteEdit_RestoreAndReturn',
     'Restore saved XWA from stack, jump to epilogue'),

    ('LABEL_F2FD38', 'NoteEdit_GetScreenId',
     'Get screen ID via FA5867, clear H, extend to XHL'),

    ('LABEL_F2FD42', 'NoteEdit_DefaultReturn',
     'Default: return XHL=0 for unhandled events'),

    ('LABEL_F2FD44', 'NoteEdit_Epilogue',
     'Pop XIZ, adjust stack, return'),

    # ==================================================================
    # 5. SqplyValProc (lines 108824-109317, 26 labels)
    #    Sequencer play value procedure: handles value changes for
    #    sequencer play mode including track selection, scrollbar updates,
    #    screen refresh, and note grid rendering.
    # ==================================================================

    ('LABEL_F30ABD', 'SqplyVal_HandleInitEvent',
     'Handle 0x1C0000B init event: dispatch to FA4409, get widget info'),

    ('LABEL_F30AF1', 'SqplyVal_InitScrollAndRefresh',
     'Set up scrollbar 0x1E80035, send 0x89 event, update scroll positions'),

    ('LABEL_F30B39', 'SqplyVal_CheckMode81',
     'Check for mode 0x81: set up 0x810016/0x810012 events, clear mem[58254]'),

    ('LABEL_F30B63', 'SqplyVal_DispatchUpdate',
     'Dispatch update: call FA9B5D with 0x1480003, jump to return'),

    ('LABEL_F30B75', 'SqplyVal_HandleScrollEvent',
     'Handle 0x1C0000F scroll event: validate screen match via 1E80069'),

    ('LABEL_F30C16', 'SqplyVal_ClearDrawBuffer',
     'Clear 16-byte draw buffer via stib_dpi loop'),

    ('LABEL_F30C48', 'SqplyVal_RenderNoteGrid0',
     'Render note grid mode 0/3/7: set up 1E8003E rect coords and draw params'),

    ('LABEL_F30C6E', 'SqplyVal_RenderNoteGrid1',
     'Render note grid mode 1: set up 1E8003F rect coords'),

    ('LABEL_F30C94', 'SqplyVal_RenderNoteGrid2',
     'Render note grid mode 2: set up 1E80040 rect coords'),

    ('LABEL_F30CB8', 'SqplyVal_CallDrawGrid',
     'Call FACF4A to draw grid, jump to return'),

    ('LABEL_F30CBF', 'SqplyVal_HandleExtraParams',
     'Handle extra parameters (modes 4-11): dispatch via jump table at 0xE3480C'),

    ('LABEL_F30CF0', 'SqplyVal_ExtraParamsData',
     'Inline .byte data for extra parameter dispatch'),

    ('LABEL_F30D8C', 'SqplyVal_HandleUpScrollEvent',
     'Handle 0x1C00017 up-scroll event: update scroll position via BERP lookups'),

    ('LABEL_F30E00', 'SqplyVal_UpScroll_Mode2',
     'Up-scroll mode 2: check bitda 2 flag, update 1E80014 and redraw'),

    ('LABEL_F30E51', 'SqplyVal_HandleDownScrollEvent',
     'Handle 0x1C00018 down-scroll event: update scroll position via BERP lookups'),

    ('LABEL_F30EC5', 'SqplyVal_DownScroll_Mode2',
     'Down-scroll mode 2: check bitda 2 flag, update 1E80015 and redraw'),

    ('LABEL_F30F13', 'SqplyVal_CallSortedUpdate',
     'Call F9A53B (sorted update) and jump to return'),

    ('LABEL_F30F1A', 'SqplyVal_HandleSelectEvent',
     'Handle 0x1C00007 select event: dispatch by track/part index'),

    ('LABEL_F30F9C', 'SqplyVal_SelectTrack',
     'Select track: lookup via 1E80036/37, get scrollbar value via 1E80035'),

    ('LABEL_F3102A', 'SqplyVal_SelectTrack_SetPart1',
     'Set part index to 1 and jump to SelectTrack'),

    ('LABEL_F31031', 'SqplyVal_SelectTrack_SetPart2',
     'Set part index to 2 and jump to SelectTrack'),

    ('LABEL_F31038', 'SqplyVal_SelectTrack_SetPart3',
     'Set part index to 3 and jump to SelectTrack'),

    ('LABEL_F3103F', 'SqplyVal_SelectTrack_NegRange',
     'Negative BERP range: lookup via 1E80037 with old part index'),

    ('LABEL_F31066', 'SqplyVal_DispatchScrollCmd',
     'Call FA9660 with scroll command'),

    ('LABEL_F3106A', 'SqplyVal_ReturnZero',
     'Return XHL=0'),

    ('LABEL_F3106C', 'SqplyVal_Epilogue',
     'Pop WERP, restore stack, return'),

    # ==================================================================
    # 6. SqedtValProc (lines 109318-109693, 21 labels)
    #    Sequencer edit value procedure: handles value changes for
    #    sequencer edit mode, similar structure to SqplyValProc but with
    #    different parameter mappings.
    # ==================================================================

    ('LABEL_F310C0', 'SqedtVal_HandleInitEvent',
     'Handle 0x1C0000B init event: set scrollbar 1E80035, send 0x88 event'),

    ('LABEL_F31125', 'SqedtVal_HandleScrollEvent',
     'Handle 0x1C0000F scroll event: validate screen match via 1E80069'),

    ('LABEL_F311C6', 'SqedtVal_ClearDrawBuffer',
     'Clear 24-byte draw buffer via stib_dpi loop'),

    ('LABEL_F311F1', 'SqedtVal_DrawParamsData',
     'Inline .byte data for edit parameter dispatch (up to 15 entries)'),

    ('LABEL_F3131B', 'SqedtVal_HandleUpScrollEvent',
     'Handle 0x1C00017 up-scroll event: update scroll position via BERP lookups'),

    ('LABEL_F3138B', 'SqedtVal_HandleDownScrollEvent',
     'Handle 0x1C00018 down-scroll event: update scroll position via BERP lookups'),

    ('LABEL_F313F9', 'SqedtVal_CallRedraw',
     'Call F9A5BD to redraw and jump to return'),

    ('LABEL_F31400', 'SqedtVal_HandleSelectEvent',
     'Handle 0x1C00007 select event: dispatch by part type (0x88-0x8B, 8/9/B)'),

    ('LABEL_F31457', 'SqedtVal_SetBerp1',
     'Set BERP 0xFB to 1 (part index 0x89)'),

    ('LABEL_F3145C', 'SqedtVal_SetBerp2',
     'Set BERP 0xFB to 2 (part index 0x8A)'),

    ('LABEL_F31461', 'SqedtVal_SetBerp3',
     'Set BERP 0xFB to 3 (part index 0x8B)'),

    ('LABEL_F31466', 'SqedtVal_SetBerp5',
     'Set BERP 0xFB to 5 (part index 0x8)'),

    ('LABEL_F3146B', 'SqedtVal_SetBerp6',
     'Set BERP 0xFB to 6 (part index 0x9)'),

    ('LABEL_F31470', 'SqedtVal_CallSortedUpdate',
     'Part index 0xB: call F9A53B sorted update'),

    ('LABEL_F31472', 'SqedtVal_DoSortedUpdate',
     'Call F9A53B and jump to return'),

    ('LABEL_F31479', 'SqedtVal_SelectDefault',
     'Default select: load part from 1E80036 BERP into 0xFB'),

    ('LABEL_F3148D', 'SqedtVal_SelectDispatch',
     'Dispatch select: lookup via 1E80036/37, update scroll via 1E80035'),

    ('LABEL_F3151B', 'SqedtVal_Select_NegRange',
     'Negative BERP range: lookup via 1E80037 with old part index'),

    ('LABEL_F31542', 'SqedtVal_DispatchScrollCmd',
     'Call FA9660 with scroll command'),

    ('LABEL_F31546', 'SqedtVal_ReturnZero',
     'Return XHL=0'),

    ('LABEL_F31548', 'SqedtVal_Epilogue',
     'Pop WERP, restore stack, return'),

    # ==================================================================
    # 7. AccIllProc (lines 111996-112291, 20 labels)
    #    Acoustic illusion procedure: handles acoustic illusion sound
    #    parameter display and editing, including two parameter panels
    #    (horizontal and vertical) with scrollbar controls.
    # ==================================================================

    ('LABEL_F331BA', 'AccIll_HandleLowerPanelEvent',
     'Handle 0x1E8000E event: dispatch 0x1C80000 with XDE=0'),

    ('LABEL_F331C6', 'AccIll_HandleUpperPanelEvent',
     'Handle 0x1E8000F event: if XDE=0, dispatch 0x1C80001 with XDE=0'),

    ('LABEL_F331D8', 'AccIll_PanelDispatch',
     'Call FA9660 to dispatch panel event'),

    ('LABEL_F331DF', 'AccIll_HandleHorizSlider',
     'Handle 0x1C80000 (horizontal slider): validate screen, set rect (100,94,280,113)'),

    ('LABEL_F33253', 'AccIll_ClearDrawBuffer1',
     'Clear 20-byte draw buffer via stib_dpi loop'),

    ('LABEL_F3329E', 'AccIll_HandleVertSlider',
     'Handle 0x1C80001 (vertical slider): validate screen, set rect (178,145,223,157)'),

    ('LABEL_F33312', 'AccIll_ClearDrawBuffer2',
     'Clear 20-byte draw buffer for vertical panel via stib_dpi loop'),

    ('LABEL_F33357', 'AccIll_CallDrawRoutine',
     'Call FACF4A to draw parameter display'),

    ('LABEL_F3335E', 'AccIll_HandleUpScroll',
     'Handle 0x1C00017 up-scroll: dispatch 1E80011/1E80012 based on XDE'),

    ('LABEL_F3337F', 'AccIll_UpScroll_Mode1',
     'Up-scroll mode 1: dispatch 1E80012 with XDE=0x100'),

    ('LABEL_F33399', 'AccIll_UpScroll_Dispatch',
     'Call FA9B5D for up-scroll dispatch'),

    ('LABEL_F3339D', 'AccIll_UpScroll_Refresh',
     'Refresh after up-scroll: call F9A5BD, update scroll positions'),

    ('LABEL_F333C9', 'AccIll_HandleDownScroll',
     'Handle 0x1C00018 down-scroll: dispatch 1E80011/1E80012 based on XDE'),

    ('LABEL_F333ED', 'AccIll_DownScroll_Mode1',
     'Down-scroll mode 1: dispatch 1E80012 with XDE=0xFFFFFF00'),

    ('LABEL_F33407', 'AccIll_DownScroll_Dispatch',
     'Call FA9B5D for down-scroll dispatch'),

    ('LABEL_F3340B', 'AccIll_DownScroll_Refresh',
     'Refresh after down-scroll: call F9A5BD, update scroll positions'),

    ('LABEL_F33435', 'AccIll_CallSortedUpdate',
     'Call F9A53B (sorted update)'),

    ('LABEL_F33439', 'AccIll_ReturnZero',
     'Return XHL=0'),

    ('LABEL_F3343D', 'AccIll_PassThrough',
     'Pass through unhandled event to FA4409'),

    ('LABEL_F33449', 'AccIll_Epilogue',
     'Pop XIZ, restore stack, return'),

    # ==================================================================
    # 8. SqplyFunc (lines 113844-114160, 36 labels)
    #    Sequencer play function: formats sequencer play parameters for
    #    display, handles screen ID queries, track selection lookups,
    #    and parameter string formatting.
    # ==================================================================

    ('LABEL_F346ED', 'SqplyFunc_ParamFormatData',
     'Inline .byte data for parameter format dispatch table'),

    ('LABEL_F34801', 'SqplyFunc_FormatRhythmPattern',
     'Format rhythm pattern: check for 0x8002/0x8001 special values'),

    ('LABEL_F3481A', 'SqplyFunc_CheckPattern8001',
     'Check for pattern 0x8001: load format string 0xE34AF4'),

    ('LABEL_F34825', 'SqplyFunc_CopyPatternString',
     'Push format string and copy via Strcpy'),

    ('LABEL_F34831', 'SqplyFunc_FormatPatternNumeric',
     'Format pattern as numeric value via Audio_SendCommand'),

    ('LABEL_F3483A', 'SqplyFunc_FormatIntro',
     'Format intro parameter: push mem[0xF238] value'),

    ('LABEL_F3484A', 'SqplyFunc_FormatEnding',
     'Format ending parameter: push mem[0xF23A] value'),

    ('LABEL_F3485F', 'SqplyFunc_PushAndFormat',
     'Push string buffer pointer and jump to Audio_SendCommand call'),

    ('LABEL_F34864', 'SqplyFunc_FormatFillIn',
     'Format fill-in parameter: push mem[0xF23F] value'),

    ('LABEL_F34872', 'SqplyFunc_PushFormatAddr',
     'Push format address and dest buffer pointer'),

    ('LABEL_F3487A', 'SqplyFunc_CallAudioSendCmd',
     'Call Audio_SendCommand with 10-byte frame'),

    ('LABEL_F34881', 'SqplyFunc_RestoreAndReturn',
     'Restore XHL from stack and jump to epilogue'),

    ('LABEL_F34887', 'SqplyFunc_HandleGetValue',
     'Handle 0x1E00045 get-value: dispatch by parameter index via table 0xE34B22'),

    ('LABEL_F348B0', 'SqplyFunc_GetValueDispatch',
     'Get-value dispatch body: return addr from various memory locations'),

    ('LABEL_F348D5', 'SqplyFunc_GetValNonPlay',
     'Get value for non-play mode (addr 9504)'),

    ('LABEL_F348EA', 'SqplyFunc_GetValNonPlay2',
     'Get value for non-play mode 2 (addr 9506)'),

    ('LABEL_F3490C', 'SqplyFunc_GetValueDone',
     'Jump to epilogue after get-value'),

    ('LABEL_F3490F', 'SqplyFunc_GetValueDefault',
     'Default get-value: return addr 9832'),

    ('LABEL_F34913', 'SqplyFunc_GetValueReturn',
     'Jump to epilogue after loading value address'),

    ('LABEL_F34916', 'SqplyFunc_StoreTrackPart',
     'Store track part byte to 0x02109C for 1E80035 event'),

    ('LABEL_F3491B', 'SqplyFunc_ReturnZero',
     'Return XHL=0 (default/unhandled)'),

    ('LABEL_F34920', 'SqplyFunc_HandleTrackLookup',
     'Handle 1E80037 event: determine track type (play/edit/perc) by screen mode'),

    ('LABEL_F34931', 'SqplyFunc_TrackMode82_86',
     'Mode 0x82/0x86: dispatch by part count (1->4, 2->5, 3->6)'),

    ('LABEL_F34943', 'SqplyFunc_TrackPart2',
     'Track part 2: return L=5'),

    ('LABEL_F34947', 'SqplyFunc_TrackPart3',
     'Track part 3: return L=6'),

    ('LABEL_F3494B', 'SqplyFunc_TrackMode88',
     'Mode 0x88: dispatch by part count (1->8, 2->9, 3->A)'),

    ('LABEL_F34962', 'SqplyFunc_TrackMode88_Part2',
     'Mode 0x88 part 2: return L=9'),

    ('LABEL_F34966', 'SqplyFunc_TrackMode88_Part3',
     'Mode 0x88 part 3: return L=A'),

    ('LABEL_F3496A', 'SqplyFunc_TrackMode96_99',
     'Mode 0x96/0x99: dispatch by part count (1->B, 2->5, 3->6)'),

    ('LABEL_F34974', 'SqplyFunc_TrackModePerc',
     'Percussion mode: same part dispatch as 0x82/0x86'),

    ('LABEL_F34986', 'SqplyFunc_TrackTypeUnknown',
     'Unknown track type: return L=0xFF'),

    ('LABEL_F34988', 'SqplyFunc_TrackTypeReturn',
     'Sign-extend HL and return track type'),

    ('LABEL_F3498E', 'SqplyFunc_HandlePartQuery',
     'Handle 1E80038 event: query part assignment by index 4-11'),

    ('LABEL_F349B0', 'SqplyFunc_PartQueryDispatch',
     'Part query dispatch body: check part assignment at mem[135324]'),

    ('LABEL_F349C7', 'SqplyFunc_GetScreenId',
     'Get screen ID via FA5867, clear H, extend to XHL'),

    ('LABEL_F349CF', 'SqplyFunc_Epilogue',
     'Restore stack and return'),

    # ==================================================================
    # 9. NoteEditSyori (lines 142564-142934, 58 labels)
    #    Note edit processing: main processing loop for note editing,
    #    dispatches to parameter-specific handlers for each editable
    #    field (pitch, velocity, gate, duration, expression, etc.).
    # ==================================================================

    ('LABEL_F466C7', 'NoteEditSy_InitPlayMode',
     'Init processing in play mode: call LABEL_F36F8B'),

    ('LABEL_F466CB', 'NoteEditSy_InitCommon',
     'Common init: call F38280, then update grid/params/display'),

    ('LABEL_F466F2', 'NoteEditSy_HandleUpScroll',
     'Handle 0x1C00017 up-scroll: dispatch by index 0-14 via table 0xE44A6A'),

    ('LABEL_F4670F', 'NoteEditSy_UpScroll_Param0',
     'Up-scroll parameter 0: call LABEL_F3656A'),

    ('LABEL_F46716', 'NoteEditSy_UpScroll_Param1',
     'Up-scroll parameter 1: call LABEL_F365D6'),

    ('LABEL_F4671D', 'NoteEditSy_UpScroll_Param2',
     'Up-scroll parameter 2: call LABEL_F36629'),

    ('LABEL_F46724', 'NoteEditSy_UpScroll_Param3',
     'Up-scroll parameter 3: call LABEL_F366B8'),

    ('LABEL_F4672B', 'NoteEditSy_UpScroll_Param4',
     'Up-scroll parameter 4: call LABEL_F36734'),

    ('LABEL_F46732', 'NoteEditSy_UpScroll_Param5',
     'Up-scroll parameter 5: call LABEL_F367E4'),

    ('LABEL_F46738', 'NoteEditSy_UpScroll_Param6',
     'Up-scroll parameter 6: call LABEL_F375D7'),

    ('LABEL_F4673E', 'NoteEditSy_UpScroll_Param7',
     'Up-scroll parameter 7: call LABEL_F36D04'),

    ('LABEL_F46744', 'NoteEditSy_UpScroll_Param8',
     'Up-scroll parameter 8: call LABEL_F37EDC'),

    ('LABEL_F4674A', 'NoteEditSy_UpScroll_Param9',
     'Up-scroll parameter 9: call LABEL_F37AA3'),

    ('LABEL_F46750', 'NoteEditSy_UpScroll_Param10',
     'Up-scroll parameter 10: call LABEL_F36E58'),

    ('LABEL_F46756', 'NoteEditSy_UpScroll_Param11',
     'Up-scroll parameter 11: call LABEL_F37A39'),

    ('LABEL_F4675C', 'NoteEditSy_UpScroll_Param12',
     'Up-scroll parameter 12: call LABEL_F37B09'),

    ('LABEL_F46762', 'NoteEditSy_HandleDownScroll',
     'Handle 0x1C00018 down-scroll: dispatch by index 0-11 via table 0xE44A52'),

    ('LABEL_F4677E', 'NoteEditSy_DownScroll_Param0',
     'Down-scroll parameter 0: call LABEL_F36591'),

    ('LABEL_F46784', 'NoteEditSy_DownScroll_Param1',
     'Down-scroll parameter 1: call LABEL_F36600'),

    ('LABEL_F4678A', 'NoteEditSy_DownScroll_Param2',
     'Down-scroll parameter 2: call LABEL_F36644'),

    ('LABEL_F46790', 'NoteEditSy_DownScroll_Param3',
     'Down-scroll parameter 3: call LABEL_F366CE'),

    ('LABEL_F46796', 'NoteEditSy_DownScroll_Param4',
     'Down-scroll parameter 4: call LABEL_F36743'),

    ('LABEL_F4679C', 'NoteEditSy_DownScroll_Param5',
     'Down-scroll parameter 5: call LABEL_F367FE'),

    ('LABEL_F467A2', 'NoteEditSy_DownScroll_Param6',
     'Down-scroll parameter 6: call LABEL_F378D7'),

    ('LABEL_F467A8', 'NoteEditSy_DownScroll_Param7',
     'Down-scroll parameter 7: call LABEL_F36D2F'),

    ('LABEL_F467B2', 'NoteEditSy_ReturnZero',
     'Return XHL=0 (common exit)'),

    ('LABEL_F467B5', 'NoteEditSy_SendScrollCmd0',
     'Send scroll command with XDE=0 via 0x1C0000F'),

    ('LABEL_F467C4', 'NoteEditSy_SendScrollCmd1',
     'Send scroll command with XDE=1 via 0x1C0000F'),

    ('LABEL_F467D3', 'NoteEditSy_SendScrollCmd2',
     'Send scroll command with XDE=2 via 0x1C0000F'),

    ('LABEL_F467E2', 'NoteEditSy_SendWidgetCmd0',
     'Send widget command with XDE=0 via 0x1C80004'),

    ('LABEL_F467F1', 'NoteEditSy_SendWidgetCmd1',
     'Send widget command with XDE=1 via 0x1C80004'),

    ('LABEL_F46800', 'NoteEditSy_SendWidgetCmd2',
     'Send widget command with XDE=2 via 0x1C80004'),

    ('LABEL_F4680F', 'NoteEditSy_SendWidgetCmd3or4',
     'Send widget command with XDE=3 (or 4 if play mode flag set)'),

    ('LABEL_F46819', 'NoteEditSy_SendWidgetCmdDispatch',
     'Dispatch widget command via 0xFA9E07'),

    ('LABEL_F46826', 'NoteEditSy_UpdateGridPosition',
     'Update note grid position: compute scroll offset, call LABEL_F368B7'),

    ('LABEL_F46842', 'NoteEditSy_GridPosPlayOffset',
     'Grid position play-mode offset: add 0xF'),

    ('LABEL_F46846', 'NoteEditSy_GridPosStore',
     'Store computed grid position to mem[10166]'),

    ('LABEL_F4689A', 'NoteEditSy_GridPosEdit',
     'Grid position edit-mode: add 0xF offset'),

    ('LABEL_F468A4', 'NoteEditSy_GridPosOutOfRange',
     'Grid position out of range: set mem[10164] to 0'),

    ('LABEL_F468AA', 'NoteEditSy_GridPosFinish',
     'Finish grid position update: send 0x1C80004 XDE=5 command'),

    ('LABEL_F468BD', 'NoteEditSy_UpdateEditModeGrid',
     'Update edit-mode grid: compute grid offset, send 0x1C80004 XDE=7'),

    ('LABEL_F468E1', 'NoteEditSy_SendModeScrollCmd',
     'Send mode-specific scroll command: XDE=9 (play) or XDE=6 (edit)'),

    ('LABEL_F468F7', 'NoteEditSy_SendScrollCmdEdit',
     'Send edit-mode scroll command: XDE=6 via 0x1C0000F'),

    ('LABEL_F468FE', 'NoteEditSy_JumpFA9E07',
     'Jump to FA9E07 for command dispatch'),

    ('LABEL_F46902', 'NoteEditSy_SendScrollCmd3',
     'Send scroll command with XDE=3 via 0x1C0000F'),

    ('LABEL_F46911', 'NoteEditSy_SendVelocityCmd',
     'Send velocity command: copy mem[10122]->mem[10602], XDE=0xA'),

    ('LABEL_F46929', 'NoteEditSy_SendGateCmd',
     'Send gate command: copy mem[10120]->mem[10602], XDE=4'),

    ('LABEL_F4693E', 'NoteEditSy_SendScrollCmd5',
     'Send scroll command with XDE=5 via 0x1C0000F'),

    ('LABEL_F4694D', 'NoteEditSy_SendScrollCmd8',
     'Send scroll command with XDE=8 via 0x1C0000F'),

    ('LABEL_F4695F', 'NoteEditSy_SendModeWidgetCmd',
     'Send mode widget command: XDE=0xD (play) or XDE=8 (edit) via 0x1C80004'),

    ('LABEL_F46975', 'NoteEditSy_WidgetCmdEdit',
     'Widget edit-mode command: XDE=8 via 0x1C80004'),

    ('LABEL_F4697F', 'NoteEditSy_JumpFA9E07_2',
     'Jump to FA9E07 for widget command dispatch'),

    ('LABEL_F46983', 'NoteEditSy_UpdateNoteDisplay',
     'Update note display: copy note params, call LABEL_F36EF2, send XDE=9'),

    ('LABEL_F469CC', 'NoteEditSy_SendWidgetCmdC',
     'Send widget command with XDE=0xC via 0x1C80004'),

    ('LABEL_F469DE', 'NoteEditSy_DisplayUpdateData',
     'Inline .byte data for display update calculations'),

    ('LABEL_F46A27', 'NoteEditSy_UpdateChordDisplay',
     'Update chord display: if play mode call LABEL_F37AF6+F36E7B, else send XDE=0xB'),

    ('LABEL_F46A35', 'NoteEditSy_ChordDisplayEdit',
     'Chord display edit mode: send 0x1C80004 XDE=0xB via FA9E07'),

    ('LABEL_F46A47', 'NoteEditSy_SendWidgetCmdE',
     'Send widget command with XDE=0xE via 0x1C80004'),

    # ==================================================================
    # 10. MainExeCall (lines 143590-144080, 45 labels)
    #     Main execute call dispatcher: central dispatcher for sequencer
    #     execution commands including play/record/song memory operations,
    #     pattern/rhythm/accompaniment loading, and mode transitions.
    # ==================================================================

    ('LABEL_F470F7', 'MainExe_HandleD6',
     'Handle mode 0xD6: call FE106A, FDB99B, F43A59'),

    ('LABEL_F47106', 'MainExe_Handle83',
     'Handle mode 0x83: call LABEL_F475E8 (sequencer stop routine)'),

    ('LABEL_F4710C', 'MainExe_Handle85',
     'Handle mode 0x85: check sub-mode E=0xA for conditional play start'),

    ('LABEL_F47132', 'MainExe_Handle85_SubE9',
     'Handle 0x85 sub-mode E=0x9: check flags for song play eligibility'),

    ('LABEL_F4714E', 'MainExe_Handle86',
     'Handle mode 0x86: check flags for song play eligibility with bit checks'),

    ('LABEL_F47162', 'MainExe_StartSongPlay',
     'Start song play: call LABEL_F3D7DF'),

    ('LABEL_F47169', 'MainExe_Handle90',
     'Handle mode 0x90: stop playback, set mem[32578]=0xFF, call F49A66/F419B6'),

    ('LABEL_F47193', 'MainExe_Handle90_Finish',
     'Finish mode 0x90: set WA=0x23, call LABEL_F4668B, clear flag'),

    ('LABEL_F471A0', 'MainExe_Handle8D',
     'Handle mode 0x8D: call FDB557, set WA=0x23'),

    ('LABEL_F471A9', 'MainExe_Handle91',
     'Handle mode 0x91: call LABEL_F4D3DB (song memory operation)'),

    ('LABEL_F471AD', 'MainExe_SongMemoryLoop',
     'Song memory processing loop: call LABEL_F46696, loop while active'),

    ('LABEL_F471C1', 'MainExe_SongMemStart',
     'Start song memory iteration: set mem[10359]=1'),

    ('LABEL_F471C6', 'MainExe_SongMemIterLoop',
     'Song memory iteration: process each part (0-15) via bit mask'),

    ('LABEL_F471D5', 'MainExe_SongMemShiftMask',
     'Shift bit mask for current part and check active flags'),

    ('LABEL_F471E9', 'MainExe_SongMemNextPart',
     'Increment part counter, loop until all 16 processed'),

    ('LABEL_F47219', 'MainExe_CallSongHandler',
     'Call LABEL_F4668B and jump to return'),

    ('LABEL_F4724E', 'MainExe_ClearPartMask1',
     'Complement BC, AND with mem[10357] to clear part bits'),

    ('LABEL_F47263', 'MainExe_ClearPartMask2',
     'Complement BC, AND with mem[65516] to clear part bits in FFE0 area'),

    ('LABEL_F47279', 'MainExe_ClearPartMask3',
     'Third part mask clear: for secondary part (mem[9858])'),

    ('LABEL_F4728E', 'MainExe_ClearPartMask4',
     'Fourth part mask clear: secondary part in FFE0 area'),

    ('LABEL_F472A4', 'MainExe_SetPartMask',
     'OR part mask into mem[10357] for tertiary part (mem[9860])'),

    ('LABEL_F472B7', 'MainExe_SetPartMaskFFE0',
     'OR part mask into mem[65516] for tertiary part'),

    ('LABEL_F472CB', 'MainExe_CheckResultCode',
     'Check result code at mem[32578]: 0xFF->done, 0x23->loop'),

    ('LABEL_F472E0', 'MainExe_CalcRemainingMask',
     'Calculate remaining active parts mask from three part indices'),

    ('LABEL_F472F9', 'MainExe_MaskSecondary',
     'Mask out secondary part (mem[9858]) from remaining mask'),

    ('LABEL_F4730C', 'MainExe_MaskTertiary',
     'Mask out tertiary part (mem[9860]) and store result'),

    ('LABEL_F47327', 'MainExe_StorePartDirect',
     'Store part index directly to mem[10359]'),

    ('LABEL_F4732B', 'MainExe_PatternLoad',
     'Pattern load: set up range parameters from mem[61938], call LABEL_F4C2A3'),

    ('LABEL_F473A6', 'MainExe_RhythmStorePartDirect',
     'Rhythm: store part index directly to mem[10359]'),

    ('LABEL_F473AA', 'MainExe_RhythmLoad',
     'Rhythm load: set up range parameters from mem[61993], call LABEL_F4C0F3'),

    ('LABEL_F4744E', 'MainExe_AccompStorePartDirect',
     'Accompaniment: store part index directly to mem[10359]'),

    ('LABEL_F47452', 'MainExe_AccompLoad',
     'Accompaniment load: set up range from mem[61916], call LABEL_F4A4EA'),

    ('LABEL_F474BC', 'MainExe_SongLoadStorePartDirect',
     'Song load: store part index directly to mem[10359]'),

    ('LABEL_F474C0', 'MainExe_SongLoad',
     'Song load: call LABEL_F4B1D1, check result'),

    ('LABEL_F474DD', 'MainExe_SongLoadCheckRedirect',
     'Song load: check for redirect (code 0x23), call LABEL_F3FD60'),

    ('LABEL_F474F3', 'MainExe_SongLoadFinish',
     'Song load finish: call LABEL_F46696, check for loop or done'),

    ('LABEL_F47505', 'MainExe_SetPartBitMask',
     'Set part bit mask: OR secondary part (mem[9858]) into mem[10357]'),

    ('LABEL_F47514', 'MainExe_OrPartMask',
     'OR shifted part mask into mem[10357]'),

    ('LABEL_F47518', 'MainExe_ReturnZero',
     'Return XHL=0'),

    ('LABEL_F4751B', 'MainExe_InlineByteData',
     'Inline .byte data block for additional dispatch logic'),

    ('LABEL_F475C5', 'MainExe_CallModeSwitch',
     'Call F99490 (mode switch) and jump to return'),

    ('LABEL_F475DF', 'MainExe_SetAllPartsMask',
     'Set all parts mask: mem[10357] = 0xFFFF'),

    ('LABEL_F475E8', 'MainExe_SequencerStop',
     'Sequencer stop routine: clear state, call F4365C/FC793D/F439B7, reset display'),

    ('LABEL_F4760C', 'MainExe_SeqStopMode1',
     'Sequencer stop mode 1: call LABEL_F41954'),

    ('LABEL_F47612', 'MainExe_SeqStopFinish',
     'Finish sequencer stop: reset scroll, call FDE6F, F59AF3, update state'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')

    with open(src, 'rb') as f:
        content = f.read().decode('latin-1')

    renamed = 0
    for old_label, new_label, comment in RENAMES:
        if old_label + ':' not in content:
            print(f'  WARNING: {old_label} not found (as definition), skipping')
            continue

        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        new_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)

        if new_content != content:
            content = new_content
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:50s} ({refs} refs)')

    with open(src, 'wb') as f:
        f.write(content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in maincpu/kn5000_v10_program.s')


if __name__ == '__main__':
    main()
