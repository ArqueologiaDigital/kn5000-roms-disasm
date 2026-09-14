# NEC µPD6383GF-3BA — the 100-pin package, read off the schematics

**What this answers:** the project has cited individual pins for a year — `SETRDY` (100),
`BR-RQ` (11), `RDY` (8), `RQ1-3`/`GF1-3` (83-88) — from four different notes, and has never had
the pinout in one place. NEC never published a datasheet for this part that anyone has found
(`LEDGER §396`: 0 hits for 638x across bitsavers' complete NEC holdings), so this table **is** the
pinout as far as this project is concerned.

**Source, and it is better than the one we expected.** The plan was to read the Pioneer CDJ-500
service manual, where the chip is IC302. That was not necessary: the **SX-WSA1R service manual**
draws **three** µPD6383GF-3BA — IC5, IC6 and **IC30** — and IC30 is drawn complete and
uncrowded on sheet **II-15/II-16 (PDF page 23)**. Every row below was read from a 400 dpi render
of that page:

```
pdftoppm -f 23 -l 23 -r 400 -png -gray "SX-WSA1R Service Manual.pdf" hi23
```

⚠ These are image-only scans — `pdftotext` returns nothing, and that has produced two false
negatives on this project already. Render before concluding anything is undocumented.

**Package.** 100-pin QFP. Pin 1 at the bottom-left, numbering **counter-clockwise**: pins 1-30
along the bottom edge, 31-50 up the right edge, 51-80 right-to-left along the top, 81-100 down
the left edge. (Forced: pin 1 and pin 30 bracket the bottom row, 31 and 50 the right, 51 is the
rightmost of the top row, and 81/100 are the top/bottom of the left column — all four read
directly.)

---

## The table

`/X` marks a pin the schematic draws with an overbar (active low).

### Bottom edge — host interface, reset, serial audio

| pin | name | pin | name | pin | name |
|---|---|---|---|---|---|
| 1 | `/CS` | 11 | `/BR-RQ` | 21 | `DI2` |
| 2 | `/C/D` | 12 | `/BR-AK` | 22 | `DI3` |
| 3 | `/SCK` | 13 | `/Fs-RST` | 23 | `DO1` |
| 4 | `SI` | 14 | `/Fs-MASK` | 24 | `DO2` |
| 5 | `SO` | 15 | `VDD` | 25 | `DO3` |
| 6 | `EIFLAG` | 16 | `GND` | 26 | `BCLKO` |
| 7 | `EOFLAG` | 17 | `BCLKI` ⚠ | 27 | `LRCKO` |
| 8 | `RDY` | 18 | `LRCKI` | 28 | `XFsO1` |
| 9 | `/RST` | 19 | `XFsI` | 29 | `XFsO2` |
| 10 | `/RST2` | 20 | `DI1` | 30 | `TEST` |

⚠ **Pin 17's number is the one cell in the whole table that is not legible** — it is obscured by a
ground stub in the drawing. `BCLKI` is placed there because the run 15/16/[17]/18 is otherwise
unbroken and the label pitch is uniform. Everything else was read directly.

### Right edge — mode straps, clock, external DRAM control and low address

| pin | name | pin | name |
|---|---|---|---|
| 31 | `/EROF` | 41 | `GND` |
| 32 | `MD1` | 42 | `VDD` |
| 33 | `MD2` | 43 | `/RAS` |
| 34 | `MD3` | 44 | `/CAS` |
| 35 | `MD4` | 45 | `/WE` |
| 36 | `GND` | 46 | `A0` |
| 37 | `EOSC` | 47 | `A1` |
| 38 | `SEL` | 48 | `A2` |
| 39 | `XI` | 49 | `A3` |
| 40 | `XO` | 50 | `A4` |

### Top edge — external DRAM address and data

| pin | name | pin | name |
|---|---|---|---|
| 51-62 | `A5` … `A16` (ascending with pin number) | 65-80 | `I/O1` … `I/O16` (ascending) |
| 63 | `VDD` | 64 | `GND` |

### Left edge — flags, parallel host port

| pin | name | pin | name |
|---|---|---|---|
| 81 | `GND` | 91 | `/READ` |
| 82 | `VDD` | 92-99 | `D0` … `D7` |
| 83 | `GF1` | 100 | `SETRDY` |
| 84 | `GF2` | | |
| 85 | `GF3` | | |
| 86 | `RQ1` | | |
| 87 | `RQ2` | | |
| 88 | `RQ3` | | |
| 89 | `/P/S` | | |
| 90 | `/WRITE` | | |

---

## What the pinout settles

**★ The external memory bus is 17 address lines and 16 data lines.** `A0`-`A16` (pins 46-50 and
51-62) and `I/O1`-`I/O16` (65-80). `instruction-set.md`'s open item *"`N` in `mod 2^N` — 17 vs 18
address bits"* has been carrying the note *"the firmware never uses more than 16 bits"*; the chip
provides **17**, which bounds the question from the silicon side rather than from the corpus.

**★ The chip has two host interfaces and the two products use different ones.** Pin 89 `/P/S`
selects. The **KN5000** wires the serial side — `/CS`, `/C/D`, `/SCK`, `SI`, `SO`, `RDY`
(`second-dsp-and-ready.md`, KN5000 manual p.35). The **WSA1R's IC30 ties `/P/S` to +5D** and wires
the **parallel** side: `D0`-`D7` on pins 92-99 to nets `DSPD0`-`DSPD7`, `/WRITE` (90) to `DSPWR`,
`/READ` (91) to `DSPRD` — which is exactly what `wsa1.cpp` describes as "P7 (DSPD0-7)". Same
silicon, two different host ports.

**⛔ `GF1`-`GF3` and `RQ1`-`RQ3` are unusable on the WSA1R, and this closes a decode route.**
On IC30:

* **`RQ1`/`RQ2`/`RQ3` (86/87/88) are tied together and strapped to GND.** The host cannot vary
  them, so if an instruction's `COND` field tests `RQ`, it can only ever see `0,0,0`.
* **`GF1`/`GF2`/`GF3` (83/84/85) are short stubs with no net label, no strap and no destination
  — not connected.** The host cannot read them.

⇒ The `rqgf` probe axis is **dead on this machine**, in exactly the way the probe review
pre-registered as outcomes (b) and (c). The honest report is *"not available on the SX-WSA1R"*,
**never** *"the chip has no COND field"* — the pins exist on the die and the CDJ-500 may well wire
them. ⚠ Read from the schematic, not from a continuity check on the physical board.

**★ IC30 has no delay DRAM at all.** All sixteen `I/O` pins (65-80) are tied to one bus that
terminates in a ground symbol, and `A5`-`A16` are unconnected stubs. That is the schematic's
version of what the runtime measurements already said from the other side: IC30 is the **program**
DSP, and it is IC5 and IC6 that carry the `LC321664AJ80` 1 Mbit DRAMs (drawn on sheet
II-17/II-18) as delay memory.

**Mode straps on IC30**: `MD1` (32) to GND; `MD2`, `MD3`, `MD4` (33/34/35) to +5D. `EOSC` (37) is
driven by an off-sheet net. What the `MD` field selects is **OPEN** — no source documents it.

**`SETRDY` (100) and `/BR-RQ` (11)** are the two pins `ROADMAP-2026-07-29.md` §6.2 names as
disabling the chip's emulator mode on the KN5000 (`SETRDY` open, `BR-RQ` strapped high ⇒ "no PC
trace without board modification"). Their numbers are now confirmed from a second board.

---

## How IC30 is wired on the SX-WSA1R — and what it means for capture

Read from the same page, below IC30's bottom edge:

| IC30 pin | name | net | what it is |
|---|---|---|---|
| 17 | `BCLKI` | `BCK` | bit clock in, shared |
| 18 | `LRCKI` | `LRCK` | frame clock in, shared |
| 20 | `DI1` | `SDO1` | tone-generator serial output 1 → DSP input |
| 21 | `DI2` | `SDO2` | tone-generator serial output 2 → DSP input |
| 22 | `DI3` | `SDO3` | tone-generator serial output 3 → DSP input |
| 23 | `DO1` | **`SUBOUT1`** | DSP output 1 |
| 24 | `DO2` | **`SUBOUT2`** | DSP output 2, through R176 470 Ω |
| 25 | `DO3` | **`SUBOUT3`** | DSP output 3, through R188 470 Ω |

★★ **`SUBOUT2` and `SUBOUT3` are DSP outputs that go nowhere on a stock machine.** `SUBOUT1`
reaches the main board's own SUB OUT 1 jacks through IC54/IC59; `SUBOUT2` and `SUBOUT3` appear at
**CN14 pins 6 and 7 and nowhere else** — they exist solely for the SY-ES1 output expansion board,
and the 470 Ω series resistors are the termination you would put on a line heading for a
connector.

That matters for the µPD6383 decode more than anything else on this page. Every probe design so
far has had to reckon with the DSP's output being **summed with the dry signal** — the wet/dry
crossfade happens inside the microprogram, so the main lane is already mixed and no wiring can
separate it. `SUBOUT2`/`SUBOUT3` are different: they carry the **program DSP's own second and
third outputs**, with nothing else mixed into them, and a stock machine never listens to them.

⚠ What is **NOT** established: whether the shipped microprogram ever writes anything to `DO2` or
`DO3`. The hardware path exists and is idle; whether the firmware drives it is a separate
question, and the honest answer today is that nobody has looked.

⚠ `MAINOUT` — CN14 pin 8, the lane the SY-ES1 turns into S/PDIF — is **not** an IC30 output. The
main mix reaches the MAIN OUT DACs through one of the other two µPD6383s (IC5/IC6), per the block
diagram on sheet II-5/II-6. So CN14 offers the main mix *and* two isolated program-DSP lanes on
one shared clock group.

---

## Also on sheet II-17/II-18: connector CN14, the SY-ES1 audio bus

Read at 400 dpi from PDF page 24, because the digital-output question turns on it:

| pin | board side | main-board net | pin | board side | main-board net |
|---|---|---|---|---|---|
| 1 | `MCK` | `MCK` | 8 | `MOUT` | **`MAINOUT`** |
| 2 | `LRCK` | `LRCK` | 9 | `FS1` | `FS1` |
| 3 | `BCK` | `BCK` | 10 | `FS2` | `FS2` |
| 4 | `LEL` | `LEL` | 11 | `+5D` | `+5D` |
| 5 | `LER` | `LER` | 12-14 | `E` | ground |
| 6 | `SDO2` | **`SUBOUT2`** | | | |
| 7 | `SDO3` | **`SUBOUT3`** | | | |

`CN11` alongside carries only power: 1 `+5A`, 2 `-5A`, 3 `+VCF`, 4 `+VCM`, 5 `-VCF`, 6-8 `E`.

So CN14 is **three independent serial audio data lanes on one shared clock group** (`MCK`/`BCK`/
`LRCK`, plus the `LEL`/`LER` latch-enables that split a lane into L and R for the PCM1702U pairs).
`MAINOUT` is the lane the SY-ES1's `TC9271F` turns into S/PDIF.
