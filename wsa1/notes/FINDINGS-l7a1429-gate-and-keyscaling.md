# The gate on L7A1429 register `0x0300`, and the four key ramps in real units

Wave 21, 2026-09-03, lane `w21/lsi-gate`.  Sixth companion in the L7A1429 set, and the one
that closes the last **UNIDENTIFIED** producer in the register table:

| note | answers |
|---|---|
| `FINDINGS-prom_c-dev104-register-map.md` (w17) | what each of the nineteen registers is built from |
| `FINDINGS-l7a1429-write-sequencing.md` (w19) | when each is written |
| `FINDINGS-l7a1429-curve-tables.md` (w19) | what quantity each ROM curve produces |
| `FINDINGS-l7a1429-parameter-names.md` (w19) | what the machine calls each register |
| `HLE-GUIDE-l7a1429.md` (w19) | what kind of engine it adds up to |
| `FINDINGS-l7a1429-packer-routines.md` (w20) | which routine computes each value |
| **this note** | **what switches register `0x0300` on**, and what the four `LinCoef_*` key ramps mean to somebody writing the device |

Everything asserted here is re-derived from
`original_ROMs/wsa1_prom_{a.ic12,b.ic13,c.ic28,d.bin}` by

```
python3 notes/w21_lsi_gate_and_keyscaling.py            # 11 sections, printed
python3 notes/w21_lsi_gate_and_keyscaling.py --selftest # FAILURES: 0
python3 notes/w21_lsi_gate_and_keyscaling.py --tables   # the four ramps, all 512 entries
```

which reads bytes.  It opens the `.s` listings for exactly one thing -- the set of
instruction START ADDRESSES, so that its census can say whether a byte-level hit lies in
code or in a region this tree frames as data -- and for nothing else.

⚠ **Felipe has no access to the hardware** (it is in storage abroad).  Nothing below
proposes measuring the instrument, and §5 says where that costs us an answer.

---

## 0. THE ANSWER, IN ONE PARAGRAPH

Register `chan+0x0000`'s bits 6..4 come from **`P[+0x07]` of the 42-byte sub-record**, not
from the 37-byte voice record that wave 19 named and wave 20 retracted.  Fifteen sites in
seven routines write that field, all with one idiom (`and (Xrr+0x07),0xFF8F`, optionally
followed by a single `set` of bit 4 or bit 5), and every one of them is downstream of the
same test: **`Q[+0x0B] & 0xC0`, the tone editor's `RESO MODE`**.  The field is therefore not
a parameter at all -- it is a **two-bit enumeration of the part's resonator mode**, 0 = none,
1 = some element is in a mode, 2 = all four are in mode 2.  Bit 6 is never set by any path.
So **register `0x0300` is a gain that exists only while the part is in a non-default
`RESO MODE`**, and in the factory set that is **eight tones, every one of them a pad**.

---

## 1. TASK 1 -- THE PRODUCER, FOUND

### 1.1 The gate itself, and what it gates -- PROVEN

`Dev104_PackStagingStruct`, 0xFC51B5-0xFC51F4 (probe §1; every byte asserted):

```
   FC51B5  ld   WA,(XBC)            WA = staging word 0  = register chan+0x0000
   FC51B7  and  WA,0x0070           <- THE GATE
   FC51BC  jr   Z,0xFC51EC
   FC51C1  ld   C,(XWA+0x13)        Q[+0x13] = p19, a 0..127 control
   FC51C8  add  XBC,0x00FDF760      Curve_Exp2Gain_U8_128
   FC51DB  or   DE,HL               DE = (b << 8) | b
   FC51E0  ld   (XBC+0x18),DE       staging word 12 = register chan+0x0300
   FC51E6  and  (XBC),0xFF7F        ... and bit 7 of word 0 is CLEARED
   FC51EF  ld   (XBC+0x18),0x0000   the Z arm: register 0x0300 <- 0
```

★ Note the last two lines together: **bit 7 and bits 6..4 of register `0x0000` are mutually
exclusive in the word the device actually receives.**  Bit 7 is set by `p33 < 0` (a negative
`SUB GAIN`, 0xFC48EE) and cleared here whenever the gate opens.  Two fields that can never be
set at once in the shipped word are a hint that the chip reads one hardware field two ways;
that is an observation, graded **WEAK**, not a decode.

### 1.2 Which record and which offset -- PROVEN

Staging word 0 is built at 0xFC4DC4-0xFC4DF1 as `(R[+0x07] << 8) | P[+0x07]`, with
`P = *(0x00E084)` (the 42-byte sub-record at `PART + 0x13 + 42*element`) and
`R = *(0x00E086)` (the 37-byte voice record).  `R[+0x07]` is read as **a byte** (`ld A,`) and
shifted left by eight, so it cannot reach bits 6..4.  `P[+0x07]` is read as **a word**
(`ld IY,`) and OR-ed in whole.

> ⚠ This confirms wave 20's correction (`FINDINGS-l7a1429-packer-routines.md` §4.1) at the
> instruction encoding, and it is the reason wave 19's answer was wrong: it named the writers
> of the *other half of the same word*.

### 1.3 The fifteen writers -- PROVEN

| site | routine | what it does to bits 6..4 |
|---|---|---|
| 0xFC4C33 + 0xFC4C3B | `Pack104_SetInputs_PartRecord` | clear, then **set bit 4**, element 0 |
| 0xFC4C59 + 0xFC4C61 | `Pack104_SetInputs_PartRecord` | clear, then **set bit 4**, element 1 |
| 0xFC4C6F, 0xFC4C7A | `Pack104_SetInputs_PartRecord` | clear only, elements 0 and 1 |
| 0xFC6CBD | `sub_FC6CA8` | clear, elements 0..3 |
| 0xFC6CFF | `sub_FC6CEA` | clear, elements 0..1 |
| 0xFC6D41 | `sub_FC6D2C` | clear, elements 2..3 |
| 0xFC6E4E + 0xFC6E5B | `sub_FC6D6E` | clear, then **set bit 5** |
| 0xFC707A + 0xFC7087 | `sub_FC6FFD` | clear, then **set bit 4** |
| 0xFC72BC + 0xFC72C9 | `sub_FC723F` | clear, then **set bit 4** |

`0xFF8F` is `~0x0070`: the mask clears exactly bits 6..4 and preserves the rest of the word,
which is what makes this a *field* write and not a word write.

**So the field takes exactly three values -- `0x00`, `0x10`, `0x20` -- and bit 6 is never set
by any path in either image.**

### 1.4 The selector: `RESO MODE` -- PROVEN for the arithmetic, STRONG for the name

`Pack104_DispatchByResoMode_ForPart` (0xFC7481) folds the four elements' 2-bit `RESO MODE`
fields into one byte and dispatches (probe §5, every byte asserted):

```
   H = m3<<6 | m2<<4 | m1<<2 | m0 ,   m_i = (Q_i[+0x0B] & 0xC0) >> 6

   H == 0x00                -> sub_FC6CA8    all four elements CLEARED
   H == 0xAA                -> sub_FC6D6E    BIT 5
   else  H & 0x0F != 0      -> sub_FC6FFD    BIT 4 on elements 0,1   (else sub_FC6CEA, clear)
         H & 0xF0 != 0      -> sub_FC723F    BIT 4 on elements 2,3   (else sub_FC6D2C, clear)
```

and `Pack104_SetInputs_PartRecord` runs **the same test on the note path**, for the first two
elements only, through the wave-select pointers at `PART[+0x16]` and `PART[+0x40]` -- which
are `P0[+0x03]` and `P1[+0x03]`, i.e. `0x13+3` and `0x13+42+3`.

`Q[+0x0B]` bits 7:6 = `RESO MODE` is inherited at grade **STRONG** from
`FINDINGS-l7a1429-parameter-names.md` §2d (prom_a sends parameter `0x0B` with mask `0xC0` at
0xFD434D; bits 5:0 with mask `0x3F` are the **PROVEN** 64-name `RESONATOR TYPE` list).  This
lane re-derives the *reads*, not the name.

### 1.5 ★★ The corroboration: the openers are the curve's other readers -- PROVEN

`Curve_Exp2Gain_U8_128` at 0xFDF760 -- **the curve that makes register `0x0300`'s value** --
is cited **four times in the whole 512 KB image**:

| site | routine |
|---|---|
| 0xFC51C8 | `Dev104_PackStagingStruct`, **inside the gated arm** |
| 0xFC6E73 | `sub_FC6D6E`  -- the arm that sets bit 5 |
| 0xFC709F | `sub_FC6FFD`  -- an arm that sets bit 4 |
| 0xFC72E1 | `sub_FC723F`  -- an arm that sets bit 4 |

**The three routines that open the gate are exactly the three other readers of the gated
register's own curve**, all four with the same index `Q[+0x13]` through the same `P[+0x03]`
pointer, and the three routines that only *clear* the field read nothing.  A coincidence
would have to place the same table, the same record byte and the same `(b<<8)|b` duplication
in four routines that share no caller.

### 1.6 The census that makes the negative falsifiable

The claim "nothing else writes bits 6..4 of `P[+0x07]`" is only worth as much as the search.
Probe §3 and §3b, in full:

* **Framing-independent byte scan.**  Every offset of all four images whose byte 0 is a
  `(Xrr+d8)` memory-operand prefix (`0x88-0x8F` byte, `0x98-0x9F` word, `0xA8-0xAF` long,
  `0xB8-0xBF` no-size) and whose byte 1 is `0x07`.  626 hits; 342 at an instruction start,
  284 inside data.  **A writer hidden in a data-framed region would appear as a `data` row**
  -- nine do in prom_c and one in prom_d, and all ten are adjudicated (two are mid-instruction
  immediates, `push 0x07ba` at 0xF9C6DE and a `jrl` displacement at 0xFBF841; the other eight
  are monotone 16-bit tables in the 0xFDE000+ data zone).
* **Address-space elimination.**  prom_a and prom_d contain **zero** such writes; prom_b's 43
  are CPU 1's address space and cannot reach the part record at `0x005D23`
  (`prom_c/prom_c.ld`: the two CPUs are separate address spaces).  That leaves prom_c's 45.
* **Base adjudication, all 45.**  30 are provably a different object -- a stack local
  (`VoiceParams_Compute_A..D`, whose destination is `(XIZ+0x08)` and whose **every** call site
  pushes an `lda XBC,XIZ+d` local: 0xFB38B3, 0xFB39FE, 0xFB3AFD, 0xFB3691, 0xFB379E), a
  mathlib frame variable, the RAM array at `0x4CCF`, the **PART** record's own `+0x07` word,
  or the voice record `R[+0x07]`.  Four are `P[+0x07]` but write bits 15/14/7 only.  The
  remaining eleven are §1.3's.
* **Provenance, which closes the remaining forms at once.**  Any pointer that can reach a
  sub-record descends from the literal `0x5D23`.  Searching all four images for the byte pair
  `23 5d` at every offset, and keeping the hits whose preceding byte is an instruction start
  whose own spelling carries `0x5D23`, gives **sixteen instructions, all in
  `prom_c/field_accessors.s`** (0xFC4B49, 0xFC4BC4, 0xFC58AC, 0xFC59FD, 0xFC5BB0, 0xFC5F09,
  0xFC6183, 0xFC63FA, 0xFC6562, 0xFC65FA, 0xFC6816, 0xFC748F, 0xFC7A32, 0xFC7AC7, 0xFC7B77,
  0xFC7D1F), plus one seventeenth spelling a text grep finds and the byte filter does not --
  `ld (XBC+0x5d23),XWA` at 0xFC7D36, a 16-bit displacement on an unrelated base, reported
  here rather than left out.  **There is nowhere else for a sub-record pointer to come from.**

**The forms that were searched, written down so the negative can be attacked:**

| form | searched how | found |
|---|---|---|
| a literal displacement `+0x07` on any base | the byte scan above, all four images | the 45 |
| a base **spilled to a frame** and reloaded | same -- the scan matches the displacement, which no spill can hide | ★ **three of the fifteen writers are exactly this** (`ld BC,(XIZ-22)` before every access in `sub_FC6D6E`/`_FC6FFD`/`_FC723F`); a census keyed on `(0x00E084)` or on one base register would have missed all three |
| a **part-record-relative** displacement `+0x1A/+0x44/+0x6E/+0x98` | byte scan for those four d8 values in prom_c | 104 positions, none downstream of any of the sixteen provenance sites |
| an **absolute** store to a `P[+0x07]` address | the provenance search above | none |
| a base **already advanced past** the field | provenance: it would still start at one of the sixteen | none |
| a block move or clear over the part record | provenance, plus the only block-shaped writes in the image (`Pack104_DispatchByResoMode_ForPart`'s eight `ld (XBC+off),0x0000` at `PART[+0x01..+0x0F]`) | those are outside every sub-record, which begin at `PART+0x13` |

**POSITIVE CONTROL.**  The same census independently finds the three writers of the *other*
bits of the same word -- bit 15 at 0xFC488B, bit 14 at 0xFC48BD, bit 7 at 0xFC48EE -- which
wave 19 documented from a different direction.  A method that finds those is not blind to a
fourth writer of the same kind.

### 1.7 ★★ What the FACTORY asks for, with a null

Over prom_d's tone database (probe §6):

* **246 of 256** framed tones have `H == 0`, so the gate is **closed** and register `0x0300`
  is written as `0x0000`.
* **Eight** open it, and they are: `Fantasia`, `Dream`, `Mist`, `Halo Pad`, `Voxmosphere`,
  `Dark Universe`, `Goblins`, `Windy Sweep`.  Every one is a pad.
* **`Dark Universe` alone** hits `H == 0xAA`, the single code the dispatcher tests for by
  name at 0xFC74F1 -- the only factory user of the bit-5 arm.
* Two further tones, `<<< Drawbar 1>>>` and `<<< Drawbar 2>>>`, also carry a non-zero
  `+0x0B`; they are **excluded**, because their records fail the parameter-names lane's
  published `p20 == 100` invariant (85/64/0/0 and 92/0/0/219).  Their framing is wrong and
  nothing may be read out of them.

⚠ **THE FRAMING PROBLEM, AND WHY THE ANSWER SURVIVES IT.**  All eight are dropped by
`dev104_topology_probe.py`'s strict 133-record population -- which is why that probe reports
`RESO MODE` as identically zero.  The strict filter rejects them for a property of their
**81-byte element blocks** (a wave index >= 307), not of their **43-byte wave-select
records**, and the eight pass **two independent invariants of a lane that never looked at byte
`+0x0B`**: `p20 == 100` in every record, and the `p25` breakpoints all inside
`{42, 54, 66, 78, 90}`.

**THE NULL.**  Permuting the `Q[+0x0B] & 0xC0` column across all 459 records, keeping the
marginal counts and the tone sizes fixed, 20 000 trials:

| statistic | observed | P(>= observed) under the shuffle |
|---|---:|---:|
| multi-element tones all of whose elements share one non-zero mode | 7 | **0.00000** |
| tones landing exactly on `H == 0xAA` | 1 | **0.00005** |

(One-element tones are excluded from the first statistic, because they satisfy it trivially --
an earlier version of this null did not exclude them and returned p = 0.56, which is what a
statistic that cannot fail looks like.)

### 1.8 ★ A lead, recorded and NOT decoded

The three gate-opening arms also fill a per-element block at the global `0x00E093`, and its
contents are suggestive: for `sub_FC6D6E`, one element's block receives
`Curve_Exp2Gain_U8_128[p19]` in both halves (0xFC6E93, 0xFC6EA3), the constant `0x8000`
(0xFC6EAD), `Curve_Exp2Gain_Percent_101[clamp(|p33|, 0..100)]` (0xFC6F20 -- **the same table
and the same control that make register `0x0280`, `SUB GAIN`**), and both tuning words
`P[+0x0E]` and `P[+0x10]` (0xFC6F36, 0xFC6F4C).  Both gains plus both tunings, per element,
is the shape of a mix or coupling matrix over the four elements.

⚠ **`0x00E093` has no located reader.**  The eleven `lda XBC,0x00e093` sites are all writes
and no other spelling of that address exists in either image.  Wave 20 already named this the
cheapest remaining item in `field_accessors.s`; this lane agrees and adds the contents.
**Recorded as a lead, grade UNIDENTIFIED.**

### 1.9 ★ What register `0x0300`'s ROLE becomes

Before: *"an 8-bit gain over a 0..127 control, 42.1 dB, duplicated into both halves"*, name a
**WEAK** three-way guess among `DEPTH` / `FORMANT` / `INTERACTION GAIN`, gate producer
**UNIDENTIFIED**.

After:

> **PROVEN.**  Register `chan+0x0300` carries `Curve_Exp2Gain_U8_128[p19]` in both halves, and
> is written as `0x0000` unless at least one element of the part has a non-zero `RESO MODE`.
> The enable is a property of the **part's resonator mode**, not of the note, the voice or
> the element being packed.

That is a real narrowing, and it moves the name argument without settling it:

* A gain that only exists when the resonators are put into a non-default mode is what
  `INTERACTION GAIN` -- the HLE guide's *"caption looking for a register"* (§3, §8.2) -- would
  look like.  `DEPTH` and `FORMANT` have no reason to be mode-gated, and `FORMANT` already has
  a better candidate in the `i5 = clamp(p15, 44..96)` chain that feeds registers
  `0x03C0`/`0x0480` (`FINDINGS-l7a1429-parameter-names.md` §6).
* ★ And the MODELING top screen's `CONNEC`+`TION` caption, which wave 20 explicitly
  **refused** to use to name the six arms (`FINDINGS-l7a1429-packer-routines.md` §2.2 -- *"a
  plausible caption is not a decode"*), now has an independent mechanical fact next to it:
  those arms dispatch on a per-element 2-bit mode and their only register-visible output is an
  enable for one gain.

⚠ **The name stays WEAK.**  This lane changes the *argument* from "assign by screen order" to
"a mode-gated gain", which is a reason rather than a position; it is still not a measurement,
and the 3! choice is not closed.  What is now **PROVEN** is the enable condition, and an HLE
should implement that and leave the name open.

**What an HLE should do**, replacing the guide's §5 row for `0x0000` and its §7.3
*"do not model 0x0000"*:

```c
// register 0x0000, decoded  (bits 3, 1, 0 are not accounted for by any lane)
//   15    p21 bit 7                      (a per-element form flag, MAIN)
//   14    p31 bit 7                      (the same, SUB)
//   13:8  the allocated 0..63 SLOT       (= this device's channel; wave 20 section 1.5)
//   7     p33 < 0  -- and CLEARED whenever bits 6:4 are non-zero
//   6:4   RESO MODE enable: 0 = off, 1 = some element in a mode, 2 = all four in mode 2
//         (bit 6 is never set by any firmware path)
//   2     set by every note event, ON AND OFF -- not a key gate
// register 0x0300 = bits 6:4 ? (g << 8) | g : 0x0000,  g = Curve_Exp2Gain_U8_128[p19]
```

---

## 2. TASK 2 -- THE FOUR KEY-SCALING RAMPS, FOR AN IMPLEMENTER

### 2.1 The one reader, six call sites -- PROVEN

All four tables are read by the identical idiom, and the probe asserts the `lda` at every one
of the six sites plus the shift:

```
   A = (s8) Q[+d]                     the DEPTH byte
   k = (0x00E088)                     the key, 0..127  (= voice[+0x0C] & 0x7F)
   if A == 0:     r = 0
   if A <  0:     k = 0x7F - k ;  A = -A        <- the curve is MIRRORED, not negated
   r = ((s8) T[k] * A) >> 5           `sra`, an ARITHMETIC shift: it FLOORS
```

★ **The mirror is what makes three unipolar tables into bipolar controls.**  `T` for MUTING
and SUB GAIN never rises above zero, yet the signed slope of `r` against the key is
`A * (dT/dk) / 32` for **either** sign of `A`: a negative depth does not flip the sign of the
contribution, it flips **which end of the keyboard is the pivot**.  An implementation that
negates instead of mirroring gets the slope right and the offset wrong by up to `2|A|` steps.

⚠ And `>> 5` is `sra`, so it **floors** a negative product: the contribution is biased by up
to one index step downward.  It is not `round`.

### 2.2 The four, side by side

| | `LinCoef_Position_KeyRamp_Q5_128` | `LinCoef_Fitting_KeyRamp_Q5_128` | `LinCoef_Muting_KeyRamp_Q5_128` | `LinCoef_SubGain_KeyRamp_Q5_128` |
|---|---|---|---|---|
| address | `0xFE0096` | `0xFE0116` | `0xFE0196` | `0xFE0216` |
| closed form | `2k - 128` | `65k//128 - 32` | `k//2 - 64`, `T[127] = 0` | byte-identical to MUTING |
| exact on | 128/128 | 128/128 | 128/128 | 128/128 |
| Q5 range | `-4.000 .. +3.938` | `-1.000 .. +1.000` | `-2.000 .. 0.000` | `-2.000 .. 0.000` |
| law slope | **2** counts/key | **65/128** = 0.507812 | **1/2** | **1/2** |
| => index steps per key | `depth/16` | `depth/63.02` | `depth/64` | `depth/64` |
| pivot (where `r = 0`) | `k = 64` | `k = 64` | `k = 127` (`+`) / `k = 0` (`-`) | as MUTING |
| full-keyboard excursion | `7.9375 x |depth|` | `2 x |depth|` | `2 x |depth|` | `2 x |depth|` |
| depth byte | `Q[+0x10]` (p16) | `Q[+0x17]` / `Q[+0x22]` | `Q[+0x18]` / `Q[+0x23]` | `Q[+0x24]` (p36) |
| destination | `R[+0x12]` -> `Curve_Position_Log2Period_251` | `v1` / `v2` -> `Curve_Fitting_Exp2Decay_256` and `_Exp2Rise_128` | `i3` / `i4` -> `Curve_Muting_Cutoff_Q16_128` and `_Q13_128` | `R[+0x10]` -> `clamp(+ R[+0x23], 0..100)` -> `Curve_Exp2Gain_Percent_101` |
| **register** | **`chan+0x00C0`** (and `abs(r)>>2` in `R[+0x14]` -> part of **`chan+0x0240`**'s index) | **`chan+0x0140`, `0x01C0`** (MAIN) and **`0x0180`, `0x0200`** (SUB) | **`chan+0x0400`, `0x0340`** (MAIN) and **`0x0440`, `0x0380`** (SUB) | **`chan+0x0280`** |
| grade | fit PROVEN, unit STRONG | fit PROVEN, unit STRONG | fit PROVEN, unit STRONG | fit PROVEN, destination STRONG |

★ **The `Position` ramp's second destination is new here.**  `R[+0x14] = abs(R[+0x12]) >> 2`
(0xFC5643/0xFC564D), and `R[+0x14]` is the first term of register `chan+0x0240`'s
`Curve_Fitting_Exp2Rise_128` index.  So the `P0SITI0N` key ramp reaches **two** registers, and
the second one gets its **magnitude**, quarter-scale, sign discarded.

### 2.3 ★ What a depth byte MEANS, per table

**MUTING -- the exact one.**  The destination index is a **semitone of cutoff**
(`index = MIDI note - 36`), and the law slope is exactly 1/2 table count per key, so the ramp
contributes `depth/64` **semitones of cutoff per semitone of key**:

| depth | key follow | | depth | key follow |
|---:|---:|---|---:|---:|
| `+32` | **+50.0 %** | | `-32` | -50.0 % |
| `+64` | **+100.0 %** (exact) | | `-64` | -100.0 % |
| `+127` | **+198.4 %** | | `-127` | -198.4 % |

⚠ **AND THE SAME CHAIN USES A DIFFERENT SCALING ONE STAGE EARLIER.**  `i3`/`i4` also carry
`ks(Q, o) = (Q[+o+3] * (clamp(note, Q[+o+1], Q[+o+2]) - Q[+o])) >> 5`, whose slope is
`Q[+o+3] >> 5` semitones per semitone -- so **there 32 = 100 %, not 64**.  An implementation
that reuses one constant for both stages is wrong by a factor of two.

**SUB GAIN -- the second exact one, and it is new.**  The destination index is literally a
**percentage of `SUB GAIN`** (`clamp(..., 0..100)` into the 101-entry
`Curve_Exp2Gain_Percent_101`, one point = 0.37631 dB).  Same `depth/64` slope, so:

| depth | slope | full-keyboard swing |
|---:|---|---|
| `+32` | 0.50 point/key = 0.188 dB/key = **2.26 dB/octave** | 64 points |
| `+64` | **1.00 point of `SUB GAIN` per semitone of key** = 0.376 dB/key = **4.52 dB/octave** | 128 points |
| `+127` | 1.98 point/key = 0.747 dB/key = **8.96 dB/octave** | 254 points |

★ and because the excursion is `2|depth|` points into a 0..100 window, **`|depth| = 50`
sweeps exactly the whole control across the keyboard, and anything above that saturates.**

**FITTING.**  The destination index is one step of `Curve_Fitting_Exp2Decay_256` /
`_Exp2Rise_128` = `2^(1/16)` = **0.37631 dB**, and the slope is `depth/63.02` steps per key:

| depth | slope | full-keyboard swing |
|---:|---|---:|
| `+32` | 0.508 step/key = 0.191 dB/key = **2.29 dB/octave** | 24.1 dB |
| `+64` | 1.016 step/key = **0.382 dB/key** = 4.59 dB/octave | 48.2 dB |
| `+127` | 2.015 step/key = 0.758 dB/key = **9.10 dB/octave** | 95.6 dB |

⚠ There is **no pitch-versus-gain identity**, so a "100 %" here needs a stated convention.
The natural one -- *one octave of the exp2 parameter per octave of key*, i.e. 16 steps per 12
keys = 4/3 step per key -- is **depth 84**.  Recorded as a **CONVENTION, not a measurement**;
the useful number is the dB/octave column, which is convention-free.

**POSITION.**  The index enters `Curve_Position_Log2Period_251`, whose closed form is
`v = round(27543 - 3072*log2 i)` (re-verified here, max residual 1 count), and whose register
`chan+0x00C0` is a log period at 3072 counts per octave.  Composing the two:

> ★★ **`position = C / i`, EXACTLY, for `i >= 1`** -- the index is the **reciprocal** of the
> position, up to one unknown constant.  `T[0] = 27648` is the table's own exception where
> `log2 0` is undefined.

That makes the key-follow statement honest but different in kind from the other three:

* **100 % key follow is already hard-wired**, by the `- R[+0x0C]` term, which enters
  `chan+0x00C0` with slope exactly -1 (`HLE-GUIDE-l7a1429.md` §2.7).  This ramp is an
  **additional deviation**, so no depth byte "means 100 %" on its own.
* One index step at `i` moves the register by `dv/di = -4432.6/i` counts = `-17.315/i`
  semitones of position.  At the factory-standard operating index -- `p13 = 125` in **400 of
  459** records -- a depth `A` gives `A/16` index steps per key:

| depth | index steps/key | semitone of position per semitone of key | of the hard-wired follow |
|---:|---:|---:|---:|
| `+32` | 2.00 | 0.277 | **+27.7 %** |
| `+64` | 4.00 | 0.554 | **+55.4 %** |
| `+127` | 7.94 | 1.100 | **+110.0 %** |

  (100 % would need depth ~= 116 at `i = 125`; the number moves with `i`, which is the whole
  point of the reciprocal law.)

### 2.4 ⚠ One structural claim TRIED AND REFUTED

`65k//128 - 32` and `k//2 - 64` agree at `k = 0` and at `k = 126`, which makes it tempting --
and it was tempting -- to say the FITTING ramp **is** the MUTING ramp offset by 32.  **Entry
for entry it is not.**  `T_Fitting[k] - T_Muting[k]` takes the values `{32: 96, 33: 32}`: the
extra `k/128` in Fitting's law moves the stair's repeat by one key over the top half of the
keyboard.  Same ramp *to within one count*, **not** the same table.  Only MUTING and SUB GAIN
are byte-identical.

### 2.5 ★ What the factory actually asks for -- the control's real resolution

Over the strict 133-record population (probe §10), every depth byte but one is a **multiple
of ten**, and the exception is a single `-5`:

| depth byte | distinct values, strict 133 | zero in |
|---|---|---:|
| Position `+0x10` | `-50 -30 -20 -10 0 20 30 40` | 67/133 |
| Fitting `+0x17` / `+0x22` | `-50 -40 -30 -20 -10 0 10` | 43/133, 41/133 |
| Muting `+0x18` / `+0x23` | `-10 -5 0 10 20 30` | 114/133 |
| SubGain `+0x24` | `0` | 133/133 |

**So the editor's control moves in steps of ten**, and the practical resolution of the
key-follow controls is:

* MUTING: **15.6 % of key follow per click**, factory range `-50..+30` = **-78 % .. +47 %**;
* SUB GAIN: 0.156 point of `SUB GAIN` per semitone per click -- **and the factory never uses
  it at all**, which is what an unused touch depth looks like;
* FITTING: 0.060 dB per semitone per click.

⚠ On the looser 459-record population a handful of values are not multiples of ten (`-128`,
`-117`, `-112`, `85`, `108`, `113`, ...), 4-6 per column; they belong to the same mis-framed
records the `p20` invariant rejects.  Reported, not smoothed away.

---

## 3. GRADES, IN ONE PLACE

| claim | grade |
|---|---|
| register `0x0300` is zero unless register `0x0000` bits 6..4 are non-zero, and carries `Curve_Exp2Gain_U8_128[p19]` in both halves otherwise | **PROVEN** |
| bits 6..4 of register `0x0000` are bits 6..4 of `P[+0x07]`, the 42-byte sub-record | **PROVEN** |
| the fifteen sites in §1.3 are the writers of that field, and nothing else writes it | **PROVEN** on the census of §1.6, whose forms are enumerated so the negative can be attacked |
| the field's value set is `{0x00, 0x10, 0x20}` and bit 6 is never set | **PROVEN** |
| the selector is `Q[+0x0B] & 0xC0` on the part's elements | **PROVEN** for the reads |
| that field is called `RESO MODE` | **STRONG**, inherited whole from `FINDINGS-l7a1429-parameter-names.md` §2d |
| eight factory tones open the gate, and one (`Dark Universe`) uses the bit-5 arm | **STRONG** -- the records pass two independent framing invariants and the clustering beats a shuffle null at p < 0.001, but they fail the strict element-block filter |
| register `0x0300` is `INTERACTION GAIN` | still **WEAK** -- the argument improved, the measurement did not happen |
| `0x00E093` is a per-element mix/coupling matrix | **UNIDENTIFIED** -- no reader located |
| the four ramps' closed forms | **PROVEN**, exact on all 512 entries |
| MUTING depth 64 = 100 % cutoff key follow; SUB GAIN depth 64 = 1 point per semitone; SUB GAIN depth 50 sweeps the whole control | **PROVEN** arithmetic on a **STRONG** unit (the units come from the curve lane) |
| FITTING "depth 84 = 100 %" | a **CONVENTION**, not a grade |
| POSITION `position = C/i` exactly | **PROVEN** given the curve lane's fit and the register's 3072-counts-per-octave unit, both **STRONG** for unit |

---

## 4. ⚠ CORRECTIONS OWED TO FILES THIS LANE DOES NOT OWN

Reported, not edited.

1. **`HLE-GUIDE-l7a1429.md` §5 row `0x0000` and §8.5** say the producer of bits 6..4 is
   UNLOCATED.  It is located: §1.3 above.  §8.5 should also drop *"Their writers, 0xFC4D27 and
   0xFC7DE9, are undecoded"* -- those two are the slot allocator's store, which wave 20
   decoded (`FINDINGS-l7a1429-packer-routines.md` §1.5).
2. **`FINDINGS-l7a1429-parameter-names.md` §6** and its 2026-09-03 correction close with
   *"the producer of the bits that gate register `0x0300` is still UNLOCATED"*, and §7 item 2
   asks for it.  Both can be struck.
3. **`dev104_topology_probe.py` §13 and `HLE-GUIDE-l7a1429.md` §3.4** report `RESONATOR TYPE`
   as `ORIGINAL` in 133 of 133 clean melodic records.  That is true of that population and
   **not** of the tone database: the strict filter drops every tone that uses `RESO MODE`, so
   the statistic is measured on a set constructed to exclude the interesting case.  §1.7's
   eight tones pass two of that lane's own invariants.  The guide's conclusion -- *"implement
   the COEFFICIENTS, not the FAMILIES"* -- is untouched; what changes is that `RESO MODE`, the
   other field of the same byte, **is** used, by eight factory pads.
4. **`FINDINGS-l7a1429-curve-tables.md` §6** gives `LinCoef_FE0196`'s slope as "1/64 of a Q5
   unit per key" and `LinCoef_FE0116`'s as "1/63"; both are right as laws.  The *measured*
   end-to-end slopes are 64/127 for both, because Fitting's extra `k/128` shows up only in the
   last entry.  §2.4 above is the detail; no number there is wrong.

---

## 5. WHAT THE NEXT PASS SHOULD DO

1. **`0x00E093` and `0x00E095`.**  Still the cheapest item, and §1.8 now says what is in the
   array: both gains and both tuning words, per element.  Its reader must exist; the eleven
   `lda XBC,0x00e093` sites are writes, so look for a base built as `0x00E086 + 0x0D` or from
   another global -- that is exactly the "a constant written as `TABLE - 4k`" form this tree
   has been caught by three times.
2. **The three big arms' arithmetic.**  `sub_FC6D6E`, `sub_FC6FFD` and `sub_FC723F` are now
   known to (a) set the gate, (b) compute register `0x0300`'s own value, (c) fill the
   `0x00E093` block, and (d) call `sub_FC4269`'s trigonometry.  (d) is the only part still
   opaque.  A routine that takes sines and cosines of a mode parameter is worth reading.
3. **One hop on the CPU 1 side**, unchanged from wave 19 §7: correlate `sub_FD616A`'s 29 call
   sites with the screen id in `(0x207C)` through prom_a's `DispatchTable_FCF000`.  That is
   what would turn `INTERACTION GAIN` from WEAK to PROVEN, and it would also tell us what the
   `RESO MODE` values 1 and 2 are called on the screen.
4. **Bits 3, 1 and 0 of register `0x0000`** are still unaccounted for by any lane.
5. **Nothing here proposes measuring the instrument.**  It is in storage abroad.
