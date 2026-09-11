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

## Next step (deliberate)
Get a **non-saturating** recursive trajectory, then run the differential null:
- seed a small excitation the way `UPD6383_BIQSEED` did (right-shift the state seeds) so the
  recursion stays in range for several frames, OR inject a short low-amplitude impulse;
- capture ~8 consecutive frames of 0x64..0x67 (TRACE_DETAIL across F..F+7);
- feed the captured x-input + coefficients (C-RAM 0x00+ >> 1, per the N1′ reconciliation) into
  DF-I / DF-II canonical / DF-II transposed under 24-bit **saturating** fixed point
  (`biquad_topology_probe.py`), and accept a form only if it reproduces the cell trajectory
  bit-exactly **and a rival FAILS**.
