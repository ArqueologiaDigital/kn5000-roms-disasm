#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in title_handlers.s (file manager title entry handlers).

Each function handles OK button events (0x1C00007) or progress events (0x1C00013)
for different file manager dialogs. FmmUtilityTitleFunc and FmmSmfUtilityTitleFunc
are nearly identical (file vs SMF variants).

Progress state machine: check disk (34048) → scan format (34050/34052) → execute → done.

Uses binary I/O to handle encoding safely.
"""

import os
import re

RENAMES = [
    # LoadTtlJgFunc (simple OK handler)
    ('LABEL_F8B808', 'LoadTtl_Return',
     'Return XHL=0'),

    # SaveTtlJgFunc
    ('LABEL_F8B819', 'SaveTtl_Return',
     'Return XHL=0'),

    # SaveSmfTtlJgFunc
    ('LABEL_F8B82A', 'SaveSmfTtl_Return',
     'Return XHL=0'),

    # SongMedleyTtlJgFunc
    ('LABEL_F8B849', 'SongMedleyTtl_Return',
     'Return XHL=0'),

    # SetupFlashFunc
    ('LABEL_F8B87C', 'SetupFlash_HandleLoadEvent',
     'Event 0x1E5000C (flash load): call FC5625'),
    ('LABEL_F8B882', 'SetupFlash_Return',
     'Return XHL=0'),

    # FmmUtilityTitleFunc - file manager utility progress state machine
    ('LABEL_F8B8D5', 'FmmUtility_DispatchState',
     'Dispatch by progress state: 0=error, 1=success, 5=cancel, else continue'),
    ('LABEL_F8B902', 'FmmUtility_ScanFormat',
     'Check format scan result (34050), skip if already done'),
    ('LABEL_F8B91E', 'FmmUtility_CheckCapacity',
     'Check capacity result (34052), proceed if available'),
    ('LABEL_F8B944', 'FmmUtility_HandleCancel',
     'State 5 (cancel): show/hide UI, call cancel handler'),
    ('LABEL_F8B988', 'FmmUtility_HandleError',
     'State 0 (error): dismiss progress, call handler with code 0x7D'),
    ('LABEL_F8B99B', 'FmmUtility_CallHandler',
     'Call operation handler (F99490) and jump to return'),
    ('LABEL_F8B9A1', 'FmmUtility_HandleSuccess',
     'State 1 (success): reset progress, show result, dismiss UI'),
    ('LABEL_F8B9E6', 'FmmUtility_ShowStatus',
     'Call status display (F994BD) and jump to return'),
    ('LABEL_F8B9EC', 'FmmUtility_ContinueWait',
     'Progress incomplete: dismiss progress, send wait event 0x1C0000A'),
    ('LABEL_F8BA0E', 'FmmUtility_HandleAbort',
     'Event value 3 (abort): call CancelOperationCleanup'),
    ('LABEL_F8BA11', 'FmmUtility_Return',
     'Return XHL=0'),

    # FmmSmfUtilityTitleFunc - identical pattern to FmmUtility, SMF variant
    ('LABEL_F8BA64', 'FmmSmfUtility_DispatchState',
     'Dispatch by progress state: 0=error, 1=success, 5=cancel, else continue'),
    ('LABEL_F8BA91', 'FmmSmfUtility_ScanFormat',
     'Check format scan result (34052), skip if already done'),
    ('LABEL_F8BAAD', 'FmmSmfUtility_CheckCapacity',
     'Check capacity result (34050), proceed if available'),
    ('LABEL_F8BAD3', 'FmmSmfUtility_HandleCancel',
     'State 5 (cancel): show/hide UI, call cancel handler'),
    ('LABEL_F8BB17', 'FmmSmfUtility_HandleError',
     'State 0 (error): dismiss progress, call handler with code 0x7D'),
    ('LABEL_F8BB2A', 'FmmSmfUtility_CallHandler',
     'Call operation handler (F99490) and jump to return'),
    ('LABEL_F8BB30', 'FmmSmfUtility_HandleSuccess',
     'State 1 (success): reset progress, show result, dismiss UI'),
    ('LABEL_F8BB75', 'FmmSmfUtility_ShowStatus',
     'Call status display (F994BD) and jump to return'),
    ('LABEL_F8BB7B', 'FmmSmfUtility_ContinueWait',
     'Progress incomplete: dismiss progress, send wait event 0x1C0000A'),
    ('LABEL_F8BB9D', 'FmmSmfUtility_HandleAbort',
     'Event value 3 (abort): call CancelOperationCleanup'),
    ('LABEL_F8BBA0', 'FmmSmfUtility_Return',
     'Return XHL=0'),

    # NOTE: External labels LABEL_F8B36E, LABEL_F8B435, LABEL_F8958D are
    # referenced from this file but defined in kn5000_v10_program.s and
    # referenced from many other include files (medley.s, disk_operations.s,
    # etc.). They should be renamed in a broader scope, not from this script.
]


def main():
    base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    src = os.path.join(base, 'maincpu', 'file_io', 'title_handlers.s')

    with open(src, 'rb') as f:
        content = f.read().decode('ascii')

    renamed = 0
    for old_label, new_label, comment in RENAMES:
        refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', content))
        if refs == 0:
            print(f'  WARNING: {old_label} not found, skipping')
            continue

        content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)
        renamed += 1
        print(f'  {old_label:25s} -> {new_label:40s} ({refs} refs)')

    # Also check and update the main program for cross-references
    main_src = os.path.join(base, 'maincpu', 'kn5000_v10_program.s')
    with open(main_src, 'rb') as f:
        main_content = f.read().decode('latin-1')

    main_renamed = 0
    for old_label, new_label, _ in RENAMES:
        main_refs = len(re.findall(r'\b' + re.escape(old_label) + r'\b', main_content))
        if main_refs > 0:
            main_content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, main_content)
            main_renamed += 1
            print(f'  {old_label:25s} (main: {main_refs} cross-refs)')

    with open(src, 'wb') as f:
        f.write(content.encode('ascii'))

    if main_renamed > 0:
        with open(main_src, 'wb') as f:
            f.write(main_content.encode('latin-1'))

    print(f'\nRenamed {renamed} labels in title_handlers.s')
    if main_renamed > 0:
        print(f'Updated {main_renamed} cross-references in kn5000_v10_program.s')


if __name__ == '__main__':
    main()
