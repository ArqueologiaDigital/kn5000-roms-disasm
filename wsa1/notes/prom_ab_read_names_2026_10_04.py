#!/usr/bin/env python3
"""Routines named by reading their bodies, 2026-10-04 -- the evidence for each, in one place.

QUESTION IT ANSWERS
  When no table or structural rule names a routine, it is named by reading it.  Each row is (old label,
  new label, what the body does that the name rests on).  The evidence is written to be checked against
  the routine's own instructions (python3 the session's rb.py viewer, or the listing).  Nothing here is
  inferred from a caller's name alone.  RAM names are wsa1/include/wsa1_ram.inc's.

RUN
  python3 notes/prom_ab_read_names_2026_10_04.py          # the table
  python3 notes/prom_ab_read_names_2026_10_04.py --args   # 'old=new|header' for the rename helper
"""
import sys

# the old label is kept as its bare address: the rename helper rewrites every old LABEL token in wsa1/notes
ROWS = [
    # prom_b 0xF65000-0xF66FFF: sequencer job screens
    ("F66619", "TrackAssignPresets_BankUp",
     "(0x0DFE) + 1, stopping at 10, and (0x0DFE) + 1 to DisplayListB_Stage+1; repaint bit 3.  (0x0DFE) is the bank\n"
     "the page shows: TrackAssignPresets_InitFromCurrentBank loads it from BStore_CurrentBank.  Called by SoftKeyCol3_TrackAssignPresets."),
    ("F66639", "TrackAssignPresets_BankDown",
     "(0x0DFE) - 1, stopping at 0, mirrored +1 to DisplayListB_Stage+1.  Called by SoftKeyCol2_TrackAssignPresets."),
    ("F665B4", "TrackAssignPresets_InitFromCurrentBank",
     "unless the previous screen latch is 0x11: (0x0DFD) = 1, (0x0DFE) = BStore_CurrentBank (+1 to the display stage),\n"
     "UI_StatusCode = 0; then, if UI_StatusCode is 0x23, requests screen 0x10.  Called by Paint_TrackAssignPresets."),
    ("F664AE", "StepRecordPartSelect_OpenStepRecord",
     "(0x0C90) = 1, (0x0DC8) = 0, and when the chosen part (0x0E5C) is 1..0x11: (0x12A0) = 0 and UI_Request = 0x800E,\n"
     "screen 0x0E = STEP RECORD.  Called by all eight SoftKeyColN_StepRecordPartSelect."),
    ("F664D5", "StepRecordPartSelect_ResetOnEntry",
     "(0x3010) = (0x60341E); on a newly entered screen (latch changed): chosen part (0x0E5C) = 0, (0x2130) |= 0x100,\n"
     "(0x2160) = 0xFFFF, (0x215E) = 0, (0x0C00) = 0, T_F409AC; then (0x34BB) |= 4.  Called by Paint_StepRecordPartSelect."),
    ("F66081", "TrackAssign_ReturnToStageZero",
     "unless (0x95) bit 2: (0x0DC0) = 0, UI_ScreenStage = 0, UI_Request_Hi |= 0x10.  Called by ExitKey_ and\n"
     "LcdKeyRow3_TrackAssign_StageNonZero."),
    ("F660ED", "SequencerMedley_InitOnEntry",
     "on a newly entered screen: (0x0E48) = (0x7F4D), Medley_Playing = 0, (0x22D0) = 0, (0x605068) |= 0x8000,\n"
     "BStore_LoadBankDirectory, T_F42410; then Blink_EnableThenStop unless the medley plays.  Called by Paint_SequencerMedley."),
    ("F66123", "BStore_LoadBankDirectory",
     "(0x60341E) = (0x360C); copies 3,072 bytes from 0x610000 + BStore_CurrentBank * 0xC00 to 0x603500, the song directory\n"
     "SmfSize_Pass and the block store walk."),
    ("F661F3", "Blink_EnableThenStop",
     "T_Blink_SetEnable(1) then T_Blink_Stop."),
    ("F66201", "SequencerMedley_StopPlayback",
     "when Medley_Playing is 1: clears it and (0x22D0); for an INT source, or FD with a NORM file: T_F43030 and, unless\n"
     "(0x0E48) bit 2, T_F42E98; otherwise (0x0E36) = 1 and T_F4257C.  Called by LcdKeyRow3_SequencerMedley and SequencerMedley_OnLeave."),
    ("F6625C", "SequencerMedley_StepFieldUp",
     "clears bit 7 of W, then SequencerMedley_StepFirstSong (Medley_Field 1) or _StepLastSong (2): the step goes UP."),
    ("F66278", "SequencerMedley_StepFieldDown",
     "sets bit 7 of W, then the same dispatch on Medley_Field: the step goes DOWN."),
    ("F66294", "SequencerMedley_StepFirstSong",
     "unless (0x95) bit 2: W bit 7 set -> Medley_FirstSong - 1 (floor 0); clear -> + 1 up to 9 (INT), 19 (disk, NORM file)\n"
     "or 99 (MIDI file); then the range fix-up 0xF662D7 and repaint bit 3."),
    ("F662F7", "SequencerMedley_StepLastSong",
     "the same as SequencerMedley_StepFirstSong on Medley_LastSong."),
    ("F6633A", "SequencerMedley_SetSourceInternal",
     "when not playing: Medley_Source = 0 (INT) and Medley_FileType = 0, each to its display stage, and both songs\n"
     "clamped to 9 (an INT medley has ten songs).  Called by SoftKeyCol2_SequencerMedley and Paint_SequencerMedley."),
    ("F660A0", "SequencerMedley_ClampSongRange",
     "clamps Medley_FirstSong to the source's last song (9 / 19 / 99) and Medley_LastSong (to 0 when beyond it), then\n"
     "keeps FIRST <= LAST, moving whichever one C (the previous FIRST) says did not change."),
    ("F65CD6", "TrackAssign_SelectTrackGroup",
     "BC = 10 (LcdKeyRow3) clears (0x0C07) bit 0 and sets (0x0C03) = 0; BC = 11 (LcdKeyRow4) sets the bit and (0x0C03) = 8;\n"
     "then (0x0C06) = the byte map 0x603422[(0x0C03)].  Called by LcdKeyRow3/4_TrackAssign_StageZero."),
]


def main():
    for o, n, ev in ROWS:
        if "--args" in sys.argv:
            print("sub_%s=%s|%s: %s" % (o, n, n, ev.replace("\n", "\\n  ")))
        else:
            print("sub_%-7s -> %s" % (o, n))
    if "--args" not in sys.argv:
        print("rows %d" % len(ROWS))


if __name__ == "__main__":
    main()
