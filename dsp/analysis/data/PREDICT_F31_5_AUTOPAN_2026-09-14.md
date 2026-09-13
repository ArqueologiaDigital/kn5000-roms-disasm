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
