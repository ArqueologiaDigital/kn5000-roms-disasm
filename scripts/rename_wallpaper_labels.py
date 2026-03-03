#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in wallpaper.s (wallpaper loading and display).

Three functions:
  FmmWallpaperLoadFunc  - Wallpaper loading with progress state machine
    Events: 0x1C00018/17 (scroll), 0x1C0000B (show), 0x1E50004 (select), 0x1C00013 (progress)
    Progress states: 0=error, 1=success, 2=continue, 3=abort, 5=cancel
  WP_ScanAvailability   - Scan wallpaper slot availability (4 types at 0xEA07AA)
  WP_FindNextSlot       - Find next available wallpaper slot from current position

Note: LABEL_F8ECB3 and LABEL_F8ED83 are cross-referenced from single_load.s.
Uses binary I/O to handle encoding safely.
"""

import os
import re

RENAMES = [
    # FmmWallpaperLoadFunc (lines 10-322) - Wallpaper loading handler
    ('LABEL_F8E9AC', 'WPLoad_DispatchState',
     'Dispatch by progress state: 0=error, 1=success, 5=cancel, else continue'),
    ('LABEL_F8E9D8', 'WPLoad_ContinueWait',
     'Progress incomplete: dismiss dialog, send wait event 0x1C0000A'),
    ('LABEL_F8E9F7', 'WPLoad_HandleCancel',
     'State 5 (cancel): dismiss UI, call cancel handler (0xF99490 code 0x48)'),
    ('LABEL_F8EA38', 'WPLoad_HandleError',
     'State 0 (error): dismiss dialog, call handler with code 0x7D'),
    ('LABEL_F8EA52', 'WPLoad_HandleSuccess',
     'State 1 (success): reset progress, call handler code 0x48, show result'),
    ('LABEL_F8EA94', 'WPLoad_CallStatusDisplay',
     'Call status display (LABEL_F994BD)'),
    ('LABEL_F8EA9B', 'WPLoad_HandleAbort',
     'Event value 3 (abort): call CancelOperationCleanup'),
    ('LABEL_F8EAA1', 'WPLoad_HandleSelection',
     'Event 0x1E50004: store widget ref, compute item count'),
    ('LABEL_F8EABA', 'WPLoad_Selection_Positive',
     'Item count >= 0: compute page, send selection event'),
    ('LABEL_F8EAD5', 'WPLoad_HandleShow',
     'Event 0x1C0000B (show): compute page, draw list'),
    ('LABEL_F8EAE9', 'WPLoad_HandleScroll',
     'Events 0x1C00017/18 (scroll up/down): process navigation'),
    ('LABEL_F8EB1B', 'WPLoad_ScrollUp',
     'Scroll up: decrement position if > 0'),
    ('LABEL_F8EB2D', 'WPLoad_PageScroll',
     'Page scroll: check direction (xwa=1 up, 2 down)'),
    ('LABEL_F8EB45', 'WPLoad_PageDown',
     'Page down: add 10 to position, check bounds'),
    ('LABEL_F8EB62', 'WPLoad_StorePosition',
     'Store new position, jump to update display'),
    ('LABEL_F8EB6B', 'WPLoad_PageDown_Boundary',
     'Page down: position exceeds total, adjust to last page'),
    ('LABEL_F8EB95', 'WPLoad_OpLoad',
     'xwa=3 (load): open progress dialog, execute load'),
    ('LABEL_F8EC05', 'WPLoad_GetSelection',
     'Get current selection index from 33204'),
    ('LABEL_F8EC09', 'WPLoad_UpdateDisplay',
     'Update display: send selection event, redraw items'),
    ('LABEL_F8EC97', 'WPLoad_RedrawPage',
     'Selection on different page: redraw full page'),
    ('LABEL_F8EC9E', 'WPLoad_SendState',
     'Send OK state event to widget'),
    ('LABEL_F8ECA9', 'WPLoad_DispatchWidget',
     'Common: call widget dispatch (0xFA9D58)'),
    ('LABEL_F8ECAD', 'WPLoad_Return',
     'Return XHL=0, pop xiz, adjust stack'),

    # WP_ScanAvailability (lines 324-421) - Scan wallpaper availability
    ('LABEL_F8ECB3', 'WP_ScanAvailability',
     'Scan 4 wallpaper types at 0xEA07AA, build availability mask'),
    ('LABEL_F8ECC3', 'WPScan_LoopBody',
     'Loop: check type byte, branch by wallpaper type'),
    ('LABEL_F8ECDB', 'WPScan_CheckAvail',
     'Check availability bit, skip if not supported'),
    ('LABEL_F8ED04', 'WPScan_MarkAvailable',
     'OR slot into availability mask (35318), check limit'),
    ('LABEL_F8ED11', 'WPScan_TypeNotThree',
     'Type != 3: check type 2 or generic path'),
    ('LABEL_F8ED3D', 'WPScan_TypeTwo_Mark',
     'Type 2: OR into availability mask, check limit'),
    ('LABEL_F8ED4A', 'WPScan_TypeGeneric',
     'Generic type: check availability, mark if present'),
    ('LABEL_F8ED68', 'WPScan_Generic_Mark',
     'Generic: OR into availability mask, check limit'),
    ('LABEL_F8ED73', 'WPScan_LimitReached',
     'Availability limit reached: store current type index'),
    ('LABEL_F8ED7A', 'WPScan_LoopContinue',
     'Increment index, continue if < 4'),

    # WP_FindNextSlot (lines 423-467) - Find next available slot
    ('LABEL_F8ED83', 'WP_FindNextSlot',
     'Find next available wallpaper slot from current position'),
    ('LABEL_F8EDA0', 'WPFind_SearchLoop',
     'Search loop: compute wrapped index, check availability'),
    ('LABEL_F8EDBC', 'WPFind_CheckSlot',
     'Check if slot is available in mask'),
    ('LABEL_F8EDC8', 'WPFind_NextSlot',
     'Slot not available: increment, continue if < 4'),
    ('LABEL_F8EDCE', 'WPFind_NotFound',
     'No available slot found: return L=0'),
    ('LABEL_F8EDD0', 'WPFind_Return',
     'Common exit: pop iz, ret'),
]

FILES_TO_SCAN = [
    ('maincpu/file_io/wallpaper.s', 'ascii'),
    ('maincpu/file_io/single_load.s', 'ascii'),
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

    print(f'\nDone.')


if __name__ == '__main__':
    main()
