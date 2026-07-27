# `hi12[3:1] > 2` — the accumulator's undecoded operations, and what can decide them

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis and the ROM corpus only.

**Why this note exists.** [`act0b-reverb.md`](act0b-reverb.md) §4 sized this
field for the first time: `step()` decodes `hi12[3:1]` for **0, 1 and 2** and
refuses **3..7** — **203 of 3154** corpus words, **31** of them otherwise fully
anchored and trapping for this reason alone. It is also what blocks the
`ACTION 0x0B` minimal pair, the one site in the corpus with known mathematics
downstream. Decoding it was ranked above the `ACTION 0x0B` question it gates.

**It is not decoded here.** What this pass delivers is a structural lead, an
enumerable parameter, and — the useful part — a demonstration of which
instruments *cannot* settle it and why.

Tool: [`../tools/f31_high.py`](../tools/f31_high.py).

```
python3 dsp/tools/f31_high.py shape     # is bit 2 an independent modifier?
python3 dsp/tools/f31_high.py biquad    # ★ the control that cannot fail
python3 dsp/tools/f31_high.py census    # the decidability census
```

**POPULATION (rule 9):** the **40 distinct body images, 3154 words**.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **CONSISTENT** /
**FALSIFIED** / **OPEN**.

---

## 0. Result

| # | statement | label |
|---|---|---|
| **A** | ★★ **THE FIELD IS NOW ENUMERABLE.** `Machine.f31hi`, four readings (`base`, `negP`, `hold`, `prod`), each mapping `f` to *(take the accumulator as feedback?, product term ∈ {P, −P, 0})*. **`f31hi = None` keeps the historical refusal**, so the default is exactly the old behaviour and no published number moves — verified by `delayline.py`'s seven self-tests, `migrate` (the published-number reproduction) included. | **MEASURED** |
| **B** | ★★ **BIT 2 LOOKS LIKE AN INDEPENDENT MODIFIER OVER THE SAME BASE OPERATIONS — for bases 0..2, and only those.** Relative frequencies, normalised to base 0: `bit2=0` gives **1.000 / 0.997 / 0.213** / 0.040 and `bit2=1` gives **1.000 / 0.983 / 0.203** / 0.356. Bases 0, 1 and 2 track to three digits across a 20-fold difference in sample size. | **MEASURED**, offered as a **lead** |
| **C** | ★ **AND THE SAME TABLE REFUTES IT AS A COMPLETE ACCOUNT.** Base 3 occurs **21** times in the `bit2=1` half against **2.6** expected from the other half's shape; `chi2 = 129.6` on 3 df is driven almost entirely by that one cell. A pure modifier cannot change how often its base occurs, so whatever bit 2 does, `f = 7` is not simply `f = 3` with a flag. | **FALSIFIED** (as a complete account) |
| **D** | ★★★ **THE BIQUAD CANNOT DECIDE THIS FIELD, AND IT IS A CONTROL THAT CANNOT FAIL.** PARAMETRIC EQ carries four `f>2` words, two in an identical structural position — `f=1`, then `f=5`, then a store of the accumulator to `mem[ptr]`, immediately before a biquad copy. Prepending that stage and scoring against the designer gives **0.198 dB for all four readings — exactly the baseline with no prefix at all.** | **MEASURED** |
| **E** | ★★★ **AND THE REASON IS VISIBLE WITHOUT RUNNING IT: PEQ's biquad BEGINS with an `f31 = 0` word** (`acc ← P`), which **discards the accumulator**. Nothing upstream that only touches `acc` can be observed through it. The store at `w004` does see the difference — it writes `acc` to `mem[ptr]` — but `w004` post-increments the pointer by `0x40`, so the biquad reads a different cell and the value is never read back. **Third control that could not fail in one day**, and the same barrier [`action00-discriminator.md`](action00-discriminator.md)'s census names. | **PROVEN BY CONSTRUCTION** |
| **F** | ★★ **THE DECIDABILITY CENSUS.** Of the 203 words, **92 are BLIND** — an `f31 = 0` word overwrites the accumulator before anything reads it — and **111 can carry a difference to an observable** (66 first reach a word that reads the accumulator, 45 first reach a store). | **MEASURED** |
| **G** | ★★ **AND `OBSERVABLE' IS NECESSARY, NOT SUFFICIENT** — a refinement the `ACTION 0x00` census did not need. PARAMETRIC EQ's three observable sites all reach a **store**, and a store only decides anything if the cell is read back, which for `w004` it is not (item E). Counting reachability without checking the read-back would have declared PEQ a usable context; it is not. | **MEASURED** |
| **H** | **In the programs with independently known arithmetic:** PARAMETRIC EQ **3** observable, **AUTO PAN 4**, SINGLE DELAY **0**, CHORUS **0**. | **MEASURED** |
| **I** | **NOT DECODED, NOT APPLIED.** Four readings, no discriminator run against known mathematics yet. All 203 words keep trapping. | **OPEN** |

---

## 1. The shape argument, at its real strength

```
  bit2=0 (f=0..3): [1335, 1331, 285,  53]   total 3004
  bit2=1 (f=4..7): [  59,   58,  12,  21]   total  150

  normalised to base 0:
     bit2=0 : 1.000  0.997  0.213  0.040
     bit2=1 : 1.000  0.983  0.203  0.356
```

Bases 0, 1 and 2 agreeing to three digits across a 20× difference in sample size
is a strong hint that `hi12[3:1]` is not a flat 8-way selector but a **2-bit base
operation with a modifier bit**. It is also *only* a frequency argument: it says
the field has structure, not what the structure means. And base 3 breaks it, so
the modifier reading cannot be the whole story.

Stated as a lead, not a decode — the project has been bitten twice this month by
a scored regularity promoted to a determination
([`dram-direction.md`](dram-direction.md), [`capture-signature.md`](capture-signature.md)).

## 2. Why the obvious instrument fails

The biquad is the project's best acceptance test: it reproduces the firmware's
own coefficient designer to 0.198 dB and has been shown able to reject wrong
models by 51 to 999 dB. It is useless here, and *provably* so rather than
empirically:

> **An `f31 = 0` word is a barrier.** `acc ← P` discards the accumulator, so no
> upstream difference that lives in `acc` survives it. PEQ's biquad starts with
> one.

That is the same lemma family as this project's other two decidability results —
`load` and `add` coinciding at `hi12[3:1] == 0`
([`action00-discriminator.md`](action00-discriminator.md)), and a capture into
the register the word already sources being the identity
([`act0b-reverb.md`](act0b-reverb.md) item E). **Three barriers, all of the form
"the difference is destroyed before anything reads it", all discovered after a
search rather than before one.** The pattern is now clear enough to check first
as a matter of routine.

## 3. Predict-then-check

- **P1 MISS, and it is the pass.** I predicted the biquad would decide the field
  because PEQ carries four `f>2` words, two of them feeding it. It cannot see
  any of them, and I could have established that from PEQ's first opcode before
  writing a line of test code.
- **P2 HIT.** I predicted the field would show internal structure rather than be
  a flat 8-way selector. Bases 0/1/2 track to three digits.
- **P3 MISS.** I predicted that structure would cover all four bases. Base 3
  refutes it, by a margin that is not close.
- **P4 HIT.** I predicted a large blind fraction. 92 of 203.
- **P5 unforeseen.** That *observable* would need splitting from *decidable* —
  PEQ's sites are reachable and still useless, because a store nobody reads back
  observes nothing.

## 4. What the next pass needs

1. ★ **AUTO PAN, not PARAMETRIC EQ.** Four observable sites, in a program whose
   arithmetic is anchored **nine-fold** — 29 LFO blocks whose increments are
   exactly `floor(f × 2²³ / 44100)` for round decimal rates
   ([`lfo-ramp.md`](lfo-ramp.md)) — and whose observable is a *ramp*, not a
   filter response, so it does not run through a biquad's `f31 = 0` barrier.
   This is the discriminator this pass was looking for and did not use.
2. **Check the barrier before building the experiment**, not after. For any
   field, ask first which words can carry a difference to a reader *that is
   itself read back*.
3. **The four readings are a starting set, not an enumeration.** `base`, `negP`,
   `hold`, `prod` cover the obvious shapes; a real solve should enumerate the
   product term, the feedback term and the sign independently, and include
   whatever base 3 turns out to be — item C says it is not a modified base 3.
