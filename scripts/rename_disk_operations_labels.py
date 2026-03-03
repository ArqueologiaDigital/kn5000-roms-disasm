#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in disk_operations.s (disk/file operations).

Functions covered:
  FileCopyFunc       - File copy handler
    Events: 0x1C00018/17 (scroll down/up), 0x1C0000B (execute copy), 0x1E50004 (select)
    xiz=0: no-context navigation; xiz=8: copy confirm; xiz=0x32: copy execute
  FileRenameFunc     - File rename handler (non-SMF)
    Events: 0x1E00086 (apply/commit rename), 0x1E0003A (text change / compose name)
    Includes character-loop to pad name with underscores up to 6 chars
  FileRenameSmfFunc  - SMF file rename handler
    Same event structure as FileRenameFunc but 8-char names, uses SMF-specific helpers
  FmmFormatFunc      - Disk format handler (FMM = Floppy/Media Management)
    Events: 0x1C00007 (OK/start), 0x1C00013 (progress tick)
    Progress sub-events: xde=2 (init), xde=3 (cancel), xde=0xA/0xB/0xF (state)
  UtilityTtlJgFunc   - Utility title jump/go handler
    Event 0x1C00007 triggers title jump (calls LABEL_F8B36E with ids 0x7B/0x7C)
  FmmLoadTitleFunc   - Load title (song/style) handler
    Events: 0x1C00007 (OK confirm), 0x1C00013 (progress)
    Progress states via sub-dispatch; includes 8-slot iteration loop
  FmmSaveTitleFunc   - Save title handler
    Events: 0x1C00007 (OK confirm), 0x1C00013 (progress)
    Iterates 6+2 slots, saves metadata
  DiskNameFunc       - Disk name entry handler
    Events: 0x1E00086 (apply), 0x1E0003A (text change), 0x1C0000B (execute save)
    11-char name padded with underscores
  DiskInfoFunc       - Disk information display handler
    Event 0x1C0000B: compute used/free space, render size strings into display widget
  SongNameFunc       - Song name entry handler
    Event 0x1C0000B: load current song name from slot, trim trailing spaces
  SaveFileNameNumFunc - Save file number display handler
    Event 0x1C0000B: look up slot number, format into 0x8850 widget
  SaveFileNameFunc   - Save file name entry handler
    Events: 0x1E00086 (apply), 0x1E0003A (text change), 0x1C0000B (load current name)
    6-char name padded with underscores
  CurFileNameFunc    - Current filename display handler
    Event 0x1C0000B: look up current file name, forward to widget

Event codes (see also misc_ui.s for full table):
  0x1C00007 = OK/Confirm         0x1C0000B = Show/Activate/Execute
  0x1C00013 = Progress tick      0x1C00017 = Scroll Up
  0x1C00018 = Scroll Down        0x1E0003A = Text Change
  0x1E00086 = Apply/Commit       0x1E50004 = List Selection

Uses binary I/O to handle encoding safely.
No cross-file references: all labels in this file are internal to disk_operations.s.
"""

import os
import re

# Renames: (old_label, new_label, brief_comment)
RENAMES = [
    # --- FileCopyFunc (lines 18-232) ---
    # Event 0x1E50004 (list selection): store widget ref, compute item count
    # Event 0x1C00018/17 (scroll down/up): navigate the file list
    # Event 0x1C0000B (execute): copy the selected file

    ('LABEL_F8BBE8',  'FCopy_ScrollDown_Clamp',
     'Scroll down: position at max (0x13), store to 32614'),
    ('LABEL_F8BBF1',  'FCopy_ScrollNeg_Reset',
     'Position negative: reset 32612=0, 32614=1'),
    ('LABEL_F8BC00',  'FCopy_HandleExecute',
     'Event 0x1C0000B: setup copy op, call file helpers, dispatch 0x1C0000F'),
    ('LABEL_F8BC38',  'FCopy_HandleScroll',
     'Events 0x1C00018/17 (scroll): dispatch by xiz context (0=nav, else copy)'),
    ('LABEL_F8BC55',  'FCopy_ScrollDown_CheckMin',
     'Scroll down (0x18), xiz=0: re-read 32614, compare vs 32612 minimum'),
    ('LABEL_F8BC6B',  'FCopy_ScrollDown_RestoreOld',
     'Positions equal and at min: restore old position from xde'),
    ('LABEL_F8BC6F',  'FCopy_ScrollDown_Reload',
     'Reload 32614 into xwa for position check'),
    ('LABEL_F8BC73',  'FCopy_Scroll_Apply',
     'Position changed: issue copy-op setup and dispatch 0x1C0000F'),
    ('LABEL_F8BCAB',  'FCopy_ScrollUp_Adjust',
     'Scroll up (0x17), xiz=0: clamp position to max 0x13'),
    ('LABEL_F8BCBF',  'FCopy_ScrollUp_CheckMax',
     'Scroll up: re-read 32614 vs 32612, clamp or advance to 32BC73'),
    ('LABEL_F8BCD7',  'FCopy_HandleCopyContext',
     'xiz != 0: check for copy-confirm (xiz=8) or copy-execute (xiz=0x32)'),
    ('LABEL_F8BD19',  'FCopy_DispatchFA9D58',
     'Tail: call 0xFA9D58 event dispatcher, then fall to return'),
    ('LABEL_F8BD20',  'FCopy_CopyConfirm_Execute',
     'xiz=8, confirmed: show progress, run copy, send results, call 0xF99490'),
    ('LABEL_F8BD97',  'FCopy_CopyExecute',
     'xiz=0x32: show progress dialog, execute copy, send done events'),
    ('LABEL_F8BE14',  'FCopy_NotifyComplete',
     'Call LABEL_F994BD to signal completion'),
    ('LABEL_F8BE18',  'FCopy_Return',
     'Common exit: lds32 xhl,0, pop xiz, ret'),

    # --- FileRenameFunc (lines 234-335) ---
    # Event 0x1E0003A (text change / compose name): build padded name into buffer 0x8870
    # Event 0x1E00086 (apply/commit): execute rename, signal completion

    ('LABEL_F8BE5D',  'FRename_PadLoop_CheckChar',
     'Name pad loop: read char, check if padding position, write underscore if needed'),
    ('LABEL_F8BE6C',  'FRename_PadLoop_Advance',
     'Increment iy, fall into loop condition'),
    ('LABEL_F8BE6E',  'FRename_PadLoop_Cond',
     'Pad loop condition: continue while iy < 6 and char != 0'),
    ('LABEL_F8BE7D',  'FRename_PadLoop_Fill',
     'iy < 6: fill remaining positions with underscores (0x5F)'),
    ('LABEL_F8BE83',  'FRename_FillLoop',
     'Fill loop: store 0x5F via stib_dri, advance iy until iy=6'),
    ('LABEL_F8BE8F',  'FRename_PadDone',
     'Name padded to 6 chars: write null terminator at offset 6'),
    ('LABEL_F8BE95',  'FRename_TextChange_Error',
     'Text change: item count < 0 (no valid selection), load default name'),
    ('LABEL_F8BEA3',  'FRename_TextChange_SendApply',
     'Text change done: send 0x1E00086 apply event to parent dispatch'),
    ('LABEL_F8BEB6',  'FRename_HandleApply',
     'Event 0x1E00086 (apply): copy name, execute rename, signal progress'),
    ('LABEL_F8BF15',  'FRename_Return',
     'Common exit: lds32 xhl,0, pop xiz, inc 4 xsp, ret'),

    # --- FileRenameSmfFunc (lines 337-438) ---
    # Same structure as FileRenameFunc but SMF format: 8-char names, SMF helpers

    ('LABEL_F8BF5C',  'FRenameSmf_PadLoop_CheckChar',
     'SMF name pad loop: check char, write underscore if at padding slot'),
    ('LABEL_F8BF6B',  'FRenameSmf_PadLoop_Advance',
     'Increment iy, fall into loop condition'),
    ('LABEL_F8BF6D',  'FRenameSmf_PadLoop_Cond',
     'SMF pad loop condition: continue while iy < 8 and char != 0'),
    ('LABEL_F8BF7E',  'FRenameSmf_PadLoop_Fill',
     'iy < 8: fill remaining positions with underscores'),
    ('LABEL_F8BF86',  'FRenameSmf_FillLoop',
     'SMF fill loop: store 0x5F, advance iy until iy=8'),
    ('LABEL_F8BF94',  'FRenameSmf_PadDone',
     'SMF name padded to 8 chars: write null terminator at offset 8'),
    ('LABEL_F8BF9A',  'FRenameSmf_TextChange_Error',
     'Text change: item count < 0, load default SMF name from 0xEA06C6'),
    ('LABEL_F8BFA8',  'FRenameSmf_TextChange_SendApply',
     'SMF text change done: send 0x1E00086 apply event'),
    ('LABEL_F8BFBB',  'FRenameSmf_HandleApply',
     'Event 0x1E00086 (apply): copy name, apply SMF template, execute rename'),
    ('LABEL_F8C020',  'FRenameSmf_Return',
     'Common exit: lds32 xhl,0, pop xiz, inc 4 xsp, ret'),

    # --- FmmFormatFunc (lines 440-605) ---
    # Event 0x1C00007 (OK): confirm/start format operation
    # Event 0x1C00013 (progress tick): sub-dispatch on xde value
    #   xde=2: init phase; xde=3: cancel; xde=0xA: execute format;
    #   xde=0xB: check abort; xde=0xF: abort/cleanup

    ('LABEL_F8C06A',  'FmmFmt_InitPhase_CheckDrive',
     'Format init: read drive selection 34048, branch on drive type (2/3 vs other)'),
    ('LABEL_F8C076',  'FmmFmt_InitPhase_DriveType23',
     'Drive type 2 or 3: save drive, send start event 0x7B0036, clear 34046'),
    ('LABEL_F8C091',  'FmmFmt_InitPhase_OtherDrive',
     'Other drive type: send event 0x7B003F, set 34046=2'),
    ('LABEL_F8C0A6',  'FmmFmt_InitPhase_SetActive',
     'Set format-active flag 32620=1, jump to return'),
    ('LABEL_F8C0AE',  'FmmFmt_HandleCancel',
     'xde=3 (cancel): call CancelOperationCleanup, clear 34046 and 32620'),
    ('LABEL_F8C0BE',  'FmmFmt_HandleProgress',
     'Event 0x1C00013 tick: check active flag 32620, sub-dispatch on xde'),
    ('LABEL_F8C172',  'FmmFmt_FormatSuccess',
     'Format succeeded (iz >= 0): send done events 0x7B0036/0x7B0031, set 34046=1'),
    ('LABEL_F8C199',  'FmmFmt_ExecutePhase2',
     'a=2 (second pass): set drive=3, send 0x7B003F/0x7B0036, call FA9D58'),
    ('LABEL_F8C1C0',  'FmmFmt_HandleAbort',
     'xde=0xB (abort check): read abort state c, clear or confirm abort'),
    ('LABEL_F8C1D1',  'FmmFmt_AbortPhase2',
     'e=2 (abort phase 2): set drive=2, send 0x7B003F/0x7B0036'),
    ('LABEL_F8C1F6',  'FmmFmt_DispatchAndNotify',
     'Call 0xFA9D58, then fall into FmmFmt_NotifyComplete'),
    ('LABEL_F8C1FC',  'FmmFmt_HandleAbortFinal',
     'xde=0xF (final abort): call 0xF99490, clear active flag 32620'),
    ('LABEL_F8C205',  'FmmFmt_NotifyComplete',
     'Clear format state flag 34046=0'),
    ('LABEL_F8C20A',  'FmmFmt_Return',
     'Common exit: lds32 xhl,0, popw iz, ret'),

    # --- UtilityTtlJgFunc (lines 607-616) ---

    ('LABEL_F8C21F',  'UtilTtlJg_Return',
     'Common exit: lds32 xhl,0, ret'),

    # --- FmmLoadTitleFunc (lines 618-802) ---
    # Event 0x1C00007 (OK): finalize / confirm selection
    # Event 0x1C00013 (progress tick): state machine with sub-states in 34048
    #   State 1 = success+reset; State 0 = success; State 5 = cancel; else = loading

    ('LABEL_F8C28B',  'FmmLoadTtl_StateDispatch',
     'Progress tick: read 34048 state, dispatch to sub-handler'),
    ('LABEL_F8C2B8',  'FmmLoadTtl_CheckFileHandle',
     'State != 0/1/5: check file handle 34050; if 0 check SMF handle 34052'),
    ('LABEL_F8C2D4',  'FmmLoadTtl_CheckSmfHandle',
     'Check SMF file handle 34052; if ready and progress=100 close UI'),
    ('LABEL_F8C2FB',  'FmmLoadTtl_StateCancelLoad',
     'State 5 (cancel): dismiss UI, call 0xF99490, clear progress flag'),
    ('LABEL_F8C33F',  'FmmLoadTtl_StateIdle',
     'State 0 (idle/done): dismiss progress UI, send 0x7D tone event'),
    ('LABEL_F8C355',  'FmmLoadTtl_StateSuccess',
     'State 1 (success): reset progress, dismiss UI, play sound, set progress=2'),
    ('LABEL_F8C39A',  'FmmLoadTtl_NotifyComplete',
     'Call LABEL_F994BD to signal completion, jump to return'),
    ('LABEL_F8C3A1',  'FmmLoadTtl_LoadSlots',
     'Load: send close events, iterate 8 slots calling LABEL_F89321'),
    ('LABEL_F8C3E6',  'FmmLoadTtl_SlotLoop',
     'Slot iteration loop: load-to-berp, call LABEL_F89321, inc iz while < 8'),
    ('LABEL_F8C3FE',  'FmmLoadTtl_HandleScrollNav',
     'xde=9 (scroll nav): validate 32624, call 0xF89605 to set new position'),
    ('LABEL_F8C420',  'FmmLoadTtl_HandleCancelOp',
     'xde=3 (cancel): CancelOperationCleanup, send 0x610001/0x1E0007F event'),
    ('LABEL_F8C435',  'FmmLoadTtl_HandleOk',
     'Event 0x1C00007 (OK): check xde=0xF, play sound by font type'),
    ('LABEL_F8C449',  'FmmLoadTtl_Ok_DefaultSound',
     'Font type != 7: play sound code 0x60'),
    ('LABEL_F8C44C',  'FmmLoadTtl_PlaySound',
     'Call 0xF99490 with sound code in wa'),
    ('LABEL_F8C450',  'FmmLoadTtl_Return',
     'Common exit: lds32 xhl,0, popw iz, ret'),

    # --- FmmSaveTitleFunc (lines 804-879) ---
    # Event 0x1C00007 (OK): finalize save or cancel
    # Event 0x1C00013 (progress tick): iterate slots, write metadata

    ('LABEL_F8C4AE',  'FmmSaveTtl_CheckFont',
     'Progress tick: check font flag 36151 (102=skip iterate), branch'),
    ('LABEL_F8C4B7',  'FmmSaveTtl_SlotLoop',
     'Iterate 6 slots: ldto_berp, call LABEL_F8937F, inc iz while iz<6'),
    ('LABEL_F8C4E2',  'FmmSaveTtl_CommitSave',
     'Commit: close progress UI, send 0xFFFFFFFF/0x1C0000A event, call FA9D58'),
    ('LABEL_F8C500',  'FmmSaveTtl_HandleCancel',
     'xde=3 (cancel): CancelOperationCleanup, send 0x670001/0x1E0007F event'),
    ('LABEL_F8C50F',  'FmmSaveTtl_DispatchAndReturn',
     'Call 0xFA9D58, fall to return'),
    ('LABEL_F8C515',  'FmmSaveTtl_HandleOk',
     'Event 0x1C00007 (OK): check xde=0xF, play sound code 0x60'),
    ('LABEL_F8C524',  'FmmSaveTtl_Return',
     'Common exit: lds32 xhl,0, popw iz, ret'),

    # --- DiskNameFunc (lines 881-973) ---
    # Event 0x1E0003A (text change): compose 11-char name, padded with underscores
    # Event 0x1E00086 (apply): execute disk rename
    # Event 0x1C0000B (execute): read current disk name into buffer

    ('LABEL_F8C56C',  'DiskName_TextChange',
     'Event 0x1E0003A: load current name, build display name, pad to 11 chars'),
    ('LABEL_F8C594',  'DiskName_PadLoop_CheckChar',
     'Disk name pad loop: read char, check if needs underscore padding'),
    ('LABEL_F8C5A8',  'DiskName_PadLoop_Advance',
     'Increment iy, fall into loop condition'),
    ('LABEL_F8C5AA',  'DiskName_PadLoop_Cond',
     'Pad loop condition: continue while iy < 11 and char != 0'),
    ('LABEL_F8C5BA',  'DiskName_PadLoop_Fill',
     'iy < 11: fill remaining positions with underscores'),
    ('LABEL_F8C5C2',  'DiskName_FillLoop',
     'Fill loop: store 0x5F, advance iy until iy=11'),
    ('LABEL_F8C5D0',  'DiskName_PadDone',
     'Disk name padded to 11 chars: write null at +11, set up 0x1E00086 dispatch'),
    ('LABEL_F8C5DC',  'DiskName_Dispatch',
     'Call 0xFA9D58 event dispatcher, jump to return'),
    ('LABEL_F8C5E2',  'DiskName_HandleApply',
     'Event 0x1E00086 (apply): copy name, save disk, signal progress/complete'),
    ('LABEL_F8C609',  'DiskName_Return',
     'Common exit: lds32 xhl,0, pop xiz, inc 4 xsp, ret'),

    # --- DiskInfoFunc (lines 975-1084) ---
    # Event 0x1C0000B: compute disk usage, build info strings, send to display widget

    ('LABEL_F8C636',  'DiskInfo_ReadDriveType',
     'Read drive type 34048; branch on type: 2/3=read capacity, 0/1=reset'),
    ('LABEL_F8C64A',  'DiskInfo_ReadCapacity',
     'Drive type 2 or 3: call 0xF8953B (total), LABEL_F89573 (free)'),
    ('LABEL_F8C65A',  'DiskInfo_ResetCapacity',
     'Drive type 0 or 1: call ResetProgressIndication, zero capacity'),
    ('LABEL_F8C65D',  'DiskInfo_ZeroCapacity',
     'Zero out stack locals for total and free capacity'),
    ('LABEL_F8C665',  'DiskInfo_ComputePercent',
     'Compute free%: if total>0 compute (total-used)*100/total, else 0'),
    ('LABEL_F8C68F',  'DiskInfo_ZeroPercent',
     'Total capacity <= 0: store 0 as percent'),
    ('LABEL_F8C694',  'DiskInfo_RenderStrings',
     'Render: convert capacity to KB, format used/free/percent into widget 0x87CE'),
    ('LABEL_F8C735',  'DiskInfo_Return',
     'Common exit: lds32 xhl,0, pop xiz, lda xsp return, ret'),

    # --- SongNameFunc (lines 1086-1140) ---
    # Event 0x1C0000B: load song name from slot, trim trailing spaces

    ('LABEL_F8C781',  'SongName_TrimLoop_ZeroChar',
     'Trailing-space trim loop body: write 0 at xde, decrement xde'),
    ('LABEL_F8C786',  'SongName_TrimLoop_Cond',
     'Trim loop condition: read char at xde, continue if space and above base'),
    ('LABEL_F8C791',  'SongName_TrimDone',
     'Trim done (non-space or reached base): call LABEL_F8929D to finalize name'),
    ('LABEL_F8C797',  'SongName_NoSlot',
     'iz < 0 (no valid slot): store 0 at first byte of name buffer 34830'),
    ('LABEL_F8C79C',  'SongName_SendDisplay',
     'Send 0x1C0000F event to display widget 0x880E'),
    ('LABEL_F8C7AD',  'SongName_Return',
     'Common exit: lds32 xhl,0, popw iz, inc 8 xsp, ret'),

    # --- SaveFileNameNumFunc (lines 1142-1175) ---
    # Event 0x1C0000B: look up save slot number, format into widget 0x8850

    ('LABEL_F8C7E6',  'SaveFileNum_NoSlot',
     'iz < 0 (no valid slot): store 0 at name buffer 34896'),
    ('LABEL_F8C7EB',  'SaveFileNum_SendDisplay',
     'Send 0x1C0000F event to display widget 0x8850'),
    ('LABEL_F8C7FC',  'SaveFileNum_Return',
     'Common exit: lds32 xhl,0, popw iz, inc 4 xsp, ret'),

    # --- SaveFileNameFunc (lines 1177-1260) ---
    # Event 0x1C0000B: load current save filename into edit buffer
    # Event 0x1E0003A (text change): compose 6-char name, pad with underscores
    # Event 0x1E00086 (apply): commit save filename via 0xF892C2

    ('LABEL_F8C84A',  'SaveFileName_TextChange',
     'Event 0x1E0003A: load slot, compose name into 34896 buffer, pad to 6'),
    ('LABEL_F8C869',  'SaveFileName_PadLoop_CheckChar',
     'Save name pad loop: read char, write underscore if padding position'),
    ('LABEL_F8C878',  'SaveFileName_PadLoop_Advance',
     'Increment iy, fall into loop condition'),
    ('LABEL_F8C87A',  'SaveFileName_PadLoop_Cond',
     'Pad loop condition: continue while iy < 6 and char != 0'),
    ('LABEL_F8C889',  'SaveFileName_PadLoop_Fill',
     'iy < 6: fill remaining positions with underscores'),
    ('LABEL_F8C88F',  'SaveFileName_FillLoop',
     'Fill loop: store 0x5F, advance iy until iy=6'),
    ('LABEL_F8C89B',  'SaveFileName_PadDone',
     'Name padded to 6 chars: write null at +6, set up 0x1E00086 dispatch'),
    ('LABEL_F8C8A7',  'SaveFileName_Dispatch',
     'Call 0xFA9D58 event dispatcher, jump to return'),
    ('LABEL_F8C8AD',  'SaveFileName_HandleApply',
     'Event 0x1E00086 (apply): copy name from event, call 0xF892C2 to commit'),
    ('LABEL_F8C8C2',  'SaveFileName_Return',
     'Common exit: lds32 xhl,0, pop xiz, inc 4 xsp, ret'),

    # --- CurFileNameFunc (lines 1262-1296) ---
    # Event 0x1C0000B: look up current file name, forward to widget 0x8870

    ('LABEL_F8C8FD',  'CurFileName_NoSlot',
     'iz < 0 (no valid slot): store 0 at name buffer 34928'),
    ('LABEL_F8C902',  'CurFileName_SendDisplay',
     'Send 0x1C0000F event to display widget 0x8870'),
    ('LABEL_F8C913',  'CurFileName_Return',
     'Common exit: lds32 xhl,0, popw iz, inc 4 xsp, ret'),
]

# Only disk_operations.s needs to be updated (no cross-file references confirmed).
FILES_TO_SCAN = [
    ('maincpu/file_io/disk_operations.s', 'ascii'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    for rel_path, encoding in FILES_TO_SCAN:
        src = os.path.join(base, rel_path)
        with open(src, 'rb') as f:
            content = f.read().decode(encoding)

        renamed = 0
        for old_label, new_label, comment in RENAMES:
            refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
            if refs == 0:
                print(f'  WARNING: {old_label} not found in {rel_path}, skipping')
                continue

            content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:45s} ({refs} refs in {rel_path})')

        with open(src, 'wb') as f:
            f.write(content.encode(encoding))

        if renamed > 0:
            print(f'  Renamed {renamed} labels in {rel_path}')

    print(f'\nDone.')


if __name__ == '__main__':
    main()
