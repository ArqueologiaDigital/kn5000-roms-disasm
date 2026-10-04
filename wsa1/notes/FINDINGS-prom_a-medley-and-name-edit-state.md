# prom_a: the SEQUENCER MEDLEY screen's bytes and the name editor's cursor (2026-10-03)

From round-1 pack prom_a-s00 (read and applied 2026-10-03; evidence lines in
`notes/lanes/wsa1-naming-r1-2026-10-02/accepted/prom_a-s00.json`), re-checked against the code.

## 1. SEQUENCER MEDLEY

| address | name | holds | evidence (prom_a) |
|---|---|---|---|
| 0x2208 | `Medley_FirstSong` | the first song of the medley, as index (shown + 1) | SequencerMedley_KeypadCommit stores value - 1 here for field 1, keeping first <= last; Draw_FirstS0ngLastS0ng |
| 0x2209 | `Medley_LastSong` | the last song | the same, field 2 |
| 0x220A | `Medley_PlayingSong` | the song now playing (shown + 1 after 'N0W PLAYING S0NG') | SequencerMedley_DrawPlayState |
| 0x220B | `Medley_Source` | 0 INT, 1 FD, 2 HD: the SELECT box filled; with Medley_FileType it bounds the song number (10 / 20 / 100) | SequencerMedley_DrawSourceBox (`(0x1303)=(0x220B)`), SequencerMedley_KeypadCommit |
| 0x0E35 | `Medley_FileType` | 0 NORM FILE, 1 MIDI FILE | SequencerMedley_DrawFileTypeBox (`(0x1304)=(0x0E35)`) |
| 0x0DC1 | `Medley_Playing` | 1 while the medley plays: the number pad and the field blink are ignored, 'N0W PLAYING S0NG' is drawn | SequencerMedley_NumberPad, _BlinkSelectedField, _DrawPlayState |
| 0x0C0F | `Medley_Field` | the selected field (1 FIRST S0NG, 2 LAST S0NG) | SequencerMedley_KeypadCommit, _BlinkSelectedField, _DrawFieldBox (`(0x1302)=(0x0C0F)`) |

## 2. The name editor

| address | name | holds | evidence (prom_a) |
|---|---|---|---|
| 0x222D | `NameEdit_CursorPos` | the character position the name cursor is on (0..5 for a song name) | S0ngSelectName_CursorLeft / _CursorRight step it; SongName_CharIndexAtCursor and SongName_StoreCharAtCursor index the name with it (18 routines, other name editors among them) |
| 0x21F9 | `NameEdit_CharIndex` | the index, in the editor's character set, of the character at the cursor | SongName_CharIndexAtCursor sets it (CharSet_F81768 lookup); SongName_NextCharAtCursor / _PrevCharAtCursor step it (clamped 0..0x24) |

## 3. The song-edit screens (same pack)

| address | name | holds | evidence (prom_a) |
|---|---|---|---|
| 0x0DE5 | `AdvanceDelay_Field` | the selected field; field 4 is the only signed one | AdvanceDelay_KeypadCommit / _KeypadSign / _BlinkSelectedField / _SelectField1 |
| 0x0DED | `N0teChange_Field` | the selected field (2/3 measures, 4/5 notes) | N0teChange_KeypadCommit, _BlinkSelectedField |
| 0x0DF0 | `N0teChange_FromMeasure` | field 2, 1..999 | N0teChange_KeypadCommit (also staged at (0x12FC)) |
| 0x0DF2 | `N0teChange_ToMeasure` | field 3, 1..999 | N0teChange_KeypadCommit ((0x12FF)) |
| 0x0DF4 | `N0teChange_FromNote` | field 4, note 0..127 | N0teChange_KeypadCommit ((0x12FB)) |
| 0x0DF5 | `N0teChange_ToNote` | field 5, note 0..127 | N0teChange_KeypadCommit ((0x12FE)) |
| 0x0DBC | `MeasureC0py_Field` | the selected field | MeasureC0py_KeypadCommit, _BlinkSelectedField |
| 0x0DDA | `MeasureInsert_Field` | the selected field | MeasureInsert_KeypadCommit, _BlinkSelectedField |
| 0x0E0C | `S0ngC0py_FromSong` | the source song (1-based: its name is read from bank value - 1) | S0ngC0py_DrawFromSong |
| 0x0E0D | `S0ngC0py_ToSong` | the destination song | S0ngC0py_DrawToSong |
| 0x0E0E | `S0ngC0py_FromTrack` | the source track; 0x12 = ALL (both columns read 'ALL') | S0ngC0py_DrawTracks |
| 0x0E0F | `S0ngC0py_ToTrack` | the destination track | S0ngC0py_DrawTracks |

The zero-for-O spelling follows the routines (the ROM's own text reads N0TE, C0PY, S0NG).  Not named:
ADVANCE/DELAY's three values (0x0DE8 / 0x0DEA / 0x0DEC -- which is which is not read here) and MEASURE
COPY / INSERT's 0x0C18 / 0x0C1A / 0x0C32 / 0x0DDE.

## 4. How the medley plays (2026-10-04)

`Medley_Start` / `Medley_Stop` / `Medley_Next` (directory slots `T_Medley_Start` / `T_Medley_Stop` / `T_Medley_Next`) dispatch
on `Medley_Source`.
- **INT** (internal songs).
  - `Medley_LoadInternalSong` scans the banks from `Medley_PlayingSong` to `Medley_LastSong`, wrapping to
    `Medley_FirstSong`, for one whose bank copy has an in-use directory entry.
  - It makes that bank `BStore_CurrentBank`, loads it, and copies its 6-character song name
    (`BStore_SongName`, workspace +0xCA) into `Medley_DisplayName` (0x0E38).
  - It sets `Medley_Countdown` (0x22D0) to 10.
  - `Medley_Tick` counts it down: at 5 the song starts, and at 0 the transports start from zero.
  - When the song ends, `Medley_AdvanceInternalSong` (`T_Medley_AdvanceInternalSong`) moves on.
  - With no song in the range, the screen shows status 0x2F and stops.
- **FD + MIDI FILE.** `Medley_StartMidiFile` mounts the disk, finds the next listed file from
  `Medley_PlayingSong`, and plays it. `Medley_Tick` moves to the next file when the countdown runs out.
  `Medley_ScheduleNextMidiFile` (`T_Medley_ScheduleNextMidiFile`) sets the countdown again. The floppy-song loader
  `Medley_LoadNextSongFromDisk` is described with the disk module.
