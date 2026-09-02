# prom_a 0xF8E6FA-0xF8E7CD: CONVERTED 2026-09-02, all 211 B

**Status (updated later the same day): all 211 B converted.** The 81 B this file
originally refused are now two LE32 address tables plus 13 bytes of identified
residue -- see the SUPERSEDED section below, which keeps the refusal verbatim.

**Status as first written: 130 B converted, 81 B left `.incbin`, refused.** A naive linear
decode over the whole 211 B span finds 9 undecodable bytes starting at
0xF8E785 and never resynchronises before the span ends -- but that failure
is entirely confined to the last 81 bytes; the first 130 are clean.

Converter: `notes/gen_prom_a_f8e6fa_module.py` (`--check` re-derives every
number below and re-verifies the 130 B region round-trips byte-exact
through llvm-mc). Gate: `make gate-wsa1`, green.

## What converts cleanly

* **0xF8E6FA (1 B)** -- an ordinary 0x0E pad byte.
* **0xF8E6FB-0xF8E712 (24 B)** -- a byte-for-byte DUPLICATE of `MemCopyWords`
  (0xF8E6E2-0xF8E6F9, already converted). Verified with a direct byte
  comparison against that exact range, not by decode plausibility.
* **0xF8E713-0xF8E74A (56 B)** -- a second block-move routine: a three-way
  branch on carry/zero into one of three `lda`/`ldir` sequences, converging
  on a shared `pop DE / pop XIX / pop XHL / ret` tail. Zero undecodable
  bytes.
* **0xF8E74B-0xF8E772 (40 B)** -- an init routine: `lda XIY,(0xf8e773)` /
  `lda XIX,(0x6007d3)` / `ld XBC,9` / `ldir` copies 9 bytes from the very
  next address in this span to RAM 0x6007d3, then zero-fills 83 bytes
  (`ld XBC,0x53`) at RAM 0x600780. Ends `ret`, then a single ordinary `reti`
  (opcode 0x07) at 0xF8E772 -- ordinary, not garbage.
* **0xF8E773-0xF8E77C (9 B, DATA)** -- the LDIR source the init routine
  literally names by address and count. All 9 bytes are zero: the routine
  zero-initialises a small header immediately before zero-filling the larger
  block that follows it.

## ★ SUPERSEDED 2026-09-02: the 81 bytes below are CONVERTED

The refusal that follows is kept verbatim because its observations are all
correct and its ONE wrong inference is the instructive part. It said "the
following 'pointers' are off by ONE byte relative to a fixed 4-byte grid".
They are not off by one: there are **two tables on two grids** with 13 bytes
between them, and `notes/prom_a_ptr_tables.py` finds both without being told:

    0xF8E774  10 entries    0xF8E7A1  11 entries

(the first two entries of each run are `0x00000000`, inside the 9-byte zero pad
that precedes each table, so the tables proper are 0xF8E77C x8 and 0xF8E7A9 x9).
The second table is not 4-aligned, which this ROM does elsewhere -- the
detector's own docstring cites `ModuleInitDirectory_F82641`, which starts on an
odd address.

**Why runs that short are believed.** The detector's `--null` control over
0xFB2000-0xFB8000 reports 5 runs, two of them 16 entries long, which read as a
false-positive rate would sink a 10-entry run. It is not a false-positive rate:
all five control hits -- 0xFB2081, 0xFB3517, 0xFB42D1, 0xFB6240, 0xFB62F6 -- are
the FIRST ENTRY of a `.long` table already declared in `wsa1_prom_a.s`. The
control region is code *and its declared tables*, and the detector found the
tables and nothing else. Its false-positive count on code there is **zero**.
`notes/gen_prom_a_f8e77c_tables.py --audit` re-derives that from the source text.

**The 13-byte gap.** `6e f7 0e 07` followed by nine zeros is BYTE-IDENTICAL to
0xF8E76F-0xF8E77C -- the `jr nz / ret / reti` closing the init routine at
0xF8E74B plus the nine-byte LDIR source that routine names by address. That
13-byte string occurs in prom_a exactly twice, at those two addresses. It is
residue of the same shape, the same linker-slack phenomenon identified this
session at 0xFDFFDF-0xFE0000, not a broken record.

**What survives from the refusal.** "No reader in the ROM cites it" is still
true and is restated in the converted block. And a NEW negative was measured:
these are NOT routine-entry tables -- only 5 of the 17 values land on an
instruction boundary of the surrounding converted code, about what chance gives
at this instruction density. Two of the five are real leaf routines this module
dispatches to by address (uDMA3_SetDest 0xF8E6C9, reached via
`lda XIX,0xF8E6C9 / jp (XIX)` at 0xF8E484, and uDMA3_GetCount 0xF8E6DA). The
emitted names say `AddrTable`, which records the record SHAPE and no role.

Converter: `notes/gen_prom_a_f8e77c_tables.py`. Gate: green, all four images.

## What WAS refused: 0xF8E77C-0xF8E7CD (81 B) -- text of 2026-09-02, superseded

This is exactly where the naive decode's undecodable bytes begin (9 bytes
in, at 0xF8E785). The first 32 bytes look like a table of 8 little-endian
longs, all `0x00F8Exxx` pointers into this same code cluster (`0xf8e68b,
0xf8e67a, 0xf8e000, 0xf8e69c, 0xf8e6ad, 0xf8e6df, 0xf8e6be, 0xf8e000`) --
but the pattern breaks immediately after: the next 4 bytes (`6e f7 0e 07`)
are not a plausible pointer, then 9 more zero bytes, then the following
"pointers" are off by ONE byte relative to a fixed 4-byte grid (`da e6 f8
00` starts at 0xF8E7A9, not the expected 0xF8E7A8).

A raw whole-ROM pointer scan (3- and 4-byte little-endian) for `0xF8E77C`
(the table's nominal start) and for `0xF8E7A9` (the byte-shifted apparent
second table's start) finds **zero hits either way** -- no reader anywhere
in the ROM cites where this stretch begins, unlike `DispatchTable_F8C2B2`
which fixed the boundaries for the 0xF8C485/0xF8C652 spans. Without an
external anchor there is nothing to pin the record width or the exact point
where the first table's slack ends and real content resumes. Left
`.incbin`, refused, narrowed to exactly these 81 bytes.

## Byte accounting

121 (code, 0xF8E6FA-0xF8E773) + 9 (data) + 81 (refused) = 211 =
`0xF8E7CD - 0xF8E6FA`, matching the `.incbin` this pass narrowed.

★ 2026-09-02, later the same day: the 81 are converted too, as 8 + 9 LE32
addresses and 13 bytes of identified residue. 0xF8E6FA-0xF8E7CD is now entirely
real source.
