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

### M1 PROGRESS 2026-09-11 — attempted; blocker RE-LOCALIZED (not the input route)
Ran the prerequisite state-writer census on the seeded band-0 frame. The input route is NOT the
blocker for the null — the input value is captured (mem[0x64]). The real gap is narrower and new:
**cells 0x66/0x67 evolve across frames (0x66: 0 → 0.00663 → 0.01543) but NO word stores to them via
the bit-4 gate** — only 0x65 is written (cur 0x02, band-0 coef +0.2478; and cur 0x06, band-1 entry
coef −0.4953, both bit-4 stores). So the biquad y-history cells 0x66/0x67 update via a mechanism not
yet identified (not a bit-4 store; candidates: a delay-line shift like 0x64→0x65, a pointer-indirect
write, or the makeup/0x102 store to an aliased cell). A canonical-vs-transposed null cannot be clean
until every state cell's update law is known, so NO topology call is made (that would overclaim).
**Next for M1:** identify the 0x66/0x67 writer — census pointer-indirect / non-bit-4 stores and the
makeup-word target across the full frame; that is now the single concrete unknown for the null.

### M1 PROGRESS (cont.) — the writer is OUTSIDE the decoded DSP store path
Full-frame store census: every band stores ONLY to its **+1 cell** (0x65, 0x69, 0x6D, 0x71, 0x75)
plus the 0x50 stereo-twin +1 cells (0x51, 0x55, 0x59, 0x5D, 0x61); **no bit-4 store EVER targets any
+2/+3 cell** (0x66, 0x67, 0x6A, 0x6B, …). Yet 0x66 is read as physical cell 0x66 (dp=0x66) and its
value evolves frame-to-frame. So the y-history +2/+3 cells are written by a mechanism **outside the
decoded DSP bit-4 store** — i.e. an external/other-process writer or an undecoded store path.
**Honest consequence:** this RE-CONNECTS the null to the input-route/external-writer question — my
"not blocked on the input route" was premature. The clean statement: the biquad stores exactly one
state per band (the +1 shared w); the +2/+3 y-history is populated by an unidentified writer, and
until that writer is known the canonical-vs-transposed null cannot be clean. This is a sharper,
truer localization than before, and it is a genuine open RE question — not withheld effort.

## M2 — Decide the unanchored ACT codes against SINGLE DELAY ground truth [offline; unblocks the class]
`unblocking-and-discriminators.md`: SINGLE DELAY has a validated answer (lag 1001, gain 0.02149296,
matched to 0.001%). If SINGLE DELAY's program exercises the unanchored codes (ACT 0x0D/0x0E, SRC
0x08/0x11), then the enumerated reading that reproduces its known lag+gain is the **correct** one —
a ground-truth decode without hardware.
- Step: grep SINGLE DELAY's disasm for the unanchored codes; if present, run each enumerated reading
  through the HLE/sim and keep only the one matching lag 1001 / gain 0.02149.
- Falsifier: if SINGLE DELAY does not use those codes, this program can't decide them — say so; try
  another known-answer program (PARAMETRIC EQ's biquad is bit-exact and may constrain SRC 0x08/0x11).

### M2 PROGRESS 2026-09-11 — the codes are LOCATED (structural, ground-truth)
`unanchored_context_probe.py` on prog09_single_delay.dsm: the input-route codes occur as a PAIR —
ACT 0x0D (SRC 0x07 = mem[ptr]) then ACT 0x0E (SRC 0x10 = acc) — three times (w1-2, w21-22, w44-45),
and each pair sits on the path **[delay-DRAM READ (w0, addr8 0x30)] → [ACT 0x0D mem][ACT 0x0E acc] →
MACs → [delay-DRAM WRITE (w5/w28/w46, addr8 0x60)]**. So in the one validated program the codes are
the **delay-line input mixing**: they gather mem (dry/input) and acc (wet/feedback) onto the bus that
feeds the delay/state write. **STRONG (ground-truth placement); the exact ALU op stays enumerated**
(consistent with ACT 0x0D: acc←bus, ACT 0x0E: P←bus). SINGLE DELAY's validated lag/gain is invariant
to the reading (result B), so it locates but does not decode the op. **This is the input-route
mechanism the biquad's x0=0x64 route shares** — the same bus-mixing, now seen where it's legible.
Next for M2: check whether PARAMETRIC EQ's bit-exact biquad constrains SRC 0x08/0x11 the same way.

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
