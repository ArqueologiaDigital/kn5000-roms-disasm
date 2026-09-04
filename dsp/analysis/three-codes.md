# `ACT 0x0D`, `0x0E`, `0x1A` — undecidable by both anchored contexts, and what the corpus says instead

NEC **uPD6383GF-3BA** (Technics SX-KN5000, IC311). Date: **2026-07-27**.
No hardware. Static analysis and the ROM corpus only.

**Why this note exists.** These three codes trap 9 of the reverb's 133 words, and
every reverb result in
[`blocka-forced-defect.md`](blocka-forced-defect.md) carries *speculative*
readings for them. They are the last thing between the reverb and a trustworthy
simulation.

Labels: **MEASURED** / **PROVEN BY CONSTRUCTION** / **CONSISTENT** / **INFERRED** /
**OPEN**.

---

## 0. Result

| # | statement | label |
|---|---|---|
| **A** | ⛔ **THE PARAMETRIC EQ HALF IS RETRACTED — §234 (2026-09-04).** The 144 identical machines were `peq_ir()` **pre-loading the sample into acc and P every frame**, so the entry words had nothing to deliver; with the sample in the cell the entry READS (`0x05` / `0x0F`) and acc = P = 0 at frame start, the same window separates the 49 `act0d × act0e` pairs and leaves the shipped `(acc<-bus, P<-bus)` **1 of 49** (`dsp/tools/gate_settle.py act0d0e`). The LFO half below stands. *Original text:* ★★★ **NEITHER known-mathematics context on this chip can decide any of the three.** PARAMETRIC EQ *carries* `0x0D` and `0x0E` — and scoring **144 machines** over `act0d × act0e × f31hi` against the designer gives **0.113 dB for every one of them**, because the biquad's first word is `f31 = 0` (`acc ← P`) and discards everything upstream. The LFO: **0 of its 29 block windows** contains any of the three. | **MEASURED** |
| **B** | ★★ **`ACT 0x0E` shares a word-shape with `ACT 0x07` (`mem[ptr] ← bus`) in 8 distinct shapes** — more than all its other anchored pairings combined (`0x15` ×2, `0x19` ×1, `0x13` ×1). Same `hi12`, `class4`, `addr8`, `SRC` and mode; differing **only** in the ACTION field. | **MEASURED** |
| **C** | ★★★ **And that independently corroborates the speculative result.** [`SPECULATIVE-reverb-run.md`](SPECULATIVE-reverb-run.md) §2 found *functionally* that `0x0E = mem[ptr] ← bus` was **the only reading of six** that let any energy reach the delay lines — 30 of 36 combinations eliminated. **Two unrelated arguments, one distributional and one functional, reaching the same answer.** | **CONSISTENT**, two routes |
| **D** | ★ **`ACT 0x1A` pairs with `0x14` (`tempB ← bus`) and `0x19`, one shape each** — and the pair sites are the reverb's own **BLOCK A `.0`** (`880.1.60.2D4`, ACT `0x14`) and **BLOCK B `.0`** (`880.1.60.2DA`, ACT `0x1A`): byte-identical but for the ACTION. With `0x1A = 0x14 + 6` exactly as `0x19 = 0x13 + 6`. | **INFERRED** (weak — one shape) |
| **E** | ⛔ **`ACT 0x0D` has NO minimal pair against any anchored code at all.** 76 distinct word-shapes carry it, and **not one** of them also appears with an anchored ACTION. It is the hardest of the three by a wide margin, and nothing in the corpus currently constrains it. | **MEASURED** (a negative) |

---

## 1. Why the anchored contexts fail

### 1.1 PARAMETRIC EQ carries them and cannot see them

`0x0D` at `w000` and `w053`; `0x0E` at `w001` and `w054`. The published
acceptance window is only `w005..w013`, so the natural move is to extend it to
`w000` — which needs `f31 = 5` (at `w003`) enumerated as well.

Extended, the window **reproduces the designer at 0.113 dB**, tighter than the
9-word window's 0.198. It is a valid test. Then:

```
  144 machines (act0d x act0e x f31hi)
  best 0.113 dB   worst 0.113 dB   accepted 144 of 144   rejected 0
```

**Every machine identical.** The window is blind to all three fields, for the
reason already on record: the biquad's first word discards the accumulator, and
whatever these codes write is not read at the pointer the biquad uses.

⛔ **RETRACTED §234 (2026-09-04).** The identity was the harness's: `peq_ir()` sets
`acc = P = x << ASH` at the top of every frame, so P — which is exactly what the
entry writes and what the biquad's first word (`f31 = 0`, `acc ← P`) reloads — was
supplied by the injection, not by the program. With the sample placed in the cell
`w0`/`w54` read and acc = P = 0 at frame start, the window is NOT blind: 2 of 49
pairs deliver both channels at 0.198 dB, a junk-pre-load control leaves 1, and it
is the pair the device ships. Reproduced as a control there: the pre-loaded harness
scores 0.198 ×42 / 999 ×7, and the seven at 999 include the right answer.
See `SPECULATIVE-APPLIED-REGISTER.md` §234 items A and B.

### 1.2 The LFO does not contain them

29 block windows, lengths 2 to 20 words. **Zero** contain an `ACT 0x0D`, `0x0E`
or `0x1A` word — CHORUS's and AUTO PAN's instances all sit outside their blocks.

**So both instruments this chip has are blind, and that is why these codes have
never been decoded.**

## 2. What the corpus says instead

Minimal pairs — the same word-shape appearing with two different ACTIONs — do
exist, and they are informative even though no acceptance test can score them:

```
  ACT 0x0E   vs 0x07 mem[ptr]<-bus  :  8 shapes     <- dominant
             vs 0x15 none(5)        :  2
             vs 0x19 tempA<-bus(2)  :  1
             vs 0x13 tempA<-bus     :  1

  ACT 0x1A   vs 0x14 tempB<-bus     :  1
             vs 0x19 tempA<-bus(2)  :  1

  ACT 0x0D   (no anchored pairing at all, over 76 shapes)
```

**This is a distributional argument, not a proof.** Sharing a word-shape shows
the two codes are *interchangeable in that structural slot* — the assembler used
the same instruction with a different action — not that they mean the same thing.
It is evidence about where a code belongs, not what it does.

But for `0x0E` it points the same way as an entirely independent functional
result (item C), and agreement between a distributional argument and a functional
one is worth considerably more than either alone.

## 3. Predict-then-check

- **P1 MISS.** I predicted extending the biquad window would bring `0x0D`/`0x0E`
  into scope. It brings them into the *program* and not into the *observable* —
  144 of 144 identical.
- **P2 HIT.** I predicted the LFO would be checked before use rather than after,
  and it was: 0 of 29 windows, established before any search was run.
- **P3 unforeseen.** I did not expect `0x0D` to have **no anchored minimal pair
  whatsoever**. That is the sharpest thing here and it re-ranks the three.

## 4. What the next pass needs

1. **`0x0E` is the tractable one.** Two independent routes agree on
   `mem[ptr] ← bus`. What it lacks is a context that can *score* it — and item B
   names 8 candidate word-shapes, each of which is a site where a program uses
   `0x07` and another uses `0x0E` in the identical slot. Executing both programs
   and comparing at that slot is a real experiment.
2. **`0x1A` needs the reverb**, which is the only place its pair occurs — and the
   reverb is exactly what cannot yet be trusted. Circular for now.
3. ★ **`0x0D` needs something the corpus does not contain.** No anchored pair, no
   anchored context. It is the one code here for which the honest answer is *the
   available evidence cannot settle this*, and saying so is more useful than
   another search that was never going to work.

---

## 5. The `0x0E` execution experiment — attempted, and the instrument has no power

§4 proposed executing the 8 word-shapes where one program uses `ACT 0x07` and
another uses `ACT 0x0E` in the identical slot. The natural test: **a word that
writes `mem[ptr]` should be followed by a read of `mem[ptr]` at the same
pointer**, before that cell is overwritten.

With the calibration codes included it looked promising — the known memory write
at 34.5%, the known temp writes at 8.9% and 5.1%, `no side effect` at 2.3%. Then
the null:

```
  base rate over ALL 3154 words (any ACTION) : 31.3%

  0x07  mem[ptr] <- bus  KNOWN   34.5%   x1.10
  0x00  acc <- bus       KNOWN   33.1%   x1.06     <- writes NO memory
  0x15  none             KNOWN   25.4%   x0.81
  0x13  tempA <- bus     KNOWN    8.9%   x0.28
  0x14  tempB <- bus     KNOWN    5.1%   x0.16
  0x12  none             KNOWN    2.3%   x0.07
  0x0E  ?                TARGET  44.8%   x1.43
  0x0D  ?                TARGET  66.5%   x2.13
  0x1A  ?                TARGET  14.3%   x0.46
```

⛔ **The known memory write beats the null by 1.10×, and a known NON-memory-write
matches it at 1.06×.** The test does not detect memory writes; it detects how
often a `mem[ptr]` read happens to follow, which is a property of **code
density**. Any conclusion about `0x0E` drawn from it would be unfounded, and none
is drawn.

**`ACT 0x0E = mem[ptr] ← bus` therefore stands at TWO routes, not three** —
distributional (§2) and functional
([`SPECULATIVE-reverb-run.md`](SPECULATIVE-reverb-run.md) §2). Still CONSISTENT,
still not applied.

### 5.1 Method note

This is the fifth instrument in one day that could not measure what it was built
to measure — **and the first that was caught before a conclusion was stated
rather than after.** The catch was computing the null *before* interpreting the
table, which is the specific step missing from the other four.

The residue worth keeping: `0x0D` at **×2.13** is the strongest association in
the table and is *higher than the known memory write* — which is not what a
memory write looks like. Unexplained, and recorded rather than interpreted.
