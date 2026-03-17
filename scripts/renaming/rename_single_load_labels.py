#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in single_load.s (and cross-referencing files).

Functions in single_load.s:

  SingleLoadModeFunc       - Mode widget event handler (show/select)
  SingleLoadDstBankFunc    - Destination bank widget event handler
  SingleLoadDstMemFunc     - Destination memory widget event handler
  SingleLoadSrcBankFunc    - Source bank widget event handler
  SingleLoadSrcMemFunc     - Source memory widget event handler
  SingleLoadSrcFunc        - Source file list event handler (scroll/show/select)
  SingleLoadDstFunc        - Destination file list event handler (scroll/show/select/confirm)
  CmpSingleLoadSrcFunc     - Composer single-load source widget handler
  CmpSingleLoadDstFunc     - Composer single-load destination widget handler
  CmpSingleLoadFileFunc    - Composer single-load file widget handler
  FmmCmpSingleLoadFunc     - Composer single-load progress event handler (state machine)
  LABEL_F919E3             - Utility: build slot label string ("N:") for given slot index

Event code conventions used here:
  0x1C0000B = Show/Activate    0x1C0000F = Action/Confirm
  0x1C00013 = Progress update  0x1C00017 = Scroll Up
  0x1C00018 = Scroll Down      0x1E50002 = List refresh
  0x1E50003 = Capture/release  0x1E50004 = Selection change

Cross-file references:
  LABEL_F919E3 is called from maincpu/file_io/medley.s and
  maincpu/file_io/smf_operations.s — those files are updated too.

Notes:
  - LABEL_F8ECB3 (WP_ScanAvailability) and LABEL_F8ED83 (WP_FindNextSlot) were
    already renamed by rename_wallpaper_labels.py; they are not repeated here.
  - LABEL_F8F0B9 and LABEL_F90075 are entries into large .byte blocks that
    encode functions not yet decoded as native mnemonics; they are named
    descriptively based on their position and the functions they reside in.

Uses binary I/O with ASCII encoding (file is pure ASCII).
"""

import os
import re

# Renames: (old_label, new_label, brief_comment)
RENAMES = [
    # SingleLoadModeFunc (lines 20-41)
    ('LABEL_F8EF70', 'SLMode_HandleShow',
     'Event 0x1C0000B (show): lookup mode offset, dispatch show to sub-widget'),
    ('LABEL_F8EF90', 'SLMode_Return',
     'Common exit: return XHL=0'),

    # SingleLoadDstBankFunc (lines 42-62)
    ('LABEL_F8EFA9', 'SLDstBank_HandleShow',
     'Event 0x1C0000B (show): lookup bank offset, dispatch show to sub-widget'),
    ('LABEL_F8EFC9', 'SLDstBank_Return',
     'Common exit: return XHL=0'),

    # SingleLoadDstMemFunc (lines 64-95)
    ('LABEL_F8EFE2', 'SLDstMem_HandleShow',
     'Event 0x1C0000B (show): load mem widget ptr, branch by bank/mem type'),
    ('LABEL_F8F003', 'SLDstMem_ShowFromBank',
     'Bank-type path: index into bank table, dispatch show'),
    ('LABEL_F8F016', 'SLDstMem_DispatchShow',
     'Call widget dispatch (0xFA9D58)'),
    ('LABEL_F8F01A', 'SLDstMem_Return',
     'Common exit: return XHL=0'),

    # SingleLoadSrcBankFunc (lines 97-128)
    ('LABEL_F8F033', 'SLSrcBank_HandleShow',
     'Event 0x1C0000B (show): load bank widget ptr, branch by bank type'),
    ('LABEL_F8F055', 'SLSrcBank_ShowFromIndex',
     'Index-based path: compute bank table index, dispatch show'),
    ('LABEL_F8F064', 'SLSrcBank_DispatchShow',
     'Call widget dispatch (0xFA9D58)'),
    ('LABEL_F8F068', 'SLSrcBank_Return',
     'Common exit: return XHL=0'),

    # SingleLoadSrcMemFunc (lines 130-163)
    ('LABEL_F8F081', 'SLSrcMem_HandleShow',
     'Event 0x1C0000B (show): load mem widget ptr, branch by bank/mem conditions'),
    ('LABEL_F8F099', 'SLSrcMem_ShowDirect',
     'Direct path: use flat mem widget, dispatch show'),
    ('LABEL_F8F0A3', 'SLSrcMem_ShowFromIndex',
     'Index-based path: compute mem table index, dispatch show'),
    ('LABEL_F8F0B2', 'SLSrcMem_DispatchShow',
     'Call widget dispatch (0xFA9D58)'),
    ('LABEL_F8F0B6', 'SLSrcMem_Return',
     'Common exit: return XHL=0'),

    # .byte block at F8F0B9 (lines 165+) — entry into undecoded function body
    # (sits between SLSrcMemFunc and SingleLoadSrcFunc; no named function label)
    ('LABEL_F8F0B9', 'SLSrcBankList_FuncBody',
     '.byte block: body of source bank list widget function (not yet decoded)'),

    # SingleLoadSrcFunc (lines 615-776)
    ('LABEL_F8FEEF', 'SLSrc_HandleShow',
     'Event 0x1C0000B (show): refresh list, lookup src offset, call child handler'),
    ('LABEL_F8FF27', 'SLSrc_HandleScroll',
     'Events 0x1C00017/18 (scroll): branch by xiz mode (5 or 6)'),
    ('LABEL_F8FF43', 'SLSrc_ScrollMode5_Prev',
     'Mode 5 scroll up: send selection -1 (xde=0xFFFFFFFF)'),
    ('LABEL_F8FF51', 'SLSrc_ScrollMode5_Dispatch',
     'Mode 5: dispatch selection event, call child handler'),
    ('LABEL_F8FF78', 'SLSrc_ScrollMode6',
     'Mode 6 scroll: branch by direction and memory type'),
    ('LABEL_F8FF9B', 'SLSrc_ScrollMode6_NoStep',
     'Mode 6: send selection unchanged (xde=0xFFFFFFFF)'),
    ('LABEL_F8FFA9', 'SLSrc_ScrollMode6_Dispatch',
     'Mode 6: dispatch selection event, call child handler'),
    ('LABEL_F8FFD0', 'SLSrc_ScrollMode7',
     'Mode 7 scroll: refresh list, call child handler'),
    ('LABEL_F9000C', 'SLSrc_ScrollMode8',
     'Mode 8 scroll: refresh list, call child handler'),
    ('LABEL_F90044', 'SLSrc_ScrollMode40',
     'Mode 0x28 scroll: lookup src offset table, call child handler'),
    ('LABEL_F90068', 'SLSrc_Return',
     'Common exit: return XHL=0'),
    ('LABEL_F9006C', 'SLSrc_ReturnCapture',
     'Event 0x1E50003 (capture/release): return XHL=0xFFFFFFFF'),
    ('LABEL_F90071', 'SLSrc_Epilogue',
     'Common epilogue: pop xiz, inc 4 xsp, ret'),

    # .byte block at F90075 (lines 778+) — undecoded function between SLSrcFunc and SLDstFunc
    ('LABEL_F90075', 'SLDstBankList_FuncBody',
     '.byte block: body of destination bank list widget function (not yet decoded)'),

    # SingleLoadDstFunc (lines 1209-1607)
    ('LABEL_F90E2B', 'SLDst_ShowHide_Internal',
     'Event 0x1E50004, bank=internal: send hide 0x9C widget event'),
    ('LABEL_F90E37', 'SLDst_ShowHide_Dispatch',
     'Dispatch show/hide 0x9C event, refresh list, check floppy'),
    ('LABEL_F90E63', 'SLDst_ClearFloppyFlag',
     'No floppy found or floppy check failed: clear floppy flag (35338=0)'),
    ('LABEL_F90E68', 'SLDst_Return',
     'Common exit: return XHL=0, jump to epilogue'),
    ('LABEL_F90E6D', 'SLDst_HandleShow',
     'Event 0x1C0000B (show): dispatch show to all sub-widgets, refresh list'),
    ('LABEL_F90EEA', 'SLDst_HandleConfirm',
     'Event 0x1C0000F (confirm): refresh list, call child dispatch with show event'),
    ('LABEL_F90F21', 'SLDst_HandleScroll',
     'Events 0x1C00017/18 (scroll): branch by xiz mode (3 or 4)'),
    ('LABEL_F90FAA', 'SLDst_ScrollMode4',
     'Mode 4: find next wallpaper slot, update show/hide widget, redispatch show'),
    ('LABEL_F90FD3', 'SLDst_ScrollMode4_Internal',
     'Mode 4, bank=internal: send hide 0x9C event (xde=0)'),
    ('LABEL_F90FDF', 'SLDst_ScrollMode4_Dispatch',
     'Mode 4: dispatch 0x9C event, call mode/bank/mem/dst sub-handlers with show'),
    ('LABEL_F9106C', 'SLDst_ScrollMode3_CallSrcMem',
     'After scroll mode 3 show: call SingleLoadSrcMemFunc with show event'),
    ('LABEL_F91072', 'SLDst_ScrollDispatch',
     'Scroll fallthrough: dispatch remaining scroll modes to child handler'),
    ('LABEL_F910DF', 'SLDst_Scroll_ChildReturn',
     'Return after child scroll dispatch'),
    ('LABEL_F91124', 'SLDst_Scroll_SubMode',
     'Scroll sub-mode dispatch block'),
    ('LABEL_F9115A', 'SLDst_Scroll_SubMode2',
     'Scroll sub-mode 2 dispatch'),
    ('LABEL_F911A0', 'SLDst_Scroll_SubMode3',
     'Scroll sub-mode 3 dispatch'),
    ('LABEL_F911D6', 'SLDst_Scroll_SubMode4',
     'Scroll sub-mode 4 dispatch'),
    ('LABEL_F91208', 'SLDst_Scroll_SubMode5',
     'Scroll sub-mode 5 dispatch'),
    ('LABEL_F91245', 'SLDst_Scroll_SubMode6',
     'Scroll sub-mode 6 dispatch'),
    ('LABEL_F91283', 'SLDst_ReturnCapture',
     'Event 0x1E50003 (capture/release): return XHL=0xFFFFFFFF'),
    ('LABEL_F91288', 'SLDst_Epilogue',
     'Common epilogue: pop xiz, inc 8 xsp, ret'),

    # CmpSingleLoadSrcFunc (lines 1609-1772)
    ('LABEL_F912D6', 'CmpSrc_HandleShow',
     'Event 0x1C0000B (show): refresh list, lookup src offset, call child handler'),
    ('LABEL_F9130B', 'CmpSrc_HandleScroll',
     'Events 0x1C00017/18 (scroll): branch by xde mode (5 or 6)'),
    ('LABEL_F91348', 'CmpSrc_ScrollMode6',
     'Mode 6 scroll: branch by direction (35322), send selection 3 or -1'),
    ('LABEL_F9138C', 'CmpSrc_ScrollMode6_NoStep',
     'Mode 6: send selection unchanged (xde=0xFFFFFFFF)'),
    ('LABEL_F913C1', 'CmpSrc_ScrollMode7',
     'Mode 7 scroll: refresh list, call child handler'),
    ('LABEL_F91400', 'CmpSrc_ScrollMode8',
     'Mode 8 scroll, fwd dir: refresh list, call child handler'),
    ('LABEL_F91442', 'CmpSrc_ScrollMode40',
     'Mode 0x28 scroll: lookup src offset table, call child handler'),
    ('LABEL_F91469', 'CmpSrc_Return',
     'Common exit: return XHL=0'),
    ('LABEL_F9146D', 'CmpSrc_ReturnCapture',
     'Event 0x1E50003 (capture/release): return XHL=0xFFFFFFFF'),
    ('LABEL_F91472', 'CmpSrc_Epilogue',
     'Common epilogue: pop xiz, inc 4 xsp, ret'),

    # CmpSingleLoadDstFunc (lines 1774-2016)
    ('LABEL_F914C8', 'CmpDst_HandleShow',
     'Event 0x1C0000B (show): dispatch show to src/dst sub-widgets, refresh list'),
    ('LABEL_F9153A', 'CmpDst_HandleScroll',
     'Events 0x1C00017/18 (scroll): branch by xde mode (3=mem scroll, others)'),
    ('LABEL_F915BF', 'CmpDst_ScrollModeA',
     'Mode 0xA scroll (bank!=4): open progress dialog, execute load, show result'),
    ('LABEL_F9162C', 'CmpDst_ScrollMode7',
     'Mode 7 scroll: refresh dst list, call child handler'),
    ('LABEL_F9166A', 'CmpDst_ScrollMode8',
     'Mode 8 scroll: branch by direction (35322), send selection 3 or -1'),
    ('LABEL_F916AF', 'CmpDst_ScrollMode8_NoStep',
     'Mode 8: send selection unchanged (xde=0xFFFFFFFF), call child handler'),
    ('LABEL_F916E0', 'CmpDst_ScrollMode5',
     'Mode 5 scroll: refresh dst list (xde=-1), call child handler'),
    ('LABEL_F9171C', 'CmpDst_ScrollMode6',
     'Mode 6 scroll, fwd dir: refresh dst list (xde=-1), call child handler'),
    ('LABEL_F9175D', 'CmpDst_Return',
     'Common exit: return XHL=0'),
    ('LABEL_F91761', 'CmpDst_ReturnCapture',
     'Event 0x1E50003 (capture/release): return XHL=0xFFFFFFFF'),
    ('LABEL_F91766', 'CmpDst_Epilogue',
     'Common epilogue: pop xiz, inc 8 xsp, ret'),

    # CmpSingleLoadFileFunc (lines 2018-2138)
    ('LABEL_F917A8', 'CmpFile_Selection_Clamp',
     'Event 0x1E50004: clamp page index to 0 if negative, then refresh list'),
    ('LABEL_F917B8', 'CmpFile_HandleShow',
     'Event 0x1C0000B (show): branch by bank mode (2=floppy or default)'),
    ('LABEL_F917D0', 'CmpFile_ShowDefault',
     'Bank != 2: use default directory ptr at 0xEA0A52'),
    ('LABEL_F917D5', 'CmpFile_ShowDraw',
     'Draw file list items, send confirm event 0x1C0000F to widget'),
    ('LABEL_F917F9', 'CmpFile_ShowDispatch',
     'Call widget dispatch (0xFA9D58)'),
    ('LABEL_F91800', 'CmpFile_HandleScroll',
     'Events 0x1C00017/18 (scroll up/down): increment or decrement page index'),
    ('LABEL_F91818', 'CmpFile_ScrollDown',
     'Scroll down (xde=1): decrement page index if > 0'),
    ('LABEL_F91826', 'CmpFile_ScrollStore',
     'Store updated page index'),
    ('LABEL_F9182A', 'CmpFile_ScrollRedraw',
     'Page changed: redraw file list, send confirm to src/dst sub-widgets'),
    ('LABEL_F91866', 'CmpFile_RedrawDispatch',
     'Draw updated list items, send confirm 0x1C0000F, refresh src+dst'),
    ('LABEL_F918A8', 'CmpFile_Return',
     'Common exit: return XHL=0, pop xiz, inc 4 xsp, ret'),

    # FmmCmpSingleLoadFunc (lines 2140-2247)
    ('LABEL_F91903', 'FmmCmpLoad_DispatchState',
     'Dispatch by progress state: 0=error, 1=success, 2=continue, 5=cancel'),
    ('LABEL_F91930', 'FmmCmpLoad_ContinueLoad',
     'State 2 (continue): set bank 4, call loader, check disk availability'),
    ('LABEL_F9194C', 'FmmCmpLoad_SignalProgress',
     'Signal progress update after disk check'),
    ('LABEL_F9194F', 'FmmCmpLoad_CloseProgress',
     'Close progress dialog, send wait event 0x1C0000A, clear flags'),
    ('LABEL_F9197B', 'FmmCmpLoad_HandleCancel',
     'State 5 (cancel): close dialog, call cancel handler (0xF99490 code 0xB0)'),
    ('LABEL_F9199C', 'FmmCmpLoad_HandleError',
     'State 0 (error): close dialog, call error handler (0xF99490 code 0x7D)'),
    ('LABEL_F919B5', 'FmmCmpLoad_HandleSuccess',
     'State 1 (success): reset progress, close dialog, call handler 0xB0, show result'),
    ('LABEL_F919D7', 'FmmCmpLoad_CallStatusDisplay',
     'Call status display (LABEL_F994BD / ShowStatusMessage)'),
    ('LABEL_F919DD', 'FmmCmpLoad_HandleAbort',
     'Event value 3 (abort): call CancelOperationCleanup'),
    ('LABEL_F919E0', 'FmmCmpLoad_Return',
     'Common exit: return XHL=0'),

    # Utility function after FmmCmpSingleLoadFunc (lines 2249-2298)
    # Cross-referenced from medley.s and smf_operations.s
    ('LABEL_F919E3', 'BuildSlotLabel',
     'Build slot label string "N:" at 0xAB000+slot*0x800; return ptr in XHL'),
    ('LABEL_F91A27', 'BuildSlotLabel_WriteLetter',
     'Slot index != 9: write ASCII letter (slot+0x31) as label char'),
    ('LABEL_F91A33', 'BuildSlotLabel_WriteColon',
     'Append colon separator \':\' after slot letter'),
    ('LABEL_F91A39', 'BuildSlotLabel_WriteContent',
     'Write file name content from name buffer into slot label area'),
]


FILES_TO_SCAN = [
    ('maincpu/file_io/single_load.s', 'ascii'),
    ('maincpu/file_io/medley.s', 'ascii'),
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
                continue

            content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:40s} ({refs} refs in {rel_path})')

        with open(src, 'wb') as f:
            f.write(content.encode(encoding))

        if renamed > 0:
            print(f'  Renamed {renamed} labels in {rel_path}')
        else:
            print(f'  No matching labels found in {rel_path}')

    print(f'\nDone.')


if __name__ == '__main__':
    main()
