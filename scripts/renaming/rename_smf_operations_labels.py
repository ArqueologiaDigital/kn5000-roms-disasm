#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in smf_operations.s (SMF load, save, naming).

Functions in this file:
  FmmSmfLoadTitleFunc   - SMF load title event handler (events 0x1C00007, 0x1C00013)
                          Progress state machine: 0=error, 1=success, 2=cancel, 5=partial
  FmmSmfSaveTitleFunc   - SMF save title event handler (event 0x1C00013)
  RenderSmfFilename     - Format 8-char SMF filename (replace 0x7E->0x5F, pad nulls with '_')
  SaveFileNameSmfFunc   - Save SMF filename (events 0x1E00086, 0x1E0003A, 0x1C0000B, 0x1E50004)
  SmfSeqToSongNumFunc   - Write sequence-to-song number (events 0x1C0000B, 0x1E50004)
  SmfSeqFromSongNumFunc - Write sequence-from-song number (events 0x1C0000B, 0x1E50004)
  SmfSeqSongNameFunc    - Dispatch song name query (events 0x1C0000B, 0x1E50004)
  SmfLoadAsFunc         - SMF load-as mode selection (events 0x1C0000B, 0x1E50004)
  TrimAndPadSmfFilename - Trim to printable chars, pad with spaces, null-terminate
  DisplaySmfFileList    - Draw 10 SMF file entries into list buffer
  ValidateSmfFilename   - Validate filename (reject all-spaces, check length limit)
  FmmSmfFileNameFunc    - Main SMF filename dialog handler (large event dispatcher)
  DisplaySmfSequenceList - Draw 10 SMF sequence entries into list buffer

Event code glossary (as used in this file):
  0x1C00001 = Init/Create        0x1C00002 = Close/Destroy
  0x1C00007 = OK (confirm)       0x1C0000A = Wait/Continue
  0x1C0000B = Show/Activate      0x1C0000F = Action/Select
  0x1C00013 = Progress update    0x1C00017 = Scroll Up
  0x1C00018 = Scroll Down        0x1C50000 = Cancel State
  0x1C50001 = OK State           0x1E0003A = Text Change
  0x1E00086 = Apply              0x1E50002 = List Selection
  0x1E50004 = Selection confirm

Cross-reference check: no LABEL_F8D* or LABEL_F8E* symbols are referenced from
other files in maincpu/file_io/. All labels are local to smf_operations.s.

Uses binary I/O with ascii encoding (file is pure ASCII).
"""

import os
import re

# Renames: (old_label, new_label, brief_comment)
RENAMES = [
    # -------------------------------------------------------------------------
    # FmmSmfLoadTitleFunc  (lines 17-161)
    # Entry: xbc=event code, xde=parameter
    # -------------------------------------------------------------------------
    ('LABEL_F8DBA6', 'SmfLoad_DispatchState',
     'Dispatch on load-state value: 0=cancel, 1=success, 2=error-detail, 5=abort-partial'),
    ('LABEL_F8DBD3', 'SmfLoad_CheckFileCount',
     'State default: check file count (34052); if 0 fall through to check slot count'),
    ('LABEL_F8DBEF', 'SmfLoad_CheckSlotCount',
     'Check slot count (34050); if 0 or mode=97 go to wait; else send close event'),
    ('LABEL_F8DC16', 'SmfLoad_AbortPartial',
     'State 5 (abort partial): dismiss dialog, hide spinner, call abort handler 0xF99490'),
    ('LABEL_F8DC5A', 'SmfLoad_ErrorCancel',
     'State 2 (cancel/error): dismiss dialog, return code 0x7D'),
    ('LABEL_F8DC70', 'SmfLoad_Success',
     'State 1 (success): reset progress, hide spinner, call handler, set save-status=2'),
    ('LABEL_F8DCB5', 'SmfLoad_CallStatusDisplay',
     'Call status display helper (LABEL_F994BD), then fall to return'),
    ('LABEL_F8DCBB', 'SmfLoad_SendWait',
     'Dismiss dialog, send wait event 0x1C0000A, fall to return'),
    ('LABEL_F8DCDD', 'SmfLoad_CancelCleanup',
     'Event 0x1C00013 xde=3 (abort): call CancelOperationCleanup'),
    ('LABEL_F8DCE2', 'SmfLoad_HandleOk',
     'Event 0x1C00007 (OK confirm): check xde=0xF, dispatch sub-code via 36148'),
    ('LABEL_F8DCF6', 'SmfLoad_OkReturnCode',
     'Sub-code != 7: return code 0x60 via F99490'),
    ('LABEL_F8DCF9', 'SmfLoad_CallHandler',
     'Call 0xF99490 with wa = handler code'),
    ('LABEL_F8DCFD', 'SmfLoad_Return',
     'Common exit: xhl=0, ret'),

    # -------------------------------------------------------------------------
    # FmmSmfSaveTitleFunc  (lines 163-201)
    # -------------------------------------------------------------------------
    ('LABEL_F8DD4D', 'SmfSave_SendWait',
     'Dismiss dialog, send wait event 0x1C0000A'),
    ('LABEL_F8DD6F', 'SmfSave_CancelCleanup',
     'Event 0x1C00013 xde=3 (abort): call CancelOperationCleanup'),
    ('LABEL_F8DD72', 'SmfSave_Return',
     'Common exit: xhl=0, ret'),

    # -------------------------------------------------------------------------
    # RenderSmfFilename  (lines 203-237)
    # Internal helper — no events
    # -------------------------------------------------------------------------
    ('LABEL_F8DD86', 'RenderSmf_CheckSeparator',
     'Loop body: check char at index; if ix%8==0 insert separator 0x5F'),
    ('LABEL_F8DD95', 'RenderSmf_IncIndex',
     'Increment ix (slot index counter)'),
    ('LABEL_F8DD97', 'RenderSmf_LoopCheck',
     'Loop head: compare ix vs 8; exit if >= 8, else fetch char and continue'),
    ('LABEL_F8DDA8', 'RenderSmf_PadCheck',
     'After main loop: if ix < 8 still has slots to pad'),
    ('LABEL_F8DDAE', 'RenderSmf_PadLoop',
     'Padding loop: write 0x5F to remaining slots until ix == 8'),

    # -------------------------------------------------------------------------
    # SaveFileNameSmfFunc  (lines 239-304)
    # Entry: xbc=event, xde=parameter, xwa=workspace pointer
    # -------------------------------------------------------------------------
    ('LABEL_F8DDF2', 'SaveFN_HandleActivate',
     'Event 0x1C0000B (show): clear first byte, copy name into field, call forward event'),
    ('LABEL_F8DE1C', 'SaveFN_HandleTextChange',
     'Event 0x1E0003A (text change): copy name, render 8-char filename, send apply event'),
    ('LABEL_F8DE42', 'SaveFN_SendEvent',
     'Call event dispatch 0xFA9D58 then fall to return'),
    ('LABEL_F8DE48', 'SaveFN_HandleApply',
     'Event 0x1E00086 (apply): copy from field, render filename, update display name'),
    ('LABEL_F8DE74', 'SaveFN_Return',
     'Common exit: xhl=0, pop xiz, adjust stack, ret'),

    # -------------------------------------------------------------------------
    # SmfSeqToSongNumFunc  (lines 306-337)
    # -------------------------------------------------------------------------
    ('LABEL_F8DE91', 'SeqToSong_BuildEntry',
     'Event 0x1C0000B (show): build song number string, send to display slot 0x8094'),
    ('LABEL_F8DECD', 'SeqToSong_Return',
     'Common exit: xhl=0, pop xiz, ret'),

    # -------------------------------------------------------------------------
    # SmfSeqFromSongNumFunc  (lines 339-370)
    # -------------------------------------------------------------------------
    ('LABEL_F8DEE8', 'SeqFromSong_BuildEntry',
     'Event 0x1C0000B (show): build from-song number string, send to display slot 0x8118'),
    ('LABEL_F8DF24', 'SeqFromSong_Return',
     'Common exit: xhl=0, pop xiz, ret'),

    # -------------------------------------------------------------------------
    # SmfSeqSongNameFunc  (lines 372-393)
    # -------------------------------------------------------------------------
    ('LABEL_F8DF3E', 'SeqSongName_BuildEntry',
     'Event 0x1C0000B (show): call LABEL_F919E3 to get song name, dispatch 0x1C0000F'),
    ('LABEL_F8DF5A', 'SeqSongName_Return',
     'Common exit: xhl=0, ret'),

    # -------------------------------------------------------------------------
    # SmfLoadAsFunc  (lines 395-415)
    # -------------------------------------------------------------------------
    ('LABEL_F8DF73', 'SmfLoadAs_Apply',
     'Event 0x1C0000B (show): compute mode table offset, dispatch load-as type to 0x1C0000F'),
    ('LABEL_F8DF93', 'SmfLoadAs_Return',
     'Common exit: xhl=0, ret'),

    # -------------------------------------------------------------------------
    # TrimAndPadSmfFilename  (lines 417-461)
    # Internal helper — no events
    # -------------------------------------------------------------------------
    ('LABEL_F8DF9C', 'TrimPad_LoopBody',
     'Copy loop: fetch char from source; replace 0x7E with 0x5F'),
    ('LABEL_F8DFA5', 'TrimPad_CheckCtrl',
     'Not 0x7E: read output byte, if < 0x20 replace with space'),
    ('LABEL_F8DFAE', 'TrimPad_StoreChar',
     'Store (possibly replaced) char into output'),
    ('LABEL_F8DFB0', 'TrimPad_AdvancePointers',
     'Increment ix, xwa (output), xhl (source)'),
    ('LABEL_F8DFB6', 'TrimPad_LoopCheck',
     'Loop head: ix < bc and source char != 0 → continue copy loop'),
    ('LABEL_F8DFC0', 'TrimPad_PadCheck',
     'After copy: if ix < bc, need to pad remaining slots with spaces'),
    ('LABEL_F8DFC4', 'TrimPad_PadLoop',
     'Space-pad loop: write 0x20 while ix < bc'),
    ('LABEL_F8DFCE', 'TrimPad_NullTerminate',
     'Write null terminator at xwa, ret'),

    # -------------------------------------------------------------------------
    # DisplaySmfFileList  (lines 463-511)
    # Internal helper — no events
    # -------------------------------------------------------------------------
    ('LABEL_F8DFE2', 'DispFileList_LoopBody',
     'Loop: build file entry slot, copy filename, dispatch 0x1C0000F; repeat 10 times'),

    # -------------------------------------------------------------------------
    # ValidateSmfFilename  (lines 513-537)
    # Internal helper — no events
    # -------------------------------------------------------------------------
    ('LABEL_F8E04E', 'ValidateFN_CheckSpace',
     'Char is not null: if space, continue scan; else return l=0 (invalid)'),
    ('LABEL_F8E056', 'ValidateFN_AdvancePointer',
     'Space found: increment iy, hl (position counters)'),
    ('LABEL_F8E05A', 'ValidateFN_LoopHead',
     'Loop head: fetch next char; if null → success; if hl < bc → check char'),
    ('LABEL_F8E067', 'ValidateFN_ReturnValid',
     'End of string or length reached: return l=1 (valid)'),

    # -------------------------------------------------------------------------
    # FmmSmfFileNameFunc  (lines 539-1261)
    # Large event dispatcher for the SMF filename selection dialog
    # xiz holds the sub-event/action code dispatched after the initial event decode
    # -------------------------------------------------------------------------
    ('LABEL_F8E0C8', 'SmfFN_JumpTable',
     'Jump table data for jp_dri dispatch (6 sub-event entries for 0x1E50002+offset)'),
    ('LABEL_F8E11E', 'SmfFN_HandleActivate',
     'Event 0x1C0000B (show): align page start, draw file list'),
    ('LABEL_F8E12F', 'SmfFN_ReturnZero',
     'Unhandled / early exit: xhl=0, jump to epilogue'),
    ('LABEL_F8E134', 'SmfFN_NavSetup',
     'Events 0x1C00017/18 (scroll): send OK-state, save current index, check xiz for nav'),
    ('LABEL_F8E170', 'SmfFN_NavDown_WrapCheck',
     'Scroll down with wrap mode (36150=107): check if next index wraps past file count'),
    ('LABEL_F8E17B', 'SmfFN_NavDown_Apply',
     'Increment ix, store new index, update display'),
    ('LABEL_F8E180', 'SmfFN_NavUp',
     'Event 0x1C00017 (scroll up): decrement ix if > 0, update display'),
    ('LABEL_F8E192', 'SmfFN_PageUp',
     'xiz=1 (page up): if ix >= 10 subtract 10, update display; else return zero'),
    ('LABEL_F8E1AE', 'SmfFN_PageDown',
     'xiz=2 (page down): add 10 to ix, check bounds, update display'),
    ('LABEL_F8E205', 'SmfFN_PageDown_WrapCheck',
     'Page down with wrap (36150=107): check if new page exceeds file count'),
    ('LABEL_F8E20D', 'SmfFN_PageDown_Add10',
     'Page down: add 10 to ix unconditionally'),
    ('LABEL_F8E211', 'SmfFN_StoreIndex',
     'Store updated index to 33196, load hl=ix, jump to update display'),
    ('LABEL_F8E21A', 'SmfFN_PageDown_ClampCheck',
     'Page down clamp: verify new page is within valid range'),
    ('LABEL_F8E23C', 'SmfFN_HandleSave',
     'xiz=3 (save/rename): open progress, read filename from field, write to SMF slot'),
    ('LABEL_F8E2AC', 'SmfFN_Save_WriteSlot',
     'Trim/pad filename, write to AB000 slot area, copy to 00F180 if secondary slot'),
    ('LABEL_F8E2F3', 'SmfFN_Save_Finish',
     'Dismiss dialog, trigger save result, update save status byte at 32578'),
    ('LABEL_F8E320', 'SmfFN_Save_NoAltSlot',
     'No secondary slot (61854==0): use wa=1 for handler'),
    ('LABEL_F8E322', 'SmfFN_Save_CallResult',
     'Call result handler (LABEL_F99463), send completion, send spinner-off'),
    ('LABEL_F8E348', 'SmfFN_HandleOpen',
     'xiz=4 (open): check USB present; if present open progress and execute load'),
    ('LABEL_F8E3A6', 'SmfFN_Open_Execute',
     'Execute open: load file, update status byte, signal progress, dismiss dialog'),
    ('LABEL_F8E41B', 'SmfFN_HandleOpen2',
     'xiz=0x32 (open variant 2): same as xiz=4 open path'),
    ('LABEL_F8E4A9', 'SmfFN_HandleDelete',
     'xiz=5 (delete): check USB present; if present confirm then delete'),
    ('LABEL_F8E4D9', 'SmfFN_Delete_Execute',
     'Execute delete via LABEL_F88B22, update count at 34052, adjust current index'),
    ('LABEL_F8E537', 'SmfFN_Delete_AdjustIndex',
     'Post-delete: if current index > new count, decrement and save back'),
    ('LABEL_F8E53C', 'SmfFN_HandleDelete2',
     'xiz=0x33 (delete variant 2): same as xiz=5 delete path'),
    ('LABEL_F8E5A2', 'SmfFN_Delete2_AdjustIndex',
     'Post-delete2: adjust current index down if past end'),
    ('LABEL_F8E5A5', 'SmfFN_CallStatusDisplayAndExit',
     'Call status display (LABEL_F994BD), jump to common return'),
    ('LABEL_F8E5AC', 'SmfFN_IgnoredEvents',
     'xiz=0xA/B/C/D (ignored events): fall through to return'),
    ('LABEL_F8E5F2', 'SmfFN_SetScrollDir0',
     'Set scroll-direction flag 35138=0 (down/right), jump to return'),
    ('LABEL_F8E5FA', 'SmfFN_HandleScrollFlag1',
     'xiz=0x15: if scroll-up event, set direction flag 35138=1'),
    ('LABEL_F8E620', 'SmfFN_LoadAs_Wrap',
     'Load-as mode reached max (3): wrap back to 0'),
    ('LABEL_F8E62F', 'SmfFN_LoadAs_Apply',
     'Apply new load-as mode: call SmfLoadAsFunc with 0x1C0000B'),
    ('LABEL_F8E635', 'SmfFN_HandleScrollFlag2',
     'xiz=0x16: if scroll-up event, set track-enable flag 35146=1'),
    ('LABEL_F8E650', 'SmfFN_SetTrackFlag0',
     'Set track-enable flag 35146=0 (scroll-down), jump to return'),
    ('LABEL_F8E658', 'SmfFN_HandleScrollFlag3',
     'xiz=0x17: if scroll-up event, set transpose flag 35148=1'),
    ('LABEL_F8E673', 'SmfFN_SetTransposeFlag0',
     'Set transpose flag 35148=0 (scroll-down), jump to return'),
    ('LABEL_F8E67B', 'SmfFN_HandleScrollFlag4',
     'xiz=0x18: if scroll-up event, set flag 35140=1'),
    ('LABEL_F8E693', 'SmfFN_SetFlag35140_0',
     'Set flag 35140=0 (scroll-down), jump to return'),
    ('LABEL_F8E69B', 'SmfFN_HandleSeqSongNum',
     'xiz=0x1E or 0x1F: increment/wrap song sequence number, dispatch seq-to/from-song'),
    ('LABEL_F8E6CF', 'SmfFN_SeqToSong_Wrap',
     'xiz=0x1E (seq-to-song): song index reached 10, wrap to 0'),
    ('LABEL_F8E6ED', 'SmfFN_HandleSeqFromSong',
     'xiz=0x1F: increment/wrap for seq-from-song, dispatch SeqFromSongNumFunc'),
    ('LABEL_F8E719', 'SmfFN_SeqFromSong_Wrap',
     'xiz=0x1F: song index reached 10, wrap to 0'),
    ('LABEL_F8E735', 'SmfFN_SeqSongName_Dispatch',
     'After seq number update: call SmfSeqSongNameFunc then return'),
    ('LABEL_F8E73A', 'SmfFN_HandleMedleyConfirm',
     'xiz=0x28: if save count != 0 and data ptr != 0, send close event 0x1C0000A'),
    ('LABEL_F8E759', 'SmfFN_DispatchEvent',
     'Call 0xFA9D58 with xwa/xbc/xde set by caller'),
    ('LABEL_F8E75D', 'SmfFN_UpdateDisplay',
     'Common update path: reload current index from 33196'),
    ('LABEL_F8E761', 'SmfFN_RefreshIfChanged',
     'If current index changed: refresh selection highlight and page'),
    ('LABEL_F8E7EF', 'SmfFN_RedrawPage',
     'Index moved to different page: call DisplaySmfFileList to redraw'),
    ('LABEL_F8E80A', 'SmfFN_UpdateFilenameField',
     'Update filename display field (mode 107): sync edit field with selected entry'),
    ('LABEL_F8E830', 'SmfFN_FetchFilename',
     'Fetch filename from list slot via LABEL_F89BF0'),
    ('LABEL_F8E845', 'SmfFN_WriteFilenameField',
     'Write rendered filename to edit field via LABEL_F892DB, then call SaveFileNameSmfFunc'),
    ('LABEL_F8E85B', 'SmfFN_SendOkState',
     'Send OK-state event (0x1C50001 xde=0), dismiss spinner'),
    ('LABEL_F8E8A7', 'SmfFN_DispatchFinalEvent',
     'Dispatch final event (0x1C50001 xde=0), fall to return zero'),
    ('LABEL_F8E8B4', 'SmfFN_Return',
     'Common exit: pop xiz, restore stack, ret'),

    # -------------------------------------------------------------------------
    # DisplaySmfSequenceList  (lines 1263-1311)
    # Internal helper — no events
    # -------------------------------------------------------------------------
    ('LABEL_F8E8C9', 'DispSeqList_LoopBody',
     'Loop: build sequence entry slot, copy name, dispatch 0x1C0000F; repeat 10 times'),
]

FILES_TO_SCAN = [
    ('maincpu/file_io/smf_operations.s', 'ascii'),
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
