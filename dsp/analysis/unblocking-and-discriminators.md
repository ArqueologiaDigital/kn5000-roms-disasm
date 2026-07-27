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
