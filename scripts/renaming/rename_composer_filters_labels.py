#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in composer_filters.s (composer load and filter UI).

Five functions handle composer file loading and filter configuration:
  FmmComposerLoadFunc       - Composer file loading with progress state machine
  RenderFilterDisplay       - Render load filter display items (6 string variants)
  FmmLoadFilterFunc         - Load filter settings dialog
  RenderSaveFilterDisplay   - Render save filter display items (3 string variants)
  FmmSaveFilterFunc         - Save filter settings dialog

Event dispatch pattern same as other file_io handlers.
Progress state machine: 0=error, 1=success, 2=continue, 3=abort, 5=cancel.

Uses binary I/O to handle encoding safely.
"""

import os
import re

RENAMES = [
    # FmmComposerLoadFunc (lines 12-316)
    ('LABEL_F8D1E4', 'CompLoad_DispatchState',
     'Dispatch by progress state: 0=error, 1=success, 5=cancel, else continue'),
    ('LABEL_F8D210', 'CompLoad_ContinueWait',
     'Progress incomplete: dismiss dialog, send wait event 0x1C0000A'),
    ('LABEL_F8D22F', 'CompLoad_HandleCancel',
     'State 5 (cancel): dismiss UI, call handler, show status 0'),
    ('LABEL_F8D26F', 'CompLoad_HandleError',
     'State 0 (error): dismiss dialog, call handler with code 0x7D'),
    ('LABEL_F8D289', 'CompLoad_HandleSuccess',
     'State 1 (success): reset progress, show result, status 2'),
    ('LABEL_F8D2CA', 'CompLoad_CallStatusDisplay',
     'Call status display (LABEL_F994BD)'),
    ('LABEL_F8D2D1', 'CompLoad_HandleAbort',
     'Event value 3 (abort): call CancelOperationCleanup'),
    ('LABEL_F8D2D7', 'CompLoad_HandleSelection',
     'Event 0x1E50004: store widget ref, compute item count'),
    ('LABEL_F8D2F7', 'CompLoad_Selection_Negative',
     'Item count < 0: set to 0, send selection event'),
    ('LABEL_F8D30B', 'CompLoad_HandleShow',
     'Event 0x1C0000B (show): draw item list'),
    ('LABEL_F8D30D', 'CompLoad_DrawItemLoop',
     'Loop: compute row offset, draw composer item at position'),
    ('LABEL_F8D335', 'CompLoad_DrawItem_Empty',
     'Item not available: use empty string (0xEA06EC)'),
    ('LABEL_F8D33A', 'CompLoad_DrawItem_Continue',
     'Continue drawing: copy name, send confirm event'),
    ('LABEL_F8D380', 'CompLoad_HandleScroll',
     'Events 0x1C00017/18 (scroll up/down): process navigation'),
    ('LABEL_F8D39E', 'CompLoad_ScrollUp',
     'Scroll up: decrement position if > 0'),
    ('LABEL_F8D3B0', 'CompLoad_PageScroll',
     'Page scroll: check direction (xde=1 up, 2 down)'),
    ('LABEL_F8D3C5', 'CompLoad_PageDown',
     'Page down: add 10 to position, check bounds'),
    ('LABEL_F8D3DE', 'CompLoad_StorePosition',
     'Store new position to 32640'),
    ('LABEL_F8D3E5', 'CompLoad_OpLoad',
     'xde=3 (load): hide buttons, init operation, execute'),
    ('LABEL_F8D408', 'CompLoad_HideButtons_Loop',
     'Loop: hide filter buttons 0-7 before load'),
    ('LABEL_F8D473', 'CompLoad_GetSelection',
     'Get current selection index from 32640'),
    ('LABEL_F8D477', 'CompLoad_UpdateDisplay',
     'Update display: send selection/confirm events, redraw items'),
    ('LABEL_F8D4C6', 'CompLoad_DispatchWidget',
     'Common: call widget dispatch (0xFA9D58)'),
    ('LABEL_F8D4CA', 'CompLoad_Return',
     'Return XHL=0, pop iz, adjust stack'),

    # RenderFilterDisplay (lines 318-415)
    ('LABEL_F8D4FA', 'RenderFilter_CheckType1',
     'Filter 1: check exclusive mode, check available/restricted'),
    ('LABEL_F8D526', 'RenderFilter_Type1_Restricted',
     'Filter 1: restricted string (0xEA06FA)'),
    ('LABEL_F8D530', 'RenderFilter_Type1_Unavail',
     'Filter 1: unavailable string (0xEA0700)'),
    ('LABEL_F8D53A', 'RenderFilter_CheckGeneric',
     'Generic filter: check available/restricted'),
    ('LABEL_F8D55C', 'RenderFilter_Generic_Restricted',
     'Generic: restricted string (0xEA070C)'),
    ('LABEL_F8D566', 'RenderFilter_CheckType2',
     'Filter 2: check dual-mode requirements'),
    ('LABEL_F8D597', 'RenderFilter_Type2_Restricted',
     'Filter 2: restricted string (0xEA0718)'),
    ('LABEL_F8D5A1', 'RenderFilter_Default',
     'Default: standard string (0xEA071E)'),
    ('LABEL_F8D5A9', 'RenderFilter_CopyAndReturn',
     'Copy string to buffer, return'),

    # FmmLoadFilterFunc (lines 417-600)
    ('LABEL_F8D5E0', 'LoadFilter_HandleShow',
     'Event 0x1C0000B (show): draw 8 filter items'),
    ('LABEL_F8D5E4', 'LoadFilter_DrawLoop',
     'Loop: render filter display, send confirm event per item'),
    ('LABEL_F8D61D', 'LoadFilter_HandleScroll',
     'Events 0x1C00017/18 (scroll): navigate filter items'),
    ('LABEL_F8D645', 'LoadFilter_ScrollUp_CheckZero',
     'Scroll up: check if at position 0'),
    ('LABEL_F8D654', 'LoadFilter_ScrollUp_Restore',
     'Scroll up: restore position from stack'),
    ('LABEL_F8D659', 'LoadFilter_ShowButton',
     'Call show button (LABEL_F89321)'),
    ('LABEL_F8D65F', 'LoadFilter_ScrollDown',
     'Scroll down: check exclusive mode and position'),
    ('LABEL_F8D676', 'LoadFilter_ScrollDown_CheckZero',
     'Scroll down: check if at position 0'),
    ('LABEL_F8D685', 'LoadFilter_ScrollDown_Restore',
     'Scroll down: restore position from stack'),
    ('LABEL_F8D68A', 'LoadFilter_HideButton',
     'Call hide button (LABEL_F89335)'),
    ('LABEL_F8D68E', 'LoadFilter_UpdateDisplay',
     'After scroll: render filter, send confirm event'),
    ('LABEL_F8D6C6', 'LoadFilter_OpLoad',
     'Position 0xA (load): check conditions, execute load'),
    ('LABEL_F8D75D', 'LoadFilter_Load_ShowCodeA',
     'Load: show progress code 0xA'),
    ('LABEL_F8D762', 'LoadFilter_Load_ShowCode1',
     'Load: show progress code 1'),
    ('LABEL_F8D764', 'LoadFilter_Load_CallHandler',
     'Load: call operation handler, show status'),
    ('LABEL_F8D77F', 'LoadFilter_Return',
     'Return XHL=0, adjust stack'),

    # RenderSaveFilterDisplay (lines 602-636)
    ('LABEL_F8D7B9', 'RenderSaveFilter_Available',
     'Filter available: use string (0xEA072A)'),
    ('LABEL_F8D7C3', 'RenderSaveFilter_Unavail',
     'Filter unavailable: use string (0xEA0730)'),
    ('LABEL_F8D7CB', 'RenderSaveFilter_CopyAndReturn',
     'Copy string to buffer, return'),

    # FmmSaveFilterFunc (lines 638-967)
    ('LABEL_F8D802', 'SaveFilter_HandleShow',
     'Event 0x1C0000B (show): draw 8 filter items'),
    ('LABEL_F8D806', 'SaveFilter_DrawLoop',
     'Loop: render save filter display, send confirm event per item'),
    ('LABEL_F8D83F', 'SaveFilter_HandleScroll',
     'Events 0x1C00017/18 (scroll): navigate filter items'),
    ('LABEL_F8D86E', 'SaveFilter_ScrollUp_Unavail',
     'Scroll up filter 1: not available, just show'),
    ('LABEL_F8D875', 'SaveFilter_ScrollDown',
     'Scroll down handler: check position and lock state'),
    ('LABEL_F8D891', 'SaveFilter_ScrollDown_Unlock',
     'Scroll down: unlock check, toggle lock state'),
    ('LABEL_F8D8A4', 'SaveFilter_ScrollOther',
     'Scroll other filters: simple lock/unlock toggle'),
    ('LABEL_F8D8B1', 'SaveFilter_LockFilter',
     'Call lock filter (LABEL_F8937F)'),
    ('LABEL_F8D8B7', 'SaveFilter_UnlockFilter',
     'Call unlock filter (LABEL_F89393)'),
    ('LABEL_F8D8BB', 'SaveFilter_UpdateDisplay',
     'After scroll: render filter, send confirm event'),
    ('LABEL_F8D8EF', 'SaveFilter_SelectAll',
     'Position 8: select all filters (lock first 6, unlock last 2)'),
    ('LABEL_F8D902', 'SaveFilter_SelectAll_Loop',
     'Loop: lock/unlock each filter by index'),
    ('LABEL_F8D912', 'SaveFilter_SelectAll_Unlock',
     'Select all: unlock filters >= 6'),
    ('LABEL_F8D916', 'SaveFilter_SelectAll_Update',
     'Select all: render and send confirm per item'),
    ('LABEL_F8D94F', 'SaveFilter_DeselectAll',
     'Position 9: deselect all filters (lock all)'),
    ('LABEL_F8D962', 'SaveFilter_DeselectAll_Loop',
     'Loop: lock each filter, render and send confirm'),
    ('LABEL_F8D9A3', 'SaveFilter_OpSave',
     'Position 0xA (save): check conditions, execute save'),
    ('LABEL_F8D9D1', 'SaveFilter_Save_NoPwd',
     'Save: no password needed, check direct save or dialog'),
    ('LABEL_F8D9FD', 'SaveFilter_DispatchWidget',
     'Common: call widget dispatch (0xFA9D58)'),
    ('LABEL_F8DA04', 'SaveFilter_Save_Execute',
     'Save: open progress dialog, execute save operation'),
    ('LABEL_F8DA76', 'SaveFilter_OpFormat',
     'Position 0x32 (format): open progress, execute format'),
    ('LABEL_F8DAF1', 'SaveFilter_CallStatusDisplay',
     'Call status display (LABEL_F994BD)'),
    ('LABEL_F8DAF7', 'SaveFilter_ResetAll',
     'Position 0xB: reset all filters to unlocked'),
    ('LABEL_F8DB0A', 'SaveFilter_ResetAll_Loop',
     'Loop: unlock each filter, render and send confirm'),
    ('LABEL_F8DB48', 'SaveFilter_Return',
     'Return XHL=0, adjust stack'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'file_io', 'composer_filters.s')

    with open(src, 'rb') as f:
        content = f.read().decode('ascii')

    renamed = 0
    for old_label, new_label, comment in RENAMES:
        if old_label + ':' not in content and old_label not in content:
            print(f'  WARNING: {old_label} not found, skipping')
            continue

        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        new_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)

        if new_content != content:
            content = new_content
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:40s} ({refs} refs)')

    with open(src, 'wb') as f:
        f.write(content.encode('ascii'))

    print(f'\nRenamed {renamed} labels in composer_filters.s')


if __name__ == '__main__':
    main()
