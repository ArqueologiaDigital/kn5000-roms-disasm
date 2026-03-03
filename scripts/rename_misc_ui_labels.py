#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in misc_ui.s (file I/O dialogs and UI utilities).

Based on analysis of event-dispatch patterns in each function. All functions follow
a consistent pattern: compare event code in XBC, branch to handler, common exit.

Event codes follow conventions:
  0x1C00001 = Init/Create    0x1C00002 = Close/Destroy
  0x1C00007 = OK/Confirm     0x1C0000B = Show/Activate
  0x1C0000F = Action/Select  0x1C00015 = Navigation
  0x1C00017 = Scroll Up      0x1C00018 = Scroll Down
  0x1C00019 = Scroll Up Done 0x1C0001A = Scroll Down Done
  0x1E0003A = Text Change    0x1E00062 = Copy Request
  0x1E00063 = Priority Query 0x1E00064 = Focus Request
  0x1E00065 = Default        0x1E0007C = Cancel
  0x1E00084 = Validate       0x1E00086 = Apply
  0x1E0009E = Show/Hide      0x1E50002 = List Selection
  0x1C50000 = Cancel State   0x1C50001 = OK State

Uses binary I/O to handle encoding safely.
"""

import os
import re

# Renames: (old_label, new_label, brief_comment)
RENAMES = [
    # JumpInsertFunc (lines 16-43)
    ('LABEL_F950B0', 'JumpInsert_DispatchBody',
     '.byte block: load offset table at EA96E4, dispatch via jp_dri'),
    ('LABEL_F950D6', 'JumpInsert_Error',
     'Range error: return XHL=0'),
    ('LABEL_F950DF', 'JumpInsert_Return',
     'Common exit: pop xiz, ret'),

    # FilePriorityFunc (lines 45-82)
    ('LABEL_F95127', 'FilePriority_ReturnPointer',
     'Event 0x63 (priority query): return pointer 0x340f4'),
    ('LABEL_F9512E', 'FilePriority_ReturnOne',
     'Event 0x64 (focus request): return XHL=1'),
    ('LABEL_F95132', 'FilePriority_DefaultReturn',
     'Default case / event 0x65: return XHL=0'),
    ('LABEL_F95134', 'FilePriority_Return',
     'Common exit: pop xiz, ret'),

    # SetupOkFunc (lines 84-93)
    ('LABEL_F9514C', 'SetupOk_Return',
     'Common exit: return XHL=0'),

    # SetupExitFunc (lines 95-129)
    ('LABEL_F951B6', 'SetupExit_Return',
     'Common exit: return XHL=0, pop xiz, ret'),

    # TechnicsFileNaming (lines 131-181)
    ('LABEL_F951F8', 'TechnicsFileNaming_Validate',
     'Event 0x84 (validate): return XHL=1'),
    ('LABEL_F951FC', 'TechnicsFileNaming_Cancel',
     'Event 0x7C (cancel): return XHL=6'),
    ('LABEL_F95200', 'TechnicsFileNaming_HandleOk',
     'Event 0x1C00007 (OK): apply name change, send navigation event'),
    ('LABEL_F9523A', 'TechnicsFileNaming_DefaultReturn',
     'Default case: return XHL=0'),
    ('LABEL_F9523C', 'TechnicsFileNaming_Return',
     'Common exit: pop xiz, inc 4 xsp, ret'),

    # TechnicsFileRename (lines 183-233)
    ('LABEL_F9527E', 'TechnicsFileRename_Validate',
     'Event 0x84 (validate): return XHL=1'),
    ('LABEL_F95282', 'TechnicsFileRename_Cancel',
     'Event 0x7C (cancel): return XHL=6'),
    ('LABEL_F95286', 'TechnicsFileRename_HandleOk',
     'Event 0x1C00007 (OK): apply rename, send close event'),
    ('LABEL_F952BD', 'TechnicsFileRename_DefaultReturn',
     'Default case: return XHL=0'),
    ('LABEL_F952BF', 'TechnicsFileRename_Return',
     'Common exit: pop xiz, inc 4 xsp, ret'),

    # SmfFileNaming (lines 235-285)
    ('LABEL_F95301', 'SmfFileNaming_Validate',
     'Event 0x84 (validate): return XHL=1'),
    ('LABEL_F95305', 'SmfFileNaming_Cancel',
     'Event 0x7C (cancel): return XHL=8'),
    ('LABEL_F9530C', 'SmfFileNaming_HandleOk',
     'Event 0x1C00007 (OK): apply name, send navigation event'),
    ('LABEL_F95346', 'SmfFileNaming_DefaultReturn',
     'Default case: return XHL=0'),
    ('LABEL_F95348', 'SmfFileNaming_Return',
     'Common exit: pop xiz, inc 4 xsp, ret'),

    # SmfFileRename (lines 287-337)
    ('LABEL_F9538A', 'SmfFileRename_Validate',
     'Event 0x84 (validate): return XHL=1'),
    ('LABEL_F9538E', 'SmfFileRename_Cancel',
     'Event 0x7C (cancel): return XHL=8'),
    ('LABEL_F95395', 'SmfFileRename_HandleOk',
     'Event 0x1C00007 (OK): apply rename, send close event'),
    ('LABEL_F953CC', 'SmfFileRename_DefaultReturn',
     'Default case: return XHL=0'),
    ('LABEL_F953CE', 'SmfFileRename_Return',
     'Common exit: pop xiz, inc 4 xsp, ret'),

    # FormatDiskNaming (lines 339-385)
    ('LABEL_F95410', 'FormatDiskNaming_Validate',
     'Event 0x84 (validate): return XHL=1'),
    ('LABEL_F95414', 'FormatDiskNaming_Cancel',
     'Event 0x7C (cancel): return XHL=0xB'),
    ('LABEL_F9541B', 'FormatDiskNaming_HandleOk',
     'Event 0x1C00007 (OK): apply name to format buffer'),
    ('LABEL_F95442', 'FormatDiskNaming_DefaultReturn',
     'Default case: return XHL=0'),
    ('LABEL_F95444', 'FormatDiskNaming_Return',
     'Common exit: pop xiz, inc 4 xsp, ret'),

    # DrawString_Centered (lines 387-445)
    ('LABEL_F9546E', 'DrawStr_LoopBody',
     'Character copy loop: compute source index, handle wrap-around'),
    ('LABEL_F95493', 'DrawStr_WrapAround',
     'Source index >= string length: wrap by subtracting length'),
    ('LABEL_F9549E', 'DrawStr_LoopCheck',
     'Increment counter, continue if < display width'),
    ('LABEL_F954A7', 'DrawStr_Epilogue',
     'Write null terminator, compute return values'),
    ('LABEL_F954BD', 'DrawStr_Return',
     'Common exit: popw iz, adjust stack, retd 2'),

    # WaitingFunc (lines 447-485)
    ('LABEL_F954EC', 'WaitingFunc_DrawMessage',
     'Event 0x1C0000B (show): lookup string, draw centered, send event'),
    ('LABEL_F9552D', 'WaitingFunc_Return',
     'Common exit: return XHL=0, pop xiz, adjust stack'),

    # DiskMedleyShowHideFunc (lines 487-499)
    ('LABEL_F95554', 'DiskMedley_Return',
     'Common exit: return XHL=0'),

    # PsFileNameBoxProc (lines 501-968) - large widget procedure
    ('LABEL_F95631', 'PsFileNameBox_Init_HideFirst',
     'Init: hide first scroll button, show second'),
    ('LABEL_F9564D', 'PsFileNameBox_Init_Configure',
     'Init: finalize button config, set cursor mode'),
    ('LABEL_F95657', 'PsFileNameBox_Init_Forward',
     'Init complete: forward init event to parent dispatcher'),
    ('LABEL_F95669', 'PsFileNameBox_HandleShow',
     'Event 0x1C0000B (show): draw list items, configure scroll buttons'),
    ('LABEL_F956E4', 'PsFileNameBox_DrawItem_Body',
     'Inner loop body: compute item position, draw name at row'),
    ('LABEL_F9570C', 'PsFileNameBox_DrawItem_Check',
     'Loop check: continue while item < total items'),
    ('LABEL_F95717', 'PsFileNameBox_CheckScrollButtons',
     'After drawing: configure scroll up/down button visibility'),
    ('LABEL_F9574E', 'PsFileNameBox_Scroll_HideDown',
     'Multi-page: hide down button, enable up button'),
    ('LABEL_F9576A', 'PsFileNameBox_Scroll_Apply',
     'Apply scroll button config, set scroll mode'),
    ('LABEL_F95777', 'PsFileNameBox_HandleConfirm',
     'Event 0x1C0000F (confirm/select): process selected item'),
    ('LABEL_F95826', 'PsFileNameBox_Confirm_Existing',
     'Confirm: selected item already exists, overwrite confirmation'),
    ('LABEL_F9583D', 'PsFileNameBox_Confirm_Execute',
     'Execute confirmation action (call 0xFAD084)'),
    ('LABEL_F95844', 'PsFileNameBox_Confirm_MultiItem',
     'Confirm: handle multi-item list (compute slot, validate bounds)'),
    ('LABEL_F95929', 'PsFileNameBox_Confirm_NewItem',
     'Confirm: new item slot, push empty params'),
    ('LABEL_F9593A', 'PsFileNameBox_Confirm_Finish',
     'Complete confirmation (call 0xFACACA)'),
    ('LABEL_F95941', 'PsFileNameBox_HandleListSelect',
     'Event 0x1E50002 (list selection): update selected index'),
    ('LABEL_F95957', 'PsFileNameBox_HandleScrollEvt',
     'Events 0x1C00017/18 (scroll up/down): forward to child widget'),
    ('LABEL_F959B6', 'PsFileNameBox_ScrollEvt_Down',
     'Scroll event was up → send paired down event'),
    ('LABEL_F959C5', 'PsFileNameBox_ScrollEvt_Send',
     'Execute scroll event forwarding'),
    ('LABEL_F959CB', 'PsFileNameBox_HandleScrollDone',
     'Events 0x1C00019/1A (scroll complete): check nav button state'),
    ('LABEL_F95A1C', 'PsFileNameBox_ScrollDone_PairDown',
     'Scroll done: send paired down-scroll event'),
    ('LABEL_F95A26', 'PsFileNameBox_ScrollDone_Forward',
     'Forward scroll-done event to child widget'),
    ('LABEL_F95A2A', 'PsFileNameBox_ReturnZero',
     'Return XHL=0 (handled), jump to exit'),
    ('LABEL_F95A2F', 'PsFileNameBox_HandleClose',
     'Event 0x1C00002 (close): clear OK flag, forward to parent'),
    ('LABEL_F95A50', 'PsFileNameBox_HandleCancelState',
     'Event 0x1C50000 (cancel state): toggle cancel flag, forward'),
    ('LABEL_F95A6B', 'PsFileNameBox_CancelState_Set',
     'Set cancel flag to 1'),
    ('LABEL_F95A6F', 'PsFileNameBox_CancelState_Forward',
     'Forward cancel-state to parent dispatcher'),
    ('LABEL_F95A80', 'PsFileNameBox_HandleOkState',
     'Event 0x1C50001 (OK state): toggle OK flag, forward'),
    ('LABEL_F95A9B', 'PsFileNameBox_OkState_Set',
     'Set OK flag to 1'),
    ('LABEL_F95A9F', 'PsFileNameBox_OkState_Forward',
     'Forward OK-state to parent dispatcher'),
    ('LABEL_F95AB0', 'PsFileNameBox_DefaultHandler',
     'Default: forward unrecognized event to parent dispatcher'),
    ('LABEL_F95ABF', 'PsFileNameBox_DispatchParent',
     'Call parent dispatcher (0xFA4409) with restored params'),
    ('LABEL_F95AC3', 'PsFileNameBox_Return',
     'Common exit: pop xiz, restore L, ret'),
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'file_io', 'misc_ui.s')

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

    print(f'\nRenamed {renamed} labels in misc_ui.s')


if __name__ == '__main__':
    main()
