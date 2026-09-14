# PRE-REGISTRATION — `f31 == 5` on AUTO PAN, the discriminator `f31-high.md` named and never ran

Written **before** the run. 2026-09-14.

## Whose idea this is
`f31-high.md` §4 item 1, "what the next pass needs":

> ★ **AUTO PAN, not PARAMETRIC EQ.** Four observable sites, in a program whose arithmetic is
> anchored **nine-fold** — 29 LFO blocks whose increments are exactly `floor(f × 2²³/44100)` for
> round decimal rates — and whose observable is a *ramp*, not a filter response, so it does not run
> through a biquad's `f31 = 0` barrier. **This is the discriminator this pass was looking for and
> did not use.**

⚠ And item D records why the obvious instrument fails, so it is not retried: PARAMETRIC EQ's
biquad gives **0.198 dB for all four readings** because it opens with an `f31 = 0` word that
discards the accumulator. §108's sweep covered TYPES 0/2/4/15/18 — **auto pan (TYPE 16) was not in
it.**

## The arms
`m_bx_f5` = SPEC bits 50-51: `0` keeps the shipped alias (`f31 & 3` ⇒ **5 → ADD**), `1` = LOAD,
`3` = HOLD. `UPD6383_CENSUS_PERPROG=1`, TYPE 16, true default otherwise.

| | mask |
|---|---|
| control (ADD) | `b910e446a39b440f` |
| LOAD | `b914e446a39b440f` |
| HOLD | `b91ce446a39b440f` |

## Predictions

| | prediction |
|---|---|
| **Q1** | the arm FIRES — `§205 f31=5` > 0 on TYPE 16 |
| **Q2** ★ | the `§228` RISE CENSUS on auto pan's phase cell reads a **different step** under at least two of the three readings — i.e. the LFO can SEE this field, which is the whole claim of item 1 and which the EQ could not do |
| **Q3** ★★ | **exactly one** reading gives a step matching a ROM increment `floor(f × 2²³/44100)` for a round decimal rate, the others not ⇒ that reading is `f31 == 5` |
| **Q4** | outcome C — the LFO sees the field but no reading lands on a ROM constant ⇒ the discriminator is live but does not decide, reported as such |
| **Q5** | ⚠ §111's boundary: a single program's result needs corroboration on the other LFO-bearing programs before promotion |


---

## RESULT — **Q2 MISS: the auto-pan discriminator is BLOCKED on the LFO rate defect**
Data: [`f31_5_autopan_2026-09-14.txt`](f31_5_autopan_2026-09-14.txt).

**Q1 HIT** — `f31 = 5` fires **2 480 216** times on TYPE 16. **Q2 MISS** — the `§228` rise census is
**identical across ADD / LOAD / HOLD**, and more to the point it shows no ramp to read:

```
   04: step    256..469760   mean     14 073      10: step   4..3415889  mean   163 075
   05: step    368..676454   mean     20 266      11: step   6..4194283  mean 1 900 064
   12: step    152..2313079  mean     93 706      13: step   6..4194283  mean 1 900 064
```

**No cell steps at or near 228** — `AUTO PAN C-RAM 01 = 0x0000E4 = 228 = floor(1.1986 × 2²³/44100)`,
the ROM's own constant for its 1.2 Hz pan.

⇒ `f31-high.md` §4 item 1's reasoning was right about the *kind* of instrument — a ramp does not
run through the biquad's `f31 = 0` barrier — but its **precondition is not met**: the ramp is not
clean in the first place. The same LFO-rate defect that §102 measured (153 Hz against 0.599 Hz on
the chorus) and that §109 found a path to (destination `P` brings it to 0.674 Hz while destroying
the hand-off) sits upstream of this discriminator.

★ **So the dependency is now explicit: `f31` 3/4/5/7 is blocked behind the LFO rate defect, and
§109 named the path to that.** That is a chain, not a dead end — and it is worth more than another
inconclusive sweep, because it says which problem to solve first.

⚠ Recorded rather than retried: this is the instrument the previous pass explicitly asked for, and
the reason it does not work is not the one it anticipated.
