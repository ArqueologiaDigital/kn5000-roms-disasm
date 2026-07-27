# The unblocking programme — and the discriminators it revealed

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
Static analysis and simulation. **Every ALU reading used here is SPECULATIVE.**

**Why this note exists.** [`single-delay-restored.md`](single-delay-restored.md)
§10.4 established that only **3 of 38** images executed at all, so every
execution-based result in this project had a denominator of three — including the
census that found **zero** discriminators for `ACT 0x0D`/`0x0E`. This note lifts the
execution blockers and re-runs that census over the corpus.

Labels: **MEASURED** / **SPECULATIVE** / **OPEN**.

---

## 0. Result

| # | statement | label |
|---|---|---|
| **A** | ★★★ **THE CORPUS NOW EXECUTES: 2 of 38 → 36 of 38 images run to completion, and mean execution goes 12.7 % → 98.0 %.** Achieved by giving each execution blocker an *enumerated* behaviour, not by decoding it. | **MEASURED** (of a **SPECULATIVE** machine) |
| **B** | ★★ **The one validated answer is unchanged at every stage.** SINGLE DELAY still emits lag **1001**, gain **+0.02149296** — the three-factor ROM-coefficient product matched to 0.001 % in `single-delay-restored.md` §5.2. **Not one addition perturbs the only program with an independently known answer.** | **MEASURED** |
| **C** | ⚠️ **QUALIFIED BY §6 — most of this separation is TRANSIENT.** 21 of 38 images DISCRIMINATE the `ACT 0x0D` × `ACT 0x0E` readings** — where the same census over the 3 executable images found **ZERO**. AUTO PAN separates **18 of 25** machines; PEQ+COMPR+DIST **16**; COMPRESSOR and PHASER **10** each. | **MEASURED** |
| **D** | ★★★ **And the top two are ROBUST.** AUTO PAN holds **18** across three alternative `altlo12` settings, three `cfmt` settings, and **with a real single-cell input instead of the fake input plane**. PEQ+COMPR+DIST holds **16** invariantly under all of them. Their discrimination is a property of the **program**, not of the speculative choices or the fake input. | **MEASURED** |
| **E** | ⛔ **ROOM REVERB's discrimination is NOT robust** — 6 signatures on the fake input plane, **1** on a real input. That one was an artefact, and it is named rather than buried. | **MEASURED** |

---

## 1. The unblocking programme

Each blocker gets a parameter defaulting to `None` = **REFUSE**, so every existing
tool's gated behaviour is untouched. Adding readings one at a time:

```
   stage             completes   mean exec   top remaining blocker
   baseline           2 of 38      12.7 %    alt lo12 (bit 11) : 25
   + altlo12          2 of 38      20.2 %    hi12[3:1] > 2     : 23
   + f31hi           11 of 38      50.1 %    c-format          : 17
   + cfmt = acc      17 of 38      61.7 %    ACT 0x01          :  9
   + act08/0C/11     23 of 38      73.3 %    ACT 0x01          : 13
   + act01/16      ★ 36 of 38    ★ 98.0 %    (two left)
```

Still blocked: **MULTI TAP DELAY `w52`** — a *missing coefficient*, the 83rd
unaligned algorithm, not an opcode — and **ROCK ROTARY `w42` = `02122BE41D`**,
`ACT 0x1D`, one further unmodelled action.

★ **`altlo12` alone buys 7.5 points of execution depth but zero completions.** It is
the #1 *first* blocker (25 of 38, 21 at `w000`) yet lifting it only moves the wall to
`hi12[3:1] > 2`. **Blocker rank by first-stop is not the same as blocker rank by
leverage**, and the ranked list in `single-delay-restored.md` §10.2 measures the
former.

## 2. What is and is not claimed

⛔ **These readings are not decoded semantics.** `altlo12 = "nop"` executes the
addressing — which *is* decoded — and applies no ALU effect; `cfmt = "acc"` picks one
of six enumerated destinations for an immediate whose destination `dsp_disasm.status()`
already calls OPEN; the six ACTION parameters are enumerated guesses.

★ **What they buy is that the corpus RUNS**, which is the precondition for every
discrimination test, and which nothing else has delivered. §0 item B is the guard: the
one program with an independently known answer still produces it, exactly.

## 3. The discriminator census, re-run

```
   distinct signatures over the 25 (act0d x act0e) readings, per image

      18  AUTO PAN            7  MIX UP            4  MODULATED CHORUS
      16  PEQ+COMPR+DIST      7  VIBRATO           4  NO OPERATION
      10  COMPRESSOR          6  RING MODULATOR    3  PEQ+DIST+DELAY
      10  PHASER              6  EXCITER           3  PEQ+VIBRATO
       8  PEQ+COMPRESSOR      6  ROOM REVERB 1     3  S.DELAY+S.DELAY
       7  AUTO WAH+S.DELAY    6  FLANGER
                              6  CHORUS            ... 21 images with > 2
```

★★★ **Twenty-one discriminators, where three programs gave zero.** The earlier
"nothing in the corpus constrains `ACT 0x0D`" was a statement about a corpus that
could not execute.

## 4. Robustness — the control that matters

The census ran on a speculative machine **and** a fake input plane, so both had to be
varied:

```
   algo program            base   altlo12(x3)  f31hi(x3)  cfmt(x3)   REAL input
    48  AUTO PAN            18    18/18/18     18/13/8    18/18/18      18
    96  PEQ+COMPR+DIST      16    16/16/16     16/16/16   16/16/16      16
    36  COMPRESSOR          10    10/10/10     10/10/10   12/10/10       8
     5  PHASER              10    10/10/10     10/10/10   10/10/10       7
    16  ROOM REVERB 1        6     6/6/6        6/6/6      6/8/6         1   <- artefact
```

★ **AUTO PAN and PEQ+COMPR+DIST keep their full separation under every alternative
and on a real input.** ⛔ ROOM REVERB does not — its apparent discrimination was the
fake plane, and it is reported as such.

## 5. What the next pass needs

1. ★★★ **AUTO PAN is the instrument this project has been missing.** 18 of 25
   readings separated, robust to every speculative choice tested, and it is one of the
   **16 LFO-bearing images** — so a *known-mathematics* reference sits inside the same
   program that discriminates.
2. **Discrimination is not yet adjudication.** Knowing the readings differ says
   nothing about which is right. The next instrument must *score* AUTO PAN's 18
   classes against something known — its LFO block is the candidate.
3. ⛔ **Do not treat §1's readings as results.** They are scaffolding that makes the
   corpus executable; each still needs deciding on its own evidence.
4. **Two blockers remain**: MULTI TAP DELAY's missing coefficient and `ACT 0x1D`.

---

## 6. ⚠️ QUALIFICATION — most of the separation is transient, and the delay line never varies

§0 items C and D counted **distinct signatures**, and the signature bundled three
different kinds of state. Splitting it is the check that item C needed and did not
get:

```
   algo program            DRAM writes   persistent memory   end-of-frame registers
    48  AUTO PAN            1 distinct       3 distinct           14 distinct
    96  PEQ+COMPR+DIST      1 distinct       3 distinct           16 distinct
    36  COMPRESSOR          1 distinct       2 distinct           10 distinct
     5  PHASER              1 distinct       3 distinct            7 distinct
     9  SINGLE DELAY        1 distinct       2 distinct            1 distinct
```

`acc`, `tA` and `tB` are **reset at every frame boundary**. Whatever they hold at the
end of a frame is transient and reaches no observable.

★ **So AUTO PAN's "18" decomposes as 1 × 3 × 14, and the 14 is transient.** The
**observable** discrimination is **3 classes, not 18** — and correspondingly 3 for
PEQ+COMPR+DIST, 2 for COMPRESSOR.

### 6.1 What survives, honestly

* ⛔ **The headline count in §0 item C overstates the usable separation by roughly
  six-fold.** Stated plainly rather than buried.
* ★ **But it is still not zero.** Observable classes go from **1** (what the 3-image
  census could see) to **2–3** across several programs. There *is* persistent,
  observable behaviour that depends on the reading — which is what §3 set out to find,
  just far less of it than the raw count suggested.
* ★★★ **And the DRAM-write column is 1 in every program tested.** No reading of
  `ACT 0x0D`/`0x0E` changes what is written to the delay line, anywhere. That
  **generalises `single-delay-restored.md` §5.5** from "the emitted amplitude is
  invariant" to *"the entire delay-line traffic is invariant"* — a stronger and more
  useful statement of why these codes resist execution-based tests.

### 6.2 And AUTO PAN's LFO does not run

Under DC input, over 9 000 samples (24.5 % of an LFO cycle), **zero of AUTO PAN's
memory cells change at all**, under every `f31hi` setting. The LFO's phase
accumulator should ramp by 228 per sample. It does not ramp; nothing persists.

⛔ **So AUTO PAN cannot yet serve as the known-mathematics instrument §5 hoped for**,
because its known mathematics — the LFO — is not running in this harness. Why the
accumulator does not persist is **OPEN** and is the first thing the next pass should
establish.

## 7. Handover

1. ★★ **The unblocking programme stands** (§1): 36 of 38 images execute, 98.0 % mean
   execution, and SINGLE DELAY's validated answer is untouched. That is real and
   reusable regardless of §6.
2. ⚠️ **Discrimination is 2–3 observable classes, not 18** (§6). Still an improvement
   on 1, still not adjudication.
3. ★★★ **The sharpest new fact is the invariant delay-line traffic** (§6.1). Any
   future instrument for these codes must look at something other than what reaches
   the delay line, because that is provably the same under every reading.
4. **First concrete task: find why no state persists across frames in AUTO PAN**
   (§6.2). Until the LFO ramps, the one program that combines discrimination with
   known mathematics cannot be used.

---

## 8. ★ Why the LFO does not run — and it partly dissolves AUTO PAN's headline

§6.2 left "why does no state persist in AUTO PAN" as the next task. Answered.

### 8.1 The cause was a fixed parameter of mine, again

`src08` decides the multiplier's other input for `SRC 0x08` words. My harness left
it at its **default `"unity"`**, which makes `P = MASK23` — and that **saturates the
accumulator on the LFO's very first word**. Tracing the block with a seeded prior
phase of 1000:

```
   src08 = "unity"   w16 acc -> 8388607 (saturated)   ...  mem[0x04] = 8388607
   src08 = "coef"    w16 acc ->     228               ...  mem[0x04] =    1228   ★
```

★ **With `src08 = "coef"` the block reproduces the ROM's own step exactly: 1000 →
1228, a step of +228 = the coefficient `0x0000E4`** that `lfo_ramp.py` derives from
`floor(f × 2²³/44100)`. The LFO's known mathematics is reproduced.

**Method rule 2, for the third time this session** — and the third time the culprit
was a parameter I had left at a default rather than enumerated.

### 8.2 ⚠️ But in the FULL program the phase still stays zero

Over 2 000 frames of the complete 50-word AUTO PAN, cell `0x04` never leaves 0: the
per-frame step is `0` in 1 999 of 1 999 transitions. The isolated block ramps; the
whole program does not. **Some later word clobbers the phase cell, and which one is
OPEN.**

### 8.3 ⚠️⚠️ And this dissolves part of §0 item D

Re-running the observable/transient split under both `src08` settings:

```
   algo program            src08=unity (D/M/R)   src08=coef (D/M/R)
    48  AUTO PAN               1 / 3 / 14           1 / 2 /  1     <- COLLAPSES
    50  VIBRATO                2 / 4 /  5           1 / 2 /  1     <- COLLAPSES
     5  PHASER                 1 / 3 /  7           1 / 3 /  3     <- partly
    96  PEQ+COMPR+DIST         1 / 3 / 16           1 / 3 / 16     ★ UNCHANGED
    36  COMPRESSOR             1 / 2 / 10           1 / 2 / 10     ★ UNCHANGED
     9  SINGLE DELAY           1 / 2 /  1           1 / 2 /  1
```

⛔ **AUTO PAN's 18 was substantially an artefact of a saturating accumulator.** §0
item D reported it as robust because the settings I varied did not include `src08` —
a control gap, and the exact failure mode this project keeps hitting.

★ **PEQ+COMPR+DIST and COMPRESSOR are unchanged under both settings.** They, not
AUTO PAN, are the robust discriminators.

★★★ **And `D = 1` in every program under both settings.** The delay-line traffic is
invariant under every reading — now confirmed across two independent `src08`
settings, which makes §6.1's generalisation of `single-delay-restored.md` §5.5 the
firmest result in this note.

## 9. Revised handover

1. ★★★ **The unblocking programme is the durable result** (§1): 36 of 38 images
   execute, 98.0 % mean execution, SINGLE DELAY's validated answer exact throughout.
2. ★ **The robust discriminators are PEQ+COMPR+DIST (16) and COMPRESSOR (10)** — not
   AUTO PAN (§8.3). Any adjudication attempt should start there.
3. ★ **`src08 = "coef"` reproduces the LFO's ROM step of 228 exactly** (§8.1) and is
   a known-mathematics anchor the harness should carry by default.
4. ⚠️ **OPEN: which word zeroes AUTO PAN's phase cell in the full program** (§8.2).
5. ★★★ **The delay-line traffic is invariant under every reading of `ACT 0x0D`/
   `0x0E`.** Any future instrument must look elsewhere; this is now checked under two
   `src08` settings and 25 readings across six programs.
6. ⛔ **Every count in §§3–4 was taken at `src08 = "unity"`** and must be re-derived
   before being quoted.

---

## 10. ★★★ The word that kills the LFO — and a FUNCTIONAL refutation of the mode-4 store target

§8.2 left "which word zeroes AUTO PAN's phase" open. Logging every memory write in
one full frame answers it, and the answer lands on a word this project had already
singled out.

### 10.1 First, a measurement error of mine

The LFO phase does **not** live at `mem[0x04]`. In the *full* program the pointer at
the store word is `0x0D` (and `0x0E` for the second LFO); `0x04` was the value in an
isolated run that started at `w14`. **§8.2's "the phase stays 0" was watching the
wrong cell.** The phase does get written — 228, on schedule — and is then destroyed.

### 10.2 The killer

```
   w18  094.A.00.200   writes mem[0x0D] = 228     <- the LFO phase, correct
   w25  012.4.01.1CE   writes mem[0x0D] = 0       <- ★ destroyed
   w31  094.A.00.200   writes mem[0x0E] = 228     <- the second LFO
   w38  012.4.01.1CE   writes mem[0x0E] = 0       <- ★ destroyed
```

★ **`012.4.01.1CE` is exactly the word [`dark-words.md`](dark-words.md) §4.4 Group E
calls "a known-mathematics lever … the cleanest possible probe of what class 4
changes."** That prediction is now vindicated from an entirely different direction:
it is the word that decides whether the chip's oscillators can run at all.

### 10.3 ★★★ The functional refutation

`class4 = 4` ⇒ `mode 4`, and `do_store()`'s own comment reads
*"modes 0/4/5: only 4 words, **OPEN**"*, defaulting the target to `st.p`. Making that
target a parameter and asking the ROM's own mathematics:

```
   mode4dest    LFO phase after 400 frames    per-frame step   verdict
   "ptr"                       0              0                flat -- phase destroyed
   "addr8"                 91200              +228             ★ RAMPS AT THE ROM STEP
   "none"                  91200              +228             ★ RAMPS AT THE ROM STEP
```

**228 = `0x0000E4` = `floor(1.1986 Hz × 2²³ / 44100)`** — `lfo_ramp.py`'s own
derivation, and 91 200 = 228 × 400 exactly.

★★★ **`mode 4` does NOT store to `mem[st.p]`.** If it did, `012.4.01.1CE` would zero
the LFO phase every frame and AUTO PAN could not pan — which the instrument
demonstrably does. This is a **functional refutation of one of the three options for a
target the code itself marks OPEN**, from a program whose known mathematics says what
must happen.

### 10.4 Controls, and what is NOT claimed

* **Regression: SINGLE DELAY is unchanged under all three settings** — lag **1001**,
  gain **+0.02149296**. The one program with an independently known answer does not
  move.
* ⚠️ **The test does NOT separate `addr8` from `none`.** Both preserve the phase
  identically. This is a **refutation of one option, not a determination** — and it is
  labelled that way.
* The result depends on `src08 = "coef"` (§8.1), which is itself justified by the same
  LFO mathematics, so the two stand or fall together.

## 11. Handover, revised again

1. ★★★ **`mode 4` store target ≠ `mem[st.p]`** (§10.3) — the first *functional*
   constraint this project has put on that field. Separating `addr8` from `none` needs
   a program where they differ; finding one is a well-posed next task.
2. ★★ **The unblocking programme** (§1): 36 of 38 execute, 98.0 %.
3. ★ **`src08 = "coef"`** reproduces the LFO's ROM step and should be the harness default.
4. ★ **Robust discriminators: PEQ+COMPR+DIST (16) and COMPRESSOR (10)**, not AUTO PAN.
5. ★★★ **Delay-line traffic is invariant under every reading of `ACT 0x0D`/`0x0E`.**

---

## 12. Eight oscillators now run at their ROM rates — and the mode-4 determination still does not follow

### 12.1 ★★ The LFO corpus, scored — ⛔ **the counts here are CORRECTED in §14; my own input injection was depressing them**

With `src08 = "coef"` and `mode4dest ≠ "ptr"`, the per-frame step of each program's
phase cell is measured and compared against the ramp constant `lfo_ramp.py` derives
from the ROM:

```
   algo program            ROM step   reproduced
     1  CHORUS                  114       ★ 114
     4  FLANGER                  38       ★  38
     5  PHASER                   76       ★  76
     6  ENSEMBLE                114       ★ 114
    48  AUTO PAN                228       ★ 228
    50  VIBRATO                 760       ★ 760
    56  MIX UP           570/989/1407     ★ 570  (1 of 3)
    68  S.DELAY+PHASER          114       ★ 114

   not reproduced: MODULATED CHORUS, RING MODULATOR, S.DELAY+CHORUS,
                   S.DELAY+FLANGER, S.DELAY+VIBRATO, PEQ+CHORUS,
                   PEQ+FLANGER, PEQ+VIBRATO                    11 of 19 steps
```

★★ **Eight distinct oscillators, in eight different programs, stepping at exactly the
rate their own ROM coefficient specifies.** That is a far broader known-mathematics
validation than the single AUTO PAN case in §10 — and it was not available at all
before §1's unblocking, because none of these programs executed.

### 12.2 ⛔ But the mode-4 target is still not determined

```
   ROM ramp steps reproduced:   mode4dest = "addr8"  8 of 19
                                mode4dest = "none"   8 of 19
```

**Identical.** 19 of 26 images *do* behave differently under the two (§11 task), so
the corpus can see a difference — but the difference does not reach the LFO, which is
the only known-mathematics scorer available. ⛔ **`"ptr"` stays refuted (§10.3);
`"addr8"` versus `"none"` stays OPEN**, and the honest statement is that the
instrument that separates them has not been found, not that the two are equivalent.

### 12.3 The 11 failures are structured

Every failure is a **combination** effect (`S.DELAY+…`, `PEQ+…`) or one of two
singletons (MODULATED CHORUS, RING MODULATOR). The plain single-effect LFOs all pass.
That is a lead: whatever the combination programs do differently — a second unit, a
different entry pointer, a shared phase cell — is a narrower question than "why does
the LFO fail", and it comes with 8 working cases to compare against.

## 13. Session handover

**Durable results**

1. ★★★ 36 of 38 images execute (was 2), 98.0 % mean execution (was 12.7 %).
2. ★★★ `mode 4` does **not** store to `mem[st.p]` — functionally refuted (§10.3).
3. ★★ Eight LFOs reproduce their ROM ramp constants exactly (§12.1).
4. ★★ `src08 = "coef"` is required for any of it and is itself justified by those
   constants.
5. ★★★ Delay-line traffic is invariant under every reading of `ACT 0x0D`/`0x0E`
   (§6.1), checked under two `src08` settings, 25 readings, six programs.
6. ★ SINGLE DELAY's validated answer — lag 1001, gain +0.02149296 — is **unchanged by
   every change in this note**, and was checked at every stage.

**Open, in priority order**

1. Separate `mode4dest` `"addr8"` from `"none"`: 19 images differ observably (§11) but
   the LFO cannot score them (§12.2).
2. Why the 11 combination-effect LFOs do not ramp (§12.3).
3. The robust discriminators PEQ+COMPR+DIST and COMPRESSOR remain unscored.
4. ⛔ Every reading in §1 is scaffolding, not a decoding, and still needs its own
   evidence.

---

## 14. Speculation round: the entry pointer — refuted, and it exposed two harness defects

**The speculation.** SINGLE DELAY needed `p0 = 0x08`; every other program was run at
`p0 = 0`. If entry pointers are per-program, and the LFO's ROM constant is a known
answer, then *sweeping `p0` should DETERMINE each program's entry pointer* — turning a
guess into a measurement.

### 14.1 ⛔ Refuted, cleanly

Sweeping `p0` over all 256 values for each of the 16 LFO-bearing images:

```
   programs whose ROM step is reproduced at p0 = 0 ........ 11
   programs whose ROM step is reproduced at SOME p0 ....... 11   (no gain)
   typical number of p0 values that work ................. 254 of 256
```

★ **The LFO is insensitive to the entry pointer** — 254 of 256 values reproduce the
constant. So it cannot determine one, and the speculation is dead as stated. **A
parameter that almost nothing depends on cannot be measured by the thing that does not
depend on it.**

### 14.2 ⚠️ But the sweep exposed a defect in §12 — the input injection was corrupting the programs

§12 reported **8 of 19**. This round reported **11**. The only difference was that §12
drove `mem[0x00]` **and** `mem[0x03]` every frame, and `0x03` is *program state* in
three images. Isolated:

```
   cells driven every frame   mode4dest=addr8   =none   =ptr
   0x00 + 0x03  (sect. 12)          8 of 19        8       5
   0x00 only                       11 of 19       11       8
   nothing at all                  11 of 19       11       8
```

⛔ **Writing `mem[0x03]` every frame destroys three programs' oscillators**
(MODULATED CHORUS, S.DELAY+CHORUS, S.DELAY+FLANGER). Verified sustained at NF = 30,
120 and 300 — 299 of 299 transitions at the exact ROM step once `0x03` is left alone.

★ **And driving nothing at all scores the same as driving `0x00`** — correct, and
obvious in hindsight: *an oscillator needs no audio input*. The injection was pure
downside.

**§12.1's "eight oscillators" is corrected to ELEVEN**, in eleven distinct programs:
CHORUS 114, MODULATED CHORUS 989, FLANGER 38, PHASER 76, ENSEMBLE 114, AUTO PAN 228,
VIBRATO 760, MIX UP 570, S.DELAY+CHORUS 114, S.DELAY+FLANGER 114, S.DELAY+PHASER 114.

### 14.3 ★ And it strengthens the mode-4 refutation

`ptr` scores **3 fewer ROM constants than `addr8`/`none` in every one of the three
injection settings** — 5 vs 8, 8 vs 11, 8 vs 11. §10.3 refuted `ptr` on one program's
inability to pan; it is now refuted on a corpus-wide count of reproduced ROM constants,
robust to how the input is driven.

⛔ **`addr8` versus `none` remains identical in all three settings.** Still OPEN, still
not equivalent — just not separated by this instrument.

### 14.4 Predict-then-check

- **P12 MISS.** The entry pointer is not determinable from the LFO — 254 of 256 values
  work.
- **P13 unforeseen, and the useful part.** The refuted sweep exposed that my own input
  injection had been suppressing three oscillators and depressing every count in §12.
- ★ **Both of this round's defects were in the harness, not the chip** — the fourth and
  fifth such this session, and the pattern is now unmistakable: *what I inject is as
  much a modelling choice as what I decode, and it needs enumerating too.*
