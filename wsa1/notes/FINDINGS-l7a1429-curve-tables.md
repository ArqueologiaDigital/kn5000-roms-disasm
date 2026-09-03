# The 0x00104000 curve tables: what the numbers are, and what quantity they produce

Lane `w19/lsi-curves`, 2026-09-03.  Third companion to
`notes/FINDINGS-prom_c-dev104-register-map.md`, which says **what each of the nineteen
per-channel registers is built from**, and to
`notes/FINDINGS-l7a1429-write-sequencing.md`, which says **when each one is written**.
This one says **what the numbers mean** — because every one of those nineteen expressions
runs through a named ROM table, and the numeric shape of a table names the physical quantity
it produces.

Everything below is re-derived from `original_ROMs/wsa1_prom_c.ic28` by

```
python3 notes/lsi_curve_tables.py --selftest   # 49 assertions, FAILURES: 0
python3 notes/lsi_curve_tables.py --fit        # every fit, with its residual AND a null
python3 notes/lsi_curve_tables.py --summary    # the (table, fit, endpoints, unit, grade) table
python3 notes/lsi_curve_tables.py --dump NAME  # the raw entries
```

That script reads the ROM image and no `.s` file.  It also re-reads, from the image, the
fifteen instructions the unit arguments lean on, so "the register's ceiling is `0x7F00`" and
"the pitch enters NEGATED" are bytes here rather than citations of another file.

⚠ **The one number that is not measured here** is the sample rate, 44,100 Hz.  It comes from
`notes/DRIVER-INSIGHT-wsa1-2026-09-02.md` (IC4's crystal X4 = 33.8688 MHz = 768 × 44100) and
`notes/FINDINGS-prom_c-tail-data-zone.md` §3 (the f64 constant pool holds `44100`, `1/44100`,
`1/220500`, `1/441000`).  It is used in exactly one place — §1 — and that section says so.

⚠ **That the device at `0x00104000` is the acoustic-modelling LSI is a declared inference**
held over from the driver work.  Nothing here rests on it; a fit is a fit whatever the chip is.

---

## 1. ★★ `Curve_FE04C9` and `Curve_FE05C9` are not two curves — they are ONE FILTER CUTOFF

This is the result that made the rest readable, and it is the one to check first.

### The encoding had to be undone before anything fit

Read as `s16`, `Curve_FE04C9` is not monotone: it falls from −510 to −31655 and then *jumps*
to +350 and rises to +28591.  Passed through the firmware's **own** `fold()` — the function
the packer applies at `0xFC5361` on the way to register `0x01C0` —

```
fold(x) = (x & 0x8000) ? 0x8000 - (x & 0x7FFF) : x + 0x8000
```

both tables become strictly monotone unsigned curves.  ★ **That is what identifies the
storage format**: `fold` was already in the register map as a step in one register's
arithmetic; it turns out to be the *inverse of the table's encoding*, and applying it is what
makes the numbers admit any fit at all.

```
F = fold(Curve_FE04C9) :   510 .. 61359, then saturated for k = 100..127
G = fold(Curve_FE05C9) :    25 ..  8188, then saturated for k = 100..127
```

### The fit

Over the live band `k = 9..100`:

```
g    = tan(pi * f_k / 44100)          f_k = 440 * 2^((k-33)/12)  Hz
F[k] = round(65536 * g / (1 + g))     max |residual| = 1 count
G[k] = round(8192  * (1 - 1/(128*g))) max |residual| = 5 counts
```

`g/(1+g)` with `g = tan(π f/fs)` is the **coefficient of a one-pole lowpass under the
bilinear transform** — `g` is the prewarped cutoff.  Nothing was fitted to obtain `f_k`: the
sample rate is the schematic's, and the note offset came out an integer.

### ⚠ The null, and it is the whole argument

Do not assume the slope; fit it.

| fit, over `k = 9..100` | R² | max residual |
|---|---|---|
| straight line in `F` | 0.7781 | 25678 counts |
| straight line in `log2 F` (a plain exponential) | 0.9982 | 0.155 in log2 |
| **straight line in `log2 atan(F/(65536−F))`** (the claimed law) | **0.99999998** | **0.00136 in log2 = 1.63 cents** |

The fitted slope is **1 / 12.0017** per index step — twelve steps per octave to 0.01%.  A
plain exponential is not the law: `F`'s own log slope drifts 12.1 → 15.7 → 11.2 steps per
doubling across the table, which is exactly what the `tan` prewarp does and what a pure
exponential cannot.

### The unit, recovered rather than assumed

Force the slope to exactly 1/12 and solve for the index-0 frequency from the ROM's entries:

```
f(k = 0) = 65.4201 Hz = MIDI note 36.0036
```

— **0.36 cents** from note 36 exactly, against a fit scatter of 1.63 cents.  So

> ★★ **The cutoff index is a SEMITONE, and `k = MIDI note − 36`.**

⚠ Landing within a cent of an equal-tempered note by luck is a ~2% coincidence.  What makes
this more than that is that `fs` was fixed *independently*, by a crystal on the schematic,
before this fit was attempted.

### ★ And the ceiling is Nyquist, which needs no external constant at all

```
theta(100) = 1.50285 rad  <  pi/2 = 1.57080  <  theta(101) = 1.59221
```

Both tables saturate at exactly `k = 100` and hold that value for the remaining 28 entries.
That is the **last index whose prewarp `tan()` is still finite and positive**.  A table of a
`tan()` that stops one step before its own pole is a bilinear filter coefficient; this
argument uses only the ROM's numbers and the 12-steps-per-octave slope, not the sample rate.

### ★ The two registers are NOT independent — an emulator has one parameter here, not two

Invert each table for the `θ` it implies — `atan(F/(65536−F))` against
`atan(1/(128·(1−G/8192)))` — and the two agree to **17.4 cents worst case** over the whole
live band, and to **3.4 cents** over `k = 9..60` where `G` still has resolution to spare.
`G` carries a *residue* `(1 − G/8192)` that falls to four counts at the top of the band, where
its own quantisation alone allows 386 cents; the disagreement stays under that bound.

Equivalently, entry for entry, `(1 − G/8192) · g = 1/128`.

> Given register `chan+0x0400`, register `chan+0x0340` is **computable**.  The pair carries
> no state the cutoff does not already carry.  Same for `chan+0x0440` / `chan+0x0380`.

### ★ Sanity against music

| index `k` | cutoff | MIDI |
|---:|---:|---:|
| 9 (the floor ends) | 110.0 Hz | 45 |
| 34 (`Table_FDFF96` min) | 466 Hz | 70 |
| 44 (a reader's lower clamp) | 831 Hz | 80 |
| 60 (`Table_FDFF96` max) | 2093 Hz | 96 |
| 96 (a reader's upper clamp) | 16744 Hz | 132 |
| 100 (the ceiling) | 21096 Hz | 136 |

The readers clamp the index to `44..96` (`0xFC4971`, `0xFC4976`) and to
`Table_FDFF96[zone] .. PART[+0x12]` (`0xFC52D2`), i.e. **831 Hz to 16.7 kHz**.  That is a
filter cutoff range on a musical voice.  It is *not* a pitch range — a pitch parameter would
not be clamped to start at 831 Hz.

---

## 2. `Curve_Log2_251` → register `chan+0x00C0`: a LOG-DOMAIN TIME, 1/256 semitone per count

```
T[0]   = 0x6C00 = 27648 = 108.000 semitones
T[k]   = round(27543 - 3072 * log2 k)     for k >= 1,   max |residual| = 1 count
```

**3072 counts per halving is 12 × 256**, so **one count is 1/256 semitone** — the unit
`MathTable_Log2_256` uses and the unit the tone generator's own pitch register
`0x0400 + chan` uses (`FINDINGS-prom_c-dev10c-register-meanings.md` §2).

Null: a straight line in `T` vs `k` gives R² = 0.781; in `T` vs `log2 k`, R² = 1.000000 with a
max residual of 0.56 counts.

The register the table feeds is (all four instructions re-read by the script):

```
0xFC4A18  ld IY,0x4280      ; note 66 plus the half-step centre 0x80
0xFC4A1B  sub IY,WA         ; 0x4280 MINUS the key-followed pitch
0xFC4A1D  add HL,IY
0xFC4A29  sub HL,WA         ; minus the key-zone word
0xFC4A37  ld HL,0x0000      ; underflow      -> the register's FLOOR
0xFC4A3C  ld HL,0x7f00      ; wrapped-negative -> the register's CEILING
```

So the register's range is **`[0x0000, 0x7F00]` = `[0, 127.000]`** in that same
1/256-semitone unit — the same 0..127 window the tone generator's pitch register uses — and
the pitch enters **negated**, pivoting on `0x4280` = note 66.5, the pivot the tone generator's
own key-follow stage uses.

> ★ **A log-domain quantity that falls by one octave when the note rises by one octave is a
> PERIOD or a TIME, not a frequency.**  Grade **STRONG**.  The slope against pitch is exactly
> −1, so whatever it is, it is proportional to the note's own period.
>
> ⚠ **The absolute scale is UNIDENTIFIED.**  Nothing in the image says which register value is
> which time.  What is fixed is the unit per count (1/256 semitone = a factor 2 per 3072
> counts), the direction, and the 10.58-octave span the clamps allow.

Musical sanity: 10.58 octaves is a range of 1625:1.  A delay line covering the 88-key range
(A0 27.5 Hz to C8 4186 Hz) needs 152:1, so the span is comfortable rather than absurd.

---

## 3. `Const_0100_251` → register `chan+0x0100`: constant on this firmware, **and refreshed**

`0x0100` in **all 251 entries**.  Read with the *same* clamped 0..250 index as
`Curve_Log2_251`, one instruction later (`lda XBC,0xFDFCD6` at `0xFC49ED`).

### ⚠ How the 251 bound is set — three independent ways, all agreeing

A constant run is exactly what a *misjudged length* looks like, so the extent is not taken
from a label:

1. **The run ends itself.**  Scanning outward from `0xFDFCD6` for words equal to `0x0100`
   stops at `0xFDFCD6..0xFDFECB` — 251 words, 502 bytes, no more and no fewer.  The word
   *before* is `3072` = `Curve_Log2_251[250]`; the word *after* is `0` =
   `Curve_Exp2Decay_101[0]`.  Neither is `0x0100`, so this is not a run bleeding into padding
   or into a neighbour.
2. **The reader's clamp.**  `cp HL,0x00fa` (else `0xFA`) at `0xFC49CC` and `cp HL,0` (else 0)
   at `0xFC49D7` give an index of 0..250 — 251 entries.
3. **The next cited base.**  `0xFDFCD6 + 502 = 0xFDFECC` = `Curve_Exp2Decay_101`, which prom_c
   cites in its own `add <X..>,#imm32` at `0xFC4B1B`.

### ⚠ And the register is refreshed, not latched once

`chan+0x0100` is one of the three registers rewritten every **24.576 ms (40.69 Hz)** per
sounding voice (`FINDINGS-l7a1429-write-sequencing.md` §5).  So the **traffic is periodic and
the value is constant**: an emulator must expect the writes and may ignore the number.

### ★ Is `0x0100` a plausible value in its neighbours' number space?

Three readings, and the numbers cannot separate them:

* **1.0 in Q8 — a unity coefficient.**  The structural twin of this pair is
  (`Curve_FE04C9`, `Curve_FE05C9`) → (`0x0400`, `0x0340`): the same
  `add`-then-`lda`-one-instruction-later idiom, one index, two words — and *there* the second
  table is a real second coefficient.  So the slot is a second-coefficient slot that this
  firmware pins.
* **Exactly one semitone (256)** in the 1/256-semitone unit its partner register `0x00C0`
  carries.  Same index, adjacent register, same units.
* **A lone flag in bit 8.**  `0x0100` has exactly one bit set, and register `0x0240` in the
  same periodic trio demonstrably *is* field-split (its low three bits are forced to 7).  A
  one-bit value is not evidence of a numeric coefficient at all.

⚠ One constant cannot distinguish a unity coefficient from a set flag.  Only a firmware or a
UI path that writes some *other* value could, and none does.  **Grade: value PROVEN, unit
UNIDENTIFIED.**  ⚠ And it constrains THIS FIRMWARE, not the silicon.

---

## 4. The three exponential tables: `0.3763 dB per step`, three times over

All three share one slope — **16 steps per doubling = 6.0206/16 = 0.3763 dB per step**.

| table | closed form | max residual | live span |
|---|---|---:|---|
| `Curve_Exp2Decay_256` | `round(32768 * 2^((k-255)/16))` | 4 counts | `0` for `k <= 46`, then 78.6 dB up to `0x8000` |
| `Curve_Exp2Rise_128` | `32768 * (1 - 2^(-k/16))` | **0 — exact on all 128** | `0` .. `0x7F7A` (0.99586) |
| `Curve_Exp2Decay_101` | `T[0]=0`; `round(32768 * 2^((k-100)/16))` | 4 counts | `0`, then 37.28 dB up to `0x8000` |
| `ExpCurve_0_to_0x80` | `T[0]=0`; `max(1, round(128 * 2^((k-127)/16)))` | **0 — exact on all 128** | `0`, then 42.1 dB up to `0x80` |

Nulls (over bands where the 1-count quantisation is under 0.0014 in log2, so the comparison is
about the law and not about rounding):

| table | straight line in `T` | straight line in `log2 T` |
|---|---:|---:|
| `Curve_Exp2Decay_256` | R² 0.841, max 10026 | R² 0.999999, max 0.0041 |
| `Curve_Exp2Rise_128` | R² 0.703, max 14439 | R² 1.000000, max 0.0042 *(on `log2(32768−T)`)* |
| `Curve_Exp2Decay_101` | R² 0.783, max 12343 | R² 0.999998, max 0.0094 |
| `ExpCurve_0_to_0x80` | R² 0.968, max 11.6 | R² 0.999849, max 0.0157 |

★ **Two of the four have index ranges that are UI parameters, and say so.**
`Curve_Exp2Decay_101`'s index is clamped `0..100` (`0xFC4B04`, `0xFC6ECA`): a **0..100 percent
control with an explicit OFF position**, given a 37 dB logarithmic taper.
`ExpCurve_0_to_0x80`'s index is a tone-record byte `0..127`: a **0..127 control** over 42 dB —
and the packer writes `(b << 8) | b`, **one byte in both halves** of register `0x0300`, which
is the shape of a device with two 8-bit fields fed the same number.

---

## 5. ⚠ The one musically absurd result, and what makes it go away

**`Curve_Exp2Decay_256` / `Curve_Exp2Rise_128` cannot be per-sample filter poles.**

The table's two largest entries are `0x8000` (= 1.0) and `0x7A90` (= 0.957520), with **nothing
in between**.  As a per-sample pole, 0.957520 is a time constant of **0.522 ms** at 44.1 kHz —
and even a 1 ms time constant would need 0.977579, which the table cannot represent.  An
envelope or a string decay wants 0.1 s to 10 s, i.e. a pole within ~100 counts of `0x8000`.
Reported rather than smoothed over: a per-sample reading of these tables is *wrong*.

★ **At the driver's own control rate the same table is exactly musical.**  The periodic
`0x00104000` refresh runs at 40.69 Hz — a period of 24.576 ms.  Stepped at that rate,
`T[i]/32768 = 2^((i-255)/16)` is a pole with `tau = 16 / (f_refresh · ln2 · (255-i))`:

| `i` | pole | τ | T60 | refresh periods |
|---:|---:|---:|---:|---:|
| 255 | 1.000000 | ∞ | (hold) | — |
| 254 | 0.957520 | 566 ms | 3.91 s | 23.0 |
| 251 | 0.840820 | 142 ms | 0.98 s | 5.8 |
| 239 | 0.500000 | 35 ms | 0.245 s | 1.4 |
| 191 | 0.062500 | 8.9 ms | 0.061 s | 0.36 |

— **24 ms to 3.9 s of T60**, where the per-sample reading gave 0.5 ms and nothing longer.
`Curve_Exp2Rise_128`'s complement gives the same law with `tau = 16/(f_refresh·ln2·k)`:
`k=1` → 567 ms, `k=16` → 35 ms, `k=127` → 4.5 ms — attack times.

⚠ **[INFERENCE, with its condition explicit]** the 40.69 Hz refresh is measured for registers
`0x00C0`/`0x0100`/`0x0240`, **not** for `0x0140`/`0x0180`, and nothing in the ROM says the LSI
advances an envelope on the host's write cadence.  What is established is the shape, and the
fact that one plausible rate turns an absurd range into a musical one.

★ **`Curve_Exp2Rise_128` in its other role IS musical without any assumption.**  Register
`0x01C0` is register `0x0400`'s word — a *cutoff coefficient* — times
`Curve_Exp2Rise_128[v1]/2`.  Scaling that coefficient scales the cutoff:

| `v1` | scale | cutoff shift |
|---:|---:|---:|
| 1 | 0.0424 | −4.56 octaves |
| 16 | 0.5000 | −1.00 octave |
| 64 | 0.9375 | −0.09 octave |
| 127 | 0.9959 | −0.01 octave |

0 to −4.6 octaves below the `0x0400` cutoff, which is the range a filter-envelope floor
covers.  **Grade STRONG** for `0x01C0`/`0x0200` being *the same quantity as `0x0400`/`0x0440`*;
the reason for the second copy is an inference.

★ **And one arithmetic coincidence, recorded with its condition.**  Register `0x0140` is
`Curve_Exp2Decay_256[0xCF − g(v1) + b]` with `b = (int8)(0x00E08C)`.  For `b = 0x30 = 48` and
`v1 >= 48` that is `32768·2^(-v1/16)`, and `Curve_Exp2Rise_128[v1]` is
`32768·(1 − 2^(-v1/16))` — an **exact `(a, 1−a)` pair**, i.e. a first-order lag toward the
`0x0400` target.  ⚠ Nothing here fixes `b`; it comes from a key-zone record in prom_d.
`Table_FDFF96`'s own values at that index run `0x22..0x3C`, which brackets `0x30`.

---

## 6. The four `LinCoef_*` ramps: key scaling, and one of them gives a **100% key follow**

Reader idiom, four sites (`0xFC55E0`, `0xFC4F51`/`0xFC500E`, `0xFC5249`/`0xFC53BF`, `0xFC513E`):

```
A = record depth (signed);  if A == 0 -> 0
D = (0x00E088), a 0..127 key
if A < 0:  D = 0x7F - D ;  A = -A          the curve is MIRRORED for a negative depth
result = (T[D] * A) >> 5                   so T is a coefficient in Q5, 32 = 1.0
```

⚠ Null: these are not "approximately linear".  Each is **exact** against its integer law on
every entry, and `LinCoef_FE0196`'s single exception at `k = 127` is what a sampled check
would have missed.

| table | law | Q5 range | slope per key | destination, and therefore its unit |
|---|---|---|---|---|
| `LinCoef_FE0096` | `2k − 128` | −4.000 .. +3.938 | 1/16 | `R[+0x12]`, the `Curve_Log2_251` index (0..250) |
| `LinCoef_FE0116` | `65k//128 − 32` | −1.000 .. +1.000, bipolar, single zero at `k=64` | 1/63 | `v1`/`v2`, an exp2 index — so one unit is **0.3763 dB** |
| `LinCoef_FE0196` | `k//2 − 64`, `T[127]=0` | −2.000 .. −0.031, unipolar | 1/64 | `i3`/`i4`, **the cutoff index, in semitones** |
| `LinCoef_FE0216` | byte-identical to `FE0196` (all 128) | — | — | two copies, one curve |

> ★★ **`LinCoef_FE0196` gives the cutoff key-follow an exact unit.**  Its slope is 1/64 of a
> Q5 unit per key, and its destination `i3` is in **semitones of cutoff**.  So a depth byte of
> **64 is exactly one semitone of cutoff per semitone of key = 100% key follow**, and the
> signed byte's ±127 range is ±198%.  The same holds for the `ks(Q, o)` stage the register map
> documents, whose slope is `Q[+o+3] >> 5`: there **32 = 100% key follow**.

---

## 7. `Table_FDFF96`: a minimum cutoff per key zone

256 `u8`, 27 distinct values, `0x22..0x3C` (34..60).  Indexed by the key-zone byte at
`0x00E08C`; used as the **lower clamp** on the cutoff index `i3`/`i4` (`0xFC52D2`, `0xFC5439`).

In §1's unit that is a **minimum cutoff of 466 Hz .. 2093 Hz per key zone** — a floor that
keeps the filter above the zone's own band.  No closed form; the values are data.
**Grade: range PROVEN, unit STRONG (it inherits §1's).**

---

## 8. The table an emulator author can use directly

| table | n | fit | endpoints | unit inferred | grade |
|---|---:|---|---|---|---|
| `Curve_Log2_251` | 251 | `T[0]=27648`; `round(27543 − 3072·log2 k)` | 27648 → 3072 | 1/256 semitone, log-domain | PROVEN fit / STRONG unit |
| `Const_0100_251` | 251 | `0x0100` | flat | Q8 unity, or 1 semitone, or a bit-8 flag | PROVEN value / UNIDENTIFIED unit |
| `Curve_Exp2Decay_256` | 256 | `round(32768·2^((k−255)/16))` | 0 (k≤46) → 0x8000 | Q15 gain, 0.3763 dB/step, 78.6 dB; **not** a per-sample pole | PROVEN fit / UNIDENTIFIED role |
| `Curve_Exp2Rise_128` | 128 | `32768·(1 − 2^(−k/16))` exact | 0 → 0x7F7A | Q15 depth; as a cutoff scaler, 0 to −4.56 octaves | PROVEN fit / STRONG for `0x01C0` |
| `Curve_Exp2Decay_101` | 101 | `T[0]=0`; `round(32768·2^((k−100)/16))` | 0 / 448 → 0x8000 | Q15 gain over a **0..100 percent** control, 37.3 dB + OFF | PROVEN fit / STRONG unit |
| `ExpCurve_0_to_0x80` | 128 | `T[0]=0`; `max(1, round(128·2^((k−127)/16)))` | 0 → 0x80 | 8-bit gain over a 0..127 control, 42.1 dB, in **both** register halves | PROVEN fit / STRONG unit |
| `Curve_FE04C9` (folded) | 128 | `round(65536·g/(1+g))`, `g = tan(π f/44100)`, `f = 440·2^((k−33)/12)` | 510 → 61359 | **one-pole lowpass coefficient**; index = semitone = MIDI note − 36 | PROVEN fit / STRONG unit |
| `Curve_FE05C9` (folded) | 128 | `round(8192·(1 − 1/(128·g)))`, same `g` | 25 → 8188 | Q13 companion of the **same** cutoff: `(1−G/8192)·g = 1/128` | PROVEN fit / UNIDENTIFIED role |
| `Table_FDFF96` | 256 | data, 27 distinct values | 0x22 → 0x3C | minimum cutoff per key zone, 466 Hz .. 2093 Hz | PROVEN range / STRONG unit |
| `LinCoef_FE0096` | 128 | `2k − 128` exact | −128 → +126 | Q5 key ramp ±4.0 | PROVEN fit / STRONG unit |
| `LinCoef_FE0116` | 128 | `65k//128 − 32` exact | −32 → +32 | Q5 key ramp ±1.0, bipolar | PROVEN fit / STRONG unit |
| `LinCoef_FE0196` | 128 | `k//2 − 64`, `T[127]=0` | −64 → −1, then 0 | Q5 key ramp −2.0..0; **depth 64 = 100% cutoff key follow** | PROVEN fit / STRONG unit |
| `LinCoef_FE0216` | 128 | byte-identical to `FE0196` | same | same | PROVEN |

### The registers this puts a physical quantity on

| register | quantity | grade |
|---|---|---|
| `chan+0x00C0` | a **log-domain time**, 1/256 semitone per count, tracking pitch with slope −1, range `[0, 0x7F00]` | STRONG (unit + direction); absolute scale UNIDENTIFIED |
| `chan+0x0100` | the constant `0x0100`; periodic traffic, constant value | value PROVEN, unit UNIDENTIFIED |
| `chan+0x0140`, `0x0180` | a Q15 gain, 13 bits used (`& 0xFFF8`), 0.3763 dB/step | PROVEN fit, role UNIDENTIFIED |
| `chan+0x01C0`, `0x0200` | **the same cutoff coefficient as `0x0400`/`0x0440`**, scaled by 0..0.996 (0 to −4.56 octaves) | STRONG |
| `chan+0x0240` | a scaled parameter word; low three bits a separate field, forced to 7 | PROVEN, role UNIDENTIFIED |
| `chan+0x0280` | a Q15 gain from a **0..100 percent** control, 37.3 dB + OFF | STRONG |
| `chan+0x0300` | an 8-bit gain from a **0..127** control, 42.1 dB, duplicated into both halves | STRONG |
| `chan+0x0340`, `0x0380` | the Q13 companion of `0x0400`/`0x0440`'s cutoff — **computable from it** | STRONG that it is tied; role UNIDENTIFIED |
| `chan+0x0400`, `0x0440` | ★★ a **one-pole lowpass cutoff coefficient**, index in semitones (`k = MIDI note − 36`), 110 Hz .. 21 kHz, saturating at Nyquist | STRONG |

**Nine of the nineteen registers now carry a physical quantity or a stated unit** —
`0x00C0`, `0x01C0`, `0x0200`, `0x0280`, `0x0300`, `0x0340`, `0x0380`, `0x0400`, `0x0440`,
counting the A/B twins separately — where the register map graded all seventeen non-constant
ones UNIDENTIFIED.  A tenth, `0x0100`, keeps its PROVEN value and gains three candidate units
it cannot choose between.

---

## 9. What is still open, and what would settle it

* **What `Curve_FE05C9` IS.**  Its closed form is exact and its tie to the cutoff is exact, so
  an emulator does not need it — but no standard filter structure this pass tried puts
  `8192·(1 − 1/(128·g))` next to `65536·g/(1+g)`.  ⚠ Recorded as a shape, not a role.
* **The absolute scale of `chan+0x00C0`.**  The unit per count and the direction are fixed;
  the zero point is not.  One value of that register observed against one known delay or decay
  time would fix it, and there is no reader in the image to supply one.
* **`Curve_Exp2Decay_256`'s rate.**  §5 shows the table is absurd per sample and musical at
  40.69 Hz.  Which rate the LSI actually uses is not in this ROM.
* **`Table_FDFF96`'s 27 values.**  A per-zone floor, with no closed form.  Its producer is the
  key-zone record in prom_d, so prom_d's zone format would give the 27 numbers a meaning.
* **The `0x00E08C` bias in `0x0140`'s index.**  If it is `0x30` the `(a, 1−a)` pair of §5 is
  exact.  It comes from prom_d.
* **Register `chan+0x0000`, `0x0040`, `0x0080`, `0x02C0`, `0x03C0`, `0x0480`** — no table
  passes through them, so this pass had no lever on them at all.

⚠ Felipe has no access to the hardware, so "measure the instrument" is not on this list.  The
routes that remain are prom_d's tone/zone record formats and the tone-editor UI, which must
display these parameters under names.
