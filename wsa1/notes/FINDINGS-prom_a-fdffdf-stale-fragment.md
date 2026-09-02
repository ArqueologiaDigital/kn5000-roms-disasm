# prom_a 0xFDFFDF-0xFE0000 (33 B): CONVERTED 2026-09-02; an earlier refusal overturned

**Status: converted.** These 33 bytes are linker SLACK holding the middle of a
stale copy of a routine prologue -- overwritten at the front by the live module
that ends at 0xFDFFDF and at the back by the module that starts at 0xFE0000.
They are dead: nothing reaches them and they never execute.

Converter: `notes/gen_prom_a_fdffdf_fragment.py` (`--audit` re-derives the
match). Instrument: `notes/prom_a_near_match.py`. Gate after the splice: all
four WSA1R images byte-identical.

## What the earlier pass said

The refusal is kept in `prom_a/wsa1_prom_a.s` above the conversion, marked
superseded. It said, correctly:

* the preceding `ret` at 0xFDFFDE is a clean function boundary;
* a decode continued from 0xFDFFDF never resynchronises before 0xFE0000;
* of the 128 possible decode starts in 0xFDFF80-0xFDFFFF, only 0xFDFFFD and
  0xFDFFFF make 0xFE0000 a boundary, and neither has a clean first instruction;
* "condition codes and operand shapes that do not occur anywhere else in this
  span -- the signature of genuinely different content".

Every one of those observations is right. The inference drawn from them --
that the content could not be identified -- is what this pass overturns. It IS
different content. It is also completely identifiable.

## What changed: the instrument

The earlier pass ran an EXACT pointer/substring scan. An exact search can never
find a relocated copy of a routine: a `call` target, a `jr` displacement and a
32-bit immediate all differ, which here is 2 to 5 bytes out of 33.

`notes/prom_a_near_match.py` slides a byte range over all four images and scores
Hamming similarity, printing a null alongside:

    python3 notes/prom_a_near_match.py 0xFDFFDF 0xFE0000

    NULL over 4000 random offsets in the same four images:
        best 5/33 (15%), mean 0.4/33 (1%)
      31/33 (94%)  prom_b 0xF00CB2, 0xF00CF3, 0xF00D34, 0xF00D75
      29/33 (88%)  prom_b 0xF0A91E
      28/33 (85%)  prom_a 0xFD054D ... 0xFDE71F   (twenty-one more)

26 places score 70% or better. The four 94% witnesses differ from these bytes in
**exactly two positions, +31 and +32**, which are the low half of a 32-bit
immediate. Not the opcodes, not the `call` target (0xfdbd28, identical), not the
`jr` displacement.

## Why it starts and ends mid-instruction

The witness at prom_b 0xF00CB2 reads, in context:

    f00cac: 30 38                push ... / push XWA
    f00cae: 9e 0a 04             pushw (XIZ+0x0a)
    f00cb1: 9e 08 04             pushw (XIZ+0x08)      <- 0xF00CB2 is its `08`
    f00cb4: 1d 28 bd fd          call 0xfdbd28
    f00cb8: ef 60 / ef 64        inc 0,XSP / inc 4,XSP
    f00cbc: d8 cf ff ff          cp WA,0xffff
            66 1e                jr z, +0x1e
            9e fe 21 ...         ld bc,(xiz-2) ...
            e9 c8 ac 02 f0 00    add XBC,0x00f002ac

prom_a 0xFDFFDF is that `08`. The `0x9e` opcode byte of its `pushw (XIZ+0x08)`
would sit at 0xFDFFDE -- which the live module's `ret` occupies. At the far end,
`e9 c8 44 01` is the head of `add XBC,0x00fc0144`; the immediate's top two bytes
would sit at 0xFE0000-0xFE0001, which the next module's first `jp` veneer
occupies.

**That is why no decode start makes 0xFE0000 a boundary.** The question had no
right answer to find: the object here is not aligned to either boundary, because
it is not this module's object at all.

## What is emitted

| range | bytes | form |
|---|---|---|
| 0xFDFFDF | 2 | `.byte` -- orphan operands of `pushw (XIZ+0x08)` |
| 0xFDFFE1 | 27 | instructions, via `prom_a/roundtrip.py` |
| 0xFDFFFC | 4 | `.byte` -- head of `add XBC,0x00fc0144`, truncated |

The 6 `.byte` bytes are two NAMED half-instructions, not undecoded residue.
`8e fc 43` is written `m_mul MBD+r6, 0xfc, 3`, the spelling this file already
uses for those bytes at 0xFDE737.

## ⚠ A tooling bug found on the way, not fixed here

`prom_a/roundtrip.py`'s `macro_prelude()` returns **only the header, with zero
`.macro` definitions**, in this tree. It slices the image file
(`notes/.image-wsa1_prom_a.s`) between `; MACRO-PRELUDE-BEGIN` and
`; MACRO-PRELUDE-END`, and in the image the include has been INLINED -- so the
first text matching the END marker is a line of the include's own prose that
quotes it, ~16 lines in, before any macro.

Consequence: roundtrip.py's macro candidate (strategy (c)) can never win in this
tree, and every form that needs one falls back to `.byte`. That inflates the
`.byte` count of every block it emits. It is left alone here because changing it
would change the emitted text of blocks other lanes are working on;
`gen_prom_a_fdffdf_fragment.py` works around it by including
`include/tlcs900_mem_ops.inc` directly in its own verifier.

## It is NOT the image tail, and NOT a vector table, checksum or filler

The lane brief described this span as sitting "at the very end of the image".
It does not. prom_a is 512 KiB linked at 0xF80000-0xFFFFFF; 0xFDFFDF is file
offset 0x5FFDF, with 128 KiB of image after it. What it sits at the end of is
the 0xFD bank, and 0xFE0000 is the next module's first `jp` veneer.

For the record, each alternative was checked and eliminated:

* **Vector table** -- no. The TLCS-900 vectors live at the top of the image
  (the SWI7 vector this tree already documents is at 0xFFFF1C), not here, and
  nothing in these 33 bytes is a table of 4-byte addresses: the pointer-shaped
  run detector finds no run in them.
* **Checksum** -- no. The bytes are not a constant, not a repeated word, and
  31 of 33 of them are byte-identical to a routine prologue that occurs 26
  times elsewhere; a checksum would not be.
* **Filler** -- no. prom_a's filler is runs of 0x0E (`ret`), verified byte by
  byte wherever this tree emits `.fill`; there is no 0x0E in this span at all.

It is linker slack holding the middle of a stale object, which is a fourth
category, and the only one consistent with a 94% match to live code elsewhere.
