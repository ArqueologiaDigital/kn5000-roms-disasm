# N4 progress: reverb impulse-decay capability + first (inconclusive) run (2026-09-11)

## Capability built
`UPD6383_REVSEED_ONCE=F` (upd6383.cpp, default 0) seeds the reverb (unit-1) state cells
**once** at frame F and lets them evolve — the BIQSEED_ONCE analogue for the reverb, so the
delay line can be impulse-tested for a decaying echo train instead of being re-forced every
frame. Pairs with the existing `UPD6383_REVSEED` (which sets the seed magnitude).

## First run — INCONCLUSIVE (documented so it is not repeated blindly)
Seeded once at frame 2000000 (REVSEED=8), captured frames F0+1..F0+3
(`data/kn5000-dsp-reverb-seedonce-{F0p1,F0p2,F0p3}-2026-09-11.txt`):
- **0xD0 grows** 0.00301 → 0.00490 → 0.00666 (ratios 1.63, 1.36) — not a clean per-loop decay;
- 0x94, 0x8A, 0x85, 0x8C, 0x8F stay constant (0x8A pinned at −1.0; 0x85/0x8C/0x8F at their seeds).

**Root cause of the inconclusive result:** the capture had **PARAMETRIC EQ selected** on unit 0
(the peq_gain rig, TYPEIDX=15). Unit 1 is therefore not running an actual reverb program, so the
seeded cells are not being advanced as a reverb delay line — hence the frozen cells and the
non-decaying 0xD0. This is a finding about the experiment setup, not a reverb decode, and it
confirms the delay-line advance (§73-78) remains the open blocker.

## Next step (deliberate)
Run the same REVSEED_ONCE decay test with an **actual reverb effect selected** (navigate to a
reverb program, not PARAMETRIC EQ) so unit 1 runs its delay-advance body, then check whether the
delay-line cells produce a decaying echo train whose per-loop ratio tracks the measured all-pass
gains (0.91 / 0.1367). Needs a rig that selects a reverb effect by its TYPE index (peq_gain only
reaches PARAMETRIC EQ); the effect-index list is the prerequisite. The delay-line advance itself
(§73-78) is the substantive open question this would test.
