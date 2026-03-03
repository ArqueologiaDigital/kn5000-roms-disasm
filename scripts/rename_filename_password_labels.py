#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in filename_password.s (password and filename UI).

Three functions handle file manager password entry and filename display:
  FmmPasswordFunc      - Password entry dialog (events 0x1E5000D-0x1E50010)
  SelectPasswordMode   - Helper: determine which password mode (load/save/both)
  FmmFileNameFunc      - Filename list display and file operations

Password modes (stored at 35340):
  0 = none, 1 = load only, 2 = save only, 3 = both load+save

File operation dispatch (via xiz parameter to FmmFileNameFunc):
  0 = scroll position   1 = page up      2 = page down
  3 = save              4 = load          5 = delete
  6 = navigate/select   0x32 = format     0x33 = format variant

Uses binary I/O to handle encoding safely.
"""

import os
import re

# Renames: (old_label, new_label, brief_comment)
RENAMES = [
    # FmmPasswordFunc (lines 11-175) - Password entry dialog
    ('LABEL_F8C95A', 'Password_ShowError',
     'No valid slot data: show error status code 10'),
    ('LABEL_F8C969', 'Password_ClearAndSetSlot',
     'Clear all slots, set current, set flags bits 7+6'),
    ('LABEL_F8C980', 'Password_HandleDeleteEvent',
     'Event 0x1E5000E: check slot conditions for delete'),
    ('LABEL_F8C9AB', 'Password_Delete_CheckLoadOnly',
     'Mode 1 (load only): check slot selected, set bit 7'),
    ('LABEL_F8C9CC', 'Password_Delete_CheckSaveOnly',
     'Mode 2 (save only): check current slot, set bit 6'),
    ('LABEL_F8C9EB', 'Password_ForwardToFileName',
     'Common: call FmmFileNameFunc with scroll event'),
    ('LABEL_F8C9F1', 'Password_ShowErrorStatus',
     'Show error status code 11'),
    ('LABEL_F8C9FC', 'Password_HandleSaveEvent',
     'Event 0x1E5000F: check slot conditions for save'),
    ('LABEL_F8CA2A', 'Password_Save_CheckLoadOnly',
     'Mode 1 (load only): check slot selected, set bit 7'),
    ('LABEL_F8CA4E', 'Password_Save_CheckSaveOnly',
     'Mode 2 (save only): check current slot, set bit 6'),
    ('LABEL_F8CA70', 'Password_ForwardToSaveFilter',
     'Common: call FmmSaveFilterFunc with scroll event'),
    ('LABEL_F8CA75', 'Password_SaveErrorStatus',
     'Show error status code 11 for save'),
    ('LABEL_F8CA7F', 'Password_HandleLoadEvent',
     'Event 0x1E50010: check slot selected, forward to seq song name'),
    ('LABEL_F8CA9A', 'Password_LoadErrorStatus',
     'Show error status code 11 for load'),
    ('LABEL_F8CAA2', 'Password_CallStatusDisplay',
     'Call status display (LABEL_F994BD)'),
    ('LABEL_F8CAA6', 'Password_Return',
     'Return XHL=0, pop xiz, adjust stack'),

    # SelectPasswordMode (lines 177-241) - Determine password mode
    ('LABEL_F8CACE', 'SelectMode_CheckSaveAvail',
     'After load check: test save conditions'),
    ('LABEL_F8CAE9', 'SelectMode_DetermineMode',
     'Both checked: determine mode byte from available operations'),
    ('LABEL_F8CB05', 'SelectMode_SetBothMode',
     'Both available, same slot: set mode 3'),
    ('LABEL_F8CB0B', 'SelectMode_SingleMode',
     'Only one mode available: check which one'),
    ('LABEL_F8CB19', 'SelectMode_CheckSaveOnlyMode',
     'Load not available: check if save available, set mode 2'),
    ('LABEL_F8CB22', 'SelectMode_StoreMode',
     'Store mode byte to 35340'),
    ('LABEL_F8CB24', 'SelectMode_Return',
     'Load mode result, return HL'),

    # FmmFileNameFunc (lines 243-806) - Filename list and file operations
    ('LABEL_F8CB84', 'FileName_ListSelect_Negative',
     'Event 0x1E50004: negative index result, clear callback'),
    ('LABEL_F8CB95', 'FileName_ListSelect_Forward',
     'Send list selection event to widget'),
    ('LABEL_F8CBA2', 'FileName_HandleShow',
     'Event 0x1C0000B (show): draw item list'),
    ('LABEL_F8CBA7', 'FileName_DrawItemLoop',
     'Loop body: compute row offset, draw filename at position'),
    ('LABEL_F8CC0C', 'FileName_HandleScroll',
     'Events 0x1C00017/18 (scroll up/down): process scroll'),
    ('LABEL_F8CC33', 'FileName_ScrollUp',
     'Scroll up: decrement position if > 0'),
    ('LABEL_F8CC49', 'FileName_PageUp',
     'xiz=1: page up, subtract 10 from position'),
    ('LABEL_F8CC60', 'FileName_PageDown',
     'xiz=2: page down, add 10 to position'),
    ('LABEL_F8CC7B', 'FileName_ScrollApply',
     'Common scroll: update display state registers'),
    ('LABEL_F8CC86', 'FileName_OpSave',
     'xiz=3 (save): create dialog, init operation, execute save'),
    ('LABEL_F8CD18', 'FileName_OpSave_ShowCodeA',
     'Save: show progress code 0xA'),
    ('LABEL_F8CD1D', 'FileName_OpSave_ShowCode1',
     'Save: show progress code 1'),
    ('LABEL_F8CD1F', 'FileName_OpSave_CallHandler',
     'Save: call operation handler, dismiss dialog'),
    ('LABEL_F8CD39', 'FileName_OpLoad',
     'xiz=4 (load): check conditions, open with/without password'),
    ('LABEL_F8CD65', 'FileName_OpLoad_NoPwd',
     'Load: no password needed, open directly or show dialog'),
    ('LABEL_F8CD94', 'FileName_OpLoad_Execute',
     'Load: open progress dialog, execute load operation'),
    ('LABEL_F8CE07', 'FileName_OpFormat',
     'xiz=0x32 (format): open progress, execute format'),
    ('LABEL_F8CE82', 'FileName_OpDelete',
     'xiz=5 (delete): check conditions, open confirm/execute'),
    ('LABEL_F8CEB7', 'FileName_OpDispatch',
     'Common: call widget dispatch (0xFA9D58), jump to exit'),
    ('LABEL_F8CEBE', 'FileName_OpDelete_Execute',
     'Delete: open progress dialog, execute delete operation'),
    ('LABEL_F8CF0B', 'FileName_OpFormatVariant',
     'xiz=0x33 (format variant): open progress, execute format'),
    ('LABEL_F8CF60', 'FileName_OpNavigate',
     'xiz=6 (navigate): adjust selection index within list'),
    ('LABEL_F8CF91', 'FileName_Navigate_ScrollUp',
     'Navigate: scroll up case, decrement selection'),
    ('LABEL_F8CFA5', 'FileName_Navigate_CheckChanged',
     'Navigate: if position changed, update display'),
    ('LABEL_F8CFF4', 'FileName_CallStatusDisplay',
     'Call status display (LABEL_F994BD)'),
    ('LABEL_F8CFF8', 'FileName_GetSelection',
     'Get current selection index from 32634'),
    ('LABEL_F8CFFC', 'FileName_UpdateDisplay',
     'Redraw list items, refresh slot buttons'),
    ('LABEL_F8D05A', 'FileName_UpdateButtons_Loop',
     'Loop: update visibility of 8 slot buttons'),
    ('LABEL_F8D072', 'FileName_UpdateButtons_Hide',
     'Slot not selected: hide button'),
    ('LABEL_F8D076', 'FileName_UpdateButtons_Check',
     'Loop check: continue for 8 buttons'),
    ('LABEL_F8D09C', 'FileName_CheckCallback',
     'Check callback registration, compute feature bits'),
    ('LABEL_F8D0CB', 'FileName_Callback_SetFilter',
     'Set filter bits for callback features'),
    ('LABEL_F8D0E4', 'FileName_Callback_Send',
     'Send callback event (0x1E50001) with feature bits'),
    ('LABEL_F8D0F3', 'FileName_Callback_Simple',
     'Simplified callback path (item 103)'),
    ('LABEL_F8D106', 'FileName_HandleRegister',
     'Event 0x1E50000: register callback, determine features'),
    ('LABEL_F8D130', 'FileName_Register_SetFilter',
     'Register: set filter bits for features'),
    ('LABEL_F8D149', 'FileName_Register_Send',
     'Register: send callback with feature bits'),
    ('LABEL_F8D158', 'FileName_Register_Simple',
     'Register: simplified path (item 103)'),
    ('LABEL_F8D169', 'FileName_DispatchWidget',
     'Common: call widget dispatch (0xFA9D58)'),
    ('LABEL_F8D16D', 'FileName_Return',
     'Return XHL=0, pop xiz, adjust stack'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'file_io', 'filename_password.s')

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

    print(f'\nRenamed {renamed} labels in filename_password.s')


if __name__ == '__main__':
    main()
