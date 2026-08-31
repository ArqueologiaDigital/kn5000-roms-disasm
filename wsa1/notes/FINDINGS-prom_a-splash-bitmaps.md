# prom_a 0xFF8000-0xFFF080: three 320 × 240 bitmaps at the very top of the ROM

Wave 6, 2026-08-25, fourth target of the pass. 28,800 substantive bytes; the
byte gate passes. Verified by `python3 notes/prom_a_splash_checks.py` — 24
checks, all re-derived from the ROM image. Emitted by
`notes/gen_prom_a_splash.py`, which refuses to print unless the checks it can
make itself pass first.

## What it is

The last 32 KiB of prom_a is 78% zero bytes with sparse bit patterns. It is
**three full-screen 1-bit images**, followed by 3,712 bytes of `0x0E` padding
that runs up to the interrupt vector table at 0xFFFF00.

```
0xFF8000  SplashImage_DitherA    9,600 bytes
0xFFA580  SplashImage_DitherB    9,600 bytes
0xFFCB00  SplashImage_Wordmark   9,600 bytes
0xFFF080  3,712 x 0x0E
```

## ★ The geometry comes from the callers, not from the data

Guessing a bitmap's width from the data is how bitmaps get misread. Here nobody
has to. prom_a `0xF94131` is:

```
ld XIY,0x00FF8000 / ldw IX,0x0000 / ldw HL,0x00F0 / ldw BC,0x0028
ldb A,0x03 / swi 7
```

SWI7 service `0x03` is `LCD_Svc_03_BlitColumns` (0xF8EDB4), converted in an
earlier wave, and its header states the argument meanings: **BC = number of
columns, HL = bytes down each column, XIY = source, IX = destination offset
within the current layer** — and the routine issues `CSRDIR DOWN` (`0x4F`)
before it starts. So:

* **40 columns × 240 bytes = 9,600 bytes**, and the source is stored
  **column-major**;
* 40 bytes × 8 pixels = **320 wide**, 240 tall — which is exactly the panel:
  `notes/FINDINGS-display-controller.md` reads `C/R = 0x27+1 = 40` and
  `L/F = 0xEF+1 = 240` off the SED1330's own SYSTEM SET bytes;
* **pixel (x, y) is bit (7 − x mod 8) of byte (x ÷ 8)·240 + y**.

Each of the three images is named by its own blit site — 0xFF8000 at 0xF94131,
0xFFA580 at 0xF94142, 0xFFCB00 at 0xF941D3 — and an instruction-shaped scan of
**both** images finds no other address in the whole region named anywhere.

⚠ Worth recording, because it cost a check: a *bare* three-byte address scan is
useless here. The bitmaps contain byte triples that read as addresses inside
their own region, so that scan returns 61 "targets" of which 58 are pixels. The
scan has to be instruction-shaped.

## ★ Images 0 and 1 are complementary halves of ONE dithered picture

This is arithmetic, not impression:

* the bitwise **AND** of all 9,600 byte pairs is **zero** — not one set bit in
  common;
* their popcounts are **equal**, 3,983 and 3,983;
* so the **OR** has exactly 7,966 set bits, the sum of the two.

Two disjoint half-tones of the same artwork. They go to two different display
layers — the first with `IX = 0x0000`, the second with `IX = 0x4C00`, and
`0x4C00` is **SAD3**, the third graphics layer's base from the SED1330 SCROLL
command that `FINDINGS-display-controller.md` decodes. The controller
OR-composites its layers, so together they make the solid shape and either one
alone is a 50% grey of it — which is how a 1-bit panel draws a grey logo.

Both cover **rows 72-153** of the panel and nothing outside them.

## The third image

`SplashImage_Wordmark` (0xFFCB00) is blitted by 0xF941D3, which sets
`(0x2540) = 1` — the layer selector — immediately before it. It is **not**
dithered: solid pixels, rows 89-121, columns 43-275, one band of large
letterforms, and it plainly reads **`Technics`** — ⚠ MIXED CASE, corrected
2026-08-25; this line first said TECHNICS. Re-rendered from the ROM at full
resolution the glyphs are a capital **T** followed by lowercase **e c h n i c
s**, with the dot of the `i` on row 89. (The image is 40 byte-columns × 240
rows = 9,600 bytes, i.e. 320 × 240, which the source header already states from
the blit site's own `BC = 40` / `HL = 240`.)

⚠ **What images 0 and 1 say is NOT established.** The preview in the source
shows a large italic script logotype in four glyph-like clusters. This tree does
not name it; anyone who wants to read it can run the previews the source already
carries, or re-render at full resolution from the generator.

## Why the source carries ASCII previews

A bitmap has no better rendering in assembly than `.byte`, and `.byte` is
exactly the case `scripts/analysis/source_coverage.py` warns about — territory
converted while telling you nothing. So the generator puts an OR-downsampled
ASCII preview of each image in its header and annotates every `.byte` line with
the **column and row range** those bytes occupy on the panel. The source now
shows what the data looks like without anyone running a tool.

## Open

* What the script logotype reads. A photograph of a real SX-WSA1 or SX-WSA1R at
  power-on settles it in a second, and Felipe's hardware testimony outranks
  anything inferred here.
* Which layer `(0x2540)` selects at 0xF94131 — the first blit's destination
  layer is whatever was selected before it, and that was not traced.
