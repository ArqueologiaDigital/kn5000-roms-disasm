# prom_a 0xF8E6FA-0xF8E77C: CONVERTED 2026-09-02 (130 of 211 B); the remaining
# 81 B refused, narrowed and documented

**Status: 130 B converted, 81 B left `.incbin`, refused.** A naive linear
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

## What is refused: 0xF8E77C-0xF8E7CD (81 B)

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
