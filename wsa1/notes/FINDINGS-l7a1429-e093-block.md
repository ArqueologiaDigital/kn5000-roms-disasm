# The block at RAM `0x00E093`: a coupled-resonator detune solver

Wave 24, 2026-09-04, lane `w24/e093-block`.  Eighth companion in the L7A1429 set, and the
one that closes the lead wave 21 recorded and correctly refused to name:

| note | answers |
|---|---|
| `FINDINGS-prom_c-dev104-register-map.md` (w17) | what each of the nineteen registers is built from |
| `FINDINGS-l7a1429-write-sequencing.md` (w19) | when each is written |
| `FINDINGS-l7a1429-curve-tables.md` (w19) | what quantity each ROM curve produces |
| `FINDINGS-l7a1429-parameter-names.md` (w19) | what the machine calls each register |
| `HLE-GUIDE-l7a1429.md` (w19) | what kind of engine it adds up to |
| `FINDINGS-l7a1429-packer-routines.md` (w20) | which routine computes each value |
| `FINDINGS-l7a1429-gate-and-keyscaling.md` (w21) | what switches register `0x0300` on |
| `FINDINGS-l7a1429-editor-pages.md` (w21) | what each editor page draws, and where `GROUP` lives |
| `FINDINGS-l7a1429-reso-scale.md` (w23) | what `RESO SCALE` does to the two tuning registers |
| **this note** | **what the `0x00E093` block is** — and how the two resonators interact |

Everything asserted here is re-derived from
`original_ROMs/wsa1_prom_{a.ic12,b.ic13,c.ic28,d.bin}` by

```
python3 notes/w24_e093_coupling_solver.py             # 8 sections, printed
python3 notes/w24_e093_coupling_solver.py --selftest  # FAILURES: 0
python3 notes/w24_e093_coupling_solver.py --census    # every census row
python3 notes/w24_e093_coupling_solver.py --reach     # the 4000-draw reachability sweep
```

which reads bytes.  It opens the `.s` listings for exactly one thing — the set of
instruction START ADDRESSES and their canonical spellings, which the converters gate on a
byte-identical round trip — and for nothing else.

⚠ **Felipe has no access to the hardware** (it is in storage abroad).  Nothing below
proposes measuring the instrument, and §8 says where that costs us the last answer.

---

## 0. THE ANSWER, IN ONE PARAGRAPH

**The block has a reader, and the block is an argument struct.**  All three routines that
open the gate on register `chan+0x0300` finish their fill loop with
`lda XBC,0x00e093 / push XBC / calr 0xFC4269` — so the block's address never appears at the
reader, because the reader is *handed* it.  `sub_FC4269` is a 1087-byte fixed-point solver
whose every magic constant is a Q11 rendering of a named quantity (`2/3`, `π`, `2π`,
`1/2π`), which evaluates, for each of the group's resonators in turn, the **loop
characteristic function of a network of coupled delay resonators at that resonator's own
nominal frequency**, and converts the resulting phase error through a `3072·log₂` table into
a **pitch offset in 1/256 semitone**.  That offset is read back into `P[+0x12]` and
`P[+0x14]`, which `Dev104_PackStagingStruct` adds to `P[+0x0A]` and `P[+0x0C]` on the way to
registers `chan+0x0040` (`MAIN RESONATOR` tuning) and `chan+0x0080` (`SUB RESONATOR`
tuning).  **So the `0x00E093` block is exactly what the task suspected — the coupling
between the resonators — and its output is a detune, quantised to about 13 cents and
bounded to about +11.5 / −6.8 semitones.**  It is written only when the part is `GROUP`ed,
and the three not-grouped arms write the same two fields as literal zero.

---

## 1. THE READER — PROVEN

### 1.1 The three call sites

Each gate-opening arm ends its per-element fill loop with the same four instructions
(probe §1; every byte asserted, the two immediates decoded from raw ROM):

```
   FC6F7C  ld  (0x00e093),0x0200       MODE  = 0x0200
   FC6F83  ld  (0x00e095),0x0008       N     = 8
   FC6F8A  lda XBC,0x00e093
   FC6F8F  push XBC
   FC6F90  calr 0xfc4269               <- THE READER
```

| arm | selected when | `MODE` | `N` | elements |
|---|---|---:|---:|---|
| `sub_FC6D6E` | `H == 0xAA` (all four in `GROUP` 2) | `0x0200` | 8 | 0..3 |
| `sub_FC6FFD` | `H & 0x0F` | `0x0400` | 4 | 0, 1 |
| `sub_FC723F` | `H & 0xF0` | `0x0400` | 4 | 2, 3 |

`N` is **twice** the number of elements: each element contributes two slots, and §2 shows
they are its `MAIN` and its `SUB` resonator.

`sub_FC4269` reads the struct pointer out of `(XIZ+0x08)` at 0xFC4270 and immediately
unpacks the two header words — `N` from `+0x02`, `MODE` from `+0x00` — and returns at once
if `N <= 0`.  The block is this routine's argument and nothing else.

### 1.2 ★★ Why the wave-21 census could not see it, stated plainly

`FINDINGS-l7a1429-gate-and-keyscaling.md` §1.8 says:

> ⚠ `0x00E093` has no located reader.  The eleven `lda XBC,0x00e093` sites are all writes
> and no other spelling of that address exists in either image.

**Every clause of that is true, and the conclusion still fell.**  There are no *reads* of
`0x00E093`, because the reader never names it.  `lda` does not write anything — it takes an
**address** — and three of the eleven push that address straight into a call.  A census that
partitions sites by *access shape* is blind to a shared worker taking the address as an
argument, which is the sixth of the failure modes this project has now been bitten by, and
the same one that hid twenty-four pointer-table handlers last week.

### 1.3 The census that makes the new negative falsifiable

Probe §7 runs a **framing-independent byte scan** over all four images at every offset for
the byte pair `93 e0` — which appears in the 16-bit immediate form, the 24-bit absolute form
and any 32-bit immediate alike, in code *and* in regions this tree frames as data:

| image | occurrences |
|---|---:|
| prom_a | **0** |
| prom_b (CPU 1's own address space; cannot reach CPU 0's RAM) | **0** |
| prom_c | **30** |
| prom_d | **0** |

and all 30 of prom_c's are adjudicated by the spelling of the instruction that contains
them: fifteen `lda XBC,0x00e093`, three `lda XWA,0x00e093`, nine `add Xrr,0x0000e093`, three
`ld (0x00e093),imm`.  There is no other spelling, and every one of the 30 lies inside the
three arms.

**The forms searched, written down so the negative can be attacked:**

| form | searched how | found |
|---|---|---|
| a literal displacement / absolute on the block | the byte scan above, all four images | the 30 |
| **the address as a CALL ARGUMENT** | every `lda Xrr,0x00e093` whose next instruction is a `push` | ★ **three — this is the answer** |
| a pointer stashed and dereferenced later | the same three sites: each `push` is consumed by the *very next* instruction, a `calr`; no `ld (…),XBC` follows any of them | none |
| a base spilled to a frame and reloaded | irrelevant here — the scan matches the ADDRESS, which no spill can hide; and the reader's own accesses are `(XBC+d)` off the argument, enumerated in §2 | — |
| a base advanced past the block | the nine `add Xrr,0x0000e093` sites are exactly the arms' own strided writes, all adjudicated in §2 | none extra |
| `TABLE − 4·k`, an arithmetically built address | ⚠ **NOT closed by the scan.**  Closed instead by the positive result: the block has a reader, and §3 shows what it does with the answer | — |
| a block move / micro-DMA | the DMA registers are loaded from immediates or registers; an immediate carrying the address would show as `93 e0` and none does outside the 30.  ⚠ Same caveat as the row above | none |
| the other processor | prom_b is a separate address space (`prom_c/prom_c.ld`) and has zero occurrences | none |

**POSITIVE CONTROL.**  The same scan independently finds all three `ld (0x00e093),imm`
header writes and all nine strided `add` sites, which are three different shapes reached
three different ways.  A method that finds those is not blind to a fourth.

---

## 2. THE BLOCK: a 68-byte argument struct, four parallel arrays — PROVEN

The four base displacements are immediates in **both** the arms and the solver, and they
agree (probe §2):

```
   +0x00   MODE   the coupling scale, 0x0200 or 0x0400
   +0x02   N      the number of slots, 8 or 4
   +0x04   A[8]   INTERACTION GAIN:  Curve_Exp2Gain_U8_128[p19] << 8, same for both slots
   +0x14   B[8]   LEVEL:  0x8000 (MAIN)  /  Curve_Exp2Gain_Percent_101[clamp(|p33|,0..100)] (SUB)
   +0x24   C[8]   TUNING IN:  P[+0x0E] (MAIN)  /  P[+0x10] (SUB)
   +0x34   D[8]   RESULT, written by the solver, read back by the arm
```

Element `k` owns slot `2k` (MAIN) and slot `2k+1` (SUB) of every array: each arm advances
all six running offsets by 4 per element (`inc 4,XIY` at 0xFC6F65), and the read-back loop
takes `D[2k]` to `P_k[+0x12]` and `D[2k+1]` to `P_k[+0x14]`.

★ **A structural corroboration the addressing did not have to give.**  `sub_FC4269` uses
seven absolute scratch arrays — `0x00E012`, `0x00E022`, `0x00E032`, `0x00E042`, `0x00E052`,
`0x00E062`, `0x00E072`.  Each is 8 words; they run **end to end** and stop exactly at
`0x00E082`, the packer's `PART` pointer.  `N = 8` is the hard maximum the RAM map allows,
and the map was laid out for it.

★★ **And both input arrays are UNIT-SCALED GAINS** (probe §4b).  `Curve_Exp2Gain_U8_128`'s
own maximum is **128**, and the solver reads `A >>ᵘ 4` of `(g << 8)` — so `A` spans exactly
`0 .. 0x800`, i.e. `[0, 1]` in Q11.  `Curve_Exp2Gain_Percent_101[100]` is **`0x8000`** — the
very literal the arms store in `B` for the MAIN slot.  So `B` is a **level array in the
`SUB GAIN` curve's own units**, with MAIN pinned at full scale, not a different kind of
number that happens to sit in the same array.

---

## 3. WHERE THE RESULT GOES: it is a DETUNE — PROVEN

The read-back loop and the packer, at the instruction (probe §3):

```
   FC6FC3  ld (XBC+0x12),WA      D[2k]   -> P_k[+0x12]
   FC6FD9  ld (XWA+0x14),BC      D[2k+1] -> P_k[+0x14]

   FC4DFA  ld DE,(XBC+0x12)      \
   FC4DFD  ld IX,(XBC+0x0a)       >  SatAsym(P[+0x0A] + P[+0x12] + d1) -> reg chan+0x0040
   FC4E9F  ld (XBC+0x02),HL      /                                        MAIN RESONATOR

   FC4EA9  ld DE,(XBC+0x14)      \
   FC4EAC  ld IX,(XBC+0x0c)       >  SatAsym(P[+0x0C] + P[+0x14] + d2) -> reg chan+0x0080
                                 /                                        SUB  RESONATOR
```

and `P[+0x0A]` / `P[+0x0C]` are built by `Pack104_ComputeTuningWords_0040_0080` from
`P[+0x0E]` / `P[+0x10]` — **the solver's own input `C[]`**.  So the block reads the
resonators' nominal tunings and returns a correction to them, in the same 1/256-semitone
unit.

★ **THE POSITIVE CONTROL IS IN THE FIRMWARE ITSELF.**  The three arms that *clear* the
`GROUP` field — the not-grouped case — write `P[+0x12] = P[+0x14] = 0x0000` and never call
the solver (0xFC6CC2/0xFC6CC7, 0xFC6D04/0xFC6D09, 0xFC6D46/0xFC6D4B).  A field that carries a
computed value when the layers are grouped and exactly zero when they are not is what a
coupling term looks like.

⚠ **AND THE TWO FIELDS HAVE A SECOND WRITER.**
`Pack104_UnpackWaveSelRec_ToSubRecord` sets `P[+0x12] = (p26 << 8) + p27` when `p25` bit 7 is
set (0xFC490A/0xFC4926) and `P[+0x14]` likewise from `p38`/`p39` (0xFC4942/0xFC495E) — the
per-tone *static* second term of the same two registers.  So the field's job is "the second
term of the tuning word", and `GROUP` **replaces** a static detune with a computed one.
⚠ Which of the two survives depends on the order in which the unpacker and the dispatcher
run, and **this lane did not establish that order**.  See §8.

---

## 4. WHAT THE SOLVER COMPUTES

### 4.1 Every magic constant is a named quantity in Q11 — PROVEN

`Multiply16_Signed_Shr11`, `Math_Sin_Q11`, `Math_Cos_Q11`, `Math_Atan_Q11` and
`Math_Exp2_Q11` all carry the scale `2048 = 1.0` from waves 7 and 19.  In that scale
(probe §4):

| literal | site | is | to |
|---|---|---|---|
| `0x0555` | 0xFC4316 | `2/3` = 2048/3072 — **octaves per 1/256-semitone unit** | 1365 vs 1365.33 |
| `0x1922` | 0xFC445B | `π` | 6434 vs 6433.98 |
| `0x3244` | 0xFC44D9 | `2π` — the phase-wrap modulus | 12868 vs 12867.96 |
| `0x0146` | 0xFC4658 | `1/2π` — radians → turns | 326 vs 325.95 |
| `0x0800` | throughout | `1.0` | exact |
| `0x1000` | 0xFC43ED | `2.0`, the product accumulator's seed | exact |

and the output table `MathTable_Log2_256` at `0xFE0CC9` is `T[k] = round(3072·(7 − log₂ k))`
over all 255 non-sentinel entries with error ≤ 1, read at index `(0x0800 − x) >> 4`.
**3072 = 12 × 256**, the same 1/256-semitone unit as everything else, so the returned value
is

```
    D = −3072 · log₂(1 − Δφ/2π)      in 1/256 semitone
```

i.e. the pitch offset of a frequency ratio `1/(1 − Δφ/2π)`.  ★ `T[128] = 0` exactly: the
null is built into the table.

### 4.2 The arithmetic, per output slot `j` — PROVEN

Probe §5 re-implements `sub_FC4269` line for line, every loop annotated with the instruction
range it stands for.  In closed form:

```
    Δoct_i = (C[j] − C[i]) · 2/3 / 2048,   folded down modulo one octave
    ω_i    = π · 2^Δoct_i                            0xFC435B, Math_Exp2_Q11
    a_i    = −(MODE/2048) · (A[i]/2048) · (B[i]/2048)
    damp   = 1 + a_j

    M(x)   = Σ over slots, where each slot m ≠ j contributes a factor
             sin(ω_m) at phase (π/2 − ω_m)  —  which is  (1 − e^{−2iω_m}) / 2

    undamped = 2·Π_{m≠j} c_m  −  Σ_{i≠j} a_i · e^{−2iω_i} · Π_{m∉{i,j}} c_m
    damped   = the same with the FIRST term multiplied by `damp`

    Δφ = arg(undamped) − arg(damped)               0xFC463A-0xFC4656
    D[j] = MathTable_Log2_256[ (0x800 − Δφ/2π) >> 4 ]
```

The magnitude/phase pair is carried in polar form throughout: `sin(ω)` is the magnitude and
`π/2 − ω` the phase, and `sin(ω)·e^{i(π/2−ω)} = (1 − e^{−2iω})/2` identically.  The phases
are reduced modulo `0x3244 = 2π` at 0xFC44CA-0xFC4552 before the final `cos`/`sin`.

### 4.3 ★ What that IS — STRONG, and it is a reading of exact constants

`e^{−2iω_m}` with `ω_m = π · f_j/f_m` is the round-trip phase of a **delay line one period
long at `f_m`, evaluated at `f_j`**.  The octave fold is what makes it exactly one turn:
folding `Δoct` into `[0, 1)` puts `f_j/f_m` in `[1, 2)`, so `2ω_m` sweeps `[2π, 4π)` — one
full revolution, no more and no less.  A factor `(1 − z^{−2})` per resonator and a term
`a_i z^{−2}` per coupling path is the **loop characteristic function of a network of coupled
waveguide resonators**; its argument vanishes at the network's true eigenfrequency; and the
phase error at the trial frequency, expressed as a fraction of a period, is exactly the
fractional pitch error, which is what the `log₂` table converts.

★ And `damp` is a **pole radius**: probe §4b shows `damp = 1 − k·G·L` with `G` the
`INTERACTION GAIN` in `[0, 1]`, `L` the slot's level in `[0, 1]`, and
**`k × (elements in the group) = 1.0` in both arms** (`0x0200 × 4 = 0x0400 × 2 = 0x0800`).
The `MODE` constant is the coupling normalised by the group size.  `damp` is confined to
`[0.75, 1]` for the four-element arm and `[0.5, 1]` for the two-element arms, and `1.0` — no
coupling — is precisely §5's null.

⚠ **GRADE.**  The *arithmetic* of §4.2 is PROVEN — it is a bit-exact re-implementation that
reproduces the ROM's own tables and its own factory data.  The *reading* in §4.3 is
**STRONG**: it rests on five independent exact constants (`2/3` making the tuning word an
octave, `π` and `2π` making the fold one round trip, `1/2π` making the phase a period
fraction, and `3072` making the answer a semitone) all agreeing on one picture, plus the
`k·N = 1` normalisation.  It is not a measurement, and no instruction says "waveguide".

---

## 5. THE NULLS, THE STEP AND THE RANGE — PROVEN

**NULL 1.**  `INTERACTION GAIN` = 0 gives `a_i = 0` for every slot and `damp = 0x0800 = 1.0`
*exactly*, so damped and undamped coincide, `Δφ = 0`, the index is 128 and `T[128] = 0`.
Verified for `N = 8` and `N = 4`, with spread and with equal tunings.

**NULL 2, independent of the first, and the one that matters for §6.**  When every resonator
carries the same tuning word, every `Δoct` is 0, every `ω = π`, and `Math_Sin_Q11(6433)`
reads back as **50** — 0.024 in Q11.  The accumulator multiplies `N−1` such factors through a
`>>11` truncation and underflows to zero.  `D = 0` at FULL gain, for both arms.

**POSITIVE CONTROL.**  `Fantasia`'s own two elements, whose tunings differ by 7 and 10
semitones, return `D = [−34, −34, 0, 0]` = **−13.28 cents** on element 0's MAIN and SUB.
Without it both nulls would be criteria that cannot fail.

**THE STEP.**  `T[127] = 34`, `T[128] = 0`, `T[129] = −34`.  One index step is **13.28
cents**: this correction *cannot be small*.  It is a pitch pull, not a fine tuning.

**THE RANGE, exhaustively.**  Sweeping all 65536 arguments of `Math_Atan_Q11` bounds its
output at 3088, so `Δφ ∈ [−6176, +6176]`, so the table index is confined to **66..189** and
the correction to **+1146 / −675 cents**.  ★ Index 0 — the `0xFFFF` log₂ **sentinel** — is
therefore **unreachable**, which is worth knowing before anyone "fixes" it.

⚠ **ONE REAL ROM DEFECT IS REACHABLE IN PRINCIPLE.**  `MathTable_Cos_256[0]` is `0x8000`,
which `Math_Cos_Q11` reads as `−2048`: `cos(0)` comes back as `−1.0`.  Any accumulated phase
below 0.0078 rad lands there.  The simulator reproduces the defect, and §6 reports that **no
factory tone that reaches this solver hits it**.

---

## 6. THE FACTORY POPULATION — with its denominator

⚠ **STATE THE DENOMINATOR.**  The counts below are over the **loose 256-tone / 459-record**
population.  `dev104_topology_probe.py`'s strict 133-record filter drops *every* tone that
uses `GROUP`, so no rate here may be quoted through it.

Eight tones reach the solver — the same eight wave 21 found, all pads, all passing that
lane's two independent framing invariants.  They generate **fourteen** solver calls, of which
**eight** have inputs the ROM determines completely; the other six run on element 3 of a
three-element tone, whose sub-record is not in any image, and are reported as *not computed*
rather than as zero.

| tone | `H` | call | `D`, cents |
|---|---|---|---|
| `Fantasia` | `0x2A` | `sub_FC6FFD`, N=4, el 0,1 | **−13.28 −13.28 +0.00 +0.00** |
| `Dream` | `0x2A` | `sub_FC6FFD`, N=4, el 0,1 | 0 0 0 0 |
| `Mist` | `0x2A` | `sub_FC6FFD`, N=4, el 0,1 | 0 0 0 0 |
| `Halo Pad` | `0x05` | `sub_FC6FFD`, N=4, el 0,1 | 0 0 0 0 |
| `Voxmosphere` | `0x2A` | `sub_FC6FFD`, N=4, el 0,1 | 0 0 0 0 |
| `Dark Universe` | `0xAA` | `sub_FC6D6E`, **N=8**, el 0-3 | 0 × 8 |
| `Goblins` | `0x2A` | `sub_FC6FFD`, N=4, el 0,1 | 0 0 0 0 |
| `Windy Sweep` | `0x2A` | `sub_FC6FFD`, N=4, el 0,1 | 0 0 0 0 |

**One of the eight determined calls returns a non-zero detune**, and it is the only `GROUP`
tone whose elements are not all identically tuned: `Fantasia`'s element 1 sits 7 and 10
semitones below element 0, so the octave differences are non-zero, the sines survive, and
element 0 is pulled −13.28 cents on **both** its resonators.  In the other seven tones every
tuning word is 0 and NULL 2 fires.

⚠ **THAT IS NOT "THE MECHANISM IS A VESTIGE".**  It is degenerate *input*, not a degenerate
routine, and the distinction is testable.  Over 4000 random tone-like draws — gains from the
real curve, `SUB GAIN` from the real curve, tunings uniform over ±2 octaves in semitones —
the arms return a non-zero correction in **78 %** (N=8) and **42 %** (N=4) of draws, with a
worst case of 1146 cents (`--reach`, seed 7).  What the factory set shows is that Technics
shipped `GROUP` presets whose resonators are tuned alike; the machine's own tone editor can
detune them, and then the block does something audible.

---

## 7. ★ WHAT THIS ADDS TO THE TOPOLOGY

`HLE-GUIDE-l7a1429.md` §0 describes two resonators, says how each is tuned and damped, and
says nothing about how they interact.  It now can:

* **They interact through their TUNINGS, in the firmware, before the chip sees anything.**
  There is no nineteenth register for coupling and none is needed: the coupling is folded
  into `chan+0x0040` and `chan+0x0080`, which the guide already models.  ★ **An emulator
  that implements the two tuning registers faithfully already implements the interaction**
  — provided the host computes `P[+0x12]`/`P[+0x14]`, which is firmware work, not device
  work.
* **`INTERACTION GAIN` (p19) now has two consumers, not one.**  Wave 21 proved it makes
  register `chan+0x0300` and that the gate on that register is the `GROUP` mode.  It *also*
  sets the pole radius of this solver, through the same curve, read at the same byte, in the
  three arms wave 21 already identified as the curve's only other citations.  ★ That is why
  the arms cite `Curve_Exp2Gain_U8_128`: not a coincidence of tables, a second use of the
  same control.
* **The coupling is scoped to the `GROUP`, and the group size is normalised out.**  Four
  elements grouped ⇒ coupling scale 1/4 each; two elements grouped ⇒ 1/2 each.
* **The interaction is between all four elements AND both resonators**, not just MAIN↔SUB:
  the solver's `N` slots are `2 × elements`, and every slot sees every other.
* **`P[+0x12]`/`P[+0x14]` now have a name**: *the second term of the tuning word* — a static
  per-tone detune from the wave-select record when `p25`/`p37` bit 7 is set, replaced by the
  computed coupling detune when the part is `GROUP`ed, and zero otherwise.

**What an HLE should do**, extending the guide's §5 rows for `0x0040` and `0x0080`:

```c
// registers chan+0x0040 (MAIN) and chan+0x0080 (SUB), in 1/256 semitone
//   = SatAsym( tuning_base  +  second_term  +  reso_scale_delta )
//   tuning_base   = Pack104_ComputeTuningWords_0040_0080 from P[+0x0E]/P[+0x10]
//   reso_scale_delta = the RESO SCALE arms (FINDINGS-l7a1429-reso-scale.md)
//   second_term:
//     GROUP off  ->  0
//     GROUP on   ->  coupled-resonator detune, sub_FC4269 (this note, section 4.2)
//     otherwise  ->  static (p26<<8)+p27 / (p38<<8)+p39 when p25/p37 bit 7 is set
// The detune is quantised to ~13.28 cents and bounded to +1146 / -675 cents.
// It is EXACTLY ZERO whenever INTERACTION GAIN is 0 or all grouped resonators
// share one tuning word -- which is true of seven of the eight factory GROUP tones.
```

---

## 8. WHAT IS STILL OPEN

1. ⚠ **The order of the two writers of `P[+0x12]`/`P[+0x14]`.**
   `Pack104_UnpackWaveSelRec_ToSubRecord` writes a static detune; the dispatcher's arms
   overwrite it (or zero it).  Which runs last per note, and whether the static term is
   therefore dead on every `GROUP`ed part *and on every ungrouped one too*, is a
   **sequencing** question this lane did not answer.  It is the cheapest remaining item:
   `FINDINGS-l7a1429-write-sequencing.md` already has the call graph.  Graded **OPEN**.
2. ⚠ **The waveguide reading of §4.3 is STRONG, not PROVEN.**  Five exact constants agreeing
   is a strong argument and not a measurement.  What would settle it is playing a `GROUP`ed
   tone with the two resonators tuned apart and measuring the pitch of the partials against
   §4.2's prediction — **and that needs the instrument, which is in storage abroad.**  This
   is the conclusion, not a next step.
3. The six solver calls whose inputs the ROM does not determine (element 3 of a
   three-element tone) would be settled by a live trace of the part record, not by more
   reading.

---

## 9. GRADES

| claim | grade |
|---|---|
| `sub_FC4269` is the block's reader; the address arrives as a call argument | **PROVEN** (probe §1, §7) |
| the block's layout: `MODE`, `N`, and four `N=8` arrays at `+4/+20/+36/+52` | **PROVEN** (§2) |
| slot `2k` is element `k`'s MAIN, slot `2k+1` its SUB | **PROVEN** (§2, §3) |
| `D[]` reaches registers `chan+0x0040` / `chan+0x0080` as an additive detune | **PROVEN** (§3) |
| the not-grouped arms write the same fields as literal zero | **PROVEN** (§3) |
| every constant in `sub_FC4269` is `2/3`, `π`, `2π`, `1/2π`, `1.0`, `2.0` in Q11 | **PROVEN** (§4.1) |
| the output table is `3072·log₂`, so `D` is 1/256 semitone | **PROVEN** (§4.1) |
| the arithmetic of §4.2, bit for bit | **PROVEN** (§4.2, `--selftest`) |
| `damp = 1 − k·G·L` with `k × group size = 1` | **PROVEN** (§4.3, probe §4b) |
| the step (13.28 cents), the range (+1146/−675), the sentinel unreachable | **PROVEN** (§5) |
| one of eight determined factory calls moves, and why | **PROVEN** (§6) |
| ★ the solver evaluates a **coupled-waveguide loop characteristic function** | **STRONG** (§4.3) |
| ★ the block is the `MAIN`↔`SUB` **interaction** the editor's caption names | **STRONG** — the mechanism is proven; that the caption `INTERACTION GAIN` names *this* as well as register `0x0300` inherits editor-pages' STRONG grade for the caption |
| which of the two writers of `P[+0x12]` survives | **OPEN** (§8.1) |
