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

## Second run — reverb correctly selected, still no decay; ROOT CAUSE found
Built `reverb_select.lua` (opens the DIGITAL REVERB page 0x0A via CPL_SEG8 0x02 — the unit-1
reverb, not the DSP-EFFECT page peq_gain uses; per notes/kn5000-dsp-paramlist.md). The page opens
(type=0x0A confirmed) and unit 1 runs, but seeding still shows no clean decay: 0xD0 grows
(1.46/1.24), and the seeded cells 0x85/0x8C/0x8F stay frozen.

`reverb_active_cells_probe.py` on the reverb frame explains it: **the REVSEED cell set is partly
wrong.** Censusing the unit-1 frame's D-RAM accesses, the real delay-line/state cells (by store
count) are **0x94 (45 reads/5 stores, the hub), 0x8B (30/4), 0xD1, 0xD2, 0xFC, 0x88, 0x89, 0xD0** —
but REVSEED seeds the **dead coefficient cells 0x85 (4 reads/0 stores) and 0x8C** and misses
0x8B/0xD1/0xD2/0xFC entirely. Frozen seed cells + a growing 0xD0 = seeding the wrong cells, not a
decoded (or refuted) decay. Evidence: `data/kn5000-dsp-reverb-frame-page0A-2026-09-11.txt`.

## Third run — REVSEED retargeted, and the reverb DECAYS
Retargeted REVSEED to the measured delay-line cells (0x94, 0x8B, 0xD0/0xD1/0xD2, 0x8A) and re-ran
the seed-once decay test on the reverb page. The seeded cells now show **stable geometric per-frame
ratios** — the reverb's linear feedback datapath is live (unlike the frozen dead cells):
- **0xD0 → ×0.767 decay** (0.7672/0.7673/0.7673),
- **0xD2, 0x8A → ×0.547 decay** (0.5467/0.5465/0.5468),
- **0x8B → ×2.024 growth** (constant — an accumulator, or the C-RAM>>1 factor-of-2 seen in the biquad).
Ratios constant to 4 decimals across all steps ⇒ clean linear behaviour; the seed-once impulse-decay
METHOD works. Tool `reverb_decay_probe.py`; data `data/kn5000-dsp-reverb-decay-F{1..4}-2026-09-11.txt`.

## Still open (the substantive question)
Mapping the per-frame ratios (0.767, 0.547) to the all-pass gains (0.91 / 0.1367) needs the
delay-line length/structure — the per-frame ratio is not the single-tap gain until the loop
structure (§73-78 delay-advance) is known — and 0x8B's ×2.024 growth needs the same structural read.
The harness (seed-once + reverb page + delay-cell targeting + decay probe) is now in place to do it.
