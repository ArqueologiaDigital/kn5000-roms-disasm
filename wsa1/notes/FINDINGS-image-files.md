# The WSA1R's images are image files now — and three committed readings were transposed

Lane IMAGE, 2026-09-02, against `notes/lanes/BRIEF-2026-09-01.md` and the
project owner's rule: *"if a data range is an image, it should be represented in
the source as an image file (such as PNG)."*

Before this pass the WSA1R tree carried **zero image files**. Every bitmap was
`.byte` rows, some with an ASCII-art preview in a comment. It now carries **216
PNGs covering 93,656 bytes** of prom_a and prom_b, each one a lossless, exact
rendering of its range, each regenerating the `.byte` rows it came from:

```
python3 scripts/build/wsa1_bitmaps.py check     # 204 bitmaps,  46,152 B
python3 scripts/build/wsa1_fonts.py   check     #  12 faces,    47,504 B
```

`check` re-derives every `.byte` value from the committed PNG and asserts the
assembly already holds exactly those bytes; `rewrite` makes the PNG the thing
you edit. Both exit non-zero on drift. `make images-check` in `wsa1/` runs both.

---

## 1. ★ One routine defines the format, and it is COLUMN-MAJOR

Every bitmap here is drawn by SWI7 service 3, `LCD_Svc_03_BlitColumns`
(prom_a `0xF8EDB4`). Its loop **is** the storage layout:

```
ld (XIZ+0x01),0x4f    ; CSRDIR DOWN -- the SED1330 cursor steps one RASTER LINE
                      ;                per byte written
                      ; outer loop runs BC times
  ld BC,HL            ; inner count is HL
  ld E,(XIY) / inc 1,XIY / ld (XIZ),E   ; HL bytes, consecutive, going DOWN
inc 1,WA              ; the next column starts ONE BYTE along in display RAM
```

One display-RAM byte is 8 **horizontal** pixels, MSB leftmost. `inc 1,WA` moves
the destination 8 pixels right. Therefore, for every op-03 object:

```
width = BC * 8      height = HL
pixel (x, y) = bit (7 - x%8) of byte  (x//8) * HL + y
```

★ **The calibration, and it needs no argument.** Apply that formula to
`0xFFCB00` with the `BC=40 / HL=240` its own blit site at `0xF941D3` sets, and
the picture reads **`Technics`** in the brand's serif face. Apply it to
`0xFF8000` OR `0xFFA580` and it reads **`WSA`** in a brush script. A wrong
reading does not produce legible type.

### ⚠ 1.1 Three committed readings are the TRANSPOSE of that, and the byte gate cannot see it

A wrong major-order still round-trips byte-exactly: the bytes are the ROM's, in
ROM order, either way. Only the picture changes. These headers are wrong about
the layout while right about the size:

| where | says | is |
|---|---|---|
| `Bitmap_F54718_48x20`, `Bitmap_F54790_48x20`, `Bitmap_F54D7E_304x6` | "BC IS the width in bytes and HL the row count", "N bytes per ROW x M rows" | BC is the COLUMN count; HL is bytes DOWN each column |
| `Bitmap_F17C59_24x17`, `Bitmap_F05CE0` | "3 bytes per row x 17 rows", "2 bytes wide x 12 rows" | same |
| the `0xF0199E` cluster header | "5 pages of 40 columns (a byte is one column, MSB the top row of its page)"; "a 24-byte cell rendered as 12 columns * 2 pages is a 12x16 icon" | 5 COLUMNS of 40 bytes = 40x40; a 24-byte cell is BC=2 / HL=12 = **16x12** |

The last one is the instructive case. Both readings draw a circle for
`0xF019AA`, because a circle is nearly symmetric under transposition — which is
precisely why the eye cannot settle it. The **records** settle it: ten op-03
records name `0xF019AA` and every one carries `BC=2, HL=12`.

### ⚠ 1.2 Edge density settles major-order, NOT grid phase

4-neighbour edge density is a good instrument for column-vs-row-major, because
those are transposes: on the eight widgets at `0xFC48D7` column-major draws
connected slider tracks and envelope curves and row-major draws disconnected
noise. It is **useless for finding where a repeating grid starts**. Measured:

| array | aligned | +12 B | +24 B | +36 B |
|---|---|---|---|---|
| `0xF78028`, 67 used slots | 0.2450 | 0.2477 | 0.2493 | 0.2512 |
| `0xF31EE1`, alignment CERTAIN | 0.0857 | — | — | **0.0801** |

On the array whose phase is not in doubt, the *misaligned* reading scores
better. Phase comes from the code that computes the address, never from a
statistic over the pixels.

---

## 2. Where each geometry comes from

Three kinds of evidence, in descending order. `wsa1_bitmaps.py list` prints each
entry's own.

**(a) An op-`0x03` display-list record.** `03 0C` + ptr32 + IX16 + BC16 + HL16,
run by `DLHandler_FarPtr` (prom_b `0xF31ABE`), which loads those fields and
issues service 3. `wsa1_bitmaps.py census` re-derives them from all four ROMs:

* **119 records, 30 distinct targets, and not one target carries two different
  `BC`/`HL` pairs.**
* ★ **The false-positive floor is MEASURED.** The same scan run for 80 randomly
  chosen two-byte opcode pairs across all four images finds **0** plausible
  records — mean 0.00, max 0. `census` asserts that floor is still zero, so if
  the test ever becomes noisy it fails rather than quietly widening.

**(b) Converted code that sets BC/HL and the source address literally.** The
three splash blits; `DrawValueGlyph_24x24` (`0xF31873`); `DLHandler_Glyph24x24`
(`0xF31ACE`); the selector table at `0xF5BEFB` through the blitter at
`0xF5BECE`; the pointer table at `0xF09B7B` through the blit at `0xF09B29`.

**(c) Nothing else.** A range with no record and no code naming it is REFUSED —
section 5 — however obviously it looks like a picture. A wrong width produces a
plausible picture that round-trips perfectly, and the byte gate cannot object.

---

## 3. ★ What the pictures turned out to be

Things that were open questions or blank labels until someone could look:

* **The splash logotype reads `WSA`.** `SplashImage_DitherA` and
  `SplashImage_DitherB` are disjoint half-tones of ONE picture (bitwise AND = 0,
  equal popcounts 3983/3983) that the SED1330 OR-composites across two layers.
  Opened together they are a brush-script **`WSA`**.
  ⚠ This CLOSES the "⚠ What the script logotype reads" entry under **Open** in
  `notes/FINDINGS-prom_a-splash-bitmaps.md` and the matching
  "⚠ WHAT THE ARTWORK SAYS IS NOT ESTABLISHED" warning in
  `prom_a/wsa1_prom_a.s`. Felipe's hardware testimony still outranks this: a
  photograph of a real SX-WSA1 at power-on is the last word.
* **`0xF78028` is the WSA1's UI icon sheet** — 119 cells of 24x24 on the grid
  `DLHandler_Glyph24x24` computes. Opened as a sheet it is unmistakable: MIDI
  plugs, `EDIT`, `ROM/ORIG`, the `GENERAL MIDI` logo, a `PRESET` grid, a
  keyboard, a tuning fork, a metronome, a clock, disks, `SONGS`, `NOM/EXP`,
  waveforms, envelope curves, a grand piano, a mixer.
* **The ten `0xFF17E2` strips are a vertical piano-keyboard ruler** labelled
  `C-2 C-1 C0 ... C8` — the same keyboard at ten scroll positions, i.e. a key
  range / split point display.
* **`0xF31EE1` is a 29-step rotary knob**; consecutive cells rotate the pointer.
* **The six `0xF019C2` objects are response-curve thumbnails**, concave through
  convex, in a 40x40 frame — which is what a "monotone rising curve" selector
  needs, and what the transposed reading would have mirrored.
* **`Font_Svc21`'s code `0x5C` is `¥`, not a backslash** — JIS X 0201 Roman,
  one more independent sign that this is a Japanese-market machine.
* In **kanji set A**, adjacent cells repeatedly form compound words
  (状態 心配 故障 工場 出荷 構成 再生 最適 簡単 機器 演奏 音色 記憶 設定 選択
  自動 確認). ⚠ Read off the sheet by eye. Worth following up: it suggests the
  private encoding of `FINDINGS-fonts.md` section 5 numbers the kanji in the
  order the UI's own message text first needs them — which would make that
  section's "the single most valuable thing to find next" reachable from the
  strings rather than from a standard.

---

## 4. ⚠ `Bitmap1bpp_FC48E4` is eight 48x15 objects, not one 120x172 one

`prom_a/wsa1_prom_a.s` frames `0xFC48E4-0xFC52F7` as "2580 bytes, 172 rows x 15
bytes (120 px), 1bpp", row-major, from a 15-byte autocorrelation peak in three
rare byte values.

**The peak is real. Its interpretation is not.** 15 is the COLUMN HEIGHT of a
column-major object, not a row stride:

* prom_b `0xF09B7B` is a pointer table of **exactly eight** entries —
  `0xFC48D7 + k * 90`, stride `0x5A = 6 * 15`. Eight is not assumed: the index
  table it is driven through, `0xF09B3B`, is 64 bytes whose maximum value is 7,
  and the words after entry 7 are code.
* Its consumer at `0xF09B29` is `ldb A,0x03 / ldw BC,0x0006 / ldw HL,0x000F /
  swi 7` — BC=6, HL=15, so 48 x 15 and 90 bytes, exactly the stride.
* The objects start at `0xFC48D7`, **13 bytes before** the committed label.
* Rendered column-major they are eight connected pictograms (a flat bar, a
  cylinder, tapered wedges, a parallelogram, a spool, an arrow, a bolt).
  Rendered row-major at the committed width they are disconnected noise.

Those eight (720 B) are exported as `Widget_FC48D7.png` .. The remaining
1,860 bytes of the committed range are named by nothing and their object grid is
**unknown** — see section 5.

---

## 5. REFUSED — looks like a picture, geometry not established

`wsa1_bitmaps.py list` prints this list with the tool, so it cannot drift from it.

* **The 110 `Bitmap_F78*` labels.** Their EXTENTS come from the pointer table at
  `0xF003F9`, whose targets are **not** on the 72-byte grid
  `DLHandler_Glyph24x24` computes (`0xF7828A - 0xF78028 = 610`, not a multiple
  of 72). The 72-byte grid is exported, because the handler's own arithmetic
  fixes it and the sheet is plainly an icon set; the `0xF003F9` framing is a
  SECOND, incompatible reading of the same bytes. ⚠ **Whoever owns those labels
  should re-examine them against the icon sheet** — one of the two framings is
  wrong and this lane did not settle which.
* **`0xFC48E4-0xFC52F7` beyond the eight widgets** — 1,860 bytes, section 4.
* **`Bitmap_DrawbarA` / `Bitmap_DrawbarB`** (699 B each). The source header
  establishes 3 slices of 233 bytes blitted 1 byte x 0x7B rows with the source
  advanced by 233, so the drawn image is a 123-row **window** into a 233-row
  slice at a run-time offset. There is no single rectangle to call the image.
* **`Bitmap_F0D5BF_80x24` is EXPORTED but its width is INFERRED, not read.** No
  record and no code names `0xF0D5BF`; `BC=10` is a boundary argument (the run
  must end at `0xF0D6AF`, and `0xF0D5BF` is the only 24-aligned start that does
  not split the `0x01..0x21` ramp above it). It is the one entry in the manifest
  whose evidence line begins with a warning sign. Treat the PNG as the best
  available reading, not as established.

---

## 6. Reproducing every number in this note

| number | command |
|---|---|
| 119 records / 30 targets / 0 ambiguous / null 0 | `python3 scripts/build/wsa1_bitmaps.py census` |
| 204 images, 46,152 B, 0 failures | `python3 scripts/build/wsa1_bitmaps.py verify` |
| 12 faces, 47,504 B, 0 failures, abutments | `python3 scripts/build/wsa1_fonts.py verify` |
| the assembly equals the PNGs | `make images-check` (in `wsa1/`) |
| edge densities, column vs row major | `python3 scripts/build/wsa1_bitmaps.py probe` |
| the ROM still rebuilds | `make gate-wsa1` (from the repo root) |

★ And the check that certifies the checks: flip one pixel of
`prom_b/images/Bitmap_F05CE0.png`, run `wsa1_bitmaps.py rewrite`, and
`make gate-wsa1` goes red with `DIFFERS wsa1_prom_b.ic13: 1 byte(s), first at
0x5CE0` — the address of that pixel. Done 2026-09-02; the tree is restored.
