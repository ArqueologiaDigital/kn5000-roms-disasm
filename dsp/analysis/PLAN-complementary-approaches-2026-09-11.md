# Plan: complementary + speculative approaches to finish N2/N4/N3 (2026-09-11)

## Honest reframe (contradict-and-correct my own "blocked" claim)
I concluded the N2/N4 differential nulls were "blocked on the input-route decode." That over-stated
it. The null needs the input **value**, and the trace already captures it (mem[0x64] each frame) —
it does **not** need the firmware's routing of audio to x0 decoded. And there is unexploited ground
truth (SINGLE DELAY's validated answer). So the path is narrower than "solve an open RE problem":
several complementary techniques can attack it with what's already capturable. Each below carries a
falsifier so a speculative reading can never pass as decoded (the standing rule).

## M1 — N2 differential null from the CAPTURED input (no firmware route needed) [offline; highest leverage]
I already have, from BIQSEED_ONCE, a non-degenerate band-0 trajectory + the captured input x0[F]
(mem[0x64]) + the coefficients (C-RAM>>1). Model DF-II **canonical** and DF-II **transposed** exactly
(cursor-ordered MAC + the store timing decoded in instruction-set.md), feed the captured x0 sequence
and coefficients, and predict the internal state (0x65/0x66/0x67) at F+1. **Accept a form only if it
reproduces the captured trajectory bit-exactly AND the rival FAILS.**
- Complication: 0x66 is written by another (cascade) word, not band 0. Handle by (a) capturing a
  SINGLE-BAND program if one exists, or (b) modelling the 2-3 coupled words that touch 0x66 (their
  cursors + store bits are in the trace), or (c) restricting the null to the cells band 0 alone writes
  (0x65, store-bit=1) — the shared w — which is exactly the DF-II discriminator.
- Falsifier: if neither form reproduces 0x65's trajectory, or both do, the null is not discriminating
  — report OPEN, do not pick.

## M2 — Decide the unanchored ACT codes against SINGLE DELAY ground truth [offline; unblocks the class]
`unblocking-and-discriminators.md`: SINGLE DELAY has a validated answer (lag 1001, gain 0.02149296,
matched to 0.001%). If SINGLE DELAY's program exercises the unanchored codes (ACT 0x0D/0x0E, SRC
0x08/0x11), then the enumerated reading that reproduces its known lag+gain is the **correct** one —
a ground-truth decode without hardware.
- Step: grep SINGLE DELAY's disasm for the unanchored codes; if present, run each enumerated reading
  through the HLE/sim and keep only the one matching lag 1001 / gain 0.02149.
- Falsifier: if SINGLE DELAY does not use those codes, this program can't decide them — say so; try
  another known-answer program (PARAMETRIC EQ's biquad is bit-exact and may constrain SRC 0x08/0x11).

## M3 — WSA1R as a second witness for the shared biquad realization [complementary; independent instance]
The WSA1R uses the same uPD6383 biquad hardware (memory: "WSA1R PEQ = same DF-I biquad"). Its DSP
device runs behind WSA1R_ENABLE_DSP. Capture its biquad state trajectory (BIQSEED_ONCE-equivalent) —
a second, independent instance of the same realization. If both KN5000 and WSA1R trajectories are
reproduced by the SAME DF-II variant and rejected by the rival, that is a cross-product null far
stronger than one instance.
- Falsifier: if the two products disagree on the winning form, the realization is not shared — a
  finding that itself corrects the "same biquad" memory.

## M4 — Longer trajectories + HLE oracle as differential referee [complementary; strengthens M1]
Extend the capture to 8+ consecutive seeded frames (BIQSEED_ONCE + TRACE_FRAME=F..F+7) for a more
constraining null, and feed the captured input through the validated DSP HLE (dsp/hle/). Divergence
between HLE and each candidate localizes the realization. (HLE is topology-agnostic on H(z) but its
internal state is a concrete reference to diff against.)

## M5 — N4 gain-mapping from the (already-decoded) delay structure [offline]
The delay-advance is decoded: delay = READ_CELL − WRITE_CELL, address DESCRIPTOR_CELL[k]+G, addr8
bit 6 = direction. Read the descriptor block to get the per-tap delay length, then relate the measured
per-frame decay ratios (0xD0 ×0.767, 0xD2/0x8A ×0.547) to the all-pass gains (0.91/0.1367) through
the known delay length. The ×2.024 growth on 0x8B: test the C-RAM>>1 factor-of-2 hypothesis.
- Falsifier: if no delay length makes the ratios consistent with the gains, the seeded cells aren't
  the ladder taps — recensus.

## M6 — N3 audible EQ, speculative + default-off [after M1 decides the form]
Once M1 fixes the realization, implement it behind `SPEC_DF2` + `SPEC_AUDIO` (default off, labelled),
route to the mix beside the HLE, accept on an INDEPENDENT spectral A/B (FFT tracks panel edits vs
peq_ab.py). Default-off/labelled keeps it within the "speculative audio, drop-in, review before merge"
rule — the behavioral edit is not merged without review, but building+testing it default-off is not
review-gated.

## Ordering
M1 first (offline, uses data in hand, highest leverage) and M2 in parallel (offline, could decode the
unanchored codes outright). M3/M4 strengthen M1. M5 is independent (offline). M6 last, gated on M1.
The reframe means the "wall" is attackable now with captured inputs + ground-truth programs — no
hardware, no overclaim (every step has a ground-truth check or a falsifier).
