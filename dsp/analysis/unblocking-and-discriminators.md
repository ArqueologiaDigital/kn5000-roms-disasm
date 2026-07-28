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

---

## 15. Speculation round 2: multi-LFO programs — the second oscillator inherits a saturated accumulator

**The speculation.** §14 left 8 of 19 ROM constants unreproduced. Looking at *which*:
**MODULATED CHORUS** carries steps 989 and 114 and reproduces only **989**; **MIX UP**
carries 570, 1407, 989 and reproduces only **570**. Every program that fully passes has
its LFOs at the *same* rate, where one working oscillator satisfies the test.

★ **So the pattern is: a program with LFOs at DIFFERENT rates runs only its FIRST.** The
obvious guess, given §10, was a second clobbering word.

### 15.1 ⛔ Not clobbering — SATURATION, and it is inherited

Tracing MIX UP's three LFO store words:

```
   w6   -> mem[0x02] = 570, 1140, 1710       ★ ramping correctly
   w10  -> mem[0x03] = 8388607 every frame     SATURATED
   w14  -> mem[0x04] = 8388607 every frame     SATURATED
```

`8388607 = 0x7FFFFF` is **the wrap word's own coefficient**. The three store words are
byte-identical (`0094A00200`); the first works because `acc` enters it at 0, and the
second and third inherit an accumulator the previous wrap word left holding the wrap
constant.

★ **The oscillators are not destroyed by another word — they are starved by the state
the previous oscillator leaves behind.**

### 15.2 ⛔ And no enumerated parameter fixes it

A phase accumulator wraps rather than saturating, and the coefficient `0x7FFFFF` is
literally a 23-bit mask, so `wrap` and `op2` were the natural candidates —
`op2 = "and_coef"` would make the wrap word compute `acc & 0x7FFFFF` exactly:

```
   wrap = sat / wrap23 / f31_2_and_coef / b7_and_coef   ->  11 / 11 / 11 / 11  of 19
   op2  = hold / and_coef / and_mask23                  ->  11 / 11 / 11  of 19
```

**Seven settings, all 11.** None touches the inter-block accumulator behaviour.

### 15.3 ★ The constraint this establishes

**MIX UP's ROM specifies three distinct LFO rates and MODULATED CHORUS two. The real
instrument runs all of them** — they are user-visible modulation rates on shipping
effects. The model runs one per program.

★ **So the accumulator's state at a wrap word's exit is wrong, and the error is in a
field that is not currently parameterised at all** — not `wrap`, not `op2`, not
`stgate`, all of which were varied. That is a *localisation*: the defect is in what
`f31 = 2` leaves in `acc` on a coefficient-consuming word, and the ROM's own rates say
what the answer has to permit.

This is the same shape as §10.3's mode-4 result — a known-mathematics constant refusing
to appear until a specific field behaves differently — but one level less resolved,
because there the option set contained a working value and here it does not.

### 15.4 Predict-then-check

- **P14 MISS.** I predicted a second clobbering word. It is saturation inheritance.
- **P15 MISS.** I predicted `op2 = "and_coef"` would restore the wrap, since the
  coefficient is exactly the mask. 11 of 19, unchanged.
- ★ **P16 the useful residue.** Both misses converge on the same localisation: the
  accumulator hand-off *between* LFO blocks, which no current parameter models. **The
  next parameter this machine needs is one nobody has written yet.**

---

## 16. Does §15 decode an instruction? — **No**, and the near-miss shows why

§15 localised a defect to "what `f31 = 2` leaves in `acc`". The natural follow-up: the
wrap word's gate already clears `acc`, and then its own ALU reloads `P` (= `0x7FFFFF`)
into it — so whether the clear lands **before or after** the ALU is exactly what
`sttime`/`stgate` control, and both had been fixed in every run so far.

### 16.1 The enumeration

All 3 × 6 = 18 `sttime` × `stgate` combinations, scored against the 19 ROM ramp
constants:

```
   sttime = before,  stgate = b7_f31_1_off        11   (baseline)
   sttime = before,  stgate = b7_ne2_off          11
   sttime = before,  stgate = b7_f31_1_keepclear  12   <- the only one above baseline
   everything else                                <11
```

### 16.2 ⛔ Why 12 is not a decoding

The 12 is a **trade, not a gain**:

```
   baseline (11)  : CHORUS, MOD CHORUS, FLANGER, PHASER, ENSEMBLE, AUTO PAN,
                    VIBRATO, MIX UP, S.DELAY+{CHORUS,FLANGER,PHASER}
   keepclear (12) : the same MINUS MIX UP, PLUS PEQ+CHORUS and PEQ+FLANGER
```

**+2 −1.** And it does not touch §15's constraint at all: MODULATED CHORUS still runs
only 989 of its two rates, and MIX UP now runs **none** of its three.

⛔ **A criterion that trades is not a forcing.** One net constant out of nineteen,
bought by breaking a program that previously worked, is exactly the kind of margin this
project has learned not to read as evidence — and the option was reached by *scoring*,
not by any argument that `keepclear` is what the hardware does.

### 16.3 What §15 actually gives, stated exactly

* ✅ **A localisation.** The accumulator hand-off between LFO blocks is wrong, and the
  ROM's own modulation rates are the criterion that says so.
* ✅ **An exhausted option set.** `wrap` (4), `op2` (3), `sttime` × `stgate` (18) — **25
  settings**, none of which makes a second oscillator run at its ROM rate.
* ⛔ **Not a decoding.** Nothing here determines a field. The missing behaviour is not
  in any enumerated option, so the honest position is that the machine needs a field it
  does not yet have — §15.4's P16, now with 25 settings behind it rather than 7.

**Contrast with §10.3**, which *was* a result: there the option set contained a value
that reproduced a ROM constant exactly (+228/frame) while the refuted value reproduced
none, and the regression control held. Here no option reproduces the constants at all.
The difference between "we refuted an option" and "we decoded a field" is exactly this,
and it is worth keeping sharp.

---

## 17. ★★★ YES — an `f31 = 2` word does NOT update the product register

§16 answered "does §15 decode an instruction?" with **no**. §17 answers it with **yes**,
for one field, and the difference between the two is exactly the difference §16.3 drew.

### 17.1 The mechanism, traced rather than scored

MIX UP's accumulate and wrap words are **one instruction with one field changed**:

```
   w4   0092A00200   hi12 = 092, f31 = 1   lo12 = 200   coef  570   ACCUMULATE
   w6   0094A00200   hi12 = 094, f31 = 2   lo12 = 200   coef  8388607   WRAP + STORE
```

Identical `lo12`, identical `ACT 0x00`, identical `SRC 0x08`. Tracing the accumulator
across the first two LFO blocks shows **two** leaks, not one:

* the wrap word's gate clears `acc`, and then `ACT 0x00` **adds the bus** — which on
  that word is the wrap coefficient `0x7FFFFF`;
* the next word (`f31 = 0`, `acc = P`) picks up the **stale `P`** that the wrap word's
  multiply left behind.

### 17.2 Two candidate fields, and only one matters

```
   f2_act00   f2_prod    ROM constants     change vs baseline
   apply      compute        11            (baseline)
   suppress   compute        11            none
   apply      skip       ★   14            +3, NO losses
   suppress   skip       ★   14            +3, NO losses
```

★★★ **`f2_prod = "skip"` — an `f31 = 2` word does not write `P` — gives 14 of 19
against 11, and every baseline constant is retained.** Not a trade (§16.2), a strict
superset.

⛔ **`f2_act00` is NOT determined**: `apply` and `suppress` score identically. The
ACT-0x00 leak is real in the trace but is not what the LFOs can see.

### 17.3 It fixes the structural problem that motivated it

```
   MODULATED CHORUS   [989]        ->  ★ [114, 989]     BOTH rates
   MIX UP             [570]        ->  ★ [570, 989]     2 of 3
   S.DELAY+VIBRATO    -            ->  ★ [760]          new
```

§15's constraint was *"a program with LFOs at different rates runs only its first."*
Under `skip`, MODULATED CHORUS runs both. **The field was predicted from a mechanism
and then confirmed by the criterion that named the problem.**

### 17.4 Three controls, all passed

| control | `compute` | `skip` |
|---|---|---|
| SINGLE DELAY (validated: lag 1001, +0.02149296) | exact | **exact** |
| execution coverage | 88 complete, 98.6 % | **identical** |
| PARAMETRIC EQ biquad, worst-case | 0.198 dB | **0.198 dB** |

★ The biquad **neither confirms nor refutes** — its section contains only **1** `f31 = 2`
word of 9, so it is nearly blind to the field. Stated rather than counted as support:
**the LFO is the sole anchor for this result.**

### 17.5 Status

**MEASURED**, anchored on the LFO ramp constants alone, with the biquad blind and the
delay context unaffected. Strength: 14 of 19 versus 11, no losses, across 12 distinct
programs, plus a mechanism identified before the score was taken.

⛔ **Not applied to the device.** It should be, but only after the remaining 5 constants
are understood — RING MODULATOR (190217), MIX UP's third rate (1407), PEQ+CHORUS,
PEQ+FLANGER, PEQ+VIBRATO — since a field that explains 14 of 19 may still be one
refinement short of the real rule.
