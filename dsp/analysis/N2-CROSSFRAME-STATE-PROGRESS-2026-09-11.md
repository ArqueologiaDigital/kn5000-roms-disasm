# N2 progress: cross-frame biquad state capture (2026-09-11)

## Goal
The only valid biquad-realization decode is a cross-frame internal-STATE match with a
differential null — response/FFT/stability/HLE are topology-invariant. This session built
the capability and took the first consecutive-frame capture.

## Capability built
`UPD6383_TRACE_DETAIL=N` (upd6383.cpp/.h, default 0 = off) re-arms the per-word frame-detail
dump for N frames at the `UPD6383_TRACE_FRAME` arm, so the biquad operand/state cells can be
read **during note-play** (the detail window otherwise re-arms only on an effect upload, which
closes before the panel-selected notes sound). With `UPD6383_SPEC_INJECT=1` (real audio →
x0=0x64) and a held C4/E4/G4, band 0's cells 0x64..0x67 are captured per frame; deterministic
emulation gives consecutive frames from re-runs at F and F+1. Tool: `eq_xframe_state_probe.py`.
Data: `data/kn5000-dsp-eq-xframe-{A,B}-2026-09-11.txt` (frames 2100001, 2100002).

## Findings (MEASURED)
1. **The input delay line shifts x0→x1 one cell per frame.** 0x65 in frame B equals 0x64 in
   frame A **exactly** (−0.0250244…). The feedforward delay is confirmed directly from state,
   not inferred from coefficients.
2. **The recursion SATURATES.** Even with a small injected input, the accumulator is pinned
   (acc=−2,523,529,216, datum clamped to −1.0) and the recursive cells 0x66/0x67 are frozen
   frame-to-frame (0.99999988 / 0.5). So the recursive-state trajectory is flat/degenerate and
   **cannot** decide the DF-II-family form. This localizes the long-standing "LLE saturates"
   problem to the recursive path and is consistent with the SEED8 note ("KN5000 EQ coeffs
   Jury-unstable in this DF-I order").

## Why no topology claim
A differential null needs a *non-degenerate* recursive trajectory that some candidate forms
reproduce and others fail. The captured recursion is saturated (degenerate), so any form would
"match" a constant — a criterion that cannot fail. Claiming a realization here would repeat the
DF-II overclaim the verification caught. Held.

## UPDATE (same session): non-degenerate trajectory OBTAINED
The saturation blocker is cleared. `UPD6383_BIQSEED_ONCE=F` (upd6383.cpp, default 0) seeds the
band-0 state **once** at frame F and lets the recursion evolve. With a small seed (BIQSEED=64),
frames 2000001/2000002 give a live trajectory: **0x66 evolves 0 → 0.00663 → 0.01543** (recursive
history), 0x64→0x65 is the input delay, 0x67 the delayed 0x66. Data:
`data/kn5000-dsp-eq-seedonce-{F0,F0p1,F0p2}-2026-09-11.txt`; tool `eq_seed_trajectory_probe.py`.

### Corroboration (MEASURED): 0x65 is a WRITTEN state cell (DF-II shared w)
The store gate (hi12 bit 4) on the band-0 words: 0x64 store=0 (read-only input x0), **0x65
store=1** (cur 0x02 reads it as an operand AND writes it), 0x66/0x67 store=0. So 0x65 is not a
passive x1 — it is the DF-II shared intermediate w: read as w[n-1], rewritten as w[n] in the same
word. Its cross-frame value tracks the delayed input only because w≈x when feedback is small
(low-signal degeneracy). This **independently corroborates SHARED-DELAY (DF-II-family)** and rules
out textbook DF-I — consistent with the topology work, now from a live seeded trajectory + the
store bit rather than from the coefficient layout alone.

## Next step (deliberate)
Distinguish DF-II canonical vs transposed (the only remaining topology unknown):
- capture ~8 consecutive seeded frames (TRACE_FRAME=F..F+7 with BIQSEED_ONCE at F) for a longer w
  trajectory, ideally at a frame with notes OFF for a clean zero-input natural response;
- feed the seeded IC + coefficients (C-RAM 0x00+ >> 1, per the N1′ reconciliation) into DF-II
  canonical vs transposed under 24-bit **saturating** fixed point (`biquad_topology_probe.py`),
  and accept a form only if it reproduces the w-trajectory bit-exactly **and the rival FAILS**.
