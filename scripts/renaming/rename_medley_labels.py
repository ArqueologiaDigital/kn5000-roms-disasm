#!/usr/bin/env python3
"""Rename LABEL_* to semantic names in medley.s (medley playback operations).

Functions and the LABEL_* symbols remaining in this file:

  GetPlayState1/GetPlayState2 (lines 1761-1769):
    LABEL_F92C0E / LABEL_F92C13 — entry-point labels preceding named function
    labels for the two tiny play-state accessors (load byte from 35138/35140).
    These appear as a LABEL_ line immediately above the named function label.

  NavigateSongList / NavigateDocList / NavigatePdList (lines 1775-1884):
    LABEL_F92C21 / LABEL_F92C70 / LABEL_F92CAC — entry-point labels above the
    respective named Navigate* function labels. Each function navigates a list
    by ±1 with wrap-around (counts stored at 34052, 34056, 34054 respectively).

  FmmSmfMedleyFunc — SmfMed_HandleStop (lines 2225-2239):
    LABEL_F93051 — sits above SmfMed_HandleStop, which is branched to from
    FmmSmfMedleyFunc when event 0x1C00013 with xde=3 (stop). Checks play-mode
    byte at 36150 (0x6F/0x72/0x73/0x76) and calls F20B70 to stop playback.

  PdMed_FormatFileList (lines 2474-2521):
    LABEL_F93283 — entry-point above PdMed_FormatFileList, which formats up to
    10 performance-data file entries (32-byte records at 34060) for list display
    using LABEL_F891DD (text copy), sending 0x1C0000F events to a widget.

  FmmPdMedleyFunc (lines 2806-3226):
    LABEL_F935C0 — entry-point above FmmPdMedleyFunc, the main event handler
    for the performance data medley controller.  Handles events 0x1C00017/18
    (nav), 0x1C0000B (show/refresh), 0x1E50004 (store widget ptr), 0x1C00013
    (progress: stop=3, play=2), 0x1E50008 (delay flag), 0x1E5000A (continue).

  PdMed_InitFromDisk — inside FmmPdMedleyFunc (lines 2945-2995):
    LABEL_F9373F — entry-point above PdMed_InitFromDisk.  Reached when play-
    mode byte != 0x75: opens progress dialog, calls LABEL_F8A625 to scan PD
    files, stores count at 34054, closes dialog, inits slot array, calls F20ACD.

  DocDiskNameFunc (lines 3228-3280):
    LABEL_F939CE — entry-point above DocDiskNameFunc. On event 0x1C0000B (show)
    reads disk label via LABEL_F8958D, strips internal spaces, trims trailing
    spaces, sends 0x1C0000F event to widget in XDE.

  DocMed_FormatSlotList (lines 3526-3612):
    LABEL_F93C9C — entry-point above DocMed_FormatSlotList.  Formats up to 10
    document medley slot entries with FormatMedleyNumber, fills remainder with
    0xFF (empty marker), sends 0x1C0000F events to slot-list widget.

  DocMed_CheckInit — inside FmmDocMedleyFunc (lines 3752-3807):
    LABEL_F93EEA — entry-point above DocMed_CheckInit. Branched to when play-
    mode byte != 0x74: checks doc count at 34056 and SMF count at 34052 to
    decide whether to reload from disk (DocMed_InitFromDisk) or go straight to
    DocMed_InitState which resets the slot array and calls F20ACD.

  Song slot utilities (lines 4044-4174):
    LABEL_F94193 — SetSongSlotValue   write BC to slot at 0x0AB000+WA*0x800+0x1C
    LABEL_F941C8 — GetSongSlotValue   read 16-bit value from same location
    LABEL_F941E5 — CheckSongSlotHasData  return 1 if slot value != 0
    LABEL_F941ED — SongSlot_RawData   12-byte raw data block (not a function)
    LABEL_F941F9 — FindFirstEmptySlot  scan 0..9, return first slot where value==0
    LABEL_F9420F — ClearAllSongSlots   write BC to all 10 slots via SetSongSlotValue
    LABEL_F94229 — ResetSlotsIfEmpty   clear all slots if FindFirstEmptySlot != 0
    LABEL_F94236 — CheckSlotIsSelected return 1 if slot WA == FindFirstEmptySlot
    LABEL_F94242 — CheckAnySlotHasData return 1 if FindFirstEmptySlot result != 0
    LABEL_F9424A — SetCurrentSlotIndex store XWA to 0x09480E
    LABEL_F94250 — GetCurrentSlotIndex load XHL from 0x09480E
    LABEL_F94256 — CheckIsCurrentSlot  return 1 if WA == current index at 0x09480E
    LABEL_F94262 — CheckSlotIndexValid  return 1 if current index at 0x09480E != 0

Cross-reference check (verified):
  No LABEL_F92C* / LABEL_F93* / LABEL_F94* labels from this file are referenced
  in any other .s file (kn5000_v10_program.s, file_io/*.s, etc.).
  Only maincpu/file_io/medley.s needs to be updated.

Uses binary I/O to handle encoding safely.
"""

import os
import re

# Renames: (old_label, new_label, brief_comment)
RENAMES = [
    # GetPlayState1 / GetPlayState2 — tiny play-state read accessors
    # (lines 1761-1769: LABEL_ line sits above the named function label)
    ('LABEL_F92C0E', 'GetPlayState1_Entry',
     'Entry alias for GetPlayState1: ldda8 l, 35138, ret (play state var 1)'),
    ('LABEL_F92C13', 'GetPlayState2_Entry',
     'Entry alias for GetPlayState2: ldda8 l, 35140, ret (play state var 2)'),

    # NavigateSongList — navigate song list ±1 with wrap-around
    # (line 1775: LABEL_ immediately above NavigateSongList function label)
    ('LABEL_F92C21', 'NavigateSongList_Entry',
     'Entry alias for NavigateSongList: WA=1 forward / WA=FFFF backward, wraps at 34052'),

    # NavigateDocList — navigate document list ±1 with wrap-around
    # (line 1816: same pattern, uses doc count at 34056)
    ('LABEL_F92C70', 'NavigateDocList_Entry',
     'Entry alias for NavigateDocList: WA=1 forward / WA=FFFF backward, wraps at 34056'),

    # NavigatePdList — navigate performance-data list ±1 with wrap-around
    # (line 1851: same pattern, uses PD count at 34054)
    ('LABEL_F92CAC', 'NavigatePdList_Entry',
     'Entry alias for NavigatePdList: WA=1 forward / WA=FFFF backward, wraps at 34054'),

    # SmfMed_HandleStop — stop handler inside FmmSmfMedleyFunc
    # (line 2225: event 0x1C00013 xde=3; checks mode byte at 36150, calls F20B70)
    ('LABEL_F93051', 'SmfMed_HandleStop_Entry',
     'Entry alias for SmfMed_HandleStop: verify mode byte at 36150, stop SMF playback'),

    # PdMed_FormatFileList — format 10 PD file entries for list display
    # (line 2474: dec 6, xsp; pushw iz; formats 10 x 32-byte entries at 34060)
    ('LABEL_F93283', 'PdMed_FormatFileList_Entry',
     'Entry alias for PdMed_FormatFileList: format 10 PD file entries, send 0x1C0000F events'),

    # FmmPdMedleyFunc — performance data medley controller (main function)
    # (line 2806: push xiz; dispatches 0x1C00017/18/0B, 0x1E50004/8/A, 0x1C00013)
    ('LABEL_F935C0', 'FmmPdMedleyFunc_Entry',
     'Entry alias for FmmPdMedleyFunc: performance data medley controller'),

    # PdMed_InitFromDisk — load PD file list from disk and initialize slots
    # (line 2945: branch from FmmPdMedleyFunc when mode != 0x75; opens progress dialog)
    ('LABEL_F9373F', 'PdMed_InitFromDisk_Entry',
     'Entry alias for PdMed_InitFromDisk: load PD files from disk via F8A625, init slot array'),

    # DocDiskNameFunc — display document disk name (strip spaces, trim trailing)
    # (line 3228: push xiz; only handles 0x1C0000B; strips internal+trailing spaces)
    ('LABEL_F939CE', 'DocDiskNameFunc_Entry',
     'Entry alias for DocDiskNameFunc: read disk label via F8958D, trim, send 0x1C0000F'),

    # DocMed_FormatSlotList — format 10 document slot entries for medley list
    # (line 3526: dec 6, xsp; queries FmmDocFileNameFunc for count, formats slots)
    ('LABEL_F93C9C', 'DocMed_FormatSlotList_Entry',
     'Entry alias for DocMed_FormatSlotList: format up to 10 doc slot entries with FormatMedleyNumber'),

    # DocMed_CheckInit — check doc/SMF counts and trigger disk reload if needed
    # (line 3752: branch from FmmDocMedleyFunc when mode != 0x74; checks 34056/34052)
    ('LABEL_F93EEA', 'DocMed_CheckInit_Entry',
     'Entry alias for DocMed_CheckInit: check doc count at 34056, reload from disk if needed'),

    # SetSongSlotValue — write song slot value at 0x0AB000+slot*0x800+0x1C
    # (line 4044: cp wa,0xA; ret nc; guards slot range 0..9)
    ('LABEL_F94193', 'SetSongSlotValue_Entry',
     'Entry alias for SetSongSlotValue: write BC to 0x0AB000+WA*0x800+0x1C (+ mirror at 0xF180)'),

    # GetSongSlotValue — read song slot value from 0x0AB000+slot*0x800+0x1C
    # (line 4064: lds hl,0; cp wa,0xA; ret nc; returns 0 for out-of-range)
    ('LABEL_F941C8', 'GetSongSlotValue_Entry',
     'Entry alias for GetSongSlotValue: read 16-bit value from 0x0AB000+WA*0x800+0x1C into HL'),

    # CheckSongSlotHasData — return 1 if slot value is non-zero
    # (line 4077: calls GetSongSlotValue, scc16 nz, hl)
    ('LABEL_F941E5', 'CheckSongSlotHasData_Entry',
     'Entry alias for CheckSongSlotHasData: return HL=1 if slot WA has non-zero value'),

    # SongSlot_RawData — 12-byte data block (not a callable function)
    # (line 4084: .byte block immediately before FindFirstEmptySlot)
    ('LABEL_F941ED', 'SongSlot_RawData_Start',
     'Start of 12-byte raw data block preceding FindFirstEmptySlot'),

    # FindFirstEmptySlot — scan slots 0-9, return first with value == 0
    # (line 4089: pushw iz; lds iz,0; loop calling GetSongSlotValue)
    ('LABEL_F941F9', 'FindFirstEmptySlot_Entry',
     'Entry alias for FindFirstEmptySlot: return HL=first slot index where value==0 (10 if all full)'),

    # ClearAllSongSlots — write BC value to all 10 song slots
    # (line 4107: push xiz; ld iz,wa; loops SetSongSlotValue for slots 0..9)
    ('LABEL_F9420F', 'ClearAllSongSlots_Entry',
     'Entry alias for ClearAllSongSlots: write BC to all 10 slots via SetSongSlotValue'),

    # ResetSlotsIfEmpty — clear all slots if FindFirstEmptySlot returns non-zero
    # (line 4123: calls FindFirstEmptySlot; if HL!=0 calls ClearAllSongSlots)
    ('LABEL_F94229', 'ResetSlotsIfEmpty_Entry',
     'Entry alias for ResetSlotsIfEmpty: if any slot has data, clear all 10 slots'),

    # CheckSlotIsSelected — return 1 if slot WA matches FindFirstEmptySlot result
    # (line 4132: pushw iz; ld iz,wa; calr FindFirstEmptySlot; cp hl,iz; scc16 z,hl)
    ('LABEL_F94236', 'CheckSlotIsSelected_Entry',
     'Entry alias for CheckSlotIsSelected: return HL=1 if slot WA matches first-empty index'),

    # CheckAnySlotHasData — return 1 if FindFirstEmptySlot result != 0
    # (line 4142: calr FindFirstEmptySlot; cps hl,0; scc16 nz,hl)
    ('LABEL_F94242', 'CheckAnySlotHasData_Entry',
     'Entry alias for CheckAnySlotHasData: return HL=1 if any slot has data (first-empty != 0)'),

    # SetCurrentSlotIndex — store slot index XWA to 0x09480E
    # (line 4149: st16_24 0x09480E, xwa; ret)
    ('LABEL_F9424A', 'SetCurrentSlotIndex_Entry',
     'Entry alias for SetCurrentSlotIndex: write XWA to external slot index at 0x09480E'),

    # GetCurrentSlotIndex — load slot index XHL from 0x09480E
    # (line 4154: ld16_24 xhl, 0x09480E; ret)
    ('LABEL_F94250', 'GetCurrentSlotIndex_Entry',
     'Entry alias for GetCurrentSlotIndex: read external slot index from 0x09480E into XHL'),

    # CheckIsCurrentSlot — return 1 if slot WA equals current index at 0x09480E
    # (line 4159: pushw iz; ld iz,wa; calr GetCurrentSlotIndex; cp hl,iz; scc16 z,hl)
    ('LABEL_F94256', 'CheckIsCurrentSlot_Entry',
     'Entry alias for CheckIsCurrentSlot: return HL=1 if slot WA equals current index at 0x09480E'),

    # CheckSlotIndexValid — return 1 if current index at 0x09480E is non-zero
    # (line 4169: calr GetCurrentSlotIndex; cps hl,0; scc16 nz,hl)
    ('LABEL_F94262', 'CheckSlotIndexValid_Entry',
     'Entry alias for CheckSlotIndexValid: return HL=1 if current slot index at 0x09480E != 0'),
]

FILES_TO_SCAN = [
    ('maincpu/file_io/medley.s', 'ascii'),
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
                print(f'  WARNING: {old_label} not found, skipping')
                continue

            content = re.sub(r'\b' + re.escape(old_label) + r'\b', new_label, content)
            renamed += 1
            print(f'  {old_label:25s} -> {new_label:45s} ({refs} refs in {rel_path})')

        with open(src, 'wb') as f:
            f.write(content.encode(encoding))

        if renamed > 0:
            print(f'  Renamed {renamed} labels in {rel_path}')
        else:
            print(f'  No labels renamed in {rel_path}')

    print(f'\nDone.')


if __name__ == '__main__':
    main()
