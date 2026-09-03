# The L7A1429 at `0x00104000`: what kind of engine it is, and what an HLE must compute

Lane `w19/lsi-topology`, 2026-09-03.  Third companion to
`notes/FINDINGS-prom_c-dev104-register-map.md` (**what** each register is built from) and
`notes/FINDINGS-l7a1429-write-sequencing.md` (**when** each one is written).  This one asks the
question neither of those asks: given the SHAPE of the arithmetic, **what is on the other end**,
and what would a device have to compute?

Every number below is re-derived from `original_ROMs/wsa1_prom_c.ic28` and
`original_ROMs/wsa1_prom_d.bin` by

```
python3 notes/dev104_topology_probe.py             # 12 sections, printed
python3 notes/dev104_topology_probe.py --selftest  # FAILURES: 0
```

which reads bytes and never a `.s` file.  Where a claim rests on something outside that probe —
the schematic, MAME's CPU core, another lane's note — the source is named at the claim.

---

## 0. THE TWO LIMITS, STATED FIRST AND LOUDLY

**0.1  "This chip is the acoustic-modelling section" is now PART settled and PART inference,
and the split moved since the wave-17 note was written.**

* **SETTLED, from the service manual, not from the firmware**
  (`notes/DRIVER-INSIGHT-wsa1-2026-09-02.md`, TARGET 3): the schematic's decoder puts
  `WFICS` = `0x104000` on **IC3, labelled `L7A1429 MODELING LSI`**, with `NAD <- SA1` — which
  *is* the `+0 = select, +2 = data` port pair the disassembly derived.  The chip identity and
  the address decode are documented, not inferred.  ⚠ The wave-17 header still calls the whole
  identification a DECLARED INFERENCE; that text predates the schematic pass and is
  **reported here, not edited** — it is another lane's file.
* **STILL INFERENCE**: what the part *does internally*.  A part number and a net name are not a
  block diagram.  Nothing below rests on the word "modelling".

**0.2  "No executable payload crosses this device" is a claim about the BUS, and this note does
not weaken it.**  The whole image holds nine `0x00104000` literals, none of them a read
(`prom_c_dev104_regmap_checks.py` section 3), and a live bus trace of the emulated machine saw
2,642 writes and zero reads.  ⚠ **A chip with fixed on-die microcode, exposing only
coefficients, produces exactly this traffic.**  Everything in this note is consistent with such
a chip, and nothing in it distinguishes "the coefficients ARE the algorithm" from "the
coefficients CONFIGURE a fixed algorithm".  What did change is that the coefficients are no
longer opaque: three of them now have a closed form (§3), which constrains the algorithm from
outside without opening it.

**0.3  ⚠ Felipe has no access to the hardware.**  Nothing below proposes measuring the
instrument.  Where an answer needs the instrument, it is listed in §8 as an open question, not
as a next step.

---

## 1. THE INTERFACE CONSTRAINT, WHICH DRIVES EVERYTHING ELSE

From the schematic, via `notes/DRIVER-INSIGHT-wsa1-2026-09-02.md` §TARGET 3:

* **IC3's output is not audio.**  Its product leaves on `RQWFI` and `IOWFI(0..12)` — nets
  `RQWFI`, `DWFI0..DWFI12` — into **IC4 pins 25-40**.  IC4 is `TC183C230002 TONE GENELATOR
  LSI` (the sheet's spelling), the device at `0x0010C000`.  So IC3 hands the tone generator a
  **13-bit word on request**.  A faithful `l7a1429_device` is not a sound device: it is a
  waveform *source* that IC4 plays.
* **IC3 has four private 16-bit DRAM ports** `M1`, `M2`, `S1`, `S2` (`A0..A9`, `NRAS/NCAS/NWE`,
  `D0..D15`) — the "SOUND RAM" of prom_a's `"=WSA SOUND RAM S0"` string.  The CPU never
  addresses that memory; there is no address, no length and no loop point anywhere in the
  nineteen registers.
* **IC4's crystal is 33.8688 MHz = 768 x 44100**, so the audio rate of the pair is **44.1 kHz**.

Two consequences an implementer must hold on to:

1. **The absence of a wave-address surface is a positive result, not a gap.**  A 19-register
   per-channel set with no address, no start, no end and no loop is not a sample player.  The
   sample player is the *other* chip, and its register `chan+0x0040` is the one that carries a
   key-zone record word (`FINDINGS-prom_c-dev10c-register-meanings.md` §4).
2. **The engine's memory is on-die-addressed.**  Whatever the four DRAM banks hold — delay
   lines, wave tables, filter state — the CPU never names an address in them.  So an HLE
   cannot dump or seed that memory from anything in the ROMs.

---

## 2. THE TOPOLOGY HYPOTHESIS

> **PRIMARY, graded STRONG.  The L7A1429's per-channel programming surface is a bank of
> THREE MATCHED SIGNAL-PROCESSING SECTIONS, each fed two filter coefficients and one
> envelope-scaled input gain, plus a log-domain time-or-length register, two log-frequency
> registers and two level registers.  It is programmed exclusively with FILTER COEFFICIENTS,
> LOG-FREQUENCIES and LEVELS.**

The argument is four measurements, each with a null.

### 2.1  `fold()` is a number FORMAT, and it decodes two tables — PROVEN

The packer's `fold(x) = (x & 0x8000) ? 0x8000 - (x & 0x7FFF) : x + 0x8000` (0xFC5306-0xFC5328,
0xFC4A51-0xFC4A73) is **sign-magnitude to offset binary**, and the proof is that under it both
`Curve_FE04C9` and `Curve_FE05C9` are **monotone over all 128 entries** — including across
`FE04C9[89] = 0x8459 -> [90] = 0x015E`, which the two's-complement reading sees as a jump from
-31655 to +350 and which under `fold` is a step of 1554, bracketed by its neighbours' 1387 and
1655.  **The null is the two's-complement reading itself: it is not monotone.**  (Probe §2.)

⚠ **REPORTED, NOT EDITED.**  `prom_c/data_tables/tail_data_zone.s` describes both tables in
two's complement — "128 s16, rising from -510 ... to +28591" and "falling from -25 to -8188".
Those are readings of the same bytes under the wrong sign convention.  That file is another
lane's.

### 2.2  `Curve_FE04C9` is a BILINEAR ONE-POLE COEFFICIENT — PROVEN as a closed form

Read as sign-magnitude Q15, every entry is

```
    a1 = (K - 1) / (K + 1)          with  K = tan(pi * f / fs)
```

and `f` **doubles every 12.0016 index steps, with a maximum residual of 0.8 cents over
i = 14..90**.  That is the standard bilinear-transform one-pole lowpass: `b0 = b1 = K/(1+K)`,
`a1 = (K-1)/(K+1)`, and `fold(word)/65536` is exactly `b0`.

**The null is four rival value-to-frequency maps** fitted the same way (probe §3):

| map | steps/octave | max residual |
|---|---:|---:|
| **bilinear, `f = atan((1+a)/(1-a))/pi`** | **12.0016** | **0.8 cents** |
| `b0` read as `f` directly | 13.3058 | 188.5 cents |
| one-pole alpha, `-ln(1-b0)/2pi` | 12.4414 | 41.6 cents |
| the word read as a POLE, `-ln|a|/2pi` | 10.9995 | 1333.2 cents |
| `K` read as `f` | 11.6180 | 317.0 cents |

The best rival is 50x worse.  A 0.8-cent fit over 77 entries is the table's own quantisation.

**The index is a MIDI note.**  Requiring `f(i) = 440 * 2^((i+36-69)/12)` gives an implied
sample rate of **44,091 +/- 11 Hz** — 44,100 to within **0.33 cent** — and no other standard
rate family (32 k, 48 k) is reachable, because they would need a non-integer note offset.
★ **IC4's 33.8688 MHz crystal is 768 x 44100.**  A curve table's closed form and a crystal on a
schematic agree to a third of a cent by wholly independent routes.

`Curve_FE05C9`, read the same way, is the same one-pole family with a cutoff that **saturates**:
`a1` runs -0.999237 to exactly **-3/4** (`-24580/32768`), i.e. a cutoff rising to a ceiling of
`0.045142 * fs` = **1,990.8 Hz**, the deficit halving every 12 steps.  ⚠ Its exact closed form
is NOT established; what is measured is the family and the ceiling.

| index i | note | `FE04C9` cutoff @44.1 k | `FE05C9` cutoff @44.1 k |
|---:|---:|---:|---:|
| 10 (clamp floor) | 46 | 116.6 Hz | 105.3 Hz |
| 34 (`Table_FDFF96` low bound) | 70 | 466.1 Hz | 1,478.5 Hz |
| 44 (section C low clamp) | 80 | 830.8 Hz | 1,700.4 Hz |
| 60 (`Table_FDFF96` other value) | 96 | 2,093.3 Hz | 1,875.8 Hz |
| 96 (section C high clamp) | 132 | 16,743.9 Hz | 1,985.0 Hz |
| 101+ (saturated) | — | 21,095.9 Hz (Nyquist) | 1,990.8 Hz |

### 2.3  THREE sections, by an EXHAUSTIVE census — PROVEN

`Curve_FE04C9`, `Curve_FE05C9` and `Curve_Exp2Rise_128` are each cited **exactly three times in
the whole 512 KB image** (probe §9; the census is over every byte, not a sighting):

| index | built by | `FE04C9` -> | `FE05C9` -> | the Rise multiply -> |
|---|---|---|---|---|
| `i3` (key-scaled) | `Dev104_PackStagingStruct` 0xFC52E3/0xFC52F0 | reg **0x0400** | reg **0x0340** | reg **0x01C0** (0xFC5361) |
| `i4` (key-scaled) | the same, 0xFC5459/0xFC5466 | reg **0x0440** | reg **0x0380** | reg **0x0200** (0xFC54D7) |
| `i5` (clamped 44..96) | `sub_FC47EE` 0xFC4989/0xFC4997 | `P[+0x26]` -> reg **0x0480** | `P[+0x24]` -> reg **0x03C0** | reg **0x0240** (0xFC4ACC) |

So registers `0x03C0` and `0x0480` — which the wave-17 map records only as "`P[+0x24]` copied
straight through" and "`P[+0x26]`" — are **the same two curve tables at a third index**,
computed earlier by a different routine and cached in the sub-record.  The grouping is
**A / B / C**, not A / B.

⚠ **THIS CORRECTS THE WAVE-17 STRUCTURAL CLAIM.**  That header says "sixteen of the nineteen
registers fall into eight A/B pairs" and then lists five pairs (ten registers).  The measured
grouping is **two A/B pairs and three A/B/C triples**:

```
   pair    0x0040  0x0080                       two log-frequency words
   pair    0x0140  0x0180                       two levels
   triple  0x01C0  0x0200  0x0240               three section input gains
   triple  0x0340  0x0380  0x03C0               three section coefficient #2
   triple  0x0400  0x0440  0x0480               three section coefficient #1
   alone   0x0000  0x00C0  0x0100  0x0280  0x02C0  0x0300
```

4 + 9 + 6 = 19.  ⚠ Reported, not edited: the wave-17 header is another lane's file.

**Two ROM images confirm it from paths that never run the packer** (probe §10, §11):

* `Dev104_LoadStageBImage`'s image at 0xFE1315 writes `Curve_FE05C9[64]` to registers
  `0x0340`, `0x0380` **and** `0x03C0` and `Curve_FE04C9[64]` to `0x0400`, `0x0440` **and**
  `0x0480`, and zero to the other thirteen.  Index 64 is MIDI note 100, 2,637 Hz.
* The power-on reset image at 0xFE133B uses index **74** for sections A and B and index **84**
  for section C — a different index for C, exactly as the packer's `i5` is independent of
  `i3`/`i4`.

### 2.4  The A/B/C grouping is a fact about the CODE, and it survives a null — PROVEN

For each claimed pair, the two code runs are compared byte for byte, the run length being the
distance between the two anchors (so if they are the same code twice they are the same length).
The null slides the second run over 122 nearby offsets (probe §5):

| pair | run length | aligned agreement | null mean | null max |
|---|---:|---:|---:|---:|
| reg 0x0040 / 0x0080 | 175 | **0.9771** | 0.0351 | 0.2000 |
| reg 0x0140 / 0x0180 | 189 | **0.9101** | 0.0274 | 0.0741 |
| reg 0x0340+0x0400+0x01C0 / 0x0380+0x0440+0x0200 | 374 | **0.9652** | 0.0264 | 0.0588 |

### 2.5  Whatever the grouping means, it is NOT "two elements per voice" — PROVEN

`Pack104_SetInputs_SubRecordPair(n, m)` selects one of the part record's four 42-byte
sub-records.  `MidiNote_OnTail` passes the **literal 0** (`0b 00 00` = `push 0x0000` at
0xFB36F2).  The three `MidiNote_OnByPartMode` sites push the **register HL** (`0x2b`), whose
low byte is a loop counter bounded by `cp L,4` (`cf dc`, 0xFB3A8A) and `cp L,2` (`cf da`,
0xFB3BA3) — and each iteration re-reads a **different channel byte** from a local array
(0xFB3A28).  So a four-element tone occupies **four channels**, each with its own full
19-register set.  Element multiplicity is already spent on channels; the A/B/C grouping is
*inside one channel*.  (Probe §6.)

### 2.6  The one loose end that supports the reading from the hardware side

IC3's four DRAM ports are named **`M1`, `M2`, `S1`, `S2`** — two pairs, with a `M`/`S` naming
split.  The firmware computes every section parameter three times.  ⚠ Two memory pairs against
three parameter sets do not obviously line up, and no evidence here connects them.  **Recorded
as an unresolved tension, not as corroboration.**

---

## 3. WHAT IT IS NOT, AND THE ALTERNATIVES

### 3.1  The physical-modelling reading — graded WEAK, and I decline to promote it

The expected answer was a waveguide: excitation with a nonlinearity, delay line whose length
sets pitch, loss filter, envelopes.  Three of those four are visible:

* **a delay length or a decay time** — register `0x00C0` is `Curve_Log2_251[...]` plus
  `(0x4280 - pitch)` minus a zone offset.  `Curve_Log2_251` runs at **3072 counts per octave =
  256 per semitone**, which is the tone generator's own pitch unit, and `0x4280` is note 66.5
  in that unit.  The pitch term enters **negated**, so the value is *inverse in frequency*: a
  log period, or a log time.  Either is physical — a waveguide's delay length is `fs/f`, and a
  string's decay time also scales as `1/f` for a fixed loss per cycle.
* **loss filters** — the three sections' one-poles, with section A's cutoff tracking the key
  over the full range and the `FE05C9` pole pinned to an absolute 1,991 Hz ceiling.  An
  absolute brightness ceiling is what a waveguide loss filter looks like; a subtractive VCF's
  cutoff tracks the key instead.
* **randomised excitation** — `R[+0x21]`, the randomised depth (`P[+0x28] * sine / 50`),
  enters the index of *both* register `0x00C0` and register `0x0240`, and those are exactly the
  two registers refreshed at 40.69 Hz.

**And here is why it stays WEAK.  There is no nonlinearity anywhere in the nineteen
registers.**  No reed table, no lip table, no scattering-junction coefficient in the `(r, 1-r)`
form a junction needs, no saturation shape, no drive curve.  `fold()` is a number format, not a
waveshaper.  Every programmed quantity is a coefficient, a log-frequency or a level.

★ **So the honest primary reading is the more conservative one, and it is the more interesting
one: as programmed from this CPU, the L7A1429 is not an excitation-plus-nonlinearity model.  It
is a coefficient-fed filter/resonator bank.**  If a nonlinearity exists it is **fixed on die**
and this CPU never parameterises it — which is precisely the standing §0.2 caveat, now with a
concrete shape.

### 3.2  Cascade or parallel? — NOT DECIDED

Nothing here distinguishes three sections in series from three in parallel, and nothing says
whether the two coefficients per section are two cascaded one-poles or the two coefficients of
one biquad-like stage.  The only hint is that the two poles cross over at about index 62 —
below it `FE05C9`'s cutoff is the higher, above it `FE04C9`'s is — and a crossing pair is what
you get from a fixed corner against a tracking one.  **WEAK; do not build on it.**

### 3.3  A crossfade? — WEAK

One control value `v1` sets **both** register `0x0140` (a level, via
`Curve_Exp2Decay_256[0xCF - g(v1) + trim]`, falling) **and** the scale factor on register
`0x01C0` (via `Curve_Exp2Rise_128[v1]`, rising).  Measured over `v1 = 0..127` the two are
monotone in opposite directions (probe §8).  Calling that a dry/wet crossfade, or a drive
control that trades linear gain for filtered content, is an **inference**.  What is measured is
"one parameter, two gains, moving apart".

---

## 4. THE `srl 0x00,XIY` ADJUDICATION — SETTLED, and not by plausibility

The question: three registers (`0x01C0`, `0x0200`, `0x0240`) are the result of
`call Multiply32 / srl 0x00,XIY / ld (struct+d),IY`.  If the TLCS-900 rule that a shift count of
0 means 16 holds, the register is the product's **HIGH** half; otherwise its **LOW** half.

### 4.1  The settling argument: the ROM already contains the answer

`Dev104_StagingStruct_ResetImage` at **0xFE133B** is a 19-word constant the power-on sweep
copies into the staging struct — the same nineteen words the packer otherwise computes.  Its
words 7, 8 and 9 are the three `srl` products.  Solving each for the `Curve_Exp2Rise_128` index
that reproduces it, under both readings (probe §11):

| word | register | value | HIGH half | LOW half |
|---|---|---|---|---|
| 7 | 0x01C0 | 0x1C54 | `Rise[45]`, from `FE04C9[74]` | **no solution, from any of 128** |
| 8 | 0x0200 | 0x1C54 | `Rise[45]`, from `FE04C9[74]` | **no solution** |
| 9 | 0x0240 | 0x26D7 | `Rise[32]`, from `FE04C9[84]`, then `&0xFFF8 \| 7` | **no solution** |

And the `FE04C9` indices are **the image's own**: words 16/17 are `FE04C9[74]` (registers
0x0400/0x0440) and word 18 is `FE04C9[84]` (register 0x0480).  The image is internally
consistent with "register 0x01C0 is register 0x0400's word, folded and scaled", which is the
whole claim.

**The null.**  For a wrong model a hit is a 16-bit coincidence: 128 candidate indices out of
65,536 values, p = 1/512 per word.  Three of three under HIGH is p ~ 7e-9.  Zero of three under
LOW is what a wrong model predicts.

### 4.2  Four further arguments, all agreeing, none dissenting

* **A second implementation of the ISA.**  MAME's TLCS-900 core,
  `src/devices/cpu/tlcs900/900tbl.hxx`, `srl32()` opens
  `uint8_t count = ( s & 0x0f ) ? ( s & 0x0f ) : 16;`.  So `srl 0x00,XIY` shifts by sixteen —
  **and so does `srl 0x10,XIY`**, which is what llvm-mc emits for `srl xiy,16`.  The two
  encodings the wave-17 note calls "not a witness" are the *same instruction* to a core that
  implements the rule; llvm-mc simply passes the immediate through and does not implement it.
  ⚠ This is a second reading of Toshiba's manual, not hardware.
* **Range.**  Over the full 128 x 128 table cross-product, every pair except the 128 with
  `Rise[0] = 0` produces a product wider than 16 bits (max `0x775A0A66`).  The low half
  discards the value entirely.
* **Commensurability.**  The eight bytes `d9 cc f8 ff d9 ce 07 00` — `and BC,0xFFF8 / or
  BC,0x0007` — appear at **0xFC50E5**, applied to a **raw `Curve_Exp2Decay_256` entry**, and
  again at **0xFC4AD9**, applied to **the product**.  The same normalisation on two quantities
  means they share a numeric range.  A raw Decay entry is 0..0x8000; the high half is 0..0x775A;
  the low half is uniform over 0..0xFFFF.
* **Smoothness.**  Sweeping the depth index 0..127 for each of the 92 unsaturated `FE04C9`
  entries — the exact control a player moves — the HIGH reading rises at **every one of 11,684
  adjacent steps**; the LOW reading is indistinguishable from a uniform-random null in both
  monotone fraction (0.518 vs 0.500) and total variation (2,825,118 vs 2,765,831 — within 3%), while the
  HIGH reading's total variation is 6,848, **404x smaller** than the null's.

* And a fifth, weaker one: a shift by zero is a no-op the compiler would not emit — `ld IY`
  after the call already delivers the low half.

### 4.3  Grade

**PROVEN, on one stated premise**: that the ROM image at 0xFE133B and the packer write the same
kind of value into the same staging word.  Given that premise the instruction must compute the
high half, and the only way `srl 0x00,XIY` does so is if 0 means 16.  ⚠ No hardware trace and
no emulator trace of any of the three registers was taken; the residual risk is that premise.

---

## 5. THE REGISTER TABLE

`chan` is 0..0x3F; the register number is `block + chan`; all nineteen are **16 bits**.
Width column is the bits the firmware actually varies.

| reg | width | value the firmware writes | proposed ROLE | grade | what an HLE should DO |
|---|---|---|---|---|---|
| **0x0000** | 16 | `(R[+0x07] << 8) \| P[+0x07]`, bit 7 CLEARED when its own bits 6..4 are non-zero; bits 13..8 carry the CHANNEL on the power-on path; bit 2 SET by every note event (on *and* off) | a per-channel MODE / ROUTING word.  Its bits 6..4 gate register 0x0300 | **UNIDENTIFIED** | store it; decode bits 6..4 only as the 0x0300 gate.  ⚠ bit 2 is **not** a key gate — the note-OFF tail sets it too (`FINDINGS-l7a1429-write-sequencing.md` §4) |
| **0x0040** | 15 | `SatAsym(P[+0x0A] + P[+0x12] + d1)`; `d1` = a PITCH DIFFERENCE in 1/256-semitone units, saturating to `[0x0000, 0x7FFF]` | a LOG-FREQUENCY, key-tracked, in the tone generator's own pitch unit and range | **STRONG** for the unit and the key tracking; **UNIDENTIFIED** for what frequency | keep as a log-frequency: `f = 2^((v/256 - 69)/12) * 440`, the same law as the pitch register.  Do not model an effect yet |
| **0x0080** | 15 | the same, from `P[+0x0C] + P[+0x14]` and `d2` | the second of the pair | **STRONG / UNIDENTIFIED** | as above |
| **0x00C0** | 15 | `Curve_Log2_251[clamp(R[+0x12]+R[+0x16]+R[+0x21], 0..250)] + (0x4280 - R[+0x0E]) - R[+0x0C]`, forced to 0x0000 / 0x7F00 on underflow | a LOG PERIOD or LOG TIME: 3072 counts/octave, **inverse in pitch**, pivoted on note 66.5 | **STRONG** for "log domain, inverse in frequency, same unit as pitch"; **WEAK** for delay length vs decay time | store, and expose it as `2^(-v/3072)` times a unit you do not yet know.  **PERIODIC**: rewritten at 40.69 Hz per sounding voice |
| **0x0100** | 16 | `Const_0100_251[the SAME index as 0x00C0]`, which is 0x0100 in all 251 entries; 0x0000 on the Stage_B path | 0x00C0's TABLE-PAIR COMPANION — the second coefficient of the same stage, flat in this firmware | **STRONG** (§6) | store it.  Expect the write at 40.69 Hz and **do not** treat it as a latch or commit |
| **0x0140** | 13 | `Curve_Exp2Decay_256[clampU8(0xCF - g(v1) + (int8)(0x00E08C))] & 0xFFF8`, or 0x0000 when bit 0 of `(0x00E089)` is set; `g(v) = v<48 ? v/2+24 : v` | a LINEAR GAIN in Q15, 0.376 dB a step, 96 dB range | **STRONG** | apply as a gain: `v / 32768`.  ⚠ bits 2..0 are masked to 000 here and to 111 on the gated arm — treat them as a separate 3-bit field, not as gain LSBs |
| **0x0180** | 13 | the same, with `v2` | the second of the pair | **STRONG** | as above |
| **0x01C0** | 16 | `high16( fold(reg 0x0400's word) * Curve_Exp2Rise_128[clamp(v1, 0..PART[+0x11])] )` | **section A's input gain**: `b0` of the bilinear one-pole, offset-binary, scaled by `1 - 2^(-v1/16)` | **STRONG** | `b0_effective = v / 65536`; pair it with 0x0400's `a1` |
| **0x0200** | 16 | the same, with `v2` and reg 0x0440's word | **section B's input gain** | **STRONG** | as above |
| **0x0240** | 16 | `( high16( fold(reg 0x0480's word) * Curve_Exp2Rise_128[clamp(R[+0x14]+R[+0x18]+\|R[+0x21]\|/4, 0..0x7F)] ) & 0xFFF8 ) \| 7` | **section C's input gain**, with a RANDOMISED depth in its index | **STRONG** | as above.  **PERIODIC** at 40.69 Hz; the randomised term is the modulation |
| **0x0280** | 16 | `Curve_Exp2Decay_101[clamp(R[+0x10]+R[+0x23], 0..100)]`, the top 100 steps of the same exponential as 0x0140 | a third LINEAR GAIN, same law, restricted range | **STRONG** for "a gain of the same family"; **UNIDENTIFIED** for what it gates | apply as `v / 32768` |
| **0x02C0** | — | the literal **0xFF00**, always, on every path | — | **UNIDENTIFIED** | write it; model nothing |
| **0x0300** | 16 | `b = ExpCurve_0_to_0x80[Q[+0x13]]`; value `= (b << 8) \| b`; 0x0000 when reg 0's bits 6..4 are clear | one BYTE mirrored into both halves, from a 0..0x80 exponential curve | **UNIDENTIFIED** | store the byte; note that the chip is being handed the same value twice, so it is likely a byte-wide register read from either half |
| **0x0340** | 16 | `Curve_FE05C9[i3]` | **section A, coefficient #2**: a one-pole `a1` whose cutoff saturates at 1,991 Hz | **STRONG** | `a1 = (fold(v) - 32768)/32768` |
| **0x0380** | 16 | `Curve_FE05C9[i4]` | **section B, coefficient #2** | **STRONG** | as above |
| **0x03C0** | 16 | `P[+0x24]`, which `sub_FC47EE` filled with `Curve_FE05C9[i5]`, `i5 = clamp(rec[+0x0F], 44..96)` | **section C, coefficient #2** | **STRONG** (§2.3) | as above.  ⚠ the wave-17 map calls this "copied straight through"; it is the same table at a third index |
| **0x0400** | 16 | `Curve_FE04C9[i3]` | **section A, coefficient #1**: bilinear one-pole `a1`, cutoff = MIDI note `i3 + 36` | **PROVEN** as the closed form; **STRONG** as the role | `a1 = (fold(v) - 32768)/32768`; `K = (1+a1)/(1-a1)`; `fc = fs * atan(K)/pi` |
| **0x0440** | 16 | `Curve_FE04C9[i4]` | **section B, coefficient #1** | **PROVEN / STRONG** | as above |
| **0x0480** | 16 | `P[+0x26]` = `Curve_FE04C9[i5]` | **section C, coefficient #1** | **PROVEN / STRONG** | as above |
| **0x0800** *(no channel)* | 16 | the literal **0x1100**, once, at power-on | — | **UNIDENTIFIED** | accept the write; model nothing |

### The index chains, for an implementer who wants the whole computation

```
  key   = voice[+0x0C] & 0x7F                     the 0..127 LinCoef index
  Q5(T,d) = (T[d < 0 ? 0x7F-key : key] * |d|) >> 5        32 = 1.0

  v1 = clamp( Q5(LinCoef_FE0116, Q[+0x17]) + P[+0x16], 0 .. PART[+0x11] )
  v2 = the same with Q[+0x22] and P[+0x18]
       -> level  reg 0x0140/0x0180 = Curve_Exp2Decay_256[ clampU8(0xCF - g(v) + (int8)E08C) ]
       -> gain   reg 0x01C0/0x0200 = high16( fold(coefficient) * Curve_Exp2Rise_128[v] )

  ks(Q,o) = bit7 of Q[+o] ? 0
          : ( Q[+o+3] * ( max(min(note, Q[+o+2]), Q[+o+1]) - Q[+o] ) ) >> 5,  note = pitch >> 8

  i3 = clamp( ks(Q,0x19) + Q5(LinCoef_FE0196, Q[+0x18]) + P[+0x1A],
              Table_FDFF96[(0x00E08C)] .. PART[+0x12] )
  i4 = the same with Q[+0x25], Q[+0x23], P[+0x1C]
  i5 = clamp( rec[+0x0F], 44 .. 96 )                       in sub_FC47EE, cached in P
       -> cutoff  = MIDI note (i + 36),  fc = 440 * 2^((i+36-69)/12) Hz at fs = 44100
```

---

## 6. THE `0x0100` TENSION, ADJUDICATED

The write-sequencing lane found that `{0x00C0, 0x0100, 0x0240}` are rewritten every 24.6 ms per
sounding voice, and that `0x0100`'s table is the constant 0x0100 in all 251 entries — "writing
an unchanging value forty times a second is not what a parameter register looks like".  Three
readings were offered.  Probe §12:

* **(c) another path writes other values — ANSWERED.**  The register takes exactly **two**
  values in the whole image: 0x0100 (packer and reset image) and **0x0000** (the Stage_B
  image, 0xFE1315 word 4) — and 0x0000 exactly where 0x00C0 is also 0x0000.  There is no path
  with a varying value.
* **(b) a LATCH / COMMIT — DISFAVOURED**, on four counts.  (i) Its producer is
  `lda XBC,0xFDFCD6 / add XBC,XIX` at 0xFC49ED — an **indexed read of a 251-entry table**,
  sharing the index register `XIX` with the `Curve_Log2_251` read one instruction earlier.  A
  commit register is not sourced from a table indexed by a synthesis parameter.  (ii) The other
  refresh arm, `Dev104_SetChanRegs_00C0_0100`, ships `{0x00C0, 0x0100}` **without** 0x0240 — so
  0x0100 travels with 0x00C0, not with "whatever was written before it".  (iii) In
  `Dev104_WriteAllChanRegs` it is the **fourth** of nineteen writes, not the last.  (iv) The
  write-sequencing lane's own §2 shows block 0 is not a commit either, so the device has no
  known commit convention at all.
* **(a) the chip needs the refresh — UNNECESSARY.**  The refresh is fully explained by the
  other two members of the trio: `0x00C0` and `0x0240` are exactly the two registers whose
  index carries `R[+0x21]`, the **randomised depth** (`P[+0x28] * sine / 50`).  They are the
  modulation destinations; `0x0100` rides along because its producer is the companion table
  read in the same routine.

> **VERDICT, graded STRONG: register 0x0100 is register 0x00C0's table-pair companion — the
> second coefficient of the same stage — held at a constant by this firmware's table.**  The
> shape `(two parallel tables, one index, two staging words)` is the same shape that
> `(Curve_FE04C9, Curve_FE05C9)` has, and for that pair the "two coefficients of one section"
> reading is now established from three independent ROM objects.
>
> ⚠ An HLE must still **expect the write at 40.69 Hz** and must not assume the value is
> invariant: the Stage_B path writes 0x0000.

---

## 7. WHAT A FIRST IMPLEMENTATION SHOULD DO

**7.1  Build the register file and the plumbing before any DSP.**

* 64 channels x 19 registers, plus the single global `0x0800`.  Channel count is PROVEN from
  this device's own loops (`FINDINGS-l7a1429-write-sequencing.md` §1).
* Port pair: `+0x00` = 16-bit register number (`block + chan`), `+0x02` = 16-bit data.  There is
  **no read port** located; return 0 and log a read, because a read would be new information.
* Come up in the power-on state: `0x0800 = 0x1100`, then all 64 channels loaded with the
  0xFE133B image, then block 0 rewritten with bit 2 cleared.  Both images and the sweep are in
  `FINDINGS-l7a1429-write-sequencing.md` §3.
* **No write-recovery delay.**  The five-`nop` bus padding every `0x0010C000` write carries
  occurs **zero** times in the eight `0x00104000` routines.
* **Do not build a "commit on block 0" model** — the write-sequencing lane measured block 0 as
  last in 1 routine, first in 2, alone in 1 and absent in the 4 that have live callers.  A
  single `(select, data)` pair is the only atomic unit.

**7.2  Decode the six section coefficients, because they are the part that is understood.**

```c
// PROVEN closed form (notes/dev104_topology_probe.py sections 2, 3, 11).
static double a1_from_word(uint16_t w) {           // sign-magnitude Q15 -> [-1, +1)
    int mag = (w & 0x8000) ? -(int)(w & 0x7FFF) : (int)w;
    return mag / 32768.0;
}
static double cutoff_hz(uint16_t w, double fs) {   // bilinear one-pole
    double a1 = a1_from_word(w);
    if (a1 >= 1.0) return fs / 2.0;
    double K = (1.0 + a1) / (1.0 - a1);            // K = tan(pi * fc / fs)
    return fs * atan(K) / M_PI;
}
// registers 0x01C0/0x0200/0x0240 are the matching b0, already scaled:
//     b0_effective = value / 65536.0
```

⚠ **Label this "the coefficient decode", not "the filter".**  What is proven is that the
*numbers* are bilinear one-pole coefficients.  That the chip runs a one-pole with them is
STRONG, not proven.

**7.3  Where you must fake, fake with the real mechanism.**

If a first device is to make a sound at all, route it through the decoded datapath and label
every stand-in:

* Three sections per channel, each a one-pole `y += b0_eff * (x - y)` (or the full bilinear
  form) with `a1` from `0x0400/0x0440/0x0480`, an unmodelled second coefficient from
  `0x0340/0x0380/0x03C0`, and `b0_eff` from `0x01C0/0x0200/0x0240`.
* Gains from `0x0140`, `0x0180`, `0x0280` as `v / 32768`.
* Every stand-in behind one switch, so it is drop-in replaceable when a coefficient's role is
  settled.
* **Do not** invent an excitation.  There is none in the register set, and inventing one would
  make the model unfalsifiable against future evidence.
* **Do not** model registers `0x0000`, `0x02C0`, `0x0300`, `0x0800` at all.  Store, expose in
  the debugger, and leave them inert.

**7.4  The hard constraint that shapes the whole device.**

There is **no key-off register**.  A note-off is the same full 19-register re-program with
release values, and after the voice leaves the active list the device sees **no further traffic
at all** (`FINDINGS-l7a1429-write-sequencing.md`).  So the entire decay happens inside the chip
with no input.  A device that treats the registers as instantaneous parameters will cut every
note off.  **The model must sustain and decay a voice autonomously**, which means the register
values are the *initial conditions and time constants* of an internal process, not a per-sample
control stream.  Registers `0x00C0` and `0x0240` are the only ones a sounding voice ever
receives again, at 40.69 Hz.

**7.5  Model IC3 before you model its output, but do not call it a sound device.**

IC3 feeds IC4 on `RQWFI` / `DWFI0..12`.  Until IC4 (`0x0010C000`, `TC183C230002`) is modelled
and the six 16-Mbit wave mask ROMs are dumped, an `l7a1429_device` that emits audio is emitting
it into nothing.  The right first device is a **register file with a decoded, inspectable
parameter view** — which is exactly what §7.1 and §7.2 give.

---

## 8. WHAT AN IMPLEMENTER STILL WOULD NOT KNOW

Stated plainly, because a confident guess here would send someone down a wrong road.

1. **What any register DOES.**  Six of the nineteen now have a decoded numeric *meaning* —
   they are one-pole coefficients and gains — and none has a decoded *function*.  Which signal
   they filter, in what order, and what the result is, is unknown.
2. **The signal path.**  Series or parallel; what the input to a section is; whether the three
   sections are three voices, three partials, three filter stages, or a driver / resonator /
   radiation chain.  §3.2.
3. **Whether there is a nonlinearity.**  Nothing in the register set parameterises one.  If the
   chip is a physical model, its nonlinearity is fixed on die and invisible from the bus.
4. **What register `0x0000`'s fields are.**  Bits 6..4 gate `0x0300`; bit 7 is cleared when they
   are non-zero; bit 2 is set by every note event including note-off; bits 13..8 hold the
   channel on the power-on path.  No field has a name.
5. **`0x02C0` = 0xFF00, `0x0300`'s mirrored byte, and the global `0x0800` = 0x1100.**  Three
   constants with no reader and no variation.
6. **What the four DRAM banks hold**, and how their `M`/`S` naming relates to the three
   parameter sections (§2.6).
7. **The exact closed form of `Curve_FE05C9`.**  Its family and its 1,990.8 Hz ceiling are
   measured; the law that generates it is not.
8. **What the second coefficient per section is FOR** — a second cascaded pole, a zero, a
   feedback term.  The `(Curve_FE04C9, Curve_FE05C9)` and `(Curve_Log2_251, Const_0100_251)`
   pairs have the same *shape*; that is all.
9. **Where the `Tone104` record physically lives.**  ⚠ **A recorded negative result** (probe
   §7), so it is not repeated: it cannot be located inside prom_d's 531 81-byte element blocks
   by its key-scaling note-bound fields.  Eight candidate base offsets score 0.90-0.93 against
   a pooled null of 0.551; nothing wins.  Do not treat an element block as a `Tone104`.
10. **What selects the Stage_B path**, on which the nineteen registers are a ROM image rather
    than a computation.

★ **What would settle most of this is a sweep on the real instrument** — hold a note and a
tone, vary one block at a time, capture the audio.  ⚠ That is recorded as the shape of the
missing evidence, **not proposed as a next step**: the instrument is in storage abroad.  The
routes that do not need it are the tone-editor UI, which must display these parameters under
names, and the ROM's localisation strings; both remain open.
