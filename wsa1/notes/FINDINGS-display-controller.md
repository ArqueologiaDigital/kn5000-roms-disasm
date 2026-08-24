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

A byte census of prom_a and prom_b finds these command bytes written to
`0x790001`, **and no others**:

| byte | SED1330 instruction | where |
|---|---|---|
| `0x40` | SYSTEM SET | `0xF8E81E` |
| `0x42` | MWRITE | `0xF8ED94`, `0xF8F60D`, `0xF8F658`, `0xF8F721`, `0xF8E92B` |
| `0x43` | MREAD | `0xF8ED2F`, `0xF8F5AB`, `0xF8F6BF` |
| `0x44` | SCROLL | `0xF8E866` |
| `0x46` | CSRW | `0xF8ECFB`, `0xF8ED52`, `0xF8F56E`, `0xF8F5D5`, `0xF8F6E9`, `0xF8E915` |
| `0x47` | CSRR | `0xF8F687` |
| `0x4C` | CSRDIR RIGHT | `0xF8F55C`, `0xF8E90B` |
| `0x58` | DISP OFF | `0xF8E8F6` |
| `0x59` | DISP ON | `0xF8F7D7`, `0xF8F832`, `0xF8E99A` |
| `0x5A` | HDOT SCR | `0xF8E8BA` |
| `0x5B` | OVLAY | `0xF8E8C9` |
| `0x5D` | CSRFORM | `0xF8E8DE` |

Names and values from `../mame/src/devices/video/sed1330.cpp:23-39`. Twelve
distinct bytes, twelve hits, zero misses — that is the identification.

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
* All 35 implemented services live in prom_a between `0xF8EAC7` and `0xF90118`,
  and every one of them either touches `0x790000/0x790001` directly or opens with
  the shared setup call at `0xF8EE93`.
* Converted and named so far: `0x0B` plot a point, `0x0C` set which layers are
  on, `0x0D` set which layers blink. The rest are `.long` entries in the table
  with a one-line note on what their first instructions do.

Two RAM bytes worth knowing:

* `(0xC6)` bit 0 — "the panel is dark, do not poll BUSY". Set by service `0x0C`
  when the DISP byte it computes comes out zero, cleared otherwise.
* `(0x2559)` — the last DISP ON/OFF parameter byte sent, so the driver can
  modify one layer without disturbing the others.

**`NMI_PowerFail_SaveAndHalt` calls service `0x0C` with `C = 0`** (`swi 7` with
`A = 0x0C`, `0xF83076`), i.e. the power-fail handler's first act is to blank the
panel — which is also where the meaning of `(0xC6)` bit 0 comes from.

## What to do next here

* Convert the SYSTEM-SET-issuing services `0x0F` and `0x10` — a firmware that
  re-runs SYSTEM SET at runtime is switching panel modes, and that will say
  something about the product.
* The ten services shaped `and BC,BC / jr Z / calr 0xF8EE93 / add IX,(0x2555)`
  are a family of block operations on the current layer; identifying one
  identifies the argument convention for all ten.
* `0xF8EE93` is called first by nearly every service and has not been read.
