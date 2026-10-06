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

⚠ **And it fails on a DITHERED image even for major-order.** `probe` reports,
for the three splash screens:

| image | column-major | row-major |
|---|---|---|
| `SplashImage_Wordmark` (solid type) | **0.0089** | 0.0484 |
| `SplashImage_DitherA` (50% half-tone) | 0.1041 | **0.0875** |
| `SplashImage_DitherB` (50% half-tone) | 0.1041 | **0.0872** |

The wordmark separates the two readings by 5.4x and picks the right one. The two
half-tones — which are the SAME artwork, at the SAME geometry, from the SAME
blit site — pick the wrong one, because a 50% dither has a high edge density
whichever way you read it. Any lane tempted to settle a layout with this
statistic should run it on a control whose answer is already known first.

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

* ~~**The 110 `Bitmap_F78*` labels.**~~ **RESOLVED 2026-09-02 by lane RQ-SHEET —
  see section 8.** The 72-byte grid is right, the `0xF003F9` framing is not, and
  the 110 labels are gone from the source.
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

---

## 7. The KN5000 side of this lane's brief, checked and left alone

The brief asked this lane to confirm `table_data`'s six FTBMP files are still
genuine images and then not touch them, and to say what else on the KN5000 side
is pixel data. Both done; **no KN5000 file was modified**, which is why this
lane's gate is `make gate-wsa1` and not `make gate-all`.

* `python3 scripts/analysis/verbatim_bmp_header_audit.py` → **OK**, all six are
  genuine uncompressed 8bpp `BITMAPINFOHEADER` BMPs, header-consistent and
  byte-identical to their recorded ROM spans: 320x240, 320x130, 320x120,
  320x120, 320x125, 320x240, **318,468 B** total. They are already image files
  in the source with no transform to invert, so there is nothing for a PNG
  round trip to add.
* `python3 scripts/analysis/l4_find_unrecognised_images.py` examines 72 opaque
  blobs at 16 candidate widths and returns **6** that are image-like and
  control-clean — all in `v7/maincpu/includes/romslices/`, scores 0.462 to
  0.714. ⚠ **REFUSED.** Not one is named by a record or by code that states a
  width; the score is a row-similarity statistic, and a statistic is exactly
  what section 1.2 shows cannot fix a geometry. They belong in the inventory
  lane's PURPOSE-UNKNOWN column, not in an images manifest:

  ```
  0.462  v7_transplant_PanelEvt_Handler_4_DualValueCheck.bin   4,008 B
  0.550  v7_data_charmap_valuedata_b.bin                       7,984 B
  0.619  v7_block_semenu_comparescreen_datatable.bin             672 B
  0.671  v7_data_naka_toshiparam_table.bin                     1,872 B
  0.696  v7_transplant_MemoryConfig_Handler_Table_tail_tail.bin  320 B
  0.714  v7_block_accscreen_uidatablock.bin                    2,096 B
  ```

* prom_c and prom_d carry **no** bitmaps this lane can find: the op-03 record
  scan returns 6 and 2 raw `03 0C` pairs in them and **0 plausible records**
  from either. prom_c is the sub-CPU and does not drive the panel.

---

## 8. ★ The two framings of `0xF78028` are settled: THE GRID WINS

Lane RQ-SHEET, 2026-09-02, on the target this note's section 5 handed on. The
rule it followed is the one section 1.2 argues for: **only the consuming code
decides**, because a wrong framing renders plausibly and round-trips
byte-exactly.

Everything below: `python3 notes/gen_prom_b_f78028_icon_sheet.py --evidence
--layout --selftest` (selftest passes, 13 checks, and it refuses if any number
moves).

### 8.1 What settled it — four things, none of them a picture

| evidence | number |
|---|---|
| `DLHandler_Glyph24x24` (`0xF31ACE`) computes `0xF78028 + index * 0x48` and blits `BC=3 / HL=24` | `0x48 = 72 = 3 * 24`: stride **equals** blit size |
| ★ the array **ends exactly on that grid** — the `0x0E` padding begins at `0xF7A1A0` | `0xF7A1A0 - 0xF78028 = 8568 = 119 * 72`, **remainder 0** |
| ★ and 119 is also the highest op-`0x23` index plus one | max index **118**, over 167 records |
| the only immediate `0xF78028` in all four ROM images | **1** hit — that `ld XIY` |
| blank-margin phase test over all 72 phases (row 0 and row 23 of each column) | phase **0** wins, 0.6469 vs 0.5749 for the runner-up |

The third row is the one that carries the argument: the **end of the data** and
the **largest index the UI ever asks for** are measurements of different things,
and they give the same count. A wrong stride has a 1-in-72 chance of even
dividing the span.

⚠ The phase test is **not** the edge-density statistic section 1.2 shows cannot
find grid phase. It is a different quantity, and it is offered as corroboration
of an answer the code already gives — never as the reason.

### 8.2 Why `PtrTable_F003F9` is not the sheet's index — measured, both ways

| test | observed | chance |
|---|---:|---:|
| its 121 targets in the sheet that are on the 72-byte grid | **1** | 1.7 |
| its 24 targets in prom_a's `DisplayList_FC4000` that are on a **record boundary** of that region's *proven* framing (155 records, zero resyncs) | **3** | 1.8 |
| immediates equal to `0xF003F9` in the four ROM images | **0** | — |
| ★ CONTROL — the table 185 B earlier at `0xF00340`, which *does* have a consumer (`add XBC,0x00F0033C` at `0xF00D51`), whose targets start `EE 0C` (`link XIZ,0`) | **25 of 26** | 3.8% |

A table that indexes neither of the two things it points at is not an index of
either — and the control says the instrument can still find a live table.

### 8.3 What replaced them, and what is left

`prom_b/wsa1_prom_b.s` now carries **119 `DLGlyph_NNN_XXXXXX` cells** over
`0xF78028-0xF7A19F`, one `.byte` line per 8-pixel column, each naming its PNG.
The 110 `Bitmap_F78*` labels, `Data_F78029` (609 B) and `Data_F799E8` (1,976 B)
are gone. `make images-check` and `make gate-wsa1` both green; both were shown
to go red at `0x7A15F` on a one-byte perturbation of a converted cell.

**Still open, but sharper.** `PtrTable_F003F9` is ONE table of 216 slots
(`0xF003F9-0xF00758`), shaped **18 columns x 12 rows** — column 17 zero in every
row, columns 13/14 the `0x00FDB10E` filler in every row, columns 15/16 always in
descending address order, and the delta between consecutive targets nearly
constant *down* a column (column 15 is 52 bytes in six successive rows, then 32
in three). Rows 0-9 point into the icon sheet, rows 10-11 into prom_a
`0xFC4082-0xFC4454`. So it is a real 12-screen x 18-field structure whose
objects are not, in this build, where it says they are. `--layout` prints the
grid. The question for the next lane is no longer *what is in the icon sheet*
(119 icons) but **what these 216 slots indexed**, and there is no second build
of this firmware to test the obvious "vestigial index" hypothesis against.

## 9. The small-icon origin, RAM 0x2350 / 0x2352, and the four drawers that use it (2026-10-04)

Every read of 0x2350 and 0x2352 in either image is in prom_b 0xF5BBE7-0xF5BEFA. They are read
by four routines, each of which positions its whole picture relative to them.

| routine | what it draws at (X, Y) = ((0x2350), (0x2352)) |
|---|---|
| `OctaveIcon_Draw` (0xF5BCE8) | one 28-pixel octave at (IX, IY). The outline is a FillRect-family box (service 0x09). It has six dividers (service 0x02, VLine) and the five black keys of `OctaveIcon_BlackKeyX`. |
| `KeyboardIcon_Draw` (0xF5BBE7) | seven `OctaveIcon_Draw`s with IX stepping by 28 from (0x2350), then the closing top key at +196..+200 and the marks either side of it. |
| `TouchCurve_DrawThumbnail` (0xF5BE5A) | the curve in bits 5..7 of the byte at XIZ. Curve 3 erases the 37 x 37 box at +1 (service 0x1B) and draws the diagonal from (+1, +38) to (+38, +1) (service 0x00, DrawLine). Any other curve blits `CurveBitmapSelector[curve]`, 40 x 40, at y*40 + x/8 (service 0x03). |
| `TouchCurve_DrawCurrentSlot` (0xF5BDBB) | first stores the origin itself: (0x2350), (0x2352) = `TouchCurve_BoxOrigins[(0x27A3)]` (or `..._BoxOrigins3` when (0x27F5) is 1). Then `TouchCurve_DrawThumbnail` on `ModelingPage_Fields+5` / `+8` + (0x27A3), and the slot's `TouchCurve_ListPtrs` list. Called by `Draw_Page12LevelTouchCurveLevel` and `SoundEditAmpLevel1_RepaintField`. |

The other writers set constants before `call KeyboardIcon_Draw`:

- (56, 139) in the two KEY FOLLOW painters (`Draw_Page22KeyFollowEnvelopeKeyFollowTouchAtk`,
  `..._TouchAttack`) and in `SoundEditFilterKeyFollow_PaintKeyboardAndValues`;
- (47, 51) in `SoundEditToneLayerKeyLayer_Paint`, the KEY LAYER page, whose subject is a key range.

The two words are named `IconOrigin_X` / `IconOrigin_Y` for that role.

`TouchCurve_DrawThumbnail` is also the filler entry of the two 48-entry selector tables
`DispatchTable_F5B8F8` / `DispatchTable_F5B9F8` (entries 1, 28, 41, 44, 46, 47, and entry 21 of the
second). Those selectors have no page, and nothing here shows them being selected.

⚠ Not established: the three-way value of (0x27F5). It is 1 or 2 from `ScreenEnter_SoundEditMenu`'s
test of a record byte & 0xC0 (0x80 -> 1, 0x40 -> 2), and `SoundEditCopy_Paint` shows `DRUM KIT:` texts
when it is 1. It is not named here.
