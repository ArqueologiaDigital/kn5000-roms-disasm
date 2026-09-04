# `POSITION`'s absolute scale: NOT in the ROM — but the missing number is now ONE dimensionless constant

Lane `w22/position-scale`, 2026-09-04.  A companion to
`notes/HLE-GUIDE-l7a1429.md`, whose §8.1 calls the scale of register `chan+0x00C0`
*"the single most valuable missing number"*.

Everything below is re-derived from `original_ROMs/wsa1_prom_{a.ic12,b.ic13,c.ic28,d.bin}` by

```
python3 notes/l7a1429_position_scale.py             # 9 sections, printed
python3 notes/l7a1429_position_scale.py --selftest  # FAILURES: 0
python3 notes/l7a1429_position_scale.py --table     # the 251 entries and their ratios
```

which reads **bytes** and never a `.s` file.  No `.s` file is edited by this lane, so
neither the byte gate nor the comment gate applies to it.

---

## 0. THE ANSWER, IN ONE PARAGRAPH

**The absolute scale is NOT recoverable from the ROM — grade UNIDENTIFIED, and I expect it
to stay that way.**  The chip's log-to-time converter is silicon; the firmware never reads
the device back; and the routine that builds the register contains **nine 16-bit
immediates, all of them clamps, masks and strides, and not one a time, a rate or a sample
count** (probe §8).  What *has* changed is the shape of the ignorance.  The guide records
only the ratio `2^(v/3072)` and an unknown scale in samples.  This lane shows the register
is far more constrained than that: the table's constant is the integer **500 = 5 × 100**,
the editor draws the control as `p13/5`, and the pivot `0x4280` is **MIDI note 66 exactly**,
so

> ```
>     tap delay  =  g · P(note) / POSITION          FORMANT = MOVE
>     tap delay  =  g · P66     / POSITION          FORMANT = FIX   (a fixed time)
> ```
>
> with `POSITION` the editor's own 0.0–50.0 control, `P(note)` the played note's period in
> samples at 44.1 kHz, `P66 = 119.1910` samples, and **`g` a single DIMENSIONLESS constant**.
> `g = 1` is the physically canonical value — the tap then sits at exactly `1/POSITION` of
> the resonator.  ⚠ **Nothing in the ROM says `g = 1`.**

That is a real reduction: the missing number went from *"an unknown scale in samples"* to
*"one dimensionless number of order 1, with a named canonical value"*.  An HLE should
expose exactly that one number.

---

## 1. ★★ The table's constant is 500, not 27543 — and the residual is ZERO

`notes/FINDINGS-l7a1429-curve-tables.md` §2 gives
`T[k] = round(27543 − 3072·log2 k)`, max |residual| **1 count**.  The better form is

```
    Curve_Position_Log2Period_251[k] = round( 3072 · log2( 500 / k ) )
```

which is **exact for every one of k = 1..250 — residual 0** (probe §1).  `27543` is
`round(3072·log2 500) = 27542.89`, i.e. the rounding of the real constant, which is why the
old form is off by one somewhere.

**The null.**  `N = 496, 498, 499, 501, 502, 504, 512` each get **250 of 250 entries
wrong**.  The design constant is the integer 500 and nothing adjacent to it.

Two endpoints follow, and both are round **in counts**:

| entry | value | in the register's own unit |
|---|---:|---|
| `T[0]` | 27648 | exactly **9 octaves** — a saturation constant; `500/0` has no value |
| `T[250]` | 3072 | exactly **1 octave** — forced, since `500/250 = 2` |

★ **Both endpoints are round in COUNTS, not in samples or in hertz.**  A designer who had
an absolute anchor to hit would have landed on one.  This one did not — the first piece of
evidence for the negative.

---

## 2. ★★ The editor divides by five, so the ratio is `100 / POSITION`

`prom_a`'s dedicated `POSITION` editor at `0xFD44C7` draws the value as
`p13/5 . 2·(p13 mod 5)` — two `div C,0x05` (`0xFD4564`, `0xFD456D`) and an `add B,B`
(`0xFD4570`) for the decimal digit, already established by the editor-pages lane
(`FINDINGS-l7a1429-editor-pages.md` §3a).  This lane adds **the range**, from the same
routine's edit descriptor:

```
    0xFD44D9  (desc+6) = 0x00FF        the byte range
    0xFD44E1  (desc+8) = 0x00FA = 250  the PARAMETER maximum
```

against the sibling editor for `p14`, which writes `0x007F` into **both** slots
(`0xFD45DE`).  So **`POSITION` runs 0.0 to 50.0 in steps of 0.2**, and the packer's own
`clamp(…, 0..250)` at `0xFC49CC` *is* the control's range, not a defensive bound.

★★ Therefore `500/k = 100/POSITION`, and

```
    Curve_Position_Log2Period_251  =  round( 3072 · log2( 100 / POSITION ) )
```

The `500` is `5 × 100`: the **5** is the display divisor and the **100** is a per-cent
denominator.  The register carries `log2(100/POSITION)` plus a pitch term.

⚠ **And the direction is forced, which excludes the obvious reading.**  The register value
*falls* as the note rises, so the chip's exponent must be `+v/3072` for the delay to track
the period.  The delay is therefore proportional to **1/POSITION**, never to `POSITION`.
A reading of the control as "per cent of the string length" is arithmetically excluded;
what survives is its reciprocal — **`POSITION` is the harmonic the comb notch lands on**,
so `POSITION 2.0` is the midpoint and `POSITION 50.0` is 2 % from the end.

---

## 3. ★★ `0x4280` is MIDI note 66 EXACTLY, and 66 is the instrument's own middle key

`FINDINGS-l7a1429-curve-tables.md` §2 reads the pivot as *"note 66.5"*.  ⚠ **That is
wrong as an interval, and the correction matters**, because the whole pitch term is a
whole number of semitones only under the right reading.

`Voice_ComputePitch` seeds the pitch word `note·256 + 0x80` — `ld A,(XIX+0x05) / sll 0x08,WA
/ and WA,0x7F00 / ld HL,WA / add HL,0x0080` at `0xFA7F3A`-`0xFA7F4B`.  So

```
    0x4280 − pitch(m)  =  17024 − (256m + 128)  =  256 · (66 − m)      for EVERY m
```

— the half-step centre in `0x4280` cancels the one in the pitch word, exactly.  The pivot
is note **66**, and the pitch term is whole semitones below it.

Then: is 66 meaningful, and is it consistent with `MUTING`'s `index = MIDI note − 36`?
**Yes, and they are the same fact seen twice.**

* `ToneGen_VelocityFromTouch` sends each key out as `key + 36` (`add C,0x24` at `0xF995EC`).
* `NoteTrim_BuildFromCalibration` walks `0 .. 0x3C` — **61 keys** (`cp (XIZ-2),0x003D` at
  `0xF99816` and `0xF9983B`).
* So keys 0..60 are **MIDI 36..96 = C2..C7**, and the middle key is **30 = MIDI 66**.

> ★★ **`MUTING`'s `−36` is the compass's BOTTOM key; `POSITION`'s `0x4280` is its CENTRE.
> Both count from the same C2.**  The `MUTING` curve's index is literally the WSA1's own key
> number, and the `POSITION` pivot is literally its middle key — MIDI 66 = F#4 = 369.9944 Hz,
> period **119.1910 samples** at 44.1 kHz.

The same `0x4280` is the tone generator's own key-follow pivot (`0xFA80C7`, `0xFA80D7`,
`0xFA80DF`), and 66 is the modal `MUTING` key-scaling breakpoint in the factory set
(`dev104_topology_probe.py` §13: `p25 ∈ {42, 54, 66, 78, 90}`).  One reference note, three
independent uses.

---

## 4. ★ The third term is not a third unknown: `R[+0x0C]` is the key zone's TUNING word

The guide writes the expression as `… + (0x4280 − R[+0x0E]) − R[+0x0C]` and leaves
`R[+0x0C]` as *"the key-zone word"*.  It is more specific than that, and it closes the
expression:

```
    0xFA748D  ld BC,(XIX+0x06) / ld (0x5a4f),BC     the zone record's TUNING word
    0xFA7494  ld BC,(XIX+0x06) / push BC            the SAME word, third argument to
    0xFA74A0  call 0xFC4D85                         Pack104_SetInputs_Rec0C_E08C
    0xFC4D93  ld (XBC+0x0c),WA                      -> R[+0x0C]
```

and `0x005A4F` is exactly what `Voice_PitchAddZoneOffset` adds to the pitch to make
`voice[+0x0A]`, the word the tone generator's pitch register `chan+0x0400` is built from
(`FINDINGS-prom_c-dev10c-register-meanings.md` §2, §4).  So

> ```
>     reg(chan+0x00C0)  =  T[k] + ( 0x4280 − voice[+0x0A] )
> ```
>
> i.e. **`POSITION` tracks the SOUNDING pitch — the sample's own tuning correction
> included — at slope exactly −1**, and, up to the global `(0x001503)` and the part's
> `±[+0x1D]`,
> ```
>     reg(0x00C0) + reg(0x0400)  =  0x4280 + T[k]
> ```
> The modelling LSI and the tone generator are handed complementary halves of one
> log-pitch quantity about the same pivot.

That is a stronger statement than the guide's, and it removes a term that looked like a
free unknown.  ★ It also means the register value for a factory tone is fully determined
once the prom_d key-zone array is located — see §8.

---

## 5. ⚠ A correction the guide needs: `FORMANT = FIX` is the MAJORITY of the factory set

`Pack104_StageRegs_00C0_0100_0240` tests **bit 7 of `p14`** and, when it is SET, **skips the
pitch term entirely** (`0xFC4A03`-`0xFC4A0C`).  The editor-pages lane names that bit
`FORMANT`, drawn `FIX`/`MOVE`.  Over the 133 self-checking melodic wave-select records
(probe §5, the same population the guide quotes):

| | count |
|---|---:|
| `FORMANT = FIX` — the register is a CONSTANT, note-independent | **103 / 133** |
| `FORMANT = MOVE` — the register tracks the note, slope −1 | 30 / 133 |

⚠ **The guide's §2.7 and §3.2 call "the slope against key is exactly −1" the single
strongest discriminator between a resonator and a subtractive voice.  It is still exactly
−1 when it is on — but it is OFF in three quarters of the factory melodic set.**  The
discriminator is not weakened (a filter-envelope time has no business being exactly
inverse in frequency *ever*), but the emphasis is wrong: the register's ordinary factory
use is a **fixed time**, which is what the caption `FORMANT` says it is.  An HLE must
implement both arms; the guide's §5 row does not mention the gate at all.

The factory `POSITION` census is narrow: **`p13 = 125` in 118 of 133**, i.e. displayed
`POSITION 25.0`, the exact middle of 0.0–50.0.  The other values are
4.0, 10.0, 14.0, 17.4, 32.2, 39.2, 50.0 — one or two records each.

★ And at `POSITION 25.0` with `FORMANT = MOVE`, the register **underflows above MIDI note
90** (`T[125] = 6144`, and `6144 + 256·(66−m) < 0` for `m > 90`) and is forced to the floor
`0x0000` by `0xFC4A37`.  The floor is reached in ordinary play, near the top of the
instrument's own compass.  Whatever the chip does at 0 is audible, and nothing in the ROM
says what that is.

---

## 6. The reduction, and why no unit is round

Let the chip's rule be `delay(v) = C · 2^(v/3072)` samples, `C` unknown.  §§1–4 give
`2^(v/3072) = (100/D) · P(m)/P66` with `D` the displayed `POSITION`, so

```
    delay = g · P(m) / D          g ≡ 100·C / P66 = 0.838990 · C
```

**One dimensionless unknown.**  The two natural anchors are:

| anchor | what it fixes | the other one then is |
|---|---|---|
| `C` a power of two (a whole number of samples, or a binary sub-multiple) | the sample grid | `g` off a power of two by **303.9 cents** |
| `g = 1` (the tap is exactly `1/POSITION` of the resonator) | the physics | `C = 1.19191` samples, off a power of two by **303.9 cents** |

★★ **They cannot both be round.**  `log2(100/P66) = −0.2533` octave, whose distance to the
nearest integer is **0.2533 octave = 303.9 cents**.  This is arithmetic, not a search
result: the ROM's exponential zero-point sits at no privileged place on either grid.

### 6.1 The roundness test, pre-registered, with its null

* **Tolerance, stated before looking:** a log-domain quantity lands on a target if it is
  within **±5 cents (±0.289 %)**.  That is the order of the agreements the curve lane
  reports for the `MUTING` fit (0.33 cent, 0.8 cent); anything looser would not be a claim
  about design intent.
* **Null for one test:** under a uniform prior on `log2(x) mod 1`, the chance of landing
  within 5 cents of *any* power of two is `2·5/1200 = 0.833 %`, i.e. **1 in 120**.
* **Candidate units tried: TWELVE** (probe §7) — `delay(v=0)` = 1/4, 1/2, 1, 2, 4, 8, 16
  samples; `delay(0x7F00)` = 1024, 2048, 4096, 65536 samples (the ceiling read as a DRAM
  depth); and `g = 1`.  Seven put `C` on a power of two, one puts `g` on one, **zero put
  both there**.  With twelve tests at p = 1/120 each the expected number of chance hits on
  a *single* grid is 0.1 — which is why a single-grid hit proves nothing here, and why the
  test that matters is the joint one, which is arithmetically impossible to pass.
* ⚠ **"A whole number of samples" is not a test.**  With a 0.289 % window every value above
  ~173 samples is within tolerance of some integer.  The target has to be a power of two,
  a named buffer size, or a sub-multiple of `fs` to discriminate at all.
* ⚠ **One soft spot, which rescues nothing.**  `g` is defined against `P66`, so it inherits
  the tone generator's unresolved half-step centre: if IC4 reads its pitch register as
  `note = v/256` rather than `(v−128)/256`, every `g` moves by `2^(1/24)` = 50 cents.
  50 ≠ 303.9, so the conclusion is unchanged — but a future `g` must say which convention
  it is quoted in.

### 6.2 A soft bound, recorded as soft

In `FORMANT = FIX` the register is a fixed delay, hence a fixed resonance at
`f = fs·D / (100·C) = 441.0·D/C` Hz.  At the factory default `POSITION 25.0`:

| `C` | resonance |
|---:|---:|
| 1.00 | 11 025 Hz |
| 1.19191 (`g = 1`) | 9 250 Hz |
| 4 | 2 756 Hz |
| 8 | 1 378 Hz |
| 16 | 689 Hz |

A body formant between 500 Hz and 3 kHz would need `C` between **3.7 and 22.1**, which does
**not** contain `g = 1`.  ⚠ **That is a musical-plausibility band, not a measurement**, and
it is recorded only so the next pass knows the two readings disagree by about a factor of
three.  It must not be quoted as a value.

---

## 7. ★★ The positive control: this parameter group DOES carry an absolute unit

A negative is worth nothing unless the instrument could have seen a positive.  The control
is the sibling parameter on the very next editor page.

`PartRec_SetMovementRate_0009` reads `Curve_Movement_PhaseStep_51` at `0xFE0296` as **51
bytes**, indexed by `p18 & 0x7F` clamped 0..50 (`ld HL,0x0032` at `0xFC6252`,
`add XBC,0x00fe0296 / ld A,(XBC)` at `0xFC626E`).  The value becomes a step in a phase
accumulator masked `&0x01FF` (`0xFC7C7A`) that indexes a 512-byte waveform at `0xFE02C9`
(`0xFC7C91`), advanced once per staging refresh.  At the measured 40.6901 Hz refresh:

```
    SPEED  0 -> step   0 ->  0.0000 Hz          SPEED 25 -> step  64 ->  5.0863 Hz
    SPEED  1 -> step   1 ->  0.0795 Hz          SPEED 40 -> step  95 ->  7.5499 Hz
    SPEED 10 -> step  25 ->  1.9868 Hz          SPEED 50 -> step 126 -> 10.0136 Hz
```

★★ **A 0..50 control in the same parameter group maps to 0.0000 – 10.0136 Hz — an exactly
zero floor and a ceiling 0.14 % from a round 10 Hz**, monotone throughout.  And 126 is the
*closest representable* step to 10 Hz (10 Hz needs 125.83; the step size near the top is 2
counts = 0.159 Hz).

**Null.**  Integer hertz are 1 apart and the window is ±0.05 Hz, so landing this close to
*some* integer by chance is p ≈ 0.1; landing on 10 specifically, with the floor exactly 0
and the curve monotone, is well below that.  Grade **STRONG**, not PROVEN, because the
40.69 Hz refresh is another lane's measurement.

Two things follow:

1. **The method finds an absolute unit when the firmware has one.**  The failure to find
   one for `POSITION` is a property of the firmware, not of the search.
2. ★ It is a second, independent argument **for** the 40.69 Hz refresh: no other plausible
   tick makes this table land on a round span.

---

## 8. GRADE, and exactly what would settle it

| claim | grade |
|---|---|
| `T[k] = round(3072·log2(500/k))`, exact for k = 1..250 | **PROVEN** |
| `POSITION` is displayed 0.0–50.0 = `p13/5`, and 250 is its own maximum | **PROVEN** (operands) |
| the register carries `log2(100/POSITION)` plus the pitch term | **PROVEN** |
| `0x4280` is MIDI note 66 exactly, and the pitch term is whole semitones | **PROVEN** |
| 66 is the middle key of the 61-key C2..C7 compass whose bottom key is the `MUTING` index's 36 | **STRONG** — three operands (`add C,0x24`, two `cp …,0x003D`) plus the `MUTING` fit |
| `R[+0x0C]` is the zone tuning word, so `reg(0x00C0) = T[k] + 0x4280 − voice[+0x0A]` | **PROVEN** (operands) |
| `FORMANT = FIX` in 103 of 133 factory melodic records | **PROVEN** (data) |
| `delay = g·P(note)/POSITION`, one dimensionless unknown | **STRONG** — it assumes only that the chip's converter is `2^(v/3072)`, which the unit and the −1 slope already fix |
| `g = 1` | **WEAK.**  Canonical, self-consistent, and unsupported |
| **the absolute scale** (`C`, or equivalently `g`) | **UNIDENTIFIED** |

### What was searched, and the null for the search

* An unaligned f32/f64 scan of **all four images** for seven candidate constants
  (`P66/100`, `P66/500`, `P66`, `500/P66`, `100/P66`, `f(66)`, `fs/100`) at ±0.5 % finds 37
  hits.  **The null**: the same scan with 70 meaningless decoys, each a real target times
  `2^u` so it sits in the same decade, finds a *median of 17 hits per decoy* against the
  real targets' median of 5.  The real targets are not enriched; they are under-represented.
  An unaligned byte scan of 2 MB finds any 0.5 %-wide value at that rate whatever the value
  is.
* **Zero** hits at an 8-aligned offset inside `Float64_ConstantPool` (`0xFCB27E-0xFCB4E5`),
  the one place in the image where a real physical constant lives
  (`FINDINGS-prom_c-f64-pool.md`).
* Every 16-bit immediate in the routine that builds the register
  (`0xFC49AD-0xFC4AEC`) is one of `0x0000`, `0x0002`, `0x0007`, `0x007F`, `0x00FA`,
  `0x4280`, `0x7F00`, `0x8000`, `0xFFF8` — clamps, masks and a stride.  **Not one is a
  time, a rate or a sample count.**

### What WOULD settle it

1. ⚠ **The instrument, and only in one specific way.**  Felipe has no access to the hardware
   (in storage abroad, no date), so this is not an available next step and nothing here
   proposes one.  But the measurement is now cheap and precise, which it was not before:
   hold `FORMANT = MOVE`, play one sustained note, sweep `POSITION`, and find the setting at
   which the pluck-position comb notch lands on a **known harmonic** of the note.  If the
   notch is on harmonic `n` at `POSITION = D`, then `g = D/n` — one reading, one number, no
   calibration.  A spectrum at two settings would over-determine it.
2. **A second-source datasheet or an application note for the L7A1429.**  The scale is a
   part-level property of the silicon.
3. **Nothing on the CPU 1 side will do it.**  The guide's §8 recommends one hop on CPU 1 to
   close the WEAK register names; that hop cannot produce this number, because the display
   path for `POSITION` is `p13/5` and stops there — there is no hertz, no millisecond and no
   per-cent conversion anywhere in the editor.

### What an HLE should do now

* Compute `tap = g · P(note) / POSITION` on the `MOVE` arm and `tap = g · P66 / POSITION`
  on the `FIX` arm, reading the `FORMANT` gate from `p14` bit 7.  Expose **`g` as one named
  device parameter, default 1.0**, and say in the comment that it is unmeasured.
* Honour the floor: at the factory default `POSITION 25.0` the register hits `0x0000` above
  MIDI note 90.
* Do **not** implement `POSITION` as a percentage of the resonator; §2 excludes that.

---

## 9. What this note changes in its neighbours — reported, not edited

Files that carry statements this lane corrects.  ⚠ They belong to other lanes and are
**not** edited here.

| file | statement | correction |
|---|---|---|
| `FINDINGS-l7a1429-curve-tables.md` §2 | `T[k] = round(27543 − 3072·log2 k)`, max residual 1 | `round(3072·log2(500/k))`, residual **0** (§1) |
| `FINDINGS-l7a1429-curve-tables.md` §2 | *"pivoting on `0x4280` = note 66.5"* | note **66** exactly; the pitch word carries the same half-step centre (§3) |
| `HLE-GUIDE-l7a1429.md` §5, row `0x00C0` | *"pivot note 66.5"*, and no mention of the `FORMANT` gate | note 66; and the pitch term is **skipped** when `p14` bit 7 is set, which is 103 of 133 factory records (§3, §5) |
| `HLE-GUIDE-l7a1429.md` §2.7 / §3.2 | the −1 slope is "the single strongest discriminator" | still true where it applies, but it applies to the **minority** arm of the factory set (§5) |
| `HLE-GUIDE-l7a1429.md` §5.2, `- R[+0x0C]` | *"the key-zone word"* | the zone's **tuning** word, the same one added to the tone generator's pitch (§4) |
| `HLE-GUIDE-l7a1429.md` §8.1 | *"the constant that turns register `chan+0x00C0` into a time in samples"* | the missing number is one **dimensionless** constant `g`, not a scale in samples (§6) |
