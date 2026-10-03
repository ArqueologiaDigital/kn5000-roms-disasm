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
