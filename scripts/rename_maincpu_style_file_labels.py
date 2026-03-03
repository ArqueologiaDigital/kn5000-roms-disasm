#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in maincpu for style convert title
functions, demo selection entry, file size encoding, and post-TM save area.

Target functions:
  1. StylCnvModlTtlFunc  (43 labels) — Style convert model title handler
  2. StylCnvCnvtTtlFunc  (27 labels) — Style convert convert title handler
  3. StylCnvSelTtlFunc   (19 labels) — Style convert select title handler
  4. Demo_SelectionEntryHandler (23 labels) — Demo song selection entry
  5. GetEncodedFileSizeData area (41 labels) — File size encoding/lookup
  6. PostTmSave area (32 labels) — Post-TM save, string/number parsing

All three StylCnv*TtlFunc handlers share the same structural pattern:
  - Event 0x1C00013 dispatches by sub-event code (Init=2, Close=5, Redraw=3,
    Scroll=8, OpenItem=4)
  - Event 0x1C00007 (OK) dispatches by notification code (PageUp/Down=1-4,
    ScrollUp/Down=2-3/0x82-0x83, Home/End=0x81/0x84, Select=0xB)
  - Title list uses 37-byte (0x25) records at address 21988
  - Selection index at 15620, item count at 14978
  - Pages of 20 (0x14) items

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
    # StylCnvModlTtlFunc  (F6C226 - F6C681)
    # Style convert MODEL title handler.  Dispatches Init(2), Close(5),
    # Redraw(3), Scroll(8), OpenItem(4) from event 0x1C00013, and
    # scroll/page/select notifications from event 0x1C00007 (OK).
    # Records are 37 bytes (0x25) at address 21988.
    # ==================================================================
    ('LABEL_F6C291', 'StylCnvModl_ScanMatchingModels',
     'Loop: scan 256 model entries, count those matching via F8AED5'),

    ('LABEL_F6C2B9', 'StylCnvModl_ScanDone',
     'Scan complete: check if any matching models found'),

    ('LABEL_F6C2C7', 'StylCnvModl_PadModelNames',
     'Found matches: pad model name strings with spaces/NULs'),

    ('LABEL_F6C2D7', 'StylCnvModl_PadOuterLoop',
     'Outer pad loop: iterate remaining models (iz to 256)'),

    ('LABEL_F6C2DB', 'StylCnvModl_PadInnerLoop',
     'Inner pad loop: set bytes 0-11 to 0x20 (space), 12-19 to 0x00'),

    ('LABEL_F6C2E5', 'StylCnvModl_PadStoreChar',
     'Store pad character (0x00 or 0x20) at record byte offset'),

    ('LABEL_F6C304', 'StylCnvModl_InitListDisplay',
     'Initialize list display: reset selection, draw header+list'),

    ('LABEL_F6C323', 'StylCnvModl_ClearDisplayBuf',
     'Clear display buffer region with 0xE0 fill pattern'),

    ('LABEL_F6C359', 'StylCnvModl_FormatFilename',
     'Format filename: process source path string characters'),

    ('LABEL_F6C35F', 'StylCnvModl_FormatLoop',
     'Format loop: scan filename chars, replace 0x5F->space, 0x25->dot'),

    ('LABEL_F6C375', 'StylCnvModl_CheckPercent',
     'Check if char is 0x25 (percent sign) and replace with 0x2E (dot)'),

    ('LABEL_F6C37D', 'StylCnvModl_FormatNext',
     'Advance to next filename character (up to 0x20 bytes)'),

    ('LABEL_F6C387', 'StylCnvModl_CopyDefaultName',
     'No match found: Strcpy default name from 0xE3D2 table'),

    ('LABEL_F6C394', 'StylCnvModl_DrawListUI',
     'Draw list UI: send display commands 0x110007/0x1C0000B'),

    ('LABEL_F6C3B3', 'StylCnvModl_WaitForAck',
     'Wait loop: poll F8AED5 until acknowledgment received'),

    ('LABEL_F6C3C4', 'StylCnvModl_HandleScroll',
     'Handle Scroll (sub-event 8): scroll by 0x14 if count nonzero'),

    ('LABEL_F6C3D1', 'StylCnvModl_HandleRedraw',
     'Handle Redraw (sub-event 3): check and invoke screen refresh'),

    ('LABEL_F6C3DF', 'StylCnvModl_RedrawDone',
     'Redraw done: call F6BCD6 helper'),

    ('LABEL_F6C3E2', 'StylCnvModl_RedrawReturnZero',
     'Return WA=0 after redraw, call F99525'),

    ('LABEL_F6C3E6', 'StylCnvModl_HandleClose',
     'Handle Close (sub-event 5): cleanup via F6C0E0, return'),

    ('LABEL_F6C3EC', 'StylCnvModl_HandleOpenItem',
     'Handle OpenItem (sub-event 4): return WA=0'),

    ('LABEL_F6C3EE', 'StylCnvModl_CallReturnAction',
     'Common: call F99525 (return action) and jump to epilogue'),

    ('LABEL_F6C3F5', 'StylCnvModl_HandleOK',
     'Handle OK event (0x1C00007): dispatch by notification code'),

    ('LABEL_F6C444', 'StylCnvModl_OK_PageUp',
     'Page up (0x81/0x1): subtract 0x14 from selection if possible'),

    ('LABEL_F6C44E', 'StylCnvModl_OK_StoreSelection',
     'Store new selection index to address 15620'),

    ('LABEL_F6C452', 'StylCnvModl_OK_LoadSelection',
     'Load current selection from 15620 into XBC'),

    ('LABEL_F6C456', 'StylCnvModl_OK_UpdateDisplay',
     'Update display: check if selection changed, compute page, redraw'),

    ('LABEL_F6C4CA', 'StylCnvModl_OK_ScrollUp',
     'Scroll up (0x2/0x3): decrement selection if not at top'),

    ('LABEL_F6C4E4', 'StylCnvModl_OK_ScrollDown',
     'Scroll down (0x82/0x83): increment selection if not at bottom'),

    ('LABEL_F6C504', 'StylCnvModl_OK_PageDown',
     'Page down (0x4/0x84): add 0x14, clamp to item count'),

    ('LABEL_F6C517', 'StylCnvModl_OK_PageDown_Clamp',
     'Clamp page-down: ensure selection stays within valid range'),

    ('LABEL_F6C543', 'StylCnvModl_OK_SelectItem',
     'Select item (0xB): look up model name, load style from disk'),

    ('LABEL_F6C563', 'StylCnvModl_OK_Select_ClearMem',
     'Clear 0x30000 bytes at 0x80000 before loading style file'),

    ('LABEL_F6C56A', 'StylCnvModl_OK_Select_FillLoop',
     'Memory fill loop: write 0xE4 pattern with 0x00 fill'),

    ('LABEL_F6C5A2', 'StylCnvModl_OK_Select_ShowError',
     'Show error: call F99490 error display, jump to epilogue'),

    ('LABEL_F6C5A9', 'StylCnvModl_OK_Select_LoadOK',
     'File loaded OK: compute aligned file size, store to 15708'),

    ('LABEL_F6C5D1', 'StylCnvModl_OK_Select_AlignSize',
     'Align file size to 256-byte boundary, store address+metadata'),

    ('LABEL_F6C5FF', 'StylCnvModl_OK_Select_CompareNames',
     'Compare model name bytes (8 chars) to existing selection'),

    ('LABEL_F6C61C', 'StylCnvModl_OK_Select_StoreResult',
     'Store comparison result: set selection flag if names match'),

    ('LABEL_F6C670', 'StylCnvModl_OK_PageRedraw',
     'Page changed: redraw with full item count and page size 0x14'),

    ('LABEL_F6C677', 'StylCnvModl_OK_CallRedraw',
     'Call F6C0F3 list redraw helper'),

    ('LABEL_F6C67A', 'StylCnvModl_Return',
     'Epilogue: set HL=0, pop xiz, restore stack, return'),

    ('LABEL_F6C681', 'StylCnvModl_End',
     'Trailing label after StylCnvModlTtlFunc (boundary marker)'),

    # ==================================================================
    # StylCnvCnvtTtlFunc  (F6C681 - F6C926)
    # Style convert CONVERT title handler.  Parallel structure to
    # ModlTtlFunc but for the conversion target list.  Uses list
    # command 0x120002 (vs 0x110002 for model).
    # ==================================================================
    ('LABEL_F6C6DB', 'StylCnvCnvt_ScanMatchingStyles',
     'Loop: scan 256 style entries, count matches via F8AED5'),

    ('LABEL_F6C703', 'StylCnvCnvt_PadStyleNames',
     'Pad style names: fill remaining entries with spaces/NULs'),

    ('LABEL_F6C713', 'StylCnvCnvt_PadOuterLoop',
     'Outer pad loop: iterate remaining styles (iz to 256)'),

    ('LABEL_F6C717', 'StylCnvCnvt_PadInnerLoop',
     'Inner pad loop: set bytes 0-11 to 0x20, 12-31 to 0x00'),

    ('LABEL_F6C721', 'StylCnvCnvt_PadStoreChar',
     'Store pad character at record byte offset'),

    ('LABEL_F6C740', 'StylCnvCnvt_InitListDisplay',
     'Initialize list: reset selection, send display cmd 0x120002'),

    ('LABEL_F6C759', 'StylCnvCnvt_HandleScroll',
     'Handle Scroll (sub-event 8): scroll by 0x14'),

    ('LABEL_F6C763', 'StylCnvCnvt_HandleRedraw',
     'Handle Redraw (sub-event 3): check state, invoke refresh'),

    ('LABEL_F6C771', 'StylCnvCnvt_HandleClose',
     'Handle Close (sub-event 5): cleanup via F6C0E0, return'),

    ('LABEL_F6C777', 'StylCnvCnvt_HandleOpenItem',
     'Handle OpenItem (sub-event 4): return WA=0'),

    ('LABEL_F6C779', 'StylCnvCnvt_CallReturnAction',
     'Common: call F99525 (return action) and jump to epilogue'),

    ('LABEL_F6C780', 'StylCnvCnvt_HandleOK',
     'Handle OK event (0x1C00007): dispatch by notification code'),

    ('LABEL_F6C7CF', 'StylCnvCnvt_OK_PageUp',
     'Page up (0x81/0x1): subtract 0x14 from selection'),

    ('LABEL_F6C7D9', 'StylCnvCnvt_OK_StoreSelection',
     'Store new selection index to address 15620'),

    ('LABEL_F6C7DD', 'StylCnvCnvt_OK_LoadSelection',
     'Load current selection from 15620 into XBC'),

    ('LABEL_F6C7E1', 'StylCnvCnvt_OK_UpdateDisplay',
     'Update display: check change, compute page, redraw items'),

    ('LABEL_F6C855', 'StylCnvCnvt_OK_ScrollUp',
     'Scroll up (0x2/0x3): decrement selection'),

    ('LABEL_F6C86F', 'StylCnvCnvt_OK_ScrollDown',
     'Scroll down (0x82/0x83): increment selection'),

    ('LABEL_F6C88F', 'StylCnvCnvt_OK_PageDown',
     'Page down (0x4/0x84): add 0x14, clamp to count'),

    ('LABEL_F6C8A2', 'StylCnvCnvt_OK_PageDown_Clamp',
     'Clamp page-down selection to valid range'),

    ('LABEL_F6C8CE', 'StylCnvCnvt_OK_SelectItem',
     'Select item (0xB): check selection type and dispatch'),

    ('LABEL_F6C8E8', 'StylCnvCnvt_OK_Select_WriteStyle',
     'Type 2: write converted style data to file system'),

    ('LABEL_F6C90A', 'StylCnvCnvt_OK_Select_Finalize',
     'Finalize selection: set flag, call D846 jump, CC14 update'),

    ('LABEL_F6C918', 'StylCnvCnvt_OK_PageRedraw',
     'Page changed: redraw with count and page size 0x14'),

    ('LABEL_F6C91F', 'StylCnvCnvt_OK_CallRedraw',
     'Call F6C0F3 list redraw helper'),

    ('LABEL_F6C922', 'StylCnvCnvt_Return',
     'Epilogue: set HL=0, pop xiz, return'),

    ('LABEL_F6C926', 'StylCnvCnvt_End',
     'Trailing label after StylCnvCnvtTtlFunc (boundary marker)'),

    # ==================================================================
    # StylCnvSelTtlFunc  (F6C926 - F6CB2A)
    # Style convert SELECT title handler.  Similar structure to the
    # other two but uses list command 0x150002 for display.
    # ==================================================================
    ('LABEL_F6C989', 'StylCnvSel_HandleScroll',
     'Handle Scroll (sub-event 8): scroll by 0x14'),

    ('LABEL_F6C991', 'StylCnvSel_HandleRedraw',
     'Handle Redraw (sub-event 3): check state, invoke refresh'),

    ('LABEL_F6C99F', 'StylCnvSel_HandleClose',
     'Handle Close (sub-event 5): cleanup via F6C0E0, return'),

    ('LABEL_F6C9A5', 'StylCnvSel_HandleOpenItem',
     'Handle OpenItem (sub-event 4): return WA=0'),

    ('LABEL_F6C9A7', 'StylCnvSel_CallReturnAction',
     'Common: call F99525 (return action) and jump to epilogue'),

    ('LABEL_F6C9AE', 'StylCnvSel_HandleOK',
     'Handle OK event (0x1C00007): dispatch by notification code'),

    ('LABEL_F6C9FD', 'StylCnvSel_OK_PageUp',
     'Page up (0x81/0x1): subtract 0x14 from selection'),

    ('LABEL_F6CA07', 'StylCnvSel_OK_StoreSelection',
     'Store new selection index to address 15620'),

    ('LABEL_F6CA0B', 'StylCnvSel_OK_LoadSelection',
     'Load current selection from 15620 into XBC'),

    ('LABEL_F6CA0F', 'StylCnvSel_OK_UpdateDisplay',
     'Update display: check change, compute page, redraw items'),

    ('LABEL_F6CA85', 'StylCnvSel_OK_ScrollUp',
     'Scroll up (0x2/0x3): decrement selection'),

    ('LABEL_F6CA9F', 'StylCnvSel_OK_ScrollDown',
     'Scroll down (0x82/0x83): increment selection'),

    ('LABEL_F6CABF', 'StylCnvSel_OK_PageDown',
     'Page down (0x4/0x84): add 0x14, clamp to count'),

    ('LABEL_F6CAD2', 'StylCnvSel_OK_PageDown_Clamp',
     'Clamp page-down selection to valid range'),

    ('LABEL_F6CB00', 'StylCnvSel_OK_SelectItem',
     'Select item (0xB): clear buffer, store index+1, jump+update'),

    ('LABEL_F6CB1C', 'StylCnvSel_OK_PageRedraw',
     'Page changed: redraw with count and page size 0x14'),

    ('LABEL_F6CB23', 'StylCnvSel_OK_CallRedraw',
     'Call F6C0F3 list redraw helper'),

    ('LABEL_F6CB26', 'StylCnvSel_Return',
     'Epilogue: set HL=0, pop xiz, return'),

    ('LABEL_F6CB2A', 'StylCnvSel_End',
     'Trailing label after StylCnvSelTtlFunc (boundary marker)'),

    # ==================================================================
    # Demo_SelectionEntryHandler  (F86A47 - F86D86)
    # Demo song selection entry handler.  Sets up audio, processes
    # button presses, manages playback state via 3375/3379 counters,
    # loads and plays demo songs via SLIDE_Parse_Header.
    # ==================================================================
    ('LABEL_F86A99', 'Demo_SelectEntry_NoNewButton',
     'No new button press: clear debounce counter to 0'),

    ('LABEL_F86A9F', 'Demo_SelectEntry_PreSaveCheck',
     'Pre-save check: dispatch based on control panel state (36148)'),

    ('LABEL_F86AC6', 'Demo_SelectEntry_CheckVoiceKeys',
     'Check voice key codes (0x72, 0x70, 0x71, 0x6F) for preset save'),

    ('LABEL_F86ADE', 'Demo_SelectEntry_SaveVoice',
     'Save voice preset before proceeding'),

    ('LABEL_F86AE1', 'Demo_SelectEntry_ExitDispatch',
     'Exit dispatch: send multi-byte command 0xE3/0xFF/0x00/0x4A/0xF2'),

    ('LABEL_F86AE9', 'Demo_SelectEntry_ByteTable',
     'Encoded byte table: dispatch/lookup data for demo selection'),

    ('LABEL_F86B7C', 'Demo_SelectEntry_ProcessSongList',
     'Process song list: check play state and auto-advance flags'),

    ('LABEL_F86BAA', 'Demo_SelectEntry_ManualSelect',
     'Manual selection path: set up playback without auto-play flag'),

    ('LABEL_F86BC7', 'Demo_SelectEntry_ToCountdown',
     'Jump to countdown timer start (set 3375=15)'),

    ('LABEL_F86BCA', 'Demo_SelectEntry_StartAutoPlay',
     'Start auto-play: set control byte 36686=4, check sequence type'),

    ('LABEL_F86BE4', 'Demo_SelectEntry_TimerTick',
     'Timer tick: decrement countdown, trigger song load at thresholds'),

    ('LABEL_F86C12', 'Demo_SelectEntry_CheckCountdown',
     'Check countdown: dispatch on value 3=StartPlay, 1=SetLoadFlag'),

    ('LABEL_F86C25', 'Demo_SelectEntry_CheckCPanel',
     'Check control panel (36148): if state 19, trigger debounce'),

    ('LABEL_F86C30', 'Demo_SelectEntry_Debounce',
     'Debounce handler: decrement 3379, set auto-play flag on zero'),

    ('LABEL_F86C5F', 'Demo_SelectEntry_AfterSongLoad',
     'After song load: set control byte, check sequence type, advance'),

    ('LABEL_F86C93', 'Demo_SelectEntry_CheckSongCount',
     'Check song count via F846DF: validate auto-advance position'),

    ('LABEL_F86CA4', 'Demo_SelectEntry_CheckLimit18',
     'Check if song index >= 18: clamp to 18 if exceeded'),

    ('LABEL_F86CAB', 'Demo_SelectEntry_ClampSongIdx',
     'Clamp song index to 18 (maximum)'),

    ('LABEL_F86CB0', 'Demo_SelectEntry_UpdateDisplay',
     'Update display: refresh pattern, animation, and song list UI'),

    ('LABEL_F86CBE', 'Demo_SelectEntry_LoadPattern',
     'Load display pattern: index*2 lookup from 0xEA00AC table'),

    ('LABEL_F86CD3', 'Demo_SelectEntry_DrawSecondary',
     'Draw secondary display: check auto-play, index*2 from 0xEA00AD'),

    ('LABEL_F86CF7', 'Demo_SelectEntry_PlaySong',
     'Play selected song: load address, parse SLIDE header, start seq'),

    ('LABEL_F86D3D', 'Demo_SelectEntry_StartPlayback',
     'Start playback: call F3CA8A/FDDE6F init, copy song ID, begin'),

    # ==================================================================
    # GetEncodedFileSizeData  (F89888 - F89913)
    # Scans 12-byte record array at 0x025DB8, matches filenames via
    # ParseTwoDigitFileNum/HandleFilenameChange, accumulates sizes.
    # ==================================================================
    ('LABEL_F8988F', 'GetEncFileSize_CopyRecordLoop',
     'Copy 12-byte records from array at 0x025DB8 into descriptor'),

    ('LABEL_F898D9', 'GetEncFileSize_AfterFirstMatch',
     'After first match: try next iteration from same handle'),

    ('LABEL_F898E7', 'GetEncFileSize_IterLoop',
     'Iteration loop: parse file number, handle change, accumulate'),

    ('LABEL_F898FE', 'GetEncFileSize_IterNext',
     'Advance iteration: call F52AE8 to get next entry'),

    ('LABEL_F8990C', 'GetEncFileSize_ReleaseHandle',
     'Release search handle via F52AAA'),

    ('LABEL_F89913', 'GetEncFileSize_Return',
     'Return: restore IZ, adjust stack (R+d16), return HL=count'),

    # ==================================================================
    # LABEL_F8991C  (F8991C - F89A7A)
    # Number-to-ASCII conversion and array search function.
    # Converts numeric index to 2-digit ASCII, formats buffer,
    # iterates 12-byte records at 0x025DB8 performing lookups/copies.
    # ==================================================================
    ('LABEL_F8991C', 'IndexToRecordLookup',
     'Convert index to ASCII, format buffer, search record array'),

    ('LABEL_F899DB', 'IdxRecLookup_AfterFirstMatch',
     'After first match: iterate remaining entries'),

    ('LABEL_F899EA', 'IdxRecLookup_IterBody',
     'Iteration body: compute index*12, check record field'),

    ('LABEL_F89A47', 'IdxRecLookup_NonZeroField',
     'Record field nonzero: advance by 2+8, compare via F89153'),

    ('LABEL_F89A5C', 'IdxRecLookup_IterNext',
     'Advance iteration: call F52AE8 for next entry'),

    ('LABEL_F89A6A', 'IdxRecLookup_ReleaseHandle',
     'Release search handle via F52AAA'),

    ('LABEL_F89A71', 'IdxRecLookup_Return',
     'Return: restore IZ, adjust stack (R+d16), return result flag'),

    # ==================================================================
    # LABEL_F89A7B  (F89A7B - F89AC6)
    # File range validator.  Checks if a file index (WA) is within
    # valid bounds for the current disk type (2/3/4 at 0x025DB6).
    # Returns HL=-1 (invalid), 0 (in range), 1 (first page), 2 (found).
    # ==================================================================
    ('LABEL_F89A7B', 'ValidateFileRange',
     'Validate file index against disk type bounds'),

    ('LABEL_F89A8C', 'ValidateFileRange_CheckLower',
     'Disk type 2/3/4: check WA >= 0'),

    ('LABEL_F89A97', 'ValidateFileRange_Invalid',
     'Out of range: return HL=0xFFFF (-1)'),

    ('LABEL_F89A9B', 'ValidateFileRange_InRange',
     'In valid range: check if in first or second page'),

    ('LABEL_F89AAB', 'ValidateFileRange_FirstPage',
     'File is in first page: return HL=1'),

    ('LABEL_F89AAE', 'ValidateFileRange_SecondPage',
     'File is in second page: compute offset, search 82-byte records'),

    ('LABEL_F89AC4', 'ValidateFileRange_Found',
     'Record found: return HL=2'),

    # ==================================================================
    # LABEL_F89AC7  (F89AC7 - F89ADC)
    # Get first page base index.  Calls ValidateFileRange, returns
    # base address at 0x0271EA or error code 0xFF98 (-104).
    # ==================================================================
    ('LABEL_F89AC7', 'GetFirstPageBase',
     'Get first-page base: validate range, return 0x0271EA or error'),

    ('LABEL_F89AD7', 'GetFirstPageBase_Valid',
     'Range valid: load and return value from 0x0271EA'),

    # ==================================================================
    # LABEL_F89ADD  (F89ADD - F89BA3)
    # Build second-page record list.  Scans 82-byte (0x52) records at
    # 0x025EB2, copies into descriptor at 0xEA03E8, iterates entries.
    # ==================================================================
    ('LABEL_F89ADD', 'BuildSecondPageRecords',
     'Build second-page record list from 82-byte records at 0x025EB2'),

    ('LABEL_F89AEF', 'BuildSecondPage_CopyRecordLoop',
     'Copy 82-byte records (29 words) into descriptor at 0xEA03E8'),

    ('LABEL_F89B4B', 'BuildSecondPage_IterStart',
     'Start iteration: iz=1, begin scanning matched entries'),

    ('LABEL_F89B5B', 'BuildSecondPage_IterBody',
     'Iteration body: compute page offset, format record buffer'),

    ('LABEL_F89B84', 'BuildSecondPage_IterNext',
     'Advance iteration: increment iz, call F52AE8'),

    ('LABEL_F89B94', 'BuildSecondPage_ReleaseHandle',
     'Release search handle via F52AAA'),

    ('LABEL_F89B9B', 'BuildSecondPage_Return',
     'Return: HL=count (iz), restore stack, return'),

    # ==================================================================
    # LABEL_F89BA4  (F89BA4 - F89BF0)
    # Navigate to file index.  Validates range, computes page
    # boundaries, calls BuildSecondPageRecords if needed.
    # Stores page start/end at 0x0271EE/0x0271F0.
    # ==================================================================
    ('LABEL_F89BA4', 'NavigateToFileIndex',
     'Navigate to file index: validate, compute page, build records'),

    ('LABEL_F89BB9', 'NavToFileIdx_InSecondPage',
     'In second page: compute 60-entry page start, clamp end'),

    ('LABEL_F89BDF', 'NavToFileIdx_ClampEnd',
     'Clamp page end to not exceed total file count'),

    ('LABEL_F89BE7', 'NavToFileIdx_StoreIndex',
     'Store current index at 0x0271EA'),

    ('LABEL_F89BEE', 'NavToFileIdx_Return',
     'Pop iz and return'),

    # ==================================================================
    # LABEL_F89BF0  (F89BF0 - F89C23)
    # Get record pointer for file index.  Validates range, computes
    # offset into 82-byte record array, returns pointer in XHL.
    # ==================================================================
    ('LABEL_F89BF0', 'GetRecordPtrForFile',
     'Get record pointer: validate index, compute 82-byte record offset'),

    ('LABEL_F89C03', 'GetRecordPtr_InRange',
     'In range: compute (index - base) * 0x52 + 0x25EB2, return ptr'),

    ('LABEL_F89C22', 'GetRecordPtr_Return',
     'Pop iz and return'),

    # ==================================================================
    # LABEL_F89C24  (F89C24 - F89C78)
    # Validate and search for file entry.  Copies 16 bytes to
    # 0xEA049C, validates range, formats buffer, searches directory.
    # Returns entry handle or -104 error.
    # ==================================================================
    ('LABEL_F89C24', 'ValidateAndSearchFile',
     'Validate file index, format buffer, search directory entry'),

    ('LABEL_F89C63', 'ValidateAndSearch_NotFound',
     'Validation failed or not found: return XHL=0xFFFFFF98 (-104)'),

    ('LABEL_F89C6A', 'ValidateAndSearch_Found',
     'Found: release handle via F52AAA, return entry from stack'),

    ('LABEL_F89C71', 'ValidateAndSearch_Return',
     'Restore iz, adjust stack (R+d16), return'),

    # ==================================================================
    # PostTmSave area  (FF04F4 - FF0A5B)
    # Post-TM (Tone Memory) save operations, file writing, flash
    # routines, string search, and integer parsing functions.
    # ==================================================================

    # --- LABEL_FF04F4: Encoded byte block (calr-based, 18 bytes) ---
    ('LABEL_FF04F4', 'PostTmSave_ByteBlock',
     'Encoded byte block: calr-based dispatch for TM save finalization'),

    # --- LABEL_FF0506: Post-TM save success handler ---
    ('LABEL_FF0506', 'PostTmSave_Success',
     'TM save success: init tone banks, copy flash data, notify UI'),

    ('LABEL_FF053C', 'PostTmSave_Failure',
     'TM save failure: call FEF455 error indicator'),

    ('LABEL_FF0546', 'PostTmSave_JumpToRestore',
     'Jump to F851DE to restore UI state'),

    # --- LABEL_FF054A-FF068B: Large encoded data/code blocks ---
    ('LABEL_FF054A', 'TmFlashWrite_Block1',
     'Flash write block 1: encoded tone memory write routine'),

    ('LABEL_FF0662', 'TmFlashWrite_Block2',
     'Flash write block 2: continuation of write routine'),

    ('LABEL_FF0666', 'TmFlashWrite_Block3',
     'Flash write block 3: finalization and verify'),

    # --- LABEL_FF068C: Flash copy to external memory ---
    ('LABEL_FF068C', 'TmFlash_CopyToExtMem',
     'Copy tone data from 0x300000+0xB0400 to external memory 0xA0000'),

    # --- LABEL_FF06A7: Large encoded data/code block ---
    ('LABEL_FF06A7', 'TmFlash_WriteRoutine',
     'Flash write routine: encoded block for multi-bank tone writes'),

    # --- LABEL_FF097D-FF099F: String search function ---
    ('LABEL_FF097D', 'StrSearch_Init',
     'String search init: load haystack, reset match position'),

    ('LABEL_FF0984', 'StrSearch_LoadNeedle',
     'Load needle string pointer from stack'),

    ('LABEL_FF0989', 'StrSearch_CompareChar',
     'Compare needle char with haystack char, return if match'),

    ('LABEL_FF0991', 'StrSearch_CheckNeedleEnd',
     'Check if at end of needle string (NUL terminator)'),

    ('LABEL_FF099A', 'StrSearch_CheckHaystackEnd',
     'Check if at end of haystack (NUL terminator)'),

    # --- LABEL_FF09A0-FF09F5: Parse signed 16-bit integer from string ---
    ('LABEL_FF09A0', 'ParseInt16',
     'Parse signed 16-bit integer from ASCII string'),

    ('LABEL_FF09AE', 'ParseInt16_SkipWhitespace',
     'Skip leading whitespace characters'),

    ('LABEL_FF09B0', 'ParseInt16_CheckWhitespace',
     'Check if current char is whitespace via bit table'),

    ('LABEL_FF09C4', 'ParseInt16_CheckMinus',
     'Check for minus sign (0x2D), set negative flag'),

    ('LABEL_FF09C9', 'ParseInt16_SkipSign',
     'Skip sign character and begin digit parsing'),

    ('LABEL_FF09CB', 'ParseInt16_DigitLoop',
     'Digit loop: accumulate value = value * 10 + digit'),

    ('LABEL_FF09E7', 'ParseInt16_ApplySign',
     'Apply sign: negate result if minus flag was set'),

    ('LABEL_FF09F3', 'ParseInt16_Positive',
     'Result is positive: copy IY to HL'),

    ('LABEL_FF09F5', 'ParseInt16_Return',
     'Return parsed 16-bit value in HL'),

    # --- LABEL_FF09F6-FF0A5B: Parse signed 32-bit integer from string ---
    ('LABEL_FF09F6', 'ParseInt32',
     'Parse signed 32-bit integer from ASCII string'),

    ('LABEL_FF0A04', 'ParseInt32_SkipWhitespace',
     'Skip leading whitespace characters'),

    ('LABEL_FF0A06', 'ParseInt32_CheckWhitespace',
     'Check if current char is whitespace via bit table'),

    ('LABEL_FF0A1A', 'ParseInt32_CheckMinus',
     'Check for minus sign (0x2D), set negative flag'),

    ('LABEL_FF0A1F', 'ParseInt32_SkipSign',
     'Skip sign character and begin digit parsing'),

    ('LABEL_FF0A21', 'ParseInt32_DigitLoop',
     'Digit loop: accumulate 32-bit value = value * 10 + digit'),

    ('LABEL_FF0A48', 'ParseInt32_ApplySign',
     'Apply sign: negate 32-bit result if minus flag was set'),

    ('LABEL_FF0A59', 'ParseInt32_Positive',
     'Result is positive: copy XIY to XHL'),

    ('LABEL_FF0A5B', 'ParseInt32_Return',
     'Return parsed 32-bit value in XHL'),
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
