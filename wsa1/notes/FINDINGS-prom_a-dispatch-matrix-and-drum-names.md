# prom_a 0xFF3800-0xFF8000 and 0xFEB330-0xFEF746: a 654-slot dispatch matrix,
# and the drum-kit name table

Wave 6, 2026-08-25, second and third targets of the pass. 34,940 substantive
bytes converted between them; the byte gate passes.

Reproducibility, both committed and both exiting non-zero on failure:
`python3 notes/prom_a_uiscreen_checks.py` (49 checks) and
`python3 notes/prom_a_drumnames_checks.py` (39 checks — 35 before this round, plus the four of §6b). The name table is
emitted by `notes/gen_prom_a_drumnames.py`, which refuses to print anything it
has not first re-read from the ROM.

---

## 1. 0xFF3800-0xFF7C65 — a UI screen module with fourteen dispatch tables

Picked because `notes/prom_a_module_frontier.py` ranked its directory run
`T_F423A0-T_F42428` first in prom_a: 35 slots over a contiguous 10,578-byte
unconverted extent.

**What the module is.** `0xFF42EE` is one of the 111 sites of the model-variant
strap `(0x0000C4)`, and it is the site the emulation side had already
disassembled: it chooses between display list `0xF580B0` (MIDI FILE LOAD / MIDI
FILE SAVE / LOAD SINGLE SOUND / LOAD SINGLE COMBI.) and `0xF58127` (only the
last two). That is the **disk menu**. So this module owns the screen the disk
functions live on — which is where emulation gap V said to look, and it is now
assembly.

⚠ **Not claimed:** which of the fourteen tables is the disk menu's. The tables
are indexed by an argument and nothing here ties an index to a legend. That is
still gap O's problem.

**The shape, which is identical in all fourteen readers:**

```
link XIZ,0 / push HL
ld H,(XIZ+0x08)                 ; the control index
cp H,0x20 / jr NC, out          ; <- 32 entries per row
[ cp (0x2229),#n / jr NC, out ] ; <- optional: n rows, (0x2229) is a page byte
push (XIZ+0x0A)                 ; the argument handed to the handler
C = 4 * (32*(0x2229) + H)
add XBC,<base> / ld XBC,(XBC) / push <retaddr> / jp (XBC)
```

So **every table's base and every table's entry count are literals in its own
reader**. That is how the counts below were established — not from a shape run
and not from where the next table happens to start:

| base | entries | reader | bound |
|---|---|---|---|
| 0xFF3800 | 32 | 0xFF431C | `cp H,0x20` @0xFF4324 |
| 0xFF3880 | 32 | 0xFF4596 | `cp H,0x20` @0xFF459E |
| 0xFF3900 | 32 | 0xFF4995 | `cp H,0x20` @0xFF499D |
| 0xFF3980 | 32 | 0xFF522F | `cp H,0x20` @0xFF5237 |
| 0xFF3A00 | 6 | 0xFF548A | `cp (0x2229),0x06` |
| 0xFF3A18 | text, 17 B | 0xFF5628 | — |
| 0xFF3A29 | 6 × 32 | 0xFF572E | both bounds |
| 0xFF3D29 | 4 | 0xFF5C3E | `cp (0x2229),0x03 / jr UGT` |
| 0xFF3D39 | 6 × 32 | 0xFF5ED1, 0xFF6550, 0xFF66AA | see below |
| 0xFF4039 | 4 words | 0xFF6789 | ⚠ none — extent only |
| 0xFF4041 | 2 | 0xFF672D | `cp (0x2229),0x02` |
| 0xFF4049 | 2 × 32 | 0xFF68D8 | ⚠ none — extent + sibling |
| 0xFF4149 | 2 | 0xFF6DB7 | `cp (0x2229),0x02` |
| 0xFF4151 | 2 × 32 | 0xFF6F21 | ⚠ none — extent + sibling |
| 0xFF4251 | 16 ptrs | 0xFF70B6 | `cp HL,0x0010` @0xFF70CF |
| 0xFF4291 | text, 16 B | 0xFF71A5 | — |
| 0xFF42A1 | text, 4×4 | 0xFF744E | — |

★ **And they tile 0xFF3800-0xFF42B1 exactly, with no gap and no overlap.** That
is one independent check on all fourteen counts at once: if any single count
were wrong the tiling would not close. `prom_a_uiscreen_checks.py` §1 walks it.

Three things worth keeping:

* **`jr UGT` at 0xFF5C43 admits 3**, so `Dispatch_FF3D29` has FOUR entries, not
  three. A `jr NC` in the same place would have meant three. The four entries are
  all distinct, which corroborates it.
* **0xFF3F39 and 0xFF3FB9 are not separate tables** — they are rows 4 and 5 of
  the 0xFF3D39 matrix (`0xFF3D39 + 4·128` and `+ 5·128`), each with its own
  dedicated reader on top of the matrix reader. Row 5 exists *only* because a
  dedicated reader names it: the matrix reader's own bound stops at 5 rows.
* **The 17-byte text field at 0xFF3A18 is what makes the region unaligned.** 17
  is odd, so every table after it sits at an odd offset from 0xFF3800. Any tool
  that assumes one aligned array here is wrong, and the first one written for
  this pass was.

★ **Most of the matrix is empty.** Of the 654 handler slots, **459 — seventy per
cent — are the single address 0xFF42B1, and 0xFF42B1 is a bare `ret`.** Only 112
distinct targets appear in all twelve tables together, and 8 of those are outside
the module (prom_b directory slots 0xF42F84-0xF42FA0). So the live handlers are
the sparse exceptions, and a reader looking for "what does control 7 do on page
3" will usually find: nothing.

⚠ A curiosity of the toolchain worth writing down: the handler that runs most
often in this module is the one line in it with **no label**. All 459 references
to 0xFF42B1 are 32-bit pointers, and the block generator labels only
call/jp/calr targets.

**`Text_UserBankAbbrevs` is four four-character labels — `"U1 -" "U2 -" "UD1-" "UD2-"`**,
indexed by `(0x2728)` at stride 4. ~~What U1 and UD1 stand for is not established
and is not guessed.~~ ★ **Settled 2026-10-04:** USER 1 / USER 2 / USER1 DRUM / USER2 DRUM. prom_b's
`DLText_F59128` holds those long forms in the same order, and `DL_F590F1`'s first record
indexes it by the same `(0x2728)`. The bare `ret` after the labels is now `DispatchMatrix_NoAction`.

## 2. 0xFEB330-0xFEF746 — the drum-kit name table

Three regions that tile exactly:

```
0xFEB330  RecordPtrs_RAM76A2          35 x LE32 -> RAM 64-byte records
0xFEB3BC  DrumKitNameBlockPtrs   130 x LE32 -> into the name table
0xFEB5C4  DrumKitNames            13 blocks x 129 names x 10 characters
```

**The names are General-MIDI percussion legends** — `Bass Dr 1`, `Hand Claps`,
`Ride Cym 1`, `Crash Cym1`, `Cowbell 2`, `Vibraslap`, `Bongo High`, `Timpani C`,
`Applause`, `Fret Noise` — fixed width 10, space padded, **no terminator**.
They are in the source as 1,677 `.ascii` lines rather than 1,050 rows of
`.byte`, because a table of names that reads as hex is converted territory that
tells you nothing.

## ★★ The name index IS the MIDI note number

Added 2026-08-25. This section used to say only *"a name's INDEX is a MIDI note
number offset. ⚠ WHICH note index 0 is, is NOT established here."* **The offset
is zero.** Indices 35-81 of a populated block are the General MIDI percussion
map in order, with no shift:

| idx | WSA1 | General MIDI | idx | WSA1 | General MIDI |
|---|---|---|---|---|---|
| 35 | `Bass Dr 2 ` | Acoustic Bass Drum | 49 | `Crash Cym1` | Crash Cymbal 1 |
| 36 | `Bass Dr 1 ` | Bass Drum 1 | 51 | `Ride Cym 1` | Ride Cymbal 1 |
| 37 | `Rim Shot  ` | Side Stick | 56 | `Cowbell 2 ` | Cowbell |
| 38 | `Snare Dr 1` | Acoustic Snare | 69 | `Cabasa    ` | Cabasa |
| 39 | `Hand Claps` | Hand Clap | 75 | `Claves    ` | Claves |
| 41 | `FloorTom L` | Low Floor Tom | 78 | `Cuica High` | Mute Cuica |
| 42 | `Hi-HatCLOn` | Closed Hi Hat | 80 | `Triangle M` | Mute Triangle |
| 44 | `Hi-Hat Ped` | Pedal Hi-Hat | 81 | `Triangle O` | Open Triangle |

★ **What makes this a decode rather than a resemblance is the negative
control.** `notes/prom_a_drumnames_checks.py` §6b tests 43 GM keywords against
the name at their own index and against the name one index either side:
**43/43 aligned, 11/43 at +1, 11/43 at −1.** (The 11 come from the runs where
GM itself repeats an instrument — three Hi-Hats, three Congas, two Bongos.) So
the test measures the ALIGNMENT, and it can fail.

Indices **82 upward** are a Technics extension *above* the GM range —
`Shaker On`, `SleighBell`, `Wind Chime`, `Castanets `, `Surdo Mute`,
`Orch.BasDr`, `Rain Stick`, `BataDrSlap`, `DarbukaOpn` — which is what a
GM-compatible kit looks like, and **0-34** are Technics extras below it:
`MetroClick`, `Metro Bell`, `Zap 1`, `Voice Ah`, `Scratch 1`, `Rev Snare`,
`Extra Tom1..3`, `Brush Long`, `Brush Tap`.

**Why this matters beyond the table.** Emulation gap O asks for an
index-to-legend tie — a way to say what a number in this machine MEANS in words
a user would recognise. This is one, for free, for the whole percussion map:
any trace that carries a drum index can now be printed as a name, and any
name-to-index question has an answer that is checkable.

⚠ **What it does NOT establish:** that the byte the reader at 0xFEB2E3 receives
arrives as a MIDI note ON THE WIRE, rather than as a key number the panel
already translated. It establishes the ENCODING of the index.

★ **How the 129 × 10 framing was established, and it is NOT the string content.**
The load-bearing evidence comes from a different table: **all 130 pointers in
`DrumKitNameBlockPtrs` are `0xFEB5C4 + 1290·k` for an integer k** — every one
lands exactly on a name-block boundary, never one byte off. 1290 = 129 × 10. And
the region is 16,770 bytes = 13 × 129 × 10 with no remainder, ending exactly
where the next code region begins (`stdi8 (0x2540),0x00` at 0xFEF746).

**Which block each drum program uses:** 123 of the 130 use block 1; the seven
exceptions are programs 24, 26 and 29 → block 2, 40 → 3, 48 → 5, 112 → 4,
120 → 6.

★ **Blocks 7-12 are populated and NOTHING NAMES THEM.** A raw three-byte address
scan of prom_a *and* prom_b finds blocks 0-6 named and blocks 7-12 named
nowhere; `notes/prom_a_xref.py` agrees. The scan is opcode-agnostic, so it
over-reports and cannot under-report — a searched negative with the search
named. Some reader must compute their addresses; it is not located.

**The record-type dispatcher at 0xFEB2F5**, whose five arms were taken from
`prom_a/roundtrip.py --block` and not from displacement arithmetic done by hand
(the first reading of them, done by hand, was wrong in both directions):

| record +0x01 | goes to | effect |
|---|---|---|
| 0x20 | 0xFEB30B | `XIY = DrumKitNameBlockPtrs[record+0x00]` — **this is the drum part** |
| 0x28, 0x29 | 0xFEB31E | `XIY = RAM 0x00603FF6` |
| 0x30 | 0xFEB324 | `XIY = RAM 0x00603FF6` again — a second, unmerged arm |
| anything else | 0xFEB32A | `XIY = 0xFEB5C4` — block 0, **129 blank names** |

So an unrecognised part type displays blanks rather than garbage, and block 0
exists for exactly that.

## 3. ★ A 64-byte RAM record array, agreed on by two independent modules

`RecordPtrs_RAM76A2` (0xFEB330) holds 35 pointers into RAM starting at **0x76A2**,
stepping by **0x40** — except once, `0x7862 → 0x78E2`, which is **0x80** — and
its last three entries fall back to entry 0.

`PtrTable_FF4251` (0xFF4251), in the *other* module converted this pass, holds 16
pointers `0x76AF … 0x7AAF`: the same base **plus 13**, the same 0x40 stride, and
**the same single 0x80 step at the same array position (index 8)**.

Two tables in two modules, reached by different readers for different purposes,
agree on the layout *and* on the one irregularity in it. That is a 64-byte
record array at RAM 0x76A2 with one 64-byte hole after record 7, and it is now
established from two directions rather than one. `FF4251`'s reader copies each
record's byte at **+13** into a 16-byte shadow at RAM 0x26B2 and its sibling
compares against that shadow and writes back on a difference — a change
detector — so record byte +13 is a value a UI watches.

⚠ What a record IS remains unknown, and so does RAM 0x00603FF6.

## 4. What the next wave should take from here

1. **Find what reads name blocks 7-12.** Six populated 1290-byte blocks that no
   address in either image names is either dead data or a computed index; which
   it is decides whether the WSA1 has more drum kits than its pointer table
   admits.
2. **Tie a dispatch index to a legend** (gap O). The tables are converted, the
   bounds are proven, and 195 live handler slots are sitting there unnamed. A
   single (index, legend) pair from a service manual or a panel photograph would
   unlock a whole 32-entry row at once.
3. `Table_FF4039` — four 16-bit values `0x0008, 0x0009, 0x0028, 0x0029` read at
   stride 2 by eight sites, with **no bound anywhere**. It is the one count in
   the module that rests on extent alone.
