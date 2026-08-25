# The WSA1's display is driven by an SED1330-family LCD controller

**Established 2026-08-24 while converting prom_a.** Two independent checks, both
citable to MAME rather than to memory, plus a third that falls out of the
parameter bytes themselves.

The controller sits on CPU 1's CS0 area at **0x790000 / 0x790001**, and every
routine that talks to it is in prom_a, in the block `0xF8E800-0xF90xxx`.

## 1. The port shape

| address | read | write |
|---|---|---|
| `0x790000` | **status** — busy in bit 6 | **data** |
| `0x790001` | **data** | **command** |

That is exactly how MAME's own drivers wire `sed1330_device`:

```
map(0x1f70, 0x1f70).rw("lcdc", FUNC(sed1330_device::status_r), FUNC(sed1330_device::data_w));
map(0x1f71, 0x1f71).rw("lcdc", FUNC(sed1330_device::data_r),   FUNC(sed1330_device::command_w));
```
`../mame/src/mame/skeleton/textelcomp.cpp:147-148`, and the same pairing appears
commented out in `../mame/src/mame/epson/px8.cpp:534-535`.

The busy bit matches too: `sed1330_device::status_r` returns `m_bf << 6`
(`../mame/src/devices/video/sed1330.cpp:245-251`), and the firmware's poll,
repeated ~30 times across the driver, is

```
	bit_dd8 0x00, 0xc6		; (0xC6) bit 0 = "display off, do not wait"
	jr nz, .skip
.wait:	bit 6,(0x790000)
	jr nz, .wait
```

## 2. The command set

**Corrected and re-derived 2026-08-24.** ⚠ The first version of this section
listed twelve command bytes and said "and no others". It was produced by a
census of the 24-bit direct form `ld (0x790001),n` alone, and the driver reaches
the port far more often through a BASE REGISTER -- `ld XIZ,0x00790000` once, then
`ld (XIZ+0x01),n` repeatedly. Those writes were invisible to it, and one command
byte, **0x4F CSRDIR DOWN**, was missing from the table entirely. Nothing in the
identification changes -- every byte is still inside MAME's SED1330 instruction
table -- but the evidence is now seven times larger.

Reproduce with `python3 notes/lcd_command_census.py` (`--sites` for every
address). It finds each `ld XIX/XIY/XIZ/XBC,0x00790000`, **confirms with unidasm
that the instruction really is that load**, disassembles forward from it to the
first return and collects the immediate writes to that register's `+0x01`; it
then does the same for the direct form.

| byte | SED1330 instruction | sites |
|---|---|---:|
| `0x40` | SYSTEM SET | 3 |
| `0x42` | MWRITE | 20 |
| `0x43` | MREAD | 10 |
| `0x44` | SCROLL | 4 |
| `0x46` | CSRW | 23 |
| `0x47` | CSRR | 4 |
| `0x4C` | CSRDIR RIGHT | 7 |
| `0x4F` | **CSRDIR DOWN** | 4 |
| `0x58` | DISP OFF | 3 |
| `0x59` | DISP ON | 5 |
| `0x5A` | HDOT SCR | 1 |
| `0x5B` | OVLAY | 4 |
| `0x5D` | CSRFORM | 1 |

**13 distinct bytes, 89 sites, 0 outside the table.** Names and values from
`../mame/src/devices/video/sed1330.cpp:23-39`. Every site is in prom_a; prom_b
never touches the controller.

The two ends of the list were checked by hand against unidasm rather than
trusted from the script: `f8e81e: bd 01 00 40  ld (XIY+0x01),0x40` (SYSTEM SET,
the first row) and `f8e8de: bd 01 00 5d  ld (XIY+0x01),0x5d` (CSRFORM, the last).

⚠ The count is a **lower bound on the sites**, not a completeness proof: the
script does not follow a base register across a call and stops at the first
return. It is an upper bound on nothing -- a byte outside the SED1330 table
would still have shown up if it were written this way, and none was.

★ CSRDIR DOWN is what makes `LCD_Svc_03_BlitColumns` (0xF8EDB4, converted)
legible: it sets the cursor to advance DOWNWARD, writes a whole column of
bytes with one MWRITE run, then moves the cursor start one byte to the RIGHT
and does the next column. The driver's block operations are column-major.

## 3. The panel the parameters describe

`LCD_Init_SED1330` (prom_a `0xF8E819`, converted) sends SYSTEM SET with

```
30 07 00 27 35 EF 28 00
```

which `sed1330_device::data_w` (`sed1330.cpp:344-405`) decodes as

* internal CG ROM, 8-line character height, single-panel drive, IV set
* `FX = 7+1 = 8` — **8 pixels per byte**
* `FY = 0+1 = 1`
* `C/R = 0x27+1 = 40` — **40 bytes displayed per line = 320 pixels**
* `TC/R = 0x35+1 = 54` byte-times per line
* `L/F = 0xEF+1 = 240` — **240 lines**
* `AP = 0x0028 = 40` bytes per line

then SCROLL with `00 00 F0 00 26 F0 00 4C`, i.e. **SAD1 = 0x0000, SL1 = 240,
SAD2 = 0x2600, SL2 = 240, SAD3 = 0x4C00** (SAD4 is not sent) — and the routine
immediately stores those same three base addresses in RAM at `(0x2541)`,
`(0x2543)`, `(0x2545)`, which is the internal cross-check.

then OVLAY `0x1C`: `MX = 0` (OR composition), layer 1 and layer 3 in **graphics**
mode, `OV = 1` (three layers); then DISP OFF `0x54` (cursor off, all three layers
solid); then it MWRITEs **0x800 x 16 = 32768 zero bytes**, clearing the whole
display RAM, and finally issues DISP ON with no parameter.

**So: 320 x 240, 1 bit per pixel, three OR-composited graphics layers based at
display-RAM 0x0000 / 0x2600 / 0x4C00, 32 KB of display RAM.**

A fourth, independent confirmation of the geometry: the pixel plotter
(`LCD_Svc_0B_PlotPoint`, `0xF8ECB5`) computes `address = Y*(0x2557) + X/8 +
(0x2555)` and indexes an 8-entry mask table at `0xF8EDAC` holding exactly
`80 40 20 10 08 04 02 01` with `X mod 8`. `(0x2557)` is the byte SYSTEM SET was
given as `APL`. MSB-leftmost, 8 pixels per byte, 40 bytes per line — the same
panel, derived from completely different code.

⚠ **What is NOT established: the exact part.** SED1330, SED1335, S1D13305 and the
second-source clones share this command set, and nothing in the firmware
distinguishes them. Write "SED1330-family". (MAME itself uses `sed1330_device`
for an SED1335 in `../mame/src/mame/yamaha/ympsr2000.cpp:31`.)

## The software above it: SWI7 is the graphics API

`swi 7` is this firmware's system call. The vector (slot `0x1C`) reaches
`SWI7_ServiceCall_Dispatch` at prom_a `0xF8E9A5` through a prom_b thunk; it masks
the service number with `0x3F` and indexes `SWI7_ServiceTable` at `0xF8E9C6`.

* The table is **64 entries, 256 bytes**, and its length is proved by that mask:
  slot `0x18` and every slot from `0x23` up hold `0xF8EAC6`, a bare `RET`.
* **34 slots are live and they name 34 distinct routines**, all in prom_a between
  `0xF8EAC7` and `0xF908FF`; the other 30 are dead. ⚠ An earlier version of this
  line said "35 implemented services ... between 0xF8EAC7 and 0xF90118". Both
  numbers were counted by hand and both were wrong. Regenerate them with
  `python3 notes/swi7_service_table.py` (`--slots` lists every slot); it reads
  the table out of the ROM, checks that all 34 targets land inside prom_a, and
  checks that the byte after slot `0x3F` is the `0x0E` RET the dead slots point
  at.
* Every live service either touches `0x790000/0x790001` directly or opens with
  the shared setup call at `0xF8EE93`.
* **All 34 are converted and named** as of 2026-08-25 — the eleven the
  2026-08-24 version of this line listed as still `.incbin`
  (`0x0E 0x0F 0x10 0x11 0x12 0x14 0x15 0x17 0x1B 0x1C 0x1E`) have since been
  done. Re-derive the list with `python3 notes/swi7_service_table.py`, which
  reads the table out of the ROM and decides "converted" from the `.incbin`
  chain rather than from any list kept by hand:

  | service | what it is |
  |---|---|
  | `0x00` | draw a **line** between two points, DDA with a 1/100 fixed-point slope |
  | `0x01` / `0x02` | a solid **horizontal** / **vertical** run of pixels |
  | `0x03` / `0x04` | **blit** a rectangle column-major / read one back |
  | `0x05` | **fill** a rectangle, with OVLAY MX forced to 1 |
  | `0x06 0x07 0x08 0x20 0x21` | **text**, byte-aligned, one per Latin face |
  | `0x16 0x19 0x1A 0x1D 0x1F` | **text** in the five Japanese faces — half-width katakana, katakana, kanji set A, hiragana, kanji set B (`FINDINGS-fonts.md`) |
  | `0x17` / `0x1C` | **text, proportional** — 6 and 11 pixels apart, starting at any pixel column, through a shift-and-merge staging buffer.  Two more faces, `0xF1E470` and `0xF1EAB0` |
  | `0x09` | a rectangle **outline** = `0x01` twice + `0x02` twice |
  | `0x0A` / `0x22` | `0x09` plus a two- / one-pixel **drop shadow** |
  | `0x0B` | plot a point |
  | `0x0C` / `0x0D` | which layers are on / which blink |
  | `0x0E` | clear a run of byte-columns |
  | `0x0F` / `0x10` | re-issue SYSTEM SET for a **two-** / **three-layer** panel |
  | `0x11` / `0x12` | a **dithered** horizontal / dashed vertical run |
  | `0x13` | `0x09` built from the **patterned** line pair `0x11`/`0x12` |
  | `0x14` | fill a rectangle with a **pattern** |
  | `0x15` | a **dashed** line |
  | `0x1B` | erase a rectangle |
  | `0x1E` | **scroll** the current layer |

  ⚠ That is **twelve** text services across **twelve** faces, not the ten this
  note and `FINDINGS-fonts.md` used to say: the two proportional ones were
  missed because the census that produced "ten" searched a fixed 0x40-byte
  window and they load their font base about 0x50 bytes in.

Two RAM bytes worth knowing:

* `(0xC6)` bit 0 — "the panel is dark, do not poll BUSY". Set by service `0x0C`
  when the DISP byte it computes comes out zero, cleared otherwise.
* `(0x2559)` — the last DISP ON/OFF parameter byte sent, so the driver can
  modify one layer without disturbing the others.

**`NMI_PowerFail_SaveAndHalt` calls service `0x0C` with `C = 0`** (`swi 7` with
`A = 0x0C`, `0xF83076`), i.e. the power-fail handler's first act is to blank the
panel — which is also where the meaning of `(0xC6)` bit 0 comes from.

## `0xF8EE93` — read 2026-08-24, and it is what names `(0x2555)`

`LCD_SelectCurrentLayer` (prom_a `0xF8EE93`, converted) is three lines of real
work: take the layer number in `(0x2540)`, scale it by 4, index a **three-entry
table of 32-bit pointers at `0xF8EEB1`**, and copy the 16-bit word the entry
points at into `(0x2555)`.

The three pointers are `(0x2541)`, `(0x2543)` and `(0x2545)` — **exactly the
three RAM words `LCD_Init_SED1330` fills with SAD1, SAD2 and SAD3** from the
SCROLL command (section 3 above). So:

* `(0x2540)` = which of the three layers is being drawn into,
* `(0x2555)` = that layer's display-RAM base,

and every drawing service's `add WA,(0x2555)` is "turn the caller's offset into
an absolute display-RAM address". The table's length is fixed by arithmetic
rather than inspection: `0xF8EEB1 + 3*4 = 0xF8EEBD`, which is the address
`SWI7_ServiceTable` slot `0x05` holds, so a fourth entry would overlap a
service's first instruction.

## The argument convention of the block services

Services `0x03` and `0x04` are converted, and they fix it for the family:

| register | meaning |
|---|---|
| `IX` | byte offset of the top-left corner **within the current layer** |
| `BC` | number of columns |
| `HL` | bytes down each column |
| `XIY` | source (`0x03`) or destination (`0x04`) buffer, advanced as it goes |

Both return immediately if `BC` or `HL` is zero, and neither clips. They differ
only in MWRITE vs MREAD and in which way the inner `ld` runs.

## The drawing state, as it now stands

All of it is CS1 static RAM, all 16-bit unless said otherwise:

| address | meaning | established by |
|---|---|---|
| `(0x2530)` `(0x2532)` | X0, Y0 | the clamp: 319 and 239 |
| `(0x2534)` `(0x2536)` | X1, Y1 | same |
| `(0x2540)` | the current layer number | `LCD_SelectCurrentLayer` |
| `(0x2541)` `(0x2543)` `(0x2545)` | the three layers' SAD values | `LCD_Init_SED1330` writes them |
| `(0x2547)` bit 0 | the line draw's "X and Y are swapped" flag | `LCD_Line_ChooseMajorAxis` |
| `(0x2548)` | slope x 100 | `LCD_Line_ComputeSlope` |
| `(0x254A)` | intercept x 100 | `LCD_Line_ComputeIntercept` |
| `(0x2550)` `(0x2552)` | the point being plotted | `LCD_PlotPointAt` reads them |
| `(0x2554)` | the OVLAY shadow | service `0x05` masks it with `0xFC` |
| `(0x2555)` | the current layer's display-RAM base | `LCD_SelectCurrentLayer` writes it |
| `(0x2557)` | AP, bytes per line (40) | the plotter multiplies Y by it |
| `(0x2559)` | the last DISP ON/OFF parameter | service `0x0C` |
| `(0x255A)` | the display address of the run being drawn | services `0x01`, `0x05`, `0x11` |
| `(0x255C) (0x255E) (0x2560) (0x2562)` | the four coordinates saved across a shadowed box | services `0x0A`, `0x22` |
| `(0xC6)` bit 0 | "the panel is dark, do not poll BUSY" | service `0x0C` |

## ★ The layer count no longer rests on the table alone

**2026-08-25.** The third open item below used to read *"Nothing yet writes
`(0x2540)`. Finding that writer names the three layers."* The writers are now
counted, and they settle the count even though they do not settle the names.

`python3 notes/lcd_layer_census.py` censuses every access to `(0x2540)` in both
images:

| access | sites | prom_a | prom_b |
|---|---:|---:|---:|
| `ld (0x2540),#imm` | **764** | 436 | 328 |
| `ld (0x2540),r` | 7 | 2 | 5 |
| `ld r,(0x2540)` | 7 | 2 | 5 |
| `lda r,0x2540` (take the address) | 6 | 4 | 2 |

★ **Over those 764 immediate writes the value is 0 at 499 sites, 1 at 180 and 2
at 85 — never 3, never anything else.** Three layers, from the code that selects
them rather than from the observation that a fourth table entry would overlap a
service's first instruction.

⚠ That is a byte-pattern census and cannot tell code from data. It does not need
to: coincidental matches would spread the immediate over `0..255`, and this one
never exceeds 2 in 764 tries. And exactly one of the sites falls inside source
this tree has converted — `0xF8EEBD`, the first instruction of
`LCD_Svc_05_FillRect`, spelled `stdi8 (0x2540), 0x01` — so at least one hit is
confirmed to be a real instruction at a real boundary, by the byte gate itself.

★ That one site is a finding of its own: **service `0x05` forces layer 1 before
doing anything else**, so a filled rectangle always lands in SAD2 = `0x2600`
whatever the caller had selected.

⚠ **The layers are still not NAMED.** Knowing the values are 0, 1, 2, and that
layer 0 is chosen three times as often as layer 2, does not say which is menu,
which is keyboard graphics and which is an overlay.

## Who calls the services

`python3 notes/swi7_call_sites.py` censuses `ldb a,nn` + `swi 7` — the
three bytes `21 nn ff`. Six of the seven Latin text services have literal call
sites (`0x06` 18, `0x20` 21, `0x17` 5, `0x08` 4, `0x07` 3, `0x21` 3) and so do
`0x0C` (57), `0x10` (15), `0x05` (11) and others; **none of the five Japanese
text services has one**. The census measures its own noise floor — 7 of 188 hits
land on slots that are dead — and that asymmetry is far outside it. See
`FINDINGS-fonts.md` §6 for what it does and does not mean.

⚠ Those are call SITES, not converted callers, so the `HL` argument of the text
services still has no established meaning.

## What to do next here

* **Name the three layers.** It needs a converted caller, and the callers are in
  prom_b.
* Convert one of the 18 `0x06` call sites, which would fix the `HL` argument for
  the whole text family at once.
* The seven `ld (0x2540),r` sites are the interesting ones: they select a layer
  computed at run time, so whatever feeds them is the layer policy.
