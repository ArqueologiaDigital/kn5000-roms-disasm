# prom_a 0xFC4000-0xFC52F7: CONVERTED 2026-09-02, on the fifth pass

**Status: refused four times by walk-plausibility arguments; converted on the
fifth by external structural evidence instead of a fifth walk.** This note kept
the refusal history so the fifth pass would not start from zero; that history
is preserved below, followed by what actually closed it.

Converter: `notes/gen_prom_a_fc4000_module.py` (`--check` re-derives and
asserts every number in this note; `--emit` produces the assembly spliced into
`prom_a/wsa1_prom_a.s`). Gate: `make gate-wsa1`, green.

## The four-way split, and why each boundary is external, not eyeballed

```
0xFC4000-0xFC482F   2,095 B  DisplayList_FC4000       records + pointer-runs
0xFC482F-0xFC48D8     169 B  FixedStringTable_FC482F  13 entries x 13 B
0xFC48D8-0xFC48E4      12 B  Unclassified_FC48D8      not established
0xFC48E4-0xFC52F8   2,580 B  Bitmap1bpp_FC48E4        172 rows x 15 B (120 px)
```

**1. DisplayList_FC4000 / FixedStringTable_FC482F boundary — self-consistency,
not plausibility.** The existing op,len-record walk was combined with the
already-known self-referential pointer-quad runs and run with **zero resync
allowed**: a record that would overrun is a hard stop, not a skip-and-retry.
It runs clean for the full 2,095 bytes — 184 records, 8 pointer-runs of 106
quads — and stops (correctly, not a failure) exactly at `0xFC482F`. The
pointer-quad claim was previously only checked for "lands somewhere in the
span"; here every one of the **106 decoded targets is checked against the
actual object boundaries this same walk derives**, and **106/106 land exactly
on one** — not a plausibility judgement, a closed self-consistency proof, the
same shape as the `0xF96CA6` reader-loop-count precedent but derived from the
data's own cross-references instead of a reader. Record op values top out at
`0x23`, inside prom_b's real `DisplayList_Run` bound (`0x24`) — corroborating,
not conclusive, since no call site in prom_a's own graph is proven to reach
this span (`reachability.py` still reports zero).

**2. FixedStringTable_FC482F — exact tiling, corroborated from both ends.** 13
entries of exactly 13 bytes, zero slack: `CELESTE 1/2`, `CHORUS 1/2`,
`ENSEMBLE 1/2`, `TREMOLO`, `ORGAN TREMOLO`, `SINGLE DELAY`, `REPEAT DELAY`,
`SOLO EFFECT 1/2`, and a combined `"MONO  STEREO"`. Its start address
(`0xFC482F`) is derived independently by walk #1 and by the exact `13*13`
tiling walked backward from where the text stops being ASCII — the two agree
to the byte.

**3. Unclassified_FC48D8 — 12 bytes, honestly left untyped.** 5 nulls, then
`0x3F 0x20 0x50` (possibly non-ASCII glyphs in a different SWI7 font —
`FINDINGS-fonts.md`'s precedent that not every text service passes an ASCII
test — not established either way), then the bitmap's own first 4 bytes. No
framing is claimed for this residue; it is reproduced as `.byte` and nothing
more.

**4. Bitmap1bpp_FC48E4 — the boundary the four prior passes could not get,
found from the bitmap's own structure (route 4 of the four listed below), not
from where a walk stopped looking plausible.** Two independent, purely
data-derived measurements, both immune to the previous walks' failure mode:

* The delta between successive occurrences of each of three **rare** byte
  values — `0xFF`, `0x55`, `0xAA`, none of them the dominant `0x00` filler —
  peaks at **15** in all three (48/77, 8/22 and 6/11 of their respective pairs,
  with harmonics at 30 and 45). This is a correlation on the data itself, not a
  parser's opinion of it.
* Of the three strides adjacent to 15, **only 15 divides the fixed 2,580-byte
  tail with zero remainder** against a boundary this tree already committed
  independently — the `0x0E` pad run at `0xFC52F8`, verified byte-by-byte
  against the dump long before this pass. 14 and 16 both leave a remainder of
  4. `--render-control` renders 200 bytes at all three strides; only 15
  produces coherent rectangular blocks, matching the diagonal edge and dither
  runs the third and fourth refusal passes already saw but could not place.

172 rows of 15 bytes = 2,580 bytes, landing exactly on `0xFC52F8`.

**Byte accounting**: 2,095 + 169 + 12 + 2,580 = 4,856 = `0xFC52F8 - 0xFC4000`.

## What is still NOT claimed

`reachability.py` still reports **zero reachable bytes** in the whole span. No
runtime reader was found — routes 1 and 3 below were eliminated, not
satisfied. What licensed the conversion was routes 2 (implicitly — the
106/106 self-referential closure is a stronger version of "a count held
elsewhere") and 4 (the bitmap stride), corroborated by the exact-tiling
evidence in the middle. Semantic content (which icon shows what, what draws
this screen) remains open.

## Routes checked and eliminated, for whoever asks "did you check X"

* **Route 1 (a reader) and route 3 (an inbound pointer)** were checked by the
  same instrument: every 3-consecutive-byte window in the *entire* 512 KB ROM
  (not just the disassembled text — the check reads the raw file, so it also
  covers everything still `.incbin`) was tested as a little-endian address
  landing inside `0xFC4000-0xFC52F8`, both in the strict 4-byte
  `lo,mid,0xFC,0x00` pointer-quad shape and in the loose 3-byte
  `lo,mid,0xFC` shape (covering `lda_24`, `jp`, `call`, and `ld Xrr,imm32`
  encodings alike, regardless of alignment). Eleven raw hits, all individually
  explained as coincidence: four `calr` relative-displacement byte pairs, one
  `ldio SC0BUF,0xfc` MIDI STOP-byte constant, two instruction-boundary
  straddles, and one straddle across two unrelated `.long` table entries.
  **Zero genuine references anywhere in the ROM.** If a reader exists, it
  builds the address purely through runtime arithmetic with no literal
  operand anywhere in the image — a materially weaker and currently
  unfalsifiable claim, so it was not pursued further.
* **Route 2 (a count/extent stored elsewhere)** was not found as a literal
  constant (no `4856`/`0x12F8`/`154`-shaped immediate near any DSP-effect
  code), but its spirit is satisfied more strongly by the 106/106
  self-referential closure above, which is an internal count-and-match rather
  than an external one.

## Original refusal history (superseded, kept for the record)

Two of the four original passes converged on `~0xFC48D7` via `op,len`
walk-plausibility arguments — the naive walk sailing through bitmap data as
records, then a non-resyncing walk getting to `0xFC48FC` before over-consuming
37 bytes of real bitmap. Both were correctly refused: agreement between two
instances of the *same kind of argument* is not independent evidence, and
neither had an external anchor. The actual boundary, `0xFC48E4`, is 13 bytes
later than that estimate — inside what those passes could see only as "text
ends, then something else", which is now accounted for by
`FixedStringTable_FC482F` ending at `0xFC48D8` and `Unclassified_FC48D8`'s
12-byte residue.
