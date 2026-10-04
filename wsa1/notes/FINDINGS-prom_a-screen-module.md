# prom_a 0xFEF746-0xFF3800: the SCREEN-DRAW module, and a split the ROM proves

Wave 6 round 2, 2026-08-25. **11,044 substantive bytes converted** (plus a
5,526-byte `0x0E` pad, disclosed separately and not in that figure); the byte
gate passes. This closes prom_a's third-largest remaining `.incbin` and takes
prom_a from 17 unconverted spans to 16.

Everything below is re-derived by `python3 notes/gen_prom_a_screens.py --check`,
which prints its own numbers and **refuses to emit the region** if either of the
two framing tests fails. The generator reproduces the inserted text line for
line, so the source and the script cannot drift.

---

## 1. Why this span, and why it was hard

`ld XIY,<start> / ld XIX,<end> / call 0xF417F0` is the WSA1's display-list call
(`notes/FINDINGS-ui-display-list.md`). A scan of both images for that shape,
filtered to targets in this range, returns **56 spans** — and the lists are
**inline**, sitting immediately after the `ret` of the routine that draws them:

```
sub_FEF778:
        ld (0x2540),0x00        ; which display layer
        ld XIY,0x00FEF78C       ; list start
        ld XIX,0x00FEF796       ; list end
        call 0xF417F0           ; DisplayList_Run
        ret
DisplayList_FEF78C:             ; <- the data, 10 bytes, then code again
        .byte 0x1B, 0x0A        ; op 1B, 10 bytes, handler 0xF31A75
        .byte 0x08, 0x00, 0xB2, 0x00, 0xE8, 0x00, 0xC0, 0x00
sub_FEF796:
        ld (0x2540),0x01
        ...
```

Code and data alternate every few bytes for 11 KB. A linear decode of the whole
span is worthless — which is exactly why it was still `.incbin`.

## 2. The two tests that make the split a decode

**TEST 1 — the length walk.** A display-list record is `+0 opcode,
+1 LENGTH OF THE WHOLE RECORD`, and the interpreter advances by that byte. So
walking the length bytes from the `<start>` immediate must land **exactly** on
the `<end>` immediate. It does for **56 of 56** spans, 347 records in all. (For
scale, prom_b's 244 spans came in at 243.) The two ends are chosen by the
linker, not by the decode, so agreement is evidence rather than tautology.

**TEST 2 — zero undecodable bytes in what is left.** With the 56 lists and the
13 tables of §3 removed, a linear disassembly of the remaining 3,956 bytes
produces **no undecodable byte at all**. This test can fail and did, repeatedly,
while the table boundaries were being found: get one boundary wrong and the
decode desynchronises and starts printing `db`. The last four `db` bytes are
what located `NoteNames`, `OctaveNames`, `TickLabels` and `CoordTable_FF00D1`.

⚠ **What the two tests do NOT establish** is where the SPAN starts. 0xFEF746 is
pinned by the `.incbin` boundary and by being a `ld (0x2540),0x00` prologue, not
by either test.

⚠ **5 of the 3,956 code bytes are emitted as `.byte`** — 0xFF0162, 0xFF016E,
0xFF017B, 0xFF0181, 0xFF01F5 — with unidasm's text in a trailing comment. They
decode; this toolchain cannot spell them back
(`notes/llvm-mc-tlcs900-spellings.md`). They are instructions, not data.

## 3. The thirteen tables

| at | shape | what says so |
|---|---|---|
| 0xFEF999 | 13 × 1 char, `"0123456789***"` | `ld XIY` at 0xFEF973, `ld BC,1` = the WIDTH, SWI7 service 0x17 |
| 0xFEF9FA | 12 × u32 | `XIY += E*4; XIY = (XIY); call T,XIY` at 0xFEF9D0-0xFEF9E0 |
| 0xFEFA2A | 9 × u32 | the same read, the arm taken when `(0x601F70)` bit 0 is SET |
| 0xFEFDE4 | 1 byte, 0x12 | `ld XIY` at 0xFEFDD6, HL = 0, BC = 1 |
| 0xFEFE58 | 1 byte, 0xAF | `ld XIY` at 0xFEFE4A, same shape |
| 0xFEFFDD | 11 × u16 | `ld A,(XIX+) / ld W,(XIX)` at 0xFEFFD7, stride 2 |
| 0xFF0058 | 29 × u16 | value goes straight to `(0x2532)`, the Y-coordinate cell |
| 0xFF00D1 | 14 × u16 | the same, step 10 rather than 4 |
| 0xFF047F | the kit-category legends — §4 | the five-way type switch at 0xFF03E9 |
| 0xFF0B08 | 13 × 2 chars | the chromatic note names |
| 0xFF0B22 | 12 × 2 chars | `"-2"` … `"9 "` |
| 0xFF0D65 | 99 × 2 chars | §5 |
| 0xFF17E2 | 2,695 bytes | period-8 data, **not decoded** |

**The note and octave tables** are `" C" "D♭" " D" "E♭" " E" " F" "F♯" " G"
"A♭" " A" "B♭" " B" " C"` — thirteen, with C repeated, which is what a
note-plus-octave formatter needs when the index runs one past B — and `"-2"`
through `"9 "`, twelve octaves, the range a 128-note MIDI keyboard spans when
C-2 is note 0. 0x88 is the flat glyph and 0x8C the sharp one; both are custom
font cells, not ASCII.

**`Data_FF17E2` is honest ignorance.** It is data because a disassembly of it is
nonsense and because the byte pattern repeats on an 8-byte period
(`FF 00 00 00 00 00 FC FC`, `FF 01 01 01 01 01 01 01`, …). Nothing in either
image names any address inside it; what names its START is that it is the `end`
immediate of the display list at 0xFF158A. A bitmap, an envelope table and a
per-step pattern grid all fit; none is claimed.

## 4. ★ The kit-category legends are the General MIDI drum-kit map — gap O

`Screen_DrawKitCategoryLegend` (0xFF03C2) draws a six-character legend at
x = 0xD5, y = 6. It gets the index from `KitCategoryLegend_Index` (0xFF043C) and
the base from `KitCategoryLegend_SelectBase` (0xFF03E9), and the base is chosen
by the **+0x01 type byte of a `RecordPtrs_RAM76A2` record** — the same five-way
switch on the same byte that 0xFEB2E3 uses to pick a drum-NAME block:

| type | base | legend |
|---|---|---|
| 0x20 | 0xFF0485 | indexed by the record's +0x00 byte |
| 0x28 | 0xFF079D | `user1 ` |
| 0x29 | 0xFF07AB | `user2 ` |
| 0x30 | 0xFF07B9 | `ext   ` |
| else | 0xFF047F | six spaces |

★ **The index is the MIDI drum-program number, ZERO-BASED.** From 0xFF0485:

| idx | legend | General MIDI kit (1-based program) |
|---|---|---|
| 0 | `STANDR` | Standard (1) |
| 8 | `ROOM  ` | Room (9) |
| 16 | `POWER ` | Power (17) |
| 24 | `ELEC  ` | Electronic (25) |
| 32 | `JAZZ  ` | Jazz (33) |
| 40 | `BRUSH ` | Brush (41) |
| 48 | `GMOrch` | Orchestra (49) |

Technics fills the gaps — 9 `LIGHT`, 10 `FUNK`, 25 `SOUL`, 26 `DANCE`,
27 `HOUSE`, 29 `SYNTH`, 30 `MODEL`, 33 `TRAD`, 112 `ORCH`, 120 `SE` — and
everything else is blank.

★ **The test has a negative control and the control did its job.** The check in
`--check` scores the seven GM keywords at their own index and at ±1: **7/7
aligned, 0/7 either side**. A first draft used the 1-based program numbers
against base 0xFF047F and scored **0/7 aligned and 7/7 at shift −1** — which is
precisely what an off-by-one looks like when the control is there to show it.
Last-entry test: the highest non-blank entry is 120, `SE    `; 130 entries × 6
from 0xFF047F ends at 0xFF078B, and **130 is exactly the entry count of
`DrumKitNameBlockPtrs` (0xFEB3BC)** — two tables written independently agreeing
on the program count.

**Why this is a gap-O result.** Gap O asks for a way to say what a number in
this machine MEANS in words a user would recognise. Together with the
percussion-name tie in `notes/FINDINGS-prom_a-dispatch-matrix-and-drum-names.md`
(the name index IS the MIDI note number), the drum subsystem now has both of
its index→legend directions: **program number → kit legend**, and **note number
→ instrument name**.

## 5. `TickLabels` (0xFF0D65): seven entries are note symbols, and which seven is the decode

99 two-character cells. Ninety-two carry digits, seven carry two bytes below
0x20 instead, and the last two are blank:

```
   8 -> 18 1F      12 -> 18 20      16 -> 17 1F      24 -> 17 20
  32 -> 16 1F      48 -> 16 20      96 -> 15 20
```

Those seven are **the divisors of 96 that are ≥ 8**, and 96 ticks is one beat:
96th, 48th, 32nd, 24th (= 16th triplet), 16th, 12th (= 8th triplet), 8th.
⚠ CORRECTED 2026-08-25 (round-2 audit F3): this read "exactly the divisors of 96
that matter musically". The source header's "exactly the divisors of 96" was
false — 1, 2, 3, 4 and 6 divide 96 too and all five carry ordinary digits
(" 1" " 2" " 3" " 4" " 6") — and "that matter musically" was a repair that
cannot fail. The bound is arithmetic, not taste. The first byte steps 0x18, 0x17, 0x16, 0x15 as the note gets
longer and the second alternates 0x1F/0x20 — a two-cell symbol, stem and head.
⚠ That a beat is 96 ticks HERE is not established; the divisor set is the whole
evidence for it.
⚠ LAST-ENTRY TEST (round-2 audit F3): entries 97 (0xFF0E27) and 98 (0xFF0E29)
are `20 20`, blank. The highest **labelled** value is 96. 99 is the EXTENT; the
labelled range is 0…96, not 0…98. Both figures are re-derived by
`python3 notes/prom_a_round3_checks.py`.

## 6. What the screens say

The text is inside the records, so this module is where a large part of the
machine's UI vocabulary lives. The five biggest lists — 0xFF0E2B (230 bytes),
0xFF0F11 (463), 0xFF10E0 (594), 0xFF1332 (600) and 0xFF158A (600) — are whole
screens; the other 51 are boxes and rules of 8 to 15 bytes.

```
SEQUENCER  REALTIME  EDIT      MASTER  REC0RD  TRACK  ASSIGN   STEP
MEDLEY     S0NG      SELECT    AFTER T0UCH     /NAME
NOTE EDIT  TRACK  SONG  PLAY  GRAPH  MEAS  NOTE  CURSOR  POS  LEN  VEL
DRUM EDIT  SOUND  KIT:  ENTER  SND  SET  INC  ERS  PART
"Press up/down button under screen corresponding track that want edit."
```

`REC0RD` and `S0NG` are spelled with a **zero** in the ROM — one occurrence
each, against zero occurrences of `RECORD` and two of the correctly spelled
`SONG`. Transcribed, not corrected.

⚠ **Which screen each list belongs to is NOT established**, and neither is what
`(0x601F00)`, `(0x601F3A)`, `(0x601F53)`, `(0x601F70)` or `(0x601F75)` hold.
**Twenty-two `bit 0,(0x601F70)` tests** sit in this module (the byte pattern
`F2 70 1F 60 C8`, counted over the span) and most of them pick a different list
either way, and `ScreenDrawPtrs_FEF9FA` / `ScreenDrawPtrs_FEFA2A` are two
whole pointer tables selected by that same bit: whatever it is, it switches the
machine between two screen layouts. Every routine in the module is
`sub_XXXXXX` except the three the kit legend pins.

## 7. Where the next wave should go

1. **Tie the five big lists to the screens that call them.** Three of the five
   are reached from the 0xFE0000 block-device module (0xFE8138, 0xFE8394,
   0xFE83CD) — the same module that owns the disk. That is a thread into
   **gap V** as well as gap O.
2. **Name `(0x601F70)` bit 0.** It is the single most-tested bit in this module
   and it selects between two whole screen layouts. It is a good candidate for
   the SX-WSA1 / SX-WSA1R variant strap the emulation notes describe, and that
   would be checkable rather than assumed.
3. **`Data_FF17E2`.** 2,695 bytes with an 8-byte period and no reader.

## 8. The NOTE / DRUM EDIT state in work DRAM (2026-10-03)

Answers item 7.2 in part.  **`(0x601F70)` bit 0 is NOTE EDIT (0) versus DRUM EDIT (1)** -- not
the variant strap.  Its only four writers (two `set 0`, two `res 0`; the other 40 uses test it) are:

| writer | bit 0 | what else it does |
|---|---|---|
| `ShowScreen_NoteEditPartSelect` (0xFE836F) | cleared | paints `DisplayList_NoteEditPartSelect` ("NOTE EDIT ... PART SELECT") |
| `ShowScreen_DrumEditPartSelect` (0xFE83A3) | set | paints the DRUM EDIT part-select list |
| `EditScreen_EnterNoteEdit` | cleared | loads (0x601F4D) from (0x601F4F), (0x601F49) from (0x601F4B), (0x601F75) = 10, (0x601F76) = 11 |
| `EditScreen_EnterDrumEdit` | set | loads (0x601F4D) from (0x601F51), (0x601F49) = 10, (0x601F75) = 7, (0x601F76) = 8 |

`EditScreen_EnterNoteEdit` and `EditScreen_EnterDrumEdit` then share the tail at 0xFE88D3, which (among much else) positions
the cursor below: the measure from (0x3552) when (0x207D) is 0x26 or 0x29 (otherwise kept), measure 1 if loading that
position fails (`BStore_ErrorCode` non-zero), then beat 0 and tick 0.  So the two pointer tables that bit
selects (`ScreenDrawPtrs_FEF9FA` / `_FEFA2A`) are the note-edit and drum-edit layouts of one editor.

**The editor's cursor is measure / beat / tick**, the three words the "MEAS" / "POS" columns of the
NOTE EDIT text would show:

| address | width | holds | evidence |
|---|---|---|---|
| 0x601F3F | word | measure, 1..999 | `EditCursor_MeasurePlus10` adds 10 and clamps to 0x3E7; `EditCursor_MeasureMinus10` subtracts 10 and floors at 1; `EditCursor_NextBeat` increments it when the beat wraps |
| 0x601F41 | word | beat within the measure, from 0 | `EditCursor_NextBeat`: compared with the measure's beat count from `EditCursor_BeatsInMeasure` (a lookup in the table at 0x601F5F); below it, +1; otherwise 0 and the measure +1 |
| 0x601F43 | byte | tick within the beat, 0..95 | `EditCursor_TickPlus1` adds 1 and `EditCursor_TickPlus5` adds 5 and clamps to 0x5F; at 0x5F either one calls `EditCursor_NextBeat`, which sets it to 0 and moves the beat on |

96 ticks per beat is the KN5000's song-clock resolution as well (`SEQ_BEAT_TICK`,
`../../technics-docs/hdae5000-filesystem.md`).  **Not established:** what (0x601F75) / (0x601F76)
count (10 / 11 in note edit, 7 / 8 in drum edit; `EditCursor_NextBeat` multiplies (0x601F75) by 0x60, so it
is a span in beats), what (0x601F49)-(0x601F51) hold, and what `sub_FE8830`'s track types 0x28 /
0x29 / 0x30 mean when `EditScreen_EnterDrumEdit` checks them before entering drum edit.

**The value fields (2026-10-04).** NOTE EDIT draws MEAS POS NOTE VEL LEN INC
(`DisplayList_NoteEditTrackSong`), and DRUM EDIT draws MEAS POS SND VEL INC. The routines that
step them pin each cell (`notes/prom_ab_read_names_2026_10_04.py`):

| address | width | field | range, step |
|---|---|---|---|
| 0x601F45 | byte | NOTE (SND) | 1..127, by 1 or 5 (`EditField_EventVelocity*`) |
| 0x601F46 | byte | VEL | 1..127, by 1 or 5; 100 by default (`EditField_NewNoteVelocity*`) |
| 0x601F47 | word | LEN when (0x601F5B) bit 0 is set | 1..0x2FFF, by 1 or 12 (`EditField_Length*`) |
| 0x601F4D | word | INC, the cursor step in ticks | 1..0x60, by 1 or 5; 0x30 by default (`EditField_Inc*`) |

⚠ **CORRECTED the same day (2026-10-04): 0x601F45 is not the NOTE field.**
- It is the selected note-on's VELOCITY, byte +3. `EditField_ApplyVelocityToEvent` writes it there, and
  `EditScreen_SelectEventAtCursor` loads it from there.
- The table row above, "NOTE (SND)", is wrong. Its routines are now
  `EditField_EventVelocity{Up,Down,Up5,Down5}`, and the RAM name is `EditField_EventVelocity`.
- 0x601F46 is the velocity a NEW note gets (`EditField_NewNoteVelocity`, 100 by default).
- Both are drawn in the same VEL cell (`EditScreen_DrawEventVelocity` / `_DrawNewNoteVelocity`). The value
  is 0x601F45 while an event is selected, 0x601F46 otherwise. EditScreen_SoftKeyCol4 steps whichever
  applies; with no selection, only in DRUM EDIT.
- The NOTE column is `EditCursor_Note`.

**Selection and keyboard input (2026-10-04).**
- `EditScreen_CursorFlags` (0x601F5B) bit 0 is set by `EditScreen_SelectEventAtCursor` when a note-on sits
  exactly on the cursor's tick and passes the DRUM EDIT filter. That routine loads the event's note into
  `EditCursor_Note`, its velocity into `EditField_EventVelocity`, and its length into `EditField_Length` as
  `(+5 & 0x7F) * 0x60 + (+4 & 0x7F)`, the same split `EditField_StoreLengthInNoteEvent` writes.
- The keyboard enters notes. `NoteEdit_TakeKeyboardInput` drains the sequencer input ring on screens 0x25 /
  0x28:
  - A note-on is held in `NoteEdit_HeldKeys` (0x601F1C: 8 slots of flag, note, velocity; one slot in
    DRUM EDIT).
  - A note-off releases its slot.
  - When the last key is up, `NoteEdit_EnterHeldNotes` enters them at the cursor, after
    `EditScreen_AppendMissingBeatMarkers` has extended the part's chain to the cursor's beat.
- `NoteEdit_ScrollRulerToNote` moves the keyboard ruler, `NoteEdit_RulerPosition` (0x601F53) 0..9, until
  the note is in view.

**Audition and redraw (2026-10-04).**
- A change of the selected note or velocity is heard. `EditScreen_AuditionEvent` ends the previous
  audition (`EditScreen_EndAudition`) and puts a 5-byte timed event on `TimedEvents_Ring`: 0x90, 0x7E,
  `EditCursor_Note`, `EditField_EventVelocity`, `EditScreen_Part`.
- It then sets `EditScreen_ActionTimer2` = 0x82. Two ticks later `EditScreen_RunDueAction2` puts the
  closing event (0x90, 0x7F, 0x28, 0, part).
- A DRUM EDIT row change auditions the row's note at velocity 0x50 (`DrumEdit_AuditionRow`).
- The note grid is drawn by `EditScreen_DrawVisibleNotes`. It walks the measure beat by beat and draws
  every note-on inside `EditScreen_VisibleNoteRange`: TopRowNote..+11 in DRUM EDIT, a per-ruler-position
  word table in NOTE EDIT.
- The selected event is highlighted on layer 1 (`EditScreen_DrawSelectedEventBar`).
- The deferred actions are these redraws, with a re-selection (`EditScreen_DeferredReselectAndRedraw`)
  or a chain extension (`EditScreen_DeferredRedrawAndExtend`).

(0x601F49) is the length cell the same routines step when (0x601F5B) bit 0 is clear. NOTE
EDIT loads it from (0x601F4B) on entry. Its role beside 0x601F47 is not established.

**The edited part and the note row (2026-10-04).**
- `(0x601F00)` is `EditScreen_Part`, the part being edited. `EditPartSelect_OpenEditor`, the action of
  SoftKeyCol1..6_EditPartSelect, stores the key's index there and the part's bit mask from
  `EditPartSelect_PartBitMask` at 0x601F01 (`EditScreen_PartMask`). Its block-store chain is entry part + 1.
  `EditScreen_SaveTrackCursor` keeps the cursor per part at 0x3460 / 0x3482.
- `(0x601F44)` is `EditCursor_Note`, the cursor's note row, 1..127.
  - It is stepped by 1 (`EditCursor_NoteUp` / `_NoteDown`, from EditScreen_SoftKeyCol3) or by 6
    (`EditCursor_NoteUp6` / `_NoteDown6`).
  - In DRUM EDIT, each step also scrolls the row list (DrumEdit_RowFollowNoteUp / DrumEdit_RowFollowNoteDown).
  - In DRUM EDIT it filters the events too: `DrumEdit_IsOtherNote` returns 0xFF for a note-on whose note
    differs from it, and 0 otherwise or in NOTE EDIT.
  - Every step also writes it into a note-on under the cursor (`EditCursor_ApplyNoteToEvent`). So in
    NOTE EDIT, moving the note row moves the selected event's pitch.
  - Holding SoftKeyCol3 steps it by 6 (`EditCursor_NoteStepHeld`, slot 0x13 of the 32-slot tables: the
    held variant of code 0x02). The direction is reversed in DRUM EDIT.
  - It is shown as an octave and note name in NOTE EDIT, and as a number in DRUM EDIT
    (`EditScreen_DrawCursorNote`).

Census of every 0x601F00-0x601F7D operand with its form and routine:
`python3 notes/wsa1_601f_census.py` (in the repository's wsa1/ directory).
